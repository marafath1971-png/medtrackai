import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../theme/med_ai_ui.dart';
import '../../core/utils/haptic_engine.dart';
import '../../widgets/common/app_loading_indicator.dart';
import '../../services/gemini_service.dart';
import '../common/refined_sheet_wrapper.dart';

// ══════════════════════════════════════════════
// MISSED DOSE PROTOCOL SHEET — AI-powered guidance
// ══════════════════════════════════════════════

class MissedDoseProtocolSheet extends StatefulWidget {
  final DoseItem dose;
  final int minutesMissedBy;

  const MissedDoseProtocolSheet({
    super.key,
    required this.dose,
    required this.minutesMissedBy,
  });

  static Future<void> show(
      BuildContext context, DoseItem dose, int minutesMissedBy) {
    HapticEngine.selection();
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => MissedDoseProtocolSheet(
        dose: dose,
        minutesMissedBy: minutesMissedBy,
      ),
    );
  }

  @override
  State<MissedDoseProtocolSheet> createState() =>
      _MissedDoseProtocolSheetState();
}

class _MissedDoseProtocolSheetState extends State<MissedDoseProtocolSheet> {
  String? _aiAdvice;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAdvice();
  }

  Future<void> _loadAdvice() async {
    final state = context.read<AppState>();
    final dose = widget.dose;
    final minutesMissedBy = widget.minutesMissedBy;
    final nextDoseInMinutes = _findNextDoseMinutes(dose, state);

    final advice = await GeminiService.getMissedDoseAdvice(
      med: dose.med,
      minutesMissedBy: minutesMissedBy,
      nextDoseInMinutes: nextDoseInMinutes,
    );

    if (mounted) {
      setState(() {
        _aiAdvice = advice;
        _loading = false;
      });
    }
  }

  int _findNextDoseMinutes(DoseItem dose, AppState state) {
    final schedule = dose.med.schedule;
    if (schedule.isEmpty) return 480;

    final nowDateTime = DateTime.now();
    final nowM = nowDateTime.hour * 60 + nowDateTime.minute;
    final schedM = dose.sched.h * 60 + dose.sched.m;

    final futureEntries = schedule
        .where((s) => (s.h * 60 + s.m) > schedM)
        .map((s) => (s.h * 60 + s.m).toInt())
        .toList()
      ..sort();

    if (futureEntries.isNotEmpty) {
      return futureEntries.first - nowM;
    }

    final allMins = schedule.map((s) => (s.h * 60 + s.m).toInt()).toList()
      ..sort();
    return allMins.first + 1440 - nowM;
  }

  Widget _adviceEntrance(Widget child) {
    if (MedAiA11y.reducedMotion(context)) return child;
    return child
        .animate()
        .fadeIn(duration: AppDurations.fast, curve: AppCurves.smooth)
        .slideY(begin: 0.04, end: 0, curve: AppCurves.smooth);
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final med = widget.dose.med;
    final reduceMotion = MedAiA11y.reducedMotion(context);
    final isOverdue = widget.minutesMissedBy <= 120;
    final statusColor = isOverdue ? L.amber : L.red;
    final statusLabel = isOverdue ? 'OVERDUE' : 'MISSED';
    final statusEmoji = isOverdue ? '⏰' : '😔';
    final schedTime =
        '${widget.dose.sched.h}:${widget.dose.sched.m.toString().padLeft(2, '0')}';

    Widget statusIcon = Container(
      width: MedAiA11y.minTapTarget + 16,
      height: MedAiA11y.minTapTarget + 16,
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(statusEmoji,
            style: AppTypography.displaySmall.copyWith(fontSize: 28)),
      ),
    );

    if (!reduceMotion) {
      statusIcon = statusIcon
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(1.0, 1.0),
            end: const Offset(1.06, 1.06),
            duration: 1500.ms,
            curve: Curves.easeInOut,
          );
    }

    return RefinedSheetWrapper(
      scrollable: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Semantics(
                label: '$statusLabel dose for ${med.name}',
                child: statusIcon,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppRadius.s),
                          ),
                          child: Text(
                            statusLabel,
                            style: AppTypography.labelSmall.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: statusColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'was $schedTime',
                          style: AppTypography.labelMedium.copyWith(
                            fontFamily: 'Courier',
                            fontSize: 13,
                            color: L.sub,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      med.name,
                      style: AppTypography.titleLarge.copyWith(
                        color: L.text,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                    Text(
                      '${med.dose} · ${med.frequency}',
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 13,
                        color: L.sub,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _adviceEntrance(
            Semantics(
              label: _loading
                  ? 'Loading AI advice'
                  : 'AI advice: ${_aiAdvice ?? ''}',
              liveRegion: true,
              child: MedAiDepthCard(
                padding: const EdgeInsets.all(20),
                radius: AppRadius.xl,
                color: L.secondary.withValues(alpha: 0.06),
                accentGlow: false,
                child: _loading
                    ? Row(
                        children: [
                          const AppLoadingIndicator(size: 16),
                          const SizedBox(width: 12),
                          Text(
                            'Pharmacist AI thinking...',
                            style: AppTypography.labelSmall.copyWith(
                              color: L.secondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.auto_awesome_rounded,
                                  size: 16, color: L.secondary),
                              const SizedBox(width: 8),
                              Text(
                                'AI ADVICE',
                                style: AppTypography.labelSmall.copyWith(
                                  fontSize: 10,
                                  color: L.secondary,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2.0,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _aiAdvice ?? '',
                            style: AppTypography.bodyLarge.copyWith(
                              color: L.text,
                              fontSize: 15,
                              height: 1.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Semantics(
            label:
                'Informational only. Always consult your doctor or pharmacist for advice.',
            child: Text(
              '⚠️ Informational only. Always consult your doctor or pharmacist for advice.',
              style: AppTypography.bodySmall.copyWith(
                fontSize: 10,
                color: L.sub,
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: MedAiCTA(
                  label: 'Skip Dose',
                  secondary: true,
                  fullWidth: true,
                  semanticsLabel: 'Skip ${med.name} dose',
                  onTap: () {
                    final state = context.read<AppState>();
                    state.skipDose(widget.dose);
                    HapticEngine.selection();
                    Navigator.pop(context);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: MedAiCTA(
                  label: 'Take Now',
                  icon: Icons.medication_rounded,
                  fullWidth: true,
                  semanticsLabel: 'Take ${med.name} now',
                  onTap: () {
                    final state = context.read<AppState>();
                    state.toggleDose(widget.dose);
                    HapticEngine.heavyImpact();
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
