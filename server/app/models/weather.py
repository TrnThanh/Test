from datetime import datetime, timezone
from typing import Optional
from sqlalchemy import String, Boolean, DateTime, Float, CheckConstraint, Integer, func
from sqlalchemy.orm import Mapped, mapped_column
from server.app.db.base import Base


class Weather(Base):
    """Bảng thông tin thời tiết (Weather) chuẩn bị cho tính năng gợi ý món ăn theo thời tiết."""
    __tablename__ = "weather"
    __table_args__ = (
        CheckConstraint(
            "min_temp IS NULL OR max_temp IS NULL OR min_temp <= max_temp",
            name="ck_weather_temp_range",
        ),
    )

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    code: Mapped[str] = mapped_column(String(30), unique=True, index=True, nullable=False)
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    description: Mapped[Optional[str]] = mapped_column(String(500), nullable=True, default=None)
    min_temp: Mapped[Optional[float]] = mapped_column(Float, nullable=True, default=None)
    max_temp: Mapped[Optional[float]] = mapped_column(Float, nullable=True, default=None)
    condition: Mapped[Optional[str]] = mapped_column(String(50), nullable=True, default=None)
    icon: Mapped[Optional[str]] = mapped_column(String(100), nullable=True, default=None)
    sort_order: Mapped[int] = mapped_column(Integer, nullable=False, default=0, server_default="0")
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True, server_default="true")
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        server_default=func.now(),
        nullable=False,
    )
