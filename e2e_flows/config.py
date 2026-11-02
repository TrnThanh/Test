import os
from pathlib import Path

# Thư mục gốc dự án
BASE_DIR = Path(__file__).resolve().parent.parent
E2E_DIR = BASE_DIR / "e2e_flows"

# Thư mục lưu trữ kết quả
SCREENSHOTS_DIR = E2E_DIR / "screenshots"
REPORTS_DIR = E2E_DIR / "reports"

SCREENSHOTS_DIR.mkdir(parents=True, exist_ok=True)
REPORTS_DIR.mkdir(parents=True, exist_ok=True)

# Cấu hình địa chỉ mạng và cổng
BACKEND_HOST = "127.0.0.1"
BACKEND_PORT = 8001
BACKEND_URL = f"http://{BACKEND_HOST}:{BACKEND_PORT}"

WEB_ADMIN_HOST = "localhost"
WEB_ADMIN_PORT = 5174
WEB_ADMIN_URL = f"http://{WEB_ADMIN_HOST}:{WEB_ADMIN_PORT}"

MOBILE_WEB_HOST = "localhost"
MOBILE_WEB_PORT = 3000
MOBILE_WEB_URL = f"http://{MOBILE_WEB_HOST}:{MOBILE_WEB_PORT}"

# Cấu hình kiểm thử
DEFAULT_TIMEOUT_MS = 15000
HEADLESS_DEFAULT = True

# Viewports
DESKTOP_VIEWPORT = {"width": 1366, "height": 768}
MOBILE_VIEWPORT = {"width": 412, "height": 915}  # Chuẩn Google Pixel 7
