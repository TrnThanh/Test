from datetime import datetime, time
from typing import Optional, List, Annotated
from pydantic import BaseModel, ConfigDict, Field, BeforeValidator, PlainSerializer, field_validator


def parse_time_or_none(v: Optional[object]) -> Optional[object]:
    if v is None or (isinstance(v, str) and not v.strip()):
        return None
    return v


HHMMTime = Annotated[
    Optional[time],
    BeforeValidator(parse_time_or_none),
    PlainSerializer(
        lambda t: t.strftime("%H:%M") if t else None,
        return_type=Optional[str],
        when_used="json-unless-none",
    ),
]


class RestaurantBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=255, description="Tên quán ăn")
    address: str = Field(..., min_length=1, max_length=500, description="Địa chỉ cụ thể của quán ăn")
    latitude: float = Field(..., ge=-90.0, le=90.0, description="Vĩ độ (-90 đến 90)")
    longitude: float = Field(..., ge=-180.0, le=180.0, description="Kinh độ (-180 đến 180)")
    phone: Optional[str] = Field(None, max_length=50, description="Số điện thoại quán")
    description: Optional[str] = Field(None, max_length=1000, description="Mô tả quán ăn")
    open_time: Optional[HHMMTime] = Field(None, description="Thời gian mở cửa (HH:MM)")
    close_time: Optional[HHMMTime] = Field(None, description="Thời gian đóng cửa (HH:MM)")
    service_licenses: List[str] = Field(default_factory=list, description="Danh sách giấy phép dịch vụ của quán (ATTP, PCCC, GPKD...)")
    is_sponsor: bool = Field(False, description="Đánh dấu quán ăn là nhà tài trợ")

    @field_validator("service_licenses")
    @classmethod
    def normalize_licenses(cls, v: List[str]) -> List[str]:
        cleaned: List[str] = []
        for lic in v:
            lic = lic.strip()
            if lic and lic not in cleaned:
                cleaned.append(lic)
        return cleaned


class RestaurantCreate(RestaurantBase):
    pass


class RestaurantUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=1, max_length=255, description="Tên quán ăn")
    address: Optional[str] = Field(None, min_length=1, max_length=500, description="Địa chỉ quán ăn")
    latitude: Optional[float] = Field(None, ge=-90.0, le=90.0, description="Vĩ độ (-90 đến 90)")
    longitude: Optional[float] = Field(None, ge=-180.0, le=180.0, description="Kinh độ (-180 đến 180)")
    phone: Optional[str] = Field(None, max_length=50, description="Số điện thoại quán")
    description: Optional[str] = Field(None, max_length=1000, description="Mô tả quán ăn")
    open_time: Optional[HHMMTime] = Field(None, description="Thời gian mở cửa (HH:MM)")
    close_time: Optional[HHMMTime] = Field(None, description="Thời gian đóng cửa (HH:MM)")
    service_licenses: Optional[List[str]] = Field(None, description="Danh sách giấy phép dịch vụ của quán")
    is_sponsor: Optional[bool] = Field(None, description="Đánh dấu quán ăn là nhà tài trợ")
    is_active: Optional[bool] = Field(None, description="Trạng thái hoạt động")

    @field_validator("service_licenses")
    @classmethod
    def normalize_licenses(cls, v: Optional[List[str]]) -> Optional[List[str]]:
        if v is not None:
            cleaned: List[str] = []
            for lic in v:
                lic = lic.strip()
                if lic and lic not in cleaned:
                    cleaned.append(lic)
            return cleaned
        return None


class RestaurantResponse(RestaurantBase):
    id: int
    is_active: bool
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class NearbyRestaurantResponse(RestaurantResponse):
    distance_km: float = Field(..., description="Khoảng cách từ người dùng đến quán (km)")
    distance_meters: float = Field(..., description="Khoảng cách từ người dùng đến quán (mét)")


class DistanceResponse(BaseModel):
    restaurant_id: int
    restaurant_name: str
    distance_km: float = Field(..., description="Khoảng cách (km)")
    distance_meters: float = Field(..., description="Khoảng cách (mét)")
