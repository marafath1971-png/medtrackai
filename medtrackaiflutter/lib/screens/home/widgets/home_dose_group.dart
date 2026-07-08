import 'package:flutter/material.dart';

import '../../../providers/app_state.dart';
import '../../../services/smart_alert_service.dart';
import '../../../theme/app_theme.dart';
import 'home_dose_row.dart';

class HomeDoseGroup extends StatelessWidget {
  final String title;
  final List<DoseItem> doses;
  final Map<String, bool> takenToday;
  final AppState state;
  final DateTime selectedDate;
  final Function(Medicine) onView;
  final VoidCallback? onTakeDose;

  const HomeDoseGroup({
    super.key,
    required this.title,
    required this.doses,
    required this.takenToday,
    required this.state,
    required this.selectedDate,
    required this.onView,
    this.onTakeDose,
  });

  static String _groupLabel(String title) {
    switch (title.toLowerCase()) {
      case 'morning':
        return '🌅 MORNING';
      case 'afternoon':
        return '☀️ AFTERNOON';
      case 'evening':
        return '🌙 EVENING';
      case 'night':
        return '🌃 NIGHT';
      default:
        return title.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final now = DateTime.now();
    final nowMins = now.hour * 60 + now.minute;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 10, top: 8),
          child: Text(
            _groupLabel(title),
            style: AppTypography.labelSmall.copyWith(
              color: L.sub.withValues(alpha: 0.55),
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 1.6,
            ),
          ),
        ),
        ...doses.map((d) {
          final isTaken = takenToday[d.key] == true;
          final doseMins = d.sched.h * 60 + d.sched.m;
          final isOverdue = !isTaken && doseMins < nowMins;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: HomeDoseRow(
              med: d.med,
              sched: d.sched,
              taken: isTaken,
              overdue: isOverdue,
              onTake: () {
                state.toggleDose(d, date: selectedDate);
                onTakeDose?.call();
                _showUndoSnackbar(context, d);
              },
              onTap: () => onView(d.med),
            ),
          );
        }),
      ],
    );
  }

  void _showUndoSnackbar(BuildContext context, DoseItem d) {
    SmartAlertService.show(
      context,
      title: 'Dose logged',
      message: '${d.med.name} marked as taken.',
      type: AlertType.success,
      icon: Icons.check_circle_rounded,
    );
  }
}
