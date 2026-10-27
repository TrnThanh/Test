import os
import sys
import time

if sys.stdout.encoding.lower() != 'utf-8':
    try:
        sys.stdout.reconfigure(encoding='utf-8')
    except Exception:
        pass

from playwright.sync_api import sync_playwright

def run_e2e_tests():
    print("=" * 60)
    print("🚀 BẮT ĐẦU TEST E2E TOÀN DỰ ÁN PTC1 BẰNG PLAYWRIGHT")
    print("=" * 60)

    screenshots_dir = os.path.join(os.path.dirname(__file__), "screenshots")
    os.makedirs(screenshots_dir, exist_ok=True)

    results = []

    with sync_playwright() as p:
        browser = p.chromium.launch(channel="chrome", headless=True)
        
        # -------------------------------------------------------------
        # TEST 1: BACKEND SWAGGER UI & API ENDPOINTS (PORT 8001)
        # -------------------------------------------------------------
        print("\n[TEST 1] Kiểm thử Backend FastAPI Swagger UI (http://127.0.0.1:8001/docs)...")
        context_backend = browser.new_context()
        page_backend = context_backend.new_page()
        try:
            resp = page_backend.goto("http://127.0.0.1:8001/docs", timeout=10000)
            assert resp and resp.status == 200, f"HTTP status: {resp.status if resp else 'No response'}"
            page_backend.wait_for_selector(".swagger-ui", timeout=8000)
            title = page_backend.title()
            print(f"  ✓ Swagger UI tải thành công! Tiêu đề trang: '{title}'")
            
            screenshot_path = os.path.join(screenshots_dir, "backend_swagger.png")
            page_backend.screenshot(path=screenshot_path)
            print(f"  ✓ Đã chụp ảnh màn hình: {screenshot_path}")
            results.append(("Backend Swagger UI", "PASS", f"Status: 200, Title: {title}"))
        except Exception as e:
            print(f"  ✗ Lỗi Backend Swagger: {e}")
            results.append(("Backend Swagger UI", "FAIL", str(e)))
        finally:
            context_backend.close()

        # -------------------------------------------------------------
        # TEST 2: BACKEND LIVE API: IP LOCATION & RESTAURANTS
        # -------------------------------------------------------------
        print("\n[TEST 2] Kiểm thử Endpoint API /api/v1/map/ip-location & /api/v1/restaurants...")
        try:
            req_ctx = p.request.new_context(base_url="http://127.0.0.1:8001")
            
            # Kiểm tra ip-location
            ip_resp = req_ctx.get("/api/v1/map/ip-location")
            assert ip_resp.status == 200, f"ip-location status: {ip_resp.status}"
            ip_data = ip_resp.json()
            print(f"  ✓ IP Location: {ip_data.get('location_name')} (lat: {ip_data.get('lat')}, lon: {ip_data.get('lon')})")
            print(f"    is_fallback = {ip_data.get('is_fallback')}, query IP = {ip_data.get('ip')}")
            assert ip_data.get('is_fallback') is False, "is_fallback phải là False khi có mạng internet!"

            # Kiểm tra danh sách nhà hàng
            rest_resp = req_ctx.get("/api/v1/restaurants")
            assert rest_resp.status == 200, f"restaurants status: {rest_resp.status}"
            rest_data = rest_resp.json()
            print(f"  ✓ Danh sách quán ăn: Tìm thấy {len(rest_data)} cơ sở ẩm thực trong CSDL.")
            
            results.append(("Backend Live API", "PASS", f"IP: {ip_data.get('city')}, Quán ăn: {len(rest_data)}"))
        except Exception as e:
            print(f"  ✗ Lỗi Backend Live API: {e}")
            results.append(("Backend Live API", "FAIL", str(e)))

        # -------------------------------------------------------------
        # TEST 3: WEB ADMIN PORTAL (PORT 5173)
        # -------------------------------------------------------------
        print("\n[TEST 3] Kiểm thử Web Admin Console (http://localhost:5173)...")
        context_web = browser.new_context(viewport={"width": 1280, "height": 800})
        page_web = context_web.new_page()
        try:
            resp = page_web.goto("http://localhost:5173", timeout=10000)
            assert resp and resp.status == 200, "Vite dev server không phản hồi!"
            
            # Chờ form login xuất hiện
            page_web.wait_for_selector(".login-card", timeout=8000)
            print("  ✓ Trang đăng nhập Admin Console đã hiển thị.")
            screenshot_login = os.path.join(screenshots_dir, "web_admin_login.png")
            page_web.screenshot(path=screenshot_login)

            # Bấm nút đăng nhập nhanh mẫu
            page_web.click(".btn-secondary")
            print("  ✓ Đã bấm 'Đăng nhập nhanh với Tài Khoản Mẫu' (admin@example.com).")
            
            # Chờ chuyển hướng vào Admin Portal
            page_web.wait_for_selector(".admin-portal", timeout=8000)
            print("  ✓ Đăng nhập thành công! Đã vào Admin Portal.")

            # Kiểm tra các thẻ thống kê tổng quan (KPIs)
            page_web.wait_for_selector(".kpi-row", timeout=5000)
            stats_text = page_web.locator(".kpi-row").inner_text().replace("\n", " | ")
            print(f"  ✓ Chỉ số KPI thống kê: {stats_text}")

            screenshot_dash = os.path.join(screenshots_dir, "web_admin_dashboard.png")
            page_web.screenshot(path=screenshot_dash)
            print(f"  ✓ Đã chụp ảnh Dashboard: {screenshot_dash}")

            # Chuyển tab Cơ sở quán ăn
            page_web.locator(".nav-tab", has_text="Cơ sở quán ăn").click()
            page_web.wait_for_timeout(1000)
            screenshot_rest = os.path.join(screenshots_dir, "web_admin_restaurants.png")
            page_web.screenshot(path=screenshot_rest)
            print(f"  ✓ Chuyển tab Quán ăn thành công: {screenshot_rest}")

            # Chuyển tab Thực đơn món
            page_web.locator(".nav-tab", has_text="Thực đơn món").click()
            page_web.wait_for_timeout(1000)
            screenshot_menu = os.path.join(screenshots_dir, "web_admin_menu.png")
            page_web.screenshot(path=screenshot_menu)
            print(f"  ✓ Chuyển tab Thực đơn thành công: {screenshot_menu}")

            # Chuyển tab Thực khách
            page_web.locator(".nav-tab", has_text="Người dùng").click()
            page_web.wait_for_timeout(1000)
            screenshot_users = os.path.join(screenshots_dir, "web_admin_users.png")
            page_web.screenshot(path=screenshot_users)
            print(f"  ✓ Chuyển tab Người dùng thành công: {screenshot_users}")

            results.append(("Web Admin Portal", "PASS", f"Login, KPIs ({stats_text[:30]}...), Tabs 100% OK"))
        except Exception as e:
            print(f"  ✗ Lỗi Web Admin: {e}")
            results.append(("Web Admin Portal", "FAIL", str(e)))
        finally:
            context_web.close()

        # -------------------------------------------------------------
        # TEST 4: FLUTTER MOBILE CONSUMER APP (PORT 3000)
        # -------------------------------------------------------------
        print("\n[TEST 4] Kiểm thử Flutter Mobile App trên Web (http://localhost:3000)...")
        context_mobile = browser.new_context(
            viewport={"width": 412, "height": 915},  # Kích thước chuẩn điện thoại Pixel 7
            permissions=["geolocation"],
            geolocation={"latitude": 21.0184, "longitude": 105.8461},
        )
        page_mobile = context_mobile.new_page()
        try:
            resp = page_mobile.goto("http://localhost:3000", timeout=15000)
            assert resp and resp.status == 200, "Flutter Web không phản hồi!"
            
            # Chờ Flutter Web hoàn tất tải engine
            print("  ✓ Đang nạp Flutter Web Engine & Canvas...")
            page_mobile.wait_for_selector("flutter-view, flt-glass-pane, canvas", timeout=20000)
            page_mobile.wait_for_timeout(4000) # Đợi render hoàn tất
            
            print(f"  ✓ Flutter Web App đã tải thành công! Tiêu đề: '{page_mobile.title()}'")
            screenshot_mobile = os.path.join(screenshots_dir, "mobile_app_loaded.png")
            page_mobile.screenshot(path=screenshot_mobile)
            print(f"  ✓ Đã chụp ảnh màn hình ứng dụng Mobile: {screenshot_mobile}")

            # Thử click chuyển đổi tab trên NavigationBar (tọa độ phía dưới thanh điều hướng)
            # NavigationBar nằm ở đáy màn hình y ~ 880
            page_mobile.mouse.click(206, 880) # Click tab Bản đồ (khoảng giữa)
            page_mobile.wait_for_timeout(3000)
            screenshot_mobile_map = os.path.join(screenshots_dir, "mobile_app_tab_switch.png")
            page_mobile.screenshot(path=screenshot_mobile_map)
            print(f"  ✓ Đã tương tác chuyển tab bản đồ và chụp ảnh: {screenshot_mobile_map}")

            results.append(("Flutter Mobile App", "PASS", "Loaded, Render Canvas & Interactive OK"))
        except Exception as e:
            print(f"  ✗ Lỗi Mobile App: {e}")
            results.append(("Flutter Mobile App", "FAIL", str(e)))
        finally:
            context_mobile.close()

        browser.close()

    print("\n" + "=" * 60)
    print("📋 BẢNG TỔNG KẾT KẾT QUẢ KIỂM THỬ PLAYWRIGHT E2E")
    print("=" * 60)
    all_pass = True
    for name, status, details in results:
        icon = "✅" if status == "PASS" else "❌"
        if status != "PASS":
            all_pass = False
        print(f"{icon} {name:<22} | Trạng thái: {status:<5} | Chi tiết: {details}")

    print("=" * 60)
    return all_pass

if __name__ == "__main__":
    success = run_e2e_tests()
    sys.exit(0 if success else 1)
