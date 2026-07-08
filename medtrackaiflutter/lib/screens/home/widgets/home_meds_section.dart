import 'package:flutter/material.dart';
import '../../../theme/med_ai_ui.dart';
import '../../../core/constants/premium_graphics.dart';
import '../../../widgets/common/premium_empty_state.dart';


class HomeMedsHeader extends StatelessWidget {
  final VoidCallback onAdd;
  const HomeMedsHeader({super.key, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        'Recently uploaded',
        style: AppTypography.titleLarge.copyWith(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: L.text,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}

class HomeMedsEmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const HomeMedsEmptyState({super.key, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return PremiumEmptyState(
      title: 'No medications',
      subtitle: 'Add your first medicine to start tracking your daily precision log.',
      illustrationAsset: PremiumGraphics.onboardingThriving,
      actionLabel: 'Add medicine',
      onAction: onAdd,
    );
  }
}
