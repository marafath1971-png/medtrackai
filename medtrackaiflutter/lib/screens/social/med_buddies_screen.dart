import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../providers/app_state.dart';
import '../../../theme/med_ai_ui.dart';
import '../../../widgets/common/app_scaffold.dart';
import '../../../widgets/common/premium_empty_state.dart';
import '../../../widgets/common/premium_page_header.dart';
import '../../../core/utils/haptic_engine.dart';

class MedBuddiesScreen extends StatefulWidget {
  const MedBuddiesScreen({super.key});

  @override
  State<MedBuddiesScreen> createState() => _MedBuddiesScreenState();
}

class _MedBuddiesScreenState extends State<MedBuddiesScreen> {
  Widget _entrance(Widget child, {Duration delay = Duration.zero}) {
    if (MedAiA11y.reducedMotion(context)) return child;
    return child
        .animate(delay: delay)
        .fadeIn(duration: AppDurations.fast, curve: AppCurves.smooth)
        .slideY(begin: 0.1, end: 0, curve: AppCurves.smooth);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final myStreak = state.getStreak();

    return AppScaffold(
      showAurora: true,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PremiumPageHeader(
              title: 'Med buddies',
              subtitle: 'Social accountability',
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                children: [
                  _entrance(
                    PremiumEmptyState(
                      title: 'No buddies connected yet',
                      subtitle:
                          'Invite a friend or caregiver to build accountability together. Your current streak is $myStreak days.',
                      icon: Icons.groups_rounded,
                      actionLabel: 'Invite buddy',
                      onAction: () {
                        HapticEngine.selection();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Buddy invite flow will be available soon.'),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
