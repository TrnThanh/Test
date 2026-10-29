from datetime import datetime
from typing import Optional, List, Literal
from pydantic import BaseModel, ConfigDict, Field, computed_field

Gender = Literal["male", "female", "other"]
ActivityLevel = Literal["sedentary", "light", "moderate", "active", "very_active"]
TargetGoal = Literal["maintain", "lose_weight", "gain_muscle", "eat_healthy"]
SpicyTolerance = Literal["none", "mild", "medium", "hot"]
BudgetRange = Literal["budget", "moderate", "premium"]


class UserProfileBase(BaseModel):
    full_name: Optional[str] = Field(None, description="Họ và tên")
    phone: Optional[str] = Field(None, max_length=50, description="Số điện thoại liên hệ")
    height_cm: Optional[float] = Field(None, ge=50.0, le=260.0, description="Chiều cao tính bằng cm")
    weight_kg: Optional[float] = Field(None, ge=10.0, le=500.0, description="Cân nặng tính bằng kg")
    gender: Optional[Gender] = Field(None, description="Giới tính (male, female, other)")
    birth_year: Optional[int] = Field(None, ge=1920, le=2026, description="Năm sinh")
    activity_level: Optional[ActivityLevel] = Field(
        None, description="Mức độ vận động (sedentary, light, moderate, active, very_active)"
    )
    target_goal: Optional[TargetGoal] = Field(
        None, description="Mục tiêu sức khỏe (maintain, lose_weight, gain_muscle, eat_healthy)"
    )
    favorite_category_ids: List[int] = Field(
        default_factory=list, description="Danh sách ID các nhóm danh mục món ăn yêu thích"
    )
    dietary_preferences: List[str] = Field(
        default_factory=list,
        description="Sở thích & chế độ ăn uống (vegetarian, vegan, low_carb, keto, healthy...)",
    )
    spicy_tolerance: Optional[SpicyTolerance] = Field(
        None, description="Mức độ ăn cay (none, mild, medium, hot)"
    )
    allergies: List[str] = Field(
        default_factory=list, description="Danh sách thành phần dị ứng (seafood, peanut, dairy...)"
    )
    budget_range: Optional[BudgetRange] = Field(
        None, description="Mức chi tiêu/ngân sách (budget, moderate, premium)"
    )


class UserProfileUpdate(BaseModel):
    full_name: Optional[str] = Field(None, description="Họ và tên")
    phone: Optional[str] = Field(None, max_length=50, description="Số điện thoại liên hệ")
    height_cm: Optional[float] = Field(None, ge=50.0, le=260.0, description="Chiều cao (cm)")
    weight_kg: Optional[float] = Field(None, ge=10.0, le=500.0, description="Cân nặng (kg)")
    gender: Optional[Gender] = Field(None, description="Giới tính")
    birth_year: Optional[int] = Field(None, ge=1920, le=2026, description="Năm sinh")
    activity_level: Optional[ActivityLevel] = Field(None, description="Mức độ vận động")
    target_goal: Optional[TargetGoal] = Field(None, description="Mục tiêu dinh dưỡng")
    favorite_category_ids: Optional[List[int]] = Field(None, description="ID các danh mục yêu thích")
    dietary_preferences: Optional[List[str]] = Field(None, description="Chế độ ăn")
    spicy_tolerance: Optional[SpicyTolerance] = Field(None, description="Khẩu vị ăn cay")
    allergies: Optional[List[str]] = Field(None, description="Thành phần dị ứng")
    budget_range: Optional[BudgetRange] = Field(None, description="Khung ngân sách")
    complete_onboarding: bool = Field(
        False, description="Đánh dấu hoàn thành khảo sát Onboarding lần đầu"
    )


class UserProfileResponse(UserProfileBase):
    id: int
    user_id: int
    is_onboarded: bool = Field(False, description="Trạng thái đã hoàn thành khảo sát ban đầu")
    onboarded_at: Optional[datetime] = None
    created_at: datetime
    updated_at: datetime

    @computed_field  # type: ignore[prop-decorator]
    @property
    def bmi(self) -> Optional[float]:
        """Chỉ số BMI (Body Mass Index) tính động: weight_kg / (height_m ^ 2)."""
        if self.height_cm and self.weight_kg and self.height_cm > 0:
            height_m = self.height_cm / 100.0
            return round(self.weight_kg / (height_m * height_m), 1)
        return None

    @computed_field  # type: ignore[prop-decorator]
    @property
    def bmi_category(self) -> Optional[str]:
        """Phân loại thể trạng theo chuẩn WHO châu Á."""
        val = self.bmi
        if val is None:
            return None
        if val < 18.5:
            return "underweight"  # Gầy / Thiếu cân
        elif val < 23.0:
            return "normal"  # Bình thường / Thể trạng chuẩn
        elif val < 25.0:
            return "overweight"  # Thừa cân / Tiền béo phì
        else:
            return "obese"  # Béo phì

    model_config = ConfigDict(from_attributes=True)
