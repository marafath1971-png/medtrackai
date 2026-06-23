import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../theme/app_theme.dart';
import '../../../core/utils/haptic_engine.dart';
import '../../../widgets/shared/shared_widgets.dart';

// ══════════════════════════════════════════════════════════════════════
// 2026 PREMIUM SCANNER HELP & TIPS
// ══════════════════════════════════════════════════════════════════════
class ScannerHelpScreen extends StatelessWidget {
  const ScannerHelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final L = context.L;

    return Scaffold(
      backgroundColor: L.bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: AnimatedPressable(
              onTap: () {
                HapticEngine.selection();
                Navigator.pop(context);
              },
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: L.fill.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_back_ios_new_rounded, color: L.text, size: 18),
              ),
            ),
            flexibleSpace: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
                  title: Text(
                    'Scanning Tips',
                    style: AppTypography.titleLarge.copyWith(
                      color: L.text,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _TipCard(
                  icon: Icons.lightbulb_outline_rounded,
                  title: 'Good Lighting is Key',
                  description: 'Make sure the pill or bottle is well-lit. Avoid strong shadows or reflections on glossy labels.',
                  delay: 0,
                ),
                const SizedBox(height: 16),
                _TipCard(
                  icon: Icons.center_focus_strong_rounded,
                  title: 'Keep it Centered',
                  description: 'Place the medication right in the middle of the brackets. Hold your phone steady until the scan completes.',
                  delay: 100,
                ),
                const SizedBox(height: 16),
                _TipCard(
                  icon: Icons.qr_code_scanner_rounded,
                  title: 'Scan the NDC or Barcode',
                  description: 'For the highest accuracy, scan the barcode or the NDC number on the side of the prescription bottle.',
                  delay: 200,
                ),
                const SizedBox(height: 16),
                _TipCard(
                  icon: Icons.mic_rounded,
                  title: 'Try Voice Mode',
                  description: 'If you can\'t scan the label, try using Voice Mode to simply speak the name of the medication.',
                  delay: 300,
                ),
                const SizedBox(height: 48),
                
                // Need Help Button
                Center(
                  child: BouncingButton(
                    onTap: () {
                      HapticEngine.selection();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Support chat opening soon...')),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(100),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Text(
                        'Contact Support',
                        style: AppTypography.titleMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0),
                ),
                const SizedBox(height: 48),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final int delay;

  const _TipCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: L.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: L.border.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppColors.accent, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.titleMedium.copyWith(
                    color: L.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: AppTypography.bodyMedium.copyWith(
                    color: L.sub.withValues(alpha: 0.8),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: delay.ms).slideX(begin: 0.05, end: 0);
  }
}
