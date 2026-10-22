from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field


class PlaceItem(BaseModel):
    place_id: Optional[int] = None
    osm_id: Optional[int] = None
    osm_type: Optional[str] = None
    display_name: str
    lat: float
    lon: float
    category: Optional[str] = None
    type: Optional[str] = None
    importance: Optional[float] = None
    boundingbox: Optional[List[str]] = None


class MapSearchResponse(BaseModel):
    query: str
    count: int
    results: List[PlaceItem]
    attribution: str = "© OpenStreetMap contributors"


class MapReverseResponse(BaseModel):
    place_id: Optional[int] = None
    osm_id: Optional[int] = None
    osm_type: Optional[str] = None
    lat: float
    lon: float
    display_name: str
    address: Dict[str, Any] = Field(default_factory=dict)
    attribution: str = "© OpenStreetMap contributors"


class IpLocationResponse(BaseModel):
    lat: float = Field(..., description="Vĩ độ")
    lon: float = Field(..., description="Kinh độ")
    city: Optional[str] = Field(None, description="Tên thành phố / quận huyện")
    region: Optional[str] = Field(None, description="Tên tỉnh / vùng")
    country: Optional[str] = Field(None, description="Tên quốc gia")
    location_name: str = Field(..., description="Tên địa danh đầy đủ")
    is_fallback: bool = Field(False, description="True nếu là toạ độ mặc định fallback HVNN Gia Lâm")
    ip: Optional[str] = Field(None, description="Địa chỉ IP của client")
