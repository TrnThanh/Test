from datetime import datetime, timezone
from typing import Optional
from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from server.app.models.user import User
from server.app.models.category import Category
from server.app.schemas.user_profile import UserProfileUpdate


# Lớp dịch vụ quản lý hồ sơ thể chất, mục tiêu và sở thích ẩm thực của người dùng
class UserProfileService:
    # Lấy thông tin hồ sơ người dùng trực tiếp từ bảng users
    @staticmethod
    def get_user_profile(db: Session, user_id: int) -> User:
        """Lấy hồ sơ người dùng trực tiếp từ bảng users."""
        # 1. Tìm kiếm người dùng theo ID
        user = db.get(User, user_id)
        # 2. Xử lý trường hợp không tìm thấy tài khoản
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Không tìm thấy người dùng với ID {user_id}.",
            )
        # 3. Trả về thực thể người dùng
        return user

    # Giữ tên cũ để tương thích ngược hoàn toàn với các unit tests và endpoints hiện tại
    get_or_create_profile = get_user_profile

    # Cập nhật thông tin thể chất, sở thích món ăn và cờ hoàn thành Onboarding
    @staticmethod
    def update_profile(db: Session, user_id: int, data: UserProfileUpdate) -> User:
        """Cập nhật thông tin hồ sơ sức khỏe & sở thích ẩm thực trực tiếp vào bảng users."""
        # 1. Truy vấn thông tin người dùng hiện tại
        user = UserProfileService.get_user_profile(db, user_id)

        # 2. Bóc tách dữ liệu cập nhật, loại bỏ cờ complete_onboarding để xử lý riêng
        update_data = data.model_dump(exclude_unset=True, exclude={"complete_onboarding"})

        # 3. Validate và lọc danh sách category IDs nếu được truyền lên
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

        # 4. Cập nhật các trường thông tin vào thực thể User
        for field, value in update_data.items():
            setattr(user, field, value)

        # 5. Xử lý cờ hoàn thành khảo sát Onboarding lần đầu
        if data.complete_onboarding and not user.is_onboarded:
            user.is_onboarded = True
            user.onboarded_at = datetime.now(timezone.utc)

        # 6. Ghi nhận thời gian cập nhật và lưu thay đổi vào cơ sở dữ liệu
        user.updated_at = datetime.now(timezone.utc)
        db.commit()
        db.refresh(user)
        return user
