# Sơ đồ Tuần tự Hệ thống (Sequence Diagrams) - PTC1

Tài liệu này mô tả chi tiết các luồng xử lý tuần tự (Sequence Diagrams) giữa **Tác nhân (Actors)** và **Các thành phần phần mềm (Components)** trong hệ thống PTC1, bám sát **100% mã nguồn thực tế hiện có** tại `server/app/`.

---

## 1. Định nghĩa Tác nhân (Actors) & Thành phần tham gia (Participants)

### 1.1. Các Tác nhân (Actors)
- 👤 **Khách hàng (User):** Người dùng dịch vụ, thực hiện đăng ký, đăng nhập tài khoản, tra cứu quán ăn.
- 🌐 **Khách vãng lai (Guest):** Người dùng chưa đăng nhập, được phép duyệt tìm kiếm quán ăn và tra cứu vị trí địa lý.
- 🗺️ **Hệ thống bản đồ ngoài (OpenStreetMap Nominatim):** Dịch vụ bên thứ ba cung cấp dữ liệu bản đồ và tọa độ địa lý.

### 1.2. Các Thành phần Hệ thống (System Participants)
- 🚪 **FastAPI APIRouter:** Tầng Controller tiếp nhận HTTP Request, xác thực schema Pydantic và điều phối.
- ⚙️ **Service Layer (`UserService`, `RestaurantService`, `MapService`, `CategoryService`, `DishService`, `MealTypeService`, `WeatherService`):** Tầng xử lý logic nghiệp vụ.
- 🔐 **Security Utils (`server.app.core.security`):** Băm và xác thực mật khẩu bằng thuật toán chuẩn PBKDF2-HMAC-SHA256 (100.000 vòng lặp).
- 🗄️ **Database Layer (PostgreSQL 14 & PostGIS Engine):** Lưu trữ dữ liệu quan hệ, mảng Postgres (`ARRAY(Text)`), chỉ mục GIN, và thực thi các truy vấn không gian (`ST_DWithin`, `ST_Distance`).

---

## 2. Luồng 1: Xác thực Tài khoản (Đăng ký & Đăng nhập)

Áp dụng cho module: `server/app/api/v1/endpoints/auth_user.py` & `server/app/services/user_service.py`.

![Sơ đồ Tuần tự Xác thực Tài khoản](seq-auth.png)

<details>
<summary><b>Xem mã nguồn Mermaid</b></summary>

```mermaid
sequenceDiagram
    autonumber
    actor User as Khách hàng (User)
    participant API as FastAPI Router (auth_user.py)
    participant Svc as UserService (user_service.py)
    participant Sec as Security Utils (PBKDF2 SHA256)
    participant DB as PostgreSQL (users table)

    User->>API: POST /api/v1/auth/user/register {email, password, full_name}
    activate API
    API->>Svc: register(db, payload)
    activate Svc
    Svc->>DB: select(User).where(User.email == email)
    DB-->>Svc: None (chưa tồn tại)
    Svc->>Sec: hash_password(password)
    Sec-->>Svc: hashed_password (salt + 100k rounds)
    Svc->>DB: INSERT INTO users ... (db.add + db.commit)
    DB-->>Svc: id, email, created_at
    Svc-->>API: User instance
    deactivate Svc
    API-->>User: HTTP 201 Created (UserResponse)
    deactivate API

    Note over User, DB: Luồng Đăng nhập (Login)
    User->>API: POST /api/v1/auth/user/login {email, password}
    activate API
    API->>Svc: authenticate(db, email, password)
    activate Svc
    Svc->>DB: select(User).where(User.email == email)
    DB-->>Svc: User record
    Svc->>Sec: verify_password(password, hashed_password)
    Sec-->>Svc: True (khớp mật khẩu)
    Svc-->>API: User (is_active = True)
    deactivate Svc
    API-->>User: HTTP 200 OK (RoleLoginResponse role='user', session_id=uuid.uuid4().hex)
    deactivate API
```
</details>

