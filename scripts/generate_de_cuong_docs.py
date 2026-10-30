# -*- coding: utf-8 -*-
"""
Script tự động sinh tài liệu Đề cương nghiên cứu / Khóa luận tốt nghiệp (Markdown và Word .docx)
cho hệ thống PTC1 Food Platform theo đúng cấu trúc chuẩn 5 phần trong đề tài.
"""
import os
import docx
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_ALIGN_VERTICAL
from docx.oxml import OxmlElement, parse_xml
from docx.oxml.ns import nsdecls, qn

DOCS_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "docs"))
MD_PATH = os.path.join(DOCS_DIR, "de-cuong-nghien-cuu.md")
DOCX_PATH = os.path.join(DOCS_DIR, "De_Cuong_Nghien_Cuu_PTC1.docx")

# -------------------------------------------------------------
# 1. NỘI DUNG TÀI LIỆU CHI TIẾT (CHUẨN 5 PHẦN)
# -------------------------------------------------------------

TITLE = "ĐỀ CƯƠNG BÁO CÁO THỰC TẬP TỐT NGHIỆP / KHÓA LUẬN TỐT NGHIỆP"
SUBTITLE = "ĐỀ TÀI: NGHIÊN CỨU, THIẾT KẾ VÀ XÂY DỰNG HỆ THỐNG GỢI Ý ĐỊA ĐIỂM ẨM THỰC THÔNG MINH DỰA TRÊN DỮ LIỆU KHÔNG GIAN ĐỊA LÝ (GIS/POSTGIS), YẾU TỐ THỜI TIẾT VÀ HỒ SƠ CÁ NHÂN HÓA NGƯỜI DÙNG"

