# ĐỀ CƯƠNG BÁO CÁO THỰC TẬP TỐT NGHIỆP / KHÓA LUẬN TỐT NGHIỆP

**ĐỀ TÀI: NGHIÊN CỨU, THIẾT KẾ VÀ XÂY DỰNG HỆ THỐNG GỢI Ý ĐỊA ĐIỂM ẨM THỰC THÔNG MINH DỰA TRÊN DỮ LIỆU KHÔNG GIAN ĐỊA LÝ (GIS/POSTGIS), YẾU TỐ THỜI TIẾT VÀ HỒ SƠ CÁ NHÂN HÓA NGƯỜI DÙNG**

---

## Phần 1: Mở đầu

### 1.1. Đặt vấn đề

Ẩm thực luôn là một phần thiết yếu trong đời sống hàng ngày của mỗi con người. Đặc biệt tại các khu đô thị vệ tinh tập trung đông đảo sinh viên, cán bộ, giảng viên như khu vực Huyện Gia Lâm (nơi đặt trụ sở Học viện Nông nghiệp Việt Nam - VNUA), nhu cầu tìm kiếm quán ăn ngon, sạch, giá cả sinh viên và khoảng cách di chuyển phù hợp luôn là vấn đề cấp bách diễn ra mỗi ngày.

Hiện nay, mặc dù các nền tảng thương mại điện tử ẩm thực như ShopeeFood hay GrabFood đã rất phổ biến, nhưng các hệ thống này chủ yếu tập trung vào nghiệp vụ đặt món trực tuyến giao tận nơi (Food Delivery) với mức chiết khấu hoa hồng cao (thường từ 20% đến 30%), khiến nhiều quán ăn bình dân, quán cơm sinh viên không thể tham gia hoặc phải tăng giá món ăn. Hơn nữa, thuật toán đề xuất của các ứng dụng này chủ yếu dựa trên quảng cáo tài trợ và tần suất đơn hàng tổng thể, chưa gắn liền với ngữ cảnh thực tế của người dùng: thời tiết tức thời (trời mưa lạnh nên ăn lẩu, đồ nóng sốt; trời nắng gắt nên chọn món nước mát, chè, salad), thể trạng sức khỏe (chỉ số BMI, cảnh báo dị ứng thực phẩm, hạn chế độ cay) và mức ngân sách sinh viên chi trả trực tiếp tại quán.

Mặt khác, công nghệ thông tin và truyền thông ngày nay đang phát triển vượt bậc, đặc biệt là công nghệ Hệ thống Thông tin Địa lý (GIS) với các tiện ích mở rộng không gian mạnh mẽ như PostgreSQL/PostGIS, dịch vụ bản đồ số mã nguồn mở OpenStreetMap, cùng sự bùng nổ của các nền tảng lập trình hiện đại như FastAPI (Python) và Flutter SDK (đa nền tảng Mobile & Web). Việc kết hợp công nghệ không gian địa lý với mô hình phân tích thời tiết và hồ sơ người dùng mở ra giải pháp tối ưu cho bài toán gợi ý ẩm thực thực tế.

Xuất phát từ thực tiễn trên, việc thực hiện đề tài "Nghiên cứu, thiết kế và xây dựng Hệ thống gợi ý địa điểm ẩm thực thông minh dựa trên dữ liệu không gian địa lý (GIS/PostGIS), yếu tố thời tiết và hồ sơ cá nhân hóa người dùng" (Hệ sinh thái PTC1) là vô cùng cần thiết và có giá trị ứng dụng thực tiễn cao.

### 1.2. Mục đích và yêu cầu

#### 1.2.1. Mục đích

- Về mặt học thuật: Nghiên cứu chuyên sâu về các mô hình hệ thống gợi ý theo ngữ cảnh (Context-Aware Recommendation Systems), kỹ thuật xử lý và truy vấn dữ liệu không gian địa lý (Spatial Query) trên hệ quản trị CSDL PostgreSQL kết hợp PostGIS, và quy trình xây dựng ứng dụng di động đa nền tảng hiện đại.

