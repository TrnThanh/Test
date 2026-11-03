"""Module Rule Engine phân loại và gợi ý 10 thể loại món ăn Việt Nam theo điều kiện thời tiết.

Định nghĩa ma trận chấm điểm đa chiều (Nhiệt độ, Khung giờ, Mưa/Độ ẩm, Mùa) phục vụ việc
gán nhãn cho bảng `weather_categories` và gợi ý thông minh cho người dùng.
"""

from typing import List, Optional, Tuple, Dict, Any

# --- CÁC ĐỊNH DANH DANH MỤC CHUẨN TRONG DATABASE ---
CAT_ID_PHO_BUN = 1            # Phở, Bún & Món nước (display_order: 1)
CAT_ID_COM_XOI = 2            # Cơm & Xôi (display_order: 2)
CAT_ID_BANH_MI = 3            # Bánh mì (display_order: 3)
CAT_ID_DO_AN_VAT = 4          # Đồ ăn vặt (display_order: 7)
CAT_ID_CA_PHE_GIAI_KHAT = 5   # Cà phê & Thức uống giải khát (display_order: 9)
CAT_ID_LAU_NUONG = 6          # Lẩu & Nướng (display_order: 5)
CAT_ID_BANH_TRUYEN_THONG = 7  # Bánh truyền thống & Món cuốn (display_order: 4)
CAT_ID_OC_LAI_RAI = 8         # Ốc & Quán lai rai (display_order: 6)
CAT_ID_CHE_TRANG_MIENG = 9    # Chè & Tráng miệng (display_order: 8)
CAT_ID_CHAY = 10              # Ẩm thực Chay & Thực dưỡng (display_order: 10)

ALL_CATEGORY_IDS = [
    CAT_ID_PHO_BUN,
    CAT_ID_COM_XOI,
    CAT_ID_BANH_MI,
    CAT_ID_DO_AN_VAT,
    CAT_ID_CA_PHE_GIAI_KHAT,
    CAT_ID_LAU_NUONG,
    CAT_ID_BANH_TRUYEN_THONG,
    CAT_ID_OC_LAI_RAI,
    CAT_ID_CHE_TRANG_MIENG,
    CAT_ID_CHAY,
]

CATEGORY_DISPLAY_ORDER = {
    CAT_ID_PHO_BUN: 1,
    CAT_ID_COM_XOI: 2,
    CAT_ID_BANH_MI: 3,
    CAT_ID_BANH_TRUYEN_THONG: 4,
    CAT_ID_LAU_NUONG: 5,
    CAT_ID_OC_LAI_RAI: 6,
    CAT_ID_DO_AN_VAT: 7,
    CAT_ID_CHE_TRANG_MIENG: 8,
    CAT_ID_CA_PHE_GIAI_KHAT: 9,
    CAT_ID_CHAY: 10,
}

CATEGORY_NAMES = {
    CAT_ID_PHO_BUN: "Phở, Bún & Món nước",
    CAT_ID_COM_XOI: "Cơm & Xôi",
    CAT_ID_BANH_MI: "Bánh mì",
    CAT_ID_BANH_TRUYEN_THONG: "Bánh truyền thống & Món cuốn",
    CAT_ID_LAU_NUONG: "Lẩu & Nướng",
    CAT_ID_OC_LAI_RAI: "Ốc & Quán lai rai",
    CAT_ID_DO_AN_VAT: "Đồ ăn vặt",
    CAT_ID_CHE_TRANG_MIENG: "Chè & Tráng miệng",
    CAT_ID_CA_PHE_GIAI_KHAT: "Cà phê & Thức uống giải khát",
    CAT_ID_CHAY: "Ẩm thực Chay & Thực dưỡng",
}

