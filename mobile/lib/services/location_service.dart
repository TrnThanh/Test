import 'location_stub.dart'
    if (dart.library.html) 'location_web.dart';

class LocationService {
  static Future<Map<String, double>?> getDeviceLocation() async {
    return await getPlatformLocation();
  }
}
