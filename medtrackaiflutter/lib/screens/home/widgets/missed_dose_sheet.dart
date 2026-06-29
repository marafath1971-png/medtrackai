import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/app_state.dart';
import '../../../theme/med_ai_ui.dart';
import '../../../services/notification_service.dart';
import '../../../core/utils/haptic_engine.dart';

/// Shows smart guidance when a dose is overdue.
/// Options: Take Now, Skip, Smart Advice.
class MissedDoseProtocolSheet extends StatelessWidget {
  final DoseItem dose;
  final int minutesLate;

  const MissedDoseProtocolSheet({
    super.key,
    required this.dose,
    required this.minutesLate,
  });

  static Future<void> show(
      BuildContext context, DoseItem dose, int minutesLate) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          MissedDoseProtocolSheet(dose: dose, minutesLate: minutesLate),
    );
  }

  Color _guidanceColor() {
    if (minutesLate < 120) return const Color(0xFF10B981);
    if (minutesLate < 360) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final L = context.L;
    final hoursLate = minutesLate ~/ 60;
    final minsLate = minutesLate % 60;
    final guidanceColor = _guidanceColor();

    return Container(
      margin: EdgeInsets.only(
        top: 60,
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: ClipRRect(
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        child: MedAiGlass(
          radius: AppRadius.xl,
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 36),
          showBorder: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 24),
                  decoration: BoxDecoration(
                    color: L.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Row(children: [
                Container(
                  width: MedAiA11y.minTapTarget,
                  height: MedAiA11y.minTapTarget,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppRadius.max),
                  ),
                  child: const Icon(Icons.access_time_rounded,
                      color: Color(0xFFF59E0B), size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(
                        'Missed Dose',
                        style: AppTypography.titleLarge.copyWith(
                            fontWeight: FontWeight.w800,
                            color: L.text,
                            letterSpacing: -0.4),
                      ),
                      Text(
                        '${dose.med.name} · ${dose.sched.label}',
                        style: AppTypography.bodySmall.copyWith(color: L.sub),
                      ),
                    ])),
              ]),

              const SizedBox(height: 20),

              MedAiDepthCard(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                radius: AppRadius.l,
                child: Row(children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: Color(0xFFF59E0B), size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      hoursLate > 0
                          ? 'You are $hoursLate h ${minsLate}m late'
                          : 'You are ${minsLate}m late',
                      style: AppTypography.labelLarge.copyWith(
                          fontWeight: FontWeight.w600, color: L.text),
                    ),
                  ),
                ]),
              ),

              const SizedBox(height: 20),

              MedAiDepthCard(
                color: guidanceColor.withValues(alpha: 0.08),
                padding: const EdgeInsets.all(16),
                radius: AppRadius.l,
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        minutesLate < 120
                            ? Icons.check_circle_rounded
                            : Icons.info_outline_rounded,
                        color: guidanceColor,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Text(
                        state.getDoseGuidance(dose.med),
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w500,
                          color: guidanceColor,
                          height: 1.5,
                        ),
                      )),
                    ]),
              ),

              const SizedBox(height: 24),

              if (minutesLate < 360) ...[
                MedAiCTA(
                  label: minutesLate > 60 ? 'Take It Late Now' : 'Take Now',
                  icon: Icons.medication_rounded,
                  semanticsLabel:
                      'Take ${dose.med.name} now',
                  onTap: () {
                    Navigator.pop(context);
                    state.toggleDose(dose);
                  },
                ),
                const SizedBox(height: 12),
              ],

              _ActionBtn(
                label: 'Remind Me Later',
                icon: Icons.snooze_rounded,
                color: const Color(0xFF8B5CF6),
                onTap: () {
                  Navigator.pop(context);
                  final payloadForSnooze =
                      'take|${dose.med.id}|${dose.sched.h}|${dose.sched.m}|${dose.sched.label}';
                  NotificationService.scheduleOneOffReminder(
                    id: dose.med.id + 500000,
                    title: '⏱️ Rescheduled: ${dose.med.name}',
                    body: 'You asked me to remind you again later.',
                    scheduledDate: DateTime.now().add(const Duration(hours: 1)),
                    payload: payloadForSnooze,
                  );
                  state.showToast('I will remind you again in 1 hour',
                      type: 'info');
                },
              ),
              const SizedBox(height: 12),

              _ActionBtn(
                label: 'Skip Today',
                icon: Icons.skip_next_rounded,
                color: const Color(0xFF6B7280),
                onTap: () {
                  Navigator.pop(context);
                  state.skipDose(dose);
                },
              ),
              const SizedBox(height: 12),
              MedAiCTA(
                label: 'Dismiss',
                secondary: true,
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: MedAiDepthCard(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        radius: AppRadius.max,
        onTap: () {
          HapticEngine.selection();
          onTap();
        },
        color: color.withValues(alpha: 0.08),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Text(
            label,
            style: AppTypography.labelLarge.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ]),
      ),
    );
  }
}
