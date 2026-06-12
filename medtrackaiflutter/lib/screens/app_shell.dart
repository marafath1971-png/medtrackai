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
import 'scan/scan_tab.dart';
import 'dashboard/dashboard_tab.dart';
import 'alarms/alarms_tab.dart';
import 'security/lock_screen.dart';
import 'social/stack_circles_screen.dart';
import '../services/analytics_service.dart';
import '../widgets/modals/dose_celebration_modal.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/common/medical_disclaimer_modal.dart';
import '../widgets/viral/reentry_screen.dart';

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
  bool _showScan = false;
  bool _fabPressed = false;
  bool _showReentry = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) MedicalDisclaimerModal.showIfNeeded(context);
      _checkReentry();
    });

    // Handle celebratory triggers
    context.read<AppState>().addListener(_handleCelebration);
  }

  void _checkReentry() {
    final state = context.read<AppState>();
    // Check if user has been away for > 3 days
    final lastSync = state.lastSyncedAt;
    if (lastSync != null) {
      if (DateTime.now().difference(lastSync).inDays >= 3) {
        setState(() => _showReentry = true);
      }
    }
  }

  void _handleCelebration() async {
    final state = context.read<AppState>();

    // First Priority: Streak Milestones
    final milestone = state.pendingMilestoneAnimation;
    if (milestone != null) {
      state.clearMilestone();
      HapticEngine.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) StreakModal.show(context, state);
      return;
    }

    final medName = state.pendingCelebrationMedName;
    if (medName != null) {
      state.clearCelebration();
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

  void _openScan() {
    HapticEngine.medium();
    setState(() => _showScan = true);
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
              backgroundColor: L.meshBg,
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

                  // ── Scan Overlay — High Detail ──
                  if (_showScan)
                    Positioned.fill(
                      child: ScanTab(
                        key: const ValueKey('scan_tab'),
                        onSave: (med) {
                          final s = context.read<AppState>();
                          s.addMedicine(med);
                          setState(() {
                            _showScan = false;
                            _tab = 0;
                          });
                          s.showToast('${med.name} added!');
                        },
                        onClose: () => setState(() => _showScan = false),
                        onManualAdd: () => setState(() => _showScan = false),
                      )
                          .animate()
                          .fadeIn(duration: 350.ms, curve: Curves.easeOut)
                          .scale(
                            begin: const Offset(0.94, 0.94),
                            curve: Curves.easeOutBack,
                          ),
                    ),

                  // ── Low stock banner ──
                  if (lowMeds.isNotEmpty && !_showScan && !bannerDismissed)
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
                    bottom: 110 + bottomPadding,
                    right: 20,
                    child: SyncStatusBanner(
                            isSyncing: isSyncing, lastSynced: lastSynced)
                        .animate(target: isSyncing ? 1 : 0)
                        .fadeIn(duration: 300.ms)
                        .scale(begin: const Offset(0.8, 0.8))
                        .slideY(begin: 0.2, end: 0),
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
                    bottom: _showScan ? -(120 + bottomPadding) : (16 + bottomPadding),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 250),
                      opacity: _showScan ? 0 : 1,
                      child: _buildBottomIsland(L, unseenAlerts),
                    ),
                  ),

                  // ── Viral Reentry Screen ──
                  if (_showReentry)
                    Positioned.fill(
                      child: ReentryScreen(
                        missedDoses: 4, // Calculate from actual state in prod
                        userName: context.select<AppState, String>((s) => s.activeProfile?.name ?? s.profile?.name ?? 'there'),
                        onDismiss: () => setState(() => _showReentry = false),
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
        return const DashboardTab();
      case 2:
        return const AlarmsTab();
      case 3:
        return const StackCirclesScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBottomIsland(AppThemeColors L, int unseenAlerts) {
    final isDark = context.select<AppState, bool>((s) => s.darkMode);
    const labels = ['Home', 'Analytics', 'Alarms', 'Circles'];
    const activeIcons = [
      Icons.home_rounded,
      Icons.bar_chart_rounded,
      Icons.alarm_on_rounded,
      Icons.group_rounded,
    ];
    const inactiveIcons = [
      Icons.home_outlined,
      Icons.bar_chart_outlined,
      Icons.alarm_outlined,
      Icons.group_outlined,
    ];
    final badges = [0, 0, unseenAlerts, 0];

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 32,
                offset: const Offset(0, 16),
                spreadRadius: -8,
              ),
              BoxShadow(
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.02),
                blurRadius: 1,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: Row(
            children: [
              // ── Nav Items ──
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
              const SizedBox(width: 12),
              // ── Integrated FAB ──
              _MedScanFAB(
                pressed: _fabPressed,
                onTap: _openScan,
                onPressDown: () {
                  HapticEngine.selection();
                  setState(() => _fabPressed = true);
                },
                onPressUp: () => setState(() => _fabPressed = false),
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
      child: GestureDetector(
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
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(0.0, selected ? -2.0 : 0.0, 0.0)
            ..multiply(Matrix4.diagonal3Values(selected ? 1.05 : 1.0, selected ? 1.05 : 1.0, 1.0)),
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
// MED SCAN FAB — Premium Island Style
// ══════════════════════════════════════════════
class _MedScanFAB extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onTapDown: (_) => onPressDown(),
      onTapUp: (_) => onPressUp(),
      onTapCancel: onPressUp,
      child: AnimatedScale(
        scale: pressed ? 0.9 : 1.0,
        duration: 150.ms,
        curve: Curves.easeOutCubic,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: AppGradients.actionRed,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.limeAccent.withValues(alpha: 0.6), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF5E5E).withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: AppColors.limeAccent.withValues(alpha: 0.4),
                blurRadius: pressed ? 8 : 24,
                spreadRadius: pressed ? 0 : 4,
              ),
            ],
          ),
          child: const Center(
            child: Icon(Icons.add_rounded, color: Colors.white, size: 28),
          ),
        ).animate(onPlay: (controller) => controller.repeat(reverse: true))
         .shimmer(duration: 2500.ms, color: Colors.white24)
         .scaleXY(end: 1.05, duration: 1500.ms, curve: Curves.easeInOutSine),
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
          GestureDetector(
            onTap: onDismiss,
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Text('✕',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Colors.grey)),
            ),
          ),
        ],
      ),
    );
  }
}
