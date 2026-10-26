from datetime import datetime
from sqlalchemy import String, Integer, DateTime, func
from sqlalchemy.orm import Mapped, mapped_column

from server.app.db.base import Base


class SeedMeta(Base):
    """Bảng lưu vết các migration / seed dữ liệu tự động đã hoàn thành."""
    __tablename__ = "seed_meta"

    key: Mapped[str] = mapped_column(String(100), primary_key=True, index=True)
    version: Mapped[int] = mapped_column(Integer, default=1)
    applied_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
