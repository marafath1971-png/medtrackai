import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../core/utils/haptic_engine.dart';
import '../../widgets/common/app_loading_indicator.dart';
import '../../services/gemini_service.dart';
import '../../widgets/shared/shared_widgets.dart';

// ══════════════════════════════════════════════
// MISSED DOSE PROTOCOL SHEET
// ══════════════════════════════════════════════
//
// Shows an AI-powered recommendation when a user taps an overdue or missed
// dose card. Asks Gemini whether to take, skip, or adjust based on the
// medicine type and how much time has passed.

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
    if (schedule.isEmpty) return 480; // Default 8h

    final nowDateTime = DateTime.now();
    final nowM = nowDateTime.hour * 60 + nowDateTime.minute;
    final schedM = dose.sched.h * 60 + dose.sched.m;

    // Find the next schedule entry after the missed one
    final futureEntries = schedule
        .where((s) => (s.h * 60 + s.m) > schedM)
        .map((s) => (s.h * 60 + s.m).toInt())
        .toList()
      ..sort();

    if (futureEntries.isNotEmpty) {
      return futureEntries.first - nowM;
    }

    // Wrap around to next day — smallest time slot + 1440 - now
    final allMins = schedule.map((s) => (s.h * 60 + s.m).toInt()).toList()
      ..sort();
    return allMins.first + 1440 - nowM;
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final med = widget.dose.med;
    final isOverdue = widget.minutesMissedBy <= 120;
    final statusColor = isOverdue ? L.amber : L.red;
    final statusLabel = isOverdue ? 'OVERDUE' : 'MISSED';
    final statusEmoji = isOverdue ? '⏰' : '😔';
    final schedTime =
        '${widget.dose.sched.h}:${widget.dose.sched.m.toString().padLeft(2, '0')}';

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          padding: EdgeInsets.fromLTRB(
              24, 16, 24, MediaQuery.of(context).padding.bottom + 24),
          decoration: BoxDecoration(
            color: L.meshBg.withValues(alpha: 0.85),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border(
              top: BorderSide(color: L.border.withValues(alpha: 0.1), width: 1.0),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: L.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Header
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
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
              ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                    begin: const Offset(1.0, 1.0),
                    end: const Offset(1.1, 1.1),
                    duration: 1500.ms,
                    curve: Curves.easeInOut,
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
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(statusLabel,
                              style: AppTypography.labelSmall.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: statusColor,
                                  letterSpacing: 0.5)),
                        ),
                        const SizedBox(width: 8),
                        Text('was $schedTime',
                            style: AppTypography.labelMedium.copyWith(
                                fontFamily: 'Courier',
                                fontSize: 13,
                                color: L.sub,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(med.name,
                        style: AppTypography.titleLarge.copyWith(
                            color: L.text,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4)),
                    Text('${med.dose} · ${med.frequency}',
                        style: AppTypography.bodySmall.copyWith(
                            fontSize: 13,
                            color: L.sub,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // AI Advice card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  L.secondary.withValues(alpha: 0.1),
                  L.secondary.withValues(alpha: 0.02),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: L.secondary.withValues(alpha: 0.3), width: 1),
              boxShadow: [
                BoxShadow(
                  color: L.secondary.withValues(alpha: 0.05),
                  blurRadius: 20,
                )
              ],
            ),
            child: _loading
                ? Row(
                    children: [
                      const AppLoadingIndicator(size: 16),
                      const SizedBox(width: 12),
                      Text('PHARMACIST AI THINKING...',
                          style: AppTypography.labelSmall.copyWith(
                              color: L.secondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.0)),
                    ],
                  ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(duration: 800.ms)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.auto_awesome_rounded,
                              size: 16, color: L.secondary),
                          const SizedBox(width: 8),
                          Text('AI ADVICE',
                              style: AppTypography.labelSmall.copyWith(
                                  fontSize: 10,
                                  color: L.secondary,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2.0)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(_aiAdvice ?? '',
                          style: AppTypography.bodyLarge.copyWith(
                              color: L.text,
                              fontSize: 15,
                              height: 1.5,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
          ).animate().fadeIn().slideY(begin: 0.05),

          const SizedBox(height: 12),

          // Safety disclaimer
          Text(
            '⚠️ Informational only. Always consult your doctor or pharmacist for advice.',
            style: AppTypography.bodySmall.copyWith(
                fontSize: 10,
                color: L.sub,
                fontStyle: FontStyle.italic,
                height: 1.4),
          ),

          const SizedBox(height: 20),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: BouncingButton(
                  onTap: () {
                    final state = context.read<AppState>();
                    state.skipDose(widget.dose);
                    HapticEngine.selection();
                    Navigator.pop(context);
                  },
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: L.fill,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text('SKIP DOSE',
                          style: AppTypography.labelSmall.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                              color: L.text)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: BouncingButton(
                  onTap: () {
                    final state = context.read<AppState>();
                    state.toggleDose(widget.dose);
                    HapticEngine.heavyImpact();
                    Navigator.pop(context);
                  },
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: L.text,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: L.text.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        )
                      ],
                    ),
                    child: Center(
                      child: Text('TAKE NOW',
                          style: AppTypography.labelSmall.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                              color: L.bg)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    )))
        .animate()
        .slideY(begin: 0.15, end: 0, duration: 400.ms, curve: Curves.easeOutCubic);
  }
}
