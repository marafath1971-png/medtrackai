import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/haptic_engine.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/common/animated_pressable.dart';

/// Reference-style week picker — month title + 7 day pills.
class HomeWeekStrip extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onChanged;

  const HomeWeekStrip({
    super.key,
    required this.selectedDate,
    required this.onChanged,
  });

  DateTime _weekStart(DateTime anchor) {
    final d = DateTime(anchor.year, anchor.month, anchor.day);
    return d.subtract(Duration(days: d.weekday % 7));
  }

  void _shiftWeek(BuildContext context, int delta) {
    HapticEngine.selection();
    final next = selectedDate.add(Duration(days: delta * 7));
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final start = _weekStart(selectedDate);
    final days = List.generate(7, (i) => start.add(Duration(days: i)));
    final monthLabel = DateFormat('MMMM yyyy').format(selectedDate);
    const dow = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                monthLabel,
                style: AppTypography.titleMedium.copyWith(
                  color: L.text,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            _ArrowBtn(
              icon: Icons.chevron_left_rounded,
              onTap: () => _shiftWeek(context, -1),
            ),
            const SizedBox(width: 4),
            _ArrowBtn(
              icon: Icons.chevron_right_rounded,
              onTap: () => _shiftWeek(context, 1),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(7, (i) {
            final day = days[i];
            final isSelected = day.year == selectedDate.year &&
                day.month == selectedDate.month &&
                day.day == selectedDate.day;
            final isToday = _isToday(day);

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i < 6 ? 8 : 0),
                child: AnimatedPressable(
                  onTap: () {
                    HapticEngine.selection();
                    onChanged(day);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFFB9EA6E),
                                Color(0xFF9ADA4B),
                              ],
                            )
                          : null,
                      color: isSelected ? null : L.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : L.border.withValues(alpha: 0.12),
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.limeDeep
                                    .withValues(alpha: 0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          dow[i],
                          style: AppTypography.labelSmall.copyWith(
                            color: isSelected
                                ? AppColors.limeInk
                                : L.sub.withValues(alpha: 0.65),
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          day.day.toString().padLeft(2, '0'),
                          style: AppTypography.labelLarge.copyWith(
                            color: isSelected
                                ? AppColors.limeInk
                                : L.text.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        if (isToday && !isSelected)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.limeDeep,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  bool _isToday(DateTime day) {
    final now = DateTime.now();
    return day.year == now.year &&
        day.month == now.month &&
        day.day == now.day;
  }
}

class _ArrowBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ArrowBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return AnimatedPressable(
      onTap: onTap,
      child: SizedBox(
        width: 36,
        height: 36,
        child: Icon(icon, size: 22, color: L.sub.withValues(alpha: 0.7)),
      ),
    );
  }
}
