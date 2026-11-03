from datetime import datetime, timezone
from typing import Optional, List, TYPE_CHECKING
from sqlalchemy import String, Float, Boolean, DateTime, ForeignKey, Index, CheckConstraint, Text, text, SmallInteger, Integer, Column
from sqlalchemy.dialects.postgresql import ARRAY
from sqlmodel import Field, Relationship
from server.app.db.base import Base

if TYPE_CHECKING:
    from server.app.models.restaurant import Restaurant
    from server.app.models.favourite_dish import FavouriteDish
    from server.app.models.category import Category
    from server.app.models.ingredient import DishIngredient, Ingredient


# Model món ăn thuộc quán ăn
class Dish(Base, table=True):
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

    id: Optional[int] = Field(default=None, primary_key=True)
    restaurant_id: int = Field(sa_column=Column(ForeignKey("restaurants.id", ondelete="CASCADE"), index=True, nullable=False))
    name: str = Field(sa_type=String(255), nullable=False)
    price: float = Field(sa_type=Float, nullable=False)
    calories: Optional[int] = Field(default=None, sa_type=Integer, nullable=True)
    description: Optional[str] = Field(default=None, sa_type=String(1000), nullable=True)
    image_url: Optional[str] = Field(default=None, sa_type=String(1000), nullable=True)

    # Khóa ngoại trỏ sang ID danh mục trong bảng categories (NULL nếu món chưa phân danh mục)
    category_id: Optional[int] = Field(
        default=None,
        sa_column=Column(ForeignKey("categories.id", ondelete="SET NULL"), nullable=True, index=True),
    )
    # Tên danh mục dạng chuỗi text (dùng cho nhóm món tự do hoặc tương thích ngược)
    category: Optional[str] = Field(default=None, sa_column=Column(String(100), nullable=True, index=True))

    spicy_level: int = Field(
        default=0,
        sa_column=Column(SmallInteger, nullable=False, default=0, server_default="0"),
    )
    dietary_tags: List[str] = Field(
        default_factory=list,
        sa_column=Column(ARRAY(Text), nullable=False, server_default=text("'{}'::text[]")),
    )
    meal_types: List[str] = Field(
        default_factory=list,
        sa_column=Column(ARRAY(Text), nullable=False, server_default=text("'{}'::text[]")),
    )
    allergens: List[str] = Field(
        default_factory=list,
        sa_column=Column(ARRAY(Text), nullable=False, server_default=text("'{}'::text[]")),
    )
    ingredients: List[str] = Field(
        default_factory=list,
        sa_column=Column(ARRAY(Text), nullable=False, server_default=text("'{}'::text[]")),
    )
    is_available: bool = Field(default=True, sa_column=Column(Boolean, default=True, nullable=False))
    created_at: datetime = Field(
        default_factory=lambda: datetime.now(timezone.utc),
        sa_column=Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False),
    )

    # --- CÁC QUAN HỆ ORM (RELATIONSHIPS) ---
    # Quán ăn (Restaurant) sở hữu món này (Quan hệ N-1)
    restaurant: Optional["Restaurant"] = Relationship(back_populates="dishes")

    # Danh mục cha (Category) sở hữu món này (Quan hệ N-1, khác với cột text `category`)
    parent_category: Optional["Category"] = Relationship(back_populates="dishes")

    # Danh sách bản ghi đánh dấu yêu thích của người dùng đối với món ăn này (Bảng trung gian favourite_dishes)
    favourite_users: List["FavouriteDish"] = Relationship(
        back_populates="dish",
        sa_relationship_kwargs={"cascade": "all, delete-orphan"},
    )

    # Danh sách liên kết nguyên liệu (Bảng trung gian dish_ingredients)
    dish_ingredients: List["DishIngredient"] = Relationship(
        back_populates="dish",
        sa_relationship_kwargs={"cascade": "all, delete-orphan", "passive_deletes": True},
    )

    # Danh sách các nguyên liệu của món ăn (đọc qua secondary, chỉ xem)
    ingredient_items: List["Ingredient"] = Relationship(
        sa_relationship_kwargs={"secondary": "dish_ingredients", "viewonly": True},
    )
