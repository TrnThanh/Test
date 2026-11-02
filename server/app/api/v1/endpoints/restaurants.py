from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, Path, status
from sqlalchemy.orm import Session

from server.app.db.session import get_db
from server.app.schemas.restaurant import (
    RestaurantCreate,
    RestaurantUpdate,
    RestaurantResponse,
    NearbyRestaurantResponse,
    DistanceResponse,
    RestaurantRouteResponse,
)
from server.app.services.map_service import map_service, haversine_distance
from server.app.services.restaurant_service import RestaurantService

router = APIRouter()


# ==============================================================================
# NHÓM ENDPOINT 1: Quản lý Quán ăn (CRUD Operations)
# ==============================================================================

# [POSTMAN GUIDE]
# POST http://localhost:8001/api/v1/restaurants
# Headers:
#   Content-Type: application/json
# Đầu vào (Body raw JSON):
# {
#   "name": "Bún Bò Huế Ngự Uyển",             // string (bắt buộc)
#   "address": "Số 45 Trâu Quỳ, Gia Lâm, Hà Nội", // string (bắt buộc)
#   "latitude": 21.0062,                        // float (-90 đến 90, bắt buộc)
#   "longitude": 105.9341,                      // float (-180 đến 180, bắt buộc)
#   "phone": "0988776655",                      // string (tuỳ chọn)
#   "opening_time": "06:30",                    // string HH:MM (tuỳ chọn)
#   "closing_time": "21:30",                    // string HH:MM (tuỳ chọn)
#   "price_min": 40000,                         // int (tuỳ chọn)
#   "price_max": 65000                          // int (tuỳ chọn)
# }
# Status Code gợi ý:
#   - 201 Created              : Tạo quán ăn mới thành công
#   - 422 Unprocessable Content: Thiếu trường bắt buộc hoặc toạ độ ngoài phạm vi
@router.post(
    "/restaurants",
    response_model=RestaurantResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Tạo quán ăn mới",
    tags=["Restaurants Management"],
)
def create_restaurant(
    payload: RestaurantCreate,
    db: Session = Depends(get_db),
) -> RestaurantResponse:
    # Chuyển payload sang tầng service để xác thực và lưu vào cơ sở dữ liệu
    return RestaurantService.create_restaurant(db=db, data=payload)


# [POSTMAN GUIDE]
# PUT http://localhost:8001/api/v1/restaurants/1
# Headers:
#   Content-Type: application/json
# Đầu vào (Path Param):
#   - restaurant_id: 1 (int, bắt buộc)
# Đầu vào (Body raw JSON):
# {
#   "name": "Bún Bò Huế Ngự Uyển (Cơ sở 1)",  // string (tuỳ chọn)
#   "opening_time": "06:00",                   // string HH:MM (tuỳ chọn)
#   "closing_time": "22:00"                    // string HH:MM (tuỳ chọn)
# }
# Status Code gợi ý:
#   - 200 OK                   : Cập nhật thông tin quán ăn thành công
#   - 404 Not Found            : Không tìm thấy quán ăn
#   - 422 Unprocessable Content: Dữ liệu cập nhật không hợp lệ
@router.put(
    "/restaurants/{restaurant_id}",
    response_model=RestaurantResponse,
    summary="Cập nhật thông tin quán ăn",
    tags=["Restaurants Management"],
)
def update_restaurant(
    restaurant_id: int = Path(..., description="ID quán ăn"),
    payload: RestaurantUpdate = ...,
    db: Session = Depends(get_db),
) -> RestaurantResponse:
    # Gọi service cập nhật các trường thông tin thay đổi
    return RestaurantService.update_restaurant(
        db=db, restaurant_id=restaurant_id, data=payload
    )


# [POSTMAN GUIDE]
# DELETE http://localhost:8001/api/v1/restaurants/1
# Headers: (Không yêu cầu)
# Đầu vào (Path Param):
#   - restaurant_id: 1 (int, bắt buộc)
# Status Code gợi ý:
#   - 200 OK       : Xoá quán ăn thành công
#   - 404 Not Found: Quán ăn không tồn tại
@router.delete(
    "/restaurants/{restaurant_id}",
    status_code=status.HTTP_200_OK,
    summary="Xoá quán ăn",
    tags=["Restaurants Management"],
)
def delete_restaurant(
    restaurant_id: int = Path(..., description="ID quán ăn"),
    db: Session = Depends(get_db),
) -> dict:
    # 1. Gọi service để xoá bản ghi quán ăn và cascade xoá món ăn liên quan
    RestaurantService.delete_restaurant(
        db=db, restaurant_id=restaurant_id
    )
    # 2. Trả về thông điệp phản hồi xác nhận xoá thành công
    return {"message": "Đã xoá quán ăn thành công.", "restaurant_id": restaurant_id}


