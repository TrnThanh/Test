from typing import List, Optional
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from server.app.db.session import get_db
from server.app.schemas.weather import WeatherResponse, WeatherCreate, WeatherUpdate, CurrentWeatherResponse
from server.app.services.weather_service import WeatherService

router = APIRouter()


# Lấy dữ liệu thời tiết thực tế từ OpenWeatherMap kèm các danh mục món ăn phù hợp với thời tiết
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
    """
    [POSTMAN TEST GUIDE]
    - Method  : GET
    - URL     : http://localhost:8001/api/v1/weather/current?lat=21.0046&lon=105.9387
    - Headers : (Không yêu cầu)
    - Params  : lat (float, mặc định HVNN 21.0046), lon (float, mặc định HVNN 105.9387)
    - Body    : (Không có)
    - Expected: 200 OK -> {"temperature": 26.5, "humidity": 70, "weather_name": "Nắng ấm", "weather_condition": "clear", "recommended_categories": [...]}
    - Errors  : 422 Unprocessable Content (toạ độ ngoài phạm vi)
    """
    # 1. Đảm bảo dữ liệu thời tiết mặc định đã được khởi tạo trong CSDL
    WeatherService.seed_default_weathers(db)
    # 2. Gọi OpenWeatherMap API hoặc fallback dữ liệu nếu không có API key
    return await WeatherService.fetch_current_weather(db=db, lat=lat, lon=lon)


# Lấy danh sách toàn bộ các trạng thái thời tiết được cấu hình trong hệ thống
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
    """
    [POSTMAN TEST GUIDE]
    - Method  : GET
    - URL     : http://localhost:8001/api/v1/weather?active_only=true
    - Headers : (Không yêu cầu)
    - Params  : active_only (bool, mặc định true)
    - Body    : (Không có)
    - Expected: 200 OK -> [{"id": 1, "code": "cold", "name": "Trời lạnh", "temp_min": 10.0, "temp_max": 19.0, "is_active": true}]
    """
    # 1. Khởi tạo dữ liệu seed nếu chưa có
    WeatherService.seed_default_weathers(db)
    # 2. Lấy danh sách thời tiết từ database
    return WeatherService.get_all_weathers(db, active_only=active_only)


# Lấy chi tiết thông tin một trạng thái thời tiết cụ thể theo ID
@router.get(
    "/{weather_id}",
    response_model=WeatherResponse,
    summary="Chi tiết một trạng thái thời tiết",
)
def get_weather(
    weather_id: int,
    db: Session = Depends(get_db),
):
    """
    [POSTMAN TEST GUIDE]
    - Method  : GET
    - URL     : http://localhost:8001/api/v1/weather/1
    - Headers : (Không yêu cầu)
    - Params  : Path weather_id (int)
    - Body    : (Không có)
    - Expected: 200 OK -> {"id": 1, "code": "cold", "name": "Trời lạnh", ...}
    - Errors  : 404 Not Found
    """
    # Tìm kiếm kiểu thời tiết theo ID
    return WeatherService.get_weather_by_id(db, weather_id)


# Tạo mới một trạng thái thời tiết vào hệ thống
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
    """
    [POSTMAN TEST GUIDE]
    - Method  : POST
    - URL     : http://localhost:8001/api/v1/weather
    - Headers : Content-Type: application/json
    - Params  : (Không có)
    - Body (raw JSON):
      {
        "code": "freezing",
        "name": "Rét buốt có tuyết",
        "description": "Nhiệt độ dưới 5 độ",
        "temp_min": -5.0,
        "temp_max": 5.0,
        "is_active": true
      }
    - Expected: 201 Created -> {"id": 5, "code": "freezing", "name": "Rét buốt có tuyết", ...}
    - Errors  : 400 Bad Request (trùng code), 422 Unprocessable Content
    """
    # Tạo bản ghi thời tiết mới
    return WeatherService.create_weather(db, data)


# Cập nhật thông tin cấu hình trạng thái thời tiết
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
    """
    [POSTMAN TEST GUIDE]
    - Method  : PUT
    - URL     : http://localhost:8001/api/v1/weather/1
    - Headers : Content-Type: application/json
    - Params  : Path weather_id (int)
    - Body (raw JSON):
      {
        "name": "Trời se lạnh",
        "temp_min": 12.0,
        "temp_max": 20.0,
        "is_active": true
      }
    - Expected: 200 OK -> {"id": 1, "name": "Trời se lạnh", ...}
    - Errors  : 404 Not Found, 422 Unprocessable Content
    """
    return WeatherService.update_weather(db, weather_id, data)


# Xoá một trạng thái thời tiết khỏi hệ thống
@router.delete(
    "/{weather_id}",
    summary="Xoá trạng thái thời tiết",
)
def delete_weather(
    weather_id: int,
    db: Session = Depends(get_db),
):
    """
    [POSTMAN TEST GUIDE]
    - Method  : DELETE
    - URL     : http://localhost:8001/api/v1/weather/1
    - Headers : (Không yêu cầu)
    - Params  : Path weather_id (int)
    - Body    : (Không có)
    - Expected: 200 OK -> {"message": "Đã xoá trạng thái thời tiết ID 1 thành công."}
    - Errors  : 404 Not Found
    """
    WeatherService.delete_weather(db, weather_id)
    return {"message": f"Đã xoá trạng thái thời tiết ID {weather_id} thành công."}
