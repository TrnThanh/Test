import ipaddress
from typing import Optional
from fastapi import Request
from server.app.schemas.map import IpLocationResponse


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
        return addr.is_global and not (
            addr.is_loopback or addr.is_private or addr.is_link_local or addr.is_reserved
        )
    except ValueError:
        return False
