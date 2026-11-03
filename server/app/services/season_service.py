from typing import List, Optional
from sqlalchemy.orm import Session
from sqlalchemy import select, text
from server.app.models.season import Season


class SeasonService:
    DEFAULT_SEASONS = [
        {"id": 1, "code": "spring", "name": "Xuân", "description": "Mùa xuân ấm áp", "sort_order": 1},
        {"id": 2, "code": "summer", "name": "Hạ", "description": "Mùa hè nắng nóng", "sort_order": 2},
        {"id": 3, "code": "autumn", "name": "Thu", "description": "Mùa thu mát mẻ", "sort_order": 3},
        {"id": 4, "code": "winter", "name": "Đông", "description": "Mùa đông lạnh giá", "sort_order": 4},
    ]

    @classmethod
    def seed_default_seasons(cls, db: Session) -> int:
        """Đảm bảo 4 mùa cố định (1..4) luôn hiện diện trong bảng seasons."""
        count = 0
        for s in cls.DEFAULT_SEASONS:
            existing = db.get(Season, s["id"])
            if not existing:
                season = Season(
                    id=s["id"],
                    code=s["code"],
                    name=s["name"],
                    description=s["description"],
                    sort_order=s["sort_order"],
                    is_active=True,
                )
                db.add(season)
                count += 1
            else:
                existing.code = s["code"]
                existing.name = s["name"]
                existing.description = s["description"]
                existing.sort_order = s["sort_order"]
        db.commit()
        return count

    @classmethod
    def get_all_seasons(cls, db: Session, active_only: bool = True) -> List[Season]:
        cls.seed_default_seasons(db)
        stmt = select(Season).order_by(Season.sort_order, Season.id)
        if active_only:
            stmt = stmt.where(Season.is_active.is_(True))
        return list(db.scalars(stmt).all())

    @classmethod
    def get_by_id(cls, db: Session, season_id: int) -> Optional[Season]:
        cls.seed_default_seasons(db)
        return db.get(Season, season_id)
