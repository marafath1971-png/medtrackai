import 'package:flutter/material.dart';

import '../../../core/utils/haptic_engine.dart';
import '../../../theme/med_ai_ui.dart';
import '../onboarding_theme.dart';

// ════════════════════════════════════════════════════════════════════════
// EATO-STYLE ONBOARDING COMPONENTS
// Big-input instruments (year wheel, weight ruler, time sliders), instant
// feedback chips, social-proof banners, payoff bars, and the privacy shield.
// Visual language: cream canvas, white cards, amber selection, navy CTA.
// ════════════════════════════════════════════════════════════════════════

// ── Year wheel picker (Eato "When is your birthyear?") ───────────────────
class ObYearWheelPicker extends StatefulWidget {
  final int? selected;
  final ValueChanged<int> onChanged;
  const ObYearWheelPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  State<ObYearWheelPicker> createState() => _ObYearWheelPickerState();
}

class _ObYearWheelPickerState extends State<ObYearWheelPicker> {
  late final List<int> _years;
  late final FixedExtentScrollController _controller;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now().year;
    // Oldest first so scrolling down moves toward the present.
    _years = [for (var y = now - 100; y <= now - 10; y++) y];
    final initial = widget.selected ?? now - 30;
    final index = (_years.indexOf(initial)).clamp(0, _years.length - 1);
    _controller = FixedExtentScrollController(initialItem: index);
    // Report the default so the CTA can enable even without scrolling.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.selected == null) widget.onChanged(_years[index]);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = ObPalette.of(context);
    return SizedBox(
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Selection band behind the centered year.
          Container(
            height: 56,
            margin: const EdgeInsets.symmetric(horizontal: 40),
            decoration: BoxDecoration(
              color: p.warmTint,
              borderRadius: BorderRadius.circular(AppRadius.l),
              border: Border.all(color: p.borderSel, width: 1.5),
            ),
          ),
          ListWheelScrollView.useDelegate(
            controller: _controller,
            itemExtent: 56,
            perspective: 0.003,
            diameterRatio: 1.6,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: (i) {
              HapticEngine.selection();
              widget.onChanged(_years[i]);
            },
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: _years.length,
              builder: (context, i) {
                final year = _years[i];
                final selected = year == (widget.selected ?? -1);
                return Center(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 120),
                    style: TextStyle(
                      fontSize: selected ? 30 : 22,
                      fontWeight:
                          selected ? FontWeight.w800 : FontWeight.w500,
                      color: selected ? p.text : p.sub.withValues(alpha: 0.55),
                    ),
                    child: Text('$year'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Weight ruler with unit toggle (Eato "What's your current weight?") ───
class ObWeightRuler extends StatefulWidget {
  /// Value is always reported in kilograms.
  final double kg;
  final ValueChanged<double> onChanged;
  const ObWeightRuler({super.key, required this.kg, required this.onChanged});

  @override
  State<ObWeightRuler> createState() => _ObWeightRulerState();
}

class _ObWeightRulerState extends State<ObWeightRuler> {
  bool _metric = true;
  double _lastDetent = 0;

  static const _minKg = 30.0;
  static const _maxKg = 220.0;

  double get _display => _metric ? widget.kg : widget.kg * 2.20462;

  void _drag(DragUpdateDetails d) {
    // ~10 logical px per unit; dragging left increases (like sliding a ruler).
    final deltaUnits = -d.delta.dx / 10.0;
    final deltaKg = _metric ? deltaUnits : deltaUnits / 2.20462;
    final next = (widget.kg + deltaKg).clamp(_minKg, _maxKg);
    if ((next - _lastDetent).abs() >= 1.0) {
      HapticEngine.selection();
      _lastDetent = next;
    }
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final p = ObPalette.of(context);
    final unit = _metric ? 'kg' : 'lbs';
    return Column(
      children: [
        // Unit toggle pill.
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: p.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _unitChip('Kg', _metric, () => setState(() => _metric = true)),
              _unitChip('Lbs', !_metric, () => setState(() => _metric = false)),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _display.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 56,
                height: 1.0,
                fontWeight: FontWeight.w800,
                color: p.text,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8, left: 6),
              child: Text(
                unit,
                style: AppTypography.labelMedium.copyWith(color: p.sub),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragUpdate: _drag,
          child: SizedBox(
            height: 84,
            width: double.infinity,
            child: CustomPaint(
              painter: _RulerPainter(
                value: _display,
                tickColor: p.sub.withValues(alpha: 0.4),
                centerColor: p.accent,
                labelColor: p.sub,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Slide the ruler',
          style: AppTypography.labelMedium.copyWith(
            color: p.sub.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _unitChip(String label, bool active, VoidCallback onTap) {
    final p = ObPalette.of(context);
    return GestureDetector(
      onTap: () {
        HapticEngine.light();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: active ? p.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: active ? p.accentInk : p.sub,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _RulerPainter extends CustomPainter {
  final double value;
  final Color tickColor;
  final Color centerColor;
  final Color labelColor;
  _RulerPainter({
    required this.value,
    required this.tickColor,
    required this.centerColor,
    required this.labelColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const pxPerUnit = 10.0;
    final tick = Paint()
      ..color = tickColor
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    final center = Paint()
      ..color = centerColor
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final mid = size.width / 2;
    final firstUnit = (value - mid / pxPerUnit).floor();
    final lastUnit = (value + mid / pxPerUnit).ceil();

    for (var u = firstUnit; u <= lastUnit; u++) {
      final x = mid + (u - value) * pxPerUnit;
      if (x < 0 || x > size.width) continue;
      final isMajor = u % 5 == 0;
      final h = isMajor ? 34.0 : 18.0;
      canvas.drawLine(Offset(x, 8), Offset(x, 8 + h), tick);
      if (isMajor) {
        final tp = TextPainter(
          text: TextSpan(
            text: '$u',
            style: TextStyle(fontSize: 12, color: labelColor),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(x - tp.width / 2, 50));
      }
    }
    // Center hairline marker.
    canvas.drawLine(Offset(mid, 0), Offset(mid, 48), center);
  }

  @override
  bool shouldRepaint(_RulerPainter old) => old.value != value;
}

// ── Instant feedback chip (Eato BMI / "Realistic Target" card) ───────────
class ObFeedbackChip extends StatelessWidget {
  final String badge;
  final String title;
  final String body;
  final bool positive;
  final String? sourceLabel;
  const ObFeedbackChip({
    super.key,
    required this.badge,
    required this.title,
    required this.body,
    this.positive = true,
    this.sourceLabel,
  });

  @override
  Widget build(BuildContext context) {
    final p = ObPalette.of(context);
    final badgeColor = positive ? p.good : p.bad;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(AppRadius.l),
        border: Border.all(color: p.border.withValues(alpha: 0.7), width: 0.5),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badge,
                  style: AppTypography.labelMedium.copyWith(
                    color: badgeColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    color: p.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(body,
              style: AppTypography.bodyMedium
                  .copyWith(color: p.sub, height: 1.35)),
          if (sourceLabel != null) ...[
            const SizedBox(height: 8),
            Text(
              sourceLabel!,
              style: AppTypography.labelMedium.copyWith(
                color: p.sub,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Wake / sleep dual sliders ─────────────────────────────────────────────
class ObDualTimeSliders extends StatelessWidget {
  final int wakeHour;
  final int sleepHour;
  final ValueChanged<int> onWakeChanged;
  final ValueChanged<int> onSleepChanged;
  const ObDualTimeSliders({
    super.key,
    required this.wakeHour,
    required this.sleepHour,
    required this.onWakeChanged,
    required this.onSleepChanged,
  });

  String _fmt(int h) {
    final period = h >= 12 ? 'PM' : 'AM';
    final display = h % 12 == 0 ? 12 : h % 12;
    return '$display:00 $period';
  }

  @override
  Widget build(BuildContext context) {
    final p = ObPalette.of(context);
    Widget row({
      required String emoji,
      required String label,
      required int value,
      required int min,
      required int max,
      required ValueChanged<int> onChanged,
    }) {
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(AppRadius.l),
          border:
              Border.all(color: p.border.withValues(alpha: 0.7), width: 0.5),
          boxShadow: AppShadows.soft,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(label,
                    style: AppTypography.bodyMedium.copyWith(
                      color: p.text,
                      fontWeight: FontWeight.w700,
                    )),
                const Spacer(),
                Text(_fmt(value),
                    style: AppTypography.bodyMedium.copyWith(
                      color: p.accent,
                      fontWeight: FontWeight.w800,
                    )),
              ],
            ),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: p.accent,
                inactiveTrackColor: p.border,
                thumbColor: p.accent,
                overlayColor: p.accent.withValues(alpha: 0.12),
                trackHeight: 5,
              ),
              child: Slider(
                value: value.toDouble(),
                min: min.toDouble(),
                max: max.toDouble(),
                divisions: max - min,
                onChanged: (v) {
                  final next = v.round();
                  if (next != value) HapticEngine.selection();
                  onChanged(next);
                },
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        row(
          emoji: '🌅',
          label: 'I usually wake up',
          value: wakeHour,
          min: 4,
          max: 12,
          onChanged: onWakeChanged,
        ),
        row(
          emoji: '🌙',
          label: 'I usually go to sleep',
          value: sleepHour,
          min: 19,
          max: 23,
          onChanged: onSleepChanged,
        ),
      ],
    );
  }
}

// ── Social-proof banner ("75% of users answered the same way") ───────────
class ObSocialProofBanner extends StatelessWidget {
  final String percent;
  final String text;
  const ObSocialProofBanner({
    super.key,
    required this.percent,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final p = ObPalette.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.l),
        border: Border.all(color: p.accent.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            percent,
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              height: 1.0,
              color: p.accent,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                text,
                style: AppTypography.bodyMedium
                    .copyWith(color: p.text, height: 1.35),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Payoff bars (Eato "Lose twice as much with Eato") ─────────────────────
class ObPayoffBars extends StatefulWidget {
  final String leftLabel;
  final String rightLabel;
  const ObPayoffBars({
    super.key,
    this.leftLabel = 'Without Med AI',
    this.rightLabel = 'With Med AI',
  });

  @override
  State<ObPayoffBars> createState() => _ObPayoffBarsState();
}

class _ObPayoffBarsState extends State<ObPayoffBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MedAiA11y.reducedMotion(context)) {
        _ctrl.value = 1;
      } else {
        _ctrl.forward();
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = ObPalette.of(context);
    Widget bar({
      required double heightFactor,
      required Color color,
      required Color ink,
      required String label,
    }) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) {
              final t = Curves.easeOutBack.transform(_ctrl.value);
              return Container(
                width: 92,
                height: 170 * heightFactor * t.clamp(0.0, 1.0),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(AppRadius.m),
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: AppTypography.labelMedium.copyWith(
                    color: ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              );
            },
          ),
        ],
      );
    }

    return SizedBox(
      height: 190,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          bar(
            heightFactor: 0.42,
            color: p.border,
            ink: p.sub,
            label: widget.leftLabel,
          ),
          const SizedBox(width: 26),
          bar(
            heightFactor: 1.0,
            color: p.accent,
            ink: p.accentInk,
            label: widget.rightLabel,
          ),
        ],
      ),
    );
  }
}

// ── Privacy shield hero ───────────────────────────────────────────────────
class ObShieldHero extends StatelessWidget {
  const ObShieldHero({super.key});

  @override
  Widget build(BuildContext context) {
    final p = ObPalette.of(context);
    return Center(
      child: Container(
        width: 120,
        height: 120,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: p.good.withValues(alpha: 0.12),
          boxShadow: AppShadows.glow(p.good, intensity: 0.18),
        ),
        child: Icon(Icons.verified_user_rounded, size: 56, color: p.good),
      ),
    );
  }
}
