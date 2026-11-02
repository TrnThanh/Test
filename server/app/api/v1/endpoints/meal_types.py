from typing import List
from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from server.app.db.session import get_db
from server.app.schemas.meal_type import MealTypeResponse, MealTypeCreate
from server.app.services.meal_type_service import MealTypeService

router = APIRouter()


# [POSTMAN GUIDE]
# GET http://localhost:8001/api/v1/meal-types?active_only=true
# Headers: (Không yêu cầu)
# Đầu vào (Query Params):
#   - active_only: true (bool, default: true)
# Status Code gợi ý:
#   - 200 OK: Lấy danh sách các loại bữa ăn thành công (Sáng, Trưa, Tối, Ăn vặt, Cả ngày)
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
    # 1. Khởi tạo các loại bữa ăn mặc định nếu chưa tồn tại
    MealTypeService.seed_default_meal_types(db)
    # 2. Truy vấn danh sách từ cơ sở dữ liệu
    return MealTypeService.get_all_meal_types(db, active_only=active_only)


# [POSTMAN GUIDE]
# GET http://localhost:8001/api/v1/meal-types/1
# Headers: (Không yêu cầu)
# Đầu vào (Path Param):
#   - meal_type_id: 1 (int, bắt buộc)
# Status Code gợi ý:
#   - 200 OK       : Chi tiết một loại bữa ăn thành công
#   - 404 Not Found: Không tìm thấy loại bữa ăn
@router.get(
    "/{meal_type_id}",
    response_model=MealTypeResponse,
    summary="Chi tiết một loại bữa ăn",
)
def get_meal_type(
    meal_type_id: int,
    db: Session = Depends(get_db),
):
    # Truy vấn loại bữa ăn theo ID
    return MealTypeService.get_meal_type_by_id(db, meal_type_id)


# [POSTMAN GUIDE]
# POST http://localhost:8001/api/v1/meal-types
# Headers:
#   Content-Type: application/json
# Đầu vào (Body raw JSON):
# {
#   "code": "midnight_snack",    // string (bắt buộc, unique)
#   "name": "Ăn đêm",            // string (bắt buộc)
#   "description": "Bữa phụ 23h", // string (tuỳ chọn)
#   "start_time": "23:00:00",    // string HH:MM:SS (tuỳ chọn)
#   "end_time": "02:00:00",      // string HH:MM:SS (tuỳ chọn)
#   "display_order": 5,          // int (tuỳ chọn)
#   "is_active": true            // bool (tuỳ chọn, default: true)
# }
# Status Code gợi ý:
#   - 201 Created              : Tạo mới loại bữa ăn thành công
#   - 400 Bad Request          : Mã code đã tồn tại
#   - 422 Unprocessable Content: Thiếu trường bắt buộc hoặc sai định dạng giờ
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
    # Tạo bản ghi loại bữa ăn mới
    return MealTypeService.create_meal_type(db, data)
