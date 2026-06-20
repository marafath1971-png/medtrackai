import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../providers/app_state.dart';
import '../../../../theme/app_theme.dart';
import '../../../../core/utils/haptic_engine.dart';

// ══════════════════════════════════════════════
// HOME HEADER — Cal AI 2026 Premium Style
// ══════════════════════════════════════════════
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

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: isScrolled ? 16 : 0,
          sigmaY: isScrolled ? 16 : 0,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
          decoration: BoxDecoration(
            color: isScrolled 
                ? L.bg.withValues(alpha: 0.8) 
                : L.bg.withValues(alpha: 0.0),
            border: Border(
              bottom: BorderSide(
                color: L.border.withValues(
                    alpha: isScrolled ? 0.08 : 0.0),
                width: 0.5,
              ),
            ),
          ),
          child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Row(
          children: [
            // ── Logo + Brand ──
            GestureDetector(
              onTap: () {
                HapticEngine.selection();
                onTap?.call();
              },
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/app_logo.png',
                    width: 32,
                    height: 32,
                  )
                      .animate()
                      .fadeIn(duration: 800.ms, curve: Curves.easeOut)
                      .slideX(begin: -0.2, end: 0, curve: Curves.easeOutBack),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _getGreeting(),
                        style: AppTypography.labelSmall.copyWith(
                          color: L.sub.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                        ),
                      ).animate().fadeIn(duration: 800.ms).slideY(begin: -0.2, end: 0),
                      Text(
                        'Med AI 🧬',
                        style: AppTypography.displaySmall.copyWith(
                          color: L.text,
                          fontWeight: FontWeight.w900,
                          fontSize: 24,
                          letterSpacing: -1.2,
                        ),
                      ).animate().fadeIn(duration: 800.ms, delay: 100.ms).slideY(begin: 0.2, end: 0),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),
            // ── Invite Caregiver (Viral Hook) ──
            GestureDetector(
              onTap: () {
                HapticEngine.selection();
                state.showToast('Invite link copied!');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: L.text.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: L.border.withValues(alpha: 0.1)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.group_add_rounded, size: 14, color: L.sub),
                    const SizedBox(width: 4),
                    Text(
                      'Invite 🚀',
                      style: AppTypography.labelSmall.copyWith(
                        color: L.sub,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // ── Notification Bell ──
            GestureDetector(
              onTap: () {
                HapticEngine.selection();
                onOpenSettings();
              },
              child: Stack(
                children: [
                  Icon(Icons.notifications_none_rounded,
                      size: 26, color: L.text),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                       width: 9,
                       height: 9,
                       decoration: BoxDecoration(
                         color: L.accent, // Theme accent dot
                         shape: BoxShape.circle,
                         border: Border.all(color: L.bg, width: 1.5),
                       ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  ),
);
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'GOOD MORNING ☀️';
    if (hour < 17) return 'GOOD AFTERNOON 🌤️';
    return 'GOOD EVENING 🌙';
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

          return GestureDetector(
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


