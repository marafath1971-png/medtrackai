import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../models/models.dart';
import '../../../theme/med_ai_ui.dart';
import '../../../core/utils/haptic_engine.dart';
import '../../../widgets/common/app_scaffold.dart';
import '../../../widgets/common/premium_page_header.dart';

class AlertLogCard extends StatelessWidget {
  final MissedAlert alert;
  final AppThemeColors L;
  final VoidCallback onTap;
  const AlertLogCard(
      {super.key, required this.alert, required this.L, required this.onTap});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.p12),
        child: Semantics(
        button: true,
        label: 'Missed dose alert for ${alert.medName}',
        child: MedAiDepthCard(
          padding: const EdgeInsets.all(AppSpacing.p16),
          accentGlow: !alert.seen,
          onTap: () {
            HapticEngine.light();
            onTap();
          },
          child: Row(children: [
            Container(
              width: MedAiA11y.minTapTargetCompact,
              height: MedAiA11y.minTapTargetCompact,
              decoration: BoxDecoration(
                  color: L.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12)),
              child: Center(
                  child: Icon(Icons.error_outline_rounded,
                      color: L.error, size: 22)),
            ),
            const SizedBox(width: AppSpacing.p16),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(alert.medName,
                      style: AppTypography.titleLarge.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: L.text),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1),
                  const SizedBox(height: 2),
                  Text('Missed ${alert.doseLabel} at ${alert.time}',
                      style: AppTypography.bodySmall.copyWith(
                          color: L.sub,
                          fontWeight: FontWeight.w600,
                          fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1),
                ])),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!alert.seen)
                  Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.p8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.p8, vertical: 3),
                    decoration: BoxDecoration(
                        color: L.fill.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(99)),
                    child: Text('New',
                        style: TextStyle(
                            color: L.sub,
                            fontSize: 10,
                            fontWeight: FontWeight.w600)),
                  ),
                Text(alert.timestamp.split(',').first,
                    style: AppTypography.labelLarge.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: L.sub.withValues(alpha: 0.6))),
              ],
            ),
            const SizedBox(width: AppSpacing.p8),
            Icon(Icons.chevron_right_rounded,
                color: L.sub.withValues(alpha: 0.3), size: 18),
          ]),
        ),
      ),
    );
}

class EscalationDemoView extends StatefulWidget {
  final AppThemeColors L;
  final VoidCallback onBack;
  const EscalationDemoView({super.key, required this.L, required this.onBack});
  @override
  State<EscalationDemoView> createState() => _EscalationDemoViewState();
}

class _EscalationDemoViewState extends State<EscalationDemoView> {
  int _step = 1;
  @override
  Widget build(BuildContext context) {
    final L = widget.L;
    return AppScaffold(
      showAurora: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PremiumPageHeader(
            title: 'Escalation protocol',
            subtitle: 'Missed dose safety simulation',
            onBack: () {
              HapticEngine.selection();
              widget.onBack();
            },
          ),
          Expanded(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.all(AppSpacing.p24),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        'Safety simulation of how missed doses trigger household alerts.',
                        style: AppTypography.bodySmall
                            .copyWith(color: L.sub, fontSize: 14)),
                    const SizedBox(height: AppSpacing.p32),
                    EscalationTimeline(activeStep: _step, L: L),
                    const SizedBox(height: AppSpacing.p40),
                    Row(children: [
                      Expanded(
                        child: MedAiCTA(
                          label: 'Previous',
                          secondary: true,
                          fullWidth: true,
                          enabled: _step > 1,
                          onTap: _step <= 1
                              ? null
                              : () => setState(() => _step--),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.p12),
                      Expanded(
                          flex: 2,
                          child: MedAiCTA(
                            label: _step >= 4 ? 'Completed' : 'Next Step',
                            enabled: _step < 4,
                            onTap: _step >= 4
                                ? null
                                : () {
                                    setState(() => _step++);
                                    if (_step == 4) {
                                      HapticEngine.heavy();
                                    }
                                  },
                          )),
                    ]),
                    if (_step == 4) ...[
                      const SizedBox(height: AppSpacing.p24),
                      _buildCriticalAlertCard(L),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildCriticalAlertCard(AppThemeColors L) {
    final reduceMotion = MedAiA11y.reducedMotion(context);
    Widget card = MedAiDepthCard(
      padding: const EdgeInsets.all(AppSpacing.p20),
      accentGlow: true,
      color: const Color(0xFF1C1917),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          children: [
            const Icon(Icons.campaign_rounded,
                color: Color(0xFFFCA5A5), size: 20),
            const SizedBox(width: AppSpacing.p12),
            Text('Critical alert sent',
                style: AppTypography.labelLarge.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFFCA5A5))),
          ],
        ),
        const SizedBox(height: AppSpacing.p12),
        Text(
            'Sarah J. missed their Blood Pressure medication. Please check on them immediately.',
            style: AppTypography.bodySmall.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                height: 1.5)),
      ]),
    );
    if (!reduceMotion) {
      card = card.animate().scale(curve: Curves.easeOutBack);
    }
    return card;
  }
}

