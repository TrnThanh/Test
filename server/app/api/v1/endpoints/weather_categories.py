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


# Thiết lập mối liên kết N-N giữa một điều kiện thời tiết và một nhóm danh mục món ăn
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
    """Liên kết một nhóm danh mục món ăn với một điều kiện thời tiết phù hợp."""
    # Tạo liên kết trong CSDL (idempotent)
    return WeatherCategoryService.link_weather_category(
        db, weather_id=weather_id, category_id=category_id
    )


# Hủy mối liên kết giữa điều kiện thời tiết và nhóm danh mục món ăn
@router.delete(
    "/weathers/{weather_id}/categories/{category_id}",
    summary="Hủy liên kết giữa thời tiết và danh mục món ăn",
)
def unlink_weather_category(
    weather_id: int,
    category_id: int,
    db: Session = Depends(get_db),
):
    """Xóa bỏ liên kết giữa thời tiết và danh mục món ăn."""
    # 1. Gọi service xóa liên kết
    WeatherCategoryService.unlink_weather_category(
        db, weather_id=weather_id, category_id=category_id
    )
    # 2. Trả về thông báo thành công
    return {"message": "Đã hủy liên kết thời tiết và danh mục thành công"}


# Lấy danh sách các nhóm danh mục món ăn phù hợp với một điều kiện thời tiết cụ thể
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
    """Truy vấn các danh mục món ăn liên kết với kiểu thời tiết."""
    # Lấy danh sách danh mục theo ID thời tiết
    return WeatherCategoryService.get_categories_by_weather(db, weather_id=weather_id)


# Lấy danh sách các điều kiện thời tiết được áp dụng cho một danh mục món ăn cụ thể
@router.get(
    "/categories/{category_id}/weathers",
    response_model=List[WeatherResponse],
    summary="Lấy danh sách trạng thái thời tiết áp dụng cho một danh mục món ăn",
)
def get_weathers_by_category(
    category_id: int,
    db: Session = Depends(get_db),
):
    """Truy vấn các kiểu thời tiết liên kết với một danh mục."""
    # Lấy danh sách thời tiết theo ID danh mục
    return WeatherCategoryService.get_weathers_by_category(db, category_id=category_id)


# Tạo liên kết giữa thời tiết và danh mục món ăn thông qua payload request body
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
    """Tạo liên kết thời tiết - danh mục qua body JSON."""
    # Tạo liên kết từ dữ liệu body
    return WeatherCategoryService.link_weather_category(
        db, weather_id=data.weather_id, category_id=data.category_id
    )


# Lấy danh sách toàn bộ các bản ghi liên kết thời tiết - danh mục có hỗ trợ phân trang
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
    """Danh sách các bản ghi liên kết N-N giữa thời tiết và danh mục."""
    # Truy vấn danh sách liên kết qua hàm get_all_links của service
    return WeatherCategoryService.get_all_links(
        db, weather_id=weather_id, category_id=category_id, skip=skip, limit=limit
    )
