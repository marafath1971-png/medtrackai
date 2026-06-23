import 'package:flutter/material.dart';
import '../../../core/utils/haptic_engine.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../theme/app_theme.dart';
import '../../../providers/app_state.dart';
import 'package:medai/widgets/common/animated_pressable.dart';

class HomeMissedAlertsBanner extends StatelessWidget {
  final AppState state;
  final AppThemeColors L;

  const HomeMissedAlertsBanner({
    super.key,
    required this.state,
    required this.L,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPressable(
      onTap: () {
        HapticEngine.alertWarning();
        state.markAlertsAsSeen();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: L.text,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: [
            ...L.shadowSoft,
            BoxShadow(
              color: L.onBg.withValues(alpha: 0.1),
              blurRadius: 40,
              offset: const Offset(0, 20),
              spreadRadius: -10,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: L.bg.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.notifications_active_rounded,
                  color: L.bg, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MISSED DOSES',
                    style: AppTypography.labelLarge.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: L.bg.withValues(alpha: 0.6),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tap to clear recent alerts',
                    style: AppTypography.titleMedium.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: L.bg,
                      letterSpacing: -0.4,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: L.bg.withValues(alpha: 0.4)),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.1, end: 0);
  }
}

class HomeLowStockBanner extends StatefulWidget {
  final AppState state;
  final AppThemeColors L;
  final VoidCallback onTap;

  const HomeLowStockBanner({
    super.key,
    required this.state,
    required this.L,
    required this.onTap,
  });

  @override
  State<HomeLowStockBanner> createState() => _HomeLowStockBannerState();
}

class _HomeLowStockBannerState extends State<HomeLowStockBanner> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lowMeds = widget.state.getLowMeds();
    if (lowMeds.isEmpty) return const SizedBox();

    return AnimatedPressable(
      onTap: () {
        HapticEngine.selection();
        widget.onTap();
      },
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final glow = 0.2 + (_pulseController.value * 0.3);
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E1E1E), Color(0xFF121212)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: widget.L.red.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.L.red.withValues(alpha: glow),
                  blurRadius: 24,
                  spreadRadius: -4,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: child,
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Background pattern/shimmer effect
              Positioned(
                right: -30,
                top: -30,
                child: Icon(
                  Icons.warning_rounded,
                  size: 140,
                  color: widget.L.red.withValues(alpha: 0.05),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .rotate(begin: -0.05, end: 0.05, duration: 4.seconds),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    // Animated Icon
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: widget.L.red.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: widget.L.red.withValues(alpha: 0.2),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(Icons.medication_liquid_rounded, color: widget.L.red, size: 24)
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .scaleXY(begin: 1.0, end: 1.1, duration: 1.seconds),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: widget.L.red,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'ACTION REQUIRED',
                                  style: AppTypography.labelSmall.copyWith(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${lowMeds.length} ${lowMeds.length == 1 ? 'Item' : 'Items'} Low on Stock',
                            style: AppTypography.titleMedium.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap to review and restock before you run out.',
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 12,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 600.ms, curve: Curves.easeOutCubic).slideY(begin: 0.2, end: 0);
  }
}

