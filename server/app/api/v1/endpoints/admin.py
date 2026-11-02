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


# [POSTMAN GUIDE]
# GET http://localhost:8001/api/v1/admin/restaurants?skip=0&limit=20&active_only=false
# Headers: (Không yêu cầu)
# Đầu vào (Query Params):
#   - skip        : 0      (int, default: 0)
#   - limit       : 20     (int, tuỳ chọn)
#   - active_only : false  (bool, default: false)
# Status Code gợi ý:
#   - 200 OK                   : Lấy danh sách toàn bộ quán ăn thành công
#   - 422 Unprocessable Content: Tham số query không hợp lệ
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
    # Truy vấn danh sách toàn bộ quán từ cơ sở dữ liệu
    return RestaurantService.get_all_active_restaurants(
        db=db, skip=skip, limit=limit, active_only=active_only
    )


# [POSTMAN GUIDE]
# POST http://localhost:8001/api/v1/admin/restaurants
# Headers:
#   Content-Type: application/json
# Đầu vào (Body raw JSON):
# {
#   "name": "Quán Phở Bò Gia Truyền",          // string (bắt buộc)
#   "address": "Số 12 Ngô Xuân Quảng, Hà Nội",  // string (bắt buộc)
#   "latitude": 21.00512,                       // float (-90 đến 90, bắt buộc)
#   "longitude": 105.93245,                     // float (-180 đến 180, bắt buộc)
#   "phone": "0912345678",                      // string (tuỳ chọn)
#   "opening_time": "06:00",                    // string HH:MM (tuỳ chọn)
#   "closing_time": "22:00",                    // string HH:MM (tuỳ chọn)
#   "price_min": 35000,                         // int (tuỳ chọn)
#   "price_max": 60000                          // int (tuỳ chọn)
# }
# Status Code gợi ý:
#   - 201 Created              : Tạo mới quán ăn thành công
#   - 422 Unprocessable Content: Thiếu tên quán hoặc toạ độ ngoài phạm vi
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
    # Gọi service tạo mới quán ăn với quyền admin
    return RestaurantService.create_restaurant(db=db, data=payload)


# [POSTMAN GUIDE]
# GET http://localhost:8001/api/v1/admin/stats
# Headers: (Không yêu cầu)
# Đầu vào: Không có
# Status Code gợi ý:
#   - 200 OK: Lấy thống kê hệ thống thành công (total_restaurants, total_dishes, ...)
@router.get(
    "/stats",
    response_model=SystemStatsResponse,
    summary="Thống kê tổng quan toàn hệ thống (Dành cho Admin Dashboard)",
)
def get_system_stats(db: Session = Depends(get_db)) -> SystemStatsResponse:
    # 1. Thu thập số liệu thống kê qua AdminService
    stats = AdminService.get_system_stats(db=db)
    # 2. Đóng gói vào SystemStatsResponse
    return SystemStatsResponse(**stats)


# [POSTMAN GUIDE]
# GET http://localhost:8001/api/v1/admin/users
# Headers: (Không yêu cầu)
# Đầu vào: Không có
# Status Code gợi ý:
#   - 200 OK: Lấy danh sách toàn bộ người dùng thành công
@router.get(
    "/users",
    response_model=List[AdminUserItem],
    summary="Lấy danh sách toàn bộ người dùng / Thực khách (Dành cho Admin)",
)
def get_all_users(db: Session = Depends(get_db)) -> List[AdminUserItem]:
    # Truy vấn danh sách người dùng
    return AdminService.get_all_users(db=db)


# [POSTMAN GUIDE]
# DELETE http://localhost:8001/api/v1/admin/users/1
# Headers: (Không yêu cầu)
# Đầu vào (Path Param):
#   - user_id: 1 (int, bắt buộc)
# Status Code gợi ý:
#   - 200 OK                   : Xoá người dùng thành công
#   - 404 Not Found            : Không tìm thấy người dùng với ID tương ứng
#   - 422 Unprocessable Content: ID không phải số nguyên
@router.delete(
    "/users/{user_id}",
    status_code=status.HTTP_200_OK,
    summary="Xóa Người dùng theo quyền Admin",
)
def delete_user_as_admin(
    user_id: int = Path(..., description="ID người dùng"),
    db: Session = Depends(get_db),
) -> dict:
    success = AdminService.delete_user_as_admin(db=db, user_id=user_id)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Không tìm thấy người dùng với ID {user_id}.",
        )
    return {"message": "Đã xóa người dùng thành công.", "user_id": user_id}


# [POSTMAN GUIDE]
# PATCH http://localhost:8001/api/v1/admin/restaurants/1/status
# Headers:
#   Content-Type: application/json
# Đầu vào (Path Param):
#   - restaurant_id: 1 (int, bắt buộc)
# Đầu vào (Body raw JSON):
# {
#   "is_active": false  // bool (bắt buộc)
# }
# Status Code gợi ý:
#   - 200 OK                   : Cập nhật trạng thái quán ăn thành công
#   - 404 Not Found            : Không tìm thấy quán ăn
#   - 422 Unprocessable Content: Sai kiểu dữ liệu
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


# [POSTMAN GUIDE]
# PUT http://localhost:8001/api/v1/admin/restaurants/1
# Headers:
#   Content-Type: application/json
# Đầu vào (Path Param):
#   - restaurant_id: 1 (int, bắt buộc)
# Đầu vào (Body raw JSON):
# {
#   "name": "Quán Phở Bò Gia Truyền (Đổi tên)",  // string (tuỳ chọn)
#   "address": "Số 15 Ngô Xuân Quảng, Hà Nội",   // string (tuỳ chọn)
#   "latitude": 21.00550,                        // float (tuỳ chọn)
#   "longitude": 105.93280,                      // float (tuỳ chọn)
#   "is_active": true                            // bool (tuỳ chọn)
# }
# Status Code gợi ý:
#   - 200 OK                   : Cập nhật thông tin quán ăn thành công
#   - 404 Not Found            : Không tìm thấy quán ăn
#   - 422 Unprocessable Content: Dữ liệu cập nhật không hợp lệ
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


# [POSTMAN GUIDE]
# DELETE http://localhost:8001/api/v1/admin/restaurants/1
# Headers: (Không yêu cầu)
# Đầu vào (Path Param):
#   - restaurant_id: 1 (int, bắt buộc)
# Status Code gợi ý:
#   - 200 OK                   : Xoá quán ăn thành công
#   - 404 Not Found            : Không tìm thấy quán ăn với ID tương ứng
#   - 422 Unprocessable Content: ID không phải số nguyên
@router.delete(
    "/restaurants/{restaurant_id}",
    status_code=status.HTTP_200_OK,
    summary="Xoá Quán ăn theo quyền Admin",
)
def delete_restaurant_as_admin(
    restaurant_id: int = Path(..., description="ID quán ăn"),
    db: Session = Depends(get_db),
) -> dict:
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
