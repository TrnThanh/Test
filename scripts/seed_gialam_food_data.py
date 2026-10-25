"""
Script nạp bộ dữ liệu ẩm thực thực tế phong phú tại Huyện Gia Lâm (PTC1 Platform).
Đảm bảo 100% tọa độ nằm chính xác trong đa giác Huyện Gia Lâm (giaLamBoundaryPolygon).
Idempotent: Có thể chạy lại nhiều lần an toàn, tự động cập nhật hoặc thêm mới.
"""

import sys
import os
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

# Đa giác ranh giới Huyện Gia Lâm (chuẩn hóa đồng bộ với Mobile & Backend)
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
    """Kiểm tra tọa độ có nằm trong ranh giới đa giác Huyện Gia Lâm hay không."""
    n = len(GIA_LAM_POLYGON)
    count = 0
    for i in range(n):
        p1 = GIA_LAM_POLYGON[i]
        p2 = GIA_LAM_POLYGON[(i + 1) % n]
        if (p1[0] <= lat < p2[0]) or (p2[0] <= lat < p1[0]):
            if lon < (p2[1] - p1[1]) * (lat - p1[0]) / (p2[0] - p1[0]) + p1[1]:
                count += 1
    return (count % 2) == 1


CATEGORIES_DATA = [
    {
        "name": "Phở & Bún",
        "description": "Các món nước thanh ngọt, sợi bún phở mềm mịn, nước dùng hầm xương đậm đà chuẩn vị truyền thống.",
        "display_order": 1,
    },
    {
        "name": "Cơm & Xôi",
        "description": "Cơm niêu giòn đáy, cơm sườn nướng mật ong và xôi nếp dẻo thơm chắc dạ trọn vẹn từng bữa ăn.",
        "display_order": 2,
    },
    {
        "name": "Bánh mì",
        "description": "Bánh mì nướng giòn rụm, đầy đặn nhân pate thịt nguội, xúc xích và rau thơm tươi ngon.",
        "display_order": 3,
    },
    {
        "name": "Đồ ăn vặt",
        "description": "Nem chua rán giòn rụm, bánh tráng nướng, khoai tây lắc phô mai thơm ngon cho bữa xế vui vẻ.",
        "display_order": 4,
    },
    {
        "name": "Cà phê & Trà sữa",
        "description": "Cà phê đậm đà, trà hoa quả thanh mát giải nhiệt và trà sữa béo ngậy đầy topping.",
        "display_order": 5,
    },
    {
        "name": "Lẩu & Nướng",
        "description": "Nồi lẩu bốc khói nghi ngút và thịt nướng xèo xèo thơm phức lý tưởng cho những buổi hội ngộ sum vầy.",
        "display_order": 6,
    },
]

