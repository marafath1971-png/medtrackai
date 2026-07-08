import 'package:flutter/material.dart';

import '../../../core/utils/haptic_engine.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/med_ai_ui.dart';
import '../../../widgets/common/animated_pressable.dart';

class DashboardStatHeader extends StatelessWidget {
  final VoidCallback onDailyLog;

  const DashboardStatHeader({super.key, required this.onDailyLog});

  @override
  Widget build(BuildContext context) {
    final L = context.L;

    return Padding(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding, 12, AppSpacing.screenPadding, 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Analytics',
                    style: AppTypography.headlineMedium.copyWith(
                      color: L.text,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Adherence & health trends',
                    style: AppTypography.bodySmall.copyWith(
                      color: L.sub,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            _IconCircleBtn(
              icon: Icons.add_rounded,
              onTap: onDailyLog,
              semanticLabel: 'Open daily log',
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

  const _IconCircleBtn({
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
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
          child: Icon(icon, size: 22, color: L.text.withValues(alpha: 0.9)),
        ),
      ),
    );
  }
}
