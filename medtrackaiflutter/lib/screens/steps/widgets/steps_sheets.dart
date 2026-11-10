import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/haptic_engine.dart';
import '../../../core/utils/step_math.dart';
import '../../../data/datasources/steps_cloud.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/controllers/steps_controller.dart';
import '../../../services/share_service.dart';
import '../../../theme/med_ai_ui.dart';
import '../../../widgets/common/animated_pressable.dart';
import '../../../widgets/common/app_bottom_sheet.dart';

/// Brand colours for the two walkers. Green is always "you", blue is always
/// the partner — on the ring, the charts and the home-screen widget.
abstract final class StepColors {
  static const heroBg = AppColors.eatoNavy;
  static const heroMe = AppColors.lime;
  static const heroPartner = Color(0xFF8AB4FF);

  static Color me(BuildContext context) =>
      context.isDark ? AppColors.lime : AppColors.limeDeep;
  static Color partner(BuildContext context) =>
      context.isDark ? heroPartner : AppColors.indigo;
}

const _sheetPadding = EdgeInsets.fromLTRB(AppSpacing.screenPadding,
    AppSpacing.p8, AppSpacing.screenPadding, AppSpacing.p24);

Widget _sheetTitle(BuildContext context, String title, String body) {
  final L = context.L;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title,
          style: AppTypography.headlineSmall
              .copyWith(color: L.text, fontWeight: FontWeight.w700)),
      const SizedBox(height: AppSpacing.p4),
      Text(body, style: AppTypography.bodyMedium.copyWith(color: L.sub)),
    ],
  );
}

// ── Goal ─────────────────────────────────────────────────────────────────

Future<void> showStepGoalSheet(BuildContext context, StepsController steps) {
  return AppBottomSheet.show<void>(
    context: context,
    builder: (_) => _GoalSheet(steps: steps),
  );
}

class _GoalSheet extends StatefulWidget {
  final StepsController steps;
  const _GoalSheet({required this.steps});

  @override
  State<_GoalSheet> createState() => _GoalSheetState();
}

class _GoalSheetState extends State<_GoalSheet> {
  late int _goal = widget.steps.goal;

  static const _presets = [5000, 7500, 10000, 12500];

