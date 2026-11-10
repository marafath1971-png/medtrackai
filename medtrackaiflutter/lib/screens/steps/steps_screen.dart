import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/utils/haptic_engine.dart';
import '../../core/utils/step_math.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/app_state.dart';
import '../../providers/controllers/steps_controller.dart';
import '../../services/share_service.dart';
import '../../services/steps_service.dart';
import '../../theme/med_ai_ui.dart';
import '../../widgets/common/animated_pressable.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/common/premium_page_header.dart';
import 'widgets/step_ring.dart';
import 'widgets/steps_charts.dart';
import 'widgets/steps_sheets.dart';
import 'widgets/steps_together_card.dart';

/// Daily steps: today's ring, the week, the hours, milestones, and the
/// walking partner.
class StepsScreen extends StatefulWidget {
  /// Defaults to the app's controller; tests pass their own.
  final StepsController? controller;

  const StepsScreen({super.key, this.controller});

  @override
  State<StepsScreen> createState() => _StepsScreenState();
}

class _StepsScreenState extends State<StepsScreen> {
  late final StepsController _steps =
      widget.controller ?? context.read<AppState>().steps;
  bool _enabling = false;

  @override
  void initState() {
    super.initState();
    _steps.refresh();
  }

  void _message(String message, {bool error = false}) {
    if (!mounted) return;
    context
        .read<AppState>()
        .showToast(message, type: error ? 'error' : 'success');
  }

