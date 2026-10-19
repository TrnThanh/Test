from typing import Optional, List, Dict, Any
from sqlalchemy import select, func
from sqlalchemy.orm import Session

from server.app.core.security import hash_password, verify_password
from server.app.models.admin import Admin
from server.app.models.seller import Seller
from server.app.models.user import User
from server.app.models.restaurant import Restaurant
from server.app.models.category import Category
from server.app.models.dish import Dish


class AdminService:
    @staticmethod
    def get_admin_by_email(db: Session, email: str) -> Optional[Admin]:
        statement = select(Admin).where(Admin.email == email.strip().lower())
        return db.scalars(statement).first()

    @staticmethod
    def authenticate_admin(db: Session, email: str, password: str) -> Optional[Admin]:
        admin = AdminService.get_admin_by_email(db, email)
        if not admin:
            return None
        if not verify_password(password, admin.hashed_password):
            return None
        return admin

    @staticmethod
    def seed_default_admin(db: Session) -> Admin:
        """Tự động khởi tạo tài khoản Admin mặc định nếu chưa tồn tại trong hệ thống."""
        default_email = "admin@example.com"
        admin = AdminService.get_admin_by_email(db, default_email)
        if not admin:
            admin = Admin(
                email=default_email,
                hashed_password=hash_password("admin123"),
                full_name="System Administrator",
                role_level=1,
            )
            db.add(admin)
            db.commit()
            db.refresh(admin)
        return admin

    @staticmethod
    def get_system_stats(db: Session) -> Dict[str, Any]:
        """Thống kê tổng quan dữ liệu toàn hệ thống cho Dashboard Quản Trị."""
        total_restaurants = db.scalar(select(func.count(Restaurant.id))) or 0
        active_restaurants = db.scalar(select(func.count(Restaurant.id)).where(Restaurant.is_active.is_(True))) or 0
        inactive_restaurants = total_restaurants - active_restaurants
        total_dishes = db.scalar(select(func.count(Dish.id))) or 0
        total_categories = db.scalar(select(func.count(Category.id))) or 0
        total_sellers = db.scalar(select(func.count(Seller.id))) or 0
        total_users = db.scalar(select(func.count(User.id))) or 0

        return {
            "total_restaurants": total_restaurants,
            "active_restaurants": active_restaurants,
            "inactive_restaurants": inactive_restaurants,
            "total_dishes": total_dishes,
            "total_categories": total_categories,
            "total_sellers": total_sellers,
            "total_users": total_users,
        }

    @staticmethod
    def get_all_sellers(db: Session) -> List[Dict[str, Any]]:
        """Lấy danh sách toàn bộ đối tác Chủ Quán (Seller) kèm số quán sở hữu."""
        sellers = db.scalars(select(Seller).order_by(Seller.id.desc())).all()
        result = []
        for s in sellers:
            r_count = db.scalar(select(func.count(Restaurant.id)).where(Restaurant.seller_id == s.id)) or 0
            result.append({
                "id": s.id,
                "email": s.email,
                "full_name": s.full_name,
                "shop_name": s.shop_name,
                "phone": s.phone,
                "is_active": s.is_active,
                "restaurant_count": r_count,
                "created_at": s.created_at,
            })
        return result

    @staticmethod
    def get_all_users(db: Session) -> List[User]:
        """Lấy danh sách toàn bộ người dùng (User/Thực khách) trong hệ thống."""
        return list(db.scalars(select(User).order_by(User.id.desc())).all())

    @staticmethod
    def update_restaurant_status(db: Session, restaurant_id: int, is_active: bool) -> Optional[Restaurant]:
        """Bật/tắt trạng thái hoạt động của quán ăn theo quyền Admin."""
        restaurant = db.get(Restaurant, restaurant_id)
        if not restaurant:
            return None
        restaurant.is_active = is_active
        db.commit()
        db.refresh(restaurant)
        return restaurant

    @staticmethod
    def delete_restaurant_as_admin(db: Session, restaurant_id: int) -> bool:
        """Xoá quán ăn theo quyền Admin."""
        restaurant = db.get(Restaurant, restaurant_id)
        if not restaurant:
            return False
        db.delete(restaurant)
        db.commit()
        return True

