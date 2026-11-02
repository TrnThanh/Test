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
    """
    [POSTMAN TEST GUIDE]
    - Method  : POST
    - URL     : http://localhost:8001/api/v1/weather-categories/weathers/1/categories/2
    - Headers : (Không yêu cầu)
    - Params  : Path weather_id (int), Path category_id (int)
    - Body    : (Không có)
    - Expected: 201 Created -> {"id": 1, "weather_id": 1, "category_id": 2, "created_at": "..."}
    - Errors  : 404 Not Found (Weather hoặc Category không tồn tại)
    """
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
    """
    [POSTMAN TEST GUIDE]
    - Method  : DELETE
    - URL     : http://localhost:8001/api/v1/weather-categories/weathers/1/categories/2
    - Headers : (Không yêu cầu)
    - Params  : Path weather_id (int), Path category_id (int)
    - Body    : (Không có)
    - Expected: 200 OK -> {"message": "Đã hủy liên kết thời tiết và danh mục thành công"}
    - Errors  : 404 Not Found
    """
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
    """
    [POSTMAN TEST GUIDE]
    - Method  : GET
    - URL     : http://localhost:8001/api/v1/weather-categories/weathers/1/categories
    - Headers : (Không yêu cầu)
    - Params  : Path weather_id (int)
    - Body    : (Không có)
    - Expected: 200 OK -> [{"id": 2, "name": "Lẩu & Nướng", "is_active": true}]
    - Errors  : 404 Not Found
    """
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
    """
    [POSTMAN TEST GUIDE]
    - Method  : GET
    - URL     : http://localhost:8001/api/v1/weather-categories/categories/2/weathers
    - Headers : (Không yêu cầu)
    - Params  : Path category_id (int)
    - Body    : (Không có)
    - Expected: 200 OK -> [{"id": 1, "code": "cold", "name": "Trời lạnh", ...}]
    - Errors  : 404 Not Found
    """
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
    """
    [POSTMAN TEST GUIDE]
    - Method  : POST
    - URL     : http://localhost:8001/api/v1/weather-categories
    - Headers : Content-Type: application/json
    - Params  : (Không có)
    - Body (raw JSON):
      {
        "weather_id": 1,
        "category_id": 2
      }
    - Expected: 201 Created -> {"id": 1, "weather_id": 1, "category_id": 2, ...}
    - Errors  : 404 Not Found, 422 Unprocessable Content
    """
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
    """
    [POSTMAN TEST GUIDE]
    - Method  : GET
    - URL     : http://localhost:8001/api/v1/weather-categories?weather_id=1&skip=0&limit=50
    - Headers : (Không yêu cầu)
    - Params  : weather_id (int, tuỳ chọn), category_id (int, tuỳ chọn), skip (int), limit (int)
    - Body    : (Không có)
    - Expected: 200 OK -> [{"id": 1, "weather_id": 1, "category_id": 2, ...}]
    """
    # Truy vấn danh sách liên kết qua hàm get_all_links của service
    return WeatherCategoryService.get_all_links(
        db, weather_id=weather_id, category_id=category_id, skip=skip, limit=limit
    )
