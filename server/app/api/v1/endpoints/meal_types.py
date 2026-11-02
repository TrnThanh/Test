from typing import List
from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from server.app.db.session import get_db
from server.app.schemas.meal_type import MealTypeResponse, MealTypeCreate
from server.app.services.meal_type_service import MealTypeService

router = APIRouter()


# Lấy danh sách các loại bữa ăn (Sáng, Trưa, Tối, Ăn vặt, Cả ngày)
@router.get(
    "",
    response_model=List[MealTypeResponse],
    summary="Lấy danh sách các loại bữa ăn",
    description="Truy vấn danh sách bữa ăn (Sáng, Trưa, Tối, Ăn vặt, Cả ngày) kèm khung giờ gợi ý.",
)
def list_meal_types(
    active_only: bool = True,
    db: Session = Depends(get_db),
):
    """
    [POSTMAN TEST GUIDE]
    - Method  : GET
    - URL     : http://localhost:8001/api/v1/meal-types?active_only=true
    - Headers : (Không yêu cầu)
    - Params  : active_only (bool, mặc định true)
    - Body    : (Không có)
    - Expected: 200 OK -> [{"id": 1, "code": "breakfast", "name": "Bữa sáng", "start_time": "06:00:00", "end_time": "10:00:00", "is_active": true}]
    """
    # 1. Khởi tạo các loại bữa ăn mặc định nếu chưa tồn tại
    MealTypeService.seed_default_meal_types(db)
    # 2. Truy vấn danh sách từ cơ sở dữ liệu
    return MealTypeService.get_all_meal_types(db, active_only=active_only)


# Xem thông tin chi tiết một phân loại bữa ăn cụ thể theo ID
@router.get(
    "/{meal_type_id}",
    response_model=MealTypeResponse,
    summary="Chi tiết một loại bữa ăn",
)
def get_meal_type(
    meal_type_id: int,
    db: Session = Depends(get_db),
):
    """
    [POSTMAN TEST GUIDE]
    - Method  : GET
    - URL     : http://localhost:8001/api/v1/meal-types/1
    - Headers : (Không yêu cầu)
    - Params  : Path meal_type_id (int)
    - Body    : (Không có)
    - Expected: 200 OK -> {"id": 1, "code": "breakfast", "name": "Bữa sáng", ...}
    - Errors  : 404 Not Found
    """
    # Truy vấn loại bữa ăn theo ID
    return MealTypeService.get_meal_type_by_id(db, meal_type_id)


# Tạo mới một phân loại bữa ăn tùy chỉnh vào hệ thống
@router.post(
    "",
    response_model=MealTypeResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Tạo mới loại bữa ăn",
)
def create_meal_type(
    data: MealTypeCreate,
    db: Session = Depends(get_db),
):
    """
    [POSTMAN TEST GUIDE]
    - Method  : POST
    - URL     : http://localhost:8001/api/v1/meal-types
    - Headers : Content-Type: application/json
    - Params  : (Không có)
    - Body (raw JSON):
      {
        "code": "midnight_snack",
        "name": "Ăn đêm",
        "description": "Bữa phụ sau 23h",
        "start_time": "23:00:00",
        "end_time": "02:00:00",
        "display_order": 5,
        "is_active": true
      }
    - Expected: 201 Created -> {"id": 6, "code": "midnight_snack", "name": "Ăn đêm", ...}
    - Errors  : 400 Bad Request (trùng code), 422 Unprocessable Content
    """
    # Tạo bản ghi loại bữa ăn mới
    return MealTypeService.create_meal_type(db, data)
