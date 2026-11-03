from datetime import datetime, timezone
from typing import Optional, List, TYPE_CHECKING
from sqlalchemy import String, Boolean, DateTime, Integer, Column, func, CheckConstraint
from sqlmodel import Field, Relationship
from server.app.db.base import Base

if TYPE_CHECKING:
    from server.app.models.weather import Weather


class Season(Base, table=True):
    """Bảng 4 mùa chuẩn hóa (Spring, Summer, Autumn, Winter) phục vụ phân loại và gợi ý thời tiết."""
    __tablename__ = "seasons"
    __table_args__ = (
        CheckConstraint("id >= 1 AND id <= 4", name="ck_seasons_id"),
    )

    id: Optional[int] = Field(default=None, primary_key=True)
    code: str = Field(sa_type=String(20), unique=True, index=True, nullable=False)
    name: str = Field(sa_type=String(50), nullable=False)
    description: Optional[str] = Field(default=None, sa_type=String(255), nullable=True)
    sort_order: int = Field(default=0, sa_column=Column(Integer, nullable=False, default=0, server_default="0"))
    is_active: bool = Field(default=True, sa_column=Column(Boolean, nullable=False, default=True, server_default="true"))
    created_at: datetime = Field(
        default_factory=lambda: datetime.now(timezone.utc),
        sa_column=Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), server_default=func.now(), nullable=False),
    )

    # Quan hệ 1-N: 1 Mùa liên kết nhiều bản ghi Weather
    weathers: List["Weather"] = Relationship(
        back_populates="season_ref",
        sa_relationship_kwargs={"passive_deletes": True},
    )
