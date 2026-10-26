import 'package:flutter/material.dart';

/// Painter vẽ các tia phẩy năng động (Playful Lime Sparks)
class SparkPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  const SparkPainter({this.color = const Color(0xFF8CE32C), this.strokeWidth = 2.4});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final cx = size.width * 0.5;
    final cy = size.height;

    // Tia trái
    canvas.drawLine(
      Offset(cx - size.width * 0.35, cy - size.height * 0.25),
      Offset(cx - size.width * 0.5, cy - size.height * 0.9),
      paint,
    );
    // Tia giữa
    canvas.drawLine(
      Offset(cx, cy - size.height * 0.3),
      Offset(cx, cy - size.height * 1.0),
      paint,
    );
    // Tia phải
    canvas.drawLine(
      Offset(cx + size.width * 0.35, cy - size.height * 0.25),
      Offset(cx + size.width * 0.5, cy - size.height * 0.9),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant SparkPainter oldDelegate) => false;
}

class SparkBurst extends StatelessWidget {
  final double width;
  final double height;
  final Color color;
  final double strokeWidth;

  const SparkBurst({
    super.key,
    this.width = 18,
    this.height = 14,
    this.color = const Color(0xFF8CE32C),
    this.strokeWidth = 2.4,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: SparkPainter(color: color, strokeWidth: strokeWidth),
    );
  }
}
