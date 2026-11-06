from typing import List, Optional
from pydantic import BaseModel, ConfigDict, Field
from server.app.schemas.restaurant import HHMMTime


class ContextInfo(BaseModel):
    meal_period: str = Field(..., description="Tên bữa ăn hiện tại (Bữa sáng, Bữa trưa...)")
    meal_time_range: str = Field(..., description="Khung giờ bữa ăn (VD: 10:00 - 14:00)")
    weather_desc: str = Field(..., description="Mô tả thời tiết hiện tại")
    target_calories_display: str = Field(..., description="Khoảng calo mục tiêu (VD: 550 - 750 kcal)")
    unverified_allergies: List[str] = Field(default_factory=list, description="Các dị ứng user khai báo nhưng hệ thống chưa có dữ liệu kiểm định")
    guest_notice: Optional[str] = Field(None, description="Lời nhắc đăng nhập cho khách vãng lai")
    disclaimer: str = Field(..., description="Tuyên bố miễn trừ y tế & an toàn thực phẩm")


class FeaturedDishInfo(BaseModel):
    id: int
    name: str
    price: float
    calories: Optional[int] = None
    image_url: Optional[str] = None
    category_id: Optional[int] = None
    dietary_tags: List[str] = Field(default_factory=list)


class RecommendationDetail(BaseModel):
    score: float = Field(..., description="Điểm đánh giá phù hợp (thang điểm 0 - 100)")
    featured_dish: FeaturedDishInfo = Field(..., description="Món ăn tiêu biểu phù hợp nhất của quán")
    badges: List[str] = Field(default_factory=list, description="Các huy hiệu nổi bật (Hợp Bữa trưa, Chuẩn ATTP...)")
    explanation: Optional[str] = Field(None, description="Lời giải thích lý do đề xuất quán ăn")


class RecommendedRestaurant(BaseModel):
    id: int
    name: str
    address: str
    latitude: float
    longitude: float
    phone: Optional[str] = None
    open_time: Optional[HHMMTime] = None
    close_time: Optional[HHMMTime] = None
    is_sponsor: bool = False
    rating: Optional[float] = None
    overall_rating: Optional[float] = None
    admin_rating: Optional[float] = None
    service_licenses: List[str] = Field(default_factory=list)
    distance_km: float = Field(..., description="Khoảng cách tính theo km")
    distance_display: str = Field(..., description="Khoảng cách hiển thị thân thiện (850m hoặc 1.2 km)")
    recommendation: RecommendationDetail

    model_config = ConfigDict(from_attributes=True)


class ContextualRecommendationResponse(BaseModel):
    context: ContextInfo
    hero_restaurant: Optional[RecommendedRestaurant] = None
    recommended_restaurants: List[RecommendedRestaurant] = Field(default_factory=list)
