import logging
from contextlib import asynccontextmanager
from typing import AsyncGenerator

import httpx
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from server.app.core.config import settings
from server.app.db.init_db import init_database
from server.app.services.map_service import map_service
from server.app.api.v1.router import api_router

logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator[None, None]:
    """Khởi tạo vòng đời ứng dụng: cấu hình HTTP client bản đồ và khởi tạo cơ sở dữ liệu."""
    shared_client = httpx.AsyncClient(timeout=5.0)
    map_service.set_route_client(shared_client)
    try:
        init_database()
        logger.info("Khởi tạo PostgreSQL tables và seed dữ liệu ban đầu thành công.")
    except Exception as exc:
        logger.warning("Không thể tự động tạo bảng DB khi khởi động: %s", exc)
    try:
        yield
    finally:
        await shared_client.aclose()
        map_service.set_route_client(None)


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
