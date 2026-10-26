/// Tiện ích kiểm tra quán có đang trong khung giờ mở cửa thực tế không
bool isOpenNow(String? openTime, String? closeTime) {
  if (openTime == null || closeTime == null || openTime.isEmpty || closeTime.isEmpty) {
    return true; // Mặc định mở nếu quán chưa thiết lập giờ
  }
  try {
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;
    final openParts = openTime.split(':');
    final closeParts = closeTime.split(':');
    final openMin = int.parse(openParts[0]) * 60 + int.parse(openParts[1]);
    final closeMin = int.parse(closeParts[0]) * 60 + int.parse(closeParts[1]);

    if (closeMin >= openMin) {
      return currentMinutes >= openMin && currentMinutes <= closeMin;
    } else {
      // Khung giờ qua đêm (ví dụ: 18:00 - 04:30)
      return currentMinutes >= openMin || currentMinutes <= closeMin;
    }
  } catch (_) {
    return true;
  }
}

/// Chuẩn hoá thông báo lỗi thân thiện với người dùng
String formatErrorMessage(Object error) {
  final str = error.toString().replaceAll('Exception: ', '');
  final lower = str.toLowerCase();
  if (lower.contains('failed to fetch') ||
      lower.contains('connection refused') ||
      lower.contains('socketexception') ||
      lower.contains('clientexception')) {
    return 'Chưa kết nối được tới máy chủ Backend (Cổng 8001/8000).\nVui lòng kiểm tra và chạy file "CHAY_SERVER.bat" để khởi động Backend!';
  }
  return str;
}