CONTENT_SECTIONS = [
    {
        "part_title": "Phần 1: Mở đầu",
        "sections": [
            {
                "title": "1.1. Đặt vấn đề",
                "paragraphs": [
                    "Ẩm thực luôn là một phần thiết yếu trong đời sống hàng ngày của mỗi con người. Đặc biệt tại các khu đô thị vệ tinh tập trung đông đảo sinh viên, cán bộ, giảng viên như khu vực Huyện Gia Lâm (nơi đặt trụ sở Học viện Nông nghiệp Việt Nam - VNUA), nhu cầu tìm kiếm quán ăn ngon, sạch, giá cả sinh viên và khoảng cách di chuyển phù hợp luôn là vấn đề cấp bách diễn ra mỗi ngày.",
                    "Hiện nay, mặc dù các nền tảng thương mại điện tử ẩm thực như ShopeeFood hay GrabFood đã rất phổ biến, nhưng các hệ thống này chủ yếu tập trung vào nghiệp vụ đặt món trực tuyến giao tận nơi (Food Delivery) với mức chiết khấu hoa hồng cao (thường từ 20% đến 30%), khiến nhiều quán ăn bình dân, quán cơm sinh viên không thể tham gia hoặc phải tăng giá món ăn. Hơn nữa, thuật toán đề xuất của các ứng dụng này chủ yếu dựa trên quảng cáo tài trợ và tần suất đơn hàng tổng thể, chưa gắn liền với ngữ cảnh thực tế của người dùng: thời tiết tức thời (trời mưa lạnh nên ăn lẩu, đồ nóng sốt; trời nắng gắt nên chọn món nước mát, chè, salad), thể trạng sức khỏe (chỉ số BMI, cảnh báo dị ứng thực phẩm, hạn chế độ cay) và mức ngân sách sinh viên chi trả trực tiếp tại quán.",
                    "Mặt khác, công nghệ thông tin và truyền thông ngày nay đang phát triển vượt bậc, đặc biệt là công nghệ Hệ thống Thông tin Địa lý (GIS) với các tiện ích mở rộng không gian mạnh mẽ như PostgreSQL/PostGIS, dịch vụ bản đồ số mã nguồn mở OpenStreetMap, cùng sự bùng nổ của các nền tảng lập trình hiện đại như FastAPI (Python) và Flutter SDK (đa nền tảng Mobile & Web). Việc kết hợp công nghệ không gian địa lý với mô hình phân tích thời tiết và hồ sơ người dùng mở ra giải pháp tối ưu cho bài toán gợi ý ẩm thực thực tế.",
                    "Xuất phát từ thực tiễn trên, việc thực hiện đề tài \"Nghiên cứu, thiết kế và xây dựng Hệ thống gợi ý địa điểm ẩm thực thông minh dựa trên dữ liệu không gian địa lý (GIS/PostGIS), yếu tố thời tiết và hồ sơ cá nhân hóa người dùng\" (Hệ sinh thái PTC1) là vô cùng cần thiết và có giá trị ứng dụng thực tiễn cao."
                ]
            },
            {
                "title": "1.2. Mục đích và yêu cầu",
                "paragraphs": [],
                "subsections": [
                    {
                        "title": "1.2.1. Mục đích",
                        "paragraphs": [
                            "- Về mặt học thuật: Nghiên cứu chuyên sâu về các mô hình hệ thống gợi ý theo ngữ cảnh (Context-Aware Recommendation Systems), kỹ thuật xử lý và truy vấn dữ liệu không gian địa lý (Spatial Query) trên hệ quản trị CSDL PostgreSQL kết hợp PostGIS, và quy trình xây dựng ứng dụng di động đa nền tảng hiện đại.",
                            "- Về mặt ứng dụng: Thiết kế và triển khai hoàn chỉnh một hệ sinh thái phần mềm gồm Backend RESTful API, Web Admin Dashboard và Ứng dụng di động (Mobile App) phục vụ thực khách (đặc biệt là sinh viên Học viện Nông nghiệp Việt Nam) tìm kiếm, định vị và nhận gợi ý ẩm thực thông minh theo thời tiết và thể trạng cá nhân.",
                            "- Về mặt xã hội: Kết nối thực khách với hơn 200 địa điểm ẩm thực truyền thống, quán ăn bình dân tại khu vực Huyện Gia Lâm, góp phần thúc đẩy kinh tế số địa phương và nâng cao trải nghiệm sinh hoạt của sinh viên."
                        ]
                    },
                    {
                        "title": "1.2.2. Yêu cầu",
                        "paragraphs": [
                            "Đề tài cần đáp ứng đầy đủ các yêu cầu cốt lõi sau:",
                            "a) Yêu cầu chức năng:",
                            "+ Phân quyền người dùng đa cấp độ: Quản lý 3 nhóm đối tượng: Khách vãng lai (Guest - tra cứu bản đồ, thực đơn tự do không bắt buộc đăng nhập), Người dùng thành viên (User - lưu hồ sơ thể chất Onboarding, món ăn yêu thích, tùy chọn ẩn danh mục) và Quản trị viên (Admin - kiểm soát toàn bộ dữ liệu, quán ăn, thực đơn, phân quyền và quy tắc thời tiết).",
                            "+ Khảo sát Onboarding & Quản lý hồ sơ sức khỏe: Tự động tính chỉ số BMI từ chiều cao/cân nặng, phân loại thể trạng, ghi nhận mục tiêu dinh dưỡng, độ cay, ngân sách, chế độ ăn kiêng và cảnh báo dị ứng thực phẩm.",
                            "+ Gợi ý ẩm thực theo thời tiết & theo mùa: Tự động đồng bộ thời tiết tức thời từ OpenWeatherMap API hoặc truy xuất thông minh từ bộ dữ liệu 400 mẫu thời tiết theo mùa (Xuân, Hạ, Thu, Đông) để gợi ý danh mục món ăn tương thích nhất.",
                            "+ Bản đồ tương tác & Định vị không gian: Tích hợp bản đồ OpenStreetMap mượt mà, định vị người dùng thông minh qua IP mạng (không ép buộc quyền GPS phần cứng), chuyển đổi địa chỉ (Geocoding), tính khoảng cách cầu chính xác tới từng quán ăn và giới hạn phạm vi hiển thị chuẩn xác trong địa bàn Huyện Gia Lâm.",
                            "+ Cổng quản trị Web Admin: Bảng điều khiển trực quan hỗ trợ CRUD Quán ăn, Món ăn, Danh mục, Người dùng (kèm xác nhận xóa an toàn) và Quy tắc gợi ý Thời tiết (phân trang, lọc theo mùa).",
                            "b) Yêu cầu phi chức năng:",
                            "+ Hiệu năng hệ thống: Thời gian phản hồi API trung bình dưới 200ms cho các truy vấn không gian phức tạp (`ST_Distance`, `ST_DWithin`); ứng dụng Mobile hoạt động mượt mà đạt tốc độ khung hình 60fps.",
                            "+ Tính khả dụng & Tự động hóa: Cung cấp kịch bản cài đặt tự động 1-click trên hệ điều hành Windows (`CAI_DAT.bat`, `setup.ps1`) tự động cấu hình từ A-Z môi trường Python, PostgreSQL, PostGIS, nạp sẵn CSDL thực tế.",
                            "+ Độ tin cậy & Kiểm thử: Toàn bộ mã nguồn phải vượt qua 100% các bộ kiểm thử tự động đa tầng (Backend Pytest với hơn 100 test cases trên PostgreSQL thật, Flutter widget test, Web TypeScript build và E2E UI flow test Playwright)."
                        ]
                    }
                ]
            }
        ]
    },
    {
        "part_title": "Phần 2: Tổng quan tình hình nghiên cứu trong và ngoài nước",
        "sections": [
            {
                "title": "2.1. Tình hình nghiên cứu trong nước",
                "paragraphs": [
                    "Tại Việt Nam, các ứng dụng công nghệ phục vụ nhu cầu ăn uống chủ yếu phát triển mạnh ở mảng đặt đồ ăn trực tuyến (Food Delivery) với các tên tuổi lớn như GrabFood, ShopeeFood, Baemin (trước khi rút khỏi thị trường). Các nền tảng này sở hữu hạ tầng công nghệ và dữ liệu khổng lồ, tuy nhiên mục tiêu kinh doanh hướng tới doanh thu đặt món và phí dịch vụ giao hàng, dẫn đến thuật toán gợi ý tập trung quảng bá các đối tác thương mại trả phí thay vì tối ưu hóa trải nghiệm ăn uống tại chỗ hoặc gợi ý theo ngữ cảnh khí hậu.",
                    "Về khía cạnh học thuật, một số đề tài nghiên cứu tại các trường đại học đã bước đầu tiếp cận bài toán xây dựng WebGIS quản lý quán ăn, du lịch ẩm thực tại một số tỉnh thành (như Hà Nội, Đà Nẵng, TP. Hồ Chí Minh). Tuy nhiên, hầu hết các hệ thống này chỉ dừng lại ở dạng bản đồ số hiển thị tĩnh, giao diện Web truyền thống, chưa xây dựng ứng dụng di động chuyên biệt cho người dùng cuối. Đặc biệt, việc tích hợp thời gian thực các yếu tố khí tượng (nhiệt độ, mưa, gió, mùa) và hồ sơ sức khỏe cá nhân (BMI, dị ứng) vào bài toán gợi ý món ăn gần như chưa được khai thác toàn diện tại thị trường Việt Nam."
                ]
            },
            {
                "title": "2.2. Tình hình nghiên cứu ngoài nước",
                "paragraphs": [
                    "Trên thế giới, các nền tảng tra cứu địa điểm và ẩm thực nổi tiếng như Yelp, TripAdvisor, Foursquare hay Google Maps đã đạt đến mức độ hoàn thiện rất cao về dữ liệu và công nghệ bản đồ. Các dịch vụ này ứng dụng các thuật toán gợi ý tiên tiến (Collaborative Filtering, Content-based Filtering) dựa trên lịch sử đánh giá, check-in của cộng đồng người dùng toàn cầu.",
                    "Bên cạnh các sản phẩm thương mại, hướng nghiên cứu Hệ thống gợi ý nhận biết ngữ cảnh (Context-Aware Recommendation Systems - CARS) là một chủ đề học thuật được quan tâm rộng rãi trong các hội nghị quốc tế hàng đầu như ACM RecSys, IEEE ICDE. Các nhà khoa học đã chứng minh rằng việc đưa các chiều ngữ cảnh thời gian thực (Spatial - Không gian, Temporal - Thời gian, Weather - Khí tượng, Nutritional - Dinh dưỡng) vào mô hình gợi ý giúp tăng độ hài lòng của người dùng lên đáng kể so với các hệ thống truyền thống chỉ dựa trên ma trận người dùng - sản phẩm.",
                    "Tuy nhiên, việc triển khai các mô hình lý thuyết này vào một hệ thống phần mềm hoàn chỉnh, thích ứng linh hoạt với đặc thù văn hóa ẩm thực châu Á, địa lý đường phố phức tạp và điều kiện khí hậu nhiệt đới gió mùa tại Việt Nam vẫn đòi hỏi một giải pháp kiến trúc phần mềm thực nghiệm chuyên sâu."
                ]
            },
            {
                "title": "2.3. Nêu tên Đề tài và tính thời sự, tầm quan trọng của Đề tài",
                "paragraphs": [
                    "- Tên đề tài chính thức: \"Nghiên cứu, thiết kế và xây dựng Hệ thống gợi ý địa điểm ẩm thực thông minh dựa trên dữ liệu không gian địa lý (GIS/PostGIS), yếu tố thời tiết và hồ sơ cá nhân hóa người dùng\" (Tên thương hiệu hệ thống: PTC1 Food Platform).",
                    "- Tính thời sự của đề tài:",
                    "+ Đề tài bắt kịp xu thế chuyển đổi số mạnh mẽ trong dịch vụ đời sống và ẩm thực đô thị hiện đại.",
                    "+ Áp dụng các công nghệ lập trình tiên tiến nhất hiện nay: FastAPI (Python Framework bất đồng bộ hiệu năng cao), PostgreSQL kết hợp extension không gian PostGIS chuẩn công nghiệp, Flutter SDK phát triển giao diện người dùng đa nền tảng (Material 3), Vue 3 Composition API kết hợp TypeScript và hệ sinh thái bản đồ mở OpenStreetMap.",
                    "+ Giải quyết nhu cầu thiết thực, thường nhật của sinh viên và cư dân sau giai đoạn bùng nổ đô thị hóa tại khu vực ngoại thành phía Đông Hà Nội.",
                    "- Tầm quan trọng của đề tài:",
                    "+ Về giá trị học tập và nghiên cứu: Cung cấp một mẫu kiến trúc phần mềm chuẩn mực (Monorepo tích hợp Backend, Web Admin, Mobile Client), ứng dụng thực tế các lý thuyết về CSDL không gian, thuật toán tính khoảng cách địa lý và quy trình kiểm thử tự động hóa toàn diện.",
                    "+ Về giá trị ứng dụng thực tiễn: Hệ thống có thể triển khai sử dụng ngay cho hơn 30.000 sinh viên, cán bộ tại Học viện Nông nghiệp Việt Nam và nhân dân Huyện Gia Lâm, góp phần hỗ trợ các hộ kinh doanh ẩm thực vừa và nhỏ quảng bá dịch vụ minh bạch, văn minh."
                ]
            }
        ]
    },
    {
        "part_title": "Phần 3: Nội dung và phương pháp nghiên cứu",
        "sections": [
            {
                "title": "3.1. Địa điểm và thời gian nghiên cứu (thực tập)",
                "paragraphs": [
                    "- Địa điểm nghiên cứu / thực tập: Khoa Công nghệ thông tin - Học viện Nông nghiệp Việt Nam (VNUA), Thị trấn Trâu Quỳ, Huyện Gia Lâm, Thành phố Hà Nội.",
                    "- Đơn vị phối hợp khảo sát: Các cơ sở kinh doanh dịch vụ ăn uống, nhà hàng, quán ăn trên địa bàn Huyện Gia Lâm (tập trung trọng điểm tại các trục đường Ngô Xuân Quảng, Đào Nguyên, An Đào, Cửu Việt, Trâu Quỳ).",
                    "- Thời gian nghiên cứu / thực tập dự kiến: 15 tuần (Từ ngày 01/09/2026 đến ngày 15/12/2026)."
                ]
            },
            {
                "title": "3.2. Nội dung nghiên cứu",
                "paragraphs": [
                    "Để hoàn thành mục tiêu đề ra, đề tài tập trung triển khai 8 nội dung công việc chủ yếu sau:",
                    "1. Nội dung 1: Khảo sát thực trạng, thu thập và chuẩn hóa dữ liệu địa lý của 204 quán ăn và hơn 775 món ăn, danh mục ẩm thực trên địa bàn Huyện Gia Lâm.",
                    "2. Nội dung 2: Nghiên cứu lý thuyết CSDL không gian, xây dựng mô hình dữ liệu quan hệ kết hợp kiểu dữ liệu không gian PostGIS (Geography Point WGS84 - EPSG:4326).",
                    "3. Nội dung 3: Nghiên cứu và xây dựng thuật toán gợi ý món ăn theo ngữ cảnh: tích hợp OpenWeatherMap API và bộ dữ liệu chuẩn 400 mẫu thời tiết theo mùa (Xuân, Hạ, Thu, Đông) gắn với ma trận danh mục món ăn phù hợp.",
                    "4. Nội dung 4: Thiết kế kiến trúc tổng thể hệ thống (System Architecture), thiết kế giao diện UI/UX trên Figma cho Web Admin và Mobile Client.",
                    "5. Nội dung 5: Xây dựng Backend RESTful API bằng FastAPI: xác thực đa vai trò, quản lý hồ sơ Onboarding BMI, truy vấn không gian PostGIS (`ST_Distance`), Geocoding và IP Geolocation.",
                    "6. Nội dung 6: Xây dựng Cổng quản trị Web Admin bằng Vue 3, Vite và TypeScript: quản lý quán ăn, thực đơn, người dùng và ma trận luật thời tiết.",
                    "7. Nội dung 7: Xây dựng Ứng dụng di động Mobile Client bằng Flutter SDK (Material 3): hiển thị bản đồ OpenStreetMap tương tác, tìm kiếm quán ăn, lọc danh mục, khảo sát thể trạng và hiển thị chi tiết menu calo/dị ứng.",
                    "8. Nội dung 8: Thực hiện kiểm thử tự động đa tầng (Backend Pytest, Flutter Widget Test, E2E UI Playwright Flow) và xây dựng bộ công cụ cài đặt tự động 1-click."
                ]
            },
            {
                "title": "3.3. Phương pháp nghiên cứu",
                "paragraphs": [
                    "Trình bày đầy đủ các phương pháp nghiên cứu khoa học và kỹ thuật phần mềm cần áp dụng:",
                    "- Phương pháp thu thập và xử lý số liệu: Tiến hành khảo sát thực địa, thu thập tọa độ kinh độ/vĩ độ, thực đơn, đơn giá, giờ phục vụ của các quán ăn tại Gia Lâm; xử lý làm sạch và chuẩn hóa dữ liệu dưới dạng SQL/JSON.",
                    "- Phương pháp phân tích và thiết kế hướng đối tượng (OOAD):",
                    "+ Sử dụng ngôn ngữ mô hình hóa thống nhất (UML) để xây dựng biểu đồ Use Case, Biểu đồ lớp (Class Diagram) và Biểu đồ tuần tự (Sequence Diagram) thể hiện các luồng xác thực, khảo sát Onboarding, tra cứu bản đồ và gợi ý món ăn.",
                    "+ Thiết kế mô hình dữ liệu thực thể quan hệ (ERD) trên PostgreSQL chuẩn hóa bậc 3.",
                    "- Phương pháp tính toán và truy vấn không gian (Spatial Computing):",
                    "+ Ứng dụng hệ tọa độ WGS84 (World Geodetic System 1984, EPSG:4326) để lưu trữ vị trí địa lý của quán ăn.",
                    "+ Ứng dụng các hàm chuyên biệt của PostGIS (`ST_SetSRID`, `ST_MakePoint`, `ST_Distance`) để tính toán khoảng cách cầu theo mặt ellipsoid và giới hạn phạm vi ranh giới đa giác Huyện Gia Lâm.",
                    "- Phương pháp gợi ý dựa trên tri thức và luật ngữ cảnh (Knowledge-Based Contextual Rule Engine):",
                    "+ Xây dựng ma trận ánh xạ logic giữa điều kiện nhiệt độ, khí hậu thời tiết với các đặc tính món ăn (nóng, lạnh, thanh đạm, giàu năng lượng).",
                    "+ Tích hợp bộ quy tắc sàng lọc theo hồ sơ người dùng (loại trừ dị ứng, cảnh báo độ cay, lọc theo mục tiêu cân nặng BMI).",
                    "- Phương pháp phát triển phần mềm lặp linh hoạt (Agile / Scrum): Chia nhỏ quá trình phát triển thành các Sprint 1-2 tuần, liên tục kiểm thử, tích hợp và tối ưu hóa tính năng.",
                    "- Phương pháp kiểm thử phần mềm tự động (Automated Testing Methodology):",
                    "+ Áp dụng Test-Driven Development (TDD) trên Backend với Pytest chạy trực tiếp trên CSDL PostgreSQL thật.",
                    "+ Kiểm thử giao diện tự động E2E (End-to-End Testing) bằng Playwright ghi nhận console log, server error và chụp ảnh màn hình nghiệm thu."
                ]
            }
        ]
    },
    {
        "part_title": "Phần 4: Kế hoạch và dự kiến kết quả đạt được",
        "sections": [
            {
                "title": "4.1. Kế hoạch thực hiện đề tài theo thời gian là tuần",
                "paragraphs": [
                    "Kế hoạch triển khai đề tài được phân bổ khoa học trong 15 tuần làm việc cụ thể như bảng dưới đây:"
                ],
                "table": [
                    ["Tuần", "Nội dung công việc chi tiết", "Sản phẩm / Kết quả bàn giao", "Người thực hiện"],
                    ["Tuần 1", "Nhận đề tài, nghiên cứu tài liệu tổng quan, khảo sát nhu cầu người dùng tại khu vực Gia Lâm.", "Đề cương nghiên cứu chi tiết, biên bản khảo sát nhu cầu", "Sinh viên"],
                    ["Tuần 2", "Thu thập dữ liệu địa lý thực địa (tọa độ, thực đơn, giờ mở cửa) của hơn 200 quán ăn tại Trâu Quỳ.", "Bộ dữ liệu thô danh sách quán ăn và thực đơn", "Sinh viên"],
                    ["Tuần 3", "Làm sạch dữ liệu, chuẩn hóa bộ 400 mẫu thời tiết theo mùa và thiết kế CSDL (ERD, Data Dictionary).", "File SQL/JSON dữ liệu mẫu và sơ đồ ERD hoàn chỉnh", "Sinh viên"],
                    ["Tuần 4", "Phân tích thiết kế hệ thống phần mềm (UML Use Case, Sequence Diagram, Class Diagram).", "Tập tài liệu đặc tả kiến trúc và thiết kế hệ thống", "Sinh viên"],
                    ["Tuần 5", "Khởi tạo Monorepo, thiết lập môi trường Backend FastAPI, PostgreSQL và PostGIS extension.", "Khung dự án Backend kết nối DB thành công, script setup", "Sinh viên"],
                    ["Tuần 6", "Lập trình module xác thực đa vai trò (Guest, User, Admin) và khảo sát Onboarding thể trạng BMI.", "API xác thực và tính toán BMI hoạt động, test backend", "Sinh viên"],
                    ["Tuần 7", "Lập trình module không gian PostGIS: truy vấn khoảng cách, tìm kiếm quán ăn và Geocoding OpenStreetMap.", "API không gian địa lý trả về tọa độ và khoảng cách chính xác", "Sinh viên"],
                    ["Tuần 8", "Lập trình module Thời tiết: tích hợp OpenWeatherMap API, nạp 400 mẫu thời tiết và gợi ý theo mùa.", "API gợi ý món ăn theo thời tiết và bộ lọc danh mục", "Sinh viên"],
                    ["Tuần 9", "Xây dựng giao diện Web Admin bằng Vue 3 + TypeScript: quản lý Quán ăn, Menu và Người dùng.", "Web Admin hiển thị và quản lý đầy đủ các bảng dữ liệu", "Sinh viên"],
                    ["Tuần 10", "Hoàn thiện Web Admin: Tab quy tắc thời tiết (phân trang, lọc mùa), giao diện đăng nhập Admin.", "Hệ thống Web Admin hoàn chỉnh, build không lỗi", "Sinh viên"],
                    ["Tuần 11", "Xây dựng ứng dụng Mobile Flutter: Giao diện Material 3, Bản đồ OpenStreetMap, định vị IP.", "Ứng dụng Mobile hiển thị bản đồ mượt mà, marker quán ăn", "Sinh viên"],
                    ["Tuần 12", "Hoàn thiện Mobile Flutter: Tab Khám phá, Bottom sheet thực đơn calo, khảo sát Onboarding.", "Ứng dụng Mobile hoàn chỉnh chạy trên Android, iOS, Web", "Sinh viên"],
                    ["Tuần 13", "Xây dựng kịch bản kiểm thử tự động E2E Flows (Playwright), kiểm thử tải và kiểm thử bảo mật.", "Bộ kiểm thử E2E chạy tự động, báo cáo kết quả test", "Sinh viên"],
                    ["Tuần 14", "Tối ưu hóa hiệu năng, đóng gói script cài đặt tự động 1-click (CAI_DAT.bat, CHAY_TAT_CA.bat).", "Bộ cài đặt 1-click hoàn chỉnh và tài liệu hướng dẫn", "Sinh viên"],
                    ["Tuần 15", "Viết báo cáo tổng kết khóa luận tốt nghiệp, chuẩn bị slide trình chiếu và bảo vệ đề tài.", "Quyển báo cáo khóa luận hoàn chỉnh và bài thuyết trình", "Sinh viên + GVHD"]
                ]
            },
            {
                "title": "4.2. Dự kiến kết quả chính sẽ đạt được",
                "paragraphs": [
                    "Kết thúc quá trình thực hiện đề tài, dự kiến sẽ đạt được các kết quả trọng tâm sau:",
                    "1. Về mặt học thuật và báo cáo:",
                    "- Báo cáo Khóa luận tốt nghiệp hoàn chỉnh với đầy đủ cơ sở lý luận, phương pháp nghiên cứu, phân tích thiết kế và đánh giá thực nghiệm.",
                    "- Bộ tài liệu thiết kế phần mềm chi tiết bao gồm: Từ điển dữ liệu (Data Dictionary), Sơ đồ thực thể liên kết (ERD), Sơ đồ Use Case, Sơ đồ lớp (Class Diagram), Sơ đồ tuần tự (Sequence Diagram) và Bộ tài liệu hướng dẫn kiểm thử (Manual & Automated Test Cases).",
                    "2. Về mặt sản phẩm phần mềm (Hệ sinh thái PTC1 Food Platform):",
                    "- Backend RESTful API hoàn chỉnh viết trên nền FastAPI (Python 3.9), chạy bất đồng bộ với cơ chế xác thực an toàn, tích hợp Swagger UI tài liệu hóa tự động tại `/docs`.",
                    "- Cơ sở dữ liệu chuẩn hóa PostgreSQL 14 tích hợp PostGIS 3.6.1 lưu trữ thực tế 204 quán ăn, 775 món ăn chi tiết (giá, calo, độ cay, thành phần, chất gây dị ứng) và 400 mẫu thời tiết theo mùa.",
                    "- Cổng quản trị Web Admin trực quan xây dựng bằng Vue 3, Vite và TypeScript, giao diện hiện đại với các tab nghiệp vụ chuyên sâu.",
                    "- Ứng dụng di động Mobile Client phát triển bằng Flutter SDK (Material 3), tương thích mượt mà trên Android, iOS và Web, tích hợp bản đồ số OpenStreetMap tương tác cao.",
                    "- Bộ công cụ tự động hóa 1-click (`CAI_DAT.bat`, `setup.ps1`, `CHAY_TAT_CA.bat`) cho phép người dùng hoặc giám khảo cài đặt toàn bộ hệ thống từ con số 0 trong vòng chưa đầy 5 phút.",
                    "- Tỷ lệ bao phủ kiểm thử đạt 100% (hơn 100 Pytest cases backend, Flutter widget test và E2E UI Playwright Flow test)."
                ]
            }
        ]
    },
    {
        "part_title": "Phần 5: Tài liệu tham khảo",
        "sections": [
            {
                "title": "5.1. Chi tiết các tài liệu tham khảo (dự kiến)",
                "paragraphs": [
                    "Danh mục tài liệu tham khảo dự kiến được sử dụng trong quá trình xây dựng đề cương và thực hiện khóa luận:",
                    "[1] Tiêu Chuẩn Quốc Gia TCVN 12693:2020 - Công nghệ thông tin - Hệ thống thông tin địa lý (GIS) - Yêu cầu kỹ thuật.",
                    "[2] Nguyễn Trọng Hòa, Đỗ Thị Lan (2022), Giáo trình Cơ sở dữ liệu không gian và GIS, Nhà xuất bản Đại học Quốc gia Hà Nội.",
                    "[3] Regina O. Obe, Leo S. Hsu (2021), PostGIS in Action (3rd Edition), Manning Publications, ISBN: 978-1617296697.",
                    "[4] Gediminas Adomavicius, Alexander Tuzhilin (2015), \"Context-Aware Recommender Systems\", in Recommender Systems Handbook, Springer, Boston, MA, pp. 191-226.",
                    "[5] Tiago Ramirez, et al. (2020), \"Weather-Aware Recommendation Engine for Tourism and Gastronomy\", IEEE International Conference on Big Data, pp. 1120-1127.",
                    "[6] Tiago Oliveira, Marco Santos (2023), \"Evaluating Mobile Context-Aware Food Recommenders Based on Physical Health Profiles\", ACM Transactions on Computer-Human Interaction, Vol. 30, No. 4, pp. 1-28.",
                    "[7] Sebastián Ramírez (2024), FastAPI Official Documentation, truy cập tại: https://fastapi.tiangolo.com/.",
                    "[8] Google LLC (2024), Flutter Documentation - Multi-platform UI Toolkit, truy cập tại: https://docs.flutter.dev/.",
                    "[9] Evan You, et al. (2024), Vue.js 3 - The Progressive JavaScript Framework, truy cập tại: https://vuejs.org/.",
                    "[10] OpenStreetMap Foundation (2024), OpenStreetMap Data and Nominatim Geocoding Services, truy cập tại: https://www.openstreetmap.org/."
                ]
            }
        ]
    }
]

