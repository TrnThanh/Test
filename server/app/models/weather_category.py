from datetime import datetime, timezone
from typing import Optional, TYPE_CHECKING
from sqlalchemy import DateTime, ForeignKey, UniqueConstraint, func, Column
from sqlmodel import Field, Relationship
from server.app.db.base import Base

if TYPE_CHECKING:
    from server.app.models.weather import Weather
    from server.app.models.category import Category


# Model liên kết nhiều-nhiều giữa thời tiết và danh mục món ăn
class WeatherCategory(Base, table=True):
    """Bảng trung gian liên kết Nhiều-Nhiều (N-N) giữa Weather và Category."""
    __tablename__ = "weather_categories"
    __table_args__ = (
        UniqueConstraint("weather_id", "category_id", name="uq_weather_category"),
    )

    id: Optional[int] = Field(default=None, primary_key=True)
    weather_id: int = Field(sa_column=Column(ForeignKey("weather.id", ondelete="CASCADE"), index=True, nullable=False))
    category_id: int = Field(sa_column=Column(ForeignKey("categories.id", ondelete="CASCADE"), index=True, nullable=False))
    created_at: datetime = Field(
        default_factory=lambda: datetime.now(timezone.utc),
        sa_column=Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), server_default=func.now(), nullable=False),
    )

    # --- CÁC QUAN HỆ ORM (RELATIONSHIPS) ---
    # Điều kiện thời tiết tham gia liên kết (Quan hệ N-1)
    weather: Optional["Weather"] = Relationship(back_populates="weather_categories")

    # Danh mục món ăn tham gia liên kết (Quan hệ N-1)
    category: Optional["Category"] = Relationship(back_populates="weather_categories")
