import 'package:flutter/material.dart';

class WeatherVisualConfig {
  final IconData? icon;
  final Widget? customWidget;
  final Color iconColor;
  final List<Color> iconBgColors;
  final Color iconBorderColor;
  final Color iconShadowColor;
  final bool isNight;

  const WeatherVisualConfig({
    this.icon,
    this.customWidget,
    required this.iconColor,
    required this.iconBgColors,
    required this.iconBorderColor,
    required this.iconShadowColor,
    required this.isNight,
  });
}

/// Painter vẽ các ngọn đồi và tán lá minh hoạ trên thẻ Thời tiết (thay đổi linh hoạt ngày và đêm)
class WeatherLandscapePainter extends CustomPainter {
  final bool isNight;

  const WeatherLandscapePainter({this.isNight = false});

  @override
  void paint(Canvas canvas, Size size) {
    if (isNight) {
      // Ban đêm: Không vẽ mặt trăng ở góc phải theo yêu cầu của người dùng,
      // chỉ vẽ các ngọn đồi và tán lá đêm nhẹ nhàng, tinh tế
      final hillPaint1 = Paint()
        ..color = const Color(0xFFE8EEF5)
        ..style = PaintingStyle.fill;
      final hillPaint2 = Paint()
        ..color = const Color(0xFFD6E2F0)
        ..style = PaintingStyle.fill;
      final leafPaint = Paint()
        ..color = const Color(0xFF3B566E).withAlpha(200)
        ..style = PaintingStyle.fill;

      final path1 = Path();
      path1.moveTo(0, size.height);
      path1.quadraticBezierTo(size.width * 0.35, size.height * 0.25, size.width, size.height * 0.45);
      path1.lineTo(size.width, size.height);
      path1.close();
      canvas.drawPath(path1, hillPaint1);

      final path2 = Path();
      path2.moveTo(size.width * 0.15, size.height);
      path2.quadraticBezierTo(size.width * 0.55, size.height * 0.5, size.width, size.height * 0.65);
      path2.lineTo(size.width, size.height);
      path2.close();
      canvas.drawPath(path2, hillPaint2);

      final leafPath = Path();
      leafPath.moveTo(size.width, size.height);
      leafPath.quadraticBezierTo(size.width * 0.5, size.height * 0.75, size.width * 0.75, size.height * 0.55);
      leafPath.quadraticBezierTo(size.width * 0.9, size.height * 0.8, size.width, size.height);
      canvas.drawPath(leafPath, leafPaint);
    } else {
      // Vòng hào quang nắng nhẹ mờ ở góc trên phải ban ngày
      final sunGlow = Paint()
        ..color = const Color(0xFFFFE8A3).withAlpha(130)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(size.width * 0.82, size.height * 0.22), 24, sunGlow);

      final hillPaint1 = Paint()
        ..color = const Color(0xFFEAF5EC)
        ..style = PaintingStyle.fill;
      final hillPaint2 = Paint()
        ..color = const Color(0xFFD7ECDC)
        ..style = PaintingStyle.fill;
      final leafPaint = Paint()
        ..color = const Color(0xFF4A7C59).withAlpha(220)
        ..style = PaintingStyle.fill;

      final path1 = Path();
      path1.moveTo(0, size.height);
      path1.quadraticBezierTo(size.width * 0.35, size.height * 0.25, size.width, size.height * 0.45);
      path1.lineTo(size.width, size.height);
      path1.close();
      canvas.drawPath(path1, hillPaint1);

      final path2 = Path();
      path2.moveTo(size.width * 0.15, size.height);
      path2.quadraticBezierTo(size.width * 0.55, size.height * 0.5, size.width, size.height * 0.65);
      path2.lineTo(size.width, size.height);
      path2.close();
      canvas.drawPath(path2, hillPaint2);

      final leafPath = Path();
      leafPath.moveTo(size.width, size.height);
      leafPath.quadraticBezierTo(size.width * 0.5, size.height * 0.75, size.width * 0.75, size.height * 0.55);
      leafPath.quadraticBezierTo(size.width * 0.9, size.height * 0.8, size.width, size.height);
      canvas.drawPath(leafPath, leafPaint);
    }
  }

  @override
  bool shouldRepaint(covariant WeatherLandscapePainter oldDelegate) => oldDelegate.isNight != isNight;
}
