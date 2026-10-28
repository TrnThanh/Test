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
    """Lấy danh sách các phân loại bữa ăn trong ngày."""
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
    """Lấy thông tin chi tiết của một loại bữa ăn."""
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
    """Tạo mới một loại bữa ăn."""
    # Tạo bản ghi loại bữa ăn mới
    return MealTypeService.create_meal_type(db, data)
