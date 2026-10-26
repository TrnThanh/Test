import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';

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
    return Stack(
      children: [
        Column(
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
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
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
        ),
        if (widget.onNavigateToMap != null)
          Positioned(
            right: 16,
            bottom: 20,
            child: Material(
              elevation: 5,
              shadowColor: Colors.black38,
              borderRadius: BorderRadius.circular(24),
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () {
                  Navigator.pop(context);
                  widget.onNavigateToMap!(
                    widget.restaurant.latitude,
                    widget.restaurant.longitude,
                    widget.restaurant,
                  );
                },
                child: Ink(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  decoration: BoxDecoration(
                    color: kPrimaryGreen,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: kPrimaryGreen.withAlpha(100),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.directions_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 6),
                      Text(
                        'Chỉ đường',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
