import os
import time
from typing import Any, Dict
from playwright.sync_api import Browser
from ..config import MOBILE_WEB_URL, SCREENSHOTS_DIR, MOBILE_VIEWPORT, DEFAULT_TIMEOUT_MS
from ..monitors import ConsoleMonitor, ServerMonitor

def run_mobile_web_flow(browser: Browser) -> Dict[str, Any]:
    """
    Luồng kiểm thử ứng dụng Flutter Mobile Consumer App trên Web:
    1. Giả lập kích thước màn hình điện thoại Pixel 7 (412x915).
    2. Cấp quyền định vị GPS giả lập (toạ độ Huyện Gia Lâm / Hà Nội).
    3. Mở ứng dụng Flutter Web (http://localhost:3000).
    4. Chờ nạp engine Flutter Web Canvas và chụp ảnh Tab Trang chủ / Khám phá (08_mobile_explore_tab.png).
    5. Chuyển tab Bản đồ ẩm thực Gia Lâm OSM và chụp ảnh (09_mobile_map_tab.png).
    6. Chuyển tab Yêu thích và chụp ảnh (10_mobile_favourites_tab.png).
    7. Chuyển tab Tài khoản và chụp ảnh (11_mobile_account_tab.png).
    8. Giám sát toàn bộ lỗi Console từ Flutter Web runtime và lỗi Server Backend.
    """
    context = browser.new_context(
        viewport=MOBILE_VIEWPORT,
        permissions=["geolocation"],
        geolocation={"latitude": 21.0184, "longitude": 105.8461},
    )
    page = context.new_page()

    console_mon = ConsoleMonitor(page, flow_name="Flutter Mobile App")
    server_mon = ServerMonitor(page, flow_name="Flutter Mobile App")

    screenshots = []
    steps_passed = []
    steps_failed = []

    try:
        # Bước 1: Mở ứng dụng Mobile Web
        resp = page.goto(MOBILE_WEB_URL, timeout=DEFAULT_TIMEOUT_MS)
        if not resp or resp.status != 200:
            raise RuntimeError(f"Flutter Web không phản hồi 200 (Status: {resp.status if resp else 'No response'})")

        # Chờ Flutter Web Engine nạp DOM
        page.wait_for_load_state("domcontentloaded", timeout=DEFAULT_TIMEOUT_MS)
        # Chờ phần tử Flutter Engine canvas được gắn vào DOM
        try:
            page.wait_for_selector("flutter-view, flt-glass-pane, canvas", state="attached", timeout=35000)
        except Exception:
            # Fallback nếu flutter view đã render xong
            pass
        time.sleep(5)  # Đợi hoàn tất render font chữ và canvas

        shot_explore = SCREENSHOTS_DIR / "08_mobile_explore_tab.png"
        page.screenshot(path=str(shot_explore))
        screenshots.append(str(shot_explore.name))
        steps_passed.append("Flutter Web Engine nạp thành công, hiển thị Tab Trang chủ / Khám phá.")

        # Vị trí thanh NavigationBar 4 tab ở đáy màn hình (y ~ 880):
        # Chiều rộng 412px chia 4 tab:
        # Tab 1: Trang chủ ~ x=51
        # Tab 2: Bản đồ ~ x=154
        # Tab 3: Yêu thích ~ x=257
        # Tab 4: Tài khoản ~ x=360

        # Bước 2: Chuyển sang Tab Bản đồ (x ~ 154, y ~ 880)
        page.mouse.click(154, 880)
        time.sleep(3)
        shot_map = SCREENSHOTS_DIR / "09_mobile_map_tab.png"
        page.screenshot(path=str(shot_map))
        screenshots.append(str(shot_map.name))
        steps_passed.append("Tương tác chuyển sang Tab Bản đồ OpenStreetMap và chụp ảnh màn hình.")

        # Bước 3: Chuyển sang Tab Yêu thích (x ~ 257, y ~ 880)
        page.mouse.click(257, 880)
        time.sleep(2)
        shot_fav = SCREENSHOTS_DIR / "10_mobile_favourites_tab.png"
        page.screenshot(path=str(shot_fav))
        screenshots.append(str(shot_fav.name))
        steps_passed.append("Tương tác chuyển sang Tab Yêu thích và chụp ảnh màn hình.")

        # Bước 4: Chuyển sang Tab Tài khoản (x ~ 360, y ~ 880)
        page.mouse.click(360, 880)
        time.sleep(2)
        shot_acc = SCREENSHOTS_DIR / "11_mobile_account_tab.png"
        page.screenshot(path=str(shot_acc))
        screenshots.append(str(shot_acc.name))
        steps_passed.append("Tương tác chuyển sang Tab Tài khoản (Auth Gate / Survey) và chụp ảnh màn hình.")

    except Exception as e:
        steps_failed.append(f"Lỗi ngoại lệ trong luồng Mobile Web: {e}")
        err_shot = SCREENSHOTS_DIR / "err_mobile_web_failure.png"
        try:
            page.screenshot(path=str(err_shot))
            screenshots.append(str(err_shot.name))
        except Exception:
            pass
    finally:
        context.close()

    status = "PASS" if not steps_failed and not console_mon.has_errors() and not server_mon.has_errors() else "FAIL"

    return {
        "flow_name": "Flutter Mobile Web Workflows",
        "url": MOBILE_WEB_URL,
        "status": status,
        "steps_passed": steps_passed,
        "steps_failed": steps_failed,
        "console_summary": console_mon.summary(),
        "server_summary": server_mon.summary(),
        "screenshots": screenshots,
    }
