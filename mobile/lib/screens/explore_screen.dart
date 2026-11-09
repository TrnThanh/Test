import '../widgets/app_top_bar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import '../l10n/app_language.dart';
import '../models/models.dart';
import '../painters/golden_moon.dart';
import '../painters/leaves_painter.dart';
import '../painters/spark_painter.dart';
import '../painters/weather_painters.dart';
import '../painters/app_illustrations.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../theme/app_colors.dart';
import '../utils/helpers.dart';
import '../widgets/restaurant_menu_widget.dart';

class ExploreScreen extends StatefulWidget {
  final ApiService api;
  final RoleLoginResponse? currentUser;
  final VoidCallback onRequireLogin;
  final String? initialCategory;
  final void Function(double lat, double lon, [Restaurant? restaurant])? onNavigateToMap;
  final VoidCallback? onNavigateToAccount;
  final ScrollController? scrollController;

  const ExploreScreen({
    super.key,
    required this.api,
    this.currentUser,
    required this.onRequireLogin,
    this.initialCategory,
    this.onNavigateToMap,
    this.onNavigateToAccount,
    this.scrollController,
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
  String _selectedCity = 'Gia Lâm - Hà Nội';

  CurrentWeather? _currentWeather;
  double? _userLat;
  double? _userLon;
  ContextualRecommendation? _contextualRec;
  int _heroIndex = 0;
  bool _showAllNearby = false;
  static const int _kDefaultNearbyLimit = 10;

  String _formatCurrency(double price) {
    final intPrice = price.round();
    if (intPrice >= 1000) {
      final s = intPrice.toString();
      final parts = <String>[];
      for (int i = s.length; i > 0; i -= 3) {
        final start = i - 3 > 0 ? i - 3 : 0;
        parts.insert(0, s.substring(start, i));
      }
      return '${parts.join(".")}đ';
    }
    return '$intPriceđ';
  }


  final List<String> _categories = const [
    'Tất cả',
    'Phở, Bún & Món nước',
    'Cơm & Xôi',
    'Bánh mì',
    'Bánh truyền thống & Món cuốn',
    'Lẩu & Nướng',
    'Ốc & Quán lai rai',
    'Đồ ăn vặt',
    'Chè & Tráng miệng',
    'Cà phê & Thức uống giải khát',
    'Ẩm thực Chay & Thực dưỡng',
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
    if (widget.currentUser?.id != oldWidget.currentUser?.id) {
      _contextualRec = null;
      _heroIndex = 0;
      _loadData();
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

    if (raw == null || raw.trim().isEmpty) return 'Gia Lâm - Hà Nội';
    final lower = raw.toLowerCase().trim();

    // 2. Tra cứu theo từ khoá thành phố / quận huyện
    if (lower.contains('gia lâm') || lower.contains('gia lam')) {
      return 'Gia Lâm - Hà Nội';
    } else if (lower.contains('hà nội') ||
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

  String _getCategoryLabel(String cat) {
    const map = {
      'Tất cả': 'cat_all',
      'Phở, Bún & Món nước': 'cat_noodles',
      'Cơm & Xôi': 'cat_rice',
      'Bánh mì': 'cat_banhmi',
      'Bánh truyền thống & Món cuốn': 'cat_traditional',
      'Lẩu & Nướng': 'cat_bbq',
      'Ốc & Quán lai rai': 'cat_seafood',
      'Đồ ăn vặt': 'cat_snacks',
      'Chè & Tráng miệng': 'cat_desserts',
      'Cà phê & Thức uống giải khát': 'cat_coffee',
      'Ẩm thực Chay & Thực dưỡng': 'cat_vegetarian',
    };
    final k = map[cat];
    if (k != null) return tr(k);
    return cat;
  }

  IconData _getCategoryIcon(String cat) {
    if (cat == 'Phở, Bún & Món nước' || cat == 'Phở' || cat == 'Bún') {
      return Icons.ramen_dining_outlined;
    } else if (cat == 'Cơm & Xôi' || cat == 'Cơm') {
      return Icons.rice_bowl_outlined;
    } else if (cat == 'Bánh mì') {
      return Icons.bakery_dining_outlined;
    } else if (cat == 'Bánh truyền thống & Món cuốn') {
      return Icons.lunch_dining_outlined;
    } else if (cat == 'Lẩu & Nướng') {
      return Icons.outdoor_grill_outlined;
    } else if (cat == 'Ốc & Quán lai rai') {
      return Icons.sports_bar_outlined;
    } else if (cat == 'Đồ ăn vặt' || cat == 'Ăn vặt') {
      return Icons.fastfood_outlined;
    } else if (cat == 'Chè & Tráng miệng') {
      return Icons.icecream_outlined;
    } else if (cat == 'Cà phê & Thức uống giải khát' || cat == 'Đồ uống') {
      return Icons.local_cafe_outlined;
    } else if (cat == 'Ẩm thực Chay & Thực dưỡng') {
      return Icons.eco_outlined;
    }
    return Icons.restaurant;
  }

  String _getMealGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 4 && hour < 11) {
      return tr('greeting_morning');
    } else if (hour >= 11 && hour < 14) {
      return tr('greeting_noon');
    } else if (hour >= 14 && hour < 18) {
      return tr('greeting_afternoon');
    } else {
      return tr('greeting_evening');
    }
  }

  String _getWeatherShortStatus(CurrentWeather? weather) {
    final isNight = _isNightTime(weather);
    if (weather == null) return isNight ? tr('weather_night_cool') : tr('weather_day_cool');
    String desc = weather.description.trim();
    final lower = desc.toLowerCase();
    if (lower.contains(' tại ')) {
      desc = desc.substring(0, lower.indexOf(' tại ')).trim();
    }
    if (lower.contains('mát mẻ')) {
      return isNight ? tr('weather_night_cool') : tr('weather_day_cool');
    }
    if (AppLanguage.instance.isVietnamese && desc.isNotEmpty) {
      return desc[0].toUpperCase() + desc.substring(1);
    }
    final temp = weather.temperature;
    if (temp < 20) return isNight ? tr('weather_chilly') : tr('weather_chilly');
    if (temp < 26) return isNight ? tr('weather_night_cool') : tr('weather_day_cool');
    if (temp < 32) return isNight ? tr('weather_mild') : tr('weather_sunny');
    return isNight ? tr('weather_hot') : tr('weather_hot');
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
          final hasGpsChanged = _userLat != lat || _userLon != lon;
          if (mounted) {
            setState(() {
              _userLat = lat;
              _userLon = lon;
            });
          }
          if (hasGpsChanged) {
            _loadData(userLat: lat, userLon: lon);
          }
          detectedCity = _resolveToCityName(null, lat: lat, lon: lon);
          widget.api.reverseMap(lat!, lon!).then((addr) {
            if (mounted && addr.isNotEmpty) {
              setState(() {
                _selectedCity = _resolveToCityName(addr, lat: lat, lon: lon);
              });
            }
          }).catchError((_) {});
        } else {
          // Khong co GPS thuc te -> Khong gan toa do gia, giu mac dinh nhan thanh pho
          detectedCity = 'Hà Nội';
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

  Future<void> _loadData({double? userLat, double? userLon}) async {
    final lat = userLat ?? _userLat;
    final lon = userLon ?? _userLon;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Tai truc tiep danh sach tat ca quan an dang hoat dong (khong phu thuoc ban kinh / GPS nearby)
      List<Restaurant> allList = [];
      try {
        allList = await widget.api.getRestaurants();
      } catch (_) {
        allList = [];
      }

      ContextualRecommendation? carRec;
      if (lat != null && lon != null) {
        try {
          carRec = await widget.api.getContextualRecommendations(
            lat: lat,
            lon: lon,
            userId: widget.currentUser?.id,
            temp: _currentWeather?.temperature,
          );
        } catch (_) {}
      }

      if (carRec != null) {
        final recMap = <int, RestaurantRecommendation>{};
        if (carRec.heroRestaurant != null && carRec.heroRestaurant!.recommendation != null) {
          recMap[carRec.heroRestaurant!.id] = carRec.heroRestaurant!.recommendation!;
        }
        for (final r in carRec.recommendedRestaurants) {
          if (r.recommendation != null) {
            recMap[r.id] = r.recommendation!;
          }
        }

        allList = allList.map((r) {
          if (recMap.containsKey(r.id)) {
            return Restaurant(
              id: r.id,
              name: r.name,
              address: r.address,
              phone: r.phone,
              description: r.description,
              openTime: r.openTime,
              closeTime: r.closeTime,
              latitude: r.latitude,
              longitude: r.longitude,
              isSponsor: r.isSponsor,
              isActive: r.isActive,
              distanceMeters: r.distanceMeters,
              distanceKm: r.distanceKm,
              serviceLicenses: r.serviceLicenses,
              recommendation: recMap[r.id],
            );
          }
          return r;
        }).toList();
      }

      setState(() {
        _restaurants = allList;
        _contextualRec = carRec;
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
    if (widget.currentUser == null) {
      list = list.where((r) => r.isSponsor).toList();
    }
    if (_currentCategory != null && _currentCategory != 'Tất cả') {
      final cat = _currentCategory!.toLowerCase();
      list = list.where((r) {
        final name = r.name.toLowerCase();
        final desc = (r.description ?? '').toLowerCase();
        final featuredDishName = (r.recommendation?.featuredDish.name ?? '').toLowerCase();

        bool match(String keyword) =>
            name.contains(keyword) || desc.contains(keyword) || featuredDishName.contains(keyword);

        if (cat == 'phở, bún & món nước' || cat == 'phở & bún' || cat == 'phở' || cat == 'bún') {
          return match('phở') || match('bún') || match('miến') || match('mì') || match('mỳ') || match('hủ tiếu') || match('bánh canh');
        }
        if (cat == 'cơm & xôi' || cat == 'cơm') return match('cơm') || match('xôi') || match('niêu') || match('sườn');
        if (cat == 'bánh mì') return match('bánh mì') || match('bánh mỳ') || match('pate') || match('bánh bao');
        if (cat == 'bánh truyền thống & món cuốn') {
          return match('bánh cuốn') || match('bánh xèo') || match('gỏi cuốn') || match('bún chả') || match('bún đậu') || match('bánh bèo') || match('bột lọc');
        }
        if (cat == 'lẩu & nướng') return match('lẩu') || match('nướng') || match('bbq');
        if (cat == 'ốc & quán lai rai') return match('ốc') || match('ngao') || match('sò') || match('nhậu') || match('bia') || match('chân gà') || match('mực');
        if (cat == 'đồ ăn vặt' || cat == 'ăn vặt') return match('ăn vặt') || match('nem chua rán') || match('khoai') || match('bánh tráng');
        if (cat == 'chè & tráng miệng') return match('chè') || match('caramen') || match('tàu hũ') || match('kem') || match('sữa chua') || match('flan');
        if (cat == 'cà phê & thức uống giải khát' || cat == 'cà phê & trà sữa' || cat == 'đồ uống') {
          return match('cà phê') || match('cafe') || match('coffee') || match('trà sữa') || match('trà') || match('nước mía') || match('sinh tố') || match('nước');
        }
        if (cat == 'ẩm thực chay & thực dưỡng' || cat == 'món chay') return match('chay') || match('thực dưỡng') || match('nấm');
        return match(cat);
      }).toList();
    }
    if (_searchQuery.trim().isEmpty) return list;
    final q = _searchQuery.toLowerCase().trim();
    return list.where((r) =>
        r.name.toLowerCase().contains(q) ||
        (r.address != null && r.address!.toLowerCase().contains(q)) ||
        (r.description != null && r.description!.toLowerCase().contains(q))).toList();
  }

  Widget _buildHeroCard(Restaurant hero, int index) {
    return Container(
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: Image.network(
                    hero.recommendation?.featuredDish.imageUrl ?? _getFoodImage(hero, index),
                    width: double.infinity,
                    height: 135,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 135,
                      color: const Color(0xFFEBF3EC),
                      alignment: Alignment.center,
                      child: const Icon(Icons.restaurant, color: Color(0xFF1B3B2B), size: 44),
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
                    child: Text(
                      (hero.recommendation != null && hero.recommendation!.badges.isNotEmpty)
                          ? hero.recommendation!.badges.first
                          : tr('match_taste'),
                      style: const TextStyle(
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
                          '${_getRatingScore(hero).toStringAsFixed(1)} (${_getDistanceText(hero, index)})',
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
              padding: const EdgeInsets.all(14),
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
                            fontFamily: 'Nunito',
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF112319),
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Text(
                            hero.recommendation != null
                                ? _formatCurrency(hero.recommendation!.featuredDish.price)
                                : '65.000đ',
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1B3B2B),
                            ),
                          ),
                          const Positioned(
                            top: -6,
                            right: -12,
                            child: SparkBurst(width: 10, height: 10),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: Color(0xFF8E9892)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          hero.recommendation?.explanation ?? hero.address ?? '15 Phố Cổ Bi, Gia Lâm, Hà Nội',
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
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: (hero.recommendation != null && hero.recommendation!.badges.isNotEmpty)
                          ? hero.recommendation!.badges.map((b) => Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEBF3EC),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                b,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF1B3B2B),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )).toList()
                          : [
                              Container(
                                margin: const EdgeInsets.only(right: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              widget.api.trackUserInteraction(userId: widget.currentUser?.id, categoryId: hero.categoryId);
                              _showMenuBottomSheet(hero);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEA580C),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              elevation: 0,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  tr('explore_now'),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_forward_rounded, size: 14),
                              ],
                            ),
                          ),
                          const Positioned(
                            left: -12,
                            child: SparkBurst(width: 10, height: 10),
                          ),
                          const Positioned(
                            right: -12,
                            child: SparkBurst(width: 10, height: 10),
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
    );
  }

  void _showMenuBottomSheet(Restaurant r) {
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
            builder: (_, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: RestaurantMenuWidget(
                  api: widget.api,
                  restaurant: r,
                  scrollController: scrollController,
                  currentUser: widget.currentUser,
                  onRequireLogin: widget.onRequireLogin,
                  onNavigateToMap: widget.onNavigateToMap,
                ),
              );
            },
          ),
        ],
      ),
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
    if (r.rating != null && r.rating! > 0) {
      return r.rating!;
    }
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
    final originLat = _userLat;
    final originLon = _userLon;
    if (originLat != null && originLon != null && r.latitude != 0 && r.longitude != 0) {
      final distMeters = const Distance().as(
        LengthUnit.Meter,
        LatLng(originLat, originLon),
        LatLng(r.latitude, r.longitude),
      );
      if (distMeters < 1000) {
        return '${distMeters.round()}m';
      }
      return '${(distMeters / 1000).toStringAsFixed(1)}km';
    }
    return '';
  }

  String _getPriceRange(Restaurant r) {
    final base = (r.id * 5) % 25 + 30; // 30k to 55k
    final max = base + 25; // 55k to 80k
    return '$base.000đ - $max.000đ';
  }

  @override
  Widget build(BuildContext context) {
    final filteredRestaurants = _filteredList;
    final isDefaultFeed = (_currentCategory == null || _currentCategory == 'Tất cả') && _searchQuery.trim().isEmpty;

    // 1. Vùng quán gợi ý (Độc lập, KHÔNG bị ảnh hưởng bởi tag lọc/search ở trên)
    final List<Restaurant> heroItems;
    if (_contextualRec != null) {
      final allRecs = [
        if (_contextualRec!.heroRestaurant != null) _contextualRec!.heroRestaurant!,
        ..._contextualRec!.recommendedRestaurants,
      ];
      final filteredRecs = widget.currentUser == null
          ? allRecs.where((r) => r.isSponsor).toList()
          : allRecs;
      final validRecs = filteredRecs.take(5).toList();
      if (validRecs.isNotEmpty) {
        heroItems = validRecs;
      } else {
        final fallback = widget.currentUser == null
            ? _restaurants.where((r) => r.isSponsor).toList()
            : _restaurants;
        heroItems = fallback.isNotEmpty ? fallback.take(5).toList() : [];
      }
    } else {
      final fallback = widget.currentUser == null
          ? _restaurants.where((r) => r.isSponsor).toList()
          : _restaurants;
      heroItems = fallback.isNotEmpty ? fallback.take(5).toList() : [];
    }

    // 2. Phần quán ăn gần đây (Quán ngon quanh đây - THAY ĐỔI theo tag lọc và search)
    final List<Restaurant> listItems;
    if (isDefaultFeed) {
      final heroIds = heroItems.map((e) => e.id).toSet();
      final remaining = filteredRestaurants.where((r) => !heroIds.contains(r.id)).toList();
      listItems = remaining.isNotEmpty ? remaining : filteredRestaurants;
    } else {
      listItems = filteredRestaurants;
    }

    final hasMoreNearby = listItems.length > _kDefaultNearbyLimit;
    final displayedItems = _showAllNearby ? listItems : listItems.take(_kDefaultNearbyLimit).toList();

    final activeIndex = heroItems.isNotEmpty ? _heroIndex.clamp(0, heroItems.length - 1) : 0;
    final hero = heroItems.isNotEmpty ? heroItems[activeIndex] : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      appBar: AppTopBar(
        title: 'Trang Chủ',
        currentUser: widget.currentUser,
        onAvatarTap: widget.onNavigateToAccount,
      ),
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
                    controller: widget.scrollController,
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 1. GREETING TAG & HEADING (Chuẩn Style NutriFood/PTC1)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEBF9F1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.spa_outlined, size: 14, color: Color(0xFF16A34A)),
                                    SizedBox(width: 5),
                                    Flexible(
                                      child: Text(
                                        'Chào ngày mới tươi vui & tràn đầy năng lượng',
                                        overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Color(0xFF16A34A),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        style: GoogleFonts.baloo2(
                                          fontSize: 26,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF111827),
                                          height: 1.2,
                                        ),
                                        children: [
                                          const TextSpan(text: 'Hôm nay, '),
                                          TextSpan(
                                            text: 'mình ăn gì nhỉ?',
                                            style: GoogleFonts.baloo2(
                                              color: const Color(0xFF16A34A),
                                              fontStyle: FontStyle.italic,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEBF9F1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.local_florist_rounded, color: Color(0xFF16A34A), size: 22),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Cùng PTC1 chọn món ngon, nhẹ lành và chuẩn dáng ✨',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 14),

                              // 2. WEATHER CARD: 28°C Có mây + Gợi ý + Anime Chef Girl (Screen 2)
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(22),
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFE3F4F6), Color(0xFFEDF8F7)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: kPrimaryTeal.withAlpha(15),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                child: Stack(
                                  children: [
                                    // Custom Paint Landscape cho test
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      width: 100,
                                      height: 60,
                                      child: Opacity(
                                        opacity: 0.15,
                                        child: CustomPaint(
                                          painter: WeatherLandscapePainter(isNight: _isNightTime(_currentWeather)),
                                        ),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.wb_sunny_rounded, color: Color(0xFFFFB800), size: 26),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    '${_currentWeather?.temperature.round() ?? 28}°C',
                                                    style: const TextStyle(
                                                      fontFamily: 'Nunito',
                                                      fontSize: 24,
                                                      fontWeight: FontWeight.w900,
                                                      color: kTextDark,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Flexible(
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: kPrimaryTeal.withAlpha(20),
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                      child: Text(
                                                        _getWeatherShortStatus(_currentWeather),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: const TextStyle(
                                                          fontFamily: 'Nunito',
                                                          color: kPrimaryTeal,
                                                          fontSize: 10.5,
                                                          fontWeight: FontWeight.w800,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${_resolveToCityName(_selectedCity, lat: _userLat, lon: _userLon)} • Độ ẩm ${_currentWeather?.humidity ?? 82}%',
                                                style: GoogleFonts.nunito(
                                                  color: const Color(0xFF64748B),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                'Thích hợp món nướng, lẩu nóng',
                                                style: GoogleFonts.nunito(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                  color: kPrimaryTeal,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const AnimeChefArt(width: 95, height: 95),
                                      ],
                                    ),
                                  ],
                                ),
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
                                        decoration: InputDecoration(
                                          hintText: tr('search_explore_hint'),
                                          hintStyle: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF8E9892),
                                            fontWeight: FontWeight.w500,
                                          ),
                                          prefixIcon: const Icon(Icons.search, color: Color(0xFF5A655F), size: 22),
                                          border: InputBorder.none,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        ),
                                        onChanged: (val) {
                                          setState(() {
                                            _searchQuery = val;
                                          });
                                        },
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
                                    final iconData = _getCategoryIcon(cat);

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
                                                    _getCategoryLabel(cat),
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

                              // PROMO BANNER: Ưu đãi đặc biệt Giảm đến 30% (Screen 5)
                              Container(
                                margin: const EdgeInsets.only(top: 4, bottom: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF0E6A69), Color(0xFF16807E)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF0E6A69).withAlpha(50),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Ưu đãi đặc biệt',
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 1),
                                          const Text(
                                            'Giảm đến 30%',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          InkWell(
                                            onTap: () {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Đang áp dụng mã giảm giá 30%!')),
                                              );
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    'Săn ngay',
                                                    style: TextStyle(
                                                      color: Color(0xFF0E6A69),
                                                      fontSize: 11.5,
                                                      fontWeight: FontWeight.w800,
                                                    ),
                                                  ),
                                                  SizedBox(width: 4),
                                                  Icon(Icons.arrow_forward_rounded, size: 12, color: Color(0xFF0E6A69)),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    const NoodleBowlArt(size: 60),
                                  ],
                                ),
                              ),

                              // 5. SECTION: GỢI Ý RIÊNG CHO BẠN
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Flexible(
                                              child: Text(
                                                tr('hungry_explore'),
                                                style: GoogleFonts.baloo2(
                                                  fontSize: 19,
                                                  fontWeight: FontWeight.w800,
                                                  color: const Color(0xFF112319),
                                                  letterSpacing: -0.2,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            const SparkBurst(width: 14, height: 12),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          (widget.currentUser != null)
                                              ? 'Gợi ý cá nhân hoá cho ${widget.currentUser!.fullName ?? widget.currentUser!.email}'
                                              : 'Gợi ý dành riêng cho bạn hôm nay',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF6E7A73),
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (heroItems.length > 1)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEBF3EC),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: const Color(0xFFD6E6D8)),
                                      ),
                                      child: Text(
                                        '${activeIndex + 1}/${heroItems.length}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF1B3B2B),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              // 6. HERO BIG FOOD CARD (Có 2 nút mũi tên trái phải nổi trên card)
                              if (hero != null) ...[
                                Stack(
                                  clipBehavior: Clip.none,
                                  alignment: Alignment.center,
                                  children: [
                                    AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 250),
                                      child: KeyedSubtree(
                                        key: ValueKey('${hero.id}_$activeIndex'),
                                        child: _buildHeroCard(hero, activeIndex),
                                      ),
                                    ),
                                    if (heroItems.length > 1) ...[
                                      // Nút mũi tên bên TRÁI mép card (chính giữa chiều dọc, nửa ngoài nửa trong mép card)
                                      Positioned(
                                        left: -14,
                                        top: 0,
                                        bottom: 0,
                                        child: Center(
                                          child: Material(
                                            color: Colors.white,
                                            shape: const CircleBorder(),
                                            elevation: 4,
                                            shadowColor: Colors.black38,
                                            child: InkWell(
                                              customBorder: const CircleBorder(),
                                              onTap: () {
                                                setState(() {
                                                  _heroIndex = (_heroIndex - 1 + heroItems.length) % heroItems.length;
                                                });
                                              },
                                              child: const SizedBox(
                                                width: 36,
                                                height: 36,
                                                child: Icon(
                                                  Icons.chevron_left_rounded,
                                                  size: 24,
                                                  color: Color(0xFF1B3B2B),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Nút mũi tên bên PHẢI mép card (chính giữa chiều dọc, nửa ngoài nửa trong mép card)
                                      Positioned(
                                        right: -14,
                                        top: 0,
                                        bottom: 0,
                                        child: Center(
                                          child: Material(
                                            color: Colors.white,
                                            shape: const CircleBorder(),
                                            elevation: 4,
                                            shadowColor: Colors.black38,
                                            child: InkWell(
                                              customBorder: const CircleBorder(),
                                              onTap: () {
                                                setState(() {
                                                  _heroIndex = (_heroIndex + 1) % heroItems.length;
                                                });
                                              },
                                              child: const SizedBox(
                                                width: 36,
                                                height: 36,
                                                child: Icon(
                                                  Icons.chevron_right_rounded,
                                                  size: 24,
                                                  color: Color(0xFF1B3B2B),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                if (heroItems.length > 1) ...[
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(heroItems.length, (idx) {
                                      final isActive = idx == activeIndex;
                                      return GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _heroIndex = idx;
                                          });
                                        },
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          margin: const EdgeInsets.symmetric(horizontal: 4),
                                          width: isActive ? 22 : 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: isActive ? const Color(0xFF1B3B2B) : const Color(0xFFD1DCD3),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                ],
                              ],
                              const SizedBox(height: 24),

                              // 7. SECTION: Khám phá quán ngon
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      tr('explore_restaurants'),
                                      style: GoogleFonts.baloo2(
                                        fontSize: 19,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF112319),
                                        letterSpacing: -0.2,
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
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          tr('see_all'),
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF1B3B2B),
                                          ),
                                        ),
                                        const SizedBox(width: 2),
                                        const Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF1B3B2B)),
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
                          Text('${tr('connection_error')}: $_error', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _loadData,
                            style: ElevatedButton.styleFrom(backgroundColor: kPrimaryGreen),
                            child: Text(tr('retry'), style: const TextStyle(color: Colors.white)),
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
                        Text(tr('no_restaurant_found'), style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  ),
                )
              else ...[
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final r = displayedItems[index];
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
                            onTap: () {
                              widget.api.trackUserInteraction(userId: widget.currentUser?.id, categoryId: r.categoryId);
                              _showMenuBottomSheet(r);
                            },
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
                                          Container(
                                            margin: const EdgeInsets.only(left: 6),
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFEF2F2),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: const Color(0xFFFCA5A5)),
                                            ),
                                            child: const Text(
                                              'Giảm 30%',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFFDC2626),
                                              ),
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
                                      if (r.recommendation != null) ...[
                                        const SizedBox(height: 5),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEBF8EE),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            '💡 Gợi ý: ${r.recommendation!.featuredDish.name} • ${_formatCurrency(r.recommendation!.featuredDish.price)}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF1B3B2B),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
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
                                          Text(' • $distanceText', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
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
                      childCount: displayedItems.length,
                    ),
                  ),
                ),
                if (hasMoreNearby)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                      child: Center(
                        child: _showAllNearby
                            ? TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _showAllNearby = false;
                                  });
                                },
                                icon: const Icon(Icons.expand_less_rounded, size: 20, color: Color(0xFF6E7A73)),
                                label: Text(
                                  tr('collapse_list'),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF6E7A73),
                                  ),
                                ),
                              )
                            : OutlinedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _showAllNearby = true;
                                  });
                                },
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFF1B3B2B), width: 1.2),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                ),
                                icon: const Icon(Icons.expand_more_rounded, size: 20, color: Color(0xFF1B3B2B)),
                                label: Text(
                                  '${tr('see_more')} ${listItems.length - _kDefaultNearbyLimit} ${tr('other_restaurants')}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1B3B2B),
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ),
              ],
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

