from datetime import datetime, time
from typing import Optional
from pydantic import BaseModel, ConfigDict, Field


class MealTypeBase(BaseModel):
    code: str = Field(..., max_length=30, description="Mã bữa ăn (breakfast, lunch, dinner, snack, all_day...)")
    name: str = Field(..., max_length=100, description="Tên bữa ăn (Bữa sáng, Bữa trưa...)")
    description: Optional[str] = Field(None, max_length=500, description="Mô tả bữa ăn")
    start_time: Optional[time] = Field(None, description="Giờ bắt đầu gợi ý (HH:MM:SS)")
    end_time: Optional[time] = Field(None, description="Giờ kết thúc gợi ý (HH:MM:SS)")
    sort_order: int = Field(0, description="Thứ tự hiển thị")
    is_active: bool = Field(True, description="Trạng thái kích hoạt")


class MealTypeCreate(MealTypeBase):
    pass


class MealTypeUpdate(BaseModel):
    name: Optional[str] = Field(None, max_length=100)
    description: Optional[str] = Field(None, max_length=500)
    start_time: Optional[time] = None
    end_time: Optional[time] = None
    sort_order: Optional[int] = None
    is_active: Optional[bool] = None


class MealTypeResponse(MealTypeBase):
    id: int
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)
