import json
import logging
from datetime import datetime, timezone
from pathlib import Path
from typing import List, Optional
import httpx
from sqlalchemy import select, text, func, delete
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
        "temperature": 35.0,
        "humidity": 65.0,
        "condition": "sunny",
        "icon": "weather-sunny",
        "season": "summer",
        "sort_order": 1,
    },
    {
        "code": "rainy",
        "name": "Trời mưa ẩm ướt",
        "description": "Mưa rào hoặc mưa dầm, thích hợp ăn đồ nóng hổi, lẩu, đồ chiên rán.",
        "temperature": 24.0,
        "humidity": 85.0,
        "condition": "rainy",
        "icon": "weather-rainy",
        "season": "rainy",
        "sort_order": 2,
    },
    {
        "code": "cold",
        "name": "Trời lạnh gió rét",
        "description": "Nhiệt độ thấp mùa đông, lý tưởng cho món nướng, lẩu, phở bò nóng.",
        "temperature": 12.0,
        "humidity": 70.0,
        "condition": "cloudy",
        "icon": "weather-snowy",
        "season": "winter",
        "sort_order": 3,
    },
    {
        "code": "mild",
        "name": "Mát mẻ dễ chịu",
        "description": "Thời tiết đẹp, phù hợp với hầu hết các món ăn đặc sắc.",
        "temperature": 24.0,
        "humidity": 60.0,
        "condition": "clear",
        "icon": "weather-partly-cloudy",
        "season": "autumn",
        "sort_order": 4,
    },
]


