import pytest
from fastapi import status
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session
from sqlalchemy import select

from server.app.models.user import User
from server.app.models.restaurant import Restaurant
from server.app.models.dish import Dish
from server.app.models.favourite_dish import FavouriteDish
from server.app.core.security import hash_password


@pytest.fixture
def test_restaurant(db_session: Session) -> Restaurant:
    restaurant = Restaurant(
        name="Phở Gia Truyền Bát Đàn",
        address="49 Bát Đàn, Hà Nội",
        latitude=21.0335,
        longitude=105.8471,
    )
    db_session.add(restaurant)
    db_session.commit()
    db_session.refresh(restaurant)
    return restaurant


@pytest.fixture
def test_user(db_session: Session) -> User:
    user = User(
        email="foodie@example.com",
        hashed_password=hash_password("123456"),
        full_name="Nguyễn Văn Thực Khách",
        is_active=True,
    )
    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)
    return user


def test_create_dish_with_category_meal_type_and_ingredients(
    client: TestClient, test_restaurant: Restaurant
):
    """Kiểm tra tạo món ăn mới có category, spicy_level, dietary_tags, meal_types, allergens và ingredients."""
    payload = {
        "name": "Phở Bò Tái Lăn",
        "price": 65000.0,
        "description": "Thịt bò tươi xào lăn đậm đà, nước dùng thơm ngọt.",
        "category": "Món chính",
        "spicy_level": 1,
        "dietary_tags": ["halal"],
        "meal_types": ["breakfast", "lunch"],
        "allergens": ["peanut"],
        "ingredients": ["Thịt bò tươi", "Bánh phở", "Hành hoa"],
    }
    response = client.post(
        f"/api/v1/restaurants/{test_restaurant.id}/dishes",
        json=payload,
    )
    assert response.status_code == status.HTTP_201_CREATED
    data = response.json()
    assert data["name"] == "Phở Bò Tái Lăn"
    assert data["price"] == 65000.0
    assert data["category"] == "Món chính"
    assert data["spicy_level"] == 1
    assert "halal" in data["dietary_tags"]
    assert "breakfast" in data["meal_types"]
    assert "lunch" in data["meal_types"]
    assert "peanut" in data["allergens"]
    assert "Thịt bò tươi" in data["ingredients"]
    assert "Bánh phở" in data["ingredients"]
    assert data["restaurant_id"] == test_restaurant.id
    assert data["is_available"] is True


