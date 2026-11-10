import 'package:flutter/material.dart';

import '../../../core/utils/haptic_engine.dart';
import '../../../core/utils/step_math.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/controllers/steps_controller.dart';
import '../../../theme/med_ai_ui.dart';
import '../../steps/widgets/step_ring.dart';
import '../../steps/widgets/steps_sheets.dart';

/// Today's steps on the home tab: a small ring, the count, and the partner's
/// count when paired. Before step counting is on, it is the way in.
class HomeStepsCard extends StatelessWidget {
  final StepsController steps;
  final VoidCallback onOpen;

  const HomeStepsCard({super.key, required this.steps, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: steps,
      builder: (context, _) {
        final l10n = AppLocalizations.of(context)!;
        final L = context.L;
        final on = steps.enabled;
        final today = steps.today;
        final partner = steps.partner;
        final theirs = steps.partnerToday;

        final String title;
        final String subtitle;
        if (!on) {
          title = l10n.stepsHomeCta;
          subtitle = l10n.stepsHomeCtaBody;
        } else {
          title = l10n.stepsHomeCount(StepMath.format(today.steps));
          if (partner != null) {
            final name = partner.name.isEmpty
                ? l10n.stepsPartnerFallbackName
                : partner.name;
            subtitle = theirs == null
                ? l10n.stepsPartnerNotSynced(name)
                : l10n.stepsHomeWith(name, StepMath.format(theirs.steps));
          } else if (today.goalMet) {
            subtitle = l10n.stepsGoalReached;
          } else {
            subtitle = l10n.stepsHomeToGo(StepMath.format(today.remaining));
          }
        }

        return Semantics(
          button: true,
          label: '$title. $subtitle',
          excludeSemantics: true,
          child: MedAiDepthCard(
            padding: const EdgeInsets.all(AppSpacing.p16),
            onTap: () {
              HapticEngine.selection();
              onOpen();
            },
            child: Row(
              children: [
                StepRing(
                  size: 56,
                  stroke: partner == null ? 7 : 5,
                  arcs: [
                    StepRingArc(
                      progress: on ? today.progress : 0,
                      color: StepColors.me(context),
                      track: L.fill,
                    ),
                    if (partner != null)
                      StepRingArc(
                        progress: theirs?.progress ?? 0,
                        color: StepColors.partner(context),
                        track: L.fill,
                      ),
                  ],
                  child: partner != null
                      ? null
                      : Icon(Icons.directions_walk_rounded,
                          size: 20, color: L.text),
                ),
                const SizedBox(width: AppSpacing.p16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleLarge.copyWith(
                          color: L.text,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall.copyWith(color: L.sub),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.p8),
                Icon(Icons.chevron_right_rounded, color: L.sub),
              ],
            ),
          ),
        );
      },
    );
  }
}
