from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from server.app.db.session import get_db
from server.app.schemas.season import SeasonResponse
from server.app.services.season_service import SeasonService

router = APIRouter()


@router.get(
    "",
    response_model=List[SeasonResponse],
    summary="Lấy danh sách 4 mùa chuẩn hóa",
    description="Truy vấn danh sách 4 mùa (Xuân, Hạ, Thu, Đông) ứng với 4 ID cố định (1..4).",
)
def list_seasons(
    active_only: bool = True,
    db: Session = Depends(get_db),
):
    return SeasonService.get_all_seasons(db, active_only=active_only)


@router.get(
    "/{season_id}",
    response_model=SeasonResponse,
    summary="Chi tiết một mùa",
    description="Lấy thông tin chi tiết của mùa theo ID (1: Xuân, 2: Hạ, 3: Thu, 4: Đông).",
)
def get_season(
    season_id: int,
    db: Session = Depends(get_db),
):
    season = SeasonService.get_by_id(db, season_id)
    if not season:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Không tìm thấy mùa có ID: {season_id}",
        )
    return season
