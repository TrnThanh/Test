from typing import List
from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from server.app.db.session import get_db
from server.app.schemas.meal_type import MealTypeResponse, MealTypeCreate
from server.app.services.meal_type_service import MealTypeService

router = APIRouter()


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
    # Đảm bảo luôn có dữ liệu mặc định
    MealTypeService.seed_default_meal_types(db)
    return MealTypeService.get_all_meal_types(db, active_only=active_only)


@router.get(
    "/{meal_type_id}",
    response_model=MealTypeResponse,
    summary="Chi tiết một loại bữa ăn",
)
def get_meal_type(
    meal_type_id: int,
    db: Session = Depends(get_db),
):
    return MealTypeService.get_meal_type_by_id(db, meal_type_id)


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
    return MealTypeService.create_meal_type(db, data)
