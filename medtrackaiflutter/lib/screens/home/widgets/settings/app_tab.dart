import 'package:go_router/go_router.dart';
import '../../../../app/app_routes.dart';
import '../../../../widgets/common/permission_soft_prompt.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../../../providers/app_state.dart';
import '../../../settings/widgets/delete_account_dialog.dart';
import '../../../../theme/med_ai_ui.dart';
import '../../../../widgets/shared/shared_widgets.dart';
import 'settings_shared.dart';
import '../../../../services/share_service.dart';
import '../../../../services/referral_service.dart';
import '../../../../services/growth_tracker.dart';
import '../../../../widgets/common/paywall_sheet.dart';
import '../../../family/profile_switcher_sheet.dart';
import '../../../../core/utils/haptic_engine.dart';
import '../../../../l10n/app_localizations.dart';

class AppTab extends StatefulWidget {
  final AppState state;
  final AppThemeColors L;
  final VoidCallback onClose;

  const AppTab({
    super.key,
    required this.state,
    required this.L,
    required this.onClose,
  });

  @override
  State<AppTab> createState() => _AppTabState();
}

class _AppTabState extends State<AppTab> {
  int _leadMins = 0;
  final _leadOpts = [
    {"v": 0, "l": "On time"},
    {"v": 5, "l": "5 min early"},
    {"v": 10, "l": "10 min early"},
    {"v": 15, "l": "15 min early"}
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final L = widget.L;
    final profile = context.select<AppState, UserProfile?>((s) => s.profile);

    return SingleChildScrollView(
  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      physics:
          const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(0, AppSpacing.p4, 0, AppSpacing.p40),
      child: Column(children: [
        SettingsSection(
            title: l10n.homeNotifications,
            child: Column(children: [
              SettingsModalRow(
                  icon: '🔔',
                  iconBg: AppColors.dangerSoft.withValues(alpha: 0.1),
                  label: l10n.homeDoseReminders,
                  sub: 'Get notified when it\'s time',
                  right: AppToggle(
                      value: profile?.notifPerm ?? true,
                      onChanged: (v) {
                        final s = context.read<AppState>();
                        if (s.profile != null) {
                          s.saveProfile(s.profile!.copyWith(notifPerm: v));
                          // The neighbouring sound toggle already did this.
                          // Without it the preference was stored but nothing
                          // re-armed, so switching reminders off left every
                          // scheduled notification firing.
                          s.refreshNotifications();
                        }
                      }),
                  first: true,
                  border: true),
              SettingsModalRow(
                  icon: '🔊',
                  iconBg: AppColors.warningSoft.withValues(alpha: 0.1),
                  label: l10n.homeReminderSound,
                  sub: 'Play a sound with notifications',
                  right: AppToggle(
                      value: profile?.notifSound ?? true,
                      onChanged: (v) {
                        final s = context.read<AppState>();
                        if (s.profile != null) {
                          s.saveProfile(s.profile!.copyWith(notifSound: v));
                          s.refreshNotifications();
                        }
                      }),
                  border: true),
              SettingsModalRow(
                  icon: '⚡',
                  iconBg: AppColors.warningSoft.withValues(alpha: 0.1),
                  label: l10n.homeHaptics,
                  sub: 'Vibrate on taps and dose logging',
                  right: AppToggle(
                      value: profile?.hapticsEnabled ?? true,
                      onChanged: (v) {
                        final s = context.read<AppState>();
                        if (s.profile != null) {
                          // Apply immediately so the confirming tap itself
                          // respects the new setting.
                          HapticEngine.isEnabled = v;
                          if (v) HapticEngine.selection();
                          s.saveProfile(s.profile!.copyWith(hapticsEnabled: v));
                        }
                      }),
                  border: true),
              SettingsModalRow(
                  icon: '🔁',
                  iconBg: AppColors.dangerSoft.withValues(alpha: 0.1),
                  label: l10n.homePersistentAlarms,
                  sub: 'Ring until you respond (for critical meds)',
                  right: AppToggle(
                      value: profile?.reminderStyle == 'persistent',
                      onChanged: (v) {
                        final s = context.read<AppState>();
                        if (s.profile != null) {
                          s.saveProfile(s.profile!
                              .copyWith(reminderStyle: v ? 'persistent' : 'normal'));
                          s.refreshNotifications();
                        }
                      }),
                  border: true),
              SettingsModalRow(
                  icon: '⏰',
                  iconBg: AppColors.pastelSky,
                  label: l10n.homeRefillAlerts,
                  sub: 'Alert when meds run low',
                  right: AppToggle(
                      value: profile?.notifRefill ?? true,
                      onChanged: (v) {
                        final s = context.read<AppState>();
                        if (s.profile != null) {
                          s.saveProfile(s.profile!.copyWith(notifRefill: v));
                        }
                      }),
                  last: true,
                  border: false),
            ])),
        SettingsSection(
            title: l10n.homeReminderTiming,
            child: Column(
                children: _leadOpts.asMap().entries.map((e) {
              final o = e.value;
              return SettingsSelectRow(
                  label: o['l'] as String,
                  isSel: _leadMins == o['v'],
                  onClick: () => setState(() => _leadMins = o['v'] as int),
                  L: L,
                  first: e.key == 0,
                  last: e.key == _leadOpts.length - 1,
                  border: e.key < _leadOpts.length - 1);
            }).toList())),
        SettingsSection(
            title: l10n.homeCaregiverProfiles,
            child: SettingsModalRow(
                icon: '👨‍👩‍👧',
                iconBg: AppColors.successSoft.withValues(alpha: 0.1),
                label: l10n.homeFamilyDependents,
                sub: 'Manage meds for loved ones',
                onClick: () {
                  ProfileSwitcherSheet.show(context);
                },
                border: false)),
        SettingsSection(
            title: l10n.homeAestheticsTheme,
            child: SettingsModalRow(
                icon: '✨',
                iconBg: AppColors.pastelMint,
                label: l10n.homeAppAppearance,
                sub: 'Custom icons and themes',
                onClick: () {
                  HapticEngine.heavyImpact();
                  context.push(AppRoutes.settingsTheme);
                },
                border: false)),
        SettingsSection(
            title: l10n.homeHealthWellness,
            child: SettingsModalRow(
                icon: '❤️',
                iconBg: AppColors.pinkSystem.withValues(alpha: 0.1),
                label: l10n.dashboardConnectHealthData,
                sub: context.select<AppState, bool>((s) => s.health.isConnected)
                    ? 'Synced with ${defaultTargetPlatform == TargetPlatform.iOS ? 'Apple Health' : 'Health Connect'}'
                    : 'Sync vitals and activity data',
                right: AppToggle(
                    value: context
                        .select<AppState, bool>((s) => s.health.isConnected),
                    onChanged: (v) {
                      final s = context.read<AppState>();
                      if (v) {
                        PermissionSoftPrompt.show(
                          context: context,
                          title: l10n.homeHealthDataAccess,
                          explanation: 'Sync your vitals, sleep, and activity data for better insights.',
                          icon: Icons.favorite_rounded,
                          buttonText: 'Connect Health',
                          permission: null,
                          fallbackExplanation: 'Enable Health Access in settings.',
                          onGranted: () => s.health.connect(),
                        );
                      } else {
                        s.health.disconnect();
                      }
                    }),
                border: false)),
        SettingsSection(
            title: l10n.homeSecurity,
            child: SettingsModalRow(
                icon: '🔐',
                iconBg: L.text.withValues(alpha: 0.1),
                label: l10n.homeBiometricLock,
                sub: 'Unlock with FaceID / Fingerprint',
                right: AppToggle(
                    value: profile?.biometricEnabled ?? false,
                    onChanged: (v) {
                      final s = context.read<AppState>();
                      if (s.isPremium) {
                        s.toggleBiometricLock(v);
                      } else {
                        PaywallSheet.show(context);
                      }
                    }),
                border: false)),
        SettingsSection(
            title: l10n.homeSupportFeedback,
            child: MedAiGlass(
              padding: const EdgeInsets.all(AppSpacing.p24),
              radius: AppRadius.xl,
              child: Column(children: [
                Text(l10n.homeEnjoyingMedai,
                    style: AppTypography.titleLarge.copyWith(
                        fontWeight: FontWeight.w700,
                        color: L.text,
                        fontSize: 18)),
                const SizedBox(height: AppSpacing.p8),
                Text(l10n.homeYourFeedbackHelpsUsImproveFor,
                    style: AppTypography.bodySmall
                        .copyWith(color: L.sub, fontWeight: FontWeight.w600)),
                const SizedBox(height: AppSpacing.p20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p4),
                      child: Icon(Icons.star_rounded,
                          color: L.text, size: 32),
                    );
                  }),
                ),
                const SizedBox(height: AppSpacing.p24),
                MedAiCTA(
                  label: l10n.homeInviteFriendsGiveAFreeMonth,
                  semanticsLabel:
                      'Invite friends to MedAI and give them a free month',
                  onTap: () async {
                    HapticEngine.selection();
                    final code = await ReferralService.myCode();
                    await ShareService.shareReferral(
                      code,
                      userName: profile?.name,
                      inviteUrl: ReferralService.inviteUrl(code),
                    );
                    await ReferralService.incrementSentCount();
                    await GrowthTracker.trackReferralSent(source: 'settings');
                  },
                ),
              ]),
            )),
        SettingsSection(
            title: l10n.homeAppInfo,
            child: Column(children: [
              SettingsModalRow(
                  icon: '💊',
                  label: l10n.appTitle,
                  sub: 'Version 2.0 · Premium Enabled',
                  border: true),
              SettingsModalRow(
                  icon: '🛡️',
                  iconBg: AppColors.green.withValues(alpha: 0.1),
                  label: l10n.homePrivacy,
                  sub: 'Your data stays on this device',
                  onClick: () => context.push(AppRoutes.settingsPrivacy),
                  border: true),
              SettingsModalRow(
                  icon: 'ℹ️',
                  iconBg: AppColors.pastelMint,
                  label:
                      '${context.select<AppState, int>((s) => s.meds.length)} medicines tracked',
                  sub: 'Smart reminders active',
                  border: true),
              SettingsModalRow(
                  icon: '🗑️',
                  iconBg: AppColors.dangerSoft.withValues(alpha: 0.1),
                  label: l10n.homeDeleteAccount,
                  sub: 'Erase all medicines and history — permanent',
                  // This row had its own dialog whose "Delete" button showed
                  // "Account scheduled for deletion within 30 days." and then
                  // did nothing at all — no deletion was ever requested. A
                  // user who wanted their health data gone was told it would
                  // be, and it stayed. Now it runs the same typed-confirmation
                  // path as the profile screen.
                  onClick: () async {
                    final confirmed = await DeleteAccountDialog.show(context);
                    if (!context.mounted || !confirmed) return;
                    await context.read<AppState>().deleteAccount();
                  },
                  border: false),
            ])),
        const SizedBox(height: 120),
      ]),
    );
  }
}
