"""Service khởi tạo và làm giàu bể nguyên liệu đa dạng (Rich Master Ingredients Pool).

Cung cấp hơn 190 nguyên liệu thực tế phân bổ chuẩn xác qua 10 nhóm nguyên liệu F&B,
đồng thời tự động làm giàu (enrich) các món ăn đang dùng nguyên liệu giữ chỗ (placeholder)
thành nguyên liệu ẩm thực thực tế.
"""

import logging
from typing import Dict, List, Optional
from sqlalchemy import text, select, func
from sqlalchemy.orm import Session

from server.app.models.ingredient_group import IngredientGroup
from server.app.models.ingredient import Ingredient, DishIngredient
from server.app.models.dish import Dish

logger = logging.getLogger(__name__)

# Danh sách 10 nhóm nguyên liệu chuẩn ngành F&B
INGREDIENT_GROUPS_DATA = [
    {
        "id": 1,
        "name": "Hải sản",
        "description": "Tôm, cua, cá, mực, bạch tuộc, nghêu, sò, ốc, hải sản tươi sống",
        "display_order": 1,
    },
    {
        "id": 2,
        "name": "Thịt gia súc",
        "description": "Thịt bò, thịt heo, thịt dê, thịt cừu, thịt bê và các phần thịt đỏ",
        "display_order": 2,
    },
    {
        "id": 3,
        "name": "Thịt gia cầm",
        "description": "Thịt gà, vịt, ngan, ngỗng, chim cút và các loại gia cầm",
        "display_order": 3,
    },
    {
        "id": 4,
        "name": "Rau củ & Nấm",
        "description": "Các loại rau xanh, củ quả, măng và nấm tươi, nấm khô",
        "display_order": 4,
    },
    {
        "id": 5,
        "name": "Sữa & Chế phẩm",
        "description": "Sữa tươi, sữa đặc, bơ, phô mai, whipping cream, sữa chua",
        "display_order": 5,
    },
    {
        "id": 6,
        "name": "Trứng",
        "description": "Trứng gà, trứng vịt, trứng cút, trứng muối, trứng bắc thảo",
        "display_order": 6,
    },
    {
        "id": 7,
        "name": "Đậu & Các loại hạt",
        "description": "Đậu hũ, tàu hũ ky, lạc rang, đậu xanh, đậu đỏ, hạt sen, hạt điều",
        "display_order": 7,
    },
    {
        "id": 8,
        "name": "Tinh bột & Ngũ cốc",
        "description": "Gạo, bánh phở, bún, mì, miến, bánh mì, các loại bột",
        "display_order": 8,
    },
    {
        "id": 9,
        "name": "Gia vị & Nước xốt",
        "description": "Nước mắm, xì dầu, hạt tiêu, tỏi, ớt, sả, gừng, rau thơm, các loại xốt",
        "display_order": 9,
    },
    {
        "id": 10,
        "name": "Trái cây & Đồ uống",
        "description": "Hoa quả tươi, nước cốt trái cây, trà, cà phê, trân châu, thạch topping",
        "display_order": 10,
    },
]