- Về mặt ứng dụng: Thiết kế và triển khai hoàn chỉnh một hệ sinh thái phần mềm gồm Backend RESTful API, Web Admin Dashboard và Ứng dụng di động (Mobile App) phục vụ thực khách (đặc biệt là sinh viên Học viện Nông nghiệp Việt Nam) tìm kiếm, định vị và nhận gợi ý ẩm thực thông minh theo thời tiết và thể trạng cá nhân.

- Về mặt xã hội: Kết nối thực khách với hơn 200 địa điểm ẩm thực truyền thống, quán ăn bình dân tại khu vực Huyện Gia Lâm, góp phần thúc đẩy kinh tế số địa phương và nâng cao trải nghiệm sinh hoạt của sinh viên.

#### 1.2.2. Yêu cầu

Đề tài cần đáp ứng đầy đủ các yêu cầu cốt lõi sau:

a) Yêu cầu chức năng:

+ Phân quyền người dùng đa cấp độ: Quản lý 3 nhóm đối tượng: Khách vãng lai (Guest - tra cứu bản đồ, thực đơn tự do không bắt buộc đăng nhập), Người dùng thành viên (User - lưu hồ sơ thể chất Onboarding, món ăn yêu thích, tùy chọn ẩn danh mục) và Quản trị viên (Admin - kiểm soát toàn bộ dữ liệu, quán ăn, thực đơn, phân quyền và quy tắc thời tiết).

+ Khảo sát Onboarding & Quản lý hồ sơ sức khỏe: Tự động tính chỉ số BMI từ chiều cao/cân nặng, phân loại thể trạng, ghi nhận mục tiêu dinh dưỡng, độ cay, ngân sách, chế độ ăn kiêng và cảnh báo dị ứng thực phẩm.

+ Gợi ý ẩm thực theo thời tiết & theo mùa: Tự động đồng bộ thời tiết tức thời từ OpenWeatherMap API hoặc truy xuất thông minh từ bộ dữ liệu 400 mẫu thời tiết theo mùa (Xuân, Hạ, Thu, Đông) để gợi ý danh mục món ăn tương thích nhất.

+ Bản đồ tương tác & Định vị không gian: Tích hợp bản đồ OpenStreetMap mượt mà, định vị người dùng thông minh qua IP mạng (không ép buộc quyền GPS phần cứng), chuyển đổi địa chỉ (Geocoding), tính khoảng cách cầu chính xác tới từng quán ăn và giới hạn phạm vi hiển thị chuẩn xác trong địa bàn Huyện Gia Lâm.

+ Cổng quản trị Web Admin: Bảng điều khiển trực quan hỗ trợ CRUD Quán ăn, Món ăn, Danh mục, Người dùng (kèm xác nhận xóa an toàn) và Quy tắc gợi ý Thời tiết (phân trang, lọc theo mùa).

b) Yêu cầu phi chức năng:

+ Hiệu năng hệ thống: Thời gian phản hồi API trung bình dưới 200ms cho các truy vấn không gian phức tạp (`ST_Distance`, `ST_DWithin`); ứng dụng Mobile hoạt động mượt mà đạt tốc độ khung hình 60fps.

+ Tính khả dụng & Tự động hóa: Cung cấp kịch bản cài đặt tự động 1-click trên hệ điều hành Windows (`CAI_DAT.bat`, `setup.ps1`) tự động cấu hình từ A-Z môi trường Python, PostgreSQL, PostGIS, nạp sẵn CSDL thực tế.

+ Độ tin cậy & Kiểm thử: Toàn bộ mã nguồn phải vượt qua 100% các bộ kiểm thử tự động đa tầng (Backend Pytest với hơn 100 test cases trên PostgreSQL thật, Flutter widget test, Web TypeScript build và E2E UI flow test Playwright).

## Phần 2: Tổng quan tình hình nghiên cứu trong và ngoài nước

### 2.1. Tình hình nghiên cứu trong nước

