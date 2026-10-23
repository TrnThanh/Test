import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'models/models.dart';
import 'services/api_service.dart';
import 'services/location_service.dart';

void main() {
  runApp(const Ptc1App());
}

/// Tiện ích kiểm tra quán có đang trong khung giờ mở cửa thực tế không
bool isOpenNow(String? openTime, String? closeTime) {
  if (openTime == null || closeTime == null || openTime.isEmpty || closeTime.isEmpty) {
    return true; // Mặc định mở nếu quán chưa thiết lập giờ
  }
  try {
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;
    final openParts = openTime.split(':');
    final closeParts = closeTime.split(':');
    final openMin = int.parse(openParts[0]) * 60 + int.parse(openParts[1]);
    final closeMin = int.parse(closeParts[0]) * 60 + int.parse(closeParts[1]);

    if (closeMin >= openMin) {
      return currentMinutes >= openMin && currentMinutes <= closeMin;
    } else {
      // Khung giờ qua đêm (ví dụ: 18:00 - 04:30)
      return currentMinutes >= openMin || currentMinutes <= closeMin;
    }
  } catch (_) {
    return true;
  }
}


/// Chuẩn hoá thông báo lỗi thân thiện với người dùng
String formatErrorMessage(Object error) {
  final str = error.toString().replaceAll('Exception: ', '');
  final lower = str.toLowerCase();
  if (lower.contains('failed to fetch') ||
      lower.contains('connection refused') ||
      lower.contains('socketexception') ||
      lower.contains('clientexception')) {
    return 'Chưa kết nối được tới máy chủ Backend (Cổng 8001/8000).\nVui lòng kiểm tra và chạy file "CHAY_SERVER.bat" để khởi động Backend!';
  }
  return str;
}

class Ptc1App extends StatelessWidget {
  final ApiService? apiService;
  final bool showInitialCategoryPrompt;

  const Ptc1App({
    super.key,
    this.apiService,
    this.showInitialCategoryPrompt = true,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PTC1 Spatial Food',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: const ColorScheme.light(
          primary: Colors.black,
          onPrimary: Colors.white,
          surface: Colors.white,
          onSurface: Colors.black,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFAFAFA),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
      ),
      home: MainShell(
        apiService: apiService ?? ApiService(),
        showInitialCategoryPrompt: showInitialCategoryPrompt,
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  final ApiService apiService;
  final bool showInitialCategoryPrompt;

  const MainShell({
    super.key,
    required this.apiService,
    this.showInitialCategoryPrompt = true,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  RoleLoginResponse? _currentUser;
  String? _selectedCategory;

  // Hỗ trợ chuyển toạ độ từ Tab Bản đồ sang Tab Gần đây
  double? _targetLat;
  double? _targetLon;

  @override
  void initState() {
    super.initState();
    if (widget.showInitialCategoryPrompt) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showInitialCategoryPicker();
      });
    }
  }

  void _showInitialCategoryPicker() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => WelcomeCategoryDialog(
        selectedCategory: _selectedCategory,
        onCategorySelected: (cat) {
          setState(() {
            _selectedCategory = cat;
          });
        },
      ),
    );
  }

  void _onLoginSuccess(RoleLoginResponse user) {
    setState(() {
      _currentUser = user;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Chào mừng ${user.fullName ?? user.email}!'),
        backgroundColor: Colors.black,
      ),
    );
    _checkAndShowOnboarding(user);
  }

  Future<void> _checkAndShowOnboarding(RoleLoginResponse user) async {
    try {
      final profile = await widget.apiService.getUserProfile(user.id);
      if (!profile.isOnboarded && mounted) {
        await Future.delayed(const Duration(milliseconds: 300));
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => OnboardingSurveyDialog(
            api: widget.apiService,
            userId: user.id,
            initialProfile: profile,
            onCompleted: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã hoàn thành khảo sát sở thích ẩm thực & sức khỏe!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
          ),
        );
      }
    } catch (_) {}
  }

  void _onLogout() {
    setState(() {
      _currentUser = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã đăng xuất tài khoản.')),
    );
  }



  @override
  Widget build(BuildContext context) {
    final tabs = [
      ExploreScreen(
        api: widget.apiService,
        currentUser: _currentUser,
        initialCategory: _selectedCategory,
        onOpenCategoryPicker: _showInitialCategoryPicker,
        onRequireLogin: () {
          setState(() => _currentIndex = 3);
        },
      ),
      MapScreen(
        api: widget.apiService,
        initialLat: _targetLat,
        initialLon: _targetLon,
        currentUser: _currentUser,
        onRequireLogin: () {
          setState(() => _currentIndex = 3);
        },
      ),
      FavouritesScreen(
        api: widget.apiService,
        currentUser: _currentUser,
        onRequireLogin: () {
          setState(() => _currentIndex = 3);
        },
        onExplore: () {
          setState(() => _currentIndex = 0);
        },
      ),
      AccountScreen(
        api: widget.apiService,
        currentUser: _currentUser,
        onLoginSuccess: _onLoginSuccess,
        onLogout: _onLogout,
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: tabs,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Bản đồ',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_outline),
            selectedIcon: Icon(Icons.favorite),
            label: 'Yêu thích',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Tài khoản',
          ),
        ],
      ),
    );
  }
}

// ==========================================
// TAB 1: KHÁM PHÁ (EXPLORE - GUEST & USER)
// ==========================================
class ExploreScreen extends StatefulWidget {
  final ApiService api;
  final RoleLoginResponse? currentUser;
  final VoidCallback onRequireLogin;
  final String? initialCategory;
  final VoidCallback? onOpenCategoryPicker;

  const ExploreScreen({
    super.key,
    required this.api,
    this.currentUser,
    required this.onRequireLogin,
    this.initialCategory,
    this.onOpenCategoryPicker,
  });

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  List<Restaurant> _restaurants = [];
  bool _loading = false;
  String? _error;
  String _searchQuery = '';
  String? _currentCategory;

  final List<String> _categories = const [
    'Tất cả',
    'Phở & Bún',
    'Cơm văn phòng',
    'Lẩu & Nướng',
    'Đồ chay',
    'Ăn vặt',
    'Món Hàn & Nhật',
    'Fastfood',
    'Hải sản',
  ];

  @override
  void initState() {
    super.initState();
    _currentCategory = widget.initialCategory;
    _loadData();
  }

