from typing import List, Optional
from fastapi import APIRouter, Depends, Query, Path, status
from sqlalchemy.orm import Session

from server.app.db.session import get_db
from server.app.schemas.dish import DishCreate, DishUpdate, DishResponse, FavouriteDishResponse
from server.app.services.dish_service import DishService

router = APIRouter()


# --- QUẢN LÝ MÓN ĂN (DISHES) ---
@router.post(
    "/restaurants/{restaurant_id}/dishes",
    response_model=DishResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Tạo món ăn mới cho quán (Dành cho Seller)",
)
def create_dish(
    restaurant_id: int = Path(..., description="ID của quán ăn"),
    seller_id: int = Query(..., description="ID của Seller sở hữu quán"),
    dish_in: DishCreate = ...,
    db: Session = Depends(get_db),
):
    """
    Seller tạo món ăn mới cho quán ăn của mình:
    - Bắt buộc: `name`, `price >= 0`.
    - Tuỳ chọn: `category_id` (ID nhóm danh mục), `category` (nhóm món), `meal_type`, `tags`.
    """
    dish = DishService.create_dish(
        db=db,
        restaurant_id=restaurant_id,
        seller_id=seller_id,
        data=dish_in,
    )
    return DishService.to_dish_response(dish)


@router.get(
    "/restaurants/{restaurant_id}/dishes",
    response_model=List[DishResponse],
    summary="Lấy thực đơn của quán ăn (Có bộ lọc category_id, category, meal_type_id, meal_type, tag, ingredient)",
)
def get_restaurant_dishes(
    restaurant_id: int = Path(..., description="ID quán ăn"),
    category_id: Optional[int] = Query(None, description="Lọc theo ID nhóm danh mục"),
    category: Optional[str] = Query(None, description="Lọc theo tên nhóm món (vd: Món chính, Đồ uống)"),
    meal_type_id: Optional[int] = Query(None, description="Lọc theo ID loại bữa ăn"),
    meal_type: Optional[str] = Query(None, description="Lọc theo bữa ăn (breakfast, lunch, dinner, snack, all_day)"),
    tag: Optional[str] = Query(None, description="Lọc theo nhãn món ăn (vd: cay, chay, signature)"),
    ingredient: Optional[str] = Query(None, description="Lọc theo nguyên liệu món ăn (vd: Thịt bò, Nấm)"),
    available_only: bool = Query(True, description="Chỉ lấy món đang còn phục vụ"),
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=200),
    db: Session = Depends(get_db),
):
    """Lấy danh sách các món ăn trong thực đơn của một quán ăn."""
    dishes = DishService.get_dishes_by_restaurant(
        db=db,
        restaurant_id=restaurant_id,
        category_id=category_id,
        category=category,
        meal_type_id=meal_type_id,
        meal_type=meal_type,
        tag=tag,
        ingredient=ingredient,
        available_only=available_only,
        skip=skip,
        limit=limit,
    )
    return [DishService.to_dish_response(d) for d in dishes]



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
    return DishService.get_distinct_categories_by_restaurant(
        db=db,
        restaurant_id=restaurant_id,
    )


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
    dish = DishService.get_dish_by_id(db=db, dish_id=dish_id)
    return DishService.to_dish_response(dish)


@router.put(
    "/dishes/{dish_id}",
    response_model=DishResponse,
    summary="Cập nhật món ăn (Dành cho Seller)",
)
def update_dish(
    dish_id: int = Path(..., description="ID món ăn cần sửa"),
    seller_id: int = Query(..., description="ID của Seller sở hữu quán"),
    dish_in: DishUpdate = ...,
    db: Session = Depends(get_db),
):
    """Cập nhật thông tin món ăn (kiểm tra quyền sở hữu)."""
    dish = DishService.update_dish(
        db=db,
        dish_id=dish_id,
        seller_id=seller_id,
        data=dish_in,
    )
    return DishService.to_dish_response(dish)



@router.delete(
    "/dishes/{dish_id}",
    summary="Xoá món ăn (Dành cho Seller)",
)
def delete_dish(
    dish_id: int = Path(..., description="ID món ăn cần xoá"),
    seller_id: int = Query(..., description="ID của Seller sở hữu quán"),
    db: Session = Depends(get_db),
):
    """Xoá một món ăn khỏi thực đơn quán."""
    DishService.delete_dish(db=db, dish_id=dish_id, seller_id=seller_id)
    return {"message": f"Món ăn với ID {dish_id} đã được xoá thành công."}


# --- MÓN ĂN YÊU THÍCH (FAVOURITE DISHES - Bỏ trường tag) ---
@router.post(
    "/users/{user_id}/favourites/{dish_id}",
    response_model=FavouriteDishResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Thêm món ăn vào danh sách yêu thích của người dùng",
)
def add_favourite(
    user_id: int = Path(..., description="ID người dùng"),
    dish_id: int = Path(..., description="ID món ăn yêu thích"),
    db: Session = Depends(get_db),
):
    """Lưu món ăn yêu thích (idempotent, không còn trường tag)."""
    return DishService.add_favourite_dish(db=db, user_id=user_id, dish_id=dish_id)


@router.delete(
    "/users/{user_id}/favourites/{dish_id}",
    summary="Bỏ yêu thích món ăn",
)
def remove_favourite(
    user_id: int = Path(..., description="ID người dùng"),
    dish_id: int = Path(..., description="ID món ăn cần bỏ yêu thích"),
    db: Session = Depends(get_db),
):
    """Xoá món ăn khỏi danh sách yêu thích của người dùng."""
    DishService.remove_favourite_dish(db=db, user_id=user_id, dish_id=dish_id)
    return {"message": "Đã xoá món ăn khỏi danh sách yêu thích thành công."}


@router.get(
    "/users/{user_id}/favourites",
    response_model=List[FavouriteDishResponse],
    summary="Lấy danh sách món ăn yêu thích của người dùng",
)
def get_user_favourites(
    user_id: int = Path(..., description="ID người dùng"),
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    db: Session = Depends(get_db),
):
    """Lấy toàn bộ món ăn mà người dùng đã nhấn yêu thích kèm chi tiết món."""
    return DishService.get_user_favourite_dishes(db=db, user_id=user_id, skip=skip, limit=limit)
