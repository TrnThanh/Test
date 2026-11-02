from typing import List, Optional
from fastapi import APIRouter, Depends, Query, Path, status
from sqlalchemy.orm import Session

from server.app.db.session import get_db
from server.app.schemas.category import CategoryCreate, CategoryUpdate, CategoryResponse
from server.app.services.category_service import CategoryService

router = APIRouter()


# ==============================================================================
# PHÂN HỆ 1: Danh mục toàn cục (Global Master Categories)
# ==============================================================================

# Tạo mới một danh mục phân loại món ăn dùng chung cho toàn bộ hệ thống
@router.post(
    "/categories",
    response_model=CategoryResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Tạo danh mục món ăn mới toàn cục",
)
def create_category(
    category_in: CategoryCreate,
    db: Session = Depends(get_db),
):
    """
    [POSTMAN TEST GUIDE]
    - Method  : POST
    - URL     : http://localhost:8001/api/v1/categories
    - Headers : Content-Type: application/json
    - Params  : (Không có)
    - Body (raw JSON):
      {
        "name": "Món Cuốn & Gỏi",
        "description": "Các món cuốn bánh tráng, gỏi tôm thịt tươi mát",
        "display_order": 1,
        "is_active": true
      }
    - Expected: 201 Created -> {"id": 1, "name": "Món Cuốn & Gỏi", "display_order": 1, "is_active": true}
    - Errors  : 400 Bad Request (Tên danh mục đã tồn tại), 422 Unprocessable Content
    """
    # Gọi service thêm danh mục toàn cục vào cơ sở dữ liệu
    return CategoryService.create_category(
        db=db,
        data=category_in,
    )


# Lấy danh sách toàn bộ các nhóm danh mục món ăn trong hệ thống
@router.get(
    "/categories",
    response_model=List[CategoryResponse],
    summary="Lấy danh sách các nhóm danh mục món ăn toàn cục",
)
def get_categories(
    is_active_only: bool = Query(False, description="Chỉ lấy danh mục đang hoạt động"),
    restaurant_id: Optional[int] = Query(None, description="Lọc danh mục có món thuộc quán ăn này"),
    db: Session = Depends(get_db),
):
    """
    [POSTMAN TEST GUIDE]
    - Method  : GET
    - URL     : http://localhost:8001/api/v1/categories?is_active_only=true
    - Headers : (Không yêu cầu)
    - Params  : is_active_only (bool, mặc định false), restaurant_id (int, tuỳ chọn)
    - Body    : (Không có)
    - Expected: 200 OK -> [{"id": 1, "name": "Cơm", "dish_count": 12, "is_active": true}]
    """
    # Lấy danh sách danh mục theo trạng thái và quán ăn
    return CategoryService.get_categories(
        db=db,
        restaurant_id=restaurant_id,
        is_active_only=is_active_only,
    )


# ==============================================================================
# PHÂN HỆ 2: Endpoints danh mục tương thích ngược theo quán ăn
# ==============================================================================

# Tạo nhóm danh mục món ăn gắn với một quán ăn cụ thể (tương thích ngược)
@router.post(
    "/restaurants/{restaurant_id}/categories",
    response_model=CategoryResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Tạo nhóm danh mục món ăn mới (Tương thích ngược)",
)
def create_category_legacy(
    restaurant_id: int = Path(..., description="ID quán ăn"),
    category_in: CategoryCreate = ...,
    db: Session = Depends(get_db),
):
    """
    [POSTMAN TEST GUIDE]
    - Method  : POST
    - URL     : http://localhost:8001/api/v1/restaurants/1/categories
    - Headers : Content-Type: application/json
    - Params  : Path restaurant_id (int)
    - Body (raw JSON):
      {
        "name": "Đồ uống đặc biệt",
        "display_order": 2
      }
    - Expected: 201 Created -> {"id": 2, "name": "Đồ uống đặc biệt", "restaurant_id": 1}
    - Errors  : 400 Bad Request, 422 Unprocessable Content
    """
    # Tạo danh mục có gắn restaurant_id
    return CategoryService.create_category(
        db=db,
        data=category_in,
        restaurant_id=restaurant_id,
    )


