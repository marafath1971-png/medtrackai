import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../theme/med_ai_ui.dart';
import '../../../widgets/common/animated_pressable.dart';
import '../../../services/share_service.dart';
import '../../../core/utils/haptic_engine.dart';
import '../../../providers/app_state.dart';
import 'package:confetti/confetti.dart';

class StreakModal extends StatefulWidget {
  final int streak;
  final Map<String, List<DoseEntry>> history;
  final StreakData streakData;
  final VoidCallback onClose;
  final VoidCallback onFreeze;
  final int freezes;

  const StreakModal(
      {super.key,
      required this.streak,
      required this.history,
      required this.streakData,
      required this.onClose,
      required this.onFreeze,
      this.freezes = 0});

  @override
  State<StreakModal> createState() => _StreakModalState();

  static void show(BuildContext context, AppState state) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'StreakModal',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (ctx, anim1, anim2) => StreakModal(
        streak: state.getStreak(),
        history: state.history,
        streakData: state.streakData,
        onClose: () => Navigator.of(ctx).pop(),
        onFreeze: () => state.useStreakFreeze(),
        freezes: state.profile?.streakFreezes ?? 0,
      ),
      transitionBuilder: (ctx, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: SlideTransition(
            position: Tween<Offset>(
                    begin: const Offset(0, 0.1), end: Offset.zero)
                .animate(
                    CurvedAnimation(parent: anim1, curve: Curves.easeOutQuart)),
            child: child,
          ),
        );
      },
    );
  }
}

