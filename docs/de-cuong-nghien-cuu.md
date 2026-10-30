# ĐỀ CƯƠNG BÁO CÁO THỰC TẬP TỐT NGHIỆP / KHÓA LUẬN TỐT NGHIỆP

**ĐỀ TÀI: NGHIÊN CỨU, THIẾT KẾ VÀ XÂY DỰNG HỆ THỐNG GỢI Ý ĐỊA ĐIỂM ẨM THỰC THÔNG MINH DỰA TRÊN DỮ LIỆU KHÔNG GIAN ĐỊA LÝ (GIS/POSTGIS), YẾU TỐ THỜI TIẾT VÀ HỒ SƠ CÁ NHÂN HÓA NGƯỜI DÙNG**

*HỆ SINH THÁI NỀN TẢNG ẨM THỰC PTC1 (PTC1 FOOD PLATFORM)*

---

## Phần 1: Mở đầu

### 1.1. Đặt vấn đề

Ẩm thực và dinh dưỡng luôn giữ vai trò là một trong những nhu cầu căn bản và thiết yếu nhất trong đời sống thường nhật của con người. Tại các khu đô thị vệ tinh đang trên đà phát triển nhanh chóng, đặc biệt là các trung tâm giáo dục đào tạo quy mô lớn như khu vực Huyện Gia Lâm (nơi đặt trụ sở chính của Học viện Nông nghiệp Việt Nam - VNUA với quy mô trên 30.000 sinh viên, cán bộ, giảng viên và người lao động sinh sống, học tập), bài toán lựa chọn địa điểm ăn uống mỗi ngày luôn là vấn đề thường trực, gây ra nhiều khó khăn và tiêu tốn không ít thời gian của đại bộ phận sinh viên.

Khảo sát thực tiễn cho thấy, sinh viên thường xuyên gặp phải tình trạng lúng túng với câu hỏi 'Hôm nay ăn gì? Ở đâu?'. Các rào cản chính bao gồm: thiếu hụt nguồn thông tin tập trung, minh bạch và đáng tin cậy về các quán ăn xung quanh; không nắm rõ khoảng cách di chuyển thực tế, dẫn đến việc tốn kém thời gian đi lại giữa các ca học; thiếu thông tin cập nhật về khung giờ đóng/mở cửa, đơn giá chi tiết từng món ăn, cũng như các yếu tố liên quan trực tiếp đến an toàn thực phẩm, mức độ phù hợp với khẩu vị cá nhân và ngân sách sinh viên vốn có phần eo hẹp.

Hiện nay, sự bùng nổ của các nền tảng thương mại điện tử giao đồ ăn trực tuyến (Food Delivery) như GrabFood, ShopeeFood hay Baemin (giai đoạn trước khi rời thị trường) đã phần nào làm thay đổi thói quen ăn uống của cư dân đô thị. Tuy nhiên, khi áp dụng vào thực tế tại các khu vực ngoại thành và cộng đồng sinh viên, các nền tảng này bộc lộ những hạn chế cố hữu:

+ Thứ nhất, mô hình kinh doanh chủ đạo của các ứng dụng này là dịch vụ giao hàng tận nơi (Delivery) với tỷ lệ chiết khấu hoa hồng rất cao đánh vào chủ quán (thường dao động từ 20% đến 30% trên tổng giá trị đơn hàng), kèm theo các khoản phụ phí vận chuyển và đóng gói đánh vào người tiêu dùng. Điều này khiến đại đa số các quán ăn bình dân, quán cơm sinh viên truyền thống có biên lợi nhuận thấp không thể tham gia, hoặc buộc phải tăng giá món ăn trên ứng dụng, gây bất lợi trực tiếp cho đối tượng sinh viên có thu nhập phụ thuộc vào gia đình.

+ Thứ hai, các ứng dụng thương mại hiện hành hoàn toàn không giải quyết được nhu cầu trải nghiệm ăn uống trực tiếp tại quán (Dine-in) - vốn là hình thức sinh hoạt phổ biến nhất của sinh viên sau giờ học hoặc trong các buổi tụ họp bạn bè. Người dùng không có công cụ trực quan để định vị các quán ăn xung quanh vị trí của mình theo thời gian thực với bản đồ tương tác đa chức năng.

+ Thứ ba, và là nhược điểm mang tính bản chất học thuật: Các thuật toán gợi ý món ăn của các nền tảng thương mại hiện nay hầu hết được xây dựng dựa trên mục tiêu tối đa hóa doanh thu và đơn hàng, ưu tiên hiển thị các đối tác quảng cáo tài trợ (Sponsored Ads) hoặc dựa trên tần suất đặt hàng toàn cục. Thuật toán hoàn toàn bỏ qua ngữ cảnh thời gian thực (Real-time Context) của thực khách, đặc biệt là sự kết hợp giữa: (1) Yếu tố thời tiết khí hậu tức thời (nhiệt độ, độ ẩm, điều kiện mưa nắng, mùa trong năm) tác động trực tiếp đến nhu cầu sinh học và tâm lý ẩm thực; (2) Yếu tố thể trạng sức khỏe và thể chất cá nhân (chỉ số khối cơ thể BMI, mức độ dung nạp cay, dị ứng thực phẩm, ngân sách chi trả và mục tiêu dinh dưỡng cá nhân).

Song song với những thách thức trên, sự tiến bộ vượt bậc của công nghệ thông tin trong kỷ nguyên số mang lại những tiền đề công nghệ vô cùng vững chắc để giải quyết triệt để bài toán này:

+ Công nghệ Hệ thống Thông tin Địa lý (GIS) mã nguồn mở, đặc biệt là hệ quản trị cơ sở dữ liệu đối tượng - quan hệ PostgreSQL tích hợp tiện ích mở rộng không gian PostGIS, cho phép lưu trữ, đánh chỉ mục không gian (Spatial Index GiST) và xử lý các phép toán hình học không gian phức tạp (tính khoảng cách mặt cầu theo ellipsoid WGS84, truy vấn bán kính lân cận, cắt lọc đa giác địa lý) với hiệu năng tính toán cực cao.

+ Nền tảng bản đồ số mở OpenStreetMap (OSM) cùng dịch vụ Geocoding Nominatim cung cấp giải pháp bản đồ trực quan, linh hoạt, hoàn toàn độc lập và không bị giới hạn bởi các chính sách tính phí thương mại đắt đỏ như Google Maps API.

+ Các lý thuyết và mô hình Hệ thống gợi ý nhận biết ngữ cảnh (Context-Aware Recommendation Systems - CARS) đang ngày càng hoàn thiện, cho phép xây dựng các công cụ suy diễn tri thức thông minh kết hợp đa chiều dữ liệu.

+ Nền tảng phát triển phần mềm hiện đại như FastAPI (framework Python bất đồng bộ tốc độ cao, hỗ trợ tài liệu hóa Swagger UI tự động), Flutter SDK (công cụ xây dựng giao diện di động đa nền tảng hiệu năng cao với Material 3) và Vue 3 (Composition API kết hợp TypeScript) cho phép triển khai một hệ sinh thái đồng bộ từ Backend, Web Admin đến Mobile Client.

Xuất phát từ những yêu cầu cấp thiết của thực tiễn đời sống sinh viên tại địa bàn Huyện Gia Lâm, cùng với mong muốn làm chủ và ứng dụng các công nghệ lập trình tiên tiến nhất, đề tài 'Nghiên cứu, thiết kế và xây dựng Hệ thống gợi ý địa điểm ẩm thực thông minh dựa trên dữ liệu không gian địa lý (GIS/PostGIS), yếu tố thời tiết và hồ sơ cá nhân hóa người dùng' (Hệ sinh thái PTC1 Food Platform) đã được lựa chọn nghiên cứu và triển khai thực hiện.

### 1.2. Mục đích và yêu cầu

#### 1.2.1. Mục đích

Mục đích tổng quát của đề tài là xây dựng thành công một giải pháp công nghệ toàn diện, kết hợp chặt chẽ giữa khoa học dữ liệu không gian, công nghệ gợi ý theo ngữ cảnh và kỹ thuật phát triển ứng dụng đa nền tảng để giải quyết bài toán gợi ý địa điểm ẩm thực cho sinh viên và cộng đồng dân cư.

Cụ thể, đề tài hướng tới 3 mục đích cốt lõi sau:

1. Về mặt học thuật và nghiên cứu khoa học:

