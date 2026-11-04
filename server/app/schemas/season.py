from datetime import datetime
from typing import Optional
from pydantic import BaseModel, ConfigDict, Field


class SeasonBase(BaseModel):
    code: str = Field(..., max_length=20, description="Mã định danh mùa (spring, summer, autumn, winter)")
    name: str = Field(..., max_length=50, description="Tên mùa hiển thị (Xuân, Hạ, Thu, Đông)")
    description: Optional[str] = Field(None, max_length=255, description="Mô tả đặc trưng của mùa")
    start_date: Optional[str] = Field(
        None,
        max_length=5,
        pattern=r"^(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])$",
        description="Ngày bắt đầu chu kỳ mùa theo định dạng MM-DD (ví dụ: 02-01)",
    )
    end_date: Optional[str] = Field(
        None,
        max_length=5,
        pattern=r"^(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])$",
        description="Ngày kết thúc chu kỳ mùa theo định dạng MM-DD (ví dụ: 04-30)",
    )
    sort_order: int = Field(0, ge=0, description="Thứ tự hiển thị")
    is_active: bool = Field(True, description="Trạng thái kích hoạt")


class SeasonResponse(SeasonBase):
    id: int
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)
