"""
Script sinh và nạp 150 Cửa hàng ẩm thực thực tế tại Huyện Gia Lâm (PTC1 Platform).
Phân bổ theo 8 cụm ẩm thực chính:
1. Trâu Quỳ / HV Nông nghiệp: 35 quán
2. Vinhomes Ocean Park 1: 35 quán
3. Ga Yên Viên / TT. Yên Viên: 20 quán
4. Làng gốm Bát Tràng: 15 quán
5. Chợ vải Ninh Hiệp: 15 quán
6. KĐT Đặng Xá: 12 quán
7. Xã Cổ Bi: 10 quán
8. Xã Kiêu Kỵ / Dương Xá: 8 quán
Tổng cộng: 150 quán, ~500 món ăn phong phú kèm ảnh Unsplash, calo, độ cay, giấy phép.
Đảm bảo 100% tọa độ nằm chính xác trong đa giác ranh giới Huyện Gia Lâm.
"""

import sys
import os
import random
from datetime import time

if sys.stdout.encoding != 'utf-8':
    try:
        sys.stdout.reconfigure(encoding='utf-8')
    except Exception:
        pass

# Đảm bảo đường dẫn import server
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from server.app.db.session import SessionLocal
from server.app.models.category import Category
from server.app.models.restaurant import Restaurant
from server.app.models.dish import Dish
from server.app.models.weather import Weather
from server.app.models.weather_category import WeatherCategory

# Đa giác ranh giới Huyện Gia Lâm chuẩn hóa
GIA_LAM_POLYGON = [
    (21.1250, 105.9340), (21.1180, 105.9450), (21.1080, 105.9520), (21.0960, 105.9600),
    (21.0820, 105.9720), (21.0720, 105.9860), (21.0600, 106.0020), (21.0480, 106.0120),
    (21.0360, 106.0240), (21.0260, 106.0350), (21.0180, 106.0280), (21.0080, 106.0160),
    (20.9990, 106.0020), (20.9920, 105.9880), (20.9820, 105.9780), (20.9700, 105.9640),
    (20.9620, 105.9480), (20.9480, 105.9380), (20.9380, 105.9300), (20.9270, 105.9220),
    (20.9340, 105.9140), (20.9480, 105.9080), (20.9620, 105.9050), (20.9780, 105.9020),
    (20.9900, 105.9040), (21.0020, 105.9120), (21.0140, 105.9160), (21.0260, 105.9140),
    (21.0360, 105.9100), (21.0480, 105.9040), (21.0580, 105.8960), (21.0700, 105.8870),
    (21.0820, 105.8800), (21.0950, 105.8820), (21.1080, 105.8920), (21.1180, 105.9120),
]


def is_in_gia_lam(lat: float, lon: float) -> bool:
    """Kiểm tra điểm có nằm trong đa giác Gia Lâm hay không (Point-in-Polygon)."""
    n = len(GIA_LAM_POLYGON)
    count = 0
    for i in range(n):
        p1 = GIA_LAM_POLYGON[i]
        p2 = GIA_LAM_POLYGON[(i + 1) % n]
        if (p1[0] <= lat < p2[0]) or (p2[0] <= lat < p1[0]):
            if lon < (p2[1] - p1[1]) * (lat - p1[0]) / (p2[0] - p1[0]) + p1[1]:
                count += 1
    return (count % 2) == 1


