from datetime import datetime, timezone
from typing import Optional, List, TYPE_CHECKING
from sqlalchemy import (
    String,
    Float,
    Integer,
    Boolean,
    DateTime,
    ForeignKey,
    CheckConstraint,
    Text,
    func,
    text,
)
from sqlalchemy.dialects.postgresql import ARRAY
from sqlalchemy.orm import Mapped, mapped_column, relationship
from server.app.db.base import Base

if TYPE_CHECKING:
    from server.app.models.user import User


class UserProfile(Base):
    """Bảng hồ sơ người dùng mở rộng: sức khỏe, thể chất và sở thích ẩm thực (User Profile & Dietary Preferences)."""
    __tablename__ = "user_profiles"
    __table_args__ = (
        CheckConstraint(
            "height_cm IS NULL OR (height_cm >= 50 AND height_cm <= 260)",
            name="ck_user_profile_height",
        ),
        CheckConstraint(
            "weight_kg IS NULL OR (weight_kg >= 10 AND weight_kg <= 500)",
            name="ck_user_profile_weight",
        ),
    )

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), unique=True, index=True, nullable=False
    )

    # Chỉ số sức khỏe & thể chất
    height_cm: Mapped[Optional[float]] = mapped_column(Float, nullable=True, default=None)
    weight_kg: Mapped[Optional[float]] = mapped_column(Float, nullable=True, default=None)
    gender: Mapped[Optional[str]] = mapped_column(String(20), nullable=True, default=None)  # male, female, other
    birth_year: Mapped[Optional[int]] = mapped_column(Integer, nullable=True, default=None)
    activity_level: Mapped[Optional[str]] = mapped_column(
        String(30), nullable=True, default=None
    )  # sedentary, light, moderate, active, very_active
    target_goal: Mapped[Optional[str]] = mapped_column(
        String(50), nullable=True, default=None
    )  # maintain, lose_weight, gain_muscle, eat_healthy

    # Tùy chọn ẩm thực & Khẩu vị
    favorite_category_ids: Mapped[List[int]] = mapped_column(
        ARRAY(Integer), nullable=False, default=list, server_default=text("'{}'::integer[]")
    )
    dietary_preferences: Mapped[List[str]] = mapped_column(
        ARRAY(Text), nullable=False, default=list, server_default=text("'{}'::text[]")
    )  # vegetarian, vegan, low_carb, keto, healthy, clean_eating...
    spicy_tolerance: Mapped[Optional[str]] = mapped_column(
        String(20), nullable=True, default=None
    )  # none, mild, medium, hot
    allergies: Mapped[List[str]] = mapped_column(
        ARRAY(Text), nullable=False, default=list, server_default=text("'{}'::text[]")
    )  # seafood, peanut, dairy, gluten, egg...
    budget_range: Mapped[Optional[str]] = mapped_column(
        String(20), nullable=True, default=None
    )  # budget, moderate, premium

    # Trạng thái khảo sát Onboarding
    is_onboarded: Mapped[bool] = mapped_column(
        Boolean, default=False, server_default=text("false"), nullable=False
    )
    onboarded_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True), nullable=True, default=None
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

    user: Mapped["User"] = relationship("User", back_populates="profile")
