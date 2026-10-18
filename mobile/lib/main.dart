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
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE8590C),
          primary: const Color(0xFFE8590C),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
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
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Đóng'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🍜 PTC1 Khám Phá Quán Ăn', style: TextStyle(fontWeight: FontWeight.bold)),
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
                                    subtitle: Text(r.address ?? 'Chưa có địa chỉ'),
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
        title: const Text('📍 Quán Ăn Lân Cận (PostGIS)', style: TextStyle(fontWeight: FontWeight.bold)),
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
                                  subtitle: Text(r.address ?? 'Toạ độ: ${r.latitude}, ${r.longitude}'),
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
        title: const Text('🗺️ Bản Đồ & Geocoding OSM', style: TextStyle(fontWeight: FontWeight.bold)),
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
  String _selectedRole = 'user'; // 'user' or 'seller'

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _shopNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  bool _loading = false;
  String? _error;

  // Seller Dashboard
  List<Restaurant> _sellerRestaurants = [];
  bool _loadingSeller = false;

  @override
  void didUpdateWidget(covariant AccountScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentUser?.role == 'seller' && oldWidget.currentUser?.id != widget.currentUser?.id) {
      _loadSellerRestaurants();
    }
  }

  Future<void> _loadSellerRestaurants() async {
    if (widget.currentUser?.role != 'seller') return;
    setState(() => _loadingSeller = true);
    try {
      final list = await widget.api.getSellerRestaurants(widget.currentUser!.id);
      setState(() => _sellerRestaurants = list);
    } catch (_) {}
    setState(() => _loadingSeller = false);
  }

  Future<void> _handleAuth() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      RoleLoginResponse res;
      if (!_isRegister) {
        // Login
        if (_selectedRole == 'user') {
          res = await widget.api.loginUser(_emailCtrl.text.trim(), _passwordCtrl.text);
        } else {
          res = await widget.api.loginSeller(_emailCtrl.text.trim(), _passwordCtrl.text);
        }
      } else {
        // Register
        if (_selectedRole == 'user') {
          res = await widget.api.registerUser(
            _emailCtrl.text.trim(),
            _passwordCtrl.text,
            _nameCtrl.text.trim(),
          );
        } else {
          res = await widget.api.registerSeller(
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
            shopName: _shopNameCtrl.text.trim(),
            fullName: _nameCtrl.text.trim(),
            phone: _phoneCtrl.text.trim(),
          );
        }
      }

      widget.onLoginSuccess(res);
      if (res.role == 'seller') {
        _loadSellerRestaurants();
      }
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

  void _openAddRestaurantDialog([Restaurant? editItem]) {
    final nameCtrl = TextEditingController(text: editItem?.name ?? '');
    final addrCtrl = TextEditingController(text: editItem?.address ?? '');
    final phoneCtrl = TextEditingController(text: editItem?.phone ?? '');
    final descCtrl = TextEditingController(text: editItem?.description ?? '');
    final latCtrl = TextEditingController(text: editItem != null ? editItem.latitude.toString() : '21.0285');
    final lonCtrl = TextEditingController(text: editItem != null ? editItem.longitude.toString() : '105.8542');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(editItem == null ? 'Thêm Quán Ăn Mới' : 'Sửa Quán Ăn'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Tên quán *')),
                TextField(controller: addrCtrl, decoration: const InputDecoration(labelText: 'Địa chỉ')),
                TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Hotline')),
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Mô tả')),
                TextField(controller: latCtrl, decoration: const InputDecoration(labelText: 'Vĩ độ (Lat) *')),
                TextField(controller: lonCtrl, decoration: const InputDecoration(labelText: 'Kinh độ (Lon) *')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Huỷ')),
            FilledButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final sellerId = widget.currentUser!.id;
                final lat = double.tryParse(latCtrl.text) ?? 21.0285;
                final lon = double.tryParse(lonCtrl.text) ?? 105.8542;

                if (editItem == null) {
                  await widget.api.createSellerRestaurant(
                    sellerId,
                    name: nameCtrl.text.trim(),
                    latitude: lat,
                    longitude: lon,
                    address: addrCtrl.text.trim(),
                    phone: phoneCtrl.text.trim(),
                    description: descCtrl.text.trim(),
                  );
                } else {
                  await widget.api.updateSellerRestaurant(
                    sellerId,
                    editItem.id,
                    name: nameCtrl.text.trim(),
                    latitude: lat,
                    longitude: lon,
                    address: addrCtrl.text.trim(),
                    phone: phoneCtrl.text.trim(),
                    description: descCtrl.text.trim(),
                  );
                }
                _loadSellerRestaurants();
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.currentUser != null) {
      final user = widget.currentUser!;
      final isSeller = user.role == 'seller';

      return Scaffold(
        appBar: AppBar(
          title: Text(isSeller ? '🏪 Quán Của Tôi (Seller)' : '👤 Tài Khoản'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: widget.onLogout,
              tooltip: 'Đăng xuất',
            ),
          ],
        ),
        floatingActionButton: isSeller
            ? FloatingActionButton.extended(
                onPressed: () => _openAddRestaurantDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Thêm Quán'),
              )
            : null,
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Xin chào, ${user.fullName ?? user.email}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Vai trò: ${user.role.toUpperCase()}',
                        style: TextStyle(color: isSeller ? Colors.deepOrange : Colors.blue, fontWeight: FontWeight.w600)),
                    if (user.shopName != null) ...[
                      const SizedBox(height: 4),
                      Text('Tên Shop: ${user.shopName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ],
                ),
              ),
            ),
            if (isSeller) ...[
              const SizedBox(height: 16),
              const Text('Danh sách quán của bạn:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (_loadingSeller)
                const Center(child: CircularProgressIndicator())
              else if (_sellerRestaurants.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Bạn chưa có quán ăn nào. Hãy bấm "Thêm Quán"!'),
                )
              else
                ..._sellerRestaurants.map((r) => Card(
                      color: Colors.white,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(r.address ?? 'Chưa có địa chỉ'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () => _openAddRestaurantDialog(r),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                              onPressed: () async {
                                final ok = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Xoá quán?'),
                                    content: Text('Bạn có chắc muốn xoá "${r.name}"?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
                                      FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xoá')),
                                    ],
                                  ),
                                );
                                if (ok == true) {
                                  await widget.api.deleteSellerRestaurant(user.id, r.id);
                                  _loadSellerRestaurants();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    )),
            ],
          ],
        ),
      );
    }

    // Auth Form (Not logged in)
    return Scaffold(
      appBar: AppBar(
        title: Text(_isRegister ? 'Tạo Tài Khoản Mới' : 'Đăng Nhập'),
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
          const SizedBox(height: 16),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'user', label: Text('👤 Thực khách')),
              ButtonSegment(value: 'seller', label: Text('🏪 Chủ quán')),
            ],
            selected: {_selectedRole},
            onSelectionChanged: (set) {
              setState(() {
                _selectedRole = set.first;
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
        ],
      ),
    );
  }
}