Tại Việt Nam, các ứng dụng công nghệ phục vụ nhu cầu ăn uống chủ yếu phát triển mạnh ở mảng đặt đồ ăn trực tuyến (Food Delivery) với các tên tuổi lớn như GrabFood, ShopeeFood, Baemin (trước khi rút khỏi thị trường). Các nền tảng này sở hữu hạ tầng công nghệ và dữ liệu khổng lồ, tuy nhiên mục tiêu kinh doanh hướng tới doanh thu đặt món và phí dịch vụ giao hàng, dẫn đến thuật toán gợi ý tập trung quảng bá các đối tác thương mại trả phí thay vì tối ưu hóa trải nghiệm ăn uống tại chỗ hoặc gợi ý theo ngữ cảnh khí hậu.

Về khía cạnh học thuật, một số đề tài nghiên cứu tại các trường đại học đã bước đầu tiếp cận bài toán xây dựng WebGIS quản lý quán ăn, du lịch ẩm thực tại một số tỉnh thành (như Hà Nội, Đà Nẵng, TP. Hồ Chí Minh). Tuy nhiên, hầu hết các hệ thống này chỉ dừng lại ở dạng bản đồ số hiển thị tĩnh, giao diện Web truyền thống, chưa xây dựng ứng dụng di động chuyên biệt cho người dùng cuối. Đặc biệt, việc tích hợp thời gian thực các yếu tố khí tượng (nhiệt độ, mưa, gió, mùa) và hồ sơ sức khỏe cá nhân (BMI, dị ứng) vào bài toán gợi ý món ăn gần như chưa được khai thác toàn diện tại thị trường Việt Nam.

### 2.2. Tình hình nghiên cứu ngoài nước

Trên thế giới, các nền tảng tra cứu địa điểm và ẩm thực nổi tiếng như Yelp, TripAdvisor, Foursquare hay Google Maps đã đạt đến mức độ hoàn thiện rất cao về dữ liệu và công nghệ bản đồ. Các dịch vụ này ứng dụng các thuật toán gợi ý tiên tiến (Collaborative Filtering, Content-based Filtering) dựa trên lịch sử đánh giá, check-in của cộng đồng người dùng toàn cầu.

Bên cạnh các sản phẩm thương mại, hướng nghiên cứu Hệ thống gợi ý nhận biết ngữ cảnh (Context-Aware Recommendation Systems - CARS) là một chủ đề học thuật được quan tâm rộng rãi trong các hội nghị quốc tế hàng đầu như ACM RecSys, IEEE ICDE. Các nhà khoa học đã chứng minh rằng việc đưa các chiều ngữ cảnh thời gian thực (Spatial - Không gian, Temporal - Thời gian, Weather - Khí tượng, Nutritional - Dinh dưỡng) vào mô hình gợi ý giúp tăng độ hài lòng của người dùng lên đáng kể so với các hệ thống truyền thống chỉ dựa trên ma trận người dùng - sản phẩm.

Tuy nhiên, việc triển khai các mô hình lý thuyết này vào một hệ thống phần mềm hoàn chỉnh, thích ứng linh hoạt với đặc thù văn hóa ẩm thực châu Á, địa lý đường phố phức tạp và điều kiện khí hậu nhiệt đới gió mùa tại Việt Nam vẫn đòi hỏi một giải pháp kiến trúc phần mềm thực nghiệm chuyên sâu.

### 2.3. Nêu tên Đề tài và tính thời sự, tầm quan trọng của Đề tài

- Tên đề tài chính thức: "Nghiên cứu, thiết kế và xây dựng Hệ thống gợi ý địa điểm ẩm thực thông minh dựa trên dữ liệu không gian địa lý (GIS/PostGIS), yếu tố thời tiết và hồ sơ cá nhân hóa người dùng" (Tên thương hiệu hệ thống: PTC1 Food Platform).

- Tính thời sự của đề tài:

+ Đề tài bắt kịp xu thế chuyển đổi số mạnh mẽ trong dịch vụ đời sống và ẩm thực đô thị hiện đại.