class EscalationTimeline extends StatelessWidget {
  final int activeStep;
  final AppThemeColors L;
  const EscalationTimeline(
      {super.key, required this.activeStep, required this.L});
  @override
  Widget build(BuildContext context) {
    final steps = [
      {
        'title': 'Dose Scheduled',
        'detail': 'System awaits confirmation',
        'icon': '⏰',
        'color': L.text
      },
      {
        'title': 'Dose Overdue',
        'detail': 'User receives nudge',
        'icon': '🔔',
        'color': const Color(0xFFF59E0B)
      },
      {
        'title': 'Grace Period Ends',
        'detail': '30 min monitoring window closed',
        'icon': '⏳',
        'color': const Color(0xFFF97316)
      },
      {
        'title': 'Household Alert',
        'detail': 'Push notifications to guardians',
        'icon': '📢',
        'color': L.error
      },
    ];
    return Column(
      children: List.generate(steps.length, (i) {
        final isActive = activeStep > i;
        final isCurrent = activeStep == i + 1;
        final isLast = i == steps.length - 1;
        final color = steps[i]['color'] as Color;
        return IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Column(children: [
              AnimatedContainer(
                duration: MedAiA11y.motion(context, AppDurations.medium),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                    color: isActive ? color : L.fill,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color:
                            isCurrent ? color : (isActive ? color : L.border),
                        width: 2.5)),
                child: Center(
                    child: Text(steps[i]['icon'] as String,
                        style: const TextStyle(fontSize: 16))),
              ),
              if (!isLast)
                Expanded(
                    child: Container(
                        width: 2,
                        color:
                            isActive ? color.withValues(alpha: 0.4) : L.border,
                        margin: const EdgeInsets.symmetric(vertical: AppSpacing.p4))),
            ]),
            const SizedBox(width: AppSpacing.p20),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 28),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(steps[i]['title'] as String,
                          style: AppTypography.labelLarge.copyWith(
                              fontSize: 15,
                              fontWeight:
                                  isCurrent ? FontWeight.w800 : FontWeight.w700,
                              color: isActive ? L.text : L.sub)),
                      const SizedBox(height: 2),
                      Text(steps[i]['detail'] as String,
                          style: AppTypography.bodySmall
                              .copyWith(color: L.sub, fontSize: 12)),
                    ]),
              ),
            ),
          ]),
        );
      }),
    );
  }
}

class AlertDetailView extends StatelessWidget {
  final MissedAlert alert;
  final AppThemeColors L;
  final VoidCallback onBack;
  const AlertDetailView(
      {super.key, required this.alert, required this.L, required this.onBack});
  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      showAurora: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PremiumPageHeader(
            title: 'Critical alert',
            subtitle: alert.medName,
            onBack: () {
              HapticEngine.selection();
              onBack();
            },
          ),
          Expanded(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.all(AppSpacing.p24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
            MedAiDepthCard(
              padding: const EdgeInsets.all(AppSpacing.p24),
              accentGlow: true,
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                        color: L.error.withValues(alpha: 0.1),
                        shape: BoxShape.circle),
                    child: Center(
                        child: Icon(Icons.warning_rounded,
                            color: L.error, size: 32)),
                  ),
                  const SizedBox(height: AppSpacing.p20),
                  Text(alert.medName,
                      style: AppTypography.displayLarge.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: L.text)),
                  const SizedBox(height: AppSpacing.p4),
                  Text('Missed ${alert.doseLabel} at ${alert.time}',
                      style: AppTypography.bodySmall.copyWith(
                          fontSize: 15,
                          color: L.sub,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: AppSpacing.p24),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    _Badge(label: 'Critical', color: L.error),
                    const SizedBox(width: AppSpacing.p8),
                    _Badge(
                        label: alert.timestamp.split(',').first, color: L.sub),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.p32),
            const MedAiSectionHeader(title: 'Safety protocol'),
            const SizedBox(height: AppSpacing.p16),
            EscalationTimeline(activeStep: 4, L: L),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p12, vertical: AppSpacing.p4),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8)),
        child: Text(label,
            style: AppTypography.labelLarge.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color)),
      );
}
