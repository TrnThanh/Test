import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Bộ họa hình Vector phong cách Anime / Foodie theo đúng bản thiết kế
class NoodleBowlArt extends StatelessWidget {
  final double size;
  const NoodleBowlArt({super.key, this.size = 200});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _NoodleBowlPainter(),
      ),
    );
  }
}

class _NoodleBowlPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Bóng đổ đáy bát
    final shadowPaint = Paint()
      ..color = const Color(0x200E6A69)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.88),
        width: w * 0.75,
        height: h * 0.18,
      ),
      shadowPaint,
    );

    // Thân bát sứ ngoài (màu nâu sẫm ấm)
    final bowlPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF3E2723), Color(0xFF5D4037), Color(0xFF2E1C14)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final bowlPath = Path()
      ..moveTo(w * 0.16, h * 0.46)
      ..quadraticBezierTo(w * 0.18, h * 0.82, w * 0.38, h * 0.85)
      ..lineTo(w * 0.62, h * 0.85)
      ..quadraticBezierTo(w * 0.82, h * 0.82, w * 0.84, h * 0.46)
      ..close();
    canvas.drawPath(bowlPath, bowlPaint);

    // Vành miệng bát
    final rimPaint = Paint()
      ..color = const Color(0xFF8D6E63)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.035;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.5, h * 0.46), width: w * 0.72, height: h * 0.26),
      rimPaint,
    );

    // Nước dùng thanh ngọt (vàng cam ấm)
    final brothPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFFFB74D), Color(0xFFE65100)],
        radius: 0.8,
      ).createShader(Rect.fromLTWH(w * 0.18, h * 0.36, w * 0.64, h * 0.22));
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.5, h * 0.47), width: w * 0.66, height: h * 0.22),
      brothPaint,
    );

    // Sợi mì / bún vàng sóng sánh
    final noodlePaint = Paint()
      ..color = const Color(0xFFFFF9C4)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = w * 0.03;

    final noodlePath = Path()
      ..moveTo(w * 0.30, h * 0.50)
      ..cubicTo(w * 0.35, h * 0.42, w * 0.45, h * 0.55, w * 0.52, h * 0.45)
      ..cubicTo(w * 0.58, h * 0.38, w * 0.65, h * 0.52, w * 0.70, h * 0.48);
    canvas.drawPath(noodlePath, noodlePaint);

    final noodlePath2 = Path()
      ..moveTo(w * 0.25, h * 0.46)
      ..cubicTo(w * 0.35, h * 0.54, w * 0.42, h * 0.44, w * 0.50, h * 0.52);
    canvas.drawPath(noodlePath2, noodlePaint);

    // Tôm sú đỏ hồng
    final shrimpPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFF7043), Color(0xFFD84315)],
      ).createShader(Rect.fromLTWH(w * 0.55, h * 0.40, w * 0.2, h * 0.16))
      ..style = PaintingStyle.fill;
    final shrimpPath = Path()
      ..moveTo(w * 0.56, h * 0.44)
      ..quadraticBezierTo(w * 0.68, h * 0.36, w * 0.72, h * 0.46)
      ..quadraticBezierTo(w * 0.66, h * 0.52, w * 0.58, h * 0.48)
      ..close();
    canvas.drawPath(shrimpPath, shrimpPaint);

    // Lá húng quế / hành lá xanh tươi
    final leafPaint = Paint()..color = const Color(0xFF43A047);
    final leafPath = Path()
      ..moveTo(w * 0.42, h * 0.42)
      ..quadraticBezierTo(w * 0.48, h * 0.34, w * 0.50, h * 0.40)
      ..quadraticBezierTo(w * 0.46, h * 0.46, w * 0.42, h * 0.42);
    canvas.drawPath(leafPath, leafPaint);

    // Lát chanh xanh tươi
    final limePaint = Paint()..color = const Color(0xFF81C784);
    canvas.drawCircle(Offset(w * 0.32, h * 0.42), w * 0.05, limePaint);
    final limeInner = Paint()..color = const Color(0xFFE8F5E9);
    canvas.drawCircle(Offset(w * 0.32, h * 0.42), w * 0.035, limeInner);

    // Làn khói nghi ngút thơm lừng (Anime steam)
    final steamPaint = Paint()
      ..color = const Color(0x66FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = w * 0.025;

    final steam1 = Path()
      ..moveTo(w * 0.40, h * 0.32)
      ..quadraticBezierTo(w * 0.36, h * 0.24, w * 0.42, h * 0.16)
      ..quadraticBezierTo(w * 0.46, h * 0.10, w * 0.40, h * 0.04);
    canvas.drawPath(steam1, steamPaint);

    final steam2 = Path()
      ..moveTo(w * 0.55, h * 0.30)
      ..quadraticBezierTo(w * 0.60, h * 0.22, w * 0.54, h * 0.14)
      ..quadraticBezierTo(w * 0.50, h * 0.08, w * 0.56, h * 0.02);
    canvas.drawPath(steam2, steamPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Anime Chef Girl (Đầu bếp vui vẻ cho Weather Card)
class AnimeChefArt extends StatelessWidget {
  final double width;
  final double height;
  const AnimeChefArt({super.key, this.width = 110, this.height = 110});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Image.asset(
        'assets/images/anime_chef.png',
        width: width,
        height: height,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => CustomPaint(
          painter: _AnimeChefPainter(),
        ),
      ),
    );
  }
}

