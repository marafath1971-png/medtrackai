import 'package:flutter/material.dart';

import '../../../core/utils/haptic_engine.dart';
import '../../../providers/app_state.dart';
import '../../../theme/med_ai_ui.dart';
import '../../../widgets/common/animated_pressable.dart';

// ══════════════════════════════════════════════════════════════
// CAREGIVER ESCALATION — the two ends of the missed-dose chain
//
// Patient side: which medicines alert the circle, and in what order the
// circle hears (AlertCoverageCard). Caregiver side: the alerts that reached
// me, with "I'm on it" to stop the chain (CaregiverAlertsCard).
// ══════════════════════════════════════════════════════════════

/// "right away", "after 15 min", "after 1 hr" — for a caregiver's delay.
String alertDelayLabel(int minutes) {
  if (minutes <= 0) return 'right away';
  if (minutes % 60 == 0) {
    final h = minutes ~/ 60;
    return 'after $h hr';
  }
  return 'after $minutes min';
}

/// The active caregivers in the order the server alerts them.
///
/// Mirrors `resolveCaregivers` in functions/missed_dose_rules.js: quickest
/// delay first. Kept in one place so the chain shown to the patient is the
/// chain the server runs.
List<Caregiver> escalationOrder(List<Caregiver> caregivers) =>
    caregivers.where((c) => c.status == 'active').toList()
      ..sort((a, b) => a.alertDelay.compareTo(b.alertDelay));

