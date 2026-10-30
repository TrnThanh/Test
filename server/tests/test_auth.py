from fastapi.testclient import TestClient


# ==============================================================================
# 1. USER AUTHENTICATION TESTS (Bảng: users)
# ==============================================================================

def test_register_user_success(client: TestClient) -> None:
    response = client.post(
        "/api/v1/auth/user/register",
        json={
            "email": "customer@example.com",
            "password": "securepassword123",
            "full_name": "Nguyen Van User",
        },
    )
    assert response.status_code == 201
    data = response.json()
    assert data["email"] == "customer@example.com"
    assert data["full_name"] == "Nguyen Van User"
    assert data["is_active"] is True
    assert "id" in data
    assert "created_at" in data
    assert "password" not in data


def test_register_user_duplicate_email(client: TestClient) -> None:
    payload = {
        "email": "dup_user@example.com",
        "password": "password123",
        "full_name": "User Duplicate",
    }
    resp1 = client.post("/api/v1/auth/user/register", json=payload)
    assert resp1.status_code == 201

    resp2 = client.post("/api/v1/auth/user/register", json=payload)
    assert resp2.status_code == 400
    assert "Email already registered" in resp2.json()["detail"]


def test_login_user_success(client: TestClient) -> None:
    client.post(
        "/api/v1/auth/user/register",
        json={
            "email": "login_user@example.com",
            "password": "MyPassword123",
            "full_name": "Login User",
        },
    )
    response = client.post(
        "/api/v1/auth/user/login",
        json={
            "email": "login_user@example.com",
            "password": "MyPassword123",
        },
    )
    assert response.status_code == 200
    data = response.json()
    assert data["role"] == "user"
    assert "session_id" in data and len(data["session_id"]) >= 32
    assert data["data"]["email"] == "login_user@example.com"


def test_login_user_wrong_password(client: TestClient) -> None:
    client.post(
        "/api/v1/auth/user/register",
        json={
            "email": "wrong_pwd_user@example.com",
            "password": "CorrectPassword",
        },
    )
    response = client.post(
        "/api/v1/auth/user/login",
        json={
            "email": "wrong_pwd_user@example.com",
            "password": "WrongPassword",
        },
    )
    assert response.status_code == 401
    assert response.json()["detail"] == "Incorrect email or password"


# ==============================================================================
# 2. SELLER AUTHENTICATION REMOVAL VERIFICATION
# ==============================================================================

def test_seller_auth_endpoints_removed(client: TestClient) -> None:
    """Xác nhận các route xác thực người bán đã bị loại bỏ hoàn toàn (404 Not Found)."""
    resp_register = client.post(
        "/api/v1/auth/seller/register",
        json={"email": "seller@example.com", "password": "123"},
    )
    assert resp_register.status_code == 404

    resp_login = client.post(
        "/api/v1/auth/seller/login",
        json={"email": "seller@example.com", "password": "123"},
    )
    assert resp_login.status_code == 404


# ==============================================================================
# 3. ADMIN AUTHENTICATION TESTS (Bảng: admins)
# ==============================================================================

def test_login_admin_default_success(client: TestClient) -> None:
    """Tài khoản Admin mặc định được tự động seed (admin@example.com / admin123)."""
    response = client.post(
        "/api/v1/auth/admin/login",
        json={
            "email": "admin@example.com",
            "password": "admin123",
        },
    )
    assert response.status_code == 200
    data = response.json()
    assert data["role"] == "admin"
    assert "session_id" in data and len(data["session_id"]) >= 32
    assert data["data"]["email"] == "admin@example.com"
    assert "role_level" not in data["data"]


def test_login_admin_wrong_password(client: TestClient) -> None:
    response = client.post(
        "/api/v1/auth/admin/login",
        json={
            "email": "admin@example.com",
            "password": "wrong_admin_password",
        },
    )
    assert response.status_code == 401
    assert response.json()["detail"] == "Incorrect email or password"

def test_register_user_confirm_password_match(client: TestClient) -> None:
    response = client.post(
        "/api/v1/auth/user/register",
        json={
            "email": "confirm_match@example.com",
            "password": "validpassword123",
            "confirm_password": "validpassword123",
            "full_name": "Match User",
        },
    )
    assert response.status_code == 201
    data = response.json()
    assert data["email"] == "confirm_match@example.com"
    assert "session_id" in data


def test_register_user_confirm_password_mismatch(client: TestClient) -> None:
    response = client.post(
        "/api/v1/auth/user/register",
        json={
            "email": "confirm_mismatch@example.com",
            "password": "validpassword123",
            "confirm_password": "differentpassword456",
            "full_name": "Mismatch User",
        },
    )
    assert response.status_code == 422
    assert "Mật khẩu xác nhận không trùng khớp" in str(response.json())


def test_register_user_friendly_validation_errors(client: TestClient) -> None:
    """Kiểm tra ngoại lệ validation 422 trả về thông điệp tiếng Việt trực quan, rõ ràng (chỉ dùng trường detail)."""
    # 1. Thiếu email và mật khẩu
    response_missing = client.post(
        "/api/v1/auth/user/register",
        json={"full_name": "Nguyen Van A"},
    )
    assert response_missing.status_code == 422
    data_missing = response_missing.json()
    assert "detail" in data_missing
    assert "message" not in data_missing
    assert "Thiếu trường email, thiếu trường password" in data_missing["detail"]

    # 2. Thiếu chỉ 1 trường (mật khẩu)
    response_single = client.post(
        "/api/v1/auth/user/register",
        json={"full_name": "Nguyen Van A", "email": "test_single@example.com"},
    )
    assert response_single.status_code == 422
    assert "Thiếu trường password" in response_single.json()["detail"]

    # 3. Mật khẩu quá ngắn (< 6 ký tự)
    response_short = client.post(
        "/api/v1/auth/user/register",
        json={
            "email": "short_pw@example.com",
            "password": "123",
            "full_name": "Short Password",
        },
    )
    assert response_short.status_code == 422
    data_short = response_short.json()
    assert "Mật khẩu" in data_short["detail"]
    assert "6 ký tự" in data_short["detail"]


def test_swagger_openapi_validation_schema(client: TestClient) -> None:
    """Kiểm tra schema Swagger OpenAPI HTTPValidationError chứa example trực quan (chỉ dùng message)."""
    response = client.get("/openapi.json")
    assert response.status_code == 200
    schema = response.json()
    assert "components" in schema and "schemas" in schema["components"]
    http_val_err = schema["components"]["schemas"]["HTTPValidationError"]
    assert "message" not in http_val_err["properties"]
    assert http_val_err["properties"]["detail"]["example"] == "Thiếu trường email, thiếu trường password"



# Kiểm tra giao diện Swagger UI /docs đã cấu hình ản hoàn toàn khối Schemas ở chân trang
def test_swagger_ui_hide_schemas(client: TestClient) -> None:
    """Kiểm tra trang /docs chứa cấu hình defaultModelsExpandDepth: -1 để ản khối Schemas."""
    # 1. Gửi request GET tới endpoint tài liệu Swagger UI /docs
    response = client.get("/docs")
    # 2. Xác thực phản hồi HTTP 200 và chứa tham số ản Schemas
    assert response.status_code == 200
    assert "defaultModelsExpandDepth" in response.text
    assert '"defaultModelsExpandDepth": -1' in response.text