# --- MA TRẬN ĐIỂM THEO NHIỆT ĐỘ (TEMPERATURE MATRIX) ---
SCORE_TEMPERATURE: Dict[str, Dict[int, int]] = {
    "freezing": {  # < 12°C: Rét đậm, rét hại
        CAT_ID_LAU_NUONG: 6,
        CAT_ID_PHO_BUN: 5,
        CAT_ID_COM_XOI: 3,
        CAT_ID_OC_LAI_RAI: 2,
        CAT_ID_DO_AN_VAT: 2,
        CAT_ID_BANH_MI: 1,
        CAT_ID_BANH_TRUYEN_THONG: 0,
        CAT_ID_CHAY: 0,
        CAT_ID_CA_PHE_GIAI_KHAT: -2,
        CAT_ID_CHE_TRANG_MIENG: -5,
    },
    "cold": {  # 12°C <= t < 19°C: Trời lạnh
        CAT_ID_LAU_NUONG: 4,
        CAT_ID_PHO_BUN: 4,
        CAT_ID_COM_XOI: 3,
        CAT_ID_OC_LAI_RAI: 2,
        CAT_ID_DO_AN_VAT: 2,
        CAT_ID_BANH_MI: 2,
        CAT_ID_BANH_TRUYEN_THONG: 1,
        CAT_ID_CHAY: 1,
        CAT_ID_CA_PHE_GIAI_KHAT: -1,
        CAT_ID_CHE_TRANG_MIENG: -3,
    },
    "cool": {  # 19°C <= t < 26°C: Mát mẻ, dễ chịu
        CAT_ID_PHO_BUN: 3,
        CAT_ID_COM_XOI: 3,
        CAT_ID_BANH_MI: 3,
        CAT_ID_BANH_TRUYEN_THONG: 3,
        CAT_ID_OC_LAI_RAI: 2,
        CAT_ID_DO_AN_VAT: 2,
        CAT_ID_LAU_NUONG: 2,
        CAT_ID_CA_PHE_GIAI_KHAT: 2,
        CAT_ID_CHAY: 2,
        CAT_ID_CHE_TRANG_MIENG: 1,
    },
    "warm": {  # 26°C <= t < 32°C: Ấm áp / Hơi oi
        CAT_ID_CA_PHE_GIAI_KHAT: 3,
        CAT_ID_CHE_TRANG_MIENG: 3,
        CAT_ID_BANH_TRUYEN_THONG: 3,
        CAT_ID_COM_XOI: 2,
        CAT_ID_BANH_MI: 2,
        CAT_ID_CHAY: 2,
        CAT_ID_PHO_BUN: 1,
        CAT_ID_DO_AN_VAT: 1,
        CAT_ID_OC_LAI_RAI: 1,
        CAT_ID_LAU_NUONG: -3,
    },
    "hot": {  # >= 32°C: Nắng nóng gắt
        CAT_ID_CA_PHE_GIAI_KHAT: 5,
        CAT_ID_CHE_TRANG_MIENG: 5,
        CAT_ID_BANH_TRUYEN_THONG: 3,
        CAT_ID_CHAY: 3,
        CAT_ID_COM_XOI: 1,
        CAT_ID_BANH_MI: 1,
        CAT_ID_PHO_BUN: 0,
        CAT_ID_DO_AN_VAT: 0,
        CAT_ID_OC_LAI_RAI: 0,
        CAT_ID_LAU_NUONG: -6,
    },
}

