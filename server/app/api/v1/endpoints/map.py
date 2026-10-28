from fastapi import APIRouter, Depends, Query, Request
from server.app.schemas.map import MapSearchResponse, MapReverseResponse, IpLocationResponse
from server.app.services.map_service import MapService, map_service

router = APIRouter()


# Dependency cung cấp singleton service bản đồ
def get_map_service() -> MapService:
    """Trả về thể hiện singleton của MapService."""
    # Trả về đối tượng map_service toàn cục
    return map_service


# Tự động xác định toạ độ địa lý theo địa chỉ IP của client (có fallback về Học viện Nông nghiệp)
@router.get(
    "/ip-location",
    response_model=IpLocationResponse,
    summary="Định vị toạ độ trực tuyến theo IP client (Online IP Geolocation)",
    description="Tự động xác định toạ độ địa lý của người dùng qua mạng Internet. Tự động fallback về toạ độ Học viện Nông nghiệp Việt Nam khi chạy trên IP localhost/private hoặc lỗi mạng.",
)
async def get_ip_location(
    request: Request,
    service: MapService = Depends(get_map_service),
) -> IpLocationResponse:
    """Xác định vị trí toạ độ địa lý của thiết bị dựa trên IP client."""
    # Gọi hàm định vị IP từ map_service
    return await service.get_ip_location(request=request)


# Tìm kiếm địa điểm theo tên hoặc địa chỉ sử dụng OpenStreetMap Nominatim (Forward Geocoding)
@router.get("/search", response_model=MapSearchResponse, summary="Tìm kiếm địa điểm (Forward Geocoding)")
async def search_places(
    q: str = Query(..., min_length=1, description="Từ khoá tìm kiếm địa điểm, địa chỉ"),
    limit: int = Query(10, ge=1, le=50, description="Số lượng kết quả tối đa trả về"),
    service: MapService = Depends(get_map_service),
) -> MapSearchResponse:
    """
    Tìm kiếm thông tin địa điểm theo tên hoặc địa chỉ sử dụng OpenStreetMap Nominatim.
    Trả về danh sách các địa điểm tìm thấy kèm theo toạ độ (lat, lon).
    """
    # Gửi truy vấn tìm kiếm địa điểm tới Nominatim API
    return await service.search(query=q, limit=limit)


# Đổi toạ độ kinh độ / vĩ độ thành địa chỉ thực tế (Reverse Geocoding)
@router.get("/reverse", response_model=MapReverseResponse, summary="Tra cứu địa chỉ từ toạ độ (Reverse Geocoding)")
async def reverse_geocode(
    lat: float = Query(..., ge=-90.0, le=90.0, description="Vĩ độ (Latitude, từ -90 đến 90)"),
    lon: float = Query(..., ge=-180.0, le=180.0, description="Kinh độ (Longitude, từ -180 đến 180)"),
    service: MapService = Depends(get_map_service),
) -> MapReverseResponse:
    """
    Tra cứu thông tin địa chỉ chi tiết từ toạ độ địa lý (lat, lon) sử dụng OpenStreetMap Nominatim.
    """
    # Tra cứu địa chỉ ngược từ toạ độ lat, lon
    return await service.reverse(lat=lat, lon=lon)