### Diễn giải chi tiết:
1. **Đăng ký:**
   - Client gửi `email`, `password`, `full_name`.
   - `UserService` kiểm tra sự tồn tại của `email` trong bảng `users`. Nếu đã tồn tại -> Trả về `400 Bad Request`.
   - Nếu hợp lệ -> Gọi `security.hash_password` sinh chuỗi muối ngẫu nhiên và băm qua PBKDF2-HMAC-SHA256.
   - Thêm bản ghi vào DB, `commit`, và trả về `UserResponse` (HTTP 201).
2. **Đăng nhập:**
   - Client gửi `email` và `password`.
   - `UserService` tìm user trong DB -> Kiểm tra chuỗi băm bằng `verify_password`. Nếu sai -> Trả về `401 Unauthorized`.
   - Kiểm tra `is_active` -> Trả về `RoleLoginResponse` với thông tin User, `role: "user"` và mã phiên `session_id` (UUID4 hex ngẫu nhiên 32 ký tự).

---

## 3. Luồng 2: Quản trị viên Tạo mới Quán ăn & Tự động sinh tọa độ PostGIS

Áp dụng cho module: `server/app/api/v1/endpoints/restaurants.py` & `server/app/services/restaurant_service.py`.

![Sơ đồ Tuần tự Quản trị viên Tạo Quán ăn](seq-restaurant-create.png)

<details>
<summary><b>Xem mã nguồn Mermaid</b></summary>

```mermaid
sequenceDiagram
    autonumber
    actor Admin as Quản trị viên (Admin)
    participant API as Router (restaurants.py)
    participant Svc as RestaurantService (restaurant_service.py)
    participant DB as PostgreSQL + PostGIS (restaurants table)

    Admin->>API: POST /api/v1/restaurants {name, address, lat, lon, phone_number, open_time, close_time, is_sponsor}
    activate API
    API->>Svc: create_restaurant(db, payload)
    activate Svc
    Svc->>DB: INSERT INTO restaurants (name, address, latitude, longitude, ...)
    activate DB
    Note right of DB: PostGIS tự động tính toán cột computed:<br/>location = ST_SetSRID(ST_MakePoint(lon, lat), 4326)::geography
    DB-->>Svc: db.commit() + db.refresh() -> Restaurant (id, location)
    deactivate DB
    Svc-->>API: Restaurant entity
    deactivate Svc
    API-->>Admin: HTTP 201 Created (RestaurantResponse)
    deactivate API
```
</details>

### Diễn giải chi tiết:
1. Quản trị viên gửi thông tin quán kèm tọa độ WGS84 (`latitude`, `longitude`).
2. Router kiểm tra ràng buộc kiểu dữ liệu qua Pydantic schema `RestaurantCreate`.
3. `RestaurantService` khởi tạo bản ghi `Restaurant` trực tiếp.
4. Khi insert vào bảng `restaurants`, engine PostgreSQL + PostGIS tự động kích hoạt biểu thức tính toán lưu trữ:
   $$location = \text{ST\_SetSRID}(\text{ST\_MakePoint}(longitude, latitude), 4326)::\text{geography}$$
5. Quán ăn được tạo thành công, trả về HTTP 201 Created.

---

## 4. Luồng 3: Tìm kiếm Quán ăn Gần đây bằng GPS (Spatial Radius Search)

Áp dụng cho module: `server/app/api/v1/endpoints/restaurants.py` (Endpoint `GET /api/v1/restaurants/nearby`).

![Sơ đồ Tuần tự Tìm Quán Gần Đây](seq-spatial-search.png)

<details>
<summary><b>Xem mã nguồn Mermaid</b></summary>

```mermaid
sequenceDiagram
    autonumber
    actor Guest as Khách vãng lai / User
    participant API as Router (restaurants.py)
    participant Svc as RestaurantService (restaurant_service.py)
    participant DB as PostgreSQL (PostGIS Engine)

    Guest->>API: GET /api/v1/restaurants/nearby?lat=10.77&lon=106.69&radius_meters=3000
    activate API
    API->>Svc: find_nearby(db, lat=10.77, lon=106.69, radius=3000)
    activate Svc
    Svc->>DB: SELECT *, ST_Distance(location, user_point) FROM restaurants<br/>WHERE ST_DWithin(location, user_point, 3000)<br/>ORDER BY distance ASC
    activate DB
    Note right of DB: Sử dụng Spatial GiST Index trên cột location<br/>Độ phức tạp O(log N)
    DB-->>Svc: Danh sách quán trong bán kính + khoảng cách mét (Float)
    deactivate DB
    Svc-->>API: List[NearbyRestaurantResponse] (gồm distance_meters & distance_km)
    deactivate Svc
    API-->>Guest: HTTP 200 OK (Danh sách quán lân cận đã sắp xếp từ gần đến xa)
    deactivate API
```
</details>