class _StreakModalState extends State<StreakModal> {
  late final ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
    if (widget.streak >= 3 && !MedAiA11y.reducedMotion(context)) {
      _confettiController.play();
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  String _getStreakTitle(int streak) {
    if (streak >= 365) return 'Unbreakable';
    if (streak >= 100) return '100-Day Legend';
    if (streak >= 30) return 'Iron Will';
    if (streak >= 7) return 'Consistency King';
    if (streak >= 3) return 'Rising Star';
    return 'Getting Started';
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final reduceMotion = MedAiA11y.reducedMotion(context);
    final size = MediaQuery.of(context).size;

    final allKeys = widget.history.keys.toList()..sort();
    final totalDaysTracked = allKeys.length;
    final allEntries = widget.history.values.expand((e) => e).toList();
    final totalTaken = allEntries.where((e) => e.taken).length;
    final totalDoses = allEntries.length;
    final overallAdh = totalDoses > 0 ? (totalTaken * 100 ~/ totalDoses) : 0;

    int best = 0, cur = 0;
    String? prev;
    for (final k in allKeys) {
      final ds = widget.history[k] ?? [];
      final rate =
          ds.isEmpty ? 0.0 : ds.where((x) => x.taken).length / ds.length;
      if (rate >= 0.8) {
        if (prev != null) {
          final diff =
              DateTime.parse(k).difference(DateTime.parse(prev)).inDays;
          cur = diff <= 1 ? cur + 1 : 1;
        } else {
          cur = 1;
        }
        if (cur > best) best = cur;
      } else {
        cur = 0;
      }
      prev = k;
    }

    final milestones = [
      {'d': 3, 'e': '🛡️', 'l': '3 Days', 'desc': 'Foundation established.'},
      {'d': 7, 'e': '⚡', 'l': '1 Week', 'desc': 'Biological rhythm sync.'},
      {'d': 14, 'e': '⚔️', 'l': '2 Weeks', 'desc': 'Efficacy optimization.'},
      {'d': 30, 'e': '🏆', 'l': '1 Month', 'desc': 'Therapeutic mastery.'},
      {'d': 60, 'e': '💎', 'l': '60 Days', 'desc': 'Unbreakable habit.'},
      {'d': 100, 'e': '👑', 'l': '100 Days', 'desc': 'Peak performance.'},
      {'d': 365, 'e': '🪐', 'l': '1 Year', 'desc': 'Legendary consistency.'},
    ];

    return Stack(
      children: [
        AnimatedPressable(
          onTap: widget.onClose,
          child: Container(
            color: Colors.black.withValues(alpha: 0.7),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: GestureDetector(
                  onTap: () {},
                  child: Container(
                    width: size.width,
                    constraints: BoxConstraints(
                      maxHeight: size.height * 0.92,
                      maxWidth: 450,
                    ),
                    decoration: BoxDecoration(
                      color: L.bg,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(32)),
                      border: Border.all(
                          color: L.border.withValues(alpha: 0.1), width: 0.5),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 12),
                          Center(
                            child: Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: L.text.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          _buildHeader(L),
                          Flexible(
                            child: RawScrollbar(
                              thumbColor: L.text.withValues(alpha: 0.1),
                              radius: const Radius.circular(10),
                              thickness: 4,
                              child: SingleChildScrollView(
                                keyboardDismissBehavior:
                                    ScrollViewKeyboardDismissBehavior.onDrag,
                                physics: const ClampingScrollPhysics(),
                                padding:
                                    const EdgeInsets.fromLTRB(24, 8, 24, 120),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildHeroMetric(
                                        L, widget.streak, best, overallAdh),
                                    const SizedBox(height: 24),
                                    _buildStatsGrid(
                                        L, totalDaysTracked, totalTaken, totalDoses),
                                    const SizedBox(height: 32),
                                    _buildSectionTitle(L, 'Last 30 Days'),
                                    const SizedBox(height: 16),
                                    _Heatmap(history: widget.history, L: L),
                                    const SizedBox(height: 40),
                                    _buildSectionTitle(L, 'Milestones'),
                                    const SizedBox(height: 20),
                                    _AscensionTrack(
                                      milestones: milestones,
                                      currentStreak: widget.streak,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          _buildFooterActions(L, widget.streak),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (widget.streak >= 3 && !reduceMotion)
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              maxBlastForce: 12,
              minBlastForce: 4,
              emissionFrequency: 0.04,
              numberOfParticles: 24,
              gravity: 0.08,
              colors: [
                L.primary.withValues(alpha: 0.6),
                L.secondary.withValues(alpha: 0.4),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildHeader(AppThemeColors L) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your streak',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  color: L.text,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _getStreakTitle(widget.streak),
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: L.sub,
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: widget.onClose,
            icon: Icon(Icons.close_rounded, color: L.text, size: 24),
            style: IconButton.styleFrom(
              minimumSize: const Size(MedAiA11y.minTapTarget, MedAiA11y.minTapTarget),
              backgroundColor: L.fill.withValues(alpha: 0.5),
              padding: const EdgeInsets.all(8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroMetric(
      AppThemeColors L, int streak, int best, int adherence) {
    final reduceMotion = MedAiA11y.reducedMotion(context);
    Widget card = MedAiDepthCard(
      accentGlow: true,
      padding: const EdgeInsets.all(AppSpacing.p24),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current streak',
                  style: AppTypography.labelSmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: L.sub,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$streak',
                      style: AppTypography.displayLarge.copyWith(
                        fontWeight: FontWeight.w800,
                        color: L.text,
                        fontSize: 64,
                        letterSpacing: -2,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'days',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: L.sub,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 56,
            color: L.border.withValues(alpha: 0.15),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _MiniHeroStat(label: 'Best', val: '$best', L: L),
              const SizedBox(height: 12),
              _MiniHeroStat(label: 'Adherence', val: '$adherence%', L: L),
            ],
          ),
        ],
      ),
    );
    if (reduceMotion) return card;
    return card.animate().fadeIn(duration: AppDurations.fast);
  }

  Widget _buildStatsGrid(
      AppThemeColors L, int tracked, int taken, int logged) {
    return Row(
      children: [
        Expanded(
            child: _StatBox(
                label: 'Days tracked', val: '$tracked', emoji: '📅', L: L)),
        const SizedBox(width: 12),
        Expanded(
            child: _StatBox(
                label: 'Doses taken', val: '$taken', emoji: '✓', L: L)),
        const SizedBox(width: 12),
        Expanded(
            child: _StatBox(
                label: 'Total logged', val: '$logged', emoji: '📊', L: L)),
      ],
    );
  }

  Widget _buildSectionTitle(AppThemeColors L, String title) {
    return Row(
      children: [
        Text(
          title,
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            color: L.text,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Divider(color: L.border.withValues(alpha: 0.1))),
      ],
    );
  }

  Widget _buildFooterActions(AppThemeColors L, int streak) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: L.bg,
        border: Border(top: BorderSide(color: L.border.withValues(alpha: 0.1))),
      ),
      child: Column(
        children: [
          // Loss-aversion mechanic (Duolingo/Cal AI): show freezes the user has
          // banked and let them spend one to protect the streak. Only shown when
          // they actually have freezes — otherwise it's just noise.
          if (widget.freezes > 0) ...[
            Semantics(
              button: true,
              label: 'Use a streak freeze, ${widget.freezes} available',
              child: MedAiCTA(
                label: 'Use freeze to protect streak (${widget.freezes})',
                icon: Icons.ac_unit_rounded,
                onTap: () {
                  HapticEngine.success();
                  widget.onFreeze();
                  widget.onClose();
                },
              ),
            ),
            const SizedBox(height: 10),
          ],
          MedAiCTA(
            label: 'Share streak',
            icon: Icons.ios_share_rounded,
            secondary: true,
            onTap: () {
              HapticEngine.selection();
              ShareService.shareStreak(streak);
            },
          ),
        ],
      ),
    );
  }
}

class _MiniHeroStat extends StatelessWidget {
  final String label, val;
  final AppThemeColors L;
  const _MiniHeroStat(
      {required this.label, required this.val, required this.L});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          val,
          style: AppTypography.titleLarge.copyWith(
            fontWeight: FontWeight.w800,
            color: L.text,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            fontWeight: FontWeight.w600,
            color: L.sub,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label, val;
  final String emoji;
  final AppThemeColors L;
  const _StatBox(
      {required this.label, required this.val, required this.emoji, required this.L});

  @override
  Widget build(BuildContext context) {
    return MedAiDepthCard(
      padding: const EdgeInsets.all(AppSpacing.p16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 10),
          Text(
            val,
            style: AppTypography.titleLarge.copyWith(
              fontWeight: FontWeight.w800,
              color: L.text,
              fontSize: 22,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: L.sub,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _Heatmap extends StatelessWidget {
  final Map<String, List<DoseEntry>> history;
  final AppThemeColors L;
  const _Heatmap({required this.history, required this.L});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    return GridView.builder(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: 28,
      itemBuilder: (c, i) {
        final d = today.subtract(Duration(days: 27 - i));
        final k = d.toIso8601String().substring(0, 10);
        final ds = history[k] ?? [];
        final rate =
            ds.isEmpty ? -1.0 : ds.where((e) => e.taken).length / ds.length;

        Color bg;
        if (rate < 0) {
          bg = L.fill.withValues(alpha: 0.5);
        } else if (rate >= 0.8) {
          bg = L.primary.withValues(alpha: 0.85);
        } else if (rate > 0) {
          bg = L.primary.withValues(alpha: 0.3);
        } else {
          bg = L.error.withValues(alpha: 0.15);
        }

        return Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
          child: Center(
            child: Text(
              '${d.day}',
              style: AppTypography.labelSmall.copyWith(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: rate >= 0.8 ? Colors.white : L.text.withValues(alpha: 0.5),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AscensionTrack extends StatelessWidget {
  final List<Map<String, dynamic>> milestones;
  final int currentStreak;

  const _AscensionTrack(
      {required this.milestones, required this.currentStreak});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return ListView.builder(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: milestones.length,
      itemBuilder: (context, index) {
        final m = milestones[index];
        final target = m['d'] as int;
        final achieved = currentStreak >= target;
        final isNext = currentStreak < target &&
            (index == 0 ||
                currentStreak >= (milestones[index - 1]['d'] as int));

        return IntrinsicHeight(
          child: Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: achieved ? L.primary : L.fill,
                      shape: BoxShape.circle,
                      border: isNext
                          ? Border.all(color: L.primary, width: 2)
                          : null,
                    ),
                    child: Center(
                      child: achieved
                          ? const Icon(Icons.check_rounded,
                              color: Colors.white, size: 16)
                          : Text(
                              m['e'] as String,
                              style: const TextStyle(fontSize: 14),
                            ),
                    ),
                  ),
                  if (index < milestones.length - 1)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: achieved ? L.primary : L.fill,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            m['l'] as String,
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: achieved || isNext ? L.text : L.sub,
                            ),
                          ),
                          if (isNext)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: L.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Next',
                                style: AppTypography.labelSmall.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                  color: L.primary,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        achieved ? 'Unlocked' : m['desc'] as String,
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                          color: achieved
                              ? L.sub
                              : L.sub.withValues(alpha: 0.8),
                        ),
                      ),
                      if (!achieved && isNext) ...[
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: currentStreak / target,
                            minHeight: 4,
                            backgroundColor: L.fill,
                            color: L.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${target - currentStreak} days remaining',
                          style: AppTypography.labelSmall.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: L.sub,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
