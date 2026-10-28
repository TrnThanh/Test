from typing import List, Optional
from fastapi import APIRouter, Depends, Query, Path, status
from sqlalchemy.orm import Session

from server.app.db.session import get_db
from server.app.schemas.dish import DishCreate, DishUpdate, DishResponse, FavouriteDishResponse
from server.app.services.dish_service import DishService

router = APIRouter()


# ==============================================================================
# PHÂN HỆ 1: Quản lý Món ăn (Dishes & Menu Management)
# ==============================================================================

# Tạo mới món ăn cho cơ sở ẩm thực kèm phân loại danh mục, độ cay và dị ứng
@router.post(
    "/restaurants/{restaurant_id}/dishes",
    response_model=DishResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Tạo món ăn mới cho quán",
)
def create_dish(
    restaurant_id: int = Path(..., description="ID của quán ăn"),
    dish_in: DishCreate = ...,
    db: Session = Depends(get_db),
):
    """
    Tạo món ăn mới cho quán ăn:
    - Bắt buộc: `name`, `price >= 0`.
    - Tuỳ chọn: `category_id`, `category`, `spicy_level`, `dietary_tags`, `meal_types`, `allergens`, `ingredients`.
    """
    # 1. Gọi service để kiểm tra dữ liệu và thêm món ăn vào CSDL
    dish = DishService.create_dish(
        db=db,
        restaurant_id=restaurant_id,
        data=dish_in,
    )
    # 2. Chuyển đổi thực thể ORM sang schema DishResponse chuẩn
    return DishService.to_dish_response(dish)


# Lấy danh sách thực đơn món ăn của quán theo nhiều tiêu chí lọc linh hoạt
@router.get(
    "/restaurants/{restaurant_id}/dishes",
    response_model=List[DishResponse],
    summary="Lấy thực đơn của quán ăn (Có bộ lọc category_id, category, spicy_level, dietary_tag, meal_type, allergen, ingredient)",
)
def get_restaurant_dishes(
    restaurant_id: int = Path(..., description="ID quán ăn"),
    category_id: Optional[int] = Query(None, description="Lọc theo ID nhóm danh mục"),
    category: Optional[str] = Query(None, description="Lọc theo tên nhóm món (vd: Món chính, Đồ uống)"),
    spicy_level: Optional[int] = Query(None, ge=0, le=3, description="Lọc theo độ cay (0 đến 3)"),
    dietary_tag: Optional[str] = Query(None, description="Lọc món theo chế độ ăn (vegetarian, vegan, halal...)"),
    meal_type: Optional[str] = Query(None, description="Lọc theo bữa ăn (breakfast, lunch, dinner, snack, all_day)"),
    allergen: Optional[str] = Query(None, description="Loại trừ món có thành phần gây dị ứng này"),
    ingredient: Optional[str] = Query(None, description="Lọc theo nguyên liệu món ăn (vd: Thịt bò, Nấm)"),
    available_only: bool = Query(True, description="Chỉ lấy món đang còn phục vụ"),
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=200),
    db: Session = Depends(get_db),
):
    """Lấy danh sách các món ăn trong thực đơn của một quán ăn."""
    # 1. Truy vấn danh sách món ăn từ service theo các điều kiện lọc
    dishes = DishService.get_dishes_by_restaurant(
        db=db,
        restaurant_id=restaurant_id,
        category_id=category_id,
        category=category,
        spicy_level=spicy_level,
        dietary_tag=dietary_tag,
        meal_type=meal_type,
        allergen=allergen,
        ingredient=ingredient,
        available_only=available_only,
        skip=skip,
        limit=limit,
    )
    # 2. Format từng món ăn thành đối tượng DishResponse
    return [DishService.to_dish_response(d) for d in dishes]


# Lấy danh sách tên các nhóm món (categories) duy nhất của một quán ăn
@router.get(
    "/restaurants/{restaurant_id}/dish-categories",
    response_model=List[str],
    summary="Lấy danh sách nhóm món (category) của quán ăn",
)
def get_dish_categories(
    restaurant_id: int = Path(..., description="ID quán ăn"),
    db: Session = Depends(get_db),
):
    """Trả về danh sách các category duy nhất để gợi ý / autocomplete."""
    # Lấy danh sách chuỗi category duy nhất
    return DishService.get_distinct_categories_by_restaurant(
        db=db,
        restaurant_id=restaurant_id,
    )


# Xem chi tiết một món ăn cụ thể theo mã định danh ID
@router.get(
    "/dishes/{dish_id}",
    response_model=DishResponse,
    summary="Lấy thông tin chi tiết của món ăn theo ID",
)
def get_dish_detail(
    dish_id: int = Path(..., description="ID món ăn"),
    db: Session = Depends(get_db),
):
    """Xem chi tiết một món ăn cụ thể."""
    # 1. Tìm kiếm món ăn theo ID
    dish = DishService.get_dish_by_id(db=db, dish_id=dish_id)
    # 2. Trả về thông tin chi tiết
    return DishService.to_dish_response(dish)