+ Áp dụng các công nghệ lập trình tiên tiến nhất hiện nay: FastAPI (Python Framework bất đồng bộ hiệu năng cao), PostgreSQL kết hợp extension không gian PostGIS chuẩn công nghiệp, Flutter SDK phát triển giao diện người dùng đa nền tảng (Material 3), Vue 3 Composition API kết hợp TypeScript và hệ sinh thái bản đồ mở OpenStreetMap.

+ Giải quyết nhu cầu thiết thực, thường nhật của sinh viên và cư dân sau giai đoạn bùng nổ đô thị hóa tại khu vực ngoại thành phía Đông Hà Nội.

- Tầm quan trọng của đề tài:

+ Về giá trị học tập và nghiên cứu: Cung cấp một mẫu kiến trúc phần mềm chuẩn mực (Monorepo tích hợp Backend, Web Admin, Mobile Client), ứng dụng thực tế các lý thuyết về CSDL không gian, thuật toán tính khoảng cách địa lý và quy trình kiểm thử tự động hóa toàn diện.

+ Về giá trị ứng dụng thực tiễn: Hệ thống có thể triển khai sử dụng ngay cho hơn 30.000 sinh viên, cán bộ tại Học viện Nông nghiệp Việt Nam và nhân dân Huyện Gia Lâm, góp phần hỗ trợ các hộ kinh doanh ẩm thực vừa và nhỏ quảng bá dịch vụ minh bạch, văn minh.

## Phần 3: Nội dung và phương pháp nghiên cứu

### 3.1. Địa điểm và thời gian nghiên cứu (thực tập)

- Địa điểm nghiên cứu / thực tập: Khoa Công nghệ thông tin - Học viện Nông nghiệp Việt Nam (VNUA), Thị trấn Trâu Quỳ, Huyện Gia Lâm, Thành phố Hà Nội.

- Đơn vị phối hợp khảo sát: Các cơ sở kinh doanh dịch vụ ăn uống, nhà hàng, quán ăn trên địa bàn Huyện Gia Lâm (tập trung trọng điểm tại các trục đường Ngô Xuân Quảng, Đào Nguyên, An Đào, Cửu Việt, Trâu Quỳ).

- Thời gian nghiên cứu / thực tập dự kiến: 15 tuần (Từ ngày 01/09/2026 đến ngày 15/12/2026).

### 3.2. Nội dung nghiên cứu

Để hoàn thành mục tiêu đề ra, đề tài tập trung triển khai 8 nội dung công việc chủ yếu sau:

1. Nội dung 1: Khảo sát thực trạng, thu thập và chuẩn hóa dữ liệu địa lý của 204 quán ăn và hơn 775 món ăn, danh mục ẩm thực trên địa bàn Huyện Gia Lâm.

2. Nội dung 2: Nghiên cứu lý thuyết CSDL không gian, xây dựng mô hình dữ liệu quan hệ kết hợp kiểu dữ liệu không gian PostGIS (Geography Point WGS84 - EPSG:4326).

3. Nội dung 3: Nghiên cứu và xây dựng thuật toán gợi ý món ăn theo ngữ cảnh: tích hợp OpenWeatherMap API và bộ dữ liệu chuẩn 400 mẫu thời tiết theo mùa (Xuân, Hạ, Thu, Đông) gắn với ma trận danh mục món ăn phù hợp.

4. Nội dung 4: Thiết kế kiến trúc tổng thể hệ thống (System Architecture), thiết kế giao diện UI/UX trên Figma cho Web Admin và Mobile Client.

5. Nội dung 5: Xây dựng Backend RESTful API bằng FastAPI: xác thực đa vai trò, quản lý hồ sơ Onboarding BMI, truy vấn không gian PostGIS (`ST_Distance`), Geocoding và IP Geolocation.

6. Nội dung 6: Xây dựng Cổng quản trị Web Admin bằng Vue 3, Vite và TypeScript: quản lý quán ăn, thực đơn, người dùng và ma trận luật thời tiết.

