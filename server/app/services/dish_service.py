from typing import List, Optional
from fastapi import HTTPException, status
from sqlalchemy import select, distinct
from sqlalchemy.orm import Session, joinedload

from server.app.models.user import User
from server.app.models.restaurant import Restaurant
from server.app.models.category import Category
from server.app.models.dish import Dish
from server.app.models.favourite_dish import FavouriteDish
from server.app.schemas.dish import DishCreate, DishUpdate, DishResponse


class DishService:
    @staticmethod
    def to_dish_response(dish: Dish) -> DishResponse:
        cat_name = dish.category_rel.name if dish.category_rel else dish.category
        res = DishResponse.model_validate(dish)
        res.category_name = cat_name
        res.meal_type_name = ", ".join(dish.meal_types) if dish.meal_types else None
        return res

    @classmethod
    def create_dish(
        cls,
        db: Session,
        restaurant_id: int,
        data: DishCreate,
    ) -> Dish:
        """Tạo món ăn mới thuộc quán, liên kết danh mục toàn cục nếu có."""
        restaurant = db.get(Restaurant, restaurant_id)
        if not restaurant:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Không tìm thấy quán ăn với ID {restaurant_id}.",
            )

        category_str = data.category.strip() if data.category else None
        if data.category_id is not None:
            category = db.get(Category, data.category_id)
            if not category:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail=f"Không tìm thấy danh mục món ăn với ID {data.category_id}.",
                )
            if not category_str:
                category_str = category.name

        cleaned_ingredients = [i.strip() for i in data.ingredients if i.strip()] if data.ingredients else []
        cleaned_dietary = [d.strip() for d in data.dietary_tags if d.strip()] if data.dietary_tags else []
        cleaned_meal_types = [m.strip() for m in data.meal_types if m.strip()] if data.meal_types else []
        cleaned_allergens = [a.strip() for a in data.allergens if a.strip()] if data.allergens else []

        dish = Dish(
            restaurant_id=restaurant_id,
            category_id=data.category_id,
            category=category_str,
            spicy_level=data.spicy_level,
            dietary_tags=cleaned_dietary,
            meal_types=cleaned_meal_types,
            allergens=cleaned_allergens,
            ingredients=cleaned_ingredients,
            name=data.name.strip(),
            price=data.price,
            description=data.description.strip() if data.description else None,
            image_url=data.image_url.strip() if data.image_url else None,
            is_available=data.is_available,
        )
        db.add(dish)
        db.commit()
        db.refresh(dish)
        return cls.get_dish_by_id(db, dish.id)

    @staticmethod
    def get_dishes_by_restaurant(
        db: Session,
        restaurant_id: int,
        category_id: Optional[int] = None,
        category: Optional[str] = None,
        spicy_level: Optional[int] = None,
        dietary_tag: Optional[str] = None,
        meal_type: Optional[str] = None,
        allergen: Optional[str] = None,
        ingredient: Optional[str] = None,
        available_only: bool = True,
        skip: int = 0,
        limit: int = 100,
    ) -> List[Dish]:
        """Lấy danh sách các món ăn của một quán theo bộ lọc."""
        restaurant = db.get(Restaurant, restaurant_id)
        if not restaurant:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Không tìm thấy quán ăn với ID {restaurant_id}.",
            )

        stmt = (
            select(Dish)
            .options(joinedload(Dish.category_rel))
            .where(Dish.restaurant_id == restaurant_id)
        )
        if available_only:
            stmt = stmt.where(Dish.is_available.is_(True))
        if category_id is not None:
            stmt = stmt.where(Dish.category_id == category_id)
        if category:
            stmt = stmt.where(Dish.category == category.strip())
        if spicy_level is not None:
            stmt = stmt.where(Dish.spicy_level == spicy_level)
        if dietary_tag:
            stmt = stmt.where(Dish.dietary_tags.contains([dietary_tag.strip()]))
        if meal_type:
            stmt = stmt.where(Dish.meal_types.contains([meal_type.strip()]))
        if allergen:
            # Loại trừ món có chứa dị ứng này
            stmt = stmt.where(~Dish.allergens.contains([allergen.strip()]))
        if ingredient:
            stmt = stmt.where(Dish.ingredients.contains([ingredient.strip()]))

        stmt = stmt.order_by(Dish.category.asc().nulls_last(), Dish.id.asc()).offset(skip).limit(limit)
        return list(db.scalars(stmt).all())

    @staticmethod
    def get_dish_by_id(db: Session, dish_id: int) -> Dish:
        """Lấy chi tiết một món ăn theo ID."""
        stmt = (
            select(Dish)
            .options(joinedload(Dish.category_rel))
            .where(Dish.id == dish_id)
        )
        dish = db.scalar(stmt)
        if not dish:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Không tìm thấy món ăn với ID {dish_id}.",
            )
        return dish

    @classmethod
    def update_dish(
        cls,
        db: Session,
        dish_id: int,
        data: DishUpdate,
    ) -> Dish:
        """Cập nhật món ăn."""
        dish = db.get(Dish, dish_id)
        if not dish:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Không tìm thấy món ăn với ID {dish_id}.",
            )

        update_data = data.model_dump(exclude_unset=True)
        if "category_id" in update_data:
            cat_id = update_data["category_id"]
            if cat_id is not None:
                cat = db.get(Category, cat_id)
                if not cat:
                    raise HTTPException(
                        status_code=status.HTTP_404_NOT_FOUND,
                        detail=f"Không tìm thấy danh mục món ăn với ID {cat_id}.",
                    )
                if "category" not in update_data or not update_data["category"]:
                    dish.category = cat.name
                dish.category_id = cat_id
            else:
                dish.category_id = None

        for key, value in update_data.items():
            if key in ["category_id"]:
                continue
            if isinstance(value, str):
                value = value.strip()
            setattr(dish, key, value)

        db.commit()
        db.refresh(dish)
        return cls.get_dish_by_id(db, dish.id)

    @staticmethod
    def delete_dish(
        db: Session,
        dish_id: int,
    ) -> bool:
        """Xoá một món ăn."""
        dish = db.get(Dish, dish_id)
        if not dish:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Không tìm thấy món ăn với ID {dish_id}.",
            )

        db.delete(dish)
        db.commit()
        return True

    @staticmethod
    def get_distinct_categories_by_restaurant(
        db: Session,
        restaurant_id: int,
    ) -> List[str]:
        """Lấy danh sách các nhóm món (category) duy nhất của một quán ăn."""
        restaurant = db.get(Restaurant, restaurant_id)
        if not restaurant:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Không tìm thấy quán ăn với ID {restaurant_id}.",
            )
        stmt = (
            select(distinct(Dish.category))
            .where(Dish.restaurant_id == restaurant_id, Dish.category.is_not(None))
            .order_by(Dish.category.asc())
        )
        return [c for c in db.scalars(stmt).all() if c]

    # --- FAVOURITE DISHES (Dành cho User) ---
    @staticmethod
    def add_to_favourites(
        db: Session,
        user_id: int,
        dish_id: int,
    ) -> FavouriteDish:
        user = db.get(User, user_id)
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Không tìm thấy người dùng với ID {user_id}.",
            )
        dish = db.get(Dish, dish_id)
        if not dish:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Không tìm thấy món ăn với ID {dish_id}.",
            )

        stmt = select(FavouriteDish).where(
            FavouriteDish.user_id == user_id,
            FavouriteDish.dish_id == dish_id,
        )
        existing = db.scalar(stmt)
        if existing:
            return existing

        fav = FavouriteDish(
            user_id=user_id,
            dish_id=dish_id,
        )
        db.add(fav)
        db.commit()
        db.refresh(fav)
        return fav

    @staticmethod
    def remove_from_favourites(
        db: Session,
        user_id: int,
        dish_id: int,
    ) -> bool:
        stmt = select(FavouriteDish).where(
            FavouriteDish.user_id == user_id,
            FavouriteDish.dish_id == dish_id,
        )
        fav = db.scalar(stmt)
        if not fav:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Món ăn ID {dish_id} không nằm trong danh sách yêu thích của bạn.",
            )
        db.delete(fav)
        db.commit()
        return True

    @staticmethod
    def get_user_favourites(
        db: Session,
        user_id: int,
        skip: int = 0,
        limit: int = 50,
    ) -> List[FavouriteDish]:
        user = db.get(User, user_id)
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Không tìm thấy người dùng với ID {user_id}.",
            )
        stmt = (
            select(FavouriteDish)
            .options(
                joinedload(FavouriteDish.dish).joinedload(Dish.category_rel),
                joinedload(FavouriteDish.dish).joinedload(Dish.restaurant),
            )
            .where(FavouriteDish.user_id == user_id)
            .order_by(FavouriteDish.id.desc())
            .offset(skip)
            .limit(limit)
        )
        return list(db.scalars(stmt).all())
