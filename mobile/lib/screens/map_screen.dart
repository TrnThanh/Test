import 'package:flutter/material.dart';
import '../l10n/app_language.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../theme/app_colors.dart';
import '../utils/helpers.dart';
import '../widgets/restaurant_menu_widget.dart';

class MapScreen extends StatefulWidget {
  final ApiService api;
  final double? initialLat;
  final double? initialLon;
  final Restaurant? initialRestaurant;
  final RoleLoginResponse? currentUser;
  final VoidCallback onRequireLogin;

  const MapScreen({
    super.key,
    required this.api,
    this.initialLat,
    this.initialLon,
    this.initialRestaurant,
    this.currentUser,
    required this.onRequireLogin,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class CuisineStyle {
  final IconData icon;
  final Color color;
  final String label;

  const CuisineStyle(this.icon, this.color, this.label);
}

CuisineStyle getCuisineStyle(String name, String? description) {
  final lower = ('$name ${description ?? ""}').toLowerCase();
  if (lower.contains('chay') || lower.contains('thực dưỡng')) {
    return const CuisineStyle(Icons.eco, Color(0xFF2E7D32), 'Ẩm thực Chay & Thực dưỡng');
  }
  if (lower.contains('ốc') || lower.contains('sò') || lower.contains('ngao') || lower.contains('nhậu') || lower.contains('hàu') || lower.contains('hến')) {
    return const CuisineStyle(Icons.sports_bar, Color(0xFF0097A7), 'Ốc & Quán lai rai');
  }
  if (lower.contains('chè') || lower.contains('kem') || lower.contains('caramen') || lower.contains('tàu hũ') || lower.contains('flan')) {
    return const CuisineStyle(Icons.icecream, Color(0xFFC2185B), 'Chè & Tráng miệng');
  }
  if (lower.contains('bánh cuốn') || lower.contains('bánh xèo') || lower.contains('gỏi cuốn') || lower.contains('bún chả') || lower.contains('bún đậu') || lower.contains('bánh bèo') || lower.contains('bột lọc')) {
    return const CuisineStyle(Icons.lunch_dining, Color(0xFF5D4037), 'Bánh truyền thống & Món cuốn');
  }
  if (lower.contains('phở') || lower.contains('bún') || lower.contains('miến') || lower.contains('mỳ') || lower.contains('mì') || lower.contains('hủ tiếu') || lower.contains('bánh canh')) {
    return const CuisineStyle(Icons.ramen_dining, Color(0xFF00897B), 'Phở, Bún & Món nước');
  }
  if (lower.contains('cơm') || lower.contains('xôi') || lower.contains('niêu') || lower.contains('sườn nướng')) {
    return const CuisineStyle(Icons.rice_bowl, Color(0xFFE65100), 'Cơm & Xôi');
  }
  if (lower.contains('lẩu') || lower.contains('nướng') || lower.contains('bbq') || lower.contains('bò tảng')) {
    return const CuisineStyle(Icons.outdoor_grill, Color(0xFFD32F2F), 'Lẩu & Nướng');
  }
  if (lower.contains('cà phê') || lower.contains('cafe') || lower.contains('coffee') || lower.contains('trà sữa') || lower.contains('trà đào') || lower.contains('trà') || lower.contains('tea')) {
    return const CuisineStyle(Icons.local_cafe, Color(0xFF6A1B9A), 'Cà phê & Thức uống giải khát');
  }
  if (lower.contains('bánh mì') || lower.contains('bánh mỳ') || lower.contains('bakery') || lower.contains('pate')) {
    return const CuisineStyle(Icons.bakery_dining, Color(0xFF1565C0), 'Bánh mì');
  }
  if (lower.contains('ăn vặt') || lower.contains('nem') || lower.contains('khoai') || lower.contains('bánh tráng')) {
    return const CuisineStyle(Icons.fastfood, Color(0xFFF57F17), 'Đồ ăn vặt');
  }
  return const CuisineStyle(Icons.restaurant, kPrimaryGreen, 'Ẩm thực');
}

class _MapScreenState extends State<MapScreen> {
  late final MapController _mapController;
  final _searchCtrl = TextEditingController();

  // Quản lý TileProvider dùng chung, bật silenceExceptions = true để triệt tiêu ClientException ra console khi huỷ/lỗi tile mạng
  late final TileProvider _tileProvider = NetworkTileProvider(
    silenceExceptions: true,
  );

  // Bounding box giới hạn phạm vi bản đồ trong địa phận Huyện Gia Lâm, Hà Nội
  static final giaLamBounds = LatLngBounds(
    const LatLng(20.9250, 105.8600),
    const LatLng(21.1300, 106.0400),
  );

  // Danh sách toạ độ đường gấp khúc ranh giới đa giác Huyện Gia Lâm ("Cắt miếng bánh")
  static const List<LatLng> giaLamBoundaryPolygon = [
    LatLng(21.1250, 105.9340), // Chóp cực bắc: Ninh Hiệp (giáp TX Từ Sơn, Bắc Ninh)
    LatLng(21.1180, 105.9450), // Đông Ninh Hiệp
    LatLng(21.1080, 105.9520), // Đình Xuyên giáp Tiên Du
    LatLng(21.0960, 105.9600), // Bờ bắc sông Đuống - Phù Đổng
    LatLng(21.0820, 105.9720), // Đền Gióng - Phù Đổng
    LatLng(21.0720, 105.9860), // Ven sông Đuống - Trung Mầu
    LatLng(21.0600, 106.0020), // Mỏm đông bắc bờ bắc sông Đuống (Trung Mầu giáp Thuận Thành)
    LatLng(21.0480, 106.0120), // Qua sông Đuống sang bờ nam Kim Sơn
    LatLng(21.0360, 106.0240), // Đê Lệ Chi
    LatLng(21.0260, 106.0350), // Chóp cực đông Gia Lâm: Lệ Chi
    LatLng(21.0180, 106.0280), // Nam Lệ Chi - Dương Quang
    LatLng(21.0080, 106.0160), // Dương Quang giáp Như Quỳnh, Hưng Yên
    LatLng(20.9990, 106.0020), // Dương Xá (QL5 giáp Như Quỳnh)
    LatLng(20.9920, 105.9880), // Dương Xá giáp Kiêu Kỵ
    LatLng(20.9820, 105.9780), // Kiêu Kỵ giáp Hưng Yên
    LatLng(20.9700, 105.9640), // Cực nam Kiêu Kỵ giáp Văn Giang
    LatLng(20.9620, 105.9480), // Đa Tốn (giáp Ecopark, Văn Giang)
    LatLng(20.9480, 105.9380), // Đa Tốn - Văn Đức
    LatLng(20.9380, 105.9300), // Đông Văn Đức giáp Văn Giang
    LatLng(20.9270, 105.9220), // Chóp cực nam Gia Lâm: Bãi bồi ven sông Hồng xã Văn Đức
    LatLng(20.9340, 105.9140), // Bờ sông Hồng xã Kim Lan
    LatLng(20.9480, 105.9080), // Kim Lan (nhìn sang Thanh Trì)
    LatLng(20.9620, 105.9050), // Bờ sông Hồng làng gốm Bát Tràng
    LatLng(20.9780, 105.9020), // Đê Bát Tràng - cống Xuân Quan
    LatLng(20.9900, 105.9040), // Bờ đê Đông Dư (giáp Cự Khối, Long Biên)
    LatLng(21.0020, 105.9120), // Chân cầu Thanh Trì (Đông Dư - Thạch Bàn)
    LatLng(21.0140, 105.9160), // Trâu Quỳ giáp Thạch Bàn
    LatLng(21.0260, 105.9140), // Cổ Bi giáp Phúc Lợi, Long Biên
    LatLng(21.0360, 105.9100), // Cổ Bi giáp bờ nam sông Đuống (Giang Biên, Long Biên)
    LatLng(21.0480, 105.9040), // Đặng Xá ven sông Đuống
    LatLng(21.0580, 105.8960), // Chân cầu Đuống (giáp Thượng Thanh, Long Biên)
    LatLng(21.0700, 105.8870), // TT. Yên Viên (ga Yên Viên giáp Long Biên)
    LatLng(21.0820, 105.8800), // Yên Viên - Yên Thường (giáp Đông Anh)
    LatLng(21.0950, 105.8820), // Xã Yên Thường (giáp Dục Tú, Đông Anh)
    LatLng(21.1080, 105.8920), // Bắc Yên Thường (giáp Đông Anh)
    LatLng(21.1180, 105.9120), // Ranh giới Đông Anh - Gia Lâm - Bắc Ninh
  ];

  static bool isPointInGiaLam(LatLng point) {
    int count = 0;
    final n = giaLamBoundaryPolygon.length;
    for (int i = 0; i < n; i++) {
      final p1 = giaLamBoundaryPolygon[i];
      final p2 = giaLamBoundaryPolygon[(i + 1) % n];
      if ((p1.latitude <= point.latitude && point.latitude < p2.latitude) ||
          (p2.latitude <= point.latitude && point.latitude < p1.latitude)) {
        if (point.longitude <
            (p2.longitude - p1.longitude) *
                    (point.latitude - p1.latitude) /
                    (p2.latitude - p1.latitude) +
                p1.longitude) {
          count++;
        }
      }
    }
    return (count % 2) == 1;
  }

  LatLng _currentCenter = const LatLng(21.0046, 105.9387); // Mặc định HVNN Gia Lâm
  LatLng? _pinnedLocation;
  double _radiusKm = 5.0;

  LatLng? _userLocation;
  String? _userLocationName;
  bool _detectingLocation = false;

  List<GeocodePlace> _places = [];
  List<Restaurant> _nearbyRestaurants = [];
  List<Restaurant> _allRestaurants = [];
  Restaurant? _selectedRestaurant;
  String _selectedCategory = 'Tất cả';

  static const List<Map<String, dynamic>> _foodCategories = [
    {'name': 'Tất cả', 'icon': Icons.restaurant_menu},
    {'name': 'Phở, Bún & Món nước', 'icon': Icons.ramen_dining},
    {'name': 'Cơm & Xôi', 'icon': Icons.rice_bowl},
    {'name': 'Bánh mì', 'icon': Icons.bakery_dining},
    {'name': 'Bánh truyền thống & Món cuốn', 'icon': Icons.lunch_dining},
    {'name': 'Lẩu & Nướng', 'icon': Icons.outdoor_grill},
    {'name': 'Ốc & Quán lai rai', 'icon': Icons.sports_bar},
    {'name': 'Đồ ăn vặt', 'icon': Icons.fastfood},
    {'name': 'Chè & Tráng miệng', 'icon': Icons.icecream},
    {'name': 'Cà phê & Thức uống giải khát', 'icon': Icons.local_cafe},
    {'name': 'Ẩm thực Chay & Thực dưỡng', 'icon': Icons.eco},
  ];

  String _getCategoryLabel(String cat) {
    const map = {
      'Tất cả': 'cat_all',
      'Phở, Bún & Món nước': 'cat_noodles',
      'Cơm & Xôi': 'cat_rice',
      'Bánh mì': 'cat_banhmi',
      'Bánh truyền thống & Món cuốn': 'cat_traditional',
      'Lẩu & Nướng': 'cat_bbq',
      'Ốc & Quán lai rai': 'cat_seafood',
      'Đồ ăn vặt': 'cat_snacks',
      'Chè & Tráng miệng': 'cat_desserts',
      'Cà phê & Thức uống giải khát': 'cat_coffee',
      'Ẩm thực Chay & Thực dưỡng': 'cat_vegetarian',
    };
    final k = map[cat];
    if (k != null) return tr(k);
    return cat;
  }

  bool _restaurantMatchesCategory(Restaurant r, String cat) {
    if (cat == 'Tất cả') return true;
    final style = getCuisineStyle(r.name, r.description);
    if (style.label == cat) return true;

    final text = '${r.name} ${r.description ?? ""} ${r.recommendation?.featuredDish.name ?? ""}'.toLowerCase();
    if (cat == 'Phở, Bún & Món nước' || cat == 'Phở & Bún') return text.contains('phở') || text.contains('bún') || text.contains('miến') || text.contains('mỳ') || text.contains('mì') || text.contains('hủ tiếu') || text.contains('bánh canh');
    if (cat == 'Cơm & Xôi') return text.contains('cơm') || text.contains('xôi') || text.contains('niêu');
    if (cat == 'Bánh mì') return text.contains('bánh mì') || text.contains('bánh mỳ') || text.contains('pate');
    if (cat == 'Bánh truyền thống & Món cuốn') return text.contains('bánh cuốn') || text.contains('bánh xèo') || text.contains('gỏi cuốn') || text.contains('bún chả') || text.contains('bún đậu') || text.contains('bánh bèo');
    if (cat == 'Lẩu & Nướng') return text.contains('lẩu') || text.contains('nướng') || text.contains('bbq');
    if (cat == 'Ốc & Quán lai rai') return text.contains('ốc') || text.contains('sò') || text.contains('ngao') || text.contains('nhậu') || text.contains('bia') || text.contains('hàu');
    if (cat == 'Đồ ăn vặt') return text.contains('ăn vặt') || text.contains('vặt') || text.contains('nem') || text.contains('khoai') || text.contains('bánh tráng');
    if (cat == 'Chè & Tráng miệng') return text.contains('chè') || text.contains('kem') || text.contains('caramen') || text.contains('tàu hũ') || text.contains('flan');
    if (cat == 'Cà phê & Thức uống giải khát' || cat == 'Cà phê & Trà sữa') return text.contains('cà phê') || text.contains('trà sữa') || text.contains('trà') || text.contains('cafe') || text.contains('coffee');
    if (cat == 'Ẩm thực Chay & Thực dưỡng') return text.contains('chay') || text.contains('thực dưỡng') || text.contains('nấm');
    return false;
  }
  double _currentZoom = 14.0;

  LatLngBounds? get _visibleBounds {
    try {
      return _mapController.camera.visibleBounds;
    } catch (_) {
      return null;
    }
  }

  bool _isRestaurantInVisibleBounds(Restaurant r, LatLngBounds? bounds) {
    if (bounds == null) return true;
    final lat = r.latitude;
    final lon = r.longitude;
    // Buffer mở rộng 0.005 độ (~550m) ra ngoài viền màn hình để cuộn mượt
    return lat >= (bounds.south - 0.005) &&
           lat <= (bounds.north + 0.005) &&
           lon >= (bounds.west - 0.005) &&
           lon <= (bounds.east + 0.005);
  }

  Offset? _getScreenOffset(LatLng point) {
    try {
      return _mapController.camera.latLngToScreenOffset(point);
    } catch (_) {
      return null;
    }
  }

  bool _hasIconCollision(Offset pos, List<Offset> placed, double minDistance) {
    final minSq = minDistance * minDistance;
    for (final p in placed) {
      final dx = pos.dx - p.dx;
      final dy = pos.dy - p.dy;
      if (dx * dx + dy * dy < minSq) {
        return true;
      }
    }
    return false;
  }

  bool _hasLabelCollision(Offset pos, List<Offset> placedLabels) {
    for (final p in placedLabels) {
      final dx = (pos.dx - p.dx).abs();
      final dy = (pos.dy - p.dy).abs();
      if (dx < 75.0 && dy < 28.0) {
        return true;
      }
    }
    return false;
  }

  List<Marker> _buildVisibleRestaurantMarkers() {
    final bounds = _visibleBounds;
    final isRouting = _isLoadingRoute || _routePoints.isNotEmpty;

    if (isRouting) {
      if (_selectedRestaurant != null) {
        return [_buildRestaurantMarker(_selectedRestaurant!, isSelected: true, showLabel: true)];
      }
      return [];
    }

    final rawList = (_allRestaurants.isNotEmpty ? _allRestaurants : _nearbyRestaurants)
        .where((r) => _restaurantMatchesCategory(r, _selectedCategory));

    final inViewSponsors = <Restaurant>[];
    final inViewRegulars = <Restaurant>[];
    Restaurant? inViewSelected;

    for (final r in rawList) {
      final isSelected = _selectedRestaurant?.id == r.id;
      if (isSelected) {
        inViewSelected = r;
        continue;
      }
      if (!_isRestaurantInVisibleBounds(r, bounds)) {
        continue;
      }
      if (r.isSponsor) {
        inViewSponsors.add(r);
      } else {
        inViewRegulars.add(r);
      }
    }

    final markers = <Marker>[];
    final placedIconOffsets = <Offset>[];
    final placedLabelOffsets = <Offset>[];

    // 1. Quán đang chọn (Ưu tiên tuyệt đối): Luôn vẽ cả Icon và Tên
    final selectedTarget = inViewSelected ?? _selectedRestaurant;
    if (selectedTarget != null) {
      markers.add(_buildRestaurantMarker(selectedTarget, isSelected: true, showLabel: true));
      final pos = _getScreenOffset(LatLng(selectedTarget.latitude, selectedTarget.longitude));
      if (pos != null) {
        placedIconOffsets.add(pos);
        placedLabelOffsets.add(pos);
      }
    }

    // Khoảng cách tối thiểu giữa 2 icon trên màn hình (chống đè chùm icon):
    final minIconDistance = _currentZoom >= 17.5 ? 28.0 : 38.0;

    // 2. Quán Sponsor (xuất hiện làm mốc mỏ neo, tự động chống đè icon):
    for (final r in inViewSponsors) {
      final pos = _getScreenOffset(LatLng(r.latitude, r.longitude));
      if (pos != null && _hasIconCollision(pos, placedIconOffsets, minIconDistance)) {
        continue; // Bị đè chùm với icon đã có -> bỏ qua
      }

      // Quyết định hiện tên: Zoom >= 14.2 VÀ không đè chữ với nhãn khác
      bool showLabel = false;
      if (_currentZoom >= 14.2) {
        if (pos == null || !_hasLabelCollision(pos, placedLabelOffsets)) {
          showLabel = true;
        }
      }

      markers.add(_buildRestaurantMarker(r, isSelected: false, showLabel: showLabel));
      if (pos != null) {
        placedIconOffsets.add(pos);
        if (showLabel) placedLabelOffsets.add(pos);
      }
    }

    // 3. Quán Thường (xuất hiện từ zoom >= 15.0):
    if (_currentZoom >= 15.0) {
      final centerLat = _currentCenter.latitude;
      final centerLon = _currentCenter.longitude;
      inViewRegulars.sort((a, b) {
        final da = (a.latitude - centerLat) * (a.latitude - centerLat) + (a.longitude - centerLon) * (a.longitude - centerLon);
        final db = (b.latitude - centerLat) * (b.latitude - centerLat) + (b.longitude - centerLon) * (b.longitude - centerLon);
        return da.compareTo(db);
      });

      for (final r in inViewRegulars) {
        final pos = _getScreenOffset(LatLng(r.latitude, r.longitude));
        // Chống đè icon: Không cho phép 2 icon nằm gần nhau dưới minIconDistance
        if (pos != null && _hasIconCollision(pos, placedIconOffsets, minIconDistance)) {
          continue;
        }

        // Quyết định hiện tên: Zoom >= 15.6 VÀ không đè chữ với nhãn khác
        bool showLabel = false;
        if (_currentZoom >= 15.6) {
          if (pos == null || !_hasLabelCollision(pos, placedLabelOffsets)) {
            showLabel = true;
          }
        }

        markers.add(_buildRestaurantMarker(r, isSelected: false, showLabel: showLabel));
        if (pos != null) {
          placedIconOffsets.add(pos);
          if (showLabel) placedLabelOffsets.add(pos);
        }
      }
    }

    return markers;
  }

  Marker _buildRestaurantMarker(Restaurant r, {required bool isSelected, required bool showLabel}) {
    final style = getCuisineStyle(r.name, r.description);
    return Marker(
      point: LatLng(r.latitude, r.longitude),
      width: isSelected ? 120 : (showLabel ? 96 : 36),
      height: isSelected ? 84 : (showLabel ? 72 : 36),
      alignment: Alignment.center,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedRestaurant = r;
            _showSearchResults = false;
          });
          _clearRoute();
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected)
              AnimatedScale(
                scale: 1.15,
                duration: const Duration(milliseconds: 200),
                child: SizedBox(
                  width: 36,
                  height: 40,
                  child: Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      Positioned(
                        bottom: 1,
                        child: Container(
                          width: 12,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.all(Radius.elliptical(12, 4)),
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.location_on,
                        color: Color(0xFFEA4335),
                        size: 38,
                      ),
                      Positioned(
                        top: 9,
                        child: Container(
                          width: 9,
                          height: 9,
                          decoration: const BoxDecoration(
                            color: Color(0xFF7A0909),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (r.isSponsor)
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: showLabel ? 32 : 28,
                    height: showLabel ? 32 : 28,
                    decoration: BoxDecoration(
                      color: style.color,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFF59E0B), width: 2.0),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x66F59E0B),
                          blurRadius: 4,
                          offset: Offset(0, 1.5),
                        ),
                      ],
                    ),
                    child: Icon(
                      style.icon,
                      color: Colors.white,
                      size: showLabel ? 16 : 14,
                    ),
                  ),
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(1.5),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF59E0B),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.star, color: Colors.white, size: 8),
                    ),
                  ),
                ],
              )
            else
              Container(
                width: showLabel ? 28 : 24,
                height: showLabel ? 28 : 24,
                decoration: BoxDecoration(
                  color: style.color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Icon(
                  style.icon,
                  color: Colors.white,
                  size: showLabel ? 15 : 13,
                ),
              ),
            if (showLabel) ...[
              const SizedBox(height: 2),
              if (r.rating != null && r.rating! > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  margin: const EdgeInsets.only(bottom: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected ? const Color(0xFFD97706) : Colors.amber.shade600,
                      width: 1,
                    ),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 2, offset: Offset(0, 1)),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, size: 10, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 2),
                      Text(
                        r.rating!.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF92400E),
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              Flexible(
                child: Text(
                  r.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isSelected ? 11 : 9.5,
                    fontWeight: (isSelected || r.isSponsor) ? FontWeight.bold : FontWeight.w600,
                    color: isSelected
                        ? const Color(0xFFB45309)
                        : (r.isSponsor ? const Color(0xFF92400E) : const Color(0xFF202124)),
                    height: 1.15,
                    shadows: const [
                      Shadow(offset: Offset(-1.2, -1.2), color: Colors.white, blurRadius: 1.5),
                      Shadow(offset: Offset(1.2, -1.2), color: Colors.white, blurRadius: 1.5),
                      Shadow(offset: Offset(1.2, 1.2), color: Colors.white, blurRadius: 1.5),
                      Shadow(offset: Offset(-1.2, 1.2), color: Colors.white, blurRadius: 1.5),
                      Shadow(offset: Offset(0, 0), color: Colors.white, blurRadius: 3),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _loading = false;
  String? _error;
  bool _showSearchResults = false;

  // Trạng thái tìm đường đi bộ (Walking Route)
  List<LatLng> _routePoints = [];
  double? _routeDistanceMeters;
  double? _routeDurationSeconds;
  bool _isRouteFallback = false;
  bool _isLoadingRoute = false;
  int _routeRequestId = 0;
  String _formatWalkingTimeOnly() {
    final dur = _routeDurationSeconds ?? 0.0;
    final totalMinutes = (dur + 30) ~/ 60;
    if (dur < 60) {
      return 'Dưới 1 phút';
    } else if (totalMinutes < 60) {
      return '$totalMinutes phút';
    } else {
      final hours = totalMinutes ~/ 60;
      final mins = totalMinutes % 60;
      return mins > 0 ? '$hours giờ $mins phút' : '$hours giờ';
    }
  }

  String _formatWalkingDistanceOnly() {
    final dist = _routeDistanceMeters ?? 0.0;
    if (dist < 1000) {
      return '${dist.round()} m';
    } else {
      return '${(dist / 1000).toStringAsFixed(1).replaceAll(".", ",")} km';
    }
  }


  void _clearRoute() {
    _routeRequestId++;
    _isLoadingRoute = false;
    _routePoints.clear();
    _routeDistanceMeters = null;
    _routeDurationSeconds = null;
    _isRouteFallback = false;
    setState(() {});
  }

  Future<void> _fetchWalkingRoute(Restaurant r) async {
    // 0. Nếu chưa có vị trí GPS người dùng, thử định vị lại nhanh
    if (_userLocation == null && !_detectingLocation) {
      await _detectUserLocation(moveToUser: false);
    }

    // 1. Xác định điểm xuất phát: ƯU TIÊN HÀNG ĐẦU LÀ VỊ TRÍ GPS THỰC TẾ CỦA NGƯỜI DÙNG (_userLocation)
    LatLng? startPos;
    if (_userLocation != null) {
      final distToDest = const Distance().as(
        LengthUnit.Meter,
        _userLocation!,
        LatLng(r.latitude, r.longitude),
      );
      if (distToDest >= 20) {
        startPos = _userLocation;
      }
    }

    // 2. Nếu không có GPS (hoặc GPS trùng quán đích), kiểm tra điểm người dùng đã ghim thủ công
    if (startPos == null && _pinnedLocation != null) {
      final distToDest = const Distance().as(
        LengthUnit.Meter,
        _pinnedLocation!,
        LatLng(r.latitude, r.longitude),
      );
      if (distToDest >= 20) {
        startPos = _pinnedLocation;
      }
    }

    // 3. Nếu chưa có GPS và chưa có điểm ghim hợp lệ: Sử dụng vị trí trung tâm mặc định tại Gia Lâm
    if (startPos == null) {
      const defaultOrigin1 = LatLng(21.0046, 105.9387); // HVNN Gia Lâm
      final d1 = const Distance().as(LengthUnit.Meter, defaultOrigin1, LatLng(r.latitude, r.longitude));
      if (d1 >= 20) {
        startPos = defaultOrigin1;
      } else {
        startPos = const LatLng(20.9980, 105.9420); // Thị trấn Trâu Quỳ
      }
    }

    final currentRequestId = ++_routeRequestId;
    setState(() {
      _isLoadingRoute = true;
    });

    try {
      final routeData = await widget.api.getRestaurantWalkingRoute(
        restaurantId: r.id,
        userLat: startPos.latitude,
        userLon: startPos.longitude,
      );

      if (!mounted || currentRequestId != _routeRequestId) return;

      // Chuyển đổi toạ độ: GeoJSON [lon, lat] -> Flutter LatLng(lat, lon)
      final List<LatLng> points = routeData.rawCoordinates
          .map((c) => LatLng(c[1], c[0]))
          .toList();

      setState(() {
        _routePoints = points;
        _routeDistanceMeters = routeData.distanceMeters;
        _routeDurationSeconds = routeData.durationSeconds;
        _isRouteFallback = routeData.isFallback;
      });

      // Fit camera bao quát toàn bộ hành trình
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || currentRequestId != _routeRequestId || _routePoints.isEmpty) return;

        final bounds = LatLngBounds.fromPoints(_routePoints);
        final spanMeters = const Distance().as(
          LengthUnit.Meter,
          bounds.southWest,
          bounds.northEast,
        );

        if (spanMeters < 20) {
          _mapController.move(bounds.center, 16.5);
        } else {
          _mapController.fitCamera(
            CameraFit.bounds(
              bounds: bounds,
              maxZoom: 17.5,
              padding: const EdgeInsets.only(top: 90, bottom: 240, left: 50, right: 50),
            ),
          );
        }
      });
    } catch (e) {
      if (!mounted || currentRequestId != _routeRequestId) return;

      String message;
      final errStr = e.toString().replaceFirst('Exception: ', '').trim();
      if (errStr.toLowerCase().contains('timeout') || errStr.toLowerCase().contains('quá thời gian')) {
        message = 'Yêu cầu tìm đường quá thời gian (10s), vui lòng thử lại';
      } else if (errStr.toLowerCase().contains('socketexception') || errStr.toLowerCase().contains('failed to fetch')) {
        message = 'Không có kết nối mạng, vui lòng kiểm tra Wifi/4G';
      } else if (errStr.isNotEmpty) {
        message = errStr;
      } else {
        message = 'Lỗi hệ thống hoặc kết nối, vui lòng thử lại sau';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted && currentRequestId == _routeRequestId) {
        setState(() {
          _isLoadingRoute = false;
        });
      }
    }
  }


  @override
  void dispose() {
    _searchCtrl.dispose();
    _tileProvider.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _loadAllRestaurants();
    if (widget.initialLat != null && widget.initialLon != null) {
      _currentCenter = LatLng(widget.initialLat!, widget.initialLon!);
      if (widget.initialRestaurant != null) {
        _selectedRestaurant = widget.initialRestaurant;
      }
      _loadNearby(_currentCenter.latitude, _currentCenter.longitude);
      _detectUserLocation(moveToUser: false);
    } else {
      _loadNearby(_currentCenter.latitude, _currentCenter.longitude);
      // Tự động định vị vị trí thực tế của người dùng (GPS thiết bị / IP trực tuyến)
      _detectUserLocation(moveToUser: true);
    }
  }

  Future<void> _detectUserLocation({bool moveToUser = true}) async {
    if (_detectingLocation) return;
    setState(() {
      _detectingLocation = true;
    });

    try {
      String? name;

      // 1. Lấy toạ độ GPS chính xác từ thiết bị / trình duyệt (KHÔNG DÙNG IP FALLBACK)
      final devPos = await LocationService.getDeviceLocation();
      if (devPos != null) {
        final targetPos = LatLng(devPos['lat']!, devPos['lon']!);
        name = 'Vị trí của bạn';

        // Phản hồi ngay lập tức: Di chuyển bản đồ & tải quán xung quanh không cần chờ mạng
        final inGiaLam = isPointInGiaLam(targetPos);
        if (mounted) {
          setState(() {
            _userLocation = targetPos;
            _userLocationName = name;
            _detectingLocation = false;
            if (inGiaLam && moveToUser) {
              _currentCenter = targetPos;
              _pinnedLocation = targetPos;
              _searchCtrl.text = name!;
              _selectedRestaurant = null;
            }
          });

          if (inGiaLam) {
            if (moveToUser) {
              _mapController.move(targetPos, 15.0);
              _loadNearby(targetPos.latitude, targetPos.longitude);
            }
          } else {
            if (moveToUser) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Vị trí GPS của bạn nằm ngoài Gia Lâm. Tuyến đường vẫn sẽ được tính từ toạ độ thực tế của bạn.'),
                  backgroundColor: Color(0xFFE65100),
                  duration: Duration(seconds: 4),
                ),
              );
            }
          }
        }

        // Tra cứu địa chỉ chi tiết ngầm trong nền để không chặn giao diện
        widget.api.reverseMap(targetPos.latitude, targetPos.longitude).then((addr) {
          if (mounted && addr.isNotEmpty) {
            setState(() {
              _userLocationName = addr;
              if (_pinnedLocation == targetPos) {
                _searchCtrl.text = addr;
              }
            });
          }
        }).catchError((_) {});
      } else {
        if (mounted && moveToUser) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Chưa lấy được toạ độ GPS. Vui lòng cho phép quyền vị trí trên trình duyệt!'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (_) {
      // Giữ nguyên toạ độ hiện tại, không gán cứng
    } finally {
      if (mounted) {
        setState(() {
          _detectingLocation = false;
        });
      }
    }
  }

  @override
  void didUpdateWidget(covariant MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialLat != null &&
        widget.initialLon != null &&
        (widget.initialLat != oldWidget.initialLat ||
         widget.initialLon != oldWidget.initialLon ||
         widget.initialRestaurant != oldWidget.initialRestaurant)) {
      final newPos = LatLng(widget.initialLat!, widget.initialLon!);
      setState(() {
        _currentCenter = newPos;
        if (widget.initialRestaurant == null) {
          _pinnedLocation = newPos;
        } else {
          _selectedRestaurant = widget.initialRestaurant;
          // Nếu _pinnedLocation trước đó bị trùng với quán thì bỏ đi để tránh tự điều hướng về chính mình
          if (_pinnedLocation != null) {
            final d = const Distance().as(LengthUnit.Meter, _pinnedLocation!, newPos);
            if (d < 20) {
              _pinnedLocation = null;
            }
          }
        }
      });
      _clearRoute();
      _mapController.move(newPos, 16.0);
      _loadNearby(newPos.latitude, newPos.longitude);
      if (_userLocation == null) {
        _detectUserLocation(moveToUser: false);
      }
    }
  }

  Future<void> _loadAllRestaurants() async {
    try {
      final list = await widget.api.getRestaurants(limit: 500);
      if (mounted) {
        final giaLamOnly = list.where((r) => isPointInGiaLam(LatLng(r.latitude, r.longitude))).toList();
        setState(() {
          _allRestaurants = giaLamOnly;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadNearby(double lat, double lon) async {
    try {
      final list = await widget.api.getNearbyRestaurants(lat: lat, lon: lon, radiusKm: _radiusKm);
      if (mounted) {
        final giaLamOnly = list.where((r) => isPointInGiaLam(LatLng(r.latitude, r.longitude))).toList();
        setState(() {
          _nearbyRestaurants = giaLamOnly;
        });
      }
    } catch (_) {}
  }

  Future<void> _search() async {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
      _showSearchResults = true;
    });

    try {
      final res = await widget.api.searchMap(q);
      final inGiaLam = res.where((p) => isPointInGiaLam(LatLng(p.latitude, p.longitude))).toList();
      setState(() {
        _places = inGiaLam.isNotEmpty ? inGiaLam : res.take(5).toList();
      });
    } catch (e) {
      setState(() {
        _error = formatErrorMessage(e);
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _onMapTap(LatLng point) async {
    if (_routePoints.isNotEmpty) {
      _clearRoute();
      return;
    }
    if (!isPointInGiaLam(point)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vị trí nằm ngoài vùng phủ sóng Huyện Gia Lâm!'),
          backgroundColor: Color(0xFFE65100),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    setState(() {
      _pinnedLocation = point;
      _selectedRestaurant = null;
      _showSearchResults = false;
    });

    _loadNearby(point.latitude, point.longitude);

    try {
      final addr = await widget.api.reverseMap(point.latitude, point.longitude);
      if (mounted && addr.isNotEmpty) {
        setState(() {
          _searchCtrl.text = addr;
        });
      }
    } catch (_) {
    }
  }

  void _selectPlace(GeocodePlace p) {
    _clearRoute();
    final pos = LatLng(p.latitude, p.longitude);
    if (!isPointInGiaLam(pos)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Địa điểm này nằm ngoài vùng phủ sóng Huyện Gia Lâm!'),
          backgroundColor: Color(0xFFE65100),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    setState(() {
      _pinnedLocation = pos;
      _showSearchResults = false;
      _searchCtrl.text = p.displayName;
    });
    _mapController.move(pos, 15.0);
    _loadNearby(p.latitude, p.longitude);
  }


  void _showMenuBottomSheet(Restaurant r) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, scrollController) {
            return RestaurantMenuWidget(
              api: widget.api,
              restaurant: r,
              scrollController: scrollController,
              currentUser: widget.currentUser,
              onRequireLogin: widget.onRequireLogin,
              onNavigateToMap: (lat, lon, [res]) {
                setState(() {
                  _selectedRestaurant = res ?? r;
                  _showSearchResults = false;
                });
                _mapController.move(LatLng(lat, lon), 16.0);
              },
            );
          },
        );
      },
    );
  }

  void _showRadiusPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(tr('radius_filter'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('${_radiusKm.toStringAsFixed(0)} km', style: const TextStyle(fontWeight: FontWeight.bold, color: kPrimaryGreen, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 16),
              Slider(
                value: _radiusKm,
                min: 1.0,
                max: 20.0,
                divisions: 19,
                activeColor: Colors.deepOrange,
                label: '${_radiusKm.toStringAsFixed(0)} km',
                onChanged: (val) {
                  setSheetState(() => _radiusKm = val);
                  setState(() => _radiusKm = val);
                },
                onChangeEnd: (val) {
                  if (_pinnedLocation != null) {
                    _loadNearby(_pinnedLocation!.latitude, _pinnedLocation!.longitude);
                  }
                },
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    if (_pinnedLocation != null) {
                      _loadNearby(_pinnedLocation!.latitude, _pinnedLocation!.longitude);
                    }
                  },
                  child: Text(tr('btn_apply')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('map_title'), style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: 'Chọn bán kính quét',
            icon: const Icon(Icons.tune),
            onPressed: _showRadiusPicker,
          ),
          IconButton(
            tooltip: 'Vị trí của tôi (GPS thiết bị)',
            icon: _detectingLocation
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue))
                : const Icon(Icons.my_location, color: Colors.blue),
            onPressed: () {
              if (_userLocation != null) {
                _mapController.move(_userLocation!, 15.0);
              }
              _detectUserLocation(moveToUser: true);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. BẢN ĐỒ OPENSTREETMAP TƯƠNG TÁC GIA LÂM
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentCenter,
              initialZoom: 14.0,
              minZoom: 11.5,
              maxZoom: 20.0,
              cameraConstraint: CameraConstraint.containCenter(
                bounds: giaLamBounds,
              ),
              onPositionChanged: (pos, hasGesture) {
                final z = pos.zoom;
                final c = pos.center;
                if (!hasGesture) {
                  // Vừa thả ngón tay hoặc kết thúc gesture: cập nhật ngay tức thì
                  setState(() {
                    _currentZoom = z;
                    _currentCenter = c;
                  });
                } else {
                  // Trong lúc đang chạm vuốt: chỉ setState khi zoom lệch lớn (>= 0.6) để giữ 60fps mượt mà
                  if ((z - _currentZoom).abs() >= 0.6) {
                    setState(() {
                      _currentZoom = z;
                      _currentCenter = c;
                    });
                  }
                }
              },
              onTap: (tapPosition, point) => _onMapTap(point),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.ptc1.mobile',
                tileBounds: giaLamBounds,
                maxNativeZoom: 19,
                maxZoom: 20.0,
                tileProvider: _tileProvider,
                evictErrorTileStrategy: EvictErrorTileStrategy.notVisibleRespectMargin,
              ),
              // 1.1 LOP MAT NA CAT MIENG BANH GIA LAM - CHE PHU VINH VIEN 100% CAC VUNG NGOAI
              PolygonLayer(
                polygons: [
                  Polygon(
                    points: const [
                      LatLng(25.0, 102.0),
                      LatLng(25.0, 110.0),
                      LatLng(17.0, 110.0),
                      LatLng(17.0, 102.0),
                    ],
                    holePointsList: [giaLamBoundaryPolygon],
                    color: const Color(0xFFFAFAFA),
                    borderColor: Colors.transparent,
                    borderStrokeWidth: 0,
                  ),
                ],
              ),
              // 1.2 DUONG GAP KHUC RANH GIOI MIENG BANH GIA LAM
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [...giaLamBoundaryPolygon, giaLamBoundaryPolygon.first],
                    color: kPrimaryGreen,
                    strokeWidth: 3.5,
                  ),
                  if (_routePoints.isNotEmpty)
                    Polyline(
                      points: _routePoints,
                      color: const Color(0xFF2563EB),
                      strokeWidth: 5.0,
                      strokeCap: StrokeCap.round,
                      strokeJoin: StrokeJoin.round,
                    ),
                ],
              ),
              MarkerLayer(
                markers: [
                  if (_userLocation != null)
                    Marker(
                      point: _userLocation!,
                      width: 52,
                      height: 52,
                      child: Tooltip(
                        message: 'Vị trí của bạn: ${_userLocationName ?? "GPS thiết bị"}',
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.blue.withAlpha(64),
                                shape: BoxShape.circle,
                              ),
                            ),
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.blue[600],
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                                boxShadow: const [
                                  BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // 1.3 Badge thời gian đi bộ nổi trên tuyến đường (Chuẩn Google Maps)
                  if (_routePoints.length > 1)
                    Marker(
                      point: _routePoints[_routePoints.length ~/ 2],
                      width: 120,
                      height: 38,
                      alignment: Alignment.center,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1D4ED8),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 2)),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.directions_walk, color: Colors.white, size: 16),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                _formatWalkingTimeOnly(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Hiển thị danh sách quán ăn theo viewport và chống đè marker
                  ..._buildVisibleRestaurantMarkers(),
                ],
              ),
            ],
          ),

          // 2.1 KHUNG XUẤT PHÁT - ĐÍCH ĐẾN CHUẨN GOOGLE MAPS (KHI ĐANG CHỈ ĐƯỜNG)
          if (_routePoints.isNotEmpty)
            Positioned(
              top: 12,
              left: 16,
              right: 16,
              child: Card(
                elevation: 6,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: const [
                                BoxShadow(color: Colors.black26, blurRadius: 2),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Column(
                              children: List.generate(
                                3,
                                (_) => Container(
                                  width: 2,
                                  height: 2,
                                  margin: const EdgeInsets.symmetric(vertical: 1),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF94A3B8),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const Icon(Icons.location_on, color: Color(0xFFEA4335), size: 18),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _userLocationName ?? 'Vị trí của bạn',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF1E293B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 4),
                              child: Divider(height: 1, color: Color(0xFFE2E8F0)),
                            ),
                            Text(
                              _selectedRestaurant?.name ?? 'Điểm đến',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Tùy chọn tuyến đường đi bộ'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(Icons.more_vert, size: 20, color: Color(0xFF64748B)),
                            ),
                          ),
                          const SizedBox(height: 4),
                          InkWell(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Đã đảo ngược chiều đi'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(Icons.swap_vert, size: 20, color: Color(0xFF64748B)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 2. KHUNG TÌM KIẾM ĐỊA ĐIỂM & CHIPS
          if (_routePoints.isEmpty)
            Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(Icons.search, color: Colors.grey),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          decoration: InputDecoration(
                            hintText: tr('map_search_hint'),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onSubmitted: (_) => _search(),
                        ),
                      ),
                      if (_searchCtrl.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() {
                              _places = [];
                              _showSearchResults = false;
                            });
                          },
                        ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: kPrimaryGreen,
                          foregroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.horizontal(right: Radius.circular(12)),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        ),
                        onPressed: _loading ? null : _search,
                        child: _loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(tr('btn_search'), style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _foodCategories.map((cat) {
                      final name = cat['name'] as String;
                      final icon = cat['icon'] as IconData;
                      final isSelected = _selectedCategory == name;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          avatar: Icon(
                            icon,
                            size: 16,
                            color: isSelected ? Colors.white : kPrimaryGreen,
                          ),
                          label: Text(_getCategoryLabel(name)),
                          selected: isSelected,
                          selectedColor: kPrimaryGreen,
                          backgroundColor: Colors.white,
                          elevation: isSelected ? 3 : 1,
                          labelStyle: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected ? kPrimaryGreen : Colors.grey.shade300,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          showCheckmark: false,
                          onSelected: (val) {
                            setState(() {
                              _selectedCategory = val ? name : 'Tất cả';
                              if (_selectedRestaurant != null &&
                                  !_restaurantMatchesCategory(_selectedRestaurant!, _selectedCategory)) {
                                _selectedRestaurant = null;
                              }
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                if (_showSearchResults && _places.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    constraints: const BoxConstraints(maxHeight: 220),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
                      ],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _places.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final p = _places[index];
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.location_on, color: kPrimaryGreen),
                          title: Text(p.displayName, maxLines: 2, overflow: TextOverflow.ellipsis),
                          subtitle: Text('Toạ độ: ${p.latitude.toStringAsFixed(4)}, ${p.longitude.toStringAsFixed(4)}'),
                          onTap: () => _selectPlace(p),
                        );
                      },
                    ),
                  ),

                if (_error != null)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('Lỗi: ${_error!}', style: const TextStyle(color: Colors.red)),
                  ),
              ],
            ),
          ),

          // 3. NÚT ĐIỀU KHIỂN ZOOM (+) (-) & VỊ TRÍ CỦA TÔI
          Positioned(
            right: 16,
            bottom: (_selectedRestaurant != null) ? 140 : 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: 'map_my_location_btn',
                  backgroundColor: Colors.white,
                  foregroundColor: kPrimaryGreen,
                  tooltip: 'Vị trí của tôi',
                  onPressed: () {
                    if (_userLocation != null) {
                      _mapController.move(_userLocation!, 15.0);
                    }
                    _detectUserLocation(moveToUser: true);
                  },
                  child: _detectingLocation
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue))
                      : const Icon(Icons.my_location),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'map_zoom_in_btn',
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  onPressed: () {
                    _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom + 1,
                    );
                  },
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'map_zoom_out_btn',
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  onPressed: () {
                    _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom - 1,
                    );
                  },
                  child: const Icon(Icons.remove),
                ),
              ],
            ),
          ),

          // 4. SHEET ĐIỀU HƯỚNG CHỈ ĐƯỜNG HOẶC CHI TIẾT QUÁN ĂN (CHUẨN GOOGLE MAPS)
          if (_selectedRestaurant != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(45),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                child: SafeArea(
                  top: false,
                  child: _routePoints.isNotEmpty
                      ? _buildDirectionsOverviewSheet()
                      : _buildRestaurantDetailsSheet(),
                ),
              ),
            ),
        ],
      ),
    );
  }


  Widget _buildDirectionsOverviewSheet() {
    final walkTime = _formatWalkingTimeOnly();
    final walkDist = _formatWalkingDistanceOnly();


    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Thanh kéo drag handle
        Center(
          child: Container(
            width: 38,
            height: 4.5,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),

        // Hàng tiêu đề: "Đi bộ" và các nút tùy chọn, chia sẻ, đóng X
        Row(
          children: [
            const Text(
              'Đi bộ',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const Spacer(),
            InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tùy chọn tuyến đường đi bộ'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.tune, size: 20, color: Color(0xFF475569)),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Chia sẻ tuyến đường đến ${_selectedRestaurant!.name}'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.share_outlined, size: 20, color: Color(0xFF475569)),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: _clearRoute,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 20, color: Color(0xFF475569)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Tóm tắt thời gian & cự ly lớn
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          children: [
            Text(
              '$walkTime ($walkDist)',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            Text(
              'Hầu như bằng phẳng',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),

        // Chi tiết tuyến đường / địa chỉ
        Text(
          _selectedRestaurant!.address != null && _selectedRestaurant!.address!.isNotEmpty
              ? 'qua ${_selectedRestaurant!.address!}'
              : 'tuyến đường đi bộ ngắn nhất đến ${_selectedRestaurant!.name}',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        if (_isRouteFallback) ...[
          const SizedBox(height: 4),
          const Text(
            '⚠️ Tuyến đường ước tính thẳng (máy chủ dẫn đường đang ngoại tuyến)',
            style: TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.w600),
          ),
        ] else if ((_routeDistanceMeters ?? 0) > 15000) ...[
          const SizedBox(height: 4),
          const Text(
            '⚠️ Quán ở xa (>15km), hãy cân nhắc phương tiện khác',
            style: TextStyle(fontSize: 12, color: Colors.deepOrange, fontWeight: FontWeight.w600),
          ),
        ],
        const SizedBox(height: 16),

        // Dãy nút hành động: [Bắt đầu] (Teal) | [Thực đơn] | [Chi tiết quán]
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: const StadiumBorder(),
                ),
                icon: const Icon(Icons.navigation, size: 18),
                label: Text(
                  AppLanguage.instance.isVietnamese ? 'Bắt đầu' : 'Start',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Bắt đầu chỉ đường đi bộ đến ${_selectedRestaurant!.name}'),
                      backgroundColor: const Color(0xFF0F766E),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFE0F2FE),
                  foregroundColor: const Color(0xFF0369A1),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: const StadiumBorder(),
                ),
                icon: const Icon(Icons.restaurant_menu, size: 18),
                label: Text(
                  AppLanguage.instance.isVietnamese ? 'Thực đơn' : 'Menu',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                onPressed: () => _showMenuBottomSheet(_selectedRestaurant!),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFF1F5F9),
                  foregroundColor: const Color(0xFF475569),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: const StadiumBorder(),
                ),
                icon: const Icon(Icons.info_outline, size: 18),
                label: Text(
                  AppLanguage.instance.isVietnamese ? 'Chi tiết quán' : 'Details',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                onPressed: _clearRoute,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRestaurantDetailsSheet() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Thanh kéo drag handle
        Center(
          child: Container(
            width: 38,
            height: 4.5,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),

        // Tên quán & Nút lưu, Đóng X
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                _selectedRestaurant!.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF1E293B),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(tr('saved_restaurant_fav')),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.bookmark_border, size: 20, color: Color(0xFF475569)),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () {
                _clearRoute();
                setState(() {
                  _selectedRestaurant = null;
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 20, color: Color(0xFF475569)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Đánh giá sao & Thể loại quán
        Row(
          children: [
            if (_selectedRestaurant!.rating != null && _selectedRestaurant!.rating! > 0) ...[
              Text(
                _selectedRestaurant!.rating!.toStringAsFixed(1),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
              ),
              const SizedBox(width: 4),
              ...List.generate(5, (i) {
                final score = _selectedRestaurant!.rating!;
                if (score >= i + 1) {
                  return const Icon(Icons.star, size: 14, color: Colors.amber);
                } else if (score >= i + 0.5) {
                  return const Icon(Icons.star_half, size: 14, color: Colors.amber);
                } else {
                  return Icon(Icons.star_border, size: 14, color: Colors.grey.shade400);
                }
              }),
              const SizedBox(width: 4),
            ] else ...[
              const Icon(Icons.star_border, size: 14, color: Colors.grey),
              const SizedBox(width: 2),
              Text(
                'Chưa có đánh giá',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey.shade600),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              '•  ${getCuisineStyle(_selectedRestaurant!.name, _selectedRestaurant!.description).label}',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
          ],
        ),
        const SizedBox(height: 4),

        // Trạng thái mở cửa
        Builder(builder: (context) {
          final open = isOpenNow(_selectedRestaurant!.openTime, _selectedRestaurant!.closeTime);
          final closeStr = _selectedRestaurant!.closeTime != null
              ? 'Đóng cửa lúc ${_selectedRestaurant!.closeTime}'
              : 'Đóng cửa lúc 22:00';
          final openStr = _selectedRestaurant!.openTime != null
              ? 'Mở cửa lúc ${_selectedRestaurant!.openTime}'
              : 'Mở cửa lúc 07:00';

          return Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: open ? 'Đang mở cửa' : 'Đã đóng cửa',
                  style: TextStyle(
                    color: open ? const Color(0xFF15803D) : const Color(0xFFDC2626),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                TextSpan(
                  text: '  •  ${open ? closeStr : openStr}',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 14),

        // Dãy nút hành động chuẩn Google Maps: [Đường đi] (Teal) | [Thực đơn] (Light Blue) | [Gọi]
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // 1. NÚT ĐƯỜNG ĐI (Pill màu Teal đậm)
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                  shape: const StadiumBorder(),
                ),
                icon: _isLoadingRoute
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.directions, size: 18),
                label: Text(
                  _isLoadingRoute ? 'Đang tìm...' : 'Đường đi',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                onPressed: _isLoadingRoute ? null : () => _fetchWalkingRoute(_selectedRestaurant!),
              ),
              const SizedBox(width: 8),

              // 2. NÚT THỰC ĐƠN (Pill màu xanh nhạt)
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFE0F2FE),
                  foregroundColor: const Color(0xFF0369A1),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  shape: const StadiumBorder(),
                ),
                icon: const Icon(Icons.restaurant_menu, size: 18),
                label: const Text(
                  'Thực đơn',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                onPressed: () => _showMenuBottomSheet(_selectedRestaurant!),
              ),
              const SizedBox(width: 8),

              // 3. NÚT GỌI ĐIỆN (nếu có số điện thoại)
              if (_selectedRestaurant!.phone != null && _selectedRestaurant!.phone!.isNotEmpty) ...[
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFE0F2FE),
                    foregroundColor: const Color(0xFF0369A1),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                    shape: const StadiumBorder(),
                  ),
                  icon: const Icon(Icons.call, size: 18),
                  label: Text(
                    'Gọi ${_selectedRestaurant!.phone!}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Số điện thoại: ${_selectedRestaurant!.phone!}'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),

        // Hộp thông tin điểm nhấn / mô tả quán (nếu có)
        if (_selectedRestaurant!.description != null && _selectedRestaurant!.description!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200, width: 1),
            ),
            child: Row(
              children: [
                const Text('💡 ', style: TextStyle(fontSize: 14)),
                Expanded(
                  child: Text(
                    _selectedRestaurant!.description!,
                    style: TextStyle(color: Colors.grey.shade800, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

typedef GeocodingScreen = MapScreen;
typedef NearbyScreen = MapScreen;

// ==========================================
// TAB 3: MÓN ĂN YÊU THÍCH (FAVOURITES - USER)
// ==========================================