/// Patient-side summary of who hears about a missed dose, and for what.
///
/// Missed-dose alerts only cover medicines flagged [Medicine.isCritical], and
/// until this card existed nothing in the app could set that flag — so the
/// server's passive detector had nothing to watch. This is where it is set.
class AlertCoverageCard extends StatelessWidget {
  final AppState state;
  const AlertCoverageCard({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final chain = escalationOrder(state.caregivers);
    if (chain.isEmpty) return const SizedBox.shrink();

    final meds = state.meds;
    final covered = meds.where((m) => m.isCritical).length;
    final none = covered == 0;

    return Semantics(
      button: true,
      label: none
          ? 'Missed-dose alerts are off. Choose medicines.'
          : 'Missed-dose alerts cover $covered of ${meds.length} medicines. Edit.',
      child: AnimatedPressable(
        onTap: () {
          HapticEngine.selection();
          AlertCoverageSheet.show(context, state);
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.p24),
          padding: const EdgeInsets.all(AppSpacing.p16),
          decoration: BoxDecoration(
            color: none
                ? (context.isDark
                    ? AppColors.amber.withValues(alpha: 0.16)
                    : AppColors.pastelSun)
                : L.card,
            borderRadius: BorderRadius.circular(AppRadius.l),
            border: Border.all(color: L.border.withValues(alpha: 0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    none
                        ? Icons.notifications_off_rounded
                        : Icons.notifications_active_rounded,
                    color: none ? AppColors.amber : AppColors.limeDeep,
                    size: 22,
                  ),
                  const SizedBox(width: AppSpacing.p12),
                  Expanded(
                    child: Text(
                      none
                          ? 'Missed-dose alerts are off'
                          : 'Alerts cover $covered of ${meds.length} medicines',
                      style: AppTypography.titleMedium.copyWith(
                        color: L.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: L.sub),
                ],
              ),
              const SizedBox(height: AppSpacing.p8),
              Text(
                none
                    ? 'Your circle is connected but won\'t hear about a missed '
                        'dose until you choose which medicines matter.'
                    : 'If one of these is still untaken, your circle hears in '
                        'this order until someone says they\'re on it:',
                style: AppTypography.bodySmall.copyWith(
                  color: L.sub,
                  height: 1.4,
                ),
              ),
              if (!none) ...[
                const SizedBox(height: AppSpacing.p12),
                _ChainRow(chain: chain),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ChainRow extends StatelessWidget {
  final List<Caregiver> chain;
  const _ChainRow({required this.chain});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final children = <Widget>[];
    for (var i = 0; i < chain.length; i++) {
      final cg = chain[i];
      if (i > 0) {
        children.add(Icon(Icons.arrow_forward_rounded,
            size: 14, color: L.sub.withValues(alpha: 0.7)));
      }
      children.add(Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: L.fill,
          borderRadius: BorderRadius.circular(AppRadius.max),
        ),
        child: Text(
          '${cg.name.isEmpty ? 'Caregiver' : cg.name} · '
          '${alertDelayLabel(cg.alertDelay)}',
          style: AppTypography.labelSmall.copyWith(
            color: L.text,
            fontWeight: FontWeight.w600,
          ),
        ),
      ));
    }
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: children,
    );
  }
}

/// Per-medicine switches for [Medicine.isCritical].
class AlertCoverageSheet extends StatelessWidget {
  final AppState state;
  const AlertCoverageSheet({super.key, required this.state});

  static Future<void> show(BuildContext context, AppState state) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AlertCoverageSheet(state: state),
    );
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final meds = state.meds;
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.8,
          ),
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.p24, AppSpacing.p12, AppSpacing.p24, AppSpacing.p24),
          decoration: BoxDecoration(
            color: L.card,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: L.border.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.p20),
                Text(
                  'Alert my circle for…',
                  style: AppTypography.titleLarge.copyWith(
                    color: L.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.p8),
                Text(
                  'Pick the medicines where a missed dose matters. Alerts '
                  'only go out between 7am and 11pm your time, and stop as '
                  'soon as you log the dose.',
                  style: AppTypography.bodySmall.copyWith(
                    color: L.sub,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.p16),
                if (meds.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'Add a medicine first — then choose whether it alerts '
                      'your circle.',
                      style: AppTypography.bodyMedium.copyWith(color: L.sub),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: meds.length,
                      separatorBuilder: (_, __) => Divider(
                          height: 1, color: L.border.withValues(alpha: 0.3)),
                      itemBuilder: (context, i) {
                        final m = meds[i];
                        return SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          value: m.isCritical,
                          activeTrackColor: AppColors.limeDeep,
                          title: Text(
                            m.name,
                            style: AppTypography.bodyMedium.copyWith(
                              color: L.text,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: m.dose.isEmpty
                              ? null
                              : Text(m.dose,
                                  style: AppTypography.labelSmall
                                      .copyWith(color: L.sub)),
                          onChanged: (v) {
                            HapticEngine.selection();
                            state.updateMedicine(m.copyWith(isCritical: v));
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Caregiver side: missed doses that reached me, newest open ones first.
class CaregiverAlertsCard extends StatelessWidget {
  final AppState state;
  const CaregiverAlertsCard({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final alerts = state.escalations;
    if (alerts.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.p24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MedAiSectionHeader(
            title: 'Missed doses',
            subtitle: alerts.any((a) => !a.isAcknowledged)
                ? 'Someone needs checking on'
                : 'All handled',
          ),
          for (final a in alerts) _EscalationRow(alert: a, state: state),
        ],
      ),
    );
  }
}

class _EscalationRow extends StatelessWidget {
  final EscalationAlert alert;
  final AppState state;
  const _EscalationRow({required this.alert, required this.state});

  Future<void> _claim(BuildContext context) async {
    HapticEngine.medium();
    try {
      final already = await state.social.acknowledgeEscalation(alert.id);
      state.showToast(already == null
          ? 'Your circle knows you\'re on it'
          : '$already is already on it');
    } catch (_) {
      state.showToast(
          'Couldn\'t reach the server — your circle was not told. Try again.',
          type: 'error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final done = alert.isAcknowledged;
    final busy = state.social.isAcknowledging(alert.id);
    final escalated = alert.reached > 1;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.p12),
      padding: const EdgeInsets.all(AppSpacing.p16),
      decoration: BoxDecoration(
        color: done
            ? L.card
            : (context.isDark
                ? AppColors.red.withValues(alpha: 0.14)
                : const Color(0xFFFFEEEC)),
        borderRadius: BorderRadius.circular(AppRadius.l),
        border: Border.all(color: L.border.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                done ? Icons.check_circle_rounded : Icons.error_rounded,
                color: done ? AppColors.limeDeep : AppColors.red,
                size: 22,
              ),
              const SizedBox(width: AppSpacing.p12),
              Expanded(
                child: Text(
                  '${alert.displayName} · ${alert.medName}',
                  style: AppTypography.titleMedium.copyWith(
                    color: L.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            done
                ? '${alert.acknowledgedByName ?? 'Someone'} is on it'
                    '${alert.time.isEmpty ? '' : ' · dose was due ${alert.time}'}'
                : 'Not taken${alert.time.isEmpty ? '' : ' — due ${alert.time}'}'
                    '${escalated ? ' · ${alert.reached} people alerted, no one has checked in' : ''}',
            style: AppTypography.bodySmall.copyWith(color: L.sub, height: 1.4),
          ),
          if (!done) ...[
            const SizedBox(height: AppSpacing.p12),
            MedAiCTA(
              label: 'I\'m on it',
              icon: Icons.front_hand_rounded,
              loading: busy,
              onTap: busy ? null : () => _claim(context),
              semanticsLabel:
                  'I\'m on it: tell the others you are checking on ${alert.displayName}',
            ),
          ],
        ],
      ),
    );
  }
}