# ==============================================================================
# NHÓM ENDPOINT 2: Công khai (Public) dành cho Khách hàng & Bản đồ
# ==============================================================================

# [POSTMAN GUIDE]
# GET http://localhost:8001/api/v1/restaurants/nearby?lat=21.0046&lon=105.9387&radius_km=3.0&skip=0&limit=50
# Headers: (Không yêu cầu)
# Đầu vào (Query Params):
#   - lat       : 21.0046 (float -90 đến 90, bắt buộc)
#   - lon       : 105.9387 (float -180 đến 180, bắt buộc)
#   - radius_km : 3.0    (float > 0 đến 100, default: 5.0)
#   - skip      : 0      (int, default: 0)
#   - limit     : 50     (int 1-500, default: 100)
# Status Code gợi ý:
#   - 200 OK                   : Tìm kiếm quán ăn xung quanh thành công
#   - 422 Unprocessable Content: Toạ độ hoặc bán kính không hợp lệ
@router.get(
    "/restaurants/nearby",
    response_model=List[NearbyRestaurantResponse],
    summary="Khách hàng tìm kiếm các quán ăn xung quanh theo bán kính (PostGIS)",
    tags=["Restaurants (Public)"],
)
def find_nearby_restaurants(
    lat: float = Query(..., ge=-90.0, le=90.0, description="Vĩ độ hiện tại của khách hàng"),
    lon: float = Query(..., ge=-180.0, le=180.0, description="Kinh độ hiện tại của khách hàng"),
    radius_km: float = Query(5.0, gt=0, le=100.0, description="Bán kính tìm kiếm (km)"),
    skip: int = Query(0, ge=0, description="Số lượng bản ghi bỏ qua"),
    limit: int = Query(100, ge=1, le=500, description="Số lượng bản ghi tối đa"),
    db: Session = Depends(get_db),
) -> List[NearbyRestaurantResponse]:
    # Uỷ thác cho RestaurantService thực thi câu lệnh SQL không gian và tính khoảng cách
    return RestaurantService.get_nearby_restaurants(
        db=db, lat=lat, lon=lon, radius_km=radius_km, skip=skip, limit=limit
    )


# [POSTMAN GUIDE]
# GET http://localhost:8001/api/v1/restaurants?skip=0&limit=50
# Headers: (Không yêu cầu)
# Đầu vào (Query Params):
#   - skip  : 0  (int, default: 0)
#   - limit : 50 (int, tuỳ chọn)
# Status Code gợi ý:
#   - 200 OK: Xem danh sách tất cả quán ăn đang hoạt động thành công
@router.get(
    "/restaurants",
    response_model=List[RestaurantResponse],
    summary="Khách hàng xem danh sách tất cả quán ăn",
    tags=["Restaurants (Public)"],
)
def list_public_restaurants(
    skip: int = Query(0, ge=0, description="Số lượng bản ghi bỏ qua"),
    limit: Optional[int] = Query(None, description="Số lượng bản ghi tối đa (để trống để lấy tất cả)"),
    db: Session = Depends(get_db),
) -> List[RestaurantResponse]:
    # Lấy danh sách tất cả quán có cờ is_active = True
    return RestaurantService.get_all_active_restaurants(
        db=db, skip=skip, limit=limit, active_only=True
    )


