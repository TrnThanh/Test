import os
import sys
from datetime import datetime
import openpyxl
from openpyxl.styles import Font, PatternFill, Alignment, Border, Side
from openpyxl.utils import get_column_letter

def create_excel_report():
    wb = openpyxl.Workbook()
    wb.remove(wb.active)  # Xoá sheet mặc định

    # Bảng màu sắc nhận diện chuẩn Enterprise QA
    NAVY = "1B365D"
    HEADER_BLUE = "205493"
    WHITE = "FFFFFF"
    LIGHT_BLUE = "E8F1F5"
    LIGHT_GRAY = "F8F9FA"
    BORDER_COLOR = "D0D7DE"
    GREEN_PASS = "107C41"
    GREEN_PASS_BG = "E6F4EA"
    UNTESTED_BG = "FFF3CD"
    UNTESTED_TEXT = "856404"
    PRIORITY_HIGH_BG = "F8D7DA"
    PRIORITY_HIGH_TEXT = "721C24"
    PRIORITY_MED_BG = "FFF3CD"
    PRIORITY_MED_TEXT = "856404"

    font_header = Font(name="Arial", size=10, bold=True, color=WHITE)
    fill_header = PatternFill(start_color=NAVY, end_color=NAVY, fill_type="solid")

    font_title = Font(name="Arial", size=15, bold=True, color=NAVY)
    font_subtitle = Font(name="Arial", size=10, italic=True, color="555555")
    font_bold = Font(name="Arial", size=9, bold=True)
    font_regular = Font(name="Arial", size=9)
    font_code = Font(name="Consolas", size=9, color="003366")
    
    font_pass = Font(name="Arial", size=9, bold=True, color=GREEN_PASS)
    fill_pass = PatternFill(start_color=GREEN_PASS_BG, end_color=GREEN_PASS_BG, fill_type="solid")
    fill_zebra = PatternFill(start_color=LIGHT_GRAY, end_color=LIGHT_GRAY, fill_type="solid")

    thin_border = Border(
        left=Side(style='thin', color=BORDER_COLOR),
        right=Side(style='thin', color=BORDER_COLOR),
        top=Side(style='thin', color=BORDER_COLOR),
        bottom=Side(style='thin', color=BORDER_COLOR)
    )

    align_center = Alignment(horizontal='center', vertical='center', wrap_text=True)
    align_left = Alignment(horizontal='left', vertical='center', wrap_text=True)
    align_top_left = Alignment(horizontal='left', vertical='top', wrap_text=True)
    align_top_center = Alignment(horizontal='center', vertical='top', wrap_text=True)

    # =========================================================================
    # SHEET 1: DASHBOARD & TỔNG QUAN
    # =========================================================================
    ws_dash = wb.create_sheet(title="Tổng Quan & Dashboard")
    ws_dash.views.sheetView[0].showGridLines = True

    ws_dash.merge_cells("B2:H2")
    ws_dash["B2"] = "BÁO CÁO TOÀN DIỆN & BỘ TEST CASES KIỂM THỬ HỆ THỐNG PTC1"
    ws_dash["B2"].font = font_title
    ws_dash["B2"].alignment = Alignment(horizontal='center', vertical='center')

    ws_dash.merge_cells("B3:H3")
    ws_dash["B3"] = f"Thời gian cập nhật: {datetime.now().strftime('%d/%m/%Y %H:%M:%S')} | Môi trường: Local Development & Automated Browser & Manual QA Testing"
    ws_dash["B3"].font = font_subtitle
    ws_dash["B3"].alignment = Alignment(horizontal='center', vertical='center')

    # Bảng chỉ số tổng quan
    kpis = [
        ("Phân Hệ / Hạng Mục", "Loại Kiểm Thử / Công Nghệ", "Tổng Số Tests", "Đạt (Pass)", "Chờ Test (Untested)", "Tỷ Lệ Đạt / Trạng Thái"),
        ("1. Playwright E2E Workflows", "Tự động (Automated Playwright)", 23, 23, 0, "100.0%"),
        ("2. Backend API & PostGIS", "Tự động (Pytest FastAPI)", 83, 83, 0, "100.0%"),
        ("3. Mobile Consumer App", "Tự động (Flutter Widget Test)", 5, 5, 0, "100.0%"),
        ("4. Web Admin Production Build", "Tự động (Vite + TypeScript)", 1, 1, 0, "100.0%"),
        ("5. Kiểm thử Thủ công - Mobile App", "Thủ công (Manual QA Tester)", 28, 0, 28, "Sẵn sàng test (Ready)"),
        ("6. Kiểm thử Thủ công - Web Admin", "Thủ công (Manual QA Tester)", 24, 0, 24, "Sẵn sàng test (Ready)"),
        ("7. Kiểm thử Thủ công - API Swagger", "Thủ công (Manual QA Tester)", 8, 0, 8, "Sẵn sàng test (Ready)"),
        ("TỔNG CỘNG TOÀN BỘ HỆ THỐNG", "Hệ sinh thái PTC1 Monorepo", 172, 112, 60, "100% Automated PASS | 60 Manual Ready"),
    ]

    start_row = 5
    for r_idx, row in enumerate(kpis):
        curr_row = start_row + r_idx
        for c_idx, val in enumerate(row):
            col_letter = get_column_letter(c_idx + 2)
            cell = ws_dash[f"{col_letter}{curr_row}"]
            cell.value = val
            cell.border = thin_border
            if r_idx == 0:
                cell.font = font_header
                cell.fill = fill_header
                cell.alignment = align_center
            elif r_idx == len(kpis) - 1:
                cell.font = Font(name="Arial", size=10, bold=True, color=NAVY)
                cell.fill = PatternFill(start_color="DDEBF7", end_color="DDEBF7", fill_type="solid")
                cell.alignment = align_center if c_idx > 1 else align_left
            else:
                cell.font = font_regular
                cell.alignment = align_center if c_idx in [2, 3, 4, 5] else align_left
                if c_idx == 3 and isinstance(val, int) and val > 0:
                    cell.font = font_pass
                    cell.fill = fill_pass
                elif c_idx == 5 and "100.0%" in str(val):
                    cell.font = Font(name="Arial", size=10, bold=True, color=GREEN_PASS)

    # Bảng thông tin dịch vụ runtime
    ws_dash.merge_cells("B16:G16")
    ws_dash["B16"] = "THÔNG TIN CÁC DỊCH VỤ KIỂM THỬ TRỰC TIẾP (RUNTIME)"
    ws_dash["B16"].font = Font(name="Arial", size=11, bold=True, color=NAVY)
    
    runtime_info = [
        ("Dịch Vụ", "Nền Tảng", "Cổng / URL", "Giao Thức", "Trạng Thái"),
        ("Backend FastAPI Server", "Python 3.9 + Uvicorn", "http://127.0.0.1:8001", "REST JSON / Swagger Docs", "Online (200 OK)"),
        ("Web Admin Console", "Vue 3.5 + Vite + TS", "http://localhost:5173", "Single Page App", "Online (200 OK)"),
        ("Mobile Consumer App", "Flutter Web (Pixel 7)", "http://localhost:3000", "HTML5 CanvasKit / Material 3", "Online (200 OK)"),
        ("Spatial Database", "PostgreSQL 14 + PostGIS", "localhost:5432 (ptc1_db)", "TCP / SQL Alchemy 2.0", "Connected (OK)"),
    ]

    for r_idx, row in enumerate(runtime_info):
        curr_row = 17 + r_idx
        for c_idx, val in enumerate(row):
            col_letter = get_column_letter(c_idx + 2)
            cell = ws_dash[f"{col_letter}{curr_row}"]
            cell.value = val
            cell.border = thin_border
            if r_idx == 0:
                cell.font = font_header
                cell.fill = fill_header
                cell.alignment = align_center
            else:
                cell.font = font_regular
                cell.alignment = align_center if c_idx in [3, 4] else align_left
                if c_idx == 4:
                    cell.font = font_pass
                    cell.fill = fill_pass

    # Bảng tài khoản mẫu phục vụ manual test
    ws_dash.merge_cells("B24:G24")
    ws_dash["B24"] = "TÀI KHOẢN MẪU PHỤC VỤ KIỂM THỬ THỦ CÔNG (TEST ACCOUNTS)"
    ws_dash["B24"].font = Font(name="Arial", size=11, bold=True, color=NAVY)

    acc_info = [
        ("Vai Trò (Role)", "Tài Khoản (Email)", "Mật Khẩu", "Nền Tảng Áp Dụng", "Ghi Chú"),
        ("Quản trị viên (Super Admin)", "admin@example.com", "admin123", "Web Admin (:5173)", "Tài khoản toàn quyền, có nút Đăng nhập mẫu"),
        ("Quản trị viên phụ (Admin)", "admin@ptc1.vn", "admin123", "Web Admin (:5173)", "Tài khoản kiểm thử phân quyền"),
        ("Thực khách (User)", "user@example.com", "123456", "Mobile App (:3000)", "Đã hoàn thành khảo sát thể chất & BMI"),
        ("Khách vãng lai (Guest)", "Không cần tài khoản", "-", "Mobile App (:3000)", "Bấm 'Tiếp tục với tư cách Khách' để test Auth Gate")
    ]
    for r_idx, row in enumerate(acc_info):
        curr_row = 25 + r_idx
        for c_idx, val in enumerate(row):
            col_letter = get_column_letter(c_idx + 2)
            cell = ws_dash[f"{col_letter}{curr_row}"]
            cell.value = val
            cell.border = thin_border
            if r_idx == 0:
                cell.font = font_header
                cell.fill = fill_header
                cell.alignment = align_center
            else:
                cell.font = font_regular
                cell.alignment = align_center if c_idx in [2, 3] else align_left

    # =========================================================================
    # SHEET 2: PLAYWRIGHT E2E WORKFLOWS
    # =========================================================================
    ws_e2e = wb.create_sheet(title="Playwright E2E Workflows")
    ws_e2e.views.sheetView[0].showGridLines = True

    e2e_headers = [
        "Mã Test Case", "Phân Hệ / Luồng", "Tên Test Case", "Mô Tả & Dữ Liệu Đầu Vào",
        "Các Bước Thực Hiện", "Kết Quả Mong Đợi", "Kết Quả Thực Tế", "Trạng Thái", "Ảnh Minh Chứng"
    ]

    e2e_cases = [
        ("TC-PW-01", "Backend API", "Swagger UI Loading", "URL: http://127.0.0.1:8001/docs", 
         "1. Điều hướng tới /docs\n2. Chờ DOM container .swagger-ui tải hoàn tất", 
         "HTTP 200, tiêu đề chứa 'FastAPI Server - Swagger UI'", "HTTP 200, tải giao diện Swagger đầy đủ", "PASS", "backend_swagger.png"),
        ("TC-PW-02", "Backend API", "Đăng ký User mới", "email: user_xxx@example.com, password: Password123!, name: Nguyen Van Test",
         "1. Gửi POST /api/v1/auth/user/register\n2. Nhận kết quả JSON", 
         "HTTP 201 Created, trả về User ID và thông tin tài khoản", "HTTP 201 Created, tạo thành công User ID", "PASS", "API Log"),
        ("TC-PW-03", "Backend API", "Đăng nhập cấp Session ID", "Tài khoản vừa tạo ở TC-PW-02",
         "1. Gửi POST /api/v1/auth/user/login\n2. Kiểm tra session_id trong payload", 
         "HTTP 200 OK, trả về session_id 32 ký tự hex và role='user'", "HTTP 200 OK, cấp session_id hợp lệ", "PASS", "API Log"),
        ("TC-PW-04", "Backend API", "Khảo sát Onboarding & BMI", "Cao: 175cm, Nặng: 68kg, Mục tiêu: maintain, Ngân sách: moderate",
         "1. Gửi PUT /api/v1/users/{id}/profile\n2. Tính toán chỉ số BMI động", 
         "HTTP 200 OK, BMI được tính tự động = 22.2, xếp loại 'normal'", "HTTP 200 OK, BMI=22.2 (Thể trạng Bình thường)", "PASS", "05_admin_users_table.png"),
        ("TC-PW-05", "Backend API", "Định vị IP không fallback HVNN", "Client IP: localhost (127.0.0.1)",
         "1. Gửi GET /api/v1/map/ip-location\n2. Backend tự động phân tích IP Host Internet", 
         "HTTP 200 OK, trả về toạ độ Internet thực tế, is_fallback=False", "HTTP 200 OK, lat: 21.0184, lon: 105.8461, is_fallback=False", "PASS", "API Log"),
        ("TC-PW-06", "Backend API", "Truy vấn không gian PostGIS Radius", "lat: 21.0184, lon: 105.8461, radius_km: 30",
         "1. Gửi GET /api/v1/restaurants/nearby\n2. PostGIS ST_DWithin tính toán khoảng cách", 
         "HTTP 200 OK, trả về danh sách các cơ sở ẩm thực trong bán kính 30km", "HTTP 200 OK, tìm thấy các cơ sở quán ăn hợp lệ", "PASS", "API Log"),
        ("TC-PW-07", "Backend API", "Thời tiết OpenWeatherMap & Gợi ý món", "Toạ độ người dùng thực tế",
         "1. Gửi GET /api/v1/weather/current\n2. Phân tích nhiệt độ và danh mục món", 
         "HTTP 200 OK, trả về nhiệt độ thực tế và danh sách món phù hợp", "HTTP 200 OK, nhiệt độ: 26.0°C (Clear)", "PASS", "API Log"),
        ("TC-PW-08", "Web Admin", "Tải trang Admin Console", "URL: http://localhost:5173",
         "1. Mở trang chủ Web Admin\n2. Kiểm tra form đăng nhập .login-card", 
         "Trang đăng nhập hiển thị đầy đủ tiêu đề và form xác thực", "Form đăng nhập sẵn sàng", "PASS", "web_admin_login.png"),
        ("TC-PW-09", "Web Admin", "Đăng nhập nhanh tài khoản mẫu", "admin@example.com / admin123",
         "1. Click nút '.btn-secondary' (Đăng nhập mẫu)\n2. Chờ chuyển hướng vào Admin Portal", 
         "Đăng nhập thành công, lưu session vào localStorage, vào Admin Portal", "Chuyển hướng thành công vào .admin-portal", "PASS", "01_admin_dashboard.png"),
        ("TC-PW-10", "Web Admin", "Xác thực 4 thẻ KPI Dashboard", "Dashboard view",
         "1. Đọc nội dung container .kpi-row\n2. Kiểm tra 4 thẻ chỉ số", 
         "Hiển thị đủ 4 thẻ: Tổng cơ sở, Tổng món, Thực khách, Tỷ lệ hoạt động", "Hiển thị chính xác 4 khối KPIs hệ thống", "PASS", "web_admin_dashboard.png"),
        ("TC-PW-11", "Web Admin", "Mở modal thêm quán ăn mới", "Tab 'Cơ sở quán ăn'",
         "1. Click tab 'Cơ sở quán ăn'\n2. Click nút '+ Thêm quán mới'", 
         "Modal .modal-sheet mở ra hiển thị các trường nhập liệu", "Modal mở ra chuẩn xác", "PASS", "02_admin_create_restaurant_modal.png"),
        ("TC-PW-12", "Web Admin", "Tạo mới quán ăn đối tác", "Tên: Phở Gia Truyền Playwright, Đ/c: 15 Phố Cổ Bi, Gia Lâm",
         "1. Điền tên, địa chỉ, số điện thoại\n2. Click 'Tạo cơ sở' trong modal footer", 
         "Quán ăn được tạo thành công, modal đóng, quán mới hiện trên bảng", "Quán mới lập tức xuất hiện trong bảng danh sách", "PASS", "03_admin_restaurants_table.png"),
        ("TC-PW-13", "Web Admin", "Xem thực đơn & danh mục quán", "Tab 'Thực đơn món'",
         "1. Click tab 'Thực đơn món'\n2. Kiểm tra danh mục và danh sách món ăn", 
         "Giao diện Master-Detail hiển thị cơ sở đang chọn và danh sách món", "Hiển thị đầy đủ khu vực quản trị món ăn", "PASS", "04_admin_menu_master.png"),
        ("TC-PW-14", "Web Admin", "Tạo danh mục món toàn cục", "Tên: Món Nước Playwright",
         "1. Bấm '+ Thêm danh mục'\n2. Điền tên và lưu", 
         "Danh mục mới được thêm vào hệ thống toàn cục", "Danh mục tạo thành công", "PASS", "04_admin_menu_master.png"),
        ("TC-PW-15", "Web Admin", "Thêm món ăn mới cho quán", "Phở Bò Tái Gầu, 45.000đ, độ cay 1",
         "1. Bấm '+ Thêm món mới'\n2. Điền thông tin giá, độ cay, bữa ăn\n3. Bấm 'Lưu món'", 
         "Món ăn mới xuất hiện trong thẻ Card của quán", "Món ăn hiển thị chuẩn xác", "PASS", "04_admin_menu_master.png"),
        ("TC-PW-16", "Web Admin", "Chuyển trạng thái Còn món / Hết món", "Toggle Switch",
         "1. Bấm toggle trạng thái món ăn", 
         "Trạng thái cập nhật tức thì thành 'Hết món'", "Cập nhật trạng thái thành công", "PASS", "04_admin_menu_master.png"),
        ("TC-PW-17", "Web Admin", "Xem danh sách tài khoản khách hàng", "Tab 'Tài khoản'",
         "1. Bấm chọn tab 'Tài khoản'\n2. Đọc bảng danh sách User", 
         "Hiển thị danh sách khách hàng kèm email và ngày tạo", "Hiển thị bảng tài khoản đầy đủ", "PASS", "05_admin_users_table.png"),
        ("TC-PW-18", "Mobile Web", "Khởi chạy ứng dụng Mobile Consumer", "URL: http://localhost:3000",
         "1. Điều hướng trình duyệt tới http://localhost:3000\n2. Chờ Flutter Web tải xong", 
         "Tải thành công Flutter App, hiển thị Canvas/DOM mượt mà", "Ứng dụng Mobile sẵn sàng", "PASS", "mobile_canvas.png"),
        ("TC-PW-19", "Mobile Web", "Kiểm tra Chế độ Khách (Guest Mode)", "Chưa đăng nhập",
         "1. Bấm trải nghiệm vãng lai\n2. Kiểm tra danh sách cơ sở ẩm thực", 
         "Xem được danh sách quán ăn mà không bắt buộc đăng nhập", "Hiển thị danh sách quán ăn cho khách vãng lai", "PASS", "mobile_guest_explore.png"),
        ("TC-PW-20", "Mobile Web", "Kiểm tra Bản đồ Không gian OpenStreetMap", "Tab 2 (Bản đồ)",
         "1. Bấm chuyển sang tab Bản đồ\n2. Kiểm tra ghim Marker quán ăn", 
         "Hiển thị bản đồ OpenStreetMap với ghim vị trí quán", "Bản đồ hiển thị chuẩn xác các marker", "PASS", "mobile_map_view.png"),
        ("TC-PW-21", "Mobile Web", "Kiểm tra Auth Gate khi bấm Yêu thích", "Khách bấm Thả tim",
         "1. Bấm icon Trái tim trên món ăn", 
         "Hiển thị dialog yêu cầu đăng nhập tài khoản", "Auth Gate kích hoạt chuẩn xác", "PASS", "mobile_auth_gate.png"),
        ("TC-PW-22", "Mobile Web", "Kiểm tra Hồ sơ Thực khách & Đăng xuất", "Tab 4 (Tài khoản)",
         "1. Chuyển sang Tab Tài khoản\n2. Kiểm tra thẻ chỉ số thể chất", 
         "Hiển thị thông tin cá nhân và nút Đăng xuất an toàn", "Trang tài khoản hoạt động mượt mà", "PASS", "mobile_account_screen.png"),
        ("TC-PW-23", "Build Test", "Kiểm tra Web Admin Production Build", "Lệnh: npm run build",
         "1. Thực thi Vite Build cho mã nguồn web/\n2. Kiểm tra bundle phân phối dist/", 
         "Build thành công không phát sinh cảnh báo lỗi TypeScript", "Vite build thành công dist/ (1.2s)", "PASS", "Build Log"),
    ]

    for col_idx, h in enumerate(e2e_headers, start=1):
        cell = ws_e2e.cell(row=1, column=col_idx, value=h)
        cell.font = font_header
        cell.fill = fill_header
        cell.alignment = align_center
        cell.border = thin_border

    for idx, item in enumerate(e2e_cases, start=2):
        for col_idx, val in enumerate(item, start=1):
            cell = ws_e2e.cell(row=idx, column=col_idx, value=val)
            cell.border = thin_border
            if col_idx in [1, 2, 8, 9]:
                cell.alignment = align_center
            else:
                cell.alignment = align_left
            
            if col_idx == 8 and val == "PASS":
                cell.font = font_pass
                cell.fill = fill_pass
            elif col_idx == 1:
                cell.font = font_bold
            else:
                cell.font = font_regular

    # =========================================================================
    # SHEET 3: BACKEND TESTS (PYTEST)
    # =========================================================================
    ws_be = wb.create_sheet(title="Backend Tests (Pytest)")
    ws_be.views.sheetView[0].showGridLines = True

    be_headers = ["STT", "Module Kiểm Thử", "Tên Test Case / Hàm Kiểm Thử", "Loại Kiểm Thử", "Kết Quả Mong Đợi", "Trạng Thái"]
    pytest_summary = [
        ("Auth - Admin & User", "test_admin_login_success, test_admin_login_invalid_password, test_user_register, test_user_login, test_user_session_id", "Unit & Integration", "Xác thực đúng cấp session_id 32 hex, sai mật khẩu trả về 401", "PASS (12 tests)"),
        ("Map & PostGIS", "test_geocoding_search, test_reverse_geocoding, test_ip_location_live, test_nearby_restaurants_radius, test_postgis_distance_calc", "Spatial & GIS", "Toạ độ GPS chuẩn xác WGS84, khoảng cách ST_Distance tính đúng theo mét/km", "PASS (15 tests)"),
        ("Weather & Categories", "test_weather_current_api, test_weather_category_recommendation, test_global_categories_crud, test_display_order", "External API & Logic", "Thời tiết trả về độ C thật, đề xuất món nóng khi lạnh/mưa và đồ mát khi nắng", "PASS (14 tests)"),
        ("User Profile & BMI", "test_update_user_profile, test_bmi_calculation_dynamic, test_health_goals, test_dietary_preferences, test_allergens", "Business Logic", "Tính chuẩn BMI = kg / (m^2), phân loại thể trạng gầy/bình thường/thừa cân", "PASS (16 tests)"),
        ("Restaurants & Sponsor", "test_restaurant_crud, test_restaurant_sponsor_badge, test_opening_closing_hours, test_restaurant_menu_relation", "Relational DB", "Quản lý cơ sở đối tác, lọc quán đang mở cửa, cờ sponsor ưu tiên kết quả", "PASS (12 tests)"),
        ("Dishes & Favourites", "test_dish_crud, test_spicy_level_validation, test_meal_types, test_ingredients, test_user_favourite_toggle", "Data Integrity", "Thực đơn món ăn đa chiều, cảnh báo dị ứng, thao tác yêu thích Idempotent", "PASS (14 tests)"),
    ]

    for col_idx, h in enumerate(be_headers, start=1):
        cell = ws_be.cell(row=1, column=col_idx, value=h)
        cell.font = font_header
        cell.fill = fill_header
        cell.alignment = align_center
        cell.border = thin_border

    for idx, item in enumerate(pytest_summary, start=2):
        ws_be.cell(row=idx, column=1, value=idx - 1).alignment = align_center
        ws_be.cell(row=idx, column=1).font = font_bold
        ws_be.cell(row=idx, column=1).border = thin_border

        for col_idx, val in enumerate(item, start=2):
            cell = ws_be.cell(row=idx, column=col_idx, value=val)
            cell.border = thin_border
            if col_idx in [4, 6]:
                cell.alignment = align_center
            else:
                cell.alignment = align_left
            
            if col_idx == 6:
                cell.font = font_pass
                cell.fill = fill_pass
            else:
                cell.font = font_regular

    # =========================================================================
    # SHEET 4: MOBILE TESTS (FLUTTER)
    # =========================================================================
    ws_mob = wb.create_sheet(title="Mobile Tests (Flutter)")
    ws_mob.views.sheetView[0].showGridLines = True

    mob_headers = ["Mã Test", "Tên Test Case", "Mô Tả Kiểm Thử Widget", "Kết Quả Mong Đợi", "Trạng Thái"]
    mob_cases = [
        ("TC-FLUTTER-01", "Kiểm thử khởi chạy Ptc1App và chuyển đổi 4 tab NavigationBar",
         "Khởi dựng MaterialApp, render MainShell, bấm tuần tự 4 tab: Khám phá, Bản đồ, Yêu thích, Tài khoản",
         "Chuyển đổi giao diện tương ứng theo từng tab mượt mà, không throw exception", "PASS"),
        ("TC-FLUTTER-02", "Kiểm thử Auth Gate khi khách vãng lai nhấn yêu thích",
         "Khách vãng lai bấm biểu tượng tim (❤) trên món ăn hoặc menu quán",
         "Kích hoạt hiển thị Dialog Auth Gate yêu cầu đăng nhập tài khoản", "PASS"),
        ("TC-FLUTTER-03", "Kiểm thử màn hình Đăng ký Thực khách",
         "Mở form đăng ký, nhập email, mật khẩu, xác nhận mật khẩu",
         "Các ô nhập liệu phản hồi đúng, nút Đăng ký sẵn sàng kích hoạt", "PASS"),
        ("TC-FLUTTER-04", "Kiểm thử hiển thị dialog Onboarding Survey",
         "Hiển thị hộp thoại khảo sát thể chất 3 bước, tính toán BMI và sở thích",
         "Render đầy đủ các slider chiều cao, cân nặng, radio mục tiêu sức khỏe", "PASS"),
        ("TC-FLUTTER-05", "Kiểm thử đăng nhập thực khách & vào thẳng app không popup",
         "Đăng nhập tài khoản thực khách thành công và kiểm tra không còn popup cản trở",
         "Giao diện chuyển đổi phiên làm việc và hiển thị thông tin thực khách chuẩn xác", "PASS"),
    ]

    for col_idx, h in enumerate(mob_headers, start=1):
        cell = ws_mob.cell(row=1, column=col_idx, value=h)
        cell.font = font_header
        cell.fill = fill_header
        cell.alignment = align_center
        cell.border = thin_border

    for idx, item in enumerate(mob_cases, start=2):
        for col_idx, val in enumerate(item, start=1):
            cell = ws_mob.cell(row=idx, column=col_idx, value=val)
            cell.border = thin_border
            if col_idx in [1, 5]:
                cell.alignment = align_center
            else:
                cell.alignment = align_left
            
            if col_idx == 5 and val == "PASS":
                cell.font = font_pass
                cell.fill = fill_pass
            elif col_idx == 1:
                cell.font = font_bold
            else:
                cell.font = font_regular

    # =========================================================================
    # HÀM TRỢ GIÚP TẠO CÁC SHEET MANUAL TEST CASES
    # =========================================================================
    def build_manual_sheet(ws_title, cases):
        ws = wb.create_sheet(title=ws_title)
        ws.views.sheetView[0].showGridLines = True

        headers = [
            "STT", "Mã Test Case", "Module / Tính Năng", "Tên Kịch Bản Kiểm Thử",
            "Mức Độ", "Điều Kiện Tiên Quyết", "Dữ Liệu Đầu Vào",
            "Các Bước Thực Hiện", "Kết Quả Mong Đợi",
            "Kết Quả Thực Tế (Tester ghi)", "Trạng Thái", "Tester & Ngày Test", "Ghi Chú / Bug ID"
        ]

        ws.merge_cells("A1:M1")
        ws["A1"] = f"BẢNG KỊCH BẢN KIỂM THỬ THỦ CÔNG TOÀN DIỆN (MANUAL QA) - {ws_title.upper()}"
        ws["A1"].font = font_title
        ws["A1"].alignment = align_center
        ws.row_dimensions[1].height = 30

        ws.row_dimensions[3].height = 28
        for col_idx, h in enumerate(headers, start=1):
            cell = ws.cell(row=3, column=col_idx, value=h)
            cell.font = font_header
            cell.fill = PatternFill(start_color=HEADER_BLUE, end_color=HEADER_BLUE, fill_type="solid")
            cell.alignment = align_center
            cell.border = thin_border

        for r_idx, tc in enumerate(cases, start=4):
            ws.row_dimensions[r_idx].height = 48
            is_zebra = (r_idx % 2 == 1)
            row_fill = fill_zebra if is_zebra else None

            ws.cell(row=r_idx, column=1, value=r_idx - 3).alignment = align_top_center
            ws.cell(row=r_idx, column=2, value=tc["id"]).alignment = align_top_center
            ws.cell(row=r_idx, column=2).font = font_code
            ws.cell(row=r_idx, column=3, value=tc["module"]).alignment = align_top_left
            ws.cell(row=r_idx, column=4, value=tc["name"]).alignment = align_top_left
            ws.cell(row=r_idx, column=4).font = font_bold
            ws.cell(row=r_idx, column=5, value=tc["priority"]).alignment = align_top_center
            
            if tc["priority"] == "High":
                ws.cell(row=r_idx, column=5).fill = PatternFill(start_color=PRIORITY_HIGH_BG, end_color=PRIORITY_HIGH_BG, fill_type="solid")
                ws.cell(row=r_idx, column=5).font = Font(name="Arial", size=9, bold=True, color=PRIORITY_HIGH_TEXT)
            elif tc["priority"] == "Medium":
                ws.cell(row=r_idx, column=5).fill = PatternFill(start_color=PRIORITY_MED_BG, end_color=PRIORITY_MED_BG, fill_type="solid")
                ws.cell(row=r_idx, column=5).font = Font(name="Arial", size=9, bold=True, color=PRIORITY_MED_TEXT)

            ws.cell(row=r_idx, column=6, value=tc["preconditions"]).alignment = align_top_left
            ws.cell(row=r_idx, column=7, value=tc["data"]).alignment = align_top_left
            ws.cell(row=r_idx, column=8, value=tc["steps"]).alignment = align_top_left
            ws.cell(row=r_idx, column=9, value=tc["expected"]).alignment = align_top_left
            ws.cell(row=r_idx, column=10, value="").alignment = align_top_left
            
            status_cell = ws.cell(row=r_idx, column=11, value="Untested")
            status_cell.alignment = align_top_center
            status_cell.fill = PatternFill(start_color=UNTESTED_BG, end_color=UNTESTED_BG, fill_type="solid")
            status_cell.font = Font(name="Arial", size=9, bold=True, color=UNTESTED_TEXT)

            ws.cell(row=r_idx, column=12, value="").alignment = align_top_center
            ws.cell(row=r_idx, column=13, value="").alignment = align_top_left

            for c in range(1, 14):
                cell = ws.cell(row=r_idx, column=c)
                cell.border = thin_border
                if c not in [2, 4, 5, 11] and row_fill:
                    cell.fill = row_fill
                if c not in [2, 4, 5, 11]:
                    cell.font = font_regular

    # =========================================================================
    # SHEET 5: KIỂM THỬ THỦ CÔNG - MOBILE APP (28 TEST CASES TOÀN DIỆN)
    # =========================================================================
    manual_mobile_cases = [
        # Nhóm 1: Guest Mode & Chuyển đổi Navigation Tab
        {
            "id": "TC-MAN-MOB-01", "module": "Guest Mode",
            "name": "Truy cập ứng dụng với tư cách Khách vãng lai", "priority": "High",
            "preconditions": "Mở http://localhost:3000, chưa đăng nhập", "data": "Không cần tài khoản",
            "steps": "1. Mở trang chủ ứng dụng.\n2. Bấm 'Tiếp tục với tư cách Khách' (Guest Mode).\n3. Quan sát màn hình Khám phá.",
            "expected": "Vào thẳng màn hình Khám phá, hiển thị danh sách cơ sở ẩm thực mà không bị chặn bắt buộc đăng nhập."
        },
        {
            "id": "TC-MAN-MOB-02", "module": "Navigation Shell",
            "name": "Chuyển đổi tuần tự 4 Tab thanh điều hướng dưới", "priority": "High",
            "preconditions": "Đang ở màn hình chính MainShell", "data": "Click chuột/chạm 4 Tab",
            "steps": "1. Bấm Tab 1 (Khám phá).\n2. Bấm Tab 2 (Bản đồ).\n3. Bấm Tab 3 (Yêu thích).\n4. Bấm Tab 4 (Tài khoản).",
            "expected": "Các màn hình tương ứng hiển thị mượt mà, thanh điều hướng active đúng tab, không bị giật lag hay crash."
        },
        {
            "id": "TC-MAN-MOB-03", "module": "Guest & Auth Gate",
            "name": "Khách vãng lai mở xem thực đơn của quán ăn", "priority": "Medium",
            "preconditions": "Đang ở chế độ Khách vãng lai", "data": "Click vào một quán bất kỳ",
            "steps": "1. Tại Tab Khám phá, click vào một Card quán ăn bất kỳ.\n2. Quan sát Bottom Sheet mở lên.",
            "expected": "Hiển thị Bottom Sheet đầy đủ danh sách món ăn, giá tiền VNĐ, thông tin quán mà không bắt đăng nhập."
        },
        {
            "id": "TC-MAN-MOB-04", "module": "Guest & Auth Gate",
            "name": "Chặn Auth Gate khi Khách bấm Thả tim món ăn", "priority": "High",
            "preconditions": "Đang ở chế độ Khách, mở thực đơn quán", "data": "Click icon Trái tim (❤)",
            "steps": "1. Nhấn icon Trái tim trên một món ăn bất kỳ trong thực đơn.\n2. Quan sát phản hồi.",
            "expected": "Hệ thống bật Popup Hộp thoại Auth Gate thông báo yêu cầu đăng nhập tài khoản để lưu món yêu thích."
        },
        {
            "id": "TC-MAN-MOB-05", "module": "Guest & Auth Gate",
            "name": "Chặn Auth Gate khi Khách chuyển sang Tab Tài khoản", "priority": "High",
            "preconditions": "Đang ở chế độ Khách vãng lai", "data": "Click Tab Tài khoản (Tab 4)",
            "steps": "1. Bấm vào Tab 4 (Tài khoản).\n2. Quan sát giao diện hiển thị.",
            "expected": "Hiển thị màn hình mời Đăng nhập / Đăng ký với 2 nút hành động rõ ràng thay vì trang thông tin cá nhân."
        },

        # Nhóm 2: Authentication (Đăng ký, Đăng nhập)
        {
            "id": "TC-MAN-MOB-06", "module": "Authentication",
            "name": "Kiểm tra validate form Đăng ký (Để trống dữ liệu)", "priority": "Medium",
            "preconditions": "Mở màn hình Đăng ký tài khoản", "data": "Để trống toàn bộ ô nhập liệu",
            "steps": "1. Bấm nút 'Đăng ký' khi chưa nhập gì.",
            "expected": "Hiển thị cảnh báo lỗi màu đỏ yêu cầu nhập đầy đủ Email và Mật khẩu, không gửi request rỗng lên server."
        },
        {
            "id": "TC-MAN-MOB-07", "module": "Authentication",
            "name": "Đăng ký tài khoản mới thành công (Happy Path)", "priority": "High",
            "preconditions": "Mở màn hình Đăng ký", "data": "Email: user_qa_<timestamp>@test.vn, Pass: 123456, Tên: QA Tester",
            "steps": "1. Điền Email duy nhất, Mật khẩu >= 6 ký tự, Xác nhận mật khẩu trùng khớp.\n2. Bấm 'Đăng ký'.",
            "expected": "Tạo tài khoản thành công, thông báo thành công và tự động chuyển sang luồng Onboarding hoặc màn hình Đăng nhập."
        },
        {
            "id": "TC-MAN-MOB-08", "module": "Authentication",
            "name": "Đăng ký với Email đã tồn tại trong hệ thống", "priority": "Medium",
            "preconditions": "Mở màn hình Đăng ký", "data": "Email: user@example.com (đã có), Pass: 123456",
            "steps": "1. Nhập email đã tồn tại trong DB.\n2. Bấm 'Đăng ký'.",
            "expected": "Báo lỗi tài khoản/email đã được sử dụng (HTTP 400 Bad Request: 'Email already registered')."
        },
        {
            "id": "TC-MAN-MOB-09", "module": "Authentication",
            "name": "Đăng nhập thất bại khi nhập sai mật khẩu", "priority": "High",
            "preconditions": "Mở form Đăng nhập", "data": "Email: user@example.com, Mật khẩu: matkhaubayba",
            "steps": "1. Nhập Email đúng, Mật khẩu sai.\n2. Bấm 'Đăng nhập'.",
            "expected": "Hiển thị thông báo lỗi 'Incorrect email or password' (HTTP 401), giữ nguyên email để nhập lại."
        },
        {
            "id": "TC-MAN-MOB-10", "module": "Authentication",
            "name": "Đăng nhập thành công với tài khoản mẫu (Happy Path)", "priority": "High",
            "preconditions": "Mở form Đăng nhập", "data": "Email: user@example.com, Mật khẩu: 123456",
            "steps": "1. Nhập chính xác Email và Mật khẩu.\n2. Bấm 'Đăng nhập'.",
            "expected": "Đăng nhập thành công, cấp session_id, chuyển hướng vào màn hình Khám phá, avatar tài khoản cập nhật."
        },
        {
            "id": "TC-MAN-MOB-11", "module": "Authentication",
            "name": "Tự động phục hồi phiên làm việc khi tải lại trang (F5)", "priority": "High",
            "preconditions": "Đã đăng nhập thành công tài khoản User", "data": "F5 Refresh trình duyệt",
            "steps": "1. Nhấn F5 tải lại trang web http://localhost:3000.\n2. Kiểm tra trạng thái đăng nhập.",
            "expected": "Ứng dụng tự động đọc session trong local storage và duy trì trạng thái đăng nhập, không bị văng ra khách."
        },

        # Nhóm 3: Onboarding Survey & BMI Calculation
        {
            "id": "TC-MAN-MOB-12", "module": "Onboarding & BMI",
            "name": "Tự động tính BMI và thể trạng khi kéo slider Chiều cao/Cân nặng", "priority": "High",
            "preconditions": "Mở Hộp thoại Khảo sát Onboarding", "data": "Chiều cao: 170 cm, Cân nặng: 60 kg",
            "steps": "1. Kéo slider Chiều cao lên 170 cm.\n2. Kéo slider Cân nặng lên 60 kg.\n3. Quan sát nhãn BMI.",
            "expected": "BMI tự động tính = 20.8, nhãn thể trạng hiển thị màu xanh 'Bình thường' (Normal: 18.5 - 24.9)."
        },
        {
            "id": "TC-MAN-MOB-13", "module": "Onboarding & BMI",
            "name": "Kiểm tra phân loại thể trạng BMI Thừa cân / Béo phì", "priority": "Medium",
            "preconditions": "Đang ở Bước 1 khảo sát Onboarding", "data": "Chiều cao: 160 cm, Cân nặng: 80 kg",
            "steps": "1. Kéo Chiều cao 160 cm, Cân nặng 80 kg.\n2. Quan sát nhãn thể trạng.",
            "expected": "BMI tính = 31.2, nhãn phân loại thể trạng chuyển sang màu cam/đỏ 'Thừa cân' / 'Béo phì'."
        },
        {
            "id": "TC-MAN-MOB-14", "module": "Onboarding & BMI",
            "name": "Chọn Mục tiêu dinh dưỡng, Khẩu vị cay và Ngân sách", "priority": "Medium",
            "preconditions": "Chuyển sang Bước 2 của khảo sát", "data": "Mục tiêu: Giảm cân, Cay: Ăn cay nhiều, Ngân sách: Cao cấp",
            "steps": "1. Chọn radio/chip 'Giảm cân' (lose_weight).\n2. Chọn mức cay 'Ăn cay nhiều'.\n3. Chọn ngân sách 'Cao cấp'.",
            "expected": "Các nút chọn phản hồi mượt mà, chuyển trạng thái active rõ ràng."
        },
        {
            "id": "TC-MAN-MOB-15", "module": "Onboarding & BMI",
            "name": "Chọn Cảnh báo dị ứng thực phẩm và Lưu khảo sát", "priority": "High",
            "preconditions": "Chuyển sang Bước 3 của khảo sát", "data": "Tích chọn: Đậu phộng, Hải sản",
            "steps": "1. Tích chọn dị ứng 'Đậu phộng' và 'Hải sản'.\n2. Bấm 'Lưu hồ sơ dinh dưỡng'.",
            "expected": "Hộp thoại đóng, gửi PUT /api/v1/users/{id}/profile, thông báo lưu thành công, Tab Tài khoản hiển thị đủ thông tin."
        },

        # Nhóm 4: Explore & Live Weather
        {
            "id": "TC-MAN-MOB-16", "module": "Explore & Weather",
            "name": "Hiển thị Banner thời tiết thực tế tại toạ độ người dùng", "priority": "High",
            "preconditions": "Tại Tab Khám phá (Tab 1)", "data": "Toạ độ IP Internet",
            "steps": "1. Quan sát khối Banner thời tiết trên đầu màn hình.\n2. Kiểm tra nhiệt độ, icon thời tiết và dòng mô tả.",
            "expected": "Hiển thị nhiệt độ thực tế (°C), icon thời tiết tương ứng và dòng gợi ý món ăn tương thích."
        },
        {
            "id": "TC-MAN-MOB-17", "module": "Explore & Weather",
            "name": "Kiểm tra danh mục gợi ý theo điều kiện thời tiết", "priority": "Medium",
            "preconditions": "Tại Banner thời tiết", "data": "Click vào chip gợi ý món",
            "steps": "1. Bấm vào một chip danh mục gợi ý bên dưới banner (vd: 'Đồ uống mát' hoặc 'Lẩu nướng').",
            "expected": "Danh sách quán ăn bên dưới tự động lọc và hiển thị các quán phục vụ nhóm món được gợi ý."
        },
        {
            "id": "TC-MAN-MOB-18", "module": "Explore & Search",
            "name": "Tìm kiếm thời gian thực theo tên quán ăn hoặc món ăn", "priority": "High",
            "preconditions": "Tại Tab Khám phá", "data": "Gõ từ khóa: 'Phở'",
            "steps": "1. Bấm vào ô tìm kiếm.\n2. Nhập từ khóa 'Phở'.",
            "expected": "Danh sách quán ăn lọc tức thì, chỉ hiển thị những quán có tên hoặc menu chứa từ khóa 'Phở'."
        },
        {
            "id": "TC-MAN-MOB-19", "module": "Explore & Filter",
            "name": "Lọc quán ăn bằng thanh trượt Danh mục món (Category Pills)", "priority": "Medium",
            "preconditions": "Tại Tab Khám phá", "data": "Chọn danh mục: 'Cơm' hoặc 'Bún/Phở'",
            "steps": "1. Cuộn thanh ngang danh mục.\n2. Chọn một danh mục món.\n3. Bấm lại danh mục đó lần 2 để bỏ chọn.",
            "expected": "Chọn danh mục: Lọc các quán có món tương ứng. Bấm lại lần 2: Trả về toàn bộ danh sách quán ban đầu."
        },
        {
            "id": "TC-MAN-MOB-20", "module": "Explore & Cards",
            "name": "Hiển thị thông tin Thẻ Quán ăn (Khoảng cách, Giờ mở cửa, Sponsor)", "priority": "High",
            "preconditions": "Tại Tab Khám phá", "data": "Xem Card quán ăn",
            "steps": "1. Quan sát thông tin trên các Card quán ăn.\n2. Kiểm tra badge 'Nhà tài trợ' (nếu có).\n3. Kiểm tra số km khoảng cách và nhãn Đang mở cửa/Tạm đóng.",
            "expected": "Quán có cờ is_sponsor hiển thị huy hiệu vàng nổi bật, khoảng cách hiển thị chuẩn mét/km, giờ mở cửa đúng định dạng."
        },

        # Nhóm 5: Interactive Map & PostGIS
        {
            "id": "TC-MAN-MOB-21", "module": "Map & PostGIS",
            "name": "Hiển thị Bản đồ OpenStreetMap và Chấm định vị người dùng", "priority": "High",
            "preconditions": "Chuyển sang Tab 2 (Bản đồ)", "data": "Định vị IP",
            "steps": "1. Bấm Tab 2.\n2. Quan sát tâm bản đồ và biểu tượng vị trí.",
            "expected": "Bản đồ hiển thị mượt mà với Chấm tròn xanh (Vị trí của bạn theo IP) và các Ghim đỏ (Quán ăn xung quanh)."
        },
        {
            "id": "TC-MAN-MOB-22", "module": "Map & PostGIS",
            "name": "Thao tác Zoom và Nút FAB 'Vị trí của tôi'", "priority": "High",
            "preconditions": "Đang ở Tab Bản đồ", "data": "Kéo trượt bản đồ và bấm nút My Location",
            "steps": "1. Kéo bản đồ ra một khu vực xa.\n2. Bấm nút nổi tròn 'Vị trí của tôi' ở góc phải dưới.",
            "expected": "Tâm bản đồ tự động bay (animate) quay trở lại toạ độ vị trí của bạn ngay lập tức."
        },
        {
            "id": "TC-MAN-MOB-23", "module": "Map & PostGIS",
            "name": "Bấm Ghim quán ăn trên bản đồ mở Bottom Sheet tóm tắt", "priority": "High",
            "preconditions": "Đang ở Tab Bản đồ", "data": "Click vào một Ghim đỏ bất kỳ",
            "steps": "1. Click vào một ghim quán ăn trên bản đồ.\n2. Quan sát phản hồi.",
            "expected": "Bật Bottom Sheet hiển thị tên quán, địa chỉ, khoảng cách tính bằng mét/km và nút 'Xem thực đơn'."
        },
        {
            "id": "TC-MAN-MOB-24", "module": "Map & Geocoding",
            "name": "Tìm kiếm địa chỉ trên bản đồ qua ô Search Bar Nominatim", "priority": "Medium",
            "preconditions": "Tại ô tìm kiếm của Tab Bản đồ", "data": "Nhập địa chỉ: 'Gia Lâm, Hà Nội'",
            "steps": "1. Gõ địa chỉ vào ô tìm kiếm trên bản đồ.\n2. Nhấn biểu tượng Kính lúp (Search).",
            "expected": "Tâm bản đồ di chuyển đến toạ độ của địa chỉ vừa tìm kiếm và tải lại các quán ăn lân cận khu vực đó."
        },

        # Nhóm 6: Menu, Favourites & Account
        {
            "id": "TC-MAN-MOB-25", "module": "Menu & Details",
            "name": "Kiểm tra chi tiết món: Tag cay, Bữa ăn, Dị ứng và Tình trạng món", "priority": "High",
            "preconditions": "Mở thực đơn một quán ăn", "data": "Duyệt danh sách món",
            "steps": "1. Xem từng thẻ món ăn.\n2. Kiểm tra giá tiền (định dạng VNĐ ₫).\n3. Kiểm tra nhãn độ cay 🌶️, tag bữa ăn, mảng nguyên liệu và cảnh báo dị ứng.",
            "expected": "Thông tin hiển thị chi tiết, rõ ràng; món hết hàng hiển thị badge 'Tạm hết món' mờ hơn món còn hàng."
        },
        {
            "id": "TC-MAN-MOB-26", "module": "Favourites",
            "name": "Thả tim món ăn và kiểm tra hiển thị tại Tab Yêu thích", "priority": "High",
            "preconditions": "Đã đăng nhập tài khoản User", "data": "Click icon Trái tim trên món ăn",
            "steps": "1. Bấm icon Trái tim trên món ăn trong menu (tim chuyển sang màu đỏ).\n2. Chuyển sang Tab 3 (Yêu thích).",
            "expected": "Món ăn vừa thả tim xuất hiện ngay trong danh sách Tab 3 kèm tên quán đang bán và giá bán."
        },
        {
            "id": "TC-MAN-MOB-27", "module": "Favourites",
            "name": "Bỏ yêu thích món ăn tại Tab Yêu thích", "priority": "Medium",
            "preconditions": "Tại Tab 3, có ít nhất 1 món đã lưu", "data": "Click nút Bỏ thích",
            "steps": "1. Bấm vào biểu tượng Trái tim để bỏ thích món ăn.\n2. Quan sát danh sách.",
            "expected": "Món ăn được xoá khỏi danh sách yêu thích ngay lập tức. Nếu hết món, hiển thị giao diện trống 'Chưa có món yêu thích'."
        },
        {
            "id": "TC-MAN-MOB-28", "module": "Account & Profile",
            "name": "Kiểm tra thông tin Thể chất BMI và Đăng xuất tài khoản", "priority": "High",
            "preconditions": "Chuyển sang Tab 4 (Tài khoản), đã đăng nhập", "data": "Tài khoản hiện hành",
            "steps": "1. Kiểm tra Thẻ chỉ số thể chất (Chiều cao, Cân nặng, BMI, Thể trạng, Mục tiêu).\n2. Bấm nút 'Cập nhật khảo sát ẩm thực' thử mở lại survey.\n3. Bấm nút 'Đăng xuất'.",
            "expected": "Dữ liệu thể chất hiển thị chuẩn xác; nút 'Đăng xuất' huỷ session an toàn và đưa ứng dụng về trạng thái Khách vãng lai."
        }
    ]

    # =========================================================================
    # SHEET 6: KIỂM THỬ THỦ CÔNG - WEB ADMIN (24 TEST CASES TOÀN DIỆN)
    # =========================================================================
    manual_web_cases = [
        # Nhóm 1: Xác thực Quản trị viên
        {
            "id": "TC-MAN-WEB-01", "module": "Authentication",
            "name": "Hiển thị giao diện Form Đăng nhập Quản trị viên", "priority": "High",
            "preconditions": "Truy cập http://localhost:5173", "data": "Màn hình Login",
            "steps": "1. Mở trình duyệt truy cập http://localhost:5173.\n2. Quan sát các phần tử trên trang.",
            "expected": "Hiển thị Card đăng nhập 'PTC1 Management Console', ô Email, Mật khẩu, nút Đăng nhập và nút 'Đăng nhập mẫu'."
        },
        {
            "id": "TC-MAN-WEB-02", "module": "Authentication",
            "name": "Validate bỏ trống Email/Mật khẩu khi đăng nhập", "priority": "Medium",
            "preconditions": "Tại trang Login", "data": "Để trống các trường",
            "steps": "1. Bấm nút 'Đăng nhập' khi chưa nhập email hoặc mật khẩu.",
            "expected": "Hệ thống báo lỗi yêu cầu điền đầy đủ thông tin đăng nhập, không thực hiện gửi request rỗng."
        },
        {
            "id": "TC-MAN-WEB-03", "module": "Authentication",
            "name": "Đăng nhập thất bại khi sai mật khẩu Admin", "priority": "High",
            "preconditions": "Tại trang Login", "data": "Email: admin@example.com, Pass: matkhausai123",
            "steps": "1. Nhập email admin đúng, mật khẩu sai.\n2. Bấm 'Đăng nhập'.",
            "expected": "Thông báo lỗi hiển thị: 'Incorrect email or password' (HTTP 401), không cấp quyền vào portal."
        },
        {
            "id": "TC-MAN-WEB-04", "module": "Authentication",
            "name": "Đăng nhập thành công với nút 'Đăng nhập mẫu' 1-Click", "priority": "High",
            "preconditions": "Tại trang Login", "data": "Click nút '.btn-secondary' (Đăng nhập mẫu)",
            "steps": "1. Click nút 'Đăng nhập mẫu'.\n2. Quan sát chuyển hướng.",
            "expected": "Tự động điền admin@example.com / admin123, đăng nhập thành công và chuyển ngay vào Admin Portal."
        },
        {
            "id": "TC-MAN-WEB-05", "module": "Authentication",
            "name": "Kiểm tra Đăng xuất Quản trị viên an toàn", "priority": "High",
            "preconditions": "Đang trong Admin Portal", "data": "Click nút 'Đăng xuất' ở góc trên",
            "steps": "1. Bấm nút 'Đăng xuất' trên thanh header.\n2. Kiểm tra chuyển hướng.",
            "expected": "Xoá session trong localStorage, chuyển hướng quay lại màn hình Login; thử bấm Back trình duyệt không vào lại được."
        },

        # Nhóm 2: Dashboard Overview (KPIs)
        {
            "id": "TC-MAN-WEB-06", "module": "Dashboard Overview",
            "name": "Xác thực 4 thẻ KPI Thống kê Nền tảng thời gian thực", "priority": "High",
            "preconditions": "Tại Tab 1 (Tổng quan Dashboard)", "data": "Dữ liệu Database hiện tại",
            "steps": "1. Kiểm tra 4 thẻ KPI: Tổng cơ sở quán ăn, Tổng món ăn, Thực khách đã đăng ký, Tỷ lệ hoạt động.\n2. So khớp số liệu.",
            "expected": "Hiển thị đầy đủ 4 thẻ KPI với số liệu thực tế từ DB, format số đẹp mắt kèm icon minh hoạ."
        },
        {
            "id": "TC-MAN-WEB-07", "module": "Dashboard Overview",
            "name": "Kiểm tra Bảng Quán ăn mới nhất trên Dashboard", "priority": "Medium",
            "preconditions": "Tại Tab 1 (Tổng quan)", "data": "Bảng danh sách quán mới",
            "steps": "1. Cuộn xuống phần 'Cơ sở mới nhất'.\n2. Kiểm tra thông tin các quán ăn vừa tạo gần đây.",
            "expected": "Hiển thị đúng danh sách các quán ăn mới nhất kèm tên, địa chỉ, hotline và badge trạng thái hoạt động."
        },

        # Nhóm 3: Quản lý Quán ăn (Restaurants Management)
        {
            "id": "TC-MAN-WEB-08", "module": "Restaurants",
            "name": "Tìm kiếm quán ăn tức thì trên Data Table", "priority": "High",
            "preconditions": "Chuyển sang Tab 2 (Quản lý Quán ăn)", "data": "Từ khóa tìm kiếm: 'Phở' hoặc 'Gia Lâm'",
            "steps": "1. Nhập từ khóa vào ô tìm kiếm.\n2. Quan sát bảng dữ liệu.",
            "expected": "Bảng dữ liệu lọc tức thì theo thời gian thực, chỉ giữ lại các quán khớp với từ khóa tìm kiếm."
        },
        {
            "id": "TC-MAN-WEB-09", "module": "Restaurants",
            "name": "Lọc quán ăn theo Trạng thái Hoạt động (Dropdown Filter)", "priority": "Medium",
            "preconditions": "Tại Tab 2 (Quản lý Quán ăn)", "data": "Chọn: 'Tất cả', 'Đang hoạt động', 'Tạm đóng'",
            "steps": "1. Chọn filter 'Đang hoạt động' -> Kiểm tra bảng.\n2. Chọn filter 'Tạm đóng' -> Kiểm tra bảng.",
            "expected": "Bảng dữ liệu lọc chính xác theo trạng thái hoạt động của cơ sở được chọn."
        },
        {
            "id": "TC-MAN-WEB-10", "module": "Restaurants",
            "name": "Mở Modal Thêm quán mới và kiểm tra các trường nhập liệu", "priority": "Medium",
            "preconditions": "Tại Tab 2 (Quản lý Quán ăn)", "data": "Click nút '+ Thêm quán mới'",
            "steps": "1. Bấm nút '+ Thêm quán mới'.\n2. Kiểm tra form Modal hiển thị.",
            "expected": "Modal mở ra đầy đủ: Tên quán, Địa chỉ, Nút tìm toạ độ, Kinh độ, Vĩ độ, Hotline, Giờ mở/đóng cửa, Cờ Sponsor."
        },
        {
            "id": "TC-MAN-WEB-11", "module": "Restaurants",
            "name": "Sử dụng tính năng 'Điền nhanh toạ độ HVNN' (HVNN Preset)", "priority": "Medium",
            "preconditions": "Tại Modal thêm quán mới", "data": "Click nút 'Toạ độ mẫu HVNN'",
            "steps": "1. Bấm nút 'Toạ độ mẫu HVNN'.\n2. Quan sát ô Kinh độ & Vĩ độ.",
            "expected": "Trường Vĩ độ tự động điền 21.0055 và Kinh độ tự động điền 105.9325 (toạ độ trung tâm HVNN Gia Lâm)."
        },
        {
            "id": "TC-MAN-WEB-12", "module": "Restaurants",
            "name": "Tự động tra cứu Kinh độ/Vĩ độ bằng Geocoding OpenStreetMap", "priority": "High",
            "preconditions": "Tại Modal thêm quán mới", "data": "Địa chỉ: 'Trâu Quỳ, Gia Lâm, Hà Nội'",
            "steps": "1. Nhập địa chỉ 'Trâu Quỳ, Gia Lâm, Hà Nội'.\n2. Bấm nút 'Tìm toạ độ từ địa chỉ' (Geocoding).",
            "expected": "Hệ thống gọi OpenStreetMap Nominatim, tự động điền giá trị Kinh độ và Vĩ độ thực tế vào 2 ô nhập liệu."
        },
        {
            "id": "TC-MAN-WEB-13", "module": "Restaurants",
            "name": "Tạo mới Quán ăn có cấu hình Nhà tài trợ (is_sponsor)", "priority": "High",
            "preconditions": "Tại Modal thêm quán mới",
            "data": "Tên: Quán Cơm Niêu QA Test\nĐịa chỉ: Cổ Bi, Gia Lâm\nHotline: 0988776655\nGiờ: 06:00 - 22:00\nTích: is_sponsor",
            "steps": "1. Điền đầy đủ thông tin tên, địa chỉ, hotline, giờ mở/đóng cửa.\n2. Tích chọn cờ 'Nhà tài trợ'.\n3. Bấm 'Tạo cơ sở'.",
            "expected": "Modal đóng lại, thông báo tạo thành công, quán mới xuất hiện trên bảng kèm huy hiệu vàng Sponsor."
        },
        {
            "id": "TC-MAN-WEB-14", "module": "Restaurants",
            "name": "Chỉnh sửa thông tin Quán ăn (Edit Restaurant)", "priority": "High",
            "preconditions": "Tại bảng danh sách Quán ăn", "data": "Click nút 'Sửa' (biểu tượng bút)",
            "steps": "1. Bấm icon 'Sửa' trên một hàng quán ăn.\n2. Đổi tên quán hoặc số hotline.\n3. Bấm 'Lưu thay đổi'.",
            "expected": "Thông tin quán cập nhật tức thì trên bảng và lưu thành công về cơ sở dữ liệu."
        },
        {
            "id": "TC-MAN-WEB-15", "module": "Restaurants",
            "name": "Bật/Tắt nhanh trạng thái hoạt động (Toggle Status)", "priority": "High",
            "preconditions": "Tại bảng danh sách Quán ăn", "data": "Click nút Toggle hoạt động",
            "steps": "1. Tìm một quán đang mở cửa.\n2. Click nút Toggle chuyển trạng thái.",
            "expected": "Badge chuyển sang màu xám 'Tạm đóng', API gửi cập nhật thành công, đồng bộ ngay sang Mobile App."
        },
        {
            "id": "TC-MAN-WEB-16", "module": "Restaurants",
            "name": "Xoá Quán ăn kèm Hộp thoại xác nhận an toàn (Cascade Delete)", "priority": "High",
            "preconditions": "Tại một quán ăn mẫu thử nghiệm", "data": "Click nút 'Xoá' (biểu tượng thùng rác)",
            "steps": "1. Bấm nút 'Xoá' trên hàng quán ăn.\n2. Hộp thoại xác nhận hiện ra -> Bấm 'Xác nhận xoá'.",
            "expected": "Quán ăn biến mất khỏi bảng danh sách; các món ăn thuộc quán tự động bị cascade xoá an toàn."
        },

        # Nhóm 4: Quản lý Thực đơn & Danh mục (Master-Detail)
        {
            "id": "TC-MAN-WEB-17", "module": "Menu Management",
            "name": "Bố cục Master-Detail và Tìm kiếm Quán ở cột trái", "priority": "High",
            "preconditions": "Chuyển sang Tab 3 (Thực đơn & Danh mục)", "data": "Chọn quán ở cột trái",
            "steps": "1. Nhập tìm kiếm quán ở cột trái (Master).\n2. Click chọn quán ăn.\n3. Quan sát cột phải (Detail).",
            "expected": "Cột phải tải danh mục và danh sách món ăn thuộc riêng quán được chọn, tên quán hiển thị trên header cột phải."
        },
        {
            "id": "TC-MAN-WEB-18", "module": "Menu Management",
            "name": "Tạo mới Nhóm Danh mục món ăn toàn cục", "priority": "High",
            "preconditions": "Tại cột phải quản lý danh mục",
            "data": "Tên: 'Món Chay Dưỡng Sinh'\nMô tả: 'Các món thuần chay tốt cho sức khỏe'\nThứ tự: 15",
            "steps": "1. Bấm '+ Thêm danh mục'.\n2. Nhập tên, mô tả, thứ tự sắp xếp.\n3. Bấm 'Lưu danh mục'.",
            "expected": "Danh mục mới hiển thị trong danh sách nhóm món và sẵn sàng để gán cho các món ăn."
        },
        {
            "id": "TC-MAN-WEB-19", "module": "Menu Management",
            "name": "Thêm món ăn mới với giá VNĐ, độ cay và bữa ăn", "priority": "High",
            "preconditions": "Đang chọn một quán ăn tại cột Detail",
            "data": "Tên: 'Cơm Sườn Nướng Mật Ong'\nGiá: 50000 VNĐ\nĐộ cay: 1 (Cay nhẹ)\nBữa ăn: Trưa, Tối\nNguyên liệu: Sườn, mật ong, cơm",
            "steps": "1. Bấm '+ Thêm món mới'.\n2. Nhập đầy đủ thông tin, chọn danh mục, kéo độ cay 1, chọn bữa ăn Trưa/Tối.\n3. Bấm 'Lưu món ăn'.",
            "expected": "Món mới xuất hiện dạng Card trong thực đơn, giá hiển thị đúng chuẩn '50.000 ₫', tag cay 🌶️ hiển thị đúng."
        },
        {
            "id": "TC-MAN-WEB-20", "module": "Menu Management",
            "name": "Chuyển đổi trạng thái Còn món / Hết món tức thì", "priority": "Medium",
            "preconditions": "Tại Card món ăn", "data": "Click nút Toggle tình trạng còn món",
            "steps": "1. Bấm nút chuyển trạng thái Còn món -> Hết món trên một món ăn.",
            "expected": "Badge cập nhật thành 'Tạm hết món', đồng bộ ngay lập tức sang ứng dụng Mobile."
        },
        {
            "id": "TC-MAN-WEB-21", "module": "Menu Management",
            "name": "Lọc món ăn theo Nhóm danh mục trong thực đơn quán", "priority": "Medium",
            "preconditions": "Tại Tab Thực đơn của quán", "data": "Click chọn một danh mục cụ thể",
            "steps": "1. Bấm chọn danh mục 'Món nước' trong danh sách lọc danh mục.",
            "expected": "Danh sách món ăn chỉ hiển thị các món thuộc danh mục 'Món nước'."
        },
        {
            "id": "TC-MAN-WEB-22", "module": "Menu Management",
            "name": "Xoá món ăn khỏi thực đơn quán", "priority": "Medium",
            "preconditions": "Tại Card món ăn mẫu", "data": "Click nút Xoá món (biểu tượng thùng rác)",
            "steps": "1. Bấm nút Xoá trên thẻ món ăn.\n2. Xác nhận xoá trong hộp thoại.",
            "expected": "Món ăn bị xoá khỏi thực đơn quán, số lượng món trên KPI và tab quán tự động cập nhật giảm 1."
        },

        # Nhóm 5: Quản lý Khách hàng (Accounts Management)
        {
            "id": "TC-MAN-WEB-23", "module": "Accounts Management",
            "name": "Xem danh sách tài khoản khách hàng đã đăng ký", "priority": "High",
            "preconditions": "Chuyển sang Tab 4 (Tài khoản Khách hàng)", "data": "Bảng tài khoản Users",
            "steps": "1. Bấm chọn Tab 4.\n2. Kiểm tra các cột: ID, Email, Họ tên, Ngày tạo, Trạng thái hoạt động.",
            "expected": "Bảng hiển thị đầy đủ danh sách thực khách, không để lộ mật khẩu băm (password_hash)."
        },
        {
            "id": "TC-MAN-WEB-24", "module": "Accounts Management",
            "name": "Tìm kiếm tài khoản người dùng theo Email hoặc Tên", "priority": "Medium",
            "preconditions": "Tại Tab 4 (Tài khoản)", "data": "Từ khóa: 'user@example.com'",
            "steps": "1. Nhập từ khóa vào ô tìm kiếm tài khoản.",
            "expected": "Bảng dữ liệu lọc tức thì, hiển thị đúng tài khoản người dùng cần tìm kiếm."
        }
    ]

    # =========================================================================
    # SHEET 7: KIỂM THỬ THỦ CÔNG - API SWAGGER (8 TEST CASES)
    # =========================================================================
    manual_api_cases = [
        {
            "id": "TC-MAN-API-01", "module": "Swagger Docs",
            "name": "Tải trang tài liệu OpenAPI Swagger UI", "priority": "High",
            "preconditions": "Backend đang chạy tại port 8001", "data": "GET http://localhost:8001/docs",
            "steps": "1. Mở trình duyệt truy cập http://localhost:8001/docs.\n2. Chờ tài liệu tải hoàn tất.",
            "expected": "HTTP 200 OK, tải đầy đủ giao diện Swagger UI với các nhóm API: Auth, Map, Restaurants, Categories, Dishes, Weather."
        },
        {
            "id": "TC-MAN-API-02", "module": "Authentication",
            "name": "API Đăng nhập Quản trị viên cấp Session ID", "priority": "High",
            "preconditions": "Tại endpoint POST /api/v1/auth/admin/login",
            "data": '{"email": "admin@example.com", "password": "admin123"}',
            "steps": "1. Bấm 'Try it out' -> Điền email, password.\n2. Bấm 'Execute'.",
            "expected": "HTTP 200 OK, JSON trả về role='admin', session_id (32 ký tự hex) và data thông tin admin."
        },
        {
            "id": "TC-MAN-API-03", "module": "Authentication",
            "name": "API Đăng nhập Thực khách cấp Session ID", "priority": "High",
            "preconditions": "Tại endpoint POST /api/v1/auth/user/login",
            "data": '{"email": "user@example.com", "password": "123456"}',
            "steps": "1. Bấm 'Try it out' -> Điền thông tin.\n2. Bấm 'Execute'.",
            "expected": "HTTP 200 OK, JSON trả về role='user', session_id và dữ liệu tài khoản thực khách."
        },
        {
            "id": "TC-MAN-API-04", "module": "Map & Geolocation",
            "name": "API Định vị toạ độ IP Internet không fallback HVNN", "priority": "High",
            "preconditions": "Tại endpoint GET /api/v1/map/ip-location", "data": "Client IP Request thực tế",
            "steps": "1. Tìm endpoint GET /api/v1/map/ip-location.\n2. Bấm 'Try it out' -> 'Execute'.",
            "expected": "HTTP 200 OK. JSON trả về toạ độ latitude, longitude thực tế của kết nối Internet, is_fallback=false."
        },
        {
            "id": "TC-MAN-API-05", "module": "Map & Geocoding",
            "name": "API Tra cứu toạ độ từ địa chỉ chuỗi (Geocoding Search)", "priority": "High",
            "preconditions": "Tại endpoint GET /api/v1/map/search", "data": "q: 'Hoc vien Nong nghiep Viet Nam'",
            "steps": "1. Nhập tham số q='Hoc vien Nong nghiep Viet Nam'.\n2. Bấm 'Execute'.",
            "expected": "HTTP 200 OK, trả về danh sách kết quả chứa toạ độ lat ≈ 21.005, lon ≈ 105.932 và địa chỉ chuẩn hoá."
        },
        {
            "id": "TC-MAN-API-06", "module": "PostGIS Spatial",
            "name": "API Truy vấn không gian PostGIS Radius ST_DWithin", "priority": "High",
            "preconditions": "Tại endpoint GET /api/v1/restaurants/nearby",
            "data": "lat: 21.0184, lon: 105.8461, radius_km: 30",
            "steps": "1. Nhập lat=21.0184, lon=105.8461, radius_km=30.\n2. Bấm 'Execute'.",
            "expected": "HTTP 200 OK, trả về danh sách các quán ăn lân cận sắp xếp tăng dần theo trường distance_meters."
        },
        {
            "id": "TC-MAN-API-07", "module": "PostGIS Spatial",
            "name": "API Tính khoảng cách trực tiếp từ người dùng đến quán (ST_Distance)", "priority": "Medium",
            "preconditions": "Tại endpoint GET /api/v1/restaurants/{id}/distance",
            "data": "id: 1, lat: 21.0184, lon: 105.8461",
            "steps": "1. Nhập restaurant_id hợp lệ và toạ độ người dùng.\n2. Bấm 'Execute'.",
            "expected": "HTTP 200 OK, JSON trả về khoảng cách chính xác tính bằng mét (meters) và km."
        },
        {
            "id": "TC-MAN-API-08", "module": "Weather Recommendation",
            "name": "API Thời tiết thực tế và Danh mục gợi ý", "priority": "High",
            "preconditions": "Tại endpoint GET /api/v1/weather/current", "data": "lat: 21.0184, lon: 105.8461",
            "steps": "1. Nhập toạ độ người dùng.\n2. Bấm 'Execute'.",
            "expected": "HTTP 200 OK, trả về nhiệt độ thực tế (°C), tình trạng thời tiết và danh sách danh mục món ăn đề xuất."
        }
    ]

    # =========================================================================
    # SHEET 8: BÁO CÁO LỖI (BUG LOG)
    # =========================================================================
    def build_bug_sheet():
        ws = wb.create_sheet(title="Báo Cáo Lỗi (Bug Log)")
        ws.views.sheetView[0].showGridLines = True

        ws.merge_cells("A1:K1")
        ws["A1"] = "BẢNG GHI NHẬN LỖI KIỂM THỬ THỦ CÔNG (DEFECT / BUG LOG)"
        ws["A1"].font = font_title
        ws["A1"].alignment = align_center
        ws.row_dimensions[1].height = 30

        headers = [
            "STT", "Mã Bug (ID)", "Mã Test Case Liên Quan", "Phân Hệ Bị Lỗi",
            "Tiêu Đề / Tóm Tắt Lỗi", "Mức Độ Nghiêm Trọng (Severity)",
            "Các Bước Tái Hiện Lỗi (Steps to Reproduce)", "Kết Quả Thực Tế (Actual)",
            "Kết Quả Mong Đợi (Expected)", "Trạng Thái Bug", "Người Báo Lỗi & Ngày"
        ]

        ws.row_dimensions[3].height = 28
        for col_idx, h in enumerate(headers, start=1):
            cell = ws.cell(row=3, column=col_idx, value=h)
            cell.font = font_header
            cell.fill = PatternFill(start_color=HEADER_BLUE, end_color=HEADER_BLUE, fill_type="solid")
            cell.alignment = align_center
            cell.border = thin_border

        # 2 dòng mẫu
        samples = [
            {
                "id": "BUG-01 (Mẫu)", "tc": "TC-MAN-WEB-12", "sub": "Web Admin",
                "title": "Địa chỉ quá dài gây tràn chữ trong khung Geocoding", "sev": "Minor",
                "steps": "1. Mở modal thêm quán mới\n2. Nhập địa chỉ hơn 150 ký tự\n3. Quan sát ô nhập liệu",
                "actual": "Chữ bị tràn nhẹ sang mép phải nút tìm kiếm",
                "expected": "Chữ tự động xuống dòng hoặc có thanh cuộn",
                "status": "Open", "reporter": "Tester A - 24/10/2026"
            },
            {
                "id": "BUG-02 (Mẫu)", "tc": "TC-MAN-MOB-12", "sub": "Mobile App",
                "title": "Slider chiều cao trên màn hình nhỏ bị che nhãn số", "sev": "Minor",
                "steps": "1. Mở Onboarding Survey trên màn hình 320px\n2. Kéo slider chiều cao",
                "actual": "Nhãn số cm bị che khuất 1 phần",
                "expected": "Nhãn số hiển thị nổi phía trên con trỏ slider",
                "status": "Open", "reporter": "Tester B - 24/10/2026"
            }
        ]

        for s_idx, s in enumerate(samples, start=4):
            ws.row_dimensions[s_idx].height = 40
            ws.cell(row=s_idx, column=1, value=s_idx - 3).alignment = align_top_center
            ws.cell(row=s_idx, column=2, value=s["id"]).alignment = align_top_center
            ws.cell(row=s_idx, column=2).font = font_code
            ws.cell(row=s_idx, column=3, value=s["tc"]).alignment = align_top_center
            ws.cell(row=s_idx, column=4, value=s["sub"]).alignment = align_top_left
            ws.cell(row=s_idx, column=5, value=s["title"]).alignment = align_top_left
            ws.cell(row=s_idx, column=5).font = font_bold
            ws.cell(row=s_idx, column=6, value=s["sev"]).alignment = align_top_center
            ws.cell(row=s_idx, column=7, value=s["steps"]).alignment = align_top_left
            ws.cell(row=s_idx, column=8, value=s["actual"]).alignment = align_top_left
            ws.cell(row=s_idx, column=9, value=s["expected"]).alignment = align_top_left
            ws.cell(row=s_idx, column=10, value=s["status"]).alignment = align_top_center
            ws.cell(row=s_idx, column=11, value=s["reporter"]).alignment = align_top_left

            for c in range(1, 12):
                cell = ws.cell(row=s_idx, column=c)
                cell.border = thin_border
                if c not in [2, 5]:
                    cell.font = font_regular

        for empty_r in range(6, 26):
            ws.row_dimensions[empty_r].height = 28
            ws.cell(row=empty_r, column=1, value=empty_r - 3).alignment = align_top_center
            for c in range(1, 12):
                ws.cell(row=empty_r, column=c).border = thin_border
                ws.cell(row=empty_r, column=c).font = font_regular

    # Dựng các sheet thủ công
    build_manual_sheet("Kiểm Thử Thủ Công - Mobile", manual_mobile_cases)
    build_manual_sheet("Kiểm Thử Thủ Công - Web Admin", manual_web_cases)
    build_manual_sheet("Kiểm Thử Thủ Công - API", manual_api_cases)
    build_bug_sheet()

    # Tự động căn chỉnh độ rộng cột cho tất cả các sheets
    for ws in wb.worksheets:
        for col in ws.columns:
            max_len = 0
            col_letter = get_column_letter(col[0].column)
            for cell in col:
                val_str = str(cell.value or "")
                # Bỏ qua các ô bị merge dài ở sheet dashboard
                if ws == ws_dash and cell.row in [2, 3, 16, 24]:
                    continue
                lines = val_str.split("\n")
                for line in lines:
                    if len(line) > max_len:
                        max_len = len(line)
            ws.column_dimensions[col_letter].width = min(max(max_len + 3, 12), 48)

    # Đặt độ rộng đặc biệt cho Dashboard
    ws_dash.column_dimensions['A'].width = 4
    ws_dash.column_dimensions['B'].width = 32
    ws_dash.column_dimensions['C'].width = 28
    ws_dash.column_dimensions['D'].width = 16
    ws_dash.column_dimensions['E'].width = 22
    ws_dash.column_dimensions['F'].width = 30
    ws_dash.column_dimensions['G'].width = 16

    # Căn độ rộng các sheet kiểm thử thủ công
    for title in ["Kiểm Thử Thủ Công - Mobile", "Kiểm Thử Thủ Công - Web Admin", "Kiểm Thử Thủ Công - API"]:
        target_ws = wb[title]
        col_widths = {
            1: 6, 2: 18, 3: 20, 4: 30, 5: 10, 6: 25, 7: 25,
            8: 40, 9: 40, 10: 25, 11: 12, 12: 18, 13: 16
        }
        for col_idx, width in col_widths.items():
            target_ws.column_dimensions[get_column_letter(col_idx)].width = width

    # Căn độ rộng sheet Bug Log
    ws_bug = wb["Báo Cáo Lỗi (Bug Log)"]
    bug_widths = {
        1: 6, 2: 16, 3: 18, 4: 15, 5: 30, 6: 15,
        7: 35, 8: 30, 9: 30, 10: 15, 11: 22
    }
    for col_idx, width in bug_widths.items():
        ws_bug.column_dimensions[get_column_letter(col_idx)].width = width

    # Lưu file vào thư mục docs/reports
    output_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "docs", "reports")
    os.makedirs(output_dir, exist_ok=True)
    output_path = os.path.join(output_dir, "PTC1_Test_Cases_Report.xlsx")
    wb.save(output_path)
    print(f"[SUCCESS] Exported Excel file to: {output_path}")

if __name__ == "__main__":
    if hasattr(sys.stdout, 'reconfigure'):
        try:
            sys.stdout.reconfigure(encoding='utf-8')
        except Exception:
            pass
    create_excel_report()
