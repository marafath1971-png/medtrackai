import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/utils/haptic_engine.dart';
import '../../services/growth_tracker.dart';
import '../../core/constants/premium_graphics.dart';
import '../../theme/med_ai_ui.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/common/med_ai_mascot.dart';
import '../../widgets/common/premium_shimmer.dart';

class GrowthDashboardScreen extends StatefulWidget {
  const GrowthDashboardScreen({super.key});

  @override
  State<GrowthDashboardScreen> createState() => _GrowthDashboardScreenState();
}

class _GrowthDashboardScreenState extends State<GrowthDashboardScreen> {
  bool _loading = true;
  String? _error;
  List<TrackedUser> _users = [];
  Map<String, double> _aiHealth = {};
  Map<String, Map<String, double>> _correlations = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final users = await GrowthTracker.getAllUsers();
      final aiHealth = await GrowthTracker.getAiFeatureHealth();
      final correlations = await GrowthTracker.getFeatureCorrelations();

      if (!mounted) return;
      setState(() {
        _users = users;
        _aiHealth = aiHealth;
        _correlations = correlations;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load growth analytics.';
        _loading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    final L = context.L;

    return AppScaffold(
      body: SafeArea(
        child: _loading
            ? const Center(child: ContextualLoader(message: 'Loading growth data...'))
            : RefreshIndicator(
                color: L.bg,
                backgroundColor: L.text,
                onRefresh: () async {
                  HapticEngine.selection();
                  await _loadData();
                },
                child: CustomScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
                      sliver: SliverList.list(
                        children: [
                          _buildHero(L),
                          if (_error != null) ...[
                            const SizedBox(height: 16),
                            _buildErrorCard(L),
                          ],
                          const SizedBox(height: 22),
                          _buildSummaryGrid(L),
                          const SizedBox(height: 28),
                          _buildSectionTitle('ACTIVATION FUNNEL',
                              'Where users convert or drop off'),
                          const SizedBox(height: 12),
                          _buildFunnelCard(L),
                          const SizedBox(height: 28),
                          _buildSectionTitle('AI FEATURE HEALTH',
                              'Quality signals for scanner and voice loops'),
                          const SizedBox(height: 12),
                          _buildAiHealthCard(L),
                          const SizedBox(height: 28),
                          _buildSectionTitle('RETENTION CORRELATIONS',
                              'Feature usage against day-7 and day-30 retention'),
                          const SizedBox(height: 12),
                          _buildCorrelationCard(L),
                          const SizedBox(height: 36),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHero(AppThemeColors L) {
    final total = _users.length;
    final retainedDay7 = _users.where((u) => u.retainedDay7).length;
    final day7Rate = _rate(retainedDay7, total);

    return LiquidGlass(
      radius: 34,
      blur: 26,
      tintOpacity: context.isDark ? 0.07 : 0.45,
      padding: const EdgeInsets.fromLTRB(20, 20, 18, 20),
      child: Row(
        children: [
          const MedAiMascot(
            size: 76,
            semanticLabel: 'Med AI growth assistant',
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Growth Command Center',
                  style: AppTypography.headlineMedium.copyWith(
                    color: L.text,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$total tracked ${total == 1 ? 'user' : 'users'} · ${day7Rate.toStringAsFixed(0)}% day-7 retention',
                  style: AppTypography.bodyMedium.copyWith(
                    color: L.sub,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Semantics(
            button: true,
            label: 'Refresh growth dashboard',
            child: IconButton.filledTonal(
              tooltip: 'Refresh',
              onPressed: () {
                HapticEngine.selection();
                _loadData();
              },
              icon: Icon(Icons.refresh_rounded, color: L.text),
            ),
          ),
        ],
      ),
    ).medAiChain(
      context,
      (w) => w.animate().fadeIn(duration: 450.ms).slideY(begin: 0.04, end: 0),
    );
  }

  Widget _buildErrorCard(AppThemeColors L) {
    return _DashboardCard(
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: L.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _error!,
              style: AppTypography.bodyMedium.copyWith(color: L.text),
            ),
          ),
          TextButton(onPressed: _loadData, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildSummaryGrid(AppThemeColors L) {
    final total = _users.length;
    final medAdded = _users.where((u) => u.firstMedAdded).length;
    final doseLogged = _users.where((u) => u.firstDoseLogged).length;
    final retainedDay7 = _users.where((u) => u.retainedDay7).length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 420;
        return GridView.count(
          crossAxisCount: isCompact ? 2 : 4,
          childAspectRatio: isCompact ? 1.18 : 1.05,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _KpiCard(
              label: 'Users',
              value: '$total',
              icon: Icons.groups_rounded,
              color: Design2026.electric,
            ),
            _KpiCard(
              label: 'Meds Added',
              value: '${_rate(medAdded, total).toStringAsFixed(0)}%',
              icon: Icons.medication_rounded,
              color: L.accent,
            ),
            _KpiCard(
              label: 'First Dose',
              value: '${_rate(doseLogged, total).toStringAsFixed(0)}%',
              icon: Icons.check_circle_rounded,
              color: L.green,
            ),
            _KpiCard(
              label: 'Day 7',
              value: '${_rate(retainedDay7, total).toStringAsFixed(0)}%',
              icon: Icons.trending_up_rounded,
              color: L.purple,
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    final L = context.L;
    return Semantics(
      header: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.labelSmall.copyWith(
              color: L.sub.withValues(alpha: 0.72),
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppTypography.bodySmall.copyWith(
              color: L.sub.withValues(alpha: 0.62),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFunnelCard(AppThemeColors L) {
    if (_users.isEmpty) {
      return const _EmptyAnalyticsCard(
        title: 'No growth records yet',
        message: 'Use the app flows or simulation utilities to populate activation data.',
      );
    }

    final total = _users.length;
    final created = _users.where((u) => u.accountCreated).length;
    final medAdded = _users.where((u) => u.firstMedAdded).length;
    final doseLogged = _users.where((u) => u.firstDoseLogged).length;
    final day2 = _users.where((u) => u.returnedDay2).length;
    final day7 = _users.where((u) => u.retainedDay7).length;

    return _DashboardCard(
      child: Column(
        children: [
          _buildFunnelRow('App installs', total, total, Design2026.electric),
          _buildFunnelRow('Account created', created, total, L.accent),
          _buildFunnelRow('Meds added', medAdded, total, L.green),
          _buildFunnelRow('First dose logged', doseLogged, total, L.amber),
          _buildFunnelRow('Day-2 return', day2, total, L.purple),
          _buildFunnelRow(
              'Day-7 retention', day7, total, Design2026.electric),
        ],
      ),
    );
  }

  Widget _buildFunnelRow(String stage, int count, int total, Color color) {
    final pct = total > 0 ? (count / total) : 0.0;
    final pctLabel = (pct * 100).toStringAsFixed(1);
    return Semantics(
      label: '$stage, $count users, $pctLabel percent',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  stage,
                  style: AppTypography.labelLarge.copyWith(
                    color: context.L.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '$count · $pctLabel%',
                style: AppTypography.labelMedium.copyWith(
                  color: context.L.sub,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: color.withValues(alpha: 0.10),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildAiHealthCard(AppThemeColors L) {
    final scanRate = _aiHealth['scanRate'] ?? 0.0;
    final voiceRate = _aiHealth['voiceRate'] ?? 0.0;
    final voiceFbRate = _aiHealth['voiceFallbackRate'] ?? 0.0;

    return _DashboardCard(
      child: Column(
        children: [
          _buildMetricRow(
            'AI Image Scan Match Rate',
            '${scanRate.toStringAsFixed(1)}%',
            'Successful parses vs total scans',
            Icons.document_scanner_rounded,
            Design2026.electric,
          ),
          const SizedBox(height: 12),
          _buildMetricRow(
            'Voice Log Match Rate',
            '${voiceRate.toStringAsFixed(1)}%',
            'Matches mapped to daily schedule',
            Icons.mic_rounded,
            L.accent,
          ),
          const SizedBox(height: 12),
          _buildMetricRow(
            'Voice Log Fallback Rate',
            '${voiceFbRate.toStringAsFixed(1)}%',
            'Failed matches redirecting to manual add',
            Icons.alt_route_rounded,
            L.amber,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(
      String title, String value, String sub, IconData icon, Color color) {
    final L = context.L;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: L.fill.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: L.border.withValues(alpha: 0.08)),
      ),
      child: Row(
      children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelLarge.copyWith(
                    color: L.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  sub,
                  style: AppTypography.bodySmall.copyWith(
                    color: L.sub,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            value,
            style: AppTypography.headlineSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorrelationCard(AppThemeColors L) {
    final features = [
      ('AI Scanner', Icons.document_scanner_rounded, _correlations['ai_scanner']),
      ('Voice Log', Icons.mic_rounded, _correlations['voice_log']),
      ('Record Mode', Icons.fiber_manual_record_rounded, _correlations['record_mode']),
      ('Care Circle', Icons.family_restroom_rounded, _correlations['care_circle']),
    ];

    return _DashboardCard(
      child: Column(
        children: [
          for (var i = 0; i < features.length; i++) ...[
            _buildCorrelationTile(
              features[i].$1,
              features[i].$2,
              features[i].$3,
            ),
            if (i != features.length - 1)
              Divider(height: 24, color: L.border.withValues(alpha: 0.10)),
          ],
        ],
      ),
    );
  }

  Widget _buildCorrelationTile(
      String feature, IconData icon, Map<String, double>? corr) {
    final L = context.L;
    final d7Used = corr?['used_day7'] ?? 0.0;
    final d7Not = corr?['not_used_day7'] ?? 0.0;
    final d30Used = corr?['used_day30'] ?? 0.0;
    final d30Not = corr?['not_used_day30'] ?? 0.0;
    final lift = d7Used - d7Not;
    final positive = lift >= 0;
    final signalColor = positive ? L.green : L.error;

    return Semantics(
      label:
          '$feature, day 7 retention ${d7Used.round()} percent for users and ${d7Not.round()} percent for non users, day 30 retention ${d30Used.round()} percent for users and ${d30Not.round()} percent for non users',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: signalColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: signalColor, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        feature,
                        style: AppTypography.labelLarge.copyWith(
                          color: L.text,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    _SignalPill(
                      label: '${positive ? '+' : ''}${lift.toStringAsFixed(0)} pts',
                      color: signalColor,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _RetentionCompare(
                  label: 'D7',
                  used: d7Used,
                  notUsed: d7Not,
                  color: signalColor,
                ),
                const SizedBox(height: 8),
                _RetentionCompare(
                  label: 'D30',
                  used: d30Used,
                  notUsed: d30Not,
                  color: d30Used >= d30Not ? L.green : L.error,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _rate(int count, int total) => total <= 0 ? 0 : (count / total) * 100;
}

class _DashboardCard extends StatelessWidget {
  final Widget child;

  const _DashboardCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return LiquidGlass(
      radius: 26,
      blur: 22,
      tintOpacity: context.isDark ? 0.06 : 0.48,
      padding: const EdgeInsets.all(18),
      child: child,
    ).medAiChain(
      context,
      (w) => w.animate().fadeIn(duration: 420.ms).slideY(begin: 0.03, end: 0),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return LiquidGlass(
      radius: 22,
      blur: 18,
      tintOpacity: context.isDark ? 0.05 : 0.42,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: AppTypography.headlineMedium.copyWith(
                  color: L.text,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.labelSmall.copyWith(
                  color: L.sub,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RetentionCompare extends StatelessWidget {
  final String label;
  final double used;
  final double notUsed;
  final Color color;

  const _RetentionCompare({
    required this.label,
    required this.used,
    required this.notUsed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final maxValue = [used, notUsed, 1.0].reduce((a, b) => a > b ? a : b);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 34,
              child: Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: L.sub,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Expanded(
              child: _MiniBar(
                value: used / maxValue,
                color: color,
                label: 'Used ${used.round()}%',
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${used.round()}%',
              style: AppTypography.labelSmall.copyWith(
                color: L.text,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            const SizedBox(width: 34),
            Expanded(
              child: _MiniBar(
                value: notUsed / maxValue,
                color: L.sub.withValues(alpha: 0.35),
                label: 'Not used ${notUsed.round()}%',
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${notUsed.round()}%',
              style: AppTypography.labelSmall.copyWith(
                color: L.sub,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MiniBar extends StatelessWidget {
  final double value;
  final Color color;
  final String label;

  const _MiniBar({
    required this.value,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: LinearProgressIndicator(
          value: value.clamp(0, 1),
          backgroundColor: context.L.fill.withValues(alpha: 0.4),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 7,
        ),
      ),
    );
  }
}

class _SignalPill extends StatelessWidget {
  final String label;
  final Color color;

  const _SignalPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _EmptyAnalyticsCard extends StatelessWidget {
  final String title;
  final String message;

  const _EmptyAnalyticsCard({
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return _DashboardCard(
      child: Column(
        children: [
          SvgPicture.asset(
            PremiumGraphics.healthInsights,
            width: 110,
            height: 86,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.titleLarge.copyWith(
              color: L.text,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: L.sub,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
