import pytest
from sqlalchemy import text, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session
from fastapi.testclient import TestClient

from server.app.models.season import Season
from server.app.models.weather import Weather
from server.app.schemas.weather import WeatherResponse
from server.app.services.season_service import SeasonService


def test_seasons_table_has_exactly_4_seasons(db_session: Session):
    """Kiểm tra bảng seasons có đúng 4 mùa cố định (1..4) với tên và mã chuẩn."""
    SeasonService.seed_default_seasons(db_session)
    seasons = db_session.scalars(select(Season).order_by(Season.id)).all()
    assert len(seasons) == 4, f"Bảng seasons phải có đúng 4 bản ghi, hiện có {len(seasons)}"

    expected = {
        1: ("spring", "Xuân"),
        2: ("summer", "Hạ"),
        3: ("autumn", "Thu"),
        4: ("winter", "Đông"),
    }
    for s in seasons:
        exp_code, exp_name = expected[s.id]
        assert s.code == exp_code
        assert s.name == exp_name
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
    """Kiểm tra API GET /api/v1/seasons/ trả về danh sách 4 mùa."""
    response = client.get("/api/v1/seasons")
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 4
    assert [d["id"] for d in data] == [1, 2, 3, 4]
    assert [d["code"] for d in data] == ["spring", "summer", "autumn", "winter"]
    assert [d["name"] for d in data] == ["Xuân", "Hạ", "Thu", "Đông"]


def test_api_get_season_detail(client: TestClient):
    """Kiểm tra API GET /api/v1/seasons/{id}."""
    resp1 = client.get("/api/v1/seasons/1")
    assert resp1.status_code == 200
    assert resp1.json()["code"] == "spring"
    assert resp1.json()["name"] == "Xuân"

    resp_404 = client.get("/api/v1/seasons/99")
    assert resp_404.status_code == 404


def test_weather_response_serialization_with_season_name(db_session: Session):
    """Kiểm tra WeatherResponse serialization chứa đầy đủ season_id và computed season_name."""
    w = db_session.query(Weather).filter(Weather.code == "SPRING_PATTERN_0001_H00").first()
    if not w:
        # Tạo bản ghi test nếu seed rút gọn
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
