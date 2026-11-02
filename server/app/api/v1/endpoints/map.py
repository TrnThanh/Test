from fastapi import APIRouter, Depends, Query, Request
from server.app.schemas.map import MapSearchResponse, MapReverseResponse
from server.app.services.map_service import MapService, map_service

router = APIRouter()


# Dependency cung cấp singleton service bản đồ
def get_map_service() -> MapService:
    """Trả về thể hiện singleton của MapService."""
    # Trả về đối tượng map_service toàn cục
    return map_service


# [POSTMAN GUIDE]
# GET http://localhost:8001/api/v1/map/search?q=Học viện Nông nghiệp Việt Nam&limit=5
# Headers: (Không yêu cầu)
# Đầu vào (Query Params):
#   - q     : "Học viện Nông nghiệp Việt Nam" (string, bắt buộc)
#   - limit : 5                              (int 1-50, default: 10)
# Status Code gợi ý:
#   - 200 OK                   : Tìm kiếm địa điểm thành công
#   - 422 Unprocessable Content: Thiếu tham số q hoặc limit không hợp lệ
@router.get("/search", response_model=MapSearchResponse, summary="Tìm kiếm địa điểm (Forward Geocoding)")
async def search_places(
    q: str = Query(..., min_length=1, description="Từ khoá tìm kiếm địa điểm, địa chỉ"),
    limit: int = Query(10, ge=1, le=50, description="Số lượng kết quả tối đa trả về"),
    service: MapService = Depends(get_map_service),
) -> MapSearchResponse:
    # Gửi truy vấn tìm kiếm địa điểm tới Nominatim API
    return await service.search(query=q, limit=limit)


# [POSTMAN GUIDE]
# GET http://localhost:8001/api/v1/map/reverse?lat=21.0046&lon=105.9387
# Headers: (Không yêu cầu)
# Đầu vào (Query Params):
#   - lat: 21.0046  (float -90 đến 90, bắt buộc)
#   - lon: 105.9387 (float -180 đến 180, bắt buộc)
# Status Code gợi ý:
#   - 200 OK                   : Tra cứu địa chỉ từ toạ độ thành công
#   - 404 Not Found            : Không tìm thấy địa chỉ tại toạ độ cung cấp
#   - 422 Unprocessable Content: Toạ độ ngoài phạm vi cho phép
@router.get("/reverse", response_model=MapReverseResponse, summary="Tra cứu địa chỉ từ toạ độ (Reverse Geocoding)")
async def reverse_geocode(
    lat: float = Query(..., ge=-90.0, le=90.0, description="Vĩ độ (Latitude, từ -90 đến 90)"),
    lon: float = Query(..., ge=-180.0, le=180.0, description="Kinh độ (Longitude, từ -180 đến 180)"),
    service: MapService = Depends(get_map_service),
) -> MapReverseResponse:
    # Tra cứu địa chỉ ngược từ toạ độ lat, lon
    return await service.reverse(lat=lat, lon=lon)
