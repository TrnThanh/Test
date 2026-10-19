from datetime import datetime, timezone
from typing import Optional, List, TYPE_CHECKING
from sqlalchemy import String, Boolean, DateTime, ForeignKey, Integer, UniqueConstraint, func
from sqlalchemy.orm import Mapped, mapped_column, relationship
from server.app.db.base import Base

if TYPE_CHECKING:
    from server.app.models.restaurant import Restaurant
    from server.app.models.dish import Dish
    from server.app.models.weather_category import WeatherCategory
    from server.app.models.weather import Weather


class Category(Base):
    """Bảng nhóm món / danh mục thực đơn (Category) thuộc sở hữu của Quán ăn (Restaurant)."""
    __tablename__ = "categories"
    __table_args__ = (
        UniqueConstraint("restaurant_id", "name", name="uq_restaurant_category_name"),
    )

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    restaurant_id: Mapped[int] = mapped_column(
        ForeignKey("restaurants.id", ondelete="CASCADE"), index=True, nullable=False
    )
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    description: Mapped[Optional[str]] = mapped_column(String(500), nullable=True, default=None)
    display_order: Mapped[int] = mapped_column(Integer, nullable=False, default=0, server_default="0")
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True, server_default="true")
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        server_default=func.now(),
        nullable=False,
    )

    restaurant: Mapped["Restaurant"] = relationship("Restaurant", back_populates="categories")
    dishes: Mapped[List["Dish"]] = relationship(
        "Dish", back_populates="category_rel", passive_deletes=True
    )
    weather_categories: Mapped[List["WeatherCategory"]] = relationship(
        "WeatherCategory", back_populates="category", cascade="all, delete-orphan", passive_deletes=True
    )
    weathers: Mapped[List["Weather"]] = relationship(
        "Weather", secondary="weather_categories", viewonly=True
    )
