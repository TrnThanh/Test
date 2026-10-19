from datetime import datetime
from typing import Optional
from pydantic import BaseModel, ConfigDict, Field


class WeatherBase(BaseModel):
    code: str = Field(..., max_length=30, description="Mã trạng thái thời tiết (hot, cold, rainy, mild...)")
    name: str = Field(..., max_length=100, description="Tên thời tiết (Nắng nóng, Mưa rào, Trời lạnh...)")
    description: Optional[str] = Field(None, max_length=500, description="Mô tả thời tiết")
    min_temp: Optional[float] = Field(None, description="Nhiệt độ tối thiểu (°C)")
    max_temp: Optional[float] = Field(None, description="Nhiệt độ tối đa (°C)")
    condition: Optional[str] = Field(None, max_length=50, description="Điều kiện khí hậu")
    icon: Optional[str] = Field(None, max_length=100, description="Tên icon hoặc URL")
    sort_order: int = Field(0, description="Thứ tự hiển thị")
    is_active: bool = Field(True, description="Trạng thái kích hoạt")


class WeatherCreate(WeatherBase):
    pass


class WeatherUpdate(BaseModel):
    name: Optional[str] = Field(None, max_length=100)
    description: Optional[str] = Field(None, max_length=500)
    min_temp: Optional[float] = None
    max_temp: Optional[float] = None
    condition: Optional[str] = Field(None, max_length=50)
    icon: Optional[str] = Field(None, max_length=100)
    sort_order: Optional[int] = None
    is_active: Optional[bool] = None


class WeatherResponse(WeatherBase):
    id: int
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)
