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


# [POSTMAN GUIDE]
# POST http://localhost:8001/api/v1/weather-categories/weathers/1/categories/2
# Headers: (Không yêu cầu)
# Đầu vào (Path Param):
#   - weather_id  : 1 (int, bắt buộc)
#   - category_id : 2 (int, bắt buộc)
# Status Code gợi ý:
#   - 201 Created  : Thiết lập liên kết thời tiết và danh mục thành công
#   - 404 Not Found: Trạng thái thời tiết hoặc danh mục không tồn tại
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
    # Tạo liên kết trong CSDL (idempotent)
    return WeatherCategoryService.link_weather_category(
        db, weather_id=weather_id, category_id=category_id
    )


# [POSTMAN GUIDE]
# DELETE http://localhost:8001/api/v1/weather-categories/weathers/1/categories/2
# Headers: (Không yêu cầu)
# Đầu vào (Path Param):
#   - weather_id  : 1 (int, bắt buộc)
#   - category_id : 2 (int, bắt buộc)
# Status Code gợi ý:
#   - 200 OK       : Hủy liên kết giữa thời tiết và danh mục thành công
#   - 404 Not Found: Bản ghi liên kết không tồn tại
@router.delete(
    "/weathers/{weather_id}/categories/{category_id}",
    summary="Hủy liên kết giữa thời tiết và danh mục món ăn",
)
def unlink_weather_category(
    weather_id: int,
    category_id: int,
    db: Session = Depends(get_db),
):
    # 1. Gọi service xóa liên kết
    WeatherCategoryService.unlink_weather_category(
        db, weather_id=weather_id, category_id=category_id
    )
    # 2. Trả về thông báo thành công
    return {"message": "Đã hủy liên kết thời tiết và danh mục thành công"}


# [POSTMAN GUIDE]
# GET http://localhost:8001/api/v1/weather-categories/weathers/1/categories
# Headers: (Không yêu cầu)
# Đầu vào (Path Param):
#   - weather_id: 1 (int, bắt buộc)
# Status Code gợi ý:
#   - 200 OK       : Lấy danh sách các danh mục món ăn theo trạng thái thời tiết thành công
#   - 404 Not Found: Trạng thái thời tiết không tồn tại
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
    # Lấy danh sách danh mục theo ID thời tiết
    return WeatherCategoryService.get_categories_by_weather(db, weather_id=weather_id)


# [POSTMAN GUIDE]
# GET http://localhost:8001/api/v1/weather-categories/categories/2/weathers
# Headers: (Không yêu cầu)
# Đầu vào (Path Param):
#   - category_id: 2 (int, bắt buộc)
# Status Code gợi ý:
#   - 200 OK       : Lấy danh sách trạng thái thời tiết áp dụng cho một danh mục thành công
#   - 404 Not Found: Danh mục món ăn không tồn tại
@router.get(
    "/categories/{category_id}/weathers",
    response_model=List[WeatherResponse],
    summary="Lấy danh sách trạng thái thời tiết áp dụng cho một danh mục món ăn",
)
def get_weathers_by_category(
    category_id: int,
    db: Session = Depends(get_db),
):
    # Lấy danh sách thời tiết theo ID danh mục
    return WeatherCategoryService.get_weathers_by_category(db, category_id=category_id)


# [POSTMAN GUIDE]
# POST http://localhost:8001/api/v1/weather-categories
# Headers:
#   Content-Type: application/json
# Đầu vào (Body raw JSON):
# {
#   "weather_id": 1,  // int (bắt buộc)
#   "category_id": 2  // int (bắt buộc)
# }
# Status Code gợi ý:
#   - 201 Created              : Tạo liên kết thời tiết và danh mục thành công
#   - 404 Not Found            : Trạng thái thời tiết hoặc danh mục không tồn tại
#   - 422 Unprocessable Content: Sai kiểu dữ liệu
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
    # Tạo liên kết từ dữ liệu body
    return WeatherCategoryService.link_weather_category(
        db, weather_id=data.weather_id, category_id=data.category_id
    )


# [POSTMAN GUIDE]
# GET http://localhost:8001/api/v1/weather-categories?weather_id=1&skip=0&limit=50
# Headers: (Không yêu cầu)
# Đầu vào (Query Params):
#   - weather_id  : 1  (int, tuỳ chọn)
#   - category_id : 2  (int, tuỳ chọn)
#   - skip        : 0  (int, default: 0)
#   - limit       : 50 (int 1-100, default: 100)
# Status Code gợi ý:
#   - 200 OK: Lấy danh sách các bản ghi liên kết thời tiết - danh mục thành công
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
    # Truy vấn danh sách liên kết qua hàm get_all_links của service
    return WeatherCategoryService.get_all_links(
        db, weather_id=weather_id, category_id=category_id, skip=skip, limit=limit
    )
