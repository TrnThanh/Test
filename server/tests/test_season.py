import pytest
from pydantic import ValidationError
from sqlalchemy import text, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session
from fastapi.testclient import TestClient

from server.app.models.season import Season
from server.app.models.weather import Weather
from server.app.schemas.season import SeasonBase, SeasonResponse
from server.app.schemas.weather import WeatherResponse
from server.app.services.season_service import SeasonService


def test_seasons_table_has_exactly_4_seasons(db_session: Session):
    """Kiểm tra bảng seasons có đúng 4 mùa cố định (1..4) với tên, mã và khoảng thời gian chuẩn."""
    SeasonService.seed_default_seasons(db_session)
    seasons = db_session.scalars(select(Season).order_by(Season.id)).all()
    assert len(seasons) == 4, f"Bảng seasons phải có đúng 4 bản ghi, hiện có {len(seasons)}"

    expected = {
        1: ("spring", "Xuân", "02-01", "04-30"),
        2: ("summer", "Hạ", "05-01", "08-31"),
        3: ("autumn", "Thu", "09-01", "11-30"),
        4: ("winter", "Đông", "12-01", "01-31"),
    }
    for s in seasons:
        exp_code, exp_name, exp_start, exp_end = expected[s.id]
        assert s.code == exp_code
        assert s.name == exp_name
        assert s.start_date == exp_start
        assert s.end_date == exp_end
        assert s.is_active is True
        assert s.sort_order == s.id


def test_weather_records_have_valid_season_id(db_session: Session):
    """Kiểm tra các bản ghi thời tiết đều được gán season_id và khớp với cột season."""
    null_count = db_session.scalar(text("SELECT count(*) FROM weather WHERE season_id IS NULL"))
    assert null_count == 0, f"Có {null_count} bản ghi weather bị NULL season_id"

    # Kiểm tra tính khớp 100% giữa text season và season_id
    mismatch_count = db_session.scalar(text("""
        SELECT count(*) 
        FROM weather w 
        JOIN seasons s ON w.season_id = s.id 
        WHERE lower(w.season) != lower(s.code)
    """))
    assert mismatch_count == 0, f"Phát hiện {mismatch_count} bản ghi lệch giữa season string và season_id"


def test_api_list_seasons(client: TestClient):
    """Kiểm tra API GET /api/v1/seasons/ trả về danh sách 4 mùa kèm start_date và end_date."""
    response = client.get("/api/v1/seasons")
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 4
    assert [d["id"] for d in data] == [1, 2, 3, 4]
    assert [d["code"] for d in data] == ["spring", "summer", "autumn", "winter"]
    assert [d["name"] for d in data] == ["Xuân", "Hạ", "Thu", "Đông"]
    assert data[0]["start_date"] == "02-01"
    assert data[0]["end_date"] == "04-30"
    assert data[1]["start_date"] == "05-01"
    assert data[1]["end_date"] == "08-31"
    assert data[2]["start_date"] == "09-01"
    assert data[2]["end_date"] == "11-30"
    assert data[3]["start_date"] == "12-01"
    assert data[3]["end_date"] == "01-31"


def test_api_get_season_detail(client: TestClient):
    """Kiểm tra API GET /api/v1/seasons/{id}."""
    resp1 = client.get("/api/v1/seasons/1")
    assert resp1.status_code == 200
    json1 = resp1.json()
    assert json1["code"] == "spring"
    assert json1["name"] == "Xuân"
    assert json1["start_date"] == "02-01"
    assert json1["end_date"] == "04-30"

    resp4 = client.get("/api/v1/seasons/4")
    assert resp4.status_code == 200
    json4 = resp4.json()
    assert json4["code"] == "winter"
    assert json4["name"] == "Đông"
    assert json4["start_date"] == "12-01"
    assert json4["end_date"] == "01-31"

    resp_404 = client.get("/api/v1/seasons/99")
    assert resp_404.status_code == 404