- Nghiên cứu chuyên sâu về các mô hình Hệ thống gợi ý nhận biết ngữ cảnh (Context-Aware Recommendation Systems - CARS), phân tích cơ chế tích hợp các chiều biến số ngữ cảnh thời gian thực (Spatial, Weather, Temporal, Health Profile) vào thuật toán gợi ý ẩm thực.

- Nghiên cứu lý thuyết cơ sở dữ liệu không gian, các chuẩn dữ liệu địa lý OGC (Open Geospatial Consortium), kỹ thuật đánh chỉ mục không gian và tối ưu hóa các hàm truy vấn không gian địa lý trong hệ quản trị CSDL PostgreSQL/PostGIS (EPSG:4326 - WGS84).

- Nghiên cứu quy trình thiết kế, phát triển phần mềm theo mô hình kiến trúc phân tầng sạch (Clean Architecture / Service Layer Pattern) kết hợp kiểm thử tự động hóa toàn diện đa tầng (Multi-tier Automated Testing) trong môi trường dự án Monorepo.

2. Về mặt ứng dụng và sản phẩm kỹ thuật:

- Thiết kế và hiện thực hóa trọn vẹn Hệ sinh thái PTC1 Food Platform bao gồm 3 phân hệ chính quy chuẩn:

+ Phân hệ Backend RESTful API: Xây dựng bằng FastAPI (Python 3.9), hoạt động bất đồng bộ với cơ chế xử lý song song, kết nối CSDL PostgreSQL 14 + PostGIS 3.6.1, cung cấp đầy đủ các endpoint nghiệp vụ và tài liệu hóa tự động qua Swagger UI.

+ Phân hệ Cổng quản trị Web Admin: Xây dựng bằng Vue 3 (Composition API), Vite và TypeScript, cung cấp giao diện quản trị dữ liệu tập trung, trực quan, hỗ trợ CRUD quán ăn, thực đơn món ăn, danh mục, quản lý người dùng và bộ quy tắc thời tiết.

+ Phân hệ Ứng dụng di động (Mobile App): Xây dựng bằng Flutter SDK (Material 3), vận hành mượt mà trên cả hệ điều hành Android, iOS và trình duyệt Web, tích hợp bản đồ số OpenStreetMap tương tác cao, cơ chế định vị trực tuyến an toàn và khảo sát thể trạng thực khách.

- Xây dựng bộ công cụ cài đặt tự động hóa 1-click (One-click Installer & Auto-seed) trên môi trường Windows (`CAI_DAT.bat`, `setup.ps1`), cho phép thiết lập toàn bộ môi trường lập trình và nạp CSDL thực tế trong vòng vài phút mà không cần can thiệp thủ công phức tạp.

3. Về mặt kinh tế - xã hội và phục vụ cộng đồng:

- Khảo sát, thu thập và số hóa dữ liệu thực tế của 204 cơ sở kinh doanh dịch vụ ăn uống và hơn 775 món ăn trên địa bàn Huyện Gia Lâm (đặc biệt là các trục đường quanh Học viện Nông nghiệp Việt Nam), giúp sinh viên dễ dàng tiếp cận các quán ăn ngon, bổ, rẻ, đảm bảo vệ sinh.

- Hỗ trợ các hộ kinh doanh quán ăn bình dân, quán cơm truyền thống số hóa thực đơn, công khai minh bạch thông tin giấy phép vệ sinh ATTP và chứng nhận kinh doanh mà không phải chịu bất kỳ chi phí hoa hồng nào, góp phần thúc đẩy kinh tế số địa phương phát triển lành mạnh.

#### 1.2.2. Yêu cầu

Để đạt được các mục đích nêu trên, hệ thống phần mềm cần được thiết kế và xây dựng đáp ứng chặt chẽ các yêu cầu kỹ thuật sau:

a) Yêu cầu về chức năng (Functional Requirements):

- Phân quyền người dùng đa cấp độ theo vai trò (Role-Based Access Control):

+ Khách vãng lai (Guest Mode): Cho phép người dùng trải nghiệm tra cứu danh sách quán ăn, duyệt menu chi tiết, xem bản đồ tương tác và tìm kiếm địa điểm ngay lập tức mà không bắt buộc phải đăng nhập.

+ Người dùng thành viên (Registered User): Hỗ trợ đăng ký (họ tên, email, số điện thoại, mật khẩu mã hóa), đăng nhập quản lý phiên làm việc tự động; thực hiện khảo sát hồ sơ thể chất (Onboarding Survey); lưu trữ danh sách món ăn yêu thích cá nhân; tùy biến ẩn/hiện các danh mục ẩm thực theo khẩu vị riêng biệt (`OptionUser`).

+ Quản trị viên hệ thống (Administrator): Quản lý toàn diện tài nguyên hệ thống thông qua Cổng Web Admin; quản lý danh mục ẩm thực; quản lý quán ăn (tọa độ, giờ phục vụ, giấy phép, tài trợ); quản lý thực đơn món ăn; quản lý người dùng (xem chi tiết, xóa tài khoản an toàn kèm cơ chế xóa liên hoàn cascade); cấu hình và quản lý ma trận luật thời tiết (Weather Rules) phân trang thông minh và lọc theo 4 mùa.

- Khảo sát Onboarding & Quản lý hồ sơ sức khỏe thực khách:

+ Thu thập các chỉ số thể chất cơ bản: Chiều cao (`height_cm`, 50-260 cm), Cân nặng (`weight_kg`, 10-500 kg), Giới tính, Năm sinh.

+ Tự động tính toán Chỉ số Khối cơ thể (BMI = Cân nặng / (Chiều cao/100)^2) và phân loại thể trạng trực quan (Gầy, Bình thường, Thừa cân, Béo phì).

+ Ghi nhận các tiêu chí cá nhân hóa: Mục tiêu dinh dưỡng (Duy trì, Giảm cân, Tăng cơ, Ăn lành mạnh Healthy); Mức độ dung nạp cay (Không cay, Cay nhẹ, Cay vừa, Ăn cay nhiều); Khung ngân sách chi trả (Tiết kiệm, Tầm trung, Cao cấp); Chế độ ăn kiêng (Chay, Vegan, Halal, Keto...); Cảnh báo dị ứng thực phẩm (Lạc/đậu phộng, Hải sản, Sữa, Trứng, Gluten...).

- Hệ thống gợi ý ẩm thực theo thời tiết tức thời và theo mùa (Weather & Seasonal Context):

+ Tự động tích hợp và đồng bộ dữ liệu thời tiết thời gian thực từ OpenWeatherMap API theo tọa độ thực tế.

+ Xây dựng cơ chế fallback thông minh dựa trên bộ dữ liệu chuẩn hóa gồm 400 mẫu thời tiết theo 4 mùa (Xuân, Hạ, Thu, Đông) bao gồm đầy đủ các thông số: nhiệt độ, điều kiện khí hậu, dải độ ẩm tối thiểu (`min_humidity`) và tối đa (`max_humidity`).

+ Tự động suy luận ma trận danh mục món ăn tương thích nhất với điều kiện thời tiết (ví dụ: ngày lạnh mưa gió gợi ý món Lẩu, Đồ nướng, Món nước nóng sốt; ngày nắng nóng oi bức gợi ý Đồ uống mát, Chè, Sinh tố, Salad giải nhiệt).

- Bản đồ tương tác & Định vị không gian địa lý (GIS/PostGIS):

+ Hiển thị bản đồ số OpenStreetMap trực quan, hỗ trợ thao tác thu phóng (Zoom), xoay bản đồ và kéo thả mượt mà trên Flutter Mobile.

+ Định vị trực tuyến thông minh dựa trên địa chỉ IP mạng (Online IP Geolocation) thông qua proxy Backend an toàn, có cơ chế fallback mặc định chính xác tại tọa độ Học viện Nông nghiệp Việt Nam, hoàn toàn không ép buộc quyền truy cập phần cứng GPS trên thiết bị.

+ Chuyển đổi địa chỉ sang tọa độ địa lý (Geocoding) thông qua OpenStreetMap Nominatim API.

+ Sử dụng hàm không gian PostGIS `ST_Distance` để tính toán khoảng cách mặt cầu theo ellipsoid WGS84 từ vị trí người dùng đến từng quán ăn trong CSDL.

+ Áp dụng thuật toán giới hạn phạm vi hiển thị và cảnh báo tọa độ chuẩn xác trong ranh giới đa giác Huyện Gia Lâm.

- Quản lý thông tin chi tiết thực đơn và dinh dưỡng:

+ Mỗi món ăn được quản lý chi tiết gồm: Tên món, đơn giá niêm yết (VNĐ), mô tả hương vị, ảnh minh họa.

