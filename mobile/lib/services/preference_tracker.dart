import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

/// Dịch vụ quản lý và tích lũy điểm sở thích theo thể loại món ăn cục bộ trên thiết bị (Local Preference Score Tracker).
///
/// Hỗ trợ:
/// 1. Tự động cộng điểm cho thể loại món ăn khi người dùng xem/click món ăn.
/// 2. Bảng quy định từ khóa tự động nhận diện thể loại khi `dish.categoryId == null`.
/// 3. Cơ chế cooldown 30 giây chống spam click cùng một món.
/// 4. Giới hạn điểm trần (tối đa 100 điểm / thể loại).
/// 5. Lưu trữ bền vững đa nền tảng (Flutter Web qua localStorage, Android/iOS qua SharedPreferences).
class PreferenceTracker extends ChangeNotifier {
  // Singleton pattern
  static final PreferenceTracker instance = PreferenceTracker._internal();

  PreferenceTracker._internal();

  /// Điểm số cộng mặc định mỗi lượt xem món
  static const int defaultIncrement = 1;

  /// Giới hạn điểm trần tối đa cho mỗi thể loại
  static const int maxScore = 100;

  /// Thời gian chờ tối thiểu giữa các lần click cùng một món để tránh spam
  static const Duration cooldownDuration = Duration(seconds: 30);

  /// Khóa lưu trữ trong SharedPreferences
  static const String storageKey = 'ptc1_preference_category_scores_v1';

  /// Bảng điểm hiện tại: categoryId (int) -> score (int)
  final Map<int, int> _scores = {};

  /// Ghi nhận thời điểm click gần nhất theo dishId (chỉ lưu trên RAM)
  final Map<int, DateTime> _lastDishTap = {};

  SharedPreferences? _prefs;
  bool _isLoaded = false;

  /// Bảng từ khóa chuẩn ánh xạ nhanh tên món sang 10 thể loại toàn cục của hệ thống PTC1
  /// (Đồng bộ với CategoryService và backend weather_food_rules.py)
  static const Map<String, int> keywordCategoryMap = {
    // 1: Phở, Bún & Món nước
    'phở': 1, 'pho': 1, 'bún': 1, 'bun': 1, 'miến': 1, 'mien': 1,
    'hủ tiếu': 1, 'hu tieu': 1, 'mì': 1, 'mi': 1, 'mỳ': 1, 'my': 1,
    'ramen': 1, 'bánh canh': 1, 'banh canh': 1,

    // 2: Cơm & Xôi
    'cơm': 2, 'com': 2, 'xôi': 2, 'xoi': 2, 'rang': 2, 'niêu': 2, 'nieu': 2, 'sườn': 2, 'suon': 2,

    // 3: Bánh mì
    'bánh mì': 3, 'banh mi': 3, 'bánh mỳ': 3, 'banh my': 3, 'sandwich': 3, 'burger': 3, 'pate': 3,

    // 4: Bánh truyền thống & Món cuốn
    'bánh cuốn': 4, 'banh cuon': 4, 'gỏi cuốn': 4, 'goi cuon': 4, 'bánh xèo': 4, 'banh xeo': 4,
    'bún chả': 4, 'bun cha': 4, 'bún đậu': 4, 'bun dau': 4, 'nem cuốn': 4,

    // 5: Lẩu & Nướng
    'lẩu': 5, 'lau': 5, 'nướng': 5, 'nuong': 5, 'bbq': 5,

    // 6: Ốc & Quán lai rai
    'ốc': 6, 'oc': 6, 'ngao': 6, 'sò': 6, 'so': 6, 'hàu': 6, 'hau': 6, 'chân gà': 6, 'chan ga': 6,

    // 7: Đồ ăn vặt
    'nem chua': 7, 'khoai tây': 7, 'khoai tay': 7, 'xúc xích': 7, 'xuc xich': 7,
    'bánh tráng': 7, 'banh trang': 7, 'ăn vặt': 7, 'an vat': 7, 'xiên': 7,

    // 8: Chè & Tráng miệng
    'chè': 8, 'che': 8, 'caramen': 8, 'kem': 8, 'sữa chua': 8, 'sua chua': 8,
    'tàu hũ': 8, 'tau hu': 8, 'tráng miệng': 8, 'trang mieng': 8,

    // 9: Cà phê & Thức uống giải khát
    'cà phê': 9, 'ca phe': 9, 'cafe': 9, 'coffee': 9, 'trà sữa': 9, 'tra sua': 9,
    'trà': 9, 'tra': 9, 'matcha': 9, 'sinh tố': 9, 'sinh to': 9, 'nước ép': 9, 'nuoc ep': 9,

    // 10: Ẩm thực Chay & Thực dưỡng
    'chay': 10, 'nấm': 10, 'nam': 10, 'dưỡng sinh': 10, 'thực dưỡng': 10, 'salad': 10,
  };

