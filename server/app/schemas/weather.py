from datetime import datetime
from typing import Optional, List, Dict, Any
from pydantic import BaseModel, ConfigDict, Field, field_validator, computed_field
from server.app.schemas.category import CategoryResponse


class HourlyWeatherItem(BaseModel):
    hour: int = Field(..., ge=0, le=23, description="Khung giờ quan trắc trong ngày (0-23)")
    temperature: float = Field(..., description="Nhiệt độ (°C)")
    humidity: float = Field(..., description="Độ ẩm (%)")
    precipitation: float = Field(0.0, description="Lượng mưa (mm)")
    weather_code: int = Field(0, description="Mã điều kiện thời tiết số")
    condition: str = Field(..., description="Điều kiện thời tiết (SUNNY, CLOUDY, RAIN...)")
    icon: str = Field(..., description="Icon minh họa thời tiết")

    @computed_field
    @property
    def hour_display(self) -> str:
        """Định dạng khung giờ 12-hour AM/PM (vd: 7:00 AM)."""
        from server.app.core.time_utils import format_hour_12h
        return format_hour_12h(self.hour) or ""


class WeatherBase(BaseModel):
    code: str = Field(..., min_length=1, max_length=60, description="Mã trạng thái thời tiết (SPRING_PATTERN_0001_H00...)")
    pattern_code: Optional[str] = Field(None, max_length=50, description="Mã nhóm mẫu thời tiết (SPRING_PATTERN_0001...)")
    hour: Optional[int] = Field(None, ge=0, le=23, description="Khung giờ quan trắc trong ngày (0-23)")
    name: str = Field(..., min_length=1, max_length=255, description="Tên thời tiết (Trời quang / Nắng đẹp...)")
    description: Optional[str] = Field(None, max_length=5000, description="Mô tả thời tiết")
    temperature: Optional[float] = Field(None, ge=-50.0, le=60.0, description="Nhiệt độ mẫu (°C)")
    humidity: Optional[float] = Field(None, ge=0.0, le=100.0, description="Độ ẩm mẫu (%)")
    precipitation: Optional[float] = Field(0.0, description="Lượng mưa tại thời điểm (mm)")
    weather_code: Optional[int] = Field(0, description="Mã số điều kiện thời tiết")
    condition: Optional[str] = Field(None, max_length=100, description="Điều kiện khí hậu")
    icon: Optional[str] = Field(None, max_length=100, description="Tên icon hoặc URL")
    season_id: Optional[int] = Field(None, ge=1, le=4, description="ID mùa trong năm (1: Xuân, 2: Hạ, 3: Thu, 4: Đông)")
    season: Optional[str] = Field(None, max_length=50, description="Mùa trong năm (spring, summer, autumn, winter)")
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
    pattern_code: Optional[str] = Field(None, max_length=50)
    hour: Optional[int] = Field(None, ge=0, le=23)
    name: Optional[str] = Field(None, min_length=1, max_length=255)
    description: Optional[str] = Field(None, max_length=5000)
    temperature: Optional[float] = Field(None, ge=-50.0, le=60.0)
    humidity: Optional[float] = Field(None, ge=0.0, le=100.0)
    precipitation: Optional[float] = None
    weather_code: Optional[int] = None
    condition: Optional[str] = Field(None, max_length=100)
    icon: Optional[str] = Field(None, max_length=100)
    season_id: Optional[int] = Field(None, ge=1, le=4)
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

    @computed_field
    @property
    def hour_display(self) -> Optional[str]:
        """Khung giờ định dạng trực quan 12-hour AM/PM (vd: 7:00 AM, 12:00 PM)."""
        from server.app.core.time_utils import format_hour_12h
        return format_hour_12h(self.hour)

    @computed_field
    @property
    def season_name(self) -> Optional[str]:
        """Tên tiếng Việt của mùa (Xuân, Hạ, Thu, Đông)."""
        mapping = {1: "Xuân", 2: "Hạ", 3: "Thu", 4: "Đông"}
        if self.season_id in mapping:
            return mapping[self.season_id]
        if self.season:
            code_mapping = {"spring": "Xuân", "summer": "Hạ", "autumn": "Thu", "winter": "Đông"}
            return code_mapping.get(self.season.lower())
        return None

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
