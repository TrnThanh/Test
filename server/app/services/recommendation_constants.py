"""Hằng số cấu hình khung giờ ăn, nhóm dị ứng và thông báo cho thuật toán gợi ý món ăn (CARS)."""

# 1. HẰNG SỐ NGUỒN SỰ THẬT DUY NHẤT CHO BỮA ĂN
# (key, match_code, name, time_range_str, start_min, end_min, ratio, fallback_cal)
MEAL_PERIOD_CONFIG = [
    ("breakfast",   "breakfast", "Bữa sáng",        "06:00 - 10:00",  6 * 60,       10 * 60,     0.25, 450),
    ("lunch",       "lunch",     "Bữa trưa",        "10:00 - 14:00", 10 * 60,       14 * 60,     0.35, 650),
    ("snack",       "snack",     "Bữa xế",          "14:00 - 17:00", 14 * 60,       17 * 60,     0.10, 250),
    ("dinner",      "dinner",    "Bữa tối",         "17:00 - 21:30", 17 * 60,       21 * 60 + 30,0.30, 600),
    ("late_dinner", "dinner",    "Bữa tối muộn",    "21:30 - 23:00", 21 * 60 + 30,  23 * 60,     0.25, 500),
    ("late_night",  "snack",     "Bữa đêm",         "23:00 - 06:00", 23 * 60,       6 * 60,      0.10, 250),
]

VALID_ALLERGENS = {
    "Hải sản", "Động vật có vỏ", "Tôm", "Cua đồng", "Mực", "Cá", "Ốc",
    "Nước mắm", "Mắm tôm", "Sữa", "Bơ (sữa)", "Phô mai", "Gluten", "Trứng"
}

ALLERGEN_GROUPS = {
    "Hải sản": ["Tôm", "Cua đồng", "Mực", "Cá", "Ốc", "Nước mắm", "Mắm tôm"],
    "Động vật có vỏ": ["Tôm", "Cua đồng", "Ốc", "Mực", "Mắm tôm"],
    "Sữa": ["Sữa", "Bơ (sữa)", "Phô mai"],
}

NAME_ALLERGEN_REGEX = {
    "Tôm": r"\btôm\b",
    "Cua đồng": r"\b(cua|riêu)\b",
    "Mực": r"\bmực\b",
    "Ốc": r"\bốc\b",
    "Cá": r"\bcá\b",
    "Mắm tôm": r"\bmắm tôm\b",
    "Nước mắm": r"\bnước mắm\b",
    "Sữa": r"\b(sữa|trà sữa)\b",
    "Phô mai": r"\bphô mai\b",
    "Bơ (sữa)": r"\bbơ\b",
    "Trứng": r"\btrứng\b",
}

DISCLAIMER_TEXT = (
    "Thông tin dị ứng và thành phần dinh dưỡng được tổng hợp tự động và chỉ mang tính chất tham khảo. "
    "Vui lòng xác nhận trực tiếp với nhà hàng trước khi sử dụng nếu bạn có tiền sử dị ứng nghiêm trọng."
)
