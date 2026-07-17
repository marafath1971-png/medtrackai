import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../theme/med_ai_ui.dart';
import 'ghost_mascot.dart';

/// Shared empty state — icon/mascot + one-line message + optional CTA.
///
/// Prefer [mascotFeature], [visual], [illustrationAsset], or [icon].
/// Do not use emoji as the primary visual.
class PremiumEmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final String emoji;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? icon;
  final Widget? visual;
  final String? illustrationAsset;

  /// Resolve a ghost mascot by feature key (see [GhostMascot.feature]).
  final String? mascotFeature;

  /// Tighter padding / smaller artwork for in-card empties.
  final bool compact;

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
    this.mascotFeature,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final reduceMotion = MedAiA11y.reducedMotion(context);
    final artSize = compact ? 72.0 : 110.0;
    final mascotSize = compact ? 64.0 : 96.0;
    final hPad = compact ? AppSpacing.p16 : 32.0;
    final vPad = compact ? AppSpacing.p24 : 48.0;

    Widget resolvedVisual = visual ??
        (mascotFeature != null
            ? GhostMascot.feature(
                mascotFeature!,
                size: mascotSize,
                idle: !reduceMotion && !compact,
                showGlow: !compact,
              )
            : (illustrationAsset != null
                ? SvgPicture.asset(
                    illustrationAsset!,
                    width: mascotSize,
                    height: mascotSize,
                    fit: BoxFit.contain,
                  )
                : (icon != null
                    ? Icon(icon, size: compact ? 32 : 44, color: L.accent)
                    : Text(
                        emoji,
                        style: AppTypography.displayLarge.copyWith(
                          fontSize: compact ? 32 : 44,
                        ),
                      ))));

    Widget iconArea = MedAiDepthCard(
      padding: EdgeInsets.zero,
      radius: AppRadius.max,
      color: L.card,
      child: SizedBox(
        width: artSize,
        height: artSize,
        child: Center(child: resolvedVisual),
      ),
    );

    Widget titleWidget = Text(
      title,
      textAlign: TextAlign.center,
      style: AppTypography.headlineLarge.copyWith(
        color: L.text,
        fontSize: compact ? 18 : 22,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
      ),
    );

    Widget subtitleWidget = Text(
      subtitle,
      textAlign: TextAlign.center,
      style: AppTypography.bodyMedium.copyWith(
        color: L.sub,
        fontSize: compact ? 13 : 15,
        fontWeight: FontWeight.w500,
        height: 1.5,
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
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          iconArea,
          SizedBox(height: compact ? AppSpacing.p16 : 32),
          titleWidget,
          SizedBox(height: compact ? AppSpacing.p8 : 12),
          subtitleWidget,
          if (actionLabel != null && onAction != null) ...[
            SizedBox(height: compact ? AppSpacing.p20 : 40),
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
