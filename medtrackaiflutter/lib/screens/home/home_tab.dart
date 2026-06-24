import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../services/smart_alert_service.dart';
import '../../widgets/shared/shared_widgets.dart';
import '../../core/utils/haptic_engine.dart';
import '../../core/utils/color_utils.dart';
import 'widgets/home_meds_section.dart';
import 'widgets/med_card.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'widgets/home_header.dart';
import 'widgets/streak_modal.dart';
import 'widgets/settings_modal_new.dart';
import 'widgets/profile_selector_ribbon.dart';
import 'widgets/voice_assistant_overlay.dart';
import '../../widgets/viral/share_milestone_card.dart';
import '../../widgets/viral/ai_quick_log_sheet.dart';
import '../medicine/medicine_detail_screen.dart';
import '../../widgets/common/mesh_gradient.dart';
import 'widgets/recovery_course_tracker.dart';
import 'widgets/home_mascot_card.dart';

class HomeTab extends StatefulWidget {
  final VoidCallback onScan;
  final ValueChanged<int>? onSwitchTab;
  const HomeTab({super.key, required this.onScan, this.onSwitchTab});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> with SingleTickerProviderStateMixin {
  bool _showStreak = false;
  bool _showSettings = false;
  Medicine? _viewingMed;
  bool _startInEditMode = false;
  double _scrollOffset = 0;
  DateTime _selectedDate = DateTime.now();
  late final ScrollController _scrollController;
  final GlobalKey _medsEmptyKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    setState(() {
      _scrollOffset = _scrollController.offset;
    });
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: 800.ms,
      curve: Curves.easeOutQuart,
    );
    HapticEngine.selection();
  }

  void _setDate(DateTime date) {
    if (date.year == _selectedDate.year &&
        date.month == _selectedDate.month &&
        date.day == _selectedDate.day) {
      return;
    }
    HapticEngine.selection();
    setState(() => _selectedDate = date);
  }

  Widget _buildMainDashboard(
    BuildContext context,
    AppThemeColors L,
    List<DoseItem> doses,
    int streak,
    Map<String, bool> takenMap,
    List<Medicine> meds,
    int takenCount,
    int remaining,
    double dosePct,
  ) {
    final severeSymptoms = context.select<AppState, List<Symptom>>((s) => s.symptoms)
        .where((s) => s.severity >= 8 && DateTime.now().difference(s.timestamp).inHours < 24)
        .toList();
    final hasSevereSymptom = severeSymptoms.isNotEmpty;

    final activeCourses = meds.where((m) => m.isCourseActive).toList();

    // Pre-calculate time groups for timeline to avoid redundant computations and ensure correct childCount
    final groups = [
      (
        title: 'Morning',
        items: doses.where((d) => d.sched.h >= 5 && d.sched.h < 11).toList()
      ),
      (
        title: 'Afternoon',
        items: doses.where((d) => d.sched.h >= 11 && d.sched.h < 17).toList()
      ),
      (
        title: 'Evening',
        items: doses.where((d) => d.sched.h >= 17 && d.sched.h < 21).toList()
      ),
      (
        title: 'Night',
        items: doses.where((d) => d.sched.h >= 21 || d.sched.h < 5).toList()
      ),
    ].where((g) => g.items.isNotEmpty).toList();

    return Scaffold(
      backgroundColor: L.bg,
      body: Stack(
        children: [
          // ── Background Ambient Glow (2026 Viral Aura) ──
          Positioned.fill(
            child: Container(color: L.bg),
          ),
          Positioned.fill(
            child: Opacity(
              opacity: 0.15,
              child: MeshGradient(
                colors: [
                  L.accent.withValues(alpha: 0.6),
                  L.purple.withValues(alpha: 0.6),
                  L.bg,
                  Colors.blue.withValues(alpha: 0.6),
                ],
              ),
            ).animate(onPlay: (controller) => controller.repeat(reverse: true))
             .fade(begin: 0.5, end: 1.0, duration: 3000.ms, curve: Curves.easeInOutSine),
          ),
          RefreshIndicator(
            onRefresh: () async {
              HapticEngine.selection();
              await context.read<AppState>().loadFromStorage();
            },
            displacement: 110,
            color: L.bg,
            backgroundColor: L.text,
            strokeWidth: 2.5,
            child: Scrollbar(
              controller: _scrollController,
              child: CustomScrollView(
  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                controller: _scrollController,
                key: const PageStorageKey('home_scroll'),
                physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics()),
                slivers: [
                  SliverToBoxAdapter(
                    child: SizedBox(
                        height: MediaQuery.of(context).padding.top + 50),
                  ),

                  SliverToBoxAdapter(
                    child: const ProfileSelectorRibbon()
                        .animate()
                        .fadeIn(duration: 500.ms)
                        .scale(
                            begin: const Offset(0.98, 0.98),
                            end: const Offset(1, 1),
                            curve: Curves.easeOutCubic),
                  ),

                  if (hasSevereSymptom)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                      sliver: SliverToBoxAdapter(
                        child: _EmergencyWarningCard(
                          symptom: severeSymptoms.first,
                        ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0),
                      ),
                    ),

                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    sliver: SliverToBoxAdapter(
                      child: _DayToggle(
                        selectedDate: _selectedDate,
                        onChanged: _setDate,
                      ),
                    ),
                  ),

                  if (activeCourses.isNotEmpty)
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final med = activeCourses[index];
                          return RecoveryCourseTracker(
                            medicine: med,
                            onTap: () {
                              HapticEngine.selection();
                              setState(() {
                                _viewingMed = med;
                                _startInEditMode = false;
                              });
                            },
                          )
                          .animate()
                          .fadeIn(duration: 500.ms, delay: (100 * index).ms)
                          .slideY(begin: 0.1, end: 0, curve: Curves.easeOutBack);
                        },
                        childCount: activeCourses.length,
                      ),
                    ),

                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    sliver: SliverToBoxAdapter(
                      child: _CalAiRingHero(
                        takenCount: takenCount,
                        total: doses.length,
                        dosePct: dosePct,
                        streak: streak,
                        remaining: remaining,
                      ).animate().fadeIn(duration: 600.ms).slideY(
                          begin: 0.06, end: 0, curve: Curves.easeOutExpo),
                    ),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    sliver: SliverToBoxAdapter(
                      child: const HomeMascotCard()
                          .animate()
                          .fadeIn(duration: 600.ms, delay: 150.ms)
                          .slideY(
                              begin: 0.06,
                              end: 0,
                              curve: Curves.easeOutExpo),
                    ),
                  ),

                  if (streak >= 7)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      sliver: SliverToBoxAdapter(
                        child: _ShareMilestoneCardCTA(
                          streak: streak,
                          dosePct: dosePct,
                          userName: context.select<AppState, String>((s) => s.activeProfile?.name ?? s.profile?.name ?? ''),
                          totalDosesTaken: takenCount,
                        )
                            .animate()
                            .fadeIn(duration: 600.ms, delay: 300.ms)
                            .slideX(begin: 0.1, end: 0),
                      ),
                    ),

                  // ── UPCOMING DOSES CAROUSEL (Moved directly below Hero Progress Card) ──
                  if (doses.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      sliver: SliverToBoxAdapter(
                        child: _NextDoseCarousel(
                          doses: doses,
                          takenToday: takenMap,
                          state: context.read<AppState>(),
                          onView: (med) => setState(() {
                            _viewingMed = med;
                            _startInEditMode = false;
                          }),
                        )
                            .animate()
                            .fadeIn(duration: 800.ms, delay: 100.ms)
                            .slideY(
                                begin: 0.08, end: 0, curve: Curves.easeOutExpo),
                      ),
                    ),

                  // ── DAILY SCHEDULE SECTION HEADER ──
                  if (doses.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                      sliver: SliverToBoxAdapter(
                        child: Row(
                          children: [
                            const Text('📅', style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 8),
                            Text(
                              'DAILY SCHEDULE',
                              style: AppTypography.labelSmall.copyWith(
                                color: L.sub.withValues(alpha: 0.8),
                                fontSize: 11,
                                letterSpacing: 2.0,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // ── DAILY SCHEDULE GROUPS LIST ──
                  if (doses.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final group = groups[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 24),
                              child: HomeDoseGroup(
                                title: group.title,
                                doses: group.items,
                                takenToday: takenMap,
                                state: context.read<AppState>(),
                                selectedDate: _selectedDate,
                                onView: (med) => setState(() {
                                  _viewingMed = med;
                                  _startInEditMode = false;
                                }),
                                onEdit: (med) => setState(() {
                                  _viewingMed = med;
                                  _startInEditMode = true;
                                }),
                                onTakeDose: () {
                                  // HapticEngine.success() or similar can go here
                                },
                              ),
                            );
                          },
                          childCount: groups.length,
                        ),
                      ),
                    ),

                  // ── MEDICINE CABINET SECTION HEADER ──
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenPadding),
                    sliver: SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12, top: 8),
                        child: Row(
                          children: [
                            const Text('🗄️', style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 8),
                            Text(
                              'MEDICINE CABINET',
                              style: AppTypography.labelSmall.copyWith(
                                color: L.sub.withValues(alpha: 0.8),
                                fontSize: 11,
                                letterSpacing: 2.0,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ── MEDICINE CABINET CONTENT ──
                  if (meds.isEmpty)
                    SliverPadding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.screenPadding),
                        sliver: SliverToBoxAdapter(
                            child: HomeMedsEmptyState(
                          key: _medsEmptyKey,
                          onAdd: widget.onScan,
                        )))
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.screenPadding),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final med = meds[index];
                            return MedCard(
                              med: med,
                              onView: () {
                                HapticEngine.selection();
                                setState(() {
                                  _viewingMed = med;
                                  _startInEditMode = false;
                                });
                              },
                              onEdit: () {
                                HapticEngine.selection();
                                setState(() {
                                  _viewingMed = med;
                                  _startInEditMode = true;
                                });
                              },
                            );
                          },
                          childCount: meds.length,
                        ),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 180)),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: HomeHeader(
              state: context.read<AppState>(),
              streak: streak,
              scrollOffset: _scrollOffset,
              onTap: _scrollToTop,
              onOpenStreak: () => setState(() => _showStreak = true),
              onOpenSettings: () => setState(() => _showSettings = true),
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
              )),
          _buildOverlay(
              _showSettings,
              'settings',
              SettingsModal(
                onClose: () => setState(() => _showSettings = false),
              )),
          const VoiceAssistantOverlay(),
          Positioned(
            bottom: 110 + MediaQuery.of(context).padding.bottom,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const _AiQuickLogFAB(),
                _InstantScanFAB(onScan: widget.onScan),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final doses = context.select<AppState, List<DoseItem>>(
        (s) => s.getDoses(date: _selectedDate));
    final streak = context.select<AppState, int>((s) => s.getStreak());
    final takenMap = context.select<AppState, Map<String, bool>>(
        (s) => s.getTakenMapForDate(_selectedDate));
    final meds = context.select<AppState, List<Medicine>>((s) => s.meds);

    final takenCount = doses.where((d) => takenMap[d.key] == true).length;
    final remaining = doses.length - takenCount;
    final dosePct = doses.isNotEmpty ? takenCount / doses.length : 0.0;

    final L = context.L;

    final mainContent = _buildMainDashboard(context, L, doses, streak, takenMap,
        meds, takenCount, remaining, dosePct);

    return AnimatedSwitcher(
      duration: 400.ms,
      switchInCurve: Curves.easeOutExpo,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
            position:
                Tween<Offset>(begin: const Offset(0.04, 0), end: Offset.zero)
                    .animate(animation),
            child: child),
      ),
      child: _viewingMed != null
          ? MedicineDetailScreen(
              key: ValueKey('med_detail_${_viewingMed!.id}'),
              medId: _viewingMed!.id,
              onBack: () => setState(() => _viewingMed = null),
              initialEditMode: _startInEditMode)
          : Container(key: const ValueKey('home_main'), child: mainContent),
    );
  }

  Widget _buildOverlay(bool visible, String key, Widget child) {
    return AnimatedSwitcher(
      duration: 350.ms,
      switchInCurve: Curves.easeOutExpo,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
            position:
                Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
                    .animate(anim),
            child: child),
      ),
      child: visible
          ? SizedBox.expand(key: ValueKey(key), child: child)
          : const SizedBox.shrink(),
    );
  }
}