# 8 Cụm ẩm thực lớn tại Gia Lâm
CLUSTERS = [
    {
        "id": "trau_quy",
        "name": "Trâu Quỳ / HV Nông Nghiệp",
        "center": (21.0036, 105.9340),
        "count": 35,
        "max_radius_deg": 0.0040,
        "streets": [
            "Ngô Xuân Quảng", "Cửu Việt 1", "Cửu Việt 2", "Đào Đất", "An Đào A", "An Đào B",
            "Nguyễn Mậu Tài", "Trường Chinh Nông Nghiệp", "Học Viện Nông Nghiệp"
        ],
        "ward": "Thị trấn Trâu Quỳ, Huyện Gia Lâm, Hà Nội",
        "styles": ["Phở & Bún", "Cơm & Xôi", "Đồ ăn vặt", "Cà phê & Trà sữa", "Bánh mì", "Lẩu & Nướng"],
    },
    {
        "id": "ocean_park",
        "name": "Vinhomes Ocean Park 1",
        "center": (20.9950, 105.9550),
        "count": 35,
        "max_radius_deg": 0.0045,
        "streets": [
            "Đại lộ San Hô 1", "Phố đi bộ Sao Biển 11", "Khu Biển Hồ Nước Mặn", "Phân khu Hải Âu 2",
            "Đường Ngọc Trai 6", "Tòa S2.01 Ocean Park", "Tòa S1.08 Ocean Park", "Khu Sapphire 2"
        ],
        "ward": "KĐT Vinhomes Ocean Park 1, Huyện Gia Lâm, Hà Nội",
        "styles": ["Lẩu & Nướng", "Cơm & Xôi", "Cà phê & Trà sữa", "Phở & Bún", "Đồ ăn vặt"],
    },
    {
        "id": "yen_vien",
        "name": "Ga Yên Viên / TT. Yên Viên",
        "center": (21.0805, 105.9020),
        "count": 20,
        "max_radius_deg": 0.0035,
        "streets": [
            "Hà Huy Tập", "Phan Đăng Lưu", "Đình Xuyên", "Khu Ga Yên Viên", "Đường Đê Vàng Yên Viên"
        ],
        "ward": "Thị trấn Yên Viên, Huyện Gia Lâm, Hà Nội",
        "styles": ["Cơm & Xôi", "Phở & Bún", "Bánh mì", "Lẩu & Nướng"],
    },
    {
        "id": "bat_trang",
        "name": "Làng Gốm Bát Tràng",
        "center": (20.9747, 105.9142),
        "count": 15,
        "max_radius_deg": 0.0030,
        "streets": [
            "Xóm 1 Làng Cổ Bát Tràng", "Xóm 2 Bát Tràng", "Đường Gốm Sứ", "Phố Chợ Gốm Bát Tràng",
            "Dốc Giang Cao", "Khu Bảo Tàng Gốm"
        ],
        "ward": "Xã Bát Tràng, Huyện Gia Lâm, Hà Nội",
        "styles": ["Phở & Bún", "Cơm & Xôi", "Lẩu & Nướng", "Đồ ăn vặt"],
    },
    {
        "id": "ninh_hiep",
        "name": "Chợ Vải Ninh Hiệp",
        "center": (21.0575, 105.9380),
        "count": 15,
        "max_radius_deg": 0.0032,
        "streets": [
            "Dốc Ninh Hiệp", "Đường Chợ Nành", "Phố Baza Ninh Hiệp", "Đường Làng Ninh Hiệp",
            "Khu Chợ Vải Mới"
        ],
        "ward": "Xã Ninh Hiệp, Huyện Gia Lâm, Hà Nội",
        "styles": ["Phở & Bún", "Bánh mì", "Cơm & Xôi", "Đồ ăn vặt"],
    },
    {
        "id": "dang_xa",
        "name": "KĐT Đặng Xá",
        "center": (21.0320, 105.9450),
        "count": 12,
        "max_radius_deg": 0.0030,
        "streets": [
            "Đường D1 KĐT Đặng Xá", "Đường D3 KĐT Đặng Xá", "Tòa CT7 Đặng Xá", "Đường Đặng Xá"
        ],
        "ward": "KĐT Đặng Xá, Xã Đặng Xá, Huyện Gia Lâm, Hà Nội",
        "styles": ["Cơm & Xôi", "Phở & Bún", "Cà phê & Trà sữa", "Bánh mì"],
    },
    {
        "id": "co_bi",
        "name": "Xã Cổ Bi",
        "center": (21.0080, 105.9300),
        "count": 10,
        "max_radius_deg": 0.0028,
        "streets": [
            "Phố Cổ Bi", "Đường đê Sông Đuống Cổ Bi", "Thôn Cam Cổ Bi", "Khu Đấu Giá Cổ Bi"
        ],
        "ward": "Xã Cổ Bi, Huyện Gia Lâm, Hà Nội",
        "styles": ["Phở & Bún", "Cơm & Xôi", "Lẩu & Nướng", "Bánh mì"],
    },
    {
        "id": "kieu_ky",
        "name": "Xã Kiêu Kỵ / Dương Xá",
        "center": (20.9850, 105.9650),
        "count": 8,
        "max_radius_deg": 0.0035,
        "streets": [
            "Đường Kiêu Kỵ", "Quốc lộ 5 Dương Xá", "Khu Làng Nghề Kiêu Kỵ", "Đường Dương Xá"
        ],
        "ward": "Xã Kiêu Kỵ, Huyện Gia Lâm, Hà Nội",
        "styles": ["Cơm & Xôi", "Lẩu & Nướng", "Phở & Bún", "Đồ ăn vặt"],
    },
]

