import pytest
from fastapi.testclient import TestClient


def test_weather_create_with_temperature_and_humidity(client: TestClient):
    """Kiểm tra tạo trạng thái thời tiết có nhiệt độ và độ ẩm hợp lệ chuẩn theo JSON mới."""
    payload = {
        "code": "humid_rainy_new",
        "name": "Mưa nồm ẩm ướt chuẩn mới",
        "description": "Nhiệt độ 24°C, độ ẩm 85.5%",
        "temperature": 24.0,
        "humidity": 85.5,
        "condition": "rainy",
        "season": "spring",
    }
    resp = client.post("/api/v1/weather", json=payload)
    assert resp.status_code == 201, resp.text
    data = resp.json()
    assert data["code"] == "humid_rainy_new"
    assert data["temperature"] == 24.0
    assert data["humidity"] == 85.5


def test_weather_create_without_humidity_defaults_none(client: TestClient):
    """Kiểm tra tạo thời tiết không truyền độ ẩm thì độ ẩm mặc định là None (null)."""
    payload = {
        "code": "dry_breeze_new",
        "name": "Gió heo may khô ráo",
        "temperature": 22.5,
    }
    resp = client.post("/api/v1/weather", json=payload)
    assert resp.status_code == 201, resp.text
    data = resp.json()
    assert data["code"] == "dry_breeze_new"
    assert data["temperature"] == 22.5
    assert data["humidity"] is None


def test_weather_update_temperature_and_humidity(client: TestClient):
    """Kiểm tra cập nhật nhiệt độ và độ ẩm cho một trạng thái thời tiết."""
    # Tạo trước 1 bản ghi
    create_resp = client.post(
        "/api/v1/weather",
        json={"code": "variable_weather_update", "name": "Thời tiết biến đổi"},
    )
    assert create_resp.status_code == 201
    w_id = create_resp.json()["id"]

    # Cập nhật nhiệt độ 28°C và độ ẩm 75%
    update_resp = client.put(f"/api/v1/weather/{w_id}", json={"temperature": 28.0, "humidity": 75.0})
    assert update_resp.status_code == 200, update_resp.text
    assert update_resp.json()["temperature"] == 28.0
    assert update_resp.json()["humidity"] == 75.0

    # Cập nhật đưa về null
    update_null = client.put(f"/api/v1/weather/{w_id}", json={"temperature": None, "humidity": None})
    assert update_null.status_code == 200
    assert update_null.json()["temperature"] is None
    assert update_null.json()["humidity"] is None


def test_weather_humidity_boundary_values(client: TestClient):
    """Kiểm tra các giá trị biên của độ ẩm (0% và 100%) và nhiệt độ (-50°C và 60°C)."""
    resp_bound = client.post(
        "/api/v1/weather",
        json={"code": "weather_bound_test", "name": "Biên nhiệt ẩm", "temperature": -50.0, "humidity": 0.0},
    )
    assert resp_bound.status_code == 201
    assert resp_bound.json()["temperature"] == -50.0
    assert resp_bound.json()["humidity"] == 0.0

    resp_bound2 = client.post(
        "/api/v1/weather",
        json={"code": "weather_bound_max", "name": "Biên tối đa", "temperature": 60.0, "humidity": 100.0},
    )
    assert resp_bound2.status_code == 201
    assert resp_bound2.json()["temperature"] == 60.0
    assert resp_bound2.json()["humidity"] == 100.0


def test_weather_temperature_out_of_range_fails(client: TestClient):
    """Kiểm tra nhiệt độ ngoài dải -50 đến 60 bị từ chối với lỗi 422."""
    resp_too_low = client.post(
        "/api/v1/weather",
        json={"code": "temp_too_low", "name": "Quá lạnh", "temperature": -60.0},
    )
    assert resp_too_low.status_code == 422

    resp_too_high = client.post(
        "/api/v1/weather",
        json={"code": "temp_too_high", "name": "Quá nóng", "temperature": 70.0},
    )
    assert resp_too_high.status_code == 422


def test_weather_humidity_out_of_range_values(client: TestClient):
    """Kiểm tra giá trị độ ẩm ngoài khoảng 0-100 bị chặn với mã 422."""
    # Độ ẩm âm
    resp_neg = client.post(
        "/api/v1/weather",
        json={"code": "humidity_neg", "name": "Độ ẩm âm", "humidity": -5.0},
    )
    assert resp_neg.status_code == 422

    # Độ ẩm vượt quá 100%
    resp_over = client.post(
        "/api/v1/weather",
        json={"code": "humidity_over_100", "name": "Độ ẩm vượt 100%", "humidity": 105.0},
    )
    assert resp_over.status_code == 422


def test_weather_create_with_hourly_data(client: TestClient):
    """Kiểm tra tạo thời tiết kèm dữ liệu 24 giờ hourly JSON array."""
    hourly_sample = [
        {"hour": h, "temperature": 20.0 + h * 0.2, "humidity": 70.0, "precipitation": 0.0, "weather_code": 0, "condition": "SUNNY", "icon": "sunny.svg"}
        for h in range(24)
    ]
    payload = {
        "code": "weather_with_hourly",
        "name": "Thời tiết đủ 24 giờ",
        "temperature": 22.0,
        "humidity": 70.0,
        "hourly": hourly_sample,
    }
    resp = client.post("/api/v1/weather", json=payload)
    assert resp.status_code == 201, resp.text
    data = resp.json()
    assert len(data["hourly"]) == 24
    assert data["hourly"][0]["hour"] == 0
    assert data["hourly"][23]["hour"] == 23
