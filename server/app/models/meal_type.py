from datetime import datetime, timezone, time
from typing import Optional
from sqlalchemy import String, Boolean, DateTime, Time, Integer, func, Column
from sqlmodel import Field
from server.app.db.base import Base


# Model loại bữa ăn trong ngày
class MealType(Base, table=True):
    """Bảng loại bữa ăn (MealType): Sáng, Trưa, Tối, Ăn vặt, Cả ngày..."""
    __tablename__ = "meal_types"

    id: Optional[int] = Field(default=None, primary_key=True)
    code: str = Field(sa_type=String(30), unique=True, index=True, nullable=False)
    name: str = Field(sa_type=String(100), nullable=False)
    description: Optional[str] = Field(default=None, sa_type=String(500), nullable=True)
    start_time: Optional[time] = Field(default=None, sa_type=Time, nullable=True)
    end_time: Optional[time] = Field(default=None, sa_type=Time, nullable=True)
    sort_order: int = Field(default=0, sa_column=Column(Integer, nullable=False, default=0, server_default="0"))
    is_active: bool = Field(default=True, sa_column=Column(Boolean, nullable=False, default=True, server_default="true"))
    created_at: datetime = Field(
        default_factory=lambda: datetime.now(timezone.utc),
        sa_column=Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), server_default=func.now(), nullable=False),
    )
