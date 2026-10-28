from datetime import datetime, timezone, time
from typing import Any, Optional, List, TYPE_CHECKING
from sqlalchemy import String, Float, Boolean, DateTime, Index, CheckConstraint, Computed, Time, Text, text, Column
from sqlalchemy.dialects.postgresql import ARRAY
from geoalchemy2 import Geography
from sqlmodel import Field, Relationship
from server.app.db.base import Base

if TYPE_CHECKING:
    from server.app.models.dish import Dish


# Model quán ăn và thông tin địa lý không gian
class Restaurant(Base, table=True):
    """Bảng quán ăn (Restaurant) với cột không gian PostGIS và mảng giấy phép dịch vụ."""
    __tablename__ = "restaurants"
    __table_args__ = (
        CheckConstraint("latitude >= -90.0 AND latitude <= 90.0", name="ck_restaurant_latitude"),
        CheckConstraint("longitude >= -180.0 AND longitude <= 180.0", name="ck_restaurant_longitude"),
        Index("ix_restaurants_lat_lon", "latitude", "longitude"),
        Index("ix_restaurants_is_sponsor", "is_sponsor"),
        Index("ix_restaurants_service_licenses_gin", "service_licenses", postgresql_using="gin"),
    )

    id: Optional[int] = Field(default=None, primary_key=True)
    name: str = Field(sa_type=String(255), nullable=False)
    address: str = Field(sa_type=String(500), nullable=False)
    latitude: float = Field(sa_type=Float, nullable=False)
    longitude: float = Field(sa_type=Float, nullable=False)
    phone: Optional[str] = Field(default=None, sa_type=String(50), nullable=True)
    description: Optional[str] = Field(default=None, sa_type=String(1000), nullable=True)
    open_time: Optional[time] = Field(default=None, sa_type=Time, nullable=True)
    close_time: Optional[time] = Field(default=None, sa_type=Time, nullable=True)
    service_licenses: List[str] = Field(
        default_factory=list,
        sa_column=Column(ARRAY(Text), nullable=False, server_default=text("'{}'::text[]")),
    )
    is_sponsor: bool = Field(default=False, sa_column=Column(Boolean, default=False, server_default="false", nullable=False))
    is_active: bool = Field(default=True, sa_column=Column(Boolean, default=True, nullable=False))
    created_at: datetime = Field(
        default_factory=lambda: datetime.now(timezone.utc),
        sa_column=Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False),
    )

    # Cột không gian PostGIS (Geography POINT WGS84 - SRID 4326), tự động đồng bộ từ longitude/latitude
    location: Optional[Any] = Field(
        default=None,
        sa_column=Column(
            Geography(geometry_type="POINT", srid=4326, spatial_index=True),
            Computed(
                "ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography",
                persisted=True,
            ),
            nullable=True,
        ),
    )

    # --- CÁC QUAN HỆ ORM (RELATIONSHIPS) ---
    # Danh sách các món ăn thuộc sở hữu của quán ăn này (Quan hệ 1-N: 1 Restaurant -> Nhiều Dishes)
    # cascade="all, delete-orphan": Khi xóa quán ăn, toàn bộ món ăn của quán sẽ tự động bị xóa theo
    dishes: List["Dish"] = Relationship(
        back_populates="restaurant",
        sa_relationship_kwargs={"cascade": "all, delete-orphan"},
    )