class _AnimeChefPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Nón đầu bếp cao trắng tinh
    final hatPaint = Paint()..color = Colors.white;
    final hatPath = Path()
      ..moveTo(w * 0.35, h * 0.36)
      ..cubicTo(w * 0.20, h * 0.26, w * 0.25, h * 0.05, w * 0.48, h * 0.08)
      ..cubicTo(w * 0.65, h * 0.02, w * 0.80, h * 0.20, w * 0.65, h * 0.36)
      ..close();
    canvas.drawPath(hatPath, hatPaint);

    final hatBand = Paint()..color = const Color(0xFFF1F5F9);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.32, h * 0.33, w * 0.36, h * 0.08),
        const Radius.circular(4),
      ),
      hatBand,
    );

    // Tóc nâu sẫm anime
    final hairPaint = Paint()..color = const Color(0xFF4A3525);
    canvas.drawCircle(Offset(w * 0.5, h * 0.45), w * 0.24, hairPaint);

    // Khuôn mặt trái xoan trắng hồng
    final skinPaint = Paint()..color = const Color(0xFFFFE0BD);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.5, h * 0.48), width: w * 0.36, height: h * 0.34),
      skinPaint,
    );

    // Tóc mái anime đáng yêu
    final bangsPath = Path()
      ..moveTo(w * 0.33, h * 0.40)
      ..quadraticBezierTo(w * 0.42, h * 0.48, w * 0.50, h * 0.42)
      ..quadraticBezierTo(w * 0.58, h * 0.48, w * 0.67, h * 0.39)
      ..close();
    canvas.drawPath(bangsPath, hairPaint);

    // Đôi mắt to tròn long lanh (Anime Eyes)
    final eyePaint = Paint()..color = const Color(0xFF2D1E12);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.42, h * 0.49), width: w * 0.06, height: h * 0.08), eyePaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.58, h * 0.49), width: w * 0.06, height: h * 0.08), eyePaint);
    final eyeSparkle = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(w * 0.41, h * 0.48), w * 0.02, eyeSparkle);
    canvas.drawCircle(Offset(w * 0.57, h * 0.48), w * 0.02, eyeSparkle);

    // Má hồng baby blush
    final blushPaint = Paint()..color = const Color(0x55FF6B8B);
    canvas.drawCircle(Offset(w * 0.37, h * 0.54), w * 0.04, blushPaint);
    canvas.drawCircle(Offset(w * 0.63, h * 0.54), w * 0.04, blushPaint);

    // Nụ cười tươi
    final smilePaint = Paint()
      ..color = const Color(0xFFD81B60)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final smilePath = Path()
      ..moveTo(w * 0.46, h * 0.55)
      ..quadraticBezierTo(w * 0.50, h * 0.59, w * 0.54, h * 0.55);
    canvas.drawPath(smilePath, smilePaint);

    // Khăn quàng cổ đầu bếp đỏ cam
    final scarfPaint = Paint()..color = const Color(0xFFFF5252);
    final scarfPath = Path()
      ..moveTo(w * 0.42, h * 0.64)
      ..lineTo(w * 0.58, h * 0.64)
      ..lineTo(w * 0.50, h * 0.72)
      ..close();
    canvas.drawPath(scarfPath, scarfPaint);

    // Áo đầu bếp trắng
    final coatPaint = Paint()..color = Colors.white;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.30, h * 0.66, w * 0.40, h * 0.34),
        const Radius.circular(8),
      ),
      coatPaint,
    );

    // Đĩa món ăn nóng hổi cầm trên tay
    final platePaint = Paint()..color = const Color(0xFF795548);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.74, h * 0.72), width: w * 0.42, height: h * 0.20),
      platePaint,
    );
    final foodPaint = Paint()..color = const Color(0xFFFF9800);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.74, h * 0.70), width: w * 0.32, height: h * 0.14),
      foodPaint,
    );
    final herbPaint = Paint()..color = const Color(0xFF4CAF50);
    canvas.drawCircle(Offset(w * 0.74, h * 0.68), w * 0.035, herbPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Anime Healthy Foodie Girl (cho Màn Khảo Sát Thể Chất / Dinh Dưỡng Screen 4)
class AnimeHealthyGirlArt extends StatelessWidget {
  final double size;
  const AnimeHealthyGirlArt({super.key, this.size = 140});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _AnimeHealthyGirlPainter(),
      ),
    );
  }
}