  Future<void> _enable() async {
    if (_enabling) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _enabling = true);
    HapticEngine.selection();
    if (_steps.access == StepAccess.needsInstall) {
      await _steps.openInstall();
    }
    final result = await _steps.enable();
    if (!mounted) return;
    setState(() => _enabling = false);
    if (result == StepAccess.denied) {
      _message(l10n.stepsDenied(_sourceName(l10n)), error: true);
    }
  }

  static String _sourceName(AppLocalizations l10n) =>
      Platform.isIOS ? l10n.stepsSourceApple : l10n.stepsSourceAndroid;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();

    return AppScaffold(
      body: ListenableBuilder(
        listenable: _steps,
        builder: (context, _) {
          final on = _steps.enabled;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PremiumPageHeader(
                title: l10n.stepsTitle,
                subtitle: DateFormat.MMMMEEEEd(locale).format(DateTime.now()),
                onBack: () => Navigator.of(context).maybePop(),
                trailing: on
                    ? _HeaderButton(
                        icon: Icons.ios_share_rounded,
                        label: l10n.stepsShare,
                        onTap: () => ShareService.shareText(
                          l10n.stepsShareText(
                              StepMath.format(_steps.today.steps)),
                        ),
                      )
                    : null,
              ),
              Expanded(
                child: on
                    ? RefreshIndicator(
                        onRefresh: () => _steps.refresh(force: true),
                        child: _Dashboard(steps: _steps, onMessage: _message),
                      )
                    : _Intro(
                        access: _steps.access,
                        busy: _enabling,
                        onEnable: _enable,
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _HeaderButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Semantics(
      button: true,
      label: label,
      child: AnimatedPressable(
        onTap: onTap,
        child: Container(
          width: MedAiA11y.minTapTargetCompact,
          height: MedAiA11y.minTapTargetCompact,
          decoration: BoxDecoration(
            color: L.card,
            shape: BoxShape.circle,
            border: Border.all(color: L.border.withValues(alpha: 0.45)),
          ),
          child: Icon(icon, color: L.text, size: 18),
        ),
      ),
    );
  }
}

// ── Not turned on yet ────────────────────────────────────────────────────

class _Intro extends StatelessWidget {
  final StepAccess access;
  final bool busy;
  final VoidCallback onEnable;

  const _Intro(
      {required this.access, required this.busy, required this.onEnable});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final L = context.L;
    final unavailable = access == StepAccess.unavailable;
    final needsInstall = access == StepAccess.needsInstall;

    // The call to action is pinned under the scrolling pitch, so it is on
    // screen on a small phone or at a large text size without scrolling.
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding,
                AppSpacing.p8, AppSpacing.screenPadding, AppSpacing.p24),
            children: [
              Center(
                child: StepRing(
                  size: 190,
                  stroke: 15,
                  arcs: [
                    StepRingArc(
                      progress: 0.72,
                      color: StepColors.me(context),
                      track: L.fill,
                    ),
                    StepRingArc(
                      progress: 0.55,
                      color: StepColors.partner(context),
                      track: L.fill,
                    ),
                  ],
                  child: Icon(Icons.directions_walk_rounded,
                      size: 48, color: L.text),
                ),
              ),
              const SizedBox(height: AppSpacing.p24),
              Text(
                l10n.stepsIntroTitle,
                textAlign: TextAlign.center,
                style: AppTypography.headlineLarge
                    .copyWith(color: L.text, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.p8),
              Text(
                l10n.stepsIntroBody,
                textAlign: TextAlign.center,
                style: AppTypography.bodyLarge.copyWith(color: L.sub),
              ),
              const SizedBox(height: AppSpacing.p24),
              MedAiDepthCard(
                child: Column(
                  children: [
                    _Bullet(
                        icon: Icons.flag_rounded, text: l10n.stepsIntroBullet1),
                    const SizedBox(height: AppSpacing.p12),
                    _Bullet(
                        icon: Icons.insights_rounded,
                        text: l10n.stepsIntroBullet2),
                    const SizedBox(height: AppSpacing.p12),
                    _Bullet(
                        icon: Icons.favorite_rounded,
                        text: l10n.stepsIntroBullet3),
                  ],
                ),
              ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, 0,
              AppSpacing.screenPadding, AppSpacing.p16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (unavailable)
                Text(
                  l10n.stepsUnavailable,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(color: L.sub),
                )
              else ...[
                if (needsInstall) ...[
                  Text(
                    l10n.stepsNeedsInstallBody,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium.copyWith(color: L.sub),
                  ),
                  const SizedBox(height: AppSpacing.p12),
                ],
                MedAiCTA(
                  label: needsInstall
                      ? l10n.stepsInstallHealthConnect
                      : l10n.stepsTurnOn,
                  icon: Icons.directions_walk_rounded,
                  loading: busy,
                  onTap: onEnable,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Bullet extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Bullet({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: L.fill, shape: BoxShape.circle),
          child: Icon(icon, size: 18, color: L.text),
        ),
        const SizedBox(width: AppSpacing.p12),
        Expanded(
          child: Text(text,
              style: AppTypography.bodyMedium.copyWith(color: L.text)),
        ),
      ],
    );
  }
}

// ── Turned on ────────────────────────────────────────────────────────────

class _Dashboard extends StatelessWidget {
  final StepsController steps;
  final void Function(String message, {bool error}) onMessage;

  const _Dashboard({required this.steps, required this.onMessage});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final L = context.L;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final today = steps.today;
    final partner = steps.partner;
    final partnerName = partner == null
        ? null
        : (partner.name.isEmpty ? l10n.stepsPartnerFallbackName : partner.name);
    final peak = steps.peakHour;
    final best = steps.bestDay;
    final source =
        Platform.isIOS ? l10n.stepsSourceApple : l10n.stepsSourceAndroid;
    final blocked = steps.access == StepAccess.unavailable ||
        steps.access == StepAccess.needsInstall;

    String dayName(StepDay d) =>
        DateFormat.EEEE(locale).format(DateTime.parse(d.dateKey));

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter, AppSpacing.p4, AppSpacing.gutter, AppSpacing.p48),
      children: [
        _Hero(steps: steps, partnerName: partnerName),
        if (blocked || today.steps == 0) ...[
          const SizedBox(height: AppSpacing.p12),
          _Notice(
            text: blocked
                ? l10n.stepsNeedsInstallBody
                : (Platform.isIOS
                    ? l10n.stepsZeroHintIos
                    : l10n.stepsZeroHintAndroid),
          ),
        ],
        const SizedBox(height: AppSpacing.cardGap),
        Row(
          children: [
            Expanded(
              child: _Stat(
                icon: Icons.route_rounded,
                tint: AppColors.pastelSky,
                value: l10n.stepsDistanceValue(steps.distanceKm
                    .toStringAsFixed(steps.distanceKm < 10 ? 2 : 1)),
                label: l10n.stepsDistance,
              ),
            ),
            const SizedBox(width: AppSpacing.cardGap),
            Expanded(
              child: _Stat(
                icon: Icons.local_fire_department_rounded,
                tint: AppColors.pastelSun,
                value: l10n.stepsEnergyValue(StepMath.format(steps.kcal)),
                label: l10n.stepsEnergy,
              ),
            ),
            const SizedBox(width: AppSpacing.cardGap),
            Expanded(
              child: _Stat(
                icon: Icons.schedule_rounded,
                tint: AppColors.pastelMint,
                value: '${steps.activeHours}',
                label: l10n.stepsActiveHours,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.p24),
        StepsTogetherCard(steps: steps, onMessage: onMessage),
        const SizedBox(height: AppSpacing.p24),
        MedAiSectionHeader(
          title: l10n.stepsThisWeek,
          subtitle: steps.weekAverage > 0
              ? l10n.stepsWeekAverage(StepMath.format(steps.weekAverage))
              : null,
        ),
        MedAiDepthCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StepsWeekChart(
                mine: steps.week,
                partner: partner == null ? null : steps.partnerWeek,
                mineColor: StepColors.me(context),
                partnerColor: StepColors.partner(context),
                describe: (mine, theirs) => theirs == null
                    ? l10n.stepsDayDetail(
                        dayName(mine), StepMath.format(mine.steps))
                    : l10n.stepsDayDetailDuo(
                        dayName(mine),
                        StepMath.format(mine.steps),
                        partnerName ?? '',
                        StepMath.format(theirs.steps),
                      ),
              ),
              if (steps.streak > 0 || best != null) ...[
                const SizedBox(height: AppSpacing.p16),
                Wrap(
                  spacing: AppSpacing.p16,
                  runSpacing: AppSpacing.p8,
                  children: [
                    if (steps.streak > 0)
                      _Fact(
                        icon: Icons.local_fire_department_rounded,
                        text: l10n.stepsStreak(steps.streak),
                      ),
                    if (best != null)
                      _Fact(
                        icon: Icons.emoji_events_rounded,
                        text: l10n.stepsBestDay(StepMath.format(best.steps)),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.p24),
        MedAiSectionHeader(
          title: l10n.stepsTodayByHour,
          subtitle: peak == null
              ? l10n.stepsNoHourlyYet
              : l10n.stepsPeakHour(
                  DateFormat.j(locale).format(DateTime(2000, 1, 1, peak))),
        ),
        MedAiDepthCard(
          child: StepsHourChart(
            hourly: today.hourly,
            color: StepColors.me(context),
          ),
        ),
        const SizedBox(height: AppSpacing.p24),
        _Badges(earned: steps.badges),
        const SizedBox(height: AppSpacing.p24),
        Text(
          l10n.stepsEstimateNote(source),
          textAlign: TextAlign.center,
          style: AppTypography.bodySmall.copyWith(color: L.sub),
        ),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  final StepsController steps;
  final String? partnerName;
  const _Hero({required this.steps, required this.partnerName});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final today = steps.today;
    final theirs = steps.partnerToday;
    const ink = Colors.white;
    final soft = Colors.white.withValues(alpha: 0.72);

    final String status;
    if (today.steps > today.goal) {
      status = l10n.stepsGoalBeaten(StepMath.format(today.steps - today.goal));
    } else if (today.goalMet) {
      status = l10n.stepsGoalReached;
    } else {
      status = l10n.stepsToGo(
        StepMath.format(today.remaining),
        StepMath.walkMinutesFor(today.remaining),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.p20, AppSpacing.p24, AppSpacing.p20, AppSpacing.p16),
      decoration: BoxDecoration(
        color: StepColors.heroBg,
        borderRadius: AppRadius.roundSquircle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: AppShadows.premium,
      ),
      child: Column(
        children: [
          Semantics(
            label:
                '${StepMath.format(today.steps)} ${l10n.stepsOfGoal(StepMath.format(today.goal))}. $status',
            excludeSemantics: true,
            child: StepRing(
              size: 220,
              stroke: partnerName == null ? 18 : 15,
              arcs: [
                StepRingArc(
                  progress: today.progress,
                  color: StepColors.heroMe,
                  track: Colors.white.withValues(alpha: 0.10),
                ),
                if (partnerName != null)
                  StepRingArc(
                    progress: theirs?.progress ?? 0,
                    color: StepColors.heroPartner,
                    track: Colors.white.withValues(alpha: 0.10),
                  ),
              ],
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 44),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      today.goalMet
                          ? Icons.check_circle_rounded
                          : Icons.directions_walk_rounded,
                      color: StepColors.heroMe,
                      size: 22,
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        StepMath.format(today.steps),
                        maxLines: 1,
                        style: AppTypography.monoNumber.copyWith(
                          color: ink,
                          fontSize: 42,
                          height: 1.1,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      l10n.stepsOfGoal(StepMath.format(today.goal)),
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall.copyWith(color: soft),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.p16),
          Text(
            status,
            textAlign: TextAlign.center,
            style: AppTypography.titleMedium
                .copyWith(color: ink, fontWeight: FontWeight.w600),
          ),
          if (partnerName != null) ...[
            const SizedBox(height: AppSpacing.p12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpacing.p16,
              runSpacing: AppSpacing.p4,
              children: [
                _Legend(color: StepColors.heroMe, label: l10n.stepsYou),
                _Legend(color: StepColors.heroPartner, label: partnerName!),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.p8),
          Semantics(
            button: true,
            child: AnimatedPressable(
              onTap: () => showStepGoalSheet(context, steps),
              child: Container(
                constraints: const BoxConstraints(
                    minHeight: MedAiA11y.minTapTargetCompact),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.tune_rounded, size: 16, color: soft),
                    const SizedBox(width: AppSpacing.p8),
                    Flexible(
                      child: Text(
                        l10n.stepsEditGoal,
                        style: AppTypography.labelLarge.copyWith(color: soft),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelMedium
                  .copyWith(color: Colors.white.withValues(alpha: 0.85)),
            ),
          ),
        ],
      );
}

class _Notice extends StatelessWidget {
  final String text;
  const _Notice({required this.text});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.p12),
      decoration: BoxDecoration(color: L.fill, borderRadius: AppRadius.roundM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: L.sub),
          const SizedBox(width: AppSpacing.p8),
          Expanded(
            child: Text(text,
                style: AppTypography.bodySmall.copyWith(color: L.sub)),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final Color tint;
  final String value;
  final String label;

  const _Stat({
    required this.icon,
    required this.tint,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return MedAiDepthCard(
      padding: const EdgeInsets.all(AppSpacing.p12),
      radius: AppRadius.l,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: context.isDark ? L.fill : tint,
              shape: BoxShape.circle,
            ),
            child: Icon(icon,
                size: 16, color: context.isDark ? L.text : AppColors.eatoNavy),
          ),
          const SizedBox(height: AppSpacing.p12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              value,
              maxLines: 1,
              style: AppTypography.titleLarge
                  .copyWith(color: L.text, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(color: L.sub),
          ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Fact({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: L.accent),
        const SizedBox(width: AppSpacing.p4),
        Flexible(
          child: Text(text,
              style: AppTypography.labelLarge.copyWith(color: L.text)),
        ),
      ],
    );
  }
}

class _Badges extends StatelessWidget {
  final Set<StepBadge> earned;
  const _Badges({required this.earned});

  static (IconData, String) _look(StepBadge b, AppLocalizations l10n) =>
      switch (b) {
        StepBadge.firstGoal => (Icons.flag_rounded, l10n.stepsBadgeFirstGoal),
        StepBadge.tenK => (Icons.bolt_rounded, l10n.stepsBadgeTenK),
        StepBadge.streak3 => (
            Icons.local_fire_department_rounded,
            l10n.stepsBadgeStreak3
          ),
        StepBadge.streak7 => (Icons.whatshot_rounded, l10n.stepsBadgeStreak7),
        StepBadge.marathonWeek => (
            Icons.emoji_events_rounded,
            l10n.stepsBadgeMarathonWeek
          ),
        StepBadge.duoDay => (Icons.favorite_rounded, l10n.stepsBadgeDuoDay),
        StepBadge.duoStreak3 => (
            Icons.volunteer_activism_rounded,
            l10n.stepsBadgeDuoStreak3
          ),
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final L = context.L;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MedAiSectionHeader(
          title: l10n.stepsBadges,
          subtitle:
              l10n.stepsBadgesEarned(earned.length, StepBadge.values.length),
        ),
        Wrap(
          spacing: AppSpacing.p8,
          runSpacing: AppSpacing.p8,
          children: [
            for (final badge in StepBadge.values)
              Builder(builder: (context) {
                final (icon, label) = _look(badge, l10n);
                final has = earned.contains(badge);
                return Semantics(
                  label: has
                      ? l10n.stepsBadgeEarned(label)
                      : l10n.stepsBadgeLocked(label),
                  excludeSemantics: true,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.p12, vertical: AppSpacing.p8),
                    decoration: BoxDecoration(
                      color: has ? L.card : L.fill,
                      borderRadius: AppRadius.circle,
                      border: Border.all(
                        color: has
                            ? L.accent.withValues(alpha: 0.6)
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          has ? icon : Icons.lock_outline_rounded,
                          size: 16,
                          color: has ? L.accent : L.sub,
                        ),
                        const SizedBox(width: 6),
                        // Flexible: a long name at a large text size wraps
                        // inside the chip instead of running off the screen.
                        Flexible(
                          child: Text(
                            label,
                            style: AppTypography.labelLarge.copyWith(
                              color: has ? L.text : L.sub,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ],
    );
  }
}
