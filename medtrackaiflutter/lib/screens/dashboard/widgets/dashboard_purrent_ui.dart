import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../../core/utils/haptic_engine.dart';
import '../../../providers/app_state.dart';
import '../../../theme/med_ai_ui.dart';
import '../../../widgets/common/animated_pressable.dart';
import '../../../widgets/common/premium_empty_state.dart';

// ─── Top bar + greeting (Purrent + finance reference blend) ─────────────────

class DashboardPurrentTopBar extends StatelessWidget {
  final VoidCallback onMenu;
  final VoidCallback onDailyLog;

  const DashboardPurrentTopBar({
    super.key,
    required this.onMenu,
    required this.onDailyLog,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final s = AppLocalizations.of(context);
    final appState = context.watch<AppState>();
    final name = (appState.activeProfile?.name ?? appState.profile?.name)?.trim();
    final display = (name != null && name.isNotEmpty) ? name.split(' ').first : 'there';
    final showAlertDot =
        appState.unseenAlertsCount > 0 || appState.getLowStockCount() > 0;

    return Padding(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.p12, AppSpacing.gutter, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'MedAI',
                  style: AppTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: L.text,
                    letterSpacing: -0.3,
                  ),
                ),
                const Spacer(),
                _MenuPill(label: 'Menu', onTap: onMenu),
              ],
            ),
            const SizedBox(height: AppSpacing.p16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hi, $display',
                        style: AppTypography.headlineMedium.copyWith(
                          fontWeight: FontWeight.w800,
                          color: L.text,
                          letterSpacing: -0.6,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.p4),
                      Text(
                        'Welcome back!',
                        style: AppTypography.bodyMedium.copyWith(
                          color: L.sub,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Semantics(
                  button: true,
                  label: showAlertDot
                      ? 'Open daily log, alerts pending'
                      : 'Open daily log',
                  child: AnimatedPressable(
                    onTap: () {
                      HapticEngine.selection();
                      onDailyLog();
                    },
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: L.card,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: L.border.withValues(alpha: 0.35),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            Icons.notifications_none_rounded,
                            size: 22,
                            color: L.text.withValues(alpha: 0.9),
                          ),
                          if (showAlertDot)
                            PositionedDirectional(
                              top: 9,
                              end: 9,
                              child: ExcludeSemantics(
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: AppColors.red,
                                    shape: BoxShape.circle,
                                    border:
                                        Border.all(color: L.card, width: 1.5),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.p8),
            Text(
              s?.dashboardTab ?? 'Trends',
              style: AppTypography.displaySmall.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 36,
                color: L.text,
                letterSpacing: -1,
                height: 1.05,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuPill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _MenuPill({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Semantics(
      button: true,
      label: label,
      child: AnimatedPressable(
        onTap: () {
          HapticEngine.selection();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p12, vertical: AppSpacing.p8),
          decoration: BoxDecoration(
            color: L.card,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: L.border.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Icon(Icons.grid_view_rounded, size: 16, color: L.text),
              const SizedBox(width: AppSpacing.p8),
              Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: L.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── 3-metric row (streak · doses · daily avg) — Cal AI neutral cards ────────

class DashboardPurrentMetricGrid extends StatelessWidget {
  final int streak;
  final int dosesWeek;
  /// Last 7 day dose counts (oldest → newest). Used for honest sparklines.
  final List<int> weeklyDoseCounts;
  /// Last 7 day adherence 0–1 (oldest → newest).
  final List<double> weeklyAdherence;

  const DashboardPurrentMetricGrid({
    super.key,
    required this.streak,
    required this.dosesWeek,
    this.weeklyDoseCounts = const [],
    this.weeklyAdherence = const [],
  });

  static List<double> _normalizeCounts(List<int> counts) {
    if (counts.isEmpty) return const [0, 0, 0, 0, 0, 0, 0];
    final max = counts.fold<int>(0, (a, b) => a > b ? a : b);
    if (max <= 0) return List<double>.filled(counts.length, 0);
    return counts.map((c) => (c / max).clamp(0.0, 1.0)).toList();
  }

  static List<double> _runningAvgSpark(List<int> counts) {
    if (counts.isEmpty) return const [0, 0, 0, 0, 0, 0, 0];
    final avgs = <double>[];
    var sum = 0;
    for (var i = 0; i < counts.length; i++) {
      sum += counts[i];
      avgs.add(sum / (i + 1));
    }
    final max = avgs.fold<double>(0, (a, b) => a > b ? a : b);
    if (max <= 0) return List<double>.filled(avgs.length, 0);
    return avgs.map((v) => (v / max).clamp(0.0, 1.0)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final avgDaily = dosesWeek > 0 ? (dosesWeek / 7).toStringAsFixed(1) : '0';
    final adherenceSpark = weeklyAdherence.isNotEmpty
        ? weeklyAdherence.map((v) => v.clamp(0.0, 1.0)).toList()
        : _normalizeCounts(weeklyDoseCounts);
    final doseSpark = _normalizeCounts(weeklyDoseCounts);
    final avgSpark = _runningAvgSpark(weeklyDoseCounts);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter, AppSpacing.p16, AppSpacing.gutter, 0),
      child: Row(
        children: [
          Expanded(
            child: _PurrentMetricCard(
              title: 'Day streak',
              value: '$streak',
              subtitle: streak == 1 ? 'day' : 'days',
              accent: AppColors.limeDeep,
              icon: Icons.local_fire_department_rounded,
              sparkline: adherenceSpark,
              trend: streak > 0 ? '↑ active' : null,
            ),
          ),
          const SizedBox(width: AppSpacing.p12),
          Expanded(
            child: _PurrentMetricCard(
              title: 'Doses logged',
              value: '$dosesWeek',
              subtitle: 'this week',
              accent: AppColors.infoSoft,
              icon: Icons.medication_rounded,
              sparkline: doseSpark,
            ),
          ),
          const SizedBox(width: AppSpacing.p12),
          Expanded(
            child: _PurrentMetricCard(
              title: 'Daily avg',
              value: avgDaily,
              subtitle: 'per day',
              accent: AppColors.warningSoft,
              icon: Icons.show_chart_rounded,
              sparkline: avgSpark,
            ),
          ),
        ],
      ),
    );
  }
}

class _PurrentMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color accent;
  final IconData icon;
  final List<double> sparkline;
  final String? trend;

  const _PurrentMetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.accent,
    required this.icon,
    required this.sparkline,
    this.trend,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Container(
      constraints: const BoxConstraints(minHeight: 132),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.p16,
        AppSpacing.p16,
        AppSpacing.p16,
        AppSpacing.p12,
      ),
      decoration: BoxDecoration(
        color: L.card,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: L.border.withValues(alpha: 0.22)),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelMedium.copyWith(
                    color: L.sub,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.badgeFill(accent),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, size: 18, color: accent),
              ),
            ],
          ),
          if (trend != null) ...[
            const SizedBox(height: AppSpacing.p4),
            Text(
              trend!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(
                color: accent,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.p12),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.headlineLarge.copyWith(
              fontWeight: FontWeight.w800,
              color: L.text,
              letterSpacing: -0.8,
              height: 1,
            ),
          ),
          const SizedBox(height: AppSpacing.p4),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.labelSmall.copyWith(
              color: L.sub,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.p8),
          ExcludeSemantics(
            child: SizedBox(
              height: AppSpacing.p24,
              child: CustomPaint(
                painter: _SparklinePainter(
                  points: sparkline,
                  color: accent.withValues(alpha: 0.85),
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> points;
  final Color color;

  _SparklinePainter({required this.points, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final x = size.width * (i / (points.length - 1));
      final y = size.height * (1 - points[i].clamp(0.0, 1.0));
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) =>
      old.points != points || old.color != color;
}

// ─── Medication diary (segmented + timeline) ──────────────────────────────────

enum DashboardDiaryRange { today, yesterday, week, month }

class DashboardMedicationDiary extends StatefulWidget {
  final Map<String, List<DoseEntry>> history;
  final List<Medicine> meds;

  const DashboardMedicationDiary({
    super.key,
    required this.history,
    required this.meds,
  });

  @override
  State<DashboardMedicationDiary> createState() =>
      _DashboardMedicationDiaryState();
}

class _DashboardMedicationDiaryState extends State<DashboardMedicationDiary> {
  DashboardDiaryRange _range = DashboardDiaryRange.today;

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final items = _buildItems();

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.gutter, AppSpacing.gutter, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Medication diary",
            style: AppTypography.titleLarge.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: L.text,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: AppSpacing.p16),
          _DiarySegmentBar(
            selected: _range,
            onChanged: (r) => setState(() => _range = r),
          ),
          const SizedBox(height: AppSpacing.p16),
          if (items.isEmpty)
            PremiumEmptyState(
              compact: true,
              title: 'No doses logged',
              subtitle: 'Nothing recorded for this period yet.',
              mascotFeature: 'missed',
              icon: Icons.event_note_rounded,
            )
          else
            ...items.map((item) => _DiaryRow(item: item)),
        ],
      ),
    );
  }

  List<_DiaryItem> _buildItems() {
    final now = DateTime.now();
    final keys = <String>[];

    switch (_range) {
      case DashboardDiaryRange.today:
        keys.add(_dateKey(now));
      case DashboardDiaryRange.yesterday:
        keys.add(_dateKey(now.subtract(const Duration(days: 1))));
      case DashboardDiaryRange.week:
        for (var i = 0; i < 7; i++) {
          keys.add(_dateKey(now.subtract(Duration(days: i))));
        }
      case DashboardDiaryRange.month:
        for (var i = 0; i < 30; i++) {
          keys.add(_dateKey(now.subtract(Duration(days: i))));
        }
    }

    final items = <_DiaryItem>[];
    for (final key in keys) {
      final entries = widget.history[key] ?? [];
      for (final entry in entries) {
        if (!entry.taken) continue;
        final med = widget.meds.where((m) => m.id == entry.medId).firstOrNull;
        final takenAt = entry.takenAt != null
            ? DateTime.tryParse(entry.takenAt!)
            : null;
        final when = takenAt ?? DateTime.tryParse(key) ?? now;
        items.add(
          _DiaryItem(
            title: med?.name ?? entry.label,
            detail: entry.label,
            when: when,
            tint: AppColors.infoSoft,
          ),
        );
      }
    }

    items.sort((a, b) => b.when.compareTo(a.when));
    return items.take(12).toList();
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class _DiaryItem {
  final String title;
  final String detail;
  final DateTime when;
  final Color tint;

  _DiaryItem({
    required this.title,
    required this.detail,
    required this.when,
    required this.tint,
  });
}

class _DiarySegmentBar extends StatelessWidget {
  final DashboardDiaryRange selected;
  final ValueChanged<DashboardDiaryRange> onChanged;

  const _DiarySegmentBar({
    required this.selected,
    required this.onChanged,
  });

  static const _labels = {
    DashboardDiaryRange.today: 'Today',
    DashboardDiaryRange.yesterday: 'Yesterday',
    DashboardDiaryRange.week: 'Week',
    DashboardDiaryRange.month: 'Month',
  };

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final reduceMotion = MedAiA11y.reducedMotion(context);
    final chipDuration =
        MedAiA11y.motion(context, const Duration(milliseconds: 220));
    return Container(
      padding: const EdgeInsets.all(AppSpacing.p4),
      decoration: BoxDecoration(
        color: L.fill.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: DashboardDiaryRange.values.map((range) {
          final isSel = range == selected;
          return Expanded(
            child: Semantics(
              button: true,
              selected: isSel,
              label: _labels[range]!,
              child: GestureDetector(
                onTap: () {
                  HapticEngine.selection();
                  onChanged(range);
                },
                child: AnimatedContainer(
                  duration: chipDuration,
                  curve: reduceMotion ? Curves.linear : Curves.easeOut,
                  padding:
                      const EdgeInsets.symmetric(vertical: AppSpacing.p12),
                  decoration: BoxDecoration(
                    color: isSel ? L.card : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: isSel
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    _labels[range]!,
                    textAlign: TextAlign.center,
                    style: AppTypography.labelSmall.copyWith(
                      fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                      color: isSel ? L.text : L.sub,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _DiaryRow extends StatelessWidget {
  final _DiaryItem item;

  const _DiaryRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final rel = _relativeTime(item.when);
    final clock = DateFormat('hh:mm a').format(item.when);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.p16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              rel,
              style: AppTypography.labelSmall.copyWith(
                color: L.sub,
                fontWeight: FontWeight.w600,
                fontSize: 11,
                height: 1.3,
              ),
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.badgeFill(item.tint),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.medication_liquid_rounded,
              size: 18,
              color: item.tint,
            ),
          ),
          const SizedBox(width: AppSpacing.p12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: L.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.detail,
                  style: AppTypography.labelMedium.copyWith(
                    color: L.sub,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Text(
            clock,
            style: AppTypography.labelSmall.copyWith(
              color: L.sub,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _relativeTime(DateTime when) {
    final diff = DateTime.now().difference(when);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours}h ${diff.inMinutes % 60}min ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays} days ago';
  }
}
