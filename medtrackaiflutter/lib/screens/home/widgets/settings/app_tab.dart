import 'package:go_router/go_router.dart';
import '../../../../app/app_routes.dart';
import '../../../../widgets/common/permission_soft_prompt.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../../../providers/app_state.dart';
import '../../../../theme/med_ai_ui.dart';
import '../../../../widgets/shared/shared_widgets.dart';
import 'settings_shared.dart';
import '../../../../services/share_service.dart';
import '../../../../services/referral_service.dart';
import '../../../../services/growth_tracker.dart';
import '../../../../widgets/common/paywall_sheet.dart';
import '../../../family/profile_switcher_sheet.dart';
import '../../../../core/utils/haptic_engine.dart';

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
    final L = widget.L;
    final profile = context.select<AppState, UserProfile?>((s) => s.profile);

    return SingleChildScrollView(
  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      physics:
          const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 40),
      child: Column(children: [
        SettingsSection(
            title: 'Notifications',
            child: Column(children: [
              SettingsModalRow(
                  icon: '🔔',
                  iconBg: const Color(0xFFEF4444).withValues(alpha: 0.1),
                  label: 'Dose Reminders',
                  sub: 'Get notified when it\'s time',
                  right: AppToggle(
                      value: profile?.notifPerm ?? true,
                      onChanged: (v) {
                        final s = context.read<AppState>();
                        if (s.profile != null) {
                          s.saveProfile(s.profile!.copyWith(notifPerm: v));
                        }
                      }),
                  first: true,
                  border: true),
              SettingsModalRow(
                  icon: '⚡',
                  iconBg: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                  label: 'Sound & Haptics',
                  sub: 'Vibrate and play sound',
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
                  icon: '🔁',
                  iconBg: const Color(0xFFEF4444).withValues(alpha: 0.1),
                  label: 'Persistent Alarms',
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
                  iconBg: const Color(0xFF6366F1).withValues(alpha: 0.1),
                  label: 'Refill Alerts',
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
            title: 'Reminder Timing',
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
            title: 'Caregiver & Profiles',
            child: SettingsModalRow(
                icon: '👨‍👩‍👧',
                iconBg: const Color(0xFF10B981).withValues(alpha: 0.1),
                label: 'Family & Dependents',
                sub: 'Manage meds for loved ones',
                onClick: () {
                  ProfileSwitcherSheet.show(context);
                },
                border: false)),
        SettingsSection(
            title: 'Aesthetics & Theme',
            child: SettingsModalRow(
                icon: '✨',
                iconBg: const Color(0xFFE879F9).withValues(alpha: 0.1),
                label: 'App Appearance',
                sub: 'Custom icons and themes',
                onClick: () {
                  HapticEngine.heavyImpact();
                  context.push(AppRoutes.settingsTheme);
                },
                border: false)),
        SettingsSection(
            title: 'Health & Wellness',
            child: SettingsModalRow(
                icon: '❤️',
                iconBg: const Color(0xFFFF2D55).withValues(alpha: 0.1),
                label: 'Connect Health Data',
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
                          title: 'Health Data Access',
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
            title: 'Security',
            child: SettingsModalRow(
                icon: '🔐',
                iconBg: L.text.withValues(alpha: 0.1),
                label: 'Biometric Lock',
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
            title: 'Support & Feedback',
            child: MedAiGlass(
              padding: const EdgeInsets.all(24),
              radius: AppRadius.xl,
              child: Column(children: [
                Text('Enjoying MedAI?',
                    style: AppTypography.titleLarge.copyWith(
                        fontWeight: FontWeight.w800,
                        color: L.text,
                        fontSize: 18)),
                const SizedBox(height: 6),
                Text('Your feedback helps us improve for everyone.',
                    style: AppTypography.bodySmall
                        .copyWith(color: L.sub, fontWeight: FontWeight.w600)),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(Icons.star_rounded,
                          color: L.text, size: 32),
                    );
                  }),
                ),
                const SizedBox(height: 24),
                MedAiCTA(
                  label: 'Invite friends — give a free month',
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
            title: 'App Info',
            child: Column(children: [
              const SettingsModalRow(
                  icon: '💊',
                  label: 'MedAI',
                  sub: 'Version 2.0 · Premium Enabled',
                  border: true),
              SettingsModalRow(
                  icon: '🛡️',
                  iconBg: const Color(0xFF22C55E).withValues(alpha: 0.1),
                  label: 'Privacy',
                  sub: 'Your data stays on this device',
                  onClick: () => context.push(AppRoutes.settingsPrivacy),
                  border: true),
              SettingsModalRow(
                  icon: 'ℹ️',
                  iconBg: const Color(0xFF6366F1).withValues(alpha: 0.1),
                  label:
                      '${context.select<AppState, int>((s) => s.meds.length)} medicines tracked',
                  sub: 'Smart reminders active',
                  border: true),
              SettingsModalRow(
                  icon: '🗑️',
                  iconBg: const Color(0xFFEF4444).withValues(alpha: 0.1),
                  label: 'Delete Account',
                  sub: 'Permanently erase your data',
                  onClick: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: L.card,
                        title: Text('Delete Account', style: AppTypography.titleMedium.copyWith(color: L.text)),
                        content: Text('Are you sure you want to permanently delete your account and all data? This action cannot be undone.', style: AppTypography.bodyMedium.copyWith(color: L.sub)),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: L.text))),
                          TextButton(onPressed: () {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account scheduled for deletion within 30 days.')));
                          }, child: const Text('Delete', style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    );
                  },
                  border: false),
            ])),
        const SizedBox(height: 120),
      ]),
    );
  }
}
