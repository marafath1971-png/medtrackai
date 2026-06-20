import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../providers/app_state.dart';
import '../../../theme/app_theme.dart';
import '../../../core/utils/haptic_engine.dart';
import '../../../widgets/common/bouncing_button.dart';

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
          ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1,1), end: const Offset(1.2,1.2), duration: 4.seconds),
          
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
                        onPressed: () {
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
                                fontFamily: 'Courier',
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
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(AppSpacing.screenPadding),
                    children: [
                      // Longevity Score Card
                      _LongevityScoreCard(score: longevityScore, L: L)
                        .animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
                        
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
                      ).animate(delay: 100.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
                      
                      const SizedBox(height: 24),
                      
                      // Trend Visualization
                      Text(
                        'TREND ANALYSIS',
                        style: AppTypography.labelSmall.copyWith(
                          fontFamily: 'Courier',
                          color: L.sub,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _TrendGraph(L: L).animate(delay: 200.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
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
        border: Border.all(color: L.primary.withValues(alpha: 0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: L.primary.withValues(alpha: 0.1),
            blurRadius: 30,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bolt_rounded, color: L.primary, size: 20)
                .animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1,1), end: const Offset(1.2,1.2)),
              const SizedBox(width: 8),
              Text(
                'LONGEVITY SCORE',
                style: AppTypography.labelLarge.copyWith(
                  fontFamily: 'Courier',
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
              fontFamily: 'Courier',
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
              fontFamily: 'Courier',
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
              fontFamily: 'Courier',
              color: L.text,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTypography.labelSmall.copyWith(
              fontFamily: 'Courier',
              color: color,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: AppTypography.bodySmall.copyWith(
              fontFamily: 'Courier',
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

class _TrendGraph extends StatelessWidget {
  final AppThemeColors L;

  const _TrendGraph({required this.L});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: L.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: L.border.withValues(alpha: 0.05)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_graph_rounded, color: L.sub.withValues(alpha: 0.3), size: 48),
            const SizedBox(height: 8),
            Text(
              'Gathering more data for trend map...',
              style: AppTypography.bodySmall.copyWith(
                fontFamily: 'Courier',
                color: L.sub,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
