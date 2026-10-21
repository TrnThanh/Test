import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';
import 'package:mobile/models/models.dart';
import 'package:mobile/services/api_service.dart';

class FakeApiService extends ApiService {
  @override
  Future<List<Restaurant>> getRestaurants({int skip = 0, int limit = 50}) async {
    return [
      Restaurant(
        id: 1,
        name: 'Phở Thìn Lò Đúc',
        address: '13 Lò Đúc, Hai Bà Trưng, Hà Nội',
        phone: '0901234567',
        description: 'Phở bò tái lăn gia truyền',
        latitude: 21.0185,
        longitude: 105.8572,
        openTime: '06:00',
        closeTime: '22:00',
        isActive: true,
      ),
      Restaurant(
        id: 2,
        name: 'Bún Chả Đắc Kim',
        address: '1 Hàng Mành, Hoàn Kiếm, Hà Nội',
        phone: '0907654321',
        description: 'Bún chả truyền thống phố cổ',
        latitude: 21.0325,
        longitude: 105.8492,
        openTime: '08:00',
        closeTime: '21:00',
        isActive: true,
      ),
    ];
  }

  @override
  Future<List<Restaurant>> getNearbyRestaurants({
    required double lat,
    required double lon,
    required double radiusKm,
  }) async {
    return [
      Restaurant(
        id: 1,
        name: 'Phở Thìn Lò Đúc',
        address: '13 Lò Đúc, Hai Bà Trưng, Hà Nội',
        latitude: 21.0185,
        longitude: 105.8572,
        openTime: '06:00',
        closeTime: '22:00',
        isActive: true,
        distanceKm: 0.8,
      ),
    ];
  }

  @override
  Future<List<GeocodePlace>> searchMap(String query) async {
    return [
      GeocodePlace(
        displayName: 'Hồ Hoàn Kiếm, Hàng Trống, Hoàn Kiếm, Hà Nội',
        latitude: 21.0285,
        longitude: 105.8542,
      ),
    ];
  }

  @override
  Future<List<Category>> getRestaurantCategories(int restaurantId) async {
    return [
      Category(
        id: 1,
        restaurantId: restaurantId,
        name: 'Phở Gia Truyền',
        displayOrder: 1,
        isActive: true,
      ),
    ];
  }

  @override
  Future<List<Dish>> getRestaurantDishes(int restaurantId, {int? categoryId}) async {
    return [
      Dish(
        id: 101,
        restaurantId: restaurantId,
        name: 'Phở Tái Lăn',
        price: 65000,
        categoryId: 1,
        categoryName: 'Phở Gia Truyền',
        mealType: 'breakfast',
        ingredients: ['Thịt bò', 'Bánh phở', 'Hành lá'],
      ),
    ];
  }

  @override
  Future<List<FavouriteDish>> getUserFavourites(int userId) async {
    return [];
  }

  UserProfile _fakeProfile = UserProfile(
    id: 1,
    userId: 1,
    heightCm: 175,
    weightKg: 68,
    gender: 'male',
    birthYear: 1998,
    activityLevel: 'moderate',
    targetGoal: 'maintain',
    favoriteCategoryIds: [1],
    dietaryPreferences: ['Eat clean'],
    spicyTolerance: 'mild',
    allergies: ['Hải sản'],
    budgetRange: 'moderate',
    isOnboarded: false,
    bmi: 22.2,
    bmiCategory: 'normal',
  );

  @override
  Future<UserProfile> getUserProfile(int userId) async {
    return _fakeProfile;
  }