  /// Khởi tạo và nạp dữ liệu điểm từ SharedPreferences (hỗ trợ inject prefs khi test)
  Future<void> init({SharedPreferences? customPrefs}) async {
    try {
      _prefs = customPrefs ?? await SharedPreferences.getInstance();
      final rawJson = _prefs?.getString(storageKey);
      if (rawJson != null && rawJson.isNotEmpty) {
        final Map<String, dynamic> decoded = jsonDecode(rawJson) as Map<String, dynamic>;
        final Map<String, dynamic> rawScores = decoded['scores'] as Map<String, dynamic>? ?? {};
        _scores.clear();
        rawScores.forEach((key, val) {
          final intKey = int.tryParse(key);
          final intVal = val is int ? val : (int.tryParse(val.toString()) ?? 0);
          if (intKey != null && intVal > 0) {
            _scores[intKey] = intVal.clamp(0, maxScore);
          }
        });
      }
    } catch (e) {
      debugPrint('⚠️ [PreferenceTracker] Lỗi khi nạp dữ liệu điểm local: $e');
    } finally {
      _isLoaded = true;
    }
  }

  /// Tự động xác định categoryId cho món ăn:
  /// - Ưu tiên dish.categoryId nếu có sẵn và hợp lệ (> 0).
  /// - Nếu không có, quét chuỗi kết hợp `${dish.category} ${dish.name}` theo bảng từ khóa.
  int? resolveCategoryId(Dish dish) {
    if (dish.categoryId != null && dish.categoryId! > 0) {
      return dish.categoryId;
    }

    final searchTarget = '${dish.category ?? ''} ${dish.name}'.trim().toLowerCase();
    if (searchTarget.isEmpty) return null;

    for (final entry in keywordCategoryMap.entries) {
      if (searchTarget.contains(entry.key)) {
        return entry.value;
      }
    }
    return null;
  }

  /// Ghi nhận tương tác click món ăn và cộng điểm cho thể loại tương ứng.
  ///
  /// Trả về `true` nếu điểm được cộng thành công; `false` nếu bỏ qua (do cooldown hoặc không xác định được thể loại).
  Future<bool> recordDishClick(Dish dish, {int points = defaultIncrement}) async {
    if (!_isLoaded) {
      await init();
    }

    final catId = resolveCategoryId(dish);
    if (catId == null) {
      return false;
    }

    // Kiểm tra cooldown chống spam cùng một món
    final now = DateTime.now();
    final lastTap = _lastDishTap[dish.id];
    if (lastTap != null && now.difference(lastTap) < cooldownDuration) {
      return false;
    }

    _lastDishTap[dish.id] = now;
    final currentScore = _scores[catId] ?? 0;
    final newScore = (currentScore + points).clamp(0, maxScore);
    _scores[catId] = newScore;

    // Lưu xuống bộ nhớ local
    await _saveToStorage();

    notifyListeners();
    return true;
  }

  /// Lưu trữ dữ liệu điểm hiện tại xuống SharedPreferences dưới dạng JSON
  Future<void> _saveToStorage() async {
    if (_prefs == null) return;
    try {
      final jsonScores = <String, int>{};
      _scores.forEach((key, val) {
        jsonScores[key.toString()] = val;
      });

      final payload = jsonEncode({
        'version': 1,
        'scores': jsonScores,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
      await _prefs!.setString(storageKey, payload);
    } catch (e) {
      debugPrint('⚠️ [PreferenceTracker] Lỗi lưu điểm vào storage: $e');
    }
  }

  /// Lấy điểm số hiện tại của một thể loại món ăn theo categoryId
  int getScore(int categoryId) {
    return _scores[categoryId] ?? 0;
  }

  /// Trả về toàn bộ bảng điểm hiện tại (không thể sửa đổi trực tiếp)
  Map<int, int> get allScores => Map.unmodifiable(_scores);

  /// Lấy danh sách Top [limit] thể loại có điểm số cao nhất, sắp xếp giảm dần
  List<MapEntry<int, int>> getTopCategories({int limit = 3}) {
    final sorted = _scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).toList();
  }

  /// Đặt lại toàn bộ điểm số về 0
  Future<void> resetScores() async {
    _scores.clear();
    _lastDishTap.clear();
    if (_prefs != null) {
      await _prefs!.remove(storageKey);
    }
    notifyListeners();
  }

  /// Đặt lại toàn bộ lịch sử cooldown (dùng cho testing)
  @visibleForTesting
  void clearCooldownHistory() {
    _lastDishTap.clear();
  }
}
