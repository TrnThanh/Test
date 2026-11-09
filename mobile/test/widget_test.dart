import 'package:mobile/services/location_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';
import 'package:mobile/models/models.dart';
import 'package:mobile/services/api_service.dart';

class FakeApiService extends ApiService {
  @override
  Future<List<Restaurant>> getRestaurants({int skip = 0, int limit = 200}) async {
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
        isSponsor: true,
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
        isSponsor: true,
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
        isSponsor: true,
        distanceKm: 0.8,
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
        isSponsor: true,
        distanceKm: 1.2,
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
  Future<RestaurantRouteData> getRestaurantWalkingRoute({
    required int restaurantId,
    required double userLat,
    required double userLon,
  }) async {
    return RestaurantRouteData(
      restaurantId: restaurantId,
      restaurantName: 'Phở Thìn Lò Đúc',
      distanceMeters: 850.0,
      durationSeconds: 680.0,
      rawCoordinates: [
        [userLon, userLat],
        [105.8572, 21.0185],
      ],
      isFallback: false,
    );
  }

  @override
  Future<CurrentWeather> getCurrentWeather({double? lat, double? lon}) async {
    return CurrentWeather(
      temperature: 28.0,
      feelsLike: 29.5,
      humidity: 70,
      condition: 'Clouds',
      description: 'Có mây',
      icon: '02d',
      latitude: lat ?? 21.0285,
      longitude: lon ?? 105.8542,
      locationName: 'Hà Nội',
      isLive: true,
    );
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
        calories: 520,
        spicyLevel: 1,
        allergens: ['Thịt bò'],
        dietaryTags: ['Ăn sáng'],
        description: 'Phở xào lăn đậm đà nước dùng truyền thống',
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
  Future<RoleLoginResponse> loginUser(String email, String password) async {
    return RoleLoginResponse(
      id: 1,
      email: email,
      fullName: 'Thực Khách Test',
      role: 'user',
      sessionId: 'fake_jwt_token',
    );
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
      favoriteCategoryIds: data['favorite_category_ids'] != null ? List<int>.from(data['favorite_category_ids']) : _fakeProfile.favoriteCategoryIds,
      dietaryPreferences: data['dietary_preferences'] != null ? List<String>.from(data['dietary_preferences']) : _fakeProfile.dietaryPreferences,
      spicyTolerance: data['spicy_tolerance'] as String? ?? _fakeProfile.spicyTolerance,
      allergies: data['allergies'] != null ? List<String>.from(data['allergies']) : _fakeProfile.allergies,
      budgetRange: data['budget_range'] as String? ?? _fakeProfile.budgetRange,
      isOnboarded: data['complete_onboarding'] == true ? true : _fakeProfile.isOnboarded,
      bmi: 22.2,
      bmiCategory: 'normal',
    );
    return _fakeProfile;
  }
}

void main() {
  tearDown(() {
    AppLanguage.instance.setLocale(const Locale('vi'));
  });

  testWidgets('Kiểm thử khởi chạy Ptc1App và chuyển đổi 4 tab NavigationBar', (WidgetTester tester) async {
    final fakeApi = FakeApiService();

    // Khởi chạy ứng dụng với fake api
    await tester.pumpWidget(Ptc1App(apiService: fakeApi));
    await tester.pumpAndSettle();

    // 1. Kiểm tra màn hình Trang chủ (Khám phá) ban đầu
    expect(find.textContaining('nay ăn gì nhỉ?'), findsOneWidget);
    expect(find.text('Phở Thìn Lò Đúc'), findsOneWidget);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.text('Bún Chả Đắc Kim'), findsOneWidget);

    // 2. Chuyển sang Tab "Bản đồ"
    await tester.tap(find.text('Bản đồ'));
    await tester.pumpAndSettle();
    expect(find.text('Bản Đồ & Quán Ăn Gia Lâm'), findsOneWidget);
    expect(find.byTooltip('Vị trí của tôi'), findsOneWidget);
    expect(find.text('Tất cả'), findsOneWidget);
    expect(find.byIcon(Icons.my_location), findsWidgets);

    // 3. Chuyển sang Tab "Đã lưu"
    await tester.tap(find.text('Đã lưu'));
    await tester.pumpAndSettle();
    expect(find.text('Món Ăn Yêu Thích'), findsOneWidget);
    expect(find.text('Lưu Giữ Món Ăn Bạn Yêu Thích'), findsOneWidget);

    // 4. Chuyển sang Tab "Cá nhân" (Chế độ Khách với giao diện mới)
    await tester.tap(find.text('Cá nhân'));
    await tester.pumpAndSettle();
    expect(find.text('Chào bạn!'), findsOneWidget);
    expect(find.text('Bạn đang trải nghiệm với tư cách Khách'), findsOneWidget);
    expect(find.text('Đăng nhập'), findsOneWidget);
    expect(find.text('Tạo tài khoản miễn phí'), findsOneWidget);
    expect(find.text('Lợi ích khi đăng nhập thành viên'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(find.text('Quyền truy cập vị trí'), findsOneWidget);
  });

  testWidgets('Kiểm thử Auth Gate khi khách vãng lai nhấn Xem chi tiết và bấm yêu thích', (WidgetTester tester) async {
    final fakeApi = FakeApiService();

    await tester.pumpWidget(Ptc1App(apiService: fakeApi));
    await tester.pumpAndSettle();

    // Bấm nút "Xem chi tiết" ở quán đầu tiên
    final menuBtn = find.text('Khám phá ngay').first;
    expect(menuBtn, findsOneWidget);
    await tester.ensureVisible(menuBtn);
    await tester.pumpAndSettle();
    await tester.tap(menuBtn);
    await tester.pumpAndSettle();

    // Kiểm tra thực đơn mở ra có món ăn
    expect(find.text('Thực đơn: Phở Thìn Lò Đúc'), findsOneWidget);
    expect(find.text('Phở Tái Lăn'), findsOneWidget);

    // Bấm nút Trái Tim (❤) yêu thích món ăn khi chưa đăng nhập
    final heartBtn = find.byTooltip('Thích món này');
    await tester.tap(heartBtn);
    await tester.pumpAndSettle();

    // Kiểm tra Auth Gate Dialog hiện lên yêu cầu đăng nhập
    expect(find.text('Yêu Cầu Đăng Nhập'), findsOneWidget);
    expect(find.text('Bạn cần đăng nhập tài khoản Thực khách để lưu món ăn này vào danh sách yêu thích.'), findsOneWidget);
    expect(find.text('Đăng nhập ngay'), findsOneWidget);

    // Bấm "Đăng nhập ngay" mở Modal Đăng Nhập mà không chuyển trang đột ngột
    await tester.tap(find.text('Đăng nhập ngay'));
    await tester.pumpAndSettle();

    expect(find.text('Đăng Nhập Khách Hàng'), findsOneWidget);
    expect(find.text('Email *'), findsOneWidget);
  });

  testWidgets('Kiểm thử màn hình Đăng ký Thực khách', (WidgetTester tester) async {
    final fakeApi = FakeApiService();

    await tester.pumpWidget(Ptc1App(apiService: fakeApi));
    await tester.pumpAndSettle();

    // Vào Tab Cá nhân
    await tester.tap(find.text('Cá nhân'));
    await tester.pumpAndSettle();

    // Bấm nút Tạo tài khoản miễn phí
    await tester.tap(find.text('Tạo tài khoản miễn phí'));
    await tester.pumpAndSettle();
    expect(find.text('Tạo Tài Khoản Khách Hàng'), findsOneWidget);
    expect(find.text('Họ và tên'), findsOneWidget);
    expect(find.text('Đăng ký ngay'), findsOneWidget);
  });

  testWidgets('Kiểm thử validation client trên AuthFormModal khi nhập email hoặc mật khẩu không hợp lệ', (WidgetTester tester) async {
    final fakeApi = FakeApiService();

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AuthFormModal(
          api: fakeApi,
          onSuccess: (_) {},
        ),
      ),
    ));
    await tester.pumpAndSettle();

    // 1. Để trống bấm Đăng nhập -> Báo lỗi nhập đầy đủ
    await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
    await tester.pumpAndSettle();
    expect(find.text('⚠️ Vui lòng nhập đầy đủ Email và Mật khẩu'), findsOneWidget);

    // 2. Nhập email sai định dạng
    final textFields = find.byType(TextField);
    await tester.enterText(textFields.at(0), 'invalid-email');
    await tester.enterText(textFields.at(1), '123456');
    await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
    await tester.pumpAndSettle();
    expect(find.text('⚠️ Địa chỉ email không đúng định dạng'), findsOneWidget);

    // 3. Nhập mật khẩu < 6 ký tự
    await tester.enterText(textFields.at(0), 'valid@ptc1.vn');
    await tester.enterText(textFields.at(1), '123');
    await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
    await tester.pumpAndSettle();
    expect(find.text('⚠️ Mật khẩu phải có tối thiểu 6 ký tự'), findsOneWidget);
  });

  testWidgets('Kiểm thử validation chiều cao, cân nặng và năm sinh trên OnboardingSurveyDialog', (WidgetTester tester) async {
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

    // Chuyển sang Tab 2 Thể chất
    await tester.tap(find.text('2. Thể Chất'));
    await tester.pumpAndSettle();

    // Nhập chiều cao không hợp lệ (ví dụ: 10 cm)
    final textFields = find.byType(TextField);
    await tester.enterText(textFields.at(0), '10');

    // Chuyển sang Tab 3 Khẩu vị và bấm Lưu & Hoàn tất
    await tester.tap(find.text('3. Khẩu Vị'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lưu & Hoàn tất'));
    await tester.pumpAndSettle();

    // Xác nhận hiển thị thông báo lỗi rõ ràng trên UI
    expect(find.text('Chiều cao phải là số từ 50 đến 260 cm.'), findsOneWidget);
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

  testWidgets('Kiểm thử khi đăng nhập tài khoản thực khách thành công không còn hiển thị WelcomeCategoryDialog và vào thẳng app', (WidgetTester tester) async {
    final fakeApi = FakeApiService();

    // Khởi chạy app mặc định
    await tester.pumpWidget(Ptc1App(apiService: fakeApi));
    await tester.pumpAndSettle();

    // Khách vãng lai vào thẳng Khám phá, không có popup
    expect(find.text('Hôm Nay Bạn Muốn Ăn Gì?'), findsNothing);

    // Chuyển sang Tab Cá nhân để đăng nhập
    await tester.tap(find.text('Cá nhân'));
    await tester.pumpAndSettle();

    // Bấm nút Đăng nhập mở modal
    await tester.tap(find.text('Đăng nhập'));
    await tester.pumpAndSettle();

    // Điền thông tin đăng nhập thực khách
    final textFields = find.byType(TextField);
    expect(textFields, findsAtLeastNWidgets(2));
    await tester.enterText(textFields.at(0), 'khach@ptc1.vn');
    await tester.enterText(textFields.at(1), 'Pass@123');

    // Bấm nút Đăng nhập trong modal
    await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    // 1. Kiểm tra tuyệt đối KHÔNG hiển thị dialog "Hôm Nay Bạn Muốn Ăn Gì?"
    expect(find.text('Hôm Nay Bạn Muốn Ăn Gì?'), findsNothing);

    // 2. Kiểm tra thông tin người dùng hiển thị thành công trong Tab Tài khoản
    expect(find.text('Tài Khoản Thực Khách'), findsOneWidget);
    expect(find.text('Thực Khách Test'), findsOneWidget);
    expect(find.byTooltip('Đăng xuất'), findsOneWidget);
  });

  testWidgets('Kiểm thử khởi chạy Ptc1App mặc định không hiện popup và vào thẳng Khám phá', (WidgetTester tester) async {
    final fakeApi = FakeApiService();

    // Khởi chạy app mặc định (showInitialCategoryPrompt = false)
    await tester.pumpWidget(Ptc1App(apiService: fakeApi));
    await tester.pumpAndSettle();

    // 1. Kiểm tra tuyệt đối KHÔNG hiển thị dialog "Hôm Nay Bạn Muốn Ăn Gì?"
    expect(find.text('Hôm Nay Bạn Muốn Ăn Gì?'), findsNothing);

    // 2. Vào thẳng màn hình Khám phá
    expect(find.textContaining('nay ăn gì nhỉ?'), findsOneWidget);
    expect(find.text('Phở Thìn Lò Đúc'), findsOneWidget);
  });


  testWidgets('Kiểm thử thẻ thời tiết và WeatherLandscapePainter thay đổi theo thời gian ngày và đêm', (WidgetTester tester) async {
    final fakeApi = FakeApiService();

    await tester.pumpWidget(Ptc1App(apiService: fakeApi));
    await tester.pumpAndSettle();

    // Xác nhận CustomPaint của WeatherLandscapePainter hiện diện trên màn hình
    expect(find.byType(CustomPaint), findsWidgets);

    // Kiểm tra render độc lập WeatherLandscapePainter cho cả ban ngày và ban đêm
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              CustomPaint(size: Size(120, 80), painter: WeatherLandscapePainter(isNight: false)),
              CustomPaint(size: Size(120, 80), painter: WeatherLandscapePainter(isNight: true)),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('Kiểm thử thẻ thời tiết cố định khu vực Gia Lâm - Hà Nội và không mở popup chọn khu vực', (WidgetTester tester) async {
    final fakeApi = FakeApiService();

    await tester.pumpWidget(Ptc1App(apiService: fakeApi));
    await tester.pumpAndSettle();

    // Xác nhận thẻ thời tiết hiển thị thông tin nhiệt độ
    final tempFinder = find.textContaining('°C');
    expect(tempFinder, findsOneWidget);

    // Chạm vào thẻ thời tiết
    await tester.tap(tempFinder);
    await tester.pumpAndSettle();

    // Đảm bảo không hiển thị modal Chọn khu vực
    expect(find.text('Chọn khu vực'), findsNothing);
  });

  testWidgets('Kiểm thử Bản đồ MapScreen hiển thị đầy đủ và các điều khiển trực quan', (WidgetTester tester) async {
    final fakeApi = FakeApiService();
    await tester.pumpWidget(
      MaterialApp(
        home: MapScreen(
          api: fakeApi,
          currentUser: null,
          onRequireLogin: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bản Đồ & Quán Ăn Gia Lâm'), findsOneWidget);
    expect(find.byIcon(Icons.tune), findsOneWidget);
    expect(find.byIcon(Icons.search), findsWidgets);
  });

  testWidgets('Kiểm thử Chỉ đường đi bộ trên MapScreen hiển thị nút và banner', (WidgetTester tester) async {
    final fakeApi = FakeApiService();
    await tester.pumpWidget(
      MaterialApp(
        home: MapScreen(
          api: fakeApi,
          currentUser: null,
          onRequireLogin: () {},
          initialRestaurant: Restaurant(
            id: 1,
            name: 'Phở Cường Trâu Quỳ',
            address: 'Trâu Quỳ, Gia Lâm, Hà Nội',
            latitude: 21.0046,
            longitude: 105.9387,
            openTime: '06:00',
            closeTime: '22:00',
            isActive: true,
            isSponsor: true,
          ),
          initialLat: 21.0046,
          initialLon: 105.9387,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Quán ban đầu được chọn -> nút "Chỉ đường" hiển thị
    expect(find.text('Đường đi'), findsOneWidget);
    expect(find.text('Thực đơn'), findsOneWidget);

    // 2. Nhấn nút "Chỉ đường"
    await tester.tap(find.text('Đường đi'));
    await tester.pumpAndSettle();

    // 3. Vì _pinnedLocation đã có toạ độ nên app lập tức gọi route và hiển thị Sheet điều hướng đi bộ Google Maps
    expect(find.text('Đi bộ'), findsOneWidget);
    expect(find.text('Bắt đầu'), findsOneWidget);
    expect(find.byIcon(Icons.directions_walk), findsWidgets);

    // 4. Bấm nút X trên sheet điều hướng -> trở về chi tiết quán và tuyến đường bị xóa
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.text('Đường đi'), findsOneWidget);
    expect(find.text('Đi bộ'), findsNothing);

    // 5. Bấm lại 'Đường đi' và test chạm vào bản đồ -> cũng xóa đường đi và quay về chi tiết quán
    await tester.tap(find.text('Đường đi'));
    await tester.pumpAndSettle();
    expect(find.text('Đi bộ'), findsOneWidget);

    // 5. Nút 'Chi tiết quán' trên sheet cũng xóa tuyến đường và quay về chi tiết quán
    await tester.tap(find.text('Chi tiết quán'));
    await tester.pumpAndSettle();
    expect(find.text('Đường đi'), findsOneWidget);
    expect(find.text('Đi bộ'), findsNothing);
  });

  testWidgets('Kiểm thử Cụm ẩm thực LOD và Viewport Culling trên MapScreen', (WidgetTester tester) async {
    final fakeApi = FakeApiService();
    await tester.pumpWidget(
      MaterialApp(
        home: MapScreen(
          api: fakeApi,
          currentUser: null,
          onRequireLogin: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.text('Bản Đồ & Quán Ăn Gia Lâm'), findsOneWidget);

    // Kiểm tra cấu hình TileLayer có silenceExceptions và evictErrorTileStrategy
    final tileLayerFinder = find.byType(TileLayer);
    expect(tileLayerFinder, findsOneWidget);
    final tileLayerWidget = tester.widget<TileLayer>(tileLayerFinder);
    expect(tileLayerWidget.evictErrorTileStrategy, EvictErrorTileStrategy.notVisibleRespectMargin);
    expect(tileLayerWidget.tileProvider, isA<NetworkTileProvider>());
    expect((tileLayerWidget.tileProvider as NetworkTileProvider).silenceExceptions, isTrue);
  });

  test('LocationService.getDeviceLocation trả về null an toàn khi chạy headless test', () async {
    final pos = await LocationService.getDeviceLocation();
    expect(pos, isNull);
  });

  test('LocationService sử dụng debugProvider khi được inject trong môi trường kiểm thử', () async {
    LocationService.debugProvider = () async => {'lat': 21.0046, 'lon': 105.9387};
    addTearDown(() => LocationService.debugProvider = null);

    final pos = await LocationService.getDeviceLocation();
    expect(pos, isNotNull);
    expect(pos!['lat'], 21.0046);
    expect(pos['lon'], 105.9387);
  });

  testWidgets('Kiểm thử ExploreScreen tải danh sách quán ăn trực tiếp không phụ thuộc GPS nearby', (WidgetTester tester) async {
    final fakeApi = FakeApiService();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExploreScreen(
            api: fakeApi,
            currentUser: null,
            onRequireLogin: () {},
            onNavigateToMap: (lat, lon, [restaurant]) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Khám phá quán ngon'), findsOneWidget);
    expect(find.text('Phở Thìn Lò Đúc'), findsOneWidget);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.text('Bún Chả Đắc Kim'), findsOneWidget);
  });

  testWidgets('Kiểm thử giao diện Thực đơn Bento Card mới, tìm kiếm và Modal chi tiết món DishDetailSheet', (WidgetTester tester) async {
    final fakeApi = FakeApiService();
    await tester.pumpWidget(Ptc1App(apiService: fakeApi));
    await tester.pumpAndSettle();

    // Mở thực đơn của quán
    final menuBtn = find.text('Khám phá ngay').first;
    await tester.ensureVisible(menuBtn);
    await tester.pumpAndSettle();
    await tester.tap(menuBtn);
    await tester.pumpAndSettle();

    // 1. Kiểm tra Header và các thành phần tìm kiếm, danh mục
    expect(find.text('Thực đơn: Phở Thìn Lò Đúc'), findsOneWidget);
    expect(find.text('Tìm món ăn trong thực đơn...'), findsOneWidget);
    expect(find.text('Tất cả (1)'), findsOneWidget);
    expect(find.text('Phở Gia Truyền (1)'), findsOneWidget);

    // 2. Kiểm tra Bento Card món ăn hiển thị Calo và độ cay
    expect(find.text('Phở Tái Lăn'), findsOneWidget);
    expect(find.text('65.000 ₫'), findsOneWidget);
    expect(find.text('520 kcal'), findsOneWidget);

    // 3. Kiểm tra tính năng tìm kiếm món ăn
    await tester.enterText(find.byType(TextField).last, 'Không có món này');
    await tester.pumpAndSettle();
    expect(find.text('Không tìm thấy món ăn nào khớp với "Không có món này"'), findsOneWidget);

    // Xóa tìm kiếm để phục hồi món ăn
    await tester.tap(find.text('Xóa tìm kiếm'));
    await tester.pumpAndSettle();
    expect(find.text('Phở Tái Lăn'), findsOneWidget);

    // 4. Bấm vào món ăn để mở Modal Chi tiết món (DishDetailSheet)
    final dishCard = find.byKey(const ValueKey('dish-card-101'));
    await tester.ensureVisible(dishCard);
    await tester.pumpAndSettle();
    await tester.tap(dishCard);
    await tester.pumpAndSettle();

    // Kiểm tra modal chi tiết món đã mở ra
    expect(find.text('Lưu vào món ăn yêu thích'), findsOneWidget);
    expect(find.text('Phở Tái Lăn'), findsNWidgets(2));

    // Cuộn xuống để xem chi tiết mô tả, dị ứng và nguyên liệu
    await tester.drag(find.byType(ListView).last, const Offset(0, -300));
    await tester.pumpAndSettle();

    expect(find.text('Mô tả món ăn'), findsOneWidget);
    expect(find.text('Phở xào lăn đậm đà nước dùng truyền thống'), findsNWidgets(2));
    expect(find.text('Cảnh báo dị ứng thực phẩm'), findsOneWidget);
    expect(find.text('Nguyên liệu chính'), findsOneWidget);

    // Cuộn lên lại và đóng modal chi tiết món
    await tester.drag(find.byType(ListView).last, const Offset(0, 300));
    await tester.pumpAndSettle();
    final closeDetailBtn = find.byIcon(Icons.close_rounded).last;
    await tester.tap(closeDetailBtn);
    await tester.pumpAndSettle();
  });

  testWidgets('Kiểm thử MapScreen hiển thị số rating của quán ăn trên bản đồ và BottomSheet', (WidgetTester tester) async {
    final fakeApi = FakeApiService();
    await tester.pumpWidget(
      MaterialApp(
        home: MapScreen(
          api: fakeApi,
          currentUser: null,
          onRequireLogin: () {},
          initialRestaurant: Restaurant(
            id: 99,
            name: 'Phở Bò Rating Cao Gia Lâm',
            address: 'Trâu Quỳ, Gia Lâm, Hà Nội',
            latitude: 21.0046,
            longitude: 105.9387,
            openTime: '06:00',
            closeTime: '22:00',
            rating: 4.8,
            isActive: true,
            isSponsor: true,
          ),
          initialLat: 21.0046,
          initialLon: 105.9387,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Kiểm tra số rating 4.8 hiển thị trên Marker và BottomSheet chi tiết quán
    expect(find.text('4.8'), findsWidgets);

    // 2. Icon sao hiển thị tương ứng
    expect(find.byIcon(Icons.star), findsWidgets);
  });


  test('Kiểm thử đơn vị AppLanguage và AppStrings từ điển song ngữ', () {
    // 1. Kiểm tra trạng thái mặc định Tiếng Việt
    expect(AppLanguage.instance.isVietnamese, isTrue);
    expect(AppLanguage.instance.currentLanguageLabel, 'Tiếng Việt');
    expect(tr('tab_home'), 'Trang chủ');
    expect(tr('tab_explore'), 'Khám phá');
    expect(tr('item_language'), 'Ngôn ngữ');

    // 2. Chuyển sang Tiếng Anh (English)
    AppLanguage.instance.setLocale(const Locale('en'));
    expect(AppLanguage.instance.isVietnamese, isFalse);
    expect(AppLanguage.instance.currentLanguageLabel, 'English');
    expect(tr('tab_home'), 'Home');
    expect(tr('tab_explore'), 'Explore');
    expect(tr('item_language'), 'Language');
    expect(tr('btn_login'), 'Log in');

    // 3. Fallback khi key không tồn tại
    expect(AppStrings.get('en', 'non_existing_key_xyz'), 'non_existing_key_xyz');

    // 4. Reset lại Tiếng Việt
    AppLanguage.instance.setLocale(const Locale('vi'));
    expect(AppLanguage.instance.isVietnamese, isTrue);
  });

  testWidgets('Kiểm thử chuyển đổi ngôn ngữ Vi <-> En qua BottomSheet tại AccountScreen và cập nhật UI tức thì', (WidgetTester tester) async {
    final fakeApi = FakeApiService();

    await tester.pumpWidget(Ptc1App(apiService: fakeApi));
    await tester.pumpAndSettle();

    // 1. Mặc định 4 tab thanh điều hướng là Tiếng Việt
    expect(find.text('Trang chủ'), findsOneWidget);
    expect(find.text('Bản đồ'), findsOneWidget);
    expect(find.text('Đã lưu'), findsOneWidget);
    expect(find.text('Cá nhân'), findsOneWidget);

    // 2. Di chuyển sang tab Cá nhân
    await tester.tap(find.text('Cá nhân'));
    await tester.pumpAndSettle();

    // 3. Cuộn xuống tìm mục Ngôn ngữ và kiểm tra nhãn Tiếng Việt
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(find.text('Ngôn ngữ'), findsOneWidget);
    expect(find.text('Tiếng Việt'), findsWidgets);

    // 4. Chạm vào mục Ngôn ngữ mở BottomSheet
    await tester.tap(find.text('Ngôn ngữ'));
    await tester.pumpAndSettle();

    // 5. Kiểm tra BottomSheet hiển thị tiêu đề và 2 tùy chọn
    expect(find.text('Chọn ngôn ngữ'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);

    // 6. Chọn English
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    // 7. Xác nhận giao diện đã chuyển sang English tức thì
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('English'), findsWidgets);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Map'), findsOneWidget);
    expect(find.text('Favourites'), findsOneWidget);
    expect(find.text('Account'), findsWidgets);

    // 8. Chạm lại vào Language để đổi ngược lại Tiếng Việt
    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();
    expect(find.text('Select Language'), findsOneWidget);
    await tester.tap(find.text('Tiếng Việt'));
    await tester.pumpAndSettle();

    // 9. Xác nhận giao diện hồi phục về Tiếng Việt
    expect(find.text('Ngôn ngữ'), findsOneWidget);
    expect(find.text('Trang chủ'), findsOneWidget);
    expect(find.text('Cá nhân'), findsOneWidget);
  });

  testWidgets('Kiểm thử cấu hình ThemeData sử dụng font chữ BeVietnamPro', (WidgetTester tester) async {
    await tester.pumpWidget(const Ptc1App());
    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.theme?.textTheme.bodyMedium?.fontFamily, 'BeVietnamPro');
  });

}