### Diễn giải chi tiết:
1. Khách hàng hoặc khách vãng lai gửi tọa độ hiện tại (`latitude`, `longitude`) kèm bán kính tìm kiếm (mặc định 5000 mét, tối đa 50000 mét).
2. Service khởi tạo điểm vị trí người dùng dưới dạng `Geography POINT(SRID 4326)`.
3. Câu lệnh SQL sử dụng hàm không gian `ST_DWithin` kết hợp **Spatial GiST Index** trên cột `location` để quét nhanh các quán trong bán kính mà không cần quét toàn bộ bảng (table scan).
4. Hàm `ST_Distance` tính toán chính xác khoảng cách trắc địa đường cong mặt cầu (WGS84 ellipsoid).
5. Trả về danh sách quán đã sắp xếp theo khoảng cách tăng dần kèm cả số mét (`distance_meters`) và km (`distance_km`).

---

## 5. Luồng 4: Tra cứu Tọa độ Địa lý qua OpenStreetMap Nominatim

Áp dụng cho module: `server/app/api/v1/endpoints/map.py` & `server/app/services/map_service.py`.

![Sơ đồ Tuần tự Tra cứu Địa điểm Bản đồ](seq-map-geocoding.png)

<details>
<summary><b>Xem mã nguồn Mermaid</b></summary>

```mermaid
sequenceDiagram
    autonumber
    actor Client as Khách hàng / Chủ quán
    participant API as Map Router (map.py)
    participant Svc as MapService (map_service.py)
    participant OSM as OpenStreetMap Nominatim API

    Client->>API: GET /api/v1/map/search?q=Chợ Bến Thành&limit=5
    activate API
    API->>Svc: search_places(query="Chợ Bến Thành", limit=5)
    activate Svc
    Svc->>OSM: HTTP GET /search?q=Chợ Bến Thành&format=jsonv2&countrycodes=vn
    activate OSM
    OSM-->>Svc: Raw JSON list (place_id, display_name, lat, lon, type)
    deactivate OSM
    Svc->>Svc: Chuẩn hóa dữ liệu sang PlaceItem (display_name, lat, lon, type)
    Svc-->>API: MapSearchResponse(total=5, results=[...])
    deactivate Svc
    API-->>Client: HTTP 200 OK (Danh sách địa điểm & tọa độ GPS)
    deactivate API
```
</details>

### Diễn giải chi tiết:
1. Client nhập tên địa điểm hoặc đường phố cần tìm.
2. `MapService` thiết lập `User-Agent` hợp lệ theo quy định sử dụng của OpenStreetMap Nominatim.
3. Gửi truy vấn HTTP GET tới endpoint tìm kiếm của Nominatim với giới hạn quốc gia Việt Nam (`countrycodes=vn`).
4. Chuẩn hóa dữ liệu trả về thành cấu trúc DTO sạch gồm: `display_name`, `latitude`, `longitude`, `type`.
5. Trả về kết quả phục vụ hiển thị gợi ý tìm kiếm hoặc tự động điền tọa độ khi chủ quán tạo quán ăn mới.

---

## 6. Luồng 5: Quản trị viên Tạo Món Ăn Mới (Dishes) & Xác Thực Danh Mục, Bữa Ăn

Áp dụng cho module: `server/app/api/v1/endpoints/dishes.py` & `server/app/services/dish_service.py`.

![Sơ đồ Tuần tự Quản trị viên Tạo Món Ăn](seq-dish-create.png)

<details>
<summary><b>Xem mã nguồn Mermaid</b></summary>

