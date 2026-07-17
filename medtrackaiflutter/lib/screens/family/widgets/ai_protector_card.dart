import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../providers/app_state.dart';

class AIProtectorCard extends StatefulWidget {
  final Caregiver cg;
  final AppState state;
  final bool isDark;

  const AIProtectorCard({
    super.key,
    required this.cg,
    required this.state,
    this.isDark = false,
  });

  @override
  State<AIProtectorCard> createState() => _AIProtectorCardState();
}

class _AIProtectorCardState extends State<AIProtectorCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOutQuart);
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final insight = widget.state.protectorInsights[widget.cg.patientUid];
    final isLoading = insight == null;
    final L = context.L;

    return FadeTransition(
      opacity: _fade,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        decoration: BoxDecoration(
          color: L.card,
          borderRadius: AppRadius.roundL,
          border: Border.all(color: L.primary.withValues(alpha: 0.1), width: 0.5),
          boxShadow: AppShadows.premium,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.p8),
                  decoration: BoxDecoration(
                    color: L.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.psychology_rounded,
                      color: L.primary, size: 20),
                ),
                const SizedBox(width: AppSpacing.p12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('MedAI protector advisor',
                          style: AppTypography.titleLarge.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: L.text)),
                      Text('Intelligent care analysis',
                          style: AppTypography.bodySmall.copyWith(
                              fontSize: 11,
                              color: L.sub,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.p20),
            if (isLoading)
              const LinearProgressIndicator(
                backgroundColor: Colors.transparent,
                minHeight: 2,
              )
            else
              Text(
                insight,
                style: AppTypography.bodyMedium.copyWith(
                  height: 1.6,
                  color: L.text,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            if (!isLoading) ...[
              const SizedBox(height: AppSpacing.p16),
              Row(
                children: [
                  Icon(Icons.auto_awesome_rounded,
                      color: L.primary.withValues(alpha: 0.4), size: 14),
                  const SizedBox(width: AppSpacing.p8),
                  Text('Patterns analyzed across last 7 days',
                      style: AppTypography.bodySmall.copyWith(
                          fontSize: 11,
                          color: L.sub,
                          fontStyle: FontStyle.italic)),
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }
}
