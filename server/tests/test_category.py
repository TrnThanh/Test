import pytest
from fastapi import status
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from server.app.models.restaurant import Restaurant
from server.app.models.category import Category
from server.app.models.dish import Dish


@pytest.fixture
def restaurant_a(db_session: Session) -> Restaurant:
    restaurant = Restaurant(
        name="Cơm Tấm Sài Gòn A",
        address="123 Lê Lợi, Q1, TP.HCM",
        latitude=10.7769,
        longitude=106.7009,
    )
    db_session.add(restaurant)
    db_session.commit()
    db_session.refresh(restaurant)
    return restaurant


@pytest.fixture
def restaurant_b(db_session: Session) -> Restaurant:
    restaurant = Restaurant(
        name="Cơm Tấm Sài Gòn B",
        address="456 Hai Bà Trưng, Q3, TP.HCM",
        latitude=10.7850,
        longitude=106.6950,
    )
    db_session.add(restaurant)
    db_session.commit()
    db_session.refresh(restaurant)
    return restaurant


def test_create_category_success(client: TestClient, restaurant_a: Restaurant):
    """Test tạo danh mục thành công."""
    res = client.post(
        f"/api/v1/restaurants/{restaurant_a.id}/categories",
        json={
            "name": "Món Cơm Đĩa",
            "description": "Các món cơm sườn, bì, chả đặc sắc",
            "display_order": 1,
            "is_active": True,
        },
    )
    assert res.status_code == status.HTTP_201_CREATED
    data = res.json()
    assert data["name"] == "Món Cơm Đĩa"
    assert data["restaurant_id"] == restaurant_a.id
    assert data["display_order"] == 1
    assert data["dish_count"] == 0


def test_create_category_duplicate_name(client: TestClient, restaurant_a: Restaurant):
    """Test tạo trùng tên danh mục trong cùng một quán sẽ bị lỗi 400."""
    client.post(
        f"/api/v1/restaurants/{restaurant_a.id}/categories",
        json={"name": "Khai Vị", "display_order": 1},
    )
    res = client.post(
        f"/api/v1/restaurants/{restaurant_a.id}/categories",
        json={"name": "khai vị", "display_order": 2},
    )
    assert res.status_code == status.HTTP_400_BAD_REQUEST
    assert "đã tồn tại" in res.json()["detail"]


def test_get_categories_and_dish_count(
    client: TestClient, restaurant_a: Restaurant, db_session: Session
):
    """Test lấy danh sách categories kèm số lượng món ăn."""
    # Tạo 2 categories
    cat1_res = client.post(
        f"/api/v1/restaurants/{restaurant_a.id}/categories",
        json={"name": "Cơm", "display_order": 2},
    )
    cat2_res = client.post(
        f"/api/v1/restaurants/{restaurant_a.id}/categories",
        json={"name": "Nước", "display_order": 1},
    )
    cat1_id = cat1_res.json()["id"]

    # Thêm món ăn vào category 1
    dish = Dish(
        restaurant_id=restaurant_a.id,
        category_id=cat1_id,
        name="Cơm Sườn Nướng",
        price=45000.0,
        meal_type="lunch",
    )
    db_session.add(dish)
    db_session.commit()

    res = client.get(f"/api/v1/restaurants/{restaurant_a.id}/categories")
    assert res.status_code == status.HTTP_200_OK
    data = res.json()
    assert len(data) >= 2
    # Nước (order=1) phải đứng trước Cơm (order=2)
    names = [c["name"] for c in data]
    assert names.index("Nước") < names.index("Cơm")
    # Cơm phải có dish_count == 1
    com_cat = next(c for c in data if c["name"] == "Cơm")
    assert com_cat["dish_count"] == 1


def test_update_and_delete_category_set_null(
    client: TestClient, restaurant_a: Restaurant, db_session: Session
):
    """Test cập nhật category và xoá category (dish.category_id chuyển thành null)."""
    cat_res = client.post(
        f"/api/v1/restaurants/{restaurant_a.id}/categories",
        json={"name": "Tráng Miệng Tạm", "display_order": 99},
    )
    cat_id = cat_res.json()["id"]

    # Sửa category
    update_res = client.put(
        f"/api/v1/categories/{cat_id}",
        json={"name": "Tráng Miệng Chính Thức", "display_order": 10},
    )
    assert update_res.status_code == status.HTTP_200_OK
    assert update_res.json()["name"] == "Tráng Miệng Chính Thức"

    # Gán món ăn vào category
    dish = Dish(
        restaurant_id=restaurant_a.id,
        category_id=cat_id,
        name="Chè Đậu Đỏ",
        price=20000.0,
    )
    db_session.add(dish)
    db_session.commit()
    db_session.refresh(dish)
    dish_id = dish.id

    # Xoá category
    del_res = client.delete(f"/api/v1/categories/{cat_id}")
    assert del_res.status_code == status.HTTP_200_OK

    # Món ăn vẫn tồn tại nhưng category_id = None
    db_session.expire_all()
    updated_dish = db_session.get(Dish, dish_id)
    assert updated_dish is not None
    assert updated_dish.category_id is None


def test_create_dish_category_restaurant_mismatch(
    client: TestClient, restaurant_a: Restaurant, restaurant_b: Restaurant
):
    """Test không thể gán category_id của quán B khi tạo món cho quán A (422)."""
    # Tạo category ở quán B
    cat_b_res = client.post(
        f"/api/v1/restaurants/{restaurant_b.id}/categories",
        json={"name": "Món Quán B"},
    )
    cat_b_id = cat_b_res.json()["id"]

    # Cố tạo món ở quán A nhưng truyền category_id của quán B
    dish_res = client.post(
        f"/api/v1/restaurants/{restaurant_a.id}/dishes",
        json={
            "name": "Món Gian Lận",
            "price": 50000.0,
            "category_id": cat_b_id,
        },
    )
    assert dish_res.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY
    assert "không thuộc quán ăn này" in dish_res.json()["detail"]
