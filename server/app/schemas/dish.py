from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, ConfigDict, Field, field_validator


class DishBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=255, description="Tên món ăn")
    price: float = Field(..., ge=0.0, description="Đơn giá món ăn (>= 0)")
    calories: Optional[int] = Field(None, ge=0, le=20000, description="Lượng calo của món ăn (kcal, >= 0)")
    description: Optional[str] = Field(None, max_length=1000, description="Mô tả món ăn")
    image_url: Optional[str] = Field(None, max_length=1000, description="Đường dẫn ảnh minh hoạ")
    category_id: Optional[int] = Field(None, description="ID nhóm danh mục (Foreign Key)")
    category: Optional[str] = Field(None, max_length=100, description="Nhóm món (vd: Món chính, Khai vị, Đồ uống)")
    spicy_level: int = Field(0, ge=0, le=3, description="Mức độ cay (0: không cay, 1: cay nhẹ, 2: cay vừa, 3: rất cay)")
    dietary_tags: List[str] = Field(default_factory=list, description="Mảng chế độ ăn (vegetarian, vegan, halal, keto...)")
    meal_types: List[str] = Field(default_factory=list, description="Mảng bữa ăn (breakfast, lunch, dinner, snack, all_day)")
    allergens: List[str] = Field(default_factory=list, description="Mảng dị ứng thực phẩm (peanut, seafood, dairy...)")
    ingredients: List[str] = Field(default_factory=list, description="Danh sách nguyên liệu món ăn (vd: ['Thịt bò', 'Hành lá'])")
    is_available: bool = Field(True, description="Trạng thái còn món / tạm hết món")

    @field_validator("category")
    @classmethod
    def normalize_category_field(cls, v: Optional[str]) -> Optional[str]:
        if v is not None:
            v = v.strip()
            return v if v else None
        return None

    @field_validator("ingredients", "dietary_tags", "meal_types", "allergens")
    @classmethod
    def normalize_string_list(cls, v: List[str]) -> List[str]:
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
    calories: Optional[int] = Field(None, ge=0, le=20000, description="Lượng calo của món ăn (kcal)")
    description: Optional[str] = Field(None, max_length=1000, description="Mô tả món ăn")
    image_url: Optional[str] = Field(None, max_length=1000, description="Ảnh minh hoạ")
    category_id: Optional[int] = Field(None, description="ID nhóm danh mục")
    category: Optional[str] = Field(None, max_length=100, description="Nhóm món")
    spicy_level: Optional[int] = Field(None, ge=0, le=3, description="Mức độ cay (0 đến 3)")
    dietary_tags: Optional[List[str]] = Field(None, description="Mảng chế độ ăn")
    meal_types: Optional[List[str]] = Field(None, description="Mảng bữa ăn")
    allergens: Optional[List[str]] = Field(None, description="Mảng dị ứng thực phẩm")
    ingredients: Optional[List[str]] = Field(None, description="Danh sách nguyên liệu")
    is_available: Optional[bool] = Field(None, description="Trạng thái còn món")

    @field_validator("category")
    @classmethod
    def normalize_category_field(cls, v: Optional[str]) -> Optional[str]:
        if v is not None:
            v = v.strip()
            return v if v else None
        return None

    @field_validator("ingredients", "dietary_tags", "meal_types", "allergens")
    @classmethod
    def normalize_string_list(cls, v: Optional[List[str]]) -> Optional[List[str]]:
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
    meal_type_name: Optional[str] = Field(None, description="Tên loại bữa ăn liên kết (nếu có)")
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class FavouriteDishResponse(BaseModel):
    id: int
    user_id: int
    dish_id: int
    created_at: datetime
    dish: Optional[DishResponse] = None

    model_config = ConfigDict(from_attributes=True)
