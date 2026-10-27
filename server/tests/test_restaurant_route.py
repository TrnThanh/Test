import pytest
from unittest.mock import AsyncMock, MagicMock
from fastapi import status
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session
import httpx

from server.app.models.restaurant import Restaurant
from server.app.services.map_service import map_service, FIFOTtlCache, haversine_distance


@pytest.fixture(autouse=True)
def clear_route_cache():
    """Tự động dọn sạch bộ nhớ đệm trước và sau mỗi test case."""
    map_service.route_cache.clear()
    yield
    map_service.route_cache.clear()


@pytest.fixture
def active_restaurant(db_session: Session) -> Restaurant:
    """Tạo quán ăn đang hoạt động ở trung tâm Hà Nội để phục vụ test."""
    rest = Restaurant(
        name="Quán Phở Bát Đàn Test",
        address="49 Bát Đàn, Hoàn Kiếm, Hà Nội",
        latitude=21.0335,
        longitude=105.8471,
        is_active=True,
    )
    db_session.add(rest)
    db_session.commit()
    db_session.refresh(rest)
    return rest


# 1. Case bình thường (Mock OSM 200 Ok trả đường polyline)
def test_walking_route_success(client: TestClient, active_restaurant: Restaurant, monkeypatch: pytest.MonkeyPatch):
    fake_payload = {
        "code": "Ok",
        "routes": [
            {
                "distance": 850.5,
                "duration": 680.4,
                "geometry": {
                    "coordinates": [
                        [105.8450, 21.0300],
                        [105.8460, 21.0320],
                        [105.8471, 21.0335],
                    ]
                },
            }
        ],
    }
    mock_resp = MagicMock()
    mock_resp.status_code = 200
    mock_resp.json.return_value = fake_payload

    mock_client = AsyncMock()
    mock_client.get = AsyncMock(return_value=mock_resp)
    monkeypatch.setattr(map_service, "_client", mock_client)

    response = client.get(
        f"/api/v1/restaurants/{active_restaurant.id}/route",
        params={"user_lat": 21.0300, "user_lon": 105.8450},
    )
    assert response.status_code == status.HTTP_200_OK
    data = response.json()
    assert data["restaurant_id"] == active_restaurant.id
    assert data["restaurant_name"] == active_restaurant.name
    assert data["is_fallback"] is False
    assert data["distance_meters"] == 850.5
    assert data["duration_seconds"] == 680.4
    assert len(data["coordinates"]) == 3
    assert data["coordinates"][0] == [105.8450, 21.0300]


# 2. Case Cache Hit (lần 2 không gọi HTTP ra ngoài)
def test_walking_route_cache_hit(client: TestClient, active_restaurant: Restaurant, monkeypatch: pytest.MonkeyPatch):
    fake_payload = {
        "code": "Ok",
        "routes": [
            {
                "distance": 500.0,
                "duration": 400.0,
                "geometry": {"coordinates": [[105.8450, 21.0300], [105.8471, 21.0335]]},
            }
        ],
    }
    mock_resp = MagicMock()
    mock_resp.status_code = 200
    mock_resp.json.return_value = fake_payload

    mock_client = AsyncMock()
    mock_client.get = AsyncMock(return_value=mock_resp)
    monkeypatch.setattr(map_service, "_client", mock_client)

    params = {"user_lat": 21.0300, "user_lon": 105.8450}
    # Gọi lần 1
    resp1 = client.get(f"/api/v1/restaurants/{active_restaurant.id}/route", params=params)
    assert resp1.status_code == 200
    assert mock_client.get.call_count == 1

    # Gọi lần 2 với cùng toạ độ
    resp2 = client.get(f"/api/v1/restaurants/{active_restaurant.id}/route", params=params)
    assert resp2.status_code == 200
    assert resp2.json()["distance_meters"] == 500.0
    # Số lần gọi HTTP vẫn là 1 (Cache Hit!)
    assert mock_client.get.call_count == 1


