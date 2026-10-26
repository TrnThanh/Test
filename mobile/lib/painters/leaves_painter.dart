import 'package:flutter/material.dart';

/// Painter vẽ tán lá trang trí góc trên phải màn hình
class TopRightLeavesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p1 = Paint()..color = const Color(0xFF8CE32C).withAlpha(180)..style = PaintingStyle.fill;
    final p2 = Paint()..color = const Color(0xFF4A7C59).withAlpha(190)..style = PaintingStyle.fill;

    final path1 = Path();
    path1.moveTo(size.width, size.height * 0.15);
    path1.quadraticBezierTo(size.width * 0.25, size.height * 0.25, size.width * 0.45, size.height * 0.65);
    path1.quadraticBezierTo(size.width * 0.85, size.height * 0.5, size.width, size.height * 0.15);
    canvas.drawPath(path1, p1);

    final path2 = Path();
    path2.moveTo(size.width, size.height * 0.6);
    path2.quadraticBezierTo(size.width * 0.5, size.height * 0.7, size.width * 0.65, size.height * 0.95);
    path2.quadraticBezierTo(size.width * 0.9, size.height * 0.85, size.width, size.height * 0.6);
    canvas.drawPath(path2, p2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
