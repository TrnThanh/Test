from typing import List, Optional
from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from server.app.models.user import User
from server.app.models.category import Category
from server.app.models.option_user import OptionUser
from server.app.schemas.option_user import OptionUserCreate, OptionUserUpdate


class OptionUserService:
    @staticmethod
    def get_user_options(db: Session, user_id: int, hide: Optional[bool] = None) -> List[OptionUser]:
        """Lấy danh sách các tùy chọn ẩn/hiện danh mục của người dùng."""
        user = db.get(User, user_id)
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Không tìm thấy người dùng với ID {user_id}.",
            )

        query = select(OptionUser).where(OptionUser.user_id == user_id)
        if hide is not None:
            query = query.where(OptionUser.hide == hide)
        return list(db.scalars(query).all())

    @staticmethod
    def create_user_option(db: Session, user_id: int, data: OptionUserCreate) -> OptionUser:
        """Tạo tùy chọn ẩn/hiện danh mục cho người dùng (Phương án B: POST)."""
        user = db.get(User, user_id)
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Không tìm thấy người dùng với ID {user_id}.",
            )

        category = db.get(Category, data.category_id)
        if not category:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Không tìm thấy danh mục với ID {data.category_id}.",
            )

        # Kiểm tra nếu đã có bản ghi cho category này của user -> cập nhật hide
        stmt = select(OptionUser).where(
            OptionUser.user_id == user_id,
            OptionUser.category_id == data.category_id,
        )
        existing = db.scalar(stmt)
        if existing:
            existing.hide = data.hide
            db.commit()
            db.refresh(existing)
            return existing

        option = OptionUser(
            user_id=user_id,
            category_id=data.category_id,
            hide=data.hide,
        )
        db.add(option)
        db.commit()
        db.refresh(option)
        return option

    @staticmethod
    def delete_user_option(db: Session, user_id: int, option_id: int) -> None:
        """Xóa một bản ghi tùy chọn theo ID."""
        user = db.get(User, user_id)
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Không tìm thấy người dùng với ID {user_id}.",
            )

        option = db.get(OptionUser, option_id)
        if not option or option.user_id != user_id:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Không tìm thấy tùy chọn ID {option_id} của người dùng {user_id}.",
            )

        db.delete(option)
        db.commit()