```mermaid
sequenceDiagram
    autonumber
    actor Admin as Quản trị viên (Admin)
    participant API as Dish Router (dishes.py)
    participant Svc as DishService (dish_service.py)
    participant DB as PostgreSQL (dishes, restaurants, categories)

    Admin->>API: POST /api/v1/restaurants/{id}/dishes {name, price, category_id, spicy_level, dietary_tags, meal_types, allergens, ingredients}
    activate API
    API->>Svc: create_dish(db, restaurant_id, data)
    activate Svc
    
    Svc->>DB: db.get(Restaurant, restaurant_id)
    DB-->>Svc: Restaurant entity
    alt Quán không tồn tại
        Svc-->>API: HTTPException 404 (Không tìm thấy quán ăn)
        API-->>Admin: HTTP 404 Not Found
    end

    opt Có truyền category_id
        Svc->>DB: db.get(Category, category_id)
        DB-->>Svc: Category entity
        alt Category toàn cục không tồn tại
            Svc-->>API: HTTPException 404 (Không tìm thấy danh mục món ăn)
            API-->>Admin: HTTP 404 Not Found
        end
    end

    Note over Svc: Xác thực & Chuẩn hóa đa chiều:<br/>- spicy_level BETWEEN 0 AND 3<br/>- meal_types ⊆ {breakfast, lunch, dinner, snack, all_day}<br/>- Chuẩn hóa mảng dietary_tags, allergens, ingredients

    Svc->>DB: INSERT INTO dishes (restaurant_id, category_id, name, price, spicy_level, dietary_tags, meal_types, allergens, ingredients)
    activate DB
    DB-->>Svc: db.commit() + db.refresh() -> Dish (id, created_at)
    deactivate DB

    Svc->>Svc: to_dish_response(dish) (nạp category_name từ quan hệ category_rel)
    Svc-->>API: DishResponse
    deactivate Svc
    API-->>Admin: HTTP 201 Created (DishResponse)
    deactivate API
```
</details>

### Diễn giải chi tiết:
1. Quản trị viên gửi yêu cầu tạo món ăn kèm các thông số đa chiều: tên, giá tiền, ID danh mục toàn cục (`category_id`), độ cay (`spicy_level`: 0..3), mảng chế độ ăn (`dietary_tags`), mảng loại bữa ăn (`meal_types`), mảng chất gây dị ứng (`allergens`), và mảng nguyên liệu (`ingredients`).
2. Tầng Controller Pydantic xác thực dữ liệu: `price >= 0`, `spicy_level` từ 0 đến 3.
3. `DishService` thực hiện kiểm tra:
   - Kiểm tra quán ăn tồn tại trong DB.
   - Nếu có `category_id`: kiểm tra danh mục toàn cục tồn tại trong DB (không còn ràng buộc theo quán).
   - Xác thực mảng `meal_types` thuộc tập hợp chuẩn: `breakfast`, `lunch`, `dinner`, `snack`, `all_day`.
4. Thực thi lệnh INSERT vào bảng `dishes`.
5. Trả về `DishResponse` với HTTP 201 Created.

---

## 7. Luồng 6: Khách Hàng Tìm Kiếm & Lọc Thực Đơn Đa Tiêu Chí

Áp dụng cho module: `server/app/api/v1/endpoints/dishes.py` (Endpoint `GET /api/v1/restaurants/{id}/dishes`).

![Sơ đồ Tuần tự Lọc Món Ăn Đa Tiêu Chí](seq-dish-filter.png)

<details>
<summary><b>Xem mã nguồn Mermaid</b></summary>

```mermaid
sequenceDiagram
    autonumber
    actor Client as Khách hàng / Guest
    participant API as Dish Router (dishes.py)
    participant Svc as DishService (dish_service.py)
    participant DB as PostgreSQL (dishes table, GIN Indexes)

    Client->>API: GET /api/v1/restaurants/{id}/dishes?category_id=1&spicy_level=2&meal_type=lunch&dietary_tag=healthy&ingredient=Thịt bò
    activate API
    API->>Svc: get_dishes_by_restaurant(db, restaurant_id, category_id, meal_type, tag, ingredient...)
    activate Svc
    
    Note over Svc, DB: Xây dựng truy vấn động kết hợp toán tử AND:<br/>1. restaurant_id == restaurant_id<br/>2. category_id == 1<br/>3. meal_type == 'lunch'<br/>4. (tag == 'signature' OR tags.contains(['signature']))<br/>5. Dish.ingredients.any('Thịt bò')<br/>6. is_available == True
    
    Svc->>DB: SELECT * FROM dishes WHERE restaurant_id = :id AND ... ORDER BY id DESC LIMIT 100
    activate DB
    Note right of DB: Tận dụng các chỉ mục:<br/>- B-Tree: ix_dishes_tag, ix_dishes_restaurant_category<br/>- GIN Index: ix_dishes_tags_gin, ix_dishes_ingredients_gin
    DB-->>Svc: List[Dish] entities
    deactivate DB

    Svc->>Svc: Chuyển đổi List[Dish] sang List[DishResponse] qua to_dish_response
    Svc-->>API: List[DishResponse]
    deactivate Svc
    API-->>Client: HTTP 200 OK (Danh sách món ăn phù hợp tiêu chí lọc)
    deactivate API
```
</details>

