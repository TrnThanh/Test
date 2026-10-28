from datetime import datetime, timezone
from typing import Optional, TYPE_CHECKING
from sqlalchemy import Boolean, DateTime, ForeignKey, func, text, Column
from sqlmodel import Field, Relationship
from server.app.db.base import Base

if TYPE_CHECKING:
    from server.app.models.user import User
    from server.app.models.category import Category


# Model tùy chọn ẩn hiện danh mục của người dùng
class OptionUser(Base, table=True):
    """Bảng lưu tùy chọn ẩn/hiện danh mục của người dùng (User Category Options / Preferences)."""
    __tablename__ = "option_users"

    id: Optional[int] = Field(default=None, primary_key=True)
    user_id: int = Field(
        sa_column=Column(ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False),
    )
    category_id: int = Field(
        sa_column=Column(ForeignKey("categories.id", ondelete="CASCADE"), index=True, nullable=False),
    )
    hide: bool = Field(
        default=True,
        sa_column=Column(Boolean, default=True, server_default=text("true"), nullable=False),
    )
    created_at: datetime = Field(
        default_factory=lambda: datetime.now(timezone.utc),
        sa_column=Column(
            DateTime(timezone=True),
            default=lambda: datetime.now(timezone.utc),
            server_default=func.now(),
            nullable=False,
        ),
    )
    updated_at: datetime = Field(
        default_factory=lambda: datetime.now(timezone.utc),
        sa_column=Column(
            DateTime(timezone=True),
            default=lambda: datetime.now(timezone.utc),
            onupdate=lambda: datetime.now(timezone.utc),
            server_default=func.now(),
            nullable=False,
        ),
    )

    # --- CÁC QUAN HỆ ORM (RELATIONSHIPS) ---
    # Người dùng sở hữu tùy chọn này (Quan hệ N-1: Nhiều OptionUser -> 1 User)
    user: Optional["User"] = Relationship(back_populates="options")

    # Danh mục được cấu hình ẩn/hiện (Quan hệ N-1: Nhiều OptionUser -> 1 Category)
    category: Optional["Category"] = Relationship()
