import 'package:flutter/material.dart';

/// Bento Design System (Spotify Wrapped x TikTok Foodie)
/// Bảng màu Pastel Blocks xen kẽ Neon Pop
class BentoColors {
  static const Color bg = Color(0xFFFFF8EE); // Kem bơ ấm
  static const Color card = Colors.white; // Thẻ trắng
  static const Color ink = Color(0xFF1E1B2E); // Tím than sâu sắc nét
  static const Color inkBody = Color(0xFF3F3B52);
  static const Color inkSoft = Color(0xFF736F85); // Slate 500
  static const Color inkLight = Color(0xFFA5A1B8);
  static const Color line = Color(0xFFF0E5D3); // Viền mỏng

  // Pastel Bento Blocks
  static const Color butter = Color(0xFFFFE885); // Vàng bơ
  static const Color mint = Color(0xFFB4F3CB); // Xanh mint
  static const Color peach = Color(0xFFFFD2BA); // Cam đào
  static const Color lavender = Color(0xFFDDD2FE); // Tím lavender
  static const Color sky = Color(0xFFBAE6FD); // Xanh biển nhạt

  // Neon Pops
  static const Color pop = Color(0xFFFF4D8D); // Neon Pink
  static const Color lime = Color(0xFFC6FF3D); // Neon Lime
  static const Color basil = Color(0xFF16A34A); // Emerald Green
}

/// Nút bấm có hiệu ứng nảy đàn hồi (Elastic Micro-bounce)
class BentoBouncy extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressScale;

  const BentoBouncy({
    super.key,
    required this.child,
    this.onTap,
    this.pressScale = 0.94,
  });

  @override
  State<BentoBouncy> createState() => _BentoBouncyState();
}

class _BentoBouncyState extends State<BentoBouncy> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? widget.pressScale : 1.0,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

/// Thẻ Bento bo tròn 28px mập mạp bồng bềnh
class BentoCard extends StatelessWidget {
  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  const BentoCard({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: BentoColors.line, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E1B2E).withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return BentoBouncy(onTap: onTap, child: card);
    }
    return card;
  }
}