### Diễn giải chi tiết:
1. Client gửi yêu cầu lấy thực đơn của quán kèm các tham số lọc tuỳ chọn: `category_id`, `meal_type_id`, `meal_type`, `tag`, `ingredient`, `available_only`.
2. `DishService` xây dựng câu lệnh truy vấn SQLAlchemy linh hoạt:
   - Bộ lọc `tag`: kiểm tra đồng thời cả cột chuỗi đơn `Dish.tag == t` hoặc mảng `Dish.tags.contains([t])`.
   - Bộ lọc `ingredient`: sử dụng toán tử SQL mảng `Dish.ingredients.any(ingredient)` để tìm món chứa nguyên liệu chỉ định.
   - Kết hợp các điều kiện bằng phép `AND`, chỉ lấy món đang phục vụ (`is_available = True` theo mặc định).
3. PostgreSQL thực thi tối ưu nhờ các chỉ mục GIN trên `tags` và `ingredients`.
4. Trả về mảng danh sách món ăn đã định dạng đầy đủ thông tin cho giao diện người dùng.

---

## 8. Luồng 7: Khách Hàng Quản Lý Món Ăn Yêu Thích (Favourites)

Áp dụng cho module: `server/app/api/v1/endpoints/dishes.py` (Endpoints `/users/{user_id}/favourites`).

![Sơ đồ Tuần tự Món Ăn Yêu Thích](seq-favourite.png)

<details>
<summary><b>Xem mã nguồn Mermaid</b></summary>

```mermaid
sequenceDiagram
    autonumber
    actor User as Khách hàng (User)
    participant API as Dishes/Favourites Router (dishes.py)
    participant Svc as DishService (dish_service.py)
    participant DB as PostgreSQL (favourite_dishes, users, dishes)

    Note over User, DB: Thao tác 1: Thêm món vào danh sách yêu thích (Idempotent)
    User->>API: POST /api/v1/users/{user_id}/favourites/{dish_id}
    activate API
    API->>Svc: add_favourite_dish(db, user_id, dish_id)
    activate Svc
    
    Svc->>DB: db.get(User, user_id)
    DB-->>Svc: User record
    alt User không tồn tại
        Svc-->>API: HTTPException 404 (Không tìm thấy người dùng)
        API-->>User: HTTP 404 Not Found
    end

    Svc->>DB: db.get(Dish, dish_id)
    DB-->>Svc: Dish record
    alt Dish không tồn tại
        Svc-->>API: HTTPException 404 (Không tìm thấy món ăn)
        API-->>User: HTTP 404 Not Found
    end

    Svc->>DB: SELECT * FROM favourite_dishes WHERE user_id = :uid AND dish_id = :did
    DB-->>Svc: Existing FavouriteDish or None
    alt Đã yêu thích trước đó
        Svc-->>API: Trả về FavouriteDish hiện tại (Idempotent)
    else Chưa có trong danh sách
        Svc->>DB: INSERT INTO favourite_dishes (user_id, dish_id)
        DB-->>Svc: commit() -> New FavouriteDish record
        Svc-->>API: FavouriteDish entity
    end
    deactivate Svc
    API-->>User: HTTP 201 Created (FavouriteDishResponse kèm chi tiết dish)
    deactivate API

    Note over User, DB: Thao tác 2: Bỏ yêu thích món ăn
    User->>API: DELETE /api/v1/users/{user_id}/favourites/{dish_id}
    activate API
    API->>Svc: remove_favourite_dish(db, user_id, dish_id)
    activate Svc
    Svc->>DB: SELECT * FROM favourite_dishes WHERE user_id = :uid AND dish_id = :did
    DB-->>Svc: FavouriteDish record
    alt Không tìm thấy bản ghi yêu thích
        Svc-->>API: HTTPException 404 (Món ăn chưa nằm trong danh sách yêu thích)
        API-->>User: HTTP 404 Not Found
    else Tìm thấy bản ghi
        Svc->>DB: DELETE FROM favourite_dishes WHERE id = :id
        DB-->>Svc: commit()
        Svc-->>API: True
        API-->>User: HTTP 200 OK {"message": "Đã bỏ món ăn khỏi danh sách yêu thích"}
    end
    deactivate Svc
    deactivate API
```
</details>

