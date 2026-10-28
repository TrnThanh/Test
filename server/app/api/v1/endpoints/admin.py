from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Path, Query, status
from sqlalchemy.orm import Session

from server.app.db.session import get_db
from server.app.models.restaurant import Restaurant
from server.app.schemas.admin import (
    SystemStatsResponse,
    AdminUserItem,
    RestaurantStatusUpdate,
)
from server.app.schemas.restaurant import RestaurantCreate, RestaurantResponse, RestaurantUpdate
from server.app.services.admin_service import AdminService
from server.app.services.restaurant_service import RestaurantService

router = APIRouter()


# Lấy danh sách toàn bộ quán ăn dành cho Admin Console (bao gồm quán tạm dừng hoạt động)
@router.get(
    "/restaurants",
    response_model=List[RestaurantResponse],
    summary="Lấy danh sách toàn bộ Quán ăn dành cho Admin (bao gồm cả quán tạm dừng)",
)
def get_all_restaurants_for_admin(
    skip: int = Query(0, ge=0, description="Số lượng bản ghi bỏ qua"),
    limit: Optional[int] = Query(None, description="Số lượng bản ghi tối đa (để trống hoặc 0 để lấy tất cả)"),
    active_only: bool = Query(False, description="Chỉ lấy quán đang hoạt động"),
    db: Session = Depends(get_db),
) -> List[RestaurantResponse]:
    """Admin lấy danh sách toàn bộ quán ăn toàn hệ thống (không giới hạn để quản lý toàn diện)."""
    # Truy vấn danh sách toàn bộ quán từ cơ sở dữ liệu
    return RestaurantService.get_all_active_restaurants(
        db=db, skip=skip, limit=limit, active_only=active_only
    )


# Tạo quán ăn mới trực tiếp từ bảng điều khiển Quản trị viên
@router.post(
    "/restaurants",
    response_model=RestaurantResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Admin tạo quán ăn mới",
)
def create_restaurant_as_admin(
    payload: RestaurantCreate,
    db: Session = Depends(get_db),
) -> RestaurantResponse:
    """Quản trị viên tạo quán ăn mới trong hệ thống."""
    # Gọi service tạo mới quán ăn với quyền admin
    return RestaurantService.create_restaurant(db=db, data=payload)


# Lấy chỉ số thống kê tổng hợp toàn bộ hệ thống (Số quán, số món ăn, danh mục, tài khoản)
@router.get(
    "/stats",
    response_model=SystemStatsResponse,
    summary="Thống kê tổng quan toàn hệ thống (Dành cho Admin Dashboard)",
)
def get_system_stats(db: Session = Depends(get_db)) -> SystemStatsResponse:
    """Trả về số lượng tổng hợp cơ sở dữ liệu: quán ăn, món ăn, danh mục, user."""
    # 1. Thu thập số liệu thống kê qua AdminService
    stats = AdminService.get_system_stats(db=db)
    # 2. Đóng gói vào SystemStatsResponse
    return SystemStatsResponse(**stats)


# Lấy danh sách tài khoản người dùng đã đăng ký trong hệ thống
@router.get(
    "/users",
    response_model=List[AdminUserItem],
    summary="Lấy danh sách toàn bộ người dùng / Thực khách (Dành cho Admin)",
)
def get_all_users(db: Session = Depends(get_db)) -> List[AdminUserItem]:
    """Danh sách tất cả các tài khoản người dùng đã đăng ký."""
    # Truy vấn danh sách người dùng
    return AdminService.get_all_users(db=db)


# Bật hoặc tắt trạng thái hoạt động của cơ sở ẩm thực theo quyền Quản trị viên
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
    # 1. Gọi service cập nhật cờ is_active
    restaurant = AdminService.update_restaurant_status(
        db=db, restaurant_id=restaurant_id, is_active=status_in.is_active
    )
    # 2. Xử lý trường hợp không tìm thấy quán ăn
    if not restaurant:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Không tìm thấy quán ăn với ID {restaurant_id}.",
        )
    # 3. Trả về thông tin quán ăn sau khi đổi trạng thái
    return restaurant


# Cập nhật thông tin chi tiết của một quán ăn theo thẩm quyền Quản trị viên
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
    # 1. Truy vấn quán ăn theo ID từ cơ sở dữ liệu
    restaurant = db.get(Restaurant, restaurant_id)
    if not restaurant:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Không tìm thấy quán ăn với ID {restaurant_id}.",
        )

    # 2. Bóc tách dữ liệu payload chỉ lấy các trường được gửi lên
    update_dict = payload.model_dump(exclude_unset=True)
    for field, value in update_dict.items():
        if isinstance(value, str):
            value = value.strip()
        setattr(restaurant, field, value)

    # 3. Commit lưu thay đổi và refresh đối tượng
    db.commit()
    db.refresh(restaurant)
    return restaurant


# Xoá cơ sở quán ăn khỏi hệ thống theo quyền Quản trị viên
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
    # 1. Gọi service xoá cơ sở quán ăn
    success = AdminService.delete_restaurant_as_admin(db=db, restaurant_id=restaurant_id)
    # 2. Kiểm tra nếu không tìm thấy quán để xoá
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Không tìm thấy quán ăn với ID {restaurant_id}.",
        )
    # 3. Trả về thông báo thành công
    return {"message": "Đã xoá quán ăn thành công.", "restaurant_id": restaurant_id}
