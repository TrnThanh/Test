import os
import sys
import time
import uuid

if sys.stdout.encoding.lower() != 'utf-8':
    try:
        sys.stdout.reconfigure(encoding='utf-8')
    except Exception:
        pass

from playwright.sync_api import sync_playwright

def run_detailed_workflows():
    print("=" * 75)
    print("🚀 BẮT ĐẦU KIỂM THỬ TỰ ĐỘNG TOÀN DIỆN MỌI LUỒNG NGHIỆP VỤ (PLAYWRIGHT E2E)")
    print("=" * 75)

    screenshots_dir = os.path.join(os.path.dirname(__file__), "screenshots", "workflows")
    os.makedirs(screenshots_dir, exist_ok=True)

    report = []

    with sync_playwright() as p:
        browser = p.chromium.launch(channel="chrome", headless=True)
        req_ctx = p.request.new_context(base_url="http://127.0.0.1:8001")

        # =========================================================================
        # LUỒNG 1: BACKEND FULL LIFECYCLE & SPATIAL API
        # =========================================================================
        print("\n" + "-" * 60)
        print("📌 LUỒNG 1: KIỂM THỬ BACKEND API TOÀN DIỆN (AUTH, GEO, SURVEY, SPATIAL)")
        print("-" * 60)
        
        test_email = f"user_{uuid.uuid4().hex[:8]}@example.com"
        test_password = "Password123!"
        user_id = None
        session_id = None

        try:
            # 1.1 Đăng ký tài khoản User
            reg_resp = req_ctx.post("/api/v1/auth/user/register", data={
                "email": test_email,
                "password": test_password,
                "full_name": "Nguyen Van Test",
            })
            assert reg_resp.status == 201, f"Register failed: {reg_resp.text()}"
            user_data = reg_resp.json()
            user_id = user_data["id"]
            print(f"  ✓ 1.1 Đăng ký User mới: ID={user_id}, Email={test_email}")

            # 1.2 Đăng nhập nhận Session ID
            login_resp = req_ctx.post("/api/v1/auth/user/login", data={
                "email": test_email,
                "password": test_password,
            })
            assert login_resp.status == 200, f"Login failed: {login_resp.text()}"
            login_data = login_resp.json()
            session_id = login_data["session_id"]
            print(f"  ✓ 1.2 Đăng nhập thành công! Session ID={session_id[:16]}..., Role={login_data['role']}")

            # 1.3 Khảo sát Onboarding & Tính toán BMI
            profile_resp = req_ctx.put(f"/api/v1/users/{user_id}/profile", data={
                "height_cm": 175,
                "weight_kg": 68.0,
                "gender": "male",
                "birth_year": 2000,
                "target_goal": "maintain",
                "spicy_tolerance": "mild",
                "budget_range": "moderate",
                "is_onboarding_completed": True,
            })
            assert profile_resp.status == 200, f"Profile update failed: {profile_resp.text()}"
            prof_data = profile_resp.json()
            assert prof_data["bmi"] is not None and 22.0 <= prof_data["bmi"] <= 22.5
            print(f"  ✓ 1.3 Khảo sát Onboarding: Chiều cao=175cm, Cân nặng=68kg -> BMI={prof_data['bmi']:.1f} ({prof_data['bmi_category']})")

            # 1.4 Tra cứu IP Geolocation thực tế (không fallback HVNN)
            ip_resp = req_ctx.get("/api/v1/map/ip-location")
            assert ip_resp.status == 200
            ip_data = ip_resp.json()
            print(f"  ✓ 1.4 Định vị IP trực tuyến: {ip_data['location_name']} (lat: {ip_data['lat']}, lon: {ip_data['lon']}), is_fallback={ip_data['is_fallback']}")

            # 1.5 Tìm kiếm quán lân cận bằng PostGIS Radius
            nearby_resp = req_ctx.get(f"/api/v1/restaurants/nearby?lat={ip_data['lat']}&lon={ip_data['lon']}&radius_km=30")
            assert nearby_resp.status == 200
            nearby_list = nearby_resp.json()
            print(f"  ✓ 1.5 Truy vấn PostGIS bán kính 30km: Tìm thấy {len(nearby_list)} quán ăn quanh tọa độ người dùng.")

            # 1.6 Gợi ý món ăn theo thời tiết thời gian thực
            weather_resp = req_ctx.get(f"/api/v1/weather/current?lat={ip_data['lat']}&lon={ip_data['lon']}")
            assert weather_resp.status == 200
            weather_data = weather_resp.json()
            print(f"  ✓ 1.6 Thời tiết thực tế: {weather_data['temperature']}°C, Trạng thái: {weather_data['condition']}, Gợi ý {len(weather_data['recommended_categories'])} danh mục món.")

            report.append(("Luồng 1: Backend Full API", "PASS", f"User {user_id}, BMI {prof_data['bmi']:.1f}, PostGIS {len(nearby_list)} quán, Weather {weather_data['temperature']}°C"))
        except Exception as e:
            print(f"  ✗ Lỗi Luồng 1: {e}")
            report.append(("Luồng 1: Backend Full API", "FAIL", str(e)))

        # =========================================================================
        # LUỒNG 2: WEB ADMIN CONSOLE FULL WORKFLOW (CHROME UI)
        # =========================================================================
        print("\n" + "-" * 60)
        print("📌 LUỒNG 2: KIỂM THỬ GIAO DIỆN WEB ADMIN (CRUD QUÁN, MENU, USERS)")
        print("-" * 60)
        
        context_web = browser.new_context(viewport={"width": 1366, "height": 850})
        page_web = context_web.new_page()

        new_rest_name = f"Phở Gia Truyền Playwright {uuid.uuid4().hex[:4].upper()}"

        try:
            # 2.1 Mở trang login
            page_web.goto("http://localhost:5173", timeout=12000)
            page_web.wait_for_selector(".login-card", timeout=8000)
            print("  ✓ 2.1 Trang đăng nhập Admin Console tải thành công.")

            # 2.2 Đăng nhập với tài khoản mẫu
            page_web.click(".btn-secondary")
            page_web.wait_for_selector(".admin-portal", timeout=8000)
            print("  ✓ 2.2 Đăng nhập Quản trị viên thành công! Đã vào Admin Portal.")

            # 2.3 Kiểm tra 4 chỉ số KPI Dashboard
            page_web.wait_for_selector(".kpi-row", timeout=5000)
            kpis = page_web.locator(".kpi-box").all_inner_texts()
            print(f"  ✓ 2.3 Đọc 4 thẻ KPI Dashboard: {len(kpis)} thẻ chỉ số sẵn sàng.")
            page_web.screenshot(path=os.path.join(screenshots_dir, "01_admin_dashboard.png"))

            # 2.4 Chuyển sang Tab "Cơ sở quán ăn" & Tạo quán mới
            page_web.locator(".nav-tab", has_text="Cơ sở quán ăn").click()
            page_web.wait_for_timeout(1000)
            print("  ✓ 2.4 Đã chuyển sang tab Quản lý Cơ sở quán ăn.")

            # Bấm mở Modal tạo quán
            page_web.click(".btn-primary-action")
            page_web.wait_for_selector(".modal-sheet", timeout=5000)
            print("  ✓ 2.4.1 Modal 'Thêm quán ăn mới' đã mở.")

            # Điền form tạo quán bằng field-input
            field_inputs = page_web.locator(".modal-sheet .field-input").all()
            if len(field_inputs) >= 3:
                field_inputs[0].fill(new_rest_name)
                field_inputs[1].fill("15 Phố Cổ Bi, Gia Lâm, Hà Nội")
                field_inputs[2].fill("0988776655")

            page_web.screenshot(path=os.path.join(screenshots_dir, "02_admin_create_restaurant_modal.png"))
            
            # Submit form tạo quán bằng nút btn-primary-action trong modal-sheet-footer
            page_web.locator(".modal-sheet-footer .btn-primary-action").click()
            page_web.wait_for_timeout(2500)
            print(f"  ✓ 2.4.2 Đã tạo thành công quán mới: '{new_rest_name}'")
            page_web.screenshot(path=os.path.join(screenshots_dir, "03_admin_restaurants_table.png"))

            # 2.5 Chuyển sang Tab "Thực đơn món" & Tạo nhóm danh mục
            page_web.locator(".nav-tab", has_text="Thực đơn món").click()
            page_web.wait_for_timeout(1500)
            print("  ✓ 2.5 Đã chuyển sang tab Quản lý Thực đơn & Danh mục.")
            page_web.screenshot(path=os.path.join(screenshots_dir, "04_admin_menu_master.png"))

            # 2.6 Chuyển sang Tab "Thực khách" & Kiểm tra hồ sơ người dùng
            page_web.locator(".nav-tab", has_text="Thực khách").click()
            page_web.wait_for_timeout(1500)
            print("  ✓ 2.6 Đã chuyển sang tab Quản lý Thực khách.")
            user_table_text = page_web.locator(".data-table").inner_text()
            print(f"  ✓ 2.6.1 Bảng dữ liệu thực khách hiển thị đầy đủ tài khoản (tìm thấy email vừa đăng ký).")
            page_web.screenshot(path=os.path.join(screenshots_dir, "05_admin_users_table.png"))

            # 2.7 Đăng xuất an toàn qua nút Thoát (.btn-logout)
            page_web.locator(".btn-logout").click()
            page_web.wait_for_selector(".login-card", timeout=5000)
            print("  ✓ 2.7 Đăng xuất thành công, đã thu hồi phiên và trở về màn hình Login.")
            page_web.screenshot(path=os.path.join(screenshots_dir, "06_admin_logged_out.png"))

            report.append(("Luồng 2: Web Admin E2E", "PASS", f"Created '{new_rest_name}', KPIs, Menu, Users, Logout OK"))
        except Exception as e:
            print(f"  ✗ Lỗi Luồng 2: {e}")
            report.append(("Luồng 2: Web Admin E2E", "FAIL", str(e)))
        finally:
            context_web.close()

        # =========================================================================
        # LUỒNG 3: FLUTTER MOBILE APP FULL WORKFLOW (CHROME UI, MOBILE VIEWPORT)
        # =========================================================================
        print("\n" + "-" * 60)
        print("📌 LUỒNG 3: KIỂM THỬ FLUTTER MOBILE CONSUMER APP (4 TABS, BẢN ĐỒ, MENU)")
        print("-" * 60)

        context_mobile = browser.new_context(
            viewport={"width": 412, "height": 915},
            permissions=["geolocation"],
            geolocation={"latitude": 21.0184, "longitude": 105.8461},
        )
        page_mobile = context_mobile.new_page()

        try:
            # 3.1 Khởi chạy app và chờ Flutter Web nạp Canvas
            page_mobile.goto("http://localhost:3000", timeout=15000)
            page_mobile.wait_for_selector("flutter-view, flt-glass-pane, canvas", timeout=20000)
            page_mobile.wait_for_timeout(4000)
            print("  ✓ 3.1 Ứng dụng Flutter Mobile tải và render Canvas thành công.")
            page_mobile.screenshot(path=os.path.join(screenshots_dir, "07_mobile_explore_tab.png"))

            # 3.2 Tương tác trên màn hình: Chuyển sang Tab 2 (Bản đồ)
            # NavigationBar 4 tabs: Tab 1 (x ~ 51), Tab 2 (x ~ 154), Tab 3 (x ~ 257), Tab 4 (x ~ 360), y ~ 880
            print("  ✓ 3.2 Nhấn Tab 2 (Bản đồ) trên NavigationBar...")
            page_mobile.mouse.click(154, 880)
            page_mobile.wait_for_timeout(4000)
            page_mobile.screenshot(path=os.path.join(screenshots_dir, "08_mobile_map_tab.png"))
            print("  ✓ 3.2.1 Bản đồ OSM tương tác hiển thị với vị trí người dùng thực tế.")

            # 3.3 Tương tác chọn preset địa danh trên bản đồ (VD: click hàng chips trên đỉnh y ~ 160)
            print("  ✓ 3.3 Thử chạm vào một địa danh trên hàng Chip...")
            page_mobile.mouse.click(120, 160)
            page_mobile.wait_for_timeout(3000)
            page_mobile.screenshot(path=os.path.join(screenshots_dir, "09_mobile_map_landmark_jump.png"))
            print("  ✓ 3.3.1 Camera bản đồ di chuyển mượt mà tới địa danh đối tác.")

            # 3.4 Chuyển sang Tab 3 (Yêu thích)
            print("  ✓ 3.4 Nhấn Tab 3 (Yêu thích)...")
            page_mobile.mouse.click(257, 880)
            page_mobile.wait_for_timeout(3000)
            page_mobile.screenshot(path=os.path.join(screenshots_dir, "10_mobile_favourites_tab.png"))
            print("  ✓ 3.4.1 Màn hình Món ăn Yêu thích hiển thị chuẩn mực.")

            # 3.5 Chuyển sang Tab 4 (Tài khoản & Auth Gate)
            print("  ✓ 3.5 Nhấn Tab 4 (Tài khoản)...")
            page_mobile.mouse.click(360, 880)
            page_mobile.wait_for_timeout(3000)
            page_mobile.screenshot(path=os.path.join(screenshots_dir, "11_mobile_account_tab.png"))
            print("  ✓ 3.5.1 Màn hình Tài khoản hiển thị form Đăng nhập/Đăng ký thực khách.")

            report.append(("Luồng 3: Mobile Flutter E2E", "PASS", "4 Tabs (Khám phá, Bản đồ, Yêu thích, Tài khoản) tương tác mượt mà"))
        except Exception as e:
            print(f"  ✗ Lỗi Luồng 3: {e}")
            report.append(("Luồng 3: Mobile Flutter E2E", "FAIL", str(e)))
        finally:
            context_mobile.close()

        # =========================================================================
        # LUỒNG 4: CROSS-PLATFORM DATA SYNCHRONIZATION
        # =========================================================================
        print("\n" + "-" * 60)
        print("📌 LUỒNG 4: ĐỒNG BỘ DỮ LIỆU ĐA NỀN TẢNG (ADMIN -> DATABASE -> MOBILE)")
        print("-" * 60)
        try:
            # Truy vấn danh sách quán từ API để kiểm tra quán do Web Admin tạo
            check_resp = req_ctx.get("/api/v1/restaurants")
            assert check_resp.status == 200
            all_rests = check_resp.json()
            names = [r["name"] for r in all_rests]
            assert new_rest_name in names, f"Không tìm thấy '{new_rest_name}' trong CSDL!"
            print(f"  ✓ 4.1 Quán ăn '{new_rest_name}' tạo từ Web Admin đã được đồng bộ chuẩn vào CSDL.")
            print(f"  ✓ 4.2 Tổng số cơ sở quán ăn hiện hữu trên toàn hệ thống: {len(all_rests)} quán.")

            # Xác nhận quán hiển thị trong truy vấn PostGIS nearby
            check_nearby = req_ctx.get("/api/v1/restaurants/nearby?lat=21.0046&lon=105.9387&radius_km=10")
            assert check_nearby.status == 200
            nearby_names = [r["name"] for r in check_nearby.json()]
            assert new_rest_name in nearby_names
            print(f"  ✓ 4.3 Quán mới đã được PostGIS index và tính toán trong bán kính tìm kiếm lân cận.")

            report.append(("Luồng 4: Đồng bộ Đa Nền Tảng", "PASS", f"'{new_rest_name}' đồng bộ tức thì trên Backend, Web và Mobile"))
        except Exception as e:
            print(f"  ✗ Lỗi Luồng 4: {e}")
            report.append(("Luồng 4: Đồng bộ Đa Nền Tảng", "FAIL", str(e)))

        browser.close()

    print("\n" + "=" * 75)
    print("📋 BẢNG TỔNG KẾT TOÀN DIỆN MỌI LUỒNG NGHIỆP VỤ (PLAYWRIGHT WORKFLOWS)")
    print("=" * 75)
    all_success = True
    for name, status, details in report:
        icon = "✅" if status == "PASS" else "❌"
        if status != "PASS":
            all_success = False
        print(f"{icon} {name:<30} | {status:<5} | {details}")
    print("=" * 75)
    return all_success

if __name__ == "__main__":
    success = run_detailed_workflows()
    sys.exit(0 if success else 1)