+ Lượng năng lượng Calo (`calories` Kcal) phục vụ theo dõi chế độ dinh dưỡng.

+ Định mức độ cay (`spicy_level`), phân loại bữa ăn (`meal_types`: Sáng, Trưa, Tối, Ăn vặt).

+ Danh sách nguyên liệu chế biến (`ingredients`) và cảnh báo dị ứng (`allergens`) để hệ thống tự động cảnh báo cho người dùng.

b) Yêu cầu về phi chức năng (Non-Functional Requirements):

- Hiệu năng hệ thống (Performance):

+ Thời gian đáp ứng của các API truy vấn không gian phức tạp (`ST_Distance`, `ST_DWithin`) phải đạt mức dưới 200ms trong điều kiện chịu tải thông thường.

+ Ứng dụng di động Flutter duy trì tốc độ khung hình mượt mà 60fps; giao diện bản đồ tối ưu hóa hiển thị marker bằng kỹ thuật Viewport Culling và gom cụm ẩm thực theo mức độ chi tiết (LOD - Level of Detail).

- Tính tương thích và Khả năng mở rộng (Compatibility & Scalability):

+ Ứng dụng di động biên dịch và chạy đồng bộ trên Android, iOS và trình duyệt Web Responsive.

+ Cổng quản trị Web Admin hiển thị hoàn hảo trên các độ phân giải màn hình từ Desktop (1920x1080) đến Laptop (1366x768) và máy tính bảng Tablet.

+ Kiến trúc Backend phân tầng tách bạch, dễ dàng mở rộng thêm các thuật toán gợi ý Machine Learning hoặc kết nối thêm các cổng thanh toán trong tương lai.

- Tính bảo mật và Toàn vẹn dữ liệu (Security & Data Integrity):

+ Mật khẩu người dùng được băm an toàn bằng thuật toán chuẩn công nghiệp (PBKDF2-HMAC-SHA256 kết hợp muối salt ngẫu nhiên).

+ Tách biệt hoàn toàn bảng dữ liệu giữa các vai trò `users` và `admins`, bảo vệ chống lại các lỗ hổng nâng quyền (Privilege Escalation).

+ Toàn bộ các thao tác chỉnh sửa dữ liệu CSDL được thực thi qua giao dịch an toàn (ACID Transactions) với cơ chế bẫy lỗi và rollback tự động.

- Tính tự động hóa và Độ tin cậy (Automation & Reliability):

+ Cung cấp script tự động hóa 1-click trên hệ điều hành Windows (`CAI_DAT.bat`, `setup.ps1`), tự động cấu hình môi trường Python 3.9, PostgreSQL 14, PostGIS 3.6.1, khởi tạo CSDL và tự động nạp dữ liệu mẫu (Auto-seed).

+ Độ bao phủ kiểm thử tự động đạt 100%: Bộ kiểm thử Pytest Backend với hơn 115 test cases thực thi trực tiếp trên CSDL PostgreSQL thật; kiểm thử Flutter Widget Test đạt 13/13 tests pass; kiểm thử tự động luồng giao diện E2E Flows bằng Playwright giám sát bảng điều khiển Console và mã lỗi HTTP Server.

## Phần 2: Tổng quan tình hình nghiên cứu trong và ngoài nước

### 2.1. Tình hình nghiên cứu trong nước

Tại thị trường Việt Nam trong khoảng một thập kỷ trở lại đây, làn sóng số hóa ngành F&B (Food and Beverage) đã diễn ra vô cùng sôi động với sự xuất hiện của nhiều nền tảng công nghệ lớn. Có thể chia các giải pháp hiện có trong nước thành 3 nhóm chính như sau:

1. Nhóm các ứng dụng thương mại điện tử giao đồ ăn trực tuyến (Food Delivery Platforms):

- Tiêu biểu gồm các ứng dụng như ShopeeFood (tiền thân là Now/DeliveryNow), GrabFood và BeFood. Các nền tảng này đã thành công lớn trong việc thay đổi thói quen mua sắm thực phẩm chế biến sẵn của người dân tại các đại đô thị.

- Ưu điểm: Sở hữu hạ tầng máy chủ mạnh mẽ, mạng lưới tài xế giao hàng đông đảo, phương thức thanh toán ví điện tử tích hợp phong phú và dữ liệu quán ăn rộng lớn.

- Hạn chế lớn đối với bài toán của đề tài:

+ Bản chất cốt lõi của các nền tảng này là phục vụ nhu cầu đặt món giao tận nhà, không hướng tới việc hỗ trợ người dùng tìm kiếm địa điểm và trải nghiệm ăn uống trực tiếp tại quán (Dine-in).

+ Thuật toán đề xuất món ăn và quán ăn bị thương mại hóa nặng nề, tập trung hiển thị các thương hiệu chi trả chi phí quảng cáo (Gian hàng tài trợ, Banner nổi bật) hoặc các chuỗi cửa hàng F&B lớn, tạo ra sự bất bình đẳng thông tin đối với các quán ăn bình dân, quán ăn truyền thống vừa và nhỏ.

+ Mức phí chiết khấu cao (20-30%) khiến người dùng phải chi trả mức giá đắt hơn từ 15% đến 25% so với giá bán trực tiếp tại cửa hàng, hoàn toàn không phù hợp với mức chi tiêu định kỳ của sinh viên.

2. Nhóm các trang tin tức, mạng xã hội và diễn đàn đánh giá ẩm thực (Food Review & Media):

- Tiêu biểu gồm Foody.vn, Địa Điểm Ăn Uống, Riviu, hay các hội nhóm cộng đồng ẩm thực trên mạng xã hội Facebook, TikTok.

- Ưu điểm: Cung cấp nhiều bài viết review chi tiết, hình ảnh sinh động và các bình luận đánh giá mang tính cộng đồng.

- Hạn chế:

+ Dữ liệu phần lớn mang tính phi cấu trúc (Unstructured Data), không được chuẩn hóa thành các trường thông tin cụ thể (như calo, mức độ cay, thành phần dị ứng, giờ đóng mở cửa thời gian thực).

+ Thiếu tích hợp bản đồ số tương tác chuyên sâu; người dùng chỉ có thể đọc bài viết đơn lẻ mà không thể lọc quán ăn theo bán kính di chuyển thực tế hoặc định vị vị trí hiện tại của bản thân.

+ Xuất hiện tràn lan các đánh giá giả mạo (Seeding, thuê review ảo), làm suy giảm độ tin cậy của thông tin đối với thực khách.

3. Nhóm các đề tài nghiên cứu học thuật về Hệ thống Thông tin Địa lý (WebGIS) trong nước:

- Tại các trường đại học lớn như Đại học Bách Khoa Hà Nội, Đại học Quốc gia Hà Nội hay Học viện Nông nghiệp Việt Nam, đã có một số công trình nghiên cứu ứng dụng GIS trong quản lý du lịch, quy hoạch điểm bán hàng hoặc giới thiệu danh lam thắng cảnh ẩm thực địa phương.

- Ưu điểm: Đã bước đầu ứng dụng được các công nghệ CSDL không gian như PostGIS và bản đồ số WebGIS để hiển thị các điểm dịch vụ (POI - Point of Interest).

- Hạn chế của các nghiên cứu trước đây:

+ Hầu hết chỉ dừng lại ở mô hình WebGIS truyền thống trên máy tính để bàn (Desktop Web), giao diện thao tác còn thô sơ, chưa xây dựng được ứng dụng di động chuyên biệt tối ưu cho người dùng cầm tay.

+ Cơ chế gợi ý còn rất đơn giản, chủ yếu dựa trên các bộ lọc thuộc tính tĩnh (lọc theo quận huyện, lọc theo loại món), chưa có sự kết hợp của mô hình gợi ý theo ngữ cảnh thời gian thực (CARS).

+ Hoàn toàn chưa tích hợp các yếu tố vi khí hậu (nhiệt độ, độ ẩm theo mùa) và hồ sơ sức khỏe y tế (chỉ số BMI, cảnh báo dị ứng) vào bài toán đề xuất món ăn.

### 2.2. Tình hình nghiên cứu ngoài nước

Trên bình diện quốc tế, bài toán gợi ý địa điểm và ẩm thực đã được các công ty công nghệ đa quốc gia cũng như các nhà khoa học máy tính nghiên cứu một cách bài bản từ nhiều năm nay:

1. Các nền tảng thương mại và dịch vụ bản đồ toàn cầu:

