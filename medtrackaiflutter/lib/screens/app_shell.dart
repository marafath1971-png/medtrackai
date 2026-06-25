import 'package:permission_handler/permission_handler.dart';
import '../widgets/common/permission_soft_prompt.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/shared/shared_widgets.dart';
import '../core/utils/haptic_engine.dart';
import 'home/home_tab.dart';
import 'home/widgets/streak_modal.dart';
import 'scan/scanner_hub_screen.dart';
import 'dashboard/dashboard_tab.dart';
import 'alarms/alarms_tab.dart';
import 'family/family_tab.dart';
import 'security/lock_screen.dart';

import '../services/analytics_service.dart';
import '../widgets/modals/dose_celebration_modal.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/common/medical_disclaimer_modal.dart';
import '../widgets/viral/reentry_screen.dart';
import '../widgets/modals/ai_consent_sheet.dart';

// ══════════════════════════════════════════════
// APP SHELL — Bottom nav + FAB + overlays
// ══════════════════════════════════════════════
class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  int _tab = 0;
  bool _fabPressed = false;
  bool _showReentry = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) await AIConsentSheet.checkAndShow(context);
      if (mounted) MedicalDisclaimerModal.showIfNeeded(context);
      _checkReentry();
    });

    // Handle celebratory triggers
    context.read<AppState>().addListener(_handleCelebration);
  }

  int _missedDoses = 0;

  void _checkReentry() async {
    final state = context.read<AppState>();
    final missed = await state.checkDailyReentry();
    if (missed != null && mounted) {
      setState(() {
        _missedDoses = missed;
        _showReentry = true;
      });
    }
  }

  void _handleCelebration() async {
    if (!mounted) return;
    final state = context.read<AppState>();

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

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    context.read<AppState>().removeListener(_handleCelebration);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      context.read<AppState>().lockApp();
    }
  }

  void _openScan() async {
    HapticEngine.medium();
    await PermissionSoftPrompt.show(
      context: context,
      title: 'Camera Access',
      explanation: 'We need your camera to scan medicine bottles and pills. This data is processed securely.',
      icon: Icons.camera_alt_rounded,
      buttonText: 'Enable Camera',
      permission: Permission.camera,
      fallbackExplanation: 'Camera permission is required to scan. Please enable it in Settings.',
      onGranted: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ScannerHubScreen(onClose: () => Navigator.pop(context)),
          ),
        );
      },
      onDenied: () {},
    );
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
                  // ── Main content ──
                  Positioned.fill(
                    child: AnimatedSwitcher(
                      duration: 450.ms,
                      switchInCurve: Curves.easeOutBack,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, animation) {
                        final isIncoming = child.key == ValueKey(_tab);
                        return FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: Tween<double>(
                              begin: isIncoming ? 0.95 : 1.0,
                              end: 1.0,
                            ).animate(animation),
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: isIncoming ? const Offset(0, 0.04) : Offset.zero,
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          ),
                        );
                      },
                      child: KeyedSubtree(
                        key: ValueKey(_tab),
                        child: _buildCurrentTab(),
                      ),
                    ),
                  ),

                  // Removed Scanner Overlay logic because we now use Navigator.push

                  // ── Low stock banner ──
                  if (lowMeds.isNotEmpty && !bannerDismissed)
                    Positioned(
                      top: MediaQuery.of(context).padding.top + AppSpacing.p12,
                      left: AppSpacing.p16,
                      right: AppSpacing.p16,
                      child: LowStockBanner(
                        meds: lowMeds,
                        onDismiss: () {
                          HapticEngine.medium();
                          context.read<AppState>().dismissLowStockBanner();
                        },
                      ).animate().fadeIn(duration: 500.ms).slideY(
                          begin: -0.2, end: 0, curve: Curves.easeOutBack),
                    ),

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

                  // ── Detached Scan FAB (right side, above nav) ──
                  AnimatedPositioned(
                      duration: const Duration(milliseconds: 380),
                      curve: Curves.easeOutQuart,
                      right: 37,
                      bottom: (16 + bottomPadding) + 76 + 24, // nav height + gap
                      child: _MedScanFAB(
                        pressed: _fabPressed,
                        onTap: _openScan,
                        onPressDown: () {
                          HapticEngine.selection();
                          setState(() => _fabPressed = true);
                        },
                        onPressUp: () => setState(() => _fabPressed = false),
                      ),
                    ),

                  // ── Toast ──
                  if (toast != null)
                    AppToast(message: toast, type: toastType ?? 'success'),

                  // ── Bottom Floating Island (Nav + Integrated FAB) ──
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 380),
                    curve: Curves.easeOutQuart,
                    left: 20,
                    right: 20,
                    bottom: (16 + bottomPadding),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 250),
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
                          setState(() => _showReentry = false);
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

  Widget _buildCurrentTab() {
    switch (_tab) {
      case 0:
        return HomeTab(
          onScan: _openScan,
          onSwitchTab: (i) => setState(() => _tab = i),
        );
      case 1:
        return DashboardTab(
          onScan: _openScan,
        );
      case 2:
        return const AlarmsTab();
      case 3:
        return const FamilyTab();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBottomIsland(AppThemeColors L, int unseenAlerts) {
    const labels = ['Home', 'Analytics', 'Alarms', 'Circle'];
    const activeIcons = [
      Icons.home_rounded,
      Icons.bar_chart_rounded,
      Icons.alarm_on_rounded,
      Icons.people_alt_rounded,
    ];
    const inactiveIcons = [
      Icons.home_outlined,
      Icons.bar_chart_outlined,
      Icons.alarm_outlined,
      Icons.people_alt_outlined,
    ];
    final badges = [0, 0, 0, unseenAlerts];

    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(
          height: 76,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            // Cal AI: nearly invisible glass — no color tint
            color: L.glass,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: L.glassBorder, // Pure white hairline
              width: 0.8,
            ),
          ),
          child: Row(
            children: [
              // ── Nav Items (full width now) ──
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    4,
                    (i) => _buildNavItem(
                      i,
                      activeIcons[i],
                      inactiveIcons[i],
                      labels[i],
                      L,
                      badges[i],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon,
      String label, AppThemeColors L, int cnt) {
    final selected = _tab == index;

    return Expanded(
      child: AnimatedPressable(
        onTap: () {
          if (_tab != index) {
            HapticEngine.selection();
            setState(() => _tab = index);
            AnalyticsService.logScreenView(
                ['Home', 'Analytics', 'Alarms', 'Circles'][index]);
          }
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: AppCurves.liquid,
          transform: Matrix4.translationValues(0.0, selected ? -4.0 : 0.0, 0.0)
            ..multiply(Matrix4.diagonal3Values(selected ? 1.15 : 1.0, selected ? 1.15 : 1.0, 1.0)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Icon(
                    selected ? activeIcon : inactiveIcon,
                    size: 24,
                    color: selected ? L.text : L.sub.withValues(alpha: 0.4),
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
              const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: selected 
                      ? AppTypography.labelSmall.copyWith(
                          color: L.text,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        )
                      : AppTypography.labelSmall.copyWith(
                          color: L.sub.withValues(alpha: 0.4),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════
// MED SCAN FAB — Premium Animated FAB
// ══════════════════════════════════════════════
class _MedScanFAB extends StatefulWidget {
  final bool pressed;
  final VoidCallback onTap;
  final VoidCallback onPressDown;
  final VoidCallback onPressUp;

  const _MedScanFAB({
    required this.pressed,
    required this.onTap,
    required this.onPressDown,
    required this.onPressUp,
  });

  @override
  State<_MedScanFAB> createState() => _MedScanFABState();
}

class _MedScanFABState extends State<_MedScanFAB>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _ringScale;
  late final Animation<double> _ringOpacity;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _ringScale = Tween<double>(begin: 1.0, end: 1.55).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeOut),
    );
    _ringOpacity = Tween<double>(begin: 0.45, end: 0.0).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return AnimatedPressable(
      onTap: widget.onTap,
      onTapDown: (_) => widget.onPressDown(),
      onTapUp: (_) => widget.onPressUp(),
      onTapCancel: widget.onPressUp,
      child: AnimatedScale(
        scale: widget.pressed ? 0.88 : 1.0,
        duration: 160.ms,
        curve: Curves.easeOut,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Pulse ring + FAB ──
            SizedBox(
              width: 76,
              height: 76,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Breathing ring
                  AnimatedBuilder(
                    animation: _pulse,
                    builder: (_, __) => Transform.scale(
                      scale: _ringScale.value,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: L.accent.withValues(alpha: _ringOpacity.value),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // FAB circle
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          L.accent,
                          Color.lerp(L.accent, Colors.black, 0.3)!,
                        ],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                        width: 1.0,
                      ),
                    ),
                    child: const Center(
                      child: Icon(Icons.camera_alt_rounded,
                          color: Colors.white, size: 25),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            // ── Label ──
            Text(
              'Scan',
              style: AppTypography.labelSmall.copyWith(
                color: L.text.withValues(alpha: 0.55),
                fontSize: 10,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, curve: Curves.easeOut)
        .slideX(begin: 0.15, end: 0, duration: 400.ms, curve: Curves.easeOutBack);
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
          AnimatedPressable(
            onTap: onDismiss,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              child: Icon(Icons.close_rounded,
                  size: 18, color: Colors.grey.withValues(alpha: 0.7)),
            ),
          ),
        ],
      ),
    );
  }
}
