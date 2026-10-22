from typing import List, Optional
from fastapi import APIRouter, Depends, Query, Path, status
from sqlalchemy.orm import Session

from server.app.db.session import get_db
from server.app.schemas.category import CategoryCreate, CategoryUpdate, CategoryResponse
from server.app.services.category_service import CategoryService

router = APIRouter()


# --- DANH MỤC TOÀN CỤC (GLOBAL MASTER CATEGORIES) ---
@router.post(
    "/categories",
    response_model=CategoryResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Tạo danh mục món ăn mới toàn cục",
)
def create_category(
    category_in: CategoryCreate,
    db: Session = Depends(get_db),
):
    """Tạo danh mục mới dùng chung cho toàn bộ hệ thống."""
    return CategoryService.create_category(
        db=db,
        data=category_in,
    )


@router.get(
    "/categories",
    response_model=List[CategoryResponse],
    summary="Lấy danh sách các nhóm danh mục món ăn toàn cục",
)
def get_categories(
    is_active_only: bool = Query(False, description="Chỉ lấy danh mục đang hoạt động"),
    restaurant_id: Optional[int] = Query(None, description="Lọc danh mục có món thuộc quán ăn này"),
    db: Session = Depends(get_db),
):
    """Lấy danh sách nhóm danh mục món ăn, sắp xếp theo thứ tự hiển thị."""
    return CategoryService.get_categories(
        db=db,
        restaurant_id=restaurant_id,
        is_active_only=is_active_only,
    )


# --- TƯƠNG THÍCH NGƯỢC: ENDPOINTS CATEGORY THEO RESTAURANT ---
@router.post(
    "/restaurants/{restaurant_id}/categories",
    response_model=CategoryResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Tạo nhóm danh mục món ăn mới (Tương thích ngược)",
)
def create_category_legacy(
    restaurant_id: int = Path(..., description="ID quán ăn"),
    category_in: CategoryCreate = ...,
    db: Session = Depends(get_db),
):
    """Tạo nhóm danh mục (tương thích endpoint cũ)."""
    return CategoryService.create_category(
        db=db,
        data=category_in,
        restaurant_id=restaurant_id,
    )


@router.get(
    "/restaurants/{restaurant_id}/categories",
    response_model=List[CategoryResponse],
    summary="Lấy danh sách các nhóm danh mục của quán ăn",
)
def get_restaurant_categories(
    restaurant_id: int = Path(..., description="ID quán ăn"),
    is_active_only: bool = Query(False, description="Chỉ lấy danh mục đang hoạt động"),
    db: Session = Depends(get_db),
):
    """Lấy danh sách nhóm danh mục có món ăn của một quán ăn."""
    return CategoryService.get_categories(
        db=db,
        restaurant_id=restaurant_id,
        is_active_only=is_active_only,
    )


@router.get(
    "/categories/{category_id}",
    response_model=CategoryResponse,
    summary="Chi tiết một danh mục món ăn",
)
def get_category_detail(
    category_id: int = Path(..., description="ID danh mục"),
    db: Session = Depends(get_db),
):
    """Lấy thông tin chi tiết của một danh mục."""
    return CategoryService.get_category_by_id(db=db, category_id=category_id)


@router.put(
    "/categories/{category_id}",
    response_model=CategoryResponse,
    summary="Cập nhật danh mục món ăn",
)
def update_category(
    category_id: int = Path(..., description="ID danh mục cần cập nhật"),
    category_in: CategoryUpdate = ...,
    db: Session = Depends(get_db),
):
    """Chỉnh sửa tên, mô tả, thứ tự hiển thị danh mục."""
    return CategoryService.update_category(
        db=db,
        category_id=category_id,
        data=category_in,
    )


@router.delete(
    "/categories/{category_id}",
    summary="Xoá danh mục món ăn",
)
def delete_category(
    category_id: int = Path(..., description="ID danh mục cần xoá"),
    db: Session = Depends(get_db),
):
    """Xoá danh mục món ăn (các món ăn thuộc danh mục sẽ chuyển thành không phân loại)."""
    CategoryService.delete_category(
        db=db,
        category_id=category_id,
    )
    return {"message": f"Danh mục {category_id} đã được xoá thành công. Các món ăn liên quan đã được chuyển thành chưa phân loại."}
