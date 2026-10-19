from typing import Optional, List, TYPE_CHECKING
from sqlalchemy.orm import Mapped, relationship
from server.app.db.base import Base
from server.app.models.base import AccountMixin

if TYPE_CHECKING:
    from server.app.models.option_user import OptionUser


class User(AccountMixin, Base):
    """Bảng người dùng thông thường (Customer / User)."""
    __tablename__ = "users"

    options: Mapped[List["OptionUser"]] = relationship(
        "OptionUser",
        back_populates="user",
        cascade="all, delete-orphan",
        passive_deletes=True,
    )
