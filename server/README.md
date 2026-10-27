# FastAPI Backend Platform (PTC1)

Hệ thống backend chuẩn hoá sử dụng **FastAPI**, **SQLAlchemy 2.0 ORM** (kết nối **PostgreSQL 14** qua driver `psycopg` kèm tiện ích không gian **PostGIS**), **Pydantic v2**, và **Pytest**.

---

## 🚀 Tính năng nổi bật
- **FastAPI hiện đại**: Sử dụng `lifespan` context manager, khởi tạo cơ sở dữ liệu và seed dữ liệu ban đầu tinh gọn qua `server/app/db/init_db.py`.
- **Tích hợp Swagger UI & ReDoc tương tác (Cổng mặc định: 8001)**:
  - Swagger UI: [http://localhost:8001/docs](http://localhost:8001/docs)
  - ReDoc: [http://localhost:8001/redoc](http://localhost:8001/redoc)
- **Cơ sở dữ liệu PostgreSQL & PostGIS**:
  - Quản lý dữ liệu quan hệ và không gian địa lý: tính khoảng cách thực tế, lọc quán ăn theo bán kính (ST_DWithin), tìm đường đi bộ OSRM.
  - Phân chia vai trò rõ ràng: `users` (khách hàng kèm hồ sơ thể chất & sở thích ẩm thực cá nhân hóa) và `admins` (quản trị viên hệ thống).
  - Tự động tạo bảng, vá schema và seed tài khoản Admin mặc định (`admin@example.com` / `admin123`) khi khởi động.
- **Cấu hình tập trung**: Quản lý bằng `pydantic-settings`, hỗ trợ nạp tự động từ file `.env`.
- **Kiểm thử độc lập trên PostgreSQL (Testing)**:
  - Bộ test sử dụng `pytest` kết nối database `ptc1_test_db` PostgreSQL thật.
  - Sử dụng cơ chế **Savepoint Rollback** (`join_transaction_mode="create_savepoint"`) giúp test chạy siêu tốc (~8s cho 104 test cases) và hoàn toàn không làm bẩn dữ liệu thật trong `ptc1_db`.

---

## 📁 Cấu trúc thư mục

```
server/
├── app/
│   ├── main.py                  # Entrypoint: cấu hình FastAPI, CORS, Swagger tags, lifespan
│   ├── core/
│   │   ├── config.py            # Quản lý cài đặt môi trường (Settings, PostgreSQL URL)
│   │   └── security.py          # Băm và xác thực mật khẩu (PBKDF2-HMAC-SHA256)
│   ├── db/
│   │   ├── base.py              # DeclarativeBase SQLAlchemy
│   │   ├── session.py           # Engine thuần PostgreSQL, SessionLocal, get_db dependency
│   │   └── init_db.py           # DDL schema patches, Base.metadata.create_all & data seeders
│   ├── utils/                   # Tiện ích dùng chung (geo.py, cache.py, network.py)
│   ├── models/                  # Models SQLAlchemy 2.0 (User, Admin, Restaurant, Dish, Category...)
│   ├── schemas/                 # Schemas Pydantic v2 (Request validation & Response serialization)
│   ├── services/                # Nghiệp vụ backend (Admin, User, Map, Restaurant, Dish, Weather, Recommendation)
│   └── api/
│       └── v1/
│           ├── router.py        # Router tổng hợp v1
│           └── endpoints/       # Các API endpoints theo module
├── tests/                       # 104 Unit & Integration tests trên PostgreSQL test database
├── requirements.txt             # Danh sách dependencies
└── README.md                    # Tài liệu hướng dẫn
```

---

## 🛠️ Hướng dẫn cài đặt & chạy

### 1. Khởi tạo môi trường ảo Python
```bash
# Tạo môi trường ảo
python -m venv .venv

# Kích hoạt môi trường (Windows PowerShell)
.\.venv\Scripts\Activate.ps1
```

### 2. Cài đặt thư viện
```bash
pip install -r server/requirements.txt
```

### 3. Cấu hình file .env
Tạo file `.env` từ `.env.example`:
```env
DATABASE_URL="postgresql+psycopg://postgres:2005@localhost:5432/ptc1_db"
TEST_DATABASE_URL="postgresql+psycopg://postgres:2005@localhost:5432/ptc1_test_db"
```

### 4. Chạy Server ở chế độ Development
Có thể chạy trực tiếp bằng file `CHAY_SERVER.bat` hoặc lệnh:
```bash
uvicorn server.app.main:app --reload --host 0.0.0.0 --port 8001
```
- Swagger UI tại: [http://localhost:8001/docs](http://localhost:8001/docs)
- Tài khoản Admin mặc định có sẵn: `admin@example.com` / `admin123`.

### 5. Chạy kiểm thử (Pytest)
```bash
pytest server/tests -v
```
Toàn bộ 104 test cases sẽ được thực thi trực tiếp trên database `ptc1_test_db` của PostgreSQL với transaction rollback tự động.