class WeatherService:
    @staticmethod
    def seed_default_weathers(db: Session) -> List[Weather]:
        """(Deprecated) Đã thay thế hoàn toàn bằng nạp mẫu thời tiết chuẩn."""
        # Tự động dọn sạch các mã thời tiết cũ nếu có
        db.execute(text("DELETE FROM weather WHERE code IN ('hot', 'rainy', 'cold', 'mild');"))
        db.commit()
        return []

    @staticmethod
    def get_weather_flat_json_path() -> Path:
        """Lấy đường dẫn tệp JSON chứa 96,000 mẫu thời tiết phẳng theo giờ (không chứa date)."""
        root_json = Path(__file__).resolve().parents[3] / "weather_4000_mau_so_flat_hourly.json"
        if root_json.exists():
            return root_json
        scripts_json = Path(__file__).resolve().parents[3] / "scripts" / "weather_4000_mau_so_flat_hourly.json"
        if scripts_json.exists():
            return scripts_json
        return WeatherService.get_weather_json_path()

    @staticmethod
    def get_weather_json_path() -> Path:
        """Lấy đường dẫn tệp JSON chứa mẫu thời tiết theo mùa."""
        json_4000 = Path(__file__).resolve().parents[3] / "scripts" / "weather_4000_mau_so_2000_2025.json"
        if json_4000.exists():
            return json_4000
        root_json = Path(__file__).resolve().parents[3] / "weather_4000_mau_so_2000_2025.json"
        if root_json.exists():
            return root_json
        return Path(__file__).resolve().parents[3] / "scripts" / "weather_400_mau_so_2000_2025.json"

    @staticmethod
    def seed_weather_patterns(db: Session, force: bool = False) -> int:
        """Tự động dọn dẹp các mẫu cũ và nạp/ghi đè 96,000 mẫu thời tiết phẳng (bỏ cột date, chỉ lấy hour) vào bảng weather."""
        from server.app.models.seed_meta import SeedMeta
        from server.app.models.weather_category import WeatherCategory

        json_file = WeatherService.get_weather_flat_json_path()
        if not json_file.exists():
            logger.warning("[WeatherSeed] Không tìm thấy tệp JSON thời tiết tại: %s", json_file)
            return 0

        # 1. Luôn tự động dọn sạch các bản ghi thời tiết cũ (hot, rainy, cold, mild hoặc mẫu cũ chưa có định dạng _H)
        db.execute(text("DELETE FROM weather WHERE code IN ('hot', 'rainy', 'cold', 'mild') OR (code LIKE '%_PATTERN_%' AND code NOT LIKE '%_H__');"))

        seed_key = "weather_96000_flat_patterns_v1"
        existing_meta = db.get(SeedMeta, seed_key)
        pattern_count = db.scalar(select(func.count(Weather.id)).where(Weather.code.like("%_PATTERN_%"))) or 0

        # Nếu đã có đủ 96000 mẫu và đã ghi nhận seed_key thì bỏ qua trừ khi force
        if not force and existing_meta and pattern_count == 96000:
            db.commit()
            return 0

        try:
            with open(json_file, "r", encoding="utf-8") as f:
                patterns: List[dict] = json.load(f)
        except Exception as e:
            logger.error("[WeatherSeed] Lỗi khi đọc tệp %s: %s", json_file, e)
            return 0

        # Nạp theo lô 2000 bản ghi bằng Bulk Upsert PostgreSQL ON CONFLICT (code) DO UPDATE (tránh quá 65535 params)
        upserted_count = 0
        batch_size = 2000
        for i in range(0, len(patterns), batch_size):
            batch = patterns[i : i + batch_size]
            clean_batch = []
            for item in batch:
                # Xử lý parse created_at
                raw_created = item.get("created_at")
                if isinstance(raw_created, str):
                    try:
                        c_at = datetime.strptime(raw_created, "%Y-%m-%d %H:%M:%S").replace(tzinfo=timezone.utc)
                    except Exception:
                        c_at = datetime.now(timezone.utc)
                elif isinstance(raw_created, datetime):
                    c_at = raw_created
                else:
                    c_at = datetime.now(timezone.utc)

                pat_code = item.get("pattern_code") or item.get("code")
                h = item.get("hour")
                # Chuẩn hóa code: nếu có hour thì code = f"{pat_code}_H{int(h):02d}", ngược lại dùng code sẵn có
                if h is not None and pat_code:
                    c_code = f"{pat_code}_H{int(h):02d}"
                else:
                    c_code = item.get("code") or pat_code

                clean_batch.append({
                    "id": item.get("id"),
                    "code": c_code,
                    "pattern_code": pat_code,
                    "hour": int(h) if h is not None else None,
                    "name": item["name"],
                    "description": item.get("description"),
                    "temperature": item.get("temperature"),
                    "humidity": item.get("humidity"),
                    "precipitation": float(item.get("precipitation") or 0.0),
                    "weather_code": int(item.get("weather_code") or 0),
                    "condition": item.get("condition"),
                    "icon": item.get("icon"),
                    "season": item.get("season"),
                    "hourly": item.get("hourly") or [],
                    "sort_order": item.get("sort_order", 0),
                    "is_active": item.get("is_active", True),
                    "created_at": c_at,
                })

            stmt = pg_insert(Weather).values(clean_batch)
            stmt = stmt.on_conflict_do_update(
                index_elements=[Weather.code],
                set_={
                    "pattern_code": stmt.excluded.pattern_code,
                    "hour": stmt.excluded.hour,
                    "name": stmt.excluded.name,
                    "description": stmt.excluded.description,
                    "temperature": stmt.excluded.temperature,
                    "humidity": stmt.excluded.humidity,
                    "precipitation": stmt.excluded.precipitation,
                    "weather_code": stmt.excluded.weather_code,
                    "condition": stmt.excluded.condition,
                    "icon": stmt.excluded.icon,
                    "season": stmt.excluded.season,
                    "hourly": stmt.excluded.hourly,
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

        # Tự động nạp liên kết weather_categories nếu chưa có
        WeatherService.seed_weather_categories_if_needed(db)

        db.commit()
        logger.info("[WeatherSeed] Đã tự động nạp và ghi đè thành công %s mẫu thời tiết chuẩn vào database (không dùng cột date).", upserted_count)
        return upserted_count

    @staticmethod
    def seed_weather_categories_if_needed(db: Session) -> int:
        """Đồng bộ liên kết danh mục món ăn gợi ý theo mùa cho bảng weather_categories."""
        count = db.scalar(select(func.count()).select_from(text("weather_categories"))) or 0
        if count > 0:
            return 0
        sql = """
        INSERT INTO weather_categories (weather_id, category_id, created_at)
        SELECT w.id, c.id, NOW()
        FROM weather w
        JOIN categories c ON (
            (w.season = 'winter' AND c.name IN ('Lẩu & Nướng', 'Phở, Bún & Món nước', 'Cơm & Xôi')) OR
            (w.season = 'summer' AND c.name IN ('Cà phê & Thức uống giải khát', 'Đồ ăn vặt', 'Ẩm thực Chay & Thực dưỡng')) OR
            (w.season = 'autumn' AND c.name IN ('Cà phê & Thức uống giải khát', 'Phở, Bún & Món nước', 'Bánh mì')) OR
            (w.season = 'spring' AND c.name IN ('Bánh mì', 'Phở, Bún & Món nước', 'Cơm & Xôi'))
        )
        ON CONFLICT (weather_id, category_id) DO NOTHING;
        """
        res = db.execute(text(sql))
        db.commit()
        return res.rowcount

    @staticmethod
    def seed_4000_weather_patterns(db: Session, force: bool = False) -> int:
        """Chuyển tiếp tới seed_weather_patterns để tương thích ngược 100%."""
        return WeatherService.seed_weather_patterns(db, force=force)

    @staticmethod
    def seed_400_weather_patterns(db: Session, force: bool = False) -> int:
        """(Deprecated) Chuyển tiếp tới seed_weather_patterns để tương thích ngược."""
        return WeatherService.seed_weather_patterns(db, force=force)

    @staticmethod
    def get_all_weathers(
        db: Session,
        active_only: bool = True,
        pattern_code: Optional[str] = None,
        hour: Optional[int] = None,
        limit: Optional[int] = None,
        offset: int = 0,
    ) -> List[Weather]:
        """Lấy danh sách các điều kiện thời tiết trong hệ thống."""
        stmt = select(Weather)
        if active_only:
            stmt = stmt.where(Weather.is_active.is_(True))
        if pattern_code:
            stmt = stmt.where(Weather.pattern_code == pattern_code.strip())
        if hour is not None:
            stmt = stmt.where(Weather.hour == hour)
        stmt = stmt.order_by(Weather.sort_order.asc(), Weather.id.asc())
        if limit is not None:
            stmt = stmt.offset(offset).limit(limit)
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
        """Lấy trạng thái thời tiết theo mã định danh (SPRING_PATTERN_0001_H00...)."""
        clean_code = code.strip().upper()
        stmt = select(Weather).where(Weather.code == clean_code)
        res = db.scalar(stmt)
        if not res:
            stmt = select(Weather).where(Weather.code == code.strip().lower())
            res = db.scalar(stmt)
        if not res:
            stmt = select(Weather).where(Weather.pattern_code == clean_code).limit(1)
            res = db.scalar(stmt)
        return res

    @staticmethod
    def create_weather(db: Session, data: WeatherCreate) -> Weather:
        """Tạo mới một trạng thái thời tiết."""
        code_clean = data.code.strip()
        stmt = select(Weather).where(Weather.code == code_clean)
        if db.scalar(stmt):
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"Mã trạng thái thời tiết '{code_clean}' đã tồn tại.",
            )

        if data.temperature is not None and not (-50.0 <= data.temperature <= 60.0):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Nhiệt độ phải nằm trong khoảng -50°C đến 60°C.",
            )
        if data.humidity is not None and not (0.0 <= data.humidity <= 100.0):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Độ ẩm phải nằm trong khoảng 0% đến 100%.",
            )
        if data.hour is not None and not (0 <= data.hour <= 23):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Khung giờ phải nằm trong khoảng 0 đến 23.",
            )

        w = Weather(
            code=code_clean,
            pattern_code=data.pattern_code.strip() if data.pattern_code else None,
            hour=data.hour,
            name=data.name.strip(),
            description=data.description.strip() if data.description else None,
            temperature=data.temperature,
            humidity=data.humidity,
            precipitation=data.precipitation if data.precipitation is not None else 0.0,
            weather_code=data.weather_code if data.weather_code is not None else 0,
            condition=data.condition.strip() if data.condition else None,
            icon=data.icon.strip() if data.icon else None,
            season=data.season.strip() if data.season else None,
            hourly=data.hourly if data.hourly else [],
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

        if w.temperature is not None and not (-50.0 <= w.temperature <= 60.0):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Nhiệt độ phải nằm trong khoảng -50°C đến 60°C.",
            )

        if w.humidity is not None and not (0.0 <= w.humidity <= 100.0):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Độ ẩm phải nằm trong khoảng 0% đến 100%.",
            )

        if w.hour is not None and not (0 <= w.hour <= 23):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Khung giờ phải nằm trong khoảng 0 đến 23.",
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
                    response = await client.get(url, params=params, timeout=5.0)
                else:
                    async with httpx.AsyncClient() as new_client:
                        response = await new_client.get(url, params=params, timeout=5.0)

                if response.status_code == 200:
                    data = response.json()
                    is_live = True
                else:
                    logger.warning("OpenWeatherMap trả về mã lỗi %s, dùng fallback mặc định.", response.status_code)
            except Exception as e:
                logger.warning("Không thể kết nối tới OpenWeatherMap (%s), kích hoạt fallback dự phòng.", e)

        if data and "main" in data:
            temp = float(data["main"]["temp"])
            feels_like = float(data["main"].get("feels_like", temp))
            humidity = int(data["main"].get("humidity", 65))
            w0 = data.get("weather", [{}])[0]
            w_id = w0.get("id", 800)
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

        # Xác định nhóm mùa và tìm mẫu thời tiết trong 96000 mẫu phù hợp nhất
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
            .order_by(func.abs(Weather.temperature - temp))
            .limit(1)
        )
        matched_weather = db.scalars(stmt_pattern).first()
        if not matched_weather:
            matched_weather = db.scalars(
                select(Weather).order_by(func.abs(Weather.temperature - temp)).limit(1)
            ).first()

        if not matched_weather:
            WeatherService.seed_weather_patterns(db)
            matched_weather = db.scalars(stmt_pattern).first() or db.scalars(select(Weather).order_by(Weather.id).limit(1)).first()

        recommended_categories: List[CategoryResponse] = []
        if matched_weather:
            try:
                cats = WeatherCategoryService.get_categories_by_weather(db, matched_weather.id)
                if not cats:
                    from server.app.models.category import Category
                    season_cats = {
                        "winter": ["Lẩu & Nướng", "Phở, Bún & Món nước", "Cơm & Xôi"],
                        "summer": ["Cà phê & Thức uống giải khát", "Đồ ăn vặt", "Ẩm thực Chay & Thực dưỡng"],
                        "autumn": ["Cà phê & Thức uống giải khát", "Phở, Bún & Món nước", "Bánh mì"],
                        "spring": ["Bánh mì", "Phở, Bún & Món nước", "Cơm & Xôi", "Ẩm thực Chay & Thực dưỡng"],
                    }
                    kw = season_cats.get(matched_weather.season, ["Phở, Bún & Món nước", "Cơm & Xôi"])
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