def test_get_season_by_date(db_session: Session):
    """Kiểm tra logic tra cứu mùa theo ngày tháng (SeasonService.get_season_by_date)."""
    # 1. Mùa Xuân (02-01 đến 04-30)
    s_spring_start = SeasonService.get_season_by_date(db_session, 2, 1)
    assert s_spring_start is not None and s_spring_start.code == "spring"
    s_spring_mid = SeasonService.get_season_by_date(db_session, 3, 15)
    assert s_spring_mid is not None and s_spring_mid.code == "spring"
    s_spring_end = SeasonService.get_season_by_date(db_session, 4, 30)
    assert s_spring_end is not None and s_spring_end.code == "spring"

    # 2. Mùa Hạ (05-01 đến 08-31)
    s_summer_start = SeasonService.get_season_by_date(db_session, 5, 1)
    assert s_summer_start is not None and s_summer_start.code == "summer"
    s_summer_mid = SeasonService.get_season_by_date(db_session, 7, 15)
    assert s_summer_mid is not None and s_summer_mid.code == "summer"
    s_summer_end = SeasonService.get_season_by_date(db_session, 8, 31)
    assert s_summer_end is not None and s_summer_end.code == "summer"

    # 3. Mùa Thu (09-01 đến 11-30)
    s_autumn_start = SeasonService.get_season_by_date(db_session, 9, 1)
    assert s_autumn_start is not None and s_autumn_start.code == "autumn"
    s_autumn_mid = SeasonService.get_season_by_date(db_session, 10, 20)
    assert s_autumn_mid is not None and s_autumn_mid.code == "autumn"
    s_autumn_end = SeasonService.get_season_by_date(db_session, 11, 30)
    assert s_autumn_end is not None and s_autumn_end.code == "autumn"

    # 4. Mùa Đông (12-01 đến 01-31, vắt năm)
    s_winter_dec = SeasonService.get_season_by_date(db_session, 12, 1)
    assert s_winter_dec is not None and s_winter_dec.code == "winter"
    s_winter_xmas = SeasonService.get_season_by_date(db_session, 12, 25)
    assert s_winter_xmas is not None and s_winter_xmas.code == "winter"
    s_winter_jan_start = SeasonService.get_season_by_date(db_session, 1, 1)
    assert s_winter_jan_start is not None and s_winter_jan_start.code == "winter"
    s_winter_jan_end = SeasonService.get_season_by_date(db_session, 1, 31)
    assert s_winter_jan_end is not None and s_winter_jan_end.code == "winter"


def test_season_schema_validation_date_format():
    """Kiểm tra schema validation với regex pattern MM-DD."""
    # Hợp lệ
    valid = SeasonBase(
        code="spring",
        name="Xuân",
        start_date="02-01",
        end_date="04-30",
    )
    assert valid.start_date == "02-01"
    assert valid.end_date == "04-30"

    # Không hợp lệ: tháng 13
    with pytest.raises(ValidationError):
        SeasonBase(code="spring", name="Xuân", start_date="13-01", end_date="04-30")

    # Không hợp lệ: ngày 32
    with pytest.raises(ValidationError):
        SeasonBase(code="spring", name="Xuân", start_date="02-32", end_date="04-30")

    # Không hợp lệ: format thiếu số 0 (2-1)
    with pytest.raises(ValidationError):
        SeasonBase(code="spring", name="Xuân", start_date="2-1", end_date="4-30")


def test_weather_response_serialization_with_season_name(db_session: Session):
    """Kiểm tra WeatherResponse serialization chứa đầy đủ season_id và computed season_name."""
    w = db_session.query(Weather).filter(Weather.code == "SPRING_PATTERN_0001_H00").first()
    if not w:
        w = Weather(
            code="SPRING_PATTERN_0001_H00",
            name="Trời quang / Nắng đẹp",
            season_id=1,
            season="spring",
            hour=0,
        )
        db_session.add(w)
        db_session.commit()
        db_session.refresh(w)

    assert w.season_id == 1
    resp = WeatherResponse.model_validate(w)
    assert resp.season_id == 1
    assert resp.season == "spring"
    assert resp.season_name == "Xuân"
    assert resp.hour_display == "12:00 AM"


def test_foreign_key_rejects_invalid_season_id(db_session: Session):
    """Kiểm tra ràng buộc khóa ngoại: không thể chèn weather với season_id không tồn tại."""
    invalid_weather = Weather(
        code="INVALID_SEASON_TEST_CODE_999",
        name="Test Thời Tiết Sai Mùa",
        season_id=999,  # Không tồn tại trong seasons
        hour=10,
    )
    db_session.add(invalid_weather)
    with pytest.raises(IntegrityError):
        db_session.commit()
    db_session.rollback()
