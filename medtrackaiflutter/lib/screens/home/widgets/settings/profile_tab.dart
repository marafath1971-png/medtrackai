import 'package:go_router/go_router.dart';
import '../../../../app/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../providers/app_state.dart';
import '../../../../theme/med_ai_ui.dart';
import '../../../../widgets/common/animated_pressable.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/export_service.dart';
import '../../../../widgets/common/paywall_sheet.dart';
import 'settings_shared.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/utils/haptic_engine.dart';

class ProfileTab extends StatefulWidget {
  final AppState state;
  final AppThemeColors L;

  const ProfileTab({
    super.key,
    required this.state,
    required this.L,
  });

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  late TextEditingController _nameCtrl;
  late TextEditingController _ageCtrl;
  String? _genderInput;
  String? _goalInput;
  String? _countryInput;
  bool _editing = false;

  final genders = ["Male", "Female", "Non-binary", "Prefer not to say"];
  final goals = [
    "Manage chronic condition",
    "Stay on top of prescriptions",
    "Support family member",
    "Post-surgery recovery",
    "General wellness",
    "Mental health support"
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.state.profile;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _ageCtrl = TextEditingController(text: p?.age ?? '');
    _genderInput = p?.gender;
    _goalInput = p?.goal;
    _countryInput = p?.country;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
  }

  Widget _maybeShimmerRow(
      bool reduceMotion, Widget row, AppThemeColors L) {
    return row;
  }

