import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/app_state.dart';
import '../../theme/med_ai_ui.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/common/premium_empty_state.dart';
import '../../widgets/common/premium_page_header.dart';

class InventoryVisualizerScreen extends StatelessWidget {
  const InventoryVisualizerScreen({super.key});

  Widget _entrance(BuildContext context, Widget child, int index) {
    if (MedAiA11y.reducedMotion(context)) return child;
    return child
        .animate(delay: (index * 80).ms)
        .fadeIn(duration: AppDurations.fast)
        .slideY(begin: 0.06, end: 0, curve: AppCurves.smooth);
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final meds = context.watch<AppState>().meds;

    return AppScaffold(
      showAurora: true,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PremiumPageHeader(
              title: 'Inventory',
              subtitle: 'Live refill levels',
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: meds.isEmpty
                  ? Center(
                      child: PremiumEmptyState(
                        title: 'No medications to track',
                        subtitle: 'Add meds from Home to see inventory levels.',
                        mascotFeature: 'refill',
                        icon: Icons.inventory_2_outlined,
                      ),
                    )
                  : GridView.builder(
                      padding:
                          const EdgeInsets.all(AppSpacing.screenPadding),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: meds.length,
                      itemBuilder: (context, index) {
                        final med = meds[index];
                        return _entrance(
                          context,
                          _LiquidFillBottle(med: med, L: L),
                          index,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiquidFillBottle extends StatelessWidget {
  final Medicine med;
  final AppThemeColors L;

  const _LiquidFillBottle({
    required this.med,
    required this.L,
  });

  @override
  Widget build(BuildContext context) {
    final fillPercentage =
        med.totalCount > 0 ? (med.count / med.totalCount).clamp(0.0, 1.0) : 0.0;
    final isLowStock = med.count <= med.refillAt;
    final liquidColor = isLowStock ? L.error : L.accent;
    final trackColor = L.border.withValues(alpha: 0.1);

    return Semantics(
      label:
          '${med.name}, ${med.count} remaining${isLowStock ? ', low stock' : ''}',
      child: MedAiDepthCard(
        padding: EdgeInsets.zero,
        radius: AppRadius.xl,
        accentGlow: isLowStock,
        color: L.card,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Positioned.fill(child: Container(color: trackColor)),
              Positioned.fill(
                child: CustomPaint(
                  painter: _LiquidPainter(
                    fillPercentage: fillPercentage,
                    color: liquidColor,
                  ),
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: L.card.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: L.border.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Icon(
                              med.isSachet
                                  ? Icons.inventory_2_outlined
                                  : Icons.medication_rounded,
                              color: liquidColor,
                              size: 18,
                            ),
                          ),
                          if (isLowStock)
                            Icon(Icons.warning_rounded,
                                color: L.error,
                                size: 20,
                                semanticLabel: 'Low stock'),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${med.count} left',
                            style: AppTypography.headlineMedium.copyWith(
                              color: fillPercentage > 0.4
                                  ? Colors.white
                                  : L.text,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            med.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.labelMedium.copyWith(
                              color: fillPercentage > 0.4
                                  ? Colors.white.withValues(alpha: 0.8)
                                  : L.sub,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiquidPainter extends CustomPainter {
  final double fillPercentage;
  final Color color;

  _LiquidPainter({
    required this.fillPercentage,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (fillPercentage <= 0) return;

    final path = Path();
    final waterLevel = size.height - (size.height * fillPercentage);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    path.moveTo(0, size.height);
    path.lineTo(0, waterLevel);
    path.lineTo(size.width, waterLevel);
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, paint);

    final highlight = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(0, waterLevel, size.width, size.height * fillPercentage * 0.35),
      highlight,
    );
  }

  @override
  bool shouldRepaint(covariant _LiquidPainter oldDelegate) {
    return oldDelegate.fillPercentage != fillPercentage ||
        oldDelegate.color != color;
  }
}
