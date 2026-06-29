import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/utils/haptic_engine.dart';
import '../../../theme/med_ai_ui.dart';
import '../../../widgets/common/animated_pressable.dart';
import '../../../widgets/common/med_ai_mascot.dart';
import '../onboarding_controller.dart';
import '../onboarding_theme.dart';

// ════════════════════════════════════════════════════════════════════════
// Eato-inspired onboarding widgets (unique_screens_hd.pdf)
// Cream canvas · navy CTA · gold accent · tall selection cards
// ════════════════════════════════════════════════════════════════════════

/// Laurel wreath + thumbs-up hero — "Your goal will be reached in our app."
class ObLaurelWelcome extends StatelessWidget {
  const ObLaurelWelcome({super.key});

  @override
  Widget build(BuildContext context) {
    final p = ObPalette.of(context);
    return SizedBox(
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(200, 200),
            painter: _LaurelPainter(color: p.accent),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.thumb_up_alt_rounded, color: p.bad, size: 36),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Text(
                  'Your adherence goal will be reached in Med AI',
                  textAlign: TextAlign.center,
                  style: AppTypography.titleMedium.copyWith(
                    color: p.accent,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LaurelPainter extends CustomPainter {
  final Color color;
  _LaurelPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    for (var side = -1; side <= 1; side += 2) {
      final path = Path();
      for (var i = 0; i < 8; i++) {
        final t = i / 7;
        final angle = math.pi * 0.75 + t * math.pi * 0.9 * side;
        final r = size.width * 0.38;
        final leaf = Offset(c.dx + math.cos(angle) * r, c.dy + math.sin(angle) * r * 0.9);
        canvas.drawCircle(leaf, 5, Paint()..color = color.withValues(alpha: 0.35));
        if (i == 0) {
          path.moveTo(leaf.dx, leaf.dy);
        } else {
          path.lineTo(leaf.dx, leaf.dy);
        }
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_LaurelPainter old) => old.color != color;
}

/// Long-term adherence chart — Med AI plan vs memory-only tracking.
class ObLongTermResultsChart extends StatefulWidget {
  const ObLongTermResultsChart({super.key});

  @override
  State<ObLongTermResultsChart> createState() => _ObLongTermResultsChartState();
}

class _ObLongTermResultsChartState extends State<ObLongTermResultsChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (!MedAiA11y.reducedMotion(context)) {
      _ctrl.forward();
    } else {
      _ctrl.value = 1;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = ObPalette.of(context);
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = Curves.easeOutCubic.transform(_ctrl.value);
        return Container(
          padding: const EdgeInsets.fromLTRB(12, 20, 12, 16),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: p.border),
            boxShadow: AppShadows.soft,
          ),
          child: Column(
            children: [
              SizedBox(
                height: 160,
                width: double.infinity,
                child: CustomPaint(
                  painter: _DualLinePainter(
                    progress: t,
                    medAi: p.accent,
                    traditional: p.bad.withValues(alpha: 0.55),
                    grid: p.border,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _LegendDot(color: p.bad.withValues(alpha: 0.7), label: 'Memory only'),
                  const SizedBox(width: 16),
                  _LegendDot(color: p.accent, label: 'Med AI plan'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final p = ObPalette.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTypography.labelSmall.copyWith(color: p.sub)),
      ],
    );
  }
}

class _DualLinePainter extends CustomPainter {
  final double progress;
  final Color medAi;
  final Color traditional;
  final Color grid;

  _DualLinePainter({
    required this.progress,
    required this.medAi,
    required this.traditional,
    required this.grid,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final pad = 12.0;
    final w = size.width - pad * 2;
    final h = size.height - pad * 2;

    for (var i = 0; i <= 4; i++) {
      final y = pad + h * i / 4;
      canvas.drawLine(
        Offset(pad, y),
        Offset(size.width - pad, y),
        Paint()..color = grid.withValues(alpha: 0.5),
      );
    }

    double yFor(List<double> adherences, double xFrac) {
      final idx = (xFrac * (adherences.length - 1)).round().clamp(0, adherences.length - 1);
      final adh = adherences[idx];
      return pad + h * (1 - adh);
    }

    void drawLine(List<double> adherences, Color color) {
      final path = Path();
      for (var i = 0; i <= 40; i++) {
        final f = (i / 40) * progress;
        final x = pad + w * f;
        final y = yFor(adherences, f);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..strokeWidth = color == medAi ? 3.5 : 2.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }

    drawLine([0.5, 0.62, 0.58, 0.48, 0.55, 0.52], traditional);
    drawLine([0.45, 0.52, 0.62, 0.74, 0.82, 0.88], medAi);

    final fill = Path();
    for (var i = 0; i <= 40; i++) {
      final f = (i / 40) * progress;
      final x = pad + w * f;
      final y = yFor([0.45, 0.52, 0.62, 0.74, 0.82, 0.88], f);
      if (i == 0) {
        fill.moveTo(x, y);
      } else {
        fill.lineTo(x, y);
      }
    }
    fill.lineTo(pad + w * progress, pad + h);
    fill.lineTo(pad, pad + h);
    fill.close();
    canvas.drawPath(fill, Paint()..color = medAi.withValues(alpha: 0.12));
  }

  @override
  bool shouldRepaint(_DualLinePainter old) => old.progress != progress;
}

/// Tall goal selection card (PDF primary-goal screen).
class ObLargeGoalTile extends StatelessWidget {
  final String label;
  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  const ObLargeGoalTile({
    super.key,
    required this.label,
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = ObPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AnimatedPressable(
        onTap: () {
          HapticEngine.selection();
          onTap();
        },
        scaleFactor: 0.98,
        child: AnimatedContainer(
          duration: MedAiA11y.motion(context, AppDurations.fast),
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: selected ? p.warmTint : p.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? p.accent : p.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.titleMedium.copyWith(
                    color: p.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Personal adherence summary (PDF BMI summary style).
class ObPersonalAdherenceSummary extends StatelessWidget {
  final OnboardingController controller;
  const ObPersonalAdherenceSummary({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final p = ObPalette.of(context);
    final score = controller.adherenceScore;
    final persona = controller.personaLabel;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.border),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Adherence baseline',
            style: AppTypography.labelLarge.copyWith(
              color: p.sub,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '$score',
                style: AppTypography.displaySmall.copyWith(
                  color: p.text,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                ' / 100',
                style: AppTypography.titleLarge.copyWith(
                  color: p.sub,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: score >= 70 ? p.good.withValues(alpha: 0.15) : p.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  score >= 70 ? 'Strong' : 'Room to grow',
                  style: AppTypography.labelSmall.copyWith(
                    color: score >= 70 ? p.good : p.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: score / 100,
              minHeight: 8,
              backgroundColor: p.border,
              valueColor: AlwaysStoppedAnimation(p.accent),
            ),
          ),
          const SizedBox(height: 18),
          _SummaryRow(label: 'Profile', value: persona.label, p: p),
          _SummaryRow(label: 'Med count', value: controller.medCountLabel, p: p),
          _SummaryRow(label: 'Challenge', value: controller.challengeLabel, p: p),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final ObPalette p;
  const _SummaryRow({required this.label, required this.value, required this.p});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: AppTypography.bodySmall.copyWith(color: p.sub)),
          ),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              color: p.text,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-width orange panel — scan / AI feature intro.
class ObOrangeScanIntro extends StatelessWidget {
  const ObOrangeScanIntro({super.key});

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFF0A04B);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      decoration: BoxDecoration(
        color: orange,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const MedAiMascot(size: 88, semanticLabel: 'Med AI scan assistant'),
          const SizedBox(height: 16),
          Text(
            'Point. Scan. Know.',
            textAlign: TextAlign.center,
            style: AppTypography.headlineSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Our AI identifies pills, flags interactions, and logs your schedule instantly.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white.withValues(alpha: 0.92),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Side-by-side Yes / No (PDF binary question screens).
class ObYesNoChoice extends StatelessWidget {
  final String? selectedId;
  final ValueChanged<String> onSelect;

  const ObYesNoChoice({
    super.key,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final p = ObPalette.of(context);
    return Row(
      children: [
        Expanded(
          child: _YesNoBtn(
            label: 'No',
            selected: selectedId == 'no',
            filled: false,
            p: p,
            onTap: () => onSelect('no'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _YesNoBtn(
            label: 'Yes',
            selected: selectedId == 'yes',
            filled: true,
            p: p,
            onTap: () => onSelect('yes'),
          ),
        ),
      ],
    );
  }
}

class _YesNoBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final bool filled;
  final ObPalette p;
  final VoidCallback onTap;

  const _YesNoBtn({
    required this.label,
    required this.selected,
    required this.filled,
    required this.p,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isYes = filled;
    return AnimatedPressable(
      onTap: () {
        HapticEngine.selection();
        onTap();
      },
      scaleFactor: 0.97,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected && isYes ? p.cta : p.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? p.accent : p.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.titleMedium.copyWith(
            color: selected && isYes ? p.ctaInk : p.text,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// Social proof — avatar cluster + bold stat (PDF screen 15).
class ObSocialProofCluster extends StatelessWidget {
  const ObSocialProofCluster({super.key});

  @override
  Widget build(BuildContext context) {
    final p = ObPalette.of(context);
    const avatars = ['👩', '👨', '👵', '🧑'];
    return Column(
      children: [
        SizedBox(
          height: 72,
          child: Stack(
            alignment: Alignment.center,
            children: List.generate(avatars.length, (i) {
              return Positioned(
                left: 40 + i * 36,
                child: Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: p.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: p.border, width: 2),
                    boxShadow: AppShadows.soft,
                  ),
                  child: Text(avatars[i], style: const TextStyle(fontSize: 24)),
                ),
              ).animate(delay: (i * 80).ms).fadeIn().scale(
                    begin: const Offset(0.8, 0.8),
                    end: const Offset(1, 1),
                    curve: Curves.easeOutBack,
                  );
            }),
          ),
        ),
        const SizedBox(height: 20),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: AppTypography.bodyLarge.copyWith(
              color: p.text,
              height: 1.45,
            ),
            children: [
              const TextSpan(
                text: '83%',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
              ),
              TextSpan(
                text: ' of Med AI members say staying on track feels effortless.',
                style: TextStyle(color: p.sub),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Large vertical goal picker scaffold content.
class ObLargeGoalPicker extends StatelessWidget {
  final List<({String id, String label, String emoji})> options;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  const ObLargeGoalPicker({
    super.key,
    required this.options,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: options
          .map(
            (o) => ObLargeGoalTile(
              label: o.label,
              emoji: o.emoji,
              selected: selectedId == o.id,
              onTap: () => onSelect(o.id),
            ),
          )
          .toList(),
    );
  }
}
