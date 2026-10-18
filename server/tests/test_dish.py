import pytest
from fastapi import status
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session
from sqlalchemy import select

from server.app.models.user import User
from server.app.models.seller import Seller
from server.app.models.restaurant import Restaurant
from server.app.models.dish import Dish
from server.app.models.favourite_dish import FavouriteDish
from server.app.core.security import hash_password


@pytest.fixture
def test_seller(db_session: Session) -> Seller:
    seller = Seller(
        email="dish_seller@example.com",
        hashed_password=hash_password("123456"),
        shop_name="Quán Phở Gia Truyền",
        is_active=True,
    )
    db_session.add(seller)
    db_session.commit()
    db_session.refresh(seller)
    return seller


@pytest.fixture
def other_seller(db_session: Session) -> Seller:
    seller = Seller(
        email="other_seller@example.com",
        hashed_password=hash_password("123456"),
        shop_name="Quán Khác",
        is_active=True,
    )
    db_session.add(seller)
    db_session.commit()
    db_session.refresh(seller)
    return seller


@pytest.fixture
def test_restaurant(db_session: Session, test_seller: Seller) -> Restaurant:
    restaurant = Restaurant(
        seller_id=test_seller.id,
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


def test_create_dish_with_category_meal_type_tags(
    client: TestClient, test_seller: Seller, test_restaurant: Restaurant
):
    """Kiểm tra tạo món ăn mới có category, meal_type và tags mảng chuỗi."""
    payload = {
        "name": "Phở Bò Tái Lăn",
        "price": 65000.0,
        "description": "Thịt bò tươi xào lăn đậm đà, nước dùng thơm ngọt.",
        "category": "Món chính",
        "meal_type": "breakfast",
        "tags": ["bestseller", "signature", "nóng"],
    }
    response = client.post(
        f"/api/v1/restaurants/{test_restaurant.id}/dishes?seller_id={test_seller.id}",
        json=payload,
    )
    assert response.status_code == status.HTTP_201_CREATED
    data = response.json()
    assert data["name"] == "Phở Bò Tái Lăn"
    assert data["price"] == 65000.0
    assert data["category"] == "Món chính"
    assert data["meal_type"] == "breakfast"
    assert "bestseller" in data["tags"]
    assert "signature" in data["tags"]
    assert data["restaurant_id"] == test_restaurant.id
    assert data["is_available"] is True


def test_create_dish_ownership_forbidden(
    client: TestClient, other_seller: Seller, test_restaurant: Restaurant
):
    """Kiểm tra Seller khác không được phép thêm món vào quán không thuộc sở hữu (403 Forbidden)."""
    payload = {
        "name": "Món Hack Quán",
        "price": 50000.0,
    }
    response = client.post(
        f"/api/v1/restaurants/{test_restaurant.id}/dishes?seller_id={other_seller.id}",
        json=payload,
    )
    assert response.status_code == status.HTTP_403_FORBIDDEN


def test_filter_dishes_by_category_meal_type_and_tag(
    client: TestClient, test_seller: Seller, test_restaurant: Restaurant
):
    """Kiểm tra tra cứu và lọc món ăn theo category, meal_type và tag."""
    # Tạo 3 món ăn với đặc tính khác nhau
    dishes = [
        {
            "name": "Phở Tái Bắp",
            "price": 60000.0,
            "category": "Món chính",
            "meal_type": "breakfast",
            "tags": ["signature", "bò"],
        },
        {
            "name": "Cơm Rang Dưa Bò",
            "price": 55000.0,
            "category": "Món chính",
            "meal_type": "lunch",
            "tags": ["no_lau", "bestseller"],
        },
        {
            "name": "Trà Chanh Hoa Nhài",
            "price": 20000.0,
            "category": "Đồ uống",
            "meal_type": "all_day",
            "tags": ["giải khát", "signature"],
        },
    ]
    for d in dishes:
        resp = client.post(
            f"/api/v1/restaurants/{test_restaurant.id}/dishes?seller_id={test_seller.id}",
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

    # 2. Lọc theo meal_type = "breakfast" (nhận cả breakfast và all_day)
    res_meal = client.get(
        f"/api/v1/restaurants/{test_restaurant.id}/dishes",
        params={"meal_type": "breakfast"},
    )
    assert res_meal.status_code == status.HTTP_200_OK
    items_meal = res_meal.json()
    assert len(items_meal) == 2  # Phở Tái Bắp và Trà Chanh (all_day)

    # 3. Lọc theo tag = "signature" (sử dụng toán tử PostgreSQL ARRAY @>)
    res_tag = client.get(
        f"/api/v1/restaurants/{test_restaurant.id}/dishes",
        params={"tag": "signature"},
    )
    assert res_tag.status_code == status.HTTP_200_OK
    items_tag = res_tag.json()
    assert len(items_tag) == 2


def test_get_distinct_dish_categories(
    client: TestClient, test_seller: Seller, test_restaurant: Restaurant
):
    """Kiểm tra lấy danh sách các nhóm món (category) duy nhất của quán để autocomplete."""
    client.post(
        f"/api/v1/restaurants/{test_restaurant.id}/dishes?seller_id={test_seller.id}",
        json={"name": "Món 1", "price": 10000.0, "category": "Món khai vị"},
    )
    client.post(
        f"/api/v1/restaurants/{test_restaurant.id}/dishes?seller_id={test_seller.id}",
        json={"name": "Món 2", "price": 20000.0, "category": "Món chính"},
    )
    client.post(
        f"/api/v1/restaurants/{test_restaurant.id}/dishes?seller_id={test_seller.id}",
        json={"name": "Món 3", "price": 30000.0, "category": "Món chính"},
    )

    response = client.get(f"/api/v1/restaurants/{test_restaurant.id}/dish-categories")
    assert response.status_code == status.HTTP_200_OK
    cats = response.json()
    assert "Món khai vị" in cats
    assert "Món chính" in cats
    assert len(cats) == 2


def test_update_and_delete_dish(
    client: TestClient, test_seller: Seller, other_seller: Seller, test_restaurant: Restaurant
):
    """Kiểm tra cập nhật và xoá món ăn, kèm kiểm tra bảo mật."""
    create_res = client.post(
        f"/api/v1/restaurants/{test_restaurant.id}/dishes?seller_id={test_seller.id}",
        json={"name": "Món Cần Sửa", "price": 40000.0, "category": "Món cũ"},
    )
    dish_id = create_res.json()["id"]

    # Seller khác cố sửa -> 403
    forbidden_update = client.put(
        f"/api/v1/dishes/{dish_id}?seller_id={other_seller.id}",
        json={"price": 50000.0},
    )
    assert forbidden_update.status_code == status.HTTP_403_FORBIDDEN

    # Chủ sở hữu sửa thành công
    success_update = client.put(
        f"/api/v1/dishes/{dish_id}?seller_id={test_seller.id}",
        json={"name": "Món Đã Sửa", "price": 45000.0, "tags": ["mới", "ngon"]},
    )
    assert success_update.status_code == status.HTTP_200_OK
    assert success_update.json()["name"] == "Món Đã Sửa"
    assert success_update.json()["price"] == 45000.0
    assert success_update.json()["tags"] == ["mới", "ngon"]

    # Xoá món ăn
    del_res = client.delete(f"/api/v1/dishes/{dish_id}?seller_id={test_seller.id}")
    assert del_res.status_code == status.HTTP_200_OK

    # Xem lại sau xoá -> 404
    get_del = client.get(f"/api/v1/dishes/{dish_id}")
    assert get_del.status_code == status.HTTP_404_NOT_FOUND


def test_dish_validation_errors(
    client: TestClient, test_seller: Seller, test_restaurant: Restaurant
):
    """Kiểm tra bắt lỗi validate khi truyền meal_type hoặc price không hợp lệ."""
    # 1. meal_type không nằm trong danh sách cho phép
    err_meal = client.post(
        f"/api/v1/restaurants/{test_restaurant.id}/dishes?seller_id={test_seller.id}",
        json={"name": "Món Lỗi Bữa Ăn", "price": 50000.0, "meal_type": "midnight_snack"},
    )
    assert err_meal.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY

    # 2. price âm
    err_price = client.post(
        f"/api/v1/restaurants/{test_restaurant.id}/dishes?seller_id={test_seller.id}",
        json={"name": "Món Giá Âm", "price": -1000.0},
    )
    assert err_price.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY


def test_favourite_dishes_without_tag(
    client: TestClient, test_seller: Seller, test_restaurant: Restaurant, test_user: User
):
    """Kiểm tra lưu món yêu thích không còn trường tag (Junction Table thuần tuý)."""
    create_dish = client.post(
        f"/api/v1/restaurants/{test_restaurant.id}/dishes?seller_id={test_seller.id}",
        json={"name": "Bún Bò Huế Yêu Thích", "price": 50000.0, "tags": ["cay", "đặc biệt"]},
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
    db_session: Session, test_seller: Seller, test_user: User
):
    """Kiểm tra khi xoá quán ăn, toàn bộ món ăn và bản ghi yêu thích tự động xoá theo (Cascade delete)."""
    restaurant = Restaurant(
        seller_id=test_seller.id,
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
