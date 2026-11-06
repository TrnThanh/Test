from datetime import datetime, timezone
from typing import Optional, List, TYPE_CHECKING
from sqlalchemy import String, Boolean, DateTime, Integer, Column, func, ForeignKey, UniqueConstraint, Text
from sqlmodel import Field, Relationship
from server.app.db.base import Base

if TYPE_CHECKING:
    from server.app.models.dish import Dish
    from server.app.models.ingredient_group import IngredientGroup


class DishIngredient(Base, table=True):
    """Bảng trung gian liên kết Nhiều-Nhiều giữa Món ăn (Dish) và Nguyên liệu (Ingredient)."""
    __tablename__ = "dish_ingredients"
    __table_args__ = (
        UniqueConstraint("dish_id", "ingredient_id", name="uq_dish_ingredient"),
    )

    id: Optional[int] = Field(default=None, primary_key=True)
    dish_id: int = Field(
        sa_column=Column(ForeignKey("dishes.id", ondelete="CASCADE"), index=True, nullable=False),
    )
    ingredient_id: int = Field(
        sa_column=Column(ForeignKey("ingredients.id", ondelete="CASCADE"), index=True, nullable=False),
    )
    created_at: datetime = Field(
        default_factory=lambda: datetime.now(timezone.utc),
        sa_column=Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), server_default=func.now(), nullable=False),
    )

    # Relationships
    dish: Optional["Dish"] = Relationship(back_populates="dish_ingredients")
    ingredient: Optional["Ingredient"] = Relationship(back_populates="dish_ingredients")


class Ingredient(Base, table=True):
    """Bảng danh mục nguyên liệu thực phẩm toàn cục (Master Ingredients Catalog)."""
    __tablename__ = "ingredients"

    id: Optional[int] = Field(default=None, primary_key=True)
    name: str = Field(sa_type=String(100), unique=True, index=True, nullable=False)
    description: Optional[str] = Field(default=None, sa_type=Text, nullable=True)
    group_id: Optional[int] = Field(
        default=None,
        sa_column=Column(ForeignKey("ingredient_groups.id", ondelete="SET NULL"), index=True, nullable=True),
    )
    allergen_group: Optional[str] = Field(
        default=None,
        sa_column=Column(String(100), index=True, nullable=True),
    )
    is_active: bool = Field(default=True, sa_column=Column(Boolean, default=True, nullable=False))
    created_at: datetime = Field(
        default_factory=lambda: datetime.now(timezone.utc),
        sa_column=Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), server_default=func.now(), nullable=False),
    )

    # Quan hệ với IngredientGroup
    group: Optional["IngredientGroup"] = Relationship(back_populates="ingredients")

    # Quan hệ 1-N với DishIngredient
    dish_ingredients: List["DishIngredient"] = Relationship(
        back_populates="ingredient",
        sa_relationship_kwargs={"cascade": "all, delete-orphan", "passive_deletes": True},
    )

    # Danh sách các món ăn sử dụng nguyên liệu này (viewonly secondary)
    dishes: List["Dish"] = Relationship(
        sa_relationship_kwargs={"secondary": "dish_ingredients", "viewonly": True},
    )
