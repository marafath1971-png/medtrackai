import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../../providers/app_state.dart';
import '../../../core/constants/premium_graphics.dart';
import '../../../theme/med_ai_ui.dart';
import '../../../widgets/common/app_scaffold.dart';
import '../../../widgets/common/premium_empty_state.dart';
import '../../../widgets/common/premium_page_header.dart';

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
          SliverToBoxAdapter(
            child: PremiumPageHeader(
              title: 'Scan History',
              subtitle: 'Your recent medication scans',
              onBack: () => Navigator.pop(context),
            ),
          ),
          if (history.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: _entrance(
                  reduceMotion,
                  PremiumEmptyState(
                    title: 'No history yet',
                    subtitle: 'Medications you scan will appear here.',
                    illustrationAsset: PremiumGraphics.onboardingDiagnose,
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
