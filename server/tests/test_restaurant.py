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
    assert resp_lat.status_code == status.HTTP_422_UNPROCESSABLE_CONTENT

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
    assert resp_lon.status_code == status.HTTP_422_UNPROCESSABLE_CONTENT


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
    assert response.status_code == status.HTTP_422_UNPROCESSABLE_CONTENT


def test_legacy_seller_routes_removed(client: TestClient):
    """Kiểm tra các đường dẫn cũ /sellers/... đã bị loại bỏ (404 Not Found)."""
    resp = client.get("/api/v1/sellers/1/restaurants")
    assert resp.status_code == 404


def test_restaurant_service_licenses_crud(client: TestClient):
    """Kiểm tra tạo, deduplicate và cập nhật giấy phép dịch vụ (service_licenses) của quán ăn."""
    payload = {
        "name": "Nhà Hàng Sen Tây Hồ - Đạt Chuẩn ATTP",
        "address": "614 Lạc Long Quân, Tây Hồ, Hà Nội",
        "latitude": 21.0712,
        "longitude": 105.8182,
        "phone": "02437199242",
        "service_licenses": [
            "Giấy chứng nhận ATTP số 123/2026/ATTP",
            "Giấy phép PCCC cơ sở",
            "Giấy chứng nhận ATTP số 123/2026/ATTP",  # Trùng lặp
            "   ",  # Khoảng trắng rỗng
        ],
    }
    response = client.post("/api/v1/restaurants", json=payload)
    assert response.status_code == status.HTTP_201_CREATED
    data = response.json()
    assert "service_licenses" in data
    # Đã khử trùng và loại bỏ rỗng
    assert len(data["service_licenses"]) == 2
    assert "Giấy chứng nhận ATTP số 123/2026/ATTP" in data["service_licenses"]
    assert "Giấy phép PCCC cơ sở" in data["service_licenses"]

    rest_id = data["id"]

    # Cập nhật thêm giấy phép mới
    update_payload = {
        "service_licenses": ["Giấy phép kinh doanh dịch vụ ăn uống", "Giấy phép đồ uống có cồn"]
    }
    update_resp = client.put(f"/api/v1/restaurants/{rest_id}", json=update_payload)
    assert update_resp.status_code == status.HTTP_200_OK
    up_data = update_resp.json()
    assert len(up_data["service_licenses"]) == 2
    assert "Giấy phép đồ uống có cồn" in up_data["service_licenses"]




def test_create_restaurant_without_rating(client: TestClient):
    """Kiểm tra tạo quán ăn không truyền rating thì rating mặc định là None (null)."""
    payload = {
        "name": "Bún chả Hương Liên",
        "address": "24 Lê Văn Hưu, Hai Bà Trưng, Hà Nội",
        "latitude": 21.0185,
        "longitude": 105.8532,
    }
    response = client.post("/api/v1/restaurants", json=payload)
    assert response.status_code == status.HTTP_201_CREATED
    data = response.json()
    assert "rating" in data
    assert data["rating"] is None


def test_create_restaurant_with_valid_rating(client: TestClient):
    """Kiểm tra tạo quán ăn với điểm rating hợp lệ (4.5)."""
    payload = {
        "name": "Cơm tấm Sài Gòn",
        "address": "12 Tô Hiến Thành, Hai Bà Trưng, Hà Nội",
        "latitude": 21.0125,
        "longitude": 105.8502,
        "rating": 4.5,
    }
    response = client.post("/api/v1/restaurants", json=payload)
    assert response.status_code == status.HTTP_201_CREATED
    data = response.json()
    assert data["rating"] == 4.5


