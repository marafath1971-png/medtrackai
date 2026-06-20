import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/shared/shared_widgets.dart';
import '../../../core/utils/haptic_engine.dart';
import '../../visualizer/impact_visualizer_screen.dart';

class ImpactVisualizerCard extends StatelessWidget {
  const ImpactVisualizerCard({super.key});

  @override
  Widget build(BuildContext context) {
    final L = context.L;

    return BouncingButton(
      scaleFactor: 0.98,
      onTap: () {
        HapticEngine.selection();
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const ImpactVisualizerScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      },
      child: SquircleCard(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        radius: 24,
        child: Row(
          children: [
            // Hologram Icon Animation
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: L.secondary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(Icons.hub_rounded, color: L.secondary, size: 24),
              ),
            ).animate(onPlay: (controller) => controller.repeat(reverse: true))
             .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.15, 1.15), duration: 2.seconds, curve: Curves.easeInOut)
             .boxShadow(
               begin: BoxShadow(color: L.secondary.withValues(alpha: 0.1), blurRadius: 10),
               end: BoxShadow(color: L.secondary.withValues(alpha: 0.4), blurRadius: 20),
             ),
            
            const SizedBox(width: 16),
            
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Body Impact 🧬',
                    style: AppTypography.titleMedium.copyWith(
                      color: L.text,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Visualize medication absorption 🚀',
                    style: AppTypography.bodySmall.copyWith(
                      color: L.sub.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            
            // Arrow
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: L.bg,
                shape: BoxShape.circle,
                border: Border.all(color: L.border.withValues(alpha: 0.1)),
              ),
              child: Icon(Icons.arrow_forward_ios_rounded, color: L.text, size: 12),
            ),
          ],
        ),
      ),
    );
  }
}
