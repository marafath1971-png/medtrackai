import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../providers/app_state.dart';
import '../../../theme/med_ai_ui.dart';
import '../../../core/utils/haptic_engine.dart';
import '../../../widgets/common/animated_pressable.dart';

class DuolingoTopBar extends StatelessWidget {
  final AppState state;
  final int streak;
  final double scrollOffset;
  final VoidCallback onOpenStreak;
  final VoidCallback onOpenSettings;
  final VoidCallback? onTap;

  const DuolingoTopBar({
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
    
    // In Duolingo, the top bar often has the language flag, streak, gems, and hearts.
    // For Med AI: Profile switcher, Streak, Adherence Hearts

    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      decoration: BoxDecoration(
        color: isScrolled ? (context.isDark ? L.bg : Colors.white) : Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: L.border.withValues(alpha: isScrolled ? 0.10 : 0.0),
            width: 1,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Profile switcher / Flag equivalent
            AnimatedPressable(
              onTap: () {
                HapticEngine.selection();
                onTap?.call();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: L.border.withValues(alpha: 0.3), width: 2),
                ),
                child: Row(
                  children: [
                    Icon(Icons.face_rounded, color: L.sub, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      'Profile',
                      style: AppTypography.labelLarge.copyWith(
                        color: L.sub,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Streak
            AnimatedPressable(
              onTap: () {
                HapticEngine.selection();
                onOpenStreak();
              },
              child: Row(
                children: [
                  Icon(
                    Icons.local_fire_department_rounded, 
                    color: Colors.orange.shade500, 
                    size: 26,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    streak.toString(),
                    style: AppTypography.labelLarge.copyWith(
                      color: Colors.orange.shade500,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            
            // Hearts / Health
            AnimatedPressable(
              onTap: () {
                HapticEngine.selection();
                onOpenSettings();
              },
              child: Row(
                children: [
                  Icon(
                    Icons.favorite_rounded, 
                    color: Colors.red.shade400, 
                    size: 26,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '5', // E.g. 5 hearts full
                    style: AppTypography.labelLarge.copyWith(
                      color: Colors.red.shade400,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
