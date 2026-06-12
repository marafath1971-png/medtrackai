import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';

class AppShimmer extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      height: height ?? double.infinity,
      decoration: BoxDecoration(
        color: context.L.fill,
        shape: shape,
        borderRadius: shape == BoxShape.circle 
            ? null 
            : BorderRadius.circular(radius ?? AppRadius.xl),
      ),
    )
    .animate(onPlay: (controller) => controller.repeat())
    .shimmer(
      duration: AppDurations.shimmer,
      color: context.L.text.withValues(alpha: 0.1),
      angle: 1.0,
    );
  }
}
