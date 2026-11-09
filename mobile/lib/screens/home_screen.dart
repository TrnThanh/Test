import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../painters/app_illustrations.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../theme/app_colors.dart';
import '../widgets/restaurant_menu_widget.dart';

/// Screen 2 trong thiết kế: Màn hình Trang Chủ (Home Screen)
class HomeScreen extends StatefulWidget {
  final ApiService api;
  final RoleLoginResponse? currentUser;
  final VoidCallback onRequireLogin;
  final void Function(double lat, double lon, [Restaurant? restaurant])? onNavigateToMap;
  final VoidCallback? onNavigateToExplore;
  final VoidCallback? onNavigateToAccount;
  final ScrollController? scrollController;

  const HomeScreen({
    super.key,
    required this.api,
    this.currentUser,
    required this.onRequireLogin,
    this.onNavigateToMap,
    this.onNavigateToExplore,
    this.onNavigateToAccount,
    this.scrollController,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Restaurant> _restaurants = [];
  bool _isListExpanded = false;
  static const int _previewLimit = 3;
  bool _loading = false;
  String _selectedCity = 'Hà Nội';
  CurrentWeather? _currentWeather;
  double? _userLat;
  double? _userLon;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadWeatherAndLocation();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final list = await widget.api.getRestaurants(limit: 50);
      if (mounted) {
        setState(() {
          _restaurants = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadWeatherAndLocation() async {
    try {
      final loc = await LocationService.getDeviceLocation();
      if (loc != null && mounted) {
        setState(() {
          _userLat = loc['lat'];
          _userLon = loc['lon'];
        });
      }
    } catch (_) {}

    try {
      final w = await widget.api.getCurrentWeather(
        lat: _userLat ?? 21.0285,
        lon: _userLon ?? 105.8542,
      );
      if (mounted) {
        setState(() => _currentWeather = w);
      }
    } catch (_) {}
  }

  void _openRestaurantDetail(Restaurant restaurant) {
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
          DraggableScrollableSheet(
            initialChildSize: 0.92,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (_, scrollCtrl) => Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: RestaurantMenuWidget(
                api: widget.api,
                restaurant: restaurant,
                scrollController: scrollCtrl,
                currentUser: widget.currentUser,
                onRequireLogin: widget.onRequireLogin,
                onNavigateToMap: widget.onNavigateToMap,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  Widget _buildSafeImage({
    required double width,
    required double height,
    BorderRadius? borderRadius,
    String? imageUrl,
  }) {
    final clipRadius = borderRadius ?? BorderRadius.circular(14);
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: clipRadius,
        child: Image.network(
          imageUrl,
          width: width,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildFallbackFoodImage(width, height, clipRadius),
        ),
      );
    }
    return _buildFallbackFoodImage(width, height, clipRadius);
  }

  Widget _buildFallbackFoodImage(double width, double height, BorderRadius radius) {
    return ClipRRect(
      borderRadius: radius,
      child: Image.asset(
        'assets/images/featured_food.jpg',
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: width,
          height: height,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFED7AA), Color(0xFFFDBA74)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Center(
            child: Icon(Icons.ramen_dining_rounded, color: Color(0xFFC2410C), size: 34),
          ),
        ),
      ),
    );
  }

  Widget _buildHotCard(String name, double rating) {
    return Container(
      width: 145,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2EBE9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSafeImage(
            width: 145,
            height: 90,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.nunito(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: kTextDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: kStarYellow, size: 15),
                    const SizedBox(width: 3),
                    Text(
                      rating.toStringAsFixed(1),
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final weatherTemp = _currentWeather != null ? '${_currentWeather!.temperature.round()}°C' : '28°C';
    final weatherDesc = _currentWeather != null && _currentWeather!.description.isNotEmpty
        ? _currentWeather!.description
        : 'Có mây';

    final displayList = _restaurants;
    final heroRestaurant = displayList.isNotEmpty ? displayList.first : null;

    return Scaffold(
      backgroundColor: kScaffoldBg,
      body: SafeArea(
        child: RefreshIndicator(
          color: kPrimaryTeal,
          onRefresh: () async {
            await _loadData();
            await _loadWeatherAndLocation();
          },
          child: CustomScrollView(
            controller: widget.scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: Stack(
                  children: [
                    // Cảnh nền phố xá pastel dịu nhẹ bao quanh Top Header
                    const Positioned.fill(
                      child: HomeHeaderScenicBackground(),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. TOP BAR: [📍 Hà Nội ▾ + Sáng nay ăn gì nhỉ? ✨] ... [🔔] [Avatar]
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Sáng nay ăn gì nhỉ? ✨',
                                style: GoogleFonts.nunito(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF1F3A5F),
                                  height: 1.15,
                                  shadows: [
                                    Shadow(
                                      color: Colors.white.withOpacity(0.85),
                                      offset: const Offset(0, 1),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  // Nút Thông Báo 🔔 (kính mờ đồng bộ 38px)
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.85),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 1.2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.04),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        const Icon(Icons.notifications_none_rounded, color: Color(0xFF334155), size: 20),
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: Container(
                                            width: 7,
                                            height: 7,
                                            decoration: const BoxDecoration(
                                              color: kBadgeRed,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Avatar Người Dùng (kính mờ đồng bộ 38px)
                                  GestureDetector(
                                    onTap: widget.onNavigateToAccount,
                                    child: Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withOpacity(0.85),
                                        border: Border.all(color: kPrimaryTeal.withOpacity(0.35), width: 1.2),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.04),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(Icons.person_rounded, color: kPrimaryTeal, size: 20),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // 2. WEATHER CARD (Khung kính mờ mờ dần từ trái qua phải ở phần bên phải, đầu bếp hòa tuyệt đối vào cảnh nền)
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // 1. Khung thẻ kính mờ (Fade mờ dần từ trái qua phải ở phần bên phải theo đúng vùng đánh dấu đỏ)
                              Positioned.fill(
                                child: ShaderMask(
                                  shaderCallback: (Rect bounds) {
                                    return const LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: [
                                        Colors.white,
                                        Colors.white,
                                        Color(0x99FFFFFF), // 60% opacity ở 60% chiều ngang
                                        Colors.transparent, // Tan biến hoàn toàn vào cảnh nền ở 95%
                                      ],
                                      stops: [0.0, 0.45, 0.68, 0.95],
                                    ).createShader(bounds);
                                  },
                                  blendMode: BlendMode.dstIn,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(24),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                                      child: Container(
                                        height: 124,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(24),
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.white.withOpacity(0.68),
                                              Colors.white.withOpacity(0.38),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(0.75),
                                            width: 1.2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF38BDF8).withOpacity(0.18),
                                              blurRadius: 24,
                                              offset: const Offset(0, 8),
                                            ),
                                            BoxShadow(
                                              color: const Color(0xFF0F3B4C).withOpacity(0.05),
                                              blurRadius: 10,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // 2. Nội dung chữ & Icon thời tiết bên trái (giữ nguyên vị trí, sắc nét 100%)
                              Container(
                                height: 124,
                                padding: const EdgeInsets.fromLTRB(16, 12, 130, 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Row(
                                      children: [
                                        WeatherSunCloudArt(width: 46, height: 42, condition: weatherDesc),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              weatherTemp,
                                              style: GoogleFonts.nunito(
                                                fontSize: 36,
                                                fontWeight: FontWeight.w900,
                                                color: const Color(0xFF0F172A),
                                                height: 1.05,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 4),
                                      child: Text(
                                        _capitalize(weatherDesc),
                                        style: GoogleFonts.nunito(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF64748B),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // 3. Quầng sáng (Glow) phía sau nhân vật
                              Positioned(
                                top: -25,
                                right: -20,
                                child: IgnorePointer(
                                  child: ImageFiltered(
                                    imageFilter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                    child: Container(
                                      width: 220,
                                      height: 220,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: RadialGradient(
                                          center: const Alignment(0.0, 0.2),
                                          radius: 0.5,
                                          colors: [
                                            Colors.white.withOpacity(0.90),
                                            Colors.white.withOpacity(0.50),
                                            Colors.white.withOpacity(0.0),
                                          ],
                                          stops: const [0.0, 0.45, 1.0],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // 4. Drop shadow mềm của nhân vật (xanh đậm 25%, offset Y 9px, blur 15px)
                              Positioned(
                                top: -12 + 9,
                                right: 18,
                                child: IgnorePointer(
                                  child: ImageFiltered(
                                    imageFilter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                                    child: ColorFiltered(
                                      colorFilter: ColorFilter.mode(
                                        const Color(0xFF1E3A5F).withOpacity(0.25),
                                        BlendMode.srcIn,
                                      ),
                                      child: Image.asset(
                                        'assets/images/anime_chef.png',
                                        width: 136,
                                        height: 136,
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // 5. Nhân vật đầu bếp Anime (Mũ nhô lên 12px, lùi vào trong 18px)
                              Positioned(
                                top: -12,
                                right: 18,
                                child: Image.asset(
                                  'assets/images/anime_chef.png',
                                  width: 136,
                                  height: 136,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const AnimeChefArt(width: 120, height: 120),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // 3. SEARCH BAR: 🔍 T🔍m qu🔍n 🔍n, m🔍n 🔍n... (1 icon k🔍nh l🔍p + n🔍t l🔍c b🔍n ph🔍i)
                          GestureDetector(
                            onTap: widget.onNavigateToExplore,
                            child: Container(
                              height: 50,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(color: const Color(0xFFE2EBE9)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 12,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 22),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Tìm quán ăn, món ăn...',
                                      style: GoogleFonts.nunito(
                                        fontSize: 14.5,
                                        color: const Color(0xFF94A3B8),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFF1F5F9),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.tune_rounded, color: Color(0xFF0F766E), size: 18),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Khoảng cách 20px liền mạch giữa thanh tìm kiếm và danh mục (không vệt xám)
              const SliverToBoxAdapter(
                child: SizedBox(height: 14),
              ),

              // 4. CATEGORIES: Cuộn ngang mượt mà, đồng bộ tone màu ấm, không bị cụt
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 94,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      _buildCategoryCircle(
                        title: 'Tất cả',
                        icon: Icons.grid_view_rounded,
                        bgColor: const Color(0xFFE6F4F1),
                        iconColor: const Color(0xFF0F766E),
                      ),
                      const SizedBox(width: 12),
                      _buildCategoryCircle(
                        title: 'Món Việt',
                        icon: Icons.ramen_dining_rounded,
                        bgColor: const Color(0xFFFEF3C7),
                        iconColor: const Color(0xFFD97706),
                      ),
                      const SizedBox(width: 12),
                      _buildCategoryCircle(
                        title: 'Món Âu',
                        icon: Icons.lunch_dining_rounded,
                        bgColor: const Color(0xFFFEF9C3),
                        iconColor: const Color(0xFFCA8A04),
                      ),
                      const SizedBox(width: 12),
                      _buildCategoryCircle(
                        title: 'Món Hàn',
                        icon: Icons.soup_kitchen_rounded,
                        bgColor: const Color(0xFFFFEDD5),
                        iconColor: const Color(0xFFEA580C),
                      ),
                      const SizedBox(width: 12),
                      _buildCategoryCircle(
                        title: 'Nướng, lẩu',
                        icon: Icons.local_fire_department_rounded,
                        bgColor: const Color(0xFFFEEAD8),
                        iconColor: const Color(0xFFDD6B20),
                      ),
                      const SizedBox(width: 12),
                      _buildCategoryCircle(
                        title: 'Đồ uống',
                        icon: Icons.local_cafe_rounded,
                        bgColor: const Color(0xFFE0F2FE),
                        iconColor: const Color(0xFF0284C7),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 24),
              ),

              // 5. GỢI Ý HÔM NAY + NỘI DUNG TIẾP THEO
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Gợi ý hôm nay + [Xem tất cả >]
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Gợi ý hôm nay',
                            style: GoogleFonts.nunito(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          GestureDetector(
                            onTap: widget.onNavigateToExplore,
                            child: Row(
                              children: [
                                Text(
                                  'Xem tất cả',
                                  style: GoogleFonts.nunito(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: kPrimaryTeal,
                                  ),
                                ),
                                const Icon(Icons.chevron_right, size: 18, color: kPrimaryTeal),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Featured Card: Lẩu Thái / Quán đề xuất đầu tiên với thông tin đầy đủ & nút rõ nét
                      if (heroRestaurant != null)
                        GestureDetector(
                          onTap: () => _openRestaurantDetail(heroRestaurant),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: const Color(0xFFE2EBE9)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 12,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Nhãn gắn với thời tiết (Icon lá mầm mát mẻ)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE6F4F1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        weatherDesc.toLowerCase().contains('mưa') || weatherDesc.toLowerCase().contains('rain')
                                            ? Icons.water_drop_rounded
                                            : Icons.eco_rounded,
                                        size: 14,
                                        color: const Color(0xFF0F766E),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        weatherDesc.toLowerCase().contains('mưa') || weatherDesc.toLowerCase().contains('rain')
                                            ? 'Hợp ngày mưa • Đề xuất cho bạn'
                                            : 'Hợp ngày se lạnh • Đề xuất cho bạn',
                                        style: GoogleFonts.nunito(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF0F766E),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    _buildSafeImage(width: 84, height: 84, imageUrl: heroRestaurant.imageUrl),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            heroRestaurant.name,
                                            style: GoogleFonts.nunito(
                                              fontSize: 16.5,
                                              fontWeight: FontWeight.w800,
                                              color: const Color(0xFF0F172A),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(Icons.star_rounded, color: kStarYellow, size: 16),
                                              const SizedBox(width: 3),
                                              Text(
                                                '${heroRestaurant.rating ?? 4.8} (2.1k)',
                                                style: GoogleFonts.nunito(
                                                  fontSize: 12.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: const Color(0xFF475569),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                width: 5,
                                                height: 5,
                                                decoration: const BoxDecoration(
                                                  color: Color(0xFF10B981),
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Mở cửa',
                                                style: GoogleFonts.nunito(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: const Color(0xFF10B981),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              const Icon(Icons.location_on, color: kPrimaryTeal, size: 15),
                                              const SizedBox(width: 3),
                                              Text(
                                                '${heroRestaurant.distanceKm != null ? heroRestaurant.distanceKm!.toStringAsFixed(1) : "1.2"} km',
                                                style: GoogleFonts.nunito(
                                                  fontSize: 12.5,
                                                  fontWeight: FontWeight.w600,
                                                  color: const Color(0xFF64748B),
                                                ),
                                              ),
                                              const Spacer(),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF0F766E),
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Text(
                                                  'Khám phá ngay',
                                                  style: GoogleFonts.nunito(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w800,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),

                      // 6. QUÁN NỔI BẬT [Hot] + [Xem thêm >]
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Quán nổi bật',
                                style: GoogleFonts.nunito(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: kBadgeRed,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                          'Hot',
                          style: GoogleFonts.nunito(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: widget.onNavigateToExplore,
                    child: Row(
                      children: [
                        Text(
                          'Xem thêm',
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: kPrimaryTeal,
                          ),
                        ),
                        const Icon(Icons.chevron_right, size: 18, color: kPrimaryTeal),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Horizontal Cards: Nhà hàng Sen Vàng, Bún Bò Huế (Screen 2 Mockup)
              SizedBox(
                height: 155,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildHotCard('Nhà hàng Sen Vàng', 4.7),
                    const SizedBox(width: 12),
                    _buildHotCard('Bún Bò Huế', 4.6),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 7. TOÀN BỘ QUÁN ĂN (Hiển thị số lượng gọn gàng + Xem thêm / Thu gọn)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Khám phá quán ngon',
                    style: GoogleFonts.nunito(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: kTextDark,
                    ),
                  ),
                  if (displayList.length > _previewLimit)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isListExpanded = !_isListExpanded;
                        });
                      },
                      child: Text(
                        _isListExpanded ? 'Thu gọn' : 'Xem thêm',
                        style: GoogleFonts.nunito(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: kPrimaryTeal,
                        ),
                      ),
                    ),
                ],
              ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final r = displayList[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2EBE9)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(5),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: InkWell(
                          onTap: () => _openRestaurantDetail(r),
                          child: Row(
                            children: [
                              _buildSafeImage(width: 76, height: 76, imageUrl: r.imageUrl, borderRadius: BorderRadius.circular(14)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      r.name,
                                      style: GoogleFonts.nunito(
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.w800,
                                        color: kTextDark,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      r.address ?? 'Hà Nội',
                                      style: GoogleFonts.nunito(
                                        fontSize: 12,
                                        color: const Color(0xFF64748B),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.star_rounded, color: kStarYellow, size: 16),
                                        const SizedBox(width: 3),
                                        Text(
                                          '${r.rating ?? 4.7}',
                                          style: GoogleFonts.nunito(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF334155),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '• ${r.openTime ?? "08:00"} - ${r.closeTime ?? "22:00"}',
                                          style: GoogleFonts.nunito(
                                            fontSize: 11.5,
                                            color: const Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.favorite_border_rounded, color: kPrimaryTeal),
                                onPressed: () => _openRestaurantDetail(r),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: _isListExpanded
                        ? displayList.length
                        : math.min(_previewLimit, displayList.length),
                  ),
                ),
              ),
              if (displayList.length > _previewLimit)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 2, 20, 16),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _isListExpanded = !_isListExpanded;
                        });
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _isListExpanded ? const Color(0xFFF1F5F9) : const Color(0xFFE6F4F1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _isListExpanded ? const Color(0xFFE2E8F0) : const Color(0xFFCCECE6),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isListExpanded
                                  ? 'Thu gọn danh sách'
                                  : 'Xem thêm ( quán khác)',
                              style: GoogleFonts.nunito(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: _isListExpanded ? const Color(0xFF64748B) : kPrimaryTeal,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              _isListExpanded
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              color: _isListExpanded ? const Color(0xFF64748B) : kPrimaryTeal,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 24),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCircle({
    required String title,
    required IconData icon,
    required Color bgColor,
    required Color iconColor,
  }) {
    final isSelected = _selectedCategory == title;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = isSelected ? null : title;
        });
        widget.onNavigateToExplore?.call();
      },
      child: SizedBox(
        width: 66,
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: iconColor.withAlpha(25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.visible,
              style: GoogleFonts.nunito(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: kTextDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCityPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final cities = ['Hà Nội', 'TP. Hồ Chí Minh', 'Đà Nẵng', 'Hải Phòng', 'Cần Thơ'];
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Chọn Thành Phố',
                  style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
              ...cities.map(
                (c) => ListTile(
                  title: Text(c, style: GoogleFonts.nunito(fontWeight: FontWeight.w600)),
                  trailing: _selectedCity == c ? const Icon(Icons.check, color: kPrimaryTeal) : null,
                  onTap: () {
                    setState(() => _selectedCity = c);
                    Navigator.pop(ctx);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
