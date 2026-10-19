from datetime import datetime
from typing import Optional, List, Literal
from pydantic import BaseModel, ConfigDict, Field, field_validator

MealType = Literal["breakfast", "lunch", "dinner", "snack", "all_day"]


class DishBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=255, description="Tên món ăn")
    price: float = Field(..., ge=0.0, description="Đơn giá món ăn (>= 0)")
    description: Optional[str] = Field(None, max_length=1000, description="Mô tả món ăn")
    image_url: Optional[str] = Field(None, max_length=1000, description="Đường dẫn ảnh minh hoạ")
    category_id: Optional[int] = Field(None, description="ID nhóm danh mục (Foreign Key)")
    category: Optional[str] = Field(None, max_length=100, description="Nhóm món (vd: Món chính, Khai vị, Đồ uống)")
    meal_type_id: Optional[int] = Field(None, description="ID loại bữa ăn (Foreign Key)")
    meal_type: MealType = Field("all_day", description="Bữa ăn: breakfast, lunch, dinner, snack, all_day")
    ingredients: List[str] = Field(default_factory=list, description="Danh sách nguyên liệu món ăn (vd: ['Thịt bò', 'Hành lá'])")
    is_available: bool = Field(True, description="Trạng thái còn món / tạm hết món")

    @field_validator("category")
    @classmethod
    def normalize_category_field(cls, v: Optional[str]) -> Optional[str]:
        if v is not None:
            v = v.strip()
            return v if v else None
        return None

    @field_validator("ingredients")
    @classmethod
    def normalize_ingredients_list(cls, v: List[str]) -> List[str]:
        cleaned: List[str] = []
        for t in v:
            t = t.strip()
            if t and t not in cleaned:
                cleaned.append(t)
        return cleaned


class DishCreate(DishBase):
    pass


class DishUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=1, max_length=255, description="Tên món ăn")
    price: Optional[float] = Field(None, ge=0.0, description="Đơn giá món ăn")
    description: Optional[str] = Field(None, max_length=1000, description="Mô tả món ăn")
    image_url: Optional[str] = Field(None, max_length=1000, description="Ảnh minh hoạ")
    category_id: Optional[int] = Field(None, description="ID nhóm danh mục")
    category: Optional[str] = Field(None, max_length=100, description="Nhóm món")
    meal_type_id: Optional[int] = Field(None, description="ID loại bữa ăn")
    meal_type: Optional[MealType] = Field(None, description="Bữa ăn")
    ingredients: Optional[List[str]] = Field(None, description="Danh sách nguyên liệu")
    is_available: Optional[bool] = Field(None, description="Trạng thái còn món")

    @field_validator("category")
    @classmethod
    def normalize_category_field(cls, v: Optional[str]) -> Optional[str]:
        if v is not None:
            v = v.strip()
            return v if v else None
        return None

    @field_validator("ingredients")
    @classmethod
    def normalize_ingredients_list(cls, v: Optional[List[str]]) -> Optional[List[str]]:
        if v is not None:
            cleaned: List[str] = []
            for t in v:
                t = t.strip()
                if t and t not in cleaned:
                    cleaned.append(t)
            return cleaned
        return None


class DishResponse(DishBase):
    id: int
    restaurant_id: int
    category_name: Optional[str] = Field(None, description="Tên nhóm danh mục liên kết")
    meal_type_name: Optional[str] = Field(None, description="Tên loại bữa ăn liên kết")
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class FavouriteDishResponse(BaseModel):
    id: int
    user_id: int
    dish_id: int
    created_at: datetime
    dish: Optional[DishResponse] = None

    model_config = ConfigDict(from_attributes=True)
