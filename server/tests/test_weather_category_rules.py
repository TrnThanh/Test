import pytest
from server.app.core.weather_food_rules import (
    classify_food_categories,
    get_weather_category_cache_key,
    get_temperature_bucket,
    get_hour_slot,
    is_rainy_condition,
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
    ALL_CATEGORY_IDS,
)


def test_temperature_buckets():
    """Kiểm tra phân nhóm dải nhiệt độ chuẩn."""
    assert get_temperature_bucket(-5.0) == "freezing"
    assert get_temperature_bucket(11.9) == "freezing"
    assert get_temperature_bucket(12.0) == "cold"
    assert get_temperature_bucket(18.9) == "cold"
    assert get_temperature_bucket(19.0) == "cool"
    assert get_temperature_bucket(25.9) == "cool"
    assert get_temperature_bucket(26.0) == "warm"
    assert get_temperature_bucket(31.9) == "warm"
    assert get_temperature_bucket(32.0) == "hot"
    assert get_temperature_bucket(42.0) == "hot"
    assert get_temperature_bucket(None) == "cool"


def test_hour_slots():
    """Kiểm tra phân loại khung giờ ăn uống theo văn hóa Việt Nam."""
    assert get_hour_slot(5) == "early_morning"
    assert get_hour_slot(6) == "early_morning"
    assert get_hour_slot(7) == "morning"
    assert get_hour_slot(9) == "morning"
    assert get_hour_slot(10) == "late_morning"
    assert get_hour_slot(11) == "lunch"
    assert get_hour_slot(13) == "lunch"
    assert get_hour_slot(14) == "afternoon"
    assert get_hour_slot(17) == "afternoon"
    assert get_hour_slot(18) == "dinner"
    assert get_hour_slot(21) == "dinner"
    assert get_hour_slot(22) == "night"
    assert get_hour_slot(23) == "night"
    assert get_hour_slot(0) == "night"
    assert get_hour_slot(4) == "night"
    assert get_hour_slot(None) == "lunch"


def test_rainy_condition():
    """Kiểm tra nhận diện điều kiện mưa và ẩm ướt."""
    assert is_rainy_condition(precipitation=2.0, condition="Clear") is True
    assert is_rainy_condition(precipitation=0.0, condition="Light Rain") is True
    assert is_rainy_condition(precipitation=0.0, condition="Mưa rào") is True
    assert is_rainy_condition(precipitation=0.0, condition="Thunderstorm") is True
    assert is_rainy_condition(precipitation=0.5, condition="Sunny") is False
    assert is_rainy_condition(precipitation=None, condition=None) is False


def test_morning_breakfast_recommendations():
    """Bữa sáng (7-9h): Ưu tiên Phở/Bún, Bánh mì, Xôi/Cơm; Tuyệt đối không gợi ý Lẩu hoặc Ốc."""
    cats = classify_food_categories(temperature=15.0, hour=8, precipitation=0.0, condition="Clear")
    assert CAT_ID_PHO_BUN in cats
    assert CAT_ID_BANH_MI in cats or CAT_ID_COM_XOI in cats
    assert CAT_ID_LAU_NUONG not in cats
    assert CAT_ID_OC_LAI_RAI not in cats


def test_lunch_recommendations():
    """Bữa trưa (11-13h): Ưu tiên Cơm & Xôi, Chay & Thực dưỡng, Phở/Bún."""
    cats = classify_food_categories(temperature=28.0, hour=12, precipitation=0.0, condition="Clear")
    assert CAT_ID_COM_XOI in cats or CAT_ID_CHAY in cats
    assert CAT_ID_LAU_NUONG not in cats


def test_afternoon_snack_recommendations():
    """Bữa xế chiều (14-17h): Ưu tiên Đồ ăn vặt, Chè & Tráng miệng, Trà/Cà phê giải khát."""
    cats = classify_food_categories(temperature=30.0, hour=16, precipitation=0.0, condition="Clear")
    assert CAT_ID_DO_AN_VAT in cats or CAT_ID_CHE_TRANG_MIENG in cats
    assert CAT_ID_CA_PHE_GIAI_KHAT in cats
    assert CAT_ID_LAU_NUONG not in cats
    assert CAT_ID_COM_XOI not in cats


def test_freezing_rainy_dinner_recommendations():
    """Tối mùa đông rét buốt mưa to: Lẩu & Nướng, Phở/Bún nước đứng đầu."""
    cats = classify_food_categories(temperature=9.0, hour=19, precipitation=8.0, condition="Rainy", season="winter")
    assert CAT_ID_LAU_NUONG in cats
    assert CAT_ID_PHO_BUN in cats
    assert CAT_ID_CHE_TRANG_MIENG not in cats


def test_sweltering_hot_summer_noon():
    """Trưa hè nắng nóng gay gắt (>35°C): Ưu tiên Thức uống giải khát, Chè, Món cuốn, Chay; Trừ điểm Lẩu."""
    cats = classify_food_categories(temperature=38.0, hour=12, precipitation=0.0, condition="Clear", season="summer")
    assert CAT_ID_CA_PHE_GIAI_KHAT in cats
    assert CAT_ID_CHE_TRANG_MIENG in cats or CAT_ID_BANH_TRUYEN_THONG in cats or CAT_ID_CHAY in cats
    assert CAT_ID_LAU_NUONG not in cats


def test_late_night_food():
    """Đêm khuya (22-4h): Ưu tiên Ốc & Quán lai rai, Phở đêm, Đồ ăn vặt nướng."""
    cats = classify_food_categories(temperature=20.0, hour=23, precipitation=0.0, condition="Clear")
    assert CAT_ID_OC_LAI_RAI in cats or CAT_ID_PHO_BUN in cats
    assert CAT_ID_COM_XOI not in cats
    assert CAT_ID_CHE_TRANG_MIENG not in cats


def test_classification_length_and_validity():
    """Mọi điều kiện thời tiết luôn trả về từ 2 đến 4 categories hợp lệ, không trùng lặp."""
    for temp in [-10.0, 5.0, 15.0, 22.0, 29.0, 37.0]:
        for hour in range(0, 24, 2):
            for rain in [0.0, 5.0]:
                for cond in ["Clear", "Rainy", "Foggy"]:
                    cats = classify_food_categories(temp, hour, rain, cond)
                    assert 2 <= len(cats) <= 4
                    assert len(cats) == len(set(cats))  # Không trùng lặp
                    for cid in cats:
                        assert cid in ALL_CATEGORY_IDS


def test_cache_key_consistency():
    """Cache key phải có tính xác định và tạo hash hợp lệ."""
    key1 = get_weather_category_cache_key(25.5, 12, 0.0, "Clear", "summer")
    key2 = get_weather_category_cache_key(25.5, 12, 0.0, "Clear", "summer")
    assert key1 == key2
    assert isinstance(key1, tuple)