- Google Maps và Google Local Guides: Dịch vụ bản đồ số số 1 thế giới với độ bao phủ địa lý toàn cầu, hỗ trợ tìm kiếm địa điểm, chỉ đường chi tiết và chấm điểm đánh giá (Rating). Tuy nhiên, Google Maps là nền tảng bản đồ dùng chung (Generic Map), dữ liệu menu món ăn tại Việt Nam thường bị phân mảnh (dưới dạng ảnh chụp menu mờ, không tìm kiếm được bên trong), không hỗ trợ phân tích calo dinh dưỡng hoặc gợi ý món ăn theo hồ sơ sức khỏe cá nhân.

- Yelp, TripAdvisor và Foursquare: Các nền tảng đánh giá địa điểm du lịch, nhà hàng hàng đầu tại Bắc Mỹ và Châu Âu. Các dịch vụ này áp dụng triệt để thuật toán Lọc cộng tác (Collaborative Filtering) và Lọc theo nội dung (Content-based Filtering) dựa trên lịch sử check-in, đánh giá xếp hạng của hàng trăm triệu người dùng. Tuy nhiên, các hệ thống này chưa thích ứng với đặc thù quán ăn đường phố, vỉa hè tại Đông Nam Á và không có cơ chế liên kết thời tiết thời gian thực với đặc tính món ăn truyền thống.

2. Các hướng nghiên cứu học thuật chuyên sâu về Hệ thống gợi ý nhận biết ngữ cảnh (Context-Aware Recommender Systems - CARS):

- Nghiên cứu nền tảng của GS. Gediminas Adomavicius và GS. Alexander Tuzhilin (công bố trên IEEE Transactions on Knowledge and Data Engineering và Recommender Systems Handbook): Các tác giả đã chỉ ra giới hạn của mô hình gợi ý truyền thống 2 chiều (User x Item -> Rating) và thiết lập mô hình toán học đa chiều (User x Item x Context -> Rating). Trong đó, biến số 'Ngữ cảnh' (Context) đóng vai trò quyết định đến tính chính xác của đề xuất.

- Nghiên cứu về gợi ý ẩm thực theo thời tiết (Weather-Aware Food Recommendation): Các công trình khoa học của Ramirez et al. (IEEE Big Data) và các nghiên cứu tại Đại học Tokyo (Nhật Bản) đã chứng minh rằng các biến số khí tượng (nhiệt độ, độ ẩm, áp suất, mưa/tuyết) có mối tương quan sinh học và tâm lý học mật thiết với sự thèm ăn của con người. Nhiệt độ thấp kích thích nhu cầu tiêu thụ các món ăn giàu calo, nóng ấm, có nước dùng sốt; trong khi nhiệt độ và độ ẩm cao kích thích nhu cầu sử dụng các món thanh nhiệt, giải khát, giàu chất xơ.

- Nghiên cứu về gợi ý ẩm thực định hướng sức khỏe (Health-Aware & Dietary Food Recommendation): Các nghiên cứu của Trattner, Elsweiler (ACM RecSys) và Oliveira, Santos (ACM TOCHI) nhấn mạnh tầm quan trọng của việc tích hợp hồ sơ dinh dưỡng (chỉ số BMI, lượng calo khuyến nghị hàng ngày, cảnh báo dị ứng thực phẩm nghiêm trọng) vào hệ thống gợi ý để thúc đẩy thói quen ăn uống lành mạnh, phòng ngừa các bệnh tim mạch và béo phì.

3. Khoảng trống nghiên cứu (Research Gap):

- Mặc dù trên thế giới đã có nhiều công trình lý thuyết xuất sắc về CARS, nhưng việc hiện thực hóa một hệ sinh thái phần mềm hoàn chỉnh (Full-stack Ecosystem) tích hợp đồng thời: (1) Công nghệ CSDL không gian địa lý PostGIS với thuật toán tính khoảng cách chính xác; (2) Cơ chế suy diễn thời tiết đa mùa với 400 mẫu thời tiết khí hậu nhiệt đới gió mùa; (3) Hồ sơ thể trạng cá nhân hóa Onboarding BMI và cảnh báo dị ứng; (4) Vận hành trên kiến trúc hiện đại (FastAPI, Vue 3, Flutter) tối ưu riêng cho cộng đồng sinh viên ngoại thành tại Việt Nam - vẫn là một khoảng trống nghiên cứu thực nghiệm chưa có đề tài nào giải quyết trọn vẹn.

### 2.3. Nêu tên Đề tài và tính thời sự, tầm quan trọng của Đề tài

- Tên đề tài chính thức: 'Nghiên cứu, thiết kế và xây dựng Hệ thống gợi ý địa điểm ẩm thực thông minh dựa trên dữ liệu không gian địa lý (GIS/PostGIS), yếu tố thời tiết và hồ sơ cá nhân hóa người dùng'.

- Tên định danh thương hiệu hệ thống: PTC1 Food Platform (Hệ sinh thái nền tảng ẩm thực PTC1).

- Tính thời sự sâu sắc của Đề tài:

+ Đề tài bắt nhịp chính xác chủ trương Chuyển đổi số quốc gia của Chính phủ và Chiến lược phát triển kinh tế số, xã hội số, cụ thể hóa vào việc ứng dụng công nghệ thông tin phục vụ trực tiếp cho đời sống sinh hoạt của sinh viên và nhân dân.

+ Áp dụng toàn diện các công nghệ lập trình hiện đại nhất trong giai đoạn hiện nay: FastAPI (Python Framework bất đồng bộ dẫn đầu về hiệu năng), PostgreSQL 14 kết hợp PostGIS 3.6.1 (chuẩn công nghiệp xử lý không gian), Flutter SDK 3.44+ (công nghệ di động đa nền tảng tương lai của Google), Vue 3 Composition API kết hợp Vite và TypeScript, cùng hệ sinh thái bản đồ mở OpenStreetMap.

+ Giải quyết bài toán 'nóng' mang tính thường nhật tại khu vực Huyện Gia Lâm - địa bàn đang trong quá trình chuyển mình mạnh mẽ từ huyện nông nghiệp phát triển thành quận đô thị văn minh, tập trung lượng sinh viên ngoại tỉnh đông đảo.

- Tầm quan trọng của Đề tài:

+ Về mặt học thuật và đào tạo kỹ sư CNTT: Đề tài là công trình tổng kết toàn diện kiến thức của chương trình đào tạo kỹ sư Công nghệ thông tin; ứng dụng thực tế các môn học chuyên ngành cốt lõi: Cơ sở dữ liệu nâng cao, Hệ thống thông tin địa lý (GIS), Phân tích thiết kế hệ thống hướng đối tượng (OOAD), Lập trình thiết bị di động, Công nghệ phần mềm và Kiểm thử tự động.

+ Về mặt ứng dụng thực tiễn cho sinh viên: Cung cấp một công cụ miễn phí, tiện lợi, không quảng cáo rác, giúp sinh viên tra cứu quán ăn nhanh chóng, lựa chọn món ăn phù hợp với túi tiền, thể trạng và thời tiết, tiết kiệm thời gian và chi phí sinh hoạt.

+ Về mặt kinh tế - xã hội đối với địa phương: Hỗ trợ hơn 200 hộ kinh doanh quán ăn, nhà hàng bình dân trên địa bàn Thị trấn Trâu Quỳ và Huyện Gia Lâm tiếp cận kênh quảng bá số văn minh, minh bạch hóa chất lượng dịch vụ và giấy phép an toàn thực phẩm, góp phần nâng cao đời sống kinh tế địa phương.

## Phần 3: Nội dung và phương pháp nghiên cứu

### 3.1. Địa điểm và thời gian nghiên cứu (thực tập)

- Cơ quan chủ quản và địa điểm thực hiện đề tài: Khoa Công nghệ thông tin - Học viện Nông nghiệp Việt Nam (VNUA), Thị trấn Trâu Quỳ, Huyện Gia Lâm, Thành phố Hà Nội.

- Đơn vị phối hợp khảo sát thực địa: Các cơ sở kinh doanh dịch vụ ăn uống, nhà hàng, quán ăn, quán cà phê trên địa bàn Huyện Gia Lâm. Trọng tâm khảo sát tập trung tại các tuyến phố ẩm thực đông đúc sinh viên: đường Ngô Xuân Quảng, Đào Nguyên, An Đào, Cửu Việt, Chiến Thắng, Trâu Quỳ và khu đô thị Vinhomes Ocean Park lân cận.

- Thời gian nghiên cứu và thực tập: Dự kiến thực hiện trong vòng 15 tuần liên tục, từ ngày 01/09/2026 đến ngày 15/12/2026.