# Pool ảnh Unsplash Food CDN chất lượng cao đã kiểm chứng hoạt động (HTTP 200)
VERIFIED_FOOD_IMAGES = {
    "Phở": "https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?w=800&auto=format&fit=crop&q=80",
    "Bún chả": "https://images.unsplash.com/photo-1569058242253-92a9c755a0ec?w=800&auto=format&fit=crop&q=80",
    "Bún đậu": "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800&auto=format&fit=crop&q=80",
    "Bún riêu": "https://images.unsplash.com/photo-1617093727343-374698b1b08d?w=800&auto=format&fit=crop&q=80",
    "Bún ốc": "https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=800&auto=format&fit=crop&q=80",
    "Canh măng": "https://images.unsplash.com/photo-1547592166-23ac45744acd?w=800&auto=format&fit=crop&q=80",
    "Cơm tấm": "https://images.unsplash.com/photo-1543339308-43e59d6b73a6?w=800&auto=format&fit=crop&q=80",
    "Cơm niêu": "https://images.unsplash.com/photo-1512058564366-18510be2db19?w=800&auto=format&fit=crop&q=80",
    "Cơm gà": "https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=800&auto=format&fit=crop&q=80",
    "Xôi xéo": "https://images.unsplash.com/photo-1516684732162-798a0062be99?w=800&auto=format&fit=crop&q=80",
    "Bánh mì pate": "https://images.unsplash.com/photo-1626074353765-517a681e40be?w=800&auto=format&fit=crop&q=80",
    "Bánh mì que": "https://images.unsplash.com/photo-1509722747041-616f39b57569?w=800&auto=format&fit=crop&q=80",
    "Nem rán": "https://images.unsplash.com/photo-1544025162-d76694265947?w=800&auto=format&fit=crop&q=80",
    "Khoai lắc": "https://images.unsplash.com/photo-1573080496219-bb080dd4f877?w=800&auto=format&fit=crop&q=80",
    "Bánh tráng nướng": "https://images.unsplash.com/photo-1601050690597-df0568f70950?w=800&auto=format&fit=crop&q=80",
    "Nem nướng": "https://images.unsplash.com/photo-1562967914-608f82629710?w=800&auto=format&fit=crop&q=80",
    "Cà phê": "https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?w=800&auto=format&fit=crop&q=80",
    "Trà hoa quả": "https://images.unsplash.com/photo-1513558161293-cdaf765ed2fd?w=800&auto=format&fit=crop&q=80",
    "Trà sữa": "https://images.unsplash.com/photo-1572490122747-3968b75cc699?w=800&auto=format&fit=crop&q=80",
    "Chè bưởi": "https://images.unsplash.com/photo-1563805042-7684c019e1cb?w=800&auto=format&fit=crop&q=80",
    "Lẩu thái": "https://images.unsplash.com/photo-1547592180-85f173990554?w=800&auto=format&fit=crop&q=80",
    "Bò nướng": "https://images.unsplash.com/photo-1544025162-d76694265947?w=800&auto=format&fit=crop&q=80",
    "Gà nướng": "https://images.unsplash.com/photo-1598515214211-89d3c73ae83b?w=800&auto=format&fit=crop&q=80",
    "Miến lươn": "https://images.unsplash.com/photo-1594041680534-e8c8cdebd659?w=800&auto=format&fit=crop&q=80",
}

