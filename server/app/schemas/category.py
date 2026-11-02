from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, ConfigDict, Field, field_validator


class CategoryBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=100, description="Tên nhóm danh mục")
    description: Optional[str] = Field(None, max_length=500, description="Mô tả nhóm danh mục")
    display_order: int = Field(0, ge=0, description="Thứ tự hiển thị (ưu tiên số nhỏ trước)")
    is_active: bool = Field(True, description="Trạng thái kích hoạt danh mục")

    @field_validator("name")
    @classmethod
    def normalize_name(cls, v: str) -> str:
        v = v.strip()
        if not v:
            raise ValueError("Tên danh mục không được để trống.")
        return v


class CategoryCreate(CategoryBase):
    pass


class CategoryUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=1, max_length=100, description="Tên nhóm danh mục")
    description: Optional[str] = Field(None, max_length=500, description="Mô tả nhóm danh mục")
    display_order: Optional[int] = Field(None, ge=0, description="Thứ tự hiển thị")
    is_active: Optional[bool] = Field(None, description="Trạng thái kích hoạt")

    @field_validator("name")
    @classmethod
    def normalize_name(cls, v: Optional[str]) -> Optional[str]:
        if v is not None:
            v = v.strip()
            if not v:
                raise ValueError("Tên danh mục không được để trống.")
            return v
        return None


class CategoryResponse(CategoryBase):
    id: int
    created_at: datetime
    dish_count: Optional[int] = Field(0, description="Số lượng món trong danh mục")

    model_config = ConfigDict(from_attributes=True)
