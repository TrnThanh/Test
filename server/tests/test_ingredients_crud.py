import pytest
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session
from sqlalchemy import select

from server.app.models.restaurant import Restaurant
from server.app.models.dish import Dish
from server.app.models.ingredient import Ingredient, DishIngredient
from server.app.schemas.dish import DishCreate
from server.app.services.dish_service import DishService


def test_ingredients_crud_flow(client: TestClient, db_session: Session):
    """Kiểm tra toàn diện flow Thêm, Xem, Sửa, Lọc và Xóa nguyên liệu."""
    # 1. Tạo nguyên liệu mới
    res = client.post(
        "/api/v1/ingredients",
        json={
            "name": "Nấm Kim Châm Tươi Test",
            "description": "Nấm tươi sạch nhập khẩu",
            "is_active": True,
        },
    )
    assert res.status_code == 201, res.text
    created = res.json()
    ing_id = created["id"]
    assert created["name"] == "Nấm Kim Châm Tươi Test"
    assert created["dish_count"] == 0

    # 2. Tạo trùng tên (không phân biệt hoa thường) -> 400 Bad Request
    dup = client.post(
        "/api/v1/ingredients",
        json={"name": "  nấm kim châm tươi test  "},
    )
    assert dup.status_code == 400

    # 3. Lấy danh sách nguyên liệu và tìm kiếm
    list_res = client.get("/api/v1/ingredients?search=Kim+Châm")
    assert list_res.status_code == 200
    data = list_res.json()
    assert data["total"] >= 1
    found = any(item["id"] == ing_id for item in data["items"])
    assert found is True

    # 4. Xem chi tiết nguyên liệu
    detail_res = client.get(f"/api/v1/ingredients/{ing_id}")
    assert detail_res.status_code == 200
    detail = detail_res.json()
    assert detail["name"] == "Nấm Kim Châm Tươi Test"
    assert detail["dish_count"] == 0
    assert len(detail["dishes"]) == 0

    # 5. Cập nhật thông tin nguyên liệu
    update_res = client.put(
        f"/api/v1/ingredients/{ing_id}",
        json={
            "name": "Nấm Kim Châm Hữu Cơ Test",
            "description": "Nấm canh tác chuẩn hữu cơ",
            "is_active": False,
        },
    )
    assert update_res.status_code == 200
    updated = update_res.json()
    assert updated["name"] == "Nấm Kim Châm Hữu Cơ Test"
    assert updated["is_active"] is False

    # 6. Xóa khi chưa có món ăn nào sử dụng -> thành công
    del_res = client.delete(f"/api/v1/ingredients/{ing_id}")
    assert del_res.status_code == 200

    # Kiểm tra lại 404
    check_res = client.get(f"/api/v1/ingredients/{ing_id}")
    assert check_res.status_code == 404


def test_delete_ingredient_safety_check(client: TestClient, db_session: Session):
    """Kiểm tra chặn xóa nguyên liệu an toàn khi có món ăn đang sử dụng."""
    # Tìm hoặc tạo nhà hàng mẫu
    restaurant = db_session.scalar(select(Restaurant).where(Restaurant.is_active.is_(True)))
    if not restaurant:
        restaurant = Restaurant(
            name="Quán Test An Toàn Xóa",
            address="123 Đống Đa, Hà Nội",
            latitude=21.0285,
            longitude=105.8542,
        )
        db_session.add(restaurant)
        db_session.commit()
        db_session.refresh(restaurant)

    # 1. Tạo món ăn kèm nguyên liệu đặc thù
    unique_ing_name = "Thịt Heo Iberico Độc Quyền Test"
    dish = DishService.create_dish(
        db=db_session,
        restaurant_id=restaurant.id,
        data=DishCreate(
            name="Thịt Heo Iberico Nướng Test",
            price=350000.0,
            ingredients=[unique_ing_name],
        ),
    )

    # 2. Tìm nguyên liệu vừa được tự động nạp
    ing = db_session.scalar(select(Ingredient).where(Ingredient.name == unique_ing_name))
    assert ing is not None
    ing_id = ing.id

    # 3. Thử xóa không có force -> Phải bị chặn 400 Bad Request
    del_fail = client.delete(f"/api/v1/ingredients/{ing_id}")
    assert del_fail.status_code == 400
    assert "đang có 1 món ăn sử dụng" in del_fail.json()["detail"]

    # 4. Thử xóa có force=true -> Thành công
    del_force = client.delete(f"/api/v1/ingredients/{ing_id}?force=true")
    assert del_force.status_code == 200

    # 5. Kiểm tra món ăn vẫn còn và mảng ingredients được dọn sạch
    db_session.refresh(dish)
    assert unique_ing_name not in (dish.ingredients or [])


def test_ingredient_allergen_group_and_auto_derive(client: TestClient, db_session: Session):
    """Kiểm tra nguyên liệu có nhóm dị ứng (allergen_group) và tự động suy luận vào dish.allergens."""
    # 1. Tìm hoặc tạo nhà hàng mẫu
    restaurant = db_session.scalar(select(Restaurant).where(Restaurant.is_active.is_(True)))
    if not restaurant:
        restaurant = Restaurant(
            name="Quán Test Dị Ứng",
            address="456 Hai Bà Trưng, Hà Nội",
            latitude=21.0285,
            longitude=105.8542,
        )
        db_session.add(restaurant)
        db_session.commit()
        db_session.refresh(restaurant)

    # 2. Tạo nguyên liệu Tôm sú có allergen_group là 'Hải sản'
    t_name = "Tôm Sú Cà Mau Test"
    res_ing = client.post(
        "/api/v1/ingredients",
        json={
            "name": t_name,
            "description": "Tôm sú tươi sống",
            "allergen_group": "Hải sản",
            "is_active": True,
        },
    )
    assert res_ing.status_code == 201
    assert res_ing.json()["allergen_group"] == "Hải sản"

    # 3. Tạo món ăn chứa nguyên liệu này
    dish = DishService.create_dish(
        db=db_session,
        restaurant_id=restaurant.id,
        data=DishCreate(
            name="Tôm Sú Nướng Muối Ớt Test",
            price=120000.0,
            ingredients=[t_name, "Muối ớt xanh"],
        ),
    )
    db_session.refresh(dish)

    # 4. Kiểm tra món ăn đã tự động suy luận có allergens = ['Hải sản']!
    assert "Hải sản" in dish.allergens
    assert t_name in dish.ingredients


def test_get_allergen_options_endpoint(client: TestClient, db_session: Session):
    """Kiểm tra API lấy danh sách các lựa chọn dị ứng kết nối từ DB."""
    # 1. Gọi endpoint /api/v1/ingredients/allergens
    res1 = client.get("/api/v1/ingredients/allergens")
    assert res1.status_code == 200
    allergens1 = res1.json()
    assert isinstance(allergens1, list)
    assert "Hải sản" in allergens1
    assert "Đậu phộng" in allergens1
    assert "Trứng" in allergens1

    # 2. Gọi endpoint alias /api/v1/allergens
    res2 = client.get("/api/v1/allergens")
    assert res2.status_code == 200
    allergens2 = res2.json()
    assert allergens2 == allergens1
