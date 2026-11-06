from typing import List, Optional
from fastapi import APIRouter, Depends, Query, Path, status
from sqlalchemy.orm import Session

from server.app.db.session import get_db
from server.app.schemas.ingredient_group import (
    IngredientGroupCreate,
    IngredientGroupUpdate,
    IngredientGroupResponse,
)
from server.app.services.ingredient_group_service import IngredientGroupService

router = APIRouter()


@router.get(
    "",
    response_model=List[IngredientGroupResponse],
    summary="Lấy danh sách các nhóm nguyên liệu (Ingredient Groups)",
)
def get_ingredient_groups(
    is_active_only: bool = Query(False, description="Chỉ lấy các nhóm đang kích hoạt"),
    db: Session = Depends(get_db),
):
    return IngredientGroupService.get_groups(
        db=db,
        is_active_only=is_active_only,
    )


@router.post(
    "",
    response_model=IngredientGroupResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Tạo mới một nhóm nguyên liệu",
)
def create_ingredient_group(
    group_in: IngredientGroupCreate,
    db: Session = Depends(get_db),
):
    return IngredientGroupService.create_group(
        db=db,
        data=group_in,
    )


@router.get(
    "/{id}",
    response_model=IngredientGroupResponse,
    summary="Xem chi tiết một nhóm nguyên liệu",
)
def get_ingredient_group(
    id: int = Path(..., description="ID nhóm nguyên liệu", ge=1),
    db: Session = Depends(get_db),
):
    return IngredientGroupService.get_group_by_id(
        db=db,
        group_id=id,
    )


@router.put(
    "/{id}",
    response_model=IngredientGroupResponse,
    summary="Cập nhật thông tin nhóm nguyên liệu",
)
def update_ingredient_group(
    group_in: IngredientGroupUpdate,
    id: int = Path(..., description="ID nhóm nguyên liệu", ge=1),
    db: Session = Depends(get_db),
):
    return IngredientGroupService.update_group(
        db=db,
        group_id=id,
        data=group_in,
    )


@router.delete(
    "/{id}",
    status_code=status.HTTP_200_OK,
    summary="Xóa một nhóm nguyên liệu",
)
def delete_ingredient_group(
    id: int = Path(..., description="ID nhóm nguyên liệu", ge=1),
    force: bool = Query(False, description="Bắt buộc xóa và gỡ liên kết nguyên liệu về null"),
    db: Session = Depends(get_db),
):
    IngredientGroupService.delete_group(
        db=db,
        group_id=id,
        force=force,
    )
    return {"message": f"Xóa nhóm nguyên liệu ID {id} thành công"}