RESTAURANTS_AND_DISHES = [
    {
        "restaurant": {
            "name": "Bún Chả Cổng Trường Nông Nghiệp",
            "address": "Số 68 Ngô Xuân Quảng, Thị trấn Trâu Quỳ, Huyện Gia Lâm, Hà Nội",
            "latitude": 21.0036,
            "longitude": 105.9340,
            "phone": "0982345678",
            "description": "Quán bún chả nướng than hoa nức tiếng sinh viên HV Nông Nghiệp, thịt nướng thơm lừng, nước chấm chua ngọt chuẩn vị Hà Thành.",
            "open_time": time(6, 30),
            "close_time": time(21, 0),
            "service_licenses": ["ATTP", "HACCP"],
            "is_sponsor": True,
        },
        "dishes": [
            {
                "name": "Bún chả nướng than hoa",
                "price": 45000.0,
                "calories": 620,
                "category_name": "Phở & Bún",
                "description": "Chả viên và chả miếng nướng than hoa thơm nức mũi, đu đủ cà rốt giòn sần sật trong nước mắm chua ngọt ấm nóng kèm đĩa bún sợi nhỏ thanh mát.",
                "image_url": "https://images.unsplash.com/photo-1569058242253-92a9c755a0ec?w=800&auto=format&fit=crop&q=80",
                "spicy_level": 1,
                "dietary_tags": ["Món truyền thống", "Giàu đạm"],
                "meal_types": ["Bữa trưa", "Bữa tối"],
                "allergens": ["Nước mắm"],
                "ingredients": ["Thịt ba chỉ", "Thịt nạc vai", "Bún tươi", "Đu đủ", "Cà rốt", "Rau sống"],
            },
            {
                "name": "Nem rán Hà Nội giòn rụm",
                "price": 30000.0,
                "calories": 350,
                "category_name": "Đồ ăn vặt",
                "description": "Nem vỏ bánh đa nem giòn rụm, nhân thịt băm, mộc nhĩ, miến dong và trứng gà thơm bùi béo ngậy chấm nước mắm tỏi ớt.",
                "image_url": "https://images.unsplash.com/photo-1544025162-d76694265947?w=800&auto=format&fit=crop&q=80",
                "spicy_level": 0,
                "dietary_tags": ["Món truyền thống", "Khai vị"],
                "meal_types": ["Bữa trưa", "Bữa tối", "Bữa xế / Ăn vặt"],
                "allergens": ["Trứng"],
                "ingredients": ["Thịt lợn", "Miến dong", "Mộc nhĩ", "Trứng gà", "Bánh đa nem"],
            },
            {
                "name": "Bún đậu mắm tôm thập cẩm",
                "price": 55000.0,
                "calories": 680,
                "category_name": "Phở & Bún",
                "description": "Mẹt bún đậu đầy đặn gồm đậu Mơ rán giòn ngoài mềm trong, chả cốm dẻo thơm, thịt chân giò luộc mỏng và mắm tôm Thanh Hóa đánh sủi bọt quất ớt.",
                "image_url": "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800&auto=format&fit=crop&q=80",
                "spicy_level": 2,
                "dietary_tags": ["Món đặc sản", "Đậm đà"],
                "meal_types": ["Bữa trưa", "Bữa tối"],
                "allergens": ["Mắm tôm"],
                "ingredients": ["Đậu phụ Mơ", "Bún lá", "Chả cốm", "Thịt chân giò", "Rau kinh giới"],
            },
        ],
    },
    {
        "restaurant": {
            "name": "Phở Bò Gia Truyền Cổ Bi",
            "address": "Số 15 Phố Cổ Bi, Xã Cổ Bi, Huyện Gia Lâm, Hà Nội",
            "latitude": 21.0055,
            "longitude": 105.9325,
            "phone": "0912345678",
            "description": "Phở bò gia truyền ninh xương ống 24h, bò tái lăn mềm ngọt, bánh phở tươi dẻo thơm ngon nức tiếng khu Cổ Bi.",
            "open_time": time(6, 0),
            "close_time": time(14, 0),
            "service_licenses": ["ATTP"],
            "is_sponsor": False,
        },
        "dishes": [
            {
                "name": "Phở bò tái lăn đặc biệt",
                "price": 55000.0,
                "calories": 480,
                "category_name": "Phở & Bún",
                "description": "Thịt bò thăn thái mỏng xào lăn nhanh trên lửa lớn cùng tỏi thơm, nước dùng ninh từ xương ống bò trong vắt ngọt hậu kèm bánh phở dẻo dai.",
                "image_url": "https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?w=800&auto=format&fit=crop&q=80",
                "spicy_level": 1,
                "dietary_tags": ["Món nước ấm nóng", "Giàu đạm"],
                "meal_types": ["Bữa sáng", "Bữa trưa"],
                "allergens": [],
                "ingredients": ["Thịt bò thăn", "Bánh phở tươi", "Xương ống bò", "Hành hoa", "Hương thảo quả"],
            },
            {
                "name": "Phở bò chín nạm gầu giòn",
                "price": 50000.0,
                "calories": 450,
                "category_name": "Phở & Bún",
                "description": "Nạm bò luộc chín mềm thơm nức, gầu giòn sần sật ngậy béo kết hợp hoàn hảo cùng nước dùng phở truyền thống và chút giấm tỏi ớt ngâm.",
                "image_url": "https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?w=800&auto=format&fit=crop&q=80",
                "spicy_level": 0,
                "dietary_tags": ["Món nước", "Cổ truyền"],
                "meal_types": ["Bữa sáng", "Bữa trưa"],
                "allergens": [],
                "ingredients": ["Nạm bò", "Gầu bò", "Bánh phở", "Nước dùng xương hầm", "Rau mùi"],
            },
            {
                "name": "Quẩy giòn giòn ăn kèm phở",
                "price": 10000.0,
                "calories": 160,
                "category_name": "Đồ ăn vặt",
                "description": "Đĩa 3 đôi quẩy chiên vàng ruộm, giòn tan bên ngoài, xốp mềm bên trong, nhúng vào bát nước dùng phở nóng hổi đậm đà.",
                "image_url": "https://images.unsplash.com/photo-1509722747041-616f39b57569?w=800&auto=format&fit=crop&q=80",
                "spicy_level": 0,
                "dietary_tags": ["Ăn kèm", "Giòn rụm"],
                "meal_types": ["Bữa sáng"],
                "allergens": ["Gluten"],
                "ingredients": ["Bột mì", "Men nở", "Dầu thực vật"],
            },
        ],
    },
    {
        "restaurant": {
            "name": "Lẩu Nướng Sinh Viên HVNN",
            "address": "Đường Đào Đất, Thị trấn Trâu Quỳ, Huyện Gia Lâm, Hà Nội",
            "latitude": 21.0045,
            "longitude": 105.9325,
            "phone": "0976543210",
            "description": "Điểm hẹn tụ tập số 1 của sinh viên Đại học Nông Nghiệp với lẩu Thái Tomyum chua cay và thịt bò nướng tảng sốt tiêu đen.",
            "open_time": time(16, 0),
            "close_time": time(23, 0),
            "service_licenses": ["ATTP", "Chứng chỉ An toàn Vệ sinh Dịch vụ"],
            "is_sponsor": True,
        },
        "dishes": [
            {
                "name": "Set Lẩu Thái Tomyum hải sản chua cay",
                "price": 269000.0,
                "calories": 890,
                "category_name": "Lẩu & Nướng",
                "description": "Nồi lẩu thơm lừng sả ớt, riềng và lá chanh Thái, đầy ắp tôm tươi, mực ống, ba chỉ bò Mỹ cuộn nấm kim châm và rau lẩu xanh mướt.",
                "image_url": "https://images.unsplash.com/photo-1547592180-85f173990554?w=800&auto=format&fit=crop&q=80",
                "spicy_level": 2,
                "dietary_tags": ["Lẩu ấm nóng", "Ăn nhóm"],
                "meal_types": ["Bữa tối"],
                "allergens": ["Hải sản", "Tôm", "Mực"],
                "ingredients": ["Ba chỉ bò", "Tôm sú", "Mực ống", "Nấm kim châm", "Cốt Tomyum", "Lá chanh"],
            },
            {
                "name": "Bò tảng nướng sốt tiêu đen",
                "price": 139000.0,
                "calories": 650,
                "category_name": "Lẩu & Nướng",
                "description": "Thịt bò nướng tảng tươi rói tẩm ướp sốt tiêu đen cay nồng, xèo xèo trên chảo bơ nóng rực kèm sốt trứng muối béo ngậy.",
                "image_url": "https://images.unsplash.com/photo-1544025162-d76694265947?w=800&auto=format&fit=crop&q=80",
                "spicy_level": 2,
                "dietary_tags": ["Món nướng", "Giàu đạm"],
                "meal_types": ["Bữa tối"],
                "allergens": ["Bơ"],
                "ingredients": ["Thịt bò tảng", "Sốt tiêu đen", "Bơ nhạt", "Hành tây", "Nấm đùi gà"],
            },
            {
                "name": "Khoai tây chiên lắc phô mai giòn tan",
                "price": 35000.0,
                "calories": 380,
                "category_name": "Đồ ăn vặt",
                "description": "Khoai tây chiên vàng giòn rụm bên ngoài bở thơm bên trong, lắc đều cùng bột phô mai mặn ngọt béo ngậy gây nghiện.",
                "image_url": "https://images.unsplash.com/photo-1573080496219-bb080dd4f877?w=800&auto=format&fit=crop&q=80",
                "spicy_level": 0,
                "dietary_tags": ["Ăn vặt", "Món chay"],
                "meal_types": ["Bữa xế / Ăn vặt", "Bữa tối"],
                "allergens": ["Sữa", "Phô mai"],
                "ingredients": ["Khoai tây", "Bột phô mai", "Dầu thực vật"],
            },
        ],
    },
    {
        "restaurant": {
            "name": "Nhà Hàng Cơm Niêu & Lẩu Biển Hồ",
            "address": "Tầng 1 Tòa S2.01, KĐT Vinhomes Ocean Park 1, Huyện Gia Lâm, Hà Nội",
            "latitude": 20.9950,
            "longitude": 105.9550,
            "phone": "0908765432",
            "description": "Không gian sang trọng nhìn ra biển hồ nước mặn, phục vụ cơm niêu cá kho tộ đậm đà và các món hải sản tươi sống thượng hạng.",
            "open_time": time(9, 30),
            "close_time": time(22, 30),
            "service_licenses": ["HACCP", "ISO 22000", "ATTP"],
            "is_sponsor": True,
        },
        "dishes": [
            {
                "name": "Cơm niêu cá bống kho tộ",
                "price": 95000.0,
                "calories": 720,
                "category_name": "Cơm & Xôi",
                "description": "Cơm niêu đất cháy đáy giòn tan vàng ươm ăn cùng cá bống sông Đuống kho tộ đậm đà thơm mùi tiêu sọ và ớt hiểm ấm bụng.",
                "image_url": "https://images.unsplash.com/photo-1512058564366-18510be2db19?w=800&auto=format&fit=crop&q=80",
                "spicy_level": 1,
                "dietary_tags": ["Đặc sản", "Cơm niêu giòn"],
                "meal_types": ["Bữa trưa", "Bữa tối"],
                "allergens": ["Cá"],
                "ingredients": ["Gạo tám xoan", "Cá bống tươi", "Nước hàng mía", "Tiêu sọ", "Hành khô"],
            },
            {
                "name": "Cơm sườn nướng mật ong sốt BBQ",
                "price": 85000.0,
                "calories": 780,
                "category_name": "Cơm & Xôi",
                "description": "Cốt lết sườn heo nướng mật ong rừng vàng óng ả, thịt ngọt mọng nước ăn kèm chả trứng hấp, đồ chua cà rốt và canh cải thanh mát.",
                "image_url": "https://images.unsplash.com/photo-1543339308-43e59d6b73a6?w=800&auto=format&fit=crop&q=80",
                "spicy_level": 0,
                "dietary_tags": ["Giàu đạm", "Món chính"],
                "meal_types": ["Bữa trưa", "Bữa tối"],
                "allergens": ["Trứng"],
                "ingredients": ["Sườn cốt lết", "Mật ong rừng", "Gạo dẻo", "Trứng gà", "Cà chua"],
            },
            {
                "name": "Bánh mì nướng bơ tỏi xúc xích",
                "price": 35000.0,
                "calories": 390,
                "category_name": "Bánh mì",
                "description": "Bánh mì nướng bơ tỏi thơm lừng giòn tan, kẹp xúc xích hun khói nướng và sốt mayonnaise tương cà đậm đà.",
                "image_url": "https://images.unsplash.com/photo-1626074353765-517a681e40be?w=800&auto=format&fit=crop&q=80",
                "spicy_level": 0,
                "dietary_tags": ["Nhanh gọn", "Ăn sáng"],
                "meal_types": ["Bữa sáng", "Bữa xế / Ăn vặt"],
                "allergens": ["Gluten", "Bơ"],
                "ingredients": ["Bánh mì baguette", "Bơ tỏi", "Xúc xích Đức", "Mayonnaise"],
            },
        ],
    },
    {
        "restaurant": {
            "name": "The Coffee House & Tea Ocean Park",
            "address": "Khu Phố Đi Bộ Sao Biển 11, Vinhomes Ocean Park 1, Huyện Gia Lâm, Hà Nội",
            "latitude": 20.9980,
            "longitude": 105.9520,
            "phone": "0934567890",
            "description": "Quán cà phê view hồ cát trắng cực chill, cà phê rang xay nguyên chất, trà đào cam sả và các loại bánh ngọt tươi mới mỗi ngày.",
            "open_time": time(7, 0),
            "close_time": time(23, 0),
            "service_licenses": ["ATTP"],
            "is_sponsor": False,
        },
        "dishes": [
            {
                "name": "Cà phê muối béo ngậy kem cheese",
                "price": 45000.0,
                "calories": 210,
                "category_name": "Cà phê & Trà sữa",
                "description": "Cà phê Robusta Đắk Lắk đậm đà hòa quyện cùng lớp kem muối biển sánh mịn béo ngậy ngọt mặn hài hòa cực cuốn.",
                "image_url": "https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?w=800&auto=format&fit=crop&q=80",
                "spicy_level": 0,
                "dietary_tags": ["Đồ uống", "Tỉnh táo"],
                "meal_types": ["Bữa sáng", "Bữa xế / Ăn vặt", "Cả ngày"],
                "allergens": ["Sữa"],
                "ingredients": ["Cà phê Robusta", "Kem sữa tươi", "Muối hồng Himalaya", "Sữa đặc"],
            },
            {
                "name": "Trà đào cam sả hạt chia tươi mát",
                "price": 52000.0,
                "calories": 160,
                "category_name": "Cà phê & Trà sữa",
                "description": "Trà đen ủ lạnh ngát hương sả đập dập, vị cam vàng thanh khiết chua nhẹ kết hợp miếng đào giòn ngọt và hạt chia bổ dưỡng.",
                "image_url": "https://images.unsplash.com/photo-1513558161293-cdaf765ed2fd?w=800&auto=format&fit=crop&q=80",
                "spicy_level": 0,
                "dietary_tags": ["Giải nhiệt", "Thanh lọc"],
                "meal_types": ["Bữa trưa", "Bữa xế / Ăn vặt", "Cả ngày"],
                "allergens": [],
                "ingredients": ["Trà đen", "Cam tươi", "Sả tươi", "Đào ngâm giòn", "Hạt chia"],
            },
            {
                "name": "Trà sữa trân châu đường đen hoàng gia",
                "price": 55000.0,
                "calories": 380,
                "category_name": "Cà phê & Trà sữa",
                "description": "Sữa tươi thanh trùng Đà Lạt ngập tràn trân châu đen nấu mật mía dẻo dai ấm nóng, hương vị ngọt ngào quyến rũ.",
                "image_url": "https://images.unsplash.com/photo-1572490122747-3968b75cc699?w=800&auto=format&fit=crop&q=80",
                "spicy_level": 0,
                "dietary_tags": ["Đồ ngọt", "Topping ngập tràn"],
                "meal_types": ["Bữa xế / Ăn vặt", "Bữa tối"],
                "allergens": ["Sữa"],
                "ingredients": ["Sữa tươi thanh trùng", "Trân châu đen", "Đường mía nâu Hàn Quốc"],
            },
        ],
    },
    {
        "restaurant": {
            "name": "Ẩm Thực Làng Gốm Bát Tràng - Măng Mực",
            "address": "Xóm 1 Làng Cổ Bát Tràng, Xã Bát Tràng, Huyện Gia Lâm, Hà Nội",
            "latitude": 20.9747,
            "longitude": 105.9142,
            "phone": "0945678901",
            "description": "Nhà hàng di sản ẩm thực gìn giữ món canh măng mực truyền thống cỗ Bát Tràng trứ danh, gà đồi nướng mật ong và chả tôm thơm bùi.",
            "open_time": time(8, 0),
            "close_time": time(21, 30),
            "service_licenses": ["ATTP", "Chứng nhận Làng nghề Ẩm thực Truyền thống"],
            "is_sponsor": False,
        },
        "dishes": [
            {
                "name": "Canh măng mực đặc sản cỗ Bát Tràng",
                "price": 120000.0,
                "calories": 320,
                "category_name": "Phở & Bún",
                "description": "Đặc sản di sản tinh hoa làng gốm với măng nứa tước sợi chỉ vàng óng xào cùng mực câu khô xé sợi, nước ninh xương gà thanh trong ngọt hậu khó quên.",
                "image_url": "https://images.unsplash.com/photo-1547592166-23ac45744acd?w=800&auto=format&fit=crop&q=80",
                "spicy_level": 0,
                "dietary_tags": ["Di sản ẩm thực", "Đặc sản Bát Tràng"],
                "meal_types": ["Bữa trưa", "Bữa tối"],
                "allergens": ["Mực", "Hải sản"],
                "ingredients": ["Măng nứa khô tước chỉ", "Mực câu khô", "Thịt thăn lợn", "Nước hầm gà"],
            },
            {
                "name": "Gà đồi nướng mật ong làng cổ",
                "price": 280000.0,
                "calories": 820,
                "category_name": "Lẩu & Nướng",
                "description": "Gà ri thả đồi thịt chắc ngọt, tẩm ướp hạt dổi mắc khén nướng mật ong than hoa da vàng giòn ruộm ăn cùng xôi nếp nương dẻo thơm.",
                "image_url": "https://images.unsplash.com/photo-1598515214211-89d3c73ae83b?w=800&auto=format&fit=crop&q=80",
                "spicy_level": 1,
                "dietary_tags": ["Món nướng", "Món nhậu sum vầy"],
                "meal_types": ["Bữa trưa", "Bữa tối"],
                "allergens": [],
                "ingredients": ["Gà ri thả đồi", "Mật ong hoa rừng", "Hạt dổi", "Mắc khén", "Lá chanh"],
            },
            {
                "name": "Xôi xéo mỡ hành ruốc nấm",
                "price": 30000.0,
                "calories": 420,
                "category_name": "Cơm & Xôi",
                "description": "Xôi nếp cái hoa vàng đồ hai lửa dẻo quánh, phủ lớp đậu xanh nghiền mịn, hành phi giòn tan và rưới mỡ gà thơm phức ấm bụng.",
                "image_url": "https://images.unsplash.com/photo-1516684732162-798a0062be99?w=800&auto=format&fit=crop&q=80",
                "spicy_level": 0,
                "dietary_tags": ["Món truyền thống", "No lâu"],
                "meal_types": ["Bữa sáng", "Bữa trưa"],
                "allergens": [],
                "ingredients": ["Gạo nếp cái hoa vàng", "Đậu xanh tiêu", "Hành ta phi giòn", "Mỡ gà ta"],
            },
        ],
    },
    {
        "restaurant": {
            "name": "Bún Riêu Cua Cột Đèn Ninh Hiệp",
            "address": "Dốc Chợ Ninh Hiệp, Xã Ninh Hiệp, Huyện Gia Lâm, Hà Nội",
            "latitude": 21.0575,
            "longitude": 105.9380,
            "phone": "0967890123",
            "description": "Tô bún riêu cua đồng xịn đầy ắp gạch riêu béo ngậy, bắp bò tái hoa, đậu phụ rán giòn và sườn sụn sần sật nức tiếng chợ vải.",
            "open_time": time(6, 0),
            "close_time": time(19, 30),
            "service_licenses": ["ATTP"],
            "is_sponsor": False,
        },
        "dishes": [
            {
                "name": "Bún riêu cua bắp bò sườn sụn thập cẩm",
                "price": 55000.0,
                "calories": 520,
                "category_name": "Phở & Bún",
                "description": "Tô bún đỏ rực cà chua mọng nước, tảng gạch riêu cua đồng thơm lừng, thịt bắp bò hoa giòn ngọt và sườn sụn non ninh mềm sần sật.",
                "image_url": "https://images.unsplash.com/photo-1617093727343-374698b1b08d?w=800&auto=format&fit=crop&q=80",
                "spicy_level": 1,
                "dietary_tags": ["Món nước đậm đà", "Đặc sản"],
                "meal_types": ["Bữa sáng", "Bữa trưa"],
                "allergens": ["Cua đồng"],
                "ingredients": ["Cua đồng giã tay", "Bắp bò hoa", "Sườn sụn non", "Đậu rán", "Dấm bỗng nếp"],
            },
            {
                "name": "Bún ốc chuối đậu tía tô",
                "price": 45000.0,
                "calories": 460,
                "category_name": "Phở & Bún",
                "description": "Ốc nhồi béo múp giòn sần sật, chuối xanh bùi dẻo, đậu rán vàng ngấm trọn nước dùng chua thanh dấm bỗng thơm nồng lá tía tô.",
                "image_url": "https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=800&auto=format&fit=crop&q=80",
                "spicy_level": 1,
                "dietary_tags": ["Món dân dã", "Thanh mát"],
                "meal_types": ["Bữa sáng", "Bữa trưa"],
                "allergens": ["Ốc"],
                "ingredients": ["Ốc nhồi ta", "Chuối xanh", "Đậu phụ Mơ", "Tía tô", "Lá lốt"],
            },
            {
                "name": "Bánh mì que cay Hải Phòng giòn rụm",
                "price": 15000.0,
                "calories": 220,
                "category_name": "Bánh mì",
                "description": "Bánh mì que dài thon nhỏ nướng giòn rụm, quết đẫm pate gan béo ngậy và chấm kèm chí chương ớt đỏ cay nồng đúng điệu.",
                "image_url": "https://images.unsplash.com/photo-1509722747041-616f39b57569?w=800&auto=format&fit=crop&q=80",
                "spicy_level": 2,
                "dietary_tags": ["Ăn nhanh", "Cay nồng"],
                "meal_types": ["Bữa sáng", "Bữa xế / Ăn vặt"],
                "allergens": ["Gluten"],
                "ingredients": ["Bột mì", "Pate gan heo", "Tương ớt chí chương"],
            },
        ],
    },
    {
        "restaurant": {
            "name": "Quán Cơm Bình Dân Ga Yên Viên",
            "address": "Số 88 Phố Hà Huy Tập, Thị trấn Yên Viên, Huyện Gia Lâm, Hà Nội",
            "latitude": 21.0805,
            "longitude": 105.9020,
            "phone": "0989012345",
            "description": "Quán cơm phục vụ hành khách ga tàu và người dân khu Yên Viên hơn 15 năm, cơm nóng hổi, sườn rim chua ngọt, cá kho tiêu và canh cua đồng mồng tơi.",
            "open_time": time(6, 30),
            "close_time": time(20, 30),
            "service_licenses": ["ATTP"],
            "is_sponsor": False,
        },
        "dishes": [
            {
                "name": "Cơm đĩa sườn rim chua ngọt đặc biệt",
                "price": 45000.0,
                "calories": 690,
                "category_name": "Cơm & Xôi",
                "description": "Đĩa cơm gạo thơm dẻo đầy đặn, sườn non rim sốt me chua ngọt đậm đà óng ánh, ăn kèm rau muống xào tỏi và bát canh cua đồng thanh mát.",
                "image_url": "https://images.unsplash.com/photo-1543339308-43e59d6b73a6?w=800&auto=format&fit=crop&q=80",
                "spicy_level": 0,
                "dietary_tags": ["Cơm bình dân", "Chắc dạ"],
                "meal_types": ["Bữa trưa", "Bữa tối"],
                "allergens": [],
                "ingredients": ["Gạo Khang Dân", "Sườn heo non", "Sốt me chua ngọt", "Rau muống", "Tỏi"],
            },
            {
                "name": "Cơm gà đùi xối mỡ giòn da",
                "price": 50000.0,
                "calories": 750,
                "category_name": "Cơm & Xôi",
                "description": "Đùi gà góc tư chiên xối mỡ da vàng rộm giòn tan, thịt bên trong mềm mọng thơm phức kèm cơm đảo nghệ thơm ngậy.",
                "image_url": "https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=800&auto=format&fit=crop&q=80",
                "spicy_level": 0,
                "dietary_tags": ["Giàu đạm", "Giòn rụm"],
                "meal_types": ["Bữa trưa", "Bữa tối"],
                "allergens": [],
                "ingredients": ["Đùi gà góc tư", "Gạo đảo nghệ", "Dưa chuột", "Cà chua", "Nước mắm tỏi ớt"],
            },
            {
                "name": "Bánh mì chảo thập cẩm pate trứng xúc xích",
                "price": 40000.0,
                "calories": 580,
                "category_name": "Bánh mì",
                "description": "Chảo gang nóng hổi xèo xèo gồm trứng ốp la lòng đào, pate rán xém cạnh, xúc xích rán và sốt tiêu cà chua đậm đà chấm bánh mì nóng giòn.",
                "image_url": "https://images.unsplash.com/photo-1626074353765-517a681e40be?w=800&auto=format&fit=crop&q=80",
                "spicy_level": 1,
                "dietary_tags": ["Món nóng sốt", "Đậm đà"],
                "meal_types": ["Bữa sáng", "Bữa tối"],
                "allergens": ["Trứng", "Gluten"],
                "ingredients": ["Trứng gà", "Pate heo", "Xúc xích", "Bánh mì nướng", "Sốt cà chua tiêu đen"],
            },
        ],
    },
]


