from typing import List, Optional
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from server.app.db.session import get_db
from server.app.schemas.weather import WeatherResponse, WeatherCreate, CurrentWeatherResponse
from server.app.services.weather_service import WeatherService

router = APIRouter()


@router.get(
    "/current",
    response_model=CurrentWeatherResponse,
    summary="Lấy thời tiết thực tế hiện tại & danh mục món ăn phù hợp (OpenWeatherMap)",
    description="Truy vấn dữ liệu thời tiết thời gian thực theo tọa độ (mặc định Học viện Nông nghiệp Việt Nam - HVNN), tự động chuẩn hóa và trả về các danh mục món ăn phù hợp.",
)
async def get_current_weather(
    lat: Optional[float] = Query(None, description="Vĩ độ (mặc định: toạ độ HVNN 21.0046)"),
    lon: Optional[float] = Query(None, description="Kinh độ (mặc định: toạ độ HVNN 105.9387)"),
    db: Session = Depends(get_db),
) -> CurrentWeatherResponse:
    # Đảm bảo dữ liệu thời tiết mặc định đã được khởi tạo
    WeatherService.seed_default_weathers(db)
    return await WeatherService.fetch_current_weather(db=db, lat=lat, lon=lon)


@router.get(
    "",
    response_model=List[WeatherResponse],
    summary="Lấy danh sách trạng thái thời tiết",
    description="Truy vấn danh sách các điều kiện thời tiết chuẩn bị cho tính năng gợi ý món ăn theo thời tiết.",
)
def list_weathers(
    active_only: bool = True,
    db: Session = Depends(get_db),
):
    # Đảm bảo luôn có dữ liệu mặc định
    WeatherService.seed_default_weathers(db)
    return WeatherService.get_all_weathers(db, active_only=active_only)


@router.get(
    "/{weather_id}",
    response_model=WeatherResponse,
    summary="Chi tiết một trạng thái thời tiết",
)
def get_weather(
    weather_id: int,
    db: Session = Depends(get_db),
):
    return WeatherService.get_weather_by_id(db, weather_id)


@router.post(
    "",
    response_model=WeatherResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Tạo mới trạng thái thời tiết",
)
def create_weather(
    data: WeatherCreate,
    db: Session = Depends(get_db),
):
    return WeatherService.create_weather(db, data)
