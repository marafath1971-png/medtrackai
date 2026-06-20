import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/app_state.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/shared/shared_widgets.dart';
import '../../../core/utils/haptic_engine.dart';
import '../../../core/utils/color_utils.dart';


// ══════════════════════════════════════════════
// MED CARD — Cal AI 2026 Style
// Flat #111111 card with left color dot accent
// ══════════════════════════════════════════════
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
    final adhColor = adh >= 90
        ? L.green
        : adh >= 70
            ? L.amber
            : L.error;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: BouncingButton(
        onTap: () {
          HapticEngine.selection();
          onView();
        },
        scaleFactor: 0.98,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: L.card.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: L.glassBorder,
                  width: 0.5,
                ),
                boxShadow: AppShadows.subtle,
              ),
              child: Row(
                children: [
                  // ── Premium Circular Glow Icon Border ──
                  Container(
                    width: 48,
                    height: 48,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: (med.isCritical ? L.error : medColor).withValues(alpha: 0.35),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (med.isCritical ? L.error : medColor).withValues(alpha: 0.12),
                          blurRadius: 8,
                          spreadRadius: 0.5,
                        ),
                      ],
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (med.isCritical ? L.error : medColor).withValues(alpha: 0.08),
                      ),
                      child: Center(
                        child: MedImage(
                          imageUrl: med.imageUrl,
                          borderRadius: 100,
                          placeholder: Icon(
                            Icons.medication_rounded,
                            size: 18,
                            color: (med.isCritical ? L.error : medColor).withValues(alpha: 0.9),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

              // ── Info ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      friendlyName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleMedium.copyWith(
                        color: L.text,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        letterSpacing: -0.3,
                      ),
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
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Adherence Badge ──
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: adhColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: adhColor.withValues(alpha: 0.2), width: 0.8),
                    ),
                    child: Text(
                      '$adh%',
                      style: AppTypography.labelSmall.copyWith(
                        color: adhColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    med.category,
                    style: AppTypography.labelSmall.copyWith(
                      color: L.sub,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  ),
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
