import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/models/models.dart';
import 'package:mobile/services/preference_tracker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PreferenceTracker tracker;

  setUp(() async {
    // Khởi tạo SharedPreferences mock
    SharedPreferences.setMockInitialValues({});
    tracker = PreferenceTracker.instance;
    await tracker.init();
    await tracker.resetScores();
    tracker.clearCooldownHistory();
  });

  group('PreferenceTracker - Unit Tests', () {
    test('1. Happy Path: Click món có categoryId hợp lệ -> điểm tăng đúng', () async {
      final dish = Dish(
        id: 101,
        restaurantId: 1,
        name: 'Món Thử Nghiệm',
        price: 50000,
        categoryId: 2, // Nhóm Cơm & Xôi
      );

      expect(tracker.getScore(2), 0);
      final recorded = await tracker.recordDishClick(dish);

      expect(recorded, isTrue);
      expect(tracker.getScore(2), 1);
      expect(tracker.allScores[2], 1);
    });

    test('2. Anti-Spam Cooldown: Click liên tục cùng món trong 30s không cộng dồn', () async {
      final dish = Dish(
        id: 102,
        restaurantId: 1,
        name: 'Bún Bò Huế',
        price: 45000,
        categoryId: 1,
      );

      final firstClick = await tracker.recordDishClick(dish);
      expect(firstClick, isTrue);
      expect(tracker.getScore(1), 1);

      // Click lần 2 ngay lập tức
      final secondClick = await tracker.recordDishClick(dish);
      expect(secondClick, isFalse);
      expect(tracker.getScore(1), 1); // Điểm vẫn giữ nguyên là 1
    });

    test('3. Keyword Fallback: Nhận diện thể loại theo từ khóa khi categoryId == null', () async {
      final phoDish = Dish(
        id: 103,
        restaurantId: 1,
        name: 'Phở bò tái lăn Gia Lâm',
        price: 55000,
        categoryId: null, // Chưa gán categoryId
      );

      final coffeeDish = Dish(
        id: 104,
        restaurantId: 1,
        name: 'Cà phê muối béo ngậy',
        price: 30000,
        categoryId: null,
      );

      final unknownDish = Dish(
        id: 105,
        restaurantId: 1,
        name: 'Món ăn trừu tượng xyz',
        price: 99000,
        categoryId: null,
      );

      // Phở -> Category 1
      expect(tracker.resolveCategoryId(phoDish), 1);
      await tracker.recordDishClick(phoDish);
      expect(tracker.getScore(1), 1);

      // Cà phê -> Category 9
      expect(tracker.resolveCategoryId(coffeeDish), 9);
      await tracker.recordDishClick(coffeeDish);
      expect(tracker.getScore(9), 1);

      // Món lạ không khớp -> null
      expect(tracker.resolveCategoryId(unknownDish), isNull);
      final recordedUnknown = await tracker.recordDishClick(unknownDish);
      expect(recordedUnknown, isFalse);
    });

    test('4. Giới hạn điểm trần (Max Score Cap = 100)', () async {
      final dish = Dish(
        id: 106,
        restaurantId: 1,
        name: 'Lẩu nướng thập cẩm',
        price: 250000,
        categoryId: 5,
      );

      // Cộng 120 điểm (vượt quá 100)
      await tracker.recordDishClick(dish, points: 120);

      expect(tracker.getScore(5), 100);
    });

    test('5. Top Categories: Trả về danh sách thể loại điểm cao nhất sắp xếp giảm dần', () async {
      final dish1 = Dish(id: 201, restaurantId: 1, name: 'Cơm tấm', price: 40000, categoryId: 2);
      final dish2 = Dish(id: 202, restaurantId: 1, name: 'Bánh mì', price: 20000, categoryId: 3);
      final dish3 = Dish(id: 203, restaurantId: 1, name: 'Trà chanh', price: 15000, categoryId: 9);

      await tracker.recordDishClick(dish1, points: 10);
      await tracker.recordDishClick(dish2, points: 25);
      await tracker.recordDishClick(dish3, points: 5);

      final top = tracker.getTopCategories(limit: 2);
      expect(top.length, 2);
      expect(top[0].key, 3); // Bánh mì 25đ
      expect(top[0].value, 25);
      expect(top[1].key, 2); // Cơm 10đ
      expect(top[1].value, 10);
    });

    test('6. Persistence: Khôi phục chính xác bảng điểm từ bộ nhớ local (SharedPreferences)', () async {
      final dish = Dish(
        id: 301,
        restaurantId: 1,
        name: 'Chè bưởi An Giang',
        price: 25000,
        categoryId: 8,
      );

      await tracker.recordDishClick(dish, points: 7);
      expect(tracker.getScore(8), 7);

      // Giả lập tắt app và mở lại
      await tracker.init();
      expect(tracker.getScore(8), 7);
      expect(tracker.allScores[8], 7);
    });

    test('7. Reset Scores: Đặt lại toàn bộ điểm số về 0', () async {
      final dish = Dish(id: 401, restaurantId: 1, name: 'Bún chả', price: 35000, categoryId: 4);
      await tracker.recordDishClick(dish, points: 15);
      expect(tracker.getScore(4), 15);

      await tracker.resetScores();
      expect(tracker.getScore(4), 0);
      expect(tracker.allScores.isEmpty, isTrue);
    });
  });
}
