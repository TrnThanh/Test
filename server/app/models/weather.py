from datetime import datetime, timezone
from typing import Optional, List, TYPE_CHECKING
from sqlalchemy import String, Boolean, DateTime, Float, CheckConstraint, Integer, Text, func, Column
from sqlmodel import Field, Relationship
from server.app.db.base import Base

if TYPE_CHECKING:
    from server.app.models.weather_category import WeatherCategory
    from server.app.models.category import Category


# Model điều kiện thời tiết
class Weather(Base, table=True):
    """Bảng thông tin thời tiết (Weather) chuẩn bị cho tính năng gợi ý món ăn theo thời tiết."""
    __tablename__ = "weather"
    __table_args__ = (
        CheckConstraint(
            "min_temp IS NULL OR max_temp IS NULL OR min_temp <= max_temp",
            name="ck_weather_temp_range",
        ),
        CheckConstraint(
            "min_humidity IS NULL OR max_humidity IS NULL OR min_humidity <= max_humidity",
            name="ck_weather_humidity_range",
        ),
        CheckConstraint(
            "(min_humidity IS NULL OR (min_humidity >= 0 AND min_humidity <= 100)) AND (max_humidity IS NULL OR (max_humidity >= 0 AND max_humidity <= 100))",
            name="ck_weather_humidity_valid",
        ),
    )

    id: Optional[int] = Field(default=None, primary_key=True)
    code: str = Field(sa_type=String(50), unique=True, index=True, nullable=False)
    name: str = Field(sa_type=String(255), nullable=False)
    description: Optional[str] = Field(default=None, sa_type=Text, nullable=True)
    min_temp: Optional[float] = Field(default=None, sa_type=Float, nullable=True)
    max_temp: Optional[float] = Field(default=None, sa_type=Float, nullable=True)
    min_humidity: Optional[int] = Field(default=None, sa_column=Column(Integer, nullable=True))
    max_humidity: Optional[int] = Field(default=None, sa_column=Column(Integer, nullable=True))
    condition: Optional[str] = Field(default=None, sa_type=String(100), nullable=True)
    icon: Optional[str] = Field(default=None, sa_type=String(100), nullable=True)
    season: Optional[str] = Field(default=None, sa_type=String(50), nullable=True, index=True)
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
