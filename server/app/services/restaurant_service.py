from typing import List, Optional
from fastapi import HTTPException, status
from sqlalchemy import select, func, literal, Float
from sqlalchemy.orm import Session
from geoalchemy2 import Geography

from server.app.models.restaurant import Restaurant
from server.app.schemas.restaurant import RestaurantCreate, RestaurantUpdate


# Lớp nghiệp vụ quản lý cơ sở ẩm thực và xử lý truy vấn không gian PostGIS
class RestaurantService:
    # Tạo mới một cơ sở ẩm thực trong hệ thống kèm trạng thái hoạt động mặc định
    @staticmethod
    def create_restaurant(
        db: Session,
        data: RestaurantCreate,
    ) -> Restaurant:
        """Tạo một quán ăn mới trong hệ thống."""
        # 1. Khởi tạo thực thể quán ăn từ dữ liệu đầu vào
        restaurant = Restaurant(
            name=data.name.strip(),
            address=data.address.strip(),
            latitude=data.latitude,
            longitude=data.longitude,
            phone=data.phone.strip() if data.phone else None,
            description=data.description.strip() if data.description else None,
            open_time=data.open_time,
            close_time=data.close_time,
            service_licenses=data.service_licenses,
            is_sponsor=data.is_sponsor,
            is_active=True,
        )
        # 2. Lưu vào CSDL và làm mới dữ liệu
        db.add(restaurant)
        db.commit()
        db.refresh(restaurant)
        return restaurant

    # Lấy thông tin chi tiết của một quán ăn theo mã định danh ID
    @staticmethod
    def get_restaurant_by_id(
        db: Session,
        restaurant_id: int,
    ) -> Restaurant:
        """Lấy thông tin chi tiết của 1 quán ăn theo ID."""
        # 1. Truy vấn quán ăn theo ID
        restaurant = db.get(Restaurant, restaurant_id)
        # 2. Báo lỗi 404 nếu không tìm thấy
        if not restaurant:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Không tìm thấy quán ăn với ID {restaurant_id}.",
            )
        return restaurant

    # Cập nhật thông tin chi tiết cơ sở ẩm thực
    @staticmethod
    def update_restaurant(
        db: Session,
        restaurant_id: int,
        data: RestaurantUpdate,
    ) -> Restaurant:
        """Cập nhật thông tin quán ăn."""
        # 1. Tìm quán ăn cần sửa
        restaurant = db.get(Restaurant, restaurant_id)
        if not restaurant:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Không tìm thấy quán ăn với ID {restaurant_id}.",
            )

        # 2. Cập nhật các trường được truyền
        update_data = data.model_dump(exclude_unset=True)
        for key, value in update_data.items():
            if isinstance(value, str):
                value = value.strip()
            setattr(restaurant, key, value)

        # 3. Commit lưu thay đổi
        db.commit()
        db.refresh(restaurant)
        return restaurant

    # Xoá cơ sở quán ăn khỏi hệ thống
    @staticmethod
    def delete_restaurant(
        db: Session,
        restaurant_id: int,
    ) -> bool:
        """Xoá một quán ăn."""
        # 1. Tìm quán ăn theo ID
        restaurant = db.get(Restaurant, restaurant_id)
        if not restaurant:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Không tìm thấy quán ăn với ID {restaurant_id}.",
            )

        # 2. Xoá khỏi database
        db.delete(restaurant)
        db.commit()
        return True

    # Lấy danh sách toàn bộ quán ăn đang hoạt động phục vụ hiển thị bản đồ
    @staticmethod
    def get_all_active_restaurants(
        db: Session,
        skip: int = 0,
        limit: Optional[int] = None,
        active_only: bool = True,
    ) -> List[Restaurant]:
        """Lấy danh sách các quán ăn công khai cho khách hàng và bản đồ (không giới hạn nếu limit là None hoặc <= 0)."""
        # 1. Khởi tạo truy vấn danh sách quán ăn theo phân trang
        stmt = select(Restaurant).order_by(Restaurant.id.desc()).offset(skip)
        # 2. Áp dụng bộ lọc trạng thái hoạt động nếu yêu cầu
        if active_only:
            stmt = stmt.where(Restaurant.is_active.is_(True))
        if limit is not None and limit > 0:
            stmt = stmt.limit(limit)
        # 3. Trả về danh sách kết quả
        return list(db.scalars(stmt).all())

    # Tìm kiếm các quán ăn trong bán kính radius_km sử dụng không gian PostGIS ST_DWithin
    @staticmethod
    def get_nearby_restaurants(
        db: Session,
        lat: float,
        lon: float,
        radius_km: float = 5.0,
        skip: int = 0,
        limit: int = 50,
        active_only: bool = True,
    ) -> List[dict]:
        """
        Tìm kiếm các quán ăn trong bán kính radius_km sử dụng hàm PostGIS ST_DWithin.
        Tự động tính khoảng cách thực tế (mét và km) và sắp xếp từ gần đến xa qua ST_Distance.
        """
        # 1. Tạo điểm toạ độ địa lý người dùng WGS84
        user_point = func.ST_SetSRID(func.ST_MakePoint(literal(lon, Float), literal(lat, Float)), 4326).cast(Geography)
        # 2. Tạo biểu thức tính khoảng cách bằng ST_Distance
        distance_meters_expr = func.ST_Distance(Restaurant.location, user_point).label("distance_meters")

        # 3. Xây dựng truy vấn ST_DWithin theo bán kính
        stmt = select(
            Restaurant,
            distance_meters_expr,
        ).where(
            func.ST_DWithin(Restaurant.location, user_point, radius_km * 1000.0)
        )

        # 4. Lọc chỉ lấy quán đang mở cửa / hoạt động
        if active_only:
            stmt = stmt.where(Restaurant.is_active.is_(True))

        # 5. Sắp xếp quán từ gần nhất đến xa nhất và phân trang
        stmt = stmt.order_by(distance_meters_expr.asc()).offset(skip).limit(limit)

        # 6. Đóng gói danh sách kết quả kèm khoảng cách
        results = []
        for restaurant, dist_m in db.execute(stmt).all():
            data = {
                "id": restaurant.id,
                "name": restaurant.name,
                "address": restaurant.address,
                "latitude": restaurant.latitude,
                "longitude": restaurant.longitude,
                "phone": restaurant.phone,
                "description": restaurant.description,
                "open_time": restaurant.open_time,
                "close_time": restaurant.close_time,
                "is_active": restaurant.is_active,
                "created_at": restaurant.created_at,
                "distance_meters": round(float(dist_m), 1),
                "distance_km": round(float(dist_m) / 1000.0, 2),
            }
            results.append(data)
        return results

    # Tính khoảng cách đường chim bay từ vị trí người dùng đến một quán ăn cụ thể
    @staticmethod
    def calculate_distance_to_restaurant(
        db: Session,
        restaurant_id: int,
        lat: float,
        lon: float,
    ) -> dict:
        """Tính khoảng cách từ toạ độ người dùng đến quán ăn cụ thể sử dụng PostGIS."""
        # 1. Lấy thông tin quán ăn
        restaurant = RestaurantService.get_restaurant_by_id(db=db, restaurant_id=restaurant_id)
        # 2. Tạo điểm toạ độ và truy vấn khoảng cách ST_Distance
        user_point = func.ST_SetSRID(func.ST_MakePoint(literal(lon, Float), literal(lat, Float)), 4326).cast(Geography)
        stmt = select(func.ST_Distance(Restaurant.location, user_point)).where(Restaurant.id == restaurant_id)
        dist_m = db.scalar(stmt)
        if dist_m is None:
            dist_m = 0.0
        # 3. Trả về kết quả khoảng cách
        return {
            "restaurant_id": restaurant_id,
            "restaurant_name": restaurant.name,
            "distance_meters": round(float(dist_m), 1),
            "distance_km": round(float(dist_m) / 1000.0, 2),
        }