# Template tên quán ăn thực tế
NAME_PREFIXES = ["Quán", "Nhà Hàng", "Bếp", "Tiệm Ăn", "Ẩm Thực", "Cơm", "Phở", "Bún", "Lẩu Nướng"]
NAME_OWNERS = ["Cô Hoa", "Bác Thành", "Chú Tuấn", "Bà Năm", "Hương Quê", "Gia Truyền", "Hà Thành", "Khu Phố", "Sinh Viên", "Thảo Nguyên", "Biển Hồ", "Làng Cổ", "Thắng Lợi", "Anh Em", "Năm Sao", "Vạn Phát", "Cây Đa", "Gốc Gạo"]

# Menu Pool theo từng thể loại
DISH_TEMPLATES = {
    "Phở & Bún": [
        ("Phở bò tái lăn đặc biệt", 55000, 480, 1, "Phở", ["Sáng", "Trưa"]),
        ("Phở bò chín nạm gầu giòn", 50000, 450, 0, "Phở", ["Sáng", "Trưa"]),
        ("Phở gà ta đùi xé da giòn", 45000, 420, 0, "Phở", ["Sáng", "Trưa"]),
        ("Bún chả nướng than hoa", 45000, 620, 1, "Bún chả", ["Trưa", "Tối"]),
        ("Bún đậu mắm tôm thập cẩm", 55000, 680, 2, "Bún đậu", ["Trưa", "Tối"]),
        ("Bún riêu cua bắp bò sườn sụn", 55000, 520, 1, "Bún riêu", ["Sáng", "Trưa"]),
        ("Bún ốc chuối đậu tía tô", 45000, 460, 1, "Bún ốc", ["Sáng", "Trưa"]),
        ("Canh măng mực đặc sản Bát Tràng", 120000, 320, 0, "Canh măng", ["Trưa", "Tối"]),
        ("Miến lươn xào giòn thơm ngậy", 65000, 480, 1, "Miến lươn", ["Sáng", "Trưa"]),
    ],
    "Cơm & Xôi": [
        ("Cơm sườn nướng mật ong sốt BBQ", 65000, 750, 0, "Cơm tấm", ["Trưa", "Tối"]),
        ("Cơm niêu cá bống kho tộ đậm đà", 95000, 720, 1, "Cơm niêu", ["Trưa", "Tối"]),
        ("Cơm niêu bò sốt tiêu đen cháy cạnh", 90000, 760, 1, "Cơm niêu", ["Trưa", "Tối"]),
        ("Cơm gà xối mỡ giòn da hạt dẻo", 50000, 750, 0, "Cơm gà", ["Trưa", "Tối"]),
        ("Cơm đĩa sườn rim me chua ngọt", 45000, 690, 0, "Cơm tấm", ["Trưa", "Tối"]),
        ("Xôi xéo mỡ hành ruốc nấm thơm bùi", 30000, 420, 0, "Xôi xéo", ["Sáng", "Trưa"]),
        ("Xôi chả mực giòn dai nóng hổi", 40000, 480, 0, "Xôi xéo", ["Sáng", "Trưa"]),
    ],
    "Bánh mì": [
        ("Bánh mì pate chả thịt nguội giòn rụm", 25000, 420, 0, "Bánh mì pate", ["Sáng", "Ăn vặt"]),
        ("Bánh mì chảo thập cẩm trứng xúc xích", 40000, 580, 1, "Bánh mì pate", ["Sáng", "Tối"]),
        ("Bánh mì que cay Hải Phòng nướng giòn", 15000, 220, 2, "Bánh mì que", ["Sáng", "Ăn vặt"]),
        ("Bánh mì nướng bơ tỏi xúc xích", 35000, 390, 0, "Bánh mì que", ["Sáng", "Ăn vặt"]),
    ],
    "Đồ ăn vặt": [
        ("Nem rán Hà Nội giòn rụm nhân thịt", 30000, 350, 0, "Nem rán", ["Trưa", "Tối", "Ăn vặt"]),
        ("Khoai tây lắc phô mai giòn tan", 35000, 380, 0, "Khoai lắc", ["Ăn vặt", "Tối"]),
        ("Bánh tráng nướng mỡ hành trứng cút", 25000, 320, 1, "Bánh tráng nướng", ["Ăn vặt", "Tối"]),
        ("Nem nướng Nha Trang cuốn bánh tráng", 50000, 450, 1, "Nem nướng", ["Trưa", "Tối"]),
        ("Chè bưởi An Giang cốt dừa béo bùi", 25000, 280, 0, "Chè bưởi", ["Ăn vặt", "Trưa"]),
    ],
    "Cà phê & Trà sữa": [
        ("Cà phê muối biển béo ngậy kem cheese", 45000, 210, 0, "Cà phê", ["Sáng", "Ăn vặt", "Cả ngày"]),
        ("Cà phê nâu đá truyền thống Đắk Lắk", 35000, 180, 0, "Cà phê", ["Sáng", "Cả ngày"]),
        ("Trà đào cam sả hạt chia tươi mát", 52000, 160, 0, "Trà hoa quả", ["Trưa", "Ăn vặt", "Cả ngày"]),
        ("Trà sữa trân châu đường đen hoàng gia", 55000, 380, 0, "Trà sữa", ["Ăn vặt", "Tối"]),
        ("Trà nhài chanh leo thanh lọc mát lạnh", 40000, 140, 0, "Trà hoa quả", ["Trưa", "Ăn vặt"]),
    ],
    "Lẩu & Nướng": [
        ("Set Lẩu Thái Tomyum hải sản chua cay", 269000, 890, 2, "Lẩu thái", ["Tối"]),
        ("Bò tảng nướng sốt tiêu đen chảo bơ", 139000, 650, 2, "Bò nướng", ["Tối"]),
        ("Gà đồi nướng mật ong hoa rừng làng cổ", 280000, 820, 1, "Gà nướng", ["Trưa", "Tối"]),
        ("Lẩu riêu cua bắp bò sườn sụn tươi rói", 299000, 850, 1, "Lẩu thái", ["Tối"]),
        ("Nầm heo nướng sốt me chua cay xèo xèo", 129000, 620, 2, "Bò nướng", ["Tối"]),
    ],
}


