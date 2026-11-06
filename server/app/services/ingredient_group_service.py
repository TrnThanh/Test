from typing import List, Optional
from fastapi import HTTPException, status
from sqlalchemy import select, func, update
from sqlalchemy.orm import Session

from server.app.models.ingredient_group import IngredientGroup
from server.app.models.ingredient import Ingredient
from server.app.schemas.ingredient_group import (
    IngredientGroupCreate,
    IngredientGroupUpdate,
    IngredientGroupResponse,
)


class IngredientGroupService:
    @staticmethod
    def get_groups(
        db: Session,
        is_active_only: bool = False,
    ) -> List[IngredientGroupResponse]:
        """Lấy danh sách các nhóm nguyên liệu kèm số lượng nguyên liệu thuộc nhóm."""
        stmt = (
            select(
                IngredientGroup,
                func.count(Ingredient.id).label("ingredient_count"),
            )
            .outerjoin(Ingredient, Ingredient.group_id == IngredientGroup.id)
            .group_by(IngredientGroup.id)
            .order_by(IngredientGroup.display_order.asc(), IngredientGroup.name.asc())
        )

        if is_active_only:
            stmt = stmt.where(IngredientGroup.is_active == True)  # noqa: E712

        results = db.execute(stmt).all()
        items = []
        for grp, ing_count in results:
            res = IngredientGroupResponse(
                id=grp.id,
                name=grp.name,
                description=grp.description,
                display_order=grp.display_order,
                is_active=grp.is_active,
                created_at=grp.created_at,
                ingredient_count=ing_count,
            )
            items.append(res)
        return items

    @staticmethod
    def get_group_by_id(db: Session, group_id: int) -> IngredientGroupResponse:
        """Lấy chi tiết một nhóm nguyên liệu."""
        grp = db.get(IngredientGroup, group_id)
        if not grp:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Không tìm thấy nhóm nguyên liệu có ID {group_id}",
            )
        ing_count = db.scalar(
            select(func.count(Ingredient.id)).where(Ingredient.group_id == group_id)
        ) or 0
        return IngredientGroupResponse(
            id=grp.id,
            name=grp.name,
            description=grp.description,
            display_order=grp.display_order,
            is_active=grp.is_active,
            created_at=grp.created_at,
            ingredient_count=ing_count,
        )

    @staticmethod
    def create_group(db: Session, data: IngredientGroupCreate) -> IngredientGroupResponse:
        """Tạo mới nhóm nguyên liệu, kiểm tra trùng tên."""
        clean_name = data.name.strip()
        existing = db.scalar(
            select(IngredientGroup).where(func.lower(IngredientGroup.name) == clean_name.lower())
        )
        if existing:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Nhóm nguyên liệu '{clean_name}' đã tồn tại trong hệ thống.",
            )

        grp = IngredientGroup(
            name=clean_name,
            description=data.description.strip() if data.description else None,
            display_order=data.display_order,
            is_active=data.is_active,
        )
        db.add(grp)
        db.commit()
        db.refresh(grp)

        return IngredientGroupResponse(
            id=grp.id,
            name=grp.name,
            description=grp.description,
            display_order=grp.display_order,
            is_active=grp.is_active,
            created_at=grp.created_at,
            ingredient_count=0,
        )

    @staticmethod
    def update_group(
        db: Session, group_id: int, data: IngredientGroupUpdate
    ) -> IngredientGroupResponse:
        """Cập nhật thông tin nhóm nguyên liệu."""
        grp = db.get(IngredientGroup, group_id)
        if not grp:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Không tìm thấy nhóm nguyên liệu có ID {group_id}",
            )

        new_name = data.name.strip() if data.name is not None else None
        if new_name and new_name.lower() != grp.name.lower():
            dup = db.scalar(
                select(IngredientGroup).where(
                    func.lower(IngredientGroup.name) == new_name.lower(),
                    IngredientGroup.id != group_id,
                )
            )
            if dup:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Nhóm nguyên liệu '{new_name}' đã tồn tại.",
                )
            grp.name = new_name

        if data.description is not None:
            grp.description = data.description.strip() if data.description else None

        if data.display_order is not None:
            grp.display_order = data.display_order

        if data.is_active is not None:
            grp.is_active = data.is_active

        db.add(grp)
        db.commit()
        db.refresh(grp)

        ing_count = db.scalar(
            select(func.count(Ingredient.id)).where(Ingredient.group_id == group_id)
        ) or 0

        return IngredientGroupResponse(
            id=grp.id,
            name=grp.name,
            description=grp.description,
            display_order=grp.display_order,
            is_active=grp.is_active,
            created_at=grp.created_at,
            ingredient_count=ing_count,
        )

    @staticmethod
    def delete_group(db: Session, group_id: int, force: bool = False) -> None:
        """Xóa nhóm nguyên liệu. Nếu có nguyên liệu thuộc nhóm, chặn xóa trừ khi force=True."""
        grp = db.get(IngredientGroup, group_id)
        if not grp:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Không tìm thấy nhóm nguyên liệu có ID {group_id}",
            )

        ing_count = db.scalar(
            select(func.count(Ingredient.id)).where(Ingredient.group_id == group_id)
        ) or 0

        if ing_count > 0 and not force:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Không thể xóa nhóm '{grp.name}' vì đang có {ing_count} nguyên liệu thuộc nhóm này. Hãy chuyển các nguyên liệu sang nhóm khác hoặc chọn xóa bắt buộc.",
            )

        # Nếu force, gỡ liên kết group_id của các nguyên liệu thuộc nhóm này về NULL
        if ing_count > 0 and force:
            db.execute(
                update(Ingredient).where(Ingredient.group_id == group_id).values(group_id=None)
            )

        db.delete(grp)
        db.commit()
