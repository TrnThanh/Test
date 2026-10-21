from typing import Optional
from sqlalchemy import select
from sqlalchemy.orm import Session

from server.app.core.security import hash_password, verify_password
from server.app.models.user import User
from server.app.schemas.user import UserRegister


class UserService:
    @staticmethod
    def get_user_by_email(db: Session, email: str) -> Optional[User]:
        statement = select(User).where(User.email == email.strip().lower())
        return db.scalars(statement).first()

    @staticmethod
    def create_user(db: Session, user_in: UserRegister) -> User:
        db_user = User(
            email=user_in.email.strip().lower(),
            hashed_password=hash_password(user_in.password),
            full_name=user_in.full_name,
        )
        db.add(db_user)
        db.commit()
        db.refresh(db_user)
        return db_user

    @staticmethod
    def authenticate_user(db: Session, email: str, password: str) -> Optional[User]:
        user = UserService.get_user_by_email(db, email)
        if not user:
            return None
        if not verify_password(password, user.hashed_password):
            return None
        return user

    @staticmethod
    def seed_default_user(db: Session) -> User:
        """Tự động khởi tạo tài khoản User/Thực khách mặc định nếu chưa tồn tại."""
        default_email = "user@example.com"
        user = UserService.get_user_by_email(db, default_email)
        if not user:
            user = User(
                email=default_email,
                hashed_password=hash_password("123456"),
                full_name="Nguyễn Văn Thực Khách",
                is_active=True,
            )
            db.add(user)
            db.commit()
            db.refresh(user)
        return user

