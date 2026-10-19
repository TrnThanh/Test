from typing import List
from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from server.app.db.session import get_db
from server.app.schemas.weather import WeatherResponse, WeatherCreate
from server.app.services.weather_service import WeatherService

router = APIRouter()


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
