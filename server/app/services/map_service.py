import ipaddress
import logging
import time
from typing import Any, Dict, List, Optional
import httpx
from fastapi import HTTPException, Request, status
from server.app.core.config import settings
from server.app.schemas.map import MapSearchResponse, MapReverseResponse, PlaceItem, IpLocationResponse

logger = logging.getLogger(__name__)

_IP_LOCATION_CACHE: Dict[str, tuple[float, IpLocationResponse]] = {}
_IP_CACHE_TTL = 3600.0  # 1 giờ


def fallback_ip_location(ip: Optional[str] = None) -> IpLocationResponse:
    """Trả về toạ độ dự phòng ước lượng khi không lấy được IP hoặc mất kết nối mạng (Hà Nội, không gán cứng HVNN)."""
    return IpLocationResponse(
        lat=21.0285,
        lon=105.8542,
        city="Hà Nội",
        region="Hà Nội",
        country="Vietnam",
        location_name="Hà Nội, Việt Nam (Vị trí ước lượng)",
        is_fallback=True,
        ip=ip,
    )


def get_client_ip(request: Request) -> str:
    """Trích xuất địa chỉ IP thực của client từ request hoặc các header proxy."""
    xff = request.headers.get("x-forwarded-for")
    if xff:
        return xff.split(",")[0].strip()
    x_real_ip = request.headers.get("x-real-ip")
    if x_real_ip:
        return x_real_ip.strip()
    return request.client.host if request.client else ""


def is_public_ip(ip: str) -> bool:
    """Kiểm tra địa chỉ IP có phải là IP public Internet hay không (loại trừ loopback, private, link-local)."""
    try:
        addr = ipaddress.ip_address(ip)
        return addr.is_global and not (addr.is_loopback or addr.is_private or addr.is_link_local or addr.is_reserved)
    except ValueError:
        return False


