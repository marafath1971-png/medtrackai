import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../theme/med_ai_ui.dart';

/// Framed HD illustration for empty states, settings heroes, and info cards.
class PremiumIllustrationBanner extends StatelessWidget {
  final String asset;
  final double height;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;

  const PremiumIllustrationBanner({
    super.key,
    required this.asset,
    this.height = 120,
    this.margin = EdgeInsets.zero,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Container(
      width: double.infinity,
      height: height,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: L.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: L.border.withValues(alpha: 0.35)),
      ),
      child: SvgPicture.asset(
        asset,
        fit: BoxFit.contain,
      ),
    );
  }
}
