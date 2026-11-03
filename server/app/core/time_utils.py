# -*- coding: utf-8 -*-
"""
Tiện ích xử lý và định dạng thời gian cho hệ thống PTC1.
"""
from typing import Optional


def format_hour_12h(hour: Optional[int]) -> Optional[str]:
    """
    Chuyển đổi số giờ (0..23) sang định dạng 12-hour AM/PM trực quan.
    Ví dụ:
        0  -> "12:00 AM"
        7  -> "7:00 AM"
        12 -> "12:00 PM"
        13 -> "1:00 PM"
        23 -> "11:00 PM"
    """
    if hour is None:
        return None
    if not (0 <= hour <= 23):
        raise ValueError(f"Khung giờ hour không hợp lệ (phải từ 0 đến 23): {hour}")
    
    suffix = "AM" if hour < 12 else "PM"
    h12 = hour % 12
    if h12 == 0:
        h12 = 12
    return f"{h12}:00 {suffix}"
