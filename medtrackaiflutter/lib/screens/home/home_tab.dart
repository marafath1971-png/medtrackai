import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/haptic_engine.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../dashboard/widgets/lime_progress_hero.dart';
import '../dashboard/widgets/ref_bento_tile.dart';
import '../medicine/medicine_detail_screen.dart';
import 'dose_grouping.dart';
import 'widgets/emergency_warning_card.dart';
import 'widgets/home_dose_group.dart';
import 'widgets/home_header.dart';
import 'widgets/home_schedule_empty.dart';
import 'widgets/home_week_strip.dart';
import 'widgets/settings_modal_new.dart';
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

  static const _hPad = AppSpacing.screenPadding;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
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

  Widget _buildMain(
    BuildContext context,
    AppThemeColors L,
    List<DoseItem> doses,
    int streak,
    Map<String, bool> takenMap,
    List<Medicine> meds,
    int takenCount,
    double adherence,
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
    final adherencePct = (adherence * 100).round();

    return Scaffold(
      backgroundColor: L.bg,
      body: Stack(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: L.bg,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: const Alignment(0, 0.35),
                colors: [
                  AppColors.lime.withValues(alpha: 0.12),
                  L.bg,
                ],
              ),
            ),
            child: RefreshIndicator(
              onRefresh: () async {
                HapticEngine.selection();
                await context.read<AppState>().loadFromStorage();
              },
              color: AppColors.limeDeep,
              backgroundColor: L.card,
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
                        onOpenStreak: () =>
                            setState(() => _showStreak = true),
                        onOpenSettings: () =>
                            setState(() => _showSettings = true),
                      ),
                    ),

                    if (severeSymptoms.isNotEmpty)
                      SliverPadding(
                        padding:
                            const EdgeInsets.fromLTRB(_hPad, 0, _hPad, 12),
                        sliver: SliverToBoxAdapter(
                          child: EmergencyWarningCard(
                              symptom: severeSymptoms.first),
                        ),
                      ),

                    SliverPadding(
                      padding:
                          const EdgeInsets.fromLTRB(_hPad, 6, _hPad, 14),
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
                          const EdgeInsets.fromLTRB(_hPad, 0, _hPad, 18),
                      sliver: SliverToBoxAdapter(
                        child: Row(
                          children: [
                            Expanded(
                              child: RefBentoTile(
                                label: 'Adherence',
                                value: '$adherencePct',
                                unit: '%',
                                emoji: '📈',
                                tint: AppColors.pastelMint,
                                onTap: widget.onSwitchTab != null
                                    ? () => widget.onSwitchTab!(1)
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: RefBentoTile(
                                label: 'Doses left',
                                value: '$dosesLeft',
                                unit: dosesLeft == 1 ? 'dose' : 'doses',
                                emoji: '💊',
                                tint: AppColors.pastelSky,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SliverPadding(
                      padding:
                          const EdgeInsets.fromLTRB(_hPad, 0, _hPad, 20),
                      sliver: SliverToBoxAdapter(
                        child: HomeWeekStrip(
                          selectedDate: _selectedDate,
                          onChanged: _setDate,
                        ),
                      ),
                    ),

                    if (doses.isEmpty)
                      SliverPadding(
                        padding:
                            const EdgeInsets.fromLTRB(_hPad, 0, _hPad, 24),
                        sliver: SliverToBoxAdapter(
                          child: HomeScheduleEmpty(
                            hasMeds: meds.isNotEmpty,
                            onAdd: widget.onScan,
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding:
                            const EdgeInsets.fromLTRB(_hPad, 0, _hPad, 24),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final group = groups[index];
                              return HomeDoseGroup(
                                title: group.title,
                                doses: group.items,
                                takenToday: takenMap,
                                state: context.read<AppState>(),
                                selectedDate: _selectedDate,
                                onView: (med) => _viewMed(med),
                              );
                            },
                            childCount: groups.length,
                          ),
                        ),
                      ),

                    const SliverToBoxAdapter(child: SizedBox(height: 120)),
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
    final doses = context.select<AppState, List<DoseItem>>(
        (s) => s.getDoses(date: _selectedDate));
    final streak = context.select<AppState, int>((s) => s.getStreak());
    final takenMap = context.select<AppState, Map<String, bool>>(
        (s) => s.getTakenMapForDate(_selectedDate));
    final meds = context.select<AppState, List<Medicine>>((s) => s.meds);
    final adherence =
        context.select<AppState, double>((s) => s.getAdherenceScore());

    final takenCount = doses.where((d) => takenMap[d.key] == true).length;
    final L = context.L;

    final mainContent = _buildMain(context, L, doses, streak, takenMap, meds,
        takenCount, adherence);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
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
      duration: const Duration(milliseconds: 280),
      child: visible
          ? SizedBox.expand(key: ValueKey(key), child: child)
          : const SizedBox.shrink(),
    );
  }
}
