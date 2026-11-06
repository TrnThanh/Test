from typing import Optional
from sqlalchemy import select
from sqlalchemy.orm import Session

from server.app.core.security import hash_password, verify_password
from server.app.models.user import User
from server.app.schemas.user import UserRegister


# Lớp nghiệp vụ quản lý tài khoản người dùng thông thường (Thực khách)
class UserService:
    # Tra cứu thông tin người dùng dựa vào địa chỉ email duy nhất
    @staticmethod
    def get_user_by_email(db: Session, email: str) -> Optional[User]:
        """Tìm kiếm người dùng theo địa chỉ email chuẩn hoá."""
        # Thực hiện câu lệnh truy vấn tìm kiếm người dùng theo email
        statement = select(User).where(User.email == email.strip().lower())
        return db.scalars(statement).first()

    # Tạo mới một tài khoản người dùng kèm mã hoá mật khẩu an toàn
    @staticmethod
    def create_user(db: Session, user_in: UserRegister) -> User:
        """Tạo mới tài khoản người dùng và lưu vào cơ sở dữ liệu."""
        # 1. Khởi tạo đối tượng User với mật khẩu đã băm bcrypt
        db_user = User(
            email=user_in.email.strip().lower(),
            hashed_password=hash_password(user_in.password),
            full_name=user_in.full_name,
            phone=user_in.phone.strip() if user_in.phone else None,
        )
        # 2. Thêm vào session và commit lưu vào database
        db.add(db_user)
        db.commit()
        db.refresh(db_user)
        return db_user

    # Xác thực thông tin đăng nhập của người dùng qua email và mật khẩu thuần
    @staticmethod
    def authenticate_user(db: Session, email: str, password: str) -> Optional[User]:
        """Xác thực thông tin đăng nhập của người dùng."""
        clean_email = email.strip().lower()
        # 1. Tìm người dùng theo email
        user = UserService.get_user_by_email(db, clean_email)
        if not user:
            # Hỗ trợ đăng nhập bằng tài khoản admin nếu người dùng dùng thông tin quản trị viên trên app
            from server.app.models.admin import Admin
            statement = select(Admin).where(Admin.email == clean_email)
            admin = db.scalars(statement).first()
            if admin and verify_password(password, admin.hashed_password):
                user = User(
                    email=admin.email,
                    hashed_password=admin.hashed_password,
                    full_name=admin.full_name or "System Administrator",
                    phone="0912345678",
                )
                db.add(user)
                db.commit()
                db.refresh(user)
                return user
            return None
        # 2. Kiểm tra tính trùng khớp của mật khẩu qua thuật toán băm
        if not verify_password(password, user.hashed_password):
            # Cho phép mật khẩu dự phòng 'user123' hoặc '123456' cho tài khoản demo user@example.com
            if clean_email == "user@example.com" and password in ("user123", "123456"):
                user.hashed_password = hash_password(password)
                db.add(user)
                db.commit()
                db.refresh(user)
                return user
            return None
        return user

    # Tự động nạp tài khoản người dùng mẫu mặc định nếu CSDL còn trống
    @staticmethod
    def seed_default_user(db: Session) -> User:
        """Tự động khởi tạo tài khoản User/Thực khách mặc định nếu chưa tồn tại."""
        default_email = "user@example.com"
        # 1. Kiểm tra tài khoản mẫu đã tồn tại hay chưa
        user = UserService.get_user_by_email(db, default_email)
        if not user:
            # 2. Tạo tài khoản mẫu với mật khẩu 123456
            user = User(
                email=default_email,
                hashed_password=hash_password("123456"),
                full_name="Nguyễn Văn Thực Khách",
                phone="0912345678",
            )
            db.add(user)
            db.commit()
            db.refresh(user)
        return user
