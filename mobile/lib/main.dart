import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
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
        useMaterial3: true,
        scaffoldBackgroundColor: kScaffoldBg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: kPrimaryGreen,
          primary: kPrimaryGreen,
          surface: Colors.white,
        ),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          foregroundColor: kTextDark,
          titleTextStyle: TextStyle(
            color: kTextDark,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
          iconTheme: IconThemeData(color: kTextDark),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: kPrimaryGreen,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: kPrimaryGreen,
            side: const BorderSide(color: kPrimaryGreen),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kBorderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kBorderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kPrimaryGreen, width: 1.8),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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

  void _openAuthModal({bool isRegister = false, VoidCallback? onSuccess}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _AuthFormModal(
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
        api: widget.apiService,
        currentUser: _currentUser,
        initialCategory: _selectedCategory,
        onOpenCategoryPicker: _showInitialCategoryPicker,
        onRequireLogin: () {
          _openAuthModal(isRegister: false);
        },
        onNavigateToMap: (lat, lon) {
          setState(() {
            _targetLat = lat;
            _targetLon = lon;
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

// ==========================================
// TAB 1: KHÁM PHÁ (EXPLORE - GUEST & USER)
// ==========================================
const Color kPrimaryGreen = Color(0xFF005930);
const Color kLightGreen = Color(0xFFE8F5E9);
const Color kSuperLightGreen = Color(0xFFF0FDF4);
const Color kScaffoldBg = Color(0xFFF8F9FA);
const Color kBorderColor = Color(0xFFE2E8F0);
const Color kTextDark = Color(0xFF0F172A);
const Color kTextMuted = Color(0xFF64748B);


const Color kForestGreen = Color(0xFF1B3B2B);
const Color kLimeGreen = Color(0xFF8CE32C);
const Color kWarmCreamBg = Color(0xFFFBF9F4);
const Color kLightMint = Color(0xFFEBF3EC);
const Color kSunYellow = Color(0xFFFFB800);
const Color kFlameBg = Color(0xFFFFF1E8);
const Color kTextTitle = Color(0xFF112319);
const Color kTextSub = Color(0xFF6E7A73);

/// Painter vẽ các tia phẩy năng động (Playful Lime Sparks)
class SparkPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  const SparkPainter({this.color = const Color(0xFF8CE32C), this.strokeWidth = 2.4});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final cx = size.width * 0.5;
    final cy = size.height;

    // Tia trái
    canvas.drawLine(
      Offset(cx - size.width * 0.35, cy - size.height * 0.25),
      Offset(cx - size.width * 0.5, cy - size.height * 0.9),
      paint,
    );
    // Tia giữa
    canvas.drawLine(
      Offset(cx, cy - size.height * 0.3),
      Offset(cx, cy - size.height * 1.0),
      paint,
    );
    // Tia phải
    canvas.drawLine(
      Offset(cx + size.width * 0.35, cy - size.height * 0.25),
      Offset(cx + size.width * 0.5, cy - size.height * 0.9),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant SparkPainter oldDelegate) => false;
}

class SparkBurst extends StatelessWidget {
  final double width;
  final double height;
  final Color color;
  final double strokeWidth;

  const SparkBurst({
    super.key,
    this.width = 18,
    this.height = 14,
    this.color = const Color(0xFF8CE32C),
    this.strokeWidth = 2.4,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: SparkPainter(color: color, strokeWidth: strokeWidth),
    );
  }
}

class WeatherVisualConfig {
  final IconData? icon;
  final Widget? customWidget;
  final Color iconColor;
  final List<Color> iconBgColors;
  final Color iconBorderColor;
  final Color iconShadowColor;
  final bool isNight;

  const WeatherVisualConfig({
    this.icon,
    this.customWidget,
    required this.iconColor,
    required this.iconBgColors,
    required this.iconBorderColor,
    required this.iconShadowColor,
    required this.isNight,
  });
}

/// Widget vẽ vầng trăng khuyết màu vàng óng ánh (Golden Crescent Moon) chuẩn xác và tuyệt đẹp
class GoldenMoonWidget extends StatelessWidget {
  final double size;

  const GoldenMoonWidget({super.key, this.size = 26});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GoldenMoonPainter(),
      ),
    );
  }
}

class _GoldenMoonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Vầng trăng khuyết màu vàng óng ánh béo tròn, đầy đặn với gradient vàng cam ấm áp
    final moonPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFEA7A), // Vàng chanh sáng rực rỡ
          Color(0xFFFFB800), // Vàng óng đậm đà
          Color(0xFFF57C00), // Cam ánh vàng đậm ở mép
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    final center = Offset(w * 0.48, h * 0.50);
    final radius = w * 0.43;

    // Vòng tròn ngoài tròn trịa, đầy đặn
    final outerPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));

    // Vòng tròn trong khoét vừa phải để thân trăng béo tròn, phúc hậu, đầy đặn
    final innerCenter = Offset(center.dx + radius * 0.62, center.dy - radius * 0.28);
    final innerRadius = radius * 0.85;

    final innerPath = Path()
      ..addOval(Rect.fromCircle(center: innerCenter, radius: innerRadius));

    final moonPath = Path.combine(PathOperation.difference, outerPath, innerPath);

    // Hào quang vàng ấm áp tỏa sáng quanh vầng trăng
    final glowPaint = Paint()
      ..color = const Color(0xFFFFB800).withAlpha(95)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
    canvas.drawPath(moonPath, glowPaint);

    // Vẽ thân trăng vàng đầy đặn
    canvas.drawPath(moonPath, moonPaint);

    // Ngôi sao nhỏ 4 cánh lấp lánh bên cạnh vầng trăng
    final starPaint = Paint()
      ..color = const Color(0xFFFFF9C4)
      ..style = PaintingStyle.fill;

    _drawStar(canvas, Offset(w * 0.80, h * 0.36), 2.2, starPaint);
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    path.moveTo(center.dx, center.dy - radius);
    path.quadraticBezierTo(center.dx, center.dy, center.dx + radius, center.dy);
    path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + radius);
    path.quadraticBezierTo(center.dx, center.dy, center.dx - radius, center.dy);
    path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - radius);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _GoldenMoonPainter oldDelegate) => false;
}

/// Painter vẽ các ngọn đồi và tán lá minh hoạ trên thẻ Thời tiết (thay đổi linh hoạt ngày và đêm)
class WeatherLandscapePainter extends CustomPainter {
  final bool isNight;

  const WeatherLandscapePainter({this.isNight = false});

