import 'package:flutter/material.dart';

import '../../../core/utils/haptic_engine.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/shared/shared_widgets.dart';

// ─────────────────────────────────────────────────────────────
// DAY TOGGLE — Cal AI style Today/Yesterday switcher.
// Extracted verbatim from home_tab.dart (was _DayToggle).
// ─────────────────────────────────────────────────────────────
class DayToggle extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onChanged;

  const DayToggle(
      {super.key, required this.selectedDate, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final isToday = selectedDate.year == today.year &&
        selectedDate.month == today.month &&
        selectedDate.day == today.day;

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: L.fill,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: L.border.withValues(alpha: 0.5),
          width: 1.0,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final halfWidth = constraints.maxWidth / 2;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutBack,
                top: 4,
                bottom: 4,
                left: isToday ? 4 : halfWidth,
                width: halfWidth - 4,
                child: Container(
                  decoration: BoxDecoration(
                    color: L.accent,
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: AnimatedPressable(
                      onTap: () {
                        HapticEngine.selection();
                        onChanged(today);
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 250),
                          style: AppTypography.labelLarge.copyWith(
                            color:
                                isToday ? Colors.white : L.sub,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          child: const Text('Today'),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: AnimatedPressable(
                      onTap: () {
                        HapticEngine.selection();
                        onChanged(yesterday);
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 250),
                          style: AppTypography.labelLarge.copyWith(
                            color:
                                !isToday ? Colors.white : L.sub,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          child: const Text('Yesterday'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
