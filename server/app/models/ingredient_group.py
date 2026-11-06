from datetime import datetime, timezone
from typing import Optional, List, TYPE_CHECKING
from sqlalchemy import String, Boolean, DateTime, Integer, Column, func, Text
from sqlmodel import Field, Relationship
from server.app.db.base import Base

if TYPE_CHECKING:
    from server.app.models.ingredient import Ingredient


class IngredientGroup(Base, table=True):
    """Bảng danh mục Nhóm nguyên liệu thực phẩm (Master Ingredient Groups / Categories)."""
    __tablename__ = "ingredient_groups"

    id: Optional[int] = Field(default=None, primary_key=True)
    name: str = Field(sa_type=String(100), unique=True, index=True, nullable=False)
    description: Optional[str] = Field(default=None, sa_type=Text, nullable=True)
    display_order: int = Field(default=0, sa_column=Column(Integer, default=0, nullable=False))
    is_active: bool = Field(default=True, sa_column=Column(Boolean, default=True, nullable=False))
    created_at: datetime = Field(
        default_factory=lambda: datetime.now(timezone.utc),
        sa_column=Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), server_default=func.now(), nullable=False),
    )

    # Quan hệ 1-N với Ingredient
    ingredients: List["Ingredient"] = Relationship(
        back_populates="group",
        sa_relationship_kwargs={"cascade": "all, delete-orphan", "passive_deletes": True},
    )
