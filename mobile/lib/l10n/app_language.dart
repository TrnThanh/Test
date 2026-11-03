import 'package:flutter/material.dart';
import 'app_strings.dart';

/// Quản lý trạng thái ngôn ngữ toàn ứng dụng bằng cơ chế Reactive ChangeNotifier thuần Flutter.
class AppLanguage extends ChangeNotifier {
  AppLanguage._();

  /// Singleton toàn cục duy nhất
  static final AppLanguage instance = AppLanguage._();

  Locale _locale = const Locale('vi');

  /// Mã locale hiện tại (mặc định 'vi')
  Locale get locale => _locale;

  /// Kiểm tra có phải đang chọn Tiếng Việt
  bool get isVietnamese => _locale.languageCode == 'vi';

  /// Nhãn hiển thị ngôn ngữ hiện tại
  String get currentLanguageLabel => isVietnamese ? 'Tiếng Việt' : 'English';

  /// Thay đổi ngôn ngữ và thông báo rebuild toàn bộ widget đang lắng nghe
  void setLocale(Locale newLocale) {
    if (_locale.languageCode == newLocale.languageCode) return;
    _locale = newLocale;
    notifyListeners();
  }

  /// Chuyển đổi qua lại nhanh giữa Tiếng Việt và English
  void toggleLanguage() {
    if (isVietnamese) {
      setLocale(const Locale('en'));
    } else {
      setLocale(const Locale('vi'));
    }
  }
}

/// Hàm tiện ích toàn cục tra cứu văn bản đa ngôn ngữ siêu ngắn gọn
String tr(String key) => AppStrings.get(AppLanguage.instance.locale.languageCode, key);
