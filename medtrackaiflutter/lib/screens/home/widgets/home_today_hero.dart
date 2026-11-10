import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/med_ai_assets.dart';
import '../../../core/utils/haptic_engine.dart';
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

  /// Current streak in days. Absorbed from LimeProgressHero, which showed the
  /// same taken/total this widget does and existed mainly to carry this.
  final int streak;

  /// Opens the streak detail. Null hides the streak chip entirely.
  final VoidCallback? onStreakTap;

  const HomeTodayHero({
    super.key,
    required this.taken,
    required this.total,
    this.nextDose,
    this.name,
    this.streak = 0,
    this.onStreakTap,
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
        color: L.card,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: L.border.withValues(alpha: 0.35),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A2621).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
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
                    color: L.sub,
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
                if (streak > 0 && onStreakTap != null) ...[
                  const SizedBox(height: AppSpacing.p12),
                  _StreakChip(days: streak, onTap: onStreakTap!),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.p12),
          GhostMascot(
            asset: s.mascot,
            size: 48,
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
        _DayState.empty =>
          'Scan a box or search by name to build your schedule.',
        _DayState.notStarted => 'Your first dose is coming up.',
        _DayState.inProgress => 'Keep going — the rest are still ahead.',
        _DayState.complete => "Nothing left today. See you tomorrow.",
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
/// Each taken segment animates in with a stagger for delight.
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
          backgroundColor: L.fill,
          valueColor: const AlwaysStoppedAnimation(AppColors.accentDeep),
        ),
      ).animate().scaleX(
          begin: 0,
          end: 1,
          alignment: Alignment.centerLeft,
          duration: 600.ms,
          curve: Curves.easeOutExpo);
    }

    return Row(
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          Expanded(
            child: AnimatedContainer(
              duration: Duration(milliseconds: 300 + i * 60),
              curve: Curves.easeOutBack,
              height: 7,
              decoration: BoxDecoration(
                color: i < taken ? AppColors.accentDeep : L.fill,
                borderRadius: BorderRadius.circular(AppRadius.max),
              ),
            ).animate(delay: Duration(milliseconds: i * 80)).scaleX(
                begin: 0,
                end: 1,
                alignment: Alignment.centerLeft,
                duration: 350.ms,
                curve: Curves.easeOutBack),
          ),
        ],
      ],
    );
  }
}

/// Animated streak chip — the fire icon pulses when streak ≥ 3 to reward
/// consistent users with a subtle celebration micro-interaction.
class _StreakChip extends StatefulWidget {
  final int days;
  final VoidCallback onTap;

  const _StreakChip({required this.days, required this.onTap});

  @override
  State<_StreakChip> createState() => _StreakChipState();
}

class _StreakChipState extends State<_StreakChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.22).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    if (widget.days >= 3) {
      _pulseCtrl.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final isHot = widget.days >= 3;
    final fireColor = widget.days >= 7
        ? const Color(0xFFFF6B35)
        : widget.days >= 3
            ? AppColors.amber
            : AppColors.accentDeep;

    return GestureDetector(
      onTap: () {
        HapticEngine.selection();
        widget.onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isHot ? fireColor.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.max),
          border: isHot
              ? Border.all(color: fireColor.withValues(alpha: 0.25), width: 1)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, child) => Transform.scale(
                scale: isHot ? _pulseAnim.value : 1.0,
                child: child,
              ),
              child: Icon(
                Icons.local_fire_department_rounded,
                size: 15,
                color: fireColor,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              widget.days == 1 ? '1 day streak' : '${widget.days} day streak',
              style: AppTypography.caption.copyWith(
                color: isHot ? fireColor : L.sub,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
