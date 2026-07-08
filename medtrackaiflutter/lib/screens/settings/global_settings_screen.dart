import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../app/app_routes.dart';
import '../../services/smart_alert_service.dart';
import '../../providers/app_state.dart';
import '../../theme/med_ai_ui.dart';
import '../../l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../widgets/shared/shared_widgets.dart';
import '../../core/utils/haptic_engine.dart';
import '../../models/constants.dart';
import '../../widgets/common/refined_sheet_wrapper.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/common/premium_page_header.dart';
import '../../core/constants/premium_graphics.dart';
import '../../widgets/common/premium_illustration_banner.dart';
// ══════════════════════════════════════════════════════════════════════
// GLOBAL SETTINGS SCREEN (Cal AI Industrial Authority Refined)
// ══════════════════════════════════════════════════════════════════════

class GlobalSettingsScreen extends StatefulWidget {
  /// When true, hides the floating glass header (shown inside settings modal).
  final bool embedded;

  const GlobalSettingsScreen({super.key, this.embedded = false});

  @override
  State<GlobalSettingsScreen> createState() => _GlobalSettingsScreenState();
}

class _GlobalSettingsScreenState extends State<GlobalSettingsScreen> {
  late UserProfile _profile;

  // Using global kCountries and local _languages
  static const List<Map<String, String>> _languages = [
    {'code': 'en', 'label': 'English', 'flag': '🇺🇸'},
    {'code': 'es', 'label': 'Español (Spanish)', 'flag': '🇪🇸'},
    {'code': 'fr', 'label': 'Français (French)', 'flag': '🇫🇷'},
    {'code': 'ja', 'label': '日本語 (Japanese)', 'flag': '🇯🇵'},
    {'code': 'ko', 'label': '한국어 (Korean)', 'flag': '🇰🇷'},
    {'code': 'ms', 'label': 'Bahasa Melayu', 'flag': '🇲🇾'},
  ];

  @override
  void initState() {
    super.initState();
    _profile = context.read<AppState>().profile ?? UserProfile();
  }