def test_filter_dishes_by_category_and_meal_type(
    client: TestClient, test_restaurant: Restaurant
):
    """Kiểm tra tra cứu và lọc món ăn theo category, meal_type, spicy_level, dietary_tag, allergen."""
    # Tạo 3 món ăn với đặc tính khác nhau
    dishes = [
        {
            "name": "Phở Tái Bắp",
            "price": 60000.0,
            "category": "Món chính",
            "spicy_level": 1,
            "dietary_tags": ["halal"],
            "meal_types": ["breakfast"],
            "allergens": [],
            "ingredients": ["Thịt bò", "Bánh phở"],
        },
        {
            "name": "Cơm Rang Dưa Bò",
            "price": 55000.0,
            "category": "Món chính",
            "spicy_level": 0,
            "dietary_tags": [],
            "meal_types": ["lunch"],
            "allergens": ["seafood"],
            "ingredients": ["Cơm", "Dưa chua", "Thịt bò"],
        },
        {
            "name": "Trà Chanh Hoa Nhài",
            "price": 20000.0,
            "category": "Đồ uống",
            "spicy_level": 0,
            "dietary_tags": ["vegetarian", "vegan"],
            "meal_types": ["all_day"],
            "allergens": [],
            "ingredients": ["Trà xanh", "Chanh", "Hoa nhài"],
        },
    ]
    for d in dishes:
        resp = client.post(
            f"/api/v1/restaurants/{test_restaurant.id}/dishes",
            json=d,
        )
        assert resp.status_code == status.HTTP_201_CREATED

    # 1. Lọc theo category = "Đồ uống"
    res_cat = client.get(
        f"/api/v1/restaurants/{test_restaurant.id}/dishes",
        params={"category": "Đồ uống"},
    )
    assert res_cat.status_code == status.HTTP_200_OK
    items_cat = res_cat.json()
    assert len(items_cat) == 1
    assert items_cat[0]["name"] == "Trà Chanh Hoa Nhài"

    # 2. Lọc theo meal_type = "breakfast"
    res_meal = client.get(
        f"/api/v1/restaurants/{test_restaurant.id}/dishes",
        params={"meal_type": "breakfast"},
    )
    assert res_meal.status_code == status.HTTP_200_OK
    items_meal = res_meal.json()
    assert len(items_meal) == 1
    assert items_meal[0]["name"] == "Phở Tái Bắp"

    # 3. Lọc theo spicy_level = 1
    res_spicy = client.get(
        f"/api/v1/restaurants/{test_restaurant.id}/dishes",
        params={"spicy_level": 1},
    )
    assert res_spicy.status_code == status.HTTP_200_OK
    items_spicy = res_spicy.json()
    assert len(items_spicy) == 1
    assert items_spicy[0]["name"] == "Phở Tái Bắp"

    # 4. Lọc theo dietary_tag = "vegan"
    res_diet = client.get(
        f"/api/v1/restaurants/{test_restaurant.id}/dishes",
        params={"dietary_tag": "vegan"},
    )
    assert res_diet.status_code == status.HTTP_200_OK
    assert len(res_diet.json()) == 1
    assert res_diet.json()[0]["name"] == "Trà Chanh Hoa Nhài"

    # 5. Loại trừ dị ứng allergen = "seafood"
    res_allergen = client.get(
        f"/api/v1/restaurants/{test_restaurant.id}/dishes",
        params={"allergen": "seafood"},
    )
    assert res_allergen.status_code == status.HTTP_200_OK
    # Không được chứa "Cơm Rang Dưa Bò" (có seafood)
    names = [i["name"] for i in res_allergen.json()]
    assert "Cơm Rang Dưa Bò" not in names


def test_get_distinct_dish_categories(
    client: TestClient, test_restaurant: Restaurant
):
    """Kiểm tra lấy danh sách các nhóm món (category) duy nhất của quán để autocomplete."""
    client.post(
        f"/api/v1/restaurants/{test_restaurant.id}/dishes",
        json={"name": "Món 1", "price": 10000.0, "category": "Món khai vị"},
    )
    client.post(
        f"/api/v1/restaurants/{test_restaurant.id}/dishes",
        json={"name": "Món 2", "price": 20000.0, "category": "Món chính"},
    )
    client.post(
        f"/api/v1/restaurants/{test_restaurant.id}/dishes",
        json={"name": "Món 3", "price": 30000.0, "category": "Món chính"},
    )

    response = client.get(f"/api/v1/restaurants/{test_restaurant.id}/dish-categories")
    assert response.status_code == status.HTTP_200_OK
    cats = response.json()
    assert "Món khai vị" in cats
    assert "Món chính" in cats
    assert len(cats) == 2


def test_update_and_delete_dish(
    client: TestClient, test_restaurant: Restaurant
):
    """Kiểm tra cập nhật và xoá món ăn."""
    create_res = client.post(
        f"/api/v1/restaurants/{test_restaurant.id}/dishes",
        json={"name": "Món Cần Sửa", "price": 40000.0, "category": "Món cũ"},
    )
    dish_id = create_res.json()["id"]

    # Cập nhật món ăn
    success_update = client.put(
        f"/api/v1/dishes/{dish_id}",
        json={"name": "Món Đã Sửa", "price": 45000.0, "description": "Món ngon đặc biệt"},
    )
    assert success_update.status_code == status.HTTP_200_OK
    assert success_update.json()["name"] == "Món Đã Sửa"
    assert success_update.json()["price"] == 45000.0
    assert success_update.json()["description"] == "Món ngon đặc biệt"

    # Xoá món ăn
    del_res = client.delete(f"/api/v1/dishes/{dish_id}")
    assert del_res.status_code == status.HTTP_200_OK

    # Xem lại sau xoá -> 404
    get_del = client.get(f"/api/v1/dishes/{dish_id}")
    assert get_del.status_code == status.HTTP_404_NOT_FOUND


