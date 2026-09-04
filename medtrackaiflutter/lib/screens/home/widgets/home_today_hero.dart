import 'package:flutter/material.dart';

import '../../../core/constants/med_ai_assets.dart';
import '../../../theme/med_ai_ui.dart';
import '../../../widgets/common/ghost_mascot.dart';

/// Home's first viewport: what is true for this person right now.
///
/// This replaces a 168px stock photograph of a salad captioned "Your #1 plan
/// for medication success". Three problems with that:
///
/// * Food imagery on a medication screen is a category mismatch — nothing in
///   the app tracks meals, so the picture promised a feature that isn't there.
/// * "MADE FOR YOU" sat above content identical for every user, which is the
///   fastest way to spend the credibility a personalised app depends on.
/// * It occupied the most valuable space on the screen while carrying no
///   information — the next dose and the day's progress sat below it.
///
/// The replacement is built from state the app already has: what is due next,
/// how the day is going, and the mascot reflecting that rather than decorating
/// it. It also shrinks to ~120px, so the schedule rises into first view.
class HomeTodayHero extends StatelessWidget {
  /// Doses taken today.
  final int taken;

  /// Doses scheduled today.
  final int total;

  /// Label for the next dose, e.g. "Metformin · 21:00". Null when none remain.
  final String? nextDose;

  /// Greeting name, if known.
  final String? name;

  const HomeTodayHero({
    super.key,
    required this.taken,
    required this.total,
    this.nextDose,
    this.name,
  });

  /// Which state the day is in. Drives copy, tint and mascot together so they
  /// can never disagree.
  _DayState get _state {
    if (total == 0) return _DayState.empty;
    if (taken >= total) return _DayState.complete;
    if (taken == 0) return _DayState.notStarted;
    return _DayState.inProgress;
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final s = _state;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.p16),
      decoration: BoxDecoration(
        color: s.tint,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  s.eyebrow.toUpperCase(),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.accentDeep,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  s.headline(taken: taken, total: total, name: name),
                  style: AppTypography.titleMedium.copyWith(
                    color: L.text,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  // The next dose is the single most actionable fact on the
                  // screen, so it is stated here rather than only in a card
                  // further down.
                  nextDose ?? s.fallbackLine,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    color: L.sub,
                    height: 1.35,
                  ),
                ),
                if (total > 0) ...[
                  const SizedBox(height: AppSpacing.p12),
                  _ProgressTrack(taken: taken, total: total),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.p12),
          GhostMascot(
            asset: s.mascot,
            size: 78,
            showGlow: false,
            semanticLabel: s.eyebrow,
          ),
        ],
      ),
    );
  }
}

enum _DayState { empty, notStarted, inProgress, complete }

extension on _DayState {
  String get eyebrow => switch (this) {
        _DayState.empty => 'Get started',
        _DayState.notStarted => 'Today',
        _DayState.inProgress => 'Today',
        _DayState.complete => 'All done',
      };

  String headline({required int taken, required int total, String? name}) =>
      switch (this) {
        _DayState.empty => 'Add your first medicine',
        _DayState.notStarted =>
          total == 1 ? '1 dose scheduled' : '$total doses scheduled',
        _DayState.inProgress => '$taken of $total taken',
        _DayState.complete =>
          name == null ? 'Every dose taken' : 'Every dose taken, $name',
      };

  String get fallbackLine => switch (this) {
        _DayState.empty => 'Scan a box or search by name to build your schedule.',
        _DayState.notStarted => 'Your first dose is coming up.',
        _DayState.inProgress => 'Keep going — the rest are still ahead.',
        _DayState.complete => "Nothing left today. See you tomorrow.",
      };

  Color get tint => switch (this) {
        _DayState.empty => AppColors.pastelSky,
        _DayState.notStarted => AppColors.pastelSky,
        _DayState.inProgress => AppColors.pastelSun,
        _DayState.complete => AppColors.pastelMint,
      };

  String get mascot => switch (this) {
        _DayState.empty => MedAiAssets.mascotMedsBottle,
        _DayState.notStarted => MedAiAssets.mascotDeterminedPill,
        _DayState.inProgress => MedAiAssets.mascotDeterminedPill,
        _DayState.complete => MedAiAssets.mascotTrophyWin,
      };
}

/// Segment per dose rather than a continuous bar — at these counts (typically
/// 1-6 a day) a fraction of a bar is harder to read than discrete marks.
class _ProgressTrack extends StatelessWidget {
  final int taken;
  final int total;

  const _ProgressTrack({required this.taken, required this.total});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    // Above ~8 the segments get too thin to read, so fall back to a bar.
    if (total > 8) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.max),
        child: LinearProgressIndicator(
          value: taken / total,
          minHeight: 7,
          backgroundColor: L.card.withValues(alpha: 0.7),
          valueColor: const AlwaysStoppedAnimation(AppColors.accentDeep),
        ),
      );
    }

    return Row(
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          Expanded(
            child: Container(
              height: 7,
              decoration: BoxDecoration(
                color: i < taken
                    ? AppColors.accentDeep
                    : L.card.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(AppRadius.max),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
