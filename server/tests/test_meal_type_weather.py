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
    """Kiểm tra API lấy danh sách trạng thái thời tiết có trường mùa (season) từ 400 mẫu."""
    resp = client.get("/api/v1/weather")
    assert resp.status_code == 200
    data = resp.json()
    assert len(data) >= 400
    seasons = {w["season"] for w in data if w.get("season")}
    assert "spring" in seasons
    assert "summer" in seasons
    assert "autumn" in seasons
    assert "winter" in seasons
    codes = [w["code"] for w in data]
    assert any("SPRING_PATTERN" in c for c in codes)
    assert any("SUMMER_PATTERN" in c for c in codes)
    assert any("AUTUMN_PATTERN" in c for c in codes)
    assert any("WINTER_PATTERN" in c for c in codes)


def test_create_custom_weather(client: TestClient):
    """Kiểm tra API tạo thêm điều kiện thời tiết mới kèm trường mùa (season)."""
    payload = {
        "code": "stormy",
        "name": "Bão to gió lớn",
        "description": "Mưa bão lớn, khuyến khích đặt ship tại nhà",
        "temperature": 21.0,
        "humidity": 80.0,
        "condition": "storm",
        "icon": "weather-lightning",
        "season": "rainy",
        "sort_order": 5,
        "is_active": True,
    }
    resp = client.post("/api/v1/weather", json=payload)
    assert resp.status_code == 201
    created = resp.json()
    assert created["id"] > 0
    assert created["code"] == "stormy"
    assert created["season"] == "rainy"


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


def test_update_and_delete_weather(client: TestClient):
    """Kiểm tra cập nhật và xoá trạng thái thời tiết."""
    # 1. Tạo thời tiết tạm
    create_resp = client.post(
        "/api/v1/weather",
        json={
            "code": "test_foggy",
            "name": "Sương mù dày đặc",
            "description": "Tầm nhìn hạn chế",
            "temperature": 15.0,
            "humidity": 85.0,
            "season": "winter",
        },
    )
    assert create_resp.status_code == 201
    w_id = create_resp.json()["id"]

    # 2. Cập nhật thông tin
    update_resp = client.put(
        f"/api/v1/weather/{w_id}",
        json={
            "name": "Sương mù buổi sáng",
            "description": "Sương mù kèm se lạnh",
            "temperature": 16.0,
            "humidity": 80.0,
            "season": "spring",
        },
    )
    assert update_resp.status_code == 200
    updated_data = update_resp.json()
    assert updated_data["name"] == "Sương mù buổi sáng"
    assert updated_data["temperature"] == 16.0
    assert updated_data["humidity"] == 80.0
    assert updated_data["season"] == "spring"

    # 3. Thử cập nhật temperature ngoài khoảng -50..60 -> 400
    bad_resp = client.put(
        f"/api/v1/weather/{w_id}",
        json={"temperature": 100.0},
    )
    assert bad_resp.status_code in (400, 422)

    # 4. Xoá thời tiết
    del_resp = client.delete(f"/api/v1/weather/{w_id}")
    assert del_resp.status_code == 200

    # 5. Kiểm tra không còn tồn tại -> 404
    get_resp = client.get(f"/api/v1/weather/{w_id}")
    assert get_resp.status_code == 404
