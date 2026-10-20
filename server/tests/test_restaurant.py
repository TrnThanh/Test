import pytest
from fastapi import status
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session
from sqlalchemy import select

from server.app.models.restaurant import Restaurant


def test_create_restaurant_success(client: TestClient):
    """Kiểm tra tạo quán ăn mới thành công kèm toạ độ bản đồ."""
    payload = {
        "name": "Phở Bát Đàn - Cơ sở 1",
        "address": "49 Bát Đàn, Hoàn Kiếm, Hà Nội",
        "latitude": 21.0335,
        "longitude": 105.8471,
        "phone": "02438255699",
        "description": "Quán phở truyền thống lâu đời",
    }
    response = client.post("/api/v1/restaurants", json=payload)
    assert response.status_code == status.HTTP_201_CREATED
    data = response.json()
    assert data["name"] == payload["name"]
    assert data["address"] == payload["address"]
    assert data["latitude"] == payload["latitude"]
    assert data["longitude"] == payload["longitude"]
    assert data["is_active"] is True
    assert "id" in data


def test_create_multiple_restaurants(client: TestClient):
    """Kiểm tra tạo nhiều quán ăn trong hệ thống."""
    # Tạo quán 1
    client.post(
        "/api/v1/restaurants",
        json={
            "name": "Chi nhánh Cầu Giấy",
            "address": "123 Cầu Giấy, Hà Nội",
            "latitude": 21.0360,
            "longitude": 105.7950,
        },
    )
    # Tạo quán 2
    client.post(
        "/api/v1/restaurants",
        json={
            "name": "Chi nhánh Đống Đa",
            "address": "456 Xã Đàn, Hà Nội",
            "latitude": 21.0150,
            "longitude": 105.8300,
        },
    )

    # Lấy danh sách quán
    response = client.get("/api/v1/restaurants")
    assert response.status_code == status.HTTP_200_OK
    items = response.json()
    assert len(items) >= 2
    names = [r["name"] for r in items]
    assert "Chi nhánh Cầu Giấy" in names
    assert "Chi nhánh Đống Đa" in names


def test_update_restaurant_success(client: TestClient):
    """Kiểm tra cập nhật thông tin và toạ độ quán ăn thành công."""
    res_create = client.post(
        "/api/v1/restaurants",
        json={
            "name": "Quán ban đầu",
            "address": "Địa chỉ cũ",
            "latitude": 21.0,
            "longitude": 105.0,
        },
    )
    res_id = res_create.json()["id"]

    # Cập nhật
    update_payload = {
        "name": "Quán sau khi đổi tên",
        "address": "Địa chỉ mới đẹp hơn",
        "latitude": 21.0285,
        "longitude": 105.8542,
        "phone": "0999999999",
    }
    response = client.put(f"/api/v1/restaurants/{res_id}", json=update_payload)
    assert response.status_code == status.HTTP_200_OK
    data = response.json()
    assert data["name"] == "Quán sau khi đổi tên"
    assert data["address"] == "Địa chỉ mới đẹp hơn"
    assert data["latitude"] == 21.0285
    assert data["longitude"] == 105.8542
    assert data["phone"] == "0999999999"


def test_delete_restaurant_success(client: TestClient):
    """Kiểm tra xoá quán ăn thành công."""
    res_create = client.post(
        "/api/v1/restaurants",
        json={
            "name": "Quán cần xoá",
            "address": "Hà Nội",
            "latitude": 21.0,
            "longitude": 105.0,
        },
    )
    res_id = res_create.json()["id"]

    # Xoá quán
    resp_delete = client.delete(f"/api/v1/restaurants/{res_id}")
    assert resp_delete.status_code == status.HTTP_200_OK

    # Lấy lại quán sau khi xoá -> 404 Not Found
    resp_get = client.get(f"/api/v1/restaurants/{res_id}")
    assert resp_get.status_code == status.HTTP_404_NOT_FOUND


