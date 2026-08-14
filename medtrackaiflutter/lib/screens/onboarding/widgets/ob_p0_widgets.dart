import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/med_ai_assets.dart';
import '../../../core/constants/premium_photos.dart';
import '../../../core/utils/haptic_engine.dart';
import '../../../theme/med_ai_ui.dart';
import '../../../widgets/common/animated_pressable.dart';
import '../../../widgets/common/app_svg_icon.dart';
import '../../../widgets/common/med_ai_mascot.dart';
import '../onboarding_controller.dart';
import '../onboarding_theme.dart';
import 'ob_photo_hero.dart';
import 'ob_widgets.dart';

// ════════════════════════════════════════════════════════════════════════
// P0 — Olive-style persona grid (2×2 illustrated cards)
// ════════════════════════════════════════════════════════════════════════
class ObPersonaOption {
  final String id;
  final String label;
  final String subtitle;
  final String emoji;
  final Color tint;
  const ObPersonaOption({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.emoji,
    required this.tint,
  });
}

class ObPersonaGrid extends StatelessWidget {
  final List<ObPersonaOption> options;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  const ObPersonaGrid({
    super.key,
    required this.options,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.82,
      ),
      itemCount: options.length,
      itemBuilder: (context, i) {
        final o = options[i];
        final selected = selectedId == o.id;
        return ObPersonaCard(
          option: o,
          selected: selected,
          onTap: () => onSelect(o.id),
        ).obFadeUp(delayMs: 35 * i);
      },
    );
  }
}

class ObPersonaCard extends StatelessWidget {
  final ObPersonaOption option;
  final bool selected;
  final VoidCallback onTap;

