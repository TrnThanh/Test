# -*- coding: utf-8 -*-
"""
Bộ kiểm thử tính năng format khung giờ 12-hour AM/PM (hour_display)
và chuẩn hóa tên sạch không nhồi giờ trong bảng weather và Pydantic schemas.
"""
import pytest
from server.app.core.time_utils import format_hour_12h
from server.app.schemas.weather import HourlyWeatherItem, WeatherResponse
from server.app.models.weather import Weather
from sqlalchemy import text


class TestTimeFormatUtils:
    def test_format_hour_12h_edge_cases(self):
        # 12:00 AM (nửa đêm)
        assert format_hour_12h(0) == "12:00 AM"
        # 7:00 AM (buổi sáng theo user request)
        assert format_hour_12h(7) == "7:00 AM"
        # 11:00 AM (trước trưa)
        assert format_hour_12h(11) == "11:00 AM"
        # 12:00 PM (chính ngọ)
        assert format_hour_12h(12) == "12:00 PM"
        # 1:00 PM (đầu giờ chiều)
        assert format_hour_12h(13) == "1:00 PM"
        # 11:00 PM (đêm muộn)
        assert format_hour_12h(23) == "11:00 PM"
        # None
        assert format_hour_12h(None) is None

    def test_format_hour_12h_invalid_raises(self):
        with pytest.raises(ValueError):
            format_hour_12h(-1)
        with pytest.raises(ValueError):
            format_hour_12h(24)


class TestWeatherSchemasHourly:
    def test_hourly_weather_item_hour_display(self):
        item = HourlyWeatherItem(
            hour=7,
            temperature=22.5,
            humidity=85.0,
            precipitation=0.0,
            weather_code=0,
            condition="SUNNY",
            icon="sunny.svg",
        )
        assert item.hour_display == "7:00 AM"
        data = item.model_dump()
        assert data["hour_display"] == "7:00 AM"

    def test_weather_response_hour_display(self):
        resp = WeatherResponse(
            id=8,
            code="SPRING_PATTERN_0001_H07",
            pattern_code="SPRING_PATTERN_0001",
            hour=7,
            name="Trời quang / Nắng đẹp - Mẫu 0001 (Mùa Xuân)",
            temperature=18.0,
            humidity=75.0,
            created_at="2026-11-03T10:00:00Z",
        )
        assert resp.hour_display == "7:00 AM"
        assert "(" not in resp.name or "Mùa" in resp.name
        assert "07:00" not in resp.name

        dumped = resp.model_dump()
        assert dumped["hour_display"] == "7:00 AM"
        assert "hourly" not in dumped


class TestDatabaseWeatherNamesClean:
    def test_hourly_column_dropped_completely(self, db_session):
        cols = db_session.execute(
            text("SELECT column_name FROM information_schema.columns WHERE table_name='weather';")
        ).scalars().all()
        assert "hourly" not in cols, "Cột 'hourly' vẫn còn trong bảng weather!"
    def test_no_hourly_baked_in_weather_name(self, db_session):
        # Xác nhận không có bản ghi nào chứa chuỗi giờ baked in như (00:00 - Mẫu...
        count_dirty = db_session.execute(
            text("SELECT COUNT(*) FROM weather WHERE name LIKE :pat"),
            {"pat": "%:00 - %"}
        ).scalar()
        assert count_dirty == 0, f"Còn {count_dirty} bản ghi chứa chuỗi giờ trong name!"

    def test_sample_weather_hour_display_api(self, client):
        # Lấy bản ghi giờ 7 sáng
        response = client.get("/api/v1/weather/?hour=7&limit=5")
        assert response.status_code == 200
        data = response.json()
        assert len(data) > 0
        for item in data:
            assert item["hour"] == 7
            assert item["hour_display"] == "7:00 AM"
            assert "07:00 -" not in item["name"]
