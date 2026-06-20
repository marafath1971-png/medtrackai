import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../providers/app_state.dart';
import '../../../theme/app_theme.dart';
import '../../../core/utils/haptic_engine.dart';
import '../../../widgets/shared/shared_widgets.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final state = context.watch<AppState>();
    
    // Bio-hacking formulas
    final adherence = state.getAdherenceScore();
    final streak = state.getStreak();
    final totalSymptoms = state.symptoms.length;
    
    // The "Longevity Score" is a gamified metric between 0 and 1000
    final longevityScore = ((adherence * 800) + (streak * 2)).clamp(0, 1000).toInt();
    
    return Scaffold(
      backgroundColor: L.bg,
      body: Stack(
        children: [
          // Background ambient glows
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: L.primary.withValues(alpha: 0.15),
                boxShadow: [
                  BoxShadow(color: L.primary.withValues(alpha: 0.2), blurRadius: 100)
                ],
              ),
            ),
          ).animate(key: const ValueKey('analytics_bg_glow_anim'), onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1,1), end: const Offset(1.2,1.2), duration: 4.seconds),
          
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Custom App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding, vertical: 16),
                  child: Row(
                    children: [
                      BouncingButton(
                        onTap: () {
                          HapticEngine.selection();
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: L.card,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: L.border.withValues(alpha: 0.1)),
                          ),
                          child: Icon(Icons.arrow_back_ios_new_rounded, color: L.text, size: 18),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'BIO-ANALYTICS',
                              style: AppTypography.labelLarge.copyWith(
                                color: L.secondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2.0,
                              ),
                            ),
                            Text(
                              'Performance Hub',
                              style: AppTypography.headlineMedium.copyWith(
                                color: L.text,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.screenPadding),
                    children: [
                      // Longevity Score Card
                      _LongevityScoreCard(score: longevityScore, L: L)
                        .animate(key: const ValueKey('analytics_score_card_anim')).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
                        
                      const SizedBox(height: 24),
                      
                      // Stat Grid
                      Row(
                        children: [
                          Expanded(
                            child: _StatMiniCard(
                              title: 'ADHERENCE',
                              value: '${(adherence * 100).round()}%',
                              subtitle: 'All Time',
                              icon: Icons.pie_chart_outline_rounded,
                              color: L.success,
                              L: L,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatMiniCard(
                              title: 'SYMPTOMS',
                              value: '$totalSymptoms',
                              subtitle: 'Total Logs',
                              icon: Icons.monitor_heart_outlined,
                              color: L.error,
                              L: L,
                            ),
                          ),
                        ],
                      ).animate(key: const ValueKey('analytics_stat_grid_anim'), delay: 100.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
                      
                      const SizedBox(height: 24),
                      
                      // Trend Visualization
                      Text(
                        'TREND ANALYSIS',
                        style: AppTypography.labelSmall.copyWith(
                          color: L.sub,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _TrendGraph(L: L).animate(key: const ValueKey('analytics_trend_graph_anim'), delay: 200.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LongevityScoreCard extends StatelessWidget {
  final int score;
  final AppThemeColors L;

  const _LongevityScoreCard({required this.score, required this.L});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: L.card,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: L.border.withValues(alpha: 0.1), width: 1.0),
        boxShadow: AppShadows.neumorphic,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bolt_rounded, color: L.primary, size: 20)
                .animate(key: const ValueKey('analytics_bolt_icon_anim'), onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1,1), end: const Offset(1.2,1.2)),
              const SizedBox(width: 8),
              Text(
                'LONGEVITY SCORE',
                style: AppTypography.labelLarge.copyWith(
                  color: L.primary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '$score',
            style: AppTypography.displayLarge.copyWith(
              color: L.text,
              fontSize: 72,
              fontWeight: FontWeight.w900,
              letterSpacing: -2.0,
              height: 1.0,
            ),
          ).animate().shimmer(duration: 2.seconds, color: L.primary.withValues(alpha: 0.3)),
          const SizedBox(height: 8),
          Text(
            'Top 5% of MedTrack Users 🚀',
            style: AppTypography.bodyMedium.copyWith(
              color: L.sub,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatMiniCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final AppThemeColors L;

  const _StatMiniCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.L,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: L.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: L.border.withValues(alpha: 0.05)),
        boxShadow: AppShadows.neumorphic,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: AppTypography.headlineMedium.copyWith(
              color: L.text,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTypography.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: AppTypography.bodySmall.copyWith(
              color: L.sub,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendGraph extends StatefulWidget {
  final AppThemeColors L;

  const _TrendGraph({required this.L});

  @override
  State<_TrendGraph> createState() => _TrendGraphState();
}

class _TrendGraphState extends State<_TrendGraph> {
  bool _animate = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _animate = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final L = widget.L;
    final data = [0.4, 0.6, 0.5, 0.8, 0.7, 0.9, 1.0];
    
    return Container(
      height: 180,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: L.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: L.border.withValues(alpha: 0.05)),
        boxShadow: AppShadows.neumorphic,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weekly Performance',
                style: AppTypography.labelMedium.copyWith(
                  color: L.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Icon(Icons.show_chart_rounded, color: L.secondary, size: 20),
            ],
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(data.length, (index) {
              final targetHeight = 100.0 * data[index];
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 500 + index * 100),
                    curve: Curves.easeOutBack,
                    height: _animate ? targetHeight : 0.0,
                    decoration: BoxDecoration(
                      color: index == data.length - 1 ? L.secondary : L.secondary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
