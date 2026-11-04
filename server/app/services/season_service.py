from typing import List, Optional
from sqlalchemy.orm import Session
from sqlalchemy import select, text
from server.app.models.season import Season


class SeasonService:
    DEFAULT_SEASONS = [
        {
            "id": 1,
            "code": "spring",
            "name": "Xuân",
            "description": "Mùa xuân ấm áp",
            "start_date": "02-01",
            "end_date": "04-30",
            "sort_order": 1,
        },
        {
            "id": 2,
            "code": "summer",
            "name": "Hạ",
            "description": "Mùa hè nắng nóng",
            "start_date": "05-01",
            "end_date": "08-31",
            "sort_order": 2,
        },
        {
            "id": 3,
            "code": "autumn",
            "name": "Thu",
            "description": "Mùa thu mát mẻ",
            "start_date": "09-01",
            "end_date": "11-30",
            "sort_order": 3,
        },
        {
            "id": 4,
            "code": "winter",
            "name": "Đông",
            "description": "Mùa đông lạnh giá",
            "start_date": "12-01",
            "end_date": "01-31",
            "sort_order": 4,
        },
    ]

    @classmethod
    def seed_default_seasons(cls, db: Session) -> int:
        """Đảm bảo 4 mùa cố định (1..4) luôn hiện diện và cập nhật chu kỳ ngày bắt đầu/kết thúc."""
        count = 0
        for s in cls.DEFAULT_SEASONS:
            existing = db.get(Season, s["id"])
            if not existing:
                season = Season(
                    id=s["id"],
                    code=s["code"],
                    name=s["name"],
                    description=s["description"],
                    start_date=s["start_date"],
                    end_date=s["end_date"],
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
                if existing.start_date is None or existing.end_date is None:
                    existing.start_date = s["start_date"]
                    existing.end_date = s["end_date"]
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

    @classmethod
    def get_season_by_date(cls, db: Session, month: int, day: int) -> Optional[Season]:
        """Tra cứu mùa phù hợp theo tháng và ngày trong năm (định dạng MM-DD)."""
        cls.seed_default_seasons(db)
        target = f"{month:02d}-{day:02d}"
        seasons = cls.get_all_seasons(db, active_only=True)
        for s in seasons:
            if not s.start_date or not s.end_date:
                continue
            if s.start_date <= s.end_date:
                # Mùa trong năm dương lịch (Xuân: 02-01 đến 04-30, Hạ: 05-01 đến 08-31, Thu: 09-01 đến 11-30)
                if s.start_date <= target <= s.end_date:
                    return s
            else:
                # Mùa Đông vắt qua năm mới (12-01 đến 01-31)
                if target >= s.start_date or target <= s.end_date:
                    return s
        return None