# Bể hơn 190 nguyên liệu đa dạng phân bổ theo từng nhóm
MASTER_INGREDIENTS_DATA: Dict[str, List[Dict[str, str]]] = {
    "Hải sản": [
        {"name": "Tôm sú tươi", "description": "Tôm sú nguyên con tươi sống, thịt chắc ngọt đậm vị"},
        {"name": "Tôm thẻ chân trắng", "description": "Tôm thẻ bóc nõn tươi ngon, ngọt thanh tự nhiên"},
        {"name": "Tôm càng xanh", "description": "Tôm càng xanh thịt dai ngọt, nhiều gạch béo bùi"},
        {"name": "Tôm hùm Alaska", "description": "Tôm hùm thịt trắng chắc dai, ngọt đậm vị biển sâu"},
        {"name": "Cua biển Cà Mau", "description": "Cua biển thịt chắc ngọt, giàu dinh dưỡng và thơm ngon"},
        {"name": "Ghẹ xanh Phan Thiết", "description": "Ghẹ xanh tươi sống, thịt thơm ngọt và mềm bùi"},
        {"name": "Mực ống tươi", "description": "Mực ống tươi giòn dai, thích hợp xào cần tỏi hoặc nhúng lẩu"},
        {"name": "Mực một nắng", "description": "Mực dẻo dai đậm đà phơi một nắng giòn ngọt"},
        {"name": "Mực trứng", "description": "Mực trứng tươi béo ngậy, chứa nhiều bọc trứng bùi ngọt"},
        {"name": "Bạch tuộc baby", "description": "Bạch tuộc nhỏ tươi giòn sần sật trong lẩu và nướng sốt cay"},
        {"name": "Cá hồi Na Uy", "description": "Cá hồi tươi béo vân mỡ cẩm thạch, giàu Omega-3 và đạm"},
        {"name": "Cá thu một nắng", "description": "Cá thu thịt nạc thơm bùi, chuyên làm sốt cà hoặc kho tiêu"},
        {"name": "Cá ba sa phi lê", "description": "Cá ba sa mềm thơm béo ngậy không xương"},
        {"name": "Cá lăng sông Đà", "description": "Cá lăng da trơn thịt ngọt thơm ít xương, làm chả cá hoặc lẩu măng chua"},
        {"name": "Cá chép giòn", "description": "Cá chép thịt giòn sần sật độc đáo xào cần tây hoặc nấu lẩu"},
        {"name": "Cá bống tượng", "description": "Cá bống tươi thịt săn chắc ngọt nước, kho tiêu tộ đậm đà"},
        {"name": "Ngao hoa", "description": "Ngao hai cùi thịt giòn ngọt nước, hấp sả ớt hoặc nấu canh chua"},
        {"name": "Sò huyết Đầm Ô Loan", "description": "Sò huyết béo ngọt giàu sắt, xào me hoặc nướng mọi"},
        {"name": "Hàu sữa tươi", "description": "Hàu sữa mọng nước béo ngậy, nướng mỡ hành phô mai"},
        {"name": "Ốc hương biển", "description": "Ốc hương giòn ngọt thơm lừng hương hoa hồi tự nhiên"},
        {"name": "Ốc móng tay", "description": "Ốc móng tay thịt ngọt giòn, xào rau muống hoặc sốt bơ tỏi"},
        {"name": "Ốc mít béo", "description": "Ốc mít luộc mắm gừng sả lá chanh giòn ngọt"},
        {"name": "Cồi sò điệp", "description": "Cồi sò điệp thịt mềm ngọt thanh tao, áp chảo hoặc đút lò phô mai"},
        {"name": "Chả cá thát lát", "description": "Chả cá quết mịn dai giòn tự nhiên thơm thì là tiêu sọ"},
        {"name": "Sứa biển tươi", "description": "Sứa biển giòn sần sật làm nộm hoa chuối giải nhiệt"},
    ],
    "Thịt gia súc": [
        {"name": "Thịt bò bắp hoa", "description": "Bắp hoa bò vân giòn sần sật, thái lát nhúng lẩu hoặc luộc mắm"},
        {"name": "Thăn bò mềm", "description": "Thăn bò mềm ngọt tự nhiên, thích hợp làm bít tết hoặc xào lăn"},
        {"name": "Nạm bò vân mỡ", "description": "Nạm bò nạc mỡ đan xen, luộc chín mềm thơm trong phở và bún bò"},
        {"name": "Ba chỉ bò Mỹ", "description": "Thịt ba chỉ bò Mỹ thái lát mỏng cuộn nấm kim châm hoặc nướng sốt"},
        {"name": "Gầu bò giòn", "description": "Gầu bò thơm ngậy giòn sần sật đặc sản phở truyền thống"},
        {"name": "Dẻ sườn bò", "description": "Dẻ sườn bò đậm đà nhiều nước thịt, nướng BBQ hoặc hầm rượu vang"},
        {"name": "Đuôi bò", "description": "Đuôi bò giàu collagen, hầm thuốc bắc hoặc nấu lẩu thơm bùi"},
        {"name": "Thịt bò Wagyu A5", "description": "Thịt bò thượng hạng vân mỡ cẩm thạch hoàn hảo, tan chảy trên đầu lưỡi"},
        {"name": "Thịt heo ba chỉ", "description": "Thịt ba chỉ tươi ngon cân đối nạc mỡ, dùng rang cháy cạnh, kho tàu, nướng"},
        {"name": "Sườn non heo", "description": "Sườn non dày thịt sụn non giòn, rim chua ngọt hoặc nướng than hoa"},
        {"name": "Sườn sụn heo", "description": "Sườn sụn giòn tan sần sật dùng nấu cháo, nhúng lẩu riêu cua"},
        {"name": "Nạc vai heo", "description": "Nạc vai mềm thơm xay làm nhân chả giò, xíu mại, viên thịt"},
        {"name": "Nạc dăm heo", "description": "Nạc dăm có vân mỡ mảnh mềm mại, nướng cơm tấm không bị khô"},
        {"name": "Móng giò heo", "description": "Móng giò ninh mềm béo bùi, nấu canh măng hoặc giả cầy"},
        {"name": "Tai heo giòn", "description": "Tai heo luộc giòn sần sật bóp nộm hoặc làm nem tai thính"},
        {"name": "Thịt dê tươi", "description": "Thịt dê núi ngọt thanh chắc thịt, xào lăn hoặc nhúng lẩu bổ dưỡng"},
        {"name": "Nầm heo sữa", "description": "Nầm heo giòn sần sật béo ngậy, nướng sốt me chua ngọt hoặc chao"},
        {"name": "Thịt bê thui", "description": "Thịt bê mềm ngọt da giòn rụm chấm tương gừng"},
        {"name": "Thịt cừu rút xương", "description": "Thịt cừu mềm mại tẩm ướp lá hương thảo nướng tiêu xanh"},
    ],
    "Thịt gia cầm": [
        {"name": "Thịt gà ta thả vườn", "description": "Gà ta thịt chắc ngọt da vàng giòn luộc lá chanh hoặc rang muối"},
        {"name": "Đùi gà góc tư", "description": "Đùi gà mọng nước chiên mắm hoặc làm cơm gà xối mỡ giòn rụm"},
        {"name": "Cánh gà tươi", "description": "Cánh gà tươi chiên giòn sốt me chua ngọt hoặc nướng bơ tỏi"},
        {"name": "Ức gà phi lê", "description": "Ức gà nạc thanh đạm giàu protein cho chế độ ăn lành mạnh"},
        {"name": "Lòng mề gà tươi", "description": "Lòng mề gà giòn sần sật xào mướp giá đỗ hoặc miến lòng gà"},
        {"name": "Thịt vịt cỏ Vân Đình", "description": "Thịt vịt nạc ngọt ít mỡ, nướng than hoa hoặc om sấu thanh mát"},
        {"name": "Ức vịt xông khói", "description": "Ức vịt hun khói gỗ sồi đậm đà hương vị Âu"},
        {"name": "Đùi vịt tiềm thảo mộc", "description": "Đùi vịt tiềm gia vị bắc ninh mềm rục ngọt nước đậm đà"},
        {"name": "Thịt ngan ré", "description": "Ngan ré dày nạc thịt thơm ngọt luộc chấm nước mắm gừng ớt"},
        {"name": "Chim cút tươi", "description": "Chim cút thịt ngọt mềm nướng ngũ vị hoặc chiên bơ tỏi"},
        {"name": "Trứng non gà", "description": "Trứng non vàng ươm béo bùi hấp dẫn trong phở gà và lòng gà xào"},
    ],
    "Rau củ & Nấm": [
        {"name": "Rau muống nước", "description": "Rau muống non xanh giòn ngọt, luộc chấm tương hoặc xào tỏi"},
        {"name": "Rau cải cúc", "description": "Rau tần ô thơm dịu thanh mát, nhúng lẩu hoặc nấu canh cá"},
        {"name": "Cải thìa tươi", "description": "Cải thìa giòn ngọt xào dầu hào hoặc ăn kèm mì tiềm dimsum"},
        {"name": "Cải ngọt bánh tẻ", "description": "Cải ngọt thanh mát nấu canh thịt bằm hoặc xào bò"},
        {"name": "Bắp cải thảo", "description": "Cải thảo mềm ngọt tự nhiên dùng nhúng lẩu hoặc muối kimchi giòn cay"},
        {"name": "Xà lách xoăn", "description": "Xà lách tươi giòn ăn sống cuộn thịt nướng chấm sốt"},
        {"name": "Rau mồng tơi", "description": "Mồng tơi non nấu canh cua đồng mướp hương giải nhiệt mùa hè"},
        {"name": "Rau dền đỏ", "description": "Rau dền ngọt mát nấu canh tôm đồng màu đỏ đẹp mắt"},
        {"name": "Bông cải xanh", "description": "Súp lơ xanh giòn ngọt giàu vitamin, luộc chấm kho quẹt"},
        {"name": "Rau ngót sạch", "description": "Rau ngót bùi ngọt thanh mát nấu canh thịt nạc giải nhiệt"},
        {"name": "Rau má tươi", "description": "Rau má giải nhiệt làm nộm thịt bò hoặc xay nước sinh tố"},
        {"name": "Cà rốt tươi", "description": "Cà rốt giòn ngọt màu cam tươi sáng giàu tiền vitamin A"},
        {"name": "Củ cải trắng", "description": "Củ cải ngọt nước dùng ninh nước dùng thanh hoặc kho thịt"},
        {"name": "Khoai tây vàng", "description": "Khoai tây dẻo bùi chiên giòn xóc phô mai hoặc hầm bò vang"},
        {"name": "Khoai lang mật", "description": "Khoai lang ngọt dẻo chảy mật nướng than hoặc chiên bơ"},
        {"name": "Khoai môn sáp", "description": "Khoai môn dẻo bùi nấu lẩu vịt om sấu hoặc nấu chè"},
        {"name": "Cà chua chín mọng", "description": "Cà chua đỏ tươi tạo vị chua thanh tự nhiên cho món canh và sốt"},
        {"name": "Dưa leo baby", "description": "Dưa chuột tươi giòn mọng nước ăn kèm chống ngấy"},
        {"name": "Bắp mỹ ngọt", "description": "Ngô ngọt vàng hạt mọng nước tạo vị ngọt tự nhiên cho nước dùng"},
        {"name": "Măng tươi Tây Bắc", "description": "Măng củ luộc thái lát xào thịt bò hoặc nấu vịt xáo măng"},
        {"name": "Măng củ chua", "description": "Măng chua giòn cay nấu canh cá hoặc ăn kèm bún riêu cua"},
        {"name": "Giá đỗ tươi", "description": "Giá đỗ giòn mát ăn sống kèm phở bún hoặc xào lòng mề"},
        {"name": "Củ sen tươi", "description": "Củ sen giòn bùi ngọt mát hầm đuôi bò hoặc nấu canh sườn"},
        {"name": "Hoa chuối non", "description": "Hoa chuối thái mỏng làm nộm gà xé phay hoặc ăn kèm bún cá"},
        {"name": "Mướp hương", "description": "Mướp hương thơm ngát xào lòng gà hoặc nấu canh cua mồng tơi"},
        {"name": "Bí đỏ hồ lô", "description": "Bí đỏ ngọt bùi dẻo thơm nấu súp kem bí đỏ hoặc canh xương"},
        {"name": "Nấm kim châm", "description": "Nấm kim châm trắng giòn dai cuộn ba chỉ bò hoặc nhúng lẩu"},
        {"name": "Nấm đùi gà baby", "description": "Nấm đùi gà thịt dày dai bùi xào bơ tỏi hoặc nướng mỡ hành"},
        {"name": "Nấm hương tươi", "description": "Nấm hương thơm nồng đậm đà cho các món xào, súp và canh"},
        {"name": "Nấm rơm tươi", "description": "Nấm rơm tròn béo ngọt bùi nấu cháo hoặc kho tiêu tộ"},
        {"name": "Nấm đông cô khô", "description": "Nấm đông cô ngâm nở thơm lừng hầm thuốc bắc tiềm vịt"},
        {"name": "Nấm mộc nhĩ", "description": "Nấm mèo đen giòn sần sật trong nhân nem rán và chả giò"},
        {"name": "Nấm tuyết ngân nhĩ", "description": "Nấm tuyết trắng giòn thanh mát nấu súp hải sản hoặc chè tuyết yến"},
        {"name": "Nấm linh chi nâu", "description": "Nấm ngọc châm nâu ngọt giòn đậm đà vị ngọt nấm tự nhiên"},
        {"name": "Nấm Truffle Đen", "description": "Nấm kim cương đen thượng hạng mang hương vị quý phái quyến rũ"},
    ],
    "Sữa & Chế phẩm": [
        {"name": "Sữa tươi tiệt trùng", "description": "Sữa tươi nguyên chất béo thơm làm nền trà sữa và bánh"},
        {"name": "Sữa đặc có đường", "description": "Sữa đặc sánh đậm ngọt bùi cho cà phê sữa nâu và sinh tố"},
        {"name": "Kem béo thực vật", "description": "Kem béo thực vật tạo độ sánh mịn thơm ngậy cho đồ uống và nước xốt"},
        {"name": "Kem tươi whipping", "description": "Kem tươi whipping cream đánh bông mịn béo phủ bánh và đồ uống"},
        {"name": "Bơ lạt thực vật", "description": "Bơ thơm ngậy xào ốc bơ tỏi hoặc phết bánh mì nướng giòn"},
        {"name": "Bơ động vật béo ngậy", "description": "Bơ béo động vật cao cấp chuyên áp chảo bít tết và nước sốt Âu"},
        {"name": "Phô mai Mozzarella", "description": "Phô mai kéo sợi dẻo dai béo ngậy cho pizza và gà nướng cay"},
        {"name": "Phô mai Cheddar", "description": "Phô mai lát vàng thơm đậm đà kẹp burger hoặc bánh mì nóng"},
        {"name": "Kem cheese mặn", "description": "Lớp kem phô mai sánh mịn mặn ngọt béo ngậy phủ trà hoa quả"},
        {"name": "Sữa chua men sống", "description": "Sữa chua lên men tự nhiên chua thanh mát lành tráng miệng"},
        {"name": "Sữa hạt yến mạch", "description": "Sữa hạt yến mạch thơm bùi dinh dưỡng cao cho thực đơn thuần chay"},
    ],
    "Trứng": [
        {"name": "Trứng gà ta", "description": "Trứng gà ta lòng đỏ vàng cam béo bùi ăn kèm phở cháo mì"},
        {"name": "Trứng gà công nghiệp", "description": "Trứng gà tươi tuyển chọn kích cỡ đồng đều dùng ốp la chiên làm bánh"},
        {"name": "Trứng vịt tươi", "description": "Trứng vịt to lòng đỏ béo đậm kho thịt ba chỉ hoặc làm xíu mại"},
        {"name": "Trứng cút tươi", "description": "Trứng cút nhỏ xinh bùi béo luộc nhúng lẩu hoặc kho sườn"},
        {"name": "Trứng cút lộn", "description": "Trứng cút lộn ngọt đậm nước dùng xào me chua ngọt rắc lạc rang"},
        {"name": "Trứng vịt lộn", "description": "Trứng vịt lộn bổ dưỡng ăn kèm gừng tươi thái sợi và rau răm"},
        {"name": "Trứng muối lòng đỏ dẻo", "description": "Lòng đỏ trứng muối dẻo bùi vàng óng làm sốt trứng muối hoặc bánh bao"},
        {"name": "Trứng bắc thảo", "description": "Trứng bách thảo đen bóng lòng dẻo bùi thơm độc đáo ăn cùng cháo trắng"},
    ],
    "Đậu & Các loại hạt": [
        {"name": "Đậu hũ non", "description": "Đậu hũ non mềm mịn mướt mượt tan trong miệng nấu canh súp"},
        {"name": "Đậu hũ mơ chiên vàng", "description": "Đậu phụ mơ vỏ giòn ruột mềm mọng ăn kèm bún đậu mắm tôm"},
        {"name": "Váng đậu khô", "description": "Tàu hũ ky chiên giòn rụm nhúng lẩu hút trọn nước lẩu đậm đà"},
        {"name": "Đậu phộng rang", "description": "Lạc rang muối giòn bùi rắc nộm gỏi, chè hoặc mì cay"},
        {"name": "Đậu xanh xát vỏ", "description": "Đậu xanh đãi vỏ nấu chè xôi hoặc làm nhân bánh truyền thống"},
        {"name": "Đậu đỏ hạt to", "description": "Đậu đỏ hạt căng mẩy ninh mềm bùi ngọt nấu chè trà sữa"},
        {"name": "Đậu đen xanh lòng", "description": "Đậu đen hạt nhỏ ruột xanh thanh nhiệt giải độc ngày hè"},
        {"name": "Hạt mè trắng rang", "description": "Vừng trắng thơm bùi rắc trang trí và gia tăng hương vị món nướng"},
        {"name": "Hạt điều rang muối", "description": "Hạt điều Bình Phước giòn rụm béo ngậy vị mặn mà"},
        {"name": "Hạt sen tươi", "description": "Hạt sen tươi Huế bùi ngọt thanh tao hầm gà hoặc nấu chè long nhãn"},
        {"name": "Hạt dẻ cười", "description": "Hạt dẻ cười giòn thơm bùi béo bổ dưỡng"},
        {"name": "Hạt óc chó", "description": "Hạt óc chó béo bùi giàu axit béo Omega-3 lành mạnh"},
        {"name": "Hạnh nhân lát", "description": "Hạnh nhân sấy giòn lát mỏng rắc kem sữa chua chè khúc bạch"},
        {"name": "Hạt chia hữu cơ", "description": "Hạt chia nở đều thanh mát cho nước giải khát và trà hoa quả"},
    ],
    "Tinh bột & Ngũ cốc": [
        {"name": "Gạo thơm ST25", "description": "Gạo tiến vua hạt dài dẻo thơm mùi lá dứa đậm vị cơm nhà"},
        {"name": "Gạo nếp cái hoa vàng", "description": "Nếp cái hoa vàng dẻo thơm lừng chuyên nấu xôi chè bánh truyền thống"},
        {"name": "Gạo Tám xoan Hải Hậu", "description": "Gạo tám xoan hạt nhỏ dẻo thơm tự nhiên cơm ngọt bùi"},
        {"name": "Gạo lứt huyết rồng", "description": "Gạo lứt đỏ giàu chất xơ và khoáng chất cho thực đơn giữ dáng"},
        {"name": "Bánh phở tươi Hà Nội", "description": "Bánh phở tráng mỏng mềm mướt dai tự nhiên làm từ gạo nguyên chất"},
        {"name": "Bún tươi sợi nhỏ", "description": "Bún tươi trắng mềm thanh mát ăn kèm bún chả, bún riêu, bún cá"},
        {"name": "Bún bò Huế sợi to", "description": "Bún sợi tròn to dai ngon ngấm đẫm nước dùng bún bò Huế cay nồng"},
        {"name": "Bánh đa đỏ Hải Phòng", "description": "Bánh đa đỏ dai giòn bản to đặc trưng của món bánh đa cua biển"},
        {"name": "Miến dong Tây Bắc", "description": "Miến dong làm từ củ dong riềng dai ngon không bị nát nhũn"},
        {"name": "Mì trứng tươi", "description": "Mì trứng vàng óng sợi dai béo cho mì vằn thắn và mì xào giòn"},
        {"name": "Mì tôm Miliket", "description": "Mì tôm hai con tôm giấy kraft sợi giòn dai ăn lẩu thân thuộc"},
        {"name": "Mì Ý Spaghetti", "description": "Mì Ý sợi dài dai ngon chuẩn al dente sốt bò băm cà chua"},
        {"name": "Mì Udon tươi", "description": "Mì Udon sợi trắng dày dai mềm phong cách Nhật Bản"},
        {"name": "Bánh mì baguette", "description": "Bánh mì vỏ giòn ruột xốp kẹp thịt nướng, pate hoặc chấm sữa"},
        {"name": "Bánh hỏi Nam Bộ", "description": "Bánh hỏi đan lưới sợi nhỏ mềm mại cuốn heo quay thịt nướng"},
        {"name": "Hủ tiếu dai Sa Đéc", "description": "Hủ tiếu sợi trong dai giòn nấu súp hoặc hủ tiếu trộn sốt đậm vị"},
        {"name": "Quẩy giòn vàng ruộm", "description": "Quẩy vàng ươm giòn rụm xốp mềm ăn kèm phở bò cháo sườn"},
        {"name": "Bột chiên giòn", "description": "Bột áo chiên hải sản gà rán giòn rụm màu vàng đẹp mắt"},
    ],
    "Gia vị & Nước xốt": [
        {"name": "Nước mắm cá cơm Phú Quốc", "description": "Nước mắm cốt truyền thống 40 độ đạm đậm đà thơm dịu"},
        {"name": "Nước tương đậu nành", "description": "Xì dầu lên men tự nhiên thơm dịu chấm dimsum và nêm xào"},
        {"name": "Dầu hào hảo hạng", "description": "Dầu hào sánh quyện đậm đà vị umami cho các món xào rau củ thịt"},
        {"name": "Hạt nêm từ thịt", "description": "Gia vị hạt nêm từ xương ống tủy ngọt nước đậm đà"},
        {"name": "Tiêu đen Phú Quốc", "description": "Hạt tiêu đen xay cay nồng ấm thơm phức đặc trưng đảo ngọc"},
        {"name": "Tiêu xanh tươi", "description": "Tiêu xanh nguyên chùm cay the sảng khoái hầm thịt bò bao tử"},
        {"name": "Tỏi tép Lý Sơn", "description": "Tỏi tép nhỏ giòn thơm nồng không hăng dùng phi thơm và pha nước mắm"},
        {"name": "Hành tím Kinh Môn", "description": "Hành tím thơm giòn ngọt nêm nếm nước dùng hoặc phi giòn rụm"},
        {"name": "Hành phi giòn rụm", "description": "Hành tím bào mỏng phi vàng giòn rụm thơm lừng rắc xôi bánh cuốn"},
        {"name": "Gừng củ tươi", "description": "Gừng già cay nồng ấm bụng khử tanh hải sản vịt gà"},
        {"name": "Sả cây tươi", "description": "Sả đập dập thơm the tinh dầu nồng nàn trong lẩu Thái và bún bò"},
        {"name": "Ớt chỉ thiên cay xé", "description": "Ớt đỏ cay nồng rực lửa cho nước chấm và nước dùng lẩu cay"},
        {"name": "Ớt sừng đỏ", "description": "Ớt sừng ngọt màu đỏ tươi bắt mắt trang trí và giảm cay"},
        {"name": "Riềng tươi xay", "description": "Củ riềng thơm nồng cho món giả cầy, cá kho riềng và chả cá Lã Vọng"},
        {"name": "Nghệ vàng tươi", "description": "Nghệ tươi giã nhỏ tạo màu vàng rực óng ả và hương thơm thảo mộc"},
        {"name": "Quế hồi thảo quả", "description": "Bộ thảo mộc gia truyền nướng thơm dậy mùi nước phở bò gia truyền"},
        {"name": "Mắm tôm Thanh Hóa", "description": "Mắm tôm tím thơm nồng gia truyền ăn bún đậu mắm tôm bún riêu"},
        {"name": "Mắm nêm cá cơm", "description": "Mắm nêm pha dứa ớt tỏi đậm đà chấm bánh tráng cuốn thịt heo"},
        {"name": "Giấm gạo lên men", "description": "Giấm gạo chua thanh thơm dịu pha nước mắm chấm và nhúng giấm"},
        {"name": "Nước cốt me chua ngọt", "description": "Nước cốt me chua dịu nấu canh chua hoặc sốt me cút lộn xào me"},
        {"name": "Mật ong hoa nhãn", "description": "Mật ong ngọt thanh thơm mát ướp sườn nướng cánh gà mật ong"},
        {"name": "Rượu mai quế lộ", "description": "Rượu thơm quế hồi hoa tiêu ướp nhân thập cẩm và thịt nướng xá xíu"},
        {"name": "Rau húng quế", "description": "Rau húng quế thơm cay ăn kèm phở bò bún bò nem nướng"},
        {"name": "Rau mùi ta", "description": "Ngò rí lá xanh thơm dịu rắc súp canh phở tạo nét thanh tao"},
        {"name": "Mùi tàu (ngò gai)", "description": "Ngò gai thơm nồng ăn cùng canh chua phở bò bún cá"},
        {"name": "Hành lá (hành hoa)", "description": "Hành hoa tươi thái nhỏ rắc các món nước súp canh phở bún"},
        {"name": "Rau thì là", "description": "Thì là thơm ngát đặc trưng khử tanh canh cá chả cá thát lát"},
        {"name": "Rau kinh giới", "description": "Kinh giới cay thơm ăn kèm bún đậu mắm tôm ốc luộc"},
        {"name": "Rau tía tô", "description": "Tía tô thơm nồng giải cảm ăn cháo nóng bún ốc chuối đậu"},
        {"name": "Lá lốt non", "description": "Lá lốt thơm bùi cuốn bò nướng lá lốt hoặc xào ốc chuối đậu"},
        {"name": "Lá chanh bánh tẻ", "description": "Lá chanh thái chỉ mỏng rắc gà luộc rang muối thơm ngát"},
        {"name": "Rau răm tươi", "description": "Rau răm cay thơm nồng ăn trứng vịt lộn gỏi gà nộm hàu"},
        {"name": "Sốt bơ tỏi", "description": "Sốt bơ tỏi sánh vàng thơm nức béo ngậy xào ốc hải sản"},
        {"name": "Sốt chua ngọt", "description": "Sốt chua ngọt đậm đà chuẩn vị sườn xào và cá chiên sốt"},
        {"name": "Sốt tiêu đen Hồng Kông", "description": "Sốt tiêu đen cay ấm sánh mịn phủ thăn bò né bít tết"},
        {"name": "Sốt mayonnaise", "description": "Sốt mayonnaise béo dịu chấm nem chua rán đồ chiên giòn"},
        {"name": "Sốt BBQ hun khói", "description": "Sốt ướp nướng BBQ kiểu Mỹ thơm nồng mùi khói gỗ sồi"},
        {"name": "Tương ớt cay nồng", "description": "Tương ớt chua cay đậm đà ăn phở bún và chấm đồ chiên"},
        {"name": "Tương cà chua", "description": "Tương cà ngọt thanh chấm khoai tây chiên bánh pizza"},
    ],
    "Trái cây & Đồ uống": [
        {"name": "Chanh tươi mọng nước", "description": "Chanh xanh nhiều nước chua thanh pha nước chấm giải khát"},
        {"name": "Quất tươi thơm ngát", "description": "Tắc tươi thơm dịu pha trà quất mật ong hoặc chấm mắm tôm"},
        {"name": "Xoài cát chín ngọt", "description": "Xoài cát Chu thơm ngọt vàng ươm làm sinh tố chè xoài"},
        {"name": "Dưa hấu ruột đỏ", "description": "Dưa hấu ngọt mát mọng nước tráng miệng hoặc ép nước tươi"},
        {"name": "Dừa nạo & Nước cốt dừa", "description": "Nước cốt dừa sánh béo ngậy nấu chè cà ri chè thái"},
        {"name": "Bưởi da xanh tép hồng", "description": "Bưởi da xanh mọng nước tép giòn ngọt làm gỏi bưởi tôm thịt"},
        {"name": "Dâu tây Đà Lạt", "description": "Dâu tây chín đỏ chua ngọt làm sinh tố trà dâu topping bánh"},
        {"name": "Cà phê Robusta Đắk Lắk", "description": "Cà phê phin nguyên chất đậm đà đắng êm sánh đậm hương vị Việt"},
        {"name": "Trà xanh Thái Nguyên", "description": "Trà mạn nõn tôm chát dịu ngọt hậu lắng đọng văn hóa trà Việt"},
        {"name": "Trà đen Oolong đậm vị", "description": "Trà Oolong thơm nồng nàn đậm vị nền trà sữa trà trái cây hảo hạng"},
        {"name": "Trân châu đen dẻo dai", "description": "Topping trân châu đường đen dẻo dai ngọt thanh cho trà sữa"},
        {"name": "Thạch pudding trứng", "description": "Pudding trứng mềm mịn béo ngậy ngập tràn hương vani"},
        {"name": "Thạch dừa xiêm", "description": "Thạch dừa giòn sần sật thanh mát giải nhiệt mùa hè"},
    ],
}