# --- MA TRẬN ĐIỂM THEO KHUNG GIỜ ĂN UỐNG (HOUR SLOT MATRIX) ---
SCORE_HOUR: Dict[str, Dict[int, int]] = {
    "early_morning": {  # 5h - 6h: Sáng sớm
        CAT_ID_PHO_BUN: 4,
        CAT_ID_BANH_MI: 4,
        CAT_ID_COM_XOI: 3,
        CAT_ID_CA_PHE_GIAI_KHAT: 3,
        CAT_ID_BANH_TRUYEN_THONG: 1,
        CAT_ID_CHAY: 0,
        CAT_ID_CHE_TRANG_MIENG: -4,
        CAT_ID_DO_AN_VAT: -4,
        CAT_ID_OC_LAI_RAI: -6,
        CAT_ID_LAU_NUONG: -6,
    },
    "morning": {  # 7h - 9h: Bữa sáng chính
        CAT_ID_PHO_BUN: 5,
        CAT_ID_BANH_MI: 5,
        CAT_ID_COM_XOI: 4,
        CAT_ID_CA_PHE_GIAI_KHAT: 4,
        CAT_ID_BANH_TRUYEN_THONG: 2,
        CAT_ID_CHAY: 1,
        CAT_ID_CHE_TRANG_MIENG: -4,
        CAT_ID_DO_AN_VAT: -4,
        CAT_ID_OC_LAI_RAI: -6,
        CAT_ID_LAU_NUONG: -6,
    },
    "late_morning": {  # 10h: Chuyển tiếp trưa
        CAT_ID_BANH_MI: 3,
        CAT_ID_PHO_BUN: 3,
        CAT_ID_CA_PHE_GIAI_KHAT: 3,
        CAT_ID_COM_XOI: 2,
        CAT_ID_BANH_TRUYEN_THONG: 2,
        CAT_ID_CHAY: 2,
        CAT_ID_CHE_TRANG_MIENG: -2,
        CAT_ID_DO_AN_VAT: -1,
        CAT_ID_OC_LAI_RAI: -4,
        CAT_ID_LAU_NUONG: -4,
    },
    "lunch": {  # 11h - 13h: Bữa trưa chính
        CAT_ID_COM_XOI: 5,
        CAT_ID_CHAY: 4,
        CAT_ID_PHO_BUN: 3,
        CAT_ID_BANH_TRUYEN_THONG: 3,
        CAT_ID_BANH_MI: 2,
        CAT_ID_CA_PHE_GIAI_KHAT: 2,
        CAT_ID_CHE_TRANG_MIENG: 0,
        CAT_ID_DO_AN_VAT: -1,
        CAT_ID_LAU_NUONG: -2,
        CAT_ID_OC_LAI_RAI: -3,
    },
    "afternoon": {  # 14h - 17h: Bữa xế chiều, trà bánh
        CAT_ID_DO_AN_VAT: 5,
        CAT_ID_CHE_TRANG_MIENG: 5,
        CAT_ID_CA_PHE_GIAI_KHAT: 4,
        CAT_ID_BANH_TRUYEN_THONG: 3,
        CAT_ID_BANH_MI: 2,
        CAT_ID_PHO_BUN: -2,
        CAT_ID_CHAY: -2,
        CAT_ID_OC_LAI_RAI: -2,
        CAT_ID_COM_XOI: -4,
        CAT_ID_LAU_NUONG: -5,
    },
    "dinner": {  # 18h - 21h: Bữa tối chính, tụ tập
        CAT_ID_LAU_NUONG: 5,
        CAT_ID_OC_LAI_RAI: 5,
        CAT_ID_COM_XOI: 4,
        CAT_ID_BANH_TRUYEN_THONG: 3,
        CAT_ID_PHO_BUN: 2,
        CAT_ID_CHAY: 2,
        CAT_ID_DO_AN_VAT: 1,
        CAT_ID_CA_PHE_GIAI_KHAT: 1,
        CAT_ID_CHE_TRANG_MIENG: 1,
        CAT_ID_BANH_MI: 0,
    },
    "night": {  # 22h - 4h: Ăn khuya, nhậu đêm
        CAT_ID_OC_LAI_RAI: 5,
        CAT_ID_PHO_BUN: 4,
        CAT_ID_DO_AN_VAT: 4,
        CAT_ID_BANH_MI: 3,
        CAT_ID_LAU_NUONG: 2,
        CAT_ID_CA_PHE_GIAI_KHAT: -2,
        CAT_ID_COM_XOI: -3,
        CAT_ID_CHAY: -3,
        CAT_ID_CHE_TRANG_MIENG: -3,
        CAT_ID_BANH_TRUYEN_THONG: 0,
    },
}

# --- MA TRẬN ĐIỂM THEO MƯA / ĐỘ ẨM ---
SCORE_RAIN = {
    CAT_ID_LAU_NUONG: 3,
    CAT_ID_PHO_BUN: 3,
    CAT_ID_OC_LAI_RAI: 2,
    CAT_ID_DO_AN_VAT: 2,
    CAT_ID_COM_XOI: 1,
    CAT_ID_BANH_TRUYEN_THONG: -1,
    CAT_ID_BANH_MI: -1,
    CAT_ID_CA_PHE_GIAI_KHAT: -2,
    CAT_ID_CHE_TRANG_MIENG: -2,
}

# --- MA TRẬN ĐIỂM THEO MÙA ---
SCORE_SEASON: Dict[str, Dict[int, int]] = {
    "winter": {
        CAT_ID_LAU_NUONG: 1,
        CAT_ID_PHO_BUN: 1,
    },
    "summer": {
        CAT_ID_CA_PHE_GIAI_KHAT: 1,
        CAT_ID_CHE_TRANG_MIENG: 1,
        CAT_ID_BANH_TRUYEN_THONG: 1,
    },
    "autumn": {
        CAT_ID_CA_PHE_GIAI_KHAT: 1,
        CAT_ID_PHO_BUN: 1,
        CAT_ID_BANH_MI: 1,
    },
    "spring": {
        CAT_ID_COM_XOI: 1,
        CAT_ID_CHAY: 1,
    },
}


def get_temperature_bucket(temperature: Optional[float]) -> str:
    """Xác định nhóm nhiệt độ."""
    if temperature is None:
        return "cool"
    if temperature < 12.0:
        return "freezing"
    if temperature < 19.0:
        return "cold"
    if temperature < 26.0:
        return "cool"
    if temperature < 32.0:
        return "warm"
    return "hot"


