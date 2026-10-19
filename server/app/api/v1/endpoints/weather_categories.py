from typing import List, Optional
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from server.app.db.session import get_db
from server.app.schemas.weather_category import (
    WeatherCategoryCreate,
    WeatherCategoryResponse,
)
from server.app.schemas.category import CategoryResponse
from server.app.schemas.weather import WeatherResponse
from server.app.services.weather_category_service import WeatherCategoryService

router = APIRouter()


@router.post(
    "/weathers/{weather_id}/categories/{category_id}",
    response_model=WeatherCategoryResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Thiết lập liên kết giữa thời tiết và danh mục món ăn",
    description="Tạo liên kết N-N giữa một trạng thái thời tiết và một nhóm danh mục thực đơn (Idempotent).",
)
def link_weather_category(
    weather_id: int,
    category_id: int,
    db: Session = Depends(get_db),
):
    return WeatherCategoryService.link_weather_category(
        db, weather_id=weather_id, category_id=category_id
    )


@router.delete(
    "/weathers/{weather_id}/categories/{category_id}",
    summary="Hủy liên kết giữa thời tiết và danh mục món ăn",
)
def unlink_weather_category(
    weather_id: int,
    category_id: int,
    db: Session = Depends(get_db),
):
    WeatherCategoryService.unlink_weather_category(
        db, weather_id=weather_id, category_id=category_id
    )
    return {"message": "Đã hủy liên kết thời tiết và danh mục thành công"}


@router.get(
    "/weathers/{weather_id}/categories",
    response_model=List[CategoryResponse],
    summary="Lấy danh sách các danh mục món ăn theo trạng thái thời tiết",
    description="Truy vấn các nhóm danh mục phù hợp với điều kiện thời tiết (phục vụ gợi ý món ăn).",
)
def get_categories_by_weather(
    weather_id: int,
    db: Session = Depends(get_db),
):
    return WeatherCategoryService.get_categories_by_weather(db, weather_id=weather_id)


@router.get(
    "/categories/{category_id}/weathers",
    response_model=List[WeatherResponse],
    summary="Lấy danh sách trạng thái thời tiết áp dụng cho một danh mục món ăn",
)
def get_weathers_by_category(
    category_id: int,
    db: Session = Depends(get_db),
):
    return WeatherCategoryService.get_weathers_by_category(db, category_id=category_id)


@router.post(
    "",
    response_model=WeatherCategoryResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Tạo liên kết thời tiết và danh mục (qua request body)",
)
def create_weather_category(
    data: WeatherCategoryCreate,
    db: Session = Depends(get_db),
):
    return WeatherCategoryService.link_weather_category(
        db, weather_id=data.weather_id, category_id=data.category_id
    )


@router.get(
    "",
    response_model=List[WeatherCategoryResponse],
    summary="Lấy danh sách các bản ghi liên kết thời tiết - danh mục",
)
def list_weather_categories(
    weather_id: Optional[int] = Query(None, description="Lọc theo ID thời tiết"),
    category_id: Optional[int] = Query(None, description="Lọc theo ID danh mục"),
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=100),
    db: Session = Depends(get_db),
):
    return WeatherCategoryService.get_all_links(
        db, weather_id=weather_id, category_id=category_id, skip=skip, limit=limit
    )
