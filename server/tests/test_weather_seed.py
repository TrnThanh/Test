"""
Kiểm thử tự động cho cơ chế nạp & ghi đè 96,000 mẫu thời tiết phẳng (bỏ cột date, chỉ giữ hour) vào bảng weather:
1. Tự động nạp đủ 96,000 mẫu thời tiết theo 4 mùa giai đoạn 2000-2025 (24,000 mẫu/mùa).
2. Tính Idempotent: chạy lại nhiều lần không sinh duplicate và thoát nhanh.
3. BẢO VỆ TUYỆT ĐỐI dữ liệu bảng users và option_users.
4. Bảo toàn các liên kết weather_categories hiện có.
5. Đồng bộ sequence ID: tạo mới weather không lỗi PK (> 96,000).
6. Kiểm tra loại bỏ 100% cột 'date', giữ chuẩn trường 'hour' [0..23], 'pattern_code', 'precipitation', 'weather_code'.
"""

from pathlib import Path
from unittest.mock import patch
from sqlalchemy.orm import Session
from sqlalchemy import func, select, text

from server.app.models.weather import Weather
from server.app.models.weather_category import WeatherCategory
from server.app.models.category import Category
from server.app.models.user import User
from server.app.models.option_user import OptionUser
from server.app.models.seed_meta import SeedMeta
from server.app.services.weather_service import WeatherService


def test_seed_weather_patterns_success(db_session: Session):
    """Kiểm thử nạp thành công 96,000 mẫu thời tiết từ tệp JSON chuẩn hóa (không có cột date)."""
    # Đảm bảo đã có dữ liệu seed từ setup_test_db
    pattern_count = db_session.query(func.count(Weather.id)).filter(
        Weather.code.like("%_PATTERN_%")
    ).scalar() or 0
    if pattern_count < 96000:
        WeatherService.seed_weather_patterns(db_session, force=False)
        pattern_count = db_session.query(func.count(Weather.id)).filter(
            Weather.code.like("%_PATTERN_%")
        ).scalar()

    assert pattern_count == 96000, f"Kỳ vọng 96000 mẫu nhưng nhận được {pattern_count}"

    # Kiểm tra đủ 4 mùa, mỗi mùa 24,000 mẫu
    for season in ["spring", "summer", "autumn", "winter"]:
        season_count = db_session.query(func.count(Weather.id)).filter(
            Weather.season == season,
            Weather.code.like("%_PATTERN_%")
        ).scalar()
        assert season_count == 24000, f"Mùa {season} phải có 24000 mẫu, thực tế có {season_count}"

    # Kiểm tra mẫu đại diện đầu tiên và cuối cùng
    p1 = db_session.query(Weather).filter(Weather.code == "SPRING_PATTERN_0001_H00").first()
    assert p1 is not None
    assert p1.pattern_code == "SPRING_PATTERN_0001"
    assert p1.hour == 0
    assert p1.season == "spring"
    assert p1.temperature == 7.4
    assert p1.humidity == 90.0
    assert p1.precipitation == 0.0
    assert p1.weather_code == 0
    assert p1.icon == "sunny.svg"
    # Đảm bảo không có trường date
    assert not hasattr(p1, "date") or getattr(p1, "date", None) is None

    p96000 = db_session.query(Weather).filter(Weather.code == "WINTER_PATTERN_1000_H23").first()
    assert p96000 is not None
    assert p96000.pattern_code == "WINTER_PATTERN_1000"
    assert p96000.hour == 23
    assert p96000.season == "winter"
    assert p96000.temperature == 15.2
    assert p96000.humidity == 90.0
    assert p96000.precipitation == 1.8
    assert p96000.weather_code == 61


def test_weather_seed_idempotency_and_overwrite(db_session: Session):
    """Kiểm thử tính idempotent: lần chạy với force=False đã có đủ 96,000 bản ghi thì thoát nhanh trả về 0."""
    result_run = WeatherService.seed_weather_patterns(db_session, force=False)
    assert result_run == 0

    count_after = db_session.query(func.count(Weather.id)).filter(
        Weather.code.like("%_PATTERN_%")
    ).scalar()
    assert count_after == 96000


