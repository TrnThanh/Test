from typing import List, Optional
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session
from server.app.db.session import get_db
from server.app.schemas.option_user import OptionUserCreate, OptionUserResponse
from server.app.services.option_user_service import OptionUserService

router = APIRouter()


# Lấy danh sách tuỳ chọn ẩn hoặc hiện các danh mục món ăn theo cấu hình của người dùng
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
    """
    [POSTMAN TEST GUIDE]
    - Method  : GET
    - URL     : http://localhost:8001/api/v1/users/1/options?hide=true
    - Headers : (Không yêu cầu)
    - Params  : Path user_id (int), Query hide (bool, tuỳ chọn)
    - Body    : (Không có)
    - Expected: 200 OK -> [{"id": 1, "user_id": 1, "category_id": 3, "hide": true, "category_name": "Đồ uống"}]
    """
    # Lấy danh sách tùy chọn theo user_id
    return OptionUserService.get_user_options(db=db, user_id=user_id, hide=hide)


# Thiết lập trạng thái ẩn hoặc hiện cho một danh mục món ăn cụ thể của người dùng
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
    """
    [POSTMAN TEST GUIDE]
    - Method  : POST
    - URL     : http://localhost:8001/api/v1/users/1/options
    - Headers : Content-Type: application/json
    - Params  : Path user_id (int)
    - Body (raw JSON):
      {
        "category_id": 3,
        "hide": true
      }
    - Expected: 201 Created -> {"id": 1, "user_id": 1, "category_id": 3, "hide": true, "category_name": "Đồ uống"}
    - Errors  : 404 Not Found (User hoặc Category không tồn tại), 422 Unprocessable Content
    """
    # Lưu tùy chọn danh mục của người dùng vào CSDL
    return OptionUserService.create_user_option(db=db, user_id=user_id, data=data)


# Xoá tuỳ chọn ẩn danh mục của người dùng (khôi phục về trạng thái hiển thị mặc định)
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
    """
    [POSTMAN TEST GUIDE]
    - Method  : DELETE
    - URL     : http://localhost:8001/api/v1/users/1/options/1
    - Headers : (Không yêu cầu)
    - Params  : Path user_id (int), Path option_id (int)
    - Body    : (Không có)
    - Expected: 204 No Content
    - Errors  : 404 Not Found (Tùy chọn không tồn tại hoặc không thuộc user)
    """
    # Gọi service xóa bản ghi tùy chọn
    OptionUserService.delete_user_option(db=db, user_id=user_id, option_id=option_id)