### 3.2. Nội dung nghiên cứu

Để đạt được các mục tiêu khoa học và hoàn thành các sản phẩm kỹ thuật đã cam kết, đề tài được cấu trúc thành 8 nội dung công việc (Work Packages) cụ thể và chặt chẽ như sau:

1. Nội dung 1: Khảo sát thực địa, thu thập và chuẩn hóa dữ liệu địa lý ẩm thực Huyện Gia Lâm:

- Tiến hành khảo sát thực địa tại các trục đường chính quanh Học viện Nông nghiệp Việt Nam.

- Thu thập tọa độ địa lý chính xác (Kinh độ, Vĩ độ theo chuẩn WGS84), tên quán, địa chỉ chi tiết, số điện thoại liên hệ, giờ mở cửa - đóng cửa thực tế, tình trạng giấy phép dịch vụ (ATTP, GPKD) của 204 quán ăn.

- Thu thập danh mục thực đơn của hơn 775 món ăn chi tiết: tên món, đơn giá niêm yết, định lượng năng lượng Calo (Kcal), cấp độ cay, loại bữa ăn phục vụ (Sáng, Trưa, Tối, Ăn vặt), danh sách nguyên liệu và các chất có nguy cơ gây dị ứng.

- Thực hiện làm sạch, loại bỏ trùng lặp và chuẩn hóa dữ liệu xuất thành các tệp tin SQL Dump (`database_dump.sql`) và JSON phục vụ tự động nạp CSDL.

2. Nội dung 2: Nghiên cứu lý thuyết CSDL không gian và thiết kế CSDL quan hệ kết hợp PostGIS:

- Nghiên cứu mô hình biểu diễn dữ liệu không gian OGC Simple Features, hệ quy chiếu tọa độ EPSG:4326 (WGS84) và cơ chế đánh chỉ mục không gian R-Tree / GiST Index.

- Thiết kế Sơ đồ thực thể liên kết (ERD) chuẩn hóa mức 3 (3NF) trên PostgreSQL 14 bao gồm các bảng cốt lõi: `users`, `admins`, `restaurants`, `categories`, `dishes`, `meal_types`, `weathers`, `weather_categories`, `favourite_dishes`, `option_users`.

- Thiết kế cột hình học không gian `restaurants.geom` thuộc kiểu `geography(Point, 4326)` cho phép thực hiện các phép toán khoảng cách trắc địa trực tiếp trên bề mặt ellipsoid của Trái Đất.

- Xây dựng Từ điển dữ liệu (Data Dictionary) chi tiết đặc tả từng trường thuộc tính, kiểu dữ liệu, khóa chính, khóa ngoại, ràng buộc CHECK và giá trị mặc định.

3. Nội dung 3: Nghiên cứu và xây dựng mô hình suy diễn gợi ý ẩm thực theo ngữ cảnh (CARS):

- Xây dựng module tích hợp OpenWeatherMap API để lấy các thông số khí tượng thời gian thực theo tọa độ địa lý.

- Xây dựng cơ chế fallback và chuẩn hóa bộ dữ liệu 400 mẫu thời tiết theo 4 mùa đặc trưng (Xuân, Hạ, Thu, Đông) tại miền Bắc Việt Nam, bổ sung đầy đủ dải nhiệt độ, điều kiện khí hậu, dải độ ẩm tối thiểu (`min_humidity`) và tối đa (`max_humidity`).

- Xây dựng ma trận luật liên kết giữa trạng thái thời tiết và danh mục món ăn phù hợp (`weather_categories`).

- Thiết lập thuật toán gợi ý đa tầng kết hợp: Lọc ngữ cảnh thời tiết -> Lọc ràng buộc sức khỏe hồ sơ Onboarding (loại bỏ món chứa chất dị ứng của người dùng, hạn chế món vượt quá độ cay cho phép) -> Xếp hạng ưu tiên theo mục tiêu dinh dưỡng BMI (Giảm cân, Tăng cơ, Duy trì).

4. Nội dung 4: Phân tích, thiết kế hệ thống phần mềm và thiết kế giao diện UI/UX:

- Áp dụng ngôn ngữ mô hình hóa thống nhất (UML) để xây dựng trọn bộ tài liệu thiết kế phần mềm: Biểu đồ Use Case tổng quan và phân rã chi tiết từng vai trò; Biểu đồ lớp (Class Diagram) đặc tả kiến trúc mã nguồn Backend; Biểu đồ tuần tự (Sequence Diagram) chi tiết cho các luồng nghiệp vụ cốt lõi (Xác thực, Khảo sát Onboarding, Tìm kiếm không gian, Gợi ý thời tiết).

- Thiết kế mẫu giao diện (Wireframe & High-fidelity Mockup) trên công cụ Figma cho cả Cổng Web Admin và Ứng dụng di động Flutter theo phong cách hiện đại, trực quan, tuân thủ nguyên tắc Material Design 3.

5. Nội dung 5: Xây dựng phân hệ Backend RESTful API với FastAPI:

- Hiện thực hóa kiến trúc phân tầng sạch (Clean Architecture): tầng Router/Controller (`server/app/api/`), tầng Nghiệp vụ Service (`server/app/services/`), tầng Dữ liệu Model/Schema (`server/app/models/`, `server/app/schemas/`), tầng Kết nối CSDL (`server/app/db/`).

- Lập trình module xác thực đa vai trò an toàn bằng mã băm PBKDF2/Bcrypt, cơ chế quản lý phiên Token cho người dùng và quản trị viên.

- Lập trình module xử lý không gian địa lý: hàm tính khoảng cách mặt cầu `ST_Distance` giữa vị trí người dùng và danh sách quán ăn; API Geocoding chuyển đổi địa chỉ; thuật toán giới hạn phạm vi bản đồ trong huyện Gia Lâm.

- Lập trình dịch vụ định vị qua IP mạng (Online IP Geolocation) an toàn qua Backend proxy.

- Tự động sinh tài liệu chuẩn hóa OpenAPI / Swagger UI phục vụ kiểm thử và kết nối client tại đường dẫn `/docs`.

6. Nội dung 6: Xây dựng Cổng quản trị Web Admin bằng Vue 3 và TypeScript:

- Khởi tạo dự án Web Frontend với Vite, Vue 3 (Composition API với `<script setup>`), TypeScript và Tailwind CSS / Modern CSS Tokens.

- Thiết kế cấu trúc các Tab quản trị nghiệp vụ chuyên biệt: Tab Tổng quan (Overview), Tab Quán ăn (Restaurants), Tab Thực đơn (Dishes), Tab Danh mục (Categories), Tab Người dùng (Users) với modal xác nhận xóa an toàn cascade, Tab Luật thời tiết (Weather Rules) tích hợp phân trang thông minh và lọc theo 4 mùa.

- Xây dựng component bảng dữ liệu dùng chung (`DataTable.vue`) với cơ chế phân trang thông minh hiển thị dấu ba chấm (`...`) khi số trang lớn, đảm bảo giao diện hiển thị gọn gàng, không bị vỡ bố cục.

7. Nội dung 7: Xây dựng Ứng dụng di động Mobile Client bằng Flutter SDK (Material 3):

- Xây dựng cấu trúc điều hướng đa tab (NavigationBar): Tab Khám phá (ExploreScreen), Tab Bản đồ (MapScreen), Tab Yêu thích (FavoritesScreen), Tab Tài khoản (ProfileScreen).

- Tích hợp bản đồ số OpenStreetMap thông qua thư viện `flutter_map` và `latlong2`, hiển thị hệ thống Marker trực quan (Marker vị trí người dùng, Marker quán ăn, Bottom Sheet xem nhanh thông tin).

- Lập trình Thẻ thời tiết động thích ứng theo thời gian ngày/đêm và mùa trong năm (`WeatherLandscapePainter`), hiển thị gợi ý món ăn tương ứng.

- Lập trình Bottom Sheet hiển thị thực đơn chi tiết kèm thông số Calo, độ cay ớt, nhãn bữa ăn và cảnh báo dị ứng.

- Hiện thực hóa hộp thoại khảo sát Onboarding Survey tự động đo lường chỉ số BMI và ghi nhận khẩu vị người dùng.

8. Nội dung 8: Thực hiện kiểm thử tự động đa tầng và xây dựng bộ đóng gói cài đặt 1-click:

- Viết và thực thi bộ kiểm thử tự động Pytest trên Backend với hơn 115 test cases trên PostgreSQL thật, kiểm tra toàn diện các hàm Service, API endpoints và migration schema.

