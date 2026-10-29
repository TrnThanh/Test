import json
import logging
from pathlib import Path
from typing import List, Optional
import httpx
from sqlalchemy import select, text, func
from sqlalchemy.dialects.postgresql import insert as pg_insert
from sqlalchemy.orm import Session
from fastapi import HTTPException, status

from server.app.core.config import settings
from server.app.models.weather import Weather
from server.app.schemas.weather import (
    WeatherCreate,
    WeatherUpdate,
    WeatherResponse,
    CurrentWeatherResponse,
)
from server.app.schemas.category import CategoryResponse
from server.app.services.weather_category_service import WeatherCategoryService

logger = logging.getLogger(__name__)

DEFAULT_WEATHERS = [
    {
        "code": "hot",
        "name": "Nắng nóng oi bức",
        "description": "Nhiệt độ cao, thích hợp ăn kem, uống trà sữa, chè giải nhiệt.",
        "min_temp": 30.0,
        "max_temp": 45.0,
        "condition": "sunny",
        "icon": "weather-sunny",
        "season": "summer",
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
        "season": "rainy",
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
        "season": "winter",
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
        "season": "autumn",
        "sort_order": 4,
    },
]


class WeatherService:
    @staticmethod
    def seed_default_weathers(db: Session) -> List[Weather]:
        """(Deprecated) Đã thay thế hoàn toàn bằng 400 mẫu thời tiết theo mùa trong seed_400_weather_patterns."""
        # Tự động dọn sạch các mã thời tiết cũ nếu có
        db.execute(text("DELETE FROM weather WHERE code IN ('hot', 'rainy', 'cold', 'mild');"))
        db.commit()
        return []

    @staticmethod
    def get_weather_json_path() -> Path:
        """Lấy đường dẫn tệp JSON chứa 400 mẫu thời tiết theo mùa."""
        return Path(__file__).resolve().parents[3] / "scripts" / "weather_400_mau_so_2000_2025.json"

    @staticmethod
    def seed_400_weather_patterns(db: Session, force: bool = False) -> int:
        """Tự động dọn dẹp các mẫu cũ và nạp/ghi đè 400 mẫu thời tiết theo 4 mùa giai đoạn 2000-2025."""
        from server.app.models.seed_meta import SeedMeta

        # 1. Luôn tự động dọn sạch các bản ghi thời tiết cũ (hot, rainy, cold, mild hoặc không thuộc 400 mẫu)
        # để đảm bảo trên bất kỳ máy nào khi khởi chạy cũng chỉ có đúng 400 mẫu mới
        db.execute(text("DELETE FROM weather WHERE code IN ('hot', 'rainy', 'cold', 'mild') OR code NOT LIKE '%_PATTERN_%';"))

        pattern_count = db.scalar(select(func.count(Weather.id)).where(Weather.code.like("%_PATTERN_%"))) or 0
        seed_key = "weather_400_patterns_v1"
        if not force and pattern_count == 400:
            db.commit()
            return 0

        json_file = WeatherService.get_weather_json_path()
        if not json_file.exists():
            logger.warning("[WeatherSeed] Không tìm thấy tệp JSON tại: %s", json_file)
            return 0

        try:
            with open(json_file, "r", encoding="utf-8") as f:
                patterns: List[dict] = json.load(f)
        except Exception as e:
            logger.error("[WeatherSeed] Lỗi khi đọc tệp %s: %s", json_file, e)
            return 0

        # Nạp theo lô 100 bản ghi bằng Bulk Upsert PostgreSQL ON CONFLICT (code) DO UPDATE
        upserted_count = 0
        batch_size = 100
        for i in range(0, len(patterns), batch_size):
            batch = patterns[i : i + batch_size]
            clean_batch = []
            for item in batch:
                clean_batch.append({
                    "code": item["code"],
                    "name": item["name"],
                    "description": item.get("description"),
                    "min_temp": item.get("min_temp"),
                    "max_temp": item.get("max_temp"),
                    "condition": item.get("condition"),
                    "icon": item.get("icon"),
                    "season": item.get("season"),
                    "sort_order": item.get("sort_order", 0),
                    "is_active": item.get("is_active", True),
                })

            stmt = pg_insert(Weather).values(clean_batch)
            stmt = stmt.on_conflict_do_update(
                index_elements=[Weather.code],
                set_={
                    "name": stmt.excluded.name,
                    "description": stmt.excluded.description,
                    "min_temp": stmt.excluded.min_temp,
                    "max_temp": stmt.excluded.max_temp,
                    "condition": stmt.excluded.condition,
                    "icon": stmt.excluded.icon,
                    "season": stmt.excluded.season,
                    "sort_order": stmt.excluded.sort_order,
                    "is_active": stmt.excluded.is_active,
                },
            )
            db.execute(stmt)
            upserted_count += len(clean_batch)

        # Cập nhật marker SeedMeta
        db.merge(SeedMeta(key=seed_key, version=1))

        # Đồng bộ sequence auto-increment ID cho bảng weather
        try:
            db.execute(text("SELECT setval(pg_get_serial_sequence('weather', 'id'), COALESCE((SELECT MAX(id) FROM weather), 1), true);"))
        except Exception as seq_err:
            logger.debug("[WeatherSeed] Không cần cập nhật sequence hoặc DB không hỗ trợ: %s", seq_err)

        db.commit()
        logger.info("[WeatherSeed] Đã tự động nạp và ghi đè thành công %s mẫu thời tiết vào database.", upserted_count)
        return upserted_count

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
    def get_weather_by_code(db: Session, code: str) -> Optional[Weather]:
        """Lấy trạng thái thời tiết theo mã định danh (hot, cold, rainy, mild)."""
        clean_code = code.strip().lower()
        stmt = select(Weather).where(Weather.code == clean_code)
        return db.scalar(stmt)

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
            season=data.season.strip() if data.season else None,
            sort_order=data.sort_order,
            is_active=data.is_active,
        )
        db.add(w)
        db.commit()
        db.refresh(w)
        return w

    @staticmethod
    def update_weather(db: Session, weather_id: int, data: WeatherUpdate) -> Weather:
        """Cập nhật thông tin cấu hình một trạng thái thời tiết."""
        w = db.get(Weather, weather_id)
        if not w:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Không tìm thấy trạng thái thời tiết với ID {weather_id}.",
            )

        update_dict = data.model_dump(exclude_unset=True)
        for key, val in update_dict.items():
            if val is not None and isinstance(val, str):
                setattr(w, key, val.strip())
            else:
                setattr(w, key, val)

        if w.min_temp is not None and w.max_temp is not None and w.min_temp > w.max_temp:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Nhiệt độ tối thiểu không được lớn hơn nhiệt độ tối đa.",
            )

        db.add(w)
        db.commit()
        db.refresh(w)
        return w

    @staticmethod
    def delete_weather(db: Session, weather_id: int) -> None:
        """Xoá một trạng thái thời tiết khỏi hệ thống."""
        w = db.get(Weather, weather_id)
        if not w:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Không tìm thấy trạng thái thời tiết với ID {weather_id}.",
            )
        db.delete(w)
        db.commit()

    @staticmethod
    def map_condition_to_code(
        temp: float,
        condition_main: Optional[str] = None,
        description: Optional[str] = None,
        weather_id: Optional[int] = None,
    ) -> str:
        """
        Quy tắc chuẩn hóa và ánh xạ thời tiết thực tế về 4 mã hệ thống:
        - 'rainy': Có mưa (Rain, Drizzle, Thunderstorm, mã OpenWeather 2xx/3xx/5xx hoặc mô tả có từ 'mưa')
        - 'cold': Trời lạnh rét (nhiệt độ <= 18°C hoặc tuyết)
        - 'hot': Nắng nóng oi bức (nhiệt độ >= 30°C)
        - 'mild': Mát mẻ dễ chịu (18°C < temp < 30°C và không mưa)
        """
        cond_lower = (condition_main or "").lower()
        desc_lower = (description or "").lower()

        # Kiểm tra mưa trước tiên (mưa ảnh hưởng mạnh nhất đến quyết định ăn uống)
        if (
            (weather_id is not None and 200 <= weather_id < 600)
            or cond_lower in ["rain", "drizzle", "thunderstorm"]
            or "mưa" in desc_lower
        ):
            return "rainy"

        # Kiểm tra trời lạnh
        if temp <= 18.0 or (weather_id is not None and 600 <= weather_id < 700):
            return "cold"

        # Kiểm tra trời nắng nóng
        if temp >= 30.0:
            return "hot"

        # Mặc định mát mẻ
        return "mild"

    @staticmethod
    async def fetch_current_weather(
        db: Session,
        lat: Optional[float] = None,
        lon: Optional[float] = None,
        client: Optional[httpx.AsyncClient] = None,
    ) -> CurrentWeatherResponse:
        """
        Lấy thông tin thời tiết thời gian thực từ OpenWeatherMap API theo tọa độ.
        - Mặc định tọa độ là Học viện Nông nghiệp Việt Nam (HVNN Gia Lâm, Hà Nội).
        - Nếu API Key chưa được thiết lập hoặc API gặp sự cố, tự động fallback an toàn mà không làm sập request.
        """
        actual_lat = lat if lat is not None else settings.DEFAULT_WEATHER_LAT
        actual_lon = lon if lon is not None else settings.DEFAULT_WEATHER_LON

        api_key = settings.OPENWEATHERMAP_API_KEY.strip()
        data = None
        is_live = False

        if api_key:
            url = f"{settings.OPENWEATHERMAP_BASE_URL.rstrip('/')}/weather"
            params = {
                "lat": actual_lat,
                "lon": actual_lon,
                "appid": api_key,
                "units": "metric",
                "lang": "vi",
            }
            try:
                if client is not None:
                    resp = await client.get(url, params=params, timeout=settings.OPENWEATHERMAP_TIMEOUT_SECONDS)
                else:
                    async with httpx.AsyncClient(timeout=settings.OPENWEATHERMAP_TIMEOUT_SECONDS) as c:
                        resp = await c.get(url, params=params)

                if resp.status_code == 200:
                    data = resp.json()
                    is_live = True
                else:
                    logger.warning("OpenWeatherMap trả về mã lỗi %s: %s", resp.status_code, resp.text)
            except Exception as exc:
                logger.warning("Không thể kết nối OpenWeatherMap API (%s). Sử dụng dữ liệu dự phòng.", exc)

        if data:
            main_info = data.get("main", {})
            temp = float(main_info.get("temp", 26.0))
            feels_like = float(main_info.get("feels_like", temp))
            humidity = int(main_info.get("humidity", 65))
            weather_list = data.get("weather", [])
            w0 = weather_list[0] if weather_list else {}
            w_id = w0.get("id")
            condition = w0.get("main", "Clear")
            desc = w0.get("description", "Trời quang mát mẻ")
            icon_code = w0.get("icon", "01d")
            location_name = data.get("name") or settings.DEFAULT_WEATHER_LOCATION_NAME
        else:
            # Dữ liệu dự phòng mặc định tại HVNN
            temp = 26.0
            feels_like = 26.5
            humidity = 65
            w_id = 800
            condition = "Clear"
            desc = "Thời tiết mát mẻ"
            icon_code = "02d"
            location_name = settings.DEFAULT_WEATHER_LOCATION_NAME

        icon_url = f"https://openweathermap.org/img/wn/{icon_code}@2x.png" if icon_code else None

        # Xác định nhóm mùa và tìm mẫu thời tiết trong 400 mẫu phù hợp nhất
        from datetime import datetime
        current_month = datetime.now().month
        if current_month in [2, 3, 4]:
            current_season = "spring"
        elif current_month in [5, 6, 7]:
            current_season = "summer"
        elif current_month in [8, 9, 10]:
            current_season = "autumn"
        else:
            current_season = "winter"

        if temp >= 30.0:
            target_season = "summer"
        elif temp <= 18.0:
            target_season = "winter"
        else:
            target_season = current_season

        stmt_pattern = (
            select(Weather)
            .where(Weather.season == target_season)
            .order_by(func.abs((Weather.min_temp + Weather.max_temp) / 2.0 - temp))
            .limit(1)
        )
        matched_weather = db.scalars(stmt_pattern).first()
        if not matched_weather:
            matched_weather = db.scalars(
                select(Weather).order_by(func.abs((Weather.min_temp + Weather.max_temp) / 2.0 - temp)).limit(1)
            ).first()

        if not matched_weather:
            WeatherService.seed_400_weather_patterns(db)
            matched_weather = db.scalars(stmt_pattern).first() or db.scalars(select(Weather).order_by(Weather.id).limit(1)).first()

        recommended_categories: List[CategoryResponse] = []
        if matched_weather:
            try:
                cats = WeatherCategoryService.get_categories_by_weather(db, matched_weather.id)
                if not cats:
                    from server.app.models.category import Category
                    season_cats = {
                        "winter": ["Lẩu & Nướng", "Phở & Bún", "Cơm & Xôi"],
                        "summer": ["Cà phê & Trà sữa", "Đồ ăn vặt", "Món chay"],
                        "autumn": ["Cà phê & Trà sữa", "Phở & Bún", "Bánh mì"],
                        "spring": ["Bánh mì", "Phở & Bún", "Cơm & Xôi", "Món chay"],
                    }
                    kw = season_cats.get(matched_weather.season, ["Phở & Bún", "Cơm & Xôi"])
                    cats = db.scalars(select(Category).where(Category.name.in_(kw))).all()
                    if not cats:
                        cats = db.scalars(select(Category).limit(5)).all()
                recommended_categories = [CategoryResponse.model_validate(c) for c in cats]
            except Exception as e:
                logger.debug("Chưa có danh mục cho weather_id %s: %s", matched_weather.id, e)

        return CurrentWeatherResponse(
            temperature=round(temp, 1),
            feels_like=round(feels_like, 1) if feels_like is not None else None,
            humidity=humidity,
            condition=condition,
            description=desc,
            icon=icon_code,
            icon_url=icon_url,
            latitude=actual_lat,
            longitude=actual_lon,
            location_name=location_name,
            matched_weather=WeatherResponse.model_validate(matched_weather) if matched_weather else None,
            recommended_categories=recommended_categories,
            is_live=is_live,
        )