def test_dish_validation_errors(
    client: TestClient, test_restaurant: Restaurant
):
    """Kiểm tra bắt lỗi validate khi truyền spicy_level hoặc price không hợp lệ."""
    # 1. spicy_level ngoài khoảng 0..3
    err_spicy = client.post(
        f"/api/v1/restaurants/{test_restaurant.id}/dishes",
        json={"name": "Món Quá Cay", "price": 50000.0, "spicy_level": 5},
    )
    assert err_spicy.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY

    err_spicy_neg = client.post(
        f"/api/v1/restaurants/{test_restaurant.id}/dishes",
        json={"name": "Món Cay Âm", "price": 50000.0, "spicy_level": -1},
    )
    assert err_spicy_neg.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY

    # 2. price âm
    err_price = client.post(
        f"/api/v1/restaurants/{test_restaurant.id}/dishes",
        json={"name": "Món Giá Âm", "price": -1000.0},
    )
    assert err_price.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY


def test_favourite_dishes_without_tag(
    client: TestClient, test_restaurant: Restaurant, test_user: User
):
    """Kiểm tra lưu món yêu thích không còn trường tag (Junction Table thuần tuý)."""
    create_dish = client.post(
        f"/api/v1/restaurants/{test_restaurant.id}/dishes",
        json={"name": "Bún Bò Huế Yêu Thích", "price": 50000.0, "ingredients": ["Thịt bò", "Bún"]},
    )
    dish_id = create_dish.json()["id"]

    # 1. Thêm món vào yêu thích (không có tag)
    fav_res = client.post(f"/api/v1/users/{test_user.id}/favourites/{dish_id}")
    assert fav_res.status_code == status.HTTP_201_CREATED
    fav_data = fav_res.json()
    assert fav_data["user_id"] == test_user.id
    assert fav_data["dish_id"] == dish_id
    assert "tag" not in fav_data

    # 2. Kiểm tra tính Idempotent (nhấn yêu thích lại không sinh bản ghi trùng)
    fav_dup = client.post(f"/api/v1/users/{test_user.id}/favourites/{dish_id}")
    assert fav_dup.status_code == status.HTTP_201_CREATED
    assert fav_dup.json()["id"] == fav_data["id"]

    # 3. Lấy danh sách món yêu thích của người dùng
    list_fav = client.get(f"/api/v1/users/{test_user.id}/favourites")
    assert list_fav.status_code == status.HTTP_200_OK
    items = list_fav.json()
    assert len(items) == 1
    assert items[0]["dish"]["name"] == "Bún Bò Huế Yêu Thích"

    # 4. Bỏ yêu thích
    del_fav = client.delete(f"/api/v1/users/{test_user.id}/favourites/{dish_id}")
    assert del_fav.status_code == status.HTTP_200_OK

    list_after = client.get(f"/api/v1/users/{test_user.id}/favourites")
    assert list_after.json() == []


def test_cascade_delete_restaurant_deletes_dishes_and_favourites(
    db_session: Session, test_user: User
):
    """Kiểm tra khi xoá quán ăn, toàn bộ món ăn và bản ghi yêu thích tự động xoá theo (Cascade delete)."""
    restaurant = Restaurant(
        name="Quán Sắp Xoá",
        address="100 Phố Nhỏ",
        latitude=21.0,
        longitude=105.0,
    )
    db_session.add(restaurant)
    db_session.commit()
    db_session.refresh(restaurant)

    dish = Dish(
        restaurant_id=restaurant.id,
        name="Món Trong Quán Sắp Xoá",
        price=30000.0,
    )
    db_session.add(dish)
    db_session.commit()
    db_session.refresh(dish)

    fav = FavouriteDish(user_id=test_user.id, dish_id=dish.id)
    db_session.add(fav)
    db_session.commit()

    # Xoá quán
    db_session.delete(restaurant)
    db_session.commit()

    # Kiểm tra món ăn và favourite đều đã bị xoá
    dish_check = db_session.get(Dish, dish.id)
    assert dish_check is None

    fav_check = db_session.scalar(
        select(FavouriteDish).where(FavouriteDish.user_id == test_user.id, FavouriteDish.dish_id == dish.id)
    )
    assert fav_check is None