# [POSTMAN GUIDE]
# GET http://localhost:8001/api/v1/restaurants/1/route?user_lat=21.0046&user_lon=105.9387
# Headers: (Không yêu cầu)
# Đầu vào (Path Param):
#   - restaurant_id : 1        (int, bắt buộc)
# Đầu vào (Query Params):
#   - user_lat      : 21.0046  (float -90 đến 90, bắt buộc)
#   - user_lon      : 105.9387 (float -180 đến 180, bắt buộc)
# Status Code gợi ý:
#   - 200 OK                   : Tìm đường đi bộ ngắn nhất đến quán ăn thành công
#   - 400 Bad Request          : Khoảng cách vượt quá giới hạn (tối đa 50km)
#   - 404 Not Found            : Quán không tồn tại hoặc đã ngừng hoạt động
#   - 422 Unprocessable Content: Quán chưa có toạ độ hợp lệ hoặc toạ độ gửi lên sai
@router.get(
    "/restaurants/{restaurant_id}/route",
    response_model=RestaurantRouteResponse,
    summary="Khách hàng tìm đường đi bộ ngắn nhất đến quán ăn (OSRM Foot Routing)",
    tags=["Restaurants (Public)"],
)
async def get_walking_route_to_restaurant(
    restaurant_id: int = Path(..., gt=0, description="ID quán ăn"),
    user_lat: float = Query(..., ge=-90.0, le=90.0, description="Vĩ độ xuất phát của người dùng"),
    user_lon: float = Query(..., ge=-180.0, le=180.0, description="Kinh độ xuất phát của người dùng"),
    db: Session = Depends(get_db),
) -> RestaurantRouteResponse:
    # 1. Truy vấn thông tin quán ăn từ cơ sở dữ liệu
    restaurant = RestaurantService.get_restaurant_by_id(db=db, restaurant_id=restaurant_id)
    # 2. Kiểm tra quán có đang mở cửa / hoạt động hay không
    if not restaurant.is_active:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Quán ăn '{restaurant.name}' hiện đã ngừng hoạt động.",
        )
    # 3. Kiểm tra tính hợp lệ của toạ độ quán ăn
    if restaurant.latitude is None or restaurant.longitude is None:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Quán ăn chưa có toạ độ hợp lệ.",
        )

    # 4. Kiểm tra cự ly thẳng Haversine (chặn request vượt quá 50km để tiết kiệm tài nguyên)
    h_dist = haversine_distance(user_lat, user_lon, restaurant.latitude, restaurant.longitude)
    if h_dist > 50000.0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Khoảng cách vượt quá giới hạn tìm đường đi bộ (tối đa 50km).",
        )

    # 5. Gọi OSRM API thông qua map_service với cơ chế FIFO TTL cache
    return await map_service.get_walking_route_to_restaurant(
        restaurant_id=restaurant.id,
        restaurant_name=restaurant.name,
        user_lat=user_lat,
        user_lon=user_lon,
        rest_lat=restaurant.latitude,
        rest_lon=restaurant.longitude,
    )


# [POSTMAN GUIDE]
# GET http://localhost:8001/api/v1/restaurants/1/distance?lat=21.0046&lon=105.9387
# Headers: (Không yêu cầu)
# Đầu vào (Path Param):
#   - restaurant_id : 1        (int, bắt buộc)
# Đầu vào (Query Params):
#   - lat           : 21.0046  (float -90 đến 90, bắt buộc)
#   - lon           : 105.9387 (float -180 đến 180, bắt buộc)
# Status Code gợi ý:
#   - 200 OK                   : Tính khoảng cách đến quán ăn thành công
#   - 404 Not Found            : Không tìm thấy quán ăn
#   - 422 Unprocessable Content: Toạ độ khách hàng ngoài phạm vi hợp lệ
@router.get(
    "/restaurants/{restaurant_id}/distance",
    response_model=DistanceResponse,
    summary="Khách hàng tính khoảng cách từ vị trí của mình đến quán ăn (PostGIS)",
    tags=["Restaurants (Public)"],
)
def get_distance_to_restaurant(
    restaurant_id: int,
    lat: float = Query(..., ge=-90.0, le=90.0, description="Vĩ độ hiện tại của khách hàng"),
    lon: float = Query(..., ge=-180.0, le=180.0, description="Kinh độ hiện tại của khách hàng"),
    db: Session = Depends(get_db),
) -> DistanceResponse:
    # Gọi hàm tính khoảng cách PostGIS từ RestaurantService
    return RestaurantService.calculate_distance_to_restaurant(
        db=db, restaurant_id=restaurant_id, lat=lat, lon=lon
    )


# [POSTMAN GUIDE]
# GET http://localhost:8001/api/v1/restaurants/1
# Headers: (Không yêu cầu)
# Đầu vào (Path Param):
#   - restaurant_id: 1 (int, bắt buộc)
# Status Code gợi ý:
#   - 200 OK       : Lấy thông tin chi tiết toạ độ quán ăn thành công
#   - 404 Not Found: Không tìm thấy quán ăn với ID tương ứng
@router.get(
    "/restaurants/{restaurant_id}",
    response_model=RestaurantResponse,
    summary="Khách hàng xem chi tiết toạ độ quán ăn để dẫn đường",
    tags=["Restaurants (Public)"],
)
def get_public_restaurant_detail(
    restaurant_id: int,
    db: Session = Depends(get_db),
) -> RestaurantResponse:
    # Trả về thông tin đầy đủ của quán ăn theo ID
    return RestaurantService.get_restaurant_by_id(db=db, restaurant_id=restaurant_id)
