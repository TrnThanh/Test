import 'package:flutter/material.dart';
import 'aurora_theme.dart';
import 'fx.dart';

/// Adapter GenZ Chunky Bento Playful
class GenzColors {
  static const Color bg = GZColors.bg;
  static const Color surface = GZColors.surface;
  static const Color dark = GZColors.ink;

  static const Color lime = GZColors.lime;
  static const Color pink = GZColors.pop;
  static const Color cyan = GZColors.sky;
  static const Color purple = GZColors.lavender;
  static const Color orange = GZColors.orange;
  static const Color yellow = GZColors.butter;
  static const Color muted = GZColors.surfaceWarm;

  static const double borderW = 1.0;
  static const double radius = 28.0; // Bo cong tròn trịa mập mạp 28px
  static const Offset shadowOffset = Offset(0, 4);
}

class GenzTheme {
  static ThemeData get theme => AuroraTheme.theme;
}

/// GenzCard: Thẻ Bento bồng bềnh bo tròn 28px
class GenzCard extends StatelessWidget {
  final Widget child;
  final Color color;
  final Color? borderColor;
  final double radius;
  final double borderWidth;
  final Offset shadowOffset;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  const GenzCard({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.borderColor,
    this.radius = 28.0,
    this.borderWidth = 1.0,
    this.shadowOffset = const Offset(0, 4),
    this.padding = const EdgeInsets.all(18.0),
    this.margin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardContent = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: borderColor ?? GZColors.line,
          width: borderWidth,
        ),
        boxShadow: GZColors.cardShadow,
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );

    if (onTap != null) {
      return AnimatedPressable(
        onTap: onTap,
        pressScale: 0.95,
        child: cardContent,
      );
    }
    return cardContent;
  }
}

/// GenzBadge: Nhãn dán Sticker tinh nghịch bo tròn viên thuốc
class GenzBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final IconData? icon;
  final double fontSize;
  final EdgeInsetsGeometry padding;
  final double radius;

  const GenzBadge({
    super.key,
    required this.label,
    this.color = GZColors.surfaceWarm,
    this.textColor = GZColors.ink,
    this.icon,
    this.fontSize = 11,
    this.padding = const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
    this.radius = 999, // Dạng viên thuốc
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: textColor.withValues(alpha: 0.12),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 3, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              color: textColor,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// GenzButton: Nút bấm Chunky Pill mập mạp đàn hồi búng ngón tay
class GenzButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color color;
  final Color textColor;
  final double radius;
  final EdgeInsetsGeometry padding;
  final bool isFullWidth;

  const GenzButton({
    super.key,
    required this.child,
    this.onPressed,
    this.color = GZColors.pop,
    this.textColor = Colors.white,
    this.radius = 999, // Chunky Pill tròn vo
    this.padding = const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget button = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: onPressed == null ? const Color(0xFFE5DDD5) : color,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: onPressed == null
            ? null
            : [
                BoxShadow(
                  color: color.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      alignment: isFullWidth ? Alignment.center : null,
      child: child,
    );

    if (onPressed != null) {
      button = AnimatedPressable(
        onTap: onPressed,
        pressScale: 0.94, // Nhún sâu hơn tạo cảm giác búng ngón tay
        child: button,
      );
    }

    if (isFullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}
