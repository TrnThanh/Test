# Khung Kiểm Thử Giao Diện E2E Đa Tầng (`e2e_flows/`)

Thư mục chứa toàn bộ hệ thống kiểm thử tự động luồng giao diện trực quan (End-to-End Workflows) cho dự án PTC1, kết hợp công nghệ **Playwright** và hệ thống giám sát lỗi đa tầng:

1. **Kiểm tra Giao diện (UI Assertions)**: Tự động điều hướng, click, chuyển tab, kiểm tra hiển thị.
2. **Soi Lỗi Console Trình Duyệt (`ConsoleMonitor`)**: Lắng nghe `console.error`, `console.warn`, và các ngoại lệ JavaScript runtime (`pageerror`).
3. **Soi Lỗi Server Backend (`ServerMonitor`)**: Lắng nghe các cuộc gọi mạng API, phát hiện lỗi kết nối (`requestfailed`) và phản hồi lỗi HTTP (`status >= 400`).
4. **Chụp Ảnh Màn Hình (`screenshots/`)**: Tự động chụp và lưu lại ảnh minh chứng trực quan cho từng bước thao tác giao diện.
5. **Xuất Báo Cáo Chi Tiết (`reports/summary.md`)**: Bảng thống kê trực quan hiển thị trên Terminal và file Markdown tổng hợp kết quả.

---

## 📁 Cấu Trúc Thư Mục

```
e2e_flows/
├── config.py                 # Cấu hình địa chỉ mạng (ports 8001, 5173, 3000), timeouts, viewports
├── runner.py                 # Bộ điều phối thực thi chính & xuất báo cáo
├── monitors/                 # Bộ giám sát lỗi đa tầng
│   ├── console_monitor.py   # Lắng nghe Console trình duyệt (logs, errors, pageerror)
│   └── server_monitor.py    # Lắng nghe Server Backend (HTTP >= 400, failed requests, ping)
├── flows/                    # Các kịch bản luồng giao diện
│   ├── flow_backend_api.py  # Luồng kiểm thử Swagger UI và các API trực tiếp
│   ├── flow_web_admin.py    # Luồng Web Admin (Đăng nhập, KPIs, Quán ăn, Menus, Users, Weather)
│   └── flow_mobile_web.py   # Luồng Flutter Mobile (Trang chủ, Bản đồ OSM, Yêu thích, Tài khoản)
├── screenshots/             # Thư mục lưu trữ ảnh chụp màn hình sau mỗi lần chạy
└── reports/                 # Thư mục lưu báo cáo summary.md và summary.json
```

---

## 🚀 Cách Chạy Kiểm Thử

### Cách 1: Chạy nhanh bằng 1-Click (Khuyến nghị trên Windows)
Chỉ cần nhấp đúp chuột vào file:
```cmd
CHAY_TEST_UI.bat
```
Script sẽ tự động kiểm tra môi trường ảo `.venv`, thực thi toàn bộ các luồng giao diện và hiển thị bảng báo cáo tổng kết ngay trên màn hình.

### Cách 2: Chạy bằng lệnh dòng lệnh Python
```powershell
# Chạy toàn bộ các luồng (chế độ ngầm headless)
.\.venv\Scripts\python.exe -m e2e_flows.runner

# Mở trình duyệt Chrome trực quan để quan sát bằng mắt
.\.venv\Scripts\python.exe -m e2e_flows.runner --headed

# Chỉ chạy riêng luồng Web Admin
.\.venv\Scripts\python.exe -m e2e_flows.runner --flow admin

# Chỉ chạy riêng luồng Mobile Web
.\.venv\Scripts\python.exe -m e2e_flows.runner --flow mobile
```

---

## ⚙️ Điều Kiện Tiên Quyết
Trước khi chạy test giao diện, các dịch vụ cần được khởi động để Playwright có thể truy cập:
- **Khởi động nhanh tất cả**: Chạy file `CHAY_TAT_CA.bat` ở thư mục gốc.
- Hoặc chạy lẻ từng phần:
  + Backend: `CHAY_SERVER.bat` (Port 8001)
  + Web Admin: `CHAY_WEB.bat` (Port 5173)
  + Mobile Web: `CHAY_MOBILE.bat` (Port 3000)
