import 'package:flutter/material.dart';

/// Widget vẽ vầng trăng khuyết màu vàng óng ánh (Golden Crescent Moon) chuẩn xác và tuyệt đẹp
class GoldenMoonWidget extends StatelessWidget {
  final double size;

  const GoldenMoonWidget({super.key, this.size = 26});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: GoldenMoonPainter(),
      ),
    );
  }
}

class GoldenMoonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Vầng trăng khuyết màu vàng óng ánh béo tròn, đầy đặn với gradient vàng cam ấm áp
    final moonPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFEA7A), // Vàng chanh sáng rực rỡ
          Color(0xFFFFB800), // Vàng óng đậm đà
          Color(0xFFF57C00), // Cam ánh vàng đậm ở mép
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    final center = Offset(w * 0.48, h * 0.50);
    final radius = w * 0.43;

    // Vòng tròn ngoài tròn trịa, đầy đặn
    final outerPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));

    // Vòng tròn trong khoét vừa phải để thân trăng béo tròn, phúc hậu, đầy đặn
    final innerCenter = Offset(center.dx + radius * 0.62, center.dy - radius * 0.28);
    final innerRadius = radius * 0.85;

    final innerPath = Path()
      ..addOval(Rect.fromCircle(center: innerCenter, radius: innerRadius));

    final moonPath = Path.combine(PathOperation.difference, outerPath, innerPath);

    // Hào quang vàng ấm áp tỏa sáng quanh vầng trăng
    final glowPaint = Paint()
      ..color = const Color(0xFFFFB800).withAlpha(95)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
    canvas.drawPath(moonPath, glowPaint);

    // Vẽ thân trăng vàng đầy đặn
    canvas.drawPath(moonPath, moonPaint);

    // Ngôi sao nhỏ 4 cánh lấp lánh bên cạnh vầng trăng
    final starPaint = Paint()
      ..color = const Color(0xFFFFF9C4)
      ..style = PaintingStyle.fill;

    _drawStar(canvas, Offset(w * 0.80, h * 0.36), 2.2, starPaint);
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    path.moveTo(center.dx, center.dy - radius);
    path.quadraticBezierTo(center.dx, center.dy, center.dx + radius, center.dy);
    path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + radius);
    path.quadraticBezierTo(center.dx, center.dy, center.dx - radius, center.dy);
    path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - radius);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant GoldenMoonPainter oldDelegate) => false;
}
