import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../providers/app_state.dart';
import '../../../theme/med_ai_ui.dart';
import '../../../core/utils/color_utils.dart';
import '../../../widgets/shared/shared_widgets.dart';

class CaregiverCard extends StatefulWidget {
  final Caregiver cg;
  final AppState state;
  final AppThemeColors L;
  final VoidCallback onDashboard;
  const CaregiverCard(
      {super.key,
      required this.cg,
      required this.state,
      required this.L,
      required this.onDashboard});
  @override
  State<CaregiverCard> createState() => _CaregiverCardState();
}

class _CaregiverCardState extends State<CaregiverCard> {
  @override
  Widget build(BuildContext context) {
    final cg = widget.cg;
    final L = widget.L;
    final isActive = cg.status == 'active';
    final medColor = hexToColor(cg.color);

    return Semantics(
      button: true,
      label: '${cg.name}, ${cg.relation}',
      child: AnimatedPressable(
        onTap: widget.onDashboard,
        scaleFactor: 0.985,
        child: MedAiDepthCard(
        padding: const EdgeInsets.all(AppSpacing.p20),
        radius: AppRadius.l,
        accentGlow: isActive,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar with Subthe Glow
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isActive
                    ? LinearGradient(
                        colors: [
                          medColor.withValues(alpha: 0.8),
                          medColor.withValues(alpha: 0.1)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                border: isActive ? null : Border.all(color: L.border),
                boxShadow: null,
              ),
              child: Padding(
                padding: EdgeInsets.all(isActive ? 2.0 : 0.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: L.card,
                    shape: BoxShape.circle,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: medColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        cg.avatar,
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const Spacer(),

            // Name & Relation
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cg.name,
                        style: AppTypography.titleLarge.copyWith(
                          color: L.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            cg.relation,
                            style: AppTypography.labelSmall.copyWith(
                              color: L.sub,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                              letterSpacing: 0.1,
                            ),
                          ),
                          if (isActive) ...[
                            const SizedBox(width: AppSpacing.p8),
                            _StatusPill(
                              label: 'Active',
                              color: L.success,
                              L: L,
                            ),
                          ] else ...[
                            const SizedBox(width: AppSpacing.p8),
                            _StatusPill(
                              label: 'Waiting',
                              color: L.sub,
                              L: L,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: L.fill.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.arrow_forward_ios_rounded,
                      size: 14, color: L.text),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.p16),

            // Latest Activity Snippet (Cal AI Ticker)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p12, vertical: AppSpacing.p8),
              decoration: BoxDecoration(
                color: L.fill.withValues(alpha: 0.4),
                borderRadius: AppRadius.roundXS,
              ),
              child: Row(
                children: [
                  Icon(Icons.radar_rounded,
                      size: 12, color: isActive ? L.success : L.warning),
                  const SizedBox(width: AppSpacing.p8),
                  Expanded(
                    child: Text(
                      isActive
                          ? 'Active monitoring · stable'
                          : 'Invite sent · waiting',
                      style: AppTypography.labelSmall.copyWith(
                        color: L.text.withValues(alpha: 0.7),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.p12),

            // Industrial Status Bar
            Container(
              height: 2,
              width: double.infinity,
              decoration: BoxDecoration(
                color: L.border.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(1),
              ),
              child: Row(
                children: [
                  Container(
                    width: isActive ? 100 : 40,
                    height: 2,
                    decoration: BoxDecoration(
                      color: isActive ? L.success : L.warning,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class FamStatJSX extends StatelessWidget {
  final String emoji, label;
  final int value;
  final Color color;
  const FamStatJSX(
      {super.key,
      required this.emoji,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return SquircleCard(
      padding: const EdgeInsets.all(AppSpacing.p16),
      boxShadow: AppShadows.soft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(height: AppSpacing.p16),
          Text(value.toString(),
              style: AppTypography.displayLarge.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: L.text,
                height: 1.0,
              )),
          const SizedBox(height: 2),
          Text(label,
              style: AppTypography.labelSmall.copyWith(
                  color: L.sub,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1)),
        ],
      ),
    );
  }
}

class PivotTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final AppThemeColors L;
  const PivotTab(
      {super.key,
      required this.label,
      required this.active,
      required this.onTap,
      required this.L});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: active,
      label: label,
      child: AnimatedPressable(
        onTap: onTap,
        scaleFactor: 0.97,
        child: AnimatedContainer(
          duration: MedAiA11y.motion(context, 250.ms),
          constraints: const BoxConstraints(minHeight: MedAiA11y.minTapTarget),
          padding: const EdgeInsets.symmetric(vertical: 11),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? L.text : Colors.transparent,
            borderRadius: AppRadius.roundS,
          ),
          child: Text(
            label,
            style: AppTypography.labelLarge.copyWith(
              fontWeight: active ? FontWeight.w800 : FontWeight.w600,
              color: active ? L.bg : L.sub,
            ),
          ),
        ),
      ),
    );
  }
}

class HeaderBtn extends StatelessWidget {
  final VoidCallback onTap;
  final String label;
  final IconData icon;
  final Color color, bg;
  const HeaderBtn(
      {super.key,
      required this.onTap,
      required this.label,
      required this.icon,
      required this.color,
      required this.bg});
  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        child: AnimatedPressable(
          onTap: onTap,
          scaleFactor: 0.97,
          child: Container(
            constraints: const BoxConstraints(minHeight: MedAiA11y.minTapTarget),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p16, vertical: AppSpacing.p8),
            decoration: BoxDecoration(
                color: bg, borderRadius: BorderRadius.circular(20)),
            child: Row(children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: AppSpacing.p8),
              Text(label,
                  style: AppTypography.labelLarge.copyWith(
                      fontSize: 14, fontWeight: FontWeight.w700, color: color)),
            ]),
          ),
        ),
      );
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final AppThemeColors L;

  const _StatusPill({
    required this.label,
    required this.color,
    required this.L,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
