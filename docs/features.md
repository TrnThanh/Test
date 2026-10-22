# Danh sách Tính năng Hệ thống (Feature List) - PTC1

Tài liệu này tổng hợp chi tiết toàn bộ các tính năng đã được hiện thực hóa và kiểm thử trong mã nguồn của hệ sinh thái **PTC1**, phân tách rõ ràng theo hai nền tảng người dùng: **Mobile App** (dành cho Thực khách / Khách hàng) và **Web Admin** (dành cho Quản trị viên).

---

## 📱 1. Mobile App (Dành cho Người dùng / Thực khách)

Được xây dựng bằng **Flutter SDK (Material 3)** tại thư mục [`mobile/lib/`](../mobile/lib/), hỗ trợ đa nền tảng (Android, iOS, Web Responsive):

### 1.1. Xác thực & Phiên làm việc (Authentication & Session)
- **Đăng nhập & Đăng ký tài khoản (`User`):** Đăng ký tài khoản người dùng với email và mật khẩu (băm mật khẩu PBKDF2 an toàn).
- **Chế độ Khách vãng lai (Guest Mode):** Cho phép người dùng trải nghiệm tra cứu quán ăn, duyệt menu và xem bản đồ ngay lập tức mà không bắt buộc phải đăng nhập.
- **Quản lý phiên làm việc tự động:** Lưu trữ `access_token` và thông tin định danh vào bộ nhớ cục bộ, tự động phục hồi phiên khi mở lại ứng dụng.
- **Đăng xuất an toàn:** Thu hồi phiên và đưa người dùng về trạng thái khách vãng lai.

### 1.2. Khảo sát Onboarding & Mở rộng Hồ sơ Thực khách (Health & Dietary Profile)
- **Hộp thoại Khảo sát tự động (Onboarding Survey Dialog):** Tự động hiển thị khi người dùng đăng nhập lần đầu hoặc mở lại từ tab Tài khoản:
  - **Chỉ số thể chất cơ bản:** Nhập Chiều cao (`height_cm`, 50–260 cm), Cân nặng (`weight_kg`, 10–500 kg), Giới tính (`gender`), Năm sinh (`birth_year`).
  - **Tính toán BMI tự động:** Tự động tính chỉ số khối cơ thể và phân loại thể trạng trực quan (*Gầy*, *Bình thường*, *Thừa cân*).
  - **Mục tiêu dinh dưỡng (`target_goal`):** Tùy chọn *Duy trì vóc dáng*, *Giảm cân*, *Tăng cơ*, *Ăn lành mạnh (Healthy)*.
  - **Khẩu vị cay (`spicy_tolerance`):** Tùy chọn *Không cay*, *Cay nhẹ*, *Cay vừa*, *Ăn cay nhiều*.
  - **Khung ngân sách (`budget_range`):** Tùy chọn *Tiết kiệm*, *Tầm trung*, *Cao cấp*.
  - **Chế độ ăn đặc biệt (`dietary_preferences`):** Gắn nhãn các chế độ ăn (`vegetarian`, `vegan`, `halal`, `keto`, `low_carb`...).
  - **Cảnh báo dị ứng thực phẩm (`allergies`):** Lưu danh sách các chất gây dị ứng (`peanut`, `seafood`, `dairy`, `egg`, `gluten`...).
  - **Danh mục yêu thích (`favorite_category_ids`):** Chọn nhanh các nhóm món ăn ưa chuộng.

### 1.3. Khám phá Ẩm thực & Gợi ý theo Thời tiết (ExploreScreen - Tab 1)
- **Banner Thời tiết thực tế (Live Weather Recommendation):**
  - Hiển thị nhiệt độ hiện tại, trạng thái khí hậu (Nắng, Mưa, Mát mẻ, Lạnh...) qua OpenWeatherMap API hoặc fallback thông minh.
  - Tự động gợi ý các danh mục món ăn tương thích với thời tiết (vd: Ngày mưa/lạnh gợi ý Lẩu, Nướng, Món nước nóng; Ngày nắng gợi ý Đồ uống mát, Chè, Salad).
- **Tìm kiếm đa năng:** Thanh tìm kiếm thời gian thực theo tên quán ăn, địa chỉ hoặc từ khóa món ăn.
- **Danh sách Quán ăn nổi bật (Restaurant Cards):**
  - Hiển thị tên quán, địa chỉ, hotline, giờ mở/đóng cửa (`HH:MM`).
  - Huy hiệu **Nhà tài trợ (`is_sponsor`)** nổi bật dành cho quán được ưu tiên quảng bá.
  - Tính toán và hiển thị khoảng cách thực tế (km/mét) từ vị trí người dùng đến quán.
