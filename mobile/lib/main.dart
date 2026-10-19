import 'package:flutter/material.dart';
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
        content: Text('Chào mừng ${user.fullName ?? user.email} (${user.role == "seller" ? "Chủ quán" : "Thực khách"})!'),
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
      ),
      GeocodingScreen(
        api: widget.apiService,
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

  const NearbyScreen({
    super.key,
    required this.api,
    this.initialLat,
    this.initialLon,
    this.currentUser,
    required this.onRequireLogin,
  });

  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<NearbyScreen> {
  double _lat = 21.0285; // Mặc định Hà Nội
  double _lon = 105.8542;
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
                      label: const Text('Hồ Gươm'),
                      selected: (_lat == 21.0285 && _lon == 105.8542),
                      onSelected: (_) {
                        setState(() {
                          _lat = 21.0285;
                          _lon = 105.8542;
                        });
                        _searchNearby();
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Cầu Giấy'),
                      selected: (_lat == 21.0333 && _lon == 105.7994),
                      onSelected: (_) {
                        setState(() {
                          _lat = 21.0333;
                          _lon = 105.7994;
                        });
                        _searchNearby();
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Tây Hồ'),
                      selected: (_lat == 21.0556 && _lon == 105.8200),
                      onSelected: (_) {
                        setState(() {
                          _lat = 21.0556;
                          _lon = 105.8200;
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
// TAB 3: BẢN ĐỒ & GEOCODING OSM
// ==========================================
class GeocodingScreen extends StatefulWidget {
  final ApiService api;
  final Function(double lat, double lon) onSelectPlaceNearby;

  const GeocodingScreen({
    super.key,
    required this.api,
    required this.onSelectPlaceNearby,
  });

  @override
  State<GeocodingScreen> createState() => _GeocodingScreenState();
}

class _GeocodingScreenState extends State<GeocodingScreen> {
  final _searchCtrl = TextEditingController();
  List<GeocodePlace> _places = [];
  bool _loading = false;
  String? _error;

  Future<void> _search() async {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await widget.api.searchMap(q);
      setState(() {
        _places = res;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bản Đồ & Geocoding OSM', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Nhập địa chỉ (VD: Hồ Gươm, Hà Nội)...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _loading ? null : _search,
                  child: _loading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Tìm'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(10),
                color: Colors.red.shade50,
                child: Text('Lỗi: $_error', style: const TextStyle(color: Colors.red)),
              ),
            Expanded(
              child: _places.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.map, size: 54, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text('Nhập tên địa điểm để tra cứu toạ độ và tìm quán',
                              style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: _places.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final p = _places[index];
                        return ListTile(
                          leading: const Icon(Icons.place, color: Colors.deepOrange),
                          title: Text(p.displayName, style: const TextStyle(fontSize: 14)),
                          subtitle: Text('Toạ độ: ${p.latitude.toStringAsFixed(4)}, ${p.longitude.toStringAsFixed(4)}'),
                          trailing: FilledButton.tonal(
                            child: const Text('Tìm quán'),
                            onPressed: () {
                              widget.onSelectPlaceNearby(p.latitude, p.longitude);
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
}

// ==========================================
// TAB 4: TÀI KHOẢN (USER / SELLER / AUTH)
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
  // Auth Form State
  String _selectedRole = 'user'; // 'user' hoặc 'seller'
  bool _isRegister = false;

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _shopNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  bool _loading = false;
  String? _error;

  // User state: Favourites & Options
  List<FavouriteDish> _favourites = [];
  bool _loadingFavourites = false;

  // Seller state: Restaurants
  List<Restaurant> _sellerRestaurants = [];
  bool _loadingSellerRestaurants = false;

  @override
  void initState() {
    super.initState();
    _loadRoleData();
  }

  @override
  void didUpdateWidget(covariant AccountScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentUser?.id != oldWidget.currentUser?.id ||
        widget.currentUser?.role != oldWidget.currentUser?.role) {
      _loadRoleData();
    }
  }

  void _loadRoleData() {
    if (widget.currentUser == null) return;
    if (widget.currentUser!.role == 'seller') {
      _loadSellerRestaurants();
    } else {
      _loadFavourites();
    }
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

  Future<void> _loadSellerRestaurants() async {
    if (widget.currentUser == null || widget.currentUser!.role != 'seller') return;
    setState(() => _loadingSellerRestaurants = true);
    try {
      final list = await widget.api.getSellerRestaurants(widget.currentUser!.id);
      setState(() => _sellerRestaurants = list);
    } catch (_) {}
    setState(() => _loadingSellerRestaurants = false);
  }

  Future<void> _handleAuth() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      RoleLoginResponse res;
      if (_selectedRole == 'seller') {
        if (!_isRegister) {
          res = await widget.api.loginSeller(_emailCtrl.text.trim(), _passwordCtrl.text);
        } else {
          res = await widget.api.registerSeller(
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
            shopName: _shopNameCtrl.text.trim().isEmpty ? 'Quán Mới' : _shopNameCtrl.text.trim(),
            fullName: _nameCtrl.text.trim(),
            phone: _phoneCtrl.text.trim(),
          );
        }
      } else {
        if (!_isRegister) {
          res = await widget.api.loginUser(_emailCtrl.text.trim(), _passwordCtrl.text);
        } else {
          res = await widget.api.registerUser(
            _emailCtrl.text.trim(),
            _passwordCtrl.text,
            _nameCtrl.text.trim(),
          );
        }
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

  void _openAddRestaurantDialog() {
    final nameCtrl = TextEditingController();
    final addrCtrl = TextEditingController(text: '123 Phố Huế, Hà Nội');
    final phoneCtrl = TextEditingController(text: '0912345678');
    final descCtrl = TextEditingController();
    final openCtrl = TextEditingController(text: '08:00');
    final closeCtrl = TextEditingController(text: '22:00');
    double lat = 21.0200;
    double lon = 105.8500;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thêm Quán Ăn Mới'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Tên quán *')),
              TextField(controller: addrCtrl, decoration: const InputDecoration(labelText: 'Địa chỉ')),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Số điện thoại')),
              TextField(controller: openCtrl, decoration: const InputDecoration(labelText: 'Giờ mở cửa (HH:MM)')),
              TextField(controller: closeCtrl, decoration: const InputDecoration(labelText: 'Giờ đóng cửa (HH:MM)')),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Mô tả')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          FilledButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              try {
                await widget.api.createSellerRestaurant(
                  widget.currentUser!.id,
                  name: nameCtrl.text.trim(),
                  address: addrCtrl.text.trim(),
                  phone: phoneCtrl.text.trim(),
                  latitude: lat,
                  longitude: lon,
                  openTime: openCtrl.text.trim(),
                  closeTime: closeCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                );
                _loadSellerRestaurants();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                }
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _openSellerMenuDialog(Restaurant r) {
    showDialog(
      context: context,
      builder: (ctx) => _SellerMenuDialog(
        sellerId: widget.currentUser!.id,
        restaurant: r,
        api: widget.api,
      ),
    );
  }

  Future<void> _deleteRestaurant(Restaurant r) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa quán'),
        content: Text('Bạn có chắc chắn muốn xóa quán "${r.name}" không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xóa')),
        ],
      ),
    );

    if (confirm == true) {
      await widget.api.deleteSellerRestaurant(widget.currentUser!.id, r.id);
      _loadSellerRestaurants();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.currentUser != null) {
      final user = widget.currentUser!;
      final isSeller = (user.role == 'seller');

      return Scaffold(
        appBar: AppBar(
          title: Text(isSeller ? 'Bảng Điều Khiển Chủ Quán' : 'Tài Khoản Thực Khách'),
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
            // Profile Card
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
                          Text(user.fullName ?? (isSeller ? 'Chủ quán' : 'Thực khách'),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text(user.email, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                          if (isSeller && user.shopName != null) ...[
                            const SizedBox(height: 2),
                            Text('🏪 Shop: ${user.shopName}',
                                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12)),
                          ],
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isSeller ? Colors.deepOrange.shade50 : const Color(0xFFEEEEEE),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: isSeller ? Colors.deepOrange : Colors.black),
                            ),
                            child: Text(
                              isSeller ? 'Chủ Quán (Seller)' : 'Thực Khách (User)',
                              style: TextStyle(
                                  color: isSeller ? Colors.deepOrange : Colors.black,
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

            // SELLER VIEW
            if (isSeller) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Quán Ăn Của Tôi', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  FilledButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Thêm Quán'),
                    onPressed: _openAddRestaurantDialog,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (_loadingSellerRestaurants)
                const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
              else if (_sellerRestaurants.isEmpty)
                Card(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(Icons.storefront, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        const Text('Bạn chưa tạo quán ăn nào', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Hãy bấm nút "Thêm Quán" để bắt đầu mở quán nhé!',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      ],
                    ),
                  ),
                )
              else
                ..._sellerRestaurants.map((r) => Card(
                      color: Colors.white,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey[200]!),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(r.address ?? 'Chưa rõ địa chỉ', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                            if (r.openTime != null && r.closeTime != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text('🕒 Mở cửa: ${r.openTime} – ${r.closeTime}',
                                    style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                              ),
                            const Divider(height: 18),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.restaurant_menu, size: 16),
                                  label: const Text('Thực Đơn'),
                                  onPressed: () => _openSellerMenuDialog(r),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  tooltip: 'Xóa quán',
                                  onPressed: () => _deleteRestaurant(r),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    )),
            ]
            // USER VIEW: FAVOURITES
            else ...[
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
          ],
        ),
      );
    }

    // ==========================================
    // AUTH FORM (CHƯA ĐĂNG NHẬP)
    // ==========================================
    return Scaffold(
      appBar: AppBar(
        title: Text(_isRegister ? 'Tạo Tài Khoản Khách Hàng' : 'Đăng Nhập Khách Hàng'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Chọn Vai Trò
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'user', label: Text('Thực khách (User)'), icon: Icon(Icons.person)),
              ButtonSegment(value: 'seller', label: Text('Chủ quán (Seller)'), icon: Icon(Icons.store)),
            ],
            selected: {_selectedRole},
            onSelectionChanged: (set) {
              setState(() {
                _selectedRole = set.first;
                _error = null;
              });
            },
          ),
          const SizedBox(height: 14),

          // Chọn Đăng nhập / Đăng ký
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
            if (_selectedRole == 'seller') ...[
              const SizedBox(height: 12),
              TextField(
                controller: _shopNameCtrl,
                decoration: const InputDecoration(labelText: 'Tên cửa hàng/Shop *', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phoneCtrl,
                decoration: const InputDecoration(labelText: 'Số điện thoại', border: OutlineInputBorder()),
              ),
            ],
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
              _selectedRole == 'seller'
                  ? '💡 Chủ quán có thể quản lý danh sách quán ăn, thực đơn món và phân loại danh mục ngay trên app.'
                  : '💡 Thực khách có thể lưu món ăn yêu thích và xem thực đơn từ hàng ngàn quán ăn lân cận.',
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

// ==========================================
// SELLER MENU MANAGEMENT DIALOG
// ==========================================
class _SellerMenuDialog extends StatefulWidget {
  final int sellerId;
  final Restaurant restaurant;
  final ApiService api;

  const _SellerMenuDialog({
    required this.sellerId,
    required this.restaurant,
    required this.api,
  });

  @override
  State<_SellerMenuDialog> createState() => _SellerMenuDialogState();
}

class _SellerMenuDialogState extends State<_SellerMenuDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Category> _categories = [];
  List<Dish> _dishes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final cats = await widget.api.getRestaurantCategories(widget.restaurant.id);
      final dishes = await widget.api.getRestaurantDishes(widget.restaurant.id);
      setState(() {
        _categories = cats;
        _dishes = dishes;
      });
    } catch (_) {}
    setState(() => _loading = false);
  }

  void _openAddCategoryDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thêm Danh Mục Mới'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Tên danh mục *')),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Mô tả')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          FilledButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              await widget.api.createCategory(
                widget.sellerId,
                widget.restaurant.id,
                nameCtrl.text.trim(),
                description: descCtrl.text.trim(),
              );
              _loadData();
            },
            child: const Text('Tạo'),
          ),
        ],
      ),
    );
  }

  void _openAddDishDialog() {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController(text: '35000');
    final ingredientsCtrl = TextEditingController();
    int? selectedCatId = _categories.isNotEmpty ? _categories.first.id : null;
    String selectedMeal = 'all_day';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Thêm Món Ăn Mới'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Tên món ăn *')),
                TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'Giá tiền (VNĐ) *'), keyboardType: TextInputType.number),
                if (_categories.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    initialValue: selectedCatId,
                    decoration: const InputDecoration(labelText: 'Danh mục'),
                    items: _categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                    onChanged: (val) => setDialogState(() => selectedCatId = val),
                  ),
                ],
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedMeal,
                  decoration: const InputDecoration(labelText: 'Bữa ăn'),
                  items: const [
                    DropdownMenuItem(value: 'all_day', child: Text('Cả ngày (all_day)')),
                    DropdownMenuItem(value: 'breakfast', child: Text('Bữa sáng (breakfast)')),
                    DropdownMenuItem(value: 'lunch', child: Text('Bữa trưa (lunch)')),
                    DropdownMenuItem(value: 'dinner', child: Text('Bữa tối (dinner)')),
                    DropdownMenuItem(value: 'snack', child: Text('Ăn vặt (snack)')),
                  ],
                  onChanged: (val) => setDialogState(() => selectedMeal = val ?? 'all_day'),
                ),
                TextField(controller: ingredientsCtrl, decoration: const InputDecoration(labelText: 'Nguyên liệu (phẩy để tách)')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            FilledButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                final ingredientsList = ingredientsCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                await widget.api.createDish(widget.sellerId, widget.restaurant.id, {
                  'name': nameCtrl.text.trim(),
                  'price': double.tryParse(priceCtrl.text) ?? 35000,
                  if (selectedCatId != null) 'category_id': selectedCatId,
                  'meal_type': selectedMeal,
                  'ingredients': ingredientsList,
                });
                _loadData();
              },
              child: const Text('Thêm Món'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: SizedBox(
        width: 600,
        height: 600,
        child: Scaffold(
          appBar: AppBar(
            title: Text('Thực đơn: ${widget.restaurant.name}'),
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Danh Mục'),
                Tab(text: 'Món Ăn'),
              ],
            ),
          ),
          body: _loading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab Danh Mục
                    Scaffold(
                      floatingActionButton: FloatingActionButton(
                        onPressed: _openAddCategoryDialog,
                        child: const Icon(Icons.add),
                      ),
                      body: _categories.isEmpty
                          ? const Center(child: Text('Chưa có danh mục nào'))
                          : ListView.separated(
                              itemCount: _categories.length,
                              separatorBuilder: (_, __) => const Divider(),
                              itemBuilder: (context, index) {
                                final c = _categories[index];
                                return ListTile(
                                  title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: c.description != null ? Text(c.description!) : null,
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () async {
                                      await widget.api.deleteCategory(widget.sellerId, c.id);
                                      _loadData();
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                    // Tab Món Ăn
                    Scaffold(
                      floatingActionButton: FloatingActionButton(
                        onPressed: _openAddDishDialog,
                        child: const Icon(Icons.add),
                      ),
                      body: _dishes.isEmpty
                          ? const Center(child: Text('Chưa có món ăn nào'))
                          : ListView.separated(
                              itemCount: _dishes.length,
                              separatorBuilder: (_, __) => const Divider(),
                              itemBuilder: (context, index) {
                                final d = _dishes[index];
                                return ListTile(
                                  title: Text(d.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('${d.price.toStringAsFixed(0)} đ • ${d.categoryName ?? 'Chung'} • ${d.mealType}'),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () async {
                                      await widget.api.deleteDish(widget.sellerId, d.id);
                                      _loadData();
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