- Viết bộ kiểm thử Flutter Widget Test (13 test cases) kiểm tra các trạng thái giao diện, luồng Auth Gate, chuyển tab và hiển thị dữ liệu.

- Xây dựng bộ kiểm thử giao diện E2E Flows bằng Playwright (`e2e_flows/`) tự động hóa kiểm tra tương tác người dùng, chụp ảnh màn hình nghiệm thu và giám sát lỗi Console/Server.

- Xây dựng các tệp kịch bản cài đặt tự động 1-click trên Windows (`CAI_DAT.bat`, `setup.ps1`, `CHAY_TAT_CA.bat`, `XUAT_DATABASE.bat`).

### 3.3. Phương pháp nghiên cứu

Để hiện thực hóa đầy đủ các nội dung nghiên cứu trên, đề tài áp dụng tổng hợp các phương pháp nghiên cứu khoa học và kỹ thuật công nghệ phần mềm tiên tiến sau:

1. Phương pháp nghiên cứu lý thuyết và tổng quan tài liệu:

- Thu thập, tổng hợp, phân tích và đánh giá các công trình nghiên cứu khoa học trong nước và quốc tế liên quan đến Hệ thống gợi ý nhận biết ngữ cảnh (CARS), Cơ sở dữ liệu không gian (Spatial Database) và Tiêu chuẩn thông tin địa lý quốc gia TCVN 12693:2020.

- Nghiên cứu các tài liệu kỹ thuật chuẩn mực (Technical Specifications) của các framework và nền tảng cốt lõi: FastAPI Documentation, PostGIS Manual, Flutter Engine Architecture, Vue 3 RFCs và OpenStreetMap API Guidelines.

2. Phương pháp khảo sát, điều tra thực địa và xử lý số liệu:

- Tiến hành điều tra, phỏng vấn trực tiếp các chủ cơ sở kinh doanh dịch vụ ăn uống và sinh viên tại khu vực Huyện Gia Lâm.

- Sử dụng thiết bị đo đạc GPS và dịch vụ OpenStreetMap Nominatim để đối soát tọa độ không gian chính xác.

- Áp dụng các kỹ thuật tiền xử lý dữ liệu (Data Preprocessing): làm sạch dữ liệu khuyết thiếu, chuẩn hóa định dạng số điện thoại, đơn giá, chuyển đổi các đơn vị đo lường (calo, độ cay, khoảng cách mét/km), chuẩn hóa chữ tiếng Việt có dấu và không dấu phục vụ tìm kiếm toàn văn (Full-text Search).

3. Phương pháp phân tích và thiết kế hệ thống hướng đối tượng (OOAD):

- Sử dụng Ngôn ngữ mô hình hóa thống nhất (UML 2.5) làm công cụ chuẩn mực để phân tích yêu cầu và đặc tả thiết kế:

+ Biểu đồ Use Case: Đặc tả các ca sử dụng của hệ thống phân chia theo 3 tác nhân chính (Guest, User, Admin).

+ Biểu đồ lớp (Class Diagram): Thiết kế cấu trúc các lớp thực thể (Entity Models), các lớp chuyển đổi dữ liệu (DTO / Schemas), các lớp dịch vụ nghiệp vụ (Services) và tầng điều khiển (API Routers).

+ Biểu đồ tuần tự (Sequence Diagram): Mô hình hóa thông điệp tương tác theo thời gian giữa Client, API Gateway, Service Layer, Spatial Engine và Database.

- Thiết kế Cơ sở dữ liệu quan hệ (ERD) tuân thủ chặt chẽ các dạng chuẩn hóa (1NF, 2NF, 3NF), đảm bảo tính toàn vẹn dữ liệu, triệt tiêu sự dư thừa thông tin và tối ưu hóa hiệu năng truy vấn.

4. Phương pháp tính toán và xử lý dữ liệu không gian địa lý (Spatial Computing):

- Áp dụng hệ tọa độ trắc địa toàn cầu WGS84 (EPSG:4326), biểu diễn vị trí địa lý của quán ăn dưới dạng đối tượng không gian Điểm: `GEOMETRY(Point, 4326)` hoặc `GEOGRAPHY(Point, 4326)`.

- Sử dụng công thức tính khoảng cách cung lớn trên mặt ellipsoid (Great-Circle Distance) thông qua hàm chuẩn hóa `ST_Distance(geom1, geom2)` của PostGIS, cho độ chính xác cao hơn vượt trội so với công thức xấp xỉ phẳng Pythagore.

- Áp dụng hàm `ST_DWithin` kết hợp chỉ mục không gian GiST (Generalized Search Tree) để lọc các quán ăn nằm trong bán kính phục vụ lân cận một cách tức thì mà không cần quét toàn bộ bảng (Full Table Scan).

- Trên ứng dụng di động Flutter: Ứng dụng thuật toán Cắt tỉa vùng nhìn (Viewport Culling) - chỉ render các marker quán ăn nằm trong khung nhìn hiển thị hiện tại của màn hình điện thoại, và thuật toán Gom cụm ẩm thực theo mức độ chi tiết (LOD - Level of Detail) giúp bản đồ không bị lag/giật khi hiển thị số lượng lớn quán ăn.

5. Phương pháp suy luận gợi ý dựa trên tri thức và luật ngữ cảnh (Knowledge-Based Contextual Rule Engine):

- Xây dựng tập luật suy diễn (Inference Rules) biểu diễn tri thức ẩm thực theo ngữ cảnh dưới dạng: IF <Điều kiện Khí hậu / Mùa> AND <Thông số Nhiệt độ / Độ ẩm> THEN <Gợi ý Danh mục Món ăn>.

- Thiết lập bộ quy tắc lọc ràng buộc thể trạng (Health Constraint Filtering):

+ Luật dị ứng: Loại bỏ hoàn toàn các món ăn có thuộc tính `allergens` giao thoa với danh sách `allergies` trong hồ sơ Onboarding của người dùng.

+ Luật độ cay: So khớp `dish.spicy_level` với ngưỡng `user.spicy_tolerance`, tự động gán nhãn cảnh báo nếu món ăn vượt quá sức chịu cay của thực khách.

+ Luật phân loại BMI: So khớp lượng calo của món ăn với thể trạng người dùng (người Thừa cân/Béo phì ưu tiên gợi ý món dưới 500 Kcal, thanh đạm, ít dầu mỡ; người Gầy ưu tiên món giàu đạm và năng lượng).

6. Phương pháp phát triển phần mềm linh hoạt (Agile / Scrum):

- Tổ chức tiến trình phát triển dự án theo mô hình Agile lặp và tăng trưởng (Iterative and Incremental Development), chia thời gian 15 tuần thành các Sprint ngắn hạn từ 1 đến 2 tuần.

- Mỗi Sprint tập trung hoàn thành một gói tính năng trọn gói có khả năng kiểm thử và chạy thực tế được (Working Software).

- Liên tục thực hiện việc kiểm tra hồi quy (Regression Testing) và tiếp nhận phản hồi để điều chỉnh kiến trúc kịp thời.

7. Phương pháp kiểm thử phần mềm tự động hóa toàn diện (Multi-tier Automated Testing):

- Tầng 1: Kiểm thử Backend với Pytest chạy trên môi trường CSDL PostgreSQL thật (không dùng mock DB giả lập), kiểm thử đầy đủ các trường hợp: Đường dẫn chuẩn (Happy Path), Giá trị biên (Edge Cases), Xử lý biệt lệ và ném lỗi (Exceptions/Rollback).

- Tầng 2: Kiểm thử Mobile với Flutter Widget Test, mô phỏng hành vi bấm nút, chuyển tab, mở modal và xác thực dữ liệu đầu vào.

- Tầng 3: Kiểm thử toàn trình End-to-End (E2E Testing) với Playwright, tự động khởi chạy trình duyệt Chromium, tương tác với giao diện Web Admin và Web Mobile, chụp ảnh màn hình nghiệm thu và ghi nhận lỗi Console/Network.

## Phần 4: Kế hoạch và dự kiến kết quả đạt được

### 4.1. Kế hoạch thực hiện đề tài theo thời gian là tuần

Tiến độ thực hiện đề tài được phân bổ khoa học và chặt chẽ trong tổng thời gian 15 tuần làm việc, với các mốc công việc chi tiết, sản phẩm bàn giao cụ thể và tiêu chí nghiệm thu rõ ràng như bảng tổng hợp dưới đây:

