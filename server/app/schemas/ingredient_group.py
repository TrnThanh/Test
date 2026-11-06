from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, ConfigDict, Field, field_validator


class IngredientGroupBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=100, description="Tên nhóm nguyên liệu (vd: Hải sản, Thịt gia súc...)")
    description: Optional[str] = Field(None, max_length=500, description="Mô tả nhóm nguyên liệu")
    display_order: int = Field(0, ge=0, description="Thứ tự hiển thị")
    is_active: bool = Field(True, description="Trạng thái kích hoạt")

    @field_validator("name")
    @classmethod
    def normalize_name(cls, v: str) -> str:
        v = v.strip()
        if not v:
            raise ValueError("Tên nhóm nguyên liệu không được để trống.")
        return v


class IngredientGroupCreate(IngredientGroupBase):
    pass


class IngredientGroupUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=1, max_length=100, description="Tên nhóm nguyên liệu")
    description: Optional[str] = Field(None, max_length=500, description="Mô tả nhóm nguyên liệu")
    display_order: Optional[int] = Field(None, ge=0, description="Thứ tự hiển thị")
    is_active: Optional[bool] = Field(None, description="Trạng thái kích hoạt")

    @field_validator("name")
    @classmethod
    def normalize_name(cls, v: Optional[str]) -> Optional[str]:
        if v is not None:
            v = v.strip()
            if not v:
                raise ValueError("Tên nhóm nguyên liệu không được để trống.")
            return v
        return None


class IngredientGroupResponse(BaseModel):
    id: int
    name: str
    description: Optional[str] = None
    display_order: int
    is_active: bool
    created_at: datetime
    ingredient_count: int = Field(0, description="Số lượng nguyên liệu thuộc nhóm này")

    model_config = ConfigDict(from_attributes=True)
