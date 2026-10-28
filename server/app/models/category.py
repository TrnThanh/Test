from datetime import datetime, timezone
from typing import Optional, List, TYPE_CHECKING
from sqlalchemy import String, Boolean, DateTime, Integer, Index, text, func, Column
from sqlmodel import Field, Relationship
from server.app.db.base import Base

if TYPE_CHECKING:
    from server.app.models.dish import Dish
    from server.app.models.weather_category import WeatherCategory
    from server.app.models.weather import Weather


# Model danh mục thực đơn món ăn toàn cục
class Category(Base, table=True):
    """Bảng nhóm món / danh mục thực đơn (Category) toàn cục (Master Catalog) dùng chung hệ thống."""
    __tablename__ = "categories"
    __table_args__ = (
        Index("uq_categories_name_lower", text("lower(name)"), unique=True),
    )

    id: Optional[int] = Field(default=None, primary_key=True)
    name: str = Field(sa_type=String(100), nullable=False)
    description: Optional[str] = Field(default=None, sa_type=String(500), nullable=True)
    display_order: int = Field(default=0, sa_column=Column(Integer, nullable=False, default=0, server_default="0"))
    is_active: bool = Field(default=True, sa_column=Column(Boolean, nullable=False, default=True, server_default="true"))
    created_at: datetime = Field(
        default_factory=lambda: datetime.now(timezone.utc),
        sa_column=Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), server_default=func.now(), nullable=False),
    )

    # --- CÁC QUAN HỆ ORM (RELATIONSHIPS) ---
    # Danh sách các món ăn thuộc danh mục này (Quan hệ 1-N: 1 Category -> Nhiều Dishes)
    # passive_deletes=True: khi xóa danh mục, để CSDL PostgreSQL tự SET NULL category_id của món ăn, code Python không can thiệp thừa
    dishes: List["Dish"] = Relationship(
        back_populates="parent_category",
        sa_relationship_kwargs={"passive_deletes": True},
    )

    # Quan hệ N-N với Weather thông qua bảng trung gian WeatherCategory
    weather_categories: List["WeatherCategory"] = Relationship(
        back_populates="category",
        sa_relationship_kwargs={"cascade": "all, delete-orphan", "passive_deletes": True},
    )

    # Danh sách các loại thời tiết liên kết với danh mục này (Đọc trực tiếp qua secondary, chỉ xem - viewonly)
    weathers: List["Weather"] = Relationship(
        sa_relationship_kwargs={"secondary": "weather_categories", "viewonly": True},
    )