| Tuần | Nội dung công việc chi tiết | Sản phẩm / Kết quả bàn giao | Tiêu chí nghiệm thu | Người thực hiện |
| --- | --- | --- | --- | --- |
| Tuần 1 | Nhận đề tài, nghiên cứu tài liệu tổng quan trong và ngoài nước; khảo sát sơ bộ nhu cầu ẩm thực của sinh viên tại khu vực Huyện Gia Lâm. | Bản đề cương nghiên cứu chi tiết; Phiếu khảo sát nhu cầu người dùng; Tài liệu tổng quan lý thuyết. | Đề cương được Giảng viên hướng dẫn thông qua và phê duyệt. | Sinh viên |
| Tuần 2 | Tiến hành khảo sát thực địa tại các trục đường Ngô Xuân Quảng, Đào Nguyên, Cửu Việt; thu thập tọa độ GPS, thực đơn, giờ mở cửa của hơn 200 quán ăn. | Tập dữ liệu khảo sát thô danh sách quán ăn, thực đơn món ăn, danh mục, hình ảnh và giấy phép. | Thu thập đủ thông tin tối thiểu 200 quán ăn và 700 món ăn quanh HVNNVN. | Sinh viên |
| Tuần 3 | Làm sạch, chuẩn hóa dữ liệu; xây dựng bộ dữ liệu 400 mẫu thời tiết theo mùa; thiết kế mô hình CSDL quan hệ kết hợp PostGIS (ERD, Data Dictionary). | Tệp CSDL chuẩn hóa (SQL dump / JSON); Sơ đồ thực thể liên kết ERD chuẩn 3NF; Bản từ điển dữ liệu. | Mô hình ERD đáp ứng đầy đủ ràng buộc khóa ngoại, kiểu Geography Point và không trùng lặp. | Sinh viên |
| Tuần 4 | Phân tích và thiết kế hệ thống phần mềm hướng đối tượng (OOAD): xây dựng biểu đồ Use Case, Sequence Diagram, Class Diagram; thiết kế UI/UX trên Figma. | Tập tài liệu đặc tả thiết kế phần mềm UML; Bộ bản vẽ mẫu giao diện Figma Web Admin & Mobile App. | Tài liệu UML mô tả đủ 100% luồng nghiệp vụ; Giao diện Figma trực quan, chuẩn Material 3. | Sinh viên |
| Tuần 5 | Khởi tạo cấu trúc dự án Monorepo; thiết lập môi trường Backend FastAPI, PostgreSQL 14, PostGIS 3.6.1; viết script tự động hóa cài đặt môi trường 1-click. | Cấu trúc thư mục Monorepo chuẩn; Script setup.ps1 và CAI_DAT.bat hoạt động; DB kết nối thành công. | Chạy 1-click cài đặt thành công môi trường Python, PostgreSQL, PostGIS trên máy mới. | Sinh viên |
| Tuần 6 | Lập trình Backend: Module xác thực người dùng (User / Admin / Guest), băm mật khẩu PBKDF2; Module hồ sơ thể chất Onboarding & tự động tính chỉ số BMI. | Các API /auth và /users hoạt động ổn định; Viết bộ test kiểm thử Pytest xác thực và Onboarding. | Pytest vượt qua 100% test cases xác thực, tính đúng phân loại thể trạng BMI. | Sinh viên |
| Tuần 7 | Lập trình Backend: Module xử lý không gian địa lý PostGIS; API tính khoảng cách mặt cầu ST_Distance; API Geocoding OpenStreetMap Nominatim; API định vị IP. | Các API /restaurants/spatial, /geocoding, /location hoạt động; Tích hợp ranh giới huyện Gia Lâm. | Truy vấn khoảng cách trả về chính xác trong thời gian < 200ms; Geocoding trả về tọa độ chuẩn. | Sinh viên |
| Tuần 8 | Lập trình Backend: Module Thời tiết; tích hợp OpenWeatherMap API; cơ chế nạp tự động 400 mẫu thời tiết theo mùa; thuật toán gợi ý món ăn theo ngữ cảnh CARS. | API /weather, /recommendations/contextual; Hệ thống luật ánh xạ thời tiết và danh mục món ăn. | Gợi ý chính xác danh mục theo nhiệt độ/độ ẩm/mùa; lọc trừ chính xác các chất dị ứng. | Sinh viên |
| Tuần 9 | Xây dựng Cổng quản trị Web Admin bằng Vue 3 + TypeScript: Bảng điều khiển Overview; Quản lý CRUD Quán ăn (Restaurants) và Thực đơn món ăn (Dishes). | Giao diện Web Admin tab Overview, Restaurants, Dishes; Kết nối API Backend bất đồng bộ. | Admin thực hiện thêm, sửa, xóa, tìm kiếm quán ăn và món ăn mượt mà, không lỗi console. | Sinh viên |
| Tuần 10 | Hoàn thiện Web Admin: Tab Quản lý người dùng (xóa an toàn cascade); Tab Luật thời tiết (Weather Rules) phân trang thông minh và lọc theo 4 mùa; Modal xác nhận. | Mã nguồn Web Admin hoàn chỉnh; Component DataTable.vue phân trang thông minh; Build Vite không lỗi. | Build kiểm thử `npm run build` thành công 100% với 0 cảnh báo lỗi TypeScript. | Sinh viên |
| Tuần 11 | Xây dựng Ứng dụng di động Flutter (Material 3): Màn hình khởi chạy, điều hướng NavigationBar; Tích hợp bản đồ OpenStreetMap (flutter_map); Hiển thị marker quán ăn. | Ứng dụng Flutter hiển thị bản đồ số mượt mà, định vị chấm xanh vị trí người dùng, marker ghim quán. | Bản đồ tương tác zoom/pan đạt 60fps; Marker quán ăn hiển thị chuẩn xác theo tọa độ CSDL. | Sinh viên |
| Tuần 12 | Hoàn thiện Ứng dụng di động Flutter: Màn hình Khám phá (ExploreScreen); Thẻ thời tiết động theo mùa; Hộp thoại Onboarding Survey; Bottom Sheet menu calo/dị ứng. | Ứng dụng Flutter Mobile hoàn chỉnh chạy mượt mà trên Android, iOS và Web; Bộ Widget tests. | Flutter widget tests vượt qua 13/13 tests; Giao diện đáp ứng mượt mà, không giật lag. | Sinh viên |
| Tuần 13 | Xây dựng bộ kiểm thử giao diện tự động E2E Flows bằng Playwright; kiểm thử tải hiệu năng API; kiểm thử bảo mật phân quyền và bẫy lỗi hệ thống. | Bộ kịch bản kiểm thử e2e_flows; Báo cáo nghiệm thu kiểm thử (Test Summary Report); File ảnh chụp màn hình. | Kịch bản E2E chạy tự động thành công 100%, ghi nhận 0 lỗi console và 0 lỗi HTTP 500 server. | Sinh viên |
| Tuần 14 | Tối ưu hóa hiệu năng toàn diện (chỉ mục CSDL, cache, nén bundle Web); hoàn thiện các launcher 1-click (CHAY_TAT_CA.bat, CHAY_SERVER.bat, XUAT_DATABASE.bat). | Bộ sản phẩm đóng gói hoàn chỉnh; Các file batch khởi chạy 1-click; Tài liệu hướng dẫn sử dụng README.md. | Khởi động toàn bộ hệ thống (Server, Web, Mobile) chỉ bằng 1 thao tác click đúp chuột. | Sinh viên |
| Tuần 15 | Viết báo cáo tổng kết Khóa luận tốt nghiệp; hoàn thiện tài liệu kỹ thuật, slide thuyết trình; chuẩn bị video demo sản phẩm và bảo vệ trước Hội đồng chấm. | Quyển báo cáo khóa luận tốt nghiệp hoàn chỉnh; Slide thuyết trình PowerPoint; Video demo hệ thống. | Báo cáo được Giảng viên hướng dẫn duyệt đạt yêu cầu bảo vệ trước Hội đồng chấm tốt nghiệp. | Sinh viên + GVHD |


### 4.2. Dự kiến kết quả chính sẽ đạt được

Sau 15 tuần nghiên cứu, thiết kế và phát triển thực nghiệm, đề tài cam kết mang lại các kết quả đầu ra toàn diện, cụ thể và có tính ứng dụng cao trên cả phương diện học thuật lý thuyết lẫn sản phẩm phần mềm thực tế:

1. Về mặt học thuật và tài liệu báo cáo khoa học:

