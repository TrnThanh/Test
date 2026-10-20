import 'package:flutter/foundation.dart';

class Env {
  static const String _override = String.fromEnvironment('API_BASE_URL');
  static int activePort = 8001;

  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:$activePort/api/v1'; // Android Emulator loopback
    }
    return 'http://localhost:$activePort/api/v1'; // Windows Desktop / Web / iOS Simulator
  }

  static void switchPort() {
    activePort = (activePort == 8001) ? 8000 : 8001;
  }
}
