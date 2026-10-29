from datetime import datetime
from typing import Optional
from pydantic import BaseModel, ConfigDict, Field


class AdminLogin(BaseModel):
    email: str = Field(..., description="Email đăng nhập quản trị viên", examples=["admin@example.com"])
    password: str = Field(..., description="Mật khẩu", examples=["AdminPass123"])


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
    is_active: bool
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class RestaurantStatusUpdate(BaseModel):
    is_active: bool = Field(..., description="Trạng thái hoạt động mới")
