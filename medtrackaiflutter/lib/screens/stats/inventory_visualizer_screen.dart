import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;
import '../../providers/app_state.dart';
import '../../theme/med_ai_ui.dart';
import '../../core/utils/haptic_engine.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/common/animated_pressable.dart';
import '../../widgets/common/premium_empty_state.dart';

class InventoryVisualizerScreen extends StatefulWidget {
  const InventoryVisualizerScreen({super.key});

  @override
  State<InventoryVisualizerScreen> createState() =>
      _InventoryVisualizerScreenState();
}

class _InventoryVisualizerScreenState extends State<InventoryVisualizerScreen>
    with TickerProviderStateMixin {
  AnimationController? _waveController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MedAiA11y.reducedMotion(context);
    if (!reduceMotion && _waveController == null) {
      _waveController = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 2),
      )..repeat();
    } else if (reduceMotion && _waveController != null) {
      _waveController!.dispose();
      _waveController = null;
    }
  }

  @override
  void dispose() {
    _waveController?.dispose();
    super.dispose();
  }

  Widget _entrance(BuildContext context, Widget child, int index) {
    if (MedAiA11y.reducedMotion(context)) return child;
    return child
        .animate(delay: (index * 100).ms)
        .fadeIn(duration: AppDurations.fast)
        .slideY(begin: 0.1, end: 0, curve: AppCurves.smooth);
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
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding, vertical: 12),
              child: Row(
                children: [
                  Semantics(
                    button: true,
                    label: 'Back',
                    child: AnimatedPressable(
                      onTap: () {
                        HapticEngine.selection();
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: MedAiA11y.minTapTarget,
                        height: MedAiA11y.minTapTarget,
                        decoration: BoxDecoration(
                          color: L.card,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: L.border.withValues(alpha: 0.12)),
                          boxShadow: AppShadows.soft,
                        ),
                        child: Icon(Icons.arrow_back_ios_new_rounded,
                            color: L.text, size: 18),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Inventory',
                          style: AppTypography.headlineSmall.copyWith(
                            fontWeight: FontWeight.w800,
                            color: L.text,
                            letterSpacing: -0.4,
                          ),
                        ),
                        Text(
                          'Live refill levels',
                          style: AppTypography.bodySmall.copyWith(color: L.sub),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: meds.isEmpty
                  ? Center(
                      child: PremiumEmptyState(
                        title: 'No medications to track',
                        subtitle: 'Add meds from Home to see inventory levels.',
                        icon: Icons.medication_outlined,
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
                          _LiquidFillBottle(
                            med: med,
                            waveController: _waveController,
                            L: L,
                          ),
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
  final AnimationController? waveController;
  final AppThemeColors L;

  const _LiquidFillBottle({
    required this.med,
    required this.waveController,
    required this.L,
  });

  @override
  Widget build(BuildContext context) {
    final fillPercentage =
        med.totalCount > 0 ? (med.count / med.totalCount).clamp(0.0, 1.0) : 0.0;
    final isLowStock = med.count <= med.refillAt;
    final liquidColor = isLowStock ? L.error : L.accent;
    final trackColor = L.border.withValues(alpha: 0.1);
    final reduceMotion = MedAiA11y.reducedMotion(context);

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
                child: waveController != null && !reduceMotion
                    ? AnimatedBuilder(
                        animation: waveController!,
                        builder: (context, child) {
                          return CustomPaint(
                            painter: _LiquidPainter(
                              fillPercentage: fillPercentage,
                              waveAnimation: waveController!.value,
                              color: liquidColor,
                            ),
                          );
                        },
                      )
                    : CustomPaint(
                        painter: _LiquidPainter(
                          fillPercentage: fillPercentage,
                          waveAnimation: 0,
                          color: liquidColor,
                          staticFill: true,
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
                          MedAiGlass(
                            padding: const EdgeInsets.all(8),
                            radius: AppRadius.xl,
                            showBorder: false,
                            child: Text(
                              med.isSachet ? '📦' : '💊',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          if (isLowStock)
                            Icon(Icons.warning_rounded,
                                color: L.error, size: 20, semanticLabel: 'Low stock'),
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
  final double waveAnimation;
  final Color color;
  final bool staticFill;

  _LiquidPainter({
    required this.fillPercentage,
    required this.waveAnimation,
    required this.color,
    this.staticFill = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (fillPercentage <= 0) return;

    final path = Path();
    final waveHeight = staticFill ? 0.0 : size.height * 0.05;
    final waterLevel = size.height - (size.height * fillPercentage);

    final backPaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    final backPath = Path();
    backPath.moveTo(0, size.height);
    backPath.lineTo(0, waterLevel);

    for (double i = 0; i <= size.width; i++) {
      final y = waterLevel +
          math.cos((i / size.width * 2 * math.pi) +
                  (waveAnimation * 2 * math.pi)) *
              waveHeight;
      backPath.lineTo(i, y);
    }

    backPath.lineTo(size.width, size.height);
    backPath.close();
    canvas.drawPath(backPath, backPaint);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    path.moveTo(0, size.height);
    path.lineTo(0, waterLevel);

    for (double i = 0; i <= size.width; i++) {
      final y = waterLevel +
          math.sin((i / size.width * 2 * math.pi) +
                  (waveAnimation * 2 * math.pi)) *
              waveHeight;
      path.lineTo(i, y);
    }

    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LiquidPainter oldDelegate) {
    return oldDelegate.fillPercentage != fillPercentage ||
        oldDelegate.waveAnimation != waveAnimation ||
        oldDelegate.color != color ||
        oldDelegate.staticFill != staticFill;
  }
}
