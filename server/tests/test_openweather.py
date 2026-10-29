import pytest
from unittest.mock import AsyncMock, patch, MagicMock
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session
import httpx

from server.app.core.config import settings
from server.app.models.restaurant import Restaurant
from server.app.models.category import Category
from server.app.models.weather import Weather
from server.app.services.weather_service import WeatherService
from server.app.services.weather_category_service import WeatherCategoryService


def test_weather_mapping_logic():
    """Kiểm tra logic ánh xạ điều kiện thực tế về 4 mã hệ thống (rainy, cold, hot, mild)."""
    # 1. Có mưa hoặc giông bão
    assert WeatherService.map_condition_to_code(temp=25.0, condition_main="Rain", description="mưa rào") == "rainy"
    assert WeatherService.map_condition_to_code(temp=28.0, condition_main="Thunderstorm", description="giông") == "rainy"
    assert WeatherService.map_condition_to_code(temp=22.0, condition_main="Clouds", description="có mưa phùn nhỏ") == "rainy"
    assert WeatherService.map_condition_to_code(temp=26.0, condition_main="Drizzle", weather_id=300) == "rainy"

    # 2. Trời lạnh (<= 18°C) hoặc tuyết
    assert WeatherService.map_condition_to_code(temp=14.5, condition_main="Clear", description="trời rét") == "cold"
    assert WeatherService.map_condition_to_code(temp=18.0, condition_main="Clouds", description="trời nhiều mây") == "cold"
    assert WeatherService.map_condition_to_code(temp=2.0, condition_main="Snow", weather_id=601) == "cold"

    # 3. Trời nắng nóng (>= 30°C)
    assert WeatherService.map_condition_to_code(temp=32.5, condition_main="Clear", description="nắng chói chang") == "hot"
    assert WeatherService.map_condition_to_code(temp=30.0, condition_main="Sunny", description="nắng nóng") == "hot"

    # 4. Mát mẻ dễ chịu (18°C - 30°C không mưa)
    assert WeatherService.map_condition_to_code(temp=24.0, condition_main="Clear", description="trời quang") == "mild"
    assert WeatherService.map_condition_to_code(temp=26.5, condition_main="Clouds", description="mây rải rác") == "mild"


def test_get_current_weather_fallback_default_hvnn(client: TestClient, db_session: Session, monkeypatch):
    """Kiểm tra khi chưa có API key thì endpoint tự fallback an toàn về toạ độ HVNN Gia Lâm."""
    monkeypatch.setattr(settings, "OPENWEATHERMAP_API_KEY", "")
    res = client.get("/api/v1/weather/current")
    assert res.status_code == 200
    data = res.json()

    assert data["latitude"] == pytest.approx(settings.DEFAULT_WEATHER_LAT)
    assert data["longitude"] == pytest.approx(settings.DEFAULT_WEATHER_LON)
    assert "Học viện Nông nghiệp Việt Nam" in data["location_name"]
    assert data["is_live"] is False
    assert data["matched_weather"] is not None
    assert "_PATTERN_" in data["matched_weather"]["code"] or data["matched_weather"]["season"] in ["spring", "summer", "autumn", "winter"]
    assert "temperature" in data
    assert "condition" in data


def test_get_current_weather_custom_coords(client: TestClient):
    """Kiểm tra truyền toạ độ tuỳ chọn (ví dụ: trung tâm Hà Nội)."""
    custom_lat = 21.0285
    custom_lon = 105.8542
    res = client.get(f"/api/v1/weather/current?lat={custom_lat}&lon={custom_lon}")
    assert res.status_code == 200
    data = res.json()
    assert data["latitude"] == pytest.approx(custom_lat)
    assert data["longitude"] == pytest.approx(custom_lon)


@pytest.mark.anyio
async def test_fetch_current_weather_with_mocked_live_api(db_session: Session):
    """Kiểm tra gọi OpenWeatherMap API giả lập trả về thời tiết mưa thực tế."""
    mock_payload = {
        "coord": {"lat": 21.0046, "lon": 105.9387},
        "weather": [
            {
                "id": 501,
                "main": "Rain",
                "description": "mưa vừa",
                "icon": "10d",
            }
        ],
        "main": {
            "temp": 22.4,
            "feels_like": 23.0,
            "humidity": 85,
        },
        "name": "Trâu Quỳ, Gia Lâm",
    }

    mock_resp = MagicMock()
    mock_resp.status_code = 200
    mock_resp.json.return_value = mock_payload

    mock_client = AsyncMock(spec=httpx.AsyncClient)
    mock_client.get.return_value = mock_resp

    with patch.object(settings, "OPENWEATHERMAP_API_KEY", "mock-test-key"):
        result = await WeatherService.fetch_current_weather(
            db=db_session,
            lat=21.0046,
            lon=105.9387,
            client=mock_client,
        )

    assert result.is_live is True
    assert result.temperature == 22.4
    assert result.humidity == 85
    assert result.condition == "Rain"
    assert result.description == "mưa vừa"
    assert result.icon == "10d"
    assert result.icon_url == "https://openweathermap.org/img/wn/10d@2x.png"
    assert result.location_name == "Trâu Quỳ, Gia Lâm"
    assert result.matched_weather is not None
    assert "_PATTERN_" in result.matched_weather.code and result.matched_weather.season in ["spring", "summer", "autumn", "winter"]


def test_current_weather_includes_recommended_categories(client: TestClient, db_session: Session, monkeypatch):
    """Kiểm tra thời tiết hiện tại tự động trả về các danh mục món ăn đã gán qua weather_categories."""
    monkeypatch.setattr(settings, "OPENWEATHERMAP_API_KEY", "")
    # 1. Tạo nhà hàng và danh mục món ăn mẫu
    rest = Restaurant(
        name="Quán Nướng & Lẩu HVNN",
        address="Trâu Quỳ, Gia Lâm, Hà Nội",
        latitude=21.0046,
        longitude=105.9387,
        is_active=True,
    )
    db_session.add(rest)
    db_session.commit()
    db_session.refresh(rest)

    cat = Category(
        name="Món Nước & Canh Nóng",
        description="Thích hợp ngày mưa mát",
        display_order=1,
        is_active=True,
    )
    db_session.add(cat)
    db_session.commit()
    db_session.refresh(cat)

    # 2. Gọi API để lấy thông tin thời tiết fallback và xác định matched_weather id
    res1 = client.get("/api/v1/weather/current")
    assert res1.status_code == 200
    data1 = res1.json()
    assert data1["matched_weather"] is not None
    matched_id = data1["matched_weather"]["id"]

    # 3. Gán danh mục món ăn này trực tiếp cho thời tiết đang khớp
    WeatherCategoryService.link_weather_category(db_session, weather_id=matched_id, category_id=cat.id)

    # 4. Gọi lại API thời tiết và kiểm tra danh mục được đề xuất
    res2 = client.get("/api/v1/weather/current")
    assert res2.status_code == 200
    data2 = res2.json()

    assert data2["matched_weather"] is not None
    assert "_PATTERN_" in data2["matched_weather"]["code"]
    recommended_cats = data2["recommended_categories"]
    cat_names = [c["name"] for c in recommended_cats]
    assert "Món Nước & Canh Nóng" in cat_names