  @override
  Future<UserProfile> updateUserProfile(int userId, Map<String, dynamic> data) async {
    _fakeProfile = UserProfile(
      id: 1,
      userId: userId,
      heightCm: data['height_cm'] != null ? (data['height_cm'] as num).toDouble() : _fakeProfile.heightCm,
      weightKg: data['weight_kg'] != null ? (data['weight_kg'] as num).toDouble() : _fakeProfile.weightKg,
      gender: data['gender'] as String? ?? _fakeProfile.gender,
      birthYear: data['birth_year'] != null ? (data['birth_year'] as num).toInt() : _fakeProfile.birthYear,
      activityLevel: data['activity_level'] as String? ?? _fakeProfile.activityLevel,
      targetGoal: data['target_goal'] as String? ?? _fakeProfile.targetGoal,
      dietaryPreferences: data['dietary_preferences'] != null ? List<String>.from(data['dietary_preferences']) : _fakeProfile.dietaryPreferences,
      spicyTolerance: data['spicy_tolerance'] as String? ?? _fakeProfile.spicyTolerance,
      allergies: data['allergies'] != null ? List<String>.from(data['allergies']) : _fakeProfile.allergies,
      budgetRange: data['budget_range'] as String? ?? _fakeProfile.budgetRange,
      isOnboarded: true,
      bmi: 22.2,
      bmiCategory: 'normal',
    );
    return _fakeProfile;
  }
}

