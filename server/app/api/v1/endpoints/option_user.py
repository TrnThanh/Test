from typing import List, Optional
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session
from server.app.db.session import get_db
from server.app.schemas.option_user import OptionUserCreate, OptionUserResponse
from server.app.services.option_user_service import OptionUserService

router = APIRouter()


# [POSTMAN GUIDE]
# GET http://localhost:8001/api/v1/users/1/options?hide=true
# Headers: (Không yêu cầu)
# Đầu vào (Path Param):
#   - user_id: 1 (int, bắt buộc)
# Đầu vào (Query Params):
#   - hide: true (bool, tuỳ chọn)
# Status Code gợi ý:
#   - 200 OK: Lấy danh sách tùy chọn ẩn/hiện danh mục của người dùng thành công
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
    # Lấy danh sách tùy chọn theo user_id
    return OptionUserService.get_user_options(db=db, user_id=user_id, hide=hide)


# [POSTMAN GUIDE]
# POST http://localhost:8001/api/v1/users/1/options
# Headers:
#   Content-Type: application/json
# Đầu vào (Path Param):
#   - user_id: 1 (int, bắt buộc)
# Đầu vào (Body raw JSON):
# {
#   "category_id": 3,  // int (bắt buộc)
#   "hide": true       // bool (bắt buộc)
# }
# Status Code gợi ý:
#   - 201 Created              : Tạo hoặc cập nhật tùy chọn ẩn danh mục thành công
#   - 404 Not Found            : Người dùng hoặc danh mục không tồn tại
#   - 422 Unprocessable Content: Sai kiểu dữ liệu
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
    # Lưu tùy chọn danh mục của người dùng vào CSDL
    return OptionUserService.create_user_option(db=db, user_id=user_id, data=data)


# [POSTMAN GUIDE]
# DELETE http://localhost:8001/api/v1/users/1/options/1
# Headers: (Không yêu cầu)
# Đầu vào (Path Param):
#   - user_id   : 1 (int, bắt buộc)
#   - option_id : 1 (int, bắt buộc)
# Status Code gợi ý:
#   - 204 No Content: Xóa tùy chọn ẩn danh mục thành công (khôi phục hiển thị)
#   - 404 Not Found : Tùy chọn không tồn tại hoặc không thuộc quyền sở hữu của người dùng
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
    # Gọi service xóa bản ghi tùy chọn
    OptionUserService.delete_user_option(db=db, user_id=user_id, option_id=option_id)
