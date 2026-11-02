import re
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
    rating: Optional[float] = Field(None, ge=0.0, le=5.0, description="Điểm đánh giá chất lượng quán ăn (0.0 đến 5.0)")
    admin_rating: Optional[float] = Field(None, ge=0.0, le=5.0, description="Điểm đánh giá thẩm định của Quản trị viên (0.0 đến 5.0)")

    @field_validator("name")
    @classmethod
    def validate_restaurant_name(cls, v: str) -> str:
        v = v.strip()
        if not v:
            raise ValueError("Tên quán ăn không được để trống.")
        return v

    @field_validator("address")
    @classmethod
    def validate_restaurant_address(cls, v: str) -> str:
        v = v.strip()
        if not v:
            raise ValueError("Địa chỉ quán ăn không được để trống.")
        return v

    @field_validator("phone")
    @classmethod
    def validate_restaurant_phone(cls, v: Optional[str]) -> Optional[str]:
        if v is None:
            return None
        v = v.strip()
        if not v:
            return None
        cleaned_phone = v.replace("-", "").replace(".", "").replace(" ", "")
        phone_regex = r"^(0|\+84)[0-9]{9,10}$"
        if not re.match(phone_regex, cleaned_phone):
            raise ValueError("Số điện thoại quán ăn không hợp lệ (phải từ 10-11 chữ số).")
        return cleaned_phone

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
    rating: Optional[float] = Field(None, ge=0.0, le=5.0, description="Điểm đánh giá chất lượng quán ăn (0.0 đến 5.0)")
    admin_rating: Optional[float] = Field(None, ge=0.0, le=5.0, description="Điểm đánh giá thẩm định của Quản trị viên (0.0 đến 5.0)")
    is_active: Optional[bool] = Field(None, description="Trạng thái hoạt động")

    @field_validator("name")
    @classmethod
    def validate_restaurant_name(cls, v: Optional[str]) -> Optional[str]:
        if v is not None:
            v = v.strip()
            if not v:
                raise ValueError("Tên quán ăn không được để trống.")
            return v
        return None

    @field_validator("address")
    @classmethod
    def validate_restaurant_address(cls, v: Optional[str]) -> Optional[str]:
        if v is not None:
            v = v.strip()
            if not v:
                raise ValueError("Địa chỉ quán ăn không được để trống.")
            return v
        return None

    @field_validator("phone")
    @classmethod
    def validate_restaurant_phone(cls, v: Optional[str]) -> Optional[str]:
        if v is None:
            return None
        v = v.strip()
        if not v:
            return None
        cleaned_phone = v.replace("-", "").replace(".", "").replace(" ", "")
        phone_regex = r"^(0|\+84)[0-9]{9,10}$"
        if not re.match(phone_regex, cleaned_phone):
            raise ValueError("Số điện thoại quán ăn không hợp lệ (phải từ 10-11 chữ số).")
        return cleaned_phone

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


class RestaurantRouteResponse(BaseModel):
    restaurant_id: int
    restaurant_name: str
    distance_meters: float = Field(..., description="Quãng đường đi bộ thực tế (mét)")
    duration_seconds: float = Field(..., description="Thời gian đi bộ ước tính (giây)")
    coordinates: List[List[float]] = Field(..., description="Mảng toạ độ tuyến đường [[lon, lat], ...]")
    is_fallback: bool = Field(False, description="Đánh dấu nếu đang dùng tuyến ước lượng đường chim bay")
