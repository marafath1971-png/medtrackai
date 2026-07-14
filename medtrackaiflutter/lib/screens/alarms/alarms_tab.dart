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
              await context.read<AppState>().loadFromStorage();
            },
            displacement: 100,
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
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
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
                      padding: const EdgeInsets.fromLTRB(24, 36, 24, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: MedAiSectionHeader(
                              title: 'Reminders',
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
                    padding: const EdgeInsets.symmetric(horizontal: 20),
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

                                  ScaffoldMessenger.of(context)
                                      .clearSnackBars();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Alarm for ${sch.med.name} removed'),
                                      duration: const Duration(seconds: 3),
                                      action: SnackBarAction(
                                        label: 'Undo',
                                        textColor: L.primary,
                                        onPressed: () {
                                          state.addSchedule(removedSch.med.id,
                                              removedSch.sched);
                                        },
                                      ),
                                    ),
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
                      padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
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
                      padding: const EdgeInsets.fromLTRB(24, 40, 24, 16),
                      child: MedAiSectionHeader(
                        title: 'Paused',
                        subtitle: '${inactiveSchedules.length} off',
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, idx) {
                          final sch = inactiveSchedules[idx];
                          return _entrance(
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
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

                                  ScaffoldMessenger.of(context)
                                      .clearSnackBars();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Alarm for ${sch.med.name} removed'),
                                      duration: const Duration(seconds: 3),
                                      action: SnackBarAction(
                                        label: 'Undo',
                                        textColor: L.primary,
                                        onPressed: () {
                                          state.addSchedule(removedSch.med.id,
                                              removedSch.sched);
                                        },
                                      ),
                                    ),
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
                      padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
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
    final topPad = MediaQuery.of(context).padding.top;
    final subtitle =
        activeCount > 0 ? '$activeCount active reminders' : 'Stay on schedule';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: EdgeInsets.fromLTRB(20, topPad + 12, 20, 10),
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
                  'Alarms',
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
              label: 'Add reminder',
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: L.text,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        '$count',
        style: AppTypography.labelSmall.copyWith(
          color: L.bg,
          fontWeight: FontWeight.w700,
          fontSize: 11,
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
    final med = widget.sch.med as Medicine;
    final s = widget.sch.sched as ScheduleEntry;
    final L = widget.L;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFC2EF7D), Color(0xFFA9E65F)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.limeDeep.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const LiveStatusDot(
                        color: AppThemeColors2026.electric,
                        size: 6,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Upcoming dose',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.limeInk.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w700,
                          fontSize: 10.5,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  fmtTime(s.h, s.m, context),
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.limeInk.withValues(alpha: 0.75),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            if (_recorded)
              Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: L.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('✅', style: TextStyle(fontSize: 48))
                        .animate()
                        .scale(duration: AppDurations.fast, curve: AppCurves.emilOut),
                    const SizedBox(height: 12),
                    Text(
                      'Logged successfully',
                      style: AppTypography.labelMedium.copyWith(
                        color: L.success,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            med.name,
                            style: AppTypography.headlineMedium.copyWith(
                              color: AppColors.limeInk,
                              fontWeight: FontWeight.w800,
                              fontSize: 28,
                              letterSpacing: -0.6,
                              height: 1.0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${med.dose} · ${s.label}',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.limeInk.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _diffStr,
                          style: AppTypography.titleMedium.copyWith(
                            color: AppColors.limeInk,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: const Text('💊', style: TextStyle(fontSize: 32)),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 32),
            if (!_recorded)
              _SwipeToConfirm(
                onConfirmed: () {
                  HapticEngine.success();
                  context
                      .read<AppState>()
                      .takeDose(widget.sch.med.id, widget.sch.idx);
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
    final med = sch.med;
    final s = sch.sched;
    final isEnabled = s.enabled;
    
    // We parse the time to separate the H:MM from the AM/PM if possible.
    final timeString = fmtTime(s.h, s.m, context);
    final parts = timeString.split(' ');
    final mainTime = parts[0];
    final amPm = parts.length > 1 ? parts[1] : '';

    return Dismissible(
      key: Key('alarm_${med.id}_${sch.idx}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        HapticEngine.heavyImpact();
        return true;
      },
      onDismissed: (_) => onRemove(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: CupertinoColors.destructiveRed,
        child: const Icon(CupertinoIcons.delete, color: Colors.white, size: 28),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onEdit,
          child: PremiumTextureCard(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        radius: 22,
        texture: PremiumTextureStyle.fineGrain,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          mainTime,
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.8,
                            color: isEnabled ? L.text : L.sub.withValues(alpha: 0.4),
                            height: 1.0,
                          ),
                        ),
                        if (amPm.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          Text(
                            amPm,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isEnabled ? L.text : L.sub.withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${med.name} • ${s.label}',
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: isEnabled
                            ? L.sub.withValues(alpha: 0.75)
                            : L.sub.withValues(alpha: 0.35),
                      ),
                    ),
                  ],
                ),
              ),
              if (isNext)
                Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.lime.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Next',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.limeInk,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ),
              CupertinoSwitch(
                value: isEnabled,
                activeTrackColor: AppColors.limeDeep,
                onChanged: (_) => onToggle(),
              ),
            ],
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxOffset = constraints.maxWidth - _knobSize - _trackPad * 2;
        final progress = (_offset / maxOffset).clamp(0.0, 1.0);

        return Semantics(
          label: 'Slide to record dose',
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
                    'Slide to record dose →',
                    style: AppTypography.labelMedium.copyWith(color: widget.L.text.withValues(alpha: 0.65),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              if (_confirmed)
                Center(
                  child: Text(
                    '✓ Dose Recorded',
                    style: AppTypography.labelMedium.copyWith(
                      color: widget.L.text,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
      decoration: BoxDecoration(
        color: L.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: L.border.withValues(alpha: 0.35), width: 0.5),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: L.text.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                '🔔',
                style: TextStyle(fontSize: 40),
              ),
            ),
          ).animate().slideY(
              begin: 0.2, end: 0, curve: Curves.easeOutBack, duration: 600.ms),
          const SizedBox(height: 24),
          Text(
            'No reminders yet',
            style: AppTypography.titleMedium.copyWith(
              color: L.text,
              fontWeight: FontWeight.w800,
              fontSize: 20,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            hasMeds
                ? 'Set reminders to never miss a dose again. Tap + to get started.'
                : 'Add your medications first, then come back to set reminders.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(color: L.sub.withValues(alpha: 0.7),
              height: 1.6,
              fontSize: 14,
            ),
          ),
          if (onSetFirst != null) ...[
            const SizedBox(height: 32),
            MedAiCTA(
              label: 'Set first reminder',
              onTap: onSetFirst,
              semanticsLabel: 'Set first reminder',
            ),
          ],
        ],
      ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text('Your medicines',
              style: AppTypography.titleMedium.copyWith(
                color: L.text,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                fontSize: 16,
              )),
          const SizedBox(width: 12),
          Expanded(
              child: Container(
                  height: 0.5, color: L.border.withValues(alpha: 0.1))),
        ]),
        const SizedBox(height: 16),
        ...meds.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
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
    return Container(
      decoration: BoxDecoration(
        color: L.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: L.border.withValues(alpha: 0.35), width: 0.5),
        boxShadow: AppShadows.soft,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        onTap: onAdd,
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
              color: L.text.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12)),
          child: const Center(
            child: Text('💊', style: TextStyle(fontSize: 22)),
          ),
        ),
        title: Text(med.name,
            style: AppTypography.titleMedium.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3)),
        subtitle: Text('Needs schedule',
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
    return RefinedSheetWrapper(
      title: 'Set reminder for',
      child: ConstrainedBox(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.55),
        child: ListView.separated(
  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 40),
          itemCount: meds.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
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
                  padding: const EdgeInsets.all(16),
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
                  const SizedBox(width: 16),
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
    final L = context.L;
    return RefinedSheetWrapper(
      title: widget.scheduleIndex != null ? 'Edit Reminder' : 'New Reminder',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── For which med ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              const SizedBox(width: 12),
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

          const SizedBox(height: 24),

          // ── Time picker ──
          ModernTimePicker(
            initialTime: _time,
            onTimeChanged: (t) => setState(() => _time = t),
          ),

          const SizedBox(height: 24),

          // ── Quick label chips ──
          Text(
            'Label',
            style: AppTypography.titleMedium.copyWith(
              color: L.text,
              fontWeight: FontWeight.w700,
              fontSize: 15,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 10),
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
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 32),

          MedAiCTA(
            label: widget.scheduleIndex != null
                ? 'Save changes'
                : 'Add reminder',
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
                : 'Add reminder',
          ),
        ],
      ),
    );
  }
}