  @override
  void didUpdateWidget(covariant ExploreScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCategory != oldWidget.initialCategory) {
      setState(() {
        _currentCategory = widget.initialCategory;
      });
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await widget.api.getRestaurants();
      setState(() {
        _restaurants = list;
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

  List<Restaurant> get _filteredList {
    var list = _restaurants;
    if (_currentCategory != null && _currentCategory != 'Tất cả') {
      final cat = _currentCategory!.toLowerCase();
      final matched = list.where((r) =>
          r.name.toLowerCase().contains(cat) ||
          (r.description != null && r.description!.toLowerCase().contains(cat))).toList();
      if (matched.isNotEmpty) {
        list = matched;
      }
    }
    if (_searchQuery.trim().isEmpty) return list;
    final q = _searchQuery.toLowerCase().trim();
    return list.where((r) =>
        r.name.toLowerCase().contains(q) ||
        (r.address != null && r.address!.toLowerCase().contains(q))).toList();
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
            return _RestaurantMenuWidget(
              api: widget.api,
              restaurant: r,
              scrollController: scrollController,
              currentUser: widget.currentUser,
              onRequireLogin: widget.onRequireLogin,
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PTC1 Khám Phá Quán Ăn', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại',
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm theo tên quán, địa chỉ...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
            ),
          ),
          // Thanh chọn thể loại món ăn
          Container(
            height: 42,
            margin: const EdgeInsets.only(bottom: 6),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (ctx, idx) {
                final cat = _categories[idx];
                final isSelected = (_currentCategory ?? 'Tất cả') == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cat),
                    selected: isSelected,
                    selectedColor: Colors.black,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    backgroundColor: Colors.white,
                    side: BorderSide(color: isSelected ? Colors.black : Colors.grey[300]!),
                    onSelected: (val) {
                      setState(() {
                        _currentCategory = cat == 'Tất cả' ? null : cat;
                      });
                    },
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Lỗi kết nối: $_error',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: Colors.red)),
                                const SizedBox(height: 12),
                                ElevatedButton(onPressed: _loadData, child: const Text('Thử lại')),
                              ],
                            ),
                          ),
                        )
                      : _filteredList.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.restaurant, size: 54, color: Colors.grey[400]),
                                  const SizedBox(height: 12),
                                  Text('Không tìm thấy quán ăn nào phù hợp',
                                      style: TextStyle(color: Colors.grey[600])),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              itemCount: _filteredList.length,
                              itemBuilder: (context, index) {
                                final r = _filteredList[index];
                                final open = isOpenNow(r.openTime, r.closeTime);

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  color: Colors.white,
                                  elevation: 0.5,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    side: BorderSide(color: Colors.grey[200]!),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(14.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                r.name,
                                                style: const TextStyle(
                                                    fontSize: 17, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: open ? Colors.green.shade50 : Colors.red.shade50,
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(
                                                    color: open ? Colors.green : Colors.red,
                                                    width: 0.8),
                                              ),
                                              child: Text(
                                                open ? '🟢 Đang mở cửa' : '🔴 Đã đóng cửa',
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: open ? Colors.green.shade800 : Colors.red.shade800),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        if (r.address != null)
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Icon(Icons.location_on, size: 16, color: Colors.deepOrange),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  r.address!,
                                                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                                                ),
                                              ),
                                            ],
                                          ),
                                        if (r.openTime != null && r.closeTime != null) ...[
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(Icons.access_time, size: 16, color: Colors.blueGrey),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Khung giờ: ${r.openTime} – ${r.closeTime}',
                                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                              ),
                                            ],
                                          ),
                                        ],
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            if (r.phone != null) ...[
                                              Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                                              const SizedBox(width: 4),
                                              Text(r.phone!, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                            ],
                                            const Spacer(),
                                            FilledButton.tonalIcon(
                                              icon: const Icon(Icons.menu_book, size: 18),
                                              label: const Text('Xem Thực Đơn'),
                                              onPressed: () => _showMenuBottomSheet(r),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// ==========================================
// TAB 2: BẢN ĐỒ & QUÁN ĂN GIA LÂM (MAP & SPATIAL SEARCH)
// ==========================================
typedef HomeScreen = ExploreScreen;

class MapScreen extends StatefulWidget {
  final ApiService api;
  final double? initialLat;
  final double? initialLon;
  final RoleLoginResponse? currentUser;
  final VoidCallback onRequireLogin;

  const MapScreen({
    super.key,
    required this.api,
    this.initialLat,
    this.initialLon,
    this.currentUser,
    required this.onRequireLogin,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late final MapController _mapController;
  final _searchCtrl = TextEditingController();

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

  LatLng _currentCenter = const LatLng(21.0285, 105.8542); // Khởi tạo trung tâm Hà Nội
  LatLng? _pinnedLocation;
  String? _pinnedAddress;
  double _radiusKm = 5.0;

  LatLng? _userLocation;
  String? _userLocationName;
  bool _detectingLocation = false;

  List<GeocodePlace> _places = [];
  List<Restaurant> _nearbyRestaurants = [];
  Restaurant? _selectedRestaurant;

  bool _loading = false;
  String? _error;
  bool _showSearchResults = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    if (widget.initialLat != null && widget.initialLon != null) {
      _currentCenter = LatLng(widget.initialLat!, widget.initialLon!);
      _pinnedLocation = _currentCenter;
      _loadNearby(_currentCenter.latitude, _currentCenter.longitude);
    } else {
      _pinnedLocation = _currentCenter;
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
      LatLng? pos;
      String? name;

      // 1. Thử xin quyền & lấy toạ độ GPS chính xác từ thiết bị / trình duyệt
      final devPos = await LocationService.getDeviceLocation();
      if (devPos != null) {
        pos = LatLng(devPos['lat']!, devPos['lon']!);
        name = 'Vị trí của bạn (GPS thiết bị)';
        try {
          final addr = await widget.api.reverseMap(pos.latitude, pos.longitude);
          if (addr.isNotEmpty) name = addr;
        } catch (_) {}
      } else {
        // 2. Fallback sang IP Geolocation từ Backend
        final loc = await widget.api.getIpLocation();
        pos = LatLng(loc.lat, loc.lon);
        name = loc.locationName;
      }

      if (mounted) {
        final targetPos = pos;
        setState(() {
          _userLocation = targetPos;
          _userLocationName = name;
          _currentCenter = targetPos;
          _pinnedLocation = targetPos;
          _pinnedAddress = name;
          _searchCtrl.text = name ?? '';
          _selectedRestaurant = null;
        });

        if (moveToUser) {
          _mapController.move(targetPos, 15.0);
        }
        _loadNearby(targetPos.latitude, targetPos.longitude);
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
        (widget.initialLat != oldWidget.initialLat || widget.initialLon != oldWidget.initialLon)) {
      final newPos = LatLng(widget.initialLat!, widget.initialLon!);
      setState(() {
        _currentCenter = newPos;
        _pinnedLocation = newPos;
      });
      _mapController.move(newPos, 14.5);
      _loadNearby(newPos.latitude, newPos.longitude);
    }
  }

  Future<void> _loadNearby(double lat, double lon) async {
    try {
      final list = await widget.api.getNearbyRestaurants(lat: lat, lon: lon, radiusKm: _radiusKm);
      if (mounted) {
        setState(() {
          _nearbyRestaurants = list;
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
      setState(() {
        _places = res.take(5).toList();
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
    setState(() {
      _pinnedLocation = point;
      _selectedRestaurant = null;
      _showSearchResults = false;
      _pinnedAddress = 'Đang tra cứu toạ độ...';
    });

    _loadNearby(point.latitude, point.longitude);

    try {
      final addr = await widget.api.reverseMap(point.latitude, point.longitude);
      if (mounted) {
        setState(() {
          _pinnedAddress = addr;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _pinnedAddress = 'Toạ độ: ${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}';
        });
      }
    }
  }

  void _selectPlace(GeocodePlace p) {
    final pos = LatLng(p.latitude, p.longitude);
    setState(() {
      _pinnedLocation = pos;
      _pinnedAddress = p.displayName;
      _showSearchResults = false;
      _searchCtrl.text = p.displayName;
    });
    _mapController.move(pos, 15.0);
    _loadNearby(p.latitude, p.longitude);
  }

  void _jumpTo(double lat, double lon, String name) {
    final pos = LatLng(lat, lon);
    setState(() {
      _pinnedLocation = pos;
      _pinnedAddress = name;
      _showSearchResults = false;
      _searchCtrl.text = name;
      _selectedRestaurant = null;
    });
    _mapController.move(pos, 14.5);
    _loadNearby(lat, lon);
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
            return _RestaurantMenuWidget(
              api: widget.api,
              restaurant: r,
              scrollController: scrollController,
              currentUser: widget.currentUser,
              onRequireLogin: widget.onRequireLogin,
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
                  const Text('Chọn Bán Kính Tìm Quán', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('${_radiusKm.toStringAsFixed(0)} km', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange, fontSize: 16)),
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
                  child: const Text('Áp dụng'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNearbyListBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, scrollCtrl) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Quán Ăn Lân Cận (${_nearbyRestaurants.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.tune, size: 14, color: Colors.deepOrange),
                    label: Text('${_radiusKm.toStringAsFixed(0)} km'),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showRadiusPicker();
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _nearbyRestaurants.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.storefront_outlined, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            Text(
                              'Không tìm thấy quán ăn nào trong bán kính ${_radiusKm.toStringAsFixed(0)} km quanh vị trí này.',
                              style: TextStyle(color: Colors.grey[600]),
                              textAlign: TextAlign.center,
                            ),
                            if (!isPointInGiaLam(_pinnedLocation ?? _currentCenter)) ...[
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.explore, size: 16),
                                label: const Text('Xem các quán đối tác tại Gia Lâm'),
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _mapController.fitCamera(CameraFit.bounds(bounds: giaLamBounds, padding: const EdgeInsets.all(24)));
                                  _jumpTo(21.0046, 105.9387, 'Khu vực ẩm thực Gia Lâm');
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.all(16),
                      itemCount: _nearbyRestaurants.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (ctx, index) {
                        final r = _nearbyRestaurants[index];
                        final open = isOpenNow(r.openTime, r.closeTime);
                        return Card(
                          color: Colors.white,
                          elevation: 1.5,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.deepOrange.shade50,
                              child: const Icon(Icons.restaurant, color: Colors.deepOrange, size: 20),
                            ),
                            title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (r.address != null)
                                  Text(r.address!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    if (r.distanceKm != null)
                                      Text('${r.distanceKm!.toStringAsFixed(1)} km  •  ', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange, fontSize: 11)),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: open ? Colors.green.shade50 : Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(open ? 'Đang mở' : 'Đã đóng', style: TextStyle(color: open ? Colors.green.shade800 : Colors.red.shade800, fontSize: 10, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () {
                                Navigator.pop(ctx);
                                _showMenuBottomSheet(r);
                              },
                              child: const Text('Thực đơn'),
                            ),
                            onTap: () {
                              Navigator.pop(ctx);
                              setState(() {
                                _selectedRestaurant = r;
                              });
                              _mapController.move(LatLng(r.latitude, r.longitude), 15.5);
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bản Đồ & Quán Ăn Gia Lâm', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: 'Chọn bán kính quét',
            icon: const Icon(Icons.tune),
            onPressed: _showRadiusPicker,
          ),
          IconButton(
            tooltip: 'Vị trí của tôi (Định vị mạng IP)',
            icon: _detectingLocation
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue))
                : const Icon(Icons.my_location, color: Colors.blue),
            onPressed: () {
              if (_userLocation != null) {
                _mapController.move(_userLocation!, 15.0);
                setState(() {
                  _pinnedLocation = _userLocation;
                  _pinnedAddress = _userLocationName ?? 'Vị trí của bạn';
                  _searchCtrl.text = _pinnedAddress!;
                });
                _loadNearby(_userLocation!.latitude, _userLocation!.longitude);
              } else {
                _detectUserLocation(moveToUser: true);
              }
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
              minZoom: 5.0,
              maxZoom: 18.0,
              onTap: (tapPosition, point) => _onMapTap(point),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.ptc1.mobile',
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [...giaLamBoundaryPolygon, giaLamBoundaryPolygon.first],
                    color: Colors.deepOrange.withAlpha(180),
                    strokeWidth: 3.0,
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
                        message: 'Vị trí của bạn: ${_userLocationName ?? "Định vị mạng IP"}',
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
                  if (_pinnedLocation != null && _pinnedLocation != _userLocation)
                    Marker(
                      point: _pinnedLocation!,
                      width: 44,
                      height: 44,
                      child: const Icon(Icons.location_pin, color: Colors.red, size: 44),
                    ),
                  ..._nearbyRestaurants.map((r) {
                    final isSelected = _selectedRestaurant?.id == r.id;
                    return Marker(
                      point: LatLng(r.latitude, r.longitude),
                      width: isSelected ? 48 : 38,
                      height: isSelected ? 48 : 38,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedRestaurant = r;
                            _showSearchResults = false;
                          });
                          _mapController.move(LatLng(r.latitude, r.longitude), 15.0);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.amber[700] : Colors.deepOrange,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
                            ],
                          ),
                          child: Icon(
                            Icons.restaurant,
                            color: Colors.white,
                            size: isSelected ? 26 : 20,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),

          // 2. KHUNG TÌM KIẾM ĐỊA ĐIỂM & CHIPS
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
                          decoration: const InputDecoration(
                            hintText: 'Tìm kiếm địa điểm tại Gia Lâm (VD: Trâu Quỳ, Ocean Park)...',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 14),
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
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.horizontal(right: Radius.circular(12)),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        onPressed: _loading ? null : _search,
                        child: _loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Tìm'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ActionChip(
                        avatar: _detectingLocation
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue))
                            : const Icon(Icons.my_location, size: 16, color: Colors.blue),
                        label: Text(
                          _userLocation != null ? 'Vị trí của tôi' : 'Định vị của tôi',
                          style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                        ),
                        backgroundColor: Colors.blue.shade50,
                        elevation: 2,
                        side: BorderSide(color: Colors.blue.shade200),
                        onPressed: () {
                          if (_userLocation != null) {
                            _mapController.move(_userLocation!, 15.0);
                            setState(() {
                              _pinnedLocation = _userLocation;
                              _pinnedAddress = _userLocationName ?? 'Vị trí của bạn';
                              _searchCtrl.text = _pinnedAddress!;
                            });
                            _loadNearby(_userLocation!.latitude, _userLocation!.longitude);
                          } else {
                            _detectUserLocation(moveToUser: true);
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      ActionChip(
                        avatar: const Icon(Icons.school, size: 16, color: Colors.deepOrange),
                        label: const Text('HVNN (Trâu Quỳ)'),
                        backgroundColor: Colors.white,
                        elevation: 2,
                        onPressed: () => _jumpTo(21.0046, 105.9387, 'Học viện Nông nghiệp Việt Nam (HVNN)'),
                      ),
                      const SizedBox(width: 8),
                      ActionChip(
                        avatar: const Icon(Icons.location_city, size: 16, color: Colors.deepOrange),
                        label: const Text('Ocean Park 1'),
                        backgroundColor: Colors.white,
                        elevation: 2,
                        onPressed: () => _jumpTo(20.9950, 105.9550, 'Vinhomes Ocean Park 1, Gia Lâm'),
                      ),
                      const SizedBox(width: 8),
                      ActionChip(
                        avatar: const Icon(Icons.palette, size: 16, color: Colors.deepOrange),
                        label: const Text('Làng gốm Bát Tràng'),
                        backgroundColor: Colors.white,
                        elevation: 2,
                        onPressed: () => _jumpTo(20.9760, 105.9080, 'Làng gốm Bát Tràng, Gia Lâm'),
                      ),
                      const SizedBox(width: 8),
                      ActionChip(
                        avatar: const Icon(Icons.store, size: 16, color: Colors.deepOrange),
                        label: const Text('Chợ Ninh Hiệp'),
                        backgroundColor: Colors.white,
                        elevation: 2,
                        onPressed: () => _jumpTo(21.1120, 105.9360, 'Chợ Ninh Hiệp, Gia Lâm'),
                      ),
                      const SizedBox(width: 8),
                      ActionChip(
                        avatar: const Icon(Icons.train, size: 16, color: Colors.deepOrange),
                        label: const Text('TT. Yên Viên'),
                        backgroundColor: Colors.white,
                        elevation: 2,
                        onPressed: () => _jumpTo(21.0830, 105.9020, 'Thị trấn Yên Viên, Gia Lâm'),
                      ),
                    ],
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
                          leading: const Icon(Icons.location_on, color: Colors.deepOrange),
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
            bottom: (_selectedRestaurant != null || _pinnedAddress != null || _pinnedLocation != null) ? 140 : 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: 'map_my_location_btn',
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue[700],
                  tooltip: 'Vị trí của tôi',
                  onPressed: () {
                    if (_userLocation != null) {
                      _mapController.move(_userLocation!, 15.0);
                      setState(() {
                        _pinnedLocation = _userLocation;
                        _pinnedAddress = _userLocationName ?? 'Vị trí của bạn';
                        _searchCtrl.text = _pinnedAddress!;
                      });
                      _loadNearby(_userLocation!.latitude, _userLocation!.longitude);
                    } else {
                      _detectUserLocation(moveToUser: true);
                    }
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

          // 4. CARD CHI TIẾT QUÁN ĐÃ CHỌN HOẶC VỊ TRÍ GHIM
          if (_selectedRestaurant != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.deepOrange.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.restaurant, color: Colors.deepOrange, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedRestaurant!.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (_selectedRestaurant!.address != null)
                                  Text(
                                    _selectedRestaurant!.address!,
                                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.grey),
                            onPressed: () {
                              setState(() {
                                _selectedRestaurant = null;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (_selectedRestaurant!.distanceKm != null)
                            Row(
                              children: [
                                const Icon(Icons.near_me, size: 16, color: Colors.deepOrange),
                                const SizedBox(width: 4),
                                Text(
                                  '${_selectedRestaurant!.distanceKm!.toStringAsFixed(1)} km',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange),
                                ),
                              ],
                            )
                          else
                            const SizedBox.shrink(),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.restaurant_menu, size: 16),
                            label: const Text('Xem thực đơn'),
                            onPressed: () => _showMenuBottomSheet(_selectedRestaurant!),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (_pinnedAddress != null || _pinnedLocation != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.place, color: Colors.red, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _pinnedAddress ?? 'Vị trí đã ghim tại Gia Lâm',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Tìm thấy ${_nearbyRestaurants.length} quán trong ${_radiusKm.toStringAsFixed(0)} km',
                              style: const TextStyle(color: Colors.deepOrange, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.tonal(
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _showNearbyListBottomSheet,
                        child: const Text('Xem quán'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

typedef GeocodingScreen = MapScreen;
typedef NearbyScreen = MapScreen;

// ==========================================
// TAB 3: MÓN ĂN YÊU THÍCH (FAVOURITES - USER)
// ==========================================
class FavouritesScreen extends StatefulWidget {
  final ApiService api;
  final RoleLoginResponse? currentUser;
  final VoidCallback onRequireLogin;
  final VoidCallback onExplore;

  const FavouritesScreen({
    super.key,
    required this.api,
    this.currentUser,
    required this.onRequireLogin,
    required this.onExplore,
  });

  @override
  State<FavouritesScreen> createState() => _FavouritesScreenState();
}

class _FavouritesScreenState extends State<FavouritesScreen> {
  List<FavouriteDish> _favourites = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFavourites();
  }

  @override
  void didUpdateWidget(covariant FavouritesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentUser?.id != oldWidget.currentUser?.id) {
      _loadFavourites();
    }
  }

  Future<void> _loadFavourites() async {
    if (widget.currentUser == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await widget.api.getUserFavourites(widget.currentUser!.id);
      if (mounted) {
        setState(() {
          _favourites = list;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = formatErrorMessage(e);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _removeFavourite(int favId) async {
    if (widget.currentUser == null) return;
    try {
      await widget.api.removeFavourite(widget.currentUser!.id, favId);
      _loadFavourites();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã bỏ món ăn khỏi danh sách yêu thích.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${formatErrorMessage(e)}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Món Ăn Yêu Thích', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.favorite_border, size: 64, color: Colors.red),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Lưu Giữ Món Ăn Bạn Yêu Thích',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Đăng nhập tài khoản Thực khách để thả tim lưu trữ các món ngon và nhận gợi ý ẩm thực chuẩn khẩu vị nhất!',
                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.login),
                  label: const Text('Đăng nhập ngay'),
                  onPressed: widget.onRequireLogin,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _favourites.isNotEmpty ? 'Món Ăn Yêu Thích (${_favourites.length})' : 'Món Ăn Yêu Thích',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại',
            onPressed: _loadFavourites,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadFavourites,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: Colors.red),
                          const SizedBox(height: 12),
                          Text(_error!, textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          OutlinedButton(onPressed: _loadFavourites, child: const Text('Thử lại')),
                        ],
                      ),
                    ),
                  )
                : _favourites.isEmpty
                    ? ListView(
                        children: [
                          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.restaurant_menu_outlined, size: 64, color: Colors.grey[400]),
                                  ),
                                  const SizedBox(height: 20),
                                  const Text(
                                    'Chưa có món ăn yêu thích nào',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Khám phá thực đơn các quán ăn hấp dẫn tại Gia Lâm và nhấn biểu tượng trái tim để lưu lại bạn nhé!',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 24),
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.black,
                                      side: const BorderSide(color: Colors.black),
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    icon: const Icon(Icons.explore),
                                    label: const Text('Khám phá món ngon ngay'),
                                    onPressed: widget.onExplore,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _favourites.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (ctx, index) {
                          final fav = _favourites[index];
                          final dish = fav.dish;
                          return Card(
                            color: Colors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: Colors.deepOrange.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.fastfood, color: Colors.deepOrange, size: 28),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          dish?.name ?? 'Món ăn #${fav.dishId}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                        const SizedBox(height: 4),
                                        if (dish != null) ...[
                                          Text(
                                            '${dish.price.toStringAsFixed(0)} ₫',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.deepOrange,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Wrap(
                                            spacing: 6,
                                            children: [
                                              if (dish.categoryName != null)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey.shade100,
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    dish.categoryName!,
                                                    style: TextStyle(fontSize: 10, color: Colors.grey[700]),
                                                  ),
                                                ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.amber.shade50,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  dish.mealType,
                                                  style: TextStyle(fontSize: 10, color: Colors.amber.shade900, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.favorite, color: Colors.red, size: 26),
                                    tooltip: 'Bỏ thích',
                                    onPressed: () => _removeFavourite(fav.id),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}

// ==========================================
// TAB 4: TÀI KHOẢN (USER AUTH & HỒ SƠ THỰC KHÁCH)
// ==========================================
class AccountScreen extends StatefulWidget {
  final ApiService api;
  final RoleLoginResponse? currentUser;
  final Function(RoleLoginResponse) onLoginSuccess;
  final VoidCallback onLogout;

  const AccountScreen({
    super.key,
    required this.api,
    required this.currentUser,
    required this.onLoginSuccess,
    required this.onLogout,
  });

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool _isRegister = false;

  final _emailCtrl = TextEditingController(text: 'user@example.com');
  final _passwordCtrl = TextEditingController(text: '123456');
  final _nameCtrl = TextEditingController(text: 'Nguyễn Văn Thực Khách');

  bool _loading = false;
  String? _error;

  UserProfile? _profile;
  bool _loadingProfile = false;

  @override
  void initState() {
    super.initState();
    _loadRoleData();
  }

  @override
  void didUpdateWidget(covariant AccountScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentUser?.id != oldWidget.currentUser?.id) {
      _loadRoleData();
    }
  }

  void _loadRoleData() {
    if (widget.currentUser == null) return;
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (widget.currentUser == null) return;
    setState(() => _loadingProfile = true);
    try {
      final p = await widget.api.getUserProfile(widget.currentUser!.id);
      setState(() => _profile = p);
    } catch (_) {}
    setState(() => _loadingProfile = false);
  }



  Future<void> _handleAuth() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      RoleLoginResponse res;
      if (!_isRegister) {
        res = await widget.api.loginUser(_emailCtrl.text.trim(), _passwordCtrl.text);
      } else {
        res = await widget.api.registerUser(
          _emailCtrl.text.trim(),
          _passwordCtrl.text,
          _nameCtrl.text.trim(),
        );
      }

      widget.onLoginSuccess(res);
      _loadRoleData();
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

  @override
  Widget build(BuildContext context) {
    if (widget.currentUser != null) {
      final user = widget.currentUser!;

      return Scaffold(
        appBar: AppBar(
          title: const Text('Tài Khoản Thực Khách'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Đăng xuất',
              onPressed: widget.onLogout,
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey[200]!),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.black,
                      child: Text(
                        (user.fullName?.isNotEmpty == true ? user.fullName![0] : user.email[0]).toUpperCase(),
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.fullName ?? 'Thực khách',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text(user.email, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEEEEE),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.black),
                            ),
                            child: const Text(
                              'Thực Khách (User)',
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Banner nhắc nhở khảo sát nếu chưa hoàn thành
            if (_profile != null && !_profile!.isOnboarded)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF97316)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFFF97316)),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Chưa thiết lập sở thích ẩm thực',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF9A3412))),
                          SizedBox(height: 2),
                          Text('Khảo sát ngay để nhận gợi ý món ăn chuẩn vóc dáng & khẩu vị!',
                              style: TextStyle(fontSize: 12, color: Color(0xFF7C2D12))),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF97316),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (ctx) => OnboardingSurveyDialog(
                            api: widget.api,
                            userId: widget.currentUser!.id,
                            initialProfile: _profile,
                            onCompleted: _loadProfile,
                          ),
                        );
                      },
                      child: const Text('Khảo sát', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),

            // Card Chi Tiết Hồ Sơ Sức Khỏe & Sở Thích
            Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey[200]!),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.health_and_safety_outlined, color: Colors.green),
                            SizedBox(width: 8),
                            Text('Hồ Sơ Sức Khỏe & Sở Thích',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_note, color: Colors.blue),
                          tooltip: 'Chỉnh sửa sở thích & thể chất',
                          onPressed: () {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (ctx) => OnboardingSurveyDialog(
                                api: widget.api,
                                userId: widget.currentUser!.id,
                                initialProfile: _profile,
                                onCompleted: _loadProfile,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    if (_loadingProfile)
                      const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
                    else if (_profile == null)
                      const Text('Chưa có thông tin hồ sơ.')
                    else ...[
                      // Thể chất: Chiều cao, cân nặng, BMI
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: Column(
                                children: [
                                  const Text('Chiều cao', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                  const SizedBox(height: 2),
                                  Text(
                                    _profile!.heightCm != null ? '${_profile!.heightCm!.toStringAsFixed(0)} cm' : '--',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: Column(
                                children: [
                                  const Text('Cân nặng', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                  const SizedBox(height: 2),
                                  Text(
                                    _profile!.weightKg != null ? '${_profile!.weightKg!.toStringAsFixed(1)} kg' : '--',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue[100]!),
                              ),
                              child: Column(
                                children: [
                                  const Text('BMI', style: TextStyle(fontSize: 11, color: Colors.blue)),
                                  const SizedBox(height: 2),
                                  Text(
                                    _profile!.bmi != null ? _profile!.bmi!.toStringAsFixed(1) : '--',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blue),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_profile!.bmiCategory != null)
                        Row(
                          children: [
                            const Text('Thể trạng: ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _profile!.bmiCategory == 'normal' ? Colors.green[100] : Colors.orange[100],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _profile!.bmiCategory == 'normal'
                                    ? 'Chuẩn dáng'
                                    : (_profile!.bmiCategory == 'underweight' ? 'Hơi gầy' : 'Thừa cân'),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _profile!.bmiCategory == 'normal' ? Colors.green[800] : Colors.orange[800],
                                ),
                              ),
                            ),
                            if (_profile!.targetGoal != null) ...[
                              const SizedBox(width: 8),
                              const Text('• Mục tiêu: ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              Text(
                                _profile!.targetGoal == 'lose_weight'
                                    ? 'Giảm cân'
                                    : (_profile!.targetGoal == 'gain_muscle'
                                        ? 'Tăng cơ'
                                        : (_profile!.targetGoal == 'eat_healthy' ? 'Ăn healthy' : 'Duy trì vóc dáng')),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ],
                        ),
                      const SizedBox(height: 8),
                      // Khẩu vị cay & Ngân sách
                      Row(
                        children: [
                          if (_profile!.spicyTolerance != null) ...[
                            Icon(Icons.local_fire_department, size: 16, color: Colors.red[400]),
                            const SizedBox(width: 4),
                            Text(
                              'Độ cay: ${_profile!.spicyTolerance == "hot" ? "Ăn cay nhiều" : (_profile!.spicyTolerance == "medium" ? "Cay vừa" : (_profile!.spicyTolerance == "mild" ? "Cay nhẹ" : "Không cay"))}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(width: 12),
                          ],
                          if (_profile!.budgetRange != null) ...[
                            Icon(Icons.account_balance_wallet_outlined, size: 16, color: Colors.teal[600]),
                            const SizedBox(width: 4),
                            Text(
                              'Ngân sách: ${_profile!.budgetRange == "budget" ? "Tiết kiệm" : (_profile!.budgetRange == "moderate" ? "Tầm trung" : "Cao cấp")}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ],
                      ),
                      if (_profile!.dietaryPreferences.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: _profile!.dietaryPreferences.map((diet) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.purple[50],
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.purple[100]!),
                            ),
                            child: Text(diet, style: TextStyle(fontSize: 11, color: Colors.purple[800])),
                          )).toList(),
                        ),
                      ],
                      if (_profile!.allergies.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Dị ứng: ', style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold)),
                            Expanded(
                              child: Wrap(
                                spacing: 4,
                                children: _profile!.allergies.map((a) => Text('$a,', style: const TextStyle(fontSize: 12, color: Colors.red))).toList(),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),


          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isRegister ? 'Tạo Tài Khoản Khách Hàng' : 'Đăng Nhập Khách Hàng'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Đăng nhập')),
              ButtonSegment(value: true, label: Text('Đăng ký')),
            ],
            selected: {_isRegister},
            onSelectionChanged: (set) {
              setState(() {
                _isRegister = set.first;
                _error = null;
              });
            },
          ),
          if (_error != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              color: Colors.red.shade50,
              child: Text('⚠️ $_error', style: TextStyle(color: Colors.red.shade800)),
            ),
          ],
          const SizedBox(height: 16),
          // Box thông tin tài khoản mẫu
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Color(0xFF1D4ED8)),
                    SizedBox(width: 6),
                    Text(
                      'Tài khoản mẫu (Đã điền sẵn):',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E3A8A)),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text('• Email: user@example.com', style: TextStyle(fontSize: 12, color: Color(0xFF1E40AF))),
                Text('• Mật khẩu: 123456', style: TextStyle(fontSize: 12, color: Color(0xFF1E40AF))),
              ],
            ),
          ),
          TextField(
            controller: _emailCtrl,
            decoration: const InputDecoration(labelText: 'Email *', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordCtrl,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Mật khẩu *', border: OutlineInputBorder()),
          ),
          if (_isRegister) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Họ và tên', border: OutlineInputBorder()),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _loading ? null : _handleAuth,
            child: _loading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(_isRegister ? 'Đăng ký ngay' : 'Đăng nhập'),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              '💡 Thực khách có thể lưu món ăn yêu thích và xem thực đơn từ hàng ngàn quán ăn lân cận.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// CLIENT MENU & FAVOURITING (GUEST-FIRST)
// ==========================================
class _RestaurantMenuWidget extends StatefulWidget {
  final ApiService api;
  final Restaurant restaurant;
  final ScrollController scrollController;
  final RoleLoginResponse? currentUser;
  final VoidCallback onRequireLogin;

  const _RestaurantMenuWidget({
    required this.api,
    required this.restaurant,
    required this.scrollController,
    this.currentUser,
    required this.onRequireLogin,
  });

  @override
  State<_RestaurantMenuWidget> createState() => _RestaurantMenuWidgetState();
}

class _RestaurantMenuWidgetState extends State<_RestaurantMenuWidget> {
  List<Category> _categories = [];
  List<Dish> _dishes = [];
  Set<int> _favouriteDishIds = {};
  int? _selectedCategoryId;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMenu();
    _loadUserFavourites();
  }

  Future<void> _loadMenu() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cats = await widget.api.getRestaurantCategories(widget.restaurant.id);
      final dishes = await widget.api.getRestaurantDishes(widget.restaurant.id);
      setState(() {
        _categories = cats;
        _dishes = dishes;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadUserFavourites() async {
    if (widget.currentUser == null || widget.currentUser!.role != 'user') return;
    try {
      final favs = await widget.api.getUserFavourites(widget.currentUser!.id);
      setState(() {
        _favouriteDishIds = favs.map((f) => f.dishId).toSet();
      });
    } catch (_) {}
  }

  Future<void> _toggleFavourite(Dish dish) async {
    if (widget.currentUser == null || widget.currentUser!.role != 'user') {
      // Auth Gate: Yêu cầu đăng nhập
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Yêu Cầu Đăng Nhập'),
          content: const Text('Bạn cần đăng nhập tài khoản Thực khách để lưu món ăn này vào danh sách yêu thích.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Để sau')),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context); // Đóng menu sheet
                widget.onRequireLogin(); // Điều hướng sang Tab Tài khoản
              },
              child: const Text('Đăng nhập ngay'),
            ),
          ],
        ),
      );
      return;
    }

    final isFav = _favouriteDishIds.contains(dish.id);
    try {
      if (isFav) {
        await widget.api.removeFavouriteDish(widget.currentUser!.id, dish.id);
        if (!mounted) return;
        setState(() => _favouriteDishIds.remove(dish.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã bỏ thích món "${dish.name}"')),
        );
      } else {
        await widget.api.addFavouriteDish(widget.currentUser!.id, dish.id);
        if (!mounted) return;
        setState(() => _favouriteDishIds.add(dish.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã thêm "${dish.name}" vào món ăn yêu thích!')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  List<Dish> get _displayedDishes {
    if (_selectedCategoryId == null) return _dishes;
    return _dishes.where((d) => d.categoryId == _selectedCategoryId).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 8),
          width: 40,
          height: 4,
          decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Thực đơn: ${widget.restaurant.name}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    if (widget.restaurant.address != null)
                      Text(widget.restaurant.address!,
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
        ),
        if (_categories.isNotEmpty)
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: const Text('Tất cả'),
                    selected: _selectedCategoryId == null,
                    onSelected: (_) => setState(() => _selectedCategoryId = null),
                  ),
                ),
                ..._categories.map((c) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(c.name),
                        selected: _selectedCategoryId == c.id,
                        onSelected: (_) => setState(() => _selectedCategoryId = c.id),
                      ),
                    )),
              ],
            ),
          ),
        const Divider(),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(child: Text('Lỗi: $_error', style: const TextStyle(color: Colors.red)))
                  : _displayedDishes.isEmpty
                      ? const Center(child: Text('Quán chưa có món trong danh mục này'))
                      : ListView.separated(
                          controller: widget.scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: _displayedDishes.length,
                          separatorBuilder: (_, __) => const Divider(height: 16),
                          itemBuilder: (context, index) {
                            final d = _displayedDishes[index];
                            final isFav = _favouriteDishIds.contains(d.id);
                            final formattedPrice = '${d.price.toStringAsFixed(0)} đ';

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(d.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 2),
                                      Text(formattedPrice,
                                          style: const TextStyle(
                                              color: Colors.deepOrange, fontWeight: FontWeight.bold, fontSize: 14)),
                                      if (d.description != null && d.description!.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(d.description!,
                                            style: TextStyle(color: Colors.grey[600], fontSize: 12), maxLines: 2),
                                      ],
                                      const SizedBox(height: 4),
                                      Wrap(
                                        spacing: 4,
                                        runSpacing: 4,
                                        children: [
                                          if (d.categoryName != null)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                  color: Colors.blue[50], borderRadius: BorderRadius.circular(4)),
                                              child: Text(d.categoryName!,
                                                  style: const TextStyle(fontSize: 10, color: Colors.blue)),
                                            ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                                color: Colors.grey[100], borderRadius: BorderRadius.circular(4)),
                                            child: Text(d.mealType,
                                                style: TextStyle(fontSize: 10, color: Colors.grey[700])),
                                          ),
                                          ...d.ingredients.map((ing) => Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                    color: Colors.green[50], borderRadius: BorderRadius.circular(4)),
                                                child: Text(ing,
                                                    style: const TextStyle(fontSize: 10, color: Colors.green)),
                                              )),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    isFav ? Icons.favorite : Icons.favorite_border,
                                    color: isFav ? Colors.red : Colors.grey,
                                  ),
                                  tooltip: isFav ? 'Bỏ thích' : 'Thích món này',
                                  onPressed: () => _toggleFavourite(d),
                                ),
                              ],
                            );
                          },
                        ),
        ),
      ],
    );
  }
}


// ============================================================================
// ONBOARDING SURVEY DIALOG (KHẢO SÁT SỞ THÍCH ẨM THỰC & SỨC KHỎE THỰC KHÁCH)
// ============================================================================
class OnboardingSurveyDialog extends StatefulWidget {
  final ApiService api;
  final int userId;
  final UserProfile? initialProfile;
  final VoidCallback onCompleted;

  const OnboardingSurveyDialog({
    super.key,
    required this.api,
    required this.userId,
    this.initialProfile,
    required this.onCompleted,
  });

  @override
  State<OnboardingSurveyDialog> createState() => _OnboardingSurveyDialogState();
}

class _OnboardingSurveyDialogState extends State<OnboardingSurveyDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _birthYearCtrl = TextEditingController();

  String? _gender;
  String? _activityLevel;
  String? _targetGoal;
  String? _spicyTolerance;
  String? _budgetRange;

  final Set<String> _selectedDiets = {};
  final Set<String> _selectedAllergies = {};
  final Set<String> _selectedCategories = {};

  bool _saving = false;
  String? _error;

  final List<String> _foodCategories = [
    'Phở & Bún',
    'Cơm văn phòng',
    'Lẩu & Nướng',
    'Đồ chay',
    'Ăn vặt & Trà sữa',
    'Món Hàn & Nhật',
    'Fastfood & Đồ Tây',
    'Hải sản',
  ];

  final List<String> _dietOptions = [
    'Ăn thanh đạm',
    'Ít dầu mỡ',
    'Eat clean',
    'Low-carb',
    'Keto',
    'Ăn chay',
    'Nhiều protein',
  ];

  final List<String> _allergyOptions = [
    'Hải sản',
    'Đậu phộng',
    'Trứng',
    'Sữa bò',
    'Gluten',
    'Đậu nành',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    final p = widget.initialProfile;
    if (p != null) {
      if (p.heightCm != null) _heightCtrl.text = p.heightCm!.toStringAsFixed(0);
      if (p.weightKg != null) _weightCtrl.text = p.weightKg!.toStringAsFixed(1);
      if (p.birthYear != null) _birthYearCtrl.text = p.birthYear.toString();
      _gender = p.gender;
      _activityLevel = p.activityLevel;
      _targetGoal = p.targetGoal ?? 'maintain';
      _spicyTolerance = p.spicyTolerance ?? 'mild';
      _budgetRange = p.budgetRange ?? 'moderate';
      _selectedDiets.addAll(p.dietaryPreferences);
      _selectedAllergies.addAll(p.allergies);
    } else {
      _targetGoal = 'maintain';
      _spicyTolerance = 'mild';
      _budgetRange = 'moderate';
      _gender = 'male';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _birthYearCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final double? h = double.tryParse(_heightCtrl.text.trim());
      final double? w = double.tryParse(_weightCtrl.text.trim());
      final int? by = int.tryParse(_birthYearCtrl.text.trim());

      final payload = <String, dynamic>{
        'gender': _gender,
        'activity_level': _activityLevel,
        'target_goal': _targetGoal,
        'spicy_tolerance': _spicyTolerance,
        'budget_range': _budgetRange,
        'dietary_preferences': _selectedDiets.toList(),
        'allergies': _selectedAllergies.toList(),
        'complete_onboarding': true,
      };

      if (h != null && h >= 50 && h <= 260) payload['height_cm'] = h;
      if (w != null && w >= 10 && w <= 500) payload['weight_kg'] = w;
      if (by != null && by >= 1920 && by <= 2026) payload['birth_year'] = by;

      await widget.api.updateUserProfile(widget.userId, payload);
      widget.onCompleted();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 680),
        child: Column(
          children: [
            // Header Dialog
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.restaurant_menu, color: Colors.white, size: 24),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Sở Thích Ẩm Thực & Sức Khỏe',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        Text('Giúp PTC1 gợi ý món ăn chuẩn gu & thể trạng của bạn',
                            style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Tab bar 3 bước
            TabBar(
              controller: _tabController,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.black,
              tabs: const [
                Tab(icon: Icon(Icons.fastfood_outlined, size: 20), text: '1. Thể Loại'),
                Tab(icon: Icon(Icons.fitness_center_outlined, size: 20), text: '2. Thể Chất'),
                Tab(icon: Icon(Icons.tune, size: 20), text: '3. Khẩu Vị'),
              ],
            ),

            if (_error != null)
              Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(8),
                color: Colors.red[50],
                child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
              ),

            // Nội dung các tab
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // TAB 1: Thể loại món & Chế độ ăn
                  ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const Text('Bạn thích những thể loại món ăn nào?',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _foodCategories.map((cat) {
                          final selected = _selectedCategories.contains(cat);
                          return FilterChip(
                            label: Text(cat),
                            selected: selected,
                            selectedColor: Colors.black,
                            labelStyle: TextStyle(
                              color: selected ? Colors.white : Colors.black,
                              fontSize: 13,
                              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                            ),
                            backgroundColor: Colors.grey[100],
                            onSelected: (val) {
                              setState(() {
                                if (val) {
                                  _selectedCategories.add(cat);
                                } else {
                                  _selectedCategories.remove(cat);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                      const Text('Chế độ ăn uống quan tâm:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _dietOptions.map((diet) {
                          final selected = _selectedDiets.contains(diet);
                          return FilterChip(
                            label: Text(diet),
                            selected: selected,
                            selectedColor: Colors.purple[700],
                            labelStyle: TextStyle(
                              color: selected ? Colors.white : Colors.purple[900],
                              fontSize: 13,
                              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                            ),
                            backgroundColor: Colors.purple[50],
                            onSelected: (val) {
                              setState(() {
                                if (val) {
                                  _selectedDiets.add(diet);
                                } else {
                                  _selectedDiets.remove(diet);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),

                  // TAB 2: Thể chất & Mục tiêu sức khỏe
                  ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const Text('Chỉ số thể chất cơ bản:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _heightCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Chiều cao (cm)',
                                hintText: '170',
                                border: OutlineInputBorder(),
                                suffixText: 'cm',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _weightCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Cân nặng (kg)',
                                hintText: '65',
                                border: OutlineInputBorder(),
                                suffixText: 'kg',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _birthYearCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Năm sinh',
                                hintText: '2000',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _gender ?? 'male',
                              decoration: const InputDecoration(
                                labelText: 'Giới tính',
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'male', child: Text('Nam')),
                                DropdownMenuItem(value: 'female', child: Text('Nữ')),
                                DropdownMenuItem(value: 'other', child: Text('Khác')),
                              ],
                              onChanged: (val) => setState(() => _gender = val),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text('Mục tiêu dinh dưỡng hiện tại:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('Duy trì vóc dáng'),
                            selected: _targetGoal == 'maintain',
                            onSelected: (_) => setState(() => _targetGoal = 'maintain'),
                          ),
                          ChoiceChip(
                            label: const Text('Giảm cân / Đốt mỡ'),
                            selected: _targetGoal == 'lose_weight',
                            onSelected: (_) => setState(() => _targetGoal = 'lose_weight'),
                          ),
                          ChoiceChip(
                            label: const Text('Tăng cân / Tăng cơ'),
                            selected: _targetGoal == 'gain_muscle',
                            onSelected: (_) => setState(() => _targetGoal = 'gain_muscle'),
                          ),
                          ChoiceChip(
                            label: const Text('Ăn uống lành mạnh'),
                            selected: _targetGoal == 'eat_healthy',
                            onSelected: (_) => setState(() => _targetGoal = 'eat_healthy'),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // TAB 3: Khẩu vị & Dị ứng & Ngân sách
                  ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const Text('Mức độ ăn cay:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('Không ăn cay'),
                            selected: _spicyTolerance == 'none',
                            onSelected: (_) => setState(() => _spicyTolerance = 'none'),
                          ),
                          ChoiceChip(
                            label: const Text('Cay nhẹ'),
                            selected: _spicyTolerance == 'mild',
                            onSelected: (_) => setState(() => _spicyTolerance = 'mild'),
                          ),
                          ChoiceChip(
                            label: const Text('Cay vừa'),
                            selected: _spicyTolerance == 'medium',
                            onSelected: (_) => setState(() => _spicyTolerance = 'medium'),
                          ),
                          ChoiceChip(
                            label: const Text('Rất cay'),
                            selected: _spicyTolerance == 'hot',
                            onSelected: (_) => setState(() => _spicyTolerance = 'hot'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const Text('Dị ứng thực phẩm (nếu có):',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _allergyOptions.map((alg) {
                          final selected = _selectedAllergies.contains(alg);
                          return FilterChip(
                            label: Text(alg),
                            selected: selected,
                            selectedColor: Colors.red[700],
                            labelStyle: TextStyle(
                              color: selected ? Colors.white : Colors.red[900],
                              fontSize: 13,
                            ),
                            backgroundColor: Colors.red[50],
                            onSelected: (val) {
                              setState(() {
                                if (val) {
                                  _selectedAllergies.add(alg);
                                } else {
                                  _selectedAllergies.remove(alg);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),
                      const Text('Ngân sách ăn uống:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('Tiết kiệm (< 40k)'),
                            selected: _budgetRange == 'budget',
                            onSelected: (_) => setState(() => _budgetRange = 'budget'),
                          ),
                          ChoiceChip(
                            label: const Text('Vừa phải (40k - 80k)'),
                            selected: _budgetRange == 'moderate',
                            onSelected: (_) => setState(() => _budgetRange = 'moderate'),
                          ),
                          ChoiceChip(
                            label: const Text('Thoải mái (> 80k)'),
                            selected: _budgetRange == 'premium',
                            onSelected: (_) => setState(() => _budgetRange = 'premium'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Footer Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(top: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Row(
                children: [
                  TextButton(
                    onPressed: _saving ? null : () => Navigator.of(context).pop(),
                    child: const Text('Để sau', style: TextStyle(color: Colors.grey)),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onPressed: _saving ? null : _handleSave,
                    child: _saving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Lưu & Hoàn tất'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ============================================================================
// WELCOME CATEGORY DIALOG (MỚI VÀO PHẢI CHỌN THỂ LOẠI MÓN ĂN)
// ============================================================================
class WelcomeCategoryDialog extends StatefulWidget {
  final String? selectedCategory;
  final Function(String) onCategorySelected;

  const WelcomeCategoryDialog({
    super.key,
    this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  State<WelcomeCategoryDialog> createState() => _WelcomeCategoryDialogState();
}

class _WelcomeCategoryDialogState extends State<WelcomeCategoryDialog> {
  String? _chosen;

  final List<Map<String, dynamic>> _categories = const [
    {'name': 'Phở & Bún', 'icon': Icons.ramen_dining, 'desc': 'Phở bò, bún bò huế, bún chả'},
    {'name': 'Cơm văn phòng', 'icon': Icons.rice_bowl, 'desc': 'Cơm tấm, cơm gà, cơm sườn'},
    {'name': 'Lẩu & Nướng', 'icon': Icons.outdoor_grill, 'desc': 'Lẩu thái, nướng BBQ, bò tơ'},
    {'name': 'Đồ chay', 'icon': Icons.eco, 'desc': 'Thanh đạm, thuần chay, healthy'},
    {'name': 'Ăn vặt', 'icon': Icons.local_cafe, 'desc': 'Trà sữa, bánh tráng, xiên que'},
    {'name': 'Món Hàn & Nhật', 'icon': Icons.set_meal, 'desc': 'Sushi, sashimi, mì cay, tokbokki'},
    {'name': 'Fastfood', 'icon': Icons.fastfood, 'desc': 'Pizza, gà rán, hamburger'},
    {'name': 'Hải sản', 'icon': Icons.water_drop, 'desc': 'Tôm, cua, ốc cay nóng hổi'},
  ];

  @override
  void initState() {
    super.initState();
    _chosen = widget.selectedCategory ?? 'Phở & Bún';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 580),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.restaurant, size: 26, color: Colors.deepOrange),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hôm Nay Bạn Muốn Ăn Gì?',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 2),
                      Text('Chọn thể loại để PTC1 chuẩn bị món ngon cho bạn',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            const Text('Chọn 1 thể loại món bạn muốn ăn nhất:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.separated(
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (ctx, i) {
                  final item = _categories[i];
                  final name = item['name']!;
                  final isSelected = _chosen == name;
                  return InkWell(
                    onTap: () => setState(() => _chosen = name),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.black : Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? Colors.black : Colors.grey[200]!,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            item['icon'] as IconData,
                            color: isSelected ? Colors.white : Colors.black87,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isSelected ? Colors.white : Colors.black,
                                  ),
                                ),
                                Text(
                                  item['desc']!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isSelected ? Colors.white70 : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_circle, color: Colors.white, size: 20),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    widget.onCategorySelected('Tất cả');
                    Navigator.of(context).pop();
                  },
                  child: const Text('Xem tất cả món', style: TextStyle(color: Colors.grey)),
                ),
                const Spacer(),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    if (_chosen != null) {
                      widget.onCategorySelected(_chosen!);
                    }
                    Navigator.of(context).pop();
                  },
                  child: const Text('Khám Phá', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}