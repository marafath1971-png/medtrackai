import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../models/product_analysis.dart';
import '../../../theme/med_ai_ui.dart';


/// How much caution a medicine calls for, and why.
///
/// The screen previously showed this as a bare "SAFETY SCORE 52%". That framing
/// misreads badly: Albendazole — a WHO essential medicine — scores 52 because it
/// has a pregnancy contraindication, a paediatric warning and five documented
/// interactions. Those are signs the drug is *well studied*, not signs it is
/// half unsafe. An obscure compound with no known interactions scored higher.
///
/// So the number is named for what it measures — how many cautions apply — and
/// always travels with the reasons that produced it.
enum CautionLevel {
  routine('Routine care', 'Standard precautions apply'),
  moderate('Read before use', 'Some cautions worth knowing'),
  elevated('Extra care needed', 'Important restrictions apply');

  const CautionLevel(this.label, this.blurb);
  final String label;
  final String blurb;
}

/// A single reason the caution level is what it is.
class CautionReason {
  final String label;
  final IconData icon;
  final bool isRestriction;

  const CautionReason({
    required this.label,
    required this.icon,
    this.isRestriction = false,
  });
}

/// Derived caution profile — the level, its drivers, and the headline metrics.
class CautionProfile {
  final CautionLevel level;
  final List<CautionReason> reasons;
  final int interactionCount;
  final int sideEffectCount;
  final bool evidenceStrong;

  const CautionProfile({
    required this.level,
    required this.reasons,
    required this.interactionCount,
    required this.sideEffectCount,
    required this.evidenceStrong,
  });

  /// Builds the profile from an analysis.
  ///
  /// Deliberately not a 0-100 score: the old percentage implied a precision the
  /// inputs cannot support (a count of interactions is not a safety measure).
  /// Three bands map onto what a reader can actually act on.
  static CautionProfile from(ProductAnalysis p) {
    final reasons = <CautionReason>[];

    final pregnancy = p.pregnancyAlert ?? '';
    final child = p.childSafetyAlert ?? '';
    final lower = '$pregnancy $child'.toLowerCase();
    final contraindicated =
        lower.contains('contraindicated') || lower.contains('not recommended');

    if (pregnancy.isNotEmpty) {
      reasons.add(CautionReason(
        label: contraindicated ? 'Not in pregnancy' : 'Pregnancy guidance',
        icon: Icons.pregnant_woman_rounded,
        isRestriction: contraindicated,
      ));
    }
    if (child.isNotEmpty) {
      reasons.add(const CautionReason(
        label: 'Child dosing differs',
        icon: Icons.child_care_rounded,
      ));
    }
    if (p.allergyRiskLevel == 'High' || p.allergyRiskLevel == 'Medium') {
      reasons.add(CautionReason(
        label: '${p.allergyRiskLevel} allergy risk',
        icon: Icons.warning_amber_rounded,
        isRestriction: p.allergyRiskLevel == 'High',
      ));
    }
    if (p.medicineInteractions.isNotEmpty) {
      reasons.add(CautionReason(
        label: '${p.medicineInteractions.length} drug interactions',
        icon: Icons.link_off_rounded,
      ));
    }

    final ev = p.scientificEvidence.toLowerCase();
    final strong = ev.contains('strong') || ev.contains('well-established');
    final weak = ev.contains('limited') || ev.contains('insufficient');

    // A restriction is what actually changes behaviour, so it — not the volume
    // of side effects — sets the band. Weak evidence also escalates: not
    // knowing is its own reason for care.
    final restrictions = reasons.where((r) => r.isRestriction).length;
    final CautionLevel level;
    if (restrictions > 0 || weak) {
      level = CautionLevel.elevated;
    } else if (reasons.isNotEmpty) {
      level = CautionLevel.moderate;
    } else {
      level = CautionLevel.routine;
    }

    return CautionProfile(
      level: level,
      reasons: reasons,
      interactionCount: p.medicineInteractions.length,
      sideEffectCount: p.sideEffects.length,
      evidenceStrong: strong,
    );
  }

  Color color(AppThemeColors L) => switch (level) {
        CautionLevel.routine => AppColors.accentDeep,
        CautionLevel.moderate => const Color(0xFFB07A1E),
        CautionLevel.elevated => const Color(0xFFB4494A),
      };

  Color tint() => switch (level) {
        CautionLevel.routine => AppColors.pastelMint,
        CautionLevel.moderate => AppColors.pastelSun,
        CautionLevel.elevated => AppColors.pastelPink,
      };
}

/// The hero: caution level, its drivers, and a metric strip.
///
/// Replaces two stacked cards ("Safety score", "AI match") that competed for
/// the same glance without either being actionable.
class ScanInsightDashboard extends StatelessWidget {
  final CautionProfile profile;
  final int confidencePct;
  final String category;
  final VoidCallback? onWhyTapped;

