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
}

void main() {
  testWidgets('Kiểm thử khởi chạy Ptc1App và chuyển đổi 4 tab NavigationBar', (WidgetTester tester) async {
    final fakeApi = FakeApiService();

    // Khởi chạy ứng dụng với fake api
    await tester.pumpWidget(Ptc1App(apiService: fakeApi));
    await tester.pumpAndSettle();

    // 1. Kiểm tra màn hình Khám phá ban đầu
    expect(find.text('🍜 PTC1 Khám Phá Quán Ăn'), findsOneWidget);
    expect(find.text('Phở Thìn Lò Đúc'), findsOneWidget);
    expect(find.text('Bún Chả Đắc Kim'), findsOneWidget);

    // 2. Chuyển sang Tab "Gần đây"
    await tester.tap(find.text('Gần đây'));
    await tester.pumpAndSettle();
    expect(find.text('📍 Quán Ăn Lân Cận (PostGIS)'), findsOneWidget);
    expect(find.text('Bán kính tìm kiếm:'), findsOneWidget);

    // 3. Chuyển sang Tab "Bản đồ OSM"
    await tester.tap(find.text('Bản đồ OSM'));
    await tester.pumpAndSettle();
    expect(find.text('🗺️ Bản Đồ & Geocoding OSM'), findsOneWidget);

    // 4. Chuyển sang Tab "Tài khoản"
    await tester.tap(find.text('Tài khoản'));
    await tester.pumpAndSettle();
    expect(find.text('Đăng Nhập'), findsOneWidget);
    expect(find.text('👤 Thực khách'), findsOneWidget);
    expect(find.text('🏪 Chủ quán'), findsOneWidget);
  });
}
