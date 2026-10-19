from datetime import datetime, timezone, time
from typing import Optional, List, TYPE_CHECKING
from sqlalchemy import String, Boolean, DateTime, Time, Integer, func
from sqlalchemy.orm import Mapped, mapped_column, relationship
from server.app.db.base import Base

if TYPE_CHECKING:
    from server.app.models.dish import Dish


class MealType(Base):
    """Bảng loại bữa ăn (MealType): Sáng, Trưa, Tối, Ăn vặt, Cả ngày..."""
    __tablename__ = "meal_types"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    code: Mapped[str] = mapped_column(String(30), unique=True, index=True, nullable=False)
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    description: Mapped[Optional[str]] = mapped_column(String(500), nullable=True, default=None)
    start_time: Mapped[Optional[time]] = mapped_column(Time, nullable=True, default=None)
    end_time: Mapped[Optional[time]] = mapped_column(Time, nullable=True, default=None)
    sort_order: Mapped[int] = mapped_column(Integer, nullable=False, default=0, server_default="0")
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True, server_default="true")
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        server_default=func.now(),
        nullable=False,
    )

    dishes: Mapped[List["Dish"]] = relationship("Dish", back_populates="meal_type_rel")
