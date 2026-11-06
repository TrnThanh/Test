from typing import Optional, List, Tuple, Set
from fastapi import HTTPException, status
from sqlalchemy import select, func, delete, text
from sqlalchemy.orm import Session

from server.app.models.ingredient import Ingredient, DishIngredient
from server.app.models.ingredient_group import IngredientGroup
from server.app.models.dish import Dish
from server.app.schemas.ingredient import (
    IngredientCreate,
    IngredientUpdate,
    IngredientResponse,
    IngredientDetailResponse,
    IngredientListResponse,
    DishSimpleResponse,
)


class IngredientService:
    @staticmethod
    def guess_allergen_group(name: str) -> Optional[str]:
        """Tự động suy luận nhóm dị ứng thực phẩm dựa trên tên nguyên liệu."""
        n = name.lower()
        if any(k in n for k in ["tôm", "cua", "cá", "ốc", "mực", "nghêu", "sò", "hàu", "nước mắm", "mắm tôm", "hải sản"]):
            return "Hải sản"
        if any(k in n for k in ["sữa", "bơ", "phô mai", "cheese"]):
            return "Sữa"
        if "trứng" in n:
            return "Trứng"
        if any(k in n for k in ["lạc", "đậu phộng"]):
            return "Đậu phộng"
        if any(k in n for k in ["đậu nành", "đậu phụ", "tàu hũ"]):
            return "Đậu nành"
        if any(k in n for k in ["bột mì", "bánh mì"]):
            return "Gluten"
        return None

    @staticmethod
    def guess_ingredient_group_id(db: Session, name: str) -> Optional[int]:
        """Tự động tìm ID nhóm nguyên liệu phù hợp với tên nguyên liệu."""
        n = name.lower()
        group_name = None
        if any(k in n for k in ["tôm", "cua", "cá", "ốc", "mực", "nghêu", "sò", "hàu", "nước mắm", "mắm tôm", "hải sản"]):
            group_name = "Hải sản"
        elif any(k in n for k in ["bò", "heo", "lợn", "bê", "dê", "cừu", "wagyu", "ba chỉ"]):
            group_name = "Thịt gia súc"
        elif any(k in n for k in ["gà", "vịt", "ngan", "cút"]):
            group_name = "Thịt gia cầm"
        elif any(k in n for k in ["sữa", "bơ", "phô mai", "cheese"]):
            group_name = "Sữa & Chế phẩm"
        elif "trứng" in n:
            group_name = "Trứng"
        elif any(k in n for k in ["lạc", "đậu phộng", "đậu nành", "đậu phụ", "hạt"]):
            group_name = "Đậu & Các loại hạt"
        elif any(k in n for k in ["bún", "phở", "mì", "bánh", "bột", "cơm"]):
            group_name = "Tinh bột & Ngũ cốc"
        elif any(k in n for k in ["nấm", "hành hoa", "rau", "củ", "quả", "cà rốt"]):
            group_name = "Rau củ & Nấm"
        elif any(k in n for k in ["gia vị", "sốt", "tiêu", "ớt", "tỏi"]):
            group_name = "Gia vị & Nước xốt"

        if group_name:
            return db.scalar(select(IngredientGroup.id).where(IngredientGroup.name == group_name))
        return None

    @staticmethod
    def get_allergen_options(db: Session) -> List[str]:
        """Lấy danh sách các nhóm và chất gây dị ứng thực phẩm từ cơ sở dữ liệu và hệ thống gợi ý."""
        allergens_set: Set[str] = set()

        # 1. Nhóm dị ứng đã khai báo trong bảng nguyên liệu ingredients
        try:
            ing_allergens = db.scalars(
                select(Ingredient.allergen_group)
                .where(Ingredient.allergen_group.is_not(None), Ingredient.allergen_group != "")
                .distinct()
            ).all()
            for a in ing_allergens:
                if a and str(a).strip():
                    allergens_set.add(str(a).strip())
        except Exception:
            pass

        # 2. Các thành phần dị ứng trong món ăn dishes
        try:
            dish_allergens = db.execute(
                text("SELECT DISTINCT unnest(allergens) FROM dishes WHERE allergens IS NOT NULL")
            ).scalars().all()
            for a in dish_allergens:
                if a and str(a).strip():
                    allergens_set.add(str(a).strip())
        except Exception:
            pass

        # 3. Kết hợp với các nhóm dị ứng chuẩn từ recommendation constants
        try:
            from server.app.services.recommendation_constants import ALLERGEN_GROUPS, VALID_ALLERGENS
            for a in VALID_ALLERGENS:
                if a and str(a).strip():
                    allergens_set.add(str(a).strip())
            for g in ALLERGEN_GROUPS.keys():
                if g and str(g).strip():
                    allergens_set.add(str(g).strip())
        except Exception:
            pass

        # 4. Đảm bảo các nhóm dị ứng chuẩn thực tế luôn hiện diện đầy đủ
        defaults = [
            "Hải sản", "Động vật có vỏ", "Tôm", "Cua đồng", "Cá", "Mực", "Ốc",
            "Đậu phộng", "Đậu nành", "Các loại hạt",
            "Trứng", "Sữa bò", "Phô mai", "Bơ (sữa)",
            "Gluten", "Mè (vừng)", "Trái cây", "Mắm tôm", "Nước mắm"
        ]
        for d in defaults:
            allergens_set.add(d)

        # 5. Sắp xếp: nhóm phổ biến ưu tiên đứng trước, các dị ứng khác xếp theo thứ tự bảng chữ cái
        priority_order = [
            "Hải sản", "Đậu phộng", "Trứng", "Sữa bò", "Gluten", "Đậu nành",
            "Động vật có vỏ", "Tôm", "Cá", "Mực", "Ốc", "Các loại hạt",
            "Phô mai", "Bơ (sữa)", "Mè (vừng)", "Trái cây"
        ]
        first_part = [item for item in priority_order if item in allergens_set]
        remaining = sorted([item for item in allergens_set if item not in first_part])
        return first_part + remaining

    @staticmethod
    def get_ingredients(
        db: Session,
        skip: int = 0,
        limit: int = 100,
        search: Optional[str] = None,
        group_id: Optional[int] = None,
        allergen_group: Optional[str] = None,
        is_active_only: bool = False,
    ) -> IngredientListResponse:
        """Lấy danh sách nguyên liệu kèm tên nhóm và số lượng món ăn sử dụng."""
        stmt = (
            select(
                Ingredient,
                IngredientGroup.name.label("group_name"),
                func.count(DishIngredient.id).label("dish_count"),
            )
            .outerjoin(IngredientGroup, Ingredient.group_id == IngredientGroup.id)
            .outerjoin(DishIngredient, DishIngredient.ingredient_id == Ingredient.id)
            .group_by(Ingredient.id, IngredientGroup.name)
        )

        if is_active_only:
            stmt = stmt.where(Ingredient.is_active == True)  # noqa: E712

        if group_id is not None:
            stmt = stmt.where(Ingredient.group_id == group_id)

        if allergen_group and allergen_group.strip():
            stmt = stmt.where(Ingredient.allergen_group == allergen_group.strip())

        if search and search.strip():
            keyword = f"%{search.strip().lower()}%"
            stmt = stmt.where(
                func.lower(Ingredient.name).like(keyword)
                | (Ingredient.description.is_not(None) & func.lower(Ingredient.description).like(keyword))
                | (IngredientGroup.name.is_not(None) & func.lower(IngredientGroup.name).like(keyword))
            )

        # Đếm tổng số lượng bản ghi thỏa mãn điều kiện
        count_stmt = select(func.count(Ingredient.id)).outerjoin(IngredientGroup, Ingredient.group_id == IngredientGroup.id)
        if is_active_only:
            count_stmt = count_stmt.where(Ingredient.is_active == True)  # noqa: E712
        if group_id is not None:
            count_stmt = count_stmt.where(Ingredient.group_id == group_id)
        if allergen_group and allergen_group.strip():
            count_stmt = count_stmt.where(Ingredient.allergen_group == allergen_group.strip())
        if search and search.strip():
            keyword = f"%{search.strip().lower()}%"
            count_stmt = count_stmt.where(
                func.lower(Ingredient.name).like(keyword)
                | (Ingredient.description.is_not(None) & func.lower(Ingredient.description).like(keyword))
                | (IngredientGroup.name.is_not(None) & func.lower(IngredientGroup.name).like(keyword))
            )
        total = db.scalar(count_stmt) or 0

        # Phân trang và sắp xếp theo tên A-Z
        stmt = stmt.order_by(Ingredient.name.asc()).offset(skip).limit(limit)
        results = db.execute(stmt).all()

        items = []
        for ing, grp_name, dish_count in results:
            res = IngredientResponse(
                id=ing.id,
                name=ing.name,
                description=ing.description,
                group_id=ing.group_id,
                group_name=grp_name,
                allergen_group=ing.allergen_group,
                is_active=ing.is_active,
                created_at=ing.created_at,
                dish_count=dish_count,
            )
            items.append(res)

        return IngredientListResponse(total=total, items=items)

    @staticmethod
    def get_ingredient_by_id(db: Session, ingredient_id: int) -> IngredientDetailResponse:
        """Lấy chi tiết một nguyên liệu kèm danh sách món ăn đang sử dụng."""
        ing = db.get(Ingredient, ingredient_id)
        if not ing:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Không tìm thấy nguyên liệu có ID {ingredient_id}",
            )

        # Lấy danh sách món ăn đang liên kết
        dishes_stmt = (
            select(Dish)
            .join(DishIngredient, DishIngredient.dish_id == Dish.id)
            .where(DishIngredient.ingredient_id == ingredient_id)
            .order_by(Dish.name.asc())
        )
        linked_dishes = db.scalars(dishes_stmt).all()
        grp_name = ing.group.name if ing.group else None

        return IngredientDetailResponse(
            id=ing.id,
            name=ing.name,
            description=ing.description,
            group_id=ing.group_id,
            group_name=grp_name,
            allergen_group=ing.allergen_group,
            is_active=ing.is_active,
            created_at=ing.created_at,
            dish_count=len(linked_dishes),
            dishes=[DishSimpleResponse.model_validate(d) for d in linked_dishes],
        )

    @staticmethod
    def create_ingredient(db: Session, data: IngredientCreate) -> IngredientResponse:
        """Tạo mới nguyên liệu, tự động gán group_id và allergen_group nếu chưa chọn."""
        clean_name = data.name.strip()
        existing = db.scalar(
            select(Ingredient).where(func.lower(Ingredient.name) == clean_name.lower())
        )
        if existing:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Nguyên liệu '{clean_name}' đã tồn tại trong hệ thống.",
            )

        group_id = data.group_id
        if not group_id:
            group_id = IngredientService.guess_ingredient_group_id(db, clean_name)

        allergen = data.allergen_group.strip() if data.allergen_group else None
        if not allergen:
            allergen = IngredientService.guess_allergen_group(clean_name)

        ing = Ingredient(
            name=clean_name,
            description=data.description.strip() if data.description else None,
            group_id=group_id,
            allergen_group=allergen,
            is_active=data.is_active,
        )
        db.add(ing)
        db.commit()
        db.refresh(ing)

        grp_name = db.scalar(select(IngredientGroup.name).where(IngredientGroup.id == ing.group_id)) if ing.group_id else None

        return IngredientResponse(
            id=ing.id,
            name=ing.name,
            description=ing.description,
            group_id=ing.group_id,
            group_name=grp_name,
            allergen_group=ing.allergen_group,
            is_active=ing.is_active,
            created_at=ing.created_at,
            dish_count=0,
        )

    @staticmethod
    def update_ingredient(
        db: Session, ingredient_id: int, data: IngredientUpdate
    ) -> IngredientResponse:
        """Cập nhật thông tin nguyên liệu và nhóm nguyên liệu."""
        ing = db.get(Ingredient, ingredient_id)
        if not ing:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Không tìm thấy nguyên liệu có ID {ingredient_id}",
            )

        old_name = ing.name
        new_name = data.name.strip() if data.name is not None else None

        if new_name and new_name.lower() != old_name.lower():
            duplicate = db.scalar(
                select(Ingredient).where(
                    func.lower(Ingredient.name) == new_name.lower(),
                    Ingredient.id != ingredient_id,
                )
            )
            if duplicate:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Nguyên liệu '{new_name}' đã tồn tại trong hệ thống.",
                )
            ing.name = new_name

        if data.description is not None:
            ing.description = data.description.strip() if data.description else None

        if data.group_id is not None:
            ing.group_id = data.group_id if data.group_id > 0 else None

        if data.allergen_group is not None:
            ing.allergen_group = data.allergen_group.strip() if data.allergen_group else None

        if data.is_active is not None:
            ing.is_active = data.is_active

        # Nếu đổi tên, đồng bộ lại mảng text dish.ingredients của các món ăn liên kết
        if new_name and new_name != old_name:
            linked_dishes = db.scalars(
                select(Dish)
                .join(DishIngredient, DishIngredient.dish_id == Dish.id)
                .where(DishIngredient.ingredient_id == ingredient_id)
            ).all()
            for dish in linked_dishes:
                if dish.ingredients:
                    dish.ingredients = [
                        new_name if x.strip().lower() == old_name.lower() else x
                        for x in dish.ingredients
                    ]
                    db.add(dish)

        db.add(ing)
        db.commit()
        db.refresh(ing)

        grp_name = db.scalar(select(IngredientGroup.name).where(IngredientGroup.id == ing.group_id)) if ing.group_id else None
        dish_count = db.scalar(
            select(func.count(DishIngredient.id)).where(
                DishIngredient.ingredient_id == ingredient_id
            )
        ) or 0

        return IngredientResponse(
            id=ing.id,
            name=ing.name,
            description=ing.description,
            group_id=ing.group_id,
            group_name=grp_name,
            allergen_group=ing.allergen_group,
            is_active=ing.is_active,
            created_at=ing.created_at,
            dish_count=dish_count,
        )

    @staticmethod
    def delete_ingredient(db: Session, ingredient_id: int, force: bool = False) -> None:
        """Xóa nguyên liệu khỏi hệ thống. Chặn xóa nếu có món đang dùng trừ khi force=True."""
        ing = db.get(Ingredient, ingredient_id)
        if not ing:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Không tìm thấy nguyên liệu có ID {ingredient_id}",
            )

        linked_dish_count = db.scalar(
            select(func.count(DishIngredient.id)).where(
                DishIngredient.ingredient_id == ingredient_id
            )
        ) or 0

        if linked_dish_count > 0 and not force:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=(
                    f"Không thể xóa nguyên liệu '{ing.name}' vì đang có {linked_dish_count} món ăn sử dụng. "
                    f"Vui lòng gỡ nguyên liệu này khỏi các món ăn trước, hoặc xác nhận xóa bắt buộc."
                ),
            )

        if linked_dish_count > 0 and force:
            linked_dishes = db.scalars(
                select(Dish)
                .join(DishIngredient, DishIngredient.dish_id == Dish.id)
                .where(DishIngredient.ingredient_id == ingredient_id)
            ).all()
            for dish in linked_dishes:
                if dish.ingredients:
                    dish.ingredients = [
                        x for x in dish.ingredients if x.strip().lower() != ing.name.lower()
                    ]
                    db.add(dish)

        db.execute(delete(DishIngredient).where(DishIngredient.ingredient_id == ingredient_id))
        db.delete(ing)
        db.commit()
