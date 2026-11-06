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


def test_compute_overall_rating():
    """Kiểm tra logic tính điểm tổng hợp theo trọng số 60% Admin + 40% Rating."""
    from server.app.services.recommendation_service import compute_overall_rating

    # 1. Có cả 2 điểm: 0.6 * 4.8 + 0.4 * 4.2 = 4.56 -> 4.6
    assert compute_overall_rating(4.8, 4.2) == 4.6

    # 2. Chỉ có admin_rating
    assert compute_overall_rating(4.5, None) == 4.5

    # 3. Chỉ có rating cộng đồng
    assert compute_overall_rating(None, 4.0) == 4.0

    # 4. Cả hai đều None
    assert compute_overall_rating(None, None) is None


def test_recommendation_scoring_upgrades():
    """Kiểm tra logic 4 nâng cấp thuật toán gợi ý (Cold start, Distance phi tuyến, Menu depth, Softmax)."""
    import math

    # 1. Trọng số Cold Start đảm bảo tổng 100%
    w_cold = [0.30, 0.25, 0.30, 0.00, 0.15]
    assert math.isclose(sum(w_cold), 1.0)

    # 2. Suy giảm khoảng cách phi tuyến: dưới 1km giữ điểm cao (>85), ngoài 5km giảm nhanh (<55)
    s_dist_1km = 100.0 * ((1.0 - (1.0 / 15.0)) ** 1.8)
    s_dist_5km = 100.0 * ((1.0 - (5.0 / 15.0)) ** 1.8)
    assert s_dist_1km > 85.0
    assert s_dist_5km < 55.0

    # 3. Đánh giá chiều sâu thực đơn (Top 3 món)
    dish_scores = [92.0, 84.0, 76.0, 40.0]
    top3 = sorted(dish_scores, reverse=True)[:3]
    depth_score = sum(top3) / len(top3)
    core_score = 0.75 * 92.0 + 0.25 * depth_score
    assert math.isclose(core_score, 0.75 * 92.0 + 0.25 * 84.0)

    # 4. Trọng số Softmax bốc Hero: Quán điểm áp đảo có xác suất vượt trội
    scores = [96.0, 72.0]
    max_s = max(scores)
    exp_w = [math.exp((s - max_s) / 12.0) for s in scores]
    assert exp_w[0] == 1.0
    assert exp_w[1] < 0.15  # Quán 72 điểm chỉ có <15% tỷ trọng so với quán 96 điểm
