import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../../providers/app_state.dart';
import '../../../theme/med_ai_ui.dart';
import '../../../widgets/common/app_scaffold.dart';
import '../../../widgets/common/animated_pressable.dart';
import '../../../core/utils/haptic_engine.dart';

class ScanHistoryScreen extends StatelessWidget {
  const ScanHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final reduceMotion = MedAiA11y.reducedMotion(context);
    final state = context.watch<AppState>();

    final history = state.meds.toList()
      ..sort((a, b) {
        final aDate = DateTime.tryParse(a.courseStartDate) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = DateTime.tryParse(b.courseStartDate) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });

    return AppScaffold(
      showAurora: true,
      body: CustomScrollView(
        physics:
            const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Semantics(
              button: true,
              label: 'Back',
              child: AnimatedPressable(
                onTap: () {
                  HapticEngine.selection();
                  Navigator.pop(context);
                },
                child: Container(
                  width: MedAiA11y.minTapTarget,
                  height: MedAiA11y.minTapTarget,
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: L.fill.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.arrow_back_ios_new_rounded,
                      color: L.text, size: 18),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
              title: Text(
                'Scan History',
                style: AppTypography.titleLarge.copyWith(
                  color: L.text,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
          if (history.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: _entrance(
                  reduceMotion,
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.history_rounded,
                            size: 48, color: AppColors.accent),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'No history yet',
                        style: AppTypography.titleMedium.copyWith(
                          color: L.text,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Medications you scan will appear here',
                        style: AppTypography.bodyMedium.copyWith(color: L.sub),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding:
                  const EdgeInsets.only(top: 16, left: 24, right: 24, bottom: 40),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final med = history[index];
                    final parsedDate =
                        DateTime.tryParse(med.courseStartDate) ?? DateTime.now();
                    final date = DateFormat('MMM d, yyyy').format(parsedDate);

                    Widget row = MedAiDepthCard(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: MedAiA11y.minTapTarget,
                            height: MedAiA11y.minTapTarget,
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(Icons.medication_rounded,
                                color: AppColors.accent, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  med.name,
                                  style: AppTypography.titleMedium.copyWith(
                                    color: L.text,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Added: $date',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: L.sub,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded,
                              color: L.sub.withValues(alpha: 0.4)),
                        ],
                      ),
                    );

                    row = Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: row,
                    );

                    if (reduceMotion) return row;
                    return row
                        .animate()
                        .fadeIn(delay: Duration(milliseconds: 50 * index))
                        .slideX(begin: 0.05, end: 0, curve: AppCurves.smooth);
                  },
                  childCount: history.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  static Widget _entrance(bool reduceMotion, Widget child) {
    if (reduceMotion) return child;
    return child
        .animate()
        .fadeIn(duration: AppDurations.fast)
        .slideY(begin: 0.1, end: 0, curve: AppCurves.smooth);
  }
}
