from datetime import datetime
from typing import Optional
from pydantic import BaseModel, ConfigDict, Field


class SeasonBase(BaseModel):
    code: str = Field(..., max_length=20, description="Mã định danh mùa (spring, summer, autumn, winter)")
    name: str = Field(..., max_length=50, description="Tên mùa hiển thị (Xuân, Hạ, Thu, Đông)")
    description: Optional[str] = Field(None, max_length=255, description="Mô tả đặc trưng của mùa")
    sort_order: int = Field(0, ge=0, description="Thứ tự hiển thị")
    is_active: bool = Field(True, description="Trạng thái kích hoạt")


class SeasonResponse(SeasonBase):
    id: int
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)