  void _set(int goal) {
    final next = StepMath.clampGoal(goal);
    if (next == _goal) return;
    HapticEngine.selection();
    setState(() => _goal = next);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final L = context.L;
    return SingleChildScrollView(
      padding: _sheetPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _sheetTitle(context, l10n.stepsGoalTitle, l10n.stepsGoalBody),
          const SizedBox(height: AppSpacing.p24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _RoundButton(
                icon: Icons.remove_rounded,
                label: l10n.stepsGoalLower,
                onTap: _goal <= StepMath.minGoal
                    ? null
                    : () => _set(_goal - StepMath.goalIncrement),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      StepMath.format(_goal),
                      style: AppTypography.monoNumber.copyWith(
                        color: L.text,
                        fontSize: 44,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(l10n.stepsGoalStepsPerDay,
                        style: AppTypography.bodySmall.copyWith(color: L.sub)),
                  ],
                ),
              ),
              _RoundButton(
                icon: Icons.add_rounded,
                label: l10n.stepsGoalRaise,
                onTap: _goal >= StepMath.maxGoal
                    ? null
                    : () => _set(_goal + StepMath.goalIncrement),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.p20),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.p8,
            runSpacing: AppSpacing.p8,
            children: [
              for (final preset in _presets)
                _Chip(
                  label: StepMath.format(preset),
                  selected: preset == _goal,
                  onTap: () => _set(preset),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.p24),
          MedAiCTA(
            label: l10n.stepsGoalSave,
            onTap: () {
              widget.steps.setGoal(_goal);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _RoundButton({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      child: AnimatedPressable(
        onTap: onTap,
        disabled: onTap == null,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: L.fill,
            shape: BoxShape.circle,
            border: Border.all(color: L.border.withValues(alpha: 0.5)),
          ),
          child: Icon(icon,
              color: onTap == null ? L.sub.withValues(alpha: 0.4) : L.text),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Chip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Semantics(
      button: true,
      selected: selected,
      child: AnimatedPressable(
        onTap: onTap,
        child: Container(
          constraints:
              const BoxConstraints(minHeight: MedAiA11y.minTapTargetCompact),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            // Solid surfaces on purpose: a tinted glass chip loses its tint in
            // light mode and the selected state disappears.
            color: selected ? L.text : L.fill,
            borderRadius: AppRadius.circle,
          ),
          child: Text(
            label,
            style: AppTypography.labelLarge.copyWith(
              color: selected ? L.bg : L.text,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Invite ───────────────────────────────────────────────────────────────

Future<void> showStepInviteSheet(BuildContext context, StepsController steps) {
  return AppBottomSheet.show<void>(
    context: context,
    builder: (_) => _InviteSheet(steps: steps),
  );
}

class _InviteSheet extends StatefulWidget {
  final StepsController steps;
  const _InviteSheet({required this.steps});

  @override
  State<_InviteSheet> createState() => _InviteSheetState();
}

class _InviteSheetState extends State<_InviteSheet> {
  late Future<String?> _code = widget.steps.createInvite();
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final L = context.L;
    return SingleChildScrollView(
      padding: _sheetPadding,
      child: FutureBuilder<String?>(
        future: _code,
        builder: (context, snap) {
          final waiting = snap.connectionState != ConnectionState.done;
          final code = snap.data;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _sheetTitle(context, l10n.stepsInviteTitle, l10n.stepsInviteBody),
              const SizedBox(height: AppSpacing.p24),
              if (waiting)
                const SizedBox(
                  height: 84,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (code == null) ...[
                Text(l10n.stepsInviteFailed,
                    style: AppTypography.bodyMedium.copyWith(color: L.red)),
                const SizedBox(height: AppSpacing.p16),
                MedAiCTA(
                  label: l10n.stepsTryAgain,
                  secondary: true,
                  onTap: () =>
                      setState(() => _code = widget.steps.createInvite()),
                ),
              ] else ...[
                Semantics(
                  button: true,
                  label:
                      '${l10n.stepsInviteTitle}: ${code.split('').join(' ')}',
                  excludeSemantics: true,
                  child: AnimatedPressable(
                    onTap: () async {
                      await Clipboard.setData(ClipboardData(text: code));
                      HapticEngine.light();
                      if (mounted) setState(() => _copied = true);
                    },
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.p20),
                      decoration: BoxDecoration(
                        color: L.fill,
                        borderRadius: AppRadius.roundL,
                      ),
                      child: Column(
                        children: [
                          Text(
                            code,
                            style: AppTypography.monoNumber.copyWith(
                              color: L.text,
                              fontSize: 36,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 8,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.p4),
                          Text(
                            _copied ? l10n.stepsCopied : l10n.stepsTapToCopy,
                            style:
                                AppTypography.bodySmall.copyWith(color: L.sub),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.p20),
                MedAiCTA(
                  label: l10n.stepsShareCode,
                  icon: Icons.ios_share_rounded,
                  onTap: () =>
                      ShareService.shareText(l10n.stepsInviteShareText(code)),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

// ── Join ─────────────────────────────────────────────────────────────────

/// Returns true once paired.
Future<bool> showStepJoinSheet(
    BuildContext context, StepsController steps) async {
  final joined = await AppBottomSheet.show<bool>(
    context: context,
    builder: (_) => _JoinSheet(steps: steps),
  );
  return joined ?? false;
}

class _JoinSheet extends StatefulWidget {
  final StepsController steps;
  const _JoinSheet({required this.steps});

  @override
  State<_JoinSheet> createState() => _JoinSheetState();
}

class _JoinSheetState extends State<_JoinSheet> {
  final _controller = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await widget.steps.join(_controller.text);
    if (!mounted) return;
    if (result == StepJoinResult.joined) {
      HapticEngine.success();
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _busy = false;
      _error = switch (result) {
        StepJoinResult.ownCode => l10n.stepsJoinOwnCode,
        StepJoinResult.signedOut => l10n.stepsSignInToPair,
        StepJoinResult.notFound => l10n.stepsJoinNotFound,
        _ => l10n.stepsJoinFailed,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final L = context.L;
    final ready = _controller.text.trim().length == 6;
    return SingleChildScrollView(
      padding: _sheetPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _sheetTitle(context, l10n.stepsJoinTitle, l10n.stepsJoinBody),
          const SizedBox(height: AppSpacing.p20),
          TextField(
            controller: _controller,
            autofocus: true,
            maxLength: 6,
            textAlign: TextAlign.center,
            textCapitalization: TextCapitalization.characters,
            autocorrect: false,
            enableSuggestions: false,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9]')),
              TextInputFormatter.withFunction(
                  (_, next) => next.copyWith(text: next.text.toUpperCase())),
            ],
            onChanged: (_) => setState(() => _error = null),
            onSubmitted: (_) {
              if (ready && !_busy) _submit();
            },
            style: AppTypography.monoNumber.copyWith(
              color: L.text,
              fontSize: 30,
              fontWeight: FontWeight.w700,
              letterSpacing: 8,
            ),
            decoration: InputDecoration(
              counterText: '',
              hintText: l10n.stepsJoinHint,
              hintStyle: AppTypography.bodyLarge.copyWith(color: L.sub),
              errorText: _error,
              errorMaxLines: 2,
              filled: true,
              fillColor: L.fill,
              border: OutlineInputBorder(
                borderRadius: AppRadius.roundL,
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.p20),
          MedAiCTA(
            label: l10n.stepsJoinCta,
            enabled: ready,
            loading: _busy,
            onTap: _submit,
          ),
        ],
      ),
    );
  }
}
