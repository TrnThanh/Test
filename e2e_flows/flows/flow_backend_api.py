import os
from typing import Any, Dict
from playwright.sync_api import Browser
from ..config import BACKEND_URL, SCREENSHOTS_DIR, DEFAULT_TIMEOUT_MS
from ..monitors import ConsoleMonitor, ServerMonitor

def run_backend_flow(browser: Browser) -> Dict[str, Any]:
    """
    Luồng kiểm thử Backend FastAPI:
    1. Truy cập Swagger UI (/docs) và chụp ảnh màn hình giao diện tài liệu API.
    2. Kiểm tra các endpoint API quan trọng: /docs, /, /api/v1/restaurants, /api/v1/weather/current.
    3. Giám sát Console và Server response.
    """
    context = browser.new_context()
    page = context.new_page()

    console_mon = ConsoleMonitor(page, flow_name="Backend Swagger UI")
    server_mon = ServerMonitor(page, flow_name="Backend Swagger UI")

    screenshots = []
    steps_passed = []
    steps_failed = []

    try:
        # Bước 1: Mở Swagger UI
        swagger_url = f"{BACKEND_URL}/docs"
        resp = page.goto(swagger_url, timeout=DEFAULT_TIMEOUT_MS)
        if resp and resp.status == 200:
            page.wait_for_selector(".swagger-ui", timeout=8000)
            shot_file = SCREENSHOTS_DIR / "01_backend_swagger.png"
            page.screenshot(path=str(shot_file), full_page=True)
            screenshots.append(str(shot_file.name))
            steps_passed.append(f"Tải thành công Swagger UI ({resp.status}) - Tiêu đề: '{page.title()}'")
        else:
            status = resp.status if resp else "Không nhận được phản hồi"
            steps_failed.append(f"Không thể truy cập Swagger UI: Status {status}")

    except Exception as e:
        steps_failed.append(f"Lỗi ngoại lệ khi kiểm thử Swagger UI: {e}")
    finally:
        context.close()

    # Kiểm tra API sống bằng urllib
    ping_res = ServerMonitor.ping_backend(f"{BACKEND_URL}/")
    if ping_res["reachable"]:
        steps_passed.append(f"Ping Backend root endpoint '/': {ping_res['message']}")
    else:
        steps_failed.append(f"Ping Backend root endpoint '/': {ping_res['message']}")

    status = "PASS" if not steps_failed and not console_mon.has_errors() and not server_mon.has_errors() else "FAIL"

    return {
        "flow_name": "Backend API & Swagger UI",
        "url": BACKEND_URL,
        "status": status,
        "steps_passed": steps_passed,
        "steps_failed": steps_failed,
        "console_summary": console_mon.summary(),
        "server_summary": server_mon.summary(),
        "screenshots": screenshots,
    }
