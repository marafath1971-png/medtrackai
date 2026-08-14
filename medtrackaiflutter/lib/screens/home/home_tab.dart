import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/haptic_engine.dart';
import '../../core/utils/scan_safety_mapper.dart';
import '../../providers/app_state.dart';
import '../../theme/med_ai_ui.dart';
import '../../widgets/common/premium_texture.dart';
import '../../widgets/common/recommend_hope_cta.dart';
import '../dashboard/widgets/lime_progress_hero.dart';
import '../dashboard/widgets/ref_bento_tile.dart';
import '../medicine/medicine_detail_screen.dart';
import 'dose_grouping.dart';
import 'widgets/emergency_warning_card.dart';
import 'widgets/home_dose_group.dart';
import 'widgets/home_header.dart';
import 'widgets/home_hope_photo_strip.dart';
import 'widgets/home_mascot_card.dart';
import 'widgets/home_schedule_empty.dart';
import 'widgets/home_week_strip.dart';
import 'widgets/know_medicine_strip.dart';
import 'widgets/med_card.dart';
import 'widgets/settings_modal_new.dart';
import 'widgets/share_milestone_cta.dart';
import 'widgets/streak_modal.dart';
import 'widgets/voice_assistant_overlay.dart';

/// Home tab — reference layout: header → hero → bento → week → doses.
class HomeTab extends StatefulWidget {
  final VoidCallback onScan;
  final ValueChanged<int>? onSwitchTab;
  const HomeTab({super.key, required this.onScan, this.onSwitchTab});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  bool _showStreak = false;
  bool _showSettings = false;
  Medicine? _viewingMed;
  bool _startInEditMode = false;
  DateTime _selectedDate = DateTime.now();
  late final ScrollController _scrollController;