  Future<void> _save(UserProfile updated) async {
    HapticEngine.selection();
    setState(() => _profile = updated);
    await context.read<AppState>().saveProfile(updated);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final s = AppLocalizations.of(context)!;
    final L = context.L;

    return AppScaffold(
      showAurora: true,
      backgroundColor: _profile.amoledMode && isDark ? Colors.black : L.bg,
      body: CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          if (!widget.embedded)
            SliverToBoxAdapter(
              child: PremiumPageHeader(
                title: 'Settings',
                subtitle: 'Preferences & account',
                onBack: Navigator.canPop(context)
                    ? () => Navigator.pop(context)
                    : null,
              ),
            ),
          if (!widget.embedded)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: PremiumIllustrationBanner(
                  asset: PremiumGraphics.paywallPro,
                  height: 110,
                  padding: EdgeInsets.all(14),
                ),
              ),
            ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              20,
              widget.embedded ? 8 : 0,
              20,
              120,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
              // ── LOCALIZATION BLOCK ───────────────────────
              _IndustrialSection(
                label: 'Localization',
                icon: Icons.language_rounded,
                L: L,
                children: [
                  _PickerTile(
                    label: s.country,
                    value: kCountries.firstWhere(
                        (c) => c['c'] == _profile.country,
                        orElse: () => kCountries[0])['v']!,
                    flag: kCountries.firstWhere(
                        (c) => c['c'] == _profile.country,
                        orElse: () => kCountries[0])['e']!,
                    onTap: () async {
                      final res = await showModalBottomSheet<String>(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => _PickerSheet(
                            title: s.selectCountry,
                            items: kCountries
                                .map((c) => {
                                      'code': c['c']!,
                                      'label': c['v']!,
                                      'flag': c['e']!
                                    })
                                .toList(),
                            selectedCode: _profile.country),
                      );
                      if (!mounted || res == null) return;
                      _save(_profile.copyWith(country: res));
                    },
                    L: L,
                  ),
                  _PickerTile(
                    label: s.language,
                    value: _languages.firstWhere(
                        (l) => l['code'] == _profile.preferredLanguage,
                        orElse: () => _languages[0])['label']!,
                    flag: _languages.firstWhere(
                        (l) => l['code'] == _profile.preferredLanguage,
                        orElse: () => _languages[0])['flag']!,
                    onTap: () async {
                      final res = await showModalBottomSheet<String>(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => _PickerSheet(
                            title: s.selectLanguage,
                            items: _languages,
                            selectedCode: _profile.preferredLanguage),
                      );
                      if (!mounted || res == null) return;
                      _save(_profile.copyWith(preferredLanguage: res));
                    },
                    L: L,
                    isLast: true,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── CLINICAL MODES BLOCK ─────────────────────
              _IndustrialSection(
                label: 'Clinical modes',
                icon: Icons.science_rounded,
                L: L,
                children: [
                  _ToggleTile(
                    title: s.showGenericNames,
                    subtitle: s.showGenericNamesSubtitle,
                    value: _profile.showGenericNames,
                    onChanged: (v) =>
                        _save(_profile.copyWith(showGenericNames: v)),
                    L: L,
                  ),
                  _ToggleTile(
                    title: s.shabbatMode,
                    subtitle: s.shabbatModeSubtitle,
                    value: _profile.shabbatMode,
                    onChanged: (v) => _save(_profile.copyWith(shabbatMode: v)),
                    L: L,
                  ),
                  _ToggleTile(
                    title: 'Diabetes Metrics',
                    subtitle: 'Synchronize blood glucose logs',
                    value: _profile.diabetesMode,
                    onChanged: (v) => _save(_profile.copyWith(diabetesMode: v)),
                    L: L,
                  ),
                  _ToggleTile(
                    title: 'Hypertension Tracking',
                    subtitle: 'Synchronize systolic/diastolic logs',
                    value: _profile.hypertensionMode,
                    onChanged: (v) =>
                        _save(_profile.copyWith(hypertensionMode: v)),
                    L: L,
                    isLast: true,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── VITAL CONNECTIVITY BLOCK ─────────────────
              _IndustrialSection(
                label: 'Vital connectivity',
                icon: Icons.favorite_rounded,
                L: L,
                children: [
                  _ToggleTile(
                    title: 'Auto-Sync Health',
                    subtitle: 'Keep vitals synchronized in background',
                    value: context.watch<AppState>().healthAutoSync,
                    onChanged: (v) =>
                        context.read<AppState>().setHealthAutoSync(v),
                    L: L,
                    isLast: true,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── ACCOUNT ARCHITECTURE BLOCK ───────────────
              _IndustrialSection(
                label: 'Account',
                icon: Icons.manage_accounts_rounded,
                L: L,
                children: [
                  _AccountActionTile(
                    icon: Icons.upload_rounded,
                    title: 'Export Health Data (CSV)',
                    subtitle: 'Generate a clinical report of your vitals',
                    onTap: () {
                      HapticEngine.selection();
                      context.read<AppState>().exportDataCSV();
                    },
                    L: L,
                  ),
                  _AccountActionTile(
                    icon: Icons.cleaning_services_rounded,
                    title: 'Clear Local Cache',
                    subtitle: 'Free up space and refresh local state',
                    onTap: () => _confirmReset(context, L),
                    L: L,
                  ),
                  _AccountActionTile(
                    icon: Icons.delete_forever_rounded,
                    title: 'Delete Account Permanently',
                    subtitle: 'Erase all personal health records',
                    color: L.error,
                    isLast: true,
                    onTap: () => _confirmDelete(context, L),
                    L: L,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── SYSTEM BLOCK ─────────────────────────────
              _IndustrialSection(
                label: 'System',
                icon: Icons.settings_rounded,
                L: L,
                children: [
                  _AccountActionTile(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    onTap: () {
                      HapticEngine.selection();
                      context.push(AppRoutes.settingsPrivacy);
                    },
                    L: L,
                  ),
                  _AccountActionTile(
                    icon: Icons.gavel_rounded,
                    title: 'Terms of Service',
                    onTap: () {
                      HapticEngine.selection();
                      context.push(AppRoutes.settingsTerms);
                    },
                    L: L,
                  ),
                  _AccountActionTile(
                    icon: Icons.support_agent_rounded,
                    title: 'Support & Feedback',
                    subtitle: 'Get help or send us feedback',
                    isLast: true,
                    onTap: () async {
                      HapticEngine.selection();
                      final url = Uri.parse(kSupportUrl);
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      } else {
                        if (context.mounted) {
                          SmartAlertService.show(
                            context,
                            title: 'Contact Support',
                            message: 'Email us at $kSupportEmail',
                            type: AlertType.info,
                          );
                        }
                      }
                    },
                    L: L,
                  ),
                ],
              ),

              const SizedBox(height: 48),

              // ── SYSTEM INTEGRITY FOOTER ──
              Center(
                child: Column(
                  children: [
                    Text(
                      kAppName.toUpperCase(),
                      style: AppTypography.labelSmall.copyWith(
                        color: L.text.withValues(alpha: 0.15),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4.0,
                        fontSize: 9,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'VERSION $kAppVersion • STABLE',
                      style: AppTypography.labelSmall.copyWith(
                        color: L.text.withValues(alpha: 0.1),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        fontSize: 8,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 120),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context, AppThemeColors L) {
    HapticEngine.alertWarning();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: L.bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Reset cache?',
            style: AppTypography.titleLarge
                .copyWith(fontWeight: FontWeight.w800, color: L.text)),
        content: Text(
            'This will clear local temporary files. Your medications and health records will remain safe.',
            style: AppTypography.bodySmall
                .copyWith(color: L.text.withValues(alpha: 0.7), height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: AppTypography.labelLarge.copyWith(color: L.sub)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AppState>().showToast('Cache cleared successfully');
            },
            child: Text('Reset',
                style: AppTypography.labelLarge
                    .copyWith(color: L.text, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, AppThemeColors L) {
    HapticEngine.heavyImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: L.bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('DELETE ACCOUNT?',
            style: AppTypography.titleLarge.copyWith(
                fontWeight: FontWeight.w900, color: L.error)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'This action is irreversible. All health data, medication history, and vitals will be permanently erased.',
                style: AppTypography.bodySmall
                    .copyWith(color: L.text.withValues(alpha: 0.7), height: 1.5)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: L.error.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: L.error.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Text('⚠️', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('PERMANENT ACTION: ACCOUNT DELETION',
                        style: AppTypography.labelSmall.copyWith(
                            color: L.error,
                            fontWeight: FontWeight.w900,
                            fontSize: 9,
                            letterSpacing: 1.0)),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('CANCEL',
                style: AppTypography.labelLarge.copyWith(color: L.sub)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AppState>().deleteAccount();
            },
            child: Text('CONFIRM DELETE',
                style: AppTypography.labelLarge.copyWith(
                    color: L.error, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}

// ── Account Action Tile ───────────────────────────────────────────────
class _AccountActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? color;
  final VoidCallback onTap;
  final AppThemeColors L;
  final bool isLast;
  const _AccountActionTile(
      {required this.icon,
      required this.title,
      this.subtitle,
      this.color,
      required this.onTap,
      required this.L,
      this.isLast = false});

  @override
  Widget build(BuildContext context) {
    final tileColor = color ?? L.text;
    return Semantics(
      button: true,
      label: subtitle != null ? '$title. $subtitle' : title,
      child: AnimatedPressable(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: MedAiA11y.minTapTarget),
          decoration: BoxDecoration(
              border: isLast
                  ? null
                  : Border(
                      bottom: BorderSide(
                          color: L.border.withValues(alpha: 0.08),
                          width: 0.5))),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: tileColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: tileColor, size: 20),
            ),
            title: Text(
              title,
              style: AppTypography.labelLarge.copyWith(
                  color: tileColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  letterSpacing: -0.1),
            ),
            subtitle: subtitle != null
                ? Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(subtitle!,
                        style: AppTypography.bodySmall.copyWith(
                            color: L.text.withValues(alpha: 0.5),
                            fontWeight: FontWeight.w500,
                            fontSize: 11)),
                  )
                : null,
            trailing: Icon(Icons.chevron_right_rounded,
                color: L.sub.withValues(alpha: 0.4), size: 22),
          ),
        ),
      ),
    );
  }
}

class _IndustrialSection extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<Widget> children;
  final AppThemeColors L;
  const _IndustrialSection(
      {required this.label,
      required this.icon,
      required this.children,
      required this.L});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MedAiSectionHeader(title: label),
        MedAiDepthCard(
          padding: EdgeInsets.zero,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final String title, subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final AppThemeColors L;
  final bool isLast;
  const _ToggleTile(
      {required this.title,
      required this.subtitle,
      required this.value,
      required this.onChanged,
      required this.L,
      this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$title. $subtitle',
      toggled: value,
      child: Container(
        constraints: const BoxConstraints(minHeight: MedAiA11y.minTapTarget),
        decoration: BoxDecoration(
            border: isLast
                ? null
                : Border(
                    bottom: BorderSide(
                        color: L.border.withValues(alpha: 0.08), width: 0.5))),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          title: Text(title,
              style: AppTypography.labelLarge.copyWith(
                color: L.text,
                fontWeight: FontWeight.w700,
                fontSize: 15,
                letterSpacing: -0.2,
              )),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(subtitle,
                style: AppTypography.bodySmall.copyWith(
                    color: L.text.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                    fontSize: 12)),
          ),
          trailing: AppToggle(
            value: value,
            onChanged: (v) {
              HapticEngine.selection();
              onChanged(v);
            },
          ),
        ),
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  final String label, value, flag;
  final VoidCallback onTap;
  final AppThemeColors L;
  final bool isLast;
  const _PickerTile(
      {required this.label,
      required this.value,
      required this.flag,
      required this.onTap,
      required this.L,
      this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$label: $value',
      child: AnimatedPressable(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: MedAiA11y.minTapTarget),
          decoration: BoxDecoration(
              border: isLast
                  ? null
                  : Border(
                      bottom: BorderSide(
                          color: L.border.withValues(alpha: 0.08),
                          width: 0.5))),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            title: Text(label,
                style: AppTypography.labelLarge.copyWith(
                    color: L.text, fontWeight: FontWeight.w800, fontSize: 15)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$flag $value',
                    style: AppTypography.bodySmall.copyWith(
                        color: L.text.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        letterSpacing: -0.2)),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right_rounded,
                    color: L.sub.withValues(alpha: 0.4), size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PickerSheet extends StatelessWidget {
  final String title;
  final List<Map<String, String>> items;
  final String selectedCode;
  const _PickerSheet(
      {required this.title, required this.items, required this.selectedCode});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return RefinedSheetWrapper(
      title: title,
      child: ListView.builder(
  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const ClampingScrollPhysics(),
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 48),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final isSelected = item['code'] == selectedCode;
          return ListTile(
            onTap: () {
              HapticEngine.selection();
              Navigator.pop(context, item['code']);
            },
            title: Text(item['label']!,
                style: AppTypography.labelLarge.copyWith(
                    fontWeight:
                        isSelected ? FontWeight.w900 : FontWeight.w700,
                    color: isSelected
                        ? L.text
                        : L.sub.withValues(alpha: 0.5),
                    fontSize: 14,
                    letterSpacing: 0.5)),
            trailing: isSelected
                ? Text('✓',
                    style: TextStyle(
                        color: L.text,
                        fontSize: 18,
                        fontWeight: FontWeight.w900))
                : null,
          );
        },
      ),
    );
  }
}
