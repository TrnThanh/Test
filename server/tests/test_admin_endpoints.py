from fastapi.testclient import TestClient


def test_admin_stats(client: TestClient) -> None:
    # First register a user to ensure stats > 0
    client.post(
        "/api/v1/auth/user/register",
        json={"email": "admin_test_user@example.com", "password": "pass123"},
    )
    client.post(
        "/api/v1/restaurants",
        json={
            "name": "Quán Mẫu Cho Stats",
            "address": "123 Đường Mẫu, Hà Nội",
            "latitude": 21.0285,
            "longitude": 105.8542,
        },
    )

    resp = client.get("/api/v1/admin/stats")
    assert resp.status_code == 200
    data = resp.json()
    assert "total_restaurants" in data
    assert "active_restaurants" in data
    assert "total_users" in data
    assert "total_sellers" not in data
    assert data["total_users"] >= 1
    assert data["total_restaurants"] >= 1


def test_admin_users_list_and_sellers_removed(client: TestClient) -> None:
    # sellers endpoint was removed -> 404
    resp_sellers = client.get("/api/v1/admin/sellers")
    assert resp_sellers.status_code == 404

    resp_users = client.get("/api/v1/admin/users")
    assert resp_users.status_code == 200
    users = resp_users.json()
    assert isinstance(users, list)


def test_admin_restaurant_management(client: TestClient) -> None:
    # 1. Admin creates restaurant
    rest_resp = client.post(
        "/api/v1/admin/restaurants",
        json={
            "name": "Quán Quản Trị Test",
            "address": "123 Đường Quản Trị, Hà Nội",
            "latitude": 21.0285,
            "longitude": 105.8542,
            "phone": "0987654321",
            "is_sponsor": True,
        },
    )
    assert rest_resp.status_code == 201
    rest_id = rest_resp.json()["id"]
    assert rest_resp.json()["is_active"] is True
    assert rest_resp.json()["is_sponsor"] is True

    # 2. Admin toggle status
    patch_resp = client.patch(
        f"/api/v1/admin/restaurants/{rest_id}/status",
        json={"is_active": False},
    )
    assert patch_resp.status_code == 200
    assert patch_resp.json()["is_active"] is False

    # 3. Admin update restaurant details
    put_resp = client.put(
        f"/api/v1/admin/restaurants/{rest_id}",
        json={"name": "Quán Quản Trị Đã Cập Nhật", "is_active": True, "is_sponsor": False},
    )
    assert put_resp.status_code == 200
    assert put_resp.json()["name"] == "Quán Quản Trị Đã Cập Nhật"
    assert put_resp.json()["is_active"] is True
    assert put_resp.json()["is_sponsor"] is False

    # 4. Admin delete restaurant
    del_resp = client.delete(f"/api/v1/admin/restaurants/{rest_id}")
    assert del_resp.status_code == 200
    assert del_resp.json()["restaurant_id"] == rest_id

    # 5. Verify deleted
    get_resp = client.get(f"/api/v1/restaurants/{rest_id}")
    assert get_resp.status_code == 404

def test_admin_delete_user(client: TestClient) -> None:
    # 1. Tạo user mới để test xoá
    reg_resp = client.post(
        "/api/v1/auth/user/register",
        json={"email": "user_to_delete@example.com", "password": "pass123delete", "full_name": "Delete Me"},
    )
    assert reg_resp.status_code == 201
    user_id = reg_resp.json()["id"]

    # 2. Xoá user qua admin API
    del_resp = client.delete(f"/api/v1/admin/users/{user_id}")
    assert del_resp.status_code == 200
    assert del_resp.json()["user_id"] == user_id

    # 3. Xoá lại lần nữa -> 404
    del_resp_again = client.delete(f"/api/v1/admin/users/{user_id}")
    assert del_resp_again.status_code == 404
