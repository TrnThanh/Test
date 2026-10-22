from typing import List, Optional
from fastapi import HTTPException, status
from sqlalchemy import select, func
from sqlalchemy.orm import Session
from server.app.models.category import Category
from server.app.models.dish import Dish
from server.app.schemas.category import CategoryCreate, CategoryUpdate, CategoryResponse


class CategoryService:
    @classmethod
    def create_category(
        cls, db: Session, data: CategoryCreate, restaurant_id: Optional[int] = None
    ) -> CategoryResponse:
        """Tạo danh mục mới toàn cục (Master Category). Tham số restaurant_id giữ lại để tương thích ngược."""
        # Kiểm tra trùng tên danh mục toàn hệ thống (không phân biệt hoa/thường)
        existing = db.execute(
            select(Category).where(
                func.lower(Category.name) == data.name.lower(),
            )
        ).scalar_one_or_none()
        if existing:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Danh mục '{data.name}' đã tồn tại trong hệ thống",
            )

        category = Category(
            name=data.name,
            description=data.description,
            display_order=data.display_order,
            is_active=data.is_active,
        )
        db.add(category)
        db.commit()
        db.refresh(category)

        res = CategoryResponse.model_validate(category)
        res.dish_count = 0
        return res

    @staticmethod
    def get_categories(
        db: Session, restaurant_id: Optional[int] = None, is_active_only: bool = False
    ) -> List[CategoryResponse]:
        """Lấy danh sách các nhóm danh mục (toàn cục hoặc theo quán ăn)."""
        query = select(Category)
        if restaurant_id is not None:
            # Lọc các danh mục mà quán này đang có món ăn phục vụ
            query = query.join(Dish, Dish.category_id == Category.id).where(Dish.restaurant_id == restaurant_id).distinct()
        if is_active_only:
            query = query.where(Category.is_active == True)  # noqa: E712
        query = query.order_by(Category.display_order.asc(), Category.id.asc())
        categories = db.execute(query).scalars().all()

        results: List[CategoryResponse] = []
        for cat in categories:
            dish_count_query = select(func.count(Dish.id)).where(Dish.category_id == cat.id)
            if restaurant_id is not None:
                dish_count_query = dish_count_query.where(Dish.restaurant_id == restaurant_id)
            dish_count = db.execute(dish_count_query).scalar() or 0

            cat_res = CategoryResponse.model_validate(cat)
            cat_res.dish_count = dish_count
            results.append(cat_res)
        return results

    @staticmethod
    def get_category_by_id(db: Session, category_id: int) -> CategoryResponse:
        cat = db.get(Category, category_id)
        if not cat:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Không tìm thấy danh mục món ăn",
            )
        dish_count = db.execute(
            select(func.count(Dish.id)).where(Dish.category_id == cat.id)
        ).scalar() or 0
        res = CategoryResponse.model_validate(cat)
        res.dish_count = dish_count
        return res

    @classmethod
    def update_category(
        cls, db: Session, category_id: int, data: CategoryUpdate
    ) -> CategoryResponse:
        cat = db.get(Category, category_id)
        if not cat:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Không tìm thấy danh mục món ăn",
            )

        update_dict = data.model_dump(exclude_unset=True)
        if "name" in update_dict and update_dict["name"] is not None:
            new_name = update_dict["name"]
            existing = db.execute(
                select(Category).where(
                    Category.id != cat.id,
                    func.lower(Category.name) == new_name.lower(),
                )
            ).scalar_one_or_none()
            if existing:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Danh mục '{new_name}' đã tồn tại trong hệ thống",
                )

        for key, value in update_dict.items():
            setattr(cat, key, value)

        db.commit()
        db.refresh(cat)

        dish_count = db.execute(
            select(func.count(Dish.id)).where(Dish.category_id == cat.id)
        ).scalar() or 0
        res = CategoryResponse.model_validate(cat)
        res.dish_count = dish_count
        return res

    @classmethod
    def delete_category(cls, db: Session, category_id: int) -> None:
        cat = db.get(Category, category_id)
        if not cat:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Không tìm thấy danh mục món ăn",
            )

        db.delete(cat)
        db.commit()
