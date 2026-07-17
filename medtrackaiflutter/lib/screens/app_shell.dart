import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app/app_routes.dart';
import '../providers/app_state.dart';
import '../theme/med_ai_ui.dart';
import '../widgets/shared/shared_widgets.dart';
import '../widgets/common/permission_soft_prompt.dart';
import '../core/utils/haptic_engine.dart';
import '../core/constants/med_ai_assets.dart';
import '../widgets/common/app_svg_icon.dart';
import 'home/widgets/streak_modal.dart';
import 'package:go_router/go_router.dart';
import 'security/lock_screen.dart';
import '../l10n/app_localizations.dart';

import '../services/analytics_service.dart';
import '../services/referral_service.dart';
import '../services/growth_tracker.dart';
import 'paywall/premium_paywall_overlay.dart';
import '../widgets/modals/dose_celebration_modal.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/common/medical_disclaimer_modal.dart';
import '../widgets/common/app_status_banner.dart';
import '../widgets/viral/reentry_screen.dart';
import '../widgets/modals/ai_consent_sheet.dart';
import 'package:flutter/scheduler.dart';

// ══════════════════════════════════════════════
// APP SHELL — Bottom nav + FAB + overlays
// ══════════════════════════════════════════════
class AppShell extends StatefulWidget {
  final Widget child;
  const AppShell({super.key, required this.child});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  bool _showReentry = false;
  AppState? _appState;
  bool _activationPaywallShown = false;
  bool _dismissedOfflineBanner = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) await AIConsentSheet.checkAndShow(context);
      if (mounted) MedicalDisclaimerModal.showIfNeeded(context);
      _checkReentry();
      _checkFirstMedActivation();
      _redeemPendingReferral();
      if (mounted) await context.read<AppState>().checkConnectivity();
    });
  }

  /// Redeems an inbound referral once the user has reached the app (past both
  /// onboarding and auth). Runs on first shell load; [ReferralService] no-ops
  /// if there's nothing pending or it was already redeemed. The premium reward
  /// grant is hooked here when entitlements go live.
  Future<void> _redeemPendingReferral() async {
    try {
      final redeemed = await ReferralService.redeemPendingInbound();
      if (redeemed != null) await GrowthTracker.trackReferralRedeemed();
    } catch (_) {/* referral redemption is best-effort */}
  }

  /// Session-1 activation (blueprint §6 step 48): if onboarding captured how
  /// the user wants to add their first med, deep-link straight there on the
  /// first home load. Users who activate in session 1 are 2–3x more likely
  /// to subscribe. One-shot: the flag is cleared before navigating.
  Future<void> _checkFirstMedActivation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final method = prefs.getString('pending_first_med_method');
      if (method == null) return;
      await prefs.remove('pending_first_med_method');
      if (!mounted) return;
      if (context.read<AppState>().meds.isNotEmpty) return;
      // Let the shell settle before pushing the add flow.
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      context.push(method == 'scan' ? AppRoutes.scanPill : AppRoutes.scan);
    } catch (_) {/* activation nudge is best-effort */}
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newState = context.read<AppState>();
    if (!identical(newState, _appState)) {
      _appState?.removeListener(_handleCelebration);
      _appState = newState;
      _appState!.addListener(_handleCelebration);
    }
  }

  int _missedDoses = 0;

  void _checkReentry() async {
    if (!mounted) return;
    final missed = await _appState!.checkDailyReentry();
    if (missed != null && mounted) {
      setState(() {
        _missedDoses = missed;
        _showReentry = true;
      });
    }
  }

  void _handleCelebration() {
    // Defer to post-frame — never access context during build/layout
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _runCelebrationLogic();
    });
  }

  void _runCelebrationLogic() async {
    if (!mounted) return;
    // Use cached _appState — never call context.read() here
    final state = _appState!;

    // Value-first funnel: the moment the user has their first *real* med (the
    // aha), present the deferred onboarding paywall. We require a non-empty
    // name so a blank placeholder from the manual-add flow doesn't trigger it
    // mid-edit — the paywall fires only once a genuine med is saved. Runs
    // before celebrations so the trial ask lands on the activation high.
    // One-shot, gated on a marker set during onboarding.
    final hasRealMed = state.meds.any((m) => m.name.trim().isNotEmpty);
    if (!_activationPaywallShown && hasRealMed && !state.isPremium) {
      _activationPaywallShown = true; // guard even if the async check bails
      await _maybeShowActivationPaywall();
      if (!mounted) return;
    }

    // First Priority: Streak Milestones
    final milestone = state.pendingMilestoneAnimation;
    if (milestone != null) {
      state.clearMilestone();
      HapticEngine.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      StreakModal.show(context, state);
      return;
    }

    final medName = state.pendingCelebrationMedName;
    if (medName != null) {
      state.clearCelebration();
      if (!mounted) return;
      DoseCelebrationModal.show(context, medName);
    }
  }

  /// Shows the personalized onboarding paywall once, immediately after the
  /// user's first med is added. The marker + goal were persisted in onboarding
  /// `_complete()` when the deferred-paywall experiment is on.
  Future<void> _maybeShowActivationPaywall() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('pending_activation_paywall') != true) return;
      await prefs.remove('pending_activation_paywall');
      if (!mounted) return;

      final goal = prefs.getString('onboarding_goal');
      final headline = switch (goal) {
        'never_miss' => 'Your plan to never miss a dose is ready.',
        'family' => "Your family's medication safety plan is ready.",
        'condition' => 'Your condition-tracking plan is ready.',
        'understand' => 'Your medication clarity plan is ready.',
        _ => null,
      };

      // Let the add-med transition settle before presenting.
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      AnalyticsService.logEvent('paywall_shown_post_activation');
      await PremiumPaywallOverlay.show(
        context,
        triggerSource: 'post_activation',
        variant: PaywallVariant.onboarding,
        personalizedHeadline: headline,
      );
    } catch (_) {/* best-effort; feature-gate paywalls remain the safety net */}
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _appState?.removeListener(_handleCelebration);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      context.read<AppState>().lockApp();
    } else if (state == AppLifecycleState.resumed) {
      context.read<AppState>().checkConnectivity().then((online) {
        if (online && mounted) {
          setState(() => _dismissedOfflineBanner = false);
        }
      });
    }
  }

  void _onReentryClosed() {
    setState(() {
      _showReentry = false;
    });
    AIConsentSheet.checkAndShow(context);
  }

  void _openScan() async {
    HapticEngine.medium();
    await PermissionSoftPrompt.show(
      context: context,
      title: 'Camera Access',
      explanation:
          'We need your camera to scan medicine bottles and pills. This data is processed securely.',
      icon: Icons.camera_alt_rounded,
      buttonText: 'Enable Camera',
      permission: Permission.camera,
      fallbackExplanation:
          'Camera permission is required to scan. Please enable it in Settings.',
      onGranted: () {
        context.push(AppRoutes.scan);
      },
      onDenied: () {},
    );
  }

  void _navigateToTab(int index) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/analytics');
        break;
      case 2:
        context.go('/alarms');
        break;
      case 3:
        context.go('/circle');
        break;
    }
    AnalyticsService.logScreenView(
      ['Home', 'Trends', 'Alarms', 'Circles'][index],
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    try {
      final String location = GoRouterState.of(context).uri.path;
      if (location.startsWith('/home')) return 0;
      if (location.startsWith('/analytics')) return 1;
      if (location.startsWith('/alarms')) return 2;
      if (location.startsWith('/circle')) return 3;
    } catch (_) {}
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final isDark = context.select<AppState, bool>((s) => s.darkMode);
    final unseenAlerts =
        context.select<AppState, int>((s) => s.unseenAlertsCount);
    final lowMeds =
        context.select<AppState, List<Medicine>>((s) => s.getLowMeds());
    final isLocked = context.select<AppState, bool>((s) => s.isLocked);
    final toast = context.select<AppState, String?>((s) => s.toast);
    final toastType = context.select<AppState, String?>((s) => s.toastType);
    final bannerDismissed =
        context.select<AppState, bool>((s) => s.lowStockBannerDismissed);
    final isOffline = context.select<AppState, bool>((s) => s.isOffline);
    final networkError =
        context.select<AppState, String?>((s) => s.networkErrorMessage);
    final isSyncing = context.select<AppState, bool>((s) => s.isMutating);
    final lastSynced =
        context.select<AppState, DateTime?>((s) => s.lastSyncedAt);

    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: isLocked
          ? const LockScreen()
          : Scaffold(
              backgroundColor: L.bg,
              resizeToAvoidBottomInset: true,
              body: Stack(
                clipBehavior: Clip.none,
                children: [
                  // ── Main content with swipe tab navigation ──
                  Positioned.fill(
                    child: MedAiSwipeTabs(
                      currentIndex: _calculateSelectedIndex(context),
                      tabCount: 4,
                      onTabChanged: _navigateToTab,
                      child: widget.child,
                    ),
                  ),

                  // Removed Scanner Overlay logic because we now use Navigator.push

                  // ── Offline / network error / low-stock status strip ──
                  Builder(builder: (context) {
                    final topInset =
                        MediaQuery.of(context).padding.top + AppSpacing.p12;
                    final showOffline =
                        (isOffline || networkError != null) &&
                            !_dismissedOfflineBanner;
                    final showLowStock =
                        lowMeds.isNotEmpty && !bannerDismissed;

                    if (!showOffline && !showLowStock) {
                      return const SizedBox.shrink();
                    }

                    return Positioned(
                      top: topInset,
                      left: 0,
                      right: 0,
                      child: Column(
                        children: [
                          if (showOffline)
                            isOffline
                                ? AppStatusBanner.offline(
                                    onRetry: () async {
                                      final online = await context
                                          .read<AppState>()
                                          .checkConnectivity();
                                      if (online && mounted) {
                                        setState(() =>
                                            _dismissedOfflineBanner = false);
                                      }
                                    },
                                    onDismiss: () => setState(
                                        () => _dismissedOfflineBanner = true),
                                  )
                                : AppStatusBanner.error(
                                    message: networkError!,
                                    onRetry: () {
                                      final s = context.read<AppState>();
                                      s.clearNetworkError();
                                      s.checkConnectivity();
                                    },
                                    onDismiss: () => context
                                        .read<AppState>()
                                        .clearNetworkError(),
                                  ),
                          if (showLowStock)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.p16),
                              child: LowStockBanner(
                                meds: lowMeds,
                                onDismiss: () {
                                  HapticEngine.medium();
                                  context
                                      .read<AppState>()
                                      .dismissLowStockBanner();
                                },
                              )
                                  .animate()
                                  .fadeIn(duration: 500.ms)
                                  .slideY(
                                      begin: -0.2,
                                      end: 0,
                                      curve: Curves.easeOutBack),
                            ),
                        ],
                      ),
                    );
                  }),

                  // ── Sync indicator ──
                  Positioned(
                    bottom: 140 + bottomPadding,
                    right: 20,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: isSyncing ? 1.0 : 0.0,
                      child: SyncStatusBanner(
                              isSyncing: isSyncing, lastSynced: lastSynced)
                    ),
                  ),

                  // ── Toast ──
                  if (toast != null)
                    AppToast(message: toast, type: toastType ?? 'success'),

                  // ── Bottom Floating Island (Nav + Integrated FAB) ──
                  AnimatedPositioned(
                    duration: AppDurations.fast,
                    curve: AppCurves.emilOut,
                    left: 20,
                    right: 20,
                    bottom: (16 + bottomPadding),
                    child: AnimatedOpacity(
                      duration: AppDurations.micro,
                      curve: AppCurves.emilOut,
                      opacity: 1,
                      child: _buildBottomIsland(L, unseenAlerts),
                    ),
                  ),

                  // ── Viral Reentry Screen ──
                  if (_showReentry)
                    Positioned.fill(
                      child: ReentryScreen(
                        missedDoses: _missedDoses, 
                        userName: context.select<AppState, String>((s) => s.activeProfile?.name ?? s.profile?.name ?? 'there'),
                        onDismiss: ({required bool streakSaved}) {
                          _onReentryClosed();
                          if (streakSaved) {
                            final st = context.read<AppState>();
                            Future.delayed(const Duration(milliseconds: 300), () {
                              if (mounted) {
                                // ignore: use_build_context_synchronously
                                StreakModal.show(context, st);
                              }
                            });
                          }
                        },
                      ).animate().fadeIn(duration: 400.ms),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildBottomIsland(AppThemeColors L, int unseenAlerts) {
    final s = AppLocalizations.of(context);
    final labels = s == null
        ? const ['Home', 'Trends', 'Alarms', 'Circle']
        : [s.homeTab, s.dashboardTab, s.alarmsTab, s.familyTab];
    const iconPaths = [
      MedAiAssets.iconHome,
      MedAiAssets.iconAnalytics,
      MedAiAssets.iconAlarms,
      MedAiAssets.iconFamily,
    ];
    final badges = [0, 0, 0, unseenAlerts];
    final currentIndex = _calculateSelectedIndex(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          decoration: BoxDecoration(
            color: context.isDark
                ? L.card.withValues(alpha: 0.72)
                : L.card,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: context.isDark
                  ? L.glassBorder.withValues(alpha: 0.35)
                  : L.border.withValues(alpha: 0.5),
              width: context.isDark ? 0.5 : 1,
            ),
            boxShadow: context.isDark
                ? AppShadows.premium
                : [
                    BoxShadow(
                      color: AppColors.eatoNavy.withValues(alpha: 0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: Row(
            children: [
              _buildNavItem(0, iconPaths[0], labels[0], L, badges[0], currentIndex),
              _buildNavItem(1, iconPaths[1], labels[1], L, badges[1], currentIndex),
              _buildScanButton(L),
              _buildNavItem(2, iconPaths[2], labels[2], L, badges[2], currentIndex),
              _buildNavItem(3, iconPaths[3], labels[3], L, badges[3], currentIndex),
            ],
          ),
        ),
      ),
    );
  }

  /// Center Scan action — the prominent primary action in the nav, matching
  /// the reference (Cal AI / Eato) center-scan pattern.
  Widget _buildScanButton(AppThemeColors L) {
    return Expanded(
      child: Semantics(
        button: true,
        label: 'Scan medicine',
        child: AnimatedPressable(
          onTap: _openScan,
          behavior: HitTestBehavior.opaque,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    // Cal AI: the primary action (Scan FAB) is near-black, not a
                    // brand color. Color is reserved for data viz + streak only.
                    colors: [L.text, L.text.withValues(alpha: 0.85)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: AppShadows.glow(
                    L.text.withValues(alpha: 0.4),
                    intensity: 0.25,
                  ),
                ),
                child: Center(
                  child: AppSvgIcon(
                    assetPath: MedAiAssets.iconScan,
                    size: 22,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Scan',
                  style: AppTypography.labelSmall.copyWith(
                    color: L.sub.withValues(alpha: 0.6),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String iconPath, String label,
      AppThemeColors L, int cnt, int currentIndex) {
    final selected = currentIndex == index;

    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: AnimatedPressable(
          onTap: () {
            HapticEngine.selection();
            _navigateToTab(index);
          },
          behavior: HitTestBehavior.opaque,
          hitTestPadding: const EdgeInsets.symmetric(vertical: 4),
          child: AnimatedContainer(
            duration: MedAiA11y.motion(context, AppDurations.micro),
            curve: AppCurves.emilOut,
            constraints: const BoxConstraints(minHeight: AppA11y.minTapTarget),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: MedAiA11y.motion(context, AppDurations.micro),
                  curve: AppCurves.emilOut,
                  padding: selected
                      ? const EdgeInsets.symmetric(horizontal: 10, vertical: 4)
                      : EdgeInsets.zero,
                  decoration: selected
                      ? BoxDecoration(
                          // Neutral active-tab pill (Cal AI: no brand color on
                          // nav; active = darker icon + subtle grey pill).
                          color: L.fill,
                          borderRadius: BorderRadius.circular(14),
                        )
                      : null,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      AppSvgIcon(
                        assetPath: iconPath,
                        size: 22,
                        color: selected ? L.text : L.sub.withValues(alpha: 0.45),
                      ),
                      if (cnt > 0)
                        Positioned(
                          top: -2,
                          right: -4,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: L.error,
                              shape: BoxShape.circle,
                              border: Border.all(color: L.card, width: 1.5),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                // scaleDown keeps the tiny nav label inside the fixed-height
                // island at large Dynamic Type instead of overflowing/clipping.
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: selected
                        ? AppTypography.labelSmall.copyWith(
                            color: L.text,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          )
                        : AppTypography.labelSmall.copyWith(
                            color: L.sub.withValues(alpha: 0.45),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
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

// ══════════════════════════════════════════════
// LOW STOCK BANNER
// ══════════════════════════════════════════════
class LowStockBanner extends StatelessWidget {
  final List<Medicine> meds;
  final VoidCallback onDismiss;
  const LowStockBanner(
      {super.key, required this.meds, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final firstName = meds.isNotEmpty ? meds.first.name : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: L.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: L.border.withValues(alpha: 0.08), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: L.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child:
                const Center(child: Text('📦', style: TextStyle(fontSize: 14))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Running low',
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: L.error,
                    fontSize: 13,
                    letterSpacing: 0,
                  ),
                ),
                Text(
                  meds.length > 1
                      ? '${meds.length} medicines need refill'
                      : '$firstName needs a refill',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                    color: L.text.withValues(alpha: 0.8),
                    height: 1.2,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Semantics(
            button: true,
            label: 'Dismiss',
            child: AnimatedPressable(
              onTap: onDismiss,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                child: Icon(Icons.close_rounded,
                    size: 18, color: L.sub.withValues(alpha: 0.8)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
