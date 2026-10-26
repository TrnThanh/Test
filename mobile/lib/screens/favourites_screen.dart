import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../utils/helpers.dart';

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
