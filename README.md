# 🍽️ PTC1 — Hệ Thống Gợi Ý Ẩm Thực Thông Minh Theo Thời Tiết & Vị Trí Địa Lý

> **PTC1 (Smart Weather-Aware & Location-Based Food Recommendation System)** là nền tảng gợi ý và tìm kiếm ẩm thực thông minh, kết hợp thời tiết thực tế theo mùa, công nghệ truy vấn không gian PostGIS và hồ sơ thể trạng dinh dưỡng (BMI, mục tiêu vóc dáng, khẩu vị, dị ứng) của thực khách.

---

## 📌 Mục Lục
- [Tổng Quan Kiến Trúc](#-tổng-quan-kiến-trúc)
- [Công Nghệ Sử Dụng (Tech Stack)](#-công-nghệ-sử-dụng-tech-stack)
- [Cấu Trúc Thư Mục](#-cấu-trúc-thư-mục)
- [Cài Đặt Môi Trường](#-cài-đặt-môi-trường)
  - [Cách 1: Cài đặt Tự Động 1-Click (Khuyến nghị trên Windows)](#cách-1-cài-đặt-tự-động-1-click-khuyến-nghị-cho-windows)
  - [Cách 2: Cài đặt Thủ Công (Manual Setup)](#cách-2-cài-đặt-thủ-công-manual-setup)
- [Khởi Chạy Hệ Thống](#-khởi-chạy-hệ-thống)
  - [1-Click Launcher](#1-click-launcher-chạy-toàn-bộ-hệ-thống)
  - [Khởi chạy từng thành phần thủ công](#khởi-chạy-từng-thành-phần-thủ-công)
- [Tài Khoản Mặc Định](#-tài-khoản-mặc-định)
- [Các Tính Năng Nổi Bật](#-các-tính-năng-nổi-bật)
- [Kiểm Thử (Testing)](#-kiểm-thử-testing)
- [Tài Liệu Kỹ Thuật Bổ Sung](#-tài-liệu-kỹ-thuật-bổ-sung)

---

## 🏛️ Tổng Quan Kiến Trúc

Hệ sinh thái **PTC1** vận hành theo mô hình Client-Server hiện đại, bao gồm:
1. **Backend API (`server/`)**: Cung cấp RESTful API v1, xử lý logic gợi ý ẩm thực theo thời tiết, thuật toán khoảng cách PostGIS, xác thực phiên bảo mật và quản lý dữ liệu.
2. **Web Admin Dashboard (`web/`)**: Giao diện quản trị phong cách SaaS hiện đại dành cho Admin quản lý mạng lưới quán ăn, cấp phép dịch vụ, thực đơn món ăn và tài khoản người dùng.
3. **Mobile Client (`mobile/`)**: Ứng dụng di động đa nền tảng (Flutter) dành cho thực khách trải nghiệm bản đồ tương tác, banner thời tiết, khảo sát thể chất & gợi ý món ăn thông minh.

---

## 💻 Công Nghệ Sử Dụng (Tech Stack)

| Thành phần | Công nghệ lõi | Chi tiết |
|---|---|---|
| **Backend API** | Python 3.9+, FastAPI, SQLModel / SQLAlchemy 2.0 | Uvicorn ASGI, Pydantic v2, GeoAlchemy2, Psycopg 3 |
| **Cơ sở dữ liệu** | PostgreSQL 14 + PostGIS 3.6+ Spatial Extension | Lưu trữ tọa độ địa lý WGS84 (`ST_Distance`, `Geography Point`), băm mật khẩu PBKDF2-SHA256 |
| **Web Admin** | Vue 3 (Composition API, `<script setup>`), Vite, TypeScript | TailwindCSS, Lucide Icons, Vue-TSC |
| **Mobile App** | Flutter 3.x (Dart 3.x), Material 3 | `flutter_map`, `latlong2`, `geolocator`, OpenStreetMap Nominatim |
| **Dịch vụ tích hợp** | OpenWeatherMap API & OpenStreetMap | Gợi ý món ăn theo thời tiết trực tiếp, định vị không gian và Geocoding |

---

## 📁 Cấu Trúc Thư Mục

```text
ptc1/
├── server/                 # Mã nguồn Backend FastAPI
│   ├── app/
│   │   ├── api/v1/         # Các Router API v1 (auth, restaurants, dishes, weather,...)
│   │   ├── core/           # Cấu hình hệ thống, bảo mật (security, config)
│   │   ├── db/             # Kết nối Database, Session, script Auto-Seed & Migration
│   │   ├── models/         # Thực thể CSDL SQLModel (Restaurant, Dish, User, Season,...)
│   │   ├── schemas/        # Lớp kiểm thực dữ liệu Pydantic
│   │   └── services/       # Nghiệp vụ lõi (SeasonService, Recommendation, Weather,...)
│   ├── tests/              # Bộ kiểm thử Pytest tự động
│   └── requirements.txt    # Danh sách thư viện Python
├── web/                    # Ứng dụng Web Admin (Vue 3 + Vite)
│   ├── src/
│   │   ├── components/     # AdminDashboard.vue, AdminLogin.vue, Toast.vue,...
│   │   └── services/       # API client giao tiếp với Backend
│   └── package.json
├── mobile/                 # Ứng dụng Di Động Thực Khách (Flutter)
│   ├── lib/
│   │   ├── screens/        # ExploreScreen, MapScreen, FavouritesScreen, AccountScreen,...
│   │   ├── models/         # Model dữ liệu Dart
│   │   └── services/       # Tầng gọi API Backend & định vị IP
│   ├── test/               # Bộ kiểm thử Flutter Widget & Unit tests
│   └── pubspec.yaml
├── docs/                   # Toàn bộ tài liệu phân tích thiết kế hệ thống
│   ├── database.md         # Thiết kế CSDL & Data Dictionary chi tiết
│   ├── erd-diagram.svg/png # Sơ đồ thực thể liên kết (ERD)
│   ├── class-diagram.md    # Sơ đồ lớp chi tiết
│   ├── features.md         # Danh mục toàn bộ tính năng hoàn chỉnh
│   └── use-cases.md        # Đặc tả Use Cases & Sơ đồ tương tác
├── CAI_DAT.bat             # File cài đặt tự động 1-click cho Windows
├── CHAY_TAT_CA.bat         # File khởi chạy đồng thời toàn bộ hệ thống
├── setup.ps1               # Script PowerShell thiết lập môi trường hoàn chỉnh
└── README.md               # Tài liệu hướng dẫn dự án
```

---

## ⚙️ Cài Đặt Môi Trường

### Cách 1: Cài đặt Tự Động 1-Click (Khuyến nghị cho Windows)

Dự án cung cấp script tự động thiết lập toàn bộ môi trường từ A đến Z (tự tải Python, PostgreSQL, PostGIS, tạo Database, nạp thư viện và chạy kiểm thử):

1. Nhấp đúp chuột vào file **`CAI_DAT.bat`** (hoặc mở PowerShell với quyền Administrator và chạy):
   ```powershell
   Set-ExecutionPolicy Bypass -Scope Process
   .\setup.ps1
   ```
2. Script sẽ tự động:
   - Cài đặt / nhận diện Python 3.9+ và PostgreSQL 14 (mật khẩu mặc định: `2005`).
   - Cài đặt tiện ích mở rộng PostGIS spatial.
   - Khởi tạo 2 database: `ptc1_db` (chính) và `ptc1_test_db` (kiểm thử).
   - Tự động sinh file cấu hình `.env`.
   - Tạo môi trường ảo `.venv` và cài đặt đầy đủ dependencies.
   - Chạy Pytest để xác nhận backend hoạt động 100%.

---

### Cách 2: Cài đặt Thủ Công (Manual Setup)

#### 1. Cấu hình CSDL PostgreSQL & PostGIS
- Đảm bảo PostgreSQL đang chạy trên cổng `5432`.
- Tạo cơ sở dữ liệu và kích hoạt extension PostGIS:
  ```sql
  CREATE DATABASE ptc1_db;
  CREATE DATABASE ptc1_test_db;
  \c ptc1_db;
  CREATE EXTENSION IF NOT EXISTS postgis;
  \c ptc1_test_db;
  CREATE EXTENSION IF NOT EXISTS postgis;
  ```

#### 2. Cài đặt Backend FastAPI
```bash
# Tạo và kích hoạt môi trường ảo Python
python -m venv .venv
# Trên Windows:
.venv\Scripts\activate
# Trên Linux/macOS:
source .venv/bin/activate

# Cài đặt thư viện
pip install -r server/requirements.txt

# Tạo file cấu hình môi trường từ mẫu
cp .env.example .env
```

#### 3. Cài đặt Web Admin
```bash
cd web
npm install
cd ..
```

#### 4. Cài đặt Mobile Client
```bash
cd mobile
flutter pub get
cd ..
```

---

## 🚀 Khởi Chạy Hệ Thống

### 1-Click Launcher (Chạy toàn bộ hệ thống)

Nhấp đúp vào file **`CHAY_TAT_CA.bat`** tại thư mục gốc. Script sẽ mở 3 cửa sổ console độc lập và khởi chạy đồng thời:
1. **Backend FastAPI:** `http://localhost:8001`
2. **Web Admin Dashboard:** `http://localhost:5174`
3. **Mobile Client (Bản Web Chrome preview):** `http://localhost:3000`

> 💡 **Cơ chế Tự Động Nạp Dữ Liệu (Auto-Seed):** Ngay khi Backend khởi động lần đầu, hệ thống tự động khởi tạo bảng, migration schema và nạp sẵn toàn bộ dữ liệu mẫu (204 quán ăn Gia Lâm, 775 món ăn, 4 mùa MM-DD, dữ liệu thời tiết và các tài khoản mặc định).

---

### Khởi chạy từng thành phần thủ công

#### 1. Khởi chạy Backend FastAPI
```bash
# Kích hoạt virtualenv và chạy uvicorn
.venv\Scripts\python.exe -m uvicorn server.app.main:app --reload --host 0.0.0.0 --port 8001
```
- Endpoint gốc (Health Check): `http://localhost:8001/`
- API Base URL: `http://localhost:8001/api/v1`

#### 2. Khởi chạy Web Admin
```bash
cd web
npm run dev
```
- Truy cập trình duyệt: `http://localhost:5174`

#### 3. Khởi chạy Mobile App
```bash
cd mobile
# Chạy trên trình duyệt Web:
flutter run -d chrome --web-port=3000

# Hoặc chạy trên thiết bị giả lập Android / iOS:
flutter run
```

---

## 🔑 Tài Khoản Mặc Định

Sau khi nạp dữ liệu khởi tạo, bạn có thể đăng nhập bằng các tài khoản chuẩn sau:

| Vai trò | Email đăng nhập | Mật khẩu | Phạm vi sử dụng |
|---|---|---|---|
| **Quản trị viên (Admin)** | `admin@example.com` | `admin123` | Đăng nhập hệ thống Web Admin (`http://localhost:5174`) |
| **Thực khách (User)** | `user@example.com` | `123456` | Đăng nhập ứng dụng Mobile / Web Mobile |
| **Khách vãng lai (Guest)** | *(Không cần đăng nhập)* | *(Trống)* | Tự động trải nghiệm khám phá quán tài trợ (`is_sponsor = true`) |

---

## ✨ Các Tính Năng Nổi Bật

### 1. 📱 Mobile App (Dành cho Thực khách)
- **Gợi ý ẩm thực theo thời tiết (Live Weather):** Hiển thị nhiệt độ, trạng thái thời tiết thực tế và đề xuất món ăn phù hợp theo mùa (Lẩu/Nướng khi trời lạnh, Đồ mát/Salad khi trời nắng).
- **Bản đồ tương tác OpenStreetMap (PostGIS):** Định vị vị trí thực khách qua IP mạng an toàn (không bắt buộc cấp quyền GPS phần cứng thiết bị), hiển thị bán kính khoảng cách chính xác đến từng quán ăn.
- **Khảo sát dinh dưỡng & Sức khỏe (Onboarding Survey):** Tính toán chỉ số thể trạng BMI tự động, ghi nhận mục tiêu vóc dáng (*Giảm cân, Tăng cơ, Ăn lành mạnh*), khẩu vị cay, khung ngân sách và cảnh báo dị ứng thực phẩm.
- **Thực đơn chi tiết & Đánh dấu yêu thích:** Xem lượng Calo (kcal), độ cay, nguyên liệu, bữa ăn và lưu các món ăn yêu thích tức thì.
- **Chế độ Khách vãng lai (Guest Mode):** Cho phép xem nhanh thông tin mà không cần đăng ký tài khoản, ưu tiên hiển thị các quán đối tác tài trợ.

### 2. 💻 Web Admin (Dành cho Quản trị viên)
- **Bảng điều khiển KPI (Dashboard Overview):** Thống kê số lượng quán ăn, tình trạng mở/đóng cửa, tổng số món ăn, danh mục và tổng thực khách.
- **Quản lý Quán ăn (Restaurants):** Thêm/sửa/xóa quán ăn, chuyển đổi trạng thái mở cửa, cấu hình giấy phép dịch vụ (ATTP, PCCC), gắn cờ tài trợ (`is_sponsor`) và tích hợp bản đồ tự động lấy tọa độ qua Geocoding.
- **Quản lý Thực đơn Master-Detail (Dishes & Categories):** Quản lý cây danh mục toàn cục, thêm món theo từng quán với giá tiền, calo, độ cay, thành phần nguyên liệu và gắn nhãn dị ứng.
- **Quản trị Tài khoản (Accounts):** Quản lý danh sách thực khách đã đăng ký với mô hình phân quyền bảo mật tinh gọn.

---

## 🧪 Kiểm Thử (Testing)

### 1. Kiểm thử Backend (Pytest)
```bash
# Chạy toàn bộ test suites của Backend
.venv\Scripts\pytest

# Chạy có hiển thị chi tiết:
.venv\Scripts\pytest -v
```

### 2. Kiểm thử Mobile (Flutter Test)
```bash
cd mobile
flutter test test/guest_sponsor_filter_test.dart
flutter test
cd ..
```

---

## 📚 Tài Liệu Kỹ Thuật Bổ Sung

Các tài liệu thiết kế chi tiết được lưu trữ đầy đủ trong thư mục [`docs/`](./docs/):
- 📊 [docs/database.md](file:///d:/projects/ptc1/docs/database.md): Đặc tả cấu trúc cơ sở dữ liệu và Data Dictionary.
- 🖼️ [docs/erd-diagram.svg](file:///d:/projects/ptc1/docs/erd-diagram.svg): Sơ đồ thực thể liên kết (ERD) trực quan.
- 📐 [docs/class-diagram.md](file:///d:/projects/ptc1/docs/class-diagram.md): Thiết kế hướng đối tượng và sơ đồ lớp.
- 📋 [docs/features.md](file:///d:/projects/ptc1/docs/features.md): Danh sách toàn bộ tính năng hệ thống.
- 🔄 [docs/sequence-diagrams.md](file:///d:/projects/ptc1/docs/sequence-diagrams.md): Các luồng tuần tự nghiệp vụ.
- 👥 [docs/use-cases.md](file:///d:/projects/ptc1/docs/use-cases.md): Đặc tả Use Cases chi tiết.

---

*Hệ thống phát triển bởi Nhóm Dự án PTC1.*