### Diễn giải chi tiết:
1. **Thêm yêu thích (POST):**
   - User gửi `user_id` và `dish_id`.
   - Hệ thống xác minh sự tồn tại của người dùng và món ăn.
   - Cơ chế **Idempotent**: kiểm tra xem cặp `(user_id, dish_id)` đã có trong bảng `favourite_dishes` chưa. Nếu đã có, trả về ngay bản ghi hiện tại mà không báo lỗi hoặc tạo thêm bản ghi trùng.
   - Nếu chưa có, tạo bản ghi mới (không lưu trường `tag` theo đúng thiết kế hiện tại) và trả về HTTP 201 Created.
2. **Bỏ yêu thích (DELETE):**
   - User gửi `user_id` và `dish_id`.
   - Hệ thống tìm và xoá bản ghi khỏi bảng `favourite_dishes`. Nếu không tìm thấy trả về HTTP 404 Not Found.
3. **Cascade Integrity:** Khi món ăn (`Dish`) hoặc tài khoản khách hàng (`User`) bị xoá, toàn bộ các bản ghi `favourite_dishes` liên quan sẽ tự động được xoá theo nhờ cơ chế `ON DELETE CASCADE`.


---



---

## 8. Luồng 8: Quản trị viên Quản lý Danh mục Toàn cục (Global Categories Management)

Áp dụng cho module: `server/app/api/v1/endpoints/categories.py` & `server/app/services/category_service.py`.

```mermaid
sequenceDiagram
    autonumber
    actor Admin as 🛡️ Quản trị viên (Admin)
    participant API as 🚪 Categories Router (categories.py)
    participant Svc as ⚙️ CategoryService (category_service.py)
    participant DB as 🗄️ PostgreSQL (categories, dishes tables)

    Note over Admin, DB: Thao tác 1: Tạo Danh mục Toàn cục mới (Global Category)
    Admin->>API: POST /api/v1/categories {name: "Món Chay", description: "Món ăn thuần thực vật", display_order: 1}
    activate API
    API->>Svc: create_category(db, payload)
    activate Svc
    Svc->>Svc: Chuẩn hóa tên: name.strip()
    Svc->>DB: SELECT * FROM categories WHERE lower(name) = lower('Món Chay')
    DB-->>Svc: None (chưa tồn tại)
    Svc->>DB: INSERT INTO categories (name, description, display_order, is_active)
    activate DB
    DB-->>Svc: db.commit() + db.refresh() -> Category (id, created_at)
    deactivate DB
    Svc-->>API: Category entity
    deactivate Svc
    API-->>Admin: HTTP 201 Created (CategoryResponse)
    deactivate API

    Note over Admin, DB: Thao tác 2: Xóa Danh mục Toàn cục & An toàn Dữ liệu (SET NULL)
    Admin->>API: DELETE /api/v1/categories/{category_id}
    activate API
    API->>Svc: delete_category(db, category_id)
    activate Svc
    Svc->>DB: db.get(Category, category_id)
    DB-->>Svc: Category record
    alt Danh mục không tồn tại
        Svc-->>API: HTTPException 404 (Không tìm thấy danh mục món ăn)
        API-->>Admin: HTTP 404 Not Found
    else Tìm thấy danh mục
        Svc->>DB: DELETE FROM categories WHERE id = category_id
        activate DB
        Note right of DB: Ràng buộc ON DELETE SET NULL:<br/>Mọi dishes.category_id trỏ tới danh mục này<br/>được tự động cập nhật về NULL (Không mất món ăn)
        DB-->>Svc: commit() thành công
        deactivate DB
        Svc-->>API: True
        API-->>Admin: HTTP 200 OK {"message": "Xóa danh mục thành công"}
    end
    deactivate Svc
    deactivate API
```

