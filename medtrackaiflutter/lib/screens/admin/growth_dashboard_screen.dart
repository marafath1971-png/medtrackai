import '../../widgets/common/premium_shimmer.dart';
import 'package:flutter/material.dart';
import '../../services/growth_tracker.dart';
import '../../theme/app_theme.dart';

class GrowthDashboardScreen extends StatefulWidget {
  const GrowthDashboardScreen({super.key});

  @override
  State<GrowthDashboardScreen> createState() => _GrowthDashboardScreenState();
}

class _GrowthDashboardScreenState extends State<GrowthDashboardScreen> {
  bool _loading = true;
  List<TrackedUser> _users = [];
  Map<String, double> _aiHealth = {};
  Map<String, Map<String, double>> _correlations = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final users = await GrowthTracker.getAllUsers();
    final aiHealth = await GrowthTracker.getAiFeatureHealth();
    final correlations = await GrowthTracker.getFeatureCorrelations();

    setState(() {
      _users = users;
      _aiHealth = aiHealth;
      _correlations = correlations;
      _loading = false;
    });
  }


  @override
  Widget build(BuildContext context) {
    final L = context.L;

    return Scaffold(
      backgroundColor: L.bg,
      appBar: AppBar(
        title: const Text('Growth & Analytics', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: L.bg,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
          )
        ],
      ),
      body: _loading
          ? const ContextualLoader(message: "Loading dashboard...")
          : SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  const SizedBox(height: 24),

                  // Activation Funnel Section
                  _buildSectionTitle('ACTIVATION FUNNEL'),
                  const SizedBox(height: 8),
                  _buildFunnelCard(L),

                  const SizedBox(height: 24),

                  // AI Feature Health Section
                  _buildSectionTitle('AI FEATURE HEALTH'),
                  const SizedBox(height: 8),
                  _buildAiHealthCard(L),

                  const SizedBox(height: 24),

                  // Feature Retention Correlations Section
                  _buildSectionTitle('RETENTION CORRELATION MATRIX'),
                  const SizedBox(height: 8),
                  _buildCorrelationCard(L),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white38,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildFunnelCard(AppThemeColors L) {
    if (_users.isEmpty) {
      return const Card(
        color: Colors.transparent,
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text('No user analytics records found. Click simulation utility above to populate.', style: TextStyle(color: Colors.white60)),
        ),
      );
    }

    final total = _users.length;
    final created = _users.where((u) => u.accountCreated).length;
    final medAdded = _users.where((u) => u.firstMedAdded).length;
    final doseLogged = _users.where((u) => u.firstDoseLogged).length;
    final day2 = _users.where((u) => u.returnedDay2).length;
    final day7 = _users.where((u) => u.retainedDay7).length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: L.fill.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: L.border.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          _buildFunnelRow('1. App Installs', total, total),
          _buildFunnelRow('2. Account Created', created, total),
          _buildFunnelRow('3. Meds Added', medAdded, total),
          _buildFunnelRow('4. First Dose Logged', doseLogged, total),
          _buildFunnelRow('5. Day-2 Return', day2, total),
          _buildFunnelRow('6. Day-7 Retention', day7, total),
        ],
      ),
    );
  }

  Widget _buildFunnelRow(String stage, int count, int total) {
    final pct = total > 0 ? (count / total) : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(stage, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
              Text('$count (${(pct * 100).toStringAsFixed(1)}%)', style: const TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: Colors.white.withValues(alpha: 0.06),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00E5A0)),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiHealthCard(AppThemeColors L) {
    final scanRate = _aiHealth['scanRate'] ?? 0.0;
    final voiceRate = _aiHealth['voiceRate'] ?? 0.0;
    final voiceFbRate = _aiHealth['voiceFallbackRate'] ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: L.fill.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: L.border.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          _buildMetricRow('AI Image Scan Match Rate', '${scanRate.toStringAsFixed(1)}%', 'Successful parses vs total scans'),
          const Divider(color: Colors.white10, height: 20),
          _buildMetricRow('Voice Log Match Rate', '${voiceRate.toStringAsFixed(1)}%', 'Matches mapped to daily schedule'),
          const Divider(color: Colors.white10, height: 20),
          _buildMetricRow('Voice Log Fallback Rate', '${voiceFbRate.toStringAsFixed(1)}%', 'Failed matches redirecting to manual add'),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String title, String value, String sub) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(sub, style: const TextStyle(color: Colors.white38, fontSize: 12)),
          ],
        ),
        Text(value, style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildCorrelationCard(AppThemeColors L) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: L.fill.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: L.border.withValues(alpha: 0.08)),
      ),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(2),
          1: FlexColumnWidth(2.2),
          2: FlexColumnWidth(2.2),
        },
        children: [
          const TableRow(
            children: [
              TableCell(child: Padding(padding: EdgeInsets.only(bottom: 12), child: Text('FEATURE', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)))),
              TableCell(child: Padding(padding: EdgeInsets.only(bottom: 12), child: Text('DAY-7 RETENTION\n(Used vs Not)', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.right))),
              TableCell(child: Padding(padding: EdgeInsets.only(bottom: 12), child: Text('DAY-30 RETENTION\n(Used vs Not)', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.right))),
            ],
          ),
          _buildCorrelationRow('AI Scanner', _correlations['ai_scanner']),
          _buildCorrelationRow('Voice Log', _correlations['voice_log']),
          _buildCorrelationRow('Record Mode', _correlations['record_mode']),
          _buildCorrelationRow('Care Circle', _correlations['care_circle']),
        ],
      ),
    );
  }

  TableRow _buildCorrelationRow(String feature, Map<String, double>? corr) {
    final d7Used = corr?['used_day7'] ?? 0.0;
    final d7Not = corr?['not_used_day7'] ?? 0.0;
    final d30Used = corr?['used_day30'] ?? 0.0;
    final d30Not = corr?['not_used_day30'] ?? 0.0;

    return TableRow(
      children: [
        TableCell(child: Padding(padding: const EdgeInsets.symmetric(vertical: 10.0), child: Text(feature, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
        TableCell(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Text(
              '${d7Used.round()}% vs ${d7Not.round()}%',
              style: TextStyle(
                color: d7Used > d7Not ? const Color(0xFF00E5A0) : Colors.white70,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ),
        TableCell(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Text(
              '${d30Used.round()}% vs ${d30Not.round()}%',
              style: TextStyle(
                color: d30Used > d30Not ? const Color(0xFF00E5A0) : Colors.white70,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ),
      ],
    );
  }
}
