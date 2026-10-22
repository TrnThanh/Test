import pytest
from fastapi import status
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from server.app.models.user import User
from server.app.models.restaurant import Restaurant
from server.app.models.category import Category
from server.app.models.option_user import OptionUser
from server.app.core.security import hash_password


@pytest.fixture
def test_user(db_session: Session) -> User:
    user = User(
        email="opt_test_user@example.com",
        hashed_password=hash_password("123456"),
        full_name="Người Dùng Test Option",
        is_active=True,
    )
    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)
    return user


@pytest.fixture
def test_restaurant(db_session: Session) -> Restaurant:
    restaurant = Restaurant(
        name="Nhà Hàng Test Option",
        address="123 Đường Test, Quận 1, TP.HCM",
        latitude=10.7769,
        longitude=106.7009,
    )
    db_session.add(restaurant)
    db_session.commit()
    db_session.refresh(restaurant)
    return restaurant


@pytest.fixture
def test_category(db_session: Session) -> Category:
    cat = Category(
        name="Hải sản cay",
        description="Các món hải sản nhiều ớt",
    )
    db_session.add(cat)
    db_session.commit()
    db_session.refresh(cat)
    return cat


def test_create_and_get_user_option(
    client: TestClient, test_user: User, test_category: Category
):
    """Kiểm tra tạo tùy chọn ẩn danh mục cho user và truy vấn lại danh sách."""
    payload = {
        "category_id": test_category.id,
        "hide": True,
    }
    response = client.post(f"/api/v1/users/{test_user.id}/options", json=payload)
    assert response.status_code == status.HTTP_201_CREATED
    data = response.json()
    assert data["user_id"] == test_user.id
    assert data["category_id"] == test_category.id
    assert data["hide"] is True
    assert "id" in data

    # Lấy danh sách options của user
    get_res = client.get(f"/api/v1/users/{test_user.id}/options")
    assert get_res.status_code == status.HTTP_200_OK
    items = get_res.json()
    assert len(items) == 1
    assert items[0]["category_id"] == test_category.id
    assert items[0]["hide"] is True


def test_update_existing_category_option(
    client: TestClient, test_user: User, test_category: Category
):
    """Kiểm tra nếu đã tạo option cho category thì gọi lại POST sẽ cập nhật trạng thái hide."""
    # 1. Ẩn danh mục
    client.post(
        f"/api/v1/users/{test_user.id}/options",
        json={"category_id": test_category.id, "hide": True},
    )

    # 2. Bỏ ẩn danh mục (hide = False)
    res_update = client.post(
        f"/api/v1/users/{test_user.id}/options",
        json={"category_id": test_category.id, "hide": False},
    )
    assert res_update.status_code == status.HTTP_201_CREATED
    assert res_update.json()["hide"] is False

    # 3. Lấy lại danh sách xác nhận chỉ có 1 bản ghi duy nhất
    get_res = client.get(f"/api/v1/users/{test_user.id}/options")
    items = get_res.json()
    assert len(items) == 1
    assert items[0]["hide"] is False


def test_delete_user_option(
    client: TestClient, test_user: User, test_category: Category
):
    """Kiểm tra xoá tùy chọn danh mục của user."""
    create_res = client.post(
        f"/api/v1/users/{test_user.id}/options",
        json={"category_id": test_category.id, "hide": True},
    )
    option_id = create_res.json()["id"]

    # Xoá option
    del_res = client.delete(f"/api/v1/users/{test_user.id}/options/{option_id}")
    assert del_res.status_code == status.HTTP_204_NO_CONTENT

    # Kiểm tra danh sách sau xoá rỗng
    get_res = client.get(f"/api/v1/users/{test_user.id}/options")
    assert len(get_res.json()) == 0


def test_cascade_delete_category_deletes_options(
    client: TestClient, test_user: User, test_category: Category, db_session: Session
):
    """Kiểm tra khi quán xoá category thì option_users tương ứng tự động xoá theo cascade."""
    client.post(
        f"/api/v1/users/{test_user.id}/options",
        json={"category_id": test_category.id, "hide": True},
    )
    opt = db_session.query(OptionUser).filter_by(category_id=test_category.id).first()
    assert opt is not None

    # Xoá category
    db_session.delete(test_category)
    db_session.commit()

    # Kiểm tra option đã bị cascade delete
    opt_after = db_session.query(OptionUser).filter_by(category_id=test_category.id).first()
    assert opt_after is None
