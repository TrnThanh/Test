from datetime import datetime
from typing import Optional
from pydantic import BaseModel, ConfigDict, Field


class OptionUserBase(BaseModel):
    category_id: int = Field(..., description="ID danh mục cần cấu hình ẩn/hiện")
    hide: bool = Field(True, description="Trạng thái ẩn (true: ẩn, false: hiển thị)")


class OptionUserCreate(OptionUserBase):
    pass


class OptionUserUpdate(BaseModel):
    hide: bool = Field(..., description="Cập nhật trạng thái ẩn (true/false)")


class OptionUserResponse(OptionUserBase):
    id: int
    user_id: int
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)