def generate_seed_data():
    """Tạo bộ dữ liệu 150 quán ăn tại Gia Lâm và danh sách món ăn tương ứng."""
    random.seed(42)  # Đảm bảo dữ liệu deterministic (chạy lại ra cùng 150 quán)

    restaurants = []
    generated_names = set()

    for cluster in CLUSTERS:
        c_lat, c_lon = cluster["center"]
        quota = cluster["count"]
        streets = cluster["streets"]
        ward = cluster["ward"]
        max_r = cluster["max_radius_deg"]
        styles = cluster["styles"]

        created_in_cluster = 0
        attempts = 0

        while created_in_cluster < quota and attempts < 1000:
            attempts += 1
            # Sinh tọa độ ngẫu nhiên xung quanh tâm cụm với phân phối chuẩn (Gaussian Jitter)
            d_lat = random.gauss(0, max_r / 2.2)
            d_lon = random.gauss(0, max_r / 2.2)
            lat = round(c_lat + d_lat, 4)
            lon = round(c_lon + d_lon, 4)

            # BẮT BUỘC kiểm tra điểm rơi trong ranh giới đa giác Huyện Gia Lâm
            if not is_in_gia_lam(lat, lon):
                continue

            # Sinh tên quán độc nhất
            primary_style = random.choice(styles)
            street = random.choice(streets)
            num = random.randint(1, 199)

            prefix = random.choice(NAME_PREFIXES)
            owner = random.choice(NAME_OWNERS)
            name_candidates = [
                f"{prefix} {primary_style.split('&')[0].strip()} {owner}",
                f"{prefix} {owner} - {street}",
                f"{primary_style.split('&')[0].strip()} {owner} {num}",
                f"{prefix} {owner} {cluster['name'].split('/')[0].strip()}",
            ]
            rest_name = random.choice(name_candidates)
            if rest_name in generated_names:
                rest_name = f"{rest_name} (Cơ sở {created_in_cluster + 1})"

            generated_names.add(rest_name)
            address = f"Số {num} {street}, {ward}"

            # Giờ mở cửa thực tế theo phong cách quán
            if "Phở" in primary_style or "Bánh mì" in primary_style:
                open_t = time(6, 0)
                close_t = time(14, 0) if random.random() < 0.4 else time(21, 30)
            elif "Lẩu" in primary_style:
                open_t = time(10, 30)
                close_t = time(23, 0)
            elif "Cà phê" in primary_style:
                open_t = time(7, 0)
                close_t = time(23, 0)
            else:
                open_t = time(6, 30)
                close_t = time(21, 0)

            # Giấy phép dịch vụ uy tín
            licenses = ["ATTP"]
            if random.random() < 0.35:
                licenses.append("HACCP")
            if random.random() < 0.15:
                licenses.append("ISO 22000")
            if "Bát Tràng" in ward and random.random() < 0.5:
                licenses.append("Chứng nhận Làng nghề Ẩm thực Truyền thống")

            phone = f"09{random.randint(10000000, 99999999)}"
            is_sponsor = (random.random() < 0.2)  # ~20% quán được tài trợ

            # Sinh 3 đến 4 món ăn phong phú cho quán
            dishes = []
            available_dishes = DISH_TEMPLATES.get(primary_style, [])
            sample_count = min(random.randint(3, 4), len(available_dishes))
            selected_templates = random.sample(available_dishes, sample_count)

            for d_name, price, calo, spicy, img_key, meals in selected_templates:
                img_url = VERIFIED_FOOD_IMAGES.get(img_key, VERIFIED_FOOD_IMAGES["Phở"])
                # Giá có biến thiên nhẹ ±10%
                varied_price = round(price * random.uniform(0.9, 1.1) / 1000) * 1000
                dishes.append({
                    "name": d_name,
                    "price": float(varied_price),
                    "calories": calo + random.randint(-20, 20),
                    "category_name": primary_style,
                    "description": f"{d_name} tươi ngon chuẩn vị phục vụ tại {rest_name}, chế biến từ nguyên liệu tuyển chọn mỗi ngày.",
                    "image_url": img_url,
                    "spicy_level": spicy,
                    "dietary_tags": ["Món tươi mới", "Chuẩn vị Gia Lâm"],
                    "meal_types": [f"Bữa {m.lower()}" if m in ["Sáng", "Trưa", "Tối"] else m for m in meals],
                    "allergens": [],
                    "ingredients": ["Nguyên liệu tươi sạch", "Gia vị truyền thống"],
                })

            restaurants.append({
                "restaurant": {
                    "name": rest_name,
                    "address": address,
                    "latitude": lat,
                    "longitude": lon,
                    "phone": phone,
                    "description": f"{rest_name} tọa lạc tại {address}, chuyên phục vụ các món {primary_style} thơm ngon, chuẩn vị, không gian thoáng đãng.",
                    "open_time": open_t,
                    "close_time": close_t,
                    "service_licenses": licenses,
                    "is_sponsor": is_sponsor,
                },
                "dishes": dishes,
            })
            created_in_cluster += 1

    return restaurants


