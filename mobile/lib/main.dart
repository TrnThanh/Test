import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'models/models.dart';
import 'services/api_service.dart';

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

class Ptc1App extends StatelessWidget {
  final ApiService? apiService;

  const Ptc1App({super.key, this.apiService});

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
      home: MainShell(apiService: apiService ?? ApiService()),
    );
  }
}

class MainShell extends StatefulWidget {
  final ApiService apiService;

  const MainShell({super.key, required this.apiService});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  RoleLoginResponse? _currentUser;

  // Hỗ trợ chuyển toạ độ từ Tab Bản đồ sang Tab Gần đây
  double? _targetLat;
  double? _targetLon;

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
  }

  void _onLogout() {
    setState(() {
      _currentUser = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã đăng xuất tài khoản.')),
    );
  }

  void _navigateToNearbyWithLocation(double lat, double lon) {
    setState(() {
      _targetLat = lat;
      _targetLon = lon;
      _currentIndex = 1; // Tab Gần đây
    });
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      ExploreScreen(
        api: widget.apiService,
        currentUser: _currentUser,
        onRequireLogin: () {
          setState(() => _currentIndex = 3);
        },
      ),
      NearbyScreen(
        api: widget.apiService,
        initialLat: _targetLat,
        initialLon: _targetLon,
        currentUser: _currentUser,
        onRequireLogin: () {
          setState(() => _currentIndex = 3);
        },
        onOpenMap: () {
          setState(() => _currentIndex = 2);
        },
      ),
      GeocodingScreen(
        api: widget.apiService,
        initialLat: _targetLat,
        initialLon: _targetLon,
        onSelectPlaceNearby: _navigateToNearbyWithLocation,
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
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Khám phá',
          ),
          NavigationDestination(
            icon: Icon(Icons.near_me_outlined),
            selectedIcon: Icon(Icons.near_me),
            label: 'Gần đây',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Bản đồ OSM',
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

  const ExploreScreen({
    super.key,
    required this.api,
    this.currentUser,
    required this.onRequireLogin,
  });

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  List<Restaurant> _restaurants = [];
  bool _loading = false;
  String? _error;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
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
        _error = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  List<Restaurant> get _filteredList {
    if (_searchQuery.trim().isEmpty) return _restaurants;
    final q = _searchQuery.toLowerCase().trim();
    return _restaurants.where((r) =>
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
// TAB 2: QUÁN GẦN ĐÂY (NEARBY SPATIAL - POSTGIS)
// ==========================================
class NearbyScreen extends StatefulWidget {
  final ApiService api;
  final double? initialLat;
  final double? initialLon;
  final RoleLoginResponse? currentUser;
  final VoidCallback onRequireLogin;
  final VoidCallback? onOpenMap;

  const NearbyScreen({
    super.key,
    required this.api,
    this.initialLat,
    this.initialLon,
    this.currentUser,
    required this.onRequireLogin,
    this.onOpenMap,
  });

  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<NearbyScreen> {
  double _lat = 21.0046; // Mặc định Học viện Nông nghiệp Việt Nam (HVNN)
  double _lon = 105.9387;
  double _radiusKm = 5.0;

  List<Restaurant> _restaurants = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null && widget.initialLon != null) {
      _lat = widget.initialLat!;
      _lon = widget.initialLon!;
    }
    _searchNearby();
  }

  @override
  void didUpdateWidget(covariant NearbyScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialLat != null && widget.initialLon != null &&
        (widget.initialLat != oldWidget.initialLat || widget.initialLon != oldWidget.initialLon)) {
      _lat = widget.initialLat!;
      _lon = widget.initialLon!;
      _searchNearby();
    }
  }

  Future<void> _searchNearby() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final list = await widget.api.getNearbyRestaurants(
        lat: _lat,
        lon: _lon,
        radiusKm: _radiusKm,
      );
      setState(() {
        _restaurants = list;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  void _showMenu(Restaurant r) {
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
        title: const Text('Quán Ăn Lân Cận (PostGIS)', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (widget.onOpenMap != null)
            IconButton(
              tooltip: 'Xem trên Bản đồ OSM',
              icon: const Icon(Icons.map_outlined),
              onPressed: widget.onOpenMap,
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Bán kính tìm kiếm:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('${_radiusKm.toStringAsFixed(1)} km',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                  ],
                ),
                Slider(
                  value: _radiusKm,
                  min: 0.5,
                  max: 20.0,
                  divisions: 39,
                  activeColor: Colors.black,
                  label: '${_radiusKm.toStringAsFixed(1)} km',
                  onChanged: (val) {
                    setState(() => _radiusKm = val);
                  },
                  onChangeEnd: (_) => _searchNearby(),
                ),
                const SizedBox(height: 8),
                const Text('Địa điểm mẫu:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('HVNN (Trâu Quỳ)'),
                      selected: (_lat == 21.0046 && _lon == 105.9387),
                      onSelected: (_) {
                        setState(() {
                          _lat = 21.0046;
                          _lon = 105.9387;
                        });
                        _searchNearby();
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Ocean Park 1'),
                      selected: (_lat == 20.9950 && _lon == 105.9550),
                      onSelected: (_) {
                        setState(() {
                          _lat = 20.9950;
                          _lon = 105.9550;
                        });
                        _searchNearby();
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Bát Tràng'),
                      selected: (_lat == 20.9760 && _lon == 105.9080),
                      onSelected: (_) {
                        setState(() {
                          _lat = 20.9760;
                          _lon = 105.9080;
                        });
                        _searchNearby();
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Ninh Hiệp'),
                      selected: (_lat == 21.1120 && _lon == 105.9360),
                      onSelected: (_) {
                        setState(() {
                          _lat = 21.1120;
                          _lon = 105.9360;
                        });
                        _searchNearby();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Lỗi: $_error', style: const TextStyle(color: Colors.red)),
                              const SizedBox(height: 8),
                              ElevatedButton(onPressed: _searchNearby, child: const Text('Thử lại')),
                            ],
                          ),
                        ),
                      )
                    : _restaurants.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.explore_off, size: 48, color: Colors.black26),
                                const SizedBox(height: 8),
                                Text('Không có quán ăn nào trong bán kính ${_radiusKm.toStringAsFixed(1)} km',
                                    style: TextStyle(color: Colors.grey[600])),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: _restaurants.length,
                            itemBuilder: (context, index) {
                              final r = _restaurants[index];
                              final distText = r.distanceKm != null
                                  ? '${r.distanceKm!.toStringAsFixed(2)} km'
                                  : r.distanceMeters != null
                                      ? '${r.distanceMeters!.toStringAsFixed(0)} m'
                                      : 'Gần đây';
                              final open = isOpenNow(r.openTime, r.closeTime);

                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                color: Colors.white,
                                elevation: 0.5,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: Colors.grey[200]!),
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.black,
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(r.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      ),
                                      Text(open ? '🟢 Mở' : '🔴 Đóng', style: const TextStyle(fontSize: 11)),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(r.address ?? 'Chưa rõ địa chỉ', maxLines: 1, overflow: TextOverflow.ellipsis),
                                      Row(
                                        children: [
                                          const Icon(Icons.near_me, size: 14, color: Colors.deepOrange),
                                          const SizedBox(width: 4),
                                          Text(distText,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.deepOrange,
                                                  fontSize: 12)),
                                          if (r.openTime != null && r.closeTime != null)
                                            Padding(
                                              padding: const EdgeInsets.only(left: 8),
                                              child: Text('• ${r.openTime}-${r.closeTime}',
                                                  style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                                  onTap: () => _showMenu(r),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// ==========================================
// ==========================================
// TAB 3: BẢN ĐỒ & GEOCODING OSM
// ==========================================
class GeocodingScreen extends StatefulWidget {
  final ApiService api;
  final double? initialLat;
  final double? initialLon;
  final Function(double lat, double lon) onSelectPlaceNearby;

  const GeocodingScreen({
    super.key,
    required this.api,
    this.initialLat,
    this.initialLon,
    required this.onSelectPlaceNearby,
  });

  @override
  State<GeocodingScreen> createState() => _GeocodingScreenState();
}

class _GeocodingScreenState extends State<GeocodingScreen> {
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

  LatLng _currentCenter = const LatLng(21.0046, 105.9387); // Mặc định Học viện Nông nghiệp Việt Nam (HVNN)
  LatLng? _pinnedLocation;
  String? _pinnedAddress;

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
    }
    _pinnedLocation = _currentCenter;
    _loadNearby(_currentCenter.latitude, _currentCenter.longitude);
  }

  @override
  void didUpdateWidget(covariant GeocodingScreen oldWidget) {
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
      final list = await widget.api.getNearbyRestaurants(lat: lat, lon: lon, radiusKm: 5.0);
      if (mounted) {
        // Chỉ giữ lại các quán nằm trong miếng bánh Gia Lâm, bỏ toàn bộ quán thừa bên ngoài
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
      // Lọc bỏ các kết quả ngoài Gia Lâm
      final inGiaLam = res.where((p) => isPointInGiaLam(LatLng(p.latitude, p.longitude))).toList();
      setState(() {
        _places = inGiaLam.isNotEmpty ? inGiaLam : res.take(2).toList();
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _onMapTap(LatLng point) async {
    if (!isPointInGiaLam(point)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vị trí nằm ngoài địa phận Huyện Gia Lâm!'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
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
    if (!isPointInGiaLam(pos)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Địa điểm này nằm ngoài địa phận Huyện Gia Lâm!'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bản Đồ & Geocoding OSM', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: 'Về HVNN',
            icon: const Icon(Icons.my_location),
            onPressed: () => _jumpTo(21.0046, 105.9387, 'Học viện Nông nghiệp Việt Nam (HVNN)'),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. BẢN ĐỒ OPENSTREETMAP TƯƠNG TÁC
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentCenter,
              initialZoom: 14.0,
              minZoom: 11.5,
              maxZoom: 18.0,
              cameraConstraint: CameraConstraint.containCenter(
                bounds: giaLamBounds,
              ),
              onTap: (tapPosition, point) => _onMapTap(point),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.ptc1.mobile',
                tileBounds: giaLamBounds,
              ),
              // 1.1 MẶT NẠ "CẮT MIẾNG BÁNH" (INVERSE MASK POLYGON)
              // Che đặc hoàn toàn 100% phần bản đồ thừa bên ngoài, chỉ hiển thị đúng miếng bánh Gia Lâm
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
                    color: const Color(0xFFFAFAFA), // 100% che đặc trùng màu nền Scaffold, xoá sạch phần thừa
                    borderColor: Colors.transparent,
                    borderStrokeWidth: 0,
                  ),
                ],
              ),
              // 1.2 ĐƯỜNG GẤP KHÚC RANH GIỚI "MIẾNG BÁNH" GIA LÂM
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [...giaLamBoundaryPolygon, giaLamBoundaryPolygon.first],
                    color: Colors.deepOrange,
                    strokeWidth: 3.5,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  // Marker điểm chọn / ghim
                  if (_pinnedLocation != null)
                    Marker(
                      point: _pinnedLocation!,
                      width: 44,
                      height: 44,
                      child: const Icon(
                        Icons.location_pin,
                        color: Colors.red,
                        size: 44,
                      ),
                    ),
                  // Marker các quán ăn lân cận xung quanh
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

          // 2. KHUNG TÌM KIẾM & CHIPS
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
                          subtitle: Text(
                              'Toạ độ: ${p.latitude.toStringAsFixed(4)}, ${p.longitude.toStringAsFixed(4)}'),
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

          // 3. NÚT ĐIỀU KHIỂN ZOOM (+) (-)
          Positioned(
            right: 16,
            bottom: (_selectedRestaurant != null || _pinnedAddress != null || _pinnedLocation != null) ? 140 : 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: 'zoom_in_btn',
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
                  heroTag: 'zoom_out_btn',
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

          // 4. CARD CHI TIẾT ĐÁY MÀN HÌNH
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
                            icon: const Icon(Icons.near_me, size: 16),
                            label: const Text('Tìm quán quanh đây'),
                            onPressed: () {
                              widget.onSelectPlaceNearby(
                                _selectedRestaurant!.latitude,
                                _selectedRestaurant!.longitude,
                              );
                            },
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
                              _pinnedAddress ?? 'Vị trí đã ghim trên bản đồ',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (_pinnedLocation != null)
                              Text(
                                'Toạ độ: ${_pinnedLocation!.latitude.toStringAsFixed(4)}, ${_pinnedLocation!.longitude.toStringAsFixed(4)}',
                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.tonal(
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Tìm quán'),
                        onPressed: () {
                          if (_pinnedLocation != null) {
                            widget.onSelectPlaceNearby(
                              _pinnedLocation!.latitude,
                              _pinnedLocation!.longitude,
                            );
                          }
                        },
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


// TAB 4: TÀI KHOẢN (USER AUTH & YÊU THÍCH)
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

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  bool _loading = false;
  String? _error;

  List<FavouriteDish> _favourites = [];
  bool _loadingFavourites = false;

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
    _loadFavourites();
  }

  Future<void> _loadFavourites() async {
    if (widget.currentUser == null) return;
    setState(() => _loadingFavourites = true);
    try {
      final list = await widget.api.getUserFavourites(widget.currentUser!.id);
      setState(() => _favourites = list);
    } catch (_) {}
    setState(() => _loadingFavourites = false);
  }

  Future<void> _removeFavourite(int favId) async {
    if (widget.currentUser == null) return;
    try {
      await widget.api.removeFavourite(widget.currentUser!.id, favId);
      _loadFavourites();
    } catch (_) {}
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
        _error = e.toString().replaceAll('Exception: ', '');
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
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Món Ăn Yêu Thích Của Bạn', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                if (_loadingFavourites)
                  const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ),
            const SizedBox(height: 8),
            if (_loadingFavourites)
              const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
            else if (_favourites.isEmpty)
              Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Icon(Icons.favorite_border, size: 44, color: Colors.grey),
                      const SizedBox(height: 8),
                      Text('Bạn chưa có món ăn yêu thích nào', style: TextStyle(color: Colors.grey[700])),
                      const SizedBox(height: 4),
                      Text('Khám phá các quán và bấm tim (❤) để lưu món ngon nhé!',
                          textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                    ],
                  ),
                ),
              )
            else
              ..._favourites.map((fav) {
                final dish = fav.dish;
                return Card(
                  color: Colors.white,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFEEEEEE),
                      child: Icon(Icons.fastfood, color: Colors.black, size: 20),
                    ),
                    title: Text(dish?.name ?? 'Món #${fav.dishId}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: dish != null
                        ? Text('${dish.price.toStringAsFixed(0)} đ • ${dish.mealType}')
                        : null,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      tooltip: 'Bỏ thích',
                      onPressed: () => _removeFavourite(fav.id),
                    ),
                  ),
                );
              }),
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
              child: Text('⚠️ ', style: TextStyle(color: Colors.red.shade800)),
            ),
          ],
          const SizedBox(height: 16),
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
