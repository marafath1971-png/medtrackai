import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/app_state.dart';
import '../../../theme/design_2026.dart';
import '../../../theme/med_ai_ui.dart';
import '../../../widgets/shared/shared_widgets.dart';
import '../../../core/utils/haptic_engine.dart';
import '../../../core/utils/color_utils.dart';

// ════════════════════════════════════════════════════════════════
// MED CARD — 2026 "Tactile Depth" Edition
// Liquid glass surface, colored depth glow, liquid-fill refill vial,
// and a status-aware adherence ring. Engaging + glanceable.
// ════════════════════════════════════════════════════════════════
class MedCard extends StatelessWidget {
  final Medicine med;
  final VoidCallback onView;
  final VoidCallback onEdit;

  const MedCard({
    super.key,
    required this.med,
    required this.onView,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final adh =
        context.select<AppState, int>((s) => s.getAdherenceForMed(med.id));
    final showGeneric = context
        .select<AppState, bool>((s) => s.profile?.showGenericNames ?? false);

    final displayName = (showGeneric && med.genericName.isNotEmpty)
        ? med.genericName
        : med.name;
    final friendlyName = _toTitleCase(displayName);
    final medColor = hexToColor(med.color);

    // Adherence color
    final adhColor =
        adh >= 90 ? L.green : adh >= 70 ? L.amber : L.error;

    // Refill logic
    final total = med.totalCount > 0 ? med.totalCount : 30;
    final current = med.count.clamp(0, total);
    final fillPct = current / total;
    final isLow = current <= med.refillAt;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        button: true,
        label: '$friendlyName, ${med.dose}, adherence $adh percent',
        child: AnimatedPressable(
          onTap: () {
            HapticEngine.selection();
            onView();
          },
          scaleFactor: 0.98,
          child: LiquidGlass(
          radius: 22,
          blur: 18,
          tintOpacity: 0.04,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              // ── Liquid-fill refill vial (depth, not a flat dot) ──
              _RefillVial(
                percent: fillPct,
                color: medColor,
                med: med,
                isLow: isLow,
              ),
              const SizedBox(width: 14),

              // ── Info ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            friendlyName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.titleMedium.copyWith(
                              color: L.text,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        if (med.isCritical) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.priority_high_rounded,
                              size: 14, color: L.error),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${med.dose} · ${med.form}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.labelSmall.copyWith(
                            color: L.sub,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        if (isLow) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: L.error.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              'Low',
                              style: AppTypography.labelSmall.copyWith(
                                color: L.error,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.1,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // ── Adherence ring ──
              _AdherenceRing(
                percent: adh,
                color: adhColor,
                categoryLabel: med.category.isEmpty ? 'Med' : med.category,
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

// ── Liquid-fill refill vial with floating med image ─────────────
class _RefillVial extends StatelessWidget {
  final double percent;
  final Color color;
  final Medicine med;
  final bool isLow;
  const _RefillVial({
    required this.percent,
    required this.color,
    required this.med,
    required this.isLow,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final vialColor = isLow ? L.error : color;

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: vialColor.withValues(alpha: 0.08),
        border: Border.all(
          color: vialColor.withValues(alpha: 0.30),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: vialColor.withValues(alpha: 0.15),
            blurRadius: 12,
            spreadRadius: 0.5,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Liquid fill at the bottom
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: LiquidFill(
                percent: percent,
                color: vialColor,
                trackColor: Colors.transparent,
                width: 52,
                height: 52,
              ),
            ),
          ),
          // Med image / icon floating on top
          MedImage(
            imageUrl: med.imageUrl,
            borderRadius: 100,
            placeholder: Icon(
              Icons.medication_rounded,
              size: 20,
              color: vialColor.withValues(alpha: 0.95),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Compact circular adherence ring ─────────────────────────────
class _AdherenceRing extends StatelessWidget {
  final int percent; // 0–100
  final Color color;
  final String categoryLabel;
  const _AdherenceRing({
    required this.percent,
    required this.color,
    required this.categoryLabel,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 40,
          height: 40,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  value: (percent / 100).clamp(0.0, 1.0),
                  strokeWidth: 3.2,
                  backgroundColor: color.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Text(
                '$percent%',
                style: AppTypography.labelSmall.copyWith(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 3),
        Text(
          categoryLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.labelSmall.copyWith(
            color: L.sub,
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

String _toTitleCase(String s) {
  if (s.isEmpty) return s;
  return s
      .toLowerCase()
      .split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}
