from datetime import datetime, timezone
from typing import Optional, List, Dict, Any, TYPE_CHECKING
from sqlalchemy import String, Boolean, DateTime, Float, CheckConstraint, Integer, Text, func, Column, JSON, Index
from sqlalchemy.dialects.postgresql import JSONB
from sqlmodel import Field, Relationship
from server.app.db.base import Base

if TYPE_CHECKING:
    from server.app.models.weather_category import WeatherCategory
    from server.app.models.category import Category


# Model điều kiện thời tiết mở rộng hỗ trợ 96,000 bản ghi chi tiết từng giờ (2000-2025)
class Weather(Base, table=True):
    """Bảng thông tin thời tiết (Weather) phục vụ gợi ý món ăn và theo dõi chi tiết từng giờ (không lưu date)."""
    __tablename__ = "weather"
    __table_args__ = (
        CheckConstraint(
            "temperature IS NULL OR (temperature >= -50.0 AND temperature <= 60.0)",
            name="ck_weather_temperature_valid",
        ),
        CheckConstraint(
            "humidity IS NULL OR (humidity >= 0.0 AND humidity <= 100.0)",
            name="ck_weather_humidity_valid",
        ),
        CheckConstraint(
            "hour IS NULL OR (hour >= 0 AND hour <= 23)",
            name="ck_weather_hour_valid",
        ),
        Index("ix_weather_pattern_hour", "pattern_code", "hour"),
        Index("ix_weather_season_temp", "season", "temperature"),
    )

    id: Optional[int] = Field(default=None, primary_key=True)
    code: str = Field(sa_type=String(60), unique=True, index=True, nullable=False)
    pattern_code: Optional[str] = Field(default=None, sa_type=String(50), index=True, nullable=True)
    hour: Optional[int] = Field(default=None, sa_type=Integer, index=True, nullable=True)
    name: str = Field(sa_type=String(255), nullable=False)
    description: Optional[str] = Field(default=None, sa_type=Text, nullable=True)
    temperature: Optional[float] = Field(default=None, sa_type=Float, nullable=True)
    humidity: Optional[float] = Field(default=None, sa_type=Float, nullable=True)
    precipitation: Optional[float] = Field(default=0.0, sa_type=Float, nullable=True)
    weather_code: Optional[int] = Field(default=0, sa_type=Integer, nullable=True)
    condition: Optional[str] = Field(default=None, sa_type=String(100), nullable=True)
    icon: Optional[str] = Field(default=None, sa_type=String(100), nullable=True)
    season: Optional[str] = Field(default=None, sa_type=String(50), nullable=True, index=True)
    hourly: List[Dict[str, Any]] = Field(
        default_factory=list,
        sa_column=Column(
            JSON().with_variant(JSONB, "postgresql"),
            nullable=False,
            server_default="[]",
        ),
    )
    sort_order: int = Field(default=0, sa_column=Column(Integer, nullable=False, default=0, server_default="0"))
    is_active: bool = Field(default=True, sa_column=Column(Boolean, nullable=False, default=True, server_default="true"))
    created_at: datetime = Field(
        default_factory=lambda: datetime.now(timezone.utc),
        sa_column=Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), server_default=func.now(), nullable=False),
    )

    # --- CÁC QUAN HỆ ORM (RELATIONSHIPS) ---
    # Quan hệ N-N với Category thông qua bảng trung gian WeatherCategory
    weather_categories: List["WeatherCategory"] = Relationship(
        back_populates="weather",
        sa_relationship_kwargs={"cascade": "all, delete-orphan", "passive_deletes": True},
    )

    # Danh sách các danh mục món ăn gợi ý theo thời tiết này (Đọc trực tiếp qua secondary, chỉ xem - viewonly)
    categories: List["Category"] = Relationship(
        sa_relationship_kwargs={"secondary": "weather_categories", "viewonly": True},
    )
