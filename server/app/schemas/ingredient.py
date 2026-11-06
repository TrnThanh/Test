from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, ConfigDict, Field, field_validator


class IngredientBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=100, description="Tên nguyên liệu")
    description: Optional[str] = Field(None, max_length=500, description="Mô tả hoặc ghi chú nguyên liệu")
    group_id: Optional[int] = Field(None, description="ID nhóm nguyên liệu (vd: Hải sản, Thịt gia súc...)")
    allergen_group: Optional[str] = Field(
        None, max_length=100, description="Nhóm dị ứng thực phẩm (vd: Hải sản, Sữa, Trứng, Đậu phộng, Gluten...)"
    )
    is_active: bool = Field(True, description="Trạng thái kích hoạt")

    @field_validator("name")
    @classmethod
    def normalize_name(cls, v: str) -> str:
        v = v.strip()
        if not v:
            raise ValueError("Tên nguyên liệu không được để trống.")
        return v

    @field_validator("allergen_group")
    @classmethod
    def normalize_allergen(cls, v: Optional[str]) -> Optional[str]:
        if v is not None:
            v = v.strip()
            return v if v else None
        return None


class IngredientCreate(IngredientBase):
    pass


class IngredientUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=1, max_length=100, description="Tên nguyên liệu")
    description: Optional[str] = Field(None, max_length=500, description="Mô tả nguyên liệu")
    group_id: Optional[int] = Field(None, description="ID nhóm nguyên liệu")
    allergen_group: Optional[str] = Field(None, max_length=100, description="Nhóm dị ứng thực phẩm")
    is_active: Optional[bool] = Field(None, description="Trạng thái kích hoạt")

    @field_validator("name")
    @classmethod
    def normalize_name(cls, v: Optional[str]) -> Optional[str]:
        if v is not None:
            v = v.strip()
            if not v:
                raise ValueError("Tên nguyên liệu không được để trống.")
            return v
        return None

    @field_validator("allergen_group")
    @classmethod
    def normalize_allergen(cls, v: Optional[str]) -> Optional[str]:
        if v is not None:
            v = v.strip()
            return v if v else None
        return None


class DishSimpleResponse(BaseModel):
    id: int
    name: str
    restaurant_id: int
    is_available: bool

    model_config = ConfigDict(from_attributes=True)


class IngredientResponse(BaseModel):
    id: int
    name: str
    description: Optional[str] = None
    group_id: Optional[int] = None
    group_name: Optional[str] = None
    allergen_group: Optional[str] = None
    is_active: bool
    created_at: datetime
    dish_count: int = Field(0, description="Số lượng món ăn đang sử dụng nguyên liệu này")

    model_config = ConfigDict(from_attributes=True)


class IngredientDetailResponse(IngredientResponse):
    dishes: List[DishSimpleResponse] = Field(default_factory=list, description="Danh sách món ăn sử dụng")


class IngredientListResponse(BaseModel):
    total: int
    items: List[IngredientResponse]
