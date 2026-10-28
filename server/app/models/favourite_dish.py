from datetime import datetime, timezone
from typing import Optional, TYPE_CHECKING
from sqlalchemy import DateTime, ForeignKey, UniqueConstraint, Column
from sqlmodel import Field, Relationship
from server.app.db.base import Base

if TYPE_CHECKING:
    from server.app.models.user import User
    from server.app.models.dish import Dish


# Model món ăn ưa thích của người dùng
class FavouriteDish(Base, table=True):
    """Bảng món ăn yêu thích của người dùng (Junction table thuần tuý user_id - dish_id)."""
    __tablename__ = "favourite_dishes"
    __table_args__ = (
        UniqueConstraint("user_id", "dish_id", name="uq_user_favourite_dish"),
    )

    id: Optional[int] = Field(default=None, primary_key=True)
    user_id: int = Field(sa_column=Column(ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False))
    dish_id: int = Field(sa_column=Column(ForeignKey("dishes.id", ondelete="CASCADE"), index=True, nullable=False))
    created_at: datetime = Field(
        default_factory=lambda: datetime.now(timezone.utc),
        sa_column=Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False),
    )

    # --- CÁC QUAN HỆ ORM (RELATIONSHIPS) ---
    # Người dùng đã yêu thích món ăn (Quan hệ N-1)
    user: Optional["User"] = Relationship()

    # Món ăn được yêu thích (Quan hệ N-1, nối ngược với Dish.favourite_users)
    dish: Optional["Dish"] = Relationship(back_populates="favourite_users")
