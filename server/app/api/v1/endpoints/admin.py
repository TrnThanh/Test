from typing import List
from fastapi import APIRouter, Depends, HTTPException, Path, Query, status
from sqlalchemy.orm import Session

from server.app.db.session import get_db
from server.app.models.restaurant import Restaurant
from server.app.schemas.admin import (
    SystemStatsResponse,
    AdminSellerItem,
    AdminUserItem,
    RestaurantStatusUpdate,
)
from server.app.schemas.restaurant import RestaurantResponse, RestaurantUpdate
from server.app.services.admin_service import AdminService
from server.app.services.restaurant_service import RestaurantService

router = APIRouter()


@router.get(
    "/restaurants",
    response_model=List[RestaurantResponse],
    summary="Lấy danh sách toàn bộ Quán ăn dành cho Admin (bao gồm cả quán tạm dừng)",
)
def get_all_restaurants_for_admin(
    skip: int = Query(0, ge=0, description="Số lượng bản ghi bỏ qua"),
    limit: int = Query(100, ge=1, le=500, description="Số lượng bản ghi tối đa (lên tới 500)"),
    active_only: bool = Query(False, description="Chỉ lấy quán đang hoạt động"),
    db: Session = Depends(get_db),
) -> List[RestaurantResponse]:
    """Admin lấy danh sách quán ăn toàn hệ thống với giới hạn linh hoạt lên đến 500 bản ghi."""
    return RestaurantService.get_all_active_restaurants(
        db=db, skip=skip, limit=limit, active_only=active_only
    )


@router.get(
    "/stats",

    response_model=SystemStatsResponse,
    summary="Thống kê tổng quan toàn hệ thống (Dành cho Admin Dashboard)",
)
def get_system_stats(db: Session = Depends(get_db)) -> SystemStatsResponse:
    """Trả về số lượng tổng hợp cơ sở dữ liệu: quán ăn, món ăn, danh mục, seller, user."""
    stats = AdminService.get_system_stats(db=db)
    return SystemStatsResponse(**stats)


@router.get(
    "/sellers",
    response_model=List[AdminSellerItem],
    summary="Lấy danh sách toàn bộ đối tác Chủ Quán (Dành cho Admin)",
)
def get_all_sellers(db: Session = Depends(get_db)) -> List[AdminSellerItem]:
    """Danh sách tất cả các tài khoản Seller trên hệ thống kèm số lượng quán."""
    return AdminService.get_all_sellers(db=db)


@router.get(
    "/users",
    response_model=List[AdminUserItem],
    summary="Lấy danh sách toàn bộ người dùng / Thực khách (Dành cho Admin)",
)
def get_all_users(db: Session = Depends(get_db)) -> List[AdminUserItem]:
    """Danh sách tất cả các tài khoản người dùng đã đăng ký."""
    return AdminService.get_all_users(db=db)


@router.patch(
    "/restaurants/{restaurant_id}/status",
    response_model=RestaurantResponse,
    summary="Bật / Tắt trạng thái hoạt động của Quán ăn theo quyền Admin",
)
def toggle_restaurant_status(
    restaurant_id: int = Path(..., description="ID quán ăn"),
    status_in: RestaurantStatusUpdate = ...,
    db: Session = Depends(get_db),
) -> RestaurantResponse:
    """Quản trị viên kích hoạt hoặc tạm dừng hoạt động quán ăn vi phạm."""
    restaurant = AdminService.update_restaurant_status(
        db=db, restaurant_id=restaurant_id, is_active=status_in.is_active
    )
    if not restaurant:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Không tìm thấy quán ăn với ID {restaurant_id}.",
        )
    return restaurant


@router.put(
    "/restaurants/{restaurant_id}",
    response_model=RestaurantResponse,
    summary="Cập nhật thông tin Quán ăn theo quyền Admin",
)
def update_restaurant_as_admin(
    restaurant_id: int = Path(..., description="ID quán ăn"),
    payload: RestaurantUpdate = ...,
    db: Session = Depends(get_db),
) -> RestaurantResponse:
    """Quản trị viên cập nhật trực tiếp thông tin quán ăn (tên, toạ độ, địa chỉ, trạng thái)."""
    restaurant = db.get(Restaurant, restaurant_id)
    if not restaurant:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Không tìm thấy quán ăn với ID {restaurant_id}.",
        )

    update_dict = payload.model_dump(exclude_unset=True)
    for field, value in update_dict.items():
        if isinstance(value, str):
            value = value.strip()
        setattr(restaurant, field, value)

    db.commit()
    db.refresh(restaurant)
    return restaurant


@router.delete(
    "/restaurants/{restaurant_id}",
    status_code=status.HTTP_200_OK,
    summary="Xoá Quán ăn theo quyền Admin",
)
def delete_restaurant_as_admin(
    restaurant_id: int = Path(..., description="ID quán ăn"),
    db: Session = Depends(get_db),
) -> dict:
    """Quản trị viên xoá cơ sở ẩm thực vi phạm khỏi hệ thống."""
    success = AdminService.delete_restaurant_as_admin(db=db, restaurant_id=restaurant_id)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Không tìm thấy quán ăn với ID {restaurant_id}.",
        )
    return {"message": "Đã xoá quán ăn thành công.", "restaurant_id": restaurant_id}
