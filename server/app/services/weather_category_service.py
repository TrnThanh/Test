from typing import List, Optional
from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from server.app.models.weather import Weather
from server.app.models.category import Category
from server.app.models.weather_category import WeatherCategory


class WeatherCategoryService:
    @staticmethod
    def link_weather_category(db: Session, weather_id: int, category_id: int) -> WeatherCategory:
        """Thiết lập liên kết giữa Weather và Category (Idempotent)."""
        # Kiểm tra tồn tại của Weather
        weather = db.get(Weather, weather_id)
        if not weather:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Không tìm thấy trạng thái thời tiết với ID {weather_id}",
            )

        # Kiểm tra tồn tại của Category
        category = db.get(Category, category_id)
        if not category:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Không tìm thấy danh mục món ăn với ID {category_id}",
            )

        # Kiểm tra xem đã tồn tại liên kết chưa (idempotent)
        stmt = select(WeatherCategory).where(
            WeatherCategory.weather_id == weather_id,
            WeatherCategory.category_id == category_id,
        )
        existing = db.execute(stmt).scalar_one_or_none()
        if existing:
            return existing

        # Tạo mới liên kết
        wc = WeatherCategory(weather_id=weather_id, category_id=category_id)
        db.add(wc)
        try:
            db.commit()
            db.refresh(wc)
            return wc
        except IntegrityError:
            db.rollback()
            existing = db.execute(stmt).scalar_one_or_none()
            if existing:
                return existing
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Không thể tạo liên kết giữa thời tiết và danh mục",
            )

    @staticmethod
    def unlink_weather_category(db: Session, weather_id: int, category_id: int) -> bool:
        """Hủy liên kết giữa Weather và Category."""
        stmt = select(WeatherCategory).where(
            WeatherCategory.weather_id == weather_id,
            WeatherCategory.category_id == category_id,
        )
        wc = db.execute(stmt).scalar_one_or_none()
        if not wc:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Không tìm thấy liên kết giữa thời tiết ID {weather_id} và danh mục ID {category_id}",
            )

        db.delete(wc)
        db.commit()
        return True

    @staticmethod
    def get_categories_by_weather(db: Session, weather_id: int) -> List[Category]:
        """Lấy danh sách các Category được liên kết với một trạng thái thời tiết."""
        weather = db.get(Weather, weather_id)
        if not weather:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Không tìm thấy trạng thái thời tiết với ID {weather_id}",
            )

        stmt = (
            select(Category)
            .join(WeatherCategory, WeatherCategory.category_id == Category.id)
            .where(WeatherCategory.weather_id == weather_id)
            .order_by(Category.display_order, Category.id)
        )
        return list(db.execute(stmt).scalars().all())

    @staticmethod
    def get_weathers_by_category(db: Session, category_id: int) -> List[Weather]:
        """Lấy danh sách các Weather được liên kết với một danh mục món ăn."""
        category = db.get(Category, category_id)
        if not category:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Không tìm thấy danh mục món ăn với ID {category_id}",
            )

        stmt = (
            select(Weather)
            .join(WeatherCategory, WeatherCategory.weather_id == Weather.id)
            .where(WeatherCategory.category_id == category_id)
            .order_by(Weather.sort_order, Weather.id)
        )
        return list(db.execute(stmt).scalars().all())

    @staticmethod
    def get_all_links(
        db: Session,
        weather_id: Optional[int] = None,
        category_id: Optional[int] = None,
        skip: int = 0,
        limit: int = 100,
    ) -> List[WeatherCategory]:
        """Truy vấn danh sách các bản ghi liên kết có hỗ trợ bộ lọc."""
        stmt = select(WeatherCategory)
        if weather_id is not None:
            stmt = stmt.where(WeatherCategory.weather_id == weather_id)
        if category_id is not None:
            stmt = stmt.where(WeatherCategory.category_id == category_id)

        stmt = stmt.order_by(WeatherCategory.id.desc()).offset(skip).limit(limit)
        return list(db.execute(stmt).scalars().all())