class _AnimeHealthyGirlPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Vòng hào quang xanh tươi mát phía sau
    final auraPaint = Paint()
      ..color = const Color(0xFFE8F6F4)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.46, auraPaint);

    // Trái tim bay bổng
    final heartPaint = Paint()..color = const Color(0xFFFF6B6B);
    final heartPath = Path()
      ..moveTo(w * 0.22, h * 0.28)
      ..cubicTo(w * 0.18, h * 0.20, w * 0.24, h * 0.16, w * 0.28, h * 0.22)
      ..cubicTo(w * 0.32, h * 0.16, w * 0.38, h * 0.20, w * 0.34, h * 0.28)
      ..lineTo(w * 0.28, h * 0.34)
      ..close();
    canvas.drawPath(heartPath, heartPaint);

    // Tóc nâu hạt dẻ
    final hairPaint = Paint()..color = const Color(0xFF5D4037);
    canvas.drawCircle(Offset(w * 0.5, h * 0.42), w * 0.25, hairPaint);

    // Băng đô xanh mint
    final headband = Paint()
      ..color = const Color(0xFF0E6A69)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.05;
    canvas.drawArc(
      Rect.fromCenter(center: Offset(w * 0.5, h * 0.40), width: w * 0.46, height: h * 0.42),
      math.pi * 1.1,
      math.pi * 0.8,
      false,
      headband,
    );

    // Khuôn mặt
    final skinPaint = Paint()..color = const Color(0xFFFFE0BD);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.5, h * 0.46), width: w * 0.34, height: h * 0.32),
      skinPaint,
    );

    // Tóc mái xéo xinh xắn
    final bangsPath = Path()
      ..moveTo(w * 0.34, h * 0.38)
      ..quadraticBezierTo(w * 0.44, h * 0.46, w * 0.54, h * 0.40)
      ..quadraticBezierTo(w * 0.60, h * 0.45, w * 0.66, h * 0.37)
      ..close();
    canvas.drawPath(bangsPath, hairPaint);

    // Mắt híp cười tít mắt vui vẻ (Smiling anime eyes)
    final eyeSmile = Paint()
      ..color = const Color(0xFF3E2723)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final leftEye = Path()
      ..moveTo(w * 0.40, h * 0.46)
      ..quadraticBezierTo(w * 0.44, h * 0.42, w * 0.47, h * 0.46);
    final rightEye = Path()
      ..moveTo(w * 0.53, h * 0.46)
      ..quadraticBezierTo(w * 0.56, h * 0.42, w * 0.60, h * 0.46);
    canvas.drawPath(leftEye, eyeSmile);
    canvas.drawPath(rightEye, eyeSmile);

    // Má hồng
    final blush = Paint()..color = const Color(0x66FF4081);
    canvas.drawCircle(Offset(w * 0.38, h * 0.50), w * 0.035, blush);
    canvas.drawCircle(Offset(w * 0.62, h * 0.50), w * 0.035, blush);

    // Miệng cười
    final mouth = Path()
      ..moveTo(w * 0.47, h * 0.52)
      ..quadraticBezierTo(w * 0.50, h * 0.55, w * 0.53, h * 0.52);
    canvas.drawPath(mouth, eyeSmile);

    // Áo thun trắng viền xanh
    final shirtPaint = Paint()..color = Colors.white;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.34, h * 0.62, w * 0.32, h * 0.32), const Radius.circular(8)),
      shirtPaint,
    );

    // Bát salad xanh tươi ngon
    final bowlPaint = Paint()..color = const Color(0xFFFFB74D);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.50, h * 0.78), width: w * 0.42, height: h * 0.22), bowlPaint);

    final saladGreens = Paint()..color = const Color(0xFF66BB6A);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.50, h * 0.74), width: w * 0.36, height: h * 0.16), saladGreens);

    final tomato = Paint()..color = const Color(0xFFEF5350);
    canvas.drawCircle(Offset(w * 0.44, h * 0.73), w * 0.03, tomato);
    canvas.drawCircle(Offset(w * 0.54, h * 0.72), w * 0.03, tomato);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Anime Eating Boy (cho Màn Khách Vãng Lai Screen 8)
