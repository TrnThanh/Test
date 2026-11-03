import pytest
from sqlalchemy import text, select
from sqlalchemy.orm import Session

from server.app.db.session import SessionLocal
from server.app.models.restaurant import Restaurant
from server.app.models.dish import Dish
from server.app.models.ingredient import Ingredient, DishIngredient
from server.app.schemas.dish import DishCreate, DishUpdate
from server.app.services.dish_service import DishService


@pytest.fixture
def db():
    session = SessionLocal()
    try:
        yield session
    finally:
        session.close()


@pytest.fixture
def sample_restaurant(db: Session):
    r = db.scalar(select(Restaurant).where(Restaurant.is_active.is_(True)))
    if not r:
        r = Restaurant(
            name="Quán Test Nguyên Liệu",
            address="123 Phố Test, Hà Nội",
            latitude=21.0285,
            longitude=105.8542,
        )
        db.add(r)
        db.commit()
        db.refresh(r)
    return r


def test_ingredients_migration_data_integrity(db: Session):
    """Kiểm tra các bảng ingredients và dish_ingredients đã nạp dữ liệu thành công từ mảng cũ."""
    total_ing = db.scalar(text("SELECT count(*) FROM ingredients;"))
    total_links = db.scalar(text("SELECT count(*) FROM dish_ingredients;"))
    assert total_ing > 0, "Bảng ingredients phải có ít nhất 1 bản ghi sau migration"
    assert total_links > 0, "Bảng dish_ingredients phải có liên kết sau migration"


def test_create_dish_syncs_ingredients_and_dish_ingredients(db: Session, sample_restaurant: Restaurant):
    """Kiểm tra tạo món mới tự động nạp nguyên liệu vào bảng ingredients và dish_ingredients."""
    create_dto = DishCreate(
        name="Phở Bò Wagyu Đặc Biệt Test",
        price=189000.0,
        ingredients=["Bánh phở tươi", "Thịt bò Wagyu A5", "Hành hoa Hà Nội"],
        meal_types=["breakfast", "lunch"],
    )

    dish = DishService.create_dish(db, sample_restaurant.id, create_dto)
    assert dish.id is not None

    # Kiểm tra liên kết trong bảng dish_ingredients
    links = db.scalars(select(DishIngredient).where(DishIngredient.dish_id == dish.id)).all()
    assert len(links) == 3

    # Kiểm tra tên nguyên liệu thông qua quan hệ
    linked_ing_ids = [l.ingredient_id for l in links]
    ings = db.scalars(select(Ingredient).where(Ingredient.id.in_(linked_ing_ids))).all()
    ing_names = {i.name for i in ings}
    assert "Bánh phở tươi" in ing_names
    assert "Thịt bò Wagyu A5" in ing_names
    assert "Hành hoa Hà Nội" in ing_names

    # Kiểm tra to_dish_response trả về mảng ingredients
    resp = DishService.to_dish_response(dish)
    assert len(resp.ingredients) == 3
    assert set(resp.ingredients) == ing_names

    # Cleanup
    DishService.delete_dish(db, dish.id)


def test_update_dish_syncs_ingredients(db: Session, sample_restaurant: Restaurant):
    """Kiểm tra cập nhật nguyên liệu cho món ăn (thêm mới, xóa bớt)."""
    dish = DishService.create_dish(
        db,
        sample_restaurant.id,
        DishCreate(
            name="Món Cập Nhật Nguyên Liệu Test",
            price=95000.0,
            ingredients=["Nguyên liệu A", "Nguyên liệu B"],
        ),
    )

    # Cập nhật: bỏ B, giữ A, thêm C
    update_dto = DishUpdate(
        ingredients=["Nguyên liệu A", "Nguyên liệu C mới"],
    )
    updated = DishService.update_dish(db, dish.id, update_dto)

    resp = DishService.to_dish_response(updated)
    assert len(resp.ingredients) == 2
    assert "Nguyên liệu A" in resp.ingredients
    assert "Nguyên liệu C mới" in resp.ingredients
    assert "Nguyên liệu B" not in resp.ingredients

    # Cleanup
    DishService.delete_dish(db, dish.id)


def test_cascade_delete_dish_removes_dish_ingredients(db: Session, sample_restaurant: Restaurant):
    """Kiểm tra khi xóa món ăn thì các liên kết trong dish_ingredients tự động bị xóa cascade."""
    dish = DishService.create_dish(
        db,
        sample_restaurant.id,
        DishCreate(
            name="Món Thử Nghiệm Cascade Delete",
            price=50000.0,
            ingredients=["Nguyên liệu Cascade X", "Nguyên liệu Cascade Y"],
        ),
    )
    dish_id = dish.id

    # Đảm bảo đã có link
    links_before = db.scalars(select(DishIngredient).where(DishIngredient.dish_id == dish_id)).all()
    assert len(links_before) == 2

    # Xóa món ăn
    DishService.delete_dish(db, dish_id)

    # Kiểm tra liên kết đã biến mất
    links_after = db.scalars(select(DishIngredient).where(DishIngredient.dish_id == dish_id)).all()
    assert len(links_after) == 0

    # Nhưng nguyên liệu trong bảng ingredients vẫn còn nguyên
    ing_x = db.scalar(select(Ingredient).where(Ingredient.name == "Nguyên liệu Cascade X"))
    assert ing_x is not None


def test_filter_dishes_by_ingredient(db: Session, sample_restaurant: Restaurant):
    """Kiểm tra tìm kiếm/lọc món ăn theo tên nguyên liệu thông qua JOIN bảng quan hệ."""
    dish = DishService.create_dish(
        db,
        sample_restaurant.id,
        DishCreate(
            name="Món Lọc Nấm Truffle Độc Đáo",
            price=250000.0,
            ingredients=["Nấm Truffle Đen", "Sốt bơ tỏi"],
        ),
    )

    # Lọc theo nguyên liệu
    matched = DishService.get_dishes_by_restaurant(
        db,
        sample_restaurant.id,
        ingredient="Nấm Truffle Đen",
    )
    assert any(d.id == dish.id for d in matched)

    # Cleanup
    DishService.delete_dish(db, dish.id)