  const ScanInsightDashboard({
    super.key,
    required this.profile,
    required this.confidencePct,
    required this.category,
    this.onWhyTapped,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final accent = profile.color(L);

    return Container(
      decoration: BoxDecoration(
        color: profile.tint(),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A2621).withValues(alpha: 0.05),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.p20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'AT A GLANCE',
                            style: AppTypography.caption.copyWith(
                              color: accent,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.p12),
                      Text(
                        profile.level.label,
                        style: AppTypography.headlineMedium.copyWith(
                          color: L.text,
                          fontWeight: FontWeight.w700,
                          height: 1.05,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profile.level.blurb,
                        style: AppTypography.bodySmall.copyWith(
                          color: L.sub,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.p12),
                _CautionDial(profile: profile, accent: accent),
              ],
            ),
          ),

          // The reasons behind the level. Without these the band is an opaque
          // verdict, which is what made the old percentage untrustworthy.
          if (profile.reasons.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.p20, 0, AppSpacing.p20, AppSpacing.p16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final r in profile.reasons)
                    _ReasonChip(reason: r, accent: accent),
                ],
              ),
            ),

          _MetricStrip(
            profile: profile,
            confidencePct: confidencePct,
            category: category,
          ),
        ],
      ),
    );
  }
}

/// Three arcs: how many cautions, out of how many were checked.
class _CautionDial extends StatelessWidget {
  final CautionProfile profile;
  final Color accent;

  const _CautionDial({required this.profile, required this.accent});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final filled = switch (profile.level) {
      CautionLevel.routine => 1,
      CautionLevel.moderate => 2,
      CautionLevel.elevated => 3,
    };

    return SizedBox(
      width: 76,
      height: 76,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(76, 76),
            painter: _ArcPainter(
              filled: filled,
              active: accent,
              idle: accent.withValues(alpha: 0.16),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$filled',
                style: AppTypography.titleLarge.copyWith(
                  color: L.text,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
              Text(
                'of 3',
                style: AppTypography.caption.copyWith(
                  color: L.sub,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final int filled;
  final Color active;
  final Color idle;

  _ArcPainter({
    required this.filled,
    required this.active,
    required this.idle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const gap = 0.22;
    const sweep = (2 * math.pi - 3 * gap) / 3;
    final center = Offset(size.width / 2, size.height / 2);

    for (var i = 0; i < 3; i++) {
      final start = -math.pi / 2 + i * (sweep + gap);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..color = i < filled ? active : idle;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: size.width / 2 - 4),
        start,
        sweep,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.filled != filled || old.active != active;
}

class _ReasonChip extends StatelessWidget {
  final CautionReason reason;
  final Color accent;

  const _ReasonChip({required this.reason, required this.accent});

  @override
  Widget build(BuildContext context) {
    final L = context.L;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: L.card.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(AppRadius.max),
        border: reason.isRestriction
            ? Border.all(color: accent.withValues(alpha: 0.45), width: 1)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(reason.icon, size: 14, color: accent),
          const SizedBox(width: 5),
          Text(
            reason.label,
            style: AppTypography.labelSmall.copyWith(
              color: L.text,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Footer metrics on a solid surface.
///
/// Solid, not [MedAiGlass]: glass drops its tint in light mode, so a tinted
/// panel over a tinted card would flatten into the parent.
class _MetricStrip extends StatelessWidget {
  final CautionProfile profile;
  final int confidencePct;
  final String category;

  const _MetricStrip({
    required this.profile,
    required this.confidencePct,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.p20, vertical: AppSpacing.p16),
      decoration: BoxDecoration(
        color: L.card.withValues(alpha: 0.72),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.xl),
        ),
      ),
      child: Row(
        children: [
          _Metric(
            value: '$confidencePct%',
            label: 'AI match',
            emphasis: confidencePct < 60,
          ),
          _Divider(L: L),
          _Metric(
            value: '${profile.interactionCount}',
            label: profile.interactionCount == 1
                ? 'Interaction'
                : 'Interactions',
          ),
          _Divider(L: L),
          _Metric(
            value: '${profile.sideEffectCount}',
            label: 'Side effects',
          ),
          _Divider(L: L),
          _Metric(
            value: profile.evidenceStrong ? 'Strong' : 'Mixed',
            label: 'Evidence',
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String value;
  final String label;
  final bool emphasis;

  const _Metric({
    required this.value,
    required this.label,
    this.emphasis = false,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;

    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.titleMedium.copyWith(
              // A low AI match is the one metric that should give the reader
              // pause, so it is the only one allowed to shout.
              color: emphasis ? const Color(0xFFB4494A) : L.text,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(
              color: L.sub,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final AppThemeColors L;
  const _Divider({required this.L});

  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 26,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        color: L.border.withValues(alpha: 0.5),
      );
}
