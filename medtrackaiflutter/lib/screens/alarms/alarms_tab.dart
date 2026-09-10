import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../providers/controllers/medication_controller.dart';
import '../../theme/med_ai_ui.dart';
import '../../widgets/common/modern_time_picker.dart';
import '../../core/utils/date_formatter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../widgets/common/refined_sheet_wrapper.dart';
import '../../widgets/shared/shared_widgets.dart';
import '../../core/utils/haptic_engine.dart';
import '../../widgets/common/premium_texture.dart';
import '../../widgets/common/app_feedback.dart';
import '../../widgets/common/premium_empty_state.dart';
import '../../widgets/modals/know_your_medicine_sheet.dart';
import '../../l10n/app_localizations.dart';

// ══════════════════════════════════════════════════════════════════════
// ALARMS TAB — Premium Reminders & Schedules
// ══════════════════════════════════════════════════════════════════════

class AlarmsTab extends StatefulWidget {
  const AlarmsTab({super.key});

  @override
  State<AlarmsTab> createState() => _AlarmsTabState();
}

class _AlarmsTabState extends State<AlarmsTab> {
  bool _isScrolled = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final scrolled = _scrollController.offset > 10;
    if (scrolled != _isScrolled) setState(() => _isScrolled = scrolled);
  }

  Widget _entrance(Widget child, {int index = 0, bool slideX = false}) {
    if (MedAiA11y.reducedMotion(context)) return child;
    if (slideX) {
      return child
          .animate(delay: (index * 50).ms)
          .fadeIn(duration: AppDurations.fast, curve: AppCurves.emilOut)
          .slideX(begin: 0.03, end: 0, curve: AppCurves.emilOut);
    }
    return child
        .animate(delay: (index * 50).ms)
        .fadeIn(duration: AppDurations.fast, curve: AppCurves.emilOut)
        .slideY(begin: 0.03, end: 0, curve: AppCurves.emilOut);
  }

  void _showAddAlarmSheet(BuildContext context, Medicine med, {int? idx}) {
    HapticEngine.selection();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => _AddAlarmSheet(
        med: med,
        scheduleIndex: idx,
        onClose: () => Navigator.pop(context),
      ),
    );
  }

  void _showMedPicker(
      BuildContext context, List<Medicine> meds, AppThemeColors L) {
    HapticEngine.selection();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MedPickerSheet(
        meds: meds,
        L: L,
        onPick: (med) {
          Navigator.pop(context);
          _showAddAlarmSheet(context, med);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final allSchedules = context
        .select<AppState, List<ScheduledMed>>((s) => s.getAllSchedules());
    final meds = context.select<AppState, List<Medicine>>((s) => s.meds);
    final L = context.L;
    final activeCount = allSchedules.where((x) => x.sched.enabled).length;

    final activeSchedules = allSchedules.where((x) => x.sched.enabled).toList()
      ..sort((a, b) =>
          (a.sched.h * 60 + a.sched.m).compareTo(b.sched.h * 60 + b.sched.m));
    final inactiveSchedules =
        allSchedules.where((x) => !x.sched.enabled).toList();

    final now = DateTime.now();
    final nowM = now.hour * 60 + now.minute;
    final nextDose = activeSchedules
            .where((s) => (s.sched.h * 60 + s.sched.m) > nowM)
            .firstOrNull ??
        (activeSchedules.isNotEmpty ? activeSchedules.first : null);

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
            displacement: 48,
            strokeWidth: 2.5,
            color: AppColors.limeDeep,
            backgroundColor: L.card,
            child: CustomScrollView(
  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              controller: _scrollController,
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                SliverToBoxAdapter(
                  child: SizedBox(
                      height: 100 + MediaQuery.of(context).padding.top),
                ),

                // ── NEXT DOSE HERO ──
                if (nextDose != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 0, AppSpacing.gutter, 0),
                      child: _entrance(
                        _NextDoseHero(sch: nextDose, L: L),
                        index: 0,
                      ),
                    ),
                  ),

                // ── SEPARATOR ──
                if (activeSchedules.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.gutter, 28, AppSpacing.gutter, AppSpacing.p12),
                      child: Row(
                        children: [
                          Expanded(
                            child: MedAiSectionHeader(
                              title: l10n.alarmsReminders,
                              subtitle: '$activeCount active',
                            ),
                          ),
                          _CountPill(count: activeCount, L: L),
                        ],
                      ),
                    ),
                  ),

                // ── ACTIVE ALARMS LIST ──
                if (activeSchedules.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, idx) {
                          final sch = activeSchedules[idx];
                          final isNext = nextDose != null &&
                              sch.med.id == nextDose.med.id &&
                              sch.idx == nextDose.idx;
                          return _entrance(
                            Padding(
                              padding: EdgeInsets.zero,
                              child: _AlarmCard(
                                sch: sch,
                                L: L,
                                isNext: isNext,
                                onToggle: () => context
                                    .read<AppState>()
                                    .toggleSchedule(sch.med.id, sch.idx),
                                onRemove: () {
                                  HapticEngine.heavyImpact();
                                  final state = context.read<AppState>();
                                  final removedSch = sch;

                                  state.removeSchedule(sch.med.id, sch.idx);

                                  AppFeedback.undo(
                                    context,
                                    message:
                                        'Alarm for ${sch.med.name} removed',
                                    onUndo: () {
                                      state.addSchedule(removedSch.med.id,
                                          removedSch.sched);
                                    },
                                  );
                                },
                                onEdit: () => _showAddAlarmSheet(
                                    context, sch.med,
                                    idx: sch.idx),
                              ),
                            ),
                            index: idx,
                            slideX: true,
                          );
                        },
                        childCount: activeSchedules.length,
                      ),
                    ),
                  ),

                // ── EMPTY STATE ──
                if (activeSchedules.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.p32, AppSpacing.gutter, 0),
                      child: _entrance(
                        _EmptyAlarmsState(
                          L: L,
                          hasMeds: meds.isNotEmpty,
                          onSetFirst: meds.isNotEmpty
                              ? () => _showMedPicker(context, meds, L)
                              : null,
                        ),
                      ),
                    ),
                  ),

                // ── PAUSED SECTION ──
                if (inactiveSchedules.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.p24, AppSpacing.p40, AppSpacing.p24, AppSpacing.p16),
                      child: MedAiSectionHeader(
                        title: l10n.alarmsPaused,
                        subtitle: '${inactiveSchedules.length} off',
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, idx) {
                          final sch = inactiveSchedules[idx];
                          return _entrance(
                            Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.p12),
                              child: _AlarmCard(
                                sch: sch,
                                L: L,
                                isNext: false,
                                onToggle: () => context
                                    .read<AppState>()
                                    .toggleSchedule(sch.med.id, sch.idx),
                                onRemove: () {
                                  HapticEngine.heavyImpact();
                                  final state = context.read<AppState>();
                                  final removedSch = sch;

                                  state.removeSchedule(sch.med.id, sch.idx);

                                  AppFeedback.undo(
                                    context,
                                    message:
                                        'Alarm for ${sch.med.name} removed',
                                    onUndo: () {
                                      state.addSchedule(removedSch.med.id,
                                          removedSch.sched);
                                    },
                                  );
                                },
                                onEdit: () => _showAddAlarmSheet(
                                    context, sch.med,
                                    idx: sch.idx),
                              ),
                            ),
                            index: idx,
                          );
                        },
                        childCount: inactiveSchedules.length,
                      ),
                    ),
                  ),
                ],

                // ── QUICK ADD FROM MEDS (only when no active alarms) ──
                if (meds.isNotEmpty &&
                    activeSchedules.isEmpty &&
                    inactiveSchedules.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.p32, AppSpacing.gutter, 0),
                      child: _QuickAddSection(
                          meds: meds,
                          L: L,
                          onAdd: (med) => _showAddAlarmSheet(context, med)),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 140)),
              ],
            ),
          ),
          ),

          // ── FROSTED HEADER ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _AlarmsHeader(
              isScrolled: _isScrolled,
              activeCount: activeCount,
              L: L,
              onAdd: () {
                if (meds.isNotEmpty) {
                  _showMedPicker(context, meds, L);
                } else {
                  HapticEngine.selection();
                  context
                      .read<AppState>()
                      .showToast('Add a medicine from the Home tab first');
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// HEADER
// ══════════════════════════════════════════════════════════════════════
class _AlarmsHeader extends StatelessWidget {
  final bool isScrolled;
  final int activeCount;
  final AppThemeColors L;
  final VoidCallback? onAdd;
  const _AlarmsHeader(
      {required this.isScrolled,
      required this.activeCount,
      required this.L,
      this.onAdd});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final topPad = MediaQuery.of(context).padding.top;
    final subtitle =
        activeCount > 0 ? '$activeCount active reminders' : 'Stay on schedule';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: EdgeInsets.fromLTRB(AppSpacing.gutter, topPad + AppSpacing.p12, AppSpacing.gutter, AppSpacing.p12),
      decoration: BoxDecoration(
        color: isScrolled ? L.bg.withValues(alpha: 0.96) : Colors.transparent,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.alarmsTab,
                  style: AppTypography.headlineMedium.copyWith(
                    color: L.text,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: L.sub,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (onAdd != null)
            Semantics(
              button: true,
              label: l10n.alarmsAddReminder,
              child: AnimatedPressable(
                onTap: onAdd!,
                child: PremiumTextureCard(
                  padding: EdgeInsets.zero,
                  radius: 999,
                  texture: PremiumTextureStyle.none,
                  child: SizedBox(
                    width: 42,
                    height: 42,
                    child: Icon(Icons.add_rounded, size: 22, color: L.text),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// COUNT PILL
// ══════════════════════════════════════════════════════════════════════
class _CountPill extends StatelessWidget {
  final int count;
  final AppThemeColors L;
  const _CountPill({required this.count, required this.L});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.pastelMint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count',
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.limeInk,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// NEXT DOSE HERO CARD
// ══════════════════════════════════════════════════════════════════════
class _NextDoseHero extends StatefulWidget {
  final dynamic sch;
  final AppThemeColors L;
  const _NextDoseHero({required this.sch, required this.L});

  @override
  State<_NextDoseHero> createState() => _NextDoseHeroState();
}

class _NextDoseHeroState extends State<_NextDoseHero> {
  late String _diffStr;
  bool _recorded = false;
  StreamSubscription<int>? _ticker;

  @override
  void initState() {
    super.initState();
    _update();
    _ticker = Stream.periodic(const Duration(minutes: 1), (i) => i)
        .listen((_) {
      if (mounted) setState(_update);
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _update() {
    final now = DateTime.now();
    final s = widget.sch.sched as ScheduleEntry;
    var target = DateTime(now.year, now.month, now.day, s.h, s.m);
    if (target.isBefore(now)) target = target.add(const Duration(days: 1));
    final diff = target.difference(now);
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    _diffStr = h > 0 ? '${h}h ${m}m away' : '${m}m away';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final med = widget.sch.med as Medicine;
    final s = widget.sch.sched as ScheduleEntry;
    final L = widget.L;

    final displayName =
        med.name.trim().isNotEmpty ? med.name.trim() : 'Untitled medicine';
    final meta = [
      if (med.dose.isNotEmpty) med.dose,
      if (s.label.isNotEmpty) s.label,
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.all(AppSpacing.p20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.limeDeep.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.eatoNavy.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.pastelMint,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const LiveStatusDot(
                      color: AppColors.limeDeep,
                      size: 6,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l10n.alarmsUpcoming,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.limeInk,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.pastelSun,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  fmtTime(s.h, s.m, context),
                  style: AppTypography.labelSmall.copyWith(
                    color: const Color(0xFF8A6A1A),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (_recorded)
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.pastelMint,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_rounded,
                          size: 36, color: AppColors.limeDeep)
                      .animate()
                      .scale(
                          duration: AppDurations.fast,
                          curve: AppCurves.emilOut),
                  const SizedBox(height: AppSpacing.p8),
                  Text(
                    l10n.alarmsLoggedSuccessfully,
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.limeInk,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            )
          else
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: MedImage(
                      imageUrl: med.imageUrl,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      borderRadius: 16,
                      placeholder: ColoredBox(
                        color: AppColors.pastelMint,
                        child: Icon(
                          Icons.medication_rounded,
                          size: 26,
                          color: L.accent,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleLarge.copyWith(
                          color: AppColors.inkStrong,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.4,
                        ),
                      ),
                      if (meta.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          meta,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.grey600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Text(
                        _diffStr,
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.limeDeep,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          const SizedBox(height: AppSpacing.p20),
          if (!_recorded)
            _SwipeToConfirm(
              onConfirmed: () async {
                final sched = widget.sch.sched as ScheduleEntry;
                final med = widget.sch.med as Medicine;
                final appState = context.read<AppState>();
                final timeLabel = fmtTime(sched.h, sched.m, context);
                final ok = await KnowYourMedicineSheet.confirmTake(
                  context,
                  med: med,
                  doseTimeLabel: timeLabel,
                );
                if (!ok || !mounted) return;
                HapticEngine.success();
                appState.takeDose(med.id, widget.sch.idx);
                setState(() => _recorded = true);
                Future.delayed(3.seconds, () {
                  if (mounted) setState(() => _recorded = false);
                });
              },
              L: L,
            ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// ALARM CARD WIDGET
// ══════════════════════════════════════════════════════════════════════
class _AlarmCard extends StatelessWidget {
  final ScheduledMed sch;
  final AppThemeColors L;
  final bool isNext;
  final VoidCallback onToggle;
  final VoidCallback onRemove;
  final VoidCallback onEdit;

  const _AlarmCard({
    required this.sch,
    required this.L,
    required this.isNext,
    required this.onToggle,
    required this.onRemove,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final med = sch.med;
    final s = sch.sched;
    final isEnabled = s.enabled;
    final timeLabel = fmtTime(s.h, s.m, context);
    final displayName =
        med.name.trim().isNotEmpty ? med.name.trim() : 'Untitled medicine';
    final subtitle = [
      if (med.dose.isNotEmpty) med.dose,
      if (s.label.isNotEmpty) s.label,
    ].join(' · ');

    return Dismissible(
      key: Key('alarm_${med.id}_${sch.idx}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        HapticEngine.heavyImpact();
        return true;
      },
      onDismissed: (_) => onRemove(),
      background: Container(
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsetsDirectional.only(end: AppSpacing.p24),
        margin: const EdgeInsets.only(bottom: AppSpacing.p12),
        decoration: BoxDecoration(
          color: AppColors.red.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white, size: 26),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.p12),
        child: Semantics(
          button: true,
          label: '$displayName reminder at $timeLabel',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HapticEngine.selection();
              onEdit();
            },
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              decoration: BoxDecoration(
                color: isEnabled ? Colors.white : L.card.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isNext
                      ? AppColors.limeDeep.withValues(alpha: 0.35)
                      : L.border.withValues(alpha: isEnabled ? 0.4 : 0.25),
                ),
                boxShadow: isEnabled
                    ? [
                        BoxShadow(
                          color: AppColors.eatoNavy.withValues(alpha: 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 52,
                    decoration: BoxDecoration(
                      color: !isEnabled
                          ? L.sub.withValues(alpha: 0.25)
                          : isNext
                              ? AppColors.limeDeep
                              : AppColors.lime.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: 52,
                      height: 52,
                      child: MedImage(
                        imageUrl: med.imageUrl,
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                        borderRadius: 14,
                        placeholder: ColoredBox(
                          color: AppColors.pastelMint,
                          child: Icon(
                            Icons.medication_rounded,
                            size: 24,
                            color: isEnabled
                                ? AppColors.limeDeep
                                : L.sub.withValues(alpha: 0.45),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.titleMedium.copyWith(
                            color: isEnabled
                                ? AppColors.inkStrong
                                : L.text.withValues(alpha: 0.4),
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodySmall.copyWith(
                              color: isEnabled
                                  ? AppColors.grey600
                                  : L.sub.withValues(alpha: 0.35),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: isEnabled
                                    ? (isNext
                                        ? AppColors.pastelMint
                                        : AppColors.pastelSun)
                                    : L.fill,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                timeLabel,
                                style: AppTypography.labelSmall.copyWith(
                                  color: !isEnabled
                                      ? L.sub.withValues(alpha: 0.45)
                                      : isNext
                                          ? AppColors.limeInk
                                          : const Color(0xFF8A6A1A),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (isNext) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.lime.withValues(alpha: 0.35),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  l10n.onboardingNext,
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.limeInk,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  CupertinoSwitch(
                    value: isEnabled,
                    activeTrackColor: AppColors.limeDeep,
                    onChanged: (_) {
                      HapticEngine.selection();
                      onToggle();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// SWIPE-TO-CONFIRM DOSE BUTTON
// ══════════════════════════════════════════════════════════════════════
class _SwipeToConfirm extends StatefulWidget {
  final VoidCallback onConfirmed;
  final AppThemeColors L;
  const _SwipeToConfirm({required this.onConfirmed, required this.L});

  @override
  State<_SwipeToConfirm> createState() => _SwipeToConfirmState();
}

class _SwipeToConfirmState extends State<_SwipeToConfirm> {
  double _offset = 0;
  bool _confirmed = false;
  static const double _knobSize = 52;
  static const double _trackPad = 4;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxOffset = constraints.maxWidth - _knobSize - _trackPad * 2;
        final progress = (_offset / maxOffset).clamp(0.0, 1.0);

        return Semantics(
          label: l10n.alarmsSlideToRecordDose2,
          slider: true,
          child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: widget.L.text.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: widget.L.border.withValues(alpha: 0.25),
              width: 0.5,
            ),
          ),
          child: Stack(
            children: [
              AnimatedContainer(
                duration: 50.ms,
                height: 60,
                width: _knobSize + _offset + _trackPad,
                decoration: BoxDecoration(
                  color: widget.L.text.withValues(alpha: progress * 0.12),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              Center(
                child: AnimatedOpacity(
                  duration: 150.ms,
                  opacity:
                      _confirmed ? 0 : (1.0 - progress * 1.6).clamp(0, 1.0),
                  child: Text(
                    l10n.alarmsSlideToRecordDose,
                    style: AppTypography.labelMedium.copyWith(color: widget.L.text.withValues(alpha: 0.65),
                      fontWeight: FontWeight.w700
                    ),
                  ),
                ),
              ),
              if (_confirmed)
                Center(
                  child: Text(
                    l10n.alarmsDoseRecorded,
                    style: AppTypography.labelMedium.copyWith(
                      color: widget.L.text,
                      fontWeight: FontWeight.w700
                    ),
                  ).animate().fadeIn(duration: 300.ms).scale(
                      begin: const Offset(0.95, 0.95), end: const Offset(1, 1)),
                ),
              if (!_confirmed)
                Positioned(
                  left: _trackPad + _offset,
                  top: _trackPad,
                  child: GestureDetector(
                    onHorizontalDragUpdate: (d) {
                      setState(() {
                        _offset = (_offset + d.delta.dx).clamp(0, maxOffset);
                      });
                    },
                    onHorizontalDragEnd: (_) {
                      if (_offset >= maxOffset * 0.88) {
                        setState(() {
                          _offset = maxOffset;
                          _confirmed = true;
                        });
                        widget.onConfirmed();
                      } else {
                        setState(() => _offset = 0);
                      }
                    },
                    child: Container(
                      width: _knobSize,
                      height: _knobSize,
                      decoration: BoxDecoration(
                        color: widget.L.text,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Center(
                            child: Text('→',
                                style: TextStyle(
                                    fontSize: 24,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700))),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// EMPTY STATE
// ══════════════════════════════════════════════════════════════════════
class _EmptyAlarmsState extends StatelessWidget {
  final AppThemeColors L;
  final bool hasMeds;
  final VoidCallback? onSetFirst;
  const _EmptyAlarmsState(
      {required this.L, required this.hasMeds, this.onSetFirst});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PremiumEmptyState(
      title: l10n.alarmsNoRemindersYet,
      subtitle: hasMeds
          ? 'Set reminders so you never miss a dose. Tap + to get started.'
          : 'Add medications first, then come back to set reminders.',
      mascotFeature: 'alarm',
      actionLabel: onSetFirst != null ? 'Set first reminder' : null,
      onAction: onSetFirst,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// QUICK ADD SECTION (when no alarms yet)
// ══════════════════════════════════════════════════════════════════════
class _QuickAddSection extends StatelessWidget {
  final List<Medicine> meds;
  final AppThemeColors L;
  final void Function(Medicine) onAdd;
  const _QuickAddSection(
      {required this.meds, required this.L, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text(l10n.homeYourMedicines,
              style: AppTypography.titleMedium.copyWith(
                color: L.text,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                fontSize: 16,
              )),
          const SizedBox(width: AppSpacing.p12),
          Expanded(
              child: Container(
                  height: 0.5, color: L.border.withValues(alpha: 0.1))),
        ]),
        const SizedBox(height: AppSpacing.p16),
        ...meds.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.p12),
              child:
                  _MedAlarmTile(med: e.value, L: L, onAdd: () => onAdd(e.value))
                      .animate(delay: (e.key * 60).ms)
                      .fadeIn(duration: 400.ms)
                      .slideX(begin: 0.05, end: 0),
            )),
      ],
    );
  }
}

class _MedAlarmTile extends StatelessWidget {
  final Medicine med;
  final AppThemeColors L;
  final VoidCallback onAdd;
  const _MedAlarmTile(
      {required this.med, required this.L, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: L.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: L.border.withValues(alpha: 0.35), width: 0.5),
        boxShadow: AppShadows.soft,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.p16, vertical: AppSpacing.p4),
        onTap: onAdd,
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
              color: L.text.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12)),
          child: Center(
            child: Icon(Icons.medication_rounded, size: 22, color: L.accent),
          ),
        ),
        title: Text(med.name,
            style: AppTypography.titleMedium.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3)),
        subtitle: Text(l10n.alarmsNeedsSchedule,
            style: AppTypography.bodySmall.copyWith(
                color: L.sub,
                fontSize: 12,
                fontWeight: FontWeight.w500)),
        trailing: Icon(Icons.add_circle_outline_rounded,
            color: L.text.withValues(alpha: 0.3), size: 24),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// MED PICKER SHEET (bottom sheet to choose which med to schedule)
// ══════════════════════════════════════════════════════════════════════
class _MedPickerSheet extends StatelessWidget {
  final List<Medicine> meds;
  final AppThemeColors L;
  final void Function(Medicine) onPick;
  const _MedPickerSheet(
      {required this.meds, required this.L, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return RefinedSheetWrapper(
      title: l10n.alarmsSetReminderFor,
      child: ConstrainedBox(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.55),
        child: ListView.separated(
  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          shrinkWrap: true,
          // The sheet opens over the Alarms tab, so the shell's floating nav
          // island covers the last rows. p40 was not enough — the final
          // medicine sat half-hidden behind it and the list does not scroll
          // far enough to free it.
          padding: const EdgeInsets.fromLTRB(
              0, AppSpacing.p8, 0, AppSpacing.bottomBuffer),
          itemCount: meds.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.p8),
          itemBuilder: (_, i) {
            final med = meds[i];
            return Semantics(
              button: true,
              label: 'Set reminder for ${med.name}',
              child: AnimatedPressable(
                onTap: () => onPick(med),
                scaleFactor: 0.985,
                child: MedAiGlass(
                  radius: AppRadius.l,
                  padding: const EdgeInsets.all(AppSpacing.p16),
                  child: Row(children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: L.text.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                        child: Text('💊', style: TextStyle(fontSize: 20))),
                  ),
                  const SizedBox(width: AppSpacing.p16),
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(med.name,
                          style: AppTypography.labelLarge.copyWith(
                              color: L.text, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(med.dose,
                          style: AppTypography.bodySmall.copyWith(
                              color: L.sub,
                              fontSize: 12)),
                    ],
                  )),
                  Icon(Icons.chevron_right_rounded,
                      color: L.sub.withValues(alpha: 0.3), size: 24),
                ]),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// ADD ALARM SHEET
// ══════════════════════════════════════════════════════════════════════
class _AddAlarmSheet extends StatefulWidget {
  final Medicine med;
  final int? scheduleIndex;
  final VoidCallback onClose;
  const _AddAlarmSheet(
      {required this.med,
      this.scheduleIndex,
      required this.onClose});

  @override
  State<_AddAlarmSheet> createState() => _AddAlarmSheetState();
}

class _AddAlarmSheetState extends State<_AddAlarmSheet> {
  late TimeOfDay _time;
  late String _label;

  @override
  void initState() {
    super.initState();
    if (widget.scheduleIndex != null &&
        widget.scheduleIndex! < widget.med.schedule.length) {
      final s = widget.med.schedule[widget.scheduleIndex!];
      _time = TimeOfDay(hour: s.h, minute: s.m);
      _label = s.label;
    } else {
      _time = TimeOfDay.now();
      _label = 'Daily Dose';
    }
  }

  static const List<String> _quickLabels = [
    'Morning',
    'Afternoon',
    'Evening',
    'Night',
    'Daily Dose'
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final L = context.L;
    return RefinedSheetWrapper(
      title: widget.scheduleIndex != null ? 'Edit Reminder' : 'New Reminder',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── For which med ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p16, vertical: AppSpacing.p12),
            decoration: BoxDecoration(
              color: L.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: L.border.withValues(alpha: 0.35), width: 0.5),
              boxShadow: AppShadows.soft,
            ),
            child: Row(children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: L.text.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                    child: Text('💊', style: TextStyle(fontSize: 12))),
              ),
              const SizedBox(width: AppSpacing.p12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(widget.med.name,
                        style: AppTypography.labelLarge.copyWith(
                            color: L.text, fontWeight: FontWeight.w700)),
                    Text(widget.med.dose,
                        style: AppTypography.bodySmall.copyWith(
                            color: L.sub, fontSize: 12)),
                  ])),
            ]),
          ),

          const SizedBox(height: AppSpacing.p24),

          // ── Time picker ──
          ModernTimePicker(
            initialTime: _time,
            onTimeChanged: (t) => setState(() => _time = t),
          ),

          const SizedBox(height: AppSpacing.p24),

          // ── Quick label chips ──
          Text(
            l10n.alarmsLabel,
            style: AppTypography.titleMedium.copyWith(
              color: L.text,
              fontWeight: FontWeight.w700,
              fontSize: 15,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: AppSpacing.p12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickLabels.map((label) {
              final selected = _label == label;
              return Semantics(
                button: true,
                selected: selected,
                label: label,
                child: AnimatedPressable(
                  onTap: () {
                    HapticEngine.selection();
                    setState(() => _label = label);
                  },
                  scaleFactor: 0.97,
                  child: AnimatedContainer(
                    duration: MedAiA11y.motion(context, 200.ms),
                    constraints: const BoxConstraints(
                      minHeight: MedAiA11y.minTapTargetCompact,
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.p12, vertical: AppSpacing.p8),
                    decoration: BoxDecoration(
                      color: selected ? L.text : L.fill.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color:
                            selected ? L.text : L.border.withValues(alpha: 0.1),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      label,
                      style: AppTypography.labelSmall.copyWith(
                        color: selected ? L.bg : L.sub,
                        fontWeight: FontWeight.w700
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: AppSpacing.p32),

          MedAiCTA(
            label: widget.scheduleIndex != null
                ? 'Save changes'
                : l10n.alarmsAddReminder,
            onTap: () {
              HapticEngine.success();
              if (widget.scheduleIndex != null) {
                context.read<AppState>().updateSchedule(
                      widget.med.id,
                      widget.scheduleIndex!,
                      ScheduleEntry(
                        id: widget.med.schedule[widget.scheduleIndex!].id,
                        h: _time.hour,
                        m: _time.minute,
                        label: _label,
                        days: widget.med.schedule[widget.scheduleIndex!].days,
                        enabled:
                            widget.med.schedule[widget.scheduleIndex!].enabled,
                      ),
                    );
              } else {
                context.read<AppState>().addSchedule(
                      widget.med.id,
                      ScheduleEntry(
                        id: 'alarm_${DateTime.now().millisecondsSinceEpoch}',
                        h: _time.hour,
                        m: _time.minute,
                        label: _label,
                        days: const [1, 2, 3, 4, 5, 6, 0],
                        enabled: true,
                      ),
                    );
              }
              widget.onClose();
            },
            semanticsLabel: widget.scheduleIndex != null
                ? 'Save reminder changes'
                : l10n.alarmsAddReminder,
          ),
        ],
      ),
    );
  }
}