7. Nội dung 7: Xây dựng Ứng dụng di động Mobile Client bằng Flutter SDK (Material 3): hiển thị bản đồ OpenStreetMap tương tác, tìm kiếm quán ăn, lọc danh mục, khảo sát thể trạng và hiển thị chi tiết menu calo/dị ứng.

8. Nội dung 8: Thực hiện kiểm thử tự động đa tầng (Backend Pytest, Flutter Widget Test, E2E UI Playwright Flow) và xây dựng bộ công cụ cài đặt tự động 1-click.

### 3.3. Phương pháp nghiên cứu

Trình bày đầy đủ các phương pháp nghiên cứu khoa học và kỹ thuật phần mềm cần áp dụng:

- Phương pháp thu thập và xử lý số liệu: Tiến hành khảo sát thực địa, thu thập tọa độ kinh độ/vĩ độ, thực đơn, đơn giá, giờ phục vụ của các quán ăn tại Gia Lâm; xử lý làm sạch và chuẩn hóa dữ liệu dưới dạng SQL/JSON.

- Phương pháp phân tích và thiết kế hướng đối tượng (OOAD):

+ Sử dụng ngôn ngữ mô hình hóa thống nhất (UML) để xây dựng biểu đồ Use Case, Biểu đồ lớp (Class Diagram) và Biểu đồ tuần tự (Sequence Diagram) thể hiện các luồng xác thực, khảo sát Onboarding, tra cứu bản đồ và gợi ý món ăn.

+ Thiết kế mô hình dữ liệu thực thể quan hệ (ERD) trên PostgreSQL chuẩn hóa bậc 3.

- Phương pháp tính toán và truy vấn không gian (Spatial Computing):

+ Ứng dụng hệ tọa độ WGS84 (World Geodetic System 1984, EPSG:4326) để lưu trữ vị trí địa lý của quán ăn.

+ Ứng dụng các hàm chuyên biệt của PostGIS (`ST_SetSRID`, `ST_MakePoint`, `ST_Distance`) để tính toán khoảng cách cầu theo mặt ellipsoid và giới hạn phạm vi ranh giới đa giác Huyện Gia Lâm.

- Phương pháp gợi ý dựa trên tri thức và luật ngữ cảnh (Knowledge-Based Contextual Rule Engine):

+ Xây dựng ma trận ánh xạ logic giữa điều kiện nhiệt độ, khí hậu thời tiết với các đặc tính món ăn (nóng, lạnh, thanh đạm, giàu năng lượng).

+ Tích hợp bộ quy tắc sàng lọc theo hồ sơ người dùng (loại trừ dị ứng, cảnh báo độ cay, lọc theo mục tiêu cân nặng BMI).

- Phương pháp phát triển phần mềm lặp linh hoạt (Agile / Scrum): Chia nhỏ quá trình phát triển thành các Sprint 1-2 tuần, liên tục kiểm thử, tích hợp và tối ưu hóa tính năng.

- Phương pháp kiểm thử phần mềm tự động (Automated Testing Methodology):

+ Áp dụng Test-Driven Development (TDD) trên Backend với Pytest chạy trực tiếp trên CSDL PostgreSQL thật.

+ Kiểm thử giao diện tự động E2E (End-to-End Testing) bằng Playwright ghi nhận console log, server error và chụp ảnh màn hình nghiệm thu.

## Phần 4: Kế hoạch và dự kiến kết quả đạt được

### 4.1. Kế hoạch thực hiện đề tài theo thời gian là tuần

Kế hoạch triển khai đề tài được phân bổ khoa học trong 15 tuần làm việc cụ thể như bảng dưới đây:

