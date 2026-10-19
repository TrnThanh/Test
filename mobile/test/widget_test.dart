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
        sellerId: 1,
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
        sellerId: 1,
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
        sellerId: 1,
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
}

void main() {
  testWidgets('Kiểm thử khởi chạy Ptc1App và chuyển đổi 4 tab NavigationBar', (WidgetTester tester) async {
    final fakeApi = FakeApiService();

    // Khởi chạy ứng dụng với fake api
    await tester.pumpWidget(Ptc1App(apiService: fakeApi));
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
    expect(find.text('Thực khách (User)'), findsOneWidget);
    expect(find.text('Chủ quán (Seller)'), findsOneWidget);
    expect(find.text('Email *'), findsOneWidget);
    expect(find.text('Mật khẩu *'), findsOneWidget);
  });

  testWidgets('Kiểm thử Auth Gate khi khách vãng lai nhấn xem thực đơn và bấm yêu thích', (WidgetTester tester) async {
    final fakeApi = FakeApiService();

    await tester.pumpWidget(Ptc1App(apiService: fakeApi));
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

  testWidgets('Kiểm thử chuyển đổi vai trò Thực khách và Chủ quán trên màn hình Đăng ký', (WidgetTester tester) async {
    final fakeApi = FakeApiService();

    await tester.pumpWidget(Ptc1App(apiService: fakeApi));
    await tester.pumpAndSettle();

    // Vào Tab Tài khoản
    await tester.tap(find.text('Tài khoản'));
    await tester.pumpAndSettle();

    // Chuyển sang chế độ Đăng Ký
    await tester.tap(find.text('Đăng ký'));
    await tester.pumpAndSettle();
    expect(find.text('Họ và tên'), findsOneWidget);

    // Chuyển vai trò sang Chủ quán (Seller)
    await tester.tap(find.text('Chủ quán (Seller)'));
    await tester.pumpAndSettle();

    // Kiểm tra xuất hiện các trường của Seller
    expect(find.text('Tên cửa hàng/Shop *'), findsOneWidget);
    expect(find.text('Số điện thoại'), findsOneWidget);
  });
}
