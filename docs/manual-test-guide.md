# BỘ TÀI LIỆU HƯỚNG DẪN KIỂM THỬ THỦ CÔNG TOÀN DIỆN (MANUAL TEST GUIDE)
## HỆ THỐNG NỀN TẢNG ẨM THỰC KHÔNG GIAN PTC1 (SPATIAL FOOD PLATFORM)

---

## 📌 1. THÔNG TIN MÔI TRƯỜNG & TÀI KHOẢN KIỂM THỬ

### 1.1. Địa chỉ dịch vụ (Access Endpoints)
| Dịch vụ / Ứng dụng | URL Truy Cập | Mục đích |
| :--- | :--- | :--- |
| **Mobile App (Thực khách)** | [http://localhost:3000](http://localhost:3000) | Ứng dụng dành cho thực khách (khám phá, xem bản đồ, gợi ý thời tiết, thực đơn, lưu yêu thích, khảo sát thể chất BMI) |
| **Web Admin Console** | [http://localhost:5173](http://localhost:5173) | Bảng điều khiển quản trị viên (quản lý quán ăn, thực đơn món, danh mục, tài khoản, KPIs) |
| **Backend API (Swagger Docs)** | [http://localhost:8001/docs](http://localhost:8001/docs) | Tài liệu kiểm tra API, OpenAPI Schema và dịch vụ PostGIS/Map |

---

### 1.2. Danh sách Tài khoản Kiểm thử Mặc định (Test Accounts)
| Vai trò (Role) | Email Đăng Nhập | Mật Khẩu | Nền Tảng Áp Dụng | Ghi Chú |
| :--- | :--- | :--- | :--- | :--- |
| **Quản trị viên (Super Admin)** | `admin@example.com` | `admin123` | **Web Admin** (`:5173`) | Tài khoản toàn quyền, có nút "Đăng nhập mẫu" 1-click |
| **Quản trị viên phụ (Admin)** | `admin@ptc1.vn` | `admin123` | **Web Admin** (`:5173`) | Tài khoản quản trị kiểm thử phân quyền |
| **Thực khách (User)** | `user@example.com` | `123456` | **Mobile App** (`:3000`) | Đã hoàn thành khảo sát thể chất & BMI |
| **Thực khách Mới** | *Tự đăng ký trên App* | *Tùy chọn* | **Mobile App** (`:3000`) | Dùng test luồng đăng ký & Onboarding lần đầu |
| **Khách vãng lai (Guest)** | *Không cần tài khoản* | *Không có* | **Mobile App** (`:3000`) | Bấm nút "Tiếp tục với tư cách Khách" để test Auth Gate |

---

## 📱 2. DANH SÁCH 28 TEST CASES KIỂM THỬ THỦ CÔNG MOBILE APP (`http://localhost:3000`)

### Nhóm 1: Guest Mode & Thanh Điều Hướng (Navigation Shell)
- **`TC-MAN-MOB-01`**: Truy cập ứng dụng với tư cách Khách vãng lai (Guest Mode).
- **`TC-MAN-MOB-02`**: Chuyển đổi tuần tự 4 Tab điều hướng dưới (Khám phá, Bản đồ, Yêu thích, Tài khoản).
- **`TC-MAN-MOB-03`**: Khách vãng lai mở xem thực đơn chi tiết của quán ăn mà không cần đăng nhập.
- **`TC-MAN-MOB-04`**: Chặn Auth Gate khi Khách vãng lai bấm Thả tim (❤) trên món ăn.
- **`TC-MAN-MOB-05`**: Chặn Auth Gate khi Khách vãng lai chuyển sang Tab Tài khoản.

### Nhóm 2: Xác thực Thực khách (Authentication)
- **`TC-MAN-MOB-06`**: Kiểm tra validate form Đăng ký khi để trống dữ liệu.
- **`TC-MAN-MOB-07`**: Đăng ký tài khoản Thực khách mới thành công (Happy Path).
- **`TC-MAN-MOB-08`**: Đăng ký với Email đã tồn tại trong hệ thống (báo lỗi trùng email).
- **`TC-MAN-MOB-09`**: Đăng nhập thất bại khi nhập sai mật khẩu (báo lỗi HTTP 401).
- **`TC-MAN-MOB-10`**: Đăng nhập thành công với tài khoản mẫu `user@example.com` / `123456`.
- **`TC-MAN-MOB-11`**: Tự động phục hồi phiên làm việc khi tải lại trang trình duyệt (F5).

### Nhóm 3: Khảo sát Onboarding & Tính toán BMI Tự động
- **`TC-MAN-MOB-12`**: Tự động tính BMI và hiển thị thể trạng khi kéo slider Chiều cao và Cân nặng (BMI = 20.8 -> Bình thường).
- **`TC-MAN-MOB-13`**: Kiểm tra phân loại thể trạng BMI Thừa cân / Béo phì (Chiều cao 160cm, Cân nặng 80kg -> BMI 31.2).
- **`TC-MAN-MOB-14`**: Chọn Mục tiêu dinh dưỡng (Giảm cân, Tăng cơ, Duy trì), Khẩu vị cay (0–3) và Khung ngân sách.
- **`TC-MAN-MOB-15`**: Chọn Cảnh báo dị ứng thực phẩm (Đậu phộng, Hải sản...) và Lưu hồ sơ dinh dưỡng.

### Nhóm 4: Khám phá Ẩm thực & Gợi ý Thời tiết (Explore Screen)
- **`TC-MAN-MOB-16`**: Hiển thị Banner Thời tiết thực tế tại toạ độ người dùng (°C và mô tả khí hậu).
- **`TC-MAN-MOB-17`**: Kiểm tra danh mục gợi ý theo điều kiện thời tiết (Nắng mát gợi ý đồ uống, Lạnh gợi ý lẩu nướng).
- **`TC-MAN-MOB-18`**: Tìm kiếm thời gian thực theo tên quán ăn hoặc món ăn qua ô Search Bar.
- **`TC-MAN-MOB-19`**: Lọc quán ăn bằng thanh trượt Danh mục món (Category Pills).
- **`TC-MAN-MOB-20`**: Hiển thị thông tin Thẻ Quán ăn: Huy hiệu Nhà tài trợ (Sponsor), khoảng cách km và trạng thái mở cửa.

### Nhóm 5: Bản đồ Không gian Tương tác & PostGIS (Map Screen)
- **`TC-MAN-MOB-21`**: Hiển thị Bản đồ OpenStreetMap và Chấm định vị người dùng theo IP (không cần cấp quyền phần cứng GPS).
- **`TC-MAN-MOB-22`**: Thao tác kéo/zoom bản đồ và Nút nổi FAB "Vị trí của tôi" (tự động bay tâm về vị trí người dùng).
- **`TC-MAN-MOB-23`**: Bấm Ghim quán ăn trên bản đồ mở Bottom Sheet tóm tắt (tên, km, nút mở menu).
- **`TC-MAN-MOB-24`**: Tìm kiếm địa chỉ trên bản đồ qua ô Search Bar Nominatim Geocoding.

### Nhóm 6: Thực đơn Quán, Yêu thích & Hồ sơ Cá nhân
- **`TC-MAN-MOB-25`**: Kiểm tra chi tiết món: Tag cay 🌶️, Bữa ăn (Sáng/Trưa/Tối), Nguyên liệu, Cảnh báo dị ứng, Badge Còn/Hết món.
- **`TC-MAN-MOB-26`**: Thả tim món ăn và kiểm tra hiển thị tại Tab Yêu thích (Favourites).
- **`TC-MAN-MOB-27`**: Bỏ yêu thích món ăn tại Tab Yêu thích và kiểm tra cập nhật tức thì.
- **`TC-MAN-MOB-28`**: Kiểm tra thông tin Thể chất BMI trên Tab Tài khoản và Đăng xuất an toàn.

---

## 💻 3. DANH SÁCH 24 TEST CASES KIỂM THỬ THỦ CÔNG WEB ADMIN (`http://localhost:5173`)

### Nhóm 1: Xác thực Quản trị viên (Admin Authentication)
- **`TC-MAN-WEB-01`**: Hiển thị giao diện Form Đăng nhập Quản trị viên.
- **`TC-MAN-WEB-02`**: Validate bỏ trống Email/Mật khẩu khi bấm Đăng nhập.
- **`TC-MAN-WEB-03`**: Đăng nhập thất bại khi nhập sai mật khẩu Admin (HTTP 401).
- **`TC-MAN-WEB-04`**: Đăng nhập nhanh với nút "Đăng nhập mẫu" 1-Click (`admin@example.com` / `admin123`).
- **`TC-MAN-WEB-05`**: Đăng xuất Quản trị viên an toàn, thu hồi session và chuyển về màn hình đăng nhập.

### Nhóm 2: Bảng Điều Khiển Tổng Quan (Dashboard Overview)
- **`TC-MAN-WEB-06`**: Xác thực 4 thẻ KPI Thống kê Nền tảng thời gian thực (Cơ sở, Món ăn, Thực khách, Tỷ lệ hoạt động).
- **`TC-MAN-WEB-07`**: Kiểm tra Bảng Quán ăn mới nhất trên Dashboard.

### Nhóm 3: Quản lý Quán ăn (Restaurants Management)
- **`TC-MAN-WEB-08`**: Tìm kiếm quán ăn tức thì trên Data Table.
- **`TC-MAN-WEB-09`**: Lọc quán ăn theo Trạng thái Hoạt động (Dropdown: Tất cả / Đang hoạt động / Tạm đóng).
- **`TC-MAN-WEB-10`**: Mở Modal Thêm quán mới và kiểm tra các trường nhập liệu.
- **`TC-MAN-WEB-11`**: Sử dụng tính năng "Điền nhanh toạ độ HVNN" (HVNN Preset button).
- **`TC-MAN-WEB-12`**: Tự động tra cứu Kinh độ/Vĩ độ bằng Geocoding OpenStreetMap.
- **`TC-MAN-WEB-13`**: Tạo mới Quán ăn có cấu hình Nhà tài trợ (`is_sponsor`).
- **`TC-MAN-WEB-14`**: Chỉnh sửa thông tin Quán ăn (Edit Restaurant).
- **`TC-MAN-WEB-15`**: Bật/Tắt nhanh trạng thái hoạt động của quán (Toggle Status).
- **`TC-MAN-WEB-16`**: Xoá Quán ăn kèm Hộp thoại xác nhận an toàn (Cascade Delete xoá các món liên quan).

### Nhóm 4: Quản lý Thực đơn & Danh mục (Menu Master-Detail)
- **`TC-MAN-WEB-17`**: Bố cục Master-Detail và Tìm kiếm Quán ở cột trái (Master).
- **`TC-MAN-WEB-18`**: Tạo mới Nhóm Danh mục món ăn toàn cục.
- **`TC-MAN-WEB-19`**: Thêm món ăn mới với giá VNĐ, độ cay (0–3), tag bữa ăn và nguyên liệu.
- **`TC-MAN-WEB-20`**: Chuyển đổi trạng thái Còn món / Hết món tức thì.
- **`TC-MAN-WEB-21`**: Lọc món ăn theo Nhóm danh mục trong thực đơn quán.
- **`TC-MAN-WEB-22`**: Xoá món ăn khỏi thực đơn quán.

### Nhóm 5: Quản lý Tài khoản Khách hàng (Accounts Management)
- **`TC-MAN-WEB-23`**: Xem danh sách tài khoản khách hàng đã đăng ký (ẩn mật khẩu băm bảo mật).
- **`TC-MAN-WEB-24`**: Tìm kiếm tài khoản người dùng theo Email hoặc Họ tên.

---

## 🛠️ 4. DANH SÁCH 8 TEST CASES KIỂM THỬ THỦ CÔNG API SWAGGER (`http://localhost:8001/docs`)

- **`TC-MAN-API-01`**: Tải trang tài liệu OpenAPI Swagger UI.
- **`TC-MAN-API-02`**: API Đăng nhập Quản trị viên cấp Session ID (`POST /api/v1/auth/admin/login`).
- **`TC-MAN-API-03`**: API Đăng nhập Thực khách cấp Session ID (`POST /api/v1/auth/user/login`).
- **`TC-MAN-API-04`**: API Định vị toạ độ IP Internet không fallback HVNN (`GET /api/v1/map/ip-location`).
- **`TC-MAN-API-05`**: API Tra cứu toạ độ từ địa chỉ chuỗi (`GET /api/v1/map/search`).
- **`TC-MAN-API-06`**: API Truy vấn không gian PostGIS Radius `ST_DWithin` (`GET /api/v1/restaurants/nearby`).
- **`TC-MAN-API-07`**: API Tính khoảng cách trực tiếp từ người dùng đến quán `ST_Distance` (`GET /api/v1/restaurants/{id}/distance`).
- **`TC-MAN-API-08`**: API Thời tiết thực tế và Danh mục gợi ý (`GET /api/v1/weather/current`).

---

## 📝 5. MẪU BIỂU GHI NHẬN LỖI (BUG LOG TEMPLATE)

Khi tester phát hiện defect, ghi nhận vào **Sheet 8 (`Báo Cáo Lỗi (Bug Log)`)** trong file Excel theo mẫu:
- **Mã Bug:** `BUG-xxx`
- **Mã Test Case liên quan:** Ví dụ `TC-MAN-MOB-12`
- **Phân hệ:** Mobile App / Web Admin / Backend API
- **Tiêu đề lỗi:** Tóm tắt ngắn gọn lỗi
- **Mức độ (Severity):** Blocker / Critical / Major / Minor
- **Các bước tái hiện (Steps):** 1... 2... 3...
- **Kết quả thực tế (Actual):** Hiện tượng xảy ra
- **Kết quả mong đợi (Expected):** Hành vi chuẩn
- **Trạng thái:** Open / In Progress / Fixed / Closed
- **Người báo & Ngày:** Tên Tester - DD/MM/YYYY
