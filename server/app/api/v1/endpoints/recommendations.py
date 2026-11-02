from typing import Optional
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from server.app.db.session import get_db
from server.app.schemas.recommendation import ContextualRecommendationResponse
from server.app.services.recommendation_service import RecommendationService

router = APIRouter()


# [POSTMAN GUIDE]
# GET http://localhost:8001/api/v1/recommendations/contextual?lat=21.0046&lon=105.9387&user_id=1&temp=25.0&weather_code=mild
# Headers: (Không yêu cầu)
# Đầu vào (Query Params):
#   - lat          : 21.0046  (float -90 đến 90, bắt buộc)
#   - lon          : 105.9387 (float -180 đến 180, bắt buộc)
#   - user_id      : 1        (int, tuỳ chọn)
#   - temp         : 25.0     (float -10 đến 50, tuỳ chọn)
#   - weather_code : "mild"   (string, tuỳ chọn: hot, cold, rainy, mild)
#   - seed         : 42       (int, tuỳ chọn)
# Status Code gợi ý:
#   - 200 OK                   : Gợi ý ẩm thực theo ngữ cảnh đa chiều (CARS) thành công
#   - 422 Unprocessable Content: Toạ độ GPS ngoài phạm vi hợp lệ
@router.get(
    "/contextual",
    response_model=ContextualRecommendationResponse,
    status_code=status.HTTP_200_OK,
    summary="Gợi ý ẩm thực theo ngữ cảnh đa chiều (CARS)",
    description=(
        "Đề xuất danh sách quán ăn theo ngữ cảnh thời gian, thời tiết, khoảng cách địa lý PostGIS 15km, "
        "nhu cầu calo thể trạng (TDEE/BMI), phòng vệ dị ứng 2 lớp, lọc ăn chay và sở thích cá nhân/học ngầm."
    ),
)
def get_contextual_recommendations(
    lat: float = Query(..., ge=-90.0, le=90.0, description="Vĩ độ GPS người dùng"),
    lon: float = Query(..., ge=-180.0, le=180.0, description="Kinh độ GPS người dùng"),
    user_id: Optional[int] = Query(None, description="ID người dùng để cá nhân hóa (Bỏ trống nếu là Guest)"),
    temp: Optional[float] = Query(None, ge=-10.0, le=50.0, description="Nhiệt độ ngoài trời (°C)"),
    weather_code: Optional[str] = Query(None, description="Mã thời tiết: hot, cold, rainy, mild"),
    seed: Optional[int] = Query(None, description="Seed ngẫu nhiên phục vụ kiểm thử đơn vị"),
    db: Session = Depends(get_db),
) -> ContextualRecommendationResponse:
    # Kích hoạt thuật toán tính điểm và xếp hạng CARS từ RecommendationService
    return RecommendationService.get_contextual_recommendations(
        db=db,
        lat=lat,
        lon=lon,
        user_id=user_id,
        temp=temp,
        weather_code=weather_code,
        seed=seed,
    )
