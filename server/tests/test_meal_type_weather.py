from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from server.app.models.meal_type import MealType
from server.app.models.weather import Weather


def test_get_meal_types_list(client: TestClient):
    """Kiểm tra API lấy danh sách các loại bữa ăn đã seed mặc định."""
    resp = client.get("/api/v1/meal-types")
    assert resp.status_code == 200
    data = resp.json()
    assert len(data) >= 5
    codes = [item["code"] for item in data]
    assert "breakfast" in codes
    assert "lunch" in codes
    assert "dinner" in codes
    assert "snack" in codes
    assert "all_day" in codes


def test_create_custom_meal_type(client: TestClient):
    """Kiểm tra API tạo thêm loại bữa ăn mới."""
    payload = {
        "code": "midnight_snack",
        "name": "Bữa đêm / Khuya",
        "description": "Các món ăn ấm bụng sau 22h đêm",
        "start_time": "22:00:00",
        "end_time": "03:00:00",
        "sort_order": 10,
        "is_active": True,
    }
    resp = client.post("/api/v1/meal-types", json=payload)
    assert resp.status_code == 201
    created = resp.json()
    assert created["id"] > 0
    assert created["code"] == "midnight_snack"
    assert created["name"] == "Bữa đêm / Khuya"

    # Thử tạo trùng mã -> 409 Conflict
    resp_dup = client.post("/api/v1/meal-types", json=payload)
    assert resp_dup.status_code == 409


def test_get_weather_list(client: TestClient):
    """Kiểm tra API lấy danh sách trạng thái thời tiết."""
    resp = client.get("/api/v1/weather")
    assert resp.status_code == 200
    data = resp.json()
    assert len(data) >= 4
    codes = [w["code"] for w in data]
    assert "hot" in codes
    assert "rainy" in codes
    assert "cold" in codes
    assert "mild" in codes


def test_create_custom_weather(client: TestClient):
    """Kiểm tra API tạo thêm điều kiện thời tiết mới."""
    payload = {
        "code": "stormy",
        "name": "Bão to gió lớn",
        "description": "Mưa bão lớn, khuyến khích đặt ship tại nhà",
        "min_temp": 18.0,
        "max_temp": 24.0,
        "condition": "storm",
        "icon": "weather-lightning",
        "sort_order": 5,
        "is_active": True,
    }
    resp = client.post("/api/v1/weather", json=payload)
    assert resp.status_code == 201
    created = resp.json()
    assert created["id"] > 0
    assert created["code"] == "stormy"


def test_create_dish_with_ingredients_and_meal_type_id(
    client: TestClient,
    db_session: Session,
):
    """Kiểm tra tạo món ăn có trường ingredients và liên kết meal_type_id."""
    # 1. Tạo quán ăn
    res_resp = client.post(
        "/api/v1/restaurants",
        json={
            "name": "Bún Bò Huế O Oanh",
            "address": "123 Lê Lợi, Huế",
            "latitude": 16.4637,
            "longitude": 107.5909,
        },
    )
    assert res_resp.status_code == 201
    restaurant_id = res_resp.json()["id"]

    # 2. Lấy ID của bữa sáng
    meal_resp = client.get("/api/v1/meal-types")
    breakfast_id = next(item["id"] for item in meal_resp.json() if item["code"] == "breakfast")

    # 3. Tạo món ăn với ingredients và meal_types
    dish_payload = {
        "name": "Bún Bò Giò Heo Đặc Biệt",
        "price": 55000.0,
        "description": "Nước dùng đậm đà hương sả ruốc",
        "meal_types": ["breakfast"],
        "ingredients": ["Thịt bắp bò", "Giò heo", "Chả cua", "Bún tươi", "Hành hoa", "Rau sống"],
        "is_available": True,
    }
    dish_resp = client.post(
        f"/api/v1/restaurants/{restaurant_id}/dishes",
        json=dish_payload,
    )
    assert dish_resp.status_code == 201
    dish_data = dish_resp.json()
    assert dish_data["name"] == "Bún Bò Giò Heo Đặc Biệt"
    assert "breakfast" in dish_data["meal_types"]
    assert len(dish_data["ingredients"]) == 6
    assert "Thịt bắp bò" in dish_data["ingredients"]

    # 4. Kiểm tra lọc món ăn theo meal_type và ingredient
    filter_resp = client.get(
        f"/api/v1/restaurants/{restaurant_id}/dishes",
        params={"meal_type": "breakfast", "ingredient": "Giò heo"},
    )
    assert filter_resp.status_code == 200
    matched_dishes = filter_resp.json()
    assert len(matched_dishes) == 1
    assert matched_dishes[0]["id"] == dish_data["id"]

    # Lọc với nguyên liệu không có -> kết quả rỗng
    filter_empty = client.get(
        f"/api/v1/restaurants/{restaurant_id}/dishes",
        params={"ingredient": "Thịt cừu"},
    )
    assert filter_empty.status_code == 200
    assert len(filter_empty.json()) == 0