class _AiQuickLogFAB extends StatefulWidget {
  const _AiQuickLogFAB();

  @override
  State<_AiQuickLogFAB> createState() => _AiQuickLogFABState();
}

class _AiQuickLogFABState extends State<_AiQuickLogFAB>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.2, end: 0.5).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return AnimatedPressable(
      onTapDown: (_) {
        HapticEngine.selection();
        setState(() => _pressed = true);
      },
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () => AiQuickLogSheet.show(context),
      child: AnimatedBuilder(
        animation: _glowAnim,
        builder: (context, child) => AnimatedScale(
          scale: _pressed ? 0.92 : 1.0,
          duration: 150.ms,
          curve: Curves.easeOutCubic,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: L.accent.withValues(alpha: 0.2 + _glowAnim.value * 0.2),
                  blurRadius: 24,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.5),
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add_rounded, color: Colors.black, size: 16),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.auto_awesome_rounded, color: Colors.black87, size: 14),
                const SizedBox(width: 8),
                Text(
                  'Log Dose',
                  style: AppTypography.labelLarge.copyWith(
                    color: Colors.black,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.2,
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

class _ShareMilestoneCardCTA extends StatelessWidget {
  final int streak;
  final double dosePct;
  final String userName;
  final int totalDosesTaken;
  const _ShareMilestoneCardCTA({
    required this.streak,
    this.dosePct = 0.0,
    this.userName = '',
    this.totalDosesTaken = 0,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final gradColors = _getStreakGradient(streak, L);
    return AnimatedPressable(
      onTap: () {
        HapticEngine.selection();
        ShareMilestoneCard.share(
          context,
          streak,
          adherencePct: dosePct,
          userName: userName,
          totalDosesTaken: totalDosesTaken,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: L.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: L.border.withValues(alpha: 0.08), width: 1.0),
          boxShadow: AppShadows.neumorphic,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: L.accent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.share_rounded, size: 18, color: L.accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🔥 Share your $streak-day streak!',
                    style: AppTypography.titleMedium.copyWith(
                      color: L.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Inspire your followers on TikTok & Instagram',
                    style: AppTypography.bodySmall.copyWith(
                      color: L.sub.withValues(alpha: 0.55),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: gradColors[0].withValues(alpha: 0.7), size: 22),
          ],
        ),
      ),
    );
  }

  List<Color> _getStreakGradient(int streak, AppThemeColors L) {
    return [L.text, L.text.withValues(alpha: 0.7)];
  }
}

class _NextDoseCarousel extends StatefulWidget {
  final List<DoseItem> doses;
  final Map<String, bool> takenToday;
  final AppState state;
  final Function(Medicine) onView;

  const _NextDoseCarousel({
    required this.doses,
    required this.takenToday,
    required this.state,
    required this.onView,
  });

  @override
  State<_NextDoseCarousel> createState() => _NextDoseCarouselState();
}

class _NextDoseCarouselState extends State<_NextDoseCarousel> {
  late final PageController _controller;
  double _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.85);
    _controller.addListener(() => setState(() => _currentPage = _controller.page!));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final upcoming = widget.doses.where((d) => widget.takenToday[d.key] != true).toList();
    final toShow = upcoming.isEmpty ? widget.doses.take(3).toList() : upcoming.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12, left: 24),
          child: Text('Coming Up Next',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: L.text,
              )),
        ),
        SizedBox(
          height: 140,
          child: PageView.builder(
            controller: _controller,
            itemCount: toShow.length,
            itemBuilder: (context, index) {
              final d = toShow[index];
              final isTaken = widget.takenToday[d.key] == true;
              final timeStr = '${d.sched.h.toString().padLeft(2, '0')}:${d.sched.m.toString().padLeft(2, '0')}';
              
              final delta = (index - _currentPage).abs();
              final scale = (1 - (delta * 0.15)).clamp(0.85, 1.0);

              return Transform.scale(
                scale: scale,
                child: BouncingButton(
                  onTap: () => widget.onView(d.med),
                  child: SquircleCard(
                    padding: const EdgeInsets.all(16),
                    color: L.card,
                    showBorder: true,
                    borderWidth: 1.0,
                    boxShadow: AppShadows.neumorphic,
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: hexToColor(d.med.color).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(Icons.vaccines_rounded, size: 24, color: hexToColor(d.med.color)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(d.med.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600, color: L.text, fontSize: 14)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(timeStr, style: AppTypography.monoNumber.copyWith(color: L.sub.withValues(alpha: 0.4), fontSize: 12)),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: isTaken ? L.green.withValues(alpha: 0.1) : L.text.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(4)),
                                    child: Text(isTaken ? 'TAKEN' : 'UNTAKEN', style: AppTypography.labelSmall.copyWith(fontSize: 7, fontWeight: FontWeight.w600, color: L.sub.withValues(alpha: 0.3))),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ANIMATED NEON RING
// ─────────────────────────────────────────────────────────────
class _AnimatedRing extends StatefulWidget {
  final double percent;
  final List<Color> colors;
  final Color trackColor;
  final double size;
  final double strokeWidth;
  final Widget child;

  const _AnimatedRing({
    required this.percent,
    required this.colors,
    required this.trackColor,
    required this.size,
    required this.strokeWidth,
    required this.child,
  });

  @override
  State<_AnimatedRing> createState() => _AnimatedRingState();
}

class _AnimatedRingState extends State<_AnimatedRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800));
    _anim = Tween<double>(begin: 0, end: widget.percent)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(_AnimatedRing old) {
    super.didUpdateWidget(old);
    if (old.percent != widget.percent) {
      _anim = Tween<double>(begin: _anim.value, end: widget.percent)
          .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
      _ctrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) => SizedBox(
        width: widget.size,
        height: widget.size,
        child: RepaintBoundary(
          child: CustomPaint(
            painter: _RingPainter(
              percent: _anim.value,
              colors: widget.colors,
              trackColor: widget.trackColor,
              strokeWidth: widget.strokeWidth,
            ),
            child: Center(child: widget.child),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double percent;
  final List<Color> colors;
  final Color trackColor;
  final double strokeWidth;

  const _RingPainter({
    required this.percent,
    required this.colors,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    const startAngle = -1.5707963267948966;
    final sweepAngle = 6.283185307179586 * percent;

    // Background track — soft, barely visible
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      6.283185307179586,
      false,
      Paint()
        ..color = trackColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    if (percent > 0) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      final validColors = colors.length >= 2 ? colors : [colors.first, colors.first];

      final gradient = SweepGradient(
        colors: validColors,
        startAngle: 0.0,
        endAngle: sweepAngle,
        tileMode: TileMode.decal,
        transform: GradientRotation(startAngle),
      );

      // Clean crisp arc — no shadow/glow
      canvas.drawArc(
        rect,
        startAngle,
        sweepAngle,
        false,
        Paint()
          ..shader = gradient.createShader(rect)
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.percent != percent || old.colors != colors;
}

// ─────────────────────────────────────────────────────────────
// DOSE GROUP — grouped timeline section
// ─────────────────────────────────────────────────────────────
class HomeDoseGroup extends StatefulWidget {
  final String title;
  final List<DoseItem> doses;
  final Map<String, bool> takenToday;
  final String? globalNextEntryKey;
  final AppState state;
  final DateTime selectedDate;
  final Function(Medicine) onView;
  final Function(Medicine) onEdit;
  final VoidCallback? onTakeDose;
  final Duration delayOffset;

  const HomeDoseGroup({
    super.key,
    required this.title,
    required this.doses,
    required this.takenToday,
    this.globalNextEntryKey,
    required this.state,
    required this.selectedDate,
    required this.onView,
    required this.onEdit,
    this.onTakeDose,
    this.delayOffset = Duration.zero,
  });

  @override
  State<HomeDoseGroup> createState() => _HomeDoseGroupState();
}

class _HomeDoseGroupState extends State<HomeDoseGroup> {
  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final now = DateTime.now();
    final nowMins = now.hour * 60 + now.minute;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            widget.title.toUpperCase(),
            style: AppTypography.sectionLabel.copyWith(
              color: L.sub.withValues(alpha: 0.5),
            ),
          ),
        ),
        ...widget.doses.asMap().entries.map((entry) {
          final idx = entry.key;
          final d = entry.value;
          final isTaken = widget.takenToday[d.key] == true;
          final doseMins = d.sched.h * 60 + d.sched.m;
          final isOverdue = !isTaken && doseMins < nowMins;
          final isActualNext = d.key == widget.globalNextEntryKey;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DoseCard(
              med: d.med,
              sched: d.sched,
              taken: isTaken,
              overdue: isOverdue,
              isNext: isActualNext && !isTaken,
              onTake: () {
                widget.state.toggleDose(d, date: widget.selectedDate);
                widget.onTakeDose?.call();
                _showUndoSnackbar(context, d);
              },
              onSnooze: () => widget.state.snoozeDose(d, 30),
              onTap: () => widget.onView(d.med),
            )
                .animate(delay: widget.delayOffset + (idx * 50).ms)
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuart),
          );
        }),
      ],
    );
  }

  void _showUndoSnackbar(BuildContext context, DoseItem d) {
    SmartAlertService.show(
      context,
      title: 'Dose Logged',
      message: '${d.med.name} marked as taken.',
      type: AlertType.success,
      icon: Icons.check_circle_rounded,
    );
  }
}


// ─────────────────────────────────────────────────────────────
// DAY TOGGLE — Cal AI style segment control
// ─────────────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────
// CAL AI RING HERO — The signature home screen element
// Large centered ring + bold numbers. THIS is the viral element.
// ─────────────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────
// CAL AI RING HERO — premium circular progress hero
// ─────────────────────────────────────────────────────────────
class _CalAiRingHero extends StatelessWidget {
  final int takenCount;
  final int total;
  final double dosePct;
  final int streak;
  final int remaining;

  const _CalAiRingHero({
    required this.takenCount,
    required this.total,
    required this.dosePct,
    required this.streak,
    required this.remaining,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final isDark = context.isDark;
    final isAllDone = total > 0 && dosePct >= 1.0;
    final isEmpty = total == 0;

    // Clean two-tone premium gradient for the ring: flowing from sage to deep teal, or glowing emerald to mint
    final ringColors = isAllDone
        ? [L.green, const Color(0xFF00E676)]
        : [L.accent, Color.lerp(L.accent, Colors.teal, 0.355)!];

    final statusText = isEmpty
        ? 'Add a medicine to get started'
        : isAllDone
            ? '🎉 All doses complete'
            : '$remaining dose${remaining == 1 ? '' : 's'} remaining';



    // Adaptive streak badge styling (glow in dark mode, crisp in light mode)
    final streakBg = isDark
        ? const Color(0xFFFF9F0A).withValues(alpha: 0.08)
        : const Color(0xFFFFF3E0);
    final streakBorder = isDark
        ? const Color(0xFFFF9F0A).withValues(alpha: 0.25)
        : const Color(0xFFFFCC80).withValues(alpha: 0.6);
    final streakTextColor = isDark
        ? const Color(0xFFFF9F0A)
        : const Color(0xFFE65100);

    final trackColor = isDark
        ? L.accent.withValues(alpha: 0.08)
        : L.accent.withValues(alpha: 0.05);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
      decoration: BoxDecoration(
        color: L.card,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: L.border.withValues(alpha: 0.08),
          width: 1.2,
        ),
        boxShadow: AppShadows.neumorphic,
      ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Header row ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Left: title + subtitle
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAllDone ? 'All Done!' : 'Today',
                        style: AppTypography.headlineSmall.copyWith(
                          color: L.text,
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isAllDone
                            ? 'Perfect day ✨'
                            : '$takenCount of $total doses taken',
                        style: AppTypography.bodySmall.copyWith(
                          color: L.sub.withValues(alpha: 0.65),
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  // Right: 🔥 Streak badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: streakBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: streakBorder,
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🔥', style: TextStyle(fontSize: 16))
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .scaleXY(begin: 0.92, end: 1.08, duration: 900.ms, curve: Curves.easeInOutSine),
                        const SizedBox(width: 5),
                        Text(
                          '$streak',
                          style: AppTypography.titleMedium.copyWith(
                            color: streakTextColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'day${streak == 1 ? '' : 's'}',
                          style: AppTypography.bodySmall.copyWith(
                            color: streakTextColor.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w500,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // ── Ring ──
              _AnimatedRing(
                percent: dosePct,
                colors: ringColors,
                trackColor: trackColor,
                size: 220,
                strokeWidth: 18,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: dosePct * 100),
                      duration: const Duration(milliseconds: 1600),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) {
                        return Text(
                          '${value.round()}%',
                          style: AppTypography.displayXL.copyWith(
                            color: L.text,
                            height: 1.0,
                            fontWeight: FontWeight.w800,
                            fontSize: 52,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isEmpty ? 'No meds' : '$takenCount / $total',
                      style: AppTypography.labelMedium.copyWith(
                        color: L.sub.withValues(alpha: 0.55),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Status pill ──
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isAllDone
                      ? L.green.withValues(alpha: 0.10)
                      : L.fill.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isAllDone
                        ? L.green.withValues(alpha: 0.18)
                        : L.border.withValues(alpha: 0.5),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  statusText,
                  style: AppTypography.bodySmall.copyWith(
                    color: isAllDone ? L.green : L.sub.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
    );
  }
}



// ─────────────────────────────────────────────────────────────
// DAY TOGGLE — Cal AI style switcher
// ─────────────────────────────────────────────────────────────
class _DayToggle extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onChanged;

  const _DayToggle({required this.selectedDate, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final isToday = selectedDate.year == today.year &&
        selectedDate.month == today.month &&
        selectedDate.day == today.day;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: L.card.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: L.purple.withValues(alpha: 0.15),
          width: 1.0,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final halfWidth = constraints.maxWidth / 2;
          return Stack(
            children: [
              // ── Sliding active pill ──
              AnimatedPositioned(
                duration: 350.ms,
                curve: Curves.easeOutBack,
                top: 4,
                bottom: 4,
                left: isToday ? 4 : halfWidth,
                width: halfWidth - 4,
                child: Container(
                  decoration: BoxDecoration(
                    color: L.text,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: L.text.withValues(alpha: 0.12),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                ),
              ),
              // ── Labels ──
              Row(
                children: [
                  Expanded(
                    child: AnimatedPressable(
                      onTap: () {
                        HapticEngine.selection();
                        onChanged(today);
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: 250.ms,
                          style: AppTypography.labelLarge.copyWith(
                            color:
                                isToday ? L.bg : L.sub.withValues(alpha: 0.65),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.4,
                            fontSize: 13,
                          ),
                          child: const Text('Today'),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: AnimatedPressable(
                      onTap: () {
                        HapticEngine.selection();
                        onChanged(yesterday);
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: 250.ms,
                          style: AppTypography.labelLarge.copyWith(
                            color:
                                !isToday ? L.bg : L.sub.withValues(alpha: 0.65),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.4,
                            fontSize: 13,
                          ),
                          child: const Text('Yesterday'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms)
        .slideY(begin: -0.1, end: 0, curve: Curves.easeOutExpo);
  }
}


// ─────────────────────────────────────────────────────────────
// EMERGENCY WARNING CARD
// ─────────────────────────────────────────────────────────────
class _EmergencyWarningCard extends StatelessWidget {
  final Symptom symptom;
  const _EmergencyWarningCard({required this.symptom});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppGradients.dangerRed,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppShadows.glow(const Color(0xFF991B1B), intensity: 0.3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.white24,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emergency_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true))
               .scaleXY(begin: 1.0, end: 1.15, duration: 800.ms, curve: Curves.easeInOut),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'CRITICAL MEDICAL ADVISORY',
                  style: AppTypography.labelLarge.copyWith(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'You logged a severe symptom of ${symptom.name} (Severity: ${symptom.severity}/10) recently. If you are experiencing chest pain, difficulty breathing, sudden weakness, or any life-threatening symptoms, seek medical help immediately.',
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          AnimatedPressable(
            onTap: () async {
              HapticEngine.heavyImpact();
              final url = Uri.parse('tel:911');
              if (await canLaunchUrl(url)) {
                await launchUrl(url);
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.phone_in_talk_rounded, color: L.error, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'CALL EMERGENCY SERVICES (911)',
                    style: AppTypography.labelLarge.copyWith(
                      color: L.error,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// BADGE GALLERY — Horizontal scrolling badges based on streak
// ─────────────────────────────────────────────────────────────

class _InstantScanFAB extends StatefulWidget {
  final VoidCallback onScan;
  const _InstantScanFAB({required this.onScan});

  @override
  State<_InstantScanFAB> createState() => _InstantScanFABState();
}

class _InstantScanFABState extends State<_InstantScanFAB> with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.1, end: 0.4).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return AnimatedPressable(
      onTapDown: (_) {
        HapticEngine.selection();
        setState(() => _pressed = true);
      },
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onScan,
      child: AnimatedBuilder(
        animation: _glowAnim,
        builder: (context, child) => AnimatedScale(
          scale: _pressed ? 0.92 : 1.0,
          duration: 150.ms,
          curve: Curves.easeOutCubic,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [L.primary, L.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: L.primary.withValues(alpha: 0.3 + _glowAnim.value * 0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.camera_alt_rounded,
                  color: L.onPrimary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'AR Scan',
                  style: AppTypography.labelLarge.copyWith(
                    color: L.onPrimary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
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
