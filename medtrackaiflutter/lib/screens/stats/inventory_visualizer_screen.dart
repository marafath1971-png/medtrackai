import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;
import '../../../providers/app_state.dart';
import '../../../theme/app_theme.dart';
import '../../../core/utils/haptic_engine.dart';
import '../../../domain/entities/medicine.dart';

class InventoryVisualizerScreen extends StatefulWidget {
  const InventoryVisualizerScreen({super.key});

  @override
  State<InventoryVisualizerScreen> createState() => _InventoryVisualizerScreenState();
}

class _InventoryVisualizerScreenState extends State<InventoryVisualizerScreen> with TickerProviderStateMixin {
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final meds = context.watch<AppState>().meds;

    return Scaffold(
      backgroundColor: L.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: L.text, size: 20),
          onPressed: () {
            HapticEngine.selection();
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Inventory',
          style: AppTypography.headlineSmall.copyWith(
            fontWeight: FontWeight.w800,
            color: L.text,
          ),
        ),
      ),
      body: meds.isEmpty
          ? Center(
              child: Text(
                'No medications to track.',
                style: AppTypography.bodyMedium.copyWith(color: L.sub),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: meds.length,
              itemBuilder: (context, index) {
                final med = meds[index];
                return _LiquidFillBottle(
                  med: med,
                  waveController: _waveController,
                  L: L,
                ).animate(delay: (index * 100).ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
              },
            ),
    );
  }
}

class _LiquidFillBottle extends StatelessWidget {
  final Medicine med;
  final AnimationController waveController;
  final AppThemeColors L;

  const _LiquidFillBottle({
    required this.med,
    required this.waveController,
    required this.L,
  });

  @override
  Widget build(BuildContext context) {
    final fillPercentage = med.totalCount > 0 ? (med.count / med.totalCount).clamp(0.0, 1.0) : 0.0;
    final isLowStock = med.count <= med.refillAt;
    
    // Low stock color logic
    final liquidColor = isLowStock ? L.error : AppColors.accent;
    final trackColor = L.border.withValues(alpha: 0.1);

    return Container(
      decoration: BoxDecoration(
        color: L.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isLowStock ? L.error.withValues(alpha: 0.5) : L.border.withValues(alpha: 0.1),
          width: isLowStock ? 2 : 1,
        ),
        boxShadow: [
          if (isLowStock)
            BoxShadow(
              color: L.error.withValues(alpha: 0.2),
              blurRadius: 20,
              spreadRadius: 2,
            )
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Background
          Positioned.fill(
            child: Container(color: trackColor),
          ),
          
          // Liquid Wave Fill
          Positioned.fill(
            child: AnimatedBuilder(
              animation: waveController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _LiquidPainter(
                    fillPercentage: fillPercentage,
                    waveAnimation: waveController.value,
                    color: liquidColor,
                  ),
                );
              },
            ),
          ),
          
          // Foreground Text Info
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Icon & Low Stock Indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: L.card.withValues(alpha: 0.8),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          med.isSachet ? '📦' : '💊',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      if (isLowStock)
                        Icon(Icons.warning_rounded, color: L.error, size: 20)
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .scale(begin: const Offset(1,1), end: const Offset(1.2,1.2), duration: 1.seconds),
                    ],
                  ),
                  
                  // Text Info
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${med.count} left',
                        style: AppTypography.headlineMedium.copyWith(
                          color: fillPercentage > 0.4 ? Colors.white : L.text,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        med.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelMedium.copyWith(
                          color: fillPercentage > 0.4 ? Colors.white.withValues(alpha: 0.8) : L.sub,
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
    );
  }
}

class _LiquidPainter extends CustomPainter {
  final double fillPercentage;
  final double waveAnimation;
  final Color color;

  _LiquidPainter({
    required this.fillPercentage,
    required this.waveAnimation,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (fillPercentage <= 0) return;

    final path = Path();
    
    final waveHeight = size.height * 0.05; // 5% of height is wave
    final waterLevel = size.height - (size.height * fillPercentage);
    
    // Add a slightly lighter background wave
    final backPaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;
      
    final backPath = Path();
    backPath.moveTo(0, size.height);
    backPath.lineTo(0, waterLevel);
    
    for (double i = 0; i <= size.width; i++) {
      final y = waterLevel + math.cos((i / size.width * 2 * math.pi) + (waveAnimation * 2 * math.pi)) * waveHeight;
      backPath.lineTo(i, y);
    }
    
    backPath.lineTo(size.width, size.height);
    backPath.close();
    
    canvas.drawPath(backPath, backPaint);

    // Front Wave
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    path.moveTo(0, size.height);
    path.lineTo(0, waterLevel);

    for (double i = 0; i <= size.width; i++) {
      final y = waterLevel + math.sin((i / size.width * 2 * math.pi) + (waveAnimation * 2 * math.pi)) * waveHeight;
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
           oldDelegate.color != color;
  }
}