  @override
  void paint(Canvas canvas, Size size) {
    if (isNight) {
      // Ban đêm: Không vẽ mặt trăng ở góc phải theo yêu cầu của người dùng,
      // chỉ vẽ các ngọn đồi và tán lá đêm nhẹ nhàng, tinh tế
      final hillPaint1 = Paint()
        ..color = const Color(0xFFE8EEF5)
        ..style = PaintingStyle.fill;
      final hillPaint2 = Paint()
        ..color = const Color(0xFFD6E2F0)
        ..style = PaintingStyle.fill;
      final leafPaint = Paint()
        ..color = const Color(0xFF3B566E).withAlpha(200)
        ..style = PaintingStyle.fill;

      final path1 = Path();
      path1.moveTo(0, size.height);
      path1.quadraticBezierTo(size.width * 0.35, size.height * 0.25, size.width, size.height * 0.45);
      path1.lineTo(size.width, size.height);
      path1.close();
      canvas.drawPath(path1, hillPaint1);

      final path2 = Path();
      path2.moveTo(size.width * 0.15, size.height);
      path2.quadraticBezierTo(size.width * 0.55, size.height * 0.5, size.width, size.height * 0.65);
      path2.lineTo(size.width, size.height);
      path2.close();
      canvas.drawPath(path2, hillPaint2);

      final leafPath = Path();
      leafPath.moveTo(size.width, size.height);
      leafPath.quadraticBezierTo(size.width * 0.5, size.height * 0.75, size.width * 0.75, size.height * 0.55);
      leafPath.quadraticBezierTo(size.width * 0.9, size.height * 0.8, size.width, size.height);
      canvas.drawPath(leafPath, leafPaint);
    } else {
      // Vòng hào quang nắng nhẹ mờ ở góc trên phải ban ngày
      final sunGlow = Paint()
        ..color = const Color(0xFFFFE8A3).withAlpha(130)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(size.width * 0.82, size.height * 0.22), 24, sunGlow);

      final hillPaint1 = Paint()
        ..color = const Color(0xFFEAF5EC)
        ..style = PaintingStyle.fill;
      final hillPaint2 = Paint()
        ..color = const Color(0xFFD7ECDC)
        ..style = PaintingStyle.fill;
      final leafPaint = Paint()
        ..color = const Color(0xFF4A7C59).withAlpha(220)
        ..style = PaintingStyle.fill;

      final path1 = Path();
      path1.moveTo(0, size.height);
      path1.quadraticBezierTo(size.width * 0.35, size.height * 0.25, size.width, size.height * 0.45);
      path1.lineTo(size.width, size.height);
      path1.close();
      canvas.drawPath(path1, hillPaint1);

      final path2 = Path();
      path2.moveTo(size.width * 0.15, size.height);
      path2.quadraticBezierTo(size.width * 0.55, size.height * 0.5, size.width, size.height * 0.65);
      path2.lineTo(size.width, size.height);
      path2.close();
      canvas.drawPath(path2, hillPaint2);

      final leafPath = Path();
      leafPath.moveTo(size.width, size.height);
      leafPath.quadraticBezierTo(size.width * 0.5, size.height * 0.75, size.width * 0.75, size.height * 0.55);
      leafPath.quadraticBezierTo(size.width * 0.9, size.height * 0.8, size.width, size.height);
      canvas.drawPath(leafPath, leafPaint);
    }
  }

  @override
  bool shouldRepaint(covariant WeatherLandscapePainter oldDelegate) => oldDelegate.isNight != isNight;
}