def test_restaurant_coordinate_validation(client: TestClient):
    """Kiểm tra validation toạ độ không hợp lệ: lat ngoài [-90, 90], lon ngoài [-180, 180]."""
    # Latitude > 90
    resp_lat = client.post(
        "/api/v1/restaurants",
        json={
            "name": "Quán lỗi lat",
            "address": "Hà Nội",
            "latitude": 95.0,
            "longitude": 105.0,
        },
    )
    assert resp_lat.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY

    # Longitude > 180
    resp_lon = client.post(
        "/api/v1/restaurants",
        json={
            "name": "Quán lỗi lon",
            "address": "Hà Nội",
            "latitude": 21.0,
            "longitude": 195.0,
        },
    )
    assert resp_lon.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY


def test_public_get_restaurants(client: TestClient):
    """Kiểm tra API public cho khách hàng xem danh sách quán và lấy toạ độ dẫn đường."""
    res_create = client.post(
        "/api/v1/restaurants",
        json={
            "name": "Cơm Tấm Sài Gòn",
            "address": "789 Nguyễn Trãi, Thanh Xuân, Hà Nội",
            "latitude": 20.9950,
            "longitude": 105.8050,
        },
    )
    res_id = res_create.json()["id"]

    # Public list
    resp_list = client.get("/api/v1/restaurants")
    assert resp_list.status_code == status.HTTP_200_OK
    assert any(r["id"] == res_id for r in resp_list.json())

    # Public detail (dùng toạ độ này để dẫn đường)
    resp_detail = client.get(f"/api/v1/restaurants/{res_id}")
    assert resp_detail.status_code == status.HTTP_200_OK
    assert resp_detail.json()["latitude"] == 20.9950
    assert resp_detail.json()["longitude"] == 105.8050


def test_create_restaurant_with_opening_hours(client: TestClient):
    """Kiểm tra tạo quán ăn kèm thời gian mở cửa và đóng cửa (HH:MM)."""
    payload = {
        "name": "Phở Đêm 24h",
        "address": "123 Phố Cổ, Hoàn Kiếm, Hà Nội",
        "latitude": 21.0333,
        "longitude": 105.8500,
        "open_time": "18:00",
        "close_time": "04:30",
    }
    response = client.post("/api/v1/restaurants", json=payload)
    assert response.status_code == status.HTTP_201_CREATED
    data = response.json()
    assert data["open_time"] == "18:00"
    assert data["close_time"] == "04:30"


def test_update_restaurant_hours(client: TestClient, db_session: Session):
    """Kiểm tra cập nhật và xoá thời gian mở/đóng cửa quán ăn."""
    r = Restaurant(
        name="Cơm Tấm Sài Gòn",
        address="10 Nguyễn Huệ, Q1, TP.HCM",
        latitude=10.7769,
        longitude=106.7009,
    )
    db_session.add(r)
    db_session.commit()
    db_session.refresh(r)

    # Cập nhật giờ mở/đóng
    up_resp = client.put(
        f"/api/v1/restaurants/{r.id}",
        json={"open_time": "07:30", "close_time": "21:00"},
    )
    assert up_resp.status_code == status.HTTP_200_OK
    assert up_resp.json()["open_time"] == "07:30"
    assert up_resp.json()["close_time"] == "21:00"

    # Xoá giờ (gửi None hoặc rỗng)
    clear_resp = client.put(
        f"/api/v1/restaurants/{r.id}",
        json={"open_time": None, "close_time": None},
    )
    assert clear_resp.status_code == status.HTTP_200_OK
    assert clear_resp.json()["open_time"] is None
    assert clear_resp.json()["close_time"] is None


def test_create_restaurant_invalid_time_format(client: TestClient):
    """Kiểm tra validation lỗi 422 khi truyền định dạng giờ không hợp lệ."""
    payload = {
        "name": "Quán Giờ Lỗi",
        "address": "456 Đường Lỗi",
        "latitude": 21.0,
        "longitude": 105.0,
        "open_time": "25:99",
        "close_time": "22:00",
    }
    response = client.post("/api/v1/restaurants", json=payload)
    assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY


def test_legacy_seller_routes_removed(client: TestClient):
    """Kiểm tra các đường dẫn cũ /sellers/... đã bị loại bỏ (404 Not Found)."""
    resp = client.get("/api/v1/sellers/1/restaurants")
    assert resp.status_code == 404
