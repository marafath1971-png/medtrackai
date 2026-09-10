import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/med_ai_assets.dart';
import '../../models/constants.dart';
import '../../theme/med_ai_ui.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/common/ghost_mascot.dart';
import '../../l10n/app_localizations.dart';

/// The first thing anyone sees on every cold start.
///
/// It previously stacked three competing marks: the mascot at 116px, the
/// wordmark set in w900 — the heaviest weight the family has — and an
/// AppLoadingIndicator that is itself MedAiLogo.badge shrunk to 18px, so the
/// logo appeared twice and the second copy was too small to read as anything
/// but a speck. All of it sat inside a white card floating on the aurora,
/// a container with nothing to contain.
///
/// One mark, one line of type, and a progress hint that reads as motion
/// rather than as a second logo.
class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final L = context.L;

    return AppScaffold(
      showAurora: true,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GhostMascot(
                asset: MedAiAssets.mascotMedsBottle,
                size: 132,
                showGlow: true,
                semanticLabel: l10n.loadingMascot(kAppName),
              ),
              const SizedBox(height: AppSpacing.p24),

              // w700 carries a wordmark at display size; w900 only makes it
              // blocky. The negative tracking does the tightening instead.
              Text(
                kAppName,
                style: AppTypography.displaySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1.0,
                  color: L.text,
                  height: 1.05,
                ),
              ).medAiChain(
                context,
                (w) => w.animate().fadeIn(duration: 420.ms),
              ),
              const SizedBox(height: AppSpacing.p8),

              Text(
                l10n.loadingPreparingYourHealthWorkspace,
                style: AppTypography.bodySmall.copyWith(
                  color: L.sub,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ).medAiChain(
                context,
                // Trails the wordmark so the screen resolves top-down rather
                // than every line arriving at once.
                (w) => w.animate(delay: 140.ms).fadeIn(duration: 380.ms),
              ),
              const SizedBox(height: AppSpacing.p24),

              const _ProgressHint(),
            ],
          ).medAiChain(
            context,
            (w) => w
                .animate()
                .fadeIn(duration: 480.ms)
                .slideY(begin: 0.04, end: 0, curve: Curves.easeOutCubic),
          ),
        ),
      ),
    );
  }
}

/// A slim determinate-looking sweep, not a second logo.
///
/// Reads as "something is happening" at a glance and stays out of the way of
/// the mark above it. Falls back to a static track under reduced motion,
/// matching how GhostMascot stops floating.
class _ProgressHint extends StatelessWidget {
  const _ProgressHint();

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final track = L.border.withValues(alpha: 0.45);

    return SizedBox(
      width: 108,
      height: 3,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: track,
          borderRadius: BorderRadius.circular(AppRadius.max),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: 0.42,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.accentDeep,
                borderRadius: BorderRadius.circular(AppRadius.max),
              ),
            ),
          ).medAiChain(
            context,
            (w) => w
                .animate(onPlay: (c) => c.repeat())
                .slideX(
                  begin: -1.0,
                  end: 2.4,
                  duration: 1150.ms,
                  curve: Curves.easeInOutCubic,
                ),
          ),
        ),
      ),
    );
  }
}
