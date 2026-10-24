import 'dart:async';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

Future<Map<String, double>?> getPlatformLocation() async {
  try {
    final completer = Completer<Map<String, double>?>();

    void onPos(web.GeolocationPosition pos) {
      if (!completer.isCompleted) {
        completer.complete({
          'lat': pos.coords.latitude.toDouble(),
          'lon': pos.coords.longitude.toDouble(),
        });
      }
    }

    void onErr(web.GeolocationPositionError error) {
      try {
        // Fallback sang chế độ nhanh nếu độ chính xác cao mất thời gian hoặc không hỗ trợ
        web.window.navigator.geolocation.getCurrentPosition(
          onPos.toJS,
          ((web.GeolocationPositionError _) {
            if (!completer.isCompleted) completer.complete(null);
          }).toJS,
          web.PositionOptions(
            enableHighAccuracy: false,
            timeout: 2500,
            maximumAge: 60000,
          ),
        );
      } catch (_) {
        if (!completer.isCompleted) completer.complete(null);
      }
    }

    // 1. Thử lấy toạ độ: cho phép dùng cache gần nhất (trong 30s) để phản hồi siêu tốc
    web.window.navigator.geolocation.getCurrentPosition(
      onPos.toJS,
      onErr.toJS,
      web.PositionOptions(
        enableHighAccuracy: true,
        timeout: 3000,
        maximumAge: 30000,
      ),
    );

    return await completer.future.timeout(
      const Duration(seconds: 6),
      onTimeout: () => null,
    );
  } catch (_) {
    return null;
  }
}
