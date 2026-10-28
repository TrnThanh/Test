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

# Quản lý vòng đời khởi động và dọn dẹp tài nguyên của ứng dụng FastAPI
@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator[None, None]:
    """Khởi tạo vòng đời ứng dụng: cấu hình HTTP client bản đồ và khởi tạo cơ sở dữ liệu."""
    # 1. Khởi tạo HTTP Client dùng chung cho dịch vụ bản đồ OSRM với timeout 5 giây
    shared_client = httpx.AsyncClient(timeout=5.0)
    # 2. Gán shared client vào singleton map_service
    map_service.set_route_client(shared_client)
    try:
        # 3. Khởi tạo cấu trúc bảng CSDL PostgreSQL và tự động nạp dữ liệu ban đầu
        init_database()
        logger.info("Khởi tạo PostgreSQL tables và seed dữ liệu ban đầu thành công.")
    except Exception as exc:
        logger.warning("Không thể tự động tạo bảng DB khi khởi động: %s", exc)
    try:
        # 4. Nhường quyền điều khiển cho server FastAPI hoạt động phục vụ request
        yield
    finally:
        # 5. Dọn dẹp tài nguyên: Đóng HTTP client khi server dừng
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

# Hàm khởi tạo và đóng gói cấu hình cho toàn bộ ứng dụng FastAPI
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

    # Đăng ký tập hợp các endpoint API phiên bản 1 (v1) với tiền tố /api/v1
    app.include_router(api_router, prefix="/api/v1")

    # Endpoint kiểm tra trạng thái sức khoẻ máy chủ (Health Check)
    @app.get("/", tags=["Health Check"])
    def root():
        """Trả về thông tin phiên bản hệ thống và các liên kết tài liệu Swagger / Redoc."""
        return {
            "app": settings.APP_NAME,
            "version": settings.APP_VERSION,
            "status": "online",
            "docs": "/docs",
            "redoc": "/redoc",
            "docs_url": "/docs",
        }

    return app

# Đối tượng ứng dụng FastAPI chính để Uvicorn nạp và thực thi
app = create_app()
