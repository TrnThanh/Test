from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
from server.app.db.session import get_db
from server.app.schemas.user_profile import UserProfileUpdate, UserProfileResponse
from server.app.services.user_profile_service import UserProfileService

router = APIRouter()


# Lấy thông tin hồ sơ sức khoẻ, thể trạng (BMI) và sở thích dinh dưỡng của người dùng
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
    """
    [POSTMAN TEST GUIDE]
    - Method  : GET
    - URL     : http://localhost:8001/api/v1/users/1/profile
    - Headers : (Không yêu cầu)
    - Params  : Path user_id (int)
    - Body    : (Không có)
    - Expected: 200 OK -> {"id": 1, "user_id": 1, "height_cm": 170.0, "weight_kg": 65.0, "bmi": 22.49, "favorite_category_ids": [1, 2], "is_onboarded": true}
    - Errors  : 404 Not Found (User không tồn tại)
    """
    # Gọi service lấy hồ sơ hoặc tạo mặc định nếu người dùng mới
    return UserProfileService.get_or_create_profile(db=db, user_id=user_id)


# Cập nhật thông tin hồ sơ thể trạng và hoàn tất khảo sát Onboarding ban đầu
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
    """
    [POSTMAN TEST GUIDE]
    - Method  : PUT
    - URL     : http://localhost:8001/api/v1/users/1/profile
    - Headers : Content-Type: application/json
    - Params  : Path user_id (int)
    - Body (raw JSON):
      {
        "height_cm": 172.5,
        "weight_kg": 64.0,
        "goal": "Duy trì cân nặng",
        "dietary_preference": "none",
        "favorite_category_ids": [1, 2],
        "spicy_tolerance": 2,
        "budget_level": "medium",
        "complete_onboarding": true
      }
    - Expected: 200 OK -> {"id": 1, "user_id": 1, "height_cm": 172.5, "weight_kg": 64.0, "bmi": 21.51, "is_onboarded": true, ...}
    - Errors  : 404 Not Found, 422 Unprocessable Content
    """
    # Cập nhật thông tin qua service
    return UserProfileService.update_profile(db=db, user_id=user_id, data=data)