# Lấy danh sách các nhóm danh mục của quán ăn cụ thể
@router.get(
    "/restaurants/{restaurant_id}/categories",
    response_model=List[CategoryResponse],
    summary="Lấy danh sách các nhóm danh mục của quán ăn",
)
def get_restaurant_categories(
    restaurant_id: int = Path(..., description="ID quán ăn"),
    is_active_only: bool = Query(False, description="Chỉ lấy danh mục đang hoạt động"),
    db: Session = Depends(get_db),
):
    """
    [POSTMAN TEST GUIDE]
    - Method  : GET
    - URL     : http://localhost:8001/api/v1/restaurants/1/categories?is_active_only=true
    - Headers : (Không yêu cầu)
    - Params  : Path restaurant_id (int), Query is_active_only (bool)
    - Body    : (Không có)
    - Expected: 200 OK -> [{"id": 1, "name": "Món chính", ...}]
    """
    # Lấy danh sách danh mục theo quán ăn cụ thể
    return CategoryService.get_categories(
        db=db,
        restaurant_id=restaurant_id,
        is_active_only=is_active_only,
    )


# Lấy thông tin chi tiết một danh mục món ăn theo ID
@router.get(
    "/categories/{category_id}",
    response_model=CategoryResponse,
    summary="Chi tiết một danh mục món ăn",
)
def get_category_detail(
    category_id: int = Path(..., description="ID danh mục"),
    db: Session = Depends(get_db),
):
    """
    [POSTMAN TEST GUIDE]
    - Method  : GET
    - URL     : http://localhost:8001/api/v1/categories/1
    - Headers : (Không yêu cầu)
    - Params  : Path category_id (int)
    - Body    : (Không có)
    - Expected: 200 OK -> {"id": 1, "name": "Cơm", "description": "...", "is_active": true}
    - Errors  : 404 Not Found
    """
    # Truy vấn chi tiết danh mục theo ID
    return CategoryService.get_category_by_id(db=db, category_id=category_id)


# Cập nhật thông tin danh mục món ăn (tên, thứ tự hiển thị, trạng thái)
@router.put(
    "/categories/{category_id}",
    response_model=CategoryResponse,
    summary="Cập nhật danh mục món ăn",
)
def update_category(
    category_id: int = Path(..., description="ID danh mục cần cập nhật"),
    category_in: CategoryUpdate = ...,
    db: Session = Depends(get_db),
):
    """
    [POSTMAN TEST GUIDE]
    - Method  : PUT
    - URL     : http://localhost:8001/api/v1/categories/1
    - Headers : Content-Type: application/json
    - Params  : Path category_id (int)
    - Body (raw JSON):
      {
        "name": "Cơm & Mì Phở",
        "display_order": 1,
        "is_active": true
      }
    - Expected: 200 OK -> {"id": 1, "name": "Cơm & Mì Phở", ...}
    - Errors  : 404 Not Found, 422 Unprocessable Content
    """
    # Cập nhật thông tin danh mục qua service
    return CategoryService.update_category(
        db=db,
        category_id=category_id,
        data=category_in,
    )


# Xoá một danh mục món ăn (các món ăn thuộc danh mục sẽ chuyển thành không phân loại)
@router.delete(
    "/categories/{category_id}",
    summary="Xoá danh mục món ăn",
)
def delete_category(
    category_id: int = Path(..., description="ID danh mục cần xoá"),
    db: Session = Depends(get_db),
):
    """
    [POSTMAN TEST GUIDE]
    - Method  : DELETE
    - URL     : http://localhost:8001/api/v1/categories/1
    - Headers : (Không yêu cầu)
    - Params  : Path category_id (int)
    - Body    : (Không có)
    - Expected: 200 OK -> {"message": "Danh mục 1 đã được xoá thành công..."}
    - Errors  : 404 Not Found
    """
    # 1. Gọi service xoá danh mục và gán category_id = None cho các món liên quan
    CategoryService.delete_category(
        db=db,
        category_id=category_id,
    )
    # 2. Trả về thông báo hoàn tất
    return {"message": f"Danh mục {category_id} đã được xoá thành công. Các món ăn liên quan đã được chuyển thành chưa phân loại."}