# Cập nhật thông tin chi tiết của món ăn đã có
@router.put(
    "/dishes/{dish_id}",
    response_model=DishResponse,
    summary="Cập nhật món ăn",
)
def update_dish(
    dish_id: int = Path(..., description="ID món ăn cần sửa"),
    dish_in: DishUpdate = ...,
    db: Session = Depends(get_db),
):
    """Cập nhật thông tin món ăn."""
    # 1. Gọi service cập nhật các trường mới của món ăn
    dish = DishService.update_dish(
        db=db,
        dish_id=dish_id,
        data=dish_in,
    )
    # 2. Trả về thông tin món ăn sau khi cập nhật
    return DishService.to_dish_response(dish)


# Xoá một món ăn khỏi thực đơn của quán
@router.delete(
    "/dishes/{dish_id}",
    summary="Xoá món ăn",
)
def delete_dish(
    dish_id: int = Path(..., description="ID món ăn cần xoá"),
    db: Session = Depends(get_db),
):
    """Xoá một món ăn khỏi thực đơn quán."""
    # 1. Xoá món ăn khỏi cơ sở dữ liệu
    DishService.delete_dish(db=db, dish_id=dish_id)
    # 2. Trả về thông báo hoàn tất
    return {"message": f"Món ăn với ID {dish_id} đã được xoá thành công."}


# ==============================================================================
# PHÂN HỆ 2: Món ăn yêu thích (Favourite Dishes)
# ==============================================================================

# Lưu một món ăn vào danh sách yêu thích của người dùng
@router.post(
    "/users/{user_id}/favourites/{dish_id}",
    response_model=FavouriteDishResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Thực khách lưu món ăn vào danh sách yêu thích",
)
def add_dish_to_favourites(
    user_id: int = Path(..., description="ID người dùng"),
    dish_id: int = Path(..., description="ID món ăn yêu thích"),
    db: Session = Depends(get_db),
):
    """Lưu một món ăn vào danh sách yêu thích của người dùng (idempotent)."""
    # 1. Thêm bản ghi vào bảng favourite_dishes (đảm bảo tính idempotent)
    fav = DishService.add_to_favourites(db=db, user_id=user_id, dish_id=dish_id)
    # 2. Đóng gói kết quả phản hồi kèm thông tin món ăn
    return FavouriteDishResponse(
        id=fav.id,
        user_id=fav.user_id,
        dish_id=fav.dish_id,
        created_at=fav.created_at,
        dish=DishService.to_dish_response(fav.dish) if fav.dish else None,
    )


# Bỏ một món ăn khỏi danh sách yêu thích của người dùng
@router.delete(
    "/users/{user_id}/favourites/{dish_id}",
    summary="Thực khách bỏ lưu món ăn khỏi danh sách yêu thích",
)
def remove_dish_from_favourites(
    user_id: int = Path(..., description="ID người dùng"),
    dish_id: int = Path(..., description="ID món ăn cần bỏ yêu thích"),
    db: Session = Depends(get_db),
):
    """Bỏ một món ăn khỏi danh sách yêu thích."""
    # 1. Xoá bản ghi món yêu thích của người dùng
    DishService.remove_from_favourites(db=db, user_id=user_id, dish_id=dish_id)
    # 2. Trả về thông báo phản hồi
    return {"message": f"Đã bỏ món ăn ID {dish_id} khỏi danh sách yêu thích."}


# Lấy danh sách toàn bộ món ăn yêu thích của một người dùng
@router.get(
    "/users/{user_id}/favourites",
    response_model=List[FavouriteDishResponse],
    summary="Lấy danh sách món ăn yêu thích của thực khách",
)
def get_user_favourite_dishes(
    user_id: int = Path(..., description="ID người dùng"),
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    db: Session = Depends(get_db),
):
    """Xem danh sách các món ăn yêu thích của người dùng kèm thông tin chi tiết món."""
    # 1. Truy vấn các món yêu thích của người dùng theo phân trang
    favs = DishService.get_user_favourites(db=db, user_id=user_id, skip=skip, limit=limit)
    # 2. Map dữ liệu sang danh sách FavouriteDishResponse
    return [
        FavouriteDishResponse(
            id=f.id,
            user_id=f.user_id,
            dish_id=f.dish_id,
            created_at=f.created_at,
            dish=DishService.to_dish_response(f.dish) if f.dish else None,
        )
        for f in favs
    ]