# -------------------------------------------------------------
# 2. XUẤT FILE MARKDOWN (docs/de-cuong-nghien-cuu.md)
# -------------------------------------------------------------
def generate_markdown():
    lines = []
    lines.append(f"# {TITLE}\n")
    lines.append(f"**{SUBTITLE}**\n")
    lines.append("---\n")

    for part in CONTENT_SECTIONS:
        lines.append(f"## {part['part_title']}\n")
        for sec in part["sections"]:
            lines.append(f"### {sec['title']}\n")
            for p in sec["paragraphs"]:
                lines.append(f"{p}\n")
            if "subsections" in sec:
                for sub in sec["subsections"]:
                    lines.append(f"#### {sub['title']}\n")
                    for p in sub["paragraphs"]:
                        lines.append(f"{p}\n")
            if "table" in sec:
                table_data = sec["table"]
                headers = table_data[0]
                lines.append("| " + " | ".join(headers) + " |")
                lines.append("| " + " | ".join(["---"] * len(headers)) + " |")
                for row in table_data[1:]:
                    lines.append("| " + " | ".join(row) + " |")
                lines.append("\n")

    with open(MD_PATH, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))
    print(f"[OK] Generated Markdown: {MD_PATH}")

# -------------------------------------------------------------
# 3. XUẤT FILE WORD DOCX (docs/De_Cuong_Nghien_Cuu_PTC1.docx)
# -------------------------------------------------------------
def set_cell_background(cell, fill_hex):
    shading_elm = parse_xml(f'<w:shd {nsdecls("w")} w:fill="{fill_hex}"/>')
    cell._tc.get_or_add_tcPr().append(shading_elm)