class AnimeEaterArt extends StatelessWidget {
  final double size;
  const AnimeEaterArt({super.key, this.size = 180});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _AnimeEaterPainter(),
      ),
    );
  }
}

class _AnimeEaterPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Hào quang nền thành phố & vị trí
    final bgGlow = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFE0F2FE), Color(0xFFF0FDF4), Colors.transparent],
        stops: [0.3, 0.7, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.48, bgGlow);

    // Ghim bản đồ đỏ nổi bật phía sau
    final pinPaint = Paint()..color = const Color(0xFFFF5252);
    final pinPath = Path()
      ..moveTo(w * 0.80, h * 0.35)
      ..cubicTo(w * 0.72, h * 0.20, w * 0.88, h * 0.20, w * 0.80, h * 0.35)
      ..lineTo(w * 0.80, h * 0.42)
      ..close();
    canvas.drawPath(pinPath, pinPaint);
    canvas.drawCircle(Offset(w * 0.80, h * 0.28), w * 0.04, Paint()..color = Colors.white);

    // Tóc đen tỉa layer cá tính anime
    final hairPaint = Paint()..color = const Color(0xFF263238);
    canvas.drawCircle(Offset(w * 0.48, h * 0.38), w * 0.24, hairPaint);

    // Khuôn mặt
    final skinPaint = Paint()..color = const Color(0xFFFFE0BD);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.48, h * 0.42), width: w * 0.32, height: h * 0.30), skinPaint);

    // Tóc mái nhọn anime
    final hairSpikes = Path()
      ..moveTo(w * 0.32, h * 0.32)
      ..lineTo(w * 0.38, h * 0.40)
      ..lineTo(w * 0.45, h * 0.34)
      ..lineTo(w * 0.52, h * 0.41)
      ..lineTo(w * 0.60, h * 0.34)
      ..lineTo(w * 0.66, h * 0.40)
      ..close();
    canvas.drawPath(hairSpikes, hairPaint);

    // Đôi mắt hạnh phúc thưởng thức đồ ăn ngon (crescent eyes)
    final eyePaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final lEye = Path()..moveTo(w * 0.40, h * 0.42)..quadraticBezierTo(w * 0.44, h * 0.38, w * 0.47, h * 0.42);
    final rEye = Path()..moveTo(w * 0.51, h * 0.42)..quadraticBezierTo(w * 0.54, h * 0.38, w * 0.58, h * 0.42);
    canvas.drawPath(lEye, eyePaint);
    canvas.drawPath(rEye, eyePaint);

    // Má hồng phấn khích
    final blush = Paint()..color = const Color(0x66FF5252);
    canvas.drawCircle(Offset(w * 0.37, h * 0.46), w * 0.035, blush);
    canvas.drawCircle(Offset(w * 0.61, h * 0.46), w * 0.035, blush);

    // Miệng nhai nhồm nhoàm đáng yêu
    final mouth = Path()..moveTo(w * 0.46, h * 0.48)..quadraticBezierTo(w * 0.49, h * 0.52, w * 0.52, h * 0.48);
    canvas.drawPath(mouth, eyePaint);

    // Áo hoodie xanh dương pastel phong cách
    final hoodiePaint = Paint()..color = const Color(0xFF38BDF8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.28, h * 0.58, w * 0.44, h * 0.38), const Radius.circular(12)),
      hoodiePaint,
    );

    // Bát ăn ngon lành trên tay
    final bowl = Paint()..color = const Color(0xFF475569);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.48, h * 0.74), width: w * 0.36, height: h * 0.18), bowl);
    final food = Paint()..color = const Color(0xFFFBBF24);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.48, h * 0.70), width: w * 0.30, height: h * 0.12), food);

    // Đôi đũa gắp thức ăn
    final stickPaint = Paint()
      ..color = const Color(0xFF854D0E)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.30, h * 0.58), Offset(w * 0.46, h * 0.66), stickPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Icon Thời tiết 3D thích ứng (Mặt trời vàng rực rỡ / Mưa giọt ngọc / Dông bão) theo thời tiết thực tế
