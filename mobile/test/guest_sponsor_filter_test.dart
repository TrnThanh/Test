import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/models.dart';
import 'package:mobile/screens/explore_screen.dart';
import 'package:mobile/screens/map_screen.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/location_service.dart';

class MockSponsorApiService extends ApiService {
  final List<Restaurant> mockRestaurants = [
    Restaurant(
      id: 1,
      name: 'Quán Sponsor Đặng Xá',
      address: 'Số 10 Đặng Xá, Gia Lâm, Hà Nội',
      phone: '0901234567',
      description: 'Quán ăn tài trợ',
      latitude: 21.0185,
      longitude: 105.9450,
      openTime: '06:00',
      closeTime: '22:00',
      isActive: true,
      isSponsor: true,
    ),
    Restaurant(
      id: 2,
      name: 'Quán Thường Cổ Bi',
      address: 'Số 20 Cổ Bi, Gia Lâm, Hà Nội',
      phone: '0907654321',
      description: 'Quán ăn bình thường không tài trợ',
      latitude: 21.0190,
      longitude: 105.9460,
      openTime: '08:00',
      closeTime: '21:00',
      isActive: true,
      isSponsor: false,
    ),
  ];

  @override
  Future<List<Restaurant>> getRestaurants({int skip = 0, int limit = 200}) async {
    return mockRestaurants;
  }

  @override
  Future<List<Restaurant>> getNearbyRestaurants({
    required double lat,
    required double lon,
    required double radiusKm,
  }) async {
    return mockRestaurants;
  }

  @override
  Future<CurrentWeather> getCurrentWeather({double? lat, double? lon}) async {
    return CurrentWeather(
      temperature: 26.0,
      condition: 'Clear',
      description: 'Mát mẻ dễ chịu',
      humidity: 60,
      latitude: 21.0185,
      longitude: 105.9450,
      locationName: 'Gia Lâm',
    );
  }

  @override
  Future<ContextualRecommendation?> getContextualRecommendations({
    required double lat,
    required double lon,
    int? userId,
    double? temp,
    String? weatherCode,
  }) async {
    return ContextualRecommendation(
      context: RecommendationContext(
        mealPeriod: 'Bữa trưa',
        mealTimeRange: '11:00 - 13:30',
        weatherDesc: 'Mát mẻ',
        targetCaloriesDisplay: '600 kcal',
        disclaimer: '',
      ),
      heroRestaurant: mockRestaurants[0], // Sponsor
      recommendedRestaurants: [mockRestaurants[0]], // Only sponsor in recs
    );
  }
}

void main() {
  setUp(() {
    LocationService.debugProvider = () async => null;
  });

  tearDown(() {
    LocationService.debugProvider = null;
  });

  testWidgets('ExploreScreen khi currentUser == null chỉ hiển thị quán is_sponsor = true', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final mockApi = MockSponsorApiService();

    await tester.pumpWidget(
      MaterialApp(
        home: ExploreScreen(
          api: mockApi,
          currentUser: null, // Khách chưa đăng nhập
          onRequireLogin: () {},
        ),
      ),
    );

    // Chờ async loadData
    await tester.pumpAndSettle();

    // Quán có is_sponsor = true phải hiển thị
    expect(find.text('Quán Sponsor Đặng Xá'), findsWidgets);

    // Quán thường is_sponsor = false không được hiển thị
    expect(find.text('Quán Thường Cổ Bi'), findsNothing);
  });

  testWidgets('ExploreScreen khi currentUser != null hiển thị cả quán thường và quán sponsor', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final mockApi = MockSponsorApiService();
    final loggedInUser = RoleLoginResponse(
      sessionId: 'sess_123',
      id: 1,
      role: 'user',
      email: 'user@test.com',
      fullName: 'Nguyễn Văn A',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ExploreScreen(
          api: mockApi,
          currentUser: loggedInUser, // Đã đăng nhập
          onRequireLogin: () {},
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Cả hai quán đều phải xuất hiện trên màn hình
    expect(find.text('Quán Sponsor Đặng Xá'), findsWidgets);
    expect(find.text('Quán Thường Cổ Bi'), findsWidgets);
  });

  testWidgets('ExploreScreen cập nhật danh sách quán ngay khi người dùng đăng nhập tài khoản', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final mockApi = MockSponsorApiService();
    RoleLoginResponse? user;

    late StateSetter setParentState;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            setParentState = setState;
            return ExploreScreen(
              api: mockApi,
              currentUser: user,
              onRequireLogin: () {},
            );
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Ban đầu chưa đăng nhập: chỉ thấy quán sponsor
    expect(find.text('Quán Sponsor Đặng Xá'), findsWidgets);
    expect(find.text('Quán Thường Cổ Bi'), findsNothing);

    // Giả lập người dùng đăng nhập thành công
    setParentState(() {
      user = RoleLoginResponse(
        sessionId: 'sess_456',
        id: 2,
        role: 'user',
        email: 'user2@test.com',
        fullName: 'Trần Thị B',
      );
    });

    await tester.pumpAndSettle();

    // Sau khi đăng nhập: cả hai quán đều xuất hiện
    expect(find.text('Quán Sponsor Đặng Xá'), findsWidgets);
    expect(find.text('Quán Thường Cổ Bi'), findsWidgets);
  });

  testWidgets('MapScreen khi currentUser == null với initialRestaurant là quán thường thì không chọn và không hiển thị BottomSheet', (WidgetTester tester) async {
    final mockApi = MockSponsorApiService();

    // Thử truyền quán thường khi chưa đăng nhập
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapScreen(
            api: mockApi,
            currentUser: null, // Khách chưa đăng nhập
            onRequireLogin: () {},
            initialRestaurant: mockApi.mockRestaurants[1], // Quán thường
            initialLat: 21.0190,
            initialLon: 105.9460,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Quán thường không được chọn hiển thị
    expect(find.text('Quán Thường Cổ Bi'), findsNothing);
  });

  testWidgets('MapScreen khi currentUser == null với initialRestaurant là quán sponsor thì hiển thị bình thường', (WidgetTester tester) async {
    final mockApi = MockSponsorApiService();

    // Truyền quán sponsor khi chưa đăng nhập
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapScreen(
            api: mockApi,
            currentUser: null, // Khách chưa đăng nhập
            onRequireLogin: () {},
            initialRestaurant: mockApi.mockRestaurants[0], // Quán sponsor
            initialLat: 21.0185,
            initialLon: 105.9450,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Quán sponsor được chọn hiển thị trên BottomSheet
    expect(find.text('Quán Sponsor Đặng Xá'), findsWidgets);
  });
}
