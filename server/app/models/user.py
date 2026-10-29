from datetime import datetime, timezone
from typing import Optional, List, TYPE_CHECKING
from sqlalchemy import (
    String,
    Float,
    Integer,
    Boolean,
    DateTime,
    CheckConstraint,
    Text,
    func,
    text,
    Column,
)
from sqlalchemy.dialects.postgresql import ARRAY
from sqlmodel import Field, Relationship
from server.app.db.base import Base
from server.app.models.base import AccountMixin

if TYPE_CHECKING:
    from server.app.models.option_user import OptionUser


# Model thực thể người dùng hệ thống kèm hồ sơ sức khoẻ
class User(AccountMixin, Base, table=True):
    """Bảng người dùng thông thường (Customer / User) tích hợp hồ sơ sức khỏe và sở thích ẩm thực."""
    __tablename__ = "users"
    __table_args__ = (
        CheckConstraint(
            "height_cm IS NULL OR (height_cm >= 50 AND height_cm <= 260)",
            name="ck_users_height",
        ),
        CheckConstraint(
            "weight_kg IS NULL OR (weight_kg >= 10 AND weight_kg <= 500)",
            name="ck_users_weight",
        ),
    )

    # Thông tin liên hệ
    phone: Optional[str] = Field(default=None, sa_type=String(50), nullable=True)

    # Chỉ số sức khỏe & thể chất
    height_cm: Optional[float] = Field(default=None, sa_type=Float, nullable=True)
    weight_kg: Optional[float] = Field(default=None, sa_type=Float, nullable=True)
    gender: Optional[str] = Field(default=None, sa_type=String(20), nullable=True)  # male, female, other
    birth_year: Optional[int] = Field(default=None, sa_type=Integer, nullable=True)
    activity_level: Optional[str] = Field(
        default=None, sa_type=String(30), nullable=True
    )  # sedentary, light, moderate, active, very_active
    target_goal: Optional[str] = Field(
        default=None, sa_type=String(50), nullable=True
    )  # maintain, lose_weight, gain_muscle, eat_healthy

    # Tùy chọn ẩm thực & Khẩu vị
    favorite_category_ids: List[int] = Field(
        default_factory=list,
        sa_column=Column(ARRAY(Integer), nullable=False, server_default=text("'{}'::integer[]")),
    )
    dietary_preferences: List[str] = Field(
        default_factory=list,
        sa_column=Column(ARRAY(Text), nullable=False, server_default=text("'{}'::text[]")),
    )  # vegetarian, vegan, low_carb, keto, healthy, clean_eating...
    spicy_tolerance: Optional[str] = Field(
        default=None, sa_type=String(20), nullable=True
    )  # none, mild, medium, hot
    allergies: List[str] = Field(
        default_factory=list,
        sa_column=Column(ARRAY(Text), nullable=False, server_default=text("'{}'::text[]")),
    )  # seafood, peanut, dairy, gluten, egg...
    budget_range: Optional[str] = Field(
        default=None, sa_type=String(20), nullable=True
    )  # budget, moderate, premium

    # Trạng thái khảo sát Onboarding
    is_onboarded: bool = Field(
        default=False,
        sa_column=Column(Boolean, default=False, server_default=text("false"), nullable=False),
    )
    onboarded_at: Optional[datetime] = Field(
        default=None,
        sa_column=Column(DateTime(timezone=True), nullable=True, default=None),
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
    # Danh sách tùy chọn ẩn/hiện danh mục món ăn của người dùng (Quan hệ 1-N: 1 User -> Nhiều OptionUser)
    # cascade="all, delete-orphan": Khi xóa người dùng, toàn bộ tùy chọn tương ứng sẽ tự động bị xóa theo
    options: List["OptionUser"] = Relationship(
        back_populates="user",
        sa_relationship_kwargs={
            "cascade": "all, delete-orphan",
            "passive_deletes": True,
        },
    )

    @property
    def user_id(self) -> int:
        """Alias tương thích trả về id người dùng trong UserProfileResponse."""
        return self.id  # type: ignore[return-value]
