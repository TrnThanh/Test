from datetime import datetime, time
from typing import Optional
from pydantic import BaseModel, ConfigDict, Field, field_validator


class MealTypeBase(BaseModel):
    code: str = Field(..., min_length=1, max_length=30, description="Mã bữa ăn (breakfast, lunch, dinner, snack, all_day...)")
    name: str = Field(..., min_length=1, max_length=100, description="Tên bữa ăn (Bữa sáng, Bữa trưa...)")
    description: Optional[str] = Field(None, max_length=500, description="Mô tả bữa ăn")
    start_time: Optional[time] = Field(None, description="Giờ bắt đầu gợi ý (HH:MM:SS)")
    end_time: Optional[time] = Field(None, description="Giờ kết thúc gợi ý (HH:MM:SS)")
    sort_order: int = Field(0, ge=0, description="Thứ tự hiển thị")
    is_active: bool = Field(True, description="Trạng thái kích hoạt")

    @field_validator("code")
    @classmethod
    def validate_code(cls, v: str) -> str:
        v = v.strip().lower()
        if not v:
            raise ValueError("Mã bữa ăn không được để trống.")
        return v

    @field_validator("name")
    @classmethod
    def validate_name(cls, v: str) -> str:
        v = v.strip()
        if not v:
            raise ValueError("Tên bữa ăn không được để trống.")
        return v


class MealTypeCreate(MealTypeBase):
    pass


class MealTypeUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=1, max_length=100)
    description: Optional[str] = Field(None, max_length=500)
    start_time: Optional[time] = None
    end_time: Optional[time] = None
    sort_order: Optional[int] = Field(None, ge=0)
    is_active: Optional[bool] = None

    @field_validator("name")
    @classmethod
    def validate_name(cls, v: Optional[str]) -> Optional[str]:
        if v is not None:
            v = v.strip()
            if not v:
                raise ValueError("Tên bữa ăn không được để trống.")
            return v
        return None


class MealTypeResponse(MealTypeBase):
    id: int
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)
