import re
from datetime import datetime
from typing import Optional
from pydantic import BaseModel, ConfigDict, Field, field_validator


class AdminLogin(BaseModel):
    email: str = Field(
        ...,
        min_length=3,
        max_length=255,
        description="Email đăng nhập quản trị viên",
        examples=["admin@example.com"],
    )
    password: str = Field(
        ...,
        min_length=6,
        max_length=72,
        description="Mật khẩu",
        examples=["AdminPass123"],
    )

    @field_validator("email")
    @classmethod
    def clean_admin_email(cls, v: str) -> str:
        v = v.strip().lower()
        email_regex = r"^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$"
        if not re.match(email_regex, v):
            raise ValueError("Địa chỉ email quản trị viên không đúng định dạng.")
        return v


class AdminResponse(BaseModel):
    id: int = Field(..., description="ID của quản trị viên", examples=[1])
    email: str = Field(..., description="Địa chỉ email", examples=["admin@example.com"])
    full_name: Optional[str] = Field(None, description="Họ và tên")
    is_active: bool = Field(True, description="Trạng thái kích hoạt")
    created_at: datetime = Field(..., description="Thời gian tạo tài khoản")

    model_config = ConfigDict(from_attributes=True)


class SystemStatsResponse(BaseModel):
    total_restaurants: int = Field(..., description="Tổng số quán ăn")
    active_restaurants: int = Field(..., description="Số quán ăn đang hoạt động")
    inactive_restaurants: int = Field(..., description="Số quán ăn tạm dừng")
    total_dishes: int = Field(..., description="Tổng số món ăn")
    total_categories: int = Field(..., description="Tổng số nhóm danh mục")
    total_users: int = Field(..., description="Tổng số tài khoản thực khách")


class AdminUserItem(BaseModel):
    id: int
    email: str
    full_name: Optional[str] = None
    phone: Optional[str] = None
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class RestaurantStatusUpdate(BaseModel):
    is_active: bool = Field(..., description="Trạng thái hoạt động mới")
