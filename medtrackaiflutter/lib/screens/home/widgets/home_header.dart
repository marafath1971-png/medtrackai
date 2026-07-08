import 'package:flutter/material.dart';

import '../../../core/utils/haptic_engine.dart';
import '../../../providers/app_state.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/med_ai_ui.dart';
import '../../../widgets/common/animated_pressable.dart';

/// Reference header — lime avatar, greeting, calendar + bell icon buttons.
class HomeHeader extends StatelessWidget {
  final AppState state;
  final VoidCallback onOpenStreak;
  final VoidCallback onOpenSettings;
  final VoidCallback? onTap;

  const HomeHeader({
    super.key,
    required this.state,
    required this.onOpenStreak,
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
        ? 'Good morning!'
        : hour < 17
            ? 'Good afternoon!'
            : 'Good evening!';

    return Padding(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding, 12, AppSpacing.screenPadding, 8),
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
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFC9EFA0), Color(0xFF8FD14F)],
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
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.limeInk,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            greeting,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.labelSmall.copyWith(
                              color: L.sub,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            userName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.titleLarge.copyWith(
                              color: L.text,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                              fontSize: 21,
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
              icon: Icons.calendar_today_outlined,
              onTap: onOpenStreak,
              semanticLabel: 'View streak calendar',
            ),
            const SizedBox(width: 8),
            _IconCircleBtn(
              icon: Icons.notifications_outlined,
              onTap: onOpenSettings,
              semanticLabel: 'Open settings',
              showBadge: true,
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
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: L.card,
            shape: BoxShape.circle,
            border: Border.all(color: L.border.withValues(alpha: 0.45)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(icon, size: 20, color: L.text.withValues(alpha: 0.9)),
              if (showBadge)
                Positioned(
                  top: 9,
                  right: 9,
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
            ],
          ),
        ),
      ),
    );
  }
}