- Một quyển Báo cáo Khóa luận tốt nghiệp đại học hoàn chỉnh (dày từ 80 đến 120 trang), trình bày chuẩn mực theo quy định học thuật của Học viện Nông nghiệp Việt Nam, bao gồm đầy đủ cơ sở lý luận, tổng quan nghiên cứu, phương pháp luận, phân tích thiết kế hệ thống và đánh giá thực nghiệm.

- Bộ hồ sơ tài liệu thiết kế phần mềm chi tiết (Software Architecture & Design Documents) bao gồm:

+ Bản Từ điển dữ liệu (Data Dictionary) và Sơ đồ thực thể liên kết (ERD) chuẩn hóa mức 3 (3NF).

+ Bộ biểu đồ mô hình hóa UML 2.5: Biểu đồ Use Case tổng thể và phân rã, Biểu đồ lớp (Class Diagram) đa tầng, Biểu đồ tuần tự (Sequence Diagram) cho các ca nghiệp vụ chính.

+ Bộ tài liệu đặc tả kiểm thử phần mềm (Test Cases Specification) bao gồm hơn 100 kịch bản kiểm thử đơn vị, kiểm thử tích hợp và kiểm thử giao diện người dùng E2E.

2. Về mặt sản phẩm phần mềm (Hệ sinh thái PTC1 Food Platform hoàn chỉnh):

- Phân hệ Backend RESTful API (FastAPI 0.128+ & Python 3.9):

+ Hoạt động bất đồng bộ với hiệu năng cao, thời gian xử lý truy vấn không gian trung bình dưới 200ms.

+ Tích hợp đầy đủ các API xác thực token an toàn, quản lý hồ sơ Onboarding BMI, truy vấn không gian PostGIS (`ST_Distance`), Geocoding và dịch vụ định vị qua IP mạng an toàn.

+ Tích hợp tài liệu hóa tự động tương tác trực tiếp qua OpenAPI Swagger UI tại địa chỉ `http://localhost:8001/docs`.

- Cơ sở dữ liệu chuẩn hóa PostgreSQL 14 tích hợp PostGIS 3.6.1:

+ Lưu trữ đầy đủ bộ dữ liệu thực tế đã được chuẩn hóa của 204 cơ sở ẩm thực trên địa bàn Huyện Gia Lâm và hơn 775 món ăn chi tiết (đơn giá, calo, độ cay, thành phần, cảnh báo dị ứng).

+ Tích hợp bộ dữ liệu chuẩn 400 mẫu thời tiết theo 4 mùa (Xuân, Hạ, Thu, Đông) bao gồm nhiệt độ, điều kiện khí hậu và dải độ ẩm chuẩn xác (`min_humidity`, `max_humidity`).

- Phân hệ Cổng quản trị Web Admin (Vue 3, Vite & TypeScript):

+ Giao diện hiện đại, tối ưu hóa trải nghiệm người dùng với các tab nghiệp vụ: Bảng điều khiển tổng quan, Quản lý Quán ăn, Quản lý Thực đơn, Quản lý Danh mục, Quản lý Người dùng (xóa an toàn cascade) và Quản lý Luật thời tiết (phân trang thông minh với dấu ba chấm, bộ lọc theo mùa).

+ Đảm bảo kiểm tra kiểu tĩnh nghiêm ngặt (Strict TypeScript), build đóng gói thành công 100% không cảnh báo lỗi.

- Phân hệ Ứng dụng di động Mobile Client (Flutter SDK & Material 3):

+ Chạy mượt mà, đồng bộ trên cả hệ điều hành Android, iOS và trình duyệt Web Responsive.

+ Tích hợp bản đồ số OpenStreetMap tương tác trực quan, hiển thị hệ thống Marker quán ăn, vị trí người dùng và Bottom Sheet thực đơn calo chi tiết.

+ Thẻ thời tiết thích ứng sinh động theo thời gian ngày/đêm và mùa trong năm; Hộp thoại Onboarding khảo sát thể trạng và tự động tính toán chỉ số BMI.

- Bộ công cụ tự động hóa và đóng gói triển khai 1-click trên Windows:

+ File `setup.ps1` và `CAI_DAT.bat`: Tự động cài đặt toàn bộ môi trường từ con số 0 trong vòng chưa đầy 5 phút.

+ File `CHAY_TAT_CA.bat`: Khởi chạy đồng thời 1-click toàn bộ 3 phân hệ Backend, Web Admin và Flutter Mobile.

+ File `XUAT_DATABASE.bat`: Trích xuất tức thời toàn bộ dữ liệu CSDL mới nhất thành file SQL dump.

- Chỉ số chất lượng và độ tin cậy kiểm thử:

+ Toàn bộ 117/117 Pytest backend cases passed (100%) trên CSDL PostgreSQL thật.

+ Toàn bộ 13/13 Flutter widget tests passed (100%).

+ Bộ kiểm thử Playwright E2E UI Flow suite thực thi tự động, ghi nhận 0 lỗi console và 0 lỗi sập máy chủ.

## Phần 5: Tài liệu tham khảo

### 5.1. Chi tiết các tài liệu tham khảo (dự kiến)

Danh mục các tài liệu khoa học, giáo trình đại học, tiêu chuẩn kỹ thuật quốc gia và tài liệu công nghệ chuyên ngành dự kiến được sử dụng trong quá trình xây dựng đề cương và thực hiện khóa luận tốt nghiệp:

[1] Tiêu Chuẩn Quốc Gia TCVN 12693:2020 (2020), Công nghệ thông tin - Hệ thống thông tin địa lý (GIS) - Yêu cầu kỹ thuật đối với cơ sở dữ liệu không gian, Bộ Khoa học và Công nghệ, Hà Nội.

[2] Nguyễn Trọng Hòa, Đỗ Thị Lan (2022), Giáo trình Cơ sở dữ liệu không gian và Công nghệ GIS, Nhà xuất bản Đại học Quốc gia Hà Nội, Hà Nội.

[3] Đặng Văn Đức (2018), Hệ thống Thông tin Địa lý (GIS) - Các khái niệm và nguyên lý cơ bản, Nhà xuất bản Khoa học và Kỹ thuật, Hà Nội.

[4] Đoàn Văn Ban (2019), Giáo trình Công nghệ phần mềm và Phân tích thiết kế hướng đối tượng bằng UML, Nhà xuất bản Đại học Quốc gia Hà Nội, Hà Nội.

[5] Regina O. Obe, Leo S. Hsu (2021), PostGIS in Action (3rd Edition), Manning Publications, New York, ISBN: 978-1617296697.

[6] Gediminas Adomavicius, Alexander Tuzhilin (2015), 'Context-Aware Recommender Systems', in Francesco Ricci et al. (eds), Recommender Systems Handbook, Springer, Boston, MA, pp. 191-226, DOI: 10.1007/978-1-4899-7637-6_6.

[7] Tiago Ramirez, Pedro Brandao, Rui Camacho (2020), 'Weather-Aware Recommendation Engine for Tourism and Gastronomy Services', Proceedings of the IEEE International Conference on Big Data (IEEE BigData 2020), Atlanta, GA, USA, pp. 1120-1127.

[8] Tiago Oliveira, Marco Santos, Rui Neves-Silva (2023), 'Evaluating Mobile Context-Aware Food Recommenders Based on Physical Health Profiles and Nutritional Needs', ACM Transactions on Computer-Human Interaction (TOCHI), Vol. 30, No. 4, pp. 1-28, DOI: 10.1145/3582431.

[9] Christoph Trattner, David Elsweiler (2017), 'Food Recommender Systems: Important Studies, Recommendation Strategies, and Open Challenges', ACM Computing Surveys, Vol. 50, No. 5, Article 75, pp. 1-34.

[10] Sebastián Ramírez (2024), FastAPI: Modern, Fast (High-Performance) Web Framework for Building APIs with Python 3.9+, Official Documentation, truy cập tại: https://fastapi.tiangolo.com/.

[11] Google LLC (2024), Flutter Documentation - Multi-platform UI Toolkit from a Single Codebase, truy cập tại: https://docs.flutter.dev/.

[12] Evan You, et al. (2024), Vue.js 3 - The Progressive JavaScript Framework Documentation, truy cập tại: https://vuejs.org/.

[13] The PostgreSQL Global Development Group (2024), PostgreSQL 14.x Documentation: Object-Relational Database Management System, truy cập tại: https://www.postgresql.org/docs/14/.

[14] OpenStreetMap Foundation (2024), OpenStreetMap Collaborative Geospatial Data and Nominatim Search API, truy cập tại: https://wiki.openstreetmap.org/.