class WeatherSunCloudArt extends StatelessWidget {
  final double width;
  final double height;
  final String? condition;
  const WeatherSunCloudArt({
    super.key,
    this.width = 46,
    this.height = 42,
    this.condition,
  });

  @override
  Widget build(BuildContext context) {
    final cond = condition?.toLowerCase() ?? '';
    final isRain = cond.contains('mưa') || cond.contains('rain') || cond.contains('drizzle');
    final isThunder = cond.contains('dông') || cond.contains('sấm') || cond.contains('storm');
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _WeatherSunCloudPainter(isRain: isRain, isThunder: isThunder),
      ),
    );
  }
}

class _WeatherSunCloudPainter extends CustomPainter {
  final bool isRain;
  final bool isThunder;
  _WeatherSunCloudPainter({this.isRain = false, this.isThunder = false});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    if (!isRain) {
      // 1. Mặt trời 3D vàng cam rạng rỡ (nằm góc trên bên trái khi không mưa)
      final sunCenter = Offset(w * 0.42, h * 0.38);
      final sunRadius = w * 0.28;

      // Tia nắng mặt trời nhẹ nhàng
      final rayPaint = Paint()
        ..color = const Color(0xFFFFB300)
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;

      for (int i = 0; i < 8; i++) {
        final angle = (i * 45) * math.pi / 180;
        final p1 = Offset(
          sunCenter.dx + math.cos(angle) * (sunRadius + 2.5),
          sunCenter.dy + math.sin(angle) * (sunRadius + 2.5),
        );
        final p2 = Offset(
          sunCenter.dx + math.cos(angle) * (sunRadius + 6.0),
          sunCenter.dy + math.sin(angle) * (sunRadius + 6.0),
        );
        canvas.drawLine(p1, p2, rayPaint);
      }

      // Gradient hình cầu 3D mặt trời
      final sunShader = RadialGradient(
        center: const Alignment(-0.35, -0.35),
        colors: const [
          Color(0xFFFFF59D),
          Color(0xFFFFCA28),
          Color(0xFFF57C00),
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: sunCenter, radius: sunRadius));

      final sunPaint = Paint()..shader = sunShader;
      canvas.drawCircle(sunCenter, sunRadius, sunPaint);
    } else {
      // Đám mây xám xanh phía sau khi trời mưa
      final backCloudShader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFB0BEC5), Color(0xFF78909C)],
      ).createShader(Rect.fromLTWH(w * 0.15, h * 0.18, w * 0.65, h * 0.45));
      final backCloudPaint = Paint()..shader = backCloudShader;
      final backCloudPath = Path();
      backCloudPath.addOval(Rect.fromCircle(center: Offset(w * 0.38, h * 0.38), radius: w * 0.22));
      backCloudPath.addOval(Rect.fromCircle(center: Offset(w * 0.58, h * 0.32), radius: w * 0.24));
      canvas.drawPath(backCloudPath, backCloudPaint);
    }

    // 2. Đám mây 3D bồng bềnh nằm phía trước
    final cloudShadow = Paint()
      ..color = const Color(0x201E3A8A)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    // Đổ bóng đáy mây
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.12, h * 0.48, w * 0.80, h * 0.40),
        const Radius.circular(16),
      ),
      cloudShadow,
    );

    final cloudColors = isRain
        ? const [Color(0xFFF1F5F9), Color(0xFFCBD5E1), Color(0xFF94A3B8)]
        : const [Color(0xFFFFFFFF), Color(0xFFF0F7FF), Color(0xFFD6E8F7)];

    final cloudShader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: cloudColors,
      stops: const [0.0, 0.6, 1.0],
    ).createShader(Rect.fromLTWH(0, h * 0.28, w, h * 0.65));

    final cloudPaint = Paint()..shader = cloudShader;

    // Các búi mây tròn 3D kết hợp
    final cloudPath = Path();
    cloudPath.addOval(Rect.fromCircle(center: Offset(w * 0.32, h * 0.62), radius: w * 0.20));
    cloudPath.addOval(Rect.fromCircle(center: Offset(w * 0.52, h * 0.50), radius: w * 0.24));
    cloudPath.addOval(Rect.fromCircle(center: Offset(w * 0.74, h * 0.64), radius: w * 0.18));
    cloudPath.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.16, h * 0.54, w * 0.70, h * 0.32),
        const Radius.circular(12),
      ),
    );

    canvas.drawPath(cloudPath, cloudPaint);

    // Điểm nhấn viền sáng trên đỉnh mây (Highlight)
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final highlightPath = Path()
      ..addArc(
        Rect.fromCircle(center: Offset(w * 0.52, h * 0.50), radius: w * 0.23),
        -math.pi * 0.8,
        math.pi * 0.6,
      );
    canvas.drawPath(highlightPath, highlightPaint);

    // 3. Giọt mưa ngọc xanh biếc rơi sinh động khi trời mưa
    if (isRain) {
      final rainPaint = Paint()
        ..color = const Color(0xFF0284C7)
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round;

      // 4 giọt mưa chéo nhẹ
      canvas.drawLine(Offset(w * 0.28, h * 0.82), Offset(w * 0.22, h * 0.98), rainPaint);
      canvas.drawLine(Offset(w * 0.46, h * 0.84), Offset(w * 0.40, h * 1.00), rainPaint);
      canvas.drawLine(Offset(w * 0.64, h * 0.82), Offset(w * 0.58, h * 0.98), rainPaint);
      canvas.drawLine(Offset(w * 0.78, h * 0.84), Offset(w * 0.72, h * 0.96), rainPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WeatherSunCloudPainter oldDelegate) =>
      oldDelegate.isRain != isRain || oldDelegate.isThunder != isThunder;
}

