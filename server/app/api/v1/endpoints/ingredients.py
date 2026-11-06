from typing import Optional
from fastapi import APIRouter, Depends, Query, Path, status
from sqlalchemy.orm import Session

from server.app.db.session import get_db
from server.app.schemas.ingredient import (
    IngredientCreate,
    IngredientUpdate,
    IngredientResponse,
    IngredientDetailResponse,
    IngredientListResponse,
)
from server.app.services.ingredient_service import IngredientService

router = APIRouter()


@router.get(
    "",
    response_model=IngredientListResponse,
    summary="Lấy danh sách nguyên liệu toàn cục (Master Ingredients)",
)
def get_ingredients(
    skip: int = Query(0, ge=0, description="Vị trí bắt đầu lấy dữ liệu"),
    limit: int = Query(100, ge=1, le=500, description="Số lượng bản ghi tối đa trả về"),
    search: Optional[str] = Query(None, description="Từ khóa tìm kiếm theo tên hoặc mô tả"),
    group_id: Optional[int] = Query(None, description="Lọc theo ID nhóm nguyên liệu"),
    allergen_group: Optional[str] = Query(None, description="Lọc theo nhóm dị ứng (Hải sản, Sữa, Trứng...)"),
    is_active_only: bool = Query(False, description="Chỉ lấy các nguyên liệu đang hoạt động"),
    db: Session = Depends(get_db),
):
    return IngredientService.get_ingredients(
        db=db,
        skip=skip,
        limit=limit,
        search=search,
        group_id=group_id,
        allergen_group=allergen_group,
        is_active_only=is_active_only,
    )


@router.post(
    "",
    response_model=IngredientResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Tạo mới một nguyên liệu toàn cục",
)
def create_ingredient(
    ingredient_in: IngredientCreate,
    db: Session = Depends(get_db),
):
    return IngredientService.create_ingredient(
        db=db,
        data=ingredient_in,
    )


@router.get(
    "/{id}",
    response_model=IngredientDetailResponse,
    summary="Xem thông tin chi tiết một nguyên liệu và danh sách món ăn sử dụng",
)
def get_ingredient_detail(
    id: int = Path(..., description="Mã định danh của nguyên liệu", ge=1),
    db: Session = Depends(get_db),
):
    return IngredientService.get_ingredient_by_id(
        db=db,
        ingredient_id=id,
    )


@router.put(
    "/{id}",
    response_model=IngredientResponse,
    summary="Cập nhật thông tin nguyên liệu",
)
def update_ingredient(
    ingredient_in: IngredientUpdate,
    id: int = Path(..., description="Mã định danh của nguyên liệu", ge=1),
    db: Session = Depends(get_db),
):
    return IngredientService.update_ingredient(
        db=db,
        ingredient_id=id,
        data=ingredient_in,
    )


@router.delete(
    "/{id}",
    status_code=status.HTTP_200_OK,
    summary="Xóa nguyên liệu khỏi hệ thống",
)
def delete_ingredient(
    id: int = Path(..., description="Mã định danh của nguyên liệu", ge=1),
    force: bool = Query(False, description="Bắt buộc xóa ngay cả khi đang có món ăn sử dụng"),
    db: Session = Depends(get_db),
):
    IngredientService.delete_ingredient(
        db=db,
        ingredient_id=id,
        force=force,
    )
    return {"message": f"Xóa nguyên liệu ID {id} thành công"}