  static const _hPad = AppSpacing.gutter;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  void _consumePendingDetail() {
    if (!mounted) return;
    final state = context.read<AppState>();
    final id = state.pendingDetailMedId;
    if (id == null) return;
    Medicine? med;
    for (final m in state.meds) {
      if (m.id == id) {
        med = m;
        break;
      }
    }
    state.clearPendingDetailMedId();
    if (med != null) {
      _viewMed(med, edit: false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: AppDurations.medium,
      curve: AppCurves.emilOut,
    );
    HapticEngine.selection();
  }

  void _setDate(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final current = DateTime(
        _selectedDate.year, _selectedDate.month, _selectedDate.day);
    if (normalized == current) return;
    HapticEngine.selection();
    setState(() => _selectedDate = normalized);
  }

  void _viewMed(Medicine med, {bool edit = false}) {
    setState(() {
      _viewingMed = med;
      _startInEditMode = edit;
    });
  }

  ({String label, String value, String unit}) _nextDoseInfo(
    List<DoseItem> doses,
    Map<String, bool> takenMap,
    DateTime forDate,
  ) {
    if (doses.isEmpty) {
      return (label: 'Next dose', value: '—', unit: 'Add meds');
    }

    final now = DateTime.now();
    final isToday = forDate.year == now.year &&
        forDate.month == now.month &&
        forDate.day == now.day;
    final nowM = now.hour * 60 + now.minute;
    final pending =
        doses.where((d) => takenMap[d.key] != true).toList()
          ..sort((a, b) {
            final am = a.sched.h * 60 + a.sched.m;
            final bm = b.sched.h * 60 + b.sched.m;
            return am.compareTo(bm);
          });

    if (pending.isEmpty) {
      return (
        label: isToday ? 'Next dose' : 'Schedule',
        value: 'Done',
        unit: 'All clear',
      );
    }

    DoseItem? next;
    if (isToday) {
      for (final d in pending) {
        final m = d.sched.h * 60 + d.sched.m;
        if (m >= nowM) {
          next = d;
          break;
        }
      }
      next ??= pending.first;
    } else {
      next = pending.first;
    }

    // Past/future days: show scheduled clock time, not a relative countdown.
    if (!isToday) {
      final h = next.sched.h;
      final m = next.sched.m;
      final hour12 = h % 12 == 0 ? 12 : h % 12;
      final ampm = h >= 12 ? 'PM' : 'AM';
      final mm = m.toString().padLeft(2, '0');
      return (
        label: forDate.isBefore(DateTime(now.year, now.month, now.day))
            ? 'First pending'
            : 'Next dose',
        value: '$hour12:$mm',
        unit: '$ampm · ${next.med.name}',
      );
    }

    var minsUntil = (next.sched.h * 60 + next.sched.m) - nowM;
    if (minsUntil < 0) minsUntil += 24 * 60;

    final countdown = minsUntil <= 0
        ? 'Now'
        : minsUntil < 60
            ? '${minsUntil}m'
            : minsUntil % 60 == 0
                ? '${minsUntil ~/ 60}h'
                : '${minsUntil ~/ 60}h ${minsUntil % 60}m';

    return (
      label: 'Next dose',
      value: countdown,
      unit: next.med.name,
    );
  }

  Widget _buildMain(
    BuildContext context,
    AppThemeColors L,
    List<DoseItem> doses,
    int streak,
    Map<String, bool> takenMap,
    List<Medicine> meds,
    int takenCount,
  ) {
    final severeSymptoms = context
        .select<AppState, List<Symptom>>((s) => s.symptoms)
        .where((s) =>
            s.severity >= 8 &&
            DateTime.now().difference(s.timestamp).inHours < 24)
        .toList();

    final groups = DoseGrouping.group(doses);
    final dosePct = doses.isEmpty ? 0.0 : takenCount / doses.length;
    final dosesLeft = (doses.length - takenCount).clamp(0, doses.length);
    final nextDose = _nextDoseInfo(doses, takenMap, _selectedDate);
    final allDone = doses.isNotEmpty && takenCount >= doses.length;
    final showMascot = allDone || (doses.isEmpty && meds.isNotEmpty);
    final reduceMotion = MedAiA11y.reducedMotion(context);
    final listSwitchDuration =
        MedAiA11y.motion(context, AppDurations.fast);
    final listSwitchReverse =
        MedAiA11y.motion(context, AppDurations.exit);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          PremiumHomeSurface(
            child: RefreshIndicator(
              onRefresh: () async {
                HapticEngine.selection();
                final state = context.read<AppState>();
                await state.checkConnectivity();
                await state.loadFromStorage();
              },
              color: AppColors.limeDeep,
              backgroundColor: L.card,
              displacement: 48,
              strokeWidth: 2.5,
              child: Scrollbar(
                controller: _scrollController,
                child: CustomScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  controller: _scrollController,
                  key: const PageStorageKey('home_scroll'),
                  physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics()),
                  slivers: [
                    SliverToBoxAdapter(
                      child: HomeHeader(
                        state: context.read<AppState>(),
                        onTap: _scrollToTop,
                        onOpenSettings: () =>
                            setState(() => _showSettings = true),
                      ),
                    ),

                    if (severeSymptoms.isNotEmpty)
                      SliverPadding(
                        padding:
                            const EdgeInsets.fromLTRB(_hPad, 0, _hPad, AppSpacing.p12),
                        sliver: SliverToBoxAdapter(
                          child: EmergencyWarningCard(
                              symptom: severeSymptoms.first),
                        ),
                      ),

                    SliverPadding(
                      padding:
                          const EdgeInsets.fromLTRB(_hPad, AppSpacing.p8, _hPad, AppSpacing.p12),
                      sliver: const SliverToBoxAdapter(
                        child: HomeHopePhotoStrip(),
                      ),
                    ),

                    SliverPadding(
                      padding:
                          const EdgeInsets.fromLTRB(_hPad, 0, _hPad, AppSpacing.p16),
                      sliver: SliverToBoxAdapter(
                        child: LimeProgressHero(
                          fraction: dosePct,
                          taken: takenCount,
                          total: doses.length,
                          streak: streak,
                          showStreak: true,
                          onTap: () => setState(() => _showStreak = true),
                        ),
                      ),
                    ),

                    SliverPadding(
                      padding:
                          const EdgeInsets.fromLTRB(_hPad, 0, _hPad, AppSpacing.p16),
                      sliver: SliverToBoxAdapter(
                        child: Row(
                          children: [
                            Expanded(
                              child: RefBentoTile(
                                label: nextDose.label,
                                value: nextDose.value,
                                unit: nextDose.unit,
                                emoji: '⏰',
                                tint: AppColors.accent,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.p12),
                            Expanded(
                              child: RefBentoTile(
                                label: 'Doses left',
                                value: '$dosesLeft',
                                unit: dosesLeft == 1 ? 'dose' : 'doses',
                                emoji: '💊',
                                tint: AppColors.infoSoft,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SliverPadding(
                      padding:
                          const EdgeInsets.fromLTRB(_hPad, 0, _hPad, AppSpacing.p16),
                      sliver: SliverToBoxAdapter(
                        child: KnowMedicineStrip(
                          onReviewFirst: () {
                            final flagged = meds
                                .where((m) => m.hasCriticalSafetyAlerts)
                                .toList();
                            final tips = meds
                                .where((m) => m.needsPreTakeBriefing)
                                .toList();
                            final target = flagged.isNotEmpty
                                ? flagged.first
                                : (tips.isNotEmpty ? tips.first : null);
                            if (target != null) {
                              setState(() => _viewingMed = target);
                            }
                          },
                        ),
                      ),
                    ),

                    SliverPadding(
                      padding:
                          const EdgeInsets.fromLTRB(_hPad, 0, _hPad, AppSpacing.p20),
                      sliver: SliverToBoxAdapter(
                        child: HomeWeekStrip(
                          selectedDate: _selectedDate,
                          onChanged: _setDate,
                        ),
                      ),
                    ),

                    if (doses.isEmpty)
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(_hPad, 0, _hPad, AppSpacing.p24),
                        sliver: SliverToBoxAdapter(
                          child: AnimatedSwitcher(
                            duration: listSwitchDuration,
                            reverseDuration: listSwitchReverse,
                            switchInCurve: AppCurves.emilOut,
                            switchOutCurve: AppCurves.emilOut,
                            transitionBuilder: (child, animation) {
                              if (reduceMotion) return child;
                              final curved = CurvedAnimation(
                                parent: animation,
                                curve: AppCurves.emilOut,
                              );
                              return FadeTransition(
                                opacity: curved,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, 0.03),
                                    end: Offset.zero,
                                  ).animate(curved),
                                  child: child,
                                ),
                              );
                            },
                            child: HomeScheduleEmpty(
                              key: ValueKey(
                                  'empty-${_selectedDate.toIso8601String()}'),
                              hasMeds: meds.isNotEmpty,
                              onAdd: widget.onScan,
                            ),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(_hPad, 0, _hPad, AppSpacing.p24),
                        sliver: SliverToBoxAdapter(
                          child: AnimatedSwitcher(
                            duration: listSwitchDuration,
                            reverseDuration: listSwitchReverse,
                            switchInCurve: AppCurves.emilOut,
                            switchOutCurve: AppCurves.emilOut,
                            transitionBuilder: (child, animation) {
                              if (reduceMotion) return child;
                              final curved = CurvedAnimation(
                                parent: animation,
                                curve: AppCurves.emilOut,
                              );
                              return FadeTransition(
                                opacity: curved,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, 0.03),
                                    end: Offset.zero,
                                  ).animate(curved),
                                  child: child,
                                ),
                              );
                            },
                            child: Column(
                              key: ValueKey(
                                  'doses-${_selectedDate.toIso8601String()}-${doses.length}'),
                              children: [
                                for (final group in groups)
                                  HomeDoseGroup(
                                    title: group.title,
                                    doses: group.items,
                                    takenToday: takenMap,
                                    state: context.read<AppState>(),
                                    selectedDate: _selectedDate,
                                    onView: (med) => _viewMed(med),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    if (meds.isNotEmpty)
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(
                            _hPad, AppSpacing.p8, _hPad, AppSpacing.p16),
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Your medicines',
                                      style:
                                          AppTypography.titleMedium.copyWith(
                                        color: AppColors.inkStrong,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.pastelMint,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      '${meds.length}',
                                      style:
                                          AppTypography.labelSmall.copyWith(
                                        color: AppColors.limeInk,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.p4),
                              Text(
                                HopeVibe.medicinesSubtitle,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.grey600,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.p12),
                              ...meds
                                  .where((m) => m.name.trim().isNotEmpty)
                                  .take(6)
                                  .map(
                                    (m) => MedCard(
                                      med: m,
                                      onView: () => _viewMed(m),
                                      onEdit: () =>
                                          _viewMed(m, edit: true),
                                    ),
                                  ),
                            ],
                          ),
                        ),
                      ),

                    if (streak >= 7)
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(
                            _hPad, AppSpacing.p8, _hPad, AppSpacing.p8),
                        sliver: SliverToBoxAdapter(
                          child: ShareMilestoneCta(
                            streak: streak,
                            dosePct: dosePct,
                            userName: context
                                    .read<AppState>()
                                    .activeProfile
                                    ?.name ??
                                context.read<AppState>().profile?.name ??
                                '',
                            totalDosesTaken: takenCount,
                          ),
                        ),
                      ),

                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                          _hPad, AppSpacing.p8, _hPad, AppSpacing.p8),
                      sliver: SliverToBoxAdapter(
                        child: RecommendHopeCta(
                          userName: context
                                  .read<AppState>()
                                  .activeProfile
                                  ?.name ??
                              context.read<AppState>().profile?.name,
                        ),
                      ),
                    ),

                    if (showMascot)
                      SliverPadding(
                        padding:
                            const EdgeInsets.fromLTRB(_hPad, AppSpacing.p16, _hPad, 0),
                        sliver: const SliverToBoxAdapter(
                          child: HomeMascotCard(),
                        ),
                      ),

                    const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.bottomBuffer)),
                  ],
                ),
              ),
            ),
          ),
          _buildOverlay(
            _showStreak,
            'streak',
            StreakModal(
              streak: streak,
              history: context.select<AppState, Map<String, List<DoseEntry>>>(
                  (s) => s.history),
              streakData:
                  context.select<AppState, StreakData>((s) => s.streakData),
              onClose: () => setState(() => _showStreak = false),
              onFreeze: () => context.read<AppState>().useStreakFreeze(),
            ),
          ),
          _buildOverlay(
            _showSettings,
            'settings',
            SettingsModal(
              onClose: () => setState(() => _showSettings = false),
            ),
          ),
          const VoiceAssistantOverlay(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendingId =
        context.select<AppState, int?>((s) => s.pendingDetailMedId);
    if (pendingId != null) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _consumePendingDetail());
    }

    final doses = context.select<AppState, List<DoseItem>>(
        (s) => s.getDoses(date: _selectedDate));
    final streak = context.select<AppState, int>((s) => s.getStreak());
    final takenMap = context.select<AppState, Map<String, bool>>(
        (s) => s.getTakenMapForDate(_selectedDate));
    final meds = context.select<AppState, List<Medicine>>((s) => s.meds);

    final takenCount = doses.where((d) => takenMap[d.key] == true).length;
    final L = context.L;

    final mainContent = _buildMain(
        context, L, doses, streak, takenMap, meds, takenCount);

    final reduceMotion = MedAiA11y.reducedMotion(context);
    return AnimatedSwitcher(
      duration: MedAiA11y.motion(context, AppDurations.fast),
      reverseDuration: MedAiA11y.motion(context, AppDurations.exit),
      switchInCurve: AppCurves.emilOut,
      switchOutCurve: AppCurves.emilOut,
      transitionBuilder: reduceMotion
          ? (child, animation) => child
          : AnimatedSwitcher.defaultTransitionBuilder,
      child: _viewingMed != null
          ? MedicineDetailScreen(
              key: ValueKey('med_detail_${_viewingMed!.id}'),
              medId: _viewingMed!.id,
              onBack: () => setState(() => _viewingMed = null),
              initialEditMode: _startInEditMode)
          : SizedBox.expand(key: const ValueKey('home_main'), child: mainContent),
    );
  }

  Widget _buildOverlay(bool visible, String key, Widget child) {
    final reduceMotion = MedAiA11y.reducedMotion(context);
    return AnimatedSwitcher(
      duration: MedAiA11y.motion(context, AppDurations.medium),
      reverseDuration: MedAiA11y.motion(context, AppDurations.exit),
      switchInCurve: AppCurves.emilOut,
      switchOutCurve: AppCurves.emilOut,
      transitionBuilder: (child, animation) {
        if (reduceMotion) return child;
        final curved = CurvedAnimation(
          parent: animation,
          curve: AppCurves.emilOut,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.97, end: 1.0).animate(curved),
            alignment: Alignment.bottomCenter,
            child: child,
          ),
        );
      },
      child: visible
          ? SizedBox.expand(key: ValueKey(key), child: child)
          : const SizedBox.shrink(),
    );
  }
}