  const ObPersonaCard({
    super.key,
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = ObPalette.of(context);

    return Semantics(
      button: true,
      selected: selected,
      label: option.label,
      child: AnimatedPressable(
        hapticEnabled: false,
        onTap: () {
          HapticEngine.selection();
          onTap();
        },
        scaleFactor: 0.96,
        child: AnimatedContainer(
          duration: MedAiA11y.motion(context, AppDurations.fast),
          curve: AppCurves.expressive,
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
          decoration: BoxDecoration(
            color: selected ? p.surfaceSel : p.surface,
            borderRadius: BorderRadius.circular(AppRadius.l),
            border: Border.all(
              color: selected ? option.tint : p.border,
              width: selected ? 2 : 0.5,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: option.tint.withValues(alpha: 0.22),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : AppShadows.soft,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      option.tint.withValues(alpha: 0.22),
                      option.tint.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(option.emoji, style: const TextStyle(fontSize: 28)),
              ),
              const Spacer(),
              Text(
                option.label,
                style: AppTypography.titleMedium.copyWith(
                  color: p.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                option.subtitle,
                style: AppTypography.bodySmall.copyWith(color: p.sub),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// P0 — Feature interstitial: Scan → Remind → Protect (soft premium)
// ════════════════════════════════════════════════════════════════════════
class ObDarkInterstitial extends StatelessWidget {
  final double progress;
  final VoidCallback? onBack;
  final VoidCallback onContinue;

  const ObDarkInterstitial({
    super.key,
    required this.progress,
    this.onBack,
    required this.onContinue,
  });

  static const _steps = [
    (
      asset: MedAiAssets.iconScan,
      title: 'Scan',
      sub: 'Identify any pill in a second',
      tint: Color(0xFFE4F5E7),
    ),
    (
      asset: MedAiAssets.iconAlarms,
      title: 'Remind',
      sub: 'Smart alerts before you forget',
      tint: Color(0xFFE8F1FB),
    ),
    (
      asset: MedAiAssets.iconShield,
      title: 'Protect',
      sub: 'Catch risky interactions early',
      tint: Color(0xFFE4F5E7),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final p = ObPalette.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [p.bgTop, p.bg],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                child: Row(
                  children: [
                    if (onBack != null)
                      _SoftCircleIcon(onTap: onBack!)
                    else
                      const SizedBox(width: AppA11y.minTapTargetCompact),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: progress.clamp(0, 1),
                          minHeight: 6,
                          backgroundColor: p.border,
                          valueColor: const AlwaysStoppedAnimation(
                            AppColors.limeDeep,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppA11y.minTapTargetCompact + 12),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
                  child: Column(
                    children: [
                      const ObPhotoHero(
                        asset: PremiumPhotos.scanHow,
                        height: 200,
                        badge: 'HOW IT WORKS',
                        overlayLine: 'Scan → Remind → Protect.',
                      ).obFadeUp(),
                      const SizedBox(height: 22),
                      Text(
                        'How Med AI helps you\nstay on track',
                        textAlign: TextAlign.center,
                        style: AppTypography.headlineLarge.copyWith(
                          color: p.text,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                          letterSpacing: -0.5,
                        ),
                      ).obFadeUp(delayMs: 40),
                      const SizedBox(height: 8),
                      Text(
                        'Three quiet moves. One calm routine.',
                        style: AppTypography.bodyMedium.copyWith(color: p.sub),
                      ).obFadeUp(delayMs: 60),
                      const SizedBox(height: 22),
                      ...List.generate(_steps.length, (i) {
                        final s = _steps[i];
                        return Column(
                          children: [
                            _SoftFeatureCard(
                              asset: s.asset,
                              title: s.title,
                              subtitle: s.sub,
                              tint: s.tint,
                            ).obFadeUp(delayMs: 80 + i * 70),
                            if (i < _steps.length - 1) ...[
                              const SizedBox(height: 10),
                              Icon(
                                Icons.arrow_downward_rounded,
                                color: p.sub.withValues(alpha: 0.55),
                                size: 22,
                              ).obFadeUp(delayMs: 110 + i * 70),
                              const SizedBox(height: 10),
                            ],
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 16),
                child: ObPrimaryButton(
                  label: 'Continue',
                  onTap: onContinue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SoftCircleIcon extends StatelessWidget {
  final VoidCallback onTap;
  const _SoftCircleIcon({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = ObPalette.of(context);
    return Semantics(
      button: true,
      label: 'Go back',
      child: AnimatedPressable(
        onTap: () {
          HapticEngine.light();
          onTap();
        },
        scaleFactor: 0.94,
        child: Container(
          width: AppA11y.minTapTargetCompact,
          height: AppA11y.minTapTargetCompact,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: p.surface,
            border: Border.all(color: p.border),
          ),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 16,
            color: p.text,
          ),
        ),
      ),
    );
  }
}

class _SoftFeatureCard extends StatelessWidget {
  final String asset;
  final String title;
  final String subtitle;
  final Color tint;

  const _SoftFeatureCard({
    required this.asset,
    required this.title,
    required this.subtitle,
    required this.tint,
  });

  @override
  Widget build(BuildContext context) {
    final p = ObPalette.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(AppRadius.l),
        border: Border.all(color: p.border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A2621).withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(16),
            ),
            child: AppSvgIcon(
              assetPath: asset,
              size: 26,
              color: p.text,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.titleMedium.copyWith(
                    color: p.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: p.sub,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// P0 — Onboarding pill scan demo (Olive-style product breakdown)
// ════════════════════════════════════════════════════════════════════════
class ObScanDemoPreview extends StatefulWidget {
  const ObScanDemoPreview({super.key});

  @override
  State<ObScanDemoPreview> createState() => _ObScanDemoPreviewState();
}

class _ObScanDemoPreviewState extends State<ObScanDemoPreview>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = ObPalette.of(context);
    final reduceMotion = MedAiA11y.reducedMotion(context);

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final reveal = reduceMotion ? 1.0 : Curves.easeOutCubic.transform(_ctrl.value);
        return Opacity(
          opacity: reveal,
          child: Transform.translate(
            offset: Offset(0, (1 - reveal) * 24),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: BorderRadius.circular(AppRadius.l),
                border: Border.all(color: p.border.withValues(alpha: 0.6)),
                boxShadow: AppShadows.premium,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      _PillVisual(accent: p.accent),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Atorvastatin 20mg',
                              style: AppTypography.titleMedium.copyWith(
                                color: p.text,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: p.good,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '94% match · Identified',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: p.good,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _DemoInsightRow(
                    mascot: true,
                    text:
                        'Take with evening meals. Watch for muscle pain with certain antibiotics.',
                    highlight: 'muscle pain',
                    highlightColor: p.bad,
                    p: p,
                  ),
                  const SizedBox(height: 14),
                  _DemoBreakdownRow(
                    label: 'Interactions',
                    status: '1 flagged',
                    statusColor: p.bad,
                    expanded: _expanded,
                    onTap: () => setState(() => _expanded = !_expanded),
                    p: p,
                  ),
                  if (_expanded) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _DemoTag('Clarithromycin', p.bad, p),
                        _DemoTag('Grapefruit juice', p.bad, p),
                      ],
                    ),
                  ],
                  const SizedBox(height: 10),
                  _DemoBreakdownRow(
                    label: 'Schedule',
                    status: '21:00 daily',
                    statusColor: p.good,
                    p: p,
                  ),
                  const SizedBox(height: 10),
                  _DemoBreakdownRow(
                    label: 'Refill',
                    status: '12 days left',
                    statusColor: const Color(0xFFF5A623),
                    p: p,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PillVisual extends StatelessWidget {
  final Color accent;
  const _PillVisual({required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, accent.withValues(alpha: 0.35)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 34,
            height: 16,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          Container(
            width: 17,
            height: 16,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(99),
                bottomLeft: Radius.circular(99),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoInsightRow extends StatelessWidget {
  final bool mascot;
  final String text;
  final String highlight;
  final Color highlightColor;
  final ObPalette p;

  const _DemoInsightRow({
    required this.mascot,
    required this.text,
    required this.highlight,
    required this.highlightColor,
    required this.p,
  });

  @override
  Widget build(BuildContext context) {
    final parts = text.split(highlight);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (mascot)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: MedAiMascot(size: 28, animate: false),
          ),
        if (mascot) const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: AppTypography.bodySmall.copyWith(
                color: p.text,
                height: 1.45,
              ),
              children: [
                TextSpan(text: parts.first),
                TextSpan(
                  text: highlight,
                  style: TextStyle(
                    color: highlightColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (parts.length > 1) TextSpan(text: parts.last),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DemoBreakdownRow extends StatelessWidget {
  final String label;
  final String status;
  final Color statusColor;
  final bool expanded;
  final VoidCallback? onTap;
  final ObPalette p;

  const _DemoBreakdownRow({
    required this.label,
    required this.status,
    required this.statusColor,
    this.expanded = false,
    this.onTap,
    required this.p,
  });

  @override
  Widget build(BuildContext context) {
    final child = Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTypography.titleMedium.copyWith(
              color: p.text,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            status,
            style: AppTypography.labelMedium.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (onTap != null) ...[
          const SizedBox(width: 6),
          Icon(
            expanded
                ? Icons.keyboard_arrow_up_rounded
                : Icons.keyboard_arrow_down_rounded,
            color: p.sub,
            size: 22,
          ),
        ],
      ],
    );

    if (onTap == null) return child;
    return AnimatedPressable(
      onTap: onTap,
      child: child,
    );
  }
}

class _DemoTag extends StatelessWidget {
  final String label;
  final Color color;
  final ObPalette p;
  const _DemoTag(this.label, this.color, this.p);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: AppTypography.labelMedium.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// P0 — Adherence score card (Olive-style 46/100 + checklist)
// ════════════════════════════════════════════════════════════════════════
class ObAdherenceScoreCard extends StatelessWidget {
  final OnboardingController controller;

  const ObAdherenceScoreCard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final p = ObPalette.of(context);
    final score = controller.adherenceScore;
    final persona = controller.personaLabel;
    final items = controller.adherenceChecklist;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(AppRadius.l),
        border: Border.all(color: p.border.withValues(alpha: 0.6)),
        boxShadow: AppShadows.premium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      p.accent.withValues(alpha: 0.2),
                      p.electric.withValues(alpha: 0.12),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  persona.emoji,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  persona.label,
                  style: AppTypography.titleMedium.copyWith(
                    color: p.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Text(
                'Your score',
                style: AppTypography.bodyMedium.copyWith(color: p.sub),
              ),
              const Spacer(),
              Text(
                '$score/100',
                style: AppTypography.headlineMedium.copyWith(
                  color: p.text,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: score / 100),
              duration: 900.ms,
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => LinearProgressIndicator(
                value: v,
                minHeight: 8,
                backgroundColor: p.border,
                valueColor: AlwaysStoppedAnimation(
                  score >= 70 ? p.good : p.bad,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Icon(
                    item.positive
                        ? Icons.check_circle_rounded
                        : Icons.cancel_rounded,
                    size: 20,
                    color: item.positive
                        ? p.good
                        : p.bad.withValues(alpha: 0.85),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.label,
                      style: AppTypography.bodyMedium.copyWith(
                        color: p.text,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// P0 — Reminder intensity radio options (Olive Recall Alerts style)
// ════════════════════════════════════════════════════════════════════════
class ObRadioOptionCard extends StatelessWidget {
  final String label;
  final String? subtitle;
  final String? badge;
  final bool selected;
  final VoidCallback onTap;

  const ObRadioOptionCard({
    super.key,
    required this.label,
    this.subtitle,
    this.badge,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ObOptionCard(
        label: label,
        subtitle: badge == null
            ? subtitle
            : [if (subtitle != null) subtitle, badge].join(' · '),
        selected: selected,
        multiSelect: false,
        onTap: onTap,
      ),
    );
  }
}
