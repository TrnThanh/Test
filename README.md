### Cách chạy cài đặt:
- **Qua PowerShell:** Mở PowerShell với quyền Administrator tại thư mục dự án và chạy:
   `powershell
   Set-ExecutionPolicy Bypass -Scope Process
   .\setup.ps1
   `
---

## 🏃 Khởi Chạy Ứng Dụng (1-Click Launcher)

Dự án cung cấp duy nhất file batch khởi chạy 1-click chuẩn hoá:
- **Khởi chạy Toàn Bộ Hệ Thống (1-Click)**: Click đúp file **CHAY_TAT_CA.bat** (Tự động khởi động đồng thời Backend FastAPI cổng 8001, Web Admin cổng 5173 và Flutter Mobile cổng 3000 trong các cửa sổ riêng biệt).
- **Tự động Nạp Dữ liệu Khởi động (Auto-Seed)**: Khi khởi chạy Backend qua CHAY_TAT_CA.bat, hệ thống tự động khởi tạo và nạp toàn diện dữ liệu mẫu (204 quán ăn Gia Lâm, 775 món ăn, 400 mẫu thời tiết theo mùa, tài khoản Admin & User) mà không cần nạp thủ công.

