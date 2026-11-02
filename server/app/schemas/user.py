from datetime import datetime
from typing import Optional
from pydantic import BaseModel, ConfigDict, Field, model_validator


class UserRegister(BaseModel):
    email: str = Field(
        ...,
        min_length=3,
        max_length=255,
        description="Địa chỉ email người dùng",
        examples=["user@example.com"],
    )
    password: str = Field(
        ...,
        min_length=6,
        max_length=72,
        description="Mật khẩu tài khoản (tối thiểu 6 ký tự)",
        examples=["SecretPass123"],
    )
    confirm_password: Optional[str] = Field(
        None,
        description="Xác nhận lại mật khẩu",
        examples=["SecretPass123"],
    )
    full_name: Optional[str] = Field(
        None,
        max_length=255,
        description="Họ và tên đầy đủ",
        examples=["Nguyễn Văn A"],
    )
    phone: Optional[str] = Field(
        None,
        max_length=50,
        description="Số điện thoại liên hệ",
        examples=["0912345678"],
    )

    @model_validator(mode="after")
    def verify_password_match(self) -> "UserRegister":
        if self.confirm_password is not None and self.confirm_password != self.password:
            raise ValueError("Mật khẩu xác nhận không trùng khớp với mật khẩu đã nhập.")
        return self


class UserLogin(BaseModel):
    email: str = Field(..., description="Email đăng nhập", examples=["user@example.com"])
    password: str = Field(..., description="Mật khẩu", examples=["SecretPass123"])


class UserResponse(BaseModel):
    id: int = Field(..., description="ID của người dùng", examples=[1])
    email: str = Field(..., description="Địa chỉ email", examples=["user@example.com"])
    full_name: Optional[str] = Field(None, description="Họ và tên")
    phone: Optional[str] = Field(None, description="Số điện thoại liên hệ")
    created_at: datetime = Field(..., description="Thời gian tạo tài khoản")
    session_id: Optional[str] = Field(None, description="Mã phiên làm việc đăng nhập")
    role: str = Field("user", description="Vai trò tài khoản")
    message: Optional[str] = Field("User registered successfully", description="Thông điệp phản hồi")
    data: Optional[dict] = Field(None, description="Dữ liệu chi tiết tài khoản")

    model_config = ConfigDict(from_attributes=True)
