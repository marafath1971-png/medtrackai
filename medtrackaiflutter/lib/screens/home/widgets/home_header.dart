import 'package:flutter/material.dart';

import '../../../core/utils/haptic_engine.dart';
import '../../../providers/app_state.dart';
import '../../../theme/med_ai_ui.dart';
import '../../../widgets/common/animated_pressable.dart';
import '../../../widgets/common/premium_texture.dart';

/// Reference header — avatar, greeting, live dose line, settings.
class HomeHeader extends StatelessWidget {
  final AppState state;
  final VoidCallback onOpenSettings;
  final VoidCallback? onTap;

  const HomeHeader({
    super.key,
    required this.state,
    required this.onOpenSettings,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final userName =
        state.activeProfile?.name ?? state.profile?.name ?? 'there';

    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning,'
        : hour < 17
            ? 'Good afternoon,'
            : 'Good evening,';

    final doses = state.getDoses();
    final takenMap = state.getTakenMapForDate(DateTime.now());
    final takenCount = doses.where((d) => takenMap[d.key] == true).length;
    final liveLine = doses.isEmpty
        ? (state.meds.isEmpty
            ? 'Scan a medicine — your success starts today'
            : 'You’re set up — open a medicine to set times')
        : takenCount >= doses.length && doses.isNotEmpty
            ? 'Perfect day — you’re winning today'
            : '$takenCount of ${doses.length} done — you’ve got this';

    return Padding(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.p12, AppSpacing.gutter, AppSpacing.p8),
        child: Row(
          children: [
            Expanded(
              child: AnimatedPressable(
                onTap: () {
                  HapticEngine.selection();
                  onTap?.call();
                },
                child: Row(
                  children: [
                    Container(
                      width: AppA11y.minTapTargetCompact,
                      height: AppA11y.minTapTargetCompact,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.lime, AppColors.limeDeep],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.limeDeep.withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        userName.isNotEmpty
                            ? userName[0].toUpperCase()
                            : 'A',
                        style: AppTypography.titleLarge.copyWith(
                          color: AppColors.limeInk,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.p12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            greeting,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodySmall.copyWith(
                              color: L.sub,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            userName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.headlineSmall.copyWith(
                              color: L.text,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.p4),
                          Text(
                            liveLine,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.limeDeep,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _IconCircleBtn(
              icon: Icons.settings_outlined,
              onTap: onOpenSettings,
              semanticLabel: 'Open settings',
              showBadge: state.unseenAlertsCount > 0 ||
                  state.getLowStockCount() > 0,
            ),
          ],
        ),
      ),
    );
  }
}

class _IconCircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String semanticLabel;
  final bool showBadge;

  const _IconCircleBtn({
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
    this.showBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Semantics(
      button: true,
      label: semanticLabel,
      child: AnimatedPressable(
        onTap: () {
          HapticEngine.selection();
          onTap();
        },
        child: PremiumTextureCard(
          padding: EdgeInsets.zero,
          radius: 999,
          texture: PremiumTextureStyle.none,
          shadows: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          child: SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, size: 20, color: L.text.withValues(alpha: 0.9)),
                if (showBadge)
                  PositionedDirectional(
                    top: 10,
                    end: 10,
                    child: ExcludeSemantics(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: L.card, width: 2),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
