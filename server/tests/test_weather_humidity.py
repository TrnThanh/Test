import pytest
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session
from server.app.models.weather import Weather


def test_weather_create_with_min_max_humidity(client: TestClient):
    """Kiểm tra tạo trạng thái thời tiết có khoảng độ ẩm (min_humidity, max_humidity) hợp lệ."""
    payload = {
        "code": "humid_rainy_range",
        "name": "Mưa nồm ẩm ướt dải rộng",
        "description": "Độ ẩm cao dao động 70% đến 95%",
        "min_temp": 20.0,
        "max_temp": 28.0,
        "min_humidity": 70,
        "max_humidity": 95,
        "condition": "rainy",
        "season": "spring",
    }
    resp = client.post("/api/v1/weather", json=payload)
    assert resp.status_code == 201, resp.text
    data = resp.json()
    assert data["code"] == "humid_rainy_range"
    assert data["min_humidity"] == 70
    assert data["max_humidity"] == 95


def test_weather_create_without_humidity_defaults_none(client: TestClient):
    """Kiểm tra tạo thời tiết không truyền độ ẩm thì min và max mặc định là None (null)."""
    payload = {
        "code": "dry_breeze_range",
        "name": "Gió heo may khô ráo",
        "min_temp": 18.0,
        "max_temp": 25.0,
    }
    resp = client.post("/api/v1/weather", json=payload)
    assert resp.status_code == 201, resp.text
    data = resp.json()
    assert data["code"] == "dry_breeze_range"
    assert data["min_humidity"] is None
    assert data["max_humidity"] is None


def test_weather_update_min_max_humidity(client: TestClient):
    """Kiểm tra cập nhật khoảng độ ẩm cho một trạng thái thời tiết."""
    # Tạo trước 1 bản ghi
    create_resp = client.post(
        "/api/v1/weather",
        json={"code": "variable_humidity_range", "name": "Thời tiết biến đổi độ ẩm"},
    )
    assert create_resp.status_code == 201
    w_id = create_resp.json()["id"]

    # Cập nhật khoảng độ ẩm từ 50% đến 80%
    update_resp = client.put(f"/api/v1/weather/{w_id}", json={"min_humidity": 50, "max_humidity": 80})
    assert update_resp.status_code == 200, update_resp.text
    assert update_resp.json()["min_humidity"] == 50
    assert update_resp.json()["max_humidity"] == 80

    # Cập nhật đưa về null
    update_null = client.put(f"/api/v1/weather/{w_id}", json={"min_humidity": None, "max_humidity": None})
    assert update_null.status_code == 200
    assert update_null.json()["min_humidity"] is None
    assert update_null.json()["max_humidity"] is None


def test_weather_humidity_boundary_values(client: TestClient):
    """Kiểm tra các giá trị biên của khoảng độ ẩm (0% và 100%)."""
    resp_bound = client.post(
        "/api/v1/weather",
        json={"code": "humidity_bound_0_100", "name": "Độ ẩm 0% - 100%", "min_humidity": 0, "max_humidity": 100},
    )
    assert resp_bound.status_code == 201
    assert resp_bound.json()["min_humidity"] == 0
    assert resp_bound.json()["max_humidity"] == 100


def test_weather_humidity_min_greater_than_max_fails(client: TestClient):
    """Kiểm tra độ ẩm tối thiểu lớn hơn độ ẩm tối đa bị từ chối với lỗi 400 Bad Request."""
    resp_inverted = client.post(
        "/api/v1/weather",
        json={"code": "humidity_inverted", "name": "Độ ẩm nghịch đảo", "min_humidity": 90, "max_humidity": 60},
    )
    assert resp_inverted.status_code == 400
    assert "Độ ẩm tối thiểu không được lớn hơn độ ẩm tối đa" in resp_inverted.text


def test_weather_humidity_out_of_range_values(client: TestClient):
    """Kiểm tra giá trị độ ẩm ngoài khoảng 0-100 bị chặn với mã 422."""
    # Độ ẩm âm
    resp_neg = client.post(
        "/api/v1/weather",
        json={"code": "humidity_neg", "name": "Độ ẩm âm", "min_humidity": -10, "max_humidity": 50},
    )
    assert resp_neg.status_code == 422

    # Độ ẩm vượt quá 100%
    resp_over = client.post(
        "/api/v1/weather",
        json={"code": "humidity_over_100", "name": "Độ ẩm vượt 100%", "min_humidity": 50, "max_humidity": 120},
    )
    assert resp_over.status_code == 422
