from datetime import datetime, timezone
from typing import Optional, TYPE_CHECKING
from sqlalchemy import Boolean, DateTime, ForeignKey, func, text
from sqlalchemy.orm import Mapped, mapped_column, relationship
from server.app.db.base import Base

if TYPE_CHECKING:
    from server.app.models.user import User
    from server.app.models.category import Category


class OptionUser(Base):
    """Bảng lưu tùy chọn ẩn/hiện danh mục của người dùng (User Category Options / Preferences)."""
    __tablename__ = "option_users"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False
    )
    category_id: Mapped[int] = mapped_column(
        ForeignKey("categories.id", ondelete="CASCADE"), index=True, nullable=False
    )
    hide: Mapped[bool] = mapped_column(
        Boolean, default=True, server_default=text("true"), nullable=False
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        server_default=func.now(),
        nullable=False,
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
        server_default=func.now(),
        nullable=False,
    )

    user: Mapped["User"] = relationship("User", back_populates="options")
    category: Mapped["Category"] = relationship("Category")