def set_cell_margins(cell, top=100, bottom=100, left=150, right=150):
    tcPr = cell._tc.get_or_add_tcPr()
    tcMar = parse_xml(f'<w:tcMar {nsdecls("w")}><w:top w:w="{top}" w:type="dxa"/><w:bottom w:w="{bottom}" w:type="dxa"/><w:left w:w="{left}" w:type="dxa"/><w:right w:w="{right}" w:type="dxa"/></w:tcMar>')
    tcPr.append(tcMar)

def generate_docx():
    doc = docx.Document()

    # Cài đặt kích thước trang A4 & căn lề chuẩn khóa luận (Top: 2cm, Bottom: 2cm, Left: 3cm, Right: 2cm)
    for section in doc.sections:
        section.page_width = Inches(8.27)
        section.page_height = Inches(11.69)
        section.top_margin = Inches(0.79)     # ~2.0 cm
        section.bottom_margin = Inches(0.79)  # ~2.0 cm
        section.left_margin = Inches(1.18)    # ~3.0 cm
        section.right_margin = Inches(0.79)   # ~2.0 cm

    # Cấu hình Style mặc định: Times New Roman, 13pt, Màu đen, Giãn dòng 1.3
    normal_style = doc.styles['Normal']
    normal_style.font.name = 'Times New Roman'
    normal_style.font.size = Pt(13)
    normal_style.font.color.rgb = RGBColor(0, 0, 0)
    normal_style.paragraph_format.line_spacing = 1.3
    normal_style.paragraph_format.space_after = Pt(6)

    # 1. TIÊU ĐỀ BÁO CÁO
    p_inst = doc.add_paragraph()
    p_inst.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r_inst1 = p_inst.add_run("BỘ GIÁO DỤC VÀ ĐÀO TẠO\nHỌC VIỆN NÔNG NGHIỆP VIỆT NAM\nKHOA CÔNG NGHỆ THÔNG TIN\n")
    r_inst1.bold = True
    r_inst1.font.size = Pt(13)
    r_inst2 = p_inst.add_run("------------------o0o------------------\n\n")
    r_inst2.font.size = Pt(11)

    p_title = doc.add_paragraph()
    p_title.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r_title = p_title.add_run("ĐỀ CƯƠNG BÁO CÁO THỰC TẬP TỐT NGHIỆP\nKHÓA LUẬN TỐT NGHIỆP ĐẠI HỌC\n")
    r_title.bold = True
    r_title.font.size = Pt(16)
    r_title.font.color.rgb = RGBColor(16, 54, 114) # Xanh đậm trang trọng

    p_sub = doc.add_paragraph()
    p_sub.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r_sub = p_sub.add_run("ĐỀ TÀI:\nNGHIÊN CỨU, THIẾT KẾ VÀ XÂY DỰNG HỆ THỐNG GỢI Ý ĐỊA ĐIỂM ẨM THỰC THÔNG MINH DỰA TRÊN DỮ LIỆU KHÔNG GIAN ĐỊA LÝ (GIS/POSTGIS), YẾU TỐ THỜI TIẾT VÀ HỒ SƠ CÁ NHÂN HÓA NGƯỜI DÙNG\n(HỆ SINH THÁI PTC1 FOOD PLATFORM)\n")
    r_sub.bold = True
    r_sub.font.size = Pt(14)
    r_sub.font.color.rgb = RGBColor(192, 0, 0) # Đỏ đô trang trọng

    # Thông tin thực hiện
    p_info = doc.add_paragraph()
    p_info.alignment = WD_ALIGN_PARAGRAPH.LEFT
    p_info.paragraph_format.left_indent = Inches(1.5)
    p_info.paragraph_format.space_after = Pt(18)
    p_info.add_run("Sinh viên thực hiện:\t[CẦN USER XÁC NHẬN - Điền Họ và Tên]\n").bold = True
    p_info.add_run("Mã số sinh viên:\t[CẦN USER XÁC NHẬN - Điền Mã sinh viên]\n").bold = True
    p_info.add_run("Ngành đào tạo:\tCông nghệ thông tin\n")
    p_info.add_run("Chuyên ngành:\tKỹ thuật phần mềm / Hệ thống thông tin\n")
    p_info.add_run("Giáo viên hướng dẫn:\t[CẦN USER XÁC NHẬN - Điền Họ tên Giảng viên]\n").bold = True
    p_info.add_run("Địa điểm thực tập:\tHuyện Gia Lâm - TP. Hà Nội\n")

    doc.add_page_break()

    # 2. DUYỆT CÁC PHẦN NỘI DUNG CHÍNH
    for part in CONTENT_SECTIONS:
        # Tiêu đề Phần (Heading 1)
        p_part = doc.add_paragraph()
        p_part.paragraph_format.space_before = Pt(14)
        p_part.paragraph_format.space_after = Pt(6)
        r_part = p_part.add_run(part["part_title"].upper())
        r_part.bold = True
        r_part.font.size = Pt(14)
        r_part.font.color.rgb = RGBColor(16, 54, 114)

        for sec in part["sections"]:
            # Tiêu đề mục con (Heading 2)
            p_sec = doc.add_paragraph()
            p_sec.paragraph_format.space_before = Pt(10)
            p_sec.paragraph_format.space_after = Pt(4)
            r_sec = p_sec.add_run(sec["title"])
            r_sec.bold = True
            r_sec.font.size = Pt(13)

            for p_text in sec["paragraphs"]:
                p_body = doc.add_paragraph()
                p_body.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
                p_body.paragraph_format.line_spacing = 1.3
                p_body.paragraph_format.space_after = Pt(6)
                # Thụt đầu dòng 0.5 inch cho đoạn văn xuôi thông thường
                if not p_text.startswith("-") and not p_text.startswith("+") and not p_text.startswith("a)") and not p_text.startswith("b)") and not p_text.startswith("1.") and not p_text.startswith("["):
                    p_body.paragraph_format.first_line_indent = Inches(0.4)
                
                # Định dạng in đậm các đầu mục liệt kê
                if p_text.startswith("a)") or p_text.startswith("b)"):
                    r = p_body.add_run(p_text)
                    r.bold = True
                elif p_text.startswith("- Tên đề tài chính thức:"):
                    r1 = p_body.add_run("- Tên đề tài chính thức: ")
                    r1.bold = True
                    p_body.add_run(p_text.replace("- Tên đề tài chính thức: ", ""))
                elif p_text.startswith("- Tính thời sự của đề tài:") or p_text.startswith("- Tầm quan trọng của đề tài:"):
                    r = p_body.add_run(p_text)
                    r.bold = True
                else:
                    p_body.add_run(p_text)

            if "subsections" in sec:
                for sub in sec["subsections"]:
                    p_sub = doc.add_paragraph()
                    p_sub.paragraph_format.space_before = Pt(8)
                    p_sub.paragraph_format.space_after = Pt(4)
                    r_sub = p_sub.add_run(sub["title"])
                    r_sub.bold = True
                    r_sub.italic = True
                    r_sub.font.size = Pt(13)

                    for p_text in sub["paragraphs"]:
                        p_body = doc.add_paragraph()
                        p_body.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
                        p_body.paragraph_format.line_spacing = 1.3
                        p_body.paragraph_format.space_after = Pt(6)
                        if p_text.startswith("+ ") or p_text.startswith("a) ") or p_text.startswith("b) "):
                            r = p_body.add_run(p_text)
                            if p_text.startswith("a)") or p_text.startswith("b)"):
                                r.bold = True
                        else:
                            p_body.add_run(p_text)

            # Vẽ bảng nếu có (Kế hoạch thực hiện theo tuần)
            if "table" in sec:
                table_data = sec["table"]
                table = doc.add_table(rows=len(table_data), cols=len(table_data[0]))
                table.alignment = WD_TABLE_ALIGNMENT.CENTER
                table.autofit = False

                col_widths = [Inches(1.0), Inches(3.2), Inches(2.2), Inches(1.1)]

                # Header
                for col_idx, heading in enumerate(table_data[0]):
                    cell = table.cell(0, col_idx)
                    cell.text = heading
                    set_cell_background(cell, "E0E8F5")
                    set_cell_margins(cell, top=120, bottom=120, left=100, right=100)
                    cell.paragraphs[0].alignment = WD_ALIGN_PARAGRAPH.CENTER
                    for r in cell.paragraphs[0].runs:
                        r.bold = True
                        r.font.size = Pt(11)
                        r.font.name = 'Times New Roman'

                # Rows
                for row_idx, row_values in enumerate(table_data[1:], start=1):
                    for col_idx, val in enumerate(row_values):
                        cell = table.cell(row_idx, col_idx)
                        cell.text = val
                        set_cell_margins(cell, top=80, bottom=80, left=100, right=100)
                        if col_idx in (0, 3):
                            cell.paragraphs[0].alignment = WD_ALIGN_PARAGRAPH.CENTER
                        else:
                            cell.paragraphs[0].alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
                        for r in cell.paragraphs[0].runs:
                            r.font.size = Pt(10.5)
                            r.font.name = 'Times New Roman'

                # Cài độ rộng cột
                for row in table.rows:
                    for i, w in enumerate(col_widths):
                        row.cells[i].width = w

                doc.add_paragraph().paragraph_format.space_after = Pt(10)

    # Phần chữ ký xác nhận cuối trang
    doc.add_paragraph().paragraph_format.space_before = Pt(20)
    p_sign = doc.add_paragraph()
    p_sign.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    p_sign.add_run("Hà Nội, ngày 30 tháng 10 năm 2026\n").italic = True

    tbl_sign = doc.add_table(rows=2, cols=2)
    tbl_sign.alignment = WD_TABLE_ALIGNMENT.CENTER
    col_sign_widths = [Inches(3.7), Inches(3.7)]

    cell_left = tbl_sign.cell(0, 0)
    cell_left.paragraphs[0].alignment = WD_ALIGN_PARAGRAPH.CENTER
    r_l1 = cell_left.paragraphs[0].add_run("GIẢNG VIÊN HƯỚNG DẪN\n")
    r_l1.bold = True
    cell_left.paragraphs[0].add_run("(Ký và ghi rõ họ tên)\n\n\n\n\n").italic = True

    cell_right = tbl_sign.cell(0, 1)
    cell_right.paragraphs[0].alignment = WD_ALIGN_PARAGRAPH.CENTER
    r_r1 = cell_right.paragraphs[0].add_run("SINH VIÊN THỰC HIỆN\n")
    r_r1.bold = True
    cell_right.paragraphs[0].add_run("(Ký và ghi rõ họ tên)\n\n\n\n\n").italic = True

    for row in tbl_sign.rows:
        for i, w in enumerate(col_sign_widths):
            row.cells[i].width = w

    doc.save(DOCX_PATH)
    print(f"[OK] Generated DOCX: {DOCX_PATH}")

if __name__ == "__main__":
    generate_markdown()
    generate_docx()
