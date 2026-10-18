from datetime import datetime, timezone
from typing import TYPE_CHECKING
from sqlalchemy import DateTime, ForeignKey, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship
from server.app.db.base import Base

if TYPE_CHECKING:
    from server.app.models.user import User
    from server.app.models.dish import Dish


class FavouriteDish(Base):
    """Bảng món ăn yêu thích của người dùng (Junction table thuần tuý user_id - dish_id)."""
    __tablename__ = "favourite_dishes"
    __table_args__ = (
        UniqueConstraint("user_id", "dish_id", name="uq_user_favourite_dish"),
    )

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False
    )
    dish_id: Mapped[int] = mapped_column(
        ForeignKey("dishes.id", ondelete="CASCADE"), index=True, nullable=False
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
    )

    user: Mapped["User"] = relationship("User")
    dish: Mapped["Dish"] = relationship("Dish", back_populates="favourite_users")
