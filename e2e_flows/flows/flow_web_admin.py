import os
import time
from typing import Any, Dict
from playwright.sync_api import Browser
from ..config import WEB_ADMIN_URL, SCREENSHOTS_DIR, DESKTOP_VIEWPORT, DEFAULT_TIMEOUT_MS
from ..monitors import ConsoleMonitor, ServerMonitor

def run_web_admin_flow(browser: Browser) -> Dict[str, Any]:
    """
    Luồng kiểm thử giao diện Web Admin Console:
    1. Mở trang đăng nhập (http://localhost:5173).
    2. Chụp ảnh màn hình Đăng nhập (02_web_admin_login.png).
    3. Thực hiện đăng nhập admin (admin@example.com / admin123).
    4. Kiểm tra trang Tổng quan (Dashboard) và chụp ảnh (03_web_admin_dashboard.png).
    5. Chuyển tab Cơ sở quán ăn và chụp ảnh (04_web_admin_restaurants.png).
    6. Chuyển tab Thực đơn món và chụp ảnh (05_web_admin_menus.png).
    7. Chuyển tab Người dùng / Tài khoản và chụp ảnh (06_web_admin_users.png).
    8. Chuyển tab Quy tắc thời tiết và chụp ảnh (07_web_admin_weather_rules.png).
    9. Thu thập toàn bộ log console (lỗi JS, cảnh báo) và phản hồi mạng từ server backend.
    """
    context = browser.new_context(viewport=DESKTOP_VIEWPORT)
    page = context.new_page()

    console_mon = ConsoleMonitor(page, flow_name="Web Admin Console")
    server_mon = ServerMonitor(page, flow_name="Web Admin Console")

    screenshots = []
    steps_passed = []
    steps_failed = []

    try:
        # Bước 1: Mở trang Web Admin
        resp = page.goto(WEB_ADMIN_URL, timeout=DEFAULT_TIMEOUT_MS)
        if not resp or resp.status != 200:
            raise RuntimeError(f"Vite dev server không phản hồi 200 (Status: {resp.status if resp else 'No response'})")
        
        # Chờ phần tử login hoặc dashboard xuất hiện
        page.wait_for_selector(".login-card, .app", timeout=DEFAULT_TIMEOUT_MS)
        time.sleep(1)

        # Kiểm tra xem đang ở màn hình nào
        if page.locator(".login-card").is_visible():
            shot_login = SCREENSHOTS_DIR / "02_web_admin_login.png"
            page.screenshot(path=str(shot_login))
            screenshots.append(str(shot_login.name))
            steps_passed.append("Hiển thị giao diện Đăng nhập Quản trị viên thành công.")

            # Bấm nút đăng nhập nhanh hoặc điền form
            fast_login_btn = page.locator("button:has-text('Đăng nhập nhanh với Tài Khoản Mẫu'), .btn-secondary")
            if fast_login_btn.is_visible():
                fast_login_btn.click()
            else:
                page.fill("#admin-email", "admin@example.com")
                page.fill("#admin-password", "admin123")
                page.click("button[type='submit']")

            page.wait_for_selector(".app", timeout=10000)
            steps_passed.append("Đăng nhập Admin thành công vào hệ thống.")
        else:
            steps_passed.append("Đã có phiên đăng nhập admin hợp lệ từ trước.")

        # Bước 2: Chụp ảnh Dashboard Tổng quan
        time.sleep(1)
        shot_dash = SCREENSHOTS_DIR / "03_web_admin_dashboard.png"
        page.screenshot(path=str(shot_dash))
        screenshots.append(str(shot_dash.name))
        steps_passed.append("Tải hoàn tất màn hình Dashboard Tổng quan (KPIs, Biểu đồ, Thống kê).")

        # Bước 3: Chuyển tab Cơ sở quán ăn
        rest_tab = page.locator("button.nav-btn:has-text('Cơ sở quán ăn')")
        if rest_tab.is_visible():
            rest_tab.click()
            time.sleep(1)
            shot_rest = SCREENSHOTS_DIR / "04_web_admin_restaurants.png"
            page.screenshot(path=str(shot_rest))
            screenshots.append(str(shot_rest.name))
            steps_passed.append("Chuyển tab Cơ sở quán ăn thành công và chụp ảnh màn hình.")
        else:
            steps_failed.append("Không tìm thấy nút điều hướng 'Cơ sở quán ăn'.")

        # Bước 4: Chuyển tab Thực đơn
        menu_tab = page.locator("button.nav-btn:has-text('Thực đơn')")
        if menu_tab.is_visible():
            menu_tab.click()
            time.sleep(1)
            shot_menu = SCREENSHOTS_DIR / "05_web_admin_menus.png"
            page.screenshot(path=str(shot_menu))
            screenshots.append(str(shot_menu.name))
            steps_passed.append("Chuyển tab Thực đơn món thành công và chụp ảnh màn hình.")
        else:
            steps_failed.append("Không tìm thấy nút điều hướng 'Thực đơn'.")

        # Bước 5: Chuyển tab Tài khoản / Người dùng
        users_tab = page.locator("button.nav-btn:has-text('Tài khoản'), button.nav-btn:has-text('Người dùng')")
        if users_tab.is_visible():
            users_tab.click()
            time.sleep(1)
            shot_users = SCREENSHOTS_DIR / "06_web_admin_users.png"
            page.screenshot(path=str(shot_users))
            screenshots.append(str(shot_users.name))
            steps_passed.append("Chuyển tab Tài khoản / Người dùng thành công và chụp ảnh màn hình.")
        else:
            steps_failed.append("Không tìm thấy nút điều hướng 'Tài khoản / Người dùng'.")

        # Bước 6: Chuyển tab Thời tiết & Gợi ý / Quy tắc
        weather_tab = page.locator("button.nav-btn:has-text('Thời tiết'), button.nav-btn:has-text('Quy tắc')")
        if weather_tab.is_visible():
            weather_tab.click()
            time.sleep(1)
            shot_weather = SCREENSHOTS_DIR / "07_web_admin_weather_rules.png"
            page.screenshot(path=str(shot_weather))
            screenshots.append(str(shot_weather.name))
            steps_passed.append("Chuyển tab Quy tắc thời tiết thành công và chụp ảnh màn hình.")

    except Exception as e:
        steps_failed.append(f"Lỗi ngoại lệ trong luồng Web Admin: {e}")
        # Chụp ảnh màn hình tại thời điểm bị lỗi
        err_shot = SCREENSHOTS_DIR / "err_web_admin_failure.png"
        try:
            page.screenshot(path=str(err_shot))
            screenshots.append(str(err_shot.name))
        except Exception:
            pass
    finally:
        context.close()

    status = "PASS" if not steps_failed and not console_mon.has_errors() and not server_mon.has_errors() else "FAIL"

    return {
        "flow_name": "Web Admin Console Workflows",
        "url": WEB_ADMIN_URL,
        "status": status,
        "steps_passed": steps_passed,
        "steps_failed": steps_failed,
        "console_summary": console_mon.summary(),
        "server_summary": server_mon.summary(),
        "screenshots": screenshots,
    }
