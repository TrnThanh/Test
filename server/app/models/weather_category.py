from datetime import datetime, timezone
from typing import TYPE_CHECKING
from sqlalchemy import DateTime, ForeignKey, UniqueConstraint, func
from sqlalchemy.orm import Mapped, mapped_column, relationship
from server.app.db.base import Base

if TYPE_CHECKING:
    from server.app.models.weather import Weather
    from server.app.models.category import Category


class WeatherCategory(Base):
    """Bảng trung gian liên kết Nhiều-Nhiều (N-N) giữa Weather và Category."""
    __tablename__ = "weather_categories"
    __table_args__ = (
        UniqueConstraint("weather_id", "category_id", name="uq_weather_category"),
    )

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    weather_id: Mapped[int] = mapped_column(
        ForeignKey("weather.id", ondelete="CASCADE"), index=True, nullable=False
    )
    category_id: Mapped[int] = mapped_column(
        ForeignKey("categories.id", ondelete="CASCADE"), index=True, nullable=False
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        server_default=func.now(),
        nullable=False,
    )

    weather: Mapped["Weather"] = relationship("Weather", back_populates="weather_categories")
    category: Mapped["Category"] = relationship("Category", back_populates="weather_categories")
