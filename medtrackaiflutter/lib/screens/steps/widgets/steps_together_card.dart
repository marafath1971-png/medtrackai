import 'package:flutter/material.dart';

import '../../../core/utils/haptic_engine.dart';
import '../../../core/utils/step_math.dart';
import '../../../domain/entities/step_day.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/controllers/steps_controller.dart';
import '../../../theme/med_ai_ui.dart';
import '../../../widgets/common/animated_pressable.dart';
import 'steps_sheets.dart';

/// "Walk together": either the invitation to pair, or the shared day once
/// two people are paired.
class StepsTogetherCard extends StatelessWidget {
  final StepsController steps;
  final void Function(String message, {bool error}) onMessage;

  const StepsTogetherCard({
    super.key,
    required this.steps,
    required this.onMessage,
  });

  @override
  Widget build(BuildContext context) {
    final partner = steps.partner;
    return MedAiDepthCard(
      child: partner == null
          ? _Unpaired(steps: steps, onMessage: onMessage)
          : _Paired(steps: steps, partner: partner, onMessage: onMessage),
    );
  }
}

class _Unpaired extends StatelessWidget {
  final StepsController steps;
  final void Function(String message, {bool error}) onMessage;
  const _Unpaired({required this.steps, required this.onMessage});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final L = context.L;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            // Two overlapping dots: the two walkers, in their ring colours.
            SizedBox(
              width: 58,
              height: 40,
              child: Stack(
                children: [
                  _Dot(
                      color: StepColors.me(context),
                      icon: Icons.person_rounded),
                  Positioned(
                    left: 20,
                    child: _Dot(
                      color: StepColors.partner(context),
                      icon: Icons.favorite_rounded,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.p12),
            Expanded(
              child: Text(
                l10n.stepsTogetherTitle,
                style: AppTypography.titleLarge
                    .copyWith(color: L.text, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.p12),
        Text(
          steps.signedIn ? l10n.stepsTogetherEmptyBody : l10n.stepsSignInToPair,
          style: AppTypography.bodyMedium.copyWith(color: L.sub),
        ),
        if (steps.signedIn) ...[
          const SizedBox(height: AppSpacing.p16),
          MedAiCTA(
            label: l10n.stepsInvitePartner,
            icon: Icons.person_add_alt_1_rounded,
            onTap: () => showStepInviteSheet(context, steps),
          ),
          const SizedBox(height: AppSpacing.p8),
          MedAiCTA(
            label: l10n.stepsEnterCode,
            secondary: true,
            onTap: () async {
              final joined = await showStepJoinSheet(context, steps);
              if (joined) onMessage(l10n.stepsJoined, error: false);
            },
          ),
        ],
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  final IconData icon;
  const _Dot({required this.color, required this.icon});

  @override
  Widget build(BuildContext context) => Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: context.L.card, width: 2),
        ),
        child: Icon(icon, size: 18, color: AppColors.eatoNavy),
      );
}

class _Paired extends StatelessWidget {
  final StepsController steps;
  final StepPartner partner;
  final void Function(String message, {bool error}) onMessage;

  const _Paired({
    required this.steps,
    required this.partner,
    required this.onMessage,
  });

  Future<void> _cheer(
      BuildContext context, StepCheerKind kind, String name) async {
    final l10n = AppLocalizations.of(context)!;
    HapticEngine.light();
    final sent = await steps.sendCheer(kind);
    if (!sent) {
      onMessage(l10n.stepsCheerFailed, error: true);
      return;
    }
    onMessage(
      kind == StepCheerKind.nudge
          ? l10n.stepsNudgeSent(name)
          : l10n.stepsCheerSent(name),
      error: false,
    );
  }

  Future<void> _confirmUnpair(BuildContext context, String name) async {
    final l10n = AppLocalizations.of(context)!;
    final yes = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(l10n.stepsUnpairConfirmTitle(name)),
        content: Text(l10n.stepsUnpairConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(false),
            child: Text(l10n.stepsKeepSharing),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(true),
            child: Text(l10n.stepsUnpair),
          ),
        ],
      ),
    );
    if (yes != true) return;
    final ok = await steps.unpair();
    if (!ok) onMessage(l10n.stepsUnpairFailed, error: true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final L = context.L;
    final name =
        partner.name.isEmpty ? l10n.stepsPartnerFallbackName : partner.name;
    final mine = steps.today;
    final theirs = steps.partnerToday;
    final total = steps.togetherSteps;
    final goal = steps.togetherGoal;
    final fraction = goal <= 0 ? 0.0 : (total / goal).clamp(0.0, 1.0);
    final diff = mine.steps - (theirs?.steps ?? 0);
    final wins = steps.weekWins;
    final duoStreak = steps.duoStreak;

    final String lead;
    if (theirs == null) {
      lead = l10n.stepsPartnerNotSynced(name);
    } else if (diff == 0) {
      lead = l10n.stepsLeadTied;
    } else if (diff > 0) {
      lead = l10n.stepsLeadYou(StepMath.format(diff), name);
    } else {
      lead = l10n.stepsLeadPartner(name, StepMath.format(-diff));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.stepsTogetherTitle,
                style: AppTypography.titleLarge
                    .copyWith(color: L.text, fontWeight: FontWeight.w700),
              ),
            ),
            Semantics(
              button: true,
              label: l10n.stepsUnpair,
              child: AnimatedPressable(
                onTap: () => _confirmUnpair(context, name),
                child: SizedBox(
                  width: MedAiA11y.minTapTargetCompact,
                  height: MedAiA11y.minTapTargetCompact,
                  child: Icon(Icons.link_off_rounded, color: L.sub, size: 20),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.p8),
        _WalkerRow(
          color: StepColors.me(context),
          name: l10n.stepsYou,
          steps: StepMath.format(mine.steps),
          done: mine.goalMet,
        ),
        const SizedBox(height: AppSpacing.p8),
        _WalkerRow(
          color: StepColors.partner(context),
          name: name,
          steps: theirs == null ? '—' : StepMath.format(theirs.steps),
          done: theirs?.goalMet ?? false,
        ),
        const SizedBox(height: AppSpacing.p16),
        // One bar, two colours: how much of the shared goal each has walked.
        ClipRRect(
          borderRadius: AppRadius.circle,
          child: SizedBox(
            height: 12,
            child: Stack(
              children: [
                Positioned.fill(child: ColoredBox(color: L.fill)),
                FractionallySizedBox(
                  widthFactor: fraction,
                  child: Row(
                    children: [
                      if (mine.steps > 0)
                        Expanded(
                          flex: mine.steps,
                          child: ColoredBox(color: StepColors.me(context)),
                        ),
                      if ((theirs?.steps ?? 0) > 0)
                        Expanded(
                          flex: theirs!.steps,
                          child: ColoredBox(color: StepColors.partner(context)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.p8),
        Text(
          l10n.stepsTogetherProgress(
              StepMath.format(total), StepMath.format(goal)),
          style: AppTypography.labelLarge
              .copyWith(color: L.text, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
        Text(lead, style: AppTypography.bodySmall.copyWith(color: L.sub)),
        if (duoStreak > 0 || wins.mine + wins.partner > 0) ...[
          const SizedBox(height: AppSpacing.p12),
          Wrap(
            spacing: AppSpacing.p8,
            runSpacing: AppSpacing.p8,
            children: [
              if (duoStreak > 0)
                _Pill(
                  icon: Icons.local_fire_department_rounded,
                  label: l10n.stepsDuoStreak(duoStreak),
                ),
              if (wins.mine + wins.partner > 0)
                _Pill(
                  icon: Icons.emoji_events_rounded,
                  label: l10n.stepsWeekWins(wins.mine, name, wins.partner),
                ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.p16),
        Row(
          children: [
            Expanded(
              child: MedAiCTA(
                label: l10n.stepsCheer,
                icon: Icons.celebration_rounded,
                enabled: steps.canCheer,
                onTap: () => _cheer(context, StepCheerKind.cheer, name),
              ),
            ),
            const SizedBox(width: AppSpacing.p8),
            Expanded(
              child: MedAiCTA(
                label: l10n.stepsNudge,
                icon: Icons.directions_walk_rounded,
                secondary: true,
                enabled: steps.canCheer,
                onTap: () => _cheer(context, StepCheerKind.nudge, name),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _WalkerRow extends StatelessWidget {
  final Color color;
  final String name;
  final String steps;
  final bool done;

  const _WalkerRow({
    required this.color,
    required this.name,
    required this.steps,
    required this.done,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.p8),
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodyLarge.copyWith(color: L.text),
          ),
        ),
        if (done) ...[
          Icon(Icons.check_circle_rounded, size: 16, color: L.green),
          const SizedBox(width: AppSpacing.p4),
        ],
        Text(
          steps,
          style: AppTypography.monoNumber.copyWith(
            color: L.text,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Pill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.p12, vertical: AppSpacing.p8),
      decoration: BoxDecoration(color: L.fill, borderRadius: AppRadius.circle),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: L.text),
          const SizedBox(width: AppSpacing.p4),
          Flexible(
            child: Text(
              label,
              style: AppTypography.labelMedium.copyWith(color: L.text),
            ),
          ),
        ],
      ),
    );
  }
}
