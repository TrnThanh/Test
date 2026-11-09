import 'package:flutter/material.dart';

/// Chunky Bento Playful Colors & Design Tokens (Chuẩn GenZ 2025/2026)
/// Phối màu Pastel Blocks xen kẽ Neon Pop (Spotify Wrapped x TikTok Foodie)
class GZColors {
  // Nền kem bơ ấm mịn & Thẻ trắng bồng bềnh
  static const Color bg = Color(0xFFFFF8EE); // Warm Butter Cream
  static const Color surface = Color(0xFFFFFFFF); // Pure Card White
  static const Color surfaceWarm = Color(0xFFFFF1DC); // Warm Cream Accent
  static const Color line = Color(0xFFF0E5D3); // Viền pastel mờ vi tế siêu mỏng

  // Chữ & Mực Tím Than thời thượng (Không dùng đen gắt)
  static const Color ink = Color(0xFF1E1B2E); // Deep Midnight Purple
  static const Color inkBody = Color(0xFF3F3B52); // Muted Purple Slate
  static const Color inkSoft = Color(0xFF736F85); // Slate 500
  static const Color inkLight = Color(0xFFA5A1B8); // Slate 400

  // Bảng Khối Bento Pastel (Vui tươi, ngọt ngào, tinh nghịch)
  static const Color butter = Color(0xFFFFE885); // Vàng bơ thơm lừng
  static const Color butterLight = Color(0xFFFFF7CE);
  static const Color mint = Color(0xFFB4F3CB); // Xanh bạc hà tươi mát
  static const Color mintLight = Color(0xFFDCFCE7);
  static const Color peach = Color(0xFFFFD2BA); // Cam đào sữa
  static const Color peachLight = Color(0xFFFFE7DA);
  static const Color lavender = Color(0xFFDDD2FE); // Tím lavender mộng mơ
  static const Color lavenderLight = Color(0xFFF3E8FF);
  static const Color sky = Color(0xFFBAE6FD); // Xanh da trời mát rượi
  static const Color skyLight = Color(0xFFE0F2FE);

  // Neon Pops (Điểm nhấn CTA nảy lửa, độc bản)
  static const Color pop = Color(0xFFFF4D8D); // Neon Strawberry Pop (Nút CTA, Trái tim, Sponsor)
  static const Color lime = Color(0xFFC6FF3D); // Neon Cyber Lime (Điểm nhấn nhỏ, Icon active)
  static const Color basil = Color(0xFF16A34A); // Emerald Basil (Đang mở cửa)
  static const Color orange = Color(0xFFFF7A00); // Vivid Orange

  // Aliases tương thích ngược với code cũ
  static const Color background = bg;
  static const Color dark = ink;
  static const Color cyanAccent = sky;
  static const Color tealAccent = mint;
  static const Color violetPrimary = pop;
  static const Color coralAccent = pop;
  static const Color pinkAccent = pop;
  static const Color orangePrimary = pop;
  static const Color amberWarm = butter;
  static const Color basilGreen = basil;
  static const Color surfaceMuted = surfaceWarm;

  // Gradients nhẹ nhàng (Chỉ dùng tạo chiều sâu rất dịu)
  static const LinearGradient popGradient = LinearGradient(
    colors: [Color(0xFFFF5E99), Color(0xFFFF3377)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient foodGradient = popGradient;
  static const LinearGradient violetGradient = popGradient;
  static const LinearGradient sunsetGradient = LinearGradient(
    colors: [Color(0xFFFF8A65), Color(0xFFFF4D8D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Chunky Soft Shadow (Đổ bóng êm ái bồng bềnh)
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: const Color(0xFF1E1B2E).withValues(alpha: 0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: const Color(0xFFFF4D8D).withValues(alpha: 0.03),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ];

  static List<BoxShadow> get floatShadow => [
        BoxShadow(
          color: const Color(0xFF1E1B2E).withValues(alpha: 0.07),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: const Color(0xFFFF4D8D).withValues(alpha: 0.08),
          blurRadius: 36,
          offset: const Offset(0, 16),
        ),
      ];

  static List<BoxShadow> glow(Color color, {double alpha = 0.25, double blur = 14}) => [
        BoxShadow(
          color: color.withValues(alpha: alpha),
          blurRadius: blur,
          offset: const Offset(0, 4),
        ),
      ];
}

typedef AuroraColors = GZColors;

/// Theme Flutter chuẩn Chunky Bento Playful
class AuroraTheme {
  static ThemeData get theme {
    const cs = ColorScheme(
      brightness: Brightness.light,
      primary: GZColors.pop,
      onPrimary: Colors.white,
      primaryContainer: GZColors.peachLight,
      onPrimaryContainer: GZColors.ink,
      secondary: GZColors.butter,
      onSecondary: GZColors.ink,
      tertiary: GZColors.mint,
      onTertiary: GZColors.ink,
      error: Color(0xFFEF4444),
      onError: Colors.white,
      surface: GZColors.surface,
      onSurface: GZColors.ink,
      surfaceContainerHighest: GZColors.surfaceWarm,
      outline: GZColors.line,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: GZColors.bg,
      fontFamily: 'BeVietnamPro',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Nunito',
          color: GZColors.ink,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
        ),
        iconTheme: IconThemeData(color: GZColors.ink),
      ),
      cardTheme: CardThemeData(
        color: GZColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28), // Bo cong cực đại 28px mập mạp
          side: const BorderSide(color: GZColors.line, width: 1.0),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        hintStyle: const TextStyle(color: GZColors.inkLight, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: GZColors.line, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: GZColors.line, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: GZColors.pop, width: 2.0),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        elevation: 20,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32), // Dialog bo tròn 32px
          side: const BorderSide(color: GZColors.line, width: 1.0),
        ),
      ),
    );
  }
}
