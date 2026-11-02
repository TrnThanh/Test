from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
from server.app.db.session import get_db
from server.app.schemas.user_profile import UserProfileUpdate, UserProfileResponse
from server.app.services.user_profile_service import UserProfileService

router = APIRouter()


# [POSTMAN GUIDE]
# GET http://localhost:8001/api/v1/users/1/profile
# Headers: (Không yêu cầu)
# Đầu vào (Path Param):
#   - user_id: 1 (int, bắt buộc)
# Status Code gợi ý:
#   - 200 OK       : Lấy thông tin hồ sơ sức khoẻ và thể trạng thành công
#   - 404 Not Found: Người dùng không tồn tại
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
    # Gọi service lấy hồ sơ hoặc tạo mặc định nếu người dùng mới
    return UserProfileService.get_or_create_profile(db=db, user_id=user_id)


# [POSTMAN GUIDE]
# PUT http://localhost:8001/api/v1/users/1/profile
# Headers:
#   Content-Type: application/json
# Đầu vào (Path Param):
#   - user_id: 1 (int, bắt buộc)
# Đầu vào (Body raw JSON):
# {
#   "height_cm": 172.5,                   // float (tuỳ chọn)
#   "weight_kg": 64.0,                    // float (tuỳ chọn)
#   "goal": "Duy trì cân nặng",           // string (tuỳ chọn)
#   "dietary_preference": "none",         // string (tuỳ chọn)
#   "favorite_category_ids": [1, 2],      // array[int] (tuỳ chọn)
#   "spicy_tolerance": 2,                 // int 0-3 (tuỳ chọn)
#   "budget_level": "medium",             // string (tuỳ chọn)
#   "complete_onboarding": true           // bool (tuỳ chọn)
# }
# Status Code gợi ý:
#   - 200 OK                   : Cập nhật hồ sơ thể trạng thành công
#   - 404 Not Found            : Người dùng không tồn tại
#   - 422 Unprocessable Content: Sai kiểu dữ liệu
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
    # Cập nhật thông tin qua service
    return UserProfileService.update_profile(db=db, user_id=user_id, data=data)
