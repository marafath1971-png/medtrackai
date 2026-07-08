import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../theme/med_ai_ui.dart';

class PremiumEmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final String emoji;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? icon;
  final Widget? visual;
  final String? illustrationAsset;

  const PremiumEmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    this.emoji = '📝',
    this.actionLabel,
    this.onAction,
    this.icon,
    this.visual,
    this.illustrationAsset,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final reduceMotion = MedAiA11y.reducedMotion(context);

    Widget iconArea = MedAiDepthCard(
      padding: EdgeInsets.zero,
      radius: AppRadius.max,
      color: L.card,
      child: SizedBox(
        width: 110,
        height: 110,
        child: Center(
          child: visual ??
              (illustrationAsset != null
                  ? SvgPicture.asset(
                      illustrationAsset!,
                      width: 96,
                      height: 96,
                      fit: BoxFit.contain,
                    )
                  : (icon != null
                      ? Icon(icon, size: 44, color: L.accent)
                      : Text(emoji,
                          style: AppTypography.displayLarge.copyWith(fontSize: 44)))),
        ),
      ),
    );

    Widget titleWidget = Text(
      title,
      textAlign: TextAlign.center,
      style: AppTypography.headlineLarge.copyWith(
        color: L.text,
        fontSize: 22,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
      ),
    );

    Widget subtitleWidget = Text(
      subtitle,
      textAlign: TextAlign.center,
      style: AppTypography.bodyMedium.copyWith(
        color: L.sub,
        fontSize: 15,
        fontWeight: FontWeight.w500,
        height: 1.6,
        letterSpacing: -0.2,
      ),
    );

    if (!reduceMotion) {
      iconArea = iconArea
          .animate()
          .fadeIn(duration: AppDurations.medium, curve: AppCurves.smooth)
          .scale(begin: const Offset(0.92, 0.92), curve: AppCurves.smooth);
      titleWidget = titleWidget
          .animate()
          .fadeIn(duration: AppDurations.medium, curve: AppCurves.smooth)
          .slideY(begin: 0.08, end: 0, curve: AppCurves.smooth);
      subtitleWidget = subtitleWidget
          .animate(delay: 100.ms)
          .fadeIn(duration: AppDurations.medium, curve: AppCurves.smooth)
          .slideY(begin: 0.1, end: 0, curve: AppCurves.smooth);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          iconArea,
          const SizedBox(height: 32),
          titleWidget,
          const SizedBox(height: 12),
          subtitleWidget,
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 40),
            _entrance(
              reduceMotion,
              MedAiCTA(
                label: actionLabel!,
                fullWidth: false,
                onTap: onAction,
                semanticsLabel: actionLabel,
              ),
              delay: 200.ms,
            ),
          ],
        ],
      ),
    );
  }

  static Widget _entrance(bool reduceMotion, Widget child, {Duration? delay}) {
    if (reduceMotion) return child;
    return child
        .animate(delay: delay)
        .fadeIn(duration: AppDurations.fast, curve: AppCurves.smooth)
        .scale(begin: const Offset(0.92, 0.92), curve: AppCurves.smooth);
  }
}
