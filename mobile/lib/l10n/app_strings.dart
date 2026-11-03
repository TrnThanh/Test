/// Từ điển chuỗi đa ngôn ngữ (Tiếng Việt & English) cho PTC1 Mobile App
class AppStrings {
  static const Map<String, Map<String, String>> _strings = {
    // Thanh điều hướng chính (NavigationBar)
    'tab_home': {'vi': 'Trang chủ', 'en': 'Home'},
    'tab_explore': {'vi': 'Khám phá', 'en': 'Explore'},
    'tab_map': {'vi': 'Bản đồ', 'en': 'Map'},
    'tab_favourites': {'vi': 'Yêu thích', 'en': 'Favourites'},
    'tab_account': {'vi': 'Tài khoản', 'en': 'Account'},

    // Cài đặt ngôn ngữ
    'item_language': {'vi': 'Ngôn ngữ', 'en': 'Language'},
    'lang_vi': {'vi': 'Tiếng Việt', 'en': 'Tiếng Việt'},
    'lang_en': {'vi': 'English', 'en': 'English'},
    'lang_choose': {'vi': 'Chọn ngôn ngữ', 'en': 'Select Language'},

    // Màn hình Tài khoản (AccountScreen)
    'account_title': {'vi': 'Tài Khoản', 'en': 'Account'},
    'greeting_guest': {'vi': 'Chào bạn!', 'en': 'Hello!'},
    'guest_experience': {
      'vi': 'Bạn đang trải nghiệm với tư cách Khách',
      'en': 'You are browsing as a Guest',
    },
    'btn_login': {'vi': 'Đăng nhập', 'en': 'Log in'},
    'btn_register_free': {'vi': 'Tạo tài khoản miễn phí', 'en': 'Create free account'},
    'member_benefits': {'vi': 'Lợi ích khi đăng nhập thành viên', 'en': 'Member Benefits'},
    'benefit_1_title': {
      'vi': 'Lưu & đồng bộ món ăn yêu thích',
      'en': 'Save & sync favorite dishes',
    },
    'benefit_1_desc': {
      'vi': 'Thả tim các món ngon để xem lại nhanh chóng bất cứ khi nào bạn đói bụng.',
      'en': 'Like tasty dishes to quickly revisit whenever you are hungry.',
    },
    'benefit_2_title': {
      'vi': 'Gợi ý món ăn thông minh theo khẩu vị',
      'en': 'Smart food recommendations for your taste',
    },
    'benefit_2_desc': {
      'vi': 'Đề xuất bữa ăn chuẩn vóc dáng, thời tiết và sở thích ăn uống cá nhân của bạn.',
      'en': 'Personalized meals based on your wellness, weather, and preferences.',
    },
    'benefit_3_title': {
      'vi': 'Khám phá quán ngon & ưu đãi quanh bạn',
      'en': 'Discover good food & deals near you',
    },
    'benefit_3_desc': {
      'vi': 'Cập nhật món ăn mới và bảng giá chuẩn xác nhất từ các quán lân cận.',
      'en': 'Get the latest dishes and pricing from nearby restaurants.',
    },
    'item_location_permission': {'vi': 'Quyền truy cập vị trí', 'en': 'Location Permission'},
    'item_location_permission_sub': {
      'vi': 'Dùng GPS để định vị và gợi ý quán ăn gần nhất',
      'en': 'Use GPS to locate and suggest the nearest dining spots',
    },
    'item_privacy': {'vi': 'Điều khoản & Quyền riêng tư', 'en': 'Terms & Privacy'},
    'item_app_version': {'vi': 'Phiên bản ứng dụng', 'en': 'App Version'},
    'btn_logout': {'vi': 'Đăng xuất', 'en': 'Log out'},
    'btn_delete_account': {'vi': 'Xoá tài khoản', 'en': 'Delete Account'},

    // Màn hình Khám phá & Bản đồ
    'search_hint': {'vi': 'Tìm món ăn, quán ăn...', 'en': 'Search food, restaurants...'},
    'today_recommend': {'vi': 'Gợi ý hôm nay', 'en': "Today's Recommendations"},
    'cuisine_categories': {'vi': 'Danh mục ẩm thực', 'en': 'Cuisine Categories'},
    'empty_favourites': {'vi': 'Chưa có quán yêu thích nào', 'en': 'No saved favorites yet'},
    'walking_route': {'vi': 'Chỉ đường đi bộ', 'en': 'Walking Route'},

    // Thao tác chung
    'close': {'vi': 'Đóng', 'en': 'Close'},
    'confirm': {'vi': 'Xác nhận', 'en': 'Confirm'},
    'cancel': {'vi': 'Hủy', 'en': 'Cancel'},
  };

  /// Tra cứu chuỗi theo mã ngôn ngữ và key. Nếu không có mã thì fallback sang Tiếng Việt ('vi').
  static String get(String langCode, String key) {
    final entry = _strings[key];
    if (entry == null) return key;
    return entry[langCode] ?? entry['vi'] ?? key;
  }
}