/// Cảnh nền Morning Scenic (Skyline phố xá pastel + vòm cây xanh ngắt) bao quanh Top Header HomeScreen
class HomeHeaderScenicBackground extends StatefulWidget {
  final Widget? child;
  const HomeHeaderScenicBackground({super.key, this.child});

  @override
  State<HomeHeaderScenicBackground> createState() => _HomeHeaderScenicBackgroundState();
}

class _HomeHeaderScenicBackgroundState extends State<HomeHeaderScenicBackground> {
  bool _hasCustomAsset = true;

  @override
  void initState() {
    super.initState();
    _checkCustomAsset();
  }

  Future<void> _checkCustomAsset() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final assets = manifest.listAssets();
      final hasAsset = assets.contains('assets/images/home_header_bg.png') ||
          assets.contains('assets/images/home_header_bg.jpg') ||
          assets.contains('assets/images/header_city_bg.png');
      if (mounted && _hasCustomAsset != hasAsset) {
        setState(() {
          _hasCustomAsset = hasAsset;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_hasCustomAsset)
          Image.asset(
            'assets/images/home_header_bg.png',
            fit: BoxFit.cover,
            alignment: const Alignment(0, -0.4), // Đẩy ảnh lên cao 50px để lấy trọn trời xanh, mây và đỉnh tháp
            errorBuilder: (_, __, ___) => CustomPaint(
              size: Size.infinite,
              painter: _HomeHeaderScenicPainter(),
            ),
          )
        else
          CustomPaint(
            size: Size.infinite,
            painter: _HomeHeaderScenicPainter(),
          ),
        // Lớp phủ trắng 10% làm sáng nhẹ ảnh và dịu nền
        Container(
          color: Colors.white.withOpacity(0.10),
        ),
        // Gradient mờ dần hoàn toàn sang #F8FAFC trước khi tới thanh tìm kiếm (~y=290-300)
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                Colors.transparent,
                Color(0x99F8FAFC),
                Color(0xFFF8FAFC),
                Color(0xFFF8FAFC),
              ],
              stops: [0.0, 0.35, 0.55, 0.68, 1.0],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        if (widget.child != null) widget.child!,
      ],
    );
  }
}

