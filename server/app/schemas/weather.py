from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, ConfigDict, Field
from server.app.schemas.category import CategoryResponse


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


class CurrentWeatherResponse(BaseModel):
    temperature: float = Field(..., description="Nhiệt độ hiện tại (°C)")
    feels_like: Optional[float] = Field(None, description="Nhiệt độ cảm nhận (°C)")
    humidity: Optional[int] = Field(None, description="Độ ẩm (%)")
    condition: str = Field(..., description="Điều kiện thời tiết (rainy, clear, clouds...)")
    description: str = Field(..., description="Mô tả chi tiết thời tiết tiếng Việt")
    icon: Optional[str] = Field(None, description="Mã icon OpenWeatherMap")
    icon_url: Optional[str] = Field(None, description="Đường dẫn ảnh icon thời tiết")
    latitude: float = Field(..., description="Vĩ độ")
    longitude: float = Field(..., description="Kinh độ")
    location_name: Optional[str] = Field(None, description="Tên địa danh (HVNN, Hà Nội)")
    matched_weather: Optional[WeatherResponse] = Field(None, description="Trạng thái Weather trong DB khớp với thời tiết này")
    recommended_categories: List[CategoryResponse] = Field(
        default_factory=list,
        description="Danh sách nhóm danh mục món ăn phù hợp với thời tiết này",
    )
    is_live: bool = Field(True, description="True nếu lấy trực tiếp từ OpenWeatherMap, False nếu dùng fallback")
