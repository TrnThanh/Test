import 'package:flutter/material.dart';
import '../l10n/app_language.dart';
import '../models/models.dart';
import '../screens/account_screen.dart';
import '../screens/explore_screen.dart';
import '../screens/favourites_screen.dart';
import '../screens/home_screen.dart';
import '../screens/map_screen.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/auth_form_modal.dart';

class MainShell extends StatefulWidget {
  final ApiService apiService;

  const MainShell({
    super.key,
    required this.apiService,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  RoleLoginResponse? _currentUser;
  String? _selectedCategory;

  final ScrollController _homeScrollController = ScrollController();
  final ScrollController _exploreScrollController = ScrollController();
  final ScrollController _favouritesScrollController = ScrollController();
  final ScrollController _accountScrollController = ScrollController();

  // Hỗ trợ chuyển toạ độ từ Tab Bản đồ sang Tab Gần đây
  double? _targetLat;
  double? _targetLon;
  Restaurant? _targetRestaurant;

  @override
  void dispose() {
    _homeScrollController.dispose();
    _exploreScrollController.dispose();
    _favouritesScrollController.dispose();
    _accountScrollController.dispose();
    super.dispose();
  }

  void _scrollToTop(ScrollController controller) {
    if (controller.hasClients && controller.offset > 0) {
      controller.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _onTabTapped(int index) {
    if (index == 0) {
      _scrollToTop(_homeScrollController);
    } else if (index == 2) {
      _scrollToTop(_favouritesScrollController);
    } else if (index == 3) {
      _scrollToTop(_accountScrollController);
    }
    setState(() {
      _currentIndex = index;
    });
  }

  void _onLoginSuccess(RoleLoginResponse user) {
    setState(() {
      _currentUser = user;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${tr('welcome_back')} ${user.fullName ?? user.email}!'),
        backgroundColor: Colors.black,
      ),
    );
  }

  void _onLogout() {
    setState(() {
      _currentUser = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(tr('logged_out'))),
    );
  }

  void _openAuthModal({bool isRegister = false, VoidCallback? onSuccess}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Stack(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(ctx).pop(),
            child: const SizedBox.expand(),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: AuthFormModal(
              api: widget.apiService,
              initialRegister: isRegister,
              onSuccess: (res) {
                _onLoginSuccess(res);
                onSuccess?.call();
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      // TAB 0: Trang chủ (Screen 2)
      HomeScreen(
        key: ValueKey('home_${_currentUser?.id}'),
        api: widget.apiService,
        currentUser: _currentUser,
        scrollController: _homeScrollController,
        onRequireLogin: () => _openAuthModal(isRegister: false),
        onNavigateToExplore: () => setState(() => _currentIndex = 1),
        onNavigateToMap: (lat, lon, [restaurant]) {
          setState(() {
            _targetLat = lat;
            _targetLon = lon;
            _targetRestaurant = restaurant;
            _currentIndex = 1;
          });
        },
        onNavigateToAccount: () => setState(() => _currentIndex = 3),
      ),

      // TAB 1: Bản đồ (Screen 3)
      MapScreen(
        key: ValueKey('map_${_currentUser?.id}'),
        api: widget.apiService,
        initialLat: _targetLat,
        initialLon: _targetLon,
        initialRestaurant: _targetRestaurant,
        currentUser: _currentUser,
        onRequireLogin: () {
          _openAuthModal(isRegister: false);
        },
      ),

      // TAB 2: Đã lưu (Screen 7)
      FavouritesScreen(
        key: ValueKey('fav_${_currentUser?.id}'),
        api: widget.apiService,
        currentUser: _currentUser,
        scrollController: _favouritesScrollController,
        onRequireLogin: () {
          _openAuthModal(isRegister: false);
        },
        onExplore: () {
          setState(() => _currentIndex = 0);
        },
      ),

      // TAB 3: Cá nhân (Screen 8)
      AccountScreen(
        key: ValueKey('acc_${_currentUser?.id}'),
        api: widget.apiService,
        currentUser: _currentUser,
        scrollController: _accountScrollController,
        onLoginSuccess: _onLoginSuccess,
        onLogout: _onLogout,
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: tabs,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Color(0xFFE2EBE9), width: 1.0),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 56,
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: _onTabTapped,
              backgroundColor: Colors.white,
              type: BottomNavigationBarType.fixed,
              elevation: 0,
              selectedItemColor: kPrimaryTeal,
              unselectedItemColor: const Color(0xFF64748B),
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
              items: [
                BottomNavigationBarItem(
                  icon: const Icon(Icons.home_outlined),
                  activeIcon: const Icon(Icons.home_rounded),
                  label: tr('tab_home'),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.map_outlined),
                  activeIcon: const Icon(Icons.map_rounded),
                  label: tr('tab_map'),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.bookmark_outline_rounded),
                  activeIcon: const Icon(Icons.bookmark_rounded),
                  label: tr('tab_favourites'),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.person_outline_rounded),
                  activeIcon: const Icon(Icons.person_rounded),
                  label: tr('tab_account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
