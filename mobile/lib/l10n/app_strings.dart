/// Từ điển chuỗi đa ngôn ngữ (Tiếng Việt & English) cho PTC1 Mobile App
class AppStrings {
  static const Map<String, Map<String, String>> _strings = {
    // ----------------------------------------------------
    // THANH ĐIỀU HƯỚNG CHÍNH (NavigationBar)
    // ----------------------------------------------------
    'tab_home': {'vi': 'Trang chủ', 'en': 'Home'},
    'tab_explore': {'vi': 'Khám phá', 'en': 'Explore'},
    'tab_map': {'vi': 'Bản đồ', 'en': 'Map'},
    'tab_favourites': {'vi': 'Yêu thích', 'en': 'Favourites'},
    'tab_account': {'vi': 'Tài khoản', 'en': 'Account'},

    // ----------------------------------------------------
    // CÀI ĐẶT NGÔN NGỮ
    // ----------------------------------------------------
    'item_language': {'vi': 'Ngôn ngữ', 'en': 'Language'},
    'lang_vi': {'vi': 'Tiếng Việt', 'en': 'Tiếng Việt'},
    'lang_en': {'vi': 'English', 'en': 'English'},
    'lang_choose': {'vi': 'Chọn ngôn ngữ', 'en': 'Select Language'},

    // ----------------------------------------------------
    // MÀN HÌNH TÀI KHOẢN (AccountScreen)
    // ----------------------------------------------------
    'account_title': {'vi': 'Tài Khoản', 'en': 'Account'},
    'account_title_member': {'vi': 'Tài Khoản Thực Khách', 'en': 'Diner Account'},
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
    'confirm_logout_title': {'vi': 'Xác nhận đăng xuất', 'en': 'Confirm Logout'},
    'confirm_logout_desc': {
      'vi': 'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản không?',
      'en': 'Are you sure you want to log out of your account?',
    },
    'diner_badge': {'vi': 'Thực khách', 'en': 'Diner'},
    'survey_banner_title': {'vi': 'Chưa thiết lập sở thích ẩm thực', 'en': 'Dietary preferences not set'},
    'survey_banner_desc': {
      'vi': 'Khảo sát ngay để nhận gợi ý món ăn chuẩn vóc dáng & khẩu vị!',
      'en': 'Take the survey now for meal picks tailored to your body & taste!',
    },
    'btn_survey': {'vi': 'Khảo sát', 'en': 'Survey'},
    'health_profile_title': {'vi': 'Hồ Sơ Sức Khỏe & Sở Thích', 'en': 'Health & Taste Profile'},
    'no_profile_info': {'vi': 'Chưa có thông tin hồ sơ sức khỏe & khẩu vị.', 'en': 'No health and dietary profile info yet.'},
    'btn_setup_now': {'vi': 'Thiết lập ngay', 'en': 'Set up now'},
    'label_height': {'vi': 'Chiều cao', 'en': 'Height'},
    'label_weight': {'vi': 'Cân nặng', 'en': 'Weight'},
    'label_bmi': {'vi': 'BMI', 'en': 'BMI'},
    'label_body_status': {'vi': 'Thể trạng', 'en': 'Status'},
    'label_goal': {'vi': 'Mục tiêu', 'en': 'Goal'},
    'label_diet': {'vi': 'Chế độ ăn', 'en': 'Diet'},
    'label_allergy': {'vi': 'Dị ứng', 'en': 'Allergies'},
    'label_budget': {'vi': 'Mức chi', 'en': 'Budget'},
    'goal_lose_weight': {'vi': 'Giảm cân', 'en': 'Weight loss'},
    'goal_gain_muscle': {'vi': 'Tăng cơ', 'en': 'Build muscle'},
    'goal_maintain': {'vi': 'Duy trì vóc dáng', 'en': 'Maintain body'},
    'goal_healthy': {'vi': 'Ăn uống lành mạnh', 'en': 'Healthy eating'},
    'bmi_underweight': {'vi': 'Hơi gầy', 'en': 'Underweight'},
    'bmi_normal': {'vi': 'Chuẩn dáng', 'en': 'Normal weight'},
    'bmi_overweight': {'vi': 'Thừa cân', 'en': 'Overweight'},

    // ----------------------------------------------------
    // MÀN HÌNH KHÁM PHÁ (ExploreScreen)
    // ----------------------------------------------------
    'greeting_morning': {'vi': 'Sáng nay ăn gì nhỉ?', 'en': 'What to eat this morning?'},
    'greeting_noon': {'vi': 'Trưa nay ăn gì nhỉ?', 'en': 'What to eat for lunch?'},
    'greeting_afternoon': {'vi': 'Chiều nay ăn gì nhỉ?', 'en': 'What to eat this afternoon?'},
    'greeting_evening': {'vi': 'Tối nay ăn gì nhỉ?', 'en': 'What to eat for dinner?'},
    'weather_night_cool': {'vi': 'Đêm mát mẻ', 'en': 'Cool night'},
    'weather_day_cool': {'vi': 'Thời tiết mát mẻ', 'en': 'Pleasant weather'},
    'weather_chilly': {'vi': 'Trời se lạnh', 'en': 'Chilly weather'},
    'weather_mild': {'vi': 'Trời dịu mát', 'en': 'Mild weather'},
    'weather_sunny': {'vi': 'Trời nắng nhẹ', 'en': 'Light sunshine'},
    'weather_hot': {'vi': 'Trời oi nóng', 'en': 'Hot & humid'},
    'search_explore_hint': {'vi': 'Thêm món gì? Tìm quán, món ăn...', 'en': 'Craving something? Search dishes, places...'},
    'search_hint': {'vi': 'Tìm món ăn, quán ăn...', 'en': 'Search food, restaurants...'},
    'hungry_explore': {'vi': 'Đói rồi, khám phá thôi!', 'en': "Hungry? Let's explore!"},
    'rec_for_you': {'vi': 'Gợi ý dành riêng cho bạn hôm nay', 'en': 'Personalized picks for you today'},
    'rec_for_user': {'vi': 'Gợi ý cá nhân hoá cho', 'en': 'Personalized picks for'},
    'match_taste': {'vi': '🌿 Hợp gu của bạn', 'en': '🌿 Matches your taste'},
    'explore_now': {'vi': 'Khám phá ngay', 'en': 'Explore now'},
    'explore_restaurants': {'vi': 'Khám phá quán ngon', 'en': 'Discover good places'},
    'see_all': {'vi': 'Xem tất cả', 'en': 'See all'},
    'see_more': {'vi': 'Xem thêm', 'en': 'See more'},
    'other_restaurants': {'vi': 'quán khác', 'en': 'more restaurants'},
    'collapse_list': {'vi': 'Thu gọn danh sách', 'en': 'Collapse list'},
    'no_restaurant_found': {'vi': 'Không tìm thấy quán ăn nào phù hợp', 'en': 'No matching restaurants found'},
    'connection_error': {'vi': 'Lỗi kết nối', 'en': 'Connection error'},

    // Categories
    'cat_all': {'vi': 'Tất cả', 'en': 'All'},
    'cat_noodles': {'vi': 'Phở, Bún & Món nước', 'en': 'Noodles & Soups'},
    'cat_rice': {'vi': 'Cơm & Xôi', 'en': 'Rice & Sticky Rice'},
    'cat_banhmi': {'vi': 'Bánh mì', 'en': 'Vietnamese Banh Mi'},
    'cat_traditional': {'vi': 'Bánh truyền thống & Món cuốn', 'en': 'Traditional Cakes & Rolls'},
    'cat_bbq': {'vi': 'Lẩu & Nướng', 'en': 'Hotpot & BBQ'},
    'cat_seafood': {'vi': 'Ốc & Quán lai rai', 'en': 'Seafood & Street Bites'},
    'cat_snacks': {'vi': 'Đồ ăn vặt', 'en': 'Snacks'},
    'cat_desserts': {'vi': 'Chè & Tráng miệng', 'en': 'Desserts & Sweet Soups'},
    'cat_coffee': {'vi': 'Cà phê & Thức uống giải khát', 'en': 'Coffee & Drinks'},
    'cat_vegetarian': {'vi': 'Ẩm thực Chay & Thực dưỡng', 'en': 'Vegetarian & Healthy'},

    // ----------------------------------------------------
    // MÀN HÌNH YÊU THÍCH (FavouritesScreen)
    // ----------------------------------------------------
    'favourites_title': {'vi': 'Món Ăn Yêu Thích', 'en': 'Favorite Dishes'},
    'favourites_guest_title': {'vi': 'Lưu Giữ Món Ăn Bạn Yêu Thích', 'en': 'Save Your Favorite Dishes'},
    'favourites_guest_desc': {
      'vi': 'Đăng nhập tài khoản Thực khách để thả tim lưu trữ các món ngon và nhận gợi ý ẩm thực chuẩn khẩu vị nhất!',
      'en': 'Sign in as a Diner to save your favorite dishes and get personalized meal recommendations!',
    },
    'empty_favourites': {'vi': 'Chưa có món ăn yêu thích nào', 'en': 'No favorite dishes yet'},
    'empty_favourites_desc': {
      'vi': 'Khám phá thực đơn các quán ăn hấp dẫn tại Gia Lâm và nhấn biểu tượng trái tim để lưu lại bạn nhé!',
      'en': 'Explore menus from delicious local spots in Gia Lam and tap the heart icon to save them!',
    },
    'btn_login_now': {'vi': 'Đăng nhập ngay', 'en': 'Log in now'},
    'btn_explore_now': {'vi': 'Khám phá món ngon ngay', 'en': 'Explore tasty food now'},
    'dish_removed_fav': {'vi': 'Đã bỏ món ăn khỏi danh sách yêu thích.', 'en': 'Dish removed from favorites.'},
    'dish_added_fav': {'vi': 'Đã thêm vào món ăn yêu thích!', 'en': 'Added to favorites!'},
    'tooltip_remove_fav': {'vi': 'Bỏ thích', 'en': 'Unlike'},
    'tooltip_refresh': {'vi': 'Tải lại', 'en': 'Reload'},

    // ----------------------------------------------------
    // MÀN HÌNH BẢN ĐỒ (MapScreen)
    // ----------------------------------------------------
    'map_title': {'vi': 'Bản Đồ & Quán Ăn Gia Lâm', 'en': 'Map & Dining in Gia Lam'},
    'map_search_hint': {'vi': 'Tìm tên quán hoặc địa điểm...', 'en': 'Search restaurant or place...'},
    'radius_filter': {'vi': 'Chọn Bán Kính Tìm Quán', 'en': 'Select Search Radius'},
    'walking_route': {'vi': 'Chỉ đường đi bộ', 'en': 'Walking Route'},
    'btn_apply': {'vi': 'Áp dụng', 'en': 'Apply'},
    'btn_search': {'vi': 'Tìm', 'en': 'Search'},
    'out_of_bounds': {'vi': 'Vị trí nằm ngoài vùng phủ sóng Gia Lâm!', 'en': 'Location outside Gia Lam area!'},
    'location_not_found': {
      'vi': 'Chưa lấy được toạ độ GPS. Vui lòng cấp quyền vị trí!',
      'en': 'Could not get GPS location. Please allow location permissions!',
    },
    'reverse_route': {'vi': 'Đã đảo ngược chiều đi', 'en': 'Reversed route direction'},
    'route_options': {'vi': 'Tùy chọn tuyến đường đi bộ', 'en': 'Walking route options'},
    'share_route': {'vi': 'Chia sẻ tuyến đường đến', 'en': 'Share route to'},
    'start_walking': {'vi': 'Bắt đầu chỉ đường đi bộ đến', 'en': 'Start walking directions to'},
    'saved_restaurant_fav': {'vi': 'Đã lưu quán vào mục yêu thích', 'en': 'Saved restaurant to favorites'},
    'phone_label': {'vi': 'Số điện thoại', 'en': 'Phone number'},

    // ----------------------------------------------------
    // THỰC ĐƠN QUÁN (RestaurantMenuWidget)
    // ----------------------------------------------------
    'menu_search_hint': {'vi': 'Tìm món ăn trong thực đơn...', 'en': 'Search dishes in menu...'},
    'login_required': {'vi': 'Yêu Cầu Đăng Nhập', 'en': 'Login Required'},
    'login_required_desc': {
      'vi': 'Bạn cần đăng nhập tài khoản để thả tim lưu món ăn này!',
      'en': 'You need to sign in to save this dish to your favorites!',
    },
    'maybe_later': {'vi': 'Để sau', 'en': 'Maybe later'},
    'clear_search': {'vi': 'Xóa tìm kiếm', 'en': 'Clear search'},
    'no_dishes_found': {'vi': 'Không tìm thấy món ăn nào', 'en': 'No dishes found'},
    'all_menu': {'vi': 'Tất cả', 'en': 'All'},

    // ----------------------------------------------------
    // FORM ĐĂNG NHẬP / ĐĂNG KÝ (AuthFormModal)
    // ----------------------------------------------------
    'modal_login_title': {'vi': 'Đăng Nhập Khách Hàng', 'en': 'Customer Sign In'},
    'modal_register_title': {'vi': 'Tạo Tài Khoản Khách Hàng', 'en': 'Create Customer Account'},
    'tab_btn_login': {'vi': 'Đăng nhập', 'en': 'Log in'},
    'tab_btn_register': {'vi': 'Đăng ký', 'en': 'Sign up'},
    'btn_submit_register': {'vi': 'Đăng ký ngay', 'en': 'Sign up now'},
    'btn_submit_login': {'vi': 'Đăng nhập', 'en': 'Log in'},
    'label_email': {'vi': 'Email *', 'en': 'Email *'},
    'label_password': {'vi': 'Mật khẩu *', 'en': 'Password *'},
    'label_confirm_password': {'vi': 'Xác nhận lại mật khẩu *', 'en': 'Confirm password *'},
    'label_fullname': {'vi': 'Họ và tên', 'en': 'Full name'},
    'label_phone': {'vi': 'Số điện thoại', 'en': 'Phone number'},
    'err_email_empty': {'vi': 'Vui lòng nhập Email', 'en': 'Please enter your email'},
    'err_email_invalid': {'vi': 'Địa chỉ email không đúng định dạng', 'en': 'Invalid email address format'},
    'err_pwd_empty': {'vi': 'Vui lòng nhập mật khẩu', 'en': 'Please enter your password'},
    'err_pwd_min': {'vi': 'Mật khẩu phải có tối thiểu 6 ký tự', 'en': 'Password must be at least 6 characters'},
    'err_confirm_pwd_empty': {'vi': 'Vui lòng xác nhận lại mật khẩu', 'en': 'Please confirm your password'},
    'err_confirm_pwd_mismatch': {'vi': 'Mật khẩu xác nhận không trùng khớp', 'en': 'Passwords do not match'},
    'err_phone_invalid': {'vi': 'Số điện thoại không hợp lệ (10 số, đầu 03, 05, 07, 08, 09)', 'en': 'Invalid phone number (10 digits)'},

    // ----------------------------------------------------
    // THAO TÁC CHUNG
    // ----------------------------------------------------
    'close': {'vi': 'Đóng', 'en': 'Close'},
    'confirm': {'vi': 'Xác nhận', 'en': 'Confirm'},
    'cancel': {'vi': 'Hủy', 'en': 'Cancel'},
    'retry': {'vi': 'Thử lại', 'en': 'Try again'},
    'welcome_back': {'vi': 'Chào mừng', 'en': 'Welcome'},
    'logged_out': {'vi': 'Đã đăng xuất tài khoản.', 'en': 'Logged out successfully.'},
  };

  /// Tra cứu chuỗi theo mã ngôn ngữ và key. Nếu không có mã thì fallback sang Tiếng Việt ('vi').
  static String get(String langCode, String key) {
    final entry = _strings[key];
    if (entry == null) return key;
    return entry[langCode] ?? entry['vi'] ?? key;
  }
}
