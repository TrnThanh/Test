"""Service chuẩn hóa và làm chuẩn thực đơn món ăn dựa trên tên nhà hàng.

Tự động phân loại 204 quán ăn theo tên thành các phong cách ẩm thực đặc trưng:
Phở, Bún chả, Bún đậu, Bún bò Huế, Bún riêu, Bún cá, Cơm tấm, Cơm gà, Cơm niêu,
Bánh mì, Bánh cuốn, Bánh xèo, Nem nướng, Cháo & Cháo ếch, Ốc & Hải sản,
Lẩu nướng BBQ, Dê núi, Vịt & Ngan, Gà Mạnh Hoạch, Đồ chay, Sushi Nhật,
Đồ Hàn & Mì cay, Pizza & Fastfood, Cà phê, Trà sữa, Chè & Tào phớ, Mâm cỗ Bát Tràng,
Đặc sản Tây Bắc, Chả cá Lã Vọng, Món Thái, Dimsum Trung Hoa, Bia nhậu...

Đồng thời tự động đồng bộ nguyên liệu ẩm thực thật từ bể 195 Master Ingredients.
"""

import logging
import re
from typing import Dict, List, Tuple, Any, Optional
from sqlalchemy import text, select
from sqlalchemy.orm import Session

from server.app.models.restaurant import Restaurant
from server.app.models.dish import Dish
from server.app.models.category import Category
from server.app.models.ingredient import Ingredient, DishIngredient

logger = logging.getLogger(__name__)

