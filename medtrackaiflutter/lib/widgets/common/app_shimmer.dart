import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// A premium, subtle skeleton loader inspired by Apple and Linear.
/// Instead of a fast, distracting shimmer, this gently pulses opacity
/// to indicate loading state without drawing the eye aggressively.
class AppShimmer extends StatefulWidget {
  final double? width;
  final double? height;
  final double? radius;
  final BoxShape shape;

  const AppShimmer({
    super.key,
    this.width,
    this.height,
    this.radius,
    this.shape = BoxShape.rectangle,
  });

  @override
  State<AppShimmer> createState() => _AppShimmerState();
}

class _AppShimmerState extends State<AppShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _opacityAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacityAnim,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnim.value,
          child: Container(
            width: widget.width ?? double.infinity,
            height: widget.height ?? double.infinity,
            decoration: BoxDecoration(
              color: context.L.fill,
              shape: widget.shape,
              borderRadius: widget.shape == BoxShape.circle
                  ? null
                  : BorderRadius.circular(widget.radius ?? AppRadius.xl),
            ),
          ),
        );
      },
    );
  }
}