class MapService:
    def __init__(
        self,
        base_url: Optional[str] = None,
        user_agent: Optional[str] = None,
        timeout: Optional[float] = None,
        client: Optional[httpx.AsyncClient] = None,
    ):
        self.base_url = (base_url or settings.NOMINATIM_BASE_URL).rstrip("/")
        self.user_agent = user_agent or settings.NOMINATIM_USER_AGENT
        self.timeout = timeout if timeout is not None else settings.NOMINATIM_TIMEOUT_SECONDS
        self._client = client

    def _get_headers(self) -> Dict[str, str]:
        return {
            "User-Agent": self.user_agent,
            "Accept": "application/json",
        }

    async def _send_request(self, endpoint: str, params: Dict[str, Any]) -> Any:
        url = f"{self.base_url}/{endpoint.lstrip('/')}"
        headers = self._get_headers()

        async def _execute(c: httpx.AsyncClient) -> httpx.Response:
            return await c.get(url, params=params, headers=headers)

        try:
            if self._client is not None:
                response = await _execute(self._client)
            else:
                async with httpx.AsyncClient(timeout=self.timeout) as c:
                    response = await _execute(c)

            if response.status_code == 403:
                raise HTTPException(
                    status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                    detail="Dịch vụ bản đồ OpenStreetMap tạm thời từ chối yêu cầu (403). Vui lòng thử lại sau.",
                )
            response.raise_for_status()
            return response.json()
        except httpx.TimeoutException:
            raise HTTPException(
                status_code=status.HTTP_504_GATEWAY_TIMEOUT,
                detail="Dịch vụ OpenStreetMap không phản hồi kịp thời (Timeout).",
            )
        except httpx.HTTPError as exc:
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail=f"Lỗi khi kết nối với máy chủ OpenStreetMap: {str(exc)}",
            )

    async def search(self, query: str, limit: int = 10) -> MapSearchResponse:
        params = {
            "q": query,
            "format": "jsonv2",
            "limit": limit,
            "addressdetails": 1,
        }
        data = await self._send_request("search", params)

        results: List[PlaceItem] = []
        if isinstance(data, list):
            for item in data:
                try:
                    results.append(
                        PlaceItem(
                            place_id=item.get("place_id"),
                            osm_id=item.get("osm_id"),
                            osm_type=item.get("osm_type"),
                            display_name=item.get("display_name", ""),
                            lat=float(item.get("lat", 0.0)),
                            lon=float(item.get("lon", 0.0)),
                            category=item.get("category"),
                            type=item.get("type"),
                            importance=item.get("importance"),
                            boundingbox=item.get("boundingbox"),
                        )
                    )
                except (ValueError, TypeError):
                    continue

        return MapSearchResponse(
            query=query,
            count=len(results),
            results=results,
        )

    async def reverse(self, lat: float, lon: float) -> MapReverseResponse:
        params = {
            "lat": lat,
            "lon": lon,
            "format": "jsonv2",
            "addressdetails": 1,
        }
        data = await self._send_request("reverse", params)

        if not isinstance(data, dict) or "error" in data:
            error_msg = (
                data.get("error", "Không tìm thấy thông tin địa chỉ tại toạ độ này")
                if isinstance(data, dict)
                else "Không tìm thấy thông tin địa chỉ tại toạ độ này"
            )
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=error_msg,
            )

        return MapReverseResponse(
            place_id=data.get("place_id"),
            osm_id=data.get("osm_id"),
            osm_type=data.get("osm_type"),
            lat=float(data.get("lat", lat)),
            lon=float(data.get("lon", lon)),
            display_name=data.get("display_name", ""),
            address=data.get("address", {}),
        )

    async def get_ip_location(
        self,
        request: Request,
        client: Optional[httpx.AsyncClient] = None,
    ) -> IpLocationResponse:
        """
        Định vị toạ độ người dùng trực tuyến theo địa chỉ IP qua mạng Internet (IP Geolocation).
        - Nếu client kết nối từ loopback/private IP (127.0.0.1, localhost, mạng LAN nội bộ) -> fallback HVNN Gia Lâm.
        - Nếu client kết nối từ public IP -> truy vấn dịch vụ ip-api.com với bộ đệm in-memory cache TTL 1 giờ.
        - Khi có lỗi mạng hoặc API gián đoạn -> tự động fallback an toàn về toạ độ mặc định HVNN.
        """
        ip = get_client_ip(request)
        is_pub = is_public_ip(ip) if ip else False
        cache_key = ip if is_pub else "__host_ip__"

        now = time.time()
        hit = _IP_LOCATION_CACHE.get(cache_key)
        if hit and (now - hit[0]) < _IP_CACHE_TTL:
            return hit[1]

        url = f"http://ip-api.com/json/{ip}" if is_pub else "http://ip-api.com/json"
        params = {"fields": "status,message,country,regionName,city,lat,lon,query"}
        try:
            if client is not None:
                resp = await client.get(url, params=params, timeout=3.0)
            elif self._client is not None:
                resp = await self._client.get(url, params=params, timeout=3.0)
            else:
                async with httpx.AsyncClient(timeout=3.0) as c:
                    resp = await c.get(url, params=params)

            if resp.status_code == 200:
                data = resp.json()
                if data.get("status") == "success":
                    city = data.get("city")
                    region = data.get("regionName")
                    country = data.get("country")
                    parts = [p for p in (city, region, country) if p]
                    loc_name = ", ".join(parts) if parts else "Vị trí người dùng (theo IP)"
                    result = IpLocationResponse(
                        lat=float(data["lat"]),
                        lon=float(data["lon"]),
                        city=city,
                        region=region,
                        country=country,
                        location_name=loc_name,
                        is_fallback=False,
                        ip=data.get("query") or ip,
                    )
                    _IP_LOCATION_CACHE[cache_key] = (now, result)
                    return result
        except Exception as exc:
            logger.warning("Lỗi tra cứu IP geolocation (%s): %s", ip, exc)

        return fallback_ip_location(ip)


map_service = MapService()
