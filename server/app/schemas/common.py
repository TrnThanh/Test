import uuid
from typing import Any, Dict
from pydantic import BaseModel, Field


class LoginRequest(BaseModel):
    email: str = Field(..., description="Email đăng nhập", examples=["user@example.com"])
    password: str = Field(..., description="Mật khẩu", examples=["SecretPass123"])


class RoleLoginResponse(BaseModel):
    message: str = Field("Login successful", description="Thông báo đăng nhập")
    role: str = Field(..., description="Vai trò tài khoản (user, admin)")
    session_id: str = Field(
        default_factory=lambda: uuid.uuid4().hex,
        description="Mã định danh phiên làm việc (Session ID)",
        examples=["4a8c9e2b1f0d4b8e9a1c2d3e4f5a6b7c"],
    )
    data: Dict[str, Any] = Field(..., description="Thông tin chi tiết của tài khoản đã đăng nhập")
