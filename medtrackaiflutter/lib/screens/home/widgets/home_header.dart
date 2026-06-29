import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../providers/app_state.dart';
import '../../../theme/med_ai_ui.dart';
import '../../../core/utils/haptic_engine.dart';
import '../../../widgets/common/animated_pressable.dart';
import '../../../widgets/common/med_ai_mascot.dart';

// ════════════════════════════════════════════════════════════════
// HOME HEADER — 2026 "Kinetic Brand Bar"
// Kinetic shimmer logo wordmark, live AI status, glass action chips.
// Frosts in on scroll like a Liquid Glass dock.
// ════════════════════════════════════════════════════════════════
class HomeHeader extends StatelessWidget {
  final AppState state;
  final int streak;
  final double scrollOffset;
  final VoidCallback onOpenStreak;
  final VoidCallback onOpenSettings;
  final VoidCallback? onTap;

  const HomeHeader({
    super.key,
    required this.state,
    required this.streak,
    this.scrollOffset = 0,
    required this.onOpenStreak,
    required this.onOpenSettings,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final isScrolled = scrollOffset > 20;
    final reduceMotion = MedAiA11y.reducedMotion(context);
    final userName = state.activeProfile?.name ?? state.profile?.name ?? 'Arafat';

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: isScrolled ? 24 : 0,
          sigmaY: isScrolled ? 24 : 0,
        ),
        child: AnimatedContainer(
          duration: MedAiA11y.motion(context, const Duration(milliseconds: 300)),
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
          decoration: BoxDecoration(
            color: isScrolled
                ? (context.isDark ? L.bg : Colors.white).withValues(alpha: 0.85)
                : Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: L.border.withValues(alpha: isScrolled ? 0.08 : 0.0),
                width: 0.5,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Row(
              children: [
                // ── User Avatar & Greeting ──
                AnimatedPressable(
                  onTap: () {
                    HapticEngine.selection();
                    onTap?.call();
                  },
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: L.accent.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : 'A',
                          style: AppTypography.titleLarge.copyWith(
                            color: L.accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _getFormattedDate(),
                            style: AppTypography.labelSmall.copyWith(
                              color: L.sub.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                              letterSpacing: 1.0,
                            ),
                          ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.1, end: 0),
                          const SizedBox(height: 2),
                          Text(
                            'Hi, $userName',
                            style: AppTypography.headlineSmall.copyWith(
                              color: L.text,
                              fontWeight: FontWeight.w800,
                              fontSize: 22,
                              letterSpacing: -0.6,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Spacer(),

                Semantics(
                  button: true,
                  label: '$streak day streak',
                  child: AnimatedPressable(
                    onTap: () {
                      HapticEngine.selection();
                      onOpenStreak();
                    },
                    child: _StreakChip(streak: streak),
                  ),
                ),
                const SizedBox(width: 8),

                Semantics(
                  button: true,
                  label: 'Open settings',
                  child: AnimatedPressable(
                    onTap: () {
                      HapticEngine.selection();
                      onOpenSettings();
                    },
                    child: SizedBox(
                      width: MedAiA11y.minTapTarget,
                      height: MedAiA11y.minTapTarget,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(Icons.notifications_none_rounded,
                              size: 26, color: L.text),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              width: 9,
                              height: 9,
                              decoration: BoxDecoration(
                                color: L.accent,
                                shape: BoxShape.circle,
                                border: Border.all(color: L.bg, width: 1.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}'.toUpperCase();
  }
}

// ── Calm brand mascot (single subtle float, no shimmer) ─────────
class _LogoBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const MedAiMascot(
      size: 44,
      showGlow: false,
      semanticLabel: 'Med AI home',
    );
  }
}
class _StreakChip extends StatelessWidget {
  final int streak;
  const _StreakChip({required this.streak});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Container(
      constraints: const BoxConstraints(minHeight: MedAiA11y.minTapTargetCompact),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: L.fill.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: L.border.withValues(alpha: 0.5),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 5),
          Text(
            '$streak day${streak == 1 ? '' : 's'}',
            style: AppTypography.labelSmall.copyWith(
              color: L.text,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class HomeWeekStrip extends StatelessWidget {
  final AppState state;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const HomeWeekStrip({
    super.key,
    required this.state,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    const dayLabels = ['W', 'T', 'F', 'S', 'S', 'M', 'T'];
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 3));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(7, (i) {
          final d = weekStart.add(Duration(days: i));
          final isSelected = d.year == selectedDate.year &&
              d.month == selectedDate.month &&
              d.day == selectedDate.day;
          final isToday =
              d.year == now.year && d.month == now.month && d.day == now.day;
          final isFuture = d.isAfter(now);

          return AnimatedPressable(
            onTap: () => onDateSelected(d),
            behavior: HitTestBehavior.opaque,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  dayLabels[i],
                  style: AppTypography.labelSmall.copyWith(
                    fontSize: 11,
                    color: L.sub.withValues(alpha: 0.4),
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 10),
                AnimatedContainer(
                  duration: 300.ms,
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? L.text
                        : (isToday
                            ? L.text.withValues(alpha: 0.1)
                            : Colors.transparent),
                    shape: BoxShape.circle,
                    border: !isSelected && isToday
                        ? Border.all(
                            color: L.text.withValues(alpha: 0.1), width: 1.5)
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '${d.day}',
                      style: AppTypography.labelSmall.copyWith(
                        fontSize: 14,
                        color: isSelected
                            ? L.bg
                            : L.text.withValues(alpha: isFuture ? 0.3 : 0.8),
                        fontWeight:
                            isSelected ? FontWeight.w900 : FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ).animate(delay: (i * 40).ms).fadeIn().slideY(begin: 0.1, end: 0),
          );
        }),
      ),
    );
  }
}