def test_create_restaurant_boundary_ratings(client: TestClient):
    """Kiểm tra tạo quán ăn với các giá trị rating biên: 0.0 và 5.0."""
    # Biên 0.0
    r0 = client.post(
        "/api/v1/restaurants",
        json={
            "name": "Quán ăn biên 0",
            "address": "Địa chỉ 0",
            "latitude": 21.0,
            "longitude": 105.0,
            "rating": 0.0,
        },
    )
    assert r0.status_code == status.HTTP_201_CREATED
    assert r0.json()["rating"] == 0.0

    # Biên 5.0
    r5 = client.post(
        "/api/v1/restaurants",
        json={
            "name": "Quán ăn biên 5",
            "address": "Địa chỉ 5",
            "latitude": 21.0,
            "longitude": 105.0,
            "rating": 5.0,
        },
    )
    assert r5.status_code == status.HTTP_201_CREATED
    assert r5.json()["rating"] == 5.0


def test_create_restaurant_invalid_rating_negative(client: TestClient):
    """Kiểm tra API từ chối tạo quán ăn nếu rating < 0.0 (422 Unprocessable Entity)."""
    payload = {
        "name": "Quán lỗi rating âm",
        "address": "Địa chỉ lỗi",
        "latitude": 21.0,
        "longitude": 105.0,
        "rating": -0.5,
    }
    response = client.post("/api/v1/restaurants", json=payload)
    assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY


def test_create_restaurant_invalid_rating_exceeds_five(client: TestClient):
    """Kiểm tra API từ chối tạo quán ăn nếu rating > 5.0 (422 Unprocessable Entity)."""
    payload = {
        "name": "Quán lỗi rating vượt trần",
        "address": "Địa chỉ lỗi",
        "latitude": 21.0,
        "longitude": 105.0,
        "rating": 5.5,
    }
    response = client.post("/api/v1/restaurants", json=payload)
    assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY


def test_update_restaurant_rating(client: TestClient):
    """Kiểm tra cập nhật rating cho quán ăn qua API PUT."""
    create_resp = client.post(
        "/api/v1/restaurants",
        json={
            "name": "Quán Trà Sữa TocoToco",
            "address": "54 Cầu Giấy, Hà Nội",
            "latitude": 21.0345,
            "longitude": 105.7985,
        },
    )
    rest_id = create_resp.json()["id"]
    assert create_resp.json()["rating"] is None

    # Cập nhật rating lên 4.8
    update_resp = client.put(
        f"/api/v1/restaurants/{rest_id}",
        json={"rating": 4.8},
    )
    assert update_resp.status_code == status.HTTP_200_OK
    assert update_resp.json()["rating"] == 4.8


def test_update_restaurant_keeps_existing_rating(client: TestClient):
    """Kiểm tra khi sửa tên quán mà không truyền rating thì rating cũ vẫn được bảo toàn."""
    create_resp = client.post(
        "/api/v1/restaurants",
        json={
            "name": "Bánh Mì Phố Cổ",
            "address": "38 Đinh Liệt, Hoàn Kiếm, Hà Nội",
            "latitude": 21.0315,
            "longitude": 105.8525,
            "rating": 4.6,
        },
    )
    rest_id = create_resp.json()["id"]

    # Cập nhật chỉ tên quán
    update_resp = client.put(
        f"/api/v1/restaurants/{rest_id}",
        json={"name": "Bánh Mì Phố Cổ - Cơ Sở 2"},
    )
    assert update_resp.status_code == status.HTTP_200_OK
    data = update_resp.json()
    assert data["name"] == "Bánh Mì Phố Cổ - Cơ Sở 2"
    assert data["rating"] == 4.6


def test_db_check_constraint_rating(db_session: Session):
    """Kiểm tra ràng buộc CheckConstraint ck_restaurant_rating ở tầng Database PostgreSQL."""
    from sqlalchemy.exc import IntegrityError

    # Cố tình insert trực tiếp entity có rating vượt quá 5.0
    invalid_restaurant = Restaurant(
        name="Quán vi phạm CheckConstraint",
        address="Địa chỉ vi phạm",
        latitude=21.0,
        longitude=105.0,
        rating=9.9,
    )
    db_session.add(invalid_restaurant)
    with pytest.raises(IntegrityError):
        db_session.commit()
    db_session.rollback()
