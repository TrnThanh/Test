# Scripts & Data Directory (PTC1)

Thư mục chứa các công cụ hỗ trợ, dữ liệu ban đầu và tiện ích xuất báo cáo của hệ thống PTC1.

---

## 📁 Danh sách tệp & Mục đích sử dụng

| Tệp / Thư mục | Định dạng | Mục đích sử dụng |
| :--- | :--- | :--- |
| **`quan_an_Gia_Lam_Ha_Noi_full.json`** | JSON | Bộ dữ liệu gốc 204 quán ăn thực tế và tọa độ tại Huyện Gia Lâm. Được `InitialSeedService` tự động nạp vào database khi khởi động backend. |
| **`database_dump.sql`** | SQL Dump | Bản sao lưu cấu trúc và dữ liệu PostgreSQL phục vụ script `XUAT_DATABASE.bat` khi cần sao lưu thủ công. |
| **`weather_400_mau_so_2000_2025.json`** | JSON | Bộ dữ liệu chuẩn hóa 400 mẫu thời tiết theo 4 mùa giai đoạn 2000-2025, được `WeatherService` tự động nạp (upsert) khi khởi động server. |
| **`weather_400_mau_so_2000_2025.sql`** | SQL Data | Bộ dữ liệu gốc 400 mẫu thời tiết theo mùa từ CSDL quan trắc 2000-2025. |
| **`convert_weather_sql_to_json.py`** | Python | Tiện ích chuyển đổi dữ liệu thời tiết từ SQL sang định dạng JSON chuẩn. |
| **`export_test_cases_excel.py`** | Python | Công cụ tự động kết xuất danh sách Test Cases ra định dạng bảng Excel (`PTC1_Test_Cases_Report.xlsx`). |
| **`export_manual_test_cases_excel.py`** | Python | Công cụ kết xuất báo cáo kiểm thử thủ công (`PTC1_Manual_Test_Cases.xlsx`). |
| **`render_diagrams.py`** | Python | Tiện ích render biểu đồ Mermaid (ERD, Class Diagram) trong thư mục `docs/` thành file ảnh SVG/PNG. |

> [!NOTE]
> Các script seed demo thử nghiệm cũ (`seed_gialam_150_restaurants.py`, `seed_gialam_food_data.py`, `seed_json_restaurants.py`) đã được dọn dẹp vì hệ thống hiện tại đã tích hợp cơ chế tự động nạp an toàn thông qua `server/app/services/initial_seed_service.py`.
