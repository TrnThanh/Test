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

# [POSTMAN GUIDE]
# POST http://localhost:8001/api/v1/categories
# Headers:
#   Content-Type: application/json
# Đầu vào (Body raw JSON):
# {
#   "name": "Món Cuốn & Gỏi",                                        // string (bắt buộc)
#   "description": "Các món cuốn bánh tráng, gỏi tôm thịt tươi mát",  // string (tuỳ chọn)
#   "display_order": 1,                                              // int (tuỳ chọn, default: 0)
#   "is_active": true                                                // bool (tuỳ chọn, default: true)
# }
# Status Code gợi ý:
#   - 201 Created              : Tạo danh mục món ăn mới toàn cục thành công
#   - 400 Bad Request          : Tên danh mục đã tồn tại
#   - 422 Unprocessable Content: Thiếu tên danh mục hoặc sai kiểu dữ liệu
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
    # Gọi service thêm danh mục toàn cục vào cơ sở dữ liệu
    return CategoryService.create_category(
        db=db,
        data=category_in,
    )


# [POSTMAN GUIDE]
# GET http://localhost:8001/api/v1/categories?is_active_only=true
# Headers: (Không yêu cầu)
# Đầu vào (Query Params):
#   - is_active_only : false (bool, default: false)
#   - restaurant_id  : 1     (int, tuỳ chọn)
# Status Code gợi ý:
#   - 200 OK: Lấy danh sách các nhóm danh mục món ăn toàn cục thành công
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
    # Lấy danh sách danh mục theo trạng thái và quán ăn
    return CategoryService.get_categories(
        db=db,
        restaurant_id=restaurant_id,
        is_active_only=is_active_only,
    )


# ==============================================================================
# PHÂN HỆ 2: Endpoints danh mục tương thích ngược theo quán ăn
# ==============================================================================

# [POSTMAN GUIDE]
# POST http://localhost:8001/api/v1/restaurants/1/categories
# Headers:
#   Content-Type: application/json
# Đầu vào (Path Param):
#   - restaurant_id: 1 (int, bắt buộc)
# Đầu vào (Body raw JSON):
# {
#   "name": "Đồ uống đặc biệt",  // string (bắt buộc)
#   "display_order": 2           // int (tuỳ chọn)
# }
# Status Code gợi ý:
#   - 201 Created              : Tạo nhóm danh mục món ăn cho quán thành công
#   - 400 Bad Request          : Tên danh mục đã tồn tại
#   - 422 Unprocessable Content: Sai dữ liệu đầu vào hoặc thiếu tên danh mục
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
    # Tạo danh mục có gắn restaurant_id
    return CategoryService.create_category(
        db=db,
        data=category_in,
        restaurant_id=restaurant_id,
    )


# [POSTMAN GUIDE]
# GET http://localhost:8001/api/v1/restaurants/1/categories?is_active_only=true
# Headers: (Không yêu cầu)
# Đầu vào (Path Param):
#   - restaurant_id: 1 (int, bắt buộc)
# Đầu vào (Query Params):
#   - is_active_only: false (bool, default: false)
# Status Code gợi ý:
#   - 200 OK: Lấy danh sách các nhóm danh mục của quán ăn thành công
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
    # Lấy danh sách danh mục theo quán ăn cụ thể
    return CategoryService.get_categories(
        db=db,
        restaurant_id=restaurant_id,
        is_active_only=is_active_only,
    )


# [POSTMAN GUIDE]
# GET http://localhost:8001/api/v1/categories/1
# Headers: (Không yêu cầu)
# Đầu vào (Path Param):
#   - category_id: 1 (int, bắt buộc)
# Status Code gợi ý:
#   - 200 OK       : Chi tiết một danh mục món ăn thành công
#   - 404 Not Found: Không tìm thấy danh mục món ăn
@router.get(
    "/categories/{category_id}",
    response_model=CategoryResponse,
    summary="Chi tiết một danh mục món ăn",
)
def get_category_detail(
    category_id: int = Path(..., description="ID danh mục"),
    db: Session = Depends(get_db),
):
    # Truy vấn chi tiết danh mục theo ID
    return CategoryService.get_category_by_id(db=db, category_id=category_id)


# [POSTMAN GUIDE]
# PUT http://localhost:8001/api/v1/categories/1
# Headers:
#   Content-Type: application/json
# Đầu vào (Path Param):
#   - category_id: 1 (int, bắt buộc)
# Đầu vào (Body raw JSON):
# {
#   "name": "Cơm & Mì Phở",  // string (tuỳ chọn)
#   "display_order": 1,      // int (tuỳ chọn)
#   "is_active": true        // bool (tuỳ chọn)
# }
# Status Code gợi ý:
#   - 200 OK                   : Cập nhật danh mục món ăn thành công
#   - 404 Not Found            : Không tìm thấy danh mục
#   - 422 Unprocessable Content: Dữ liệu cập nhật không hợp lệ
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
    # Cập nhật thông tin danh mục qua service
    return CategoryService.update_category(
        db=db,
        category_id=category_id,
        data=category_in,
    )


# [POSTMAN GUIDE]
# DELETE http://localhost:8001/api/v1/categories/1
# Headers: (Không yêu cầu)
# Đầu vào (Path Param):
#   - category_id: 1 (int, bắt buộc)
# Status Code gợi ý:
#   - 200 OK       : Xoá danh mục món ăn thành công
#   - 404 Not Found: Không tìm thấy danh mục món ăn cần xoá
@router.delete(
    "/categories/{category_id}",
    summary="Xoá danh mục món ăn",
)
def delete_category(
    category_id: int = Path(..., description="ID danh mục cần xoá"),
    db: Session = Depends(get_db),
):
    # 1. Gọi service xoá danh mục và gán category_id = None cho các món liên quan
    CategoryService.delete_category(
        db=db,
        category_id=category_id,
    )
    # 2. Trả về thông báo hoàn tất
    return {"message": f"Danh mục {category_id} đã được xoá thành công. Các món ăn liên quan đã được chuyển thành chưa phân loại."}