def test_preserve_user_and_option_user_data(db_session: Session):
    """Kiểm thử bảo toàn 100% dữ liệu User và OptionUser khi nạp weather."""
    test_email = "weather_test_preserve@ptc1.vn"
    user = db_session.query(User).filter(User.email == test_email).first()
    if not user:
        user = User(
            email=test_email,
            hashed_password="hashed_pw_test",
            full_name="User Test Weather Preserve",
            height_cm=175.0,
            weight_kg=70.0,
            target_goal="gain_muscle",
            allergies=["Peanut"],
        )
        db_session.add(user)
        db_session.commit()
        db_session.refresh(user)

    cat = db_session.query(Category).first()
    if not cat:
        cat = Category(name="Danh mục Test", sort_order=1, is_active=True)
        db_session.add(cat)
        db_session.commit()
        db_session.refresh(cat)

    opt = db_session.query(OptionUser).filter(
        OptionUser.user_id == user.id,
        OptionUser.category_id == cat.id
    ).first()
    if not opt:
        opt = OptionUser(user_id=user.id, category_id=cat.id, hide=True)
        db_session.add(opt)
        db_session.commit()

    # Chạy lại seed với force=False
    WeatherService.seed_weather_patterns(db_session, force=False)

    user_after = db_session.query(User).filter(User.email == test_email).first()
    assert user_after is not None, "Dữ liệu User không được biến mất"
    assert user_after.full_name == "User Test Weather Preserve"

    opt_after = db_session.query(OptionUser).filter(
        OptionUser.user_id == user.id,
        OptionUser.category_id == cat.id
    ).first()
    assert opt_after is not None, "Dữ liệu OptionUser phải được bảo toàn"
    assert opt_after.hide is True


def test_legacy_weather_purged_and_only_flat_patterns_kept(db_session: Session):
    """Kiểm thử tự động dọn sạch các mã cũ (hot, rainy, cold, mild)."""
    # Đảm bảo không còn bản ghi cũ nào trong hệ thống
    legacy_count = db_session.query(Weather).filter(
        Weather.code.in_(["hot", "rainy", "cold", "mild"])
    ).count()
    assert legacy_count == 0, "Toàn bộ mã weather cũ (hot, rainy, cold, mild) phải được dọn sạch"


def test_preserve_weather_category_links(db_session: Session):
    """Kiểm thử bảo toàn liên kết WeatherCategory khi chạy seed."""
    cat = db_session.query(Category).first()
    if not cat:
        cat = Category(name="Danh mục Test Link", sort_order=1, is_active=True)
        db_session.add(cat)
        db_session.commit()
        db_session.refresh(cat)

    w = db_session.query(Weather).filter(Weather.code == "SPRING_PATTERN_0001_H00").first()
    assert w is not None

    link = db_session.query(WeatherCategory).filter(
        WeatherCategory.weather_id == w.id,
        WeatherCategory.category_id == cat.id
    ).first()
    if not link:
        link = WeatherCategory(weather_id=w.id, category_id=cat.id)
        db_session.add(link)
        db_session.commit()

    # Chạy lại seed với force=False
    WeatherService.seed_weather_patterns(db_session, force=False)

    # Kiểm tra liên kết vẫn còn nguyên
    link_after = db_session.query(WeatherCategory).filter(
        WeatherCategory.weather_id == w.id,
        WeatherCategory.category_id == cat.id
    ).first()
    assert link_after is not None, "Liên kết WeatherCategory phải được bảo toàn nguyên vẹn sau seed"


def test_sequence_synced_after_seed(db_session: Session):
    """Kiểm thử sequence ID PostgreSQL được đồng bộ chính xác (> 96000)."""
    new_custom_weather = Weather(
        code="CUSTOM_WEATHER_TEST_SEQ",
        name="Thời tiết tùy chỉnh sau seed",
        pattern_code="CUSTOM_TEST",
        hour=12,
        temperature=22.5,
        humidity=70.0,
    )
    db_session.add(new_custom_weather)
    db_session.commit()
    db_session.refresh(new_custom_weather)

    assert new_custom_weather.id is not None
    assert new_custom_weather.id > 96000

    # Dọn dẹp bản ghi kiểm thử
    db_session.delete(new_custom_weather)
    db_session.commit()


def test_no_date_column_in_database(db_session: Session):
    """Kiểm thử khẳng định TUYỆT ĐỐI không có cột 'date' trong bảng weather."""
    cols = db_session.execute(
        text("SELECT column_name FROM information_schema.columns WHERE table_name='weather'")
    ).scalars().all()
    assert "date" not in cols, "Cột 'date' không được phép có mặt trong bảng weather!"
    assert "hour" in cols, "Cột 'hour' phải có mặt trong bảng weather!"
    assert "pattern_code" in cols, "Cột 'pattern_code' phải có mặt trong bảng weather!"
    assert "precipitation" in cols, "Cột 'precipitation' phải có mặt trong bảng weather!"
    assert "weather_code" in cols, "Cột 'weather_code' phải có mặt trong bảng weather!"
