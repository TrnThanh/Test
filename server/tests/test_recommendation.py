import re
import pytest
from fastapi.testclient import TestClient
from server.app.main import app
from server.app.db.session import SessionLocal
from server.app.models.user import User
from server.app.models.dish import Dish
from server.app.models.restaurant import Restaurant
from server.app.models.option_user import OptionUser


@pytest.fixture(scope="module")
def client():
    with TestClient(app) as c:
        yield c


def test_contextual_recommendations_guest(client):
    """Kiểm tra gợi ý chế độ khách vãng lai (không có user_id)."""
    res = client.get("/api/v1/recommendations/contextual?lat=21.0062&lon=105.9325&temp=25.0&weather_code=mild")
    assert res.status_code == 200
    data = res.json()
    assert "context" in data
    assert "disclaimer" in data["context"]
    assert data["context"]["guest_notice"] is not None
    assert "recommended_restaurants" in data
    assert isinstance(data["recommended_restaurants"], list)
    if data["hero_restaurant"]:
        assert "recommendation" in data["hero_restaurant"]
        assert "featured_dish" in data["hero_restaurant"]["recommendation"]
        assert data["hero_restaurant"]["recommendation"]["score"] <= 100.0


def test_contextual_recommendations_with_user_and_allergies(client):
    """Kiểm tra gợi ý cho user có khai báo dị ứng Hải sản."""
    db = SessionLocal()
    user = db.query(User).filter(User.email == "test_allergy@ptc1.vn").first()
    if not user:
        user = User(
            email="test_allergy@ptc1.vn",
            hashed_password="hash",
            full_name="User Dị Ứng",
            height_cm=170.0,
            weight_kg=65.0,
            gender="male",
            birth_year=1995,
            activity_level="moderate",
            target_goal="maintain",
            allergies=["Hải sản"],
            spicy_tolerance="mild",
        )
        db.add(user)
        db.commit()
        db.refresh(user)
    else:
        user.allergies = ["Hải sản"]
        db.commit()
        db.refresh(user)

    uid = user.id
    db.close()

    res = client.get(f"/api/v1/recommendations/contextual?lat=21.0062&lon=105.9325&user_id={uid}&temp=25.0&weather_code=mild")
    assert res.status_code == 200
    data = res.json()
    assert data["context"]["guest_notice"] is None

    # Đảm bảo không có món hải sản nào bị lọt
    all_dishes = []
    if data["hero_restaurant"]:
        all_dishes.append(data["hero_restaurant"]["recommendation"]["featured_dish"]["name"].lower())
    for r in data["recommended_restaurants"]:
        all_dishes.append(r["recommendation"]["featured_dish"]["name"].lower())

    for dname in all_dishes:
        for kw in [r"\btôm\b", r"\bcua\b", r"\bmực\b", r"\bốc\b", r"\bcá\b", r"\bmắm tôm\b"]:
            assert not re.search(kw, dname, re.IGNORECASE), f"Món dị ứng bị rò rỉ: {dname}"


def test_contextual_recommendations_hero_not_duplicated(client):
    """Kiểm tra Hero Restaurant không bao giờ bị lặp lại trong danh sách recommended_restaurants."""
    res = client.get("/api/v1/recommendations/contextual?lat=21.0062&lon=105.9325&seed=123")
    assert res.status_code == 200
    data = res.json()
    if data["hero_restaurant"]:
        hero_id = data["hero_restaurant"]["id"]
        rec_ids = [r["id"] for r in data["recommended_restaurants"]]
        assert hero_id not in rec_ids, f"Hero restaurant {hero_id} bị lặp lại trong danh sách đề xuất!"
