from typing import List, Optional
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session
from server.app.db.session import get_db
from server.app.schemas.option_user import OptionUserCreate, OptionUserResponse
from server.app.services.option_user_service import OptionUserService

router = APIRouter()


@router.get(
    "/{user_id}/options",
    response_model=List[OptionUserResponse],
    status_code=status.HTTP_200_OK,
    summary="Lấy danh sách tùy chọn ẩn/hiện danh mục của người dùng",
    description="Lấy danh sách các danh mục mà user đã cấu hình ẩn/hiện. Hỗ trợ lọc theo ?hide=true hoặc ?hide=false.",
)
def get_user_options(
    user_id: int,
    hide: Optional[bool] = Query(None, description="Lọc theo trạng thái ẩn (true/false)"),
    db: Session = Depends(get_db),
) -> List[OptionUserResponse]:
    return OptionUserService.get_user_options(db=db, user_id=user_id, hide=hide)


@router.post(
    "/{user_id}/options",
    response_model=OptionUserResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Tạo hoặc cập nhật tùy chọn ẩn danh mục của người dùng",
    description="Thiết lập trạng thái ẩn (hide: true/false) cho một category_id thuộc sở hữu của user_id.",
)
def create_user_option(
    user_id: int,
    data: OptionUserCreate,
    db: Session = Depends(get_db),
) -> OptionUserResponse:
    return OptionUserService.create_user_option(db=db, user_id=user_id, data=data)


@router.delete(
    "/{user_id}/options/{option_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Xóa tùy chọn ẩn danh mục của người dùng",
    description="Xóa bản ghi tùy chọn theo ID, đưa danh mục về trạng thái mặc định (hiển thị).",
)
def delete_user_option(
    user_id: int,
    option_id: int,
    db: Session = Depends(get_db),
) -> None:
    OptionUserService.delete_user_option(db=db, user_id=user_id, option_id=option_id)
