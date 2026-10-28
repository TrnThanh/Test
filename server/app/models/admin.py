from datetime import datetime, timezone
from typing import Optional
from sqlalchemy import DateTime, String
from sqlmodel import Field
from server.app.db.base import Base


# Model thực thể Quản trị viên (Admin)
class Admin(Base, table=True):
    """Bảng quản trị viên hệ thống (Admin). Khai báo trực tiếp các thuộc tính tài khoản quản trị."""
    __tablename__ = "admins"

    id: Optional[int] = Field(default=None, primary_key=True, index=True)
    email: str = Field(sa_type=String(255), unique=True, index=True, nullable=False)
    hashed_password: str = Field(sa_type=String(255), nullable=False)
    full_name: Optional[str] = Field(default=None, sa_type=String(255), nullable=True)
    is_active: bool = Field(default=True, nullable=False)
    created_at: datetime = Field(
        default_factory=lambda: datetime.now(timezone.utc),
        sa_type=DateTime(timezone=True),
        nullable=False,
    )
