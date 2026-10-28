from datetime import datetime, timezone
from sqlalchemy import String, Integer, DateTime, func, Column
from sqlmodel import Field
from server.app.db.base import Base


# Model lưu trữ trạng thái seed migration dữ liệu
class SeedMeta(Base, table=True):
    """Bảng lưu vết các migration / seed dữ liệu tự động đã hoàn thành."""
    __tablename__ = "seed_meta"

    key: str = Field(sa_type=String(100), primary_key=True, index=True)
    version: int = Field(default=1, sa_type=Integer)
    applied_at: datetime = Field(
        default_factory=lambda: datetime.now(timezone.utc),
        sa_column=Column(DateTime(timezone=True), server_default=func.now(), nullable=False),
    )