- **Bộ lọc Danh mục món ăn (Category Filter):**
  - Thanh cuộn ngang các nhóm danh mục toàn cục (Cơm, Bún/Phở, Đồ uống, Khai vị...).
  - Tích hợp tùy chọn ẩn/hiện danh mục theo sở thích cá nhân (`OptionUser`).
- **Xem Chi tiết Thực đơn Quán ăn (Bottom Sheet Menu):**
  - Danh sách món ăn chi tiết: Tên món, đơn giá (VNĐ), mô tả hương vị, ảnh minh họa.
  - Nhãn độ cay 🌶️ (`spicy_level`: Cay nhẹ, Cay vừa, Rất cay).
  - Nhãn loại bữa ăn (`meal_types`: Sáng, Trưa, Tối, Ăn vặt, Cả ngày).
  - Danh sách thành phần nguyên liệu (`ingredients`) và cảnh báo dị ứng (`allergens`).
  - Huy hiệu trạng thái còn món / tạm hết món.

### 1.4. Bản đồ Tương tác & Định vị Không gian (MapScreen - Tab 2)
- **Bản đồ số OpenStreetMap (flutter_map):** Hỗ trợ zoom in/out, kéo thả và xoay bản đồ mượt mà.
- **Định vị trực tuyến qua IP (Online IP Geolocation):**
  - Tự động phát hiện vị trí người dùng qua IP mạng (proxy an toàn qua Backend, có fallback mặc định tại Học viện Nông nghiệp Việt Nam).
  - Hoàn toàn **không yêu cầu cấp quyền phần cứng GPS** trên thiết bị, hoạt động mượt mà trên cả trình duyệt Web và Mobile.
- **Hệ thống Marker trực quan:**
  - Marker chấm xanh: Vị trí của bạn (theo mạng Internet).
  - Marker ghim đỏ: Vị trí các quán ăn ẩm thực xung quanh.
- **Truy vấn không gian PostGIS:** Tính toán khoảng cách cầu theo tọa độ WGS84 (`ST_Distance` / PostGIS Geography Point).
- **Tìm kiếm địa điểm (Geocoding):** Gõ địa chỉ bất kỳ để bay tâm bản đồ đến vị trí đó qua OpenStreetMap Nominatim.
- **Nút FAB "Vị trí của tôi" (My Location):** Đưa tâm bản đồ quay trở lại tọa độ người dùng ngay lập tức.
- **Bottom Sheet tóm tắt quán ăn:** Bấm vào Marker bất kỳ trên bản đồ để xem nhanh thông tin quán, khoảng cách và nút xem thực đơn.

### 1.5. Món ăn Yêu thích (FavouritesScreen - Tab 3)
- **Danh sách món ăn đã lưu:** Quản lý toàn bộ các món ăn được thực khách thả tim yêu thích.
- **Thao tác yêu thích 1 chạm:** Thêm/bỏ yêu thích tức thì, hỗ trợ xử lý Idempotent chống trùng lặp dữ liệu.
- **Xem thông tin liên kết:** Hiển thị trực tiếp tên quán ăn đang bán món đó và giá bán hiện hành.

### 1.6. Màn hình Tài khoản & Chỉ số Cá nhân (AccountScreen - Tab 4)
- Xem thông tin tài khoản (Email, họ tên, ngày tham gia).
- **Thẻ Thống kê Thể chất & BMI:** Hiển thị trực quan Chiều cao, Cân nặng, chỉ số BMI, Phân loại thể trạng, Mục tiêu thể hình, Khẩu vị cay, Khung ngân sách, Dị ứng.
- **Nút "Cập nhật khảo sát ẩm thực":** Cho phép người dùng làm lại khảo sát bất cứ lúc nào để thay đổi khẩu vị hoặc cập nhật cân nặng mới.

---

## 💻 2. Web Admin (Dành cho Quản trị viên hệ thống)

Được xây dựng bằng **Vue 3 (Composition API, `<script setup>`) + Vite + TypeScript** tại thư mục [`web/src/components/AdminDashboard.vue`](../web/src/components/AdminDashboard.vue), thiết kế theo phong cách **Modern SaaS Dashboard**:

### 2.1. Xác thực Quản trị viên (Admin Authentication)
- Màn hình đăng nhập bảo mật dành riêng cho Quản trị viên ([`AdminLogin.vue`](../web/src/components/AdminLogin.vue)).
- Phân tách vai trò độc lập (Role Separation), lưu trữ phiên làm việc `access_token` và bảo vệ toàn bộ API quản trị.