void main() {
  testWidgets('Kiểm thử khởi chạy Ptc1App và chuyển đổi 4 tab NavigationBar', (WidgetTester tester) async {
    final fakeApi = FakeApiService();

    // Khởi chạy ứng dụng với fake api
    await tester.pumpWidget(Ptc1App(apiService: fakeApi, showInitialCategoryPrompt: false));
    await tester.pumpAndSettle();

    // 1. Kiểm tra màn hình Khám phá ban đầu
    expect(find.text('PTC1 Khám Phá Quán Ăn'), findsOneWidget);
    expect(find.text('Phở Thìn Lò Đúc'), findsOneWidget);
    expect(find.text('Bún Chả Đắc Kim'), findsOneWidget);

    // 2. Chuyển sang Tab "Gần đây"
    await tester.tap(find.text('Gần đây'));
    await tester.pumpAndSettle();
    expect(find.text('Quán Ăn Lân Cận (PostGIS)'), findsOneWidget);
    expect(find.text('Bán kính tìm kiếm:'), findsOneWidget);

    // 3. Chuyển sang Tab "Bản đồ OSM"
    await tester.tap(find.text('Bản đồ OSM'));
    await tester.pumpAndSettle();
    expect(find.text('Bản Đồ & Geocoding OSM'), findsOneWidget);

    // 4. Chuyển sang Tab "Tài khoản"
    await tester.tap(find.text('Tài khoản'));
    await tester.pumpAndSettle();
    expect(find.text('Đăng Nhập Khách Hàng'), findsOneWidget);
    expect(find.text('Email *'), findsOneWidget);
    expect(find.text('Mật khẩu *'), findsOneWidget);
  });

  testWidgets('Kiểm thử Auth Gate khi khách vãng lai nhấn xem thực đơn và bấm yêu thích', (WidgetTester tester) async {
    final fakeApi = FakeApiService();

    await tester.pumpWidget(Ptc1App(apiService: fakeApi, showInitialCategoryPrompt: false));
    await tester.pumpAndSettle();

    // Bấm nút "Xem Thực Đơn" ở quán đầu tiên
    final menuBtn = find.text('Xem Thực Đơn').first;
    expect(menuBtn, findsOneWidget);
    await tester.tap(menuBtn);
    await tester.pumpAndSettle();

    // Kiểm tra thực đơn mở ra có món ăn
    expect(find.text('Thực đơn: Phở Thìn Lò Đúc'), findsOneWidget);
    expect(find.text('Phở Tái Lăn'), findsOneWidget);

    // Bấm nút Trái Tim (❤) yêu thích món ăn khi chưa đăng nhập
    final heartBtn = find.byIcon(Icons.favorite_border).first;
    await tester.tap(heartBtn);
    await tester.pumpAndSettle();

    // Kiểm tra Auth Gate Dialog hiện lên yêu cầu đăng nhập
    expect(find.text('Yêu Cầu Đăng Nhập'), findsOneWidget);
    expect(find.text('Bạn cần đăng nhập tài khoản Thực khách để lưu món ăn này vào danh sách yêu thích.'), findsOneWidget);
    expect(find.text('Đăng nhập ngay'), findsOneWidget);

    // Bấm "Đăng nhập ngay" chuyển thẳng sang Tab Tài khoản
    await tester.tap(find.text('Đăng nhập ngay'));
    await tester.pumpAndSettle();

    expect(find.text('Đăng Nhập Khách Hàng'), findsOneWidget);
  });

  testWidgets('Kiểm thử màn hình Đăng ký Thực khách', (WidgetTester tester) async {
    final fakeApi = FakeApiService();

    await tester.pumpWidget(Ptc1App(apiService: fakeApi, showInitialCategoryPrompt: false));
    await tester.pumpAndSettle();

    // Vào Tab Tài khoản
    await tester.tap(find.text('Tài khoản'));
    await tester.pumpAndSettle();

    // Chuyển sang chế độ Đăng Ký
    await tester.tap(find.text('Đăng ký'));
    await tester.pumpAndSettle();
    expect(find.text('Họ và tên'), findsOneWidget);
    expect(find.text('Đăng ký ngay'), findsOneWidget);
  });

  testWidgets('Kiểm thử hiển thị dialog Onboarding Survey và các thành phần khảo sát', (WidgetTester tester) async {
    final fakeApi = FakeApiService();

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: OnboardingSurveyDialog(
          api: fakeApi,
          userId: 1,
          onCompleted: () {},
        ),
      ),
    ));
    await tester.pumpAndSettle();

    // Kiểm tra tiêu đề khảo sát và các tab
    expect(find.text('Sở Thích Ẩm Thực & Sức Khỏe'), findsOneWidget);
    expect(find.text('1. Thể Loại'), findsOneWidget);
    expect(find.text('2. Thể Chất'), findsOneWidget);
    expect(find.text('3. Khẩu Vị'), findsOneWidget);

    // Chuyển sang Tab 2 Thể chất
    await tester.tap(find.text('2. Thể Chất'));
    await tester.pumpAndSettle();
    expect(find.text('Chỉ số thể chất cơ bản:'), findsOneWidget);
    expect(find.text('Chiều cao (cm)'), findsOneWidget);
    expect(find.text('Cân nặng (kg)'), findsOneWidget);

    // Chuyển sang Tab 3 Khẩu vị
    await tester.tap(find.text('3. Khẩu Vị'));
    await tester.pumpAndSettle();
    expect(find.text('Mức độ ăn cay:'), findsOneWidget);
    expect(find.text('Dị ứng thực phẩm (nếu có):'), findsOneWidget);
    expect(find.text('Lưu & Hoàn tất'), findsOneWidget);
  });

  testWidgets('Kiểm thử WelcomeCategoryDialog khi vừa vào app và lọc thể loại món ăn', (WidgetTester tester) async {
    final fakeApi = FakeApiService();

    await tester.pumpWidget(Ptc1App(apiService: fakeApi, showInitialCategoryPrompt: true));
    await tester.pumpAndSettle();

    // 1. Kiểm tra Dialog chào mừng tự động hiển thị
    expect(find.text('Hôm Nay Bạn Muốn Ăn Gì?'), findsOneWidget);
    expect(find.text('Phở & Bún'), findsAtLeastNWidgets(1));
    expect(find.text('Khám Phá'), findsOneWidget);

    // 2. Nhấn nút "Khám Phá Ngay"
    await tester.tap(find.text('Khám Phá'));
    await tester.pumpAndSettle();

    // 3. Kiểm tra Dialog đã đóng và hiển thị màn hình Khám phá kèm danh sách quán
    expect(find.text('PTC1 Khám Phá Quán Ăn'), findsOneWidget);
    expect(find.text('Phở Thìn Lò Đúc'), findsOneWidget);
  });
}
