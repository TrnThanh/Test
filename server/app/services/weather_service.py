from typing import List, Optional
from sqlalchemy import select
from sqlalchemy.orm import Session
from fastapi import HTTPException, status

from server.app.models.weather import Weather
from server.app.schemas.weather import WeatherCreate, WeatherUpdate


DEFAULT_WEATHERS = [
    {
        "code": "hot",
        "name": "Nắng nóng oi bức",
        "description": "Nhiệt độ cao, thích hợp ăn kem, uống trà sữa, chè giải nhiệt.",
        "min_temp": 30.0,
        "max_temp": 45.0,
        "condition": "sunny",
        "icon": "weather-sunny",
        "sort_order": 1,
    },
    {
        "code": "rainy",
        "name": "Trời mưa ẩm ướt",
        "description": "Mưa rào hoặc mưa dầm, thích hợp ăn đồ nóng hổi, lẩu, đồ chiên rán.",
        "min_temp": 20.0,
        "max_temp": 28.0,
        "condition": "rainy",
        "icon": "weather-rainy",
        "sort_order": 2,
    },
    {
        "code": "cold",
        "name": "Trời lạnh gió rét",
        "description": "Nhiệt độ thấp mùa đông, lý tưởng cho món nướng, lẩu, phở bò nóng.",
        "min_temp": 5.0,
        "max_temp": 18.0,
        "condition": "cloudy",
        "icon": "weather-snowy",
        "sort_order": 3,
    },
    {
        "code": "mild",
        "name": "Mát mẻ dễ chịu",
        "description": "Thời tiết đẹp, phù hợp với hầu hết các món ăn đặc sắc.",
        "min_temp": 19.0,
        "max_temp": 29.0,
        "condition": "clear",
        "icon": "weather-partly-cloudy",
        "sort_order": 4,
    },
]


class WeatherService:
    @staticmethod
    def seed_default_weathers(db: Session) -> List[Weather]:
        """Tự động seed các trạng thái thời tiết mẫu nếu chưa tồn tại."""
        results = []
        for item in DEFAULT_WEATHERS:
            stmt = select(Weather).where(Weather.code == item["code"])
            existing = db.scalar(stmt)
            if not existing:
                w = Weather(
                    code=item["code"],
                    name=item["name"],
                    description=item["description"],
                    min_temp=item["min_temp"],
                    max_temp=item["max_temp"],
                    condition=item["condition"],
                    icon=item["icon"],
                    sort_order=item["sort_order"],
                    is_active=True,
                )
                db.add(w)
                results.append(w)
            else:
                results.append(existing)
        db.commit()
        return results

    @staticmethod
    def get_all_weathers(db: Session, active_only: bool = True) -> List[Weather]:
        """Lấy danh sách các điều kiện thời tiết trong hệ thống."""
        stmt = select(Weather)
        if active_only:
            stmt = stmt.where(Weather.is_active.is_(True))
        stmt = stmt.order_by(Weather.sort_order.asc(), Weather.id.asc())
        return list(db.scalars(stmt).all())

    @staticmethod
    def get_weather_by_id(db: Session, weather_id: int) -> Weather:
        """Lấy chi tiết một trạng thái thời tiết."""
        w = db.get(Weather, weather_id)
        if not w:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Không tìm thấy trạng thái thời tiết với ID {weather_id}.",
            )
        return w

    @staticmethod
    def create_weather(db: Session, data: WeatherCreate) -> Weather:
        """Tạo mới một trạng thái thời tiết."""
        code_clean = data.code.strip().lower()
        stmt = select(Weather).where(Weather.code == code_clean)
        if db.scalar(stmt):
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"Mã trạng thái thời tiết '{code_clean}' đã tồn tại.",
            )

        w = Weather(
            code=code_clean,
            name=data.name.strip(),
            description=data.description.strip() if data.description else None,
            min_temp=data.min_temp,
            max_temp=data.max_temp,
            condition=data.condition.strip() if data.condition else None,
            icon=data.icon.strip() if data.icon else None,
            sort_order=data.sort_order,
            is_active=data.is_active,
        )
        db.add(w)
        db.commit()
        db.refresh(w)
        return w
