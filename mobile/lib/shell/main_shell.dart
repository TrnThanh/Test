import 'package:flutter/material.dart';
import '../models/models.dart';
import '../screens/account_screen.dart';
import '../screens/explore_screen.dart';
import '../screens/favourites_screen.dart';
import '../screens/map_screen.dart';
import '../services/api_service.dart';
import '../widgets/auth_form_modal.dart';
import '../widgets/onboarding_survey_dialog.dart';
import '../widgets/welcome_category_dialog.dart';

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
  Restaurant? _targetRestaurant;

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
        onOpenCategoryPicker: _showInitialCategoryPicker,
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
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedItemColor: const Color(0xFF1B3B2B),
          unselectedItemColor: const Color(0xFF6E7A73),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Trang chủ',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined),
              activeIcon: Icon(Icons.map),
              label: 'Khám phá',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_outline),
              activeIcon: Icon(Icons.favorite),
              label: 'Yêu thích',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Tài khoản',
            ),
          ],
        ),
      ),
    );
  }
}