| Tuần | Nội dung công việc chi tiết | Sản phẩm / Kết quả bàn giao | Người thực hiện |
| --- | --- | --- | --- |
| Tuần 1 | Nhận đề tài, nghiên cứu tài liệu tổng quan, khảo sát nhu cầu người dùng tại khu vực Gia Lâm. | Đề cương nghiên cứu chi tiết, biên bản khảo sát nhu cầu | Sinh viên |
| Tuần 2 | Thu thập dữ liệu địa lý thực địa (tọa độ, thực đơn, giờ mở cửa) của hơn 200 quán ăn tại Trâu Quỳ. | Bộ dữ liệu thô danh sách quán ăn và thực đơn | Sinh viên |
| Tuần 3 | Làm sạch dữ liệu, chuẩn hóa bộ 400 mẫu thời tiết theo mùa và thiết kế CSDL (ERD, Data Dictionary). | File SQL/JSON dữ liệu mẫu và sơ đồ ERD hoàn chỉnh | Sinh viên |
| Tuần 4 | Phân tích thiết kế hệ thống phần mềm (UML Use Case, Sequence Diagram, Class Diagram). | Tập tài liệu đặc tả kiến trúc và thiết kế hệ thống | Sinh viên |
| Tuần 5 | Khởi tạo Monorepo, thiết lập môi trường Backend FastAPI, PostgreSQL và PostGIS extension. | Khung dự án Backend kết nối DB thành công, script setup | Sinh viên |
| Tuần 6 | Lập trình module xác thực đa vai trò (Guest, User, Admin) và khảo sát Onboarding thể trạng BMI. | API xác thực và tính toán BMI hoạt động, test backend | Sinh viên |
| Tuần 7 | Lập trình module không gian PostGIS: truy vấn khoảng cách, tìm kiếm quán ăn và Geocoding OpenStreetMap. | API không gian địa lý trả về tọa độ và khoảng cách chính xác | Sinh viên |
| Tuần 8 | Lập trình module Thời tiết: tích hợp OpenWeatherMap API, nạp 400 mẫu thời tiết và gợi ý theo mùa. | API gợi ý món ăn theo thời tiết và bộ lọc danh mục | Sinh viên |
| Tuần 9 | Xây dựng giao diện Web Admin bằng Vue 3 + TypeScript: quản lý Quán ăn, Menu và Người dùng. | Web Admin hiển thị và quản lý đầy đủ các bảng dữ liệu | Sinh viên |
| Tuần 10 | Hoàn thiện Web Admin: Tab quy tắc thời tiết (phân trang, lọc mùa), giao diện đăng nhập Admin. | Hệ thống Web Admin hoàn chỉnh, build không lỗi | Sinh viên |
| Tuần 11 | Xây dựng ứng dụng Mobile Flutter: Giao diện Material 3, Bản đồ OpenStreetMap, định vị IP. | Ứng dụng Mobile hiển thị bản đồ mượt mà, marker quán ăn | Sinh viên |
| Tuần 12 | Hoàn thiện Mobile Flutter: Tab Khám phá, Bottom sheet thực đơn calo, khảo sát Onboarding. | Ứng dụng Mobile hoàn chỉnh chạy trên Android, iOS, Web | Sinh viên |
| Tuần 13 | Xây dựng kịch bản kiểm thử tự động E2E Flows (Playwright), kiểm thử tải và kiểm thử bảo mật. | Bộ kiểm thử E2E chạy tự động, báo cáo kết quả test | Sinh viên |
| Tuần 14 | Tối ưu hóa hiệu năng, đóng gói script cài đặt tự động 1-click (CAI_DAT.bat, CHAY_TAT_CA.bat). | Bộ cài đặt 1-click hoàn chỉnh và tài liệu hướng dẫn | Sinh viên |
| Tuần 15 | Viết báo cáo tổng kết khóa luận tốt nghiệp, chuẩn bị slide trình chiếu và bảo vệ đề tài. | Quyển báo cáo khóa luận hoàn chỉnh và bài thuyết trình | Sinh viên + GVHD |


### 4.2. Dự kiến kết quả chính sẽ đạt được

Kết thúc quá trình thực hiện đề tài, dự kiến sẽ đạt được các kết quả trọng tâm sau:

1. Về mặt học thuật và báo cáo:

- Báo cáo Khóa luận tốt nghiệp hoàn chỉnh với đầy đủ cơ sở lý luận, phương pháp nghiên cứu, phân tích thiết kế và đánh giá thực nghiệm.

