from typing import List
from fastapi import APIRouter, Depends, Query, Path, status
from sqlalchemy.orm import Session

from server.app.db.session import get_db
from server.app.schemas.restaurant import (
    RestaurantCreate,
    RestaurantUpdate,
    RestaurantResponse,
    NearbyRestaurantResponse,
    DistanceResponse,
)
from server.app.services.restaurant_service import RestaurantService

router = APIRouter()


# ---------------------------------------------------------
# Endpoints Quản lý Quán ăn (CRUD Operations)
# ---------------------------------------------------------

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
    return RestaurantService.create_restaurant(db=db, data=payload)


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
    return RestaurantService.update_restaurant(
        db=db, restaurant_id=restaurant_id, data=payload
    )


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
    RestaurantService.delete_restaurant(
        db=db, restaurant_id=restaurant_id
    )
    return {"message": "Đã xoá quán ăn thành công.", "restaurant_id": restaurant_id}


# ---------------------------------------------------------
# Endpoints công khai (Public) dành cho Khách hàng & Bản đồ
# ---------------------------------------------------------

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
    limit: int = Query(50, ge=1, le=100, description="Số lượng bản ghi tối đa"),
    db: Session = Depends(get_db),
) -> List[NearbyRestaurantResponse]:
    """
    Sử dụng PostGIS (ST_DWithin và ST_Distance trên cột geography) để tìm quán ăn
    trong bán kính radius_km và sắp xếp theo thứ tự từ gần nhất đến xa nhất.
    """
    return RestaurantService.get_nearby_restaurants(
        db=db, lat=lat, lon=lon, radius_km=radius_km, skip=skip, limit=limit
    )


@router.get(
    "/restaurants",
    response_model=List[RestaurantResponse],
    summary="Khách hàng xem danh sách tất cả quán ăn",
    tags=["Restaurants (Public)"],
)
def list_public_restaurants(
    skip: int = Query(0, ge=0, description="Số lượng bản ghi bỏ qua"),
    limit: int = Query(50, ge=1, le=100, description="Số lượng bản ghi tối đa"),
    db: Session = Depends(get_db),
) -> List[RestaurantResponse]:
    """Lấy danh sách các quán ăn đang hoạt động để hiển thị lên bản đồ hoặc danh sách khám phá."""
    return RestaurantService.get_all_active_restaurants(
        db=db, skip=skip, limit=limit, active_only=True
    )


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
    return RestaurantService.calculate_distance_to_restaurant(
        db=db, restaurant_id=restaurant_id, lat=lat, lon=lon
    )


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
    return RestaurantService.get_restaurant_by_id(db=db, restaurant_id=restaurant_id)
