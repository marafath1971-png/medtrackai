import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../../core/utils/haptic_engine.dart';
import '../../../providers/app_state.dart';
import '../../../theme/med_ai_ui.dart';
import '../../../widgets/common/animated_pressable.dart';

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

    return Padding(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 10, 22, 0),
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
            const SizedBox(height: 18),
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
                          fontSize: 26,
                          color: L.text,
                          letterSpacing: -0.6,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 4),
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
                  label: 'Open daily log',
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
                          Positioned(
                            top: 9,
                            right: 9,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: AppColors.red,
                                shape: BoxShape.circle,
                                border: Border.all(color: L.card, width: 1.5),
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
            const SizedBox(height: 6),
            Text(
              s?.dashboardTab ?? 'Trends',
              style: AppTypography.displaySmall.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 34,
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: L.card,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: L.border.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Icon(Icons.grid_view_rounded, size: 16, color: L.text),
              const SizedBox(width: 6),
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

// ─── 3-metric row (streak · doses · daily avg) ───────────────────────────────

class DashboardPurrentMetricGrid extends StatelessWidget {
  final int streak;
  final int dosesWeek;

  const DashboardPurrentMetricGrid({
    super.key,
    required this.streak,
    required this.dosesWeek,
  });

  @override
  Widget build(BuildContext context) {
    final avgDaily = dosesWeek > 0 ? (dosesWeek / 7).toStringAsFixed(1) : '0';

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
      child: Row(
        children: [
          Expanded(
            child: _PurrentMetricCard(
              title: 'Day streak',
              value: '$streak',
              subtitle: streak == 1 ? 'day' : 'days',
              colors: const [Color(0xFFC9EFA0), Color(0xFF8FD14F)],
              pattern: _PatternType.dots,
              sparkline: const [0.2, 0.35, 0.4, 0.55, 0.5, 0.72, 0.8],
              trend: streak > 0 ? '↑ active' : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _PurrentMetricCard(
              title: 'Doses logged',
              value: '$dosesWeek',
              subtitle: 'this week',
              colors: const [Color(0xFF9CA5FF), Color(0xFFB8B0FF)],
              pattern: _PatternType.waves,
              sparkline: const [0.3, 0.45, 0.5, 0.6, 0.55, 0.7, 0.65],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _PurrentMetricCard(
              title: 'Daily avg',
              value: avgDaily,
              subtitle: 'per day',
              colors: const [Color(0xFFFFE08A), Color(0xFFFFC857)],
              pattern: _PatternType.curves,
              sparkline: const [0.55, 0.62, 0.58, 0.72, 0.68, 0.8, 0.87],
            ),
          ),
        ],
      ),
    );
  }
}

enum _PatternType { waves, curves, dots, rings }

class _PurrentMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final List<Color> colors;
  final _PatternType pattern;
  final List<double> sparkline;
  final String? trend;

  const _PurrentMetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.colors,
    required this.pattern,
    required this.sparkline,
    this.trend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 148,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.last.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _CardPatternPainter(pattern: pattern),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.inkStrong.withValues(alpha: 0.75),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (trend != null)
                    Text(
                      trend!,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.inkStrong.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
              const Spacer(),
              Text(
                value,
                style: AppTypography.headlineMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 28,
                  color: AppColors.inkStrong,
                  letterSpacing: -0.8,
                  height: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.inkStrong.withValues(alpha: 0.65),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 28,
                child: CustomPaint(
                  painter: _SparklinePainter(
                    points: sparkline,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardPatternPainter extends CustomPainter {
  final _PatternType pattern;

  _CardPatternPainter({required this.pattern});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    switch (pattern) {
      case _PatternType.waves:
        final path = Path();
        for (var y = size.height * 0.55; y < size.height; y += 14) {
          path.moveTo(0, y);
          for (var x = 0.0; x <= size.width; x += 8) {
            path.lineTo(x, y + math.sin(x / 18) * 4);
          }
        }
        canvas.drawPath(path, paint);
      case _PatternType.curves:
        canvas.drawArc(
          Rect.fromLTWH(-20, size.height * 0.35, size.width * 0.9, 80),
          0,
          math.pi,
          false,
          paint,
        );
      case _PatternType.dots:
        for (var x = 8.0; x < size.width; x += 12) {
          for (var y = size.height * 0.45; y < size.height; y += 12) {
            canvas.drawCircle(Offset(x, y), 1.2, paint..style = PaintingStyle.fill);
          }
        }
      case _PatternType.rings:
        canvas.drawCircle(
          Offset(size.width * 0.75, size.height * 0.72),
          22,
          paint,
        );
        canvas.drawCircle(
          Offset(size.width * 0.75, size.height * 0.72),
          34,
          paint,
        );
    }
  }

  @override
  bool shouldRepaint(covariant _CardPatternPainter old) =>
      old.pattern != pattern;
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
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
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
          const SizedBox(height: 14),
          _DiarySegmentBar(
            selected: _range,
            onChanged: (r) => setState(() => _range = r),
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: L.card,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: L.border.withValues(alpha: 0.25)),
              ),
              child: Text(
                'No doses logged for this period',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(color: L.sub),
              ),
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
            tint: const Color(0xFF9CA5FF),
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
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: L.fill.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: DashboardDiaryRange.values.map((range) {
          final isSel = range == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticEngine.selection();
                onChanged(range);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(vertical: 10),
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
      padding: const EdgeInsets.only(bottom: 14),
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
              color: item.tint.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.medication_liquid_rounded,
              size: 18,
              color: item.tint,
            ),
          ),
          const SizedBox(width: 12),
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
                    color: const Color(0xFF9CA5FF),
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