### 2.2. Tab 1: Tổng quan Nền tảng (Dashboard Overview)
- **Thẻ Chỉ số Hiệu suất Chính (KPI Stat Cards):**
  - Tổng số quán ăn trên toàn hệ thống.
  - Số lượng quán đang mở cửa hoạt động / số quán tạm đóng.
  - Tổng số món ăn trên toàn hệ thống.
  - Tổng số nhóm danh mục món ăn.
  - Tổng số tài khoản thực khách (`users`) đã đăng ký.
- **Bảng Quán ăn Mới nhất:** Theo dõi nhanh các quán ăn mới tạo và tình trạng kích hoạt.

### 2.3. Tab 2: Quản lý Quán ăn (Restaurants Management)
- **Bảng dữ liệu Quán ăn (Data Table):** Hiển thị toàn bộ danh sách quán ăn kèm phân trang, tìm kiếm tức thì theo tên quán, địa chỉ hoặc số điện thoại hotline.
- **Tạo mới Quán ăn (Create Restaurant):**
  - Nhập tên quán, địa chỉ cụ thể.
  - **Tích hợp Bản đồ Geocoding:** Nút *"Tìm tọa độ từ địa chỉ"* tự động điền Kinh độ (`longitude`) và Vĩ độ (`latitude`) qua dịch vụ bản đồ OpenStreetMap.
  - Nhập số điện thoại hotline, mô tả giới thiệu.
  - Cấu hình giờ mở cửa (`open_time`) và giờ đóng cửa (`close_time`) chuẩn định dạng `HH:MM`.
  - Cấu hình cờ **Nhà tài trợ (`is_sponsor`)** để ưu tiên quán ăn lên đầu kết quả tìm kiếm.
- **Chỉnh sửa Quán ăn (Edit Restaurant):** Cập nhật bất kỳ trường thông tin nào của quán ăn.
- **Chuyển đổi trạng thái nhanh (Toggle Status):** Bật/Tắt trạng thái hoạt động của quán ăn chỉ với 1 click chuột.
- **Xóa Quán ăn (Delete Restaurant):** Hộp thoại xác nhận an toàn trước khi xóa (tự động cascade xóa các món ăn liên quan).
- **Chuyển nhanh sang Quản lý thực đơn:** Nút tắt chuyển thẳng sang tab Thực đơn của quán đang chọn.

### 2.4. Tab 3: Quản lý Thực đơn & Danh mục (Menu & Dish Management - Bố cục Master-Detail)
- **Bố cục Master-Detail trực quan:**
  - **Cột trái (Master):** Danh sách chọn quán ăn kèm ô tìm kiếm quán nhanh.
  - **Cột phải (Detail):** Không gian quản lý danh mục và thực đơn của quán được chọn.
- **Quản lý Danh mục (Categories):**
  - Xem danh sách nhóm danh mục và đếm số lượng món ăn trong từng nhóm.
  - Tạo danh mục toàn cục mới, chỉnh sửa tên, mô tả, thứ tự sắp xếp hiển thị (`display_order`).
  - Xóa danh mục an toàn (món ăn thuộc danh mục sẽ chuyển sang trạng thái "Chưa phân loại", không làm mất dữ liệu món).
- **Quản lý Món ăn (Dishes):**
  - **Hiển thị Card Grid hiện đại:** Ảnh minh họa món, tên món ăn, giá tiền định dạng chuẩn VNĐ, nhãn danh mục, tag bữa ăn, nhãn độ cay 🌶️ (`spicy_level`), mảng nguyên liệu.
  - **Lọc món ăn:** Lọc nhanh theo nhóm danh mục hoặc trạng thái còn món / hết món.
  - **Thêm món ăn mới:** Điền tên món, giá bán, chọn nhóm danh mục, nhập mô tả, URL ảnh, độ cay (0–3), bữa ăn phù hợp, danh sách nguyên liệu.
  - **Chỉnh sửa món ăn:** Cập nhật thông tin chi tiết của món.
  - **Cập nhật nhanh tình trạng còn món:** Bật/Tắt trạng thái Còn món (Available) hoặc Tạm hết món (Out of stock) chỉ với 1 click.
  - **Xóa món ăn:** Gỡ bỏ món ăn khỏi thực đơn quán.

### 2.5. Tab 4: Quản lý Tài khoản Khách hàng (Accounts Management)
- Xem danh sách toàn bộ tài khoản người dùng (`users`) đã đăng ký trong hệ sinh thái.
- Tìm kiếm tài khoản theo email hoặc họ tên.
- Hiển thị ngày tạo tài khoản, ID định danh và trạng thái kích hoạt tài khoản (`is_active`).
- Chuẩn hóa mô hình 2 vai trò tinh gọn (`User` và `Admin`), loại bỏ hoàn toàn các cấu trúc role thừa thãi.
