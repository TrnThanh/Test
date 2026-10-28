from typing import Optional, List, Dict, Any
from sqlalchemy import select, func
from sqlalchemy.orm import Session

from server.app.core.security import hash_password, verify_password
from server.app.models.admin import Admin
from server.app.models.user import User
from server.app.models.restaurant import Restaurant
from server.app.models.category import Category
from server.app.models.dish import Dish


# Lớp dịch vụ quản trị hệ thống, thống kê và kiểm soát quyền admin
class AdminService:
    # Tra cứu thông tin quản trị viên theo email duy nhất
    @staticmethod
    def get_admin_by_email(db: Session, email: str) -> Optional[Admin]:
        """Tìm tài khoản quản trị viên theo email."""
        # Thực hiện câu lệnh truy vấn tìm kiếm admin theo email
        statement = select(Admin).where(Admin.email == email.strip().lower())
        return db.scalars(statement).first()

    # Xác thực đăng nhập quản trị viên qua email và mật khẩu
    @staticmethod
    def authenticate_admin(db: Session, email: str, password: str) -> Optional[Admin]:
        """Xác thực thông tin đăng nhập admin."""
        # 1. Tìm tài khoản admin
        admin = AdminService.get_admin_by_email(db, email)
        if not admin:
            return None
        # 2. So khớp mật khẩu đã băm
        if not verify_password(password, admin.hashed_password):
            return None
        return admin

    # Tự động nạp tài khoản Admin quản trị mặc định ban đầu nếu chưa có
    @staticmethod
    def seed_default_admin(db: Session) -> Admin:
        """Tự động khởi tạo tài khoản Admin mặc định nếu chưa tồn tại trong hệ thống."""
        default_email = "admin@example.com"
        # 1. Kiểm tra tài khoản admin mặc định
        admin = AdminService.get_admin_by_email(db, default_email)
        if not admin:
            # 2. Tạo tài khoản admin cấp 1
            admin = Admin(
                email=default_email,
                hashed_password=hash_password("admin123"),
                full_name="System Administrator",
            )
            db.add(admin)
            db.commit()
            db.refresh(admin)
        return admin

    # Thống kê tổng hợp số liệu CSDL phục vụ hiển thị trên Admin Dashboard
    @staticmethod
    def get_system_stats(db: Session) -> Dict[str, Any]:
        """Thống kê tổng quan dữ liệu toàn hệ thống cho Dashboard Quản Trị."""
        # 1. Đếm tổng số cơ sở ẩm thực
        total_restaurants = db.scalar(select(func.count(Restaurant.id))) or 0
        # 2. Đếm số quán ăn đang hoạt động
        active_restaurants = db.scalar(select(func.count(Restaurant.id)).where(Restaurant.is_active.is_(True))) or 0
        inactive_restaurants = total_restaurants - active_restaurants
        # 3. Đếm số món ăn, danh mục và người dùng
        total_dishes = db.scalar(select(func.count(Dish.id))) or 0
        total_categories = db.scalar(select(func.count(Category.id))) or 0
        total_users = db.scalar(select(func.count(User.id))) or 0

        # 4. Trả về đối tượng dictionary thống kê
        return {
            "total_restaurants": total_restaurants,
            "active_restaurants": active_restaurants,
            "inactive_restaurants": inactive_restaurants,
            "total_dishes": total_dishes,
            "total_categories": total_categories,
            "total_users": total_users,
        }

    # Lấy danh sách toàn bộ người dùng đã đăng ký trong hệ thống
    @staticmethod
    def get_all_users(db: Session) -> List[User]:
        """Lấy danh sách toàn bộ người dùng (User/Thực khách) trong hệ thống."""
        # Truy vấn danh sách người dùng sắp xếp theo ID giảm dần
        return list(db.scalars(select(User).order_by(User.id.desc())).all())

    # Bật hoặc tắt trạng thái kích hoạt của quán ăn theo quyền quản trị viên
    @staticmethod
    def update_restaurant_status(db: Session, restaurant_id: int, is_active: bool) -> Optional[Restaurant]:
        """Bật/tắt trạng thái hoạt động của quán ăn theo quyền Admin."""
        # 1. Tìm quán ăn theo ID
        restaurant = db.get(Restaurant, restaurant_id)
        if not restaurant:
            return None
        # 2. Cập nhật trạng thái và commit
        restaurant.is_active = is_active
        db.commit()
        db.refresh(restaurant)
        return restaurant

    # Xoá vĩnh viễn cơ sở quán ăn khỏi hệ thống theo quyền quản trị viên
    @staticmethod
    def delete_restaurant_as_admin(db: Session, restaurant_id: int) -> bool:
        """Xoá quán ăn theo quyền Admin."""
        # 1. Tìm quán ăn theo ID
        restaurant = db.get(Restaurant, restaurant_id)
        if not restaurant:
            return False
        # 2. Xoá khỏi database
        db.delete(restaurant)
        db.commit()
        return True