  Widget _upgradeCard(
      AppThemeColors L, bool reduceMotion, BuildContext context) {
    final card = Semantics(
      button: true,
      label: 'Upgrade to MedAI Pro',
      child: AnimatedPressable(
        onTap: () {
          HapticEngine.selection();
          PaywallSheet.show(context);
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(AppSpacing.p20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.lime, AppColors.limeDeep],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.limeDeep.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.75),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.workspace_premium_rounded,
                  size: 24,
                  color: AppColors.limeInk,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.p16),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('Your success plan',
                      style: AppTypography.titleLarge.copyWith(
                          color: AppColors.limeInk,
                          fontSize: 18,
                          letterSpacing: -0.4,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: AppSpacing.p4),
                  Text('Unlock AI insights, family care & unlimited scans.',
                      style: AppTypography.labelSmall.copyWith(
                          color: AppColors.limeInk.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.1)),
                ])),
            Icon(Icons.arrow_outward_rounded,
                color: AppColors.limeInk.withValues(alpha: 0.7), size: 20),
          ]),
        ),
      ),
    );

    return card;
  }

  void _confirmDeleteAccount(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: widget.L.bg,
        title: Text('Delete Account?',
            style: AppTypography.titleLarge
                .copyWith(color: widget.L.text, fontWeight: FontWeight.w800)),
        content: Text(
          'This action is permanent and will delete all your medication history and account data from our servers.',
          style: AppTypography.bodyMedium.copyWith(color: widget.L.sub),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: AppTypography.labelLarge.copyWith(color: widget.L.sub)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.state.deleteAccount();
            },
            child: Text('Delete',
                style: AppTypography.labelLarge.copyWith(color: AppColors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.state.profile;
    final L = widget.L;
    final s = AppLocalizations.of(context)!;
    final reduceMotion = MedAiA11y.reducedMotion(context);

    final avatarEmoji = Text(p?.avatar ?? '😊',
        style: AppTypography.displaySmall.copyWith(fontSize: 36));

    Widget heroCard = MedAiDepthCard(
      padding: const EdgeInsets.all(AppSpacing.p24),
      child: Row(children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
              color: L.fill.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: L.border.withValues(alpha: 0.1))),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Center(
                child: p?.photoUrl != null
                    ? Image.network(
                        p!.photoUrl!,
                        fit: BoxFit.cover,
                        width: 72,
                        height: 72,
                        errorBuilder: (_, __, ___) => Text(p.avatar,
                            style: AppTypography.displaySmall
                                .copyWith(fontSize: 36)),
                      )
                    : avatarEmoji),
          ),
        ),
        const SizedBox(width: AppSpacing.p20),
        Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Row(
                children: [
                  Flexible(
                    child: Text(p?.name ?? 'Your Name',
                        style: AppTypography.titleLarge.copyWith(
                            fontWeight: FontWeight.w800,
                            color: L.text,
                            fontSize: 22,
                            letterSpacing: -0.5)),
                  ),
                  if (widget.state.isPremium) ...[
                    const SizedBox(width: AppSpacing.p8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.p8, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.amber, Colors.orangeAccent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('PRO',
                          style: AppTypography.labelSmall.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 10,
                              color: Colors.black,
                              letterSpacing: 0.5)),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.p8),
              Text(
                  '${p?.age != null && p!.age.isNotEmpty ? "Age ${p.age}" : "Age not set"}${p?.gender != null && p!.gender.isNotEmpty ? " · ${p.gender}" : ""}',
                  style: AppTypography.bodySmall.copyWith(
                      color: L.sub.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w700)),
            ])),
        if (!_editing)
          Semantics(
            button: true,
            label: s.edit,
            child: AnimatedPressable(
              onTap: () {
                HapticEngine.selection();
                setState(() => _editing = true);
              },
              scaleFactor: 0.96,
              child: Container(
                constraints:
                    const BoxConstraints(minHeight: MedAiA11y.minTapTarget),
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.p16, vertical: AppSpacing.p12),
                decoration: BoxDecoration(
                    color: L.fill.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: L.border.withValues(alpha: 0.1))),
                child: Text(s.edit,
                    style: AppTypography.labelLarge.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        letterSpacing: 0.1,
                        color: L.text)),
              ),
            ),
          ),
      ]),
    );
    if (!reduceMotion) {
      heroCard = heroCard
          .animate()
          .fade(duration: AppDurations.fast)
          .slideY(begin: 0.1, end: 0, curve: AppCurves.smooth);
    }

    return SingleChildScrollView(
  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      physics:
          const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(0, AppSpacing.p4, 0, AppSpacing.p40),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p16),
            child: heroCard,
          ),
          const SizedBox(height: AppSpacing.p20),

          // ── APP SETTINGS (GLOBAL AUTHORITY) ──────────
          SettingsSection(
            title: 'App Settings',
            child: Column(children: [
              _maybeShimmerRow(
                reduceMotion,
                SettingsModalRow(
                  icon: '🌐',
                  label: s.globalSettings,
                  sub: s.globalSettingsSubtitle,
                  onClick: () {
                    context.push(AppRoutes.settingsGlobal);
                  },
                  first: true,
                  last: true,
                  border: false,
                ),
                L,
              ),
            ]),
          ),
          const SizedBox(height: AppSpacing.p24),

          if (_editing) ...[
            SettingsSection(
                title: s.editProfile,
                child: Column(children: [
                  SettingsEditField(
                      label: 'Name',
                      ctrl: _nameCtrl,
                      placeholder: 'Your name',
                      L: L),
                  SettingsEditField(
                      label: 'Age',
                      ctrl: _ageCtrl,
                      placeholder: 'e.g. 35',
                      L: L,
                      keyboard: TextInputType.number,
                      border: false),
                ])),
            SettingsSection(
                title: 'Gender',
                child: Column(
                    children: genders
                        .asMap()
                        .entries
                        .map((e) => SettingsSelectRow(
                            label: e.value,
                            isSel: _genderInput == e.value,
                            onClick: () =>
                                setState(() => _genderInput = e.value),
                            L: L,
                            first: e.key == 0,
                            last: e.key == genders.length - 1,
                            border: e.key < genders.length - 1))
                        .toList())),
            SettingsSection(
                title: 'Primary Goal',
                child: Column(
                    children: goals
                        .asMap()
                        .entries
                        .map((e) => SettingsSelectRow(
                            label: e.value,
                            isSel: _goalInput == e.value,
                            onClick: () => setState(() => _goalInput = e.value),
                            L: L,
                            first: e.key == 0,
                            last: e.key == goals.length - 1,
                            border: e.key < goals.length - 1))
                        .toList())),
            // Removed redundant country selector from edit form to consolidate in Global Settings
            Row(children: [
              Expanded(
                child: MedAiCTA(
                  label: s.cancel,
                  secondary: true,
                  onTap: () {
                    HapticEngine.selection();
                    setState(() {
                      _editing = false;
                      _nameCtrl.text = p?.name ?? '';
                      _ageCtrl.text = p?.age ?? '';
                      _genderInput = p?.gender;
                      _goalInput = p?.goal;
                      _countryInput = p?.country;
                    });
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.p8),
              Expanded(
                flex: 2,
                child: MedAiCTA(
                  label: 'Save changes',
                  semanticsLabel: 'Save profile changes',
                  onTap: () {
                    HapticEngine.success();
                    final newProfile = p?.copyWith(
                            name: _nameCtrl.text,
                            age: _ageCtrl.text,
                            gender: _genderInput,
                            goal: _goalInput,
                            country: _countryInput) ??
                        UserProfile(
                            name: _nameCtrl.text,
                            age: _ageCtrl.text,
                            gender: _genderInput ?? '',
                            goal: _goalInput ?? '',
                            avatar: '😊',
                            conditions: const [],
                            notifPerm: true);
                    widget.state.saveProfile(newProfile);
                    setState(() => _editing = false);
                  },
                ),
              ),
            ]),
            const SizedBox(height: AppSpacing.p24),
          ] else ...[
            SettingsSection(
                title: 'Your Info',
                child: Column(children: [
                  SettingsModalRow(
                      icon: '🎯',
                      label: 'Health Goal',
                      sub: p?.goal ?? 'Not set',
                      first: true,
                      border: true),
                  SettingsModalRow(
                      icon: '🩺',
                      label: 'Conditions',
                      sub: p?.conditions.isNotEmpty == true
                          ? p!.conditions.join(", ")
                          : 'Not set',
                      border: true),
                  SettingsModalRow(
                      icon: '🎂',
                      label: 'Age',
                      sub: p?.age != null && p!.age.isNotEmpty
                          ? '${p.age} years old'
                          : 'Not set',
                      border: true),
                  SettingsModalRow(
                      icon: '🧬',
                      label: 'Gender',
                      sub: p?.gender ?? 'Not set',
                      last: true,
                      border: false),
                ])),
            if (!widget.state.isPremium)
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.p16, 0, AppSpacing.p16, AppSpacing.p24),
                child: _upgradeCard(L, reduceMotion, context),
              ),
            SettingsSection(
              title: 'Subscription',
              child: Column(children: [
                if (widget.state.isPremium)
                  SettingsModalRow(
                    icon: '💳',
                    label: 'Manage Subscription',
                    sub: 'View or cancel your plan',
                    onClick: () => widget.state.manageSubscription(),
                    first: true,
                    border: true,
                  ),
                SettingsModalRow(
                  icon: '🔄',
                  label: 'Restore Purchases',
                  sub: 'Already paid? Restore here',
                  onClick: () => widget.state.restorePurchases(),
                  first: !widget.state.isPremium,
                  last: true,
                  border: false,
                ),
              ]),
            ),
            // Moved to top as primary section
            SettingsSection(
              title: 'Data & Reports',
              child: Column(children: [
                SettingsModalRow(
                  icon: Icons.assignment_rounded,
                  label: 'Clinical PDF Report',
                  sub: 'Generate a summary for your doctor',
                  onClick: () async {
                    final ok = await ExportService.exportAdherenceReport(
                        widget.state);
                    if (!ok && context.mounted) {
                      PaywallSheet.show(context);
                    }
                  },
                  first: true,
                  border: true,
                ),
                SettingsModalRow(
                  icon: '🎬',
                  label: 'Med Wrapped 2026',
                  sub: 'View your yearly consistency slideshow',
                  onClick: () {
                    HapticEngine.selection();
                    context.push(AppRoutes.statsMedWrapped);
                  },
                  border: true,
                ),
                SettingsModalRow(
                  icon: '📊',
                  label: 'Export CSV Data',
                  sub: 'Download raw history for backup',
                  onClick: () => widget.state.exportDataCSV(),
                  last: true,
                  border: false,
                ),
              ]),
            ),
            SettingsSection(
              title: 'Account',
              child: Column(
                children: [
                  if (AuthService.isLoggedIn) ...[
                    SettingsModalRow(
                      icon: '🚪',
                      label: 'Sign Out',
                      sub: AuthService.email,
                      onClick: () {
                        HapticEngine.selection();
                        widget.state.signOut();
                      },
                      first: true,
                      border: true,
                    ),
                    SettingsModalRow(
                      icon: '🗑️',
                      label: 'Delete Account',
                      sub: 'Permanently remove your data',
                      iconBg: L.red,
                      onClick: () => _confirmDeleteAccount(context),
                      last: true,
                      border: false,
                    ),
                  ] else ...[
                    SettingsModalRow(
                      icon: '🌐',
                      label: 'Sign in with Google',
                      onClick: () => widget.state.signInWithGoogle(),
                      first: true,
                      border: true,
                    ),
                    SettingsModalRow(
                      icon: Icons.apple_rounded,
                      label: 'Sign in with Apple',
                      onClick: () => widget.state.signInWithApple(),
                      last: true,
                      border: false,
                    ),
                  ],
                ],
              ),
            ),
            SettingsSection(
              title: 'Support & Feedback',
              child: Column(children: [
                SettingsModalRow(
                  icon: '💬',
                  label: 'Contact Support',
                  sub: 'Get help with your account',
                  onClick: () => widget.state.contactSupport(),
                  first: true,
                  border: true,
                ),
                SettingsModalRow(
                  icon: '⭐',
                  label: 'Rate MedAI',
                  sub: 'Help us improve for others',
                  onClick: () => widget.state.requestReview(),
                  last: true,
                  border: false,
                ),
              ]),
            ),
            SettingsSection(
              title: 'Legal & Privacy',
              child: Column(children: [
                SettingsModalRow(
                  icon: '🔐',
                  label: 'Privacy Policy',
                  sub: 'How we protect your data',
                  onClick: () => widget.state.openPrivacyPolicy(),
                  first: true,
                  border: true,
                ),
                SettingsModalRow(
                  icon: '📜',
                  label: 'Terms of Service',
                  sub: 'Your rights and responsibilities',
                  onClick: () => widget.state.openTermsOfService(),
                  border: true,
                ),
                SettingsModalRow(
                  icon: 'ℹ️',
                  label: 'Open Source Licenses',
                  sub: 'Software that makes MedAI possible',
                  onClick: () => showLicensePage(context: context),
                  last: true,
                  border: false,
                ),
              ]),
            ),
            if (kDebugMode)
              SettingsSection(
                title: 'Developer Options',
                child: Column(
                  children: [
                    SettingsModalRow(
                      icon: '🚀',
                      label: 'Growth & Analytics Dashboard',
                      sub: 'Funnel analytics and mock simulator',
                      onClick: () {
                        HapticEngine.selection();
                        context.push(AppRoutes.adminGrowth);
                      },
                      first: true,
                      last: true,
                      border: false,
                    ),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.p12),
            Center(
              child: Column(
                children: [
                  Text(
                    'MedAI 1.0.0+1',
                    style: AppTypography.labelSmall.copyWith(color: L.sub.withValues(alpha: 0.4),
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.p4),
                  Text(
                    'Made by the MedAI team',
                    style: AppTypography.labelSmall.copyWith(
                      color: L.sub.withValues(alpha: 0.3),
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 140),
          ],
        ],
      ),
    );
  }
}
