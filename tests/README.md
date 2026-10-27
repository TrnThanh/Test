# Kiểm Thử Toàn Diện (PTC1 Testing Suite)

Thư mục chứa các kịch bản kiểm thử tự động giao diện (End-to-End E2E) và bộ ảnh chụp màn hình minh hoạ giao diện cho toàn đội ngũ phát triển.

---

## 📁 Cấu Trúc Thư Mục Kiểm Thử

| Thư mục / Tệp | Loại kiểm thử | Mục đích & Công cụ |
| :--- | :--- | :--- |
| **`server/tests/`** | **Unit & Integration Tests** | 104 test cases kiểm thử logic API FastAPI, bảo mật, xác thực và PostGIS trên database PostgreSQL `ptc1_test_db`.<br>👉 Chạy lệnh: `pytest server/tests` |
| **`tests/test_detailed_workflows.py`** | **E2E Workflows (Playwright)** | Kịch bản tự động duyệt qua tất cả luồng nghiệp vụ trên Web Admin và Mobile App. |
| **`tests/test_playwright_e2e.py`** | **E2E Visual Check** | Kịch bản kiểm tra giao diện tổng thể và kết nối mạng. |
| **`tests/screenshots/`** | **UI Screenshots** | Bộ ảnh chụp màn hình trực quan các phân hệ (Admin, Mobile, Explore, Favourites, Map) phục vụ các thành viên trong nhóm theo dõi và nghiệm thu. |
| **`docs/reports/`** | **Test Reports** | Chứa các file bảng tính Excel báo cáo kết quả kiểm thử tự động (`PTC1_Test_Cases_Report.xlsx`) và thủ công (`PTC1_Manual_Test_Cases.xlsx`). |
