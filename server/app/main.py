import logging
from contextlib import asynccontextmanager
from typing import AsyncGenerator

import httpx
from fastapi import FastAPI, Request, status
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.openapi.utils import get_openapi
from fastapi.responses import JSONResponse

from server.app.core.config import settings
from server.app.db.init_db import init_database
from server.app.services.map_service import map_service
from server.app.api.v1.router import api_router

logger = logging.getLogger(__name__)

# Bảng tra cứu tên trường dữ liệu sang tiếng Việt thân thiện
FIELD_NAME_MAP = {
    "email": "Email",
    "password": "Mật khẩu",
    "confirm_password": "Xác nhận mật khẩu",
    "full_name": "Họ và tên",
    "phone": "Số điện thoại",
    "name": "Tên",
    "price": "Giá tiền",
    "spicy_level": "Độ cay",
    "calories": "Lượng calo",
    "opening_time": "Giờ mở cửa",
    "closing_time": "Giờ đóng cửa",
    "latitude": "Vĩ độ (latitude)",
    "longitude": "Kinh độ (longitude)",
    "lat": "Vĩ độ (lat)",
    "lon": "Kinh độ (lon)",
    "radius_km": "Bán kính tìm kiếm (km)",
    "limit": "Giới hạn số lượng",
    "skip": "Số bản ghi bỏ qua",
    "query": "Từ khóa tìm kiếm",
    "category_id": "Danh mục",
    "meal_type_id": "Bữa ăn",
}


def format_validation_error_message(err: dict) -> str:
    """Chuyển đổi từng lỗi Pydantic thô thành câu thông báo tiếng Việt trực quan, rõ ràng."""
    loc = err.get("loc", ())
    field_key = str(loc[-1]) if loc else ""
    field_label = FIELD_NAME_MAP.get(field_key, field_key)
    err_type = str(err.get("type", ""))
    raw_msg = str(err.get("msg", "")).strip()

    # Bỏ tiền tố lỗi mặc định của Pydantic nếu có
    if raw_msg.startswith("Value error, "):
        return raw_msg[len("Value error, "):].strip()

    if err_type == "missing":
        if field_key:
            return f"Thiếu trường {field_key}"
        return "Thiếu thông tin bắt buộc trong yêu cầu."

    if err_type == "string_too_short":
        min_length = err.get("ctx", {}).get("min_length")
        if min_length:
            return f"Trường '{field_label}' phải có tối thiểu {min_length} ký tự."
        return f"Trường '{field_label}' quá ngắn."

    if err_type == "string_too_long":
        max_length = err.get("ctx", {}).get("max_length")
        if max_length:
            return f"Trường '{field_label}' không được vượt quá {max_length} ký tự."
        return f"Trường '{field_label}' quá dài."

    if "greater_than" in err_type or "less_than" in err_type:
        return f"Trường '{field_label}' có giá trị không hợp lệ ({raw_msg})."

    if field_label:
        return f"Trường '{field_label}': {raw_msg}."
    return raw_msg

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

    # Xử lý ngoại lệ validate dữ liệu đầu vào: Loại bỏ JSON lồng phức tạp, trả về thông báo trực quan
    @app.exception_handler(RequestValidationError)
    async def validation_exception_handler(request: Request, exc: RequestValidationError) -> JSONResponse:
        """Xử lý ngoại lệ dữ liệu không hợp lệ (422) và trả về thông báo tiếng Việt trực quan, rõ ràng."""
        errors = exc.errors()
        missing_fields: list[str] = []
        other_messages: list[str] = []

        for err in errors:
            err_type = str(err.get("type", ""))
            loc = err.get("loc", ())
            field_key = str(loc[-1]) if loc else ""

            if err_type == "missing":
                if field_key and field_key not in missing_fields:
                    missing_fields.append(field_key)
            else:
                msg = format_validation_error_message(err)
                if msg and msg not in other_messages:
                    other_messages.append(msg)

        message_parts = []
        if missing_fields:
            missing_text = ", ".join(f"thiếu trường {k}" for k in missing_fields)
            missing_text = missing_text[0].upper() + missing_text[1:] if missing_text else ""
            message_parts.append(missing_text)
        if other_messages:
            message_parts.extend(other_messages)

        detail_msg = ". ".join(message_parts) if message_parts else "Dữ liệu yêu cầu không hợp lệ. Vui lòng kiểm tra lại."
        return JSONResponse(
            status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
            content={
                "message": detail_msg,
            },
        )

    # Tùy biến schema OpenAPI Swagger UI: Thay thế mẫu lỗi 422 lồng phức tạp bằng thông điệp trực quan
    def custom_openapi():
        """Tùy biến tài liệu OpenAPI Swagger UI: Đơn giản hóa cấu trúc lỗi Validation Error."""
        if app.openapi_schema:
            return app.openapi_schema
        openapi_schema = get_openapi(
            title=app.title,
            version=app.version,
            description=app.description,
            routes=app.routes,
            tags=app.openapi_tags,
        )
        if "components" in openapi_schema and "schemas" in openapi_schema["components"]:
            schemas = openapi_schema["components"]["schemas"]
            schemas["HTTPValidationError"] = {
                "title": "HTTPValidationError",
                "type": "object",
                "properties": {
                    "message": {
                        "title": "Thông điệp lỗi",
                        "type": "string",
                        "example": "Thiếu trường email, thiếu trường password",
                    },
                },
            }
            if "ValidationError" in schemas:
                del schemas["ValidationError"]
        app.openapi_schema = openapi_schema
        return app.openapi_schema

    app.openapi = custom_openapi

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
