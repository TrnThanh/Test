"""
Kiểm thử tự động cho cơ chế nạp & ghi đè 4000 mẫu thời tiết (Weather Seed):
1. Tự động nạp đủ 4000 mẫu thời tiết theo 4 mùa giai đoạn 2000-2025 (1000 mẫu/mùa).
2. Tính Idempotent: chạy lại nhiều lần không sinh duplicate và thoát nhanh.
3. Ghi đè (Upsert): cập nhật dữ liệu nếu bản ghi cùng code đã tồn tại.
4. BẢO VỆ TUYỆT ĐỐI dữ liệu bảng users và option_users.
5. Bảo toàn các liên kết weather_categories hiện có.
6. Đồng bộ sequence ID: tạo mới weather không lỗi PK.
"""

from pathlib import Path
from unittest.mock import patch
from sqlalchemy.orm import Session
from sqlalchemy import func, select

from server.app.models.weather import Weather
from server.app.models.weather_category import WeatherCategory
from server.app.models.category import Category
from server.app.models.user import User
from server.app.models.option_user import OptionUser
from server.app.models.seed_meta import SeedMeta
from server.app.services.weather_service import WeatherService


def test_seed_4000_weather_patterns_success(db_session: Session):
    """Kiểm thử nạp thành công 4000 mẫu thời tiết từ tệp JSON chuẩn hóa."""
    # Xoá marker nếu có
    db_session.query(SeedMeta).filter(SeedMeta.key == "weather_4000_patterns_v1").delete()
    db_session.commit()

    upserted = WeatherService.seed_4000_weather_patterns(db_session, force=True)
    assert upserted == 4000

    # Kiểm tra tổng số mẫu thời tiết trong DB
    pattern_count = db_session.query(func.count(Weather.id)).filter(
        Weather.code.like("%_PATTERN_%")
    ).scalar()
    assert pattern_count == 4000, f"Kỳ vọng 4000 mẫu nhưng nhận được {pattern_count}"

    # Kiểm tra đủ 4 mùa, mỗi mùa 1000 mẫu
    for season in ["spring", "summer", "autumn", "winter"]:
        season_count = db_session.query(func.count(Weather.id)).filter(
            Weather.season == season,
            Weather.code.like("%_PATTERN_%")
        ).scalar()
        assert season_count == 1000, f"Mùa {season} phải có 1000 mẫu, thực tế có {season_count}"

    # Kiểm tra mẫu đại diện đầu tiên và cuối cùng
    p1 = db_session.query(Weather).filter(Weather.code == "SPRING_PATTERN_0001").first()
    assert p1 is not None
    assert p1.season == "spring"
    assert p1.min_temp == 4.5
    assert p1.max_temp == 18.5
    assert p1.icon == "sunny.svg"
    assert p1.min_humidity == 42
    assert p1.max_humidity == 94

    p4000 = db_session.query(Weather).filter(Weather.code == "WINTER_PATTERN_1000").first()
    assert p4000 is not None
    assert p4000.season == "winter"
    assert p4000.min_temp == 15.0
    assert p4000.max_temp == 26.9
    assert p4000.min_humidity == 82
    assert p4000.max_humidity == 99


def test_weather_seed_idempotency_and_overwrite(db_session: Session):
    """Kiểm thử tính idempotent: lần chạy 2 không nạp lại nếu không force; force=True thì ghi đè."""
    # Nạp lần 1
    WeatherService.seed_4000_weather_patterns(db_session, force=True)
    count_first = db_session.query(func.count(Weather.id)).filter(
        Weather.code.like("%_PATTERN_%")
    ).scalar()
    assert count_first == 4000

    # Chạy lần 2 với force=False (đã có marker) -> trả về 0 bản ghi, không thêm dòng nào
    result_run2 = WeatherService.seed_4000_weather_patterns(db_session, force=False)
    assert result_run2 == 0
    count_after_run2 = db_session.query(func.count(Weather.id)).filter(
        Weather.code.like("%_PATTERN_%")
    ).scalar()
    assert count_after_run2 == 4000

    # Chạy lần 3 với force=True -> ghi đè cập nhật 4000 bản ghi mà không tăng tổng số dòng
    result_force = WeatherService.seed_4000_weather_patterns(db_session, force=True)
    assert result_force == 4000
    count_after_force = db_session.query(func.count(Weather.id)).filter(
        Weather.code.like("%_PATTERN_%")
    ).scalar()
    assert count_after_force == 4000, "Upsert ghi đè không được làm nhân đôi số lượng bản ghi"


