from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, ConfigDict, Field, field_validator
from server.app.schemas.category import CategoryResponse


class WeatherBase(BaseModel):
    code: str = Field(..., min_length=1, max_length=50, description="Mã trạng thái thời tiết (hot, cold, rainy, mild, SPRING_PATTERN_001...)")
    name: str = Field(..., min_length=1, max_length=255, description="Tên thời tiết (Nắng nóng, Mưa rào, Trời lạnh...)")
    description: Optional[str] = Field(None, max_length=5000, description="Mô tả thời tiết")
    min_temp: Optional[float] = Field(None, ge=-50.0, le=60.0, description="Nhiệt độ tối thiểu (°C)")
    max_temp: Optional[float] = Field(None, ge=-50.0, le=60.0, description="Nhiệt độ tối đa (°C)")
    min_humidity: Optional[int] = Field(None, ge=0, le=100, description="Độ ẩm tối thiểu (%)")
    max_humidity: Optional[int] = Field(None, ge=0, le=100, description="Độ ẩm tối đa (%)")
    condition: Optional[str] = Field(None, max_length=100, description="Điều kiện khí hậu")
    icon: Optional[str] = Field(None, max_length=100, description="Tên icon hoặc URL")
    season: Optional[str] = Field(None, max_length=50, description="Mùa trong năm (spring, summer, autumn, winter, dry, rainy...)")
    sort_order: int = Field(0, ge=0, description="Thứ tự hiển thị")
    is_active: bool = Field(True, description="Trạng thái kích hoạt")

    @field_validator("code")
    @classmethod
    def validate_code(cls, v: str) -> str:
        v = v.strip()
        if not v:
            raise ValueError("Mã thời tiết không được để trống.")
        return v

    @field_validator("name")
    @classmethod
    def validate_name(cls, v: str) -> str:
        v = v.strip()
        if not v:
            raise ValueError("Tên thời tiết không được để trống.")
        return v


class WeatherCreate(WeatherBase):
    pass


class WeatherUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=1, max_length=255)
    description: Optional[str] = Field(None, max_length=5000)
    min_temp: Optional[float] = Field(None, ge=-50.0, le=60.0)
    max_temp: Optional[float] = Field(None, ge=-50.0, le=60.0)
    min_humidity: Optional[int] = Field(None, ge=0, le=100)
    max_humidity: Optional[int] = Field(None, ge=0, le=100)
    condition: Optional[str] = Field(None, max_length=100)
    icon: Optional[str] = Field(None, max_length=100)
    season: Optional[str] = Field(None, max_length=50)
    sort_order: Optional[int] = Field(None, ge=0)
    is_active: Optional[bool] = None

    @field_validator("name")
    @classmethod
    def validate_name(cls, v: Optional[str]) -> Optional[str]:
        if v is not None:
            v = v.strip()
            if not v:
                raise ValueError("Tên thời tiết không được để trống.")
            return v
        return None


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
