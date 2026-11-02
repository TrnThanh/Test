import pytest
from fastapi import status
from fastapi.testclient import TestClient
from sqlalchemy import select
from sqlalchemy.orm import Session

from server.app.models.user import User
from server.app.models.restaurant import Restaurant
from server.app.models.category import Category
from server.app.core.security import hash_password


@pytest.fixture
def test_user(db_session: Session) -> User:
    user = User(
        email="profile_tester@example.com",
        hashed_password=hash_password("Password123"),
        full_name="Nguyễn Văn Thực Khách",
    )
    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)
    return user


@pytest.fixture
def test_category(db_session: Session) -> Category:
    restaurant = Restaurant(
        name="Quán Cơm Mẹ Nấu",
        address="10 Phố Ẩm Thực, Hà Nội",
        latitude=21.0285,
        longitude=105.8542,
    )
    db_session.add(restaurant)
    db_session.commit()
    db_session.refresh(restaurant)

    category = Category(
        name="Món Nướng & Lẩu",
        description="Đồ nướng và lẩu gia đình",
    )
    db_session.add(category)
    db_session.commit()
    db_session.refresh(category)
    return category


def test_get_or_create_profile_default(client: TestClient, test_user: User):
    """Kiểm tra truy vấn profile lần đầu tiên: trả về giá trị mặc định từ bảng users."""
    response = client.get(f"/api/v1/users/{test_user.id}/profile")
    assert response.status_code == status.HTTP_200_OK
    data = response.json()
    assert data["user_id"] == test_user.id
    assert data["is_onboarded"] is False
    assert data["onboarded_at"] is None
    assert data["height_cm"] is None
    assert data["weight_kg"] is None
    assert data["bmi"] is None
    assert data["bmi_category"] is None
    assert data["favorite_category_ids"] == []
    assert data["dietary_preferences"] == []
    assert data["allergies"] == []


def test_update_profile_physical_and_bmi(client: TestClient, test_user: User):
    """Kiểm tra cập nhật chỉ số thể chất trực tiếp trên User và tính toán BMI tự động."""
    payload = {
        "height_cm": 175.0,
        "weight_kg": 70.0,
        "gender": "male",
        "birth_year": 1998,
        "activity_level": "moderate",
        "target_goal": "maintain",
    }
    response = client.put(f"/api/v1/users/{test_user.id}/profile", json=payload)
    assert response.status_code == status.HTTP_200_OK
    data = response.json()
    assert data["height_cm"] == 175.0
    assert data["weight_kg"] == 70.0
    assert data["gender"] == "male"
    assert data["birth_year"] == 1998
    assert data["activity_level"] == "moderate"
    assert data["target_goal"] == "maintain"
    # BMI = 70 / (1.75 * 1.75) = 22.857 -> 22.9 (normal)
    assert data["bmi"] == 22.9
    assert data["bmi_category"] == "normal"


def test_update_profile_preferences_and_onboarding(
    client: TestClient, test_user: User, test_category: Category
):
    """Kiểm tra cập nhật sở thích món ăn, dị ứng, khẩu vị cay và hoàn thành onboarding trực tiếp trên User."""
    payload = {
        "favorite_category_ids": [test_category.id],
        "dietary_preferences": ["healthy", "low_carb"],
        "spicy_tolerance": "medium",
        "allergies": ["peanut", "seafood"],
        "budget_range": "moderate",
        "complete_onboarding": True,
    }
    response = client.put(f"/api/v1/users/{test_user.id}/profile", json=payload)
    assert response.status_code == status.HTTP_200_OK
    data = response.json()
    assert data["favorite_category_ids"] == [test_category.id]
    assert data["dietary_preferences"] == ["healthy", "low_carb"]
    assert data["spicy_tolerance"] == "medium"
    assert data["allergies"] == ["peanut", "seafood"]
    assert data["budget_range"] == "moderate"
    assert data["is_onboarded"] is True
    assert data["onboarded_at"] is not None


def test_get_profile_not_found(client: TestClient):
    """Kiểm tra mã lỗi 404 khi user_id không tồn tại trong hệ thống."""
    response = client.get("/api/v1/users/999999/profile")
    assert response.status_code == status.HTTP_404_NOT_FOUND


def test_validation_constraints(client: TestClient, test_user: User):
    """Kiểm tra validate dữ liệu chiều cao/cân nặng/gender ngoài phạm vi cho phép."""
    # Chiều cao quá bé (< 50cm)
    res1 = client.put(f"/api/v1/users/{test_user.id}/profile", json={"height_cm": 30.0})
    assert res1.status_code == status.HTTP_422_UNPROCESSABLE_CONTENT

    # Giới tính không thuộc enum
    res2 = client.put(f"/api/v1/users/{test_user.id}/profile", json={"gender": "invalid_gender"})
    assert res2.status_code == status.HTTP_422_UNPROCESSABLE_CONTENT


def test_delete_user_cleans_up_data(
    client: TestClient, db_session: Session, test_user: User
):
    """Kiểm tra khi xóa User thì toàn bộ dữ liệu người dùng và hồ sơ được dọn dẹp sạch sẽ."""
    user_id = test_user.id
    # Cập nhật thông tin trước
    client.put(f"/api/v1/users/{user_id}/profile", json={"height_cm": 170.0, "weight_kg": 65.0})

    # Xóa user khỏi cơ sở dữ liệu
    db_session.delete(test_user)
    db_session.commit()

    # Truy vấn lại endpoint profile phải trả về 404
    res = client.get(f"/api/v1/users/{user_id}/profile")
    assert res.status_code == status.HTTP_404_NOT_FOUND
    assert db_session.get(User, user_id) is None
