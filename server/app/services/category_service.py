from typing import List, Optional
from fastapi import HTTPException, status
from sqlalchemy import select, func
from sqlalchemy.orm import Session
from server.app.models.category import Category
from server.app.models.restaurant import Restaurant
from server.app.models.dish import Dish
from server.app.schemas.category import CategoryCreate, CategoryUpdate, CategoryResponse


class CategoryService:
    @classmethod
    def create_category(
        cls, db: Session, restaurant_id: int, data: CategoryCreate
    ) -> CategoryResponse:
        restaurant = db.get(Restaurant, restaurant_id)
        if not restaurant:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Không tìm thấy quán ăn với ID này",
            )

        # Kiểm tra trùng tên danh mục trong quán
        existing = db.execute(
            select(Category).where(
                Category.restaurant_id == restaurant_id,
                func.lower(Category.name) == data.name.lower(),
            )
        ).scalar_one_or_none()
        if existing:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Danh mục '{data.name}' đã tồn tại trong quán ăn này",
            )

        category = Category(
            restaurant_id=restaurant_id,
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
        db: Session, restaurant_id: int, is_active_only: bool = False
    ) -> List[CategoryResponse]:
        query = select(Category).where(Category.restaurant_id == restaurant_id)
        if is_active_only:
            query = query.where(Category.is_active == True)  # noqa: E712
        query = query.order_by(Category.display_order.asc(), Category.id.asc())
        categories = db.execute(query).scalars().all()

        results: List[CategoryResponse] = []
        for cat in categories:
            dish_count = db.execute(
                select(func.count(Dish.id)).where(Dish.category_id == cat.id)
            ).scalar() or 0
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
                    Category.restaurant_id == cat.restaurant_id,
                    Category.id != cat.id,
                    func.lower(Category.name) == new_name.lower(),
                )
            ).scalar_one_or_none()
            if existing:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Danh mục '{new_name}' đã tồn tại trong quán ăn này",
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
