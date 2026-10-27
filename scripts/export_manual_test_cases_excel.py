import os
import sys
from datetime import datetime
import openpyxl
from openpyxl.styles import Font, PatternFill, Alignment, Border, Side
from openpyxl.utils import get_column_letter

def build_manual_test_excel():
    wb = openpyxl.Workbook()
    wb.remove(wb.active)  # Xoá sheet mặc định

    # Bảng màu chuyên nghiệp chuẩn Enterprise QA
    NAVY = "1B365D"
    HEADER_BLUE = "205493"
    WHITE = "FFFFFF"
    ICE_BLUE = "EDF4FA"
    LIGHT_GRAY = "F9FAFB"
    BORDER_COLOR = "D0D7DE"
    TEXT_DARK = "1F2328"
    
    # Màu trạng thái
    PASS_BG = "D4EDDA"
    PASS_TEXT = "155724"
    UNTESTED_BG = "FFF3CD"
    UNTESTED_TEXT = "856404"
    PRIORITY_HIGH_BG = "F8D7DA"
    PRIORITY_HIGH_TEXT = "721C24"

    font_title = Font(name="Arial", size=15, bold=True, color=NAVY)
    font_subtitle = Font(name="Arial", size=10, italic=True, color="555555")
    font_section = Font(name="Arial", size=12, bold=True, color=NAVY)
    font_header = Font(name="Arial", size=10, bold=True, color=WHITE)
    font_bold = Font(name="Arial", size=9, bold=True, color=TEXT_DARK)
    font_regular = Font(name="Arial", size=9, color=TEXT_DARK)
    font_code = Font(name="Consolas", size=9, color="003366")

    fill_header = PatternFill(start_color=HEADER_BLUE, end_color=HEADER_BLUE, fill_type="solid")
    fill_sub_header = PatternFill(start_color=ICE_BLUE, end_color=ICE_BLUE, fill_type="solid")
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
    # SHEET 1: HƯỚNG DẪN & THÔNG TIN MÔI TRƯỜNG
    # =========================================================================
    ws_info = wb.create_sheet(title="Hướng Dẫn & Môi Trường")
    ws_info.views.sheetView[0].showGridLines = True

    ws_info.merge_cells("B2:H2")
    ws_info["B2"] = "KẾ HOẠCH & BỘ TEST CASES KIỂM THỬ THỦ CÔNG (MANUAL TEST) - PTC1"
    ws_info["B2"].font = font_title
    ws_info["B2"].alignment = align_center

    ws_info.merge_cells("B3:H3")
    ws_info["B3"] = f"Dự án: PTC1 Spatial Food Platform | Tạo ngày: {datetime.now().strftime('%d/%m/%Y')} | Người lập: Antigravity QA Team"
    ws_info["B3"].font = font_subtitle
    ws_info["B3"].alignment = align_center

    # Bảng thông tin dịch vụ
    ws_info["B5"] = "1. ĐỊA CHỈ TRUY CẬP HỆ THỐNG KIỂM THỬ"
    ws_info["B5"].font = font_section

    endpoints = [
        ("Mobile App (Thực khách)", "http://localhost:3000", "Khám phá món, bản đồ, thời tiết, thả tim, khảo sát BMI"),
        ("Web Admin Console", "http://localhost:5173", "Quản lý cơ sở quán ăn, thực đơn món, danh mục, tài khoản, KPIs"),
        ("Backend Swagger UI", "http://localhost:8001/docs", "Kiểm tra trực tiếp API, OpenAPI Schema và dịch vụ PostGIS/Map")
    ]
    
    headers_ep = ["Phân Hệ", "Đường Dẫn Truy Cập (URL)", "Mục Đích Kiểm Thử"]
    for col_idx, h in enumerate(headers_ep, start=2):
        cell = ws_info.cell(row=6, column=col_idx, value=h)
        cell.font = font_header
        cell.fill = fill_header
        cell.alignment = align_center
        cell.border = thin_border

    for row_idx, ep in enumerate(endpoints, start=7):
        ws_info.cell(row=row_idx, column=2, value=ep[0]).alignment = align_left
        ws_info.cell(row=row_idx, column=3, value=ep[1]).alignment = align_left
        ws_info.cell(row=row_idx, column=4, value=ep[2]).alignment = align_left
        for c in range(2, 5):
            ws_info.cell(row=row_idx, column=c).border = thin_border
            ws_info.cell(row=row_idx, column=c).font = font_regular

    # Bảng tài khoản kiểm thử
    ws_info["B12"] = "2. DANH SÁCH TÀI KHOẢN MẪU (TEST ACCOUNTS)"
    ws_info["B12"].font = font_section

    accounts = [
        ("Quản trị viên (Super Admin)", "admin@example.com", "admin123", "Web Admin (:5173)", "Tài khoản toàn quyền, có nút Đăng nhập mẫu"),
        ("Quản trị viên phụ (Admin)", "admin@ptc1.vn", "admin123", "Web Admin (:5173)", "Tài khoản admin kiểm thử phân quyền"),
        ("Thực khách (User)", "user@example.com", "123456", "Mobile App (:3000)", "Đã hoàn thành khảo sát BMI (Cao 175cm, Nặng 68kg)"),
        ("Khách vãng lai (Guest)", "Không cần tài khoản", "-", "Mobile App (:3000)", "Bấm 'Tiếp tục với tư cách Khách' để test Auth Gate")
    ]
    headers_acc = ["Vai Trò (Role)", "Tài Khoản (Email)", "Mật Khẩu", "Nền Tảng Áp Dụng", "Ghi Chú"]
    for col_idx, h in enumerate(headers_acc, start=2):
        cell = ws_info.cell(row=13, column=col_idx, value=h)
        cell.font = font_header
        cell.fill = fill_header
        cell.alignment = align_center
        cell.border = thin_border

    for row_idx, acc in enumerate(accounts, start=14):
        ws_info.cell(row=row_idx, column=2, value=acc[0]).alignment = align_left
        ws_info.cell(row=row_idx, column=3, value=acc[1]).alignment = align_left
        ws_info.cell(row=row_idx, column=4, value=acc[2]).alignment = align_center
        ws_info.cell(row=row_idx, column=5, value=acc[3]).alignment = align_left
        ws_info.cell(row=row_idx, column=6, value=acc[4]).alignment = align_left
        for c in range(2, 7):
            ws_info.cell(row=row_idx, column=c).border = thin_border
            ws_info.cell(row=row_idx, column=c).font = font_regular

    # Bảng quy ước trạng thái
    ws_info["B20"] = "3. HƯỚNG DẪN TESTER ĐIỀN KẾT QUẢ VÀO FILE EXCEL"
    ws_info["B20"].font = font_section

    instructions = [
        ("Cột 'Trạng Thái' (Status):", "Điền 'PASS' nếu đúng kết quả mong đợi, 'FAIL' nếu có lỗi, 'BLOCKED' nếu bị tắc không test tiếp được."),
        ("Cột 'Kết Quả Thực Tế' (Actual Result):", "Ghi nhận hiện tượng xảy ra trên màn hình khi thực hiện test."),
        ("Cột 'Tester & Ngày Test':", "Điền tên người test và ngày thực hiện (vd: 'Tuấn Anh - 24/10/2026')."),
        ("Khi phát hiện lỗi (FAIL):", "Ghi chi tiết vào Sheet 'Báo Cáo Lỗi (Bug Log)' kèm các bước tái hiện và ảnh chụp.")
    ]
    for r_idx, (k, v) in enumerate(instructions, start=21):
        c1 = ws_info.cell(row=r_idx, column=2, value=k)
        c1.font = font_bold
        c2 = ws_info.cell(row=r_idx, column=3, value=v)
        c2.font = font_regular
        ws_info.merge_cells(start_row=r_idx, start_column=3, end_row=r_idx, end_column=7)

    # Hàm tạo sheet test cases chuẩn
    def setup_test_sheet(title, test_cases):
        ws = wb.create_sheet(title=title)
        ws.views.sheetView[0].showGridLines = True

        headers = [
            "STT", "Mã Test Case", "Module / Tính Năng", "Tên Kịch Bản Kiểm Thử",
            "Mức Độ", "Điều Kiện Tiên Quyết", "Dữ Liệu Đầu Vào",
            "Các Bước Thực Hiện", "Kết Quả Mong Đợi",
            "Kết Quả Thực Tế (Tester ghi)", "Trạng Thái", "Tester & Ngày Test", "Ghi Chú / Bug ID"
        ]

        # Tiêu đề sheet
        ws.merge_cells("A1:M1")
        ws["A1"] = f"DANH SÁCH TEST CASES KIỂM THỬ THỦ CÔNG: {title.upper()}"
        ws["A1"].font = font_title
        ws["A1"].alignment = align_center
        ws.row_dimensions[1].height = 30

        # Header hàng 3
        ws.row_dimensions[3].height = 28
        for col_idx, h in enumerate(headers, start=1):
            cell = ws.cell(row=3, column=col_idx, value=h)
            cell.font = font_header
            cell.fill = fill_header
            cell.alignment = align_center
            cell.border = thin_border

        for r_idx, tc in enumerate(test_cases, start=4):
            ws.row_dimensions[r_idx].height = 45
            is_zebra = (r_idx % 2 == 1)
            row_fill = fill_zebra if is_zebra else None

            # Dữ liệu
            ws.cell(row=r_idx, column=1, value=r_idx - 3).alignment = align_top_center
            ws.cell(row=r_idx, column=2, value=tc["id"]).alignment = align_top_center
            ws.cell(row=r_idx, column=2).font = font_code
            ws.cell(row=r_idx, column=3, value=tc["module"]).alignment = align_top_left
            ws.cell(row=r_idx, column=4, value=tc["name"]).alignment = align_top_left
            ws.cell(row=r_idx, column=4).font = font_bold
            ws.cell(row=r_idx, column=5, value=tc["priority"]).alignment = align_top_center
            
            # Tô màu priority
            if tc["priority"] == "High":
                ws.cell(row=r_idx, column=5).fill = PatternFill(start_color=PRIORITY_HIGH_BG, end_color=PRIORITY_HIGH_BG, fill_type="solid")
                ws.cell(row=r_idx, column=5).font = Font(name="Arial", size=9, bold=True, color=PRIORITY_HIGH_TEXT)

            ws.cell(row=r_idx, column=6, value=tc["preconditions"]).alignment = align_top_left
            ws.cell(row=r_idx, column=7, value=tc["data"]).alignment = align_top_left
            ws.cell(row=r_idx, column=8, value=tc["steps"]).alignment = align_top_left
            ws.cell(row=r_idx, column=9, value=tc["expected"]).alignment = align_top_left
            ws.cell(row=r_idx, column=10, value="").alignment = align_top_left
            
            # Trạng thái mặc định
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

        # Tự căn chỉnh độ rộng cột
        col_widths = {
            1: 6,   # STT
            2: 15,  # Mã Test Case
            3: 16,  # Module
            4: 25,  # Tên Kịch Bản
            5: 10,  # Mức Độ
            6: 22,  # Điều Kiện
            7: 22,  # Dữ Liệu
            8: 38,  # Các Bước
            9: 38,  # Kết Quả Mong Đợi
            10: 25, # Kết Quả Thực Tế
            11: 12, # Trạng Thái
            12: 18, # Tester & Ngày
            13: 16  # Ghi Chú
        }
        for col_idx, width in col_widths.items():
            col_letter = get_column_letter(col_idx)
            ws.column_dimensions[col_letter].width = width

    # =========================================================================
    # SHEET 2: TEST CASES MOBILE APP (THỰC KHÁCH)
    # =========================================================================
    cases_mobile = [
        {
            "id": "TC-MOB-01",
            "module": "Guest & Auth Gate",
            "name": "Trải nghiệm Khách vãng lai xem danh sách quán",
            "priority": "High",
            "preconditions": "Ứng dụng mở tại http://localhost:3000, chưa đăng nhập",
            "data": "Không cần tài khoản",
            "steps": "1. Mở trang chủ ứng dụng.\n2. Chọn 'Tiếp tục với tư cách Khách' (Guest Mode).\n3. Lướt màn hình Khám phá xem danh sách quán ăn.",
            "expected": "Hiển thị danh sách các quán ăn ẩm thực kèm tên quán, hotline, khoảng cách km, không phát sinh lỗi."
        },
        {
            "id": "TC-MOB-02",
            "module": "Guest & Auth Gate",
            "name": "Kích hoạt Auth Gate khi Khách bấm Thả tim",
            "priority": "High",
            "preconditions": "Đang ở chế độ Khách vãng lai",
            "data": "Click icon Trái tim (❤) trên món ăn",
            "steps": "1. Mở xem thực đơn một quán ăn bất kỳ.\n2. Nhấn biểu tượng Trái tim trên một món ăn.",
            "expected": "Hiển thị Hộp thoại thông báo yêu cầu đăng nhập tài khoản (Auth Gate Dialog). Ứng dụng không bị crash."
        },
        {
            "id": "TC-MOB-03",
            "module": "Authentication",
            "name": "Đăng ký tài khoản Thực khách mới",
            "priority": "High",
            "preconditions": "Tại màn hình Đăng ký tài khoản",
            "data": "Email: user_test_<time>@example.com\nMật khẩu: 123456\nHọ tên: Nguyễn Văn Test",
            "steps": "1. Điền Email, Họ tên, Mật khẩu, Xác nhận mật khẩu.\n2. Bấm nút 'Đăng ký'.",
            "expected": "Đăng ký thành công, hệ thống thông báo thành công và chuyển sang màn hình Đăng nhập hoặc tự động đăng nhập."
        },
        {
            "id": "TC-MOB-04",
            "module": "Authentication",
            "name": "Đăng nhập thất bại với sai mật khẩu",
            "priority": "Medium",
            "preconditions": "Tại form Đăng nhập",
            "data": "Email: user@example.com\nMật khẩu: sai_pass_999",
            "steps": "1. Nhập Email đúng nhưng Mật khẩu sai.\n2. Bấm nút 'Đăng nhập'.",
            "expected": "Hệ thống báo lỗi đăng nhập không thành công (Incorrect email or password), giữ nguyên form để nhập lại."
        },
        {
            "id": "TC-MOB-05",
            "module": "Authentication",
            "name": "Đăng nhập thành công với tài khoản mẫu",
            "priority": "High",
            "preconditions": "Tại form Đăng nhập",
            "data": "Email: user@example.com\nMật khẩu: 123456",
            "steps": "1. Nhập Email và Mật khẩu chính xác.\n2. Bấm nút 'Đăng nhập'.",
            "expected": "Đăng nhập thành công, chuyển hướng vào màn hình chính, session_id được lưu vào máy."
        },
        {
            "id": "TC-MOB-06",
            "module": "Onboarding & BMI",
            "name": "Khảo sát thể chất và tự động tính chỉ số BMI",
            "priority": "High",
            "preconditions": "Đăng nhập tài khoản, mở Onboarding Survey Dialog",
            "data": "Chiều cao: 175 cm\nCân nặng: 68 kg\nGiới tính: Nam",
            "steps": "1. Di chuyển thanh slider Chiều cao lên 175 cm.\n2. Di chuyển thanh slider Cân nặng lên 68 kg.\n3. Quan sát chỉ số BMI tự động nhảy trên giao diện.",
            "expected": "BMI tự động tính = 22.2, hiển thị phân loại thể trạng 'Bình thường' (Normal). Dữ liệu phản hồi tức thì."
        },
        {
            "id": "TC-MOB-07",
            "module": "Onboarding & BMI",
            "name": "Lưu tùy chọn dinh dưỡng, khẩu vị và dị ứng",
            "priority": "Medium",
            "preconditions": "Đang ở bước 2 & 3 của hộp thoại Khảo sát",
            "data": "Mục tiêu: maintain\nKhẩu vị cay: Cay vừa\nDị ứng: peanut, seafood",
            "steps": "1. Chọn mục tiêu 'Duy trì vóc dáng'.\n2. Chọn độ ăn cay 'Cay vừa'.\n3. Tích chọn dị ứng 'Đậu phộng' và 'Hải sản'.\n4. Bấm 'Lưu hồ sơ dinh dưỡng'.",
            "expected": "Hộp thoại đóng lại thành công, dữ liệu được gửi lưu vào Backend, Tab Tài khoản hiển thị đầy đủ thông tin vừa lưu."
        },
        {
            "id": "TC-MOB-08",
            "module": "Explore & Weather",
            "name": "Hiển thị Banner Thời tiết thực tế và Gợi ý món",
            "priority": "High",
            "preconditions": "Ở màn hình Khám phá (Tab 1)",
            "data": "Toạ độ IP người dùng thực tế",
            "steps": "1. Kiểm tra khối Banner thời tiết trên đỉnh màn hình.\n2. Quan sát nhiệt độ (°C) và tình trạng thời tiết (Nắng, Mây, Mưa...).\n3. Kiểm tra danh sách các danh mục món ăn gợi ý bên dưới banner.",
            "expected": "Banner tải mượt mà, hiển thị nhiệt độ thực tế và danh mục gợi ý phù hợp (vd: Nắng gợi ý Đồ uống giải khát, Mưa gợi ý Lẩu nướng/Món nước nóng)."
        },
        {
            "id": "TC-MOB-09",
            "module": "Explore & Search",
            "name": "Tìm kiếm quán ăn theo từ khóa thời gian thực",
            "priority": "High",
            "preconditions": "Ở màn hình Khám phá (Tab 1)",
            "data": "Từ khóa: 'Phở' hoặc 'Cơm'",
            "steps": "1. Bấm vào thanh tìm kiếm.\n2. Gõ từ khóa 'Phở'.",
            "expected": "Danh sách quán ăn lọc tự động theo từ khóa, chỉ hiển thị các quán có tên hoặc menu liên quan đến Phở."
        },
        {
            "id": "TC-MOB-10",
            "module": "Explore & Filter",
            "name": "Lọc quán ăn theo Danh mục món ăn (Category Pills)",
            "priority": "Medium",
            "preconditions": "Ở màn hình Khám phá (Tab 1)",
            "data": "Chọn danh mục: 'Đồ uống' hoặc 'Bún/Phở'",
            "steps": "1. Cuộn thanh ngang danh mục bên dưới thanh tìm kiếm.\n2. Bấm chọn danh mục 'Đồ uống'.",
            "expected": "Giao diện cập nhật danh sách quán phục vụ nhóm danh mục được chọn, pill danh mục chuyển trạng thái active."
        },
        {
            "id": "TC-MOB-11",
            "module": "Map & PostGIS",
            "name": "Định vị bản đồ không cần cấp quyền phần cứng GPS",
            "priority": "High",
            "preconditions": "Chuyển sang Tab 2 (Bản đồ)",
            "data": "Không yêu cầu popup Browser Location",
            "steps": "1. Bấm chọn Tab 2 (Bản đồ).\n2. Quan sát tâm bản đồ và biểu tượng định vị.",
            "expected": "Bản đồ OpenStreetMap mở ra mượt mà, hiển thị Chấm xanh (vị trí IP người dùng) và các Ghim đỏ (quán ăn xung quanh), không hiện popup xin quyền GPS phiền hà."
        },
        {
            "id": "TC-MOB-12",
            "module": "Map & PostGIS",
            "name": "Tương tác Ghim quán ăn và Nút Vị trí của tôi",
            "priority": "High",
            "preconditions": "Đang ở Tab Bản đồ",
            "data": "Click ghim quán ăn trên bản đồ",
            "steps": "1. Kéo bản đồ ra vị trí khác.\n2. Bấm nút nổi FAB 'Vị trí của tôi' -> Kiểm tra tâm bản đồ.\n3. Bấm vào một Ghim đỏ bất kỳ.",
            "expected": "Bấm 'Vị trí của tôi' đưa tâm bản đồ quay lập tức về vị trí của người dùng. Bấm ghim mở ra Bottom Sheet tóm tắt thông tin quán (tên, km, nút mở menu)."
        },
        {
            "id": "TC-MOB-13",
            "module": "Menu & Details",
            "name": "Xem chi tiết Món ăn và Nhãn cảnh báo dị ứng",
            "priority": "Medium",
            "preconditions": "Mở xem thực đơn của một quán ăn",
            "data": "Danh sách món ăn",
            "steps": "1. Mở xem thực đơn quán.\n2. Kiểm tra các trường thông tin của món: Giá tiền VNĐ, nhãn độ cay 🌶️, tag bữa ăn (Sáng/Trưa/Tối), nguyên liệu và nhãn cảnh báo dị ứng.",
            "expected": "Hiển thị đầy đủ, rõ ràng các tag độ cay và dị ứng thực phẩm giúp thực khách có lựa chọn an toàn."
        },
        {
            "id": "TC-MOB-14",
            "module": "Favourites",
            "name": "Thả tim lưu món ăn vào Danh sách Yêu thích",
            "priority": "High",
            "preconditions": "Đã đăng nhập tài khoản User",
            "data": "Click nút Thả tim trên món ăn",
            "steps": "1. Bấm nút Thả tim trên một món ăn trong menu.\n2. Chuyển sang Tab 3 (Món Yêu thích).",
            "expected": "Món ăn vừa thích xuất hiện đầy đủ trong danh sách Tab 3 kèm tên quán và giá bán hiện hành."
        },
        {
            "id": "TC-MOB-15",
            "module": "Favourites",
            "name": "Bỏ yêu thích món ăn",
            "priority": "Medium",
            "preconditions": "Đang ở Tab 3 (Món Yêu thích), có ít nhất 1 món đã lưu",
            "data": "Click nút Bỏ thích",
            "steps": "1. Tại Tab 3, bấm vào biểu tượng Trái tim để bỏ thích món đó.",
            "expected": "Món ăn được xoá khỏi danh sách yêu thích ngay lập tức. Nếu hết món, hiển thị giao diện trống thân thiện."
        },
        {
            "id": "TC-MOB-16",
            "module": "Account & Profile",
            "name": "Xem hồ sơ chỉ số thể trạng và Đăng xuất an toàn",
            "priority": "Medium",
            "preconditions": "Chuyển sang Tab 4 (Tài khoản), đã đăng nhập",
            "data": "Tài khoản hiện hành",
            "steps": "1. Kiểm tra Thẻ thống kê BMI, Chiều cao, Cân nặng, Mục tiêu dinh dưỡng.\n2. Bấm nút 'Đăng xuất'.",
            "expected": "Hiển thị chuẩn xác các chỉ số dinh dưỡng. Bấm Đăng xuất thu hồi session an toàn và đưa người dùng về trạng thái Khách vãng lai."
        }
    ]

    # =========================================================================
    # SHEET 3: TEST CASES WEB ADMIN CONSOLE (QUẢN TRỊ VIÊN)
    # =========================================================================
    cases_web = [
        {
            "id": "TC-WEB-01",
            "module": "Authentication",
            "name": "Hiển thị trang đăng nhập Quản trị viên",
            "priority": "High",
            "preconditions": "Mở http://localhost:5173",
            "data": "Trang Login",
            "steps": "1. Điều hướng tới http://localhost:5173.\n2. Kiểm tra form đăng nhập và các thành phần giao diện.",
            "expected": "Trang đăng nhập hiển thị đầy đủ tiêu đề 'PTC1 Management Console', ô nhập Email, Mật khẩu, nút Đăng nhập và nút 'Đăng nhập mẫu'."
        },
        {
            "id": "TC-WEB-02",
            "module": "Authentication",
            "name": "Đăng nhập nhanh với nút Đăng nhập mẫu",
            "priority": "High",
            "preconditions": "Đang ở màn hình Login Web Admin",
            "data": "Click nút 'Đăng nhập mẫu'",
            "steps": "1. Click vào nút 'Đăng nhập mẫu' (Secondary button).",
            "expected": "Hệ thống tự động điền admin@example.com / admin123, đăng nhập thành công và chuyển ngay vào giao diện Admin Portal."
        },
        {
            "id": "TC-WEB-03",
            "module": "Dashboard Overview",
            "name": "Xác thực 4 thẻ KPI Thống kê Nền tảng",
            "priority": "High",
            "preconditions": "Đang ở Tab 1 (Tổng quan Dashboard)",
            "data": "Dữ liệu database hiện hành",
            "steps": "1. Kiểm tra 4 thẻ KPI đầu trang: Tổng cơ sở quán ăn, Tổng món ăn, Thực khách đã đăng ký, Tỷ lệ hoạt động.\n2. So sánh với danh sách quán mới bên dưới.",
            "expected": "Hiển thị đầy đủ 4 thẻ KPI với số liệu thực tế, format số đẹp mắt, danh sách quán mới tải chính xác."
        },
        {
            "id": "TC-WEB-04",
            "module": "Restaurants",
            "name": "Tìm kiếm quán ăn trên bảng danh sách",
            "priority": "Medium",
            "preconditions": "Chuyển sang Tab 2 (Quản lý Quán ăn)",
            "data": "Từ khóa tìm kiếm: 'Phở' hoặc tên địa chỉ",
            "steps": "1. Nhập từ khóa vào ô 'Tìm kiếm theo tên quán, địa chỉ, hotline...'.",
            "expected": "Bảng danh sách lọc dữ liệu tức thì theo từ khóa nhập vào."
        },
        {
            "id": "TC-WEB-05",
            "module": "Restaurants",
            "name": "Tự động tra cứu Kinh độ/Vĩ độ bằng Geocoding",
            "priority": "High",
            "preconditions": "Mở Modal '+ Thêm quán mới'",
            "data": "Địa chỉ: 'Trâu Quỳ, Gia Lâm, Hà Nội'",
            "steps": "1. Nhập tên quán và nhập địa chỉ 'Trâu Quỳ, Gia Lâm, Hà Nội'.\n2. Bấm nút 'Tìm toạ độ từ địa chỉ' (Geocoding).",
            "expected": "Hệ thống gọi OpenStreetMap Nominatim, tự động điền giá trị Kinh độ (longitude ≈ 105.93) và Vĩ độ (latitude ≈ 21.01)."
        },
        {
            "id": "TC-WEB-06",
            "module": "Restaurants",
            "name": "Tạo mới cơ sở quán ăn có nhãn Sponsor",
            "priority": "High",
            "preconditions": "Tại Modal thêm quán mới",
            "data": "Tên: Quán Ăn Test Manual QA\nHotline: 0912345678\nGiờ: 07:00 - 22:00\nTích chọn: Nhà tài trợ (is_sponsor)",
            "steps": "1. Điền đầy đủ thông tin tên, hotline, giờ mở/đóng cửa.\n2. Tích chọn cờ 'Nhà tài trợ'.\n3. Bấm 'Tạo cơ sở'.",
            "expected": "Modal đóng lại, thông báo tạo thành công, quán mới xuất hiện ngay trên bảng danh sách kèm huy hiệu Sponsor."
        },
        {
            "id": "TC-WEB-07",
            "module": "Restaurants",
            "name": "Bật/Tắt nhanh trạng thái hoạt động của quán",
            "priority": "Medium",
            "preconditions": "Tại bảng danh sách Quán ăn",
            "data": "Click nút Toggle trạng thái",
            "steps": "1. Tìm một quán đang ở trạng thái 'Đang hoạt động'.\n2. Click nút Toggle chuyển sang 'Tạm đóng'.",
            "expected": "Trạng thái đổi lập tức, badge trạng thái cập nhật màu tương ứng và lưu thành công về cơ sở dữ liệu."
        },
        {
            "id": "TC-WEB-08",
            "module": "Menu Management",
            "name": "Bố cục Master-Detail Quản lý thực đơn",
            "priority": "High",
            "preconditions": "Chuyển sang Tab 3 (Thực đơn & Danh mục)",
            "data": "Chọn quán ăn ở cột Master trái",
            "steps": "1. Quan sát cột trái (Master): danh sách các quán ăn kèm ô tìm kiếm.\n2. Bấm chọn một quán ăn.\n3. Quan sát cột phải (Detail).",
            "expected": "Cột phải tải danh mục và danh sách các món ăn thuộc riêng quán được chọn, thông tin đồng bộ chính xác."
        },
        {
            "id": "TC-WEB-09",
            "module": "Menu Management",
            "name": "Thêm nhóm Danh mục món ăn toàn cục",
            "priority": "Medium",
            "preconditions": "Tại cột phải quản lý danh mục",
            "data": "Tên danh mục: 'Món Chay Thanh Đạm'\nMô tả: 'Các món thuần chay lành mạnh'\nThứ tự: 10",
            "steps": "1. Bấm nút '+ Thêm danh mục'.\n2. Điền tên, mô tả và thứ tự hiển thị.\n3. Bấm 'Lưu danh mục'.",
            "expected": "Danh mục mới được thêm vào hệ thống toàn cục, hiển thị trong danh sách chọn nhóm món."
        },
        {
            "id": "TC-WEB-10",
            "module": "Menu Management",
            "name": "Thêm món ăn mới với giá VNĐ, độ cay và bữa ăn",
            "priority": "High",
            "preconditions": "Đang chọn một quán ăn tại cột Detail",
            "data": "Tên món: 'Cơm Gà Xối Mỡ Sốt Cay'\nGiá: 55000 VNĐ\nĐộ cay: 2 (Cay vừa)\nBữa ăn: Trưa, Tối\nNguyên liệu: Gà, cơm, ớt",
            "steps": "1. Bấm '+ Thêm món mới'.\n2. Nhập đầy đủ thông tin tên món, giá bán, chọn danh mục, mức độ cay, tag bữa ăn, nguyên liệu.\n3. Bấm 'Lưu món ăn'.",
            "expected": "Món ăn mới xuất hiện dưới dạng thẻ Card trong menu của quán, giá hiển thị định dạng chuẩn '55.000 ₫', tag cay hiển thị đúng."
        },
        {
            "id": "TC-WEB-11",
            "module": "Menu Management",
            "name": "Chuyển đổi trạng thái Còn món / Hết món",
            "priority": "Medium",
            "preconditions": "Tại Card món ăn trong danh sách thực đơn",
            "data": "Click nút Toggle tình trạng còn món",
            "steps": "1. Bấm chuyển đổi trạng thái Còn món -> Hết món trên một món ăn.",
            "expected": "Món ăn cập nhật badge 'Tạm hết món', đồng bộ ngay lập tức sang ứng dụng Mobile của thực khách."
        },
        {
            "id": "TC-WEB-12",
            "module": "Accounts",
            "name": "Xem danh sách và tìm kiếm Thực khách",
            "priority": "Medium",
            "preconditions": "Chuyển sang Tab 4 (Tài khoản Khách hàng)",
            "data": "Từ khóa tìm kiếm: 'user@example.com'",
            "steps": "1. Nhập email vào ô tìm kiếm tài khoản.\n2. Kiểm tra thông tin ngày tạo, User ID, trạng thái hoạt động.",
            "expected": "Danh sách hiển thị chuẩn xác, thông tin bảo mật (không lộ password hash), tìm kiếm phản hồi nhanh."
        }
    ]

    # =========================================================================
    # SHEET 4: TEST CASES BACKEND SWAGGER API
    # =========================================================================
    cases_api = [
        {
            "id": "TC-API-01",
            "module": "Swagger Docs",
            "name": "Tải trang OpenAPI Swagger UI",
            "priority": "High",
            "preconditions": "Backend đang chạy tại port 8001",
            "data": "GET http://localhost:8001/docs",
            "steps": "1. Mở trình duyệt truy cập http://localhost:8001/docs.\n2. Chờ tài liệu Swagger UI tải hoàn tất.",
            "expected": "HTTP 200 OK, hiển thị đầy đủ các nhóm endpoint: Auth, Map, Restaurants, Categories, Dishes, Weather."
        },
        {
            "id": "TC-API-02",
            "module": "Map & Geolocation",
            "name": "API Định vị toạ độ IP Internet không fallback HVNN",
            "priority": "High",
            "preconditions": "Truy cập endpoint GET /api/v1/map/ip-location",
            "data": "Client IP Request thực tế",
            "steps": "1. Tại Swagger, tìm endpoint GET /api/v1/map/ip-location.\n2. Bấm 'Try it out' -> 'Execute'.",
            "expected": "HTTP 200 OK. JSON trả về toạ độ latitude, longitude thực tế của kết nối Internet, trường is_fallback=false."
        },
        {
            "id": "TC-API-03",
            "module": "PostGIS Spatial",
            "name": "API Truy vấn không gian PostGIS Radius ST_DWithin",
            "priority": "High",
            "preconditions": "Truy cập endpoint GET /api/v1/restaurants/nearby",
            "data": "lat: 21.0184, lon: 105.8461, radius_km: 30",
            "steps": "1. Nhập lat=21.0184, lon=105.8461, radius_km=30.\n2. Bấm 'Execute'.",
            "expected": "HTTP 200 OK, trả về danh sách các quán ăn lân cận sắp xếp tăng dần theo trường distance_meters."
        },
        {
            "id": "TC-API-04",
            "module": "Weather Recommendation",
            "name": "API Thời tiết thực tế và Danh mục gợi ý",
            "priority": "Medium",
            "preconditions": "Truy cập endpoint GET /api/v1/weather/current",
            "data": "lat: 21.0184, lon: 105.8461",
            "steps": "1. Nhập toạ độ người dùng.\n2. Bấm 'Execute'.",
            "expected": "HTTP 200 OK, trả về nhiệt độ thực tế (°C), tình trạng thời tiết và danh sách danh mục món ăn đề xuất."
        }
    ]

    # =========================================================================
    # SHEET 5: BÁO CÁO LỖI (BUG LOG TEMPLATE)
    # =========================================================================
    def setup_bug_sheet():
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
            cell.fill = fill_header
            cell.alignment = align_center
            cell.border = thin_border

        # 3 dòng mẫu ghi nhận lỗi
        sample_bugs = [
            {
                "id": "BUG-01 (Mẫu)",
                "tc": "TC-WEB-05",
                "sub": "Web Admin",
                "title": "Địa chỉ quá dài gây tràn chữ trong khung Geocoding",
                "sev": "Minor",
                "steps": "1. Mở modal thêm quán mới\n2. Nhập địa chỉ hơn 150 ký tự\n3. Quan sát ô nhập liệu",
                "actual": "Chữ bị tràn nhẹ sang mép phải nút tìm kiếm",
                "expected": "Chữ tự động xuống dòng hoặc có thanh cuộn",
                "status": "Open",
                "reporter": "Tester A - 24/10/2026"
            }
        ]

        for r_idx, b in enumerate(sample_bugs, start=4):
            ws.row_dimensions[r_idx].height = 40
            ws.cell(row=r_idx, column=1, value=r_idx - 3).alignment = align_top_center
            ws.cell(row=r_idx, column=2, value=b["id"]).alignment = align_top_center
            ws.cell(row=r_idx, column=2).font = font_code
            ws.cell(row=r_idx, column=3, value=b["tc"]).alignment = align_top_center
            ws.cell(row=r_idx, column=4, value=b["sub"]).alignment = align_top_left
            ws.cell(row=r_idx, column=5, value=b["title"]).alignment = align_top_left
            ws.cell(row=r_idx, column=5).font = font_bold
            ws.cell(row=r_idx, column=6, value=b["sev"]).alignment = align_top_center
            ws.cell(row=r_idx, column=7, value=b["steps"]).alignment = align_top_left
            ws.cell(row=r_idx, column=8, value=b["actual"]).alignment = align_top_left
            ws.cell(row=r_idx, column=9, value=b["expected"]).alignment = align_top_left
            ws.cell(row=r_idx, column=10, value=b["status"]).alignment = align_top_center
            ws.cell(row=r_idx, column=11, value=b["reporter"]).alignment = align_top_left

            for c in range(1, 12):
                cell = ws.cell(row=r_idx, column=c)
                cell.border = thin_border
                if c not in [2, 5]:
                    cell.font = font_regular

        # Thêm 15 hàng trống có sẵn border để tester nhập liệu trực tiếp
        for empty_r in range(5, 20):
            ws.row_dimensions[empty_r].height = 30
            ws.cell(row=empty_r, column=1, value=empty_r - 3).alignment = align_top_center
            for c in range(1, 12):
                ws.cell(row=empty_r, column=c).border = thin_border
                ws.cell(row=empty_r, column=c).font = font_regular

        col_widths = {
            1: 6,   # STT
            2: 15,  # Mã Bug
            3: 16,  # Mã TC
            4: 15,  # Phân hệ
            5: 30,  # Tiêu đề
            6: 15,  # Severity
            7: 35,  # Steps
            8: 30,  # Actual
            9: 30,  # Expected
            10: 15, # Trạng thái
            11: 22  # Reporter
        }
        for col_idx, width in col_widths.items():
            col_letter = get_column_letter(col_idx)
            ws.column_dimensions[col_letter].width = width

    # Khởi tạo các sheet
    setup_test_sheet("Mobile App (Thực Khách)", cases_mobile)
    setup_test_sheet("Web Admin (Quản Trị)", cases_web)
    setup_test_sheet("Backend API (Swagger)", cases_api)
    setup_bug_sheet()

    output_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "docs", "reports")
    os.makedirs(output_dir, exist_ok=True)
    output_path = os.path.join(output_dir, "PTC1_Manual_Test_Cases.xlsx")
    wb.save(output_path)
    print(f"[V] Da tao thanh cong file Excel Manual Test: {output_path}")

if __name__ == "__main__":
    build_manual_test_excel()
