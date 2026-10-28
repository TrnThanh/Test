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

# Tạo mới một cơ sở ẩm thực trong hệ thống (chỉ dành cho quản trị viên)
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
    """Tạo mới một quán ăn trong hệ thống."""
    # Chuyển payload sang tầng service để xác thực và lưu vào cơ sở dữ liệu
    return RestaurantService.create_restaurant(db=db, data=payload)


# Cập nhật thông tin chi tiết của một quán ăn theo ID
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
    """Cập nhật thông tin quán ăn (tên, địa chỉ, toạ độ, giờ mở/đóng cửa...)."""
    # Gọi service cập nhật các trường thông tin thay đổi
    return RestaurantService.update_restaurant(
        db=db, restaurant_id=restaurant_id, data=payload
    )


# Xoá hoàn toàn một cơ sở quán ăn khỏi hệ thống
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
    """Xoá một quán ăn khỏi hệ thống."""
    # 1. Gọi service để xoá bản ghi quán ăn và cascade xoá món ăn liên quan
    RestaurantService.delete_restaurant(
        db=db, restaurant_id=restaurant_id
    )
    # 2. Trả về thông điệp phản hồi xác nhận xoá thành công
    return {"message": "Đã xoá quán ăn thành công.", "restaurant_id": restaurant_id}


# ==============================================================================
# NHÓM ENDPOINT 2: Công khai (Public) dành cho Khách hàng & Bản đồ
# ==============================================================================

# Tìm kiếm các quán ăn xung quanh vị trí khách hàng dựa trên không gian địa lý PostGIS
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
    """
    Sử dụng PostGIS (ST_DWithin và ST_Distance trên cột geography) để tìm quán ăn
    trong bán kính radius_km và sắp xếp theo thứ tự từ gần nhất đến xa nhất.
    """
    # Uỷ thác cho RestaurantService thực thi câu lệnh SQL không gian và tính khoảng cách
    return RestaurantService.get_nearby_restaurants(
        db=db, lat=lat, lon=lon, radius_km=radius_km, skip=skip, limit=limit
    )


# Lấy danh sách toàn bộ các quán ăn đang hoạt động để hiển thị danh mục khám phá
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
    """Lấy danh sách các quán ăn đang hoạt động để hiển thị lên bản đồ hoặc danh sách khám phá."""
    # Lấy danh sách tất cả quán có cờ is_active = True
    return RestaurantService.get_all_active_restaurants(
        db=db, skip=skip, limit=limit, active_only=True
    )


# Chỉ đường đi bộ thực tế bám sát ngõ ngách, đường phố từ vị trí người dùng đến quán ăn
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
    """
    Tìm đường đi bộ thực tế bám sát ngõ ngách, đường phố từ vị trí người dùng đến quán ăn:
    1. Kiểm tra quán ăn tồn tại, đang hoạt động (active), toạ độ không NULL.
    2. Kiểm tra cự ly không vượt quá 50km (chặn request quá xa).
    3. Tra cứu bộ nhớ đệm FIFO TTL Cache.
    4. Gọi OSRM Foot Profile, tự động fallback an toàn nếu có sự cố.
    """
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


# Tính khoảng cách trực tiếp từ vị trí khách hàng đến quán ăn cụ thể
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
    """Tính khoảng cách chính xác theo mét và km sử dụng hàm PostGIS ST_Distance."""
    # Gọi hàm tính khoảng cách PostGIS từ RestaurantService
    return RestaurantService.calculate_distance_to_restaurant(
        db=db, restaurant_id=restaurant_id, lat=lat, lon=lon
    )


# Lấy thông tin chi tiết toạ độ và địa chỉ quán ăn phục vụ dẫn đường
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
    """Lấy thông tin chi tiết của quán ăn gồm toạ độ (latitude, longitude) để thực hiện dẫn đường."""
    # Trả về thông tin đầy đủ của quán ăn theo ID
    return RestaurantService.get_restaurant_by_id(db=db, restaurant_id=restaurant_id)
