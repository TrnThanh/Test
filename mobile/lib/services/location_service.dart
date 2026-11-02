import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Dịch vụ định vị GPS thiết bị phần cứng thời gian thực cho ứng dụng di động
class LocationService {
  // Khởi tạo private ngăn việc tạo thực thể từ bên ngoài
  LocationService._();

  /// Hook phục vụ unit test và widget test thay thế kết quả GPS thật
  @visibleForTesting
  static Future<Map<String, double>?> Function()? debugProvider;

  // Cache lưu request đang chạy để chống gọi trùng lặp mở nhiều popup cùng lúc
  static Future<Map<String, double>?>? _inFlight;

  /// Lấy toạ độ GPS thực tế từ thiết bị (Android, iOS, Web)
  static Future<Map<String, double>?> getDeviceLocation() {
    // 1. Ưu tiên mock provider nếu đang chạy trong môi trường kiểm thử
    final override = debugProvider;
    if (override != null) {
      return override();
    }

    // 2. Trong môi trường kiểm thử tự động headless (flutter test), trả về null an toàn tránh treo native channel
    if (!kIsWeb) {
      try {
        if (Platform.environment.containsKey('FLUTTER_TEST')) {
          return Future.value(null);
        }
      } catch (_) {}
    }

    // 3. Tái sử dụng request đang chờ nếu người dùng bấm liên tiếp
    return _inFlight ??= _fetch().whenComplete(() => _inFlight = null);
  }

  // Luồng kiểm tra quyền và truy xuất toạ độ GPS chi tiết
  static Future<Map<String, double>?> _fetch() async {
    try {
      // 1. Kiểm tra dịch vụ định vị GPS trên thiết bị có đang được bật không
      final isServiceEnabled = await Geolocator.isLocationServiceEnabled()
          .timeout(const Duration(seconds: 3));
      if (!isServiceEnabled) {
        debugPrint('[LocationService] Dịch vụ GPS trên thiết bị đang bị tắt.');
        return await _lastKnownOrNull();
      }

      // 2. Kiểm tra quyền truy cập vị trí hiện tại của ứng dụng
      var permission = await Geolocator.checkPermission()
          .timeout(const Duration(seconds: 3));
      if (permission == LocationPermission.denied) {
        // Yêu cầu người dùng cấp quyền truy cập vị trí
        permission = await Geolocator.requestPermission()
            .timeout(const Duration(seconds: 15));
      }

      // 3. Xử lý trường hợp người dùng từ chối cấp quyền
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        debugPrint('[LocationService] Quyền vị trí bị từ chối: $permission');
        return null;
      }

      // 4. Lấy toạ độ GPS chính xác với timeout 2 lớp (5s trong settings, 6s ngoài future)
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 5),
        ),
      ).timeout(const Duration(seconds: 6));

      return {
        'lat': position.latitude,
        'lon': position.longitude,
      };
    } on TimeoutException {
      // Xử lý riêng biệt khi hết thời gian chờ phản hồi GPS (đặc biệt trên Web hoặc máy không có chip GPS)
      debugPrint('[LocationService] Quá thời gian chờ phản hồi toạ độ GPS (timeout), sử dụng vị trí mặc định.');
      return await _lastKnownOrNull();
    } catch (e) {
      // Bắt an toàn mọi ngoại lệ bao gồm MissingPluginException trong test
      debugPrint('[LocationService] Lỗi khi lấy toạ độ GPS: $e');
      return await _lastKnownOrNull();
    }
  }

  // Thử lấy toạ độ gần nhất đã lưu trong bộ đệm hệ điều hành nếu GPS hiện tại bị chậm
  static Future<Map<String, double>?> _lastKnownOrNull() async {
    try {
      final lastPos = await Geolocator.getLastKnownPosition()
          .timeout(const Duration(seconds: 2));
      if (lastPos != null) {
        return {
          'lat': lastPos.latitude,
          'lon': lastPos.longitude,
        };
      }
    } catch (_) {}
    return null;
  }
}
