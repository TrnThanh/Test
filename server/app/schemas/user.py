import re
from datetime import datetime
from typing import Optional
from pydantic import BaseModel, ConfigDict, Field, field_validator, model_validator


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

    @field_validator("email")
    @classmethod
    def validate_email_format(cls, v: str) -> str:
        v = v.strip().lower()
        email_regex = r"^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$"
        if not re.match(email_regex, v):
            raise ValueError("Địa chỉ email không đúng định dạng.")
        return v

    @field_validator("phone")
    @classmethod
    def validate_phone_format(cls, v: Optional[str]) -> Optional[str]:
        if v is None:
            return None
        v = v.strip()
        if not v:
            return None
        phone_regex = r"^(0|\+84)(3|5|7|8|9)[0-9]{8}$"
        if not re.match(phone_regex, v):
            raise ValueError("Số điện thoại không hợp lệ (phải là 10 chữ số chuẩn Việt Nam).")
        return v

    @field_validator("full_name")
    @classmethod
    def validate_full_name(cls, v: Optional[str]) -> Optional[str]:
        if v is None:
            return None
        v = v.strip()
        return v or None

    @model_validator(mode="after")
    def verify_password_match(self) -> "UserRegister":
        if self.confirm_password is not None and self.confirm_password != self.password:
            raise ValueError("Mật khẩu xác nhận không trùng khớp với mật khẩu đã nhập.")
        return self


class UserLogin(BaseModel):
    email: str = Field(..., description="Email đăng nhập", examples=["user@example.com"])
    password: str = Field(..., description="Mật khẩu", examples=["SecretPass123"])

    @field_validator("email")
    @classmethod
    def clean_login_email(cls, v: str) -> str:
        return v.strip().lower()


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