class IngredientSeedService:
    @staticmethod
    def seed_ingredient_groups(db: Session) -> Dict[str, int]:
        """Tạo hoặc cập nhật 10 nhóm nguyên liệu chuẩn."""
        group_id_map: Dict[str, int] = {}
        for g_data in INGREDIENT_GROUPS_DATA:
            group = db.scalar(select(IngredientGroup).where(IngredientGroup.name == g_data["name"]))
            if not group:
                group = IngredientGroup(
                    name=g_data["name"],
                    description=g_data["description"],
                    display_order=g_data["display_order"],
                    is_active=True,
                )
                db.add(group)
                db.flush()
                logger.info("Đã tạo nhóm nguyên liệu mới: %s (ID %d)", group.name, group.id)
            else:
                group.description = g_data["description"]
                group.display_order = g_data["display_order"]
                group.is_active = True
                db.flush()
            group_id_map[group.name] = group.id
        db.commit()
        return group_id_map

    @staticmethod
    def seed_master_ingredients(db: Session) -> Dict[str, int]:
        """Nạp bể hơn 190 nguyên liệu đa dạng vào bảng ingredients."""
        group_id_map = IngredientSeedService.seed_ingredient_groups(db)
        ing_id_map: Dict[str, int] = {}

        inserted_count = 0
        updated_count = 0

        for group_name, items in MASTER_INGREDIENTS_DATA.items():
            g_id = group_id_map.get(group_name)
            for item in items:
                name = item["name"].strip()
                desc = item.get("description", "")
                existing = db.scalar(select(Ingredient).where(func.lower(Ingredient.name) == name.lower()))
                if not existing:
                    new_ing = Ingredient(
                        name=name,
                        description=desc,
                        group_id=g_id,
                        is_active=True,
                    )
                    db.add(new_ing)
                    db.flush()
                    ing_id_map[name.lower()] = new_ing.id
                    inserted_count += 1
                else:
                    existing.group_id = g_id
                    if desc:
                        existing.description = desc
                    existing.is_active = True
                    db.flush()
                    ing_id_map[name.lower()] = existing.id
                    updated_count += 1

        db.commit()
        logger.info(
            "Hoàn tất nạp bể nguyên liệu master: %d nguyên liệu mới, %d nguyên liệu cập nhật.",
            inserted_count,
            updated_count,
        )
        return ing_id_map

    @staticmethod
    def derive_ingredients_for_dish_name(dish_name: str) -> List[str]:
        """Suy luận danh sách 3 - 6 nguyên liệu ẩm thực thực tế dựa trên tên món ăn."""
        n = dish_name.lower()
        res: List[str] = []

        # 1. Nhận diện món nước / tinh bột chính
        if "phở" in n:
            res.append("Bánh phở tươi Hà Nội")
            res.append("Hành lá (hành hoa)")
            res.append("Quế hồi thảo quả")
            res.append("Nước mắm cá cơm Phú Quốc")
            if "gà" in n:
                res.append("Thịt gà ta thả vườn")
                res.append("Lá chanh bánh tẻ")
            elif "tái" in n or "nạm" in n or "gầu" in n or "bò" in n:
                res.append("Thịt bò bắp hoa")
                res.append("Gừng củ tươi")
        elif "bún chả" in n:
            res.extend(["Bún tươi sợi nhỏ", "Thịt heo ba chỉ", "Nước mắm cá cơm Phú Quốc", "Hành tím Kinh Môn", "Rau húng quế"])
        elif "bún bò" in n:
            res.extend(["Bún bò Huế sợi to", "Nạm bò vân mỡ", "Móng giò heo", "Sả cây tươi", "Ớt chỉ thiên cay xé"])
        elif "bún cá" in n:
            res.extend(["Bún tươi sợi nhỏ", "Chả cá thát lát", "Rau thì là", "Cà chua chín mọng", "Nước mắm cá cơm Phú Quốc"])
        elif "bún đậu" in n:
            res.extend(["Bún tươi sợi nhỏ", "Đậu hũ mơ chiên vàng", "Mắm tôm Thanh Hóa", "Thịt heo ba chỉ", "Rau kinh giới"])
        elif "bún riêu" in n or "bánh đa cua" in n:
            res.extend(["Bánh đa đỏ Hải Phòng" if "bánh đa" in n else "Bún tươi sợi nhỏ", "Cà chua chín mọng", "Đậu hũ mơ chiên vàng", "Măng củ chua", "Rau muống nước"])
        elif "bún" in n:
            res.extend(["Bún tươi sợi nhỏ", "Hành lá (hành hoa)", "Nước mắm cá cơm Phú Quốc"])
        elif "miến" in n:
            res.extend(["Miến dong Tây Bắc", "Mộc nhĩ", "Nấm hương tươi", "Hành lá (hành hoa)"])
        elif "mì ý" in n or "spaghetti" in n:
            res.extend(["Mì Ý Spaghetti", "Thăn bò mềm", "Cà chua chín mọng", "Phô mai Cheddar", "Dầu hào hảo hạng"])
        elif "mì" in n:
            res.extend(["Mì trứng tươi", "Cải thìa tươi", "Hành lá (hành hoa)", "Dầu hào hảo hạng"])
        elif "cơm sườn" in n or "cơm tấm" in n:
            res.extend(["Gạo Tám xoan Hải Hậu", "Sườn non heo", "Trứng gà ta", "Nước mắm cá cơm Phú Quốc", "Dưa leo baby"])
        elif "cơm gà" in n:
            res.extend(["Gạo thơm ST25", "Thịt gà ta thả vườn", "Dưa leo baby", "Cà chua chín mọng", "Nước mắm cá cơm Phú Quốc"])
        elif "cơm rang" in n or "cơm chiên" in n:
            res.extend(["Gạo Tám xoan Hải Hậu", "Trứng gà ta", "Hành lá (hành hoa)", "Cà rốt tươi", "Dầu hào hảo hạng"])
        elif "cơm niêu" in n:
            res.extend(["Gạo thơm ST25", "Hành tím Kinh Môn", "Dầu hào hảo hạng", "Tiêu đen Phú Quốc"])
        elif "cơm" in n:
            res.extend(["Gạo Tám xoan Hải Hậu", "Dưa leo baby", "Nước mắm cá cơm Phú Quốc"])
        elif "xôi" in n:
            res.extend(["Gạo nếp cái hoa vàng", "Hành phi giòn rụm"])
            if "chả mực" in n:
                res.extend(["Mực ống tươi", "Nước mắm cá cơm Phú Quốc"])
            elif "xéo" in n:
                res.extend(["Đậu xanh xát vỏ"])
            elif "thịt" in n:
                res.extend(["Thịt heo ba chỉ"])
        elif "cháo" in n:
            res.extend(["Gạo Tám xoan Hải Hậu", "Hành lá (hành hoa)", "Tiêu đen Phú Quốc", "Quẩy giòn vàng ruộm"])
            if "sườn" in n:
                res.append("Sườn sụn heo")
            elif "gà" in n:
                res.append("Thịt gà ta thả vườn")
            elif "bò" in n:
                res.append("Thịt bò bắp hoa")
        elif "bánh mì" in n:
            res.extend(["Bánh mì baguette", "Dưa leo baby", "Rau mùi ta", "Sốt mayonnaise"])
            if "thịt" in n or "chả" in n or "heo" in n:
                res.append("Thịt heo ba chỉ")
            elif "bò" in n:
                res.append("Thăn bò mềm")
            elif "trứng" in n:
                res.append("Trứng gà ta")

        # 2. Nhận diện các loại thịt / đạm chính nếu chưa có
        if ("gà" in n) and ("Thịt gà ta thả vườn" not in res):
            res.extend(["Thịt gà ta thả vườn", "Lá chanh bánh tẻ", "Hành lá (hành hoa)"])
        elif ("bò" in n or "bít tết" in n or "steak" in n) and not any("bò" in r.lower() for r in res):
            res.extend(["Thăn bò mềm", "Hành tím Kinh Môn", "Tiêu đen Phú Quốc", "Tỏi tép Lý Sơn"])
        elif ("heo" in n or "sườn" in n) and not any("heo" in r.lower() or "sườn" in r.lower() for r in res):
            res.extend(["Sườn non heo", "Hành tím Kinh Môn", "Nước mắm cá cơm Phú Quốc"])
        elif "dê" in n and "Thịt dê tươi" not in res:
            res.extend(["Thịt dê tươi", "Sả cây tươi", "Gừng củ tươi", "Rau húng quế"])
        elif "vịt" in n and "Thịt vịt cỏ Vân Đình" not in res:
            res.extend(["Thịt vịt cỏ Vân Đình", "Gừng củ tươi", "Nước mắm cá cơm Phú Quốc"])
        elif "cút" in n:
            res.extend(["Trứng cút lộn" if "lộn" in n else "Chim cút tươi", "Nước cốt me chua ngọt", "Đậu phộng rang", "Rau răm tươi"])
        elif "ốc" in n:
            res.extend(["Ốc hương biển", "Sả cây tươi", "Lá chanh bánh tẻ", "Ớt chỉ thiên cay xé", "Gừng củ tươi"])
        elif "mực" in n and not any("mực" in r.lower() for r in res):
            res.extend(["Mực ống tươi", "Cà chua chín mọng", "Tỏi tép Lý Sơn", "Nước mắm cá cơm Phú Quốc"])
        elif "tôm" in n and not any("tôm" in r.lower() for r in res):
            res.extend(["Tôm sú tươi", "Tỏi tép Lý Sơn", "Ớt chỉ thiên cay xé"])
        elif "cá" in n and not any("cá" in r.lower() for r in res):
            res.extend(["Cá thu một nắng", "Rau thì là", "Gừng củ tươi", "Nước mắm cá cơm Phú Quốc"])

        # 3. Lẩu
        if "lẩu" in n:
            if "Nấm kim châm" not in res:
                res.append("Nấm kim châm")
            if "Bắp mỹ ngọt" not in res:
                res.append("Bắp mỹ ngọt")
            if "Rau muống nước" not in res:
                res.append("Rau muống nước")
            if "Đậu hũ non" not in res:
                res.append("Đậu hũ non")
            if "Mì tôm Miliket" not in res and not any("bún" in r.lower() or "mì" in r.lower() for r in res):
                res.append("Mì tôm Miliket")
            if "tomyum" in n or "thái" in n:
                res.extend(["Tôm sú tươi", "Sả cây tươi", "Nước cốt me chua ngọt"])

        # 4. Đồ uống, tráng miệng, trà sữa, cà phê
        if "cà phê" in n:
            res = ["Cà phê Robusta Đắk Lắk"]
            if "sữa" in n or "bạc xỉu" in n:
                res.extend(["Sữa đặc có đường", "Sữa tươi tiệt trùng"])
            if "muối" in n:
                res.extend(["Kem cheese mặn", "Sữa đặc có đường"])
        elif "trà sữa" in n:
            res = ["Trà đen Oolong đậm vị", "Sữa tươi tiệt trùng", "Trân châu đen dẻo dai", "Sữa đặc có đường"]
            if "kem cheese" in n or "phô mai" in n:
                res.append("Kem cheese mặn")
            if "pudding" in n:
                res.append("Thạch pudding trứng")
        elif "trà" in n and ("chanh" in n or "đào" in n or "tắc" in n or "quất" in n or "vải" in n):
            res = ["Trà xanh Thái Nguyên", "Quất tươi thơm ngát", "Chanh tươi mọng nước"]
        elif "sinh tố" in n or "nước ép" in n:
            res = ["Chanh tươi mọng nước", "Sữa đặc có đường", "Sữa tươi tiệt trùng"]
            if "xoài" in n:
                res.append("Xoài cát chín ngọt")
            elif "dưa hấu" in n:
                res.append("Dưa hấu ruột đỏ")
            elif "dâu" in n:
                res.append("Dâu tây Đà Lạt")
        elif "chè" in n:
            res = ["Hạt sen tươi", "Đậu đỏ hạt to", "Dừa nạo & Nước cốt dừa", "Thạch dừa xiêm"]

        # Nếu vẫn chưa map được gì thích hợp
        if not res:
            res = ["Gạo thơm ST25", "Thịt heo ba chỉ", "Rau muống nước", "Nước mắm cá cơm Phú Quốc", "Tỏi tép Lý Sơn"]

        # Loại bỏ trùng lặp và giới hạn 5-6 nguyên liệu
        seen = set()
        unique_res = []
        for r in res:
            if r not in seen:
                seen.add(r)
                unique_res.append(r)
        return unique_res[:6]

    @staticmethod
    def enrich_dishes_with_real_ingredients(db: Session, force: bool = False) -> Dict[str, int]:
        """
        Làm giàu nguyên liệu cho toàn bộ 775 món ăn trong CSDL.
        Thay thế các placeholder thô ('Nguyên liệu tuyển chọn', 'Gia vị thảo mộc'...)
        bằng các nguyên liệu ẩm thực thực tế, đồng thời đồng bộ bảng dish_ingredients.
        """
        # 1. Đảm bảo master ingredients pool đã được nạp
        IngredientSeedService.seed_master_ingredients(db)

        # Lấy bản đồ tên nguyên liệu -> ID nguyên liệu
        all_ings = db.scalars(select(Ingredient)).all()
        name_to_ing = {i.name.lower().strip(): i for i in all_ings}

        # Danh sách các từ khóa placeholder cần thay thế
        PLACEHOLDER_KEYWORDS = [
            "tuyển chọn",
            "thảo mộc",
            "tươi sống",
            "truyền thống",
            "tươi sạch gia lâm",
            "tự nhiên",
            "attp",
            "nguyên liệu a",
            "nguyên liệu b",
            "nguyên liệu c",
            "cascade",
        ]

        def _is_placeholder_list(ing_list: Optional[List[str]]) -> bool:
            if not ing_list:
                return True
            # Nếu tất cả các nguyên liệu đều chứa từ khóa placeholder
            for item in ing_list:
                item_lower = (item or "").lower()
                is_p = any(pk in item_lower for pk in PLACEHOLDER_KEYWORDS)
                if not is_p:
                    return False
            return True

        dishes = db.scalars(select(Dish)).all()
        updated_dish_count = 0
        dish_ing_links_created = 0

        for dish in dishes:
            current_ings = dish.ingredients or []
            if force or _is_placeholder_list(current_ings):
                # Suy luận nguyên liệu thực tế cho món ăn này
                new_ing_names = IngredientSeedService.derive_ingredients_for_dish_name(dish.name)
                dish.ingredients = new_ing_names
                updated_dish_count += 1

                # Xóa các liên kết dish_ingredients cũ của món này
                db.execute(text("DELETE FROM dish_ingredients WHERE dish_id = :d_id"), {"d_id": dish.id})

                # Thêm liên kết mới vào dish_ingredients
                for ing_name in new_ing_names:
                    ing_obj = name_to_ing.get(ing_name.lower().strip())
                    if not ing_obj:
                        # Tạo nhanh nếu chưa có
                        ing_obj = Ingredient(name=ing_name, is_active=True)
                        db.add(ing_obj)
                        db.flush()
                        name_to_ing[ing_name.lower().strip()] = ing_obj

                    db.add(DishIngredient(dish_id=dish.id, ingredient_id=ing_obj.id))
                    dish_ing_links_created += 1

        # Dọn sạch các nguyên liệu dummy thừa không còn món nào liên kết
        dummy_names = [
            "Nguyên liệu tuyển chọn",
            "Nguyên liệu tươi sống",
            "Gia vị thảo mộc",
            "Gia vị truyền thống",
            "Nguyên liệu A",
            "Nguyên liệu B",
            "Nguyên liệu C mới",
            "Nguyên liệu Cascade X",
            "Nguyên liệu Cascade Y",
            "Thực phẩm tươi sạch Gia Lâm",
            "Gia vị tự nhiên",
            "Chứng nhận ATTP",
        ]
        for d_name in dummy_names:
            db.execute(
                text("""
                    DELETE FROM ingredients
                    WHERE lower(name) = lower(:n)
                    AND id NOT IN (SELECT ingredient_id FROM dish_ingredients);
                """),
                {"n": d_name},
            )

        db.commit()
        logger.info(
            "Hoàn tất làm giàu nguyên liệu món ăn: %d món ăn được cập nhật, %d liên kết dish_ingredients được tạo.",
            updated_dish_count,
            dish_ing_links_created,
        )
        return {
            "dishes_updated": updated_dish_count,
            "links_created": dish_ing_links_created,
        }
