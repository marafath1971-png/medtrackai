import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/haptic_engine.dart';
import '../../../providers/app_state.dart';
import '../../../theme/med_ai_ui.dart';
import '../../../widgets/common/animated_pressable.dart';

class DashboardRefHeader extends StatelessWidget {
  final VoidCallback onDailyLog;
  final VoidCallback? onSearch;

  const DashboardRefHeader({
    super.key,
    required this.onDailyLog,
    this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final appState = context.watch<AppState>();
    final name = (appState.activeProfile?.name ?? appState.profile?.name)?.trim();
    final displayName =
        (name != null && name.isNotEmpty) ? name : 'Your profile';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'M';

    return Padding(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
        child: Row(
          children: [
            Expanded(
              child: MedAiGlass(
                radius: 999,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
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
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        initial,
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.limeInk,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleMedium.copyWith(
                          color: L.text,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            _GlassIconBtn(
              icon: Icons.search_rounded,
              label: 'Search',
              onTap: onSearch ?? onDailyLog,
            ),
            const SizedBox(width: 8),
            _GlassIconBtn(
              icon: Icons.notifications_none_rounded,
              label: 'Open daily log',
              onTap: onDailyLog,
              showDot: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassIconBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool showDot;

  const _GlassIconBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.showDot = false,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Semantics(
      button: true,
      label: label,
      child: AnimatedPressable(
        onTap: () {
          HapticEngine.selection();
          onTap();
        },
        child: MedAiGlass(
          radius: 999,
          padding: const EdgeInsets.all(10),
          child: SizedBox(
            width: 22,
            height: 22,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Icon(icon, size: 22, color: L.text.withValues(alpha: 0.9)),
                if (showDot)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
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
