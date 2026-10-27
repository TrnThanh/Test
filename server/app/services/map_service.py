import logging
import time
from typing import Any, Dict, List, Optional

import httpx
from fastapi import HTTPException, Request, status

from server.app.core.config import settings
from server.app.schemas.map import (
    MapSearchResponse,
    MapReverseResponse,
    PlaceItem,
    IpLocationResponse,
)
from server.app.schemas.restaurant import RestaurantRouteResponse
from server.app.utils.cache import FIFOTtlCache
from server.app.utils.geo import haversine_distance
from server.app.utils.network import fallback_ip_location, get_client_ip, is_public_ip

logger = logging.getLogger(__name__)

_NOMINATIM_FAILS_UNTIL: float = 0.0
_IP_LOCATION_CACHE: Dict[str, tuple[float, IpLocationResponse]] = {}
_IP_CACHE_TTL = 3600.0  # 1 giờ


class MapService:
    def __init__(
        self,
        base_url: Optional[str] = None,
        user_agent: Optional[str] = None,
        timeout: Optional[float] = None,
        client: Optional[httpx.AsyncClient] = None,
        foot_router_url: Optional[str] = None,
    ):
        self.base_url = (base_url or settings.NOMINATIM_BASE_URL).rstrip("/")
        self.user_agent = user_agent or settings.NOMINATIM_USER_AGENT
        self.timeout = timeout if timeout is not None else settings.NOMINATIM_TIMEOUT_SECONDS
        self._client = client
        self._route_client: Optional[httpx.AsyncClient] = None
        self.foot_router_url = (foot_router_url or "https://routing.openstreetmap.de/routed-foot/route/v1/driving").rstrip("/")
        self.route_cache = FIFOTtlCache(maxsize=1000, ttl_seconds=300.0)

    def set_client(self, client: Optional[httpx.AsyncClient]) -> None:
        """Cập nhật httpx client dùng chung (từ FastAPI lifespan hoặc fixture test)."""
        self._client = client

    def set_route_client(self, client: Optional[httpx.AsyncClient]) -> None:
        """Cập nhật httpx client dùng riêng cho dịch vụ tìm đường đi bộ."""
        self._route_client = client

    def _get_headers(self) -> Dict[str, str]:
        return {
            "User-Agent": self.user_agent,
            "Accept": "application/json",
        }

    async def _send_request(self, endpoint: str, params: Dict[str, Any]) -> Any:
        global _NOMINATIM_FAILS_UNTIL
        # Circuit breaker: Nếu Nominatim đang gián đoạn, bỏ qua chờ đợi vô ích để phản hồi ngay lập tức
        if self._client is None and time.time() < _NOMINATIM_FAILS_UNTIL:
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail="OpenStreetMap tạm thời không phản hồi (Circuit breaker).",
            )

        url = f"{self.base_url}/{endpoint.lstrip('/')}"
        headers = self._get_headers()

        async def _execute(c: httpx.AsyncClient) -> httpx.Response:
            return await c.get(url, params=params, headers=headers)

        req_timeout = self.timeout if self._client is not None else min(self.timeout, 2.0)

        try:
            if self._client is not None:
                response = await _execute(self._client)
            else:
                async with httpx.AsyncClient(timeout=req_timeout) as c:
                    response = await _execute(c)

            if response.status_code == 403:
                raise HTTPException(
                    status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                    detail="Dịch vụ bản đồ OpenStreetMap tạm thời từ chối yêu cầu (403). Vui lòng thử lại sau.",
                )
            response.raise_for_status()
            return response.json()
        except httpx.TimeoutException:
            if self._client is None:
                _NOMINATIM_FAILS_UNTIL = time.time() + 300.0
            raise HTTPException(
                status_code=status.HTTP_504_GATEWAY_TIMEOUT,
                detail="Dịch vụ OpenStreetMap không phản hồi kịp thời (Timeout).",
            )
        except httpx.HTTPError as exc:
            if self._client is None:
                _NOMINATIM_FAILS_UNTIL = time.time() + 300.0
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
        try:
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
            return MapSearchResponse(query=query, count=len(results), results=results)
        except HTTPException:
            if self._client is not None:
                raise
            logger.warning("Nominatim search HTTP error for query '%s'", query)
        except Exception as exc:
            if self._client is not None:
                raise
            logger.warning("Nominatim search failed for query '%s': %s", query, exc)

        # Fallback 1: Photon Komoot Geocoder
        try:
            photon_url = "https://photon.komoot.io/api/"
            photon_params = {"q": query, "limit": limit}
            headers = {"User-Agent": "PTC1-RestaurantApp/1.0"}
            async with httpx.AsyncClient(timeout=4.0) as c:
                p_resp = await c.get(photon_url, params=photon_params, headers=headers)
                if p_resp.status_code == 200:
                    p_data = p_resp.json()
                    features = p_data.get("features", [])
                    p_results: List[PlaceItem] = []
                    for f in features:
                        coords = f.get("geometry", {}).get("coordinates", [])
                        props = f.get("properties", {})
                        if len(coords) >= 2:
                            name_parts = [props.get("name"), props.get("district"), props.get("city"), props.get("country")]
                            disp = ", ".join([str(p) for p in name_parts if p]) or query
                            p_results.append(
                                PlaceItem(
                                    display_name=disp,
                                    lat=float(coords[1]),
                                    lon=float(coords[0]),
                                    type=props.get("type"),
                                )
                            )
                    if p_results:
                        return MapSearchResponse(query=query, count=len(p_results), results=p_results)
        except Exception as exc:
            logger.warning("Photon search fallback failed: %s", exc)

        return MapSearchResponse(
            query=query,
            count=0,
            results=[],
        )

    async def reverse(self, lat: float, lon: float) -> MapReverseResponse:
        params = {
            "lat": lat,
            "lon": lon,
            "format": "jsonv2",
            "addressdetails": 1,
        }
        try:
            data = await self._send_request("reverse", params)
            if isinstance(data, dict) and "error" not in data:
                return MapReverseResponse(
                    place_id=data.get("place_id"),
                    osm_id=data.get("osm_id"),
                    osm_type=data.get("osm_type"),
                    lat=float(data.get("lat", lat)),
                    lon=float(data.get("lon", lon)),
                    display_name=data.get("display_name", ""),
                    address=data.get("address", {}),
                )
            if self._client is not None:
                error_msg = data.get("error", "Không tìm thấy thông tin địa chỉ tại toạ độ này") if isinstance(data, dict) else "Không tìm thấy thông tin địa chỉ tại toạ độ này"
                raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=error_msg)
        except HTTPException:
            if self._client is not None:
                raise
            logger.warning("Nominatim reverse HTTP error for lat=%s, lon=%s", lat, lon)
        except Exception as exc:
            if self._client is not None:
                raise
            logger.warning("Nominatim reverse failed for lat=%s, lon=%s: %s", lat, lon, exc)

        # Fallback 1: BigDataCloud Reverse Geocoding API
        try:
            bg_url = "https://api.bigdatacloud.net/data/reverse-geocode-client"
            bg_params = {"latitude": lat, "longitude": lon, "localityLanguage": "vi"}
            async with httpx.AsyncClient(timeout=4.0) as c:
                bg_resp = await c.get(bg_url, params=bg_params, follow_redirects=True)
                if bg_resp.status_code == 200:
                    bg_data = bg_resp.json()
                    locality = bg_data.get("locality") or bg_data.get("city")
                    subdivision = bg_data.get("principalSubdivision")
                    country = bg_data.get("countryName") or "Việt Nam"
                    parts = [str(p) for p in (locality, subdivision, country) if p]
                    disp_name = ", ".join(parts) if parts else f"Toạ độ ({lat:.4f}, {lon:.4f})"
                    return MapReverseResponse(
                        lat=lat,
                        lon=lon,
                        display_name=disp_name,
                        address={
                            "locality": locality or "",
                            "city": subdivision or "",
                            "country": country,
                        },
                    )
        except Exception as exc:
            logger.warning("BigDataCloud reverse fallback failed: %s", exc)

        # Fallback 2: Local coordinate-based fallback (never throws 502/500)
        disp_name = f"Toạ độ ({lat:.4f}, {lon:.4f})"
        city = "Việt Nam"
        if 20.5 <= lat <= 21.6 and 105.2 <= lon <= 106.3:
            disp_name = "Hà Nội, Việt Nam"
            city = "Hà Nội"
        elif 10.3 <= lat <= 11.2 and 106.3 <= lon <= 107.2:
            disp_name = "TP. Hồ Chí Minh, Việt Nam"
            city = "TP. Hồ Chí Minh"
        elif 15.8 <= lat <= 16.3 and 108.0 <= lon <= 108.5:
            disp_name = "Đà Nẵng, Việt Nam"
            city = "Đà Nẵng"

        return MapReverseResponse(
            lat=lat,
            lon=lon,
            display_name=disp_name,
            address={"city": city, "country": "Việt Nam"},
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

    async def get_walking_route_to_restaurant(
        self,
        restaurant_id: int,
        restaurant_name: str,
        user_lat: float,
        user_lon: float,
        rest_lat: float,
        rest_lon: float,
    ) -> RestaurantRouteResponse:
        """
        Tìm tuyến đường đi bộ ngắn nhất từ vị trí người dùng đến quán ăn.
        - Kiểm tra cache in-memory FIFO TTL (key: toạ độ làm tròn 4 chữ số, restaurant_id).
        - Gọi OSRM Foot Routing Engine (routed-foot) qua HTTP GET với timeout 5s.
        - Kiểm tra nghiêm ngặt HTTP 200, code == 'Ok' và cấu trúc routes.
        - Nếu thành công: lưu vào cache và trả về.
        - Nếu lỗi / timeout / 429 / 5xx / NoRoute: fallback về đường nối 2 điểm với cự ly Haversine * 1.3 và vận tốc 1.25 m/s. TUYỆT ĐỐI KHÔNG lưu fallback vào cache.
        """
        cache_key = (round(user_lat, 4), round(user_lon, 4), restaurant_id)
        cached = self.route_cache.get(cache_key)
        if cached is not None:
            return cached

        url = f"{self.foot_router_url}/{user_lon:.6f},{user_lat:.6f};{rest_lon:.6f},{rest_lat:.6f}"
        params = {"overview": "full", "geometries": "geojson"}
        headers = {
            "User-Agent": f"{self.user_agent} - PTC1 Walking Route Service",
            "Accept": "application/json",
        }

        client = self._client or self._route_client
        try:
            if client is not None:
                resp = await client.get(url, params=params, headers=headers, timeout=5.0)
            else:
                async with httpx.AsyncClient(timeout=5.0) as c:
                    resp = await c.get(url, params=params, headers=headers)

            if resp.status_code != 200:
                raise ValueError(f"OSRM HTTP {resp.status_code}: {resp.text[:200]}")

            data = resp.json()
            if not isinstance(data, dict):
                raise ValueError("OSRM response không phải JSON object")

            code = data.get("code")
            if code != "Ok":
                raise ValueError(f"OSRM code '{code}' khác 'Ok'")

            routes = data.get("routes")
            if not isinstance(routes, list) or len(routes) == 0:
                raise ValueError("OSRM routes rỗng")

            r0 = routes[0]
            if not isinstance(r0, dict):
                raise ValueError("OSRM route item không hợp lệ")

            dist = r0.get("distance")
            dur = r0.get("duration")
            if not isinstance(dist, (int, float)) or not isinstance(dur, (int, float)):
                raise ValueError("OSRM distance/duration không phải kiểu số")

            coords = r0.get("geometry", {}).get("coordinates")
            if not isinstance(coords, list) or len(coords) < 2:
                raise ValueError("OSRM coordinates không đủ dữ liệu toạ độ")

            result = RestaurantRouteResponse(
                restaurant_id=restaurant_id,
                restaurant_name=restaurant_name,
                distance_meters=round(float(dist), 1),
                duration_seconds=round(float(dur), 1),
                coordinates=coords,
                is_fallback=False,
            )
            # CHỈ lưu vào cache khi thành công thực tế
            self.route_cache.set(cache_key, result)
            return result

        except Exception as exc:
            logger.warning(
                "OSRM foot routing fallback kích hoạt cho quán %s (%s). Lý do: %s",
                restaurant_id, restaurant_name, exc,
            )
            # Fallback Haversine thuần Python với hệ số uốn lượn 1.3 và vận tốc 1.25 m/s
            h_dist = haversine_distance(user_lat, user_lon, rest_lat, rest_lon)
            fb_dist = round(h_dist * 1.3, 1)
            fb_dur = round(fb_dist / 1.25, 1)
            fb_coords = [[user_lon, user_lat], [rest_lon, rest_lat]]

            return RestaurantRouteResponse(
                restaurant_id=restaurant_id,
                restaurant_name=restaurant_name,
                distance_meters=fb_dist,
                duration_seconds=fb_dur,
                coordinates=fb_coords,
                is_fallback=True,
            )


map_service = MapService()