def test_preserve_user_and_option_user_data(db_session: Session):
    """Kiểm thử bảo toàn 100% dữ liệu User và OptionUser khi nạp/ghi đè weather."""
    # Tạo user mẫu và option_user mẫu
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
            is_active=True,
        )
        db_session.add(user)
        db_session.commit()
        db_session.refresh(user)

    # Tạo category mẫu nếu chưa có
    cat = db_session.query(Category).first()
    if not cat:
        cat = Category(name="Danh mục Test", sort_order=1, is_active=True)
        db_session.add(cat)
        db_session.commit()
        db_session.refresh(cat)

    # Thêm option_user
    opt = db_session.query(OptionUser).filter(
        OptionUser.user_id == user.id,
        OptionUser.category_id == cat.id
    ).first()
    if not opt:
        opt = OptionUser(user_id=user.id, category_id=cat.id, hide=True)
        db_session.add(opt)
        db_session.commit()

    # Thực hiện seed weather với force=True
    WeatherService.seed_4000_weather_patterns(db_session, force=True)

    # Kiểm tra lại user và option_user
    user_after = db_session.query(User).filter(User.email == test_email).first()
    assert user_after is not None, "Dữ liệu User không được biến mất"
    assert user_after.full_name == "User Test Weather Preserve"
    assert user_after.height_cm == 175.0
    assert user_after.allergies == ["Peanut"]

    opt_after = db_session.query(OptionUser).filter(
        OptionUser.user_id == user.id,
        OptionUser.category_id == cat.id
    ).first()
    assert opt_after is not None, "Dữ liệu OptionUser của người dùng phải được bảo toàn nguyên vẹn"
    assert opt_after.hide is True


def test_legacy_weather_purged_and_only_4000_patterns_kept(db_session: Session):
    """Kiểm thử tự động dọn sạch 4 mẫu cũ (hot, rainy, cold, mild), chỉ giữ duy nhất 4000 mẫu mới."""
    from server.app.services.weather_service import DEFAULT_WEATHERS

    # Giả lập DB có sẵn 4 bản ghi hot, rainy, cold, mild
    for item in DEFAULT_WEATHERS:
        existing = db_session.query(Weather).filter(Weather.code == item["code"]).first()
        if not existing:
            db_session.add(Weather(
                code=item["code"],
                name=item["name"],
                description=item["description"],
                min_temp=item["min_temp"],
                max_temp=item["max_temp"],
                condition=item["condition"],
                icon=item["icon"],
                season=item.get("season"),
                sort_order=item["sort_order"],
                is_active=True,
            ))
    db_session.commit()

    # Xác nhận DB có bản ghi cũ
    legacy_count = db_session.query(Weather).filter(
        Weather.code.in_(["hot", "rainy", "cold", "mild"])
    ).count()
    assert legacy_count > 0, "Cần có bản ghi cũ để kiểm thử cơ chế tự động dọn rác"

    # Chạy nạp 4000 mẫu
    WeatherService.seed_4000_weather_patterns(db_session, force=True)

    # Kiểm tra: 4 bản ghi cũ ĐÃ BỊ XOÁ HOÀN TOÀN
    legacy_after = db_session.query(Weather).filter(
        Weather.code.in_(["hot", "rainy", "cold", "mild"])
    ).count()
    assert legacy_after == 0, "Toàn bộ 4 bản ghi weather cũ (hot, rainy, cold, mild) phải bị xóa sạch"

    # Kiểm tra: Bảng weather CHỈ CÒN ĐÚNG 4000 bản ghi theo mùa
    total_weathers = db_session.query(Weather).count()
    assert total_weathers == 4000, f"Bảng weather phải chỉ có đúng 4000 mẫu, thực tế có {total_weathers}"


def test_preserve_weather_category_links(db_session: Session):
    """Kiểm thử bảo toàn liên kết WeatherCategory khi chạy seed."""
    cat = db_session.query(Category).first()
    if not cat:
        cat = Category(name="Danh mục Liên Kết Mẫu", sort_order=1, is_active=True)
        db_session.add(cat)
        db_session.commit()
        db_session.refresh(cat)

    w = db_session.query(Weather).filter(Weather.code == "SPRING_PATTERN_0001").first()
    assert w is not None

    link = db_session.query(WeatherCategory).filter(
        WeatherCategory.weather_id == w.id,
        WeatherCategory.category_id == cat.id
    ).first()
    if not link:
        link = WeatherCategory(weather_id=w.id, category_id=cat.id)
        db_session.add(link)
        db_session.commit()

    # Chạy lại seed với force=True
    WeatherService.seed_4000_weather_patterns(db_session, force=True)

    # Kiểm tra liên kết vẫn còn nguyên
    link_after = db_session.query(WeatherCategory).filter(
        WeatherCategory.weather_id == w.id,
        WeatherCategory.category_id == cat.id
    ).first()
    assert link_after is not None, "Liên kết WeatherCategory phải được bảo toàn nguyên vẹn sau seed"


def test_sequence_synced_after_seed(db_session: Session):
    """Kiểm thử sequence ID PostgreSQL được đồng bộ chính xác, không gây duplicate key error khi tạo mới."""
    WeatherService.seed_4000_weather_patterns(db_session, force=True)

    new_custom_weather = Weather(
        code="CUSTOM_WEATHER_TEST_SEQ",
        name="Thời tiết tùy chỉnh sau seed",
        min_temp=20.0,
        max_temp=25.0,
    )
    db_session.add(new_custom_weather)
    db_session.commit()
    db_session.refresh(new_custom_weather)

    assert new_custom_weather.id is not None
    assert new_custom_weather.id > 4000

    # Dọn dẹp bản ghi kiểm thử
    db_session.delete(new_custom_weather)
    db_session.commit()


def test_missing_json_file_graceful_handling(db_session: Session):
    """Kiểm thử xử lý an toàn khi không tìm thấy tệp JSON: không làm sập ứng dụng."""
    with patch.object(WeatherService, "get_weather_json_path", return_value=Path("non_existent_weather.json")):
        result = WeatherService.seed_4000_weather_patterns(db_session, force=True)
        assert result == 0
