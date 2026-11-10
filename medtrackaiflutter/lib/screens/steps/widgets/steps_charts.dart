import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/haptic_engine.dart';
import '../../../core/utils/step_math.dart';
import '../../../domain/entities/step_day.dart';
import '../../../theme/med_ai_ui.dart';

/// Seven days of steps as bars, with an optional second series for a walking
/// partner. Tapping a day shows its numbers.
class StepsWeekChart extends StatefulWidget {
  final List<StepDay> mine;

  /// Same length and order as [mine], or null when walking solo.
  final List<StepDay>? partner;
  final Color mineColor;
  final Color partnerColor;
  final String Function(StepDay mine, StepDay? partner) describe;

  const StepsWeekChart({
    super.key,
    required this.mine,
    required this.describe,
    required this.mineColor,
    required this.partnerColor,
    this.partner,
  });

  @override
  State<StepsWeekChart> createState() => _StepsWeekChartState();
}

class _StepsWeekChartState extends State<StepsWeekChart> {
  late int _selected = widget.mine.length - 1;

  @override
  void didUpdateWidget(StepsWeekChart old) {
    super.didUpdateWidget(old);
    if (_selected >= widget.mine.length) _selected = widget.mine.length - 1;
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final mine = widget.mine;
    final partner = widget.partner;
    final locale = Localizations.localeOf(context).toLanguageTag();

    var peak = 1;
    for (var i = 0; i < mine.length; i++) {
      peak = math.max(peak, math.max(mine[i].steps, mine[i].goal));
      if (partner != null) peak = math.max(peak, partner[i].steps);
    }
    final goalFraction = mine.last.goal / peak;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.describe(mine[_selected], partner?[_selected]),
          style: AppTypography.bodySmall.copyWith(color: L.sub),
        ),
        const SizedBox(height: AppSpacing.p12),
        SizedBox(
          height: 132,
          child: LayoutBuilder(builder: (context, box) {
            const labelHeight = 22.0;
            final plot = box.maxHeight - labelHeight;
            return Stack(
              children: [
                // Goal line, measured from the bottom of the plot area.
                Positioned(
                  left: 0,
                  right: 0,
                  top: plot * (1 - goalFraction),
                  child: _DashedLine(color: L.sub.withValues(alpha: 0.45)),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < mine.length; i++)
                      Expanded(
                        child: _DayColumn(
                          label: DateFormat.E(locale)
                              .format(DateTime.parse(mine[i].dateKey))
                              .characters
                              .take(2)
                              .toString(),
                          semantics: widget.describe(mine[i], partner?[i]),
                          selected: i == _selected,
                          plotHeight: plot,
                          mine: mine[i].steps / peak,
                          partner:
                              partner == null ? null : partner[i].steps / peak,
                          mineColor: mine[i].goalMet
                              ? widget.mineColor
                              : widget.mineColor.withValues(alpha: 0.55),
                          partnerColor: widget.partnerColor,
                          onTap: () {
                            HapticEngine.selection();
                            setState(() => _selected = i);
                          },
                        ),
                      ),
                  ],
                ),
              ],
            );
          }),
        ),
      ],
    );
  }
}

class _DayColumn extends StatelessWidget {
  final String label;
  final String semantics;
  final bool selected;
  final double plotHeight;
  final double mine;
  final double? partner;
  final Color mineColor;
  final Color partnerColor;
  final VoidCallback onTap;

  const _DayColumn({
    required this.label,
    required this.semantics,
    required this.selected,
    required this.plotHeight,
    required this.mine,
    required this.partner,
    required this.mineColor,
    required this.partnerColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    Widget bar(double fraction, Color color) => AnimatedContainer(
          duration: MedAiA11y.motion(context, AppDurations.medium),
          curve: AppCurves.emilOut,
          width: partner == null ? 18 : 10,
          // A day with steps always shows at least a sliver, so "a few" does
          // not read as "none".
          height: fraction <= 0 ? 3 : math.max(6, plotHeight * fraction),
          decoration: BoxDecoration(
            color: fraction <= 0 ? L.fill : color,
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
        );

    return Semantics(
      button: true,
      selected: selected,
      label: semantics,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          children: [
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  bar(mine, mineColor),
                  if (partner != null) ...[
                    const SizedBox(width: 3),
                    bar(partner!, partnerColor),
                  ],
                ],
              ),
            ),
            SizedBox(
              height: 22,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    color: selected ? L.text : L.sub,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedLine extends StatelessWidget {
  final Color color;
  const _DashedLine({required this.color});

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 1,
        child: CustomPaint(painter: _DashPainter(color), size: Size.infinite),
      );
}

class _DashPainter extends CustomPainter {
  final Color color;
  _DashPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 8) {
      canvas.drawLine(
          Offset(x, 0), Offset(math.min(x + 4, size.width), 0), paint);
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => old.color != color;
}

/// Today hour by hour: 24 thin bars, the busiest one highlighted.
class StepsHourChart extends StatelessWidget {
  final List<int> hourly;
  final Color color;

  const StepsHourChart({super.key, required this.hourly, required this.color});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final values = [
      for (var h = 0; h < 24; h++) h < hourly.length ? hourly[h] : 0
    ];
    final peak = values.fold(1, math.max);
    final peakHour = StepMath.peakHour(values);
    final locale = Localizations.localeOf(context).toLanguageTag();
    String tick(int hour) =>
        DateFormat.j(locale).format(DateTime(2000, 1, 1, hour));

    return ExcludeSemantics(
      child: Column(
        children: [
          SizedBox(
            height: 72,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var h = 0; h < 24; h++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1.5),
                      child: Container(
                        height: values[h] <= 0
                            ? 3
                            : math.max(5, 72 * values[h] / peak),
                        decoration: BoxDecoration(
                          color: values[h] <= 0
                              ? L.fill
                              : (h == peakHour
                                  ? color
                                  : color.withValues(alpha: 0.5)),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.p8),
          // Four equal columns, so each label starts under the hour it names
          // and none can push the row wider than the chart.
          Row(
            children: [
              for (final h in const [0, 6, 12, 18])
                Expanded(
                  child: Text(
                    tick(h),
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    softWrap: false,
                    style: AppTypography.caption.copyWith(color: L.sub),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