# Từ điển định nghĩa các chủ đề ẩm thực chuyên biệt
# Cấu trúc mỗi món: (name, price, calories, spicy_level, category_name, meal_types, ingredients)
THEME_DISH_CATALOG: Dict[str, List[Tuple[str, float, int, int, str, List[str], List[str]]]] = {
    "pho": [
        (
            "Phở bò tái lăn đặc biệt",
            55000,
            480,
            1,
            "Phở & Bún",
            ["Bữa sáng", "Bữa trưa"],
            ["Bánh phở tươi Hà Nội", "Thịt bò bắp hoa", "Hành lá (hành hoa)", "Tỏi tép Lý Sơn", "Nước mắm cá cơm Phú Quốc"],
        ),
        (
            "Phở bò chín nạm gầu giòn",
            50000,
            460,
            0,
            "Phở & Bún",
            ["Bữa sáng", "Bữa trưa"],
            ["Bánh phở tươi Hà Nội", "Nạm bò vân mỡ", "Gầu bò giòn", "Hành lá (hành hoa)", "Quế hồi thảo quả"],
        ),
        (
            "Phở gà ta đùi xé da giòn",
            45000,
            420,
            0,
            "Phở & Bún",
            ["Bữa sáng", "Bữa trưa"],
            ["Bánh phở tươi Hà Nội", "Thịt gà ta thả vườn", "Lá chanh bánh tẻ", "Hành lá (hành hoa)", "Gừng củ tươi"],
        ),
        (
            "Quẩy giòn vàng ruộm ăn phở",
            10000,
            150,
            0,
            "Đồ ăn vặt",
            ["Bữa sáng", "Bữa trưa"],
            ["Quẩy giòn vàng ruộm"],
        ),
        (
            "Trứng gà ta trần nước dùng",
            10000,
            90,
            0,
            "Phở & Bún",
            ["Bữa sáng", "Bữa trưa"],
            ["Trứng gà ta"],
        ),
    ],
    "bun_cha": [
        (
            "Bún chả nướng than hoa truyền thống",
            45000,
            620,
            1,
            "Phở & Bún",
            ["Bữa trưa", "Bữa tối"],
            ["Bún tươi sợi nhỏ", "Thịt heo ba chỉ", "Nạc vai heo", "Nước mắm cá cơm Phú Quốc", "Rau húng quế", "Đu đủ non"],
        ),
        (
            "Nem cua bể giòn rụm Hải Phòng",
            25000,
            280,
            0,
            "Đồ ăn vặt",
            ["Bữa trưa", "Bữa tối"],
            ["Cua biển Cà Mau", "Thịt heo ba chỉ", "Nấm mộc nhĩ", "Trứng gà ta", "Bún tươi sợi nhỏ"],
        ),
        (
            "Chả que tre nướng than hoa",
            50000,
            600,
            1,
            "Phở & Bún",
            ["Bữa trưa", "Bữa tối"],
            ["Bún tươi sợi nhỏ", "Thịt heo ba chỉ", "Hành tím Kinh Môn", "Nước mắm cá cơm Phú Quốc"],
        ),
    ],
    "bun_dau": [
        (
            "Mẹt bún đậu mắm tôm thập cẩm đặc biệt",
            55000,
            680,
            2,
            "Phở & Bún",
            ["Bữa trưa", "Bữa tối"],
            ["Bún tươi sợi nhỏ", "Đậu hũ mơ chiên vàng", "Mắm tôm Thanh Hóa", "Thịt heo ba chỉ", "Rau kinh giới", "Quất tươi thơm ngát"],
        ),
        (
            "Chả cốm Hà Nội chiên giòn rụm",
            30000,
            240,
            0,
            "Đồ ăn vặt",
            ["Bữa trưa", "Bữa tối"],
            ["Nạc vai heo", "Hạt nêm từ thịt"],
        ),
        (
            "Nem chua rán giòn rụm phố cổ",
            35000,
            260,
            1,
            "Đồ ăn vặt",
            ["Bữa trưa", "Bữa tối", "Bữa xế / Ăn vặt"],
            ["Bột chiên giòn", "Tương ớt cay nồng"],
        ),
        (
            "Lòng dồi chiên giòn thơm nức",
            40000,
            310,
            1,
            "Đồ ăn vặt",
            ["Bữa trưa", "Bữa tối"],
            ["Mắm tôm Thanh Hóa", "Rau húng quế", "Ớt chỉ thiên cay xé"],
        ),
    ],
    "bun_bo": [
        (
            "Bún bò Huế đặc biệt giò nạm gầu",
            55000,
            580,
            2,
            "Phở & Bún",
            ["Bữa sáng", "Bữa trưa", "Bữa tối"],
            ["Bún bò Huế sợi to", "Nạm bò vân mỡ", "Móng giò heo", "Sả cây tươi", "Ớt chỉ thiên cay xé", "Hành lá (hành hoa)"],
        ),
        (
            "Bún bò Huế bắp hoa chả cua",
            50000,
            520,
            2,
            "Phở & Bún",
            ["Bữa sáng", "Bữa trưa", "Bữa tối"],
            ["Bún bò Huế sợi to", "Thịt bò bắp hoa", "Cua biển Cà Mau", "Sả cây tươi", "Rau húng quế"],
        ),
        (
            "Bún giò gân cay nồng xứ Huế",
            50000,
            540,
            2,
            "Phở & Bún",
            ["Bữa sáng", "Bữa trưa", "Bữa tối"],
            ["Bún bò Huế sợi to", "Móng giò heo", "Ớt chỉ thiên cay xé", "Sả cây tươi"],
        ),
    ],
    "bun_ca": [
        (
            "Bún cá rô đồng chiên giòn ngọt nước",
            45000,
            460,
            1,
            "Phở & Bún",
            ["Bữa sáng", "Bữa trưa"],
            ["Bún tươi sợi nhỏ", "Chả cá thát lát", "Rau thì là", "Cà chua chín mọng", "Nước mắm cá cơm Phú Quốc"],
        ),
        (
            "Bún cá cay Hải Phòng chả cá măng chua",
            50000,
            490,
            2,
            "Phở & Bún",
            ["Bữa sáng", "Bữa trưa"],
            ["Bún tươi sợi nhỏ", "Chả cá thát lát", "Măng củ chua", "Ớt chỉ thiên cay xé", "Rau cần"],
        ),
        (
            "Bún cá thu biển chả mực Hạ Long",
            55000,
            520,
            1,
            "Phở & Bún",
            ["Bữa sáng", "Bữa trưa"],
            ["Bún tươi sợi nhỏ", "Cá thu một nắng", "Mực ống tươi", "Cà chua chín mọng", "Rau thì là"],
        ),
    ],
    "bun_rieu": [
        (
            "Bún riêu cua bắp bò sườn sụn tóp mỡ",
            55000,
            560,
            1,
            "Phở & Bún",
            ["Bữa sáng", "Bữa trưa"],
            ["Bún tươi sợi nhỏ", "Cua biển Cà Mau", "Thịt bò bắp hoa", "Sườn sụn heo", "Đậu hũ mơ chiên vàng", "Cà chua chín mọng"],
        ),
        (
            "Bánh đa cua Hải Phòng đỏ au chả lá lốt",
            50000,
            510,
            1,
            "Phở & Bún",
            ["Bữa sáng", "Bữa trưa"],
            ["Bánh đa đỏ Hải Phòng", "Lá lốt non", "Thịt heo ba chỉ", "Rau muống nước", "Hành phi giòn rụm"],
        ),
        (
            "Bún riêu ốc chuối đậu tía tô",
            45000,
            470,
            1,
            "Phở & Bún",
            ["Bữa sáng", "Bữa trưa"],
            ["Bún tươi sợi nhỏ", "Ốc hương biển", "Đậu hũ mơ chiên vàng", "Rau tía tô", "Cà chua chín mọng"],
        ),
    ],
    "bun_tron_pho_tron": [
        (
            "Phở gà trộn chua ngọt đậu phộng hành phi",
            45000,
            460,
            1,
            "Phở & Bún",
            ["Bữa trưa", "Bữa tối"],
            ["Bánh phở tươi Hà Nội", "Thịt gà ta thả vườn", "Đậu phộng rang", "Hành phi giòn rụm", "Rau mùi ta"],
        ),
        (
            "Bún bò trộn Nam Bộ thanh mát",
            50000,
            490,
            1,
            "Phở & Bún",
            ["Bữa trưa", "Bữa tối"],
            ["Bún tươi sợi nhỏ", "Thăn bò mềm", "Giá đỗ tươi", "Đậu phộng rang", "Hành phi giòn rụm"],
        ),
        (
            "Miến lươn trộn sốt me chua cay",
            55000,
            480,
            2,
            "Phở & Bún",
            ["Bữa trưa", "Bữa tối"],
            ["Miến dong Tây Bắc", "Rau răm tươi", "Nước cốt me chua ngọt", "Đậu phộng rang"],
        ),
    ],
    "com_tam": [
        (
            "Cơm tấm sườn bì chả trứng ốp la",
            55000,
            760,
            0,
            "Cơm & Xôi",
            ["Bữa trưa", "Bữa tối"],
            ["Gạo Tám xoan Hải Hậu", "Sườn non heo", "Trứng gà ta", "Dưa leo baby", "Nước mắm cá cơm Phú Quốc"],
        ),
        (
            "Cơm tấm sườn cây nướng mật ong",
            60000,
            780,
            0,
            "Cơm & Xôi",
            ["Bữa trưa", "Bữa tối"],
            ["Gạo thơm ST25", "Sườn non heo", "Mật ong hoa nhãn", "Dưa leo baby"],
        ),
        (
            "Canh khổ qua nhồi thịt băm thanh mát",
            20000,
            160,
            0,
            "Cơm & Xôi",
            ["Bữa trưa", "Bữa tối"],
            ["Nạc vai heo", "Nấm mộc nhĩ", "Hành lá (hành hoa)"],
        ),
        (
            "Cơm tấm đùi gà nướng mỡ hành",
            50000,
            720,
            0,
            "Cơm & Xôi",
            ["Bữa trưa", "Bữa tối"],
            ["Gạo thơm ST25", "Đùi gà góc tư", "Hành lá (hành hoa)", "Nước mắm cá cơm Phú Quốc"],
        ),
    ],
    "com_ga": [
        (
            "Cơm gà xối mỡ giòn da hạt dẻo",
            50000,
            750,
            0,
            "Cơm & Xôi",
            ["Bữa trưa", "Bữa tối"],
            ["Gạo thơm ST25", "Đùi gà góc tư", "Dưa leo baby", "Cà chua chín mọng", "Nước mắm cá cơm Phú Quốc"],
        ),
        (
            "Cơm gà xé phay bóp hành tây rau răm",
            45000,
            680,
            1,
            "Cơm & Xôi",
            ["Bữa trưa", "Bữa tối"],
            ["Gạo thơm ST25", "Thịt gà ta thả vườn", "Rau răm tươi", "Hành tím Kinh Môn", "Quất tươi thơm ngát"],
        ),
        (
            "Cơm gà nướng sốt cay mật ong",
            55000,
            740,
            2,
            "Cơm & Xôi",
            ["Bữa trưa", "Bữa tối"],
            ["Gạo thơm ST25", "Cánh gà tươi", "Mật ong hoa nhãn", "Tương ớt cay nồng"],
        ),
    ],
    "com_nieu": [
        (
            "Cơm niêu bò sốt tiêu đen cháy 2 mặt",
            90000,
            760,
            1,
            "Cơm & Xôi",
            ["Bữa trưa", "Bữa tối"],
            ["Gạo thơm ST25", "Thăn bò mềm", "Sốt tiêu đen Hồng Kông", "Hành tím Kinh Môn"],
        ),
        (
            "Cơm niêu gà sốt nấm cháy giòn",
            80000,
            710,
            0,
            "Cơm & Xôi",
            ["Bữa trưa", "Bữa tối"],
            ["Gạo thơm ST25", "Thịt gà ta thả vườn", "Nấm hương tươi", "Dầu hào hảo hạng"],
        ),
        (
            "Cơm niêu cá bống kho tộ đậm đà",
            95000,
            730,
            1,
            "Cơm & Xôi",
            ["Bữa trưa", "Bữa tối"],
            ["Gạo thơm ST25", "Cá bống tượng", "Tiêu đen Phú Quốc", "Nước mắm cá cơm Phú Quốc"],
        ),
        (
            "Canh cua đồng mồng tơi mướp hương",
            35000,
            140,
            0,
            "Cơm & Xôi",
            ["Bữa trưa", "Bữa tối"],
            ["Cua biển Cà Mau", "Rau mồng tơi", "Mướp hương"],
        ),
    ],
    "com_binh_dan": [
        (
            "Suất cơm sườn rim chua ngọt đậm vị",
            45000,
            690,
            0,
            "Cơm & Xôi",
            ["Bữa trưa", "Bữa tối"],
            ["Gạo Tám xoan Hải Hậu", "Sườn non heo", "Sốt chua ngọt", "Dưa leo baby"],
        ),
        (
            "Suất cơm thịt kho tàu trứng cút béo ngậy",
            40000,
            680,
            0,
            "Cơm & Xôi",
            ["Bữa trưa", "Bữa tối"],
            ["Gạo Tám xoan Hải Hậu", "Thịt heo ba chỉ", "Trứng cút tươi", "Nước mắm cá cơm Phú Quốc"],
        ),
        (
            "Suất cơm đùi gà chiên nước mắm tỏi ớt",
            45000,
            720,
            1,
            "Cơm & Xôi",
            ["Bữa trưa", "Bữa tối"],
            ["Gạo Tám xoan Hải Hậu", "Đùi gà góc tư", "Tỏi tép Lý Sơn", "Nước mắm cá cơm Phú Quốc"],
        ),
        (
            "Canh chua thịt băm nấu dứa giá đỗ",
            15000,
            110,
            0,
            "Cơm & Xôi",
            ["Bữa trưa", "Bữa tối"],
            ["Nạc vai heo", "Cà chua chín mọng", "Giá đỗ tươi", "Hành lá (hành hoa)"],
        ),
    ],
    "xoi": [
        (
            "Xôi xéo mỡ hành ruốc thịt thơm bùi",
            30000,
            450,
            0,
            "Cơm & Xôi",
            ["Bữa sáng", "Bữa trưa"],
            ["Gạo nếp cái hoa vàng", "Đậu xanh xát vỏ", "Hành phi giòn rụm", "Nạc vai heo"],
        ),
        (
            "Xôi chả mực giòn dai nóng hổi",
            40000,
            490,
            0,
            "Cơm & Xôi",
            ["Bữa sáng", "Bữa trưa"],
            ["Gạo nếp cái hoa vàng", "Mực ống tươi", "Hành phi giòn rụm", "Nước mắm cá cơm Phú Quốc"],
        ),
        (
            "Xôi thịt kho trứng lòng đào béo ngậy",
            35000,
            540,
            0,
            "Cơm & Xôi",
            ["Bữa sáng", "Bữa trưa"],
            ["Gạo nếp cái hoa vàng", "Thịt heo ba chỉ", "Trứng gà ta", "Hành phi giòn rụm"],
        ),
        (
            "Xôi gà xé nấm hương thơm lừng",
            35000,
            470,
            0,
            "Cơm & Xôi",
            ["Bữa sáng", "Bữa trưa"],
            ["Gạo nếp cái hoa vàng", "Thịt gà ta thả vườn", "Nấm hương tươi", "Hành phi giòn rụm"],
        ),
    ],
    "chao": [
        (
            "Cháo ếch Singapore niêu đất cay nồng",
            85000,
            510,
            2,
            "Phở & Bún",
            ["Bữa trưa", "Bữa tối"],
            ["Gạo Tám xoan Hải Hậu", "Gừng củ tươi", "Ớt chỉ thiên cay xé", "Dầu hào hảo hạng", "Hành lá (hành hoa)"],
        ),
        (
            "Cháo sườn sụn niêu đất quẩy giòn",
            40000,
            430,
            0,
            "Phở & Bún",
            ["Bữa sáng", "Bữa trưa", "Bữa tối"],
            ["Gạo Tám xoan Hải Hậu", "Sườn sụn heo", "Quẩy giòn vàng ruộm", "Tiêu đen Phú Quốc", "Hành lá (hành hoa)"],
        ),
        (
            "Cháo lòng heo hạt gạo hoa vàng",
            45000,
            460,
            1,
            "Phở & Bún",
            ["Bữa sáng", "Bữa trưa"],
            ["Gạo Tám xoan Hải Hậu", "Tai heo giòn", "Rau tía tô", "Hành lá (hành hoa)", "Tiêu đen Phú Quốc"],
        ),
        (
            "Cháo gà ta hạt sen bùi ngọt",
            40000,
            420,
            0,
            "Phở & Bún",
            ["Bữa sáng", "Bữa trưa", "Bữa tối"],
            ["Gạo Tám xoan Hải Hậu", "Thịt gà ta thả vườn", "Hạt sen tươi", "Hành lá (hành hoa)", "Tiêu đen Phú Quốc"],
        ),
    ],
    "banh_mi": [
        (
            "Bánh mì pate chả thịt nguội giòn rụm",
            25000,
            420,
            0,
            "Bánh mì",
            ["Bữa sáng", "Bữa xế / Ăn vặt"],
            ["Bánh mì baguette", "Thịt heo ba chỉ", "Dưa leo baby", "Rau mùi ta", "Sốt mayonnaise"],
        ),
        (
            "Bánh mì chảo thập cẩm pate trứng xúc xích",
            40000,
            580,
            1,
            "Bánh mì",
            ["Bữa sáng", "Bữa tối"],
            ["Bánh mì baguette", "Trứng gà ta", "Bơ lạt thực vật", "Cà chua chín mọng"],
        ),
        (
            "Bánh mì que cay Hải Phòng nướng giòn",
            15000,
            220,
            2,
            "Bánh mì",
            ["Bữa sáng", "Bữa xế / Ăn vặt"],
            ["Bánh mì baguette", "Tương ớt cay nồng"],
        ),
        (
            "Bánh mì bò sốt tiêu đen phô mai",
            45000,
            520,
            1,
            "Bánh mì",
            ["Bữa sáng", "Bữa trưa", "Bữa tối"],
            ["Bánh mì baguette", "Thăn bò mềm", "Phô mai Cheddar", "Sốt tiêu đen Hồng Kông"],
        ),
    ],
    "banh_cuon": [
        (
            "Bánh cuốn nóng chả lụa hành phi thơm nức",
            35000,
            380,
            0,
            "Bánh mì",
            ["Bữa sáng", "Bữa trưa"],
            ["Nạc vai heo", "Nấm mộc nhĩ", "Hành phi giòn rụm", "Nước mắm cá cơm Phú Quốc"],
        ),
        (
            "Bánh cuốn trứng lòng đào béo ngậy",
            35000,
            410,
            0,
            "Bánh mì",
            ["Bữa sáng", "Bữa trưa"],
            ["Trứng gà ta", "Hành phi giòn rụm", "Nước mắm cá cơm Phú Quốc"],
        ),
        (
            "Bánh cuốn thịt nướng than hoa",
            45000,
            460,
            1,
            "Bánh mì",
            ["Bữa sáng", "Bữa trưa"],
            ["Thịt heo ba chỉ", "Hành phi giòn rụm", "Nước mắm cá cơm Phú Quốc", "Rau húng quế"],
        ),
    ],
    "banh_xeo": [
        (
            "Bánh xèo giòn rụm tôm nhảy miền Tây",
            50000,
            520,
            1,
            "Bánh mì",
            ["Bữa trưa", "Bữa tối"],
            ["Tôm sú tươi", "Thịt heo ba chỉ", "Giá đỗ tươi", "Xà lách xoăn", "Nước mắm cá cơm Phú Quốc"],
        ),
        (
            "Nem lụi nướng sả cây thơm lừng",
            45000,
            440,
            1,
            "Bánh mì",
            ["Bữa trưa", "Bữa tối"],
            ["Nạc vai heo", "Sả cây tươi", "Bánh tráng", "Nước mắm cá cơm Phú Quốc"],
        ),
        (
            "Bánh khọt tôm thịt nước cốt dừa",
            50000,
            480,
            0,
            "Bánh mì",
            ["Bữa trưa", "Bữa tối"],
            ["Tôm sú tươi", "Dừa nạo & Nước cốt dừa", "Hành lá (hành hoa)"],
        ),
    ],
    "nem_nuong": [
        (
            "Suất nem nướng Nha Trang cuốn bánh tráng",
            50000,
            510,
            1,
            "Đồ ăn vặt",
            ["Bữa trưa", "Bữa tối"],
            ["Nạc vai heo", "Dưa leo baby", "Xà lách xoăn", "Nước mắm cá cơm Phú Quốc", "Đậu phộng rang"],
        ),
        (
            "Ram bắp giòn rụm sốt tương ngọt",
            40000,
            380,
            0,
            "Đồ ăn vặt",
            ["Bữa trưa", "Bữa tối"],
            ["Bắp mỹ ngọt", "Bột chiên giòn", "Tương cà chua"],
        ),
        (
            "Bún trộn nem nướng rau sống thanh mát",
            45000,
            460,
            1,
            "Phở & Bún",
            ["Bữa trưa", "Bữa tối"],
            ["Bún tươi sợi nhỏ", "Nạc vai heo", "Xà lách xoăn", "Đậu phộng rang", "Hành phi giòn rụm"],
        ),
    ],
    "oc_hai_san": [
        (
            "Ốc hương xào bơ tỏi thơm nức mũi",
            85000,
            380,
            1,
            "Đồ ăn vặt",
            ["Bữa tối", "Bữa xế / Ăn vặt"],
            ["Ốc hương biển", "Bơ lạt thực vật", "Tỏi tép Lý Sơn", "Ớt chỉ thiên cay xé", "Rau răm tươi"],
        ),
        (
            "Ốc móng tay xào rau muống tỏi giòn",
            75000,
            340,
            1,
            "Đồ ăn vặt",
            ["Bữa tối", "Bữa xế / Ăn vặt"],
            ["Ốc móng tay", "Rau muống nước", "Tỏi tép Lý Sơn", "Dầu hào hảo hạng"],
        ),
        (
            "Cút lộn xào me chua ngọt đậm đà",
            40000,
            360,
            1,
            "Đồ ăn vặt",
            ["Bữa tối", "Bữa xế / Ăn vặt"],
            ["Trứng cút lộn", "Nước cốt me chua ngọt", "Đậu phộng rang", "Rau răm tươi", "Hành phi giòn rụm"],
        ),
        (
            "Hàu sữa nướng mỡ hành phô mai",
            60000,
            320,
            0,
            "Đồ ăn vặt",
            ["Bữa tối"],
            ["Hàu sữa tươi", "Hành lá (hành hoa)", "Đậu phộng rang", "Phô mai Mozzarella"],
        ),
        (
            "Ngao hoa hấp sả ớt ngọt nước",
            55000,
            240,
            2,
            "Đồ ăn vặt",
            ["Bữa tối"],
            ["Ngao hoa", "Sả cây tươi", "Ớt chỉ thiên cay xé"],
        ),
    ],
    "lau_nuong": [
        (
            "Set lẩu Thái Tomyum hải sản chua cay",
            299000,
            950,
            2,
            "Lẩu & Nướng",
            ["Bữa trưa", "Bữa tối"],
            ["Tôm sú tươi", "Mực ống tươi", "Nấm kim châm", "Bắp mỹ ngọt", "Rau muống nước", "Đậu hũ non", "Mì tôm Miliket"],
        ),
        (
            "Lẩu riêu cua bắp bò sườn sụn đồng quê",
            350000,
            890,
            1,
            "Lẩu & Nướng",
            ["Bữa trưa", "Bữa tối"],
            ["Cua biển Cà Mau", "Thịt bò bắp hoa", "Sườn sụn heo", "Đậu hũ mơ chiên vàng", "Bún tươi sợi nhỏ"],
        ),
        (
            "Set nướng chảo bơ bò tảng sốt me cay",
            249000,
            980,
            1,
            "Lẩu & Nướng",
            ["Bữa tối"],
            ["Ba chỉ bò Mỹ", "Thịt bò bắp hoa", "Nấm kim châm", "Bơ lạt thực vật", "Nước cốt me chua ngọt"],
        ),
        (
            "Nầm heo nướng sốt sa tế xèo xèo",
            150000,
            640,
            2,
            "Lẩu & Nướng",
            ["Bữa tối"],
            ["Nầm heo sữa", "Bơ lạt thực vật", "Ớt chỉ thiên cay xé", "Đậu bắp"],
        ),
    ],
    "de": [
        (
            "Dê tái chanh hoa chuối giòn bùi",
            120000,
            380,
            1,
            "Lẩu & Nướng",
            ["Bữa trưa", "Bữa tối"],
            ["Thịt dê tươi", "Hoa chuối non", "Chanh tươi mọng nước", "Rau húng quế", "Gừng củ tươi"],
        ),
        (
            "Dê nướng tảng than hoa thơm lừng",
            150000,
            520,
            1,
            "Lẩu & Nướng",
            ["Bữa trưa", "Bữa tối"],
            ["Thịt dê tươi", "Sả cây tươi", "Vừng trắng", "Ớt sừng đỏ"],
        ),
        (
            "Lẩu dê thuốc bắc niêu đất bổ dưỡng",
            320000,
            820,
            1,
            "Lẩu & Nướng",
            ["Bữa trưa", "Bữa tối"],
            ["Thịt dê tươi", "Củ sen tươi", "Nấm đông cô khô", "Đậu hũ non", "Mì trứng tươi"],
        ),
        (
            "Dê xào lăn sả ớt cốt dừa béo bùi",
            135000,
            460,
            1,
            "Lẩu & Nướng",
            ["Bữa trưa", "Bữa tối"],
            ["Thịt dê tươi", "Sả cây tươi", "Dừa nạo & Nước cốt dừa", "Đậu phộng rang"],
        ),
    ],
    "vit_ngan": [
        (
            "Ngan cháy tỏi thơm lừng giòn bì",
            160000,
            620,
            1,
            "Phở & Bún",
            ["Bữa trưa", "Bữa tối"],
            ["Thịt ngan ré", "Tỏi tép Lý Sơn", "Nước mắm cá cơm Phú Quốc", "Hành lá (hành hoa)"],
        ),
        (
            "Vịt cỏ nướng than hoa lá móc mật",
            180000,
            680,
            1,
            "Lẩu & Nướng",
            ["Bữa trưa", "Bữa tối"],
            ["Thịt vịt cỏ Vân Đình", "Gừng củ tươi", "Nước mắm cá cơm Phú Quốc"],
        ),
        (
            "Bún ngan măng chua tiết nóng",
            45000,
            470,
            1,
            "Phở & Bún",
            ["Bữa sáng", "Bữa trưa", "Bữa tối"],
            ["Bún tươi sợi nhỏ", "Thịt ngan ré", "Măng củ chua", "Hành lá (hành hoa)", "Rau mùi ta"],
        ),
        (
            "Vịt om sấu chua thanh nóng hổi",
            220000,
            720,
            1,
            "Lẩu & Nướng",
            ["Bữa trưa", "Bữa tối"],
            ["Thịt vịt cỏ Vân Đình", "Khoai môn sáp", "Rau muống nước", "Bún tươi sợi nhỏ"],
        ),
    ],
    "ga_chick": [
        (
            "Gà ta luộc lá chanh da giòn thịt ngọt",
            160000,
            520,
            0,
            "Lẩu & Nướng",
            ["Bữa trưa", "Bữa tối"],
            ["Thịt gà ta thả vườn", "Lá chanh bánh tẻ", "Hạt nêm từ thịt"],
        ),
        (
            "Gà chiên nước mắm thơm lừng giòn rụm",
            150000,
            640,
            1,
            "Lẩu & Nướng",
            ["Bữa trưa", "Bữa tối"],
            ["Cánh gà tươi", "Đùi gà góc tư", "Nước mắm cá cơm Phú Quốc", "Tỏi tép Lý Sơn"],
        ),
        (
            "Lẩu gà lá é chua cay thơm nồng",
            280000,
            780,
            1,
            "Lẩu & Nướng",
            ["Bữa trưa", "Bữa tối"],
            ["Thịt gà ta thả vườn", "Măng tươi Tây Bắc", "Bún tươi sợi nhỏ", "Ớt chỉ thiên cay xé"],
        ),
        (
            "Gà nướng lu than hoa ớt hiểm xôi cháy",
            220000,
            860,
            2,
            "Lẩu & Nướng",
            ["Bữa trưa", "Bữa tối"],
            ["Thịt gà ta thả vườn", "Gạo nếp cái hoa vàng", "Ớt chỉ thiên cay xé", "Mật ong hoa nhãn"],
        ),
    ],
    "thit_cho": [
        (
            "Thịt hấp chấm mắm tôm sả ớt",
            120000,
            490,
            2,
            "Lẩu & Nướng",
            ["Bữa trưa", "Bữa tối"],
            ["Mắm tôm Thanh Hóa", "Sả cây tươi", "Ớt chỉ thiên cay xé", "Rau húng quế"],
        ),
        (
            "Rựa mận béo ngậy thơm riềng mẻ",
            130000,
            540,
            1,
            "Lẩu & Nướng",
            ["Bữa trưa", "Bữa tối"],
            ["Riềng tươi xay", "Bún tươi sợi nhỏ", "Rau húng quế"],
        ),
        (
            "Dồi nướng than hoa thơm lừng giòn bì",
            110000,
            460,
            1,
            "Lẩu & Nướng",
            ["Bữa trưa", "Bữa tối"],
            ["Đậu xanh xát vỏ", "Đậu phộng rang", "Hành lá (hành hoa)"],
        ),
        (
            "Chả nướng que tre vàng ươm",
            120000,
            510,
            1,
            "Lẩu & Nướng",
            ["Bữa trưa", "Bữa tối"],
            ["Riềng tươi xay", "Mắm tôm Thanh Hóa"],
        ),
    ],
    "chay": [
        (
            "Cơm niêu nấm kho tiêu chay thanh tịnh",
            65000,
            450,
            1,
            "Món chay",
            ["Bữa trưa", "Bữa tối"],
            ["Gạo thơm ST25", "Nấm đông cô khô", "Tiêu đen Phú Quốc", "Đậu hũ non"],
        ),
        (
            "Phở nấm hương đậu hũ chay ngọt thanh",
            40000,
            360,
            0,
            "Món chay",
            ["Bữa sáng", "Bữa trưa"],
            ["Bánh phở tươi Hà Nội", "Nấm hương tươi", "Đậu hũ non", "Rau mùi ta"],
        ),
        (
            "Bún riêu chay nấu sữa đậu nành nấm đùi gà",
            40000,
            380,
            0,
            "Món chay",
            ["Bữa sáng", "Bữa trưa"],
            ["Bún tươi sợi nhỏ", "Nấm đùi gà baby", "Cà chua chín mọng", "Đậu hũ mơ chiên vàng"],
        ),
        (
            "Nem nấm chay chiên giòn sốt mè rang",
            45000,
            320,
            0,
            "Món chay",
            ["Bữa trưa", "Bữa tối"],
            ["Nấm mộc nhĩ", "Cà rốt tươi", "Hạt mè trắng rang", "Bột chiên giòn"],
        ),
        (
            "Lẩu nấm thiên nhiên dưỡng sinh",
            220000,
            580,
            0,
            "Món chay",
            ["Bữa trưa", "Bữa tối"],
            ["Nấm kim châm", "Nấm đùi gà baby", "Nấm hương tươi", "Bắp mỹ ngọt", "Bông cải xanh"],
        ),
    ],
    "sushi_nhat": [
        (
            "Set Nigiri cá hồi và cá ngừ đại dương",
            155000,
            450,
            0,
            "Lẩu & Nướng",
            ["Bữa trưa", "Bữa tối"],
            ["Cá hồi Na Uy", "Gạo thơm ST25", "Nước tương đậu nành"],
        ),
        (
            "Maki tôm chiên Tempura sốt cay",
            95000,
            420,
            1,
            "Lẩu & Nướng",
            ["Bữa trưa", "Bữa tối"],
            ["Tôm sú tươi", "Bột chiên giòn", "Sốt mayonnaise", "Tương ớt cay nồng"],
        ),
        (
            "Cơm lươn Nhật nướng sốt Teriyaki đậm đà",
            165000,
            640,
            0,
            "Cơm & Xôi",
            ["Bữa trưa", "Bữa tối"],
            ["Gạo thơm ST25", "Hạt mè trắng rang", "Dầu hào hảo hạng"],
        ),
        (
            "Mì Udon hải sản nước tương Nhật",
            85000,
            480,
            0,
            "Phở & Bún",
            ["Bữa trưa", "Bữa tối"],
            ["Mì Udon tươi", "Tôm sú tươi", "Mực ống tươi", "Cải thìa tươi"],
        ),
    ],
    "han_quoc_my_cay": [
        (
            "Mì cay cấp độ Hàn Quốc hải sản",
            55000,
            590,
            3,
            "Phở & Bún",
            ["Bữa trưa", "Bữa tối"],
            ["Mì tôm Miliket", "Tôm sú tươi", "Mực ống tươi", "Nấm kim châm", "Ớt chỉ thiên cay xé"],
        ),
        (
            "Mì cay ba chỉ bò Mỹ nấm kim châm",
            55000,
            610,
            2,
            "Phở & Bún",
            ["Bữa trưa", "Bữa tối"],
            ["Mì tôm Miliket", "Ba chỉ bò Mỹ", "Nấm kim châm", "Bắp cải thảo"],
        ),
        (
            "Kimbap chiên xù sốt mayonnaise",
            40000,
            380,
            0,
            "Đồ ăn vặt",
            ["Bữa xế / Ăn vặt", "Bữa tối"],
            ["Gạo thơm ST25", "Trứng gà ta", "Cà rốt tươi", "Dưa leo baby", "Sốt mayonnaise"],
        ),
        (
            "Tokbokki phô mai cay sốt Hàn Quốc",
            45000,
            460,
            2,
            "Đồ ăn vặt",
            ["Bữa xế / Ăn vặt", "Bữa tối"],
            ["Phô mai Mozzarella", "Tương ớt cay nồng", "Hạt mè trắng rang"],
        ),
    ],
    "fast_food_pizza": [
        (
            "Gà rán giòn rụm sốt cay ngọt",
            45000,
            480,
            1,
            "Đồ ăn vặt",
            ["Bữa trưa", "Bữa xế / Ăn vặt", "Bữa tối"],
            ["Đùi gà góc tư", "Cánh gà tươi", "Bột chiên giòn", "Tương ớt cay nồng"],
        ),
        (
            "Burger bò phô mai 2 tầng đẫm sốt",
            55000,
            620,
            0,
            "Bánh mì",
            ["Bữa sáng", "Bữa trưa", "Bữa tối"],
            ["Thăn bò mềm", "Phô mai Cheddar", "Xà lách xoăn", "Cà chua chín mọng", "Sốt mayonnaise"],
        ),
        (
            "Pizza hải sản sốt phô mai Mozzarella",
            120000,
            780,
            0,
            "Lẩu & Nướng",
            ["Bữa trưa", "Bữa tối"],
            ["Tôm sú tươi", "Mực ống tươi", "Phô mai Mozzarella", "Cà chua chín mọng"],
        ),
        (
            "Khoai tây chiên giòn xóc phô mai",
            35000,
            360,
            0,
            "Đồ ăn vặt",
            ["Bữa xế / Ăn vặt", "Bữa tối"],
            ["Khoai tây vàng", "Phô mai Cheddar", "Tương cà chua"],
        ),
    ],
    "cafe": [
        (
            "Cà phê muối biển béo ngậy kem cheese",
            45000,
            190,
            0,
            "Cà phê & Trà sữa",
            ["Bữa sáng", "Bữa xế / Ăn vặt"],
            ["Cà phê Robusta Đắk Lắk", "Kem cheese mặn", "Sữa đặc có đường"],
        ),
        (
            "Cà phê nâu đá truyền thống Đắk Lắk",
            35000,
            160,
            0,
            "Cà phê & Trà sữa",
            ["Bữa sáng", "Bữa trưa", "Bữa xế / Ăn vặt"],
            ["Cà phê Robusta Đắk Lắk", "Sữa đặc có đường"],
        ),
        (
            "Bạc xỉu ba tầng thơm ngậy sữa tươi",
            40000,
            210,
            0,
            "Cà phê & Trà sữa",
            ["Bữa sáng", "Bữa xế / Ăn vặt"],
            ["Cà phê Robusta Đắk Lắk", "Sữa tươi tiệt trùng", "Sữa đặc có đường"],
        ),
        (
            "Cà phê đen đá phin nguyên chất",
            30000,
            40,
            0,
            "Cà phê & Trà sữa",
            ["Bữa sáng", "Bữa trưa"],
            ["Cà phê Robusta Đắk Lắk"],
        ),
    ],
    "tra_sua": [
        (
            "Trà sữa trân châu hoàng gia đậm vị",
            55000,
            360,
            0,
            "Cà phê & Trà sữa",
            ["Bữa xế / Ăn vặt"],
            ["Trà đen Oolong đậm vị", "Sữa tươi tiệt trùng", "Trân châu đen dẻo dai", "Sữa đặc có đường"],
        ),
        (
            "Trà sữa nướng trân châu đường đen",
            50000,
            380,
            0,
            "Cà phê & Trà sữa",
            ["Bữa xế / Ăn vặt"],
            ["Trà đen Oolong đậm vị", "Sữa tươi tiệt trùng", "Trân châu đen dẻo dai", "Kem béo thực vật"],
        ),
        (
            "Trà ô long sen vàng kem cheese béo ngậy",
            55000,
            310,
            0,
            "Cà phê & Trà sữa",
            ["Bữa xế / Ăn vặt"],
            ["Trà đen Oolong đậm vị", "Kem cheese mặn", "Hạt sen tươi"],
        ),
        (
            "Trà đào cam sả hạt chia tươi mát",
            45000,
            180,
            0,
            "Cà phê & Trà sữa",
            ["Bữa sáng", "Bữa trưa", "Bữa xế / Ăn vặt"],
            ["Trà xanh Thái Nguyên", "Sả cây tươi", "Hạt chia hữu cơ"],
        ),
    ],
    "che_trang_mieng": [
        (
            "Chè bưởi An Giang cùi giòn cốt dừa",
            25000,
            280,
            0,
            "Cà phê & Trà sữa",
            ["Bữa xế / Ăn vặt"],
            ["Bưởi da xanh tép hồng", "Đậu xanh xát vỏ", "Dừa nạo & Nước cốt dừa"],
        ),
        (
            "Tào phớ thạch trân châu đường đen",
            20000,
            190,
            0,
            "Cà phê & Trà sữa",
            ["Bữa xế / Ăn vặt"],
            ["Đậu hũ non", "Trân châu đen dẻo dai", "Dừa nạo & Nước cốt dừa"],
        ),
        (
            "Chè sầu riêng cốt dừa thạch dừa giòn",
            35000,
            340,
            0,
            "Cà phê & Trà sữa",
            ["Bữa xế / Ăn vặt"],
            ["Dừa nạo & Nước cốt dừa", "Thạch dừa xiêm", "Sữa tươi tiệt trùng"],
        ),
        (
            "Sữa chua mít nếp cẩm hạt sen",
            30000,
            260,
            0,
            "Cà phê & Trà sữa",
            ["Bữa xế / Ăn vặt"],
            ["Sữa chua men sống", "Gạo nếp cái hoa vàng", "Hạt sen tươi"],
        ),
    ],
    "banh_trang_an_vat": [
        (
            "Bánh tráng nướng mỡ hành trứng cút giòn rụm",
            25000,
            320,
            1,
            "Đồ ăn vặt",
            ["Bữa xế / Ăn vặt", "Bữa tối"],
            ["Trứng cút tươi", "Hành lá (hành hoa)", "Tương ớt cay nồng", "Sốt mayonnaise"],
        ),
        (
            "Bánh tráng cuộn sốt bơ béo ngậy",
            30000,
            340,
            1,
            "Đồ ăn vặt",
            ["Bữa xế / Ăn vặt", "Bữa tối"],
            ["Bơ lạt thực vật", "Đậu phộng rang", "Hành phi giòn rụm", "Trứng cút tươi"],
        ),
        (
            "Chân gà sả tắc chua cay giòn sần sật",
            50000,
            310,
            2,
            "Đồ ăn vặt",
            ["Bữa xế / Ăn vặt", "Bữa tối"],
            ["Sả cây tươi", "Quất tươi thơm ngát", "Ớt chỉ thiên cay xé", "Gừng củ tươi"],
        ),
        (
            "Khoai lang kén chiên vàng thơm ngậy",
            25000,
            290,
            0,
            "Đồ ăn vặt",
            ["Bữa xế / Ăn vặt", "Bữa tối"],
            ["Khoai lang mật", "Dừa nạo & Nước cốt dừa", "Hạt mè trắng rang"],
        ),
    ],
    "bia_nhau": [
        (
            "Mực khô nướng than hoa xé sợi",
            120000,
            340,
            1,
            "Đồ ăn vặt",
            ["Bữa tối"],
            ["Mực một nắng", "Tương ớt cay nồng"],
        ),
        (
            "Đậu phụ lướt ván giòn rụm chấm mắm tôm",
            30000,
            260,
            1,
            "Đồ ăn vặt",
            ["Bữa trưa", "Bữa tối"],
            ["Đậu hũ mơ chiên vàng", "Mắm tôm Thanh Hóa", "Rau kinh giới"],
        ),
        (
            "Bò xào cần tỏi đĩa lớn nhắm bia",
            110000,
            420,
            1,
            "Lẩu & Nướng",
            ["Bữa trưa", "Bữa tối"],
            ["Thịt bò bắp hoa", "Tỏi tép Lý Sơn", "Cần tây", "Dầu hào hảo hạng"],
        ),
        (
            "Lạc luộc & lạc rang muối giòn bùi",
            15000,
            190,
            0,
            "Đồ ăn vặt",
            ["Bữa trưa", "Bữa tối"],
            ["Đậu phộng rang"],
        ),
    ],
    "co_bat_trang_truyen_thong": [
        (
            "Canh măng mực Bát Tràng truyền thống",
            150000,
            420,
            0,
            "Lẩu & Nướng",
            ["Bữa trưa", "Bữa tối"],
            ["Mực một nắng", "Măng tươi Tây Bắc", "Nước mắm cá cơm Phú Quốc", "Hành lá (hành hoa)"],
        ),
        (
            "Su hào xào mực giòn ngọt làng gốm",
            120000,
            360,
            0,
            "Lẩu & Nướng",
            ["Bữa trưa", "Bữa tối"],
            ["Mực ống tươi", "Cà rốt tươi", "Hành hoa", "Rau mùi ta"],
        ),
        (
            "Chim câu hầm hạt sen cốm xanh",
            180000,
            560,
            0,
            "Lẩu & Nướng",
            ["Bữa trưa", "Bữa tối"],
            ["Chim cút tươi", "Hạt sen tươi", "Nấm hương tươi", "Củ sen tươi"],
        ),
        (
            "Chả tôm chiên giòn mâm cỗ truyền thống",
            110000,
            440,
            0,
            "Đồ ăn vặt",
            ["Bữa trưa", "Bữa tối"],
            ["Tôm sú tươi", "Nạc vai heo", "Bột chiên giòn"],
        ),
    ],
    "tay_bac": [
        (
            "Thịt trâu gác bếp chấm chẩm chéo Tây Bắc",
            180000,
            480,
            2,
            "Đồ ăn vặt",
            ["Bữa trưa", "Bữa tối"],
            ["Thịt bò bắp hoa", "Gừng củ tươi", "Ớt chỉ thiên cay xé", "Tỏi tép Lý Sơn"],
        ),
        (
            "Lợn bản nướng mắc khén hạt dổi",
            150000,
            590,
            1,
            "Lẩu & Nướng",
            ["Bữa trưa", "Bữa tối"],
            ["Thịt heo ba chỉ", "Mật ong hoa nhãn", "Sả cây tươi"],
        ),
        (
            "Thắng cố ngựa niêu đất thơm nồng",
            220000,
            680,
            1,
            "Lẩu & Nướng",
            ["Bữa trưa", "Bữa tối"],
            ["Sả cây tươi", "Gừng củ tươi", "Quế hồi thảo quả", "Rau cải cúc"],
        ),
        (
            "Xôi ngũ sắc Tây Bắc dẻo thơm",
            40000,
            420,
            0,
            "Cơm & Xôi",
            ["Bữa sáng", "Bữa trưa", "Bữa tối"],
            ["Gạo nếp cái hoa vàng", "Hành phi giòn rụm"],
        ),
    ],
    "cha_ca_la_vong": [
        (
            "Chả cá lăng nướng giảo thì là hành hoa",
            135000,
            520,
            1,
            "Phở & Bún",
            ["Bữa trưa", "Bữa tối"],
            ["Cá lăng sông Đà", "Rau thì là", "Hành lá (hành hoa)", "Bún tươi sợi nhỏ", "Mắm tôm Thanh Hóa", "Đậu phộng rang"],
        ),
        (
            "Lẩu đầu cá lăng măng chua cay",
            280000,
            760,
            1,
            "Lẩu & Nướng",
            ["Bữa trưa", "Bữa tối"],
            ["Cá lăng sông Đà", "Măng củ chua", "Cà chua chín mọng", "Rau muống nước", "Bún tươi sợi nhỏ"],
        ),
        (
            "Canh cá lăng nấu dọc mùng thì là",
            110000,
            380,
            1,
            "Phở & Bún",
            ["Bữa trưa", "Bữa tối"],
            ["Cá lăng sông Đà", "Rau thì là", "Cà chua chín mọng", "Nước mắm cá cơm Phú Quốc"],
        ),
    ],
    "thai": [
        (
            "Set lẩu Thái Tomyum hải sản chua cay",
            299000,
            950,
            2,
            "Lẩu & Nướng",
            ["Bữa trưa", "Bữa tối"],
            ["Tôm sú tươi", "Mực ống tươi", "Nấm kim châm", "Bắp mỹ ngọt", "Sả cây tươi", "Lá chanh bánh tẻ", "Nước cốt me chua ngọt"],
        ),
        (
            "Pad Thai tôm tươi xào trứng sợi dai",
            75000,
            540,
            1,
            "Phở & Bún",
            ["Bữa trưa", "Bữa tối"],
            ["Bánh phở tươi Hà Nội", "Tôm sú tươi", "Trứng gà ta", "Giá đỗ tươi", "Đậu phộng rang"],
        ),
        (
            "Gỏi đu đủ tôm khô Som Tum cay nồng",
            60000,
            260,
            3,
            "Đồ ăn vặt",
            ["Bữa trưa", "Bữa tối"],
            ["Tôm sú tươi", "Đậu phộng rang", "Ớt chỉ thiên cay xé", "Chanh tươi mọng nước", "Nước mắm cá cơm Phú Quốc"],
        ),
        (
            "Cơm chiên trái dứa hải sản kiểu Thái",
            85000,
            640,
            0,
            "Cơm & Xôi",
            ["Bữa trưa", "Bữa tối"],
            ["Gạo thơm ST25", "Tôm sú tươi", "Mực ống tươi", "Hạt điều rang muối", "Trứng gà ta"],
        ),
    ],
    "dimsum_trung_hoa": [
        (
            "Há cảo tôm tươi hấp xửng tre",
            45000,
            280,
            0,
            "Bánh mì",
            ["Bữa sáng", "Bữa trưa", "Bữa tối"],
            ["Tôm sú tươi", "Nước tương đậu nành"],
        ),
        (
            "Xíu mại thịt heo trứng cút thơm bùi",
            40000,
            320,
            0,
            "Bánh mì",
            ["Bữa sáng", "Bữa trưa", "Bữa tối"],
            ["Nạc vai heo", "Trứng cút tươi", "Nấm mộc nhĩ", "Dầu hào hảo hạng"],
        ),
        (
            "Mì vằn thắn sủi cảo xá xíu tôm tươi",
            50000,
            490,
            0,
            "Phở & Bún",
            ["Bữa sáng", "Bữa trưa", "Bữa tối"],
            ["Mì trứng tươi", "Tôm sú tươi", "Thịt heo ba chỉ", "Cải thìa tươi", "Hành lá (hành hoa)"],
        ),
        (
            "Chân gà hấp tàu xì Hong Kong đậm đà",
            55000,
            340,
            1,
            "Đồ ăn vặt",
            ["Bữa trưa", "Bữa tối"],
            ["Dầu hào hảo hạng", "Nước tương đậu nành", "Ớt sừng đỏ"],
        ),
    ],
    "nha_hang_viet": [
        (
            "Sườn non heo rim mắm tỏi đậm đà",
            95000,
            490,
            0,
            "Cơm & Xôi",
            ["Bữa trưa", "Bữa tối"],
            ["Sườn non heo", "Tỏi tép Lý Sơn", "Nước mắm cá cơm Phú Quốc", "Hành tím Kinh Môn"],
        ),
        (
            "Cá thu sốt cà chua thì là",
            85000,
            410,
            0,
            "Cơm & Xôi",
            ["Bữa trưa", "Bữa tối"],
            ["Cá thu một nắng", "Cà chua chín mọng", "Rau thì là", "Hành lá (hành hoa)"],
        ),
        (
            "Canh ngao nấu chua thì là thanh mát",
            45000,
            180,
            0,
            "Cơm & Xôi",
            ["Bữa trưa", "Bữa tối"],
            ["Ngao hoa", "Cà chua chín mọng", "Rau thì là", "Hành lá (hành hoa)"],
        ),
        (
            "Thịt ba chỉ rang cháy cạnh thơm lừng",
            75000,
            520,
            0,
            "Cơm & Xôi",
            ["Bữa trưa", "Bữa tối"],
            ["Thịt heo ba chỉ", "Hành tím Kinh Môn", "Nước mắm cá cơm Phú Quốc"],
        ),
        (
            "Rau muống xào tỏi Lý Sơn giòn xanh",
            35000,
            160,
            0,
            "Cơm & Xôi",
            ["Bữa trưa", "Bữa tối"],
            ["Rau muống nước", "Tỏi tép Lý Sơn", "Dầu hào hảo hạng"],
        ),
    ],
}


