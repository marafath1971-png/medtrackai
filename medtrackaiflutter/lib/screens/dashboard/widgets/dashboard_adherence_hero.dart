import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../theme/app_theme.dart';
import '../../../theme/med_ai_ui.dart';

/// Reference Statistic hero — big adherence value + 7-day bar chart.
class DashboardAdherenceHero extends StatelessWidget {
  final List<Map<String, dynamic>> trendData;
  final double adherence;

  const DashboardAdherenceHero({
    super.key,
    required this.trendData,
    required this.adherence,
  });

  static const _dow = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final pct = (adherence * 100).round();
    final week = trendData.length >= 7
        ? trendData.sublist(trendData.length - 7)
        : trendData;
    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        color: L.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: L.border.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Adherence',
            style: AppTypography.labelMedium.copyWith(
              color: L.sub,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$pct',
                style: AppTypography.displaySmall.copyWith(
                  color: L.text,
                  fontWeight: FontWeight.w800,
                  fontSize: 36,
                  letterSpacing: -1,
                  height: 1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 6),
                child: Text(
                  '%',
                  style: AppTypography.titleMedium.copyWith(
                    color: L.sub,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'Target: 100%',
                style: AppTypography.labelSmall.copyWith(
                  color: L.sub.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (week.isEmpty)
            SizedBox(
              height: 120,
              child: Center(
                child: Text(
                  'Log doses to see your weekly chart',
                  style: AppTypography.bodySmall.copyWith(color: L.sub),
                ),
              ),
            )
          else
            SizedBox(
              height: 148,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(week.length, (i) {
                  final day = week[i];
                  final val = (day['value'] as num?)?.toDouble() ?? 0.0;
                  final dateStr = day['date'] as String? ?? '';
                  final isToday = dateStr == todayKey;
                  final barPct = (val * 100).round();
                  final date = DateTime.tryParse(dateStr);
                  final dowLabel = date != null
                      ? _dow[(date.weekday - 1) % 7]
                      : _dow[i % 7];
                  final isStrong = val >= 0.8;

                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: i < week.length - 1 ? 6 : 0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '$barPct%',
                            style: AppTypography.labelSmall.copyWith(
                              color: isToday && isStrong
                                  ? AppColors.limeInk
                                  : L.sub.withValues(alpha: 0.55),
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: FractionallySizedBox(
                                heightFactor:
                                    val <= 0 ? 0.08 : val.clamp(0.12, 1.0),
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6),
                                    gradient: isToday && isStrong
                                        ? const LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Color(0xFFB9EA6E),
                                              Color(0xFF8FD14F),
                                            ],
                                          )
                                        : null,
                                    color: isToday && isStrong
                                        ? null
                                        : L.fill.withValues(alpha: 0.55),
                                  ),
                                  foregroundDecoration: !(isToday && isStrong)
                                      ? BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          color: L.fill.withValues(alpha: 0.3),
                                        )
                                      : null,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            dowLabel,
                            style: AppTypography.labelSmall.copyWith(
                              color: isToday
                                  ? AppColors.limeDeep
                                  : L.sub.withValues(alpha: 0.55),
                              fontWeight:
                                  isToday ? FontWeight.w800 : FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}
