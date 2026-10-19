from datetime import datetime, timezone
from typing import Optional, List, TYPE_CHECKING
from sqlalchemy import String, Float, Boolean, DateTime, ForeignKey, Index, CheckConstraint, Text, text
from sqlalchemy.dialects.postgresql import ARRAY
from sqlalchemy.orm import Mapped, mapped_column, relationship
from server.app.db.base import Base

if TYPE_CHECKING:
    from server.app.models.restaurant import Restaurant
    from server.app.models.favourite_dish import FavouriteDish
    from server.app.models.category import Category
    from server.app.models.meal_type import MealType


class Dish(Base):
    """Bảng món ăn (Dish) thuộc sở hữu của Quán ăn (Restaurant)."""
    __tablename__ = "dishes"
    __table_args__ = (
        CheckConstraint("price >= 0", name="ck_dish_price"),
        CheckConstraint(
            "meal_type IN ('breakfast', 'lunch', 'dinner', 'snack', 'all_day')",
            name="ck_dishes_meal_type",
        ),
        Index("ix_dishes_restaurant_category", "restaurant_id", "category"),
        Index("ix_dishes_ingredients_gin", "ingredients", postgresql_using="gin"),
    )

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    restaurant_id: Mapped[int] = mapped_column(
        ForeignKey("restaurants.id", ondelete="CASCADE"), index=True, nullable=False
    )
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    price: Mapped[float] = mapped_column(Float, nullable=False)
    description: Mapped[Optional[str]] = mapped_column(String(1000), nullable=True, default=None)
    image_url: Mapped[Optional[str]] = mapped_column(String(1000), nullable=True, default=None)
    category_id: Mapped[Optional[int]] = mapped_column(
        ForeignKey("categories.id", ondelete="SET NULL"), nullable=True, index=True
    )
    category: Mapped[Optional[str]] = mapped_column(String(100), nullable=True, default=None, index=True)
    meal_type_id: Mapped[Optional[int]] = mapped_column(
        ForeignKey("meal_types.id", ondelete="SET NULL"), nullable=True, index=True
    )
    meal_type: Mapped[str] = mapped_column(
        String(20), nullable=False, default="all_day", server_default="all_day", index=True
    )
    ingredients: Mapped[List[str]] = mapped_column(
        ARRAY(Text), nullable=False, default=list, server_default=text("'{}'::text[]")
    )
    is_available: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
    )

    restaurant: Mapped["Restaurant"] = relationship("Restaurant", back_populates="dishes")
    category_rel: Mapped[Optional["Category"]] = relationship("Category", back_populates="dishes")
    meal_type_rel: Mapped[Optional["MealType"]] = relationship("MealType", back_populates="dishes")
    favourite_users: Mapped[List["FavouriteDish"]] = relationship(
        "FavouriteDish", back_populates="dish", cascade="all, delete-orphan"
    )