class RestaurantMenuAlignService:
    @staticmethod
    def classify_restaurant_theme(name: str) -> str:
        """Phân loại quán ăn theo tên thành chủ đề ẩm thực chính xác."""
        n = name.lower()

        # 1. Các món đặc sản / đặc thù theo tên riêng
        if any(k in n for k in ["chả cá", "vua cá lăng", "phùng gia"]):
            return "cha_ca_la_vong"
        if any(k in n for k in ["bát tràng", "cỗ cổ truyền", "làng cổ"]):
            return "co_bat_trang_truyen_thong"
        if any(k in n for k in ["thắng cố", "tây bắc"]):
            return "tay_bac"
        if any(k in n for k in ["thịt chó", "tiểu hổ"]):
            return "thit_cho"
        if any(k in n for k in ["chay", "belotus", "hali"]):
            return "chay"
        if any(k in n for k in ["sushi", "nhật bản", "meshinoya", "koi", "minori", "shio", "ryu sushi"]):
            return "sushi_nhat"
        if any(k in n for k in ["korea", "hàn quốc", "kimbap", "mỳ cay", "mì cay", "chukkumi"]):
            return "han_quoc_my_cay"
        if any(k in n for k in ["dimsum", "taiwan", "taipei", "vằn thắn", "trung hoa", "mu wu", "hong kong"]):
            return "dimsum_trung_hoa"
        if any(k in n for k in ["thai", "thái", "koh yam", "pai kin khao", "khrua baan"]):
            return "thai"

        # 2. Fast food, đồ uống, tráng miệng
        if any(k in n for k in ["pizza", "burger", "jollibee", "wallace", "lotteria", "fivestar", "gà rán"]):
            return "fast_food_pizza"
        if any(k in n for k in ["kem", "chè", "tào phớ", "ngọc thạch quán", "soymel"]):
            return "che_trang_mieng"
        if any(k in n for k in ["trà sữa", "milktea", "yi he tang", "mixue", "bingxue", "oolo", "oolong", "tocotoco"]):
            return "tra_sua"
        if any(k in n for k in ["cafe", "cà phê", "coffee", "kafa", "highlands", "tane"]):
            return "cafe"
        if any(k in n for k in ["trà", "tea", "chickgarden"]):
            return "tra_sua"
        if any(k in n for k in ["bánh tráng", "ăn vặt", "tên lửa", "út mart", "mẹ sữa"]):
            return "banh_trang_an_vat"

        # 3. Quán ốc & hải sản
        if any(k in n for k in ["ốc", "hải sản", "cảng"]):
            return "oc_hai_san"

        # 4. Các loại đạm chính: Dê, Ngan/Vịt, Gà, Bò, Ếch, Cá kèo
        if any(k in n for k in ["dê", "sơn dương"]):
            return "de"
        if any(k in n for k in ["ngan", "vịt"]):
            return "vit_ngan"
        if any(k in n for k in ["mạnh hoạch", "chicken", "gà tươi", "gà"]):
            return "ga_chick"
        if any(k in n for k in ["cháo ếch", "lẩu ếch"]):
            return "chao"
        if any(k in n for k in ["cá kèo"]):
            return "oc_hai_san"
        if any(k in n for k in ["bò tơ", "bò nhúng dấm"]):
            return "lau_nuong"

        # 5. Phở & Các loại bún cụ thể
        if "phở bò" in n or "phở gà" in n or "phở cồ" in n or "phở" in n:
            return "pho"
        if "bún chả" in n:
            return "bun_cha"
        if "bún đậu" in n:
            return "bun_dau"
        if "bún bò" in n:
            return "bun_bo"
        if "bún cá" in n:
            return "bun_ca"
        if "bún riêu" in n or "bánh đa cua" in n:
            return "bun_rieu"
        if "trộn" in n:
            return "bun_tron_pho_tron"

        # 6. Cơm, Xôi, Cháo
        if any(k in n for k in ["cơm tấm", "sườn bì chả", "sài gòn nhỏ"]):
            return "com_tam"
        if "cơm gà" in n:
            return "com_ga"
        if any(k in n for k in ["cơm niêu", "cơm thố", "kombo", "meat24"]):
            return "com_nieu"
        if any(k in n for k in ["cơm bình dân", "cơm mẹ nấu", "cơm ngon", "quán cơm", "cơm"]):
            return "com_binh_dan"
        if "xôi" in n:
            return "xoi"
        if "cháo" in n:
            return "chao"

        # 7. Bánh mì, Bánh cuốn, Bánh xèo, Nem nướng
        if "bánh mì" in n:
            return "banh_mi"
        if "bánh cuốn" in n:
            return "banh_cuon"
        if any(k in n for k in ["bánh xèo", "bánh khọt"]):
            return "banh_xeo"
        if "nem nướng" in n:
            return "nem_nuong"

        # 8. Lẩu & nướng, Quán bia
        if any(k in n for k in ["bia", "vườn bia"]):
            return "bia_nhau"
        if any(k in n for k in ["lẩu", "nướng", "bbq", "hotpot", "gogi", "manwah", "nhắng nướng"]):
            return "lau_nuong"

        # Mặc định là nhà hàng ẩm thực Việt
        return "nha_hang_viet"

    @staticmethod
    def align_menus_for_all_restaurants(db: Session) -> Dict[str, Any]:
        """
        Duyệt qua toàn bộ quán ăn trong CSDL và cập nhật thực đơn món ăn
        chuẩn hóa đúng theo tên và phong cách của quán.
        """
        # Đảm bảo categories tồn tại
        categories = db.scalars(select(Category)).all()
        cat_map = {c.name: c.id for c in categories}

        # Đảm bảo nguyên liệu master đã được nạp
        all_ings = db.scalars(select(Ingredient)).all()
        name_to_ing = {i.name.lower().strip(): i for i in all_ings}

        restaurants = db.scalars(select(Restaurant).order_by(Restaurant.id)).all()

        theme_counts: Dict[str, int] = {}
        total_dishes_realigned = 0
        total_links_created = 0

        for rest in restaurants:
            theme = RestaurantMenuAlignService.classify_restaurant_theme(rest.name)
            theme_counts[theme] = theme_counts.get(theme, 0) + 1

            dish_templates = THEME_DISH_CATALOG.get(theme, THEME_DISH_CATALOG["nha_hang_viet"])

            # Lấy các món ăn hiện tại của quán này
            existing_dishes = db.scalars(select(Dish).where(Dish.restaurant_id == rest.id).order_by(Dish.id)).all()

            # Số món cần gán cho quán (thường từ 3-4 món)
            num_dishes = min(len(dish_templates), max(len(existing_dishes), 3))

            for idx in range(num_dishes):
                t_dish = dish_templates[idx % len(dish_templates)]
                name, price, cal, spicy, cat_name, meal_types, ing_names = t_dish

                cat_id = cat_map.get(cat_name)

                if idx < len(existing_dishes):
                    # Cập nhật món hiện có
                    dish = existing_dishes[idx]
                    dish.name = name
                    dish.price = price
                    dish.calories = cal
                    dish.spicy_level = spicy
                    dish.category = cat_name
                    dish.category_id = cat_id
                    dish.meal_types = meal_types
                    dish.ingredients = ing_names
                else:
                    # Tạo thêm món mới nếu quán có ít hơn 3 món
                    dish = Dish(
                        restaurant_id=rest.id,
                        name=name,
                        price=price,
                        calories=cal,
                        spicy_level=spicy,
                        category=cat_name,
                        category_id=cat_id,
                        meal_types=meal_types,
                        ingredients=ing_names,
                    )
                    db.add(dish)
                    db.flush()

                total_dishes_realigned += 1

                # Đồng bộ bảng dish_ingredients
                db.execute(text("DELETE FROM dish_ingredients WHERE dish_id = :d_id"), {"d_id": dish.id})
                for ing_name in ing_names:
                    ing_obj = name_to_ing.get(ing_name.lower().strip())
                    if not ing_obj:
                        ing_obj = Ingredient(name=ing_name, is_active=True)
                        db.add(ing_obj)
                        db.flush()
                        name_to_ing[ing_name.lower().strip()] = ing_obj

                    db.add(DishIngredient(dish_id=dish.id, ingredient_id=ing_obj.id))
                    total_links_created += 1

            # Nếu quán có nhiều hơn num_dishes món, xóa bớt các món dư thừa để thực đơn gọn gàng
            if len(existing_dishes) > num_dishes:
                for extra_dish in existing_dishes[num_dishes:]:
                    db.execute(text("DELETE FROM dish_ingredients WHERE dish_id = :d_id"), {"d_id": extra_dish.id})
                    db.delete(extra_dish)

        db.commit()
        logger.info(
            "Hoàn tất chuẩn hóa thực đơn cho %d quán ăn. Tổng %d món ăn được đồng bộ.",
            len(restaurants),
            total_dishes_realigned,
        )

        return {
            "total_restaurants": len(restaurants),
            "total_dishes": total_dishes_realigned,
            "theme_counts": theme_counts,
        }