- Bộ tài liệu thiết kế phần mềm chi tiết bao gồm: Từ điển dữ liệu (Data Dictionary), Sơ đồ thực thể liên kết (ERD), Sơ đồ Use Case, Sơ đồ lớp (Class Diagram), Sơ đồ tuần tự (Sequence Diagram) và Bộ tài liệu hướng dẫn kiểm thử (Manual & Automated Test Cases).

2. Về mặt sản phẩm phần mềm (Hệ sinh thái PTC1 Food Platform):

- Backend RESTful API hoàn chỉnh viết trên nền FastAPI (Python 3.9), chạy bất đồng bộ với cơ chế xác thực an toàn, tích hợp Swagger UI tài liệu hóa tự động tại `/docs`.

- Cơ sở dữ liệu chuẩn hóa PostgreSQL 14 tích hợp PostGIS 3.6.1 lưu trữ thực tế 204 quán ăn, 775 món ăn chi tiết (giá, calo, độ cay, thành phần, chất gây dị ứng) và 400 mẫu thời tiết theo mùa.

- Cổng quản trị Web Admin trực quan xây dựng bằng Vue 3, Vite và TypeScript, giao diện hiện đại với các tab nghiệp vụ chuyên sâu.

- Ứng dụng di động Mobile Client phát triển bằng Flutter SDK (Material 3), tương thích mượt mà trên Android, iOS và Web, tích hợp bản đồ số OpenStreetMap tương tác cao.

- Bộ công cụ tự động hóa 1-click (`CAI_DAT.bat`, `setup.ps1`, `CHAY_TAT_CA.bat`) cho phép người dùng hoặc giám khảo cài đặt toàn bộ hệ thống từ con số 0 trong vòng chưa đầy 5 phút.

- Tỷ lệ bao phủ kiểm thử đạt 100% (hơn 100 Pytest cases backend, Flutter widget test và E2E UI Playwright Flow test).

## Phần 5: Tài liệu tham khảo

### 5.1. Chi tiết các tài liệu tham khảo (dự kiến)

Danh mục tài liệu tham khảo dự kiến được sử dụng trong quá trình xây dựng đề cương và thực hiện khóa luận:

[1] Tiêu Chuẩn Quốc Gia TCVN 12693:2020 - Công nghệ thông tin - Hệ thống thông tin địa lý (GIS) - Yêu cầu kỹ thuật.

[2] Nguyễn Trọng Hòa, Đỗ Thị Lan (2022), Giáo trình Cơ sở dữ liệu không gian và GIS, Nhà xuất bản Đại học Quốc gia Hà Nội.

[3] Regina O. Obe, Leo S. Hsu (2021), PostGIS in Action (3rd Edition), Manning Publications, ISBN: 978-1617296697.

[4] Gediminas Adomavicius, Alexander Tuzhilin (2015), "Context-Aware Recommender Systems", in Recommender Systems Handbook, Springer, Boston, MA, pp. 191-226.

[5] Tiago Ramirez, et al. (2020), "Weather-Aware Recommendation Engine for Tourism and Gastronomy", IEEE International Conference on Big Data, pp. 1120-1127.

[6] Tiago Oliveira, Marco Santos (2023), "Evaluating Mobile Context-Aware Food Recommenders Based on Physical Health Profiles", ACM Transactions on Computer-Human Interaction, Vol. 30, No. 4, pp. 1-28.

[7] Sebastián Ramírez (2024), FastAPI Official Documentation, truy cập tại: https://fastapi.tiangolo.com/.

[8] Google LLC (2024), Flutter Documentation - Multi-platform UI Toolkit, truy cập tại: https://docs.flutter.dev/.

[9] Evan You, et al. (2024), Vue.js 3 - The Progressive JavaScript Framework, truy cập tại: https://vuejs.org/.

[10] OpenStreetMap Foundation (2024), OpenStreetMap Data and Nominatim Geocoding Services, truy cập tại: https://www.openstreetmap.org/.
