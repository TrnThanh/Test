from datetime import datetime, timezone, time
from typing import Any, Optional, List, TYPE_CHECKING
from sqlalchemy import String, Float, Boolean, DateTime, Index, CheckConstraint, Computed, Time
from sqlalchemy.orm import Mapped, mapped_column, relationship
from geoalchemy2 import Geography
from server.app.db.base import Base

if TYPE_CHECKING:
    from server.app.models.dish import Dish
    from server.app.models.category import Category


class Restaurant(Base):
    """Bảng quán ăn (Restaurant) với cột không gian PostGIS."""
    __tablename__ = "restaurants"
    __table_args__ = (
        CheckConstraint("latitude >= -90.0 AND latitude <= 90.0", name="ck_restaurant_latitude"),
        CheckConstraint("longitude >= -180.0 AND longitude <= 180.0", name="ck_restaurant_longitude"),
        Index("ix_restaurants_lat_lon", "latitude", "longitude"),
    )

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    address: Mapped[str] = mapped_column(String(500), nullable=False)
    latitude: Mapped[float] = mapped_column(Float, nullable=False)
    longitude: Mapped[float] = mapped_column(Float, nullable=False)
    phone: Mapped[Optional[str]] = mapped_column(String(50), nullable=True, default=None)
    description: Mapped[Optional[str]] = mapped_column(String(1000), nullable=True, default=None)
    open_time: Mapped[Optional[time]] = mapped_column(Time, nullable=True, default=None)
    close_time: Mapped[Optional[time]] = mapped_column(Time, nullable=True, default=None)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
    )

    # Cột không gian PostGIS (Geography POINT WGS84 - SRID 4326), tự động đồng bộ từ longitude/latitude
    location: Mapped[Optional[Any]] = mapped_column(
        Geography(geometry_type="POINT", srid=4326, spatial_index=True),
        Computed(
            "ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography",
            persisted=True,
        ),
        nullable=True,
        deferred=True,
    )

    categories: Mapped[List["Category"]] = relationship(
        "Category", back_populates="restaurant", cascade="all, delete-orphan"
    )
    dishes: Mapped[List["Dish"]] = relationship(
        "Dish", back_populates="restaurant", cascade="all, delete-orphan"
    )