# 3. Case OSM trả 200 nhưng code: "NoRoute" -> Fallback an toàn
def test_walking_route_osrm_no_route_fallback(client: TestClient, active_restaurant: Restaurant, monkeypatch: pytest.MonkeyPatch):
    mock_resp = MagicMock()
    mock_resp.status_code = 200
    mock_resp.json.return_value = {"code": "NoRoute", "message": "Impossible route"}

    mock_client = AsyncMock()
    mock_client.get = AsyncMock(return_value=mock_resp)
    monkeypatch.setattr(map_service, "_client", mock_client)

    response = client.get(
        f"/api/v1/restaurants/{active_restaurant.id}/route",
        params={"user_lat": 21.0300, "user_lon": 105.8450},
    )
    assert response.status_code == status.HTTP_200_OK
    data = response.json()
    assert data["is_fallback"] is True
    assert len(data["coordinates"]) == 2
    assert data["distance_meters"] > 0
    assert data["duration_seconds"] > 0


# 4. Case OSM trả status 429 Too Many Requests -> Fallback an toàn kèm log
def test_walking_route_osrm_429_fallback(client: TestClient, active_restaurant: Restaurant, monkeypatch: pytest.MonkeyPatch):
    mock_resp = MagicMock()
    mock_resp.status_code = 429
    mock_resp.text = "Too Many Requests"

    mock_client = AsyncMock()
    mock_client.get = AsyncMock(return_value=mock_resp)
    monkeypatch.setattr(map_service, "_client", mock_client)

    response = client.get(
        f"/api/v1/restaurants/{active_restaurant.id}/route",
        params={"user_lat": 21.0300, "user_lon": 105.8450},
    )
    assert response.status_code == status.HTTP_200_OK
    data = response.json()
    assert data["is_fallback"] is True
    assert len(data["coordinates"]) == 2


# 5. Case OSM Timeout / 5xx / HTML body 200 -> Fallback an toàn
def test_walking_route_osrm_timeout_or_html_fallback(client: TestClient, active_restaurant: Restaurant, monkeypatch: pytest.MonkeyPatch):
    # Giả lập timeout
    mock_client = AsyncMock()
    mock_client.get = AsyncMock(side_effect=httpx.TimeoutException("OSM Timeout"))
    monkeypatch.setattr(map_service, "_client", mock_client)

    resp_timeout = client.get(
        f"/api/v1/restaurants/{active_restaurant.id}/route",
        params={"user_lat": 21.0300, "user_lon": 105.8450},
    )
    assert resp_timeout.status_code == status.HTTP_200_OK
    assert resp_timeout.json()["is_fallback"] is True

    # Giả lập trả về HTML lỗi 200
    mock_resp_html = MagicMock()
    mock_resp_html.status_code = 200
    mock_resp_html.json.side_effect = ValueError("Invalid JSON response")
    mock_client.get = AsyncMock(return_value=mock_resp_html)

    resp_html = client.get(
        f"/api/v1/restaurants/{active_restaurant.id}/route",
        params={"user_lat": 21.0300, "user_lon": 105.8450},
    )
    assert resp_html.status_code == status.HTTP_200_OK
    assert resp_html.json()["is_fallback"] is True


# 6. Case Fallback KHÔNG bị lưu cache (lần sau thử lại vẫn gọi ngoài)
def test_walking_route_fallback_never_cached(client: TestClient, active_restaurant: Restaurant, monkeypatch: pytest.MonkeyPatch):
    # Lần 1: Lỗi timeout -> fallback
    mock_client = AsyncMock()
    mock_client.get = AsyncMock(side_effect=httpx.TimeoutException("Timeout"))
    monkeypatch.setattr(map_service, "_client", mock_client)

    params = {"user_lat": 21.0300, "user_lon": 105.8450}
    resp1 = client.get(f"/api/v1/restaurants/{active_restaurant.id}/route", params=params)
    assert resp1.status_code == 200
    assert resp1.json()["is_fallback"] is True
    # Đảm bảo cache trống, không lưu kết quả fallback
    cache_key = (round(21.0300, 4), round(105.8450, 4), active_restaurant.id)
    assert map_service.route_cache.get(cache_key) is None

    # Lần 2: OSRM hồi phục trả 200 Ok
    fake_payload = {
        "code": "Ok",
        "routes": [{"distance": 900.0, "duration": 720.0, "geometry": {"coordinates": [[105.8450, 21.0300], [105.8471, 21.0335]]}}],
    }
    mock_resp2 = MagicMock()
    mock_resp2.status_code = 200
    mock_resp2.json.return_value = fake_payload
    mock_client.get = AsyncMock(return_value=mock_resp2)

    resp2 = client.get(f"/api/v1/restaurants/{active_restaurant.id}/route", params=params)
    assert resp2.status_code == 200
    assert resp2.json()["is_fallback"] is False
    assert mock_client.get.call_count == 1  # Lần 2 đã gọi ra ngoài thành công!


