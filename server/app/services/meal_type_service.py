from datetime import time
from typing import List, Optional
from sqlalchemy import select
from sqlalchemy.orm import Session
from fastapi import HTTPException, status

from server.app.models.meal_type import MealType
from server.app.schemas.meal_type import MealTypeCreate, MealTypeUpdate


DEFAULT_MEAL_TYPES = [
    {
        "code": "breakfast",
        "name": "Bữa sáng",
        "description": "Các món ăn nhẹ nhàng, giàu năng lượng cho buổi sáng.",
        "start_time": time(6, 0, 0),
        "end_time": time(10, 0, 0),
        "sort_order": 1,
    },
    {
        "code": "lunch",
        "name": "Bữa trưa",
        "description": "Các món cơm đĩa, phở bún đầy đủ dưỡng chất cho bữa trưa.",
        "start_time": time(11, 0, 0),
        "end_time": time(14, 0, 0),
        "sort_order": 2,
    },
    {
        "code": "dinner",
        "name": "Bữa tối",
        "description": "Các món ăn gia đình, lẩu nướng, món ấm cúng cho bữa tối.",
        "start_time": time(17, 30, 0),
        "end_time": time(21, 30, 0),
        "sort_order": 3,
    },
    {
        "code": "snack",
        "name": "Bữa xế / Ăn vặt",
        "description": "Trà sữa, bánh ngọt, đồ ăn vặt buổi chiều hoặc đêm.",
        "start_time": time(14, 30, 0),
        "end_time": time(17, 0, 0),
        "sort_order": 4,
    },
    {
        "code": "all_day",
        "name": "Cả ngày",
        "description": "Phục vụ suốt ngày, bất kỳ khung giờ nào.",
        "start_time": None,
        "end_time": None,
        "sort_order": 5,
    },
]


class MealTypeService:
    @staticmethod
    def seed_default_meal_types(db: Session) -> List[MealType]:
        """Tự động seed các loại bữa ăn cơ bản nếu chưa tồn tại."""
        results = []
        for item in DEFAULT_MEAL_TYPES:
            stmt = select(MealType).where(MealType.code == item["code"])
            existing = db.scalar(stmt)
            if not existing:
                mt = MealType(
                    code=item["code"],
                    name=item["name"],
                    description=item["description"],
                    start_time=item["start_time"],
                    end_time=item["end_time"],
                    sort_order=item["sort_order"],
                    is_active=True,
                )
                db.add(mt)
                results.append(mt)
            else:
                results.append(existing)
        db.commit()
        return results

    @staticmethod
    def get_all_meal_types(db: Session, active_only: bool = True) -> List[MealType]:
        """Lấy danh sách các loại bữa ăn sắp xếp theo sort_order."""
        stmt = select(MealType)
        if active_only:
            stmt = stmt.where(MealType.is_active.is_(True))
        stmt = stmt.order_by(MealType.sort_order.asc(), MealType.id.asc())
        return list(db.scalars(stmt).all())

    @staticmethod
    def get_meal_type_by_id(db: Session, meal_type_id: int) -> MealType:
        """Lấy chi tiết một loại bữa ăn."""
        mt = db.get(MealType, meal_type_id)
        if not mt:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Không tìm thấy loại bữa ăn với ID {meal_type_id}.",
            )
        return mt

    @staticmethod
    def create_meal_type(db: Session, data: MealTypeCreate) -> MealType:
        """Tạo mới một loại bữa ăn."""
        code_clean = data.code.strip().lower()
        stmt = select(MealType).where(MealType.code == code_clean)
        if db.scalar(stmt):
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"Mã bữa ăn '{code_clean}' đã tồn tại trong hệ thống.",
            )

        mt = MealType(
            code=code_clean,
            name=data.name.strip(),
            description=data.description.strip() if data.description else None,
            start_time=data.start_time,
            end_time=data.end_time,
            sort_order=data.sort_order,
            is_active=data.is_active,
        )
        db.add(mt)
        db.commit()
        db.refresh(mt)
        return mt
