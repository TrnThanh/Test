from datetime import datetime, timezone
from typing import Optional
from sqlalchemy import DateTime, String
from sqlmodel import SQLModel, Field


# Mixin chứa các trường tài khoản người dùng và quản trị viên
class AccountMixin(SQLModel):
    """Mixin chứa các trường thông tin cơ bản cho tài khoản có xác thực mật khẩu."""
    id: Optional[int] = Field(default=None, primary_key=True, index=True)
    email: str = Field(sa_type=String(255), unique=True, index=True, nullable=False)
    hashed_password: str = Field(sa_type=String(255), nullable=False)
    full_name: Optional[str] = Field(default=None, sa_type=String(255), nullable=True)
    created_at: datetime = Field(
        default_factory=lambda: datetime.now(timezone.utc),
        sa_type=DateTime(timezone=True),
        nullable=False,
    )
