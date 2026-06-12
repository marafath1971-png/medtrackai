import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../core/utils/haptic_engine.dart';
import '../../widgets/shared/shared_widgets.dart'; // Contains BouncingButton

// ══════════════════════════════════════════════
// HOOK B: STACKING CIRCLES (Social Accountability)
// Premium Gen Z Biohacking Leaderboards
// ══════════════════════════════════════════════

class StackCirclesScreen extends StatefulWidget {
  const StackCirclesScreen({super.key});

  @override
  State<StackCirclesScreen> createState() => _StackCirclesScreenState();
}

class _StackCirclesScreenState extends State<StackCirclesScreen> {
  // Mock data for the social feed
  final List<Map<String, dynamic>> _circleMembers = [
    {
      'name': 'Alex',
      'avatar': 'assets/images/app_logo.png',
      'streak': 142,
      'adherence': 0.98,
      'status': 'took_stack', // took_stack, pending, missed
      'stackName': 'God Mode',
      'time': '10 mins ago',
    },
    {
      'name': 'Sarah',
      'avatar': 'assets/images/app_logo.png',
      'streak': 45,
      'adherence': 0.88,
      'status': 'pending',
      'stackName': 'Flow State',
      'time': 'Waiting...',
    },
    {
      'name': 'Marcus',
      'avatar': 'assets/images/app_logo.png',
      'streak': 12,
      'adherence': 0.72,
      'status': 'missed',
      'stackName': 'Deep Sleep',
      'time': 'Missed yesterday',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    
    return Scaffold(
      backgroundColor: Colors.black, // True AMOLED black
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'My Circles',
          style: AppTypography.titleLarge.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          BouncingButton(
            onTap: () {
              HapticEngine.selection();
              _showPremiumGate(context);
            },
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: AppGradients.neonLime,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.add_rounded, color: Colors.black, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'NEW CIRCLE',
                    style: AppTypography.labelSmall.copyWith(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Circle Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: L.fill.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: AppColors.limeAccent.withValues(alpha: 0.2),
                        width: 1,
                      ),
                      boxShadow: AppShadows.glow(AppColors.limeAccent, intensity: 0.1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Sigma Stackers ⚡',
                              style: AppTypography.headlineSmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Rank #4',
                                style: AppTypography.labelSmall.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You are dominating this week. Keep the momentum.',
                          style: AppTypography.bodyMedium.copyWith(
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Leaderboard / Members
                        ..._circleMembers.map((member) => _buildMemberRow(L, member)),
                      ],
                    ),
                  ).animate().fade(duration: 400.ms).slideY(begin: 0.05, end: 0),
                  
                  const SizedBox(height: 40),
                  Text(
                    'Discover Circles',
                    style: AppTypography.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Premium teaser cards
                  _buildDiscoverCard(
                    L, 
                    title: 'Huberman Protocol', 
                    members: 1240, 
                    gradient: AppGradients.cyanFlash,
                  ),
                  const SizedBox(height: 16),
                  _buildDiscoverCard(
                    L, 
                    title: 'Silicon Valley Founders', 
                    members: 312, 
                    gradient: AppGradients.purpleDusk,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberRow(AppThemeColors L, Map<String, dynamic> member) {
    final bool isDone = member['status'] == 'took_stack';
    final bool isMissed = member['status'] == 'missed';
    
    Color statusColor = Colors.white.withValues(alpha: 0.4);
    if (isDone) statusColor = AppColors.limeAccent;
    if (isMissed) statusColor = L.error;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          // Avatar with gradient ring
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isDone 
                  ? AppGradients.neonLime 
                  : LinearGradient(colors: [L.border, L.border]),
            ),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: Colors.black,
              child: Image.asset(member['avatar'], width: 24, height: 24, color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      member['name'],
                      style: AppTypography.titleMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '🔥 ${member['streak']}',
                        style: AppTypography.labelSmall.copyWith(
                          color: const Color(0xFFFF6D00),
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  isDone ? '${member['stackName']} • ${member['time']}' : member['time'],
                  style: AppTypography.bodySmall.copyWith(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: isDone ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          
          // Interaction Button (Nudge/Spark)
          BouncingButton(
            onTap: () {
              HapticEngine.medium();
              if (!isDone) {
                // Show nudge toast
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Nudge sent to ${member['name']} ⚡'),
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                );
              }
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDone ? Colors.transparent : L.border.withValues(alpha: 0.1),
                border: Border.all(
                  color: isDone ? Colors.transparent : L.border.withValues(alpha: 0.2),
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  isDone ? '👏' : '⚡',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoverCard(AppThemeColors L, {required String title, required int members, required Gradient gradient}) {
    return BouncingButton(
      onTap: () {
        HapticEngine.selection();
        _showPremiumGate(context);
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: L.fill.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: L.border.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: gradient,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.group_rounded, color: Colors.white, size: 20),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '$members biohackers',
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.lock_rounded, color: Colors.white24, size: 16),
          ],
        ),
      ),
    );
  }

  void _showPremiumGate(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(32),
        decoration: const BoxDecoration(
          color: Color(0xFF111111),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: AppGradients.goldLegend,
                shape: BoxShape.circle,
                boxShadow: AppShadows.glow(const Color(0xFFFFD700), intensity: 0.3),
              ),
              child: const Center(
                child: Icon(Icons.workspace_premium_rounded, color: Colors.black, size: 32),
              ),
            ).animate().scale(curve: Curves.elasticOut, duration: 800.ms),
            const SizedBox(height: 24),
            Text(
              'Unlimited Circles',
              style: AppTypography.headlineSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Join unlimited stacking circles, challenge friends to duels, and unlock the global leaderboards with Med AI Premium.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: Colors.white.withValues(alpha: 0.6),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            BouncingButton(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: AppGradients.goldLegend,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    'UPGRADE NOW',
                    style: AppTypography.labelLarge.copyWith(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