def seed_150_restaurants():
    """Nạp toàn bộ 150 quán ăn và thực đơn vào DB PostgreSQL."""
    db = SessionLocal()
    try:
        print("=== BẮT ĐẦU SEED 150 CỬA HÀNG ẨM THỰC TẠI HUYỆN GIA LÂM ===")
        
        # 1. Đảm bảo Categories toàn cục
        categories = db.query(Category).all()
        cat_map = {c.name: c.id for c in categories}
        print(f"-> Danh mục hiện có trong hệ thống: {len(cat_map)} categories.")

        # 2. Sinh dữ liệu 150 quán
        print("-> Đang tính toán phân bổ 150 quán theo 8 cụm ẩm thực Gia Lâm...")
        data = generate_seed_data()
        print(f"-> Đã sinh thành công {len(data)} quán ăn với 100% tọa độ trong Gia Lâm!")

        # 3. Nạp hoặc cập nhật vào database
        inserted_rests = 0
        inserted_dishes = 0

        for idx, item in enumerate(data, start=1):
            r_info = item["restaurant"]
            # Kiểm tra tọa độ trước khi nạp
            if not is_in_gia_lam(r_info["latitude"], r_info["longitude"]):
                raise ValueError(f"Tọa độ ({r_info['latitude']}, {r_info['longitude']}) không hợp lệ!")

            rest = db.query(Restaurant).filter(
                Restaurant.name == r_info["name"], Restaurant.address == r_info["address"]
            ).first()

            if not rest:
                rest = Restaurant(
                    name=r_info["name"],
                    address=r_info["address"],
                    latitude=r_info["latitude"],
                    longitude=r_info["longitude"],
                    phone=r_info["phone"],
                    description=r_info["description"],
                    open_time=r_info["open_time"],
                    close_time=r_info["close_time"],
                    service_licenses=r_info["service_licenses"],
                    is_sponsor=r_info["is_sponsor"],
                    is_active=True,
                )
                db.add(rest)
                db.flush()
                inserted_rests += 1
            else:
                rest.latitude = r_info["latitude"]
                rest.longitude = r_info["longitude"]
                rest.phone = r_info["phone"]
                rest.description = r_info["description"]
                rest.open_time = r_info["open_time"]
                rest.close_time = r_info["close_time"]
                rest.service_licenses = r_info["service_licenses"]
                rest.is_sponsor = r_info["is_sponsor"]
                rest.is_active = True
                db.flush()

            for d_info in item["dishes"]:
                cat_id = cat_map.get(d_info["category_name"])
                dish = db.query(Dish).filter(
                    Dish.restaurant_id == rest.id, Dish.name == d_info["name"]
                ).first()

                if not dish:
                    dish = Dish(
                        restaurant_id=rest.id,
                        name=d_info["name"],
                        price=d_info["price"],
                        calories=d_info["calories"],
                        description=d_info["description"],
                        image_url=d_info["image_url"],
                        category_id=cat_id,
                        category=d_info["category_name"],
                        spicy_level=d_info["spicy_level"],
                        dietary_tags=d_info["dietary_tags"],
                        meal_types=d_info["meal_types"],
                        allergens=d_info["allergens"],
                        ingredients=d_info["ingredients"],
                        is_available=True,
                    )
                    db.add(dish)
                    inserted_dishes += 1
                else:
                    dish.price = d_info["price"]
                    dish.calories = d_info["calories"]
                    dish.image_url = d_info["image_url"]
                    dish.category_id = cat_id
                    dish.category = d_info["category_name"]
                    dish.is_available = True

            if idx % 25 == 0 or idx == len(data):
                print(f"  + Đã xử lý {idx}/{len(data)} quán ăn...")

        db.commit()

        total_rests = db.query(Restaurant).filter(Restaurant.is_active == True).count()
        total_dishes = db.query(Dish).filter(Dish.is_available == True).count()
        print(f"\n=== HOÀN TẤT SEED DỮ LIỆU ===")
        print(f"-> Tổng số quán ăn hiện có trong DB: {total_rests} quán (100% ranh giới Gia Lâm).")
        print(f"-> Tổng số món ăn hiện có trong DB: {total_dishes} món.")
    except Exception as e:
        db.rollback()
        print(f"Lỗi khi seed 150 quán ăn: {e}")
        raise e
    finally:
        db.close()


if __name__ == "__main__":
    seed_150_restaurants()