class _HomeHeaderScenicPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Bầu trời xanh trong trẻo chuyển êm dịu xuống nền sáng (không vệt ngang, không đổi tầng)
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFCEEBFC), // Xanh trời sáng trong pastel
          Color(0xFFE5F4FE),
          Color(0xFFF3FAFE),
          Color(0xFFF8FAFC), // Hòa quyện liền mạch 100% vào nền app
        ],
        stops: [0.0, 0.32, 0.65, 1.0],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), skyPaint);

    // 2. Tòa nhà cao tầng phía xa mờ ảo (Distant Skyline pastel nhẹ)
    final distantSkylinePaint = Paint()
      ..color = const Color(0xFFC5E8FC).withOpacity(0.55);

    final distantPath = Path();
    distantPath.moveTo(w * 0.26, h * 0.44);
    distantPath.lineTo(w * 0.26, h * 0.18);
    distantPath.lineTo(w * 0.33, h * 0.18);
    distantPath.lineTo(w * 0.33, h * 0.44);

    distantPath.moveTo(w * 0.36, h * 0.44);
    distantPath.lineTo(w * 0.36, h * 0.14);
    distantPath.lineTo(w * 0.42, h * 0.14);
    distantPath.lineTo(w * 0.42, h * 0.44);

    distantPath.moveTo(w * 0.65, h * 0.44);
    distantPath.lineTo(w * 0.65, h * 0.16);
    distantPath.lineTo(w * 0.72, h * 0.16);
    distantPath.lineTo(w * 0.72, h * 0.44);
    canvas.drawPath(distantPath, distantSkylinePaint);

    // 3. Khối tòa nhà thành phố trung tâm (Kéo dài xuống sau thẻ thời tiết để tạo hiệu ứng blur kính mờ)
    final skylinePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFFA6DCF8).withOpacity(0.70),
          const Color(0xFFC7EBFD).withOpacity(0.40),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, h * 0.05, w, h * 0.42));

    final skylinePath = Path();
    skylinePath.addRect(Rect.fromLTWH(w * 0.31, h * 0.20, w * 0.07, h * 0.24));

    // Tháp nhọn kim trung tâm (Landmark)
    skylinePath.moveTo(w * 0.48, h * 0.44);
    skylinePath.lineTo(w * 0.48, h * 0.15);
    skylinePath.lineTo(w * 0.493, h * 0.12);
    skylinePath.lineTo(w * 0.497, h * 0.05);
    skylinePath.lineTo(w * 0.503, h * 0.05);
    skylinePath.lineTo(w * 0.507, h * 0.12);
    skylinePath.lineTo(w * 0.52, h * 0.15);
    skylinePath.lineTo(w * 0.52, h * 0.44);

    skylinePath.addRect(Rect.fromLTWH(w * 0.54, h * 0.18, w * 0.07, h * 0.26));
    skylinePath.addRect(Rect.fromLTWH(w * 0.62, h * 0.22, w * 0.06, h * 0.22));
    canvas.drawPath(skylinePath, skylinePaint);

    // Kim ăng-ten tháp
    final antennaPaint = Paint()
      ..color = const Color(0xFF7CC5ED).withOpacity(0.7)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.50, h * 0.05), Offset(w * 0.50, h * 0.02), antennaPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
