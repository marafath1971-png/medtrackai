import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../providers/app_state.dart';
import '../../../theme/med_ai_ui.dart';
import '../../../widgets/common/app_scaffold.dart';
import '../../../widgets/common/premium_empty_state.dart';
import '../../../widgets/common/premium_page_header.dart';
import '../../../core/utils/haptic_engine.dart';
import '../../../core/utils/logger.dart';
import '../../../services/growth_tracker.dart';
import '../../../services/referral_service.dart';
import '../../../services/share_service.dart';
import '../../l10n/app_localizations.dart';

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

  bool _sending = false;

  /// Shares a real referral link, the same flow the settings screen uses.
  Future<void> _inviteBuddy(AppState state) async {
    // The share sheet is a platform call that can take a moment to appear;
    // without this guard an impatient double-tap sends two invites and
    // double-counts the referral.
    if (_sending) return;
    setState(() => _sending = true);
    HapticEngine.selection();

    try {
      final code = await ReferralService.myCode();
      await ShareService.shareReferral(
        code,
        userName: state.profile?.name,
        inviteUrl: ReferralService.inviteUrl(code),
      );
      await ReferralService.incrementSentCount();
      await GrowthTracker.trackReferralSent(source: 'buddies');
    } catch (e) {
      appLogger.w('[MedBuddies] invite share failed: $e');
      if (mounted) {
        state.showToast('Could not open sharing. Please try again.',
            type: 'error');
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = context.watch<AppState>();
    final myStreak = state.getStreak();

    return AppScaffold(
      showAurora: true,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PremiumPageHeader(
              title: l10n.socialMedBuddies,
              subtitle: 'Social accountability',
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                children: [
                  _entrance(
                    PremiumEmptyState(
                      title: l10n.socialNoBuddiesConnectedYet,
                      subtitle: l10n.socialInviteAFriendOrCaregiverTo(myStreak),
                      mascotFeature: 'community',
                      icon: Icons.groups_rounded,
                      actionLabel: 'Invite buddy',
                      // This used to show a "Buddy invite coming soon" toast
                      // while ReferralService — code generation, invite URLs,
                      // send tracking — sat fully built beside it, already
                      // wired up in settings. The only thing missing was the
                      // call. A dead end on the one screen whose entire
                      // purpose is inviting someone.
                      onAction: () => _inviteBuddy(state),
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
