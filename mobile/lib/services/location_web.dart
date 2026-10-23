import 'dart:async';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

Future<Map<String, double>?> getPlatformLocation() async {
  try {
    final completer = Completer<Map<String, double>?>();
    web.window.navigator.geolocation.getCurrentPosition(
      ((web.GeolocationPosition pos) {
        final lat = pos.coords.latitude;
        final lon = pos.coords.longitude;
        completer.complete({
          'lat': lat.toDouble(),
          'lon': lon.toDouble(),
        });
      }).toJS,
      ((web.GeolocationPositionError error) {
        completer.complete(null);
      }).toJS,
      web.PositionOptions(
        enableHighAccuracy: true,
        timeout: 6000,
      ),
    );
    return await completer.future.timeout(
      const Duration(seconds: 7),
      onTimeout: () => null,
    );
  } catch (_) {
    return null;
  }
}
