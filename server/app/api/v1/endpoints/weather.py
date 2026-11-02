from typing import List, Optional
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from server.app.db.session import get_db
from server.app.schemas.weather import WeatherResponse, WeatherCreate, WeatherUpdate, CurrentWeatherResponse
from server.app.services.weather_service import WeatherService

router = APIRouter()


# [POSTMAN GUIDE]
# GET http://localhost:8001/api/v1/weather/current?lat=21.0046&lon=105.9387
# Headers: (Không yêu cầu)
# Đầu vào (Query Params):
#   - lat: 21.0046  (float -90 đến 90, tuỳ chọn, mặc định toạ độ HVNN: 21.0046)
#   - lon: 105.9387 (float -180 đến 180, tuỳ chọn, mặc định toạ độ HVNN: 105.9387)
# Status Code gợi ý:
#   - 200 OK                   : Lấy thông tin thời tiết thực tế & danh mục phù hợp thành công
#   - 422 Unprocessable Content: Toạ độ ngoài phạm vi hợp lệ
@router.get(
    "/current",
    response_model=CurrentWeatherResponse,
    summary="Lấy thời tiết thực tế hiện tại & danh mục món ăn phù hợp (OpenWeatherMap)",
    description="Truy vấn dữ liệu thời tiết thời gian thực theo tọa độ (mặc định Học viện Nông nghiệp Việt Nam - HVNN), tự động chuẩn hóa và trả về các danh mục món ăn phù hợp.",
)
async def get_current_weather(
    lat: Optional[float] = Query(None, description="Vĩ độ (mặc định: toạ độ HVNN 21.0046)"),
    lon: Optional[float] = Query(None, description="Kinh độ (mặc định: toạ độ HVNN 105.9387)"),
    db: Session = Depends(get_db),
) -> CurrentWeatherResponse:
    # 1. Đảm bảo dữ liệu thời tiết mặc định đã được khởi tạo trong CSDL
    WeatherService.seed_default_weathers(db)
    # 2. Gọi OpenWeatherMap API hoặc fallback dữ liệu nếu không có API key
    return await WeatherService.fetch_current_weather(db=db, lat=lat, lon=lon)


# [POSTMAN GUIDE]
# GET http://localhost:8001/api/v1/weather?active_only=true
# Headers: (Không yêu cầu)
# Đầu vào (Query Params):
#   - active_only: true (bool, default: true)
# Status Code gợi ý:
#   - 200 OK: Lấy danh sách trạng thái thời tiết cấu hình thành công
@router.get(
    "",
    response_model=List[WeatherResponse],
    summary="Lấy danh sách trạng thái thời tiết",
    description="Truy vấn danh sách các điều kiện thời tiết chuẩn bị cho tính năng gợi ý món ăn theo thời tiết.",
)
def list_weathers(
    active_only: bool = True,
    db: Session = Depends(get_db),
):
    # 1. Khởi tạo dữ liệu seed nếu chưa có
    WeatherService.seed_default_weathers(db)
    # 2. Lấy danh sách thời tiết từ database
    return WeatherService.get_all_weathers(db, active_only=active_only)


# [POSTMAN GUIDE]
# GET http://localhost:8001/api/v1/weather/1
# Headers: (Không yêu cầu)
# Đầu vào (Path Param):
#   - weather_id: 1 (int, bắt buộc)
# Status Code gợi ý:
#   - 200 OK       : Lấy chi tiết trạng thái thời tiết thành công
#   - 404 Not Found: Trạng thái thời tiết không tồn tại
@router.get(
    "/{weather_id}",
    response_model=WeatherResponse,
    summary="Chi tiết một trạng thái thời tiết",
)
def get_weather(
    weather_id: int,
    db: Session = Depends(get_db),
):
    # Tìm kiếm kiểu thời tiết theo ID
    return WeatherService.get_weather_by_id(db, weather_id)


# [POSTMAN GUIDE]
# POST http://localhost:8001/api/v1/weather
# Headers:
#   Content-Type: application/json
# Đầu vào (Body raw JSON):
# {
#   "code": "freezing",               // string (bắt buộc, unique)
#   "name": "Rét buốt có tuyết",      // string (bắt buộc)
#   "description": "Dưới 5 độ C",     // string (tuỳ chọn)
#   "temp_min": -5.0,                 // float (tuỳ chọn)
#   "temp_max": 5.0,                  // float (tuỳ chọn)
#   "is_active": true                 // bool (tuỳ chọn, default: true)
# }
# Status Code gợi ý:
#   - 201 Created              : Tạo mới trạng thái thời tiết thành công
#   - 400 Bad Request          : Mã code đã tồn tại
#   - 422 Unprocessable Content: Sai kiểu dữ liệu hoặc thiếu trường bắt buộc
@router.post(
    "",
    response_model=WeatherResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Tạo mới trạng thái thời tiết",
)
def create_weather(
    data: WeatherCreate,
    db: Session = Depends(get_db),
):
    # Tạo bản ghi thời tiết mới
    return WeatherService.create_weather(db, data)


# [POSTMAN GUIDE]
# PUT http://localhost:8001/api/v1/weather/1
# Headers:
#   Content-Type: application/json
# Đầu vào (Path Param):
#   - weather_id: 1 (int, bắt buộc)
# Đầu vào (Body raw JSON):
# {
#   "name": "Trời se lạnh",  // string (tuỳ chọn)
#   "temp_min": 12.0,        // float (tuỳ chọn)
#   "temp_max": 20.0,        // float (tuỳ chọn)
#   "is_active": true        // bool (tuỳ chọn)
# }
# Status Code gợi ý:
#   - 200 OK                   : Cập nhật trạng thái thời tiết thành công
#   - 404 Not Found            : Trạng thái thời tiết không tồn tại
#   - 422 Unprocessable Content: Dữ liệu cập nhật không hợp lệ
@router.put(
    "/{weather_id}",
    response_model=WeatherResponse,
    summary="Cập nhật trạng thái thời tiết",
)
def update_weather(
    weather_id: int,
    data: WeatherUpdate,
    db: Session = Depends(get_db),
):
    return WeatherService.update_weather(db, weather_id, data)


# [POSTMAN GUIDE]
# DELETE http://localhost:8001/api/v1/weather/1
# Headers: (Không yêu cầu)
# Đầu vào (Path Param):
#   - weather_id: 1 (int, bắt buộc)
# Status Code gợi ý:
#   - 200 OK       : Xoá trạng thái thời tiết thành công
#   - 404 Not Found: Trạng thái thời tiết không tồn tại
@router.delete(
    "/{weather_id}",
    summary="Xoá trạng thái thời tiết",
)
def delete_weather(
    weather_id: int,
    db: Session = Depends(get_db),
):
    WeatherService.delete_weather(db, weather_id)
    return {"message": f"Đã xoá trạng thái thời tiết ID {weather_id} thành công."}
