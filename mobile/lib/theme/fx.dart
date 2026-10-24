import 'package:flutter/material.dart';
import 'aurora_theme.dart';

/// AnimatedPressable: Hiệu ứng Spring đàn hồi siêu mượt khi chạm.
/// Bọc quanh bất kỳ Card, Button hay Component tương tác nào.
class AnimatedPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressScale;
  final Duration duration;

  const AnimatedPressable({
    super.key,
    required this.child,
    this.onTap,
    this.pressScale = 0.96,
    this.duration = const Duration(milliseconds: 140),
  });

  @override
  State<AnimatedPressable> createState() => _AnimatedPressableState();
}

class _AnimatedPressableState extends State<AnimatedPressable> {
  bool _isDown = false;

  void _handleTapDown(TapDownDetails _) {
    if (widget.onTap != null) setState(() => _isDown = true);
  }

  void _handleTapUp(TapUpDetails _) {
    if (_isDown) setState(() => _isDown = false);
  }

  void _handleTapCancel() {
    if (_isDown) setState(() => _isDown = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isDown ? widget.pressScale : 1.0,
        duration: widget.duration,
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

/// BouncyHeartButton: Nút thả tim nảy nở đa nhịp rung rinh (Scale 1.0 -> 1.35 -> 0.9 -> 1.0)
/// Đảm bảo animation bounded kết thúc sau 320ms, an toàn 100% với pumpAndSettle.
class BouncyHeartButton extends StatefulWidget {
  final bool isLiked;
  final VoidCallback onToggle;
  final String tooltip;

  const BouncyHeartButton({
    super.key,
    required this.isLiked,
    required this.onToggle,
    this.tooltip = 'Thích món này',
  });

  @override
  State<BouncyHeartButton> createState() => _BouncyHeartButtonState();
}

class _BouncyHeartButtonState extends State<BouncyHeartButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.35)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.35, end: 0.9)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.9, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 25,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handlePress() {
    _controller.forward(from: 0.0);
    widget.onToggle();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: widget.tooltip,
      onPressed: _handlePress,
      icon: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.isLiked
                ? const Color(0xFFFFE8EE)
                : AuroraColors.surfaceMuted,
            boxShadow: widget.isLiked
                ? AuroraColors.glow(AuroraColors.coralAccent, alpha: 0.25, blur: 10)
                : null,
          ),
          child: Icon(
            widget.isLiked ? Icons.favorite : Icons.favorite_border,
            color: widget.isLiked
                ? AuroraColors.coralAccent
                : AuroraColors.inkSoft,
            size: 20,
          ),
        ),
      ),
    );
  }
}

/// StaggeredCard: Danh sách xuất hiện trượt nhẹ và Fade-in mượt mà tuần tự.
/// Chỉ delay cho các item đầu để tối ưu trải nghiệm.
class StaggeredCard extends StatefulWidget {
  final int index;
  final Widget child;

  const StaggeredCard({
    super.key,
    required this.index,
    required this.child,
  });

  @override
  State<StaggeredCard> createState() => _StaggeredCardState();
}

class _StaggeredCardState extends State<StaggeredCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    final delayIndex = widget.index.clamp(0, 8);
    final totalDuration = 280 + (delayIndex * 40);

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: totalDuration),
    );

    final startInterval = (delayIndex * 0.08).clamp(0.0, 0.6);
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Interval(startInterval, 1.0, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(curved);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(curved);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}