### Diễn giải chi tiết:
1. **Tạo danh mục toàn cục:**
   - Quản trị viên gửi tên danh mục (`name`), mô tả (`description`), thứ tự hiển thị (`display_order`). Không cần cung cấp `restaurant_id`.
   - `CategoryService` kiểm tra ràng buộc duy nhất toàn cục không phân biệt hoa thường (`lower(name)`). Nếu đã tồn tại trả về `400 Bad Request`.
   - Tạo bản ghi và trả về `CategoryResponse` (HTTP 201 Created).
2. **Xóa danh mục an toàn (SET NULL):**
   - Khi xóa danh mục, khóa ngoại `dishes.category_id` tự động nhận giá trị `NULL` nhờ cơ chế `ON DELETE SET NULL`. Toàn bộ món ăn của các quán vẫn được bảo toàn nguyên vẹn trong thực đơn.

---

## 9. Luồng 9: Khảo sát Onboarding & Cập nhật Hồ sơ Sức khỏe / Sở thích (User Profile)

Áp dụng cho module: `mobile/lib/main.dart`, `server/app/api/v1/endpoints/user_profiles.py` & `server/app/services/user_profile_service.py`.

```mermaid
sequenceDiagram
    autonumber
    actor User as 👤 Khách hàng (User)
    participant Mobile as 📱 Flutter Mobile (main.dart)
    participant API as 🚪 FastAPI Router (user_profiles.py)
    participant Svc as ⚙️ UserProfileService
    participant DB as 🗄️ PostgreSQL (users table)

    Note over User, DB: Giai đoạn 1: Đăng nhập & Kiểm tra Onboarding
    User->>Mobile: Đăng nhập thành công vào ứng dụng
    Mobile->>API: GET /api/v1/users/{user_id}/profile
    activate API
    API->>Svc: get_or_create_profile(db, user_id)
    activate Svc
    Svc->>DB: db.get(User, user_id)
    DB-->>Svc: User entity (tích hợp hồ sơ)
    deactivate Svc
    API-->>Mobile: HTTP 200 OK (UserProfileResponse: is_onboarded=False)
    deactivate API

    Note over User, Mobile: Giai đoạn 2: Khảo sát tương tác (Onboarding Survey Wizard)
    Mobile->>User: Hiển thị OnboardingSurveyDialog (3 Bước)
    User->>Mobile: Bước 1: Chọn thể loại món & chế độ ăn (healthy, low_carb)
    User->>Mobile: Bước 2: Nhập chiều cao (175cm), cân nặng (70kg), mục tiêu (maintain)
    User->>Mobile: Bước 3: Chọn độ cay (cay vừa), dị ứng (hải sản), ngân sách
    User->>Mobile: Nhấn nút [Lưu & Hoàn tất]

    Note over Mobile, DB: Giai đoạn 3: Lưu trữ trực tiếp & Tính toán BMI động
    Mobile->>API: PUT /api/v1/users/{user_id}/profile {height_cm, weight_kg, complete_onboarding: true, ...}
    activate API
    API->>Svc: update_profile(db, user_id, payload)
    activate Svc
    Svc->>Svc: Kiểm tra ràng buộc (height BETWEEN 50 AND 260, weight BETWEEN 10 AND 500)
    Svc->>Svc: Gán is_onboarded = True, onboarded_at = now(), updated_at = now()
    Svc->>DB: UPDATE users SET ... (db.commit + db.refresh)
    DB-->>Svc: Cập nhật thành công
    deactivate Svc
    API->>API: Tính toán tự động: bmi = 70 / (1.75^2) = 22.9, bmi_category = 'normal'
    API-->>Mobile: HTTP 200 OK (UserProfileResponse: bmi=22.9, bmi_category='normal', is_onboarded=True)
    deactivate API

    Mobile->>User: Đóng Dialog, thông báo hoàn tất & hiển thị thẻ Hồ Sơ Sức Khỏe trên Tab Tài Khoản
```


</details>

