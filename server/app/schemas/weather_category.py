from datetime import datetime
from typing import Optional
from pydantic import BaseModel, ConfigDict, Field
from server.app.schemas.weather import WeatherResponse
from server.app.schemas.category import CategoryResponse


class WeatherCategoryBase(BaseModel):
    weather_id: int = Field(..., description="ID của trạng thái thời tiết")
    category_id: int = Field(..., description="ID của danh mục món ăn")


class WeatherCategoryCreate(WeatherCategoryBase):
    pass


class WeatherCategoryResponse(WeatherCategoryBase):
    id: int = Field(..., description="ID liên kết")
    created_at: datetime = Field(..., description="Thời điểm tạo liên kết")

    model_config = ConfigDict(from_attributes=True)


class WeatherCategoryDetailResponse(WeatherCategoryResponse):
    weather: Optional[WeatherResponse] = None
    category: Optional[CategoryResponse] = None

    model_config = ConfigDict(from_attributes=True)
