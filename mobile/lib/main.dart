import 'package:flutter/material.dart';
import 'models/models.dart';
import 'services/api_service.dart';

void main() {
  runApp(const Ptc1App());
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

  void _onLoginSuccess(RoleLoginResponse user) {
    setState(() {
      _currentUser = user;
    });
  }

  void _onLogout() {
    setState(() {
      _currentUser = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      ExploreScreen(api: widget.apiService),
      NearbyScreen(api: widget.apiService),
      GeocodingScreen(api: widget.apiService),
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
// TAB 1: KHÁM PHÁ (EXPLORE)
// ==========================================
class ExploreScreen extends StatefulWidget {
  final ApiService api;
  const ExploreScreen({super.key, required this.api});

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

  void _showDetail(Restaurant r) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                r.name,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (r.address != null) ...[
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 18, color: Colors.deepOrange),
                    const SizedBox(width: 8),
                    Expanded(child: Text(r.address!)),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              if (r.phone != null) ...[
                Row(
                  children: [
                    const Icon(Icons.phone, size: 18, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(r.phone!, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              if (r.openTime != null && r.closeTime != null) ...[
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 18, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text('Giờ mở cửa: ${r.openTime} – ${r.closeTime}',
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              if (r.description != null) ...[
                Text(r.description!, style: TextStyle(color: Colors.grey[700])),
                const SizedBox(height: 8),
              ],
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Toạ độ: ${r.latitude.toStringAsFixed(4)}, ${r.longitude.toStringAsFixed(4)}'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.restaurant_menu),
                      label: const Text('Thực Đơn'),
                      onPressed: () {
                        Navigator.pop(context);
                        _showMenuBottomSheet(r);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Đóng'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
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
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, scrollController) {
            return _RestaurantMenuWidget(api: widget.api, restaurant: r, scrollController: scrollController);
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
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm theo tên quán hoặc địa chỉ...',
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
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Lỗi: $_error', style: const TextStyle(color: Colors.red)),
                              const SizedBox(height: 8),
                              ElevatedButton(onPressed: _loadData, child: const Text('Thử lại')),
                            ],
                          ),
                        )
                      : _filteredList.isEmpty
                          ? const Center(child: Text('Chưa có quán ăn nào'))
                          : ListView.builder(
                              itemCount: _filteredList.length,
                              itemBuilder: (context, index) {
                                final r = _filteredList[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  color: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(color: Colors.grey[200]!),
                                  ),
                                  child: ListTile(
                                    title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(r.address ?? 'Chưa có địa chỉ'),
                                        if (r.openTime != null && r.closeTime != null)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 2),
                                            child: Text('🕒 ${r.openTime} – ${r.closeTime}',
                                                style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                                          ),
                                      ],
                                    ),
                                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                    onTap: () => _showDetail(r),
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
// TAB 2: QUÁN GẦN ĐÂY (NEARBY SPATIAL)
// ==========================================
class NearbyScreen extends StatefulWidget {
  final ApiService api;
  const NearbyScreen({super.key, required this.api});

  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<NearbyScreen> {
  double _lat = 21.0285;
  double _lon = 105.8542;
  double _radiusKm = 5.0;

  List<Restaurant> _nearbyList = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _search();
  }

  Future<void> _search() async {
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
        _nearbyList = list;
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

  void _selectPreset(double lat, double lon) {
    setState(() {
      _lat = lat;
      _lon = lon;
    });
    _search();
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.deepOrange.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_radiusKm.toStringAsFixed(1)} km',
                        style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _radiusKm,
                  min: 1.0,
                  max: 20.0,
                  divisions: 38,
                  activeColor: const Color(0xFFE8590C),
                  onChanged: (val) {
                    setState(() {
                      _radiusKm = val;
                    });
                  },
                  onChangeEnd: (_) => _search(),
                ),
                const SizedBox(height: 8),
                const Text('Toạ độ mẫu:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: [
                    ActionChip(
                      label: const Text('Hồ Gươm (HN)'),
                      onPressed: () => _selectPreset(21.0285, 105.8542),
                    ),
                    ActionChip(
                      label: const Text('Cầu Giấy (HN)'),
                      onPressed: () => _selectPreset(21.0378, 105.7838),
                    ),
                    ActionChip(
                      label: const Text('Quận 1 (HCM)'),
                      onPressed: () => _selectPreset(10.7769, 106.7009),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tìm thấy ${_nearbyList.length} quán',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: _search,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Quét lại'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text('Lỗi: $_error', style: const TextStyle(color: Colors.red)))
                    : _nearbyList.isEmpty
                        ? const Center(child: Text('Không có quán nào trong bán kính này'))
                        : ListView.builder(
                            itemCount: _nearbyList.length,
                            itemBuilder: (context, index) {
                              final r = _nearbyList[index];
                              final distText = r.distanceKm != null
                                  ? (r.distanceKm! < 1
                                      ? '${(r.distanceKm! * 1000).round()} m'
                                      : '${r.distanceKm!.toStringAsFixed(1)} km')
                                  : '';
                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                color: Colors.white,
                                child: ListTile(
                                  title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(r.address ?? 'Toạ độ: ${r.latitude}, ${r.longitude}'),
                                      if (r.openTime != null && r.closeTime != null)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 2),
                                          child: Text('🕒 ${r.openTime} – ${r.closeTime}',
                                              style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                                        ),
                                    ],
                                  ),
                                  trailing: distText.isNotEmpty
                                      ? Chip(
                                          label: Text(distText, style: const TextStyle(fontSize: 12)),
                                          backgroundColor: Colors.deepOrange.shade50,
                                        )
                                      : null,
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
  const GeocodingScreen({super.key, required this.api});

  @override
  State<GeocodingScreen> createState() => _GeocodingScreenState();
}

class _GeocodingScreenState extends State<GeocodingScreen> {
  final _searchCtrl = TextEditingController();
  List<GeocodePlace> _places = [];
  bool _searching = false;
  String? _addressResult;
  bool _reversing = false;

  Future<void> _searchPlace() async {
    final text = _searchCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _searching = true;
      _places = [];
    });
    try {
      final res = await widget.api.searchMap(text);
      setState(() {
        _places = res;
      });
    } catch (_) {}
    setState(() {
      _searching = false;
    });
  }

  Future<void> _reverseCoord(double lat, double lon) async {
    setState(() {
      _reversing = true;
      _addressResult = null;
    });
    try {
      final addr = await widget.api.reverseMap(lat, lon);
      setState(() {
        _addressResult = addr;
      });
    } catch (_) {}
    setState(() {
      _reversing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bản Đồ & Geocoding OSM', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Tìm toạ độ từ địa chỉ (Forward Geocoding):', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Nhập địa chỉ (VD: Hồ Gươm, Ba Đình)...',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _searching ? null : _searchPlace,
                child: _searching
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Tìm'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_places.isNotEmpty)
            ..._places.map((p) => Card(
                  color: Colors.white,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(p.displayName, style: const TextStyle(fontSize: 14)),
                    subtitle: Text('Lat: ${p.latitude.toStringAsFixed(4)}, Lon: ${p.longitude.toStringAsFixed(4)}'),
                    trailing: const Icon(Icons.touch_app, size: 16),
                    onTap: () => _reverseCoord(p.latitude, p.longitude),
                  ),
                )),
          const Divider(height: 32),
          const Text('Tra cứu ngược toạ độ (Reverse Geocoding):', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  const Text('Bấm vào địa điểm bên trên hoặc thử toạ độ mẫu 21.0285, 105.8542:'),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: _reversing ? null : () => _reverseCoord(21.0285, 105.8542),
                    child: _reversing
                        ? const CircularProgressIndicator()
                        : const Text('Đổi toạ độ Hồ Gươm sang địa chỉ'),
                  ),
                  if (_addressResult != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      color: Colors.grey[100],
                      child: Text('📍 $_addressResult', style: const TextStyle(fontWeight: FontWeight.w500)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// TAB 4: TÀI KHOẢN & SELLER DASHBOARD
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

  // Favourites list
  List<FavouriteDish> _favourites = [];
  bool _loadingFavourites = false;

  @override
  void initState() {
    super.initState();
    if (widget.currentUser != null) {
      _loadFavourites();
    }
  }

  @override
  void didUpdateWidget(covariant AccountScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentUser?.id != oldWidget.currentUser?.id && widget.currentUser != null) {
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

  Future<void> _handleAuth() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      RoleLoginResponse res;
      if (!_isRegister) {
        // Login as User
        res = await widget.api.loginUser(_emailCtrl.text.trim(), _passwordCtrl.text);
      } else {
        // Register as User
        res = await widget.api.registerUser(
          _emailCtrl.text.trim(),
          _passwordCtrl.text,
          _nameCtrl.text.trim(),
        );
      }

      widget.onLoginSuccess(res);
      _loadFavourites();
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
          title: const Text('Tài Khoản Của Tôi'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: widget.onLogout,
              tooltip: 'Đăng xuất',
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.black,
                      child: Text(
                        (user.fullName?.isNotEmpty == true
                                ? user.fullName![0]
                                : user.email[0])
                            .toUpperCase(),
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.fullName ?? 'Thực khách',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(user.email,
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 13)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEEEEE),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.black),
                            ),
                            child: const Text('Thực Khách (User)',
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
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
                const Text('Món Ăn Yêu Thích',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                if (_loadingFavourites)
                  const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ),
            const SizedBox(height: 8),
            if (_loadingFavourites)
              const Center(
                  child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ))
            else if (_favourites.isEmpty)
              Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Icon(Icons.favorite_border,
                          size: 44, color: Colors.black54),
                      const SizedBox(height: 8),
                      Text('Bạn chưa có món ăn yêu thích nào.',
                          style: TextStyle(color: Colors.grey[700])),
                      const SizedBox(height: 4),
                      Text(
                          'Hãy khám phá quán ăn và thêm các món ngon vào danh sách nhé!',
                          textAlign: TextAlign.center,
                          style:
                              TextStyle(color: Colors.grey[500], fontSize: 12)),
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
                      child: Text('M', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                    ),
                    title: Text(dish?.name ?? 'Món #${fav.dishId}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: dish != null
                        ? Text(
                            '${dish.price.toStringAsFixed(0)} đ • ${dish.mealType}')
                        : null,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.black, size: 20),
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

    // Auth Form (Not logged in)
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
            const SizedBox(height: 16),
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
              '💡 Quản trị viên và Chủ quán vui lòng truy cập\nCổng Web Quản Lý (Vite/Vue) trên máy tính.',
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
// CLIENT MENU BOTTOM SHEET WIDGET
// ==========================================
class _RestaurantMenuWidget extends StatefulWidget {
  final ApiService api;
  final Restaurant restaurant;
  final ScrollController scrollController;

  const _RestaurantMenuWidget({
    required this.api,
    required this.restaurant,
    required this.scrollController,
  });

  @override
  State<_RestaurantMenuWidget> createState() => _RestaurantMenuWidgetState();
}

class _RestaurantMenuWidgetState extends State<_RestaurantMenuWidget> {
  List<Category> _categories = [];
  List<Dish> _dishes = [];
  int? _selectedCategoryId;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMenu();
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
                                          ...d.tags.map((t) => Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                    color: Colors.orange[50], borderRadius: BorderRadius.circular(4)),
                                                child: Text('#$t',
                                                    style: const TextStyle(fontSize: 10, color: Colors.deepOrange)),
                                              )),
                                        ],
                                      ),
                                    ],
                                  ),
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
  final ApiService api;
  final int sellerId;
  final Restaurant restaurant;

  const _SellerMenuDialog({
    required this.api,
    required this.sellerId,
    required this.restaurant,
  });

  @override
  State<_SellerMenuDialog> createState() => _SellerMenuDialogState();
}

class _SellerMenuDialogState extends State<_SellerMenuDialog> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<Category> _categories = [];
  List<Dish> _dishes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thêm nhóm danh mục'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: 'Tên danh mục (VD: Cơm, Khai vị)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Huỷ')),
          FilledButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              await widget.api.createCategory(widget.sellerId, widget.restaurant.id, nameCtrl.text.trim());
              _loadData();
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }

  void _openAddDishDialog() {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController(text: '35000');
    final tagsCtrl = TextEditingController();
    int? selectedCatId = _categories.isNotEmpty ? _categories.first.id : null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Thêm món ăn mới'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Tên món *')),
                TextField(
                    controller: priceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Giá bán (VNĐ) *')),
                if (_categories.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: selectedCatId,
                    decoration: const InputDecoration(labelText: 'Danh mục'),
                    items: _categories
                        .map((c) => DropdownMenuItem<int>(value: c.id, child: Text(c.name)))
                        .toList(),
                    onChanged: (val) => setDialogState(() => selectedCatId = val),
                  ),

                ],
                TextField(controller: tagsCtrl, decoration: const InputDecoration(labelText: 'Tags (phẩy để tách)')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Huỷ')),
            FilledButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                final tagsList = tagsCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                await widget.api.createDish(widget.sellerId, widget.restaurant.id, {
                  'name': nameCtrl.text.trim(),
                  'price': double.tryParse(priceCtrl.text) ?? 35000,
                  if (selectedCatId != null) 'category_id': selectedCatId,
                  'tags': tagsList,
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 450,
        height: 520,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text('Thực đơn: ${widget.restaurant.name}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        overflow: TextOverflow.ellipsis),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            TabBar(
              controller: _tabCtrl,
              tabs: [
                Tab(text: 'Món ăn (${_dishes.length})'),
                Tab(text: 'Danh mục (${_categories.length})'),
              ],
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabCtrl,
                      children: [
                        // Tab 1: Dishes
                        Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: FilledButton.icon(
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('Thêm Món Ăn'),
                                onPressed: _openAddDishDialog,
                              ),
                            ),
                            Expanded(
                              child: _dishes.isEmpty
                                  ? const Center(child: Text('Chưa có món ăn nào'))
                                  : ListView.builder(
                                      itemCount: _dishes.length,
                                      itemBuilder: (ctx, i) {
                                        final d = _dishes[i];
                                        return ListTile(
                                          title: Text(d.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                          subtitle: Text(
                                              '${d.price.toStringAsFixed(0)} đ • ${d.categoryName ?? "Chưa phân loại"}'),
                                          trailing: IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
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
                        // Tab 2: Categories
                        Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: FilledButton.icon(
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('Thêm Danh Mục'),
                                onPressed: _openAddCategoryDialog,
                              ),
                            ),
                            Expanded(
                              child: _categories.isEmpty
                                  ? const Center(child: Text('Chưa có nhóm danh mục nào'))
                                  : ListView.builder(
                                      itemCount: _categories.length,
                                      itemBuilder: (ctx, i) {
                                        final c = _categories[i];
                                        return ListTile(
                                          title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                          subtitle: Text('Thứ tự: ${c.displayOrder} • ${c.dishCount} món'),
                                          trailing: IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                            onPressed: () async {
                                              await widget.api.deleteCategory(widget.sellerId, c.id);
                                              _loadData();
                                            },
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ],
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

