from datetime import datetime, timezone
from typing import Optional
from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from server.app.models.user import User
from server.app.models.category import Category
from server.app.schemas.user_profile import UserProfileUpdate


class UserProfileService:
    @staticmethod
    def get_or_create_profile(db: Session, user_id: int) -> User:
        """Lấy hồ sơ người dùng trực tiếp từ bảng users."""
        user = db.get(User, user_id)
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Không tìm thấy người dùng với ID {user_id}.",
            )
        return user

    @staticmethod
    def update_profile(db: Session, user_id: int, data: UserProfileUpdate) -> User:
        """Cập nhật thông tin hồ sơ sức khỏe & sở thích ẩm thực trực tiếp vào bảng users."""
        user = UserProfileService.get_or_create_profile(db, user_id)

        update_data = data.model_dump(exclude_unset=True, exclude={"complete_onboarding"})

        # Validate và lọc danh sách category IDs nếu được truyền
        if "favorite_category_ids" in update_data and update_data["favorite_category_ids"] is not None:
            cat_ids = update_data["favorite_category_ids"]
            if cat_ids:
                stmt = select(Category.id).where(Category.id.in_(cat_ids))
                valid_ids = set(db.scalars(stmt).all())
                # Giữ nguyên thứ tự và loại bỏ trùng lặp / id không hợp lệ
                filtered_ids = []
                seen = set()
                for cid in cat_ids:
                    if cid in valid_ids and cid not in seen:
                        filtered_ids.append(cid)
                        seen.add(cid)
                update_data["favorite_category_ids"] = filtered_ids
            else:
                update_data["favorite_category_ids"] = []

        # Cập nhật các trường
        for field, value in update_data.items():
            setattr(user, field, value)

        # Xử lý cờ hoàn thành Onboarding
        if data.complete_onboarding and not user.is_onboarded:
            user.is_onboarded = True
            user.onboarded_at = datetime.now(timezone.utc)

        user.updated_at = datetime.now(timezone.utc)
        db.commit()
        db.refresh(user)
        return user