/// Painter vẽ tán lá trang trí góc trên phải màn hình
class TopRightLeavesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p1 = Paint()..color = const Color(0xFF8CE32C).withAlpha(180)..style = PaintingStyle.fill;
    final p2 = Paint()..color = const Color(0xFF4A7C59).withAlpha(190)..style = PaintingStyle.fill;

    final path1 = Path();
    path1.moveTo(size.width, size.height * 0.15);
    path1.quadraticBezierTo(size.width * 0.25, size.height * 0.25, size.width * 0.45, size.height * 0.65);
    path1.quadraticBezierTo(size.width * 0.85, size.height * 0.5, size.width, size.height * 0.15);
    canvas.drawPath(path1, p1);

    final path2 = Path();
    path2.moveTo(size.width, size.height * 0.6);
    path2.quadraticBezierTo(size.width * 0.5, size.height * 0.7, size.width * 0.65, size.height * 0.95);
    path2.quadraticBezierTo(size.width * 0.9, size.height * 0.85, size.width, size.height * 0.6);
    canvas.drawPath(path2, p2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ExploreScreen extends StatefulWidget {
  final ApiService api;
  final RoleLoginResponse? currentUser;
  final VoidCallback onRequireLogin;
  final String? initialCategory;
  final VoidCallback? onOpenCategoryPicker;
  final void Function(double lat, double lon)? onNavigateToMap;
  final VoidCallback? onNavigateToAccount;

  const ExploreScreen({
    super.key,
    required this.api,
    this.currentUser,
    required this.onRequireLogin,
    this.initialCategory,
    this.onOpenCategoryPicker,
    this.onNavigateToMap,
    this.onNavigateToAccount,
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
  String _selectedCity = 'Hà Nội';

  CurrentWeather? _currentWeather;


  final List<String> _categories = const [
    'Tất cả',
    'Phở',
    'Bún',
    'Cơm',
    'Bánh mì',
    'Ăn vặt',
    'Đồ uống',
    'Lẩu & Nướng',
  ];

  @override
  void initState() {
    super.initState();
    _currentCategory = widget.initialCategory;
    _loadData();
    _loadWeatherAndLocation();
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

  String _resolveToCityName(String? raw, {double? lat, double? lon}) {
    // 1. Kiểm tra toạ độ địa lý nếu có
    if (lat != null && lon != null) {
      if (lat >= 20.5 && lat <= 21.6 && lon >= 105.2 && lon <= 106.3) {
        return 'Hà Nội';
      } else if (lat >= 10.3 && lat <= 11.3 && lon >= 106.2 && lon <= 107.2) {
        return 'TP. Hồ Chí Minh';
      } else if (lat >= 15.8 && lat <= 16.3 && lon >= 107.8 && lon <= 108.6) {
        return 'Đà Nẵng';
      } else if (lat >= 20.6 && lat <= 21.1 && lon >= 106.4 && lon <= 107.1) {
        return 'Hải Phòng';
      } else if (lat >= 9.8 && lat <= 10.4 && lon >= 105.3 && lon <= 106.0) {
        return 'Cần Thơ';
      }
    }

    if (raw == null || raw.trim().isEmpty) return 'Hà Nội';
    final lower = raw.toLowerCase().trim();

    // 2. Tra cứu theo từ khoá thành phố / quận huyện
    if (lower.contains('hà nội') ||
        lower.contains('ha noi') ||
        lower.contains('xom pho') ||
        lower.contains('xóm phố') ||
        lower.contains('gia lâm') ||
        lower.contains('hoàn kiếm') ||
        lower.contains('đống đa') ||
        lower.contains('hai bà trưng') ||
        lower.contains('cầu giấy')) {
      return 'Hà Nội';
    } else if (lower.contains('hồ chí minh') ||
        lower.contains('ho chi minh') ||
        lower.contains('sài gòn') ||
        lower.contains('saigon') ||
        lower.contains('thủ đức')) {
      return 'TP. Hồ Chí Minh';
    } else if (lower.contains('đà nẵng') || lower.contains('da nang')) {
      return 'Đà Nẵng';
    } else if (lower.contains('hải phòng') || lower.contains('hai phong')) {
      return 'Hải Phòng';
    } else if (lower.contains('cần thơ') || lower.contains('can tho')) {
      return 'Cần Thơ';
    }

    // 3. Phân tích chuỗi địa chỉ từ OpenStreetMap
    final parts = raw.split(',');
    for (final part in parts.reversed) {
      final p = part.trim();
      final pLower = p.toLowerCase();
      if (pLower.contains('thành phố') || pLower.contains('tỉnh')) {
        return p.replaceAll(RegExp(r'^(Thành phố|Tỉnh)\s+', caseSensitive: false), '').trim();
      }
    }

    return parts.isNotEmpty ? parts.last.trim() : raw.trim();
  }

  bool _isNightTime(CurrentWeather? weather) {
    final nowHour = DateTime.now().hour;
    if (nowHour >= 18 || nowHour < 6) {
      return true;
    }
    final icon = weather?.icon?.trim().toLowerCase() ?? '';
    if (icon.endsWith('n')) {
      return true;
    }
    return false;
  }

  WeatherVisualConfig _getWeatherVisualConfig(CurrentWeather? weather) {
    final isNight = _isNightTime(weather);
    final condition = (weather?.condition ?? '').toLowerCase();
    final description = (weather?.description ?? '').toLowerCase();

    final isRainy = condition.contains('rain') || condition.contains('drizzle') || description.contains('mưa');
    final isThunder = condition.contains('thunder') || description.contains('dông') || description.contains('sấm');
    final isCloudy = condition.contains('cloud') || description.contains('mây');

    if (isNight) {
      if (isThunder) {
        return const WeatherVisualConfig(
          icon: Icons.thunderstorm_rounded,
          iconColor: Color(0xFFFFD54F),
          iconBgColors: [Color(0xFF1E2638), Color(0xFF131826)],
          iconBorderColor: Color(0xFF2E384D),
          iconShadowColor: Color(0x40FFC107),
          isNight: true,
        );
      }
      if (isRainy) {
        return const WeatherVisualConfig(
          icon: Icons.water_drop_rounded,
          iconColor: Color(0xFF60A5FA),
          iconBgColors: [Color(0xFF1E2638), Color(0xFF131826)],
          iconBorderColor: Color(0xFF2E384D),
          iconShadowColor: Color(0x3338BDF8),
          isNight: true,
        );
      }
      // Ban đêm: Hiển thị Vầng trăng khuyết màu vàng óng ánh (Golden Crescent Moon) chuẩn xác,
      // nổi bật và tuyệt đẹp trên nền trời đêm
      return const WeatherVisualConfig(
        customWidget: GoldenMoonWidget(size: 26),
        iconColor: Color(0xFFFFC107),
        iconBgColors: [Color(0xFF1E2638), Color(0xFF131826)],
        iconBorderColor: Color(0xFF2E384D),
        iconShadowColor: Color(0x40FFC107),
        isNight: true,
      );
    } else {
      if (isThunder) {
        return const WeatherVisualConfig(
          icon: Icons.thunderstorm_rounded,
          iconColor: Color(0xFF475569),
          iconBgColors: [Color(0xFFF1F5F9), Color(0xFFE2E8F0)],
          iconBorderColor: Color(0xFFCBD5E1),
          iconShadowColor: Color(0x33334155),
          isNight: false,
        );
      }
      if (isRainy) {
        return const WeatherVisualConfig(
          icon: Icons.water_drop_rounded,
          iconColor: Color(0xFF0284C7),
          iconBgColors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
          iconBorderColor: Color(0xFFBAE6FD),
          iconShadowColor: Color(0x330284C7),
          isNight: false,
        );
      }
      if (isCloudy) {
        return const WeatherVisualConfig(
          icon: Icons.wb_cloudy_rounded,
          iconColor: Color(0xFFF59E0B),
          iconBgColors: [Color(0xFFFFF9E6), Color(0xFFFFEDBA)],
          iconBorderColor: Color(0xFFFFDF85),
          iconShadowColor: Color(0x33FFB800),
          isNight: false,
        );
      }
      return const WeatherVisualConfig(
        icon: Icons.wb_sunny_rounded,
        iconColor: Color(0xFFFF9E00),
        iconBgColors: [Color(0xFFFFF9E6), Color(0xFFFFEDBA)],
        iconBorderColor: Color(0xFFFFDF85),
        iconShadowColor: Color(0x33FFB800),
        isNight: false,
      );
    }
  }

  String _getMealGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 4 && hour < 11) {
      return 'Sáng nay ăn gì nhỉ?';
    } else if (hour >= 11 && hour < 14) {
      return 'Trưa nay ăn gì nhỉ?';
    } else if (hour >= 14 && hour < 18) {
      return 'Chiều nay ăn gì nhỉ?';
    } else {
      return 'Tối nay ăn gì nhỉ?';
    }
  }

  String _getWeatherShortStatus(CurrentWeather? weather) {
    final isNight = _isNightTime(weather);
    if (weather == null) return isNight ? 'Đêm mát mẻ' : 'Thời tiết mát mẻ';
    String desc = weather.description.trim();
    final lower = desc.toLowerCase();
    if (lower.contains(' tại ')) {
      desc = desc.substring(0, lower.indexOf(' tại ')).trim();
    }
    if (lower.contains('mát mẻ')) {
      return isNight ? 'Đêm mát mẻ' : 'Thời tiết mát mẻ';
    }
    if (desc.isNotEmpty) {
      return desc[0].toUpperCase() + desc.substring(1);
    }
    final temp = weather.temperature;
    if (temp < 20) return isNight ? 'Đêm se lạnh' : 'Trời se lạnh';
    if (temp < 26) return isNight ? 'Đêm mát mẻ' : 'Thời tiết mát mẻ';
    if (temp < 32) return isNight ? 'Trời dịu mát' : 'Trời nắng nhẹ';
    return isNight ? 'Đêm oi ả' : 'Trời oi nóng';
  }

  String _getWeatherRecommendation(CurrentWeather? weather) {
    if (weather == null) {
      return 'Trời mát, cực hợp làm bát Phở nóng hổi!';
    }
    final temp = weather.temperature;
    final cond = weather.condition.toLowerCase();
    final desc = weather.description.toLowerCase();

    if (cond.contains('rain') || desc.contains('mưa')) {
      return 'Trời mưa mát mẻ, xì xụp bát Phở nóng hoặc Lẩu thơm!';
    } else if (temp < 22) {
      return 'Trời se lạnh, cực hợp làm bát Phở nóng hổi!';
    } else if (temp >= 22 && temp < 28) {
      return 'Trời mát, cực hợp làm bát Phở nóng hổi!';
    } else if (temp >= 28 && temp < 33) {
      return 'Thời tiết ấm áp, thích hợp thưởng thức Bún chả & Trà đá!';
    } else {
      return 'Trời oi nóng, giải nhiệt với Bún ốc hoặc Chè mát lạnh!';
    }
  }

  Future<void> _loadWeatherAndLocation({double? forcedLat, double? forcedLon, String? forcedCity}) async {
    setState(() {
  
    });

    double? lat = forcedLat;
    double? lon = forcedLon;
    String detectedCity = forcedCity ?? _selectedCity;

    try {
      if (lat == null || lon == null) {
        // Chỉ lấy toạ độ GPS thực tế từ thiết bị (HOÀN TOÀN KHÔNG DÙNG IP FALLBACK)
        final devPos = await LocationService.getDeviceLocation();
        if (devPos != null) {
          lat = devPos['lat'];
          lon = devPos['lon'];
          detectedCity = _resolveToCityName(null, lat: lat, lon: lon);
          widget.api.reverseMap(lat!, lon!).then((addr) {
            if (mounted && addr.isNotEmpty) {
              setState(() {
                _selectedCity = _resolveToCityName(addr, lat: lat, lon: lon);
              });
            }
          }).catchError((_) {});
        } else {
          // Khi không có GPS, dùng ngay toạ độ của thành phố đang được chọn
          final cityCoords = {
            'Hà Nội': {'lat': 21.0285, 'lon': 105.8542},
            'TP. Hồ Chí Minh': {'lat': 10.7769, 'lon': 106.7009},
            'Đà Nẵng': {'lat': 16.0544, 'lon': 108.2022},
            'Hải Phòng': {'lat': 20.8449, 'lon': 106.6881},
            'Cần Thơ': {'lat': 10.0452, 'lon': 105.7469},
          };
          final def = cityCoords[detectedCity] ?? cityCoords['Hà Nội']!;
          lat = def['lat'];
          lon = def['lon'];
        }
      }
    } catch (_) {}

    // Lấy thời tiết từ API theo toạ độ
    try {
      final weather = await widget.api.getCurrentWeather(lat: lat, lon: lon);
      if (mounted) {
        setState(() {
          _currentWeather = weather;

          if (forcedCity == null && weather.locationName != null && weather.locationName!.isNotEmpty) {
            detectedCity = _resolveToCityName(weather.locationName, lat: lat, lon: lon);
          }
          _selectedCity = detectedCity;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _selectedCity = detectedCity;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
      
        });
      }
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
        (r.address != null && r.address!.toLowerCase().contains(q)) ||
        (r.description != null && r.description!.toLowerCase().contains(q))).toList();
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

  String _getFoodImage(Restaurant r, int index) {
    final name = r.name.toLowerCase();
    final desc = (r.description ?? '').toLowerCase();

    if (name.contains('phở') || desc.contains('phở')) {
      return 'https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?w=500&auto=format&fit=crop&q=80';
    } else if (name.contains('bánh mì') || desc.contains('bánh mì')) {
      return 'https://images.unsplash.com/photo-1626804475297-41608ea09aeb?w=500&auto=format&fit=crop&q=80';
    } else if (name.contains('cơm') || desc.contains('cơm')) {
      return 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500&auto=format&fit=crop&q=80';
    } else if (name.contains('bún') || desc.contains('bún')) {
      return 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=500&auto=format&fit=crop&q=80';
    } else if (name.contains('miến') || desc.contains('miến')) {
      return 'https://images.unsplash.com/photo-1617093727343-374698b1b08d?w=500&auto=format&fit=crop&q=80';
    } else if (name.contains('trà') || name.contains('cà phê') || name.contains('nước') || desc.contains('uống')) {
      return 'https://images.unsplash.com/photo-1517256064527-09c73fc73e38?w=500&auto=format&fit=crop&q=80';
    } else if (name.contains('lẩu') || name.contains('nướng')) {
      return 'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=500&auto=format&fit=crop&q=80';
    }

    final curations = [
      'https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?w=500&auto=format&fit=crop&q=80',
      'https://images.unsplash.com/photo-1626804475297-41608ea09aeb?w=500&auto=format&fit=crop&q=80',
      'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500&auto=format&fit=crop&q=80',
      'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=500&auto=format&fit=crop&q=80',
      'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=500&auto=format&fit=crop&q=80',
    ];
    return curations[index % curations.length];
  }

  List<String> _getRestaurantTags(Restaurant r) {
    final name = r.name.toLowerCase();
    final desc = (r.description ?? '').toLowerCase();

    if (name.contains('phở') || desc.contains('phở')) {
      return ['Phở truyền thống', 'Ăn sáng'];
    } else if (name.contains('bánh mì') || desc.contains('bánh mì')) {
      return ['Bánh mì giòn', 'Ăn vặt'];
    } else if (name.contains('cơm') || desc.contains('cơm')) {
      return ['Cơm tấm', 'Ăn trưa/tối'];
    } else if (name.contains('bún') || desc.contains('bún')) {
      return ['Bún chả đậm vị', 'Ăn trưa'];
    } else {
      return ['Món Việt', 'Hương vị xưa'];
    }
  }

  double _getRatingScore(Restaurant r) {
    return 4.6 + ((r.id * 17) % 4) / 10.0;
  }

  String _getReviewCountText(Restaurant r) {
    final count = ((r.id * 313) % 1500) + 400;
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return '$count';
  }

  String _getDistanceText(Restaurant r, int index) {
    if (r.distanceKm != null && r.distanceKm! > 0) {
      if (r.distanceKm! < 1.0) {
        return '${(r.distanceKm! * 1000).round()}m';
      }
      return '${r.distanceKm!.toStringAsFixed(1)}km';
    } else if (r.distanceMeters != null && r.distanceMeters! > 0) {
      if (r.distanceMeters! < 1000) {
        return '${r.distanceMeters!.round()}m';
      }
      return '${(r.distanceMeters! / 1000).toStringAsFixed(1)}km';
    }
    final m = ((r.id * 350) % 1800) + 400;
    if (m < 1000) return '${m}m';
    return '${(m / 1000).toStringAsFixed(1)}km';
  }

  String _getPriceRange(Restaurant r) {
    final base = (r.id * 5) % 25 + 30; // 30k to 55k
    final max = base + 25; // 55k to 80k
    return '$base.000đ - $max.000đ';
  }

  void _showLocationPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final cities = ['Hà Nội', 'TP. Hồ Chí Minh', 'Đà Nẵng', 'Hải Phòng', 'Cần Thơ'];
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Chọn khu vực',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...cities.map((city) {
                  final isSelected = city == _selectedCity;
                  return ListTile(
                    leading: Icon(
                      Icons.location_on,
                      color: isSelected ? kPrimaryGreen : Colors.grey,
                    ),
                    title: Text(
                      city,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? kPrimaryGreen : Colors.black87,
                      ),
                    ),
                    trailing: isSelected ? const Icon(Icons.check, color: kPrimaryGreen) : null,
                    onTap: () {
                      Navigator.pop(ctx);
                      final coords = {
                        'Hà Nội': {'lat': 21.0285, 'lon': 105.8542},
                        'TP. Hồ Chí Minh': {'lat': 10.7769, 'lon': 106.7009},
                        'Đà Nẵng': {'lat': 16.0544, 'lon': 108.2022},
                        'Hải Phòng': {'lat': 20.8449, 'lon': 106.6881},
                        'Cần Thơ': {'lat': 10.0452, 'lon': 105.7469},
                      };
                      final cPos = coords[city];
                      _loadWeatherAndLocation(
                        forcedLat: cPos?['lat'],
                        forcedLon: cPos?['lon'],
                        forcedCity: city,
                      );
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final restaurants = _filteredList;
    final hero = restaurants.isNotEmpty ? restaurants.first : null;
    final listItems = restaurants.length > 1 ? restaurants.skip(1).toList() : restaurants;

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F4),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Stack(
              children: [
                // Trang trí lá cây góc trên phải màn hình
                Positioned(
                  top: 0,
                  right: 0,
                  width: 80,
                  height: 140,
                  child: IgnorePointer(
                    child: CustomPaint(painter: TopRightLeavesPainter()),
                  ),
                ),
                RefreshIndicator(
                  onRefresh: () async {
                    await Future.wait([
                      _loadData(),
                      _loadWeatherAndLocation(),
                    ]);
                  },
                  color: const Color(0xFF1B3B2B),
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // TIÊU ĐỀ NĂNG ĐỘNG Theo Thời Gian ("Sáng / Trưa / Chiều / Tối nay ăn gì nhỉ?")
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Text(
                                    _getMealGreeting(),
                                    style: const TextStyle(
                                      fontSize: 27,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF112319),
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  Positioned(
                                    top: -12,
                                    left: 118,
                                    child: const SparkBurst(width: 18, height: 14),
                                  ),
                                  Positioned(
                                    top: -10,
                                    right: -14,
                                    child: const SparkBurst(width: 18, height: 14),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              // 2. WEATHER CARD (Card Bento hiện đại, gradient tinh tế & tự động đổi ngày/đêm)
                              Builder(
                                builder: (context) {
                                  final weatherVisual = _getWeatherVisualConfig(_currentWeather);
                                  return Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: weatherVisual.isNight
                                            ? const [Colors.white, Color(0xFFF7F8FC)]
                                            : const [Colors.white, Color(0xFFF7FBF8)],
                                      ),
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: weatherVisual.isNight
                                            ? const Color(0xFFE2E8F0)
                                            : const Color(0xFFE2EFE5),
                                        width: 1.2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: weatherVisual.isNight
                                              ? const Color(0xFF1E293B).withAlpha(12)
                                              : const Color(0xFF1B3B2B).withAlpha(12),
                                          blurRadius: 18,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: Stack(
                                      children: [
                                        Positioned(
                                          right: 0,
                                          top: 0,
                                          bottom: 0,
                                          width: 120,
                                          child: ClipRRect(
                                            borderRadius: const BorderRadius.horizontal(right: Radius.circular(24)),
                                            child: CustomPaint(
                                              painter: WeatherLandscapePainter(isNight: weatherVisual.isNight),
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 48,
                                                height: 48,
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                    colors: weatherVisual.iconBgColors,
                                                  ),
                                                  shape: BoxShape.circle,
                                                  border: Border.all(color: weatherVisual.iconBorderColor, width: 1.5),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: weatherVisual.iconShadowColor,
                                                      blurRadius: 10,
                                                      offset: const Offset(0, 3),
                                                    ),
                                                  ],
                                                ),
                                                child: Center(
                                                  child: weatherVisual.customWidget ??
                                                      Icon(
                                                        weatherVisual.icon,
                                                        color: weatherVisual.iconColor,
                                                        size: 26,
                                                      ),
                                                ),
                                              ),
                                              const SizedBox(width: 14),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      '${_currentWeather?.temperature.round() ?? 26}°C',
                                                      style: const TextStyle(
                                                        fontSize: 24,
                                                        fontWeight: FontWeight.w900,
                                                        color: Color(0xFF112319),
                                                        letterSpacing: -0.5,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      _getWeatherShortStatus(_currentWeather),
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.w700,
                                                        color: weatherVisual.isNight
                                                            ? const Color(0xFF1E293B)
                                                            : const Color(0xFF1B3B2B),
                                                        letterSpacing: -0.2,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Container(
                                                width: 28,
                                                height: 28,
                                                decoration: BoxDecoration(
                                                  color: weatherVisual.isNight
                                                      ? const Color(0xFFEEF2F6)
                                                      : const Color(0xFFEBF3EC),
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: weatherVisual.isNight
                                                        ? const Color(0xFFE2E8F0)
                                                        : const Color(0xFFD6E8D9),
                                                    width: 0.8,
                                                  ),
                                                ),
                                                child: Icon(
                                                  Icons.chevron_right_rounded,
                                                  color: weatherVisual.isNight
                                                      ? const Color(0xFF1E293B)
                                                      : const Color(0xFF1B3B2B),
                                                  size: 18,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 16),

                              // 3. SEARCH BAR + NÚT LỌC TRÒN XANH ĐẬM
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(999),
                                        border: Border.all(color: const Color(0xFFE8E6DF), width: 1.2),
                                      ),
                                      child: TextField(
                                        decoration: const InputDecoration(
                                          hintText: 'Thêm món gì? Tìm quán, món ăn...',
                                          hintStyle: TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF8E9892),
                                            fontWeight: FontWeight.w500,
                                          ),
                                          prefixIcon: Icon(Icons.search, color: Color(0xFF5A655F), size: 22),
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        ),
                                        onChanged: (val) {
                                          setState(() {
                                            _searchQuery = val;
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  InkWell(
                                    onTap: () => widget.onOpenCategoryPicker?.call(),
                                    borderRadius: BorderRadius.circular(999),
                                    child: Container(
                                      width: 48,
                                      height: 48,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF1B3B2B),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.tune_rounded,
                                        color: Colors.white,
                                        size: 22,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // 4. CATEGORY PILLS CUỘN NGANG CÓ ICON VÀ GẠCH CHÂN LIME
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: _categories.map((cat) {
                                    final isSelected = (_currentCategory ?? 'Tất cả') == cat;
                                    IconData iconData = Icons.restaurant;
                                    if (cat == 'Phở') iconData = Icons.ramen_dining_outlined;
                                    else if (cat == 'Bún') iconData = Icons.soup_kitchen_outlined;
                                    else if (cat == 'Cơm') iconData = Icons.rice_bowl_outlined;
                                    else if (cat == 'Bánh mì') iconData = Icons.local_cafe_outlined;
                                    else if (cat == 'Ăn vặt') iconData = Icons.fastfood_outlined;
                                    else if (cat == 'Đồ uống') iconData = Icons.local_drink_outlined;
                                    else if (cat == 'Lẩu & Nướng') iconData = Icons.outdoor_grill_outlined;

                                    return Padding(
                                      padding: const EdgeInsets.only(right: 10),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          InkWell(
                                            onTap: () {
                                              setState(() {
                                                _currentCategory = cat == 'Tất cả' ? null : cat;
                                              });
                                            },
                                            borderRadius: BorderRadius.circular(20),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                              decoration: BoxDecoration(
                                                color: isSelected ? const Color(0xFF1B3B2B) : const Color(0xFFEBF3EC),
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    iconData,
                                                    size: 16,
                                                    color: isSelected ? Colors.white : const Color(0xFF1B3B2B),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    cat,
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                                      color: isSelected ? Colors.white : const Color(0xFF112319),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          if (isSelected)
                                            Container(
                                              width: 22,
                                              height: 4,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF8CE32C),
                                                borderRadius: BorderRadius.circular(2),
                                              ),
                                            )
                                          else
                                            const SizedBox(height: 4),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                              const SizedBox(height: 18),

                              // 5. SECTION: Đổi rồi, khám phá thôi! (Kèm sticker Lửa)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Expanded(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            'Đổi rồi, khám phá thôi!',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w900,
                                              color: Color(0xFF112319),
                                              letterSpacing: -0.3,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        SizedBox(width: 4),
                                        SparkBurst(width: 14, height: 12),
                                      ],
                                    ),
                                  ),
                                  Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFFFF1E8),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.local_fire_department,
                                          color: Color(0xFFFF6D3B),
                                          size: 22,
                                        ),
                                      ),
                                      const Positioned(
                                        top: -4,
                                        right: -8,
                                        child: SparkBurst(width: 12, height: 10),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Gợi ý dành riêng cho bạn hôm nay',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6E7A73),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 14),

                              // 6. HERO BIG FOOD CARD (Thẻ lớn bo tròn 24px)
                              if (hero != null)
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(color: const Color(0xFFF0EFEA), width: 1.2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withAlpha(12),
                                        blurRadius: 16,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                                            child: Image.network(
                                              _getFoodImage(hero, 0),
                                              width: double.infinity,
                                              height: 190,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => Container(
                                                height: 190,
                                                color: const Color(0xFFEBF3EC),
                                                alignment: Alignment.center,
                                                child: const Icon(Icons.restaurant, color: Color(0xFF1B3B2B), size: 48),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            top: 12,
                                            left: 12,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF1B3B2B),
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: const Text(
                                                '🌿 Hợp gu của bạn',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 12,
                                            right: 12,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(20),
                                                boxShadow: const [
                                                  BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                                                ],
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.star_rounded, size: 16, color: Color(0xFFFFB800)),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${_getRatingScore(hero).toStringAsFixed(1)} (${_getDistanceText(hero, 0)})',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w800,
                                                      color: Color(0xFF112319),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    hero.name,
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.w900,
                                                      color: Color(0xFF112319),
                                                      letterSpacing: -0.3,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Stack(
                                                  clipBehavior: Clip.none,
                                                  children: [
                                                    const Text(
                                                      '65.000đ',
                                                      style: TextStyle(
                                                        fontSize: 17,
                                                        fontWeight: FontWeight.w900,
                                                        color: Color(0xFF1B3B2B),
                                                      ),
                                                    ),
                                                    Positioned(
                                                      top: -6,
                                                      right: -12,
                                                      child: const SparkBurst(width: 10, height: 10),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                const Icon(Icons.location_on, size: 14, color: Color(0xFF8E9892)),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    hero.address ?? '15 Phố Cổ Bi, Gia Lâm, Hà Nội',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Color(0xFF6E7A73),
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 14),
                                            Wrap(
                                              alignment: WrapAlignment.spaceBetween,
                                              crossAxisAlignment: WrapCrossAlignment.center,
                                              spacing: 8,
                                              runSpacing: 10,
                                              children: [
                                                Wrap(
                                                  spacing: 6,
                                                  runSpacing: 6,
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFFEBF3EC),
                                                        borderRadius: BorderRadius.circular(20),
                                                      ),
                                                      child: const Text(
                                                        'Sốt vang đậm đà',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color: Color(0xFF1B3B2B),
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                                    ),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFFEBF3EC),
                                                        borderRadius: BorderRadius.circular(20),
                                                      ),
                                                      child: const Text(
                                                        'Ăn sáng/Trưa',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color: Color(0xFF1B3B2B),
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                                  child: Stack(
                                                    clipBehavior: Clip.none,
                                                    alignment: Alignment.center,
                                                    children: [
                                                      ElevatedButton(
                                                        onPressed: () => _showMenuBottomSheet(hero),
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: const Color(0xFF1B3B2B),
                                                          foregroundColor: Colors.white,
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(20),
                                                          ),
                                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                                          elevation: 0,
                                                        ),
                                                        child: const Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            Text(
                                                              'Khám phá ngay',
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                fontWeight: FontWeight.w800,
                                                              ),
                                                            ),
                                                            SizedBox(width: 4),
                                                            Icon(Icons.arrow_forward_rounded, size: 14),
                                                          ],
                                                        ),
                                                      ),
                                                      Positioned(
                                                        left: -12,
                                                        child: const SparkBurst(width: 10, height: 10),
                                                      ),
                                                      Positioned(
                                                        right: -12,
                                                        child: const SparkBurst(width: 10, height: 10),
                                                      ),
                                                    ],
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
                              const SizedBox(height: 24),

                              // 7. SECTION: Quán ngon quanh đây
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'Quán ngon quanh đây',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF112319),
                                        letterSpacing: -0.3,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        _currentCategory = null;
                                        _searchQuery = '';
                                      });
                                    },
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Xem tất cả',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF1B3B2B),
                                          ),
                                        ),
                                        SizedBox(width: 2),
                                        Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF1B3B2B)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
              // 7. LIST OF COMPACT RESTAURANT CARDS
              if (_loading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: kPrimaryGreen),
                  ),
                )
              else if (_error != null)
                SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Lỗi kết nối: $_error', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _loadData,
                            style: ElevatedButton.styleFrom(backgroundColor: kPrimaryGreen),
                            child: const Text('Thử lại', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else if (listItems.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.restaurant, size: 54, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text('Không tìm thấy quán ăn nào phù hợp', style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final r = listItems[index];
                        final tags = _getRestaurantTags(r);
                        final rating = _getRatingScore(r);
                        final reviewCount = _getReviewCountText(r);
                        final distanceText = _getDistanceText(r, index + 1);
                        final priceRange = _getPriceRange(r);
                        final imageUrl = _getFoodImage(r, index + 1);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFF0EFEA), width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(8),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: InkWell(
                            onTap: () => _showMenuBottomSheet(r),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Left square image
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    imageUrl,
                                    width: 84,
                                    height: 84,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 84,
                                      height: 84,
                                      color: const Color(0xFFE2E8F0),
                                      child: const Icon(Icons.restaurant, color: Color(0xFF94A3B8), size: 30),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Right details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              r.name,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFF0F172A),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Text(
                                            distanceText,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF0F172A),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        r.address ?? 'Hà Nội',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF64748B),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.star, size: 14, color: Color(0xFFF59E0B)),
                                          const SizedBox(width: 2),
                                          Text(
                                            '${rating.toStringAsFixed(1)} ($reviewCount)',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF0F172A),
                                            ),
                                          ),
                                          const Text(' • ', style: TextStyle(color: Color(0xFF94A3B8))),
                                            Flexible(
                                              child: Text(
                                                priceRange,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  color: kPrimaryGreen,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 6,
                                        children: tags.map((t) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF1F5F9),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              t,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: Color(0xFF64748B),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: listItems.length,
                    ),
                  ),
                ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 24),
              ),
            ],
          ),
        ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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

  LatLng _currentCenter = const LatLng(21.0046, 105.9387); // Mặc định HVNN Gia Lâm
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
      String? name;

      // 1. Lấy toạ độ GPS chính xác từ thiết bị / trình duyệt (KHÔNG DÙNG IP FALLBACK)
      final devPos = await LocationService.getDeviceLocation();
      if (devPos != null) {
        final targetPos = LatLng(devPos['lat']!, devPos['lon']!);
        name = 'Vị trí của bạn';

        // Phản hồi ngay lập tức: Di chuyển bản đồ & tải quán xung quanh không cần chờ mạng
        final inGiaLam = isPointInGiaLam(targetPos);
        if (mounted) {
          if (inGiaLam) {
            setState(() {
              _userLocation = targetPos;
              _userLocationName = name;
              _currentCenter = targetPos;
              _pinnedLocation = targetPos;
              _pinnedAddress = name;
              _searchCtrl.text = name!;
              _selectedRestaurant = null;
              _detectingLocation = false;
            });

            if (moveToUser) {
              _mapController.move(targetPos, 15.0);
            }
            _loadNearby(targetPos.latitude, targetPos.longitude);
          } else {
            setState(() {
              _detectingLocation = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Vị trí của bạn nằm ngoài vùng phủ sóng! Hệ thống chỉ hỗ trợ khu vực Huyện Gia Lâm.'),
                backgroundColor: Color(0xFFE65100),
                duration: Duration(seconds: 4),
              ),
            );
          }
        }

        // Tra cứu địa chỉ chi tiết ngầm trong nền để không chặn giao diện
        widget.api.reverseMap(targetPos.latitude, targetPos.longitude).then((addr) {
          if (mounted && addr.isNotEmpty) {
            setState(() {
              _userLocationName = addr;
              if (_pinnedLocation == targetPos) {
                _pinnedAddress = addr;
                _searchCtrl.text = addr;
              }
            });
          }
        }).catchError((_) {});
      } else {
        if (mounted) {
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
          content: Text('Địa điểm này nằm ngoài vùng phủ sóng Huyện Gia Lâm!'),
          backgroundColor: Color(0xFFE65100),
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
                    avatar: const Icon(Icons.tune, size: 14, color: kPrimaryGreen),
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
                              child: const Icon(Icons.restaurant, color: kPrimaryGreen, size: 20),
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
                                      Text('${r.distanceKm!.toStringAsFixed(1)} km  •  ', style: const TextStyle(fontWeight: FontWeight.bold, color: kPrimaryGreen, fontSize: 11)),
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
                            color: isSelected ? Colors.amber.shade800 : kPrimaryGreen,
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
                            : const Text('Tìm', style: TextStyle(fontWeight: FontWeight.bold)),
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
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: kPrimaryGreen))
                            : const Icon(Icons.my_location, size: 16, color: kPrimaryGreen),
                        label: const Text(
                          'Vị trí của tôi',
                          style: TextStyle(color: kPrimaryGreen, fontWeight: FontWeight.bold),
                        ),
                        backgroundColor: kLightGreen,
                        elevation: 1,
                        side: BorderSide(color: kPrimaryGreen.withAlpha(80)),
                        onPressed: () {
                          if (_userLocation != null) {
                            _mapController.move(_userLocation!, 15.0);
                          }
                          _detectUserLocation(moveToUser: true);
                        },
                      ),
                      const SizedBox(width: 8),
                      ActionChip(
                        avatar: const Icon(Icons.school, size: 16, color: kPrimaryGreen),
                        label: const Text('HVNN (Trâu Quỳ)'),
                        backgroundColor: Colors.white,
                        elevation: 2,
                        onPressed: () => _jumpTo(21.0046, 105.9387, 'Học viện Nông nghiệp Việt Nam (HVNN)'),
                      ),
                      const SizedBox(width: 8),
                      ActionChip(
                        avatar: const Icon(Icons.location_city, size: 16, color: kPrimaryGreen),
                        label: const Text('Ocean Park 1'),
                        backgroundColor: Colors.white,
                        elevation: 2,
                        onPressed: () => _jumpTo(20.9950, 105.9550, 'Vinhomes Ocean Park 1, Gia Lâm'),
                      ),
                      const SizedBox(width: 8),
                      ActionChip(
                        avatar: const Icon(Icons.palette, size: 16, color: kPrimaryGreen),
                        label: const Text('Làng gốm Bát Tràng'),
                        backgroundColor: Colors.white,
                        elevation: 2,
                        onPressed: () => _jumpTo(20.9760, 105.9080, 'Làng gốm Bát Tràng, Gia Lâm'),
                      ),
                      const SizedBox(width: 8),
                      ActionChip(
                        avatar: const Icon(Icons.store, size: 16, color: kPrimaryGreen),
                        label: const Text('Chợ Ninh Hiệp'),
                        backgroundColor: Colors.white,
                        elevation: 2,
                        onPressed: () => _jumpTo(21.1120, 105.9360, 'Chợ Ninh Hiệp, Gia Lâm'),
                      ),
                      const SizedBox(width: 8),
                      ActionChip(
                        avatar: const Icon(Icons.train, size: 16, color: kPrimaryGreen),
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
                              color: kLightGreen,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.restaurant, color: kPrimaryGreen, size: 24),
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
                                const Icon(Icons.near_me, size: 16, color: kPrimaryGreen),
                                const SizedBox(width: 4),
                                Text(
                                  '${_selectedRestaurant!.distanceKm!.toStringAsFixed(1)} km',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: kPrimaryGreen),
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
                  decoration: const BoxDecoration(
                    color: kLightGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.favorite_rounded, size: 64, color: kPrimaryGreen),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Lưu Giữ Món Ăn Bạn Yêu Thích',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: kTextDark),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Đăng nhập tài khoản Thực khách để thả tim lưu trữ các món ngon và nhận gợi ý ẩm thực chuẩn khẩu vị nhất!',
                  style: TextStyle(color: kTextMuted, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: kPrimaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.login),
                  label: const Text('Đăng nhập ngay', style: TextStyle(fontWeight: FontWeight.bold)),
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
                                    decoration: const BoxDecoration(
                                      color: kLightGreen,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.restaurant_menu_rounded, size: 64, color: kPrimaryGreen),
                                  ),
                                  const SizedBox(height: 20),
                                  const Text(
                                    'Chưa có món ăn yêu thích nào',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kTextDark),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Khám phá thực đơn các quán ăn hấp dẫn tại Gia Lâm và nhấn biểu tượng trái tim để lưu lại bạn nhé!',
                                    style: TextStyle(color: kTextMuted, fontSize: 14),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 24),
                                  FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: kPrimaryGreen,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    icon: const Icon(Icons.explore),
                                    label: const Text('Khám phá món ngon ngay', style: TextStyle(fontWeight: FontWeight.bold)),
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
                                      color: kLightGreen,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.fastfood, color: kPrimaryGreen, size: 28),
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
                                              color: kPrimaryGreen,
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
      if (mounted) setState(() => _profile = p);
    } catch (_) {}
    if (mounted) setState(() => _loadingProfile = false);
  }

  void _openAuthSheet({bool isRegister = false, VoidCallback? onSuccess}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _AuthFormModal(
        api: widget.api,
        initialRegister: isRegister,
        onSuccess: (res) {
          widget.onLoginSuccess(res);
          _loadRoleData();
          onSuccess?.call();
        },
      ),
    );
  }

  void _showLocationInfo() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.location_on, color: kPrimaryGreen),
            SizedBox(width: 8),
            Text('Quyền vị trí GPS', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'PTC1 sử dụng toạ độ vị trí thời gian thực từ thiết bị để gợi ý quán ăn lân cận và hiển thị thời tiết chính xác nhất. Vị trí của bạn hoàn toàn được bảo mật và không lưu trữ trên máy chủ.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: kPrimaryGreen),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyInfo() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.privacy_tip_outlined, color: kPrimaryGreen),
            SizedBox(width: 8),
            Text('Điều khoản & Quyền riêng tư', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'PTC1 cam kết tôn trọng quyền riêng tư của khách hàng. Bạn có thể tự do tìm kiếm quán ăn và tra cứu thực đơn mà không cần cung cấp bất kỳ thông tin cá nhân nào khi ở chế độ Khách.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: kPrimaryGreen),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitRow({required IconData icon, required String title, required String desc}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: kLightGreen,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: kPrimaryGreen, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: kTextDark)),
              const SizedBox(height: 3),
              Text(desc, style: const TextStyle(fontSize: 12, color: kTextMuted, height: 1.35)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // ----------------------------------------------------
    // TRẠNG THÁI 1: ĐÃ ĐĂNG NHẬP THỰC KHÁCH
    // ----------------------------------------------------
    if (widget.currentUser != null) {
      final user = widget.currentUser!;

      return Scaffold(
        backgroundColor: kScaffoldBg,
        appBar: AppBar(
          title: const Text('Tài Khoản Thực Khách', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Color(0xFFDC2626)),
              tooltip: 'Đăng xuất',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: const Text('Xác nhận đăng xuất', style: TextStyle(fontWeight: FontWeight.bold)),
                    content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi tài khoản không?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Huỷ', style: TextStyle(color: Colors.grey))),
                      FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
                        onPressed: () {
                          Navigator.pop(ctx);
                          widget.onLogout();
                        },
                        child: const Text('Đăng xuất'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          children: [
            // Thẻ hồ sơ thành viên
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: kBorderColor),
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8, offset: const Offset(0, 3)),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: kPrimaryGreen,
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
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kTextDark)),
                        const SizedBox(height: 2),
                        Text(user.email, style: const TextStyle(color: kTextMuted, fontSize: 13)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: kLightGreen,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: kPrimaryGreen.withAlpha(80)),
                          ),
                          child: const Text(
                            'Thành Viên Thực Khách',
                            style: TextStyle(color: kPrimaryGreen, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Banner nhắc nhở khảo sát nếu chưa hoàn thành
            if (_profile != null && !_profile!.isOnboarded)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: kSuperLightGreen,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: kPrimaryGreen.withAlpha(80)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.eco_outlined, color: kPrimaryGreen, size: 24),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Chưa thiết lập sở thích ẩm thực',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kPrimaryGreen)),
                          SizedBox(height: 2),
                          Text('Khảo sát ngay để nhận gợi ý món ăn chuẩn vóc dáng & khẩu vị!',
                              style: TextStyle(fontSize: 12, color: Color(0xFF166534))),
                        ],
                      ),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: kPrimaryGreen,
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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: kBorderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.health_and_safety_outlined, color: kPrimaryGreen),
                          SizedBox(width: 8),
                          Text('Hồ Sơ Sức Khỏe & Sở Thích',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: kTextDark)),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_note, color: kPrimaryGreen),
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
                  const Divider(height: 16),
                  if (_loadingProfile)
                    const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
                  else if (_profile == null)
                    const Text('Chưa có thông tin hồ sơ.')
                  else ...[
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: kScaffoldBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: kBorderColor),
                            ),
                            child: Column(
                              children: [
                                const Text('Chiều cao', style: TextStyle(fontSize: 11, color: kTextMuted)),
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
                              color: kScaffoldBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: kBorderColor),
                            ),
                            child: Column(
                              children: [
                                const Text('Cân nặng', style: TextStyle(fontSize: 11, color: kTextMuted)),
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
                              color: kLightGreen,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: kPrimaryGreen.withAlpha(60)),
                            ),
                            child: Column(
                              children: [
                                const Text('BMI', style: TextStyle(fontSize: 11, color: kPrimaryGreen, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 2),
                                Text(
                                  _profile!.bmi != null ? _profile!.bmi!.toStringAsFixed(1) : '--',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: kPrimaryGreen),
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
                          const Text('Thể trạng: ', style: TextStyle(fontSize: 12, color: kTextMuted)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: kLightGreen,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _profile!.bmiCategory == 'normal'
                                  ? 'Chuẩn dáng'
                                  : (_profile!.bmiCategory == 'underweight' ? 'Hơi gầy' : 'Thừa cân'),
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kPrimaryGreen),
                            ),
                          ),
                          if (_profile!.targetGoal != null) ...[
                            const SizedBox(width: 8),
                            const Text('• Mục tiêu: ', style: TextStyle(fontSize: 12, color: kTextMuted)),
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
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Khối Cài đặt & Quyền riêng tư
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              clipBehavior: Clip.antiAlias,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: kBorderColor),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.location_on_outlined, color: kPrimaryGreen),
                      title: const Text('Quyền vị trí GPS', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                      onTap: _showLocationInfo,
                    ),
                    const Divider(height: 1, indent: 56),
                    ListTile(
                      leading: const Icon(Icons.privacy_tip_outlined, color: kPrimaryGreen),
                      title: const Text('Điều khoản & Quyền riêng tư', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                      onTap: _showPrivacyInfo,
                    ),
                    const Divider(height: 1, indent: 56),
                    const ListTile(
                      leading: Icon(Icons.info_outline, color: kPrimaryGreen),
                      title: Text('Phiên bản ứng dụng', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      trailing: Text('v1.0.0 (PTC1)', style: TextStyle(color: kTextMuted, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ----------------------------------------------------
    // TRẠNG THÁI 2: CHẾ ĐỘ KHÁCH (CHƯA ĐĂNG NHẬP)
    // ----------------------------------------------------
    return Scaffold(
      backgroundColor: kScaffoldBg,
      appBar: AppBar(
        title: const Text('Tài Khoản', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: kTextDark)),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        children: [
          // 1. Khối Avatar mặc định + Lời chào Khách
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kBorderColor),
              boxShadow: [
                BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: kLightGreen,
                    shape: BoxShape.circle,
                    border: Border.all(color: kPrimaryGreen.withAlpha(40), width: 2),
                  ),
                  child: const Icon(Icons.person_outline_rounded, size: 40, color: kPrimaryGreen),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Chào bạn!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: kTextDark),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Bạn đang trải nghiệm với tư cách Khách',
                  style: TextStyle(fontSize: 13, color: kTextMuted),
                ),
                const SizedBox(height: 18),
                // 2. Hai nút: Đăng nhập & Tạo tài khoản miễn phí
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: kPrimaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _openAuthSheet(isRegister: false),
                        child: const Text('Đăng nhập', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kPrimaryGreen,
                          side: const BorderSide(color: kPrimaryGreen, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _openAuthSheet(isRegister: true),
                        child: const Text('Tạo tài khoản miễn phí', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. Khối 3 Lợi ích thành viên
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kBorderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.stars_rounded, color: kPrimaryGreen, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Lợi ích khi đăng nhập thành viên',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: kTextDark),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildBenefitRow(
                  icon: Icons.favorite_border_rounded,
                  title: 'Lưu & đồng bộ món ăn yêu thích',
                  desc: 'Thả tim các món ngon để xem lại nhanh chóng bất cứ khi nào bạn đói bụng.',
                ),
                const Divider(height: 22, color: Color(0xFFF1F5F9)),
                _buildBenefitRow(
                  icon: Icons.psychology_outlined,
                  title: 'Gợi ý món ăn thông minh theo khẩu vị',
                  desc: 'Đề xuất bữa ăn chuẩn vóc dáng, thời tiết và sở thích ăn uống cá nhân của bạn.',
                ),
                const Divider(height: 22, color: Color(0xFFF1F5F9)),
                _buildBenefitRow(
                  icon: Icons.storefront_outlined,
                  title: 'Khám phá quán ngon & ưu đãi quanh bạn',
                  desc: 'Cập nhật món ăn mới và bảng giá chuẩn xác nhất từ các quán lân cận.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 4. Khối Cài đặt, quyền riêng tư (dùng được không cần tài khoản)
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            clipBehavior: Clip.antiAlias,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: kBorderColor),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: kLightGreen, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.location_on_outlined, color: kPrimaryGreen, size: 20),
                    ),
                    title: const Text('Quyền truy cập vị trí', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('Dùng GPS để định vị và gợi ý quán ăn gần nhất', style: TextStyle(fontSize: 12, color: kTextMuted)),
                    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: _showLocationInfo,
                  ),
                  const Divider(height: 1, indent: 60, color: Color(0xFFF1F5F9)),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: kLightGreen, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.language_rounded, color: kPrimaryGreen, size: 20),
                    ),
                    title: const Text('Ngôn ngữ', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    trailing: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Tiếng Việt', style: TextStyle(fontSize: 13, color: kTextMuted)),
                        SizedBox(width: 4),
                        Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                    onTap: () {},
                  ),
                  const Divider(height: 1, indent: 60, color: Color(0xFFF1F5F9)),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: kLightGreen, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.privacy_tip_outlined, color: kPrimaryGreen, size: 20),
                    ),
                    title: const Text('Điều khoản & Quyền riêng tư', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: _showPrivacyInfo,
                  ),
                  const Divider(height: 1, indent: 60, color: Color(0xFFF1F5F9)),
                  const ListTile(
                    leading: SizedBox(width: 20),
                    title: Text('Phiên bản ứng dụng', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    trailing: Text('v1.0.0 (PTC1)', style: TextStyle(fontSize: 13, color: kTextMuted, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ==========================================
// FORM ĐĂNG NHẬP / ĐĂNG KÝ MODAL BOTTOM SHEET
// ==========================================
class _AuthFormModal extends StatefulWidget {
  final ApiService api;
  final bool initialRegister;
  final Function(RoleLoginResponse) onSuccess;

  const _AuthFormModal({
    required this.api,
    this.initialRegister = false,
    required this.onSuccess,
  });

  @override
  State<_AuthFormModal> createState() => _AuthFormModalState();
}

class _AuthFormModalState extends State<_AuthFormModal> {
  late bool _isRegister;
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _isRegister = widget.initialRegister;
  }

  void _fillSampleAccount() {
    setState(() {
      _emailCtrl.text = 'user@example.com';
      _passwordCtrl.text = '123456';
      if (_isRegister) {
        _nameCtrl.text = 'Nguyễn Văn Thực Khách';
      }
    });
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final pwd = _passwordCtrl.text;
    if (email.isEmpty || pwd.isEmpty) {
      setState(() => _error = 'Vui lòng nhập đầy đủ Email và Mật khẩu');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      RoleLoginResponse res;
      if (!_isRegister) {
        res = await widget.api.loginUser(email, pwd);
      } else {
        final name = _nameCtrl.text.trim();
        res = await widget.api.registerUser(email, pwd, name);
      }
      if (mounted) {
        Navigator.pop(context);
        widget.onSuccess(res);
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isRegister ? 'Tạo Tài Khoản Khách Hàng' : 'Đăng Nhập Khách Hàng',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kTextDark),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),

          SegmentedButton<bool>(
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: kPrimaryGreen,
              selectedForegroundColor: Colors.white,
              backgroundColor: Colors.white,
              foregroundColor: kTextDark,
              side: const BorderSide(color: kBorderColor),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            segments: const [
              ButtonSegment(value: false, label: Text('Đăng nhập', style: TextStyle(fontWeight: FontWeight.bold))),
              ButtonSegment(value: true, label: Text('Đăng ký', style: TextStyle(fontWeight: FontWeight.bold))),
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
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('⚠️ $_error', style: TextStyle(color: Colors.red.shade800, fontSize: 13)),
            ),
          ],

          const SizedBox(height: 14),

          // Nút điền nhanh tài khoản mẫu
          InkWell(
            onTap: _fillSampleAccount,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: kSuperLightGreen,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kPrimaryGreen.withAlpha(80)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.flash_on_rounded, size: 16, color: kPrimaryGreen),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Bấm để điền nhanh tài khoản mẫu (user@example.com / 123456)',
                      style: TextStyle(fontSize: 11, color: kPrimaryGreen, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email *'),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _passwordCtrl,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Mật khẩu *'),
          ),

          if (_isRegister) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Họ và tên'),
            ),
          ],

          const SizedBox(height: 20),

          SizedBox(
            height: 48,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: kPrimaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(_isRegister ? 'Đăng ký ngay' : 'Đăng nhập', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                                              color: kPrimaryGreen, fontWeight: FontWeight.bold, fontSize: 14)),
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
                            selectedColor: kPrimaryGreen,
                            labelStyle: TextStyle(
                              color: selected ? Colors.white : kTextDark,
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
                      backgroundColor: kPrimaryGreen,
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
                  child: const Icon(Icons.restaurant, size: 26, color: kPrimaryGreen),
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
                        color: isSelected ? kPrimaryGreen : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? kPrimaryGreen : kBorderColor,
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