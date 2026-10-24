from datetime import datetime, timezone
from typing import Optional, List, TYPE_CHECKING
from sqlalchemy import String, Float, Boolean, DateTime, ForeignKey, Index, CheckConstraint, Text, text, SmallInteger, Integer
from sqlalchemy.dialects.postgresql import ARRAY
from sqlalchemy.orm import Mapped, mapped_column, relationship
from server.app.db.base import Base

if TYPE_CHECKING:
    from server.app.models.restaurant import Restaurant
    from server.app.models.favourite_dish import FavouriteDish
    from server.app.models.category import Category


class Dish(Base):
    """Bảng món ăn (Dish) thuộc sở hữu của Quán ăn (Restaurant)."""
    __tablename__ = "dishes"
    __table_args__ = (
        CheckConstraint("price >= 0", name="ck_dish_price"),
        CheckConstraint("spicy_level >= 0 AND spicy_level <= 3", name="ck_dishes_spicy_level"),
        CheckConstraint("calories IS NULL OR calories >= 0", name="ck_dishes_calories_non_negative"),
        Index("ix_dishes_restaurant_category", "restaurant_id", "category"),
        Index("ix_dishes_ingredients_gin", "ingredients", postgresql_using="gin"),
        Index("ix_dishes_dietary_tags_gin", "dietary_tags", postgresql_using="gin"),
        Index("ix_dishes_meal_types_gin", "meal_types", postgresql_using="gin"),
        Index("ix_dishes_allergens_gin", "allergens", postgresql_using="gin"),
    )

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    restaurant_id: Mapped[int] = mapped_column(
        ForeignKey("restaurants.id", ondelete="CASCADE"), index=True, nullable=False
    )
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    price: Mapped[float] = mapped_column(Float, nullable=False)
    calories: Mapped[Optional[int]] = mapped_column(Integer, nullable=True, default=None)
    description: Mapped[Optional[str]] = mapped_column(String(1000), nullable=True, default=None)
    image_url: Mapped[Optional[str]] = mapped_column(String(1000), nullable=True, default=None)
    category_id: Mapped[Optional[int]] = mapped_column(
        ForeignKey("categories.id", ondelete="SET NULL"), nullable=True, index=True
    )
    category: Mapped[Optional[str]] = mapped_column(String(100), nullable=True, default=None, index=True)
    spicy_level: Mapped[int] = mapped_column(
        SmallInteger, nullable=False, default=0, server_default="0"
    )
    dietary_tags: Mapped[List[str]] = mapped_column(
        ARRAY(Text), nullable=False, default=list, server_default=text("'{}'::text[]")
    )
    meal_types: Mapped[List[str]] = mapped_column(
        ARRAY(Text), nullable=False, default=list, server_default=text("'{}'::text[]")
    )
    allergens: Mapped[List[str]] = mapped_column(
        ARRAY(Text), nullable=False, default=list, server_default=text("'{}'::text[]")
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
    favourite_users: Mapped[List["FavouriteDish"]] = relationship(
        "FavouriteDish", back_populates="dish", cascade="all, delete-orphan"
    )