# 7. Case TTL hết hạn (dùng fake clock truyền vào constructor) -> Gọi lại HTTP
def test_fifo_ttl_cache_expiration():
    fake_time = 1000.0
    cache = FIFOTtlCache(maxsize=10, ttl_seconds=300.0, clock=lambda: fake_time)

    cache.set("key1", "val1")
    assert cache.get("key1") == "val1"

    # Nhảy thời gian quá 300s
    fake_time += 301.0
    assert cache.get("key1") is None
    # Key hết hạn bị chủ động xoá khỏi bộ nhớ
    assert "key1" not in cache._cache


# 8. Case FIFO Eviction (khởi tạo FIFOTtlCache(maxsize=3) nạp 4 items)
def test_fifo_ttl_cache_eviction():
    cache = FIFOTtlCache(maxsize=3)
    cache.set("a", 1)
    cache.set("b", 2)
    cache.set("c", 3)
    assert len(cache._cache) == 3

    # Nạp phần tử thứ 4 -> phần tử 'a' đầu tiên bị đẩy ra
    cache.set("d", 4)
    assert len(cache._cache) == 3
    assert cache.get("a") is None
    assert cache.get("b") == 2
    assert cache.get("c") == 3
    assert cache.get("d") == 4


# 9. Case Quán không tồn tại hoặc is_active == False (404), toạ độ NULL (422)
def test_walking_route_not_found_or_inactive(client: TestClient, db_session: Session):
    # Quán không tồn tại
    resp_404 = client.get(
        "/api/v1/restaurants/999999/route",
        params={"user_lat": 21.0300, "user_lon": 105.8450},
    )
    assert resp_404.status_code == status.HTTP_404_NOT_FOUND

    # Quán đã ngừng hoạt động (is_active = False)
    inactive_rest = Restaurant(
        name="Quán Đã Đóng Cửa",
        address="100 Phố Huế, Hà Nội",
        latitude=21.0150,
        longitude=105.8520,
        is_active=False,
    )
    db_session.add(inactive_rest)
    db_session.commit()
    db_session.refresh(inactive_rest)

    resp_inactive = client.get(
        f"/api/v1/restaurants/{inactive_rest.id}/route",
        params={"user_lat": 21.0300, "user_lon": 105.8450},
    )
    assert resp_inactive.status_code == status.HTTP_404_NOT_FOUND
    assert "ngừng hoạt động" in resp_inactive.json()["detail"]


# 10. Case Cự ly > 50km (400 - không đụng cache/OSM), toạ độ ngoài biên ge/le (422)
def test_walking_route_distance_over_50km_and_validation(client: TestClient, active_restaurant: Restaurant, monkeypatch: pytest.MonkeyPatch):
    mock_client = AsyncMock()
    monkeypatch.setattr(map_service, "_client", mock_client)

    # Toạ độ ở TP. Hồ Chí Minh (cách Hà Nội > 1000 km) -> 400 Bad Request
    resp_far = client.get(
        f"/api/v1/restaurants/{active_restaurant.id}/route",
        params={"user_lat": 10.8231, "user_lon": 106.6297},
    )
    assert resp_far.status_code == status.HTTP_400_BAD_REQUEST
    assert "tối đa 50km" in resp_far.json()["detail"]
    # Tuyệt đối không gọi OSM khi vượt cự ly
    assert mock_client.get.call_count == 0

    # Toạ độ ngoài biên (user_lat = 95.0, user_lon = 200.0) -> 422 Unprocessable Content
    resp_inv_lat = client.get(
        f"/api/v1/restaurants/{active_restaurant.id}/route",
        params={"user_lat": 95.0, "user_lon": 105.8450},
    )
    assert resp_inv_lat.status_code == status.HTTP_422_UNPROCESSABLE_CONTENT

    resp_inv_lon = client.get(
        f"/api/v1/restaurants/{active_restaurant.id}/route",
        params={"user_lat": 21.0300, "user_lon": 200.0},
    )
    assert resp_inv_lon.status_code == status.HTTP_422_UNPROCESSABLE_CONTENT
