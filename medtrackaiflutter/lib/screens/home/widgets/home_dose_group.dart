import 'package:flutter/material.dart';

import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/haptic_engine.dart';
import '../../../providers/app_state.dart';
import '../../../services/smart_alert_service.dart';
import '../../../theme/med_ai_ui.dart';
import '../../../widgets/modals/know_your_medicine_sheet.dart';
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

  static ({String label, IconData icon, Color tint, Color ink}) _periodStyle(
    String title,
  ) {
    switch (title.toLowerCase()) {
      case 'morning':
        return (
          label: 'Morning',
          icon: Icons.wb_sunny_rounded,
          tint: AppColors.pastelSun,
          ink: const Color(0xFF8A6A1A),
        );
      case 'afternoon':
        return (
          label: 'Afternoon',
          icon: Icons.light_mode_rounded,
          tint: AppColors.pastelMint,
          ink: AppColors.limeInk,
        );
      case 'evening':
        return (
          label: 'Evening',
          icon: Icons.wb_twilight_rounded,
          tint: AppColors.pastelSky,
          ink: const Color(0xFF2F5F7A),
        );
      case 'night':
        return (
          label: 'Night',
          icon: Icons.nights_stay_rounded,
          tint: const Color(0xFFE8E4F5),
          ink: const Color(0xFF4A3F6B),
        );
      default:
        return (
          label: title,
          icon: Icons.schedule_rounded,
          tint: AppColors.pastelMint,
          ink: AppColors.inkStrong,
        );
    }
  }

  Future<void> _handleTake(
    BuildContext context,
    DoseItem d,
    bool isTaken,
  ) async {
    if (isTaken) {
      HapticEngine.selection();
      state.toggleDose(d, date: selectedDate);
      onTakeDose?.call();
      return;
    }

    final ok = await KnowYourMedicineSheet.confirmTake(
      context,
      med: d.med,
      doseTimeLabel: fmtTime(d.sched.h, d.sched.m, context),
    );
    if (!ok || !context.mounted) return;

    state.toggleDose(d, date: selectedDate);
    onTakeDose?.call();
    _showUndoSnackbar(context, d);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final nowMins = now.hour * 60 + now.minute;
    final style = _periodStyle(title);
    final takenCount =
        doses.where((d) => takenToday[d.key] == true).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.p12, bottom: AppSpacing.p8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: style.tint,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(style.icon, size: 14, color: style.ink),
                    const SizedBox(width: 6),
                    Text(
                      style.label,
                      style: AppTypography.labelMedium.copyWith(
                        color: style.ink,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$takenCount/${doses.length}',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.grey600,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        ...doses.map((d) {
          final isTaken = takenToday[d.key] == true;
          final doseMins = d.sched.h * 60 + d.sched.m;
          final isOverdue = !isTaken && doseMins < nowMins;

          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.p8),
            child: HomeDoseRow(
              med: d.med,
              sched: d.sched,
              taken: isTaken,
              overdue: isOverdue,
              onTake: () => _handleTake(context, d, isTaken),
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
