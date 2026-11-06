import 'package:flutter/material.dart';
import '../l10n/app_language.dart';
import '../models/models.dart';
import '../screens/account_screen.dart';
import '../screens/explore_screen.dart';
import '../screens/favourites_screen.dart';
import '../screens/map_screen.dart';
import '../services/api_service.dart';
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

  final ScrollController _exploreScrollController = ScrollController();
  final ScrollController _favouritesScrollController = ScrollController();
  final ScrollController _accountScrollController = ScrollController();

  // Hỗ trợ chuyển toạ độ từ Tab Bản đồ sang Tab Gần đây
  double? _targetLat;
  double? _targetLon;
  Restaurant? _targetRestaurant;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
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
      _scrollToTop(_exploreScrollController);
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => AuthFormModal(
        api: widget.apiService,
        initialRegister: isRegister,
        onSuccess: (res) {
          _onLoginSuccess(res);
          onSuccess?.call();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      ExploreScreen(
        key: ValueKey(_currentUser?.id),
        api: widget.apiService,
        currentUser: _currentUser,
        initialCategory: _selectedCategory,
        scrollController: _exploreScrollController,
        onRequireLogin: () {
          _openAuthModal(isRegister: false);
        },
        onNavigateToMap: (lat, lon, [restaurant]) {
          setState(() {
            _targetLat = lat;
            _targetLon = lon;
            _targetRestaurant = restaurant;
            _currentIndex = 1;
          });
        },
        onNavigateToAccount: () {
          setState(() => _currentIndex = 3);
        },
      ),
      MapScreen(
        api: widget.apiService,
        initialLat: _targetLat,
        initialLon: _targetLon,
        initialRestaurant: _targetRestaurant,
        currentUser: _currentUser,
        onRequireLogin: () {
          _openAuthModal(isRegister: false);
        },
      ),
      FavouritesScreen(
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
      AccountScreen(
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
            top: BorderSide(color: Color(0xFFF1F5F9), width: 1.2),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedItemColor: const Color(0xFF1B3B2B),
          unselectedItemColor: const Color(0xFF6E7A73),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined),
              activeIcon: const Icon(Icons.home),
              label: tr('tab_home'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.map_outlined),
              activeIcon: const Icon(Icons.map),
              label: tr('tab_map'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.favorite_outline),
              activeIcon: const Icon(Icons.favorite),
              label: tr('tab_favourites'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline),
              activeIcon: const Icon(Icons.person),
              label: tr('tab_account'),
            ),
          ],
        ),
      ),
    );
  }
}
