from datetime import datetime, timezone
from typing import Optional
from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from server.app.models.user import User
from server.app.models.user_profile import UserProfile
from server.app.models.category import Category
from server.app.schemas.user_profile import UserProfileUpdate


class UserProfileService:
    @staticmethod
    def get_or_create_profile(db: Session, user_id: int) -> UserProfile:
        """Lấy hồ sơ người dùng. Nếu chưa tồn tại, tự động tạo mới (idempotent get-or-create)."""
        user = db.get(User, user_id)
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Không tìm thấy người dùng với ID {user_id}.",
            )

        stmt = select(UserProfile).where(UserProfile.user_id == user_id)
        profile = db.scalar(stmt)
        if not profile:
            profile = UserProfile(user_id=user_id)
            db.add(profile)
            db.commit()
            db.refresh(profile)

        return profile

    @staticmethod
    def update_profile(db: Session, user_id: int, data: UserProfileUpdate) -> UserProfile:
        """Cập nhật thông tin hồ sơ sức khỏe & sở thích ẩm thực của người dùng."""
        profile = UserProfileService.get_or_create_profile(db, user_id)

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
            setattr(profile, field, value)

        # Xử lý cờ hoàn thành Onboarding
        if data.complete_onboarding and not profile.is_onboarded:
            profile.is_onboarded = True
            profile.onboarded_at = datetime.now(timezone.utc)

        db.commit()
        db.refresh(profile)
        return profile
