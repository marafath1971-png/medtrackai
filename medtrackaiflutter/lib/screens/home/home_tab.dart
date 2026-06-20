import 'dart:ui';
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
  final GlobalKey _medsHeaderKey = GlobalKey();
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
                colors: dosePct >= 1.0 
                    ? [L.green, L.accent, L.green, L.green] 
                    : dosePct > 0 
                        ? [L.accent, Colors.blue, L.accent, L.card] 
                        : [Colors.blue, L.card, L.bg, L.card],
              ),
            ),
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

                  if (doses.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
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

                            if (index >= groups.length) return null;
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
                          childCount: 4,
                        ),
                      ),
                    ),

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
                            .fadeIn(duration: 800.ms, delay: 300.ms)
                            .slideY(
                                begin: 0.08, end: 0, curve: Curves.easeOutExpo),
                      ),
                    ),

                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenPadding),
                    sliver: SliverToBoxAdapter(
                      child: Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: HomeMedsHeader(
                            key: _medsHeaderKey,
                            onAdd: widget.onScan,
                          )),
                    ),
                  ),
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
            child: const _AiQuickLogFAB(),
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
    return GestureDetector(
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
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: L.primary,
              borderRadius: BorderRadius.circular(24),
              boxShadow: L.shadowSoft,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 6),
                Text(
                  'Log Dose',
                  style: AppTypography.labelLarge.copyWith(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
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
    return GestureDetector(
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
          gradient: LinearGradient(
            colors: [
              gradColors[0].withValues(alpha: 0.12),
              gradColors[1].withValues(alpha: 0.04),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: gradColors[0].withValues(alpha: 0.3), width: 0.8),
          boxShadow: [
            BoxShadow(
              color: gradColors[0].withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradColors),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: gradColors[0].withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.share_rounded, size: 18, color: Colors.white),
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
                    // margin: const EdgeInsets.symmetric(horizontal: 4),
                    color: L.card,
                    showBorder: true,
                    borderWidth: 1.0,
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
// ANIMATED RING
// ─────────────────────────────────────────────────────────────
class _AnimatedRing extends StatefulWidget {
  final double percent;
  final Color color;
  final Color trackColor;
  final double size;
  final double strokeWidth;
  final Widget child;

  const _AnimatedRing({
    required this.percent,
    required this.color,
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
        vsync: this, duration: const Duration(milliseconds: 1400));
    _anim = Tween<double>(begin: 0, end: widget.percent)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutExpo));
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(_AnimatedRing old) {
    super.didUpdateWidget(old);
    if (old.percent != widget.percent) {
      _anim = Tween<double>(begin: _anim.value, end: widget.percent)
          .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutExpo));
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
              color: widget.color,
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
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  const _RingPainter({
    required this.percent,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    const startAngle = -1.5707963267948966;
    final sweepAngle = 6.283185307179586 * percent;

    // Background track
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
      // Soft outer glow
      canvas.drawArc(
        rect,
        startAngle,
        sweepAngle,
        false,
        Paint()
          ..color = color.withValues(alpha: 0.25)
          ..strokeWidth = strokeWidth + 8
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0),
      );
      // Sharp progress arc
      canvas.drawArc(
        rect,
        startAngle,
        sweepAngle,
        false,
        Paint()
          ..color = color
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.percent != percent || old.color != color;
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
    final isAllDone = total > 0 && dosePct >= 1.0;
    final isEmpty = total == 0;
    final primaryColor = isAllDone ? L.green : L.accent;
    final pct = (dosePct * 100).round();
    final level = (streak / 3).floor() + 1; // Example gamification

    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: L.card.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.15),
                blurRadius: 40,
                spreadRadius: -10,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LEVEL $level',
                        style: AppTypography.labelSmall.copyWith(
                          color: primaryColor,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isAllDone ? 'MAX AURA ✨' : 'IN PROGRESS 🔥',
                        style: AppTypography.titleLarge.copyWith(
                          color: L.text,
                          fontWeight: FontWeight.w600,
                          fontSize: 24,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: L.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: L.border, width: 0.5),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.local_fire_department_rounded, color: L.accent, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          '$streak',
                          style: AppTypography.titleMedium.copyWith(
                            color: L.text,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              // Liquid XP Bar
              Row(
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        Container(
                          height: 18,
                          decoration: BoxDecoration(
                            color: L.fill,
                            borderRadius: BorderRadius.circular(9),
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 1200),
                          curve: Curves.easeOutExpo,
                          height: 18,
                          width: MediaQuery.of(context).size.width * 0.7 * dosePct,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [primaryColor.withValues(alpha: 0.7), primaryColor],
                            ),
                            borderRadius: BorderRadius.circular(9),
                            boxShadow: [
                              BoxShadow(color: primaryColor.withValues(alpha: 0.5), blurRadius: 12),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '$pct%',
                    style: AppTypography.titleMedium.copyWith(
                      color: L.text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Status Text
              Text(
                isEmpty
                    ? 'Scan a medicine to gain XP'
                    : isAllDone
                        ? 'All quests completed! +100 XP'
                        : '$remaining quests remaining today',
                style: AppTypography.bodySmall.copyWith(
                  color: L.sub,
                  fontWeight: FontWeight.w600,
                ),
              ),
              
              const SizedBox(height: 24),
              // Bento Stats
              Row(
                children: [
                  _XPStatBox(title: 'Taken', value: '$takenCount', color: L.sub),
                  const SizedBox(width: 12),
                  _XPStatBox(title: 'Total', value: '$total', color: L.sub),
                  const SizedBox(width: 12),
                  _XPStatBox(title: 'Next Lvl', value: '${3 - (streak % 3)} days', color: primaryColor),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _XPStatBox extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _XPStatBox({required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.L.fill.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.toUpperCase(),
              style: AppTypography.labelSmall.copyWith(
                color: context.L.sub.withValues(alpha: 0.6),
                fontWeight: FontWeight.w500,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: AppTypography.titleMedium.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
          ],
        ),
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
        color: L.fill.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: L.border.withValues(alpha: 0.08), width: 0.8),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final halfWidth = constraints.maxWidth / 2;
          return Stack(
            children: [
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
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
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
                                isToday ? L.bg : L.text.withValues(alpha: 0.6),
                            fontWeight:
                                isToday ? FontWeight.w600 : FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                          child: const Text('Today'),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
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
                                !isToday ? L.bg : L.text.withValues(alpha: 0.6),
                            fontWeight:
                                !isToday ? FontWeight.w600 : FontWeight.w600,
                            letterSpacing: 0.5,
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
          GestureDetector(
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
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
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

