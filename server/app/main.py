import logging
from contextlib import asynccontextmanager
from typing import AsyncGenerator
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from sqlalchemy import text
from server.app.core.config import settings
from server.app.db.base import Base
from server.app.db.session import engine, SessionLocal
from server.app.api.v1.router import api_router
from server.app.services.admin_service import AdminService
from server.app.services.user_service import UserService
from server.app.services.meal_type_service import MealTypeService
from server.app.services.weather_service import WeatherService
# Import models để Base.metadata nhận diện các bảng trước khi create_all
import server.app.models  # noqa: F401

logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator[None, None]:
    """Khởi tạo vòng đời ứng dụng: tự động tạo bảng PostgreSQL và seed admin, meal_types, weathers mặc định."""
    try:
        with engine.begin() as conn:
            conn.execute(text("CREATE EXTENSION IF NOT EXISTS postgis;"))
            conn.execute(text("ALTER TABLE IF EXISTS restaurants DROP COLUMN IF EXISTS seller_id CASCADE;"))
            conn.execute(text("DROP TABLE IF EXISTS sellers CASCADE;"))
            conn.execute(text("ALTER TABLE restaurants ADD COLUMN IF NOT EXISTS open_time TIME;"))
            conn.execute(text("ALTER TABLE restaurants ADD COLUMN IF NOT EXISTS close_time TIME;"))
        Base.metadata.create_all(bind=engine)
        # Tự động seed tài khoản Admin, MealTypes và Weathers mặc định
        with SessionLocal() as db:
            AdminService.seed_default_admin(db)
            UserService.seed_default_user(db)
            MealTypeService.seed_default_meal_types(db)
            WeatherService.seed_default_weathers(db)
        logger.info("Khởi tạo PostgreSQL tables và seed dữ liệu ban đầu thành công.")
    except Exception as exc:
        logger.warning("Không thể tự động tạo bảng DB khi khởi động: %s", exc)
    yield


openapi_tags = [
    {
        "name": "User Authentication",
        "description": "API đăng ký và đăng nhập dành cho khách hàng / người dùng thông thường.",
    },
    {
        "name": "Admin Authentication",
        "description": "API đăng nhập dành cho quản trị viên hệ thống (mặc định: admin@example.com / admin123).",
    },
]


def create_app() -> FastAPI:
    """Khởi tạo FastAPI app với giao diện Swagger UI tương tác."""
    app = FastAPI(
        title=settings.APP_NAME,
        version=settings.APP_VERSION,
        description="""
# Hệ thống PTC1 API Platform
Backend FastAPI chuẩn hoá phục vụ ứng dụng tìm kiếm quán ăn, thực đơn món ăn đa chiều,
dịch vụ bản đồ địa lý OpenStreetMap Geocoding và truy vấn không gian PostGIS.
        """,
        openapi_tags=openapi_tags,
        lifespan=lifespan,
    )

    # Cấu hình CORS để Web Frontend (Vue 3 / Vite) và Mobile App (Flutter) giao tiếp thông suốt
    app.add_middleware(
        CORSMiddleware,
        allow_origin_regex=r".*",
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    app.include_router(api_router, prefix="/api/v1")

    @app.get("/", tags=["Health Check"])
    def root():
        return {
            "app": settings.APP_NAME,
            "version": settings.APP_VERSION,
            "status": "online",
            "docs": "/docs",
            "redoc": "/redoc",
            "docs_url": "/docs",
        }

    return app


app = create_app()
