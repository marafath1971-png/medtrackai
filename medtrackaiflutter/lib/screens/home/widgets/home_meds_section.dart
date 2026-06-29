import 'package:flutter/material.dart';
import '../../../theme/med_ai_ui.dart';
import '../../../widgets/common/med_ai_mascot.dart';
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
      visual: const MedAiMascot(
        size: 84,
        semanticLabel: 'Med AI assistant ready to help add a medicine',
      ),
      actionLabel: 'Add medicine',
      onAction: onAdd,
    );
  }
}