def get_hour_slot(hour: Optional[int]) -> str:
    """Xác định khung giờ ăn uống theo tập quán sinh hoạt Việt Nam."""
    if hour is None:
        return "lunch"
    h = int(hour) % 24
    if 5 <= h <= 6:
        return "early_morning"
    if 7 <= h <= 9:
        return "morning"
    if h == 10:
        return "late_morning"
    if 11 <= h <= 13:
        return "lunch"
    if 14 <= h <= 17:
        return "afternoon"
    if 18 <= h <= 21:
        return "dinner"
    return "night"


def is_rainy_condition(precipitation: Optional[float], condition: Optional[str]) -> bool:
    """Kiểm tra điều kiện thời tiết có mưa hay ẩm ướt đáng kể."""
    if precipitation is not None and precipitation > 1.5:
        return True
    if condition:
        cond_lower = condition.lower()
        if any(w in cond_lower for w in ["rain", "drizzle", "storm", "mưa", "shower", "thunder"]):
            return True
    return False


def get_weather_category_cache_key(
    temperature: Optional[float],
    hour: Optional[int],
    precipitation: Optional[float] = 0.0,
    condition: Optional[str] = None,
    season: Optional[str] = None,
) -> Tuple[str, str, bool, str, str]:
    """Tạo cache key tối ưu hóa cho memoization grouping."""
    t_bucket = get_temperature_bucket(temperature)
    h_slot = get_hour_slot(hour)
    is_rain = is_rainy_condition(precipitation, condition)

    cond_key = "normal"
    if condition:
        cond_lower = condition.lower()
        if "fog" in cond_lower or "sương" in cond_lower:
            cond_key = "fog"
        elif "cloud" in cond_lower or "u ám" in cond_lower:
            cond_key = "cloudy"

    s_key = (season or "unknown").lower().strip()
    return (t_bucket, h_slot, is_rain, cond_key, s_key)


def classify_food_categories(
    temperature: Optional[float],
    hour: Optional[int],
    precipitation: Optional[float] = 0.0,
    condition: Optional[str] = None,
    season: Optional[str] = None,
) -> List[int]:
    """Tính toán và trả về danh sách 2–4 ID thể loại món ăn phù hợp nhất với điều kiện thời tiết."""
    scores: Dict[int, int] = {cid: 0 for cid in ALL_CATEGORY_IDS}

    # 1. Điểm theo Nhiệt độ
    t_bucket = get_temperature_bucket(temperature)
    for cid, pts in SCORE_TEMPERATURE.get(t_bucket, {}).items():
        scores[cid] += pts

    # 2. Điểm theo Khung giờ
    h_slot = get_hour_slot(hour)
    for cid, pts in SCORE_HOUR.get(h_slot, {}).items():
        scores[cid] += pts

    # 3. Điểm theo Mưa
    if is_rainy_condition(precipitation, condition):
        for cid, pts in SCORE_RAIN.items():
            scores[cid] += pts

    # 4. Điểm theo sương mù / u ám
    if condition:
        cond_lower = condition.lower()
        if "fog" in cond_lower or "sương" in cond_lower:
            scores[CAT_ID_PHO_BUN] += 1
            scores[CAT_ID_LAU_NUONG] += 1
            scores[CAT_ID_CA_PHE_GIAI_KHAT] += 1

    # 5. Điểm theo Mùa
    if season:
        s_norm = season.lower().strip()
        for cid, pts in SCORE_SEASON.get(s_norm, {}).items():
            scores[cid] += pts

    # Sắp xếp các categories theo:
    # 1. Điểm giảm dần (-scores[cid])
    # 2. Thứ tự hiển thị ưu tiên chuẩn trong UI (CATEGORY_DISPLAY_ORDER[cid])
    ranked = sorted(
        ALL_CATEGORY_IDS,
        key=lambda cid: (-scores[cid], CATEGORY_DISPLAY_ORDER.get(cid, 99)),
    )

    # Chọn số lượng danh mục (2–4 danh mục)
    # Mặc định chọn 3
    top_0_score = scores[ranked[0]]
    top_2_score = scores[ranked[2]]
    top_3_score = scores[ranked[3]] if len(ranked) > 3 else -999

    # Nếu 2 món đầu tiên quá vượt trội so với món thứ 3 (chênh >= 5 điểm)
    if top_0_score - top_2_score >= 5 and (scores[ranked[1]] - top_2_score >= 3):
        n = 2
    # Nếu món thứ 4 có điểm rất sát với món thứ 3 (chênh <= 1 điểm) và không quá âm
    elif top_3_score >= top_2_score - 1 and top_3_score > 0:
        n = 4
    else:
        n = 3

    return ranked[:n]
