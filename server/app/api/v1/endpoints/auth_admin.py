import uuid
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from server.app.db.session import get_db
from server.app.schemas.admin import AdminLogin
from server.app.schemas.common import RoleLoginResponse
from server.app.services.admin_service import AdminService

router = APIRouter()


# Xác thực đăng nhập quản trị viên hệ thống (Admin Console)
@router.post(
    "/login",
    response_model=RoleLoginResponse,
    status_code=status.HTTP_200_OK,
    summary="Đăng nhập tài khoản Admin",
    description="Kiểm tra email và mật khẩu trong bảng admins.",
)
def login_admin(
    admin_in: AdminLogin,
    db: Session = Depends(get_db),
) -> RoleLoginResponse:
    """
    [POSTMAN TEST GUIDE]
    - Method  : POST
    - URL     : http://localhost:8001/api/v1/auth/admin/login
    - Headers : Content-Type: application/json
    - Params  : (Không có)
    - Body (raw JSON):
      {
        "email": "admin@example.com",
        "password": "admin123"
      }
    - Expected: 200 OK
      {
        "message": "Admin login successful",
        "role": "admin",
        "session_id": "<hex_uuid>",
        "data": {
          "id": 1,
          "email": "admin@example.com",
          "full_name": "System Administrator",
          "is_active": true,
          "created_at": "..."
        }
      }
    - Errors  : 401 Unauthorized (Incorrect email or password), 422 Unprocessable Content (thiếu email/password)
    """
    # 1. Gọi service xác thực thông tin đăng nhập admin
    admin = AdminService.authenticate_admin(db=db, email=admin_in.email, password=admin_in.password)
    # 2. Kiểm tra nếu thông tin đăng nhập không hợp lệ
    if not admin:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
        )
    # 3. Chuẩn bị dữ liệu thông tin quản trị viên trả về
    admin_dict = {
        "id": admin.id,
        "email": admin.email,
        "full_name": admin.full_name,
        "is_active": admin.is_active,
        "created_at": admin.created_at.isoformat(),
    }
    # 4. Trả về phản hồi đăng nhập thành công kèm session ID ngẫu nhiên
    return RoleLoginResponse(
        message="Admin login successful",
        role="admin",
        session_id=uuid.uuid4().hex,
        data=admin_dict,
    )
