import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PremiumShimmer extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const PremiumShimmer({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<PremiumShimmer> createState() => _PremiumShimmerState();
}

class _PremiumShimmerState extends State<PremiumShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                L.border.withValues(alpha: 0.3),
                L.border.withValues(alpha: 0.8),
                L.border.withValues(alpha: 0.3),
              ],
              stops: const [0.1, 0.3, 0.4],
              begin: const Alignment(-1.0, -0.3),
              end: const Alignment(1.0, 0.3),
              transform: _SlidingGradientTransform(slidePercent: _controller.value),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform({required this.slidePercent});

  final double slidePercent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0.0, 0.0);
  }
}

class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumShimmer(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white, // Color doesn't matter much as ShaderMask colors over it
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class ContextualLoader extends StatelessWidget {
  final String message;
  final Color? color;
  final bool isDark;
  
  const ContextualLoader({
    super.key,
    this.message = 'Analyzing your data...',
    this.color,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final primaryColor = color ?? L.accent;
    final textColor = isDark ? Colors.white : L.text;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primaryColor.withValues(alpha: 0.1),
              boxShadow: AppShadows.glow(primaryColor, intensity: 0.3),
            ),
            child: Icon(Icons.auto_awesome_rounded, color: primaryColor, size: 28)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(begin: 0.9, end: 1.1, duration: 800.ms, curve: Curves.easeInOut),
          ).animate(onPlay: (c) => c.repeat())
           .shimmer(duration: 2000.ms, color: primaryColor.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            message,
            style: AppTypography.labelLarge.copyWith(
              color: textColor.withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
           .fade(begin: 0.6, end: 1.0, duration: 1000.ms),
        ],
      ),
    );
  }
}