def seed_food_data():
    """Hàm nạp dữ liệu chính với kiểm tra ranh giới Gia Lâm và bảo toàn dữ liệu."""
    db = SessionLocal()
    try:
        print("[1/5] Kiểm tra và tạo/cập nhật Danh mục thực đơn (Categories toàn cục)...")
        category_map = {}
        for cat_data in CATEGORIES_DATA:
            cat = db.query(Category).filter(Category.name.ilike(cat_data["name"])).first()
            if not cat:
                cat = Category(
                    name=cat_data["name"],
                    description=cat_data["description"],
                    display_order=cat_data["display_order"],
                    is_active=True,
                )
                db.add(cat)
                db.flush()
                print(f"  + Thêm mới Category: {cat.name} (id={cat.id})")
            else:
                cat.description = cat_data["description"]
                cat.display_order = cat_data["display_order"]
                cat.is_active = True
                db.flush()
                print(f"  * Cập nhật Category: {cat.name} (id={cat.id})")
            category_map[cat.name] = cat.id

        print("\n[2/5] Dọn dẹp dữ liệu quán ăn mẫu nằm ngoài Huyện Gia Lâm...")
        out_of_bounds_rests = db.query(Restaurant).all()
        for r in out_of_bounds_rests:
            if not is_in_gia_lam(r.latitude, r.longitude):
                print(f"  - Xoá quán nằm ngoài Gia Lâm: {r.name} ({r.latitude}, {r.longitude}) - id={r.id}")
                db.delete(r)
        db.flush()

        print("\n[3/5] Nạp các Quán ăn thực tế bên trong Huyện Gia Lâm...")
        rest_count = 0
        dish_count = 0

        for item in RESTAURANTS_AND_DISHES:
            r_info = item["restaurant"]
            lat = r_info["latitude"]
            lon = r_info["longitude"]

            # Kiểm tra tọa độ trong Gia Lâm
            if not is_in_gia_lam(lat, lon):
                raise ValueError(f"Lỗi: Tọa độ quán {r_info['name']} ({lat}, {lon}) nằm ngoài ranh giới Gia Lâm!")

            # Tìm quán theo tên và địa chỉ
            rest = (
                db.query(Restaurant)
                .filter(Restaurant.name == r_info["name"], Restaurant.address == r_info["address"])
                .first()
            )
            if not rest:
                rest = Restaurant(
                    name=r_info["name"],
                    address=r_info["address"],
                    latitude=lat,
                    longitude=lon,
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
                print(f"  + Tạo Quán ăn mới: {rest.name} (id={rest.id}, Gia Lâm: OK)")
            else:
                rest.latitude = lat
                rest.longitude = lon
                rest.phone = r_info["phone"]
                rest.description = r_info["description"]
                rest.open_time = r_info["open_time"]
                rest.close_time = r_info["close_time"]
                rest.service_licenses = r_info["service_licenses"]
                rest.is_sponsor = r_info["is_sponsor"]
                rest.is_active = True
                db.flush()
                print(f"  * Cập nhật Quán ăn: {rest.name} (id={rest.id}, Gia Lâm: OK)")

            rest_count += 1

            # Nạp danh sách món ăn của quán
            for d_info in item["dishes"]:
                cat_id = category_map.get(d_info["category_name"])
                dish = (
                    db.query(Dish)
                    .filter(Dish.restaurant_id == rest.id, Dish.name == d_info["name"])
                    .first()
                )
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
                    print(f"    - Thêm món: {dish.name} ({dish.price:,.0f}đ, {dish.calories} kcal)")
                else:
                    dish.price = d_info["price"]
                    dish.calories = d_info["calories"]
                    dish.description = d_info["description"]
                    dish.image_url = d_info["image_url"]
                    dish.category_id = cat_id
                    dish.category = d_info["category_name"]
                    dish.spicy_level = d_info["spicy_level"]
                    dish.dietary_tags = d_info["dietary_tags"]
                    dish.meal_types = d_info["meal_types"]
                    dish.allergens = d_info["allergens"]
                    dish.ingredients = d_info["ingredients"]
                    dish.is_available = True
                    print(f"    * Cập nhật món: {dish.name} ({dish.price:,.0f}đ, {dish.calories} kcal)")
                dish_count += 1

        print("\n[4/5] Liên kết Danh mục thực đơn với Thời tiết (WeatherCategory)...")
        # Liên kết danh mục với các thời tiết phù hợp để gợi ý thông minh
        weather_records = db.query(Weather).all()
        for w in weather_records:
            # Nếu thời tiết mát mẻ / se lạnh hoặc mưa: ưu tiên Phở & Bún, Lẩu & Nướng, Cơm & Xôi
            cool_categories = ["Phở & Bún", "Lẩu & Nướng", "Cơm & Xôi"]
            hot_categories = ["Cà phê & Trà sữa", "Đồ ăn vặt", "Bánh mì"]

            target_cat_names = cool_categories if ("mát" in (w.description or "").lower() or "lạnh" in (w.description or "").lower() or "mưa" in (w.name or "").lower()) else (cool_categories + hot_categories)

            for c_name in target_cat_names:
                cat_id = category_map.get(c_name)
                if cat_id:
                    exists = db.query(WeatherCategory).filter_by(weather_id=w.id, category_id=cat_id).first()
                    if not exists:
                        wc = WeatherCategory(weather_id=w.id, category_id=cat_id)
                        db.add(wc)

        db.commit()
        print(f"\n[5/5] Hoàn thành nạp dữ liệu: {rest_count} quán ăn, {dish_count} món ăn, {len(category_map)} danh mục!")
    except Exception as e:
        db.rollback()
        print(f"Lỗi khi seed dữ liệu: {e}")
        raise e
    finally:
        db.close()


if __name__ == "__main__":
    seed_food_data()
