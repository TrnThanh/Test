import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import '../l10n/app_language.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/preference_tracker.dart';
import '../theme/app_colors.dart';
import '../utils/helpers.dart';

// ==========================================
// CLIENT MENU & FAVOURITING (GUEST-FIRST)
// ==========================================
class RestaurantMenuWidget extends StatefulWidget {
  final ApiService api;
  final Restaurant restaurant;
  final ScrollController scrollController;
  final RoleLoginResponse? currentUser;
  final VoidCallback onRequireLogin;
  final void Function(double lat, double lon, [Restaurant? restaurant])? onNavigateToMap;

  const RestaurantMenuWidget({
    super.key,
    required this.api,
    required this.restaurant,
    required this.scrollController,
    this.currentUser,
    required this.onRequireLogin,
    this.onNavigateToMap,
  });

  @override
  State<RestaurantMenuWidget> createState() => _RestaurantMenuWidgetState();
}

class _RestaurantMenuWidgetState extends State<RestaurantMenuWidget> {
  List<Category> _categories = [];
  List<Dish> _dishes = [];
  Set<int> _favouriteDishIds = {};
  int? _selectedCategoryId;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMenu();
    _loadUserFavourites();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMenu() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cats = await widget.api.getRestaurantCategories(widget.restaurant.id);
      final dishes = await widget.api.getRestaurantDishes(widget.restaurant.id);
      if (mounted) {
        setState(() {
          _categories = cats;
          _dishes = dishes;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _loadUserFavourites() async {
    if (widget.currentUser == null || widget.currentUser!.role != 'user') return;
    try {
      final favs = await widget.api.getUserFavourites(widget.currentUser!.id);
      if (mounted) {
        setState(() {
          _favouriteDishIds = favs.map((f) => f.dishId).toSet();
        });
      }
    } catch (_) {}
  }

  Future<void> _toggleFavourite(Dish dish) async {
    if (widget.currentUser == null || widget.currentUser!.role != 'user') {
      // Auth Gate: Yêu cầu đăng nhập
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.lock_outline_rounded, color: kPrimaryGreen),
              const SizedBox(width: 8),
              Expanded(
                child: Text(tr('login_required'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ),
            ],
          ),
          content: Text(
            tr('login_required_desc'),
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(tr('maybe_later'), style: const TextStyle(color: Colors.grey)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: kPrimaryGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
                widget.onRequireLogin();
              },
              child: Text(tr('btn_login_now')),
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
          SnackBar(
            content: Text(tr('dish_removed_fav')),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } else {
        await widget.api.addFavouriteDish(widget.currentUser!.id, dish.id);
        if (!mounted) return;
        setState(() => _favouriteDishIds.add(dish.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('dish_added_fav')),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  String _formatVnd(double price) {
    final intPrice = price.round();
    final s = intPrice.toString();
    final buffer = StringBuffer();
    final len = s.length;
    for (int i = 0; i < len; i++) {
      if (i > 0 && (len - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(s[i]);
    }
    return '${buffer.toString()} ₫';
  }

  List<Dish> get _displayedDishes {
    var list = _dishes;
    if (_selectedCategoryId != null) {
      list = list.where((d) => d.categoryId == _selectedCategoryId).toList();
    }
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((d) {
        final nameMatch = d.name.toLowerCase().contains(q);
        final descMatch = (d.description ?? '').toLowerCase().contains(q);
        final ingMatch = d.ingredients.any((ing) => ing.toLowerCase().contains(q));
        return nameMatch || descMatch || ingMatch;
      }).toList();
    }
    return list;
  }

  void _showDishDetail(Dish dish) {
    PreferenceTracker.instance.recordDishClick(dish);
    final formattedPrice = _formatVnd(dish.price);
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (bottomSheetContext, setModalState) {
            final isFav = _favouriteDishIds.contains(dish.id);
            return Stack(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(ctx).pop(),
                  child: const SizedBox.expand(),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.82,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                    ),
              child: Column(
                children: [
                  // Drag Handle & Top controls
                  Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 6),
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                      children: [
                        // Dish Large Image
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: dish.imageUrl != null && dish.imageUrl!.isNotEmpty
                                  ? Image.network(
                                      dish.imageUrl!,
                                      width: double.infinity,
                                      height: 220,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => _buildDetailImagePlaceholder(),
                                    )
                                  : _buildDetailImagePlaceholder(),
                            ),
                            Positioned(
                              top: 12,
                              right: 12,
                              child: Material(
                                color: Colors.black.withAlpha(120),
                                shape: const CircleBorder(),
                                child: IconButton(
                                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
                                  onPressed: () => Navigator.pop(ctx),
                                ),
                              ),
                            ),
                            if (dish.isAvailable == false)
                              Positioned(
                                bottom: 12,
                                left: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.red[700],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Tạm ngưng phục vụ',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Title & Price Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    dish.name,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1E293B),
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    formattedPrice,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFFEA580C),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton.filledTonal(
                              style: IconButton.styleFrom(
                                backgroundColor: isFav ? Colors.red[50] : Colors.grey[100],
                              ),
                              icon: Icon(
                                isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                color: isFav ? Colors.red : Colors.grey[600],
                                size: 26,
                              ),
                              tooltip: isFav ? 'Bỏ thích' : 'Thích món này',
                              onPressed: () async {
                                await _toggleFavourite(dish);
                                setModalState(() {});
                              },
                            ),
                          ],
                        ),

                        // Quick info chips (Calories, Spicy, Category)
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (dish.calories != null && dish.calories! > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF7ED),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFFFEDD5)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.local_fire_department_rounded, size: 16, color: Color(0xFFEA580C)),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${dish.calories} kcal',
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFFC2410C),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (dish.spicyLevel > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFFEE2E2)),
                                ),
                                child: Text(
                                  '🌶️ Độ cay: Cấp ${dish.spicyLevel}',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFDC2626),
                                  ),
                                ),
                              ),
                            if (dish.categoryName != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFDBEAFE)),
                                ),
                                child: Text(
                                  dish.categoryName!,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF2563EB),
                                  ),
                                ),
                              ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Bữa: ${dish.mealType}',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Description
                        if (dish.description != null && dish.description!.isNotEmpty) ...[
                          const SizedBox(height: 18),
                          const Text(
                            'Mô tả món ăn',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            dish.description!,
                            style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.5),
                          ),
                        ],

                        // Allergens Warning
                        if (dish.allergens.isNotEmpty) ...[
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFBEB),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFFDE68A)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 22),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Cảnh báo dị ứng thực phẩm',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13.5,
                                          color: Color(0xFF92400E),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 4,
                                        children: dish.allergens.map((alg) => Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: const Color(0xFFFCD34D)),
                                          ),
                                          child: Text(
                                            alg,
                                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFFB45309)),
                                          ),
                                        )).toList(),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Ingredients List
                        if (dish.ingredients.isNotEmpty) ...[
                          const SizedBox(height: 18),
                          const Text(
                            'Nguyên liệu chính',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: dish.ingredients.map((ing) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFDCFCE7)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check_circle_outline, size: 14, color: Color(0xFF16A34A)),
                                  const SizedBox(width: 5),
                                  Text(
                                    ing,
                                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF15803D), fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            )).toList(),
                          ),
                        ],

                        // Dietary Tags
                        if (dish.dietaryTags.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: dish.dietaryTags.map((dt) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3E8FF),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFE9D5FF)),
                              ),
                              child: Text(
                                '#$dt',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF7E22CE), fontWeight: FontWeight.w600),
                              ),
                            )).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Fixed Bottom Action Button
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(10),
                          blurRadius: 10,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      top: false,
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: isFav ? Colors.red[600] : kPrimaryGreen,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          icon: Icon(
                            isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: Colors.white,
                          ),
                          label: Text(
                            isFav ? 'Đã lưu trong món yêu thích' : 'Lưu vào món ăn yêu thích',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          onPressed: () async {
                            await _toggleFavourite(dish);
                            setModalState(() {});
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
          },
        );
      },
    );
  }

  Widget _buildDetailImagePlaceholder() {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFEBF3EC), Color(0xFFD4E6D8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.restaurant_rounded, color: kPrimaryGreen, size: 54),
      ),
    );
  }

  Widget _buildThumbnailPlaceholder() {
    return Container(
      width: 90,
      height: 90,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF1F5F2), Color(0xFFE2EBE5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.restaurant_rounded, color: Color(0xFF1B3B2B), size: 32),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayed = _displayedDishes;


    return Stack(
      children: [
        Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 4),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // 1. SLEEK HEADER THÔNG TIN QUÁN & BADGES (Screen 6)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2EBE9)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF1F5F9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: Color(0xFF1E293B)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Thực đơn: ${widget.restaurant.name}',
                          style: GoogleFonts.nunito(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w900,
                            color: kTextDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(160),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('1/8', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: kStarYellow, size: 16),
                      const SizedBox(width: 2),
                      Text(
                        '${widget.restaurant.rating ?? 4.7}',
                        style: GoogleFonts.nunito(fontSize: 12.5, fontWeight: FontWeight.w800, color: kTextDark),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '• ${widget.restaurant.distanceKm != null ? "${widget.restaurant.distanceKm!.toStringAsFixed(1)} km" : "800 m"}',
                        style: GoogleFonts.nunito(fontSize: 11.5, color: const Color(0xFF64748B), fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('⭐ Tài trợ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6F4F1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('🛡️ ATTP', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: kPrimaryTeal)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 2. TABS: [Thực đơn] [Đánh giá] [Thông tin] (Screen 6)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.only(bottom: 4),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: kPrimaryTeal, width: 2.5)),
                    ),
                    child: Text(
                      'Thực đơn',
                      style: GoogleFonts.nunito(fontSize: 13.5, fontWeight: FontWeight.w800, color: kPrimaryTeal),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Text(
                    'Đánh giá',
                    style: GoogleFonts.nunito(fontSize: 13.5, fontWeight: FontWeight.w600, color: const Color(0xFF94A3B8)),
                  ),
                  const SizedBox(width: 20),
                  Text(
                    'Thông tin',
                    style: GoogleFonts.nunito(fontSize: 13.5, fontWeight: FontWeight.w600, color: const Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            // Search Bar cho thực đơn
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2EBE5)),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: const TextStyle(fontSize: 13.5),
                  decoration: InputDecoration(
                    hintText: tr('menu_search_hint'),
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF64748B)),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFF64748B)),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Category Chips ngang
            if (_categories.isNotEmpty)
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text('${tr('all_menu')} (${_dishes.length})'),
                        selected: _selectedCategoryId == null,
                        showCheckmark: false,
                        selectedColor: kPrimaryGreen,
                        backgroundColor: const Color(0xFFF4F6F4),
                        labelStyle: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: _selectedCategoryId == null ? Colors.white : const Color(0xFF475569),
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide.none,
                        onSelected: (_) => setState(() => _selectedCategoryId = null),
                      ),
                    ),
                    ..._categories.map((c) {
                      final count = _dishes.where((d) => d.categoryId == c.id).length;
                      final isSelected = _selectedCategoryId == c.id;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text('${c.name} ($count)'),
                          selected: isSelected,
                          showCheckmark: false,
                          selectedColor: kPrimaryGreen,
                          backgroundColor: const Color(0xFFF4F6F4),
                          labelStyle: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : const Color(0xFF475569),
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          side: BorderSide.none,
                          onSelected: (_) => setState(() => _selectedCategoryId = c.id),
                        ),
                      );
                    }),
                  ],
                ),
              ),

            const SizedBox(height: 6),
            const Divider(height: 1, color: Color(0xFFF0F4F1)),

            // Danh sách món ăn Bento Card
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: kPrimaryGreen))
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline_rounded, color: Colors.red, size: 36),
                              const SizedBox(height: 8),
                              Text('Lỗi: $_error', style: const TextStyle(color: Colors.red)),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: _loadMenu,
                                icon: const Icon(Icons.refresh),
                                label: Text(tr('retry')),
                              ),
                            ],
                          ),
                        )
                      : displayed.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Icon(Icons.search_off_rounded, color: Color(0xFF94A3B8), size: 36),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _searchQuery.isNotEmpty
                                        ? 'Không tìm thấy món ăn nào khớp với "$_searchQuery"'
                                        : 'Quán chưa có món trong danh mục này',
                                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 13.5),
                                  ),
                                  if (_searchQuery.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    TextButton(
                                      onPressed: () {
                                        _searchController.clear();
                                        FocusScope.of(context).unfocus();
                                        setState(() => _searchQuery = '');
                                      },
                                      child: Text(tr('clear_search'), style: const TextStyle(color: kPrimaryGreen)),
                                    ),
                                  ],
                                ],
                              ),
                            )
                          : ListView.separated(
                              controller: widget.scrollController,
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                              itemCount: displayed.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final d = displayed[index];
                                final isFav = _favouriteDishIds.contains(d.id);
                                final formattedPrice = _formatVnd(d.price);

                                return Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFFEAEFEA)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withAlpha(5),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      key: ValueKey('dish-card-${d.id}'),
                                      borderRadius: BorderRadius.circular(16),
                                      onTap: () => _showDishDetail(d),
                                      child: Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                          // Thumbnail ảnh món chuẩn mockup NutriFood
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(14),
                                            child: SizedBox(
                                              width: 95,
                                              height: 95,
                                              child: Stack(
                                                children: [
                                                  Positioned.fill(
                                                    child: d.imageUrl != null && d.imageUrl!.isNotEmpty
                                                        ? Image.network(
                                                            d.imageUrl!,
                                                            fit: BoxFit.cover,
                                                            errorBuilder: (_, __, ___) => _buildThumbnailPlaceholder(),
                                                          )
                                                        : _buildThumbnailPlaceholder(),
                                                  ),
                                                  if (index == 0)
                                                    Positioned(
                                                      bottom: 4,
                                                      left: 4,
                                                      child: Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                                        decoration: BoxDecoration(
                                                          color: const Color(0xFF16A34A),
                                                          borderRadius: BorderRadius.circular(4),
                                                        ),
                                                        child: Text(
                                                          'Bán chạy',
                                                          style: GoogleFonts.nunito(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.white),
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),

                                          // Chi tiết món ăn
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  d.name,
                                                  style: const TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w700,
                                                    color: Color(0xFF1E293B),
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 3),
                                                Text(
                                                  formattedPrice,
                                                  style: const TextStyle(
                                                    color: Color(0xFFEA580C),
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 14.5,
                                                  ),
                                                ),
                                                if (d.description != null && d.description!.isNotEmpty) ...[
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    d.description!,
                                                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 11.5),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],
                                                const SizedBox(height: 5),

                                                // Hàng badge (Calo, Cay, Chay, Nguyên liệu)
                                                Wrap(
                                                  spacing: 5,
                                                  runSpacing: 4,
                                                  children: [
                                                    if (d.calories != null && d.calories! > 0)
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                        decoration: BoxDecoration(
                                                          color: const Color(0xFFFFF7ED),
                                                          borderRadius: BorderRadius.circular(6),
                                                        ),
                                                        child: Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            const Icon(Icons.local_fire_department_rounded, size: 11, color: Color(0xFFEA580C)),
                                                            const SizedBox(width: 2),
                                                            Text(
                                                              '${d.calories} kcal',
                                                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFC2410C)),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    if (d.spicyLevel > 0)
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                        decoration: BoxDecoration(
                                                          color: const Color(0xFFFEF2F2),
                                                          borderRadius: BorderRadius.circular(6),
                                                        ),
                                                        child: Text(
                                                          '🌶️' * d.spicyLevel.clamp(1, 3),
                                                          style: const TextStyle(fontSize: 10),
                                                        ),
                                                      ),
                                                    if (d.categoryName != null)
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                        decoration: BoxDecoration(
                                                          color: const Color(0xFFEFF6FF),
                                                          borderRadius: BorderRadius.circular(6),
                                                        ),
                                                        child: Text(
                                                          d.categoryName!,
                                                          style: const TextStyle(fontSize: 10, color: Color(0xFF2563EB), fontWeight: FontWeight.w500),
                                                        ),
                                                      ),
                                                    if (d.dietaryTags.isNotEmpty)
                                                      ...d.dietaryTags.map((dt) => Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                        decoration: BoxDecoration(
                                                          color: const Color(0xFFF3E8FF),
                                                          borderRadius: BorderRadius.circular(6),
                                                        ),
                                                        child: Text(
                                                          dt,
                                                          style: const TextStyle(fontSize: 10, color: Color(0xFF7E22CE), fontWeight: FontWeight.w600),
                                                        ),
                                                      )),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),

                                          // Nút Tim yêu thích
                                          IconButton(
                                            icon: Icon(
                                              isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                              color: isFav ? Colors.red : const Color(0xFF94A3B8),
                                              size: 22,
                                            ),
                                            tooltip: isFav ? 'Bỏ thích' : 'Thích món này',
                                            onPressed: () => _toggleFavourite(d),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                              },
                            ),
            ),
          ],
        ),

        // Sticky Bottom Bar: [♡ Đã lưu] & [Đặt bàn] (Screen 6)
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(12),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kPrimaryTeal,
                      side: const BorderSide(color: kPrimaryTeal, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    icon: const Icon(Icons.favorite_border_rounded, size: 18),
                    label: Text(
                      'Đã lưu',
                      style: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 13.5),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(tr('saved_restaurant_fav')),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: kPrimaryTeal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    icon: const Icon(Icons.table_restaurant_rounded, size: 18),
                    label: Text(
                      'Đặt bàn',
                      style: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                    onPressed: () {
                      if (widget.onNavigateToMap != null) {
                        Navigator.pop(context);
                        widget.onNavigateToMap!(
                          widget.restaurant.latitude,
                          widget.restaurant.longitude,
                          widget.restaurant,
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Chức năng đặt bàn trực tuyến đang hoàn thiện!')),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
