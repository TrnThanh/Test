from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
from server.app.db.session import get_db
from server.app.schemas.user_profile import UserProfileUpdate, UserProfileResponse
from server.app.services.user_profile_service import UserProfileService

router = APIRouter()


@router.get(
    "/{user_id}/profile",
    response_model=UserProfileResponse,
    status_code=status.HTTP_200_OK,
    summary="Lấy hồ sơ sức khỏe và sở thích ẩm thực của người dùng",
    description="Lấy thông tin chi tiết hồ sơ người dùng (chiều cao, cân nặng, BMI, mục tiêu, sở thích ẩm thực, khẩu vị cay, dị ứng, ngân sách và trạng thái khảo sát onboarding). Tự động tạo hồ sơ mặc định nếu người dùng chưa có.",
)
def get_user_profile(
    user_id: int,
    db: Session = Depends(get_db),
) -> UserProfileResponse:
    return UserProfileService.get_or_create_profile(db=db, user_id=user_id)


@router.put(
    "/{user_id}/profile",
    response_model=UserProfileResponse,
    status_code=status.HTTP_200_OK,
    summary="Cập nhật hồ sơ sức khỏe và sở thích ẩm thực (kèm hoàn thành khảo sát)",
    description="Cập nhật từng phần hoặc toàn phần hồ sơ cá nhân. Gửi kèm complete_onboarding: true khi người dùng hoàn thành khảo sát lần đầu.",
)
def update_user_profile(
    user_id: int,
    data: UserProfileUpdate,
    db: Session = Depends(get_db),
) -> UserProfileResponse:
    return UserProfileService.update_profile(db=db, user_id=user_id, data=data)
