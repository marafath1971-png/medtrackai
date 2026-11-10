import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/app_state.dart';
import '../../theme/med_ai_ui.dart';
import '../../core/utils/haptic_engine.dart';
import '../../widgets/shared/shared_widgets.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/common/premium_empty_state.dart';
import '../../widgets/common/premium_page_header.dart';
import '../../l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context)!;
    final L = context.L;
    final meds = context.watch<AppState>().meds;

    return AppScaffold(
      showAurora: true,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PremiumPageHeader(
              title: l10n.inventory,
              subtitle: 'Live refill levels',
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: meds.isEmpty
                  ? Center(
                      child: PremiumEmptyState(
                        title: l10n.statsNoMedicationsToTrack,
                        subtitle: 'Add meds from Home to see inventory levels.',
                        mascotFeature: 'refill',
                        icon: Icons.inventory_2_outlined,
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(AppSpacing.screenPadding),
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

  void _showRefillSheet(BuildContext context, Medicine med, AppThemeColors L) {
    HapticEngine.selection();
    int addAmount = 30;
    final state = context.read<AppState>();
    final isLowStock = med.count <= med.refillAt;
    final liquidColor = isLowStock ? L.error : L.accent;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final projectedCount = med.count + addAmount;
          return Container(
            padding: const EdgeInsets.all(AppSpacing.p24),
            decoration: BoxDecoration(
              color: L.card,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 28,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: L.border.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.p20),
                  // Medicine Header
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: liquidColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: liquidColor.withValues(alpha: 0.2)),
                        ),
                        child: Icon(
                          med.isSachet
                              ? Icons.inventory_2_outlined
                              : Icons.medication_rounded,
                          color: liquidColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.p16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              med.name,
                              style: AppTypography.titleLarge.copyWith(
                                fontWeight: FontWeight.w700,
                                color: L.text,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Current stock: ${med.count} / ${med.totalCount} units${isLowStock ? ' · Low stock' : ''}',
                              style: AppTypography.labelSmall.copyWith(
                                color: isLowStock ? L.error : L.sub,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.p24),

                  // Quick preset pills
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [15, 30, 60, 90].map((preset) {
                      final isSelected = addAmount == preset;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: AnimatedPressable(
                          onTap: () {
                            HapticEngine.selection();
                            setSheetState(() => addAmount = preset);
                          },
                          scaleFactor: 0.94,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? L.accent
                                  : L.fill.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? L.accent
                                    : L.border.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              '+$preset',
                              style: AppTypography.labelMedium.copyWith(
                                color: isSelected ? Colors.white : L.text,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: AppSpacing.p24),

                  // Stepper & Units Display
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _StepButton(
                        icon: Icons.remove_rounded,
                        onTap: () {
                          HapticEngine.selection();
                          setSheetState(
                              () => addAmount = (addAmount - 5).clamp(5, 500));
                        },
                        L: L,
                      ),
                      const SizedBox(width: AppSpacing.p24),
                      Column(
                        children: [
                          Text(
                            '+$addAmount',
                            style: AppTypography.displayLarge.copyWith(
                              fontWeight: FontWeight.w700,
                              color: L.text,
                              fontSize: 48,
                              letterSpacing: -1.5,
                            ),
                          ),
                          Text(
                            'Units to add',
                            style: AppTypography.labelSmall.copyWith(
                              color: L.sub,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: AppSpacing.p24),
                      _StepButton(
                        icon: Icons.add_rounded,
                        onTap: () {
                          HapticEngine.selection();
                          setSheetState(
                              () => addAmount = (addAmount + 5).clamp(5, 500));
                        },
                        L: L,
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.p16),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: L.fill.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'New Total: $projectedCount units',
                      style: AppTypography.labelSmall.copyWith(
                        color: L.sub,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.p24),

                  // Confirm Restock Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        HapticEngine.success();
                        await state.refillMedication(med.id, amount: addAmount);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: L.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Restock Bottle',
                        style: AppTypography.labelLarge.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.p8),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final fillPercentage =
        med.totalCount > 0 ? (med.count / med.totalCount).clamp(0.0, 1.0) : 0.0;
    final isLowStock = med.count <= med.refillAt;
    final liquidColor = isLowStock ? L.error : L.accent;
    final trackColor = L.border.withValues(alpha: 0.1);

    return Semantics(
      button: true,
      label: isLowStock
          ? l10n.statsInventoryRemainingLowStock(med.name, med.count)
          : l10n.statsInventoryRemaining(med.name, med.count),
      child: AnimatedPressable(
        onTap: () => _showRefillSheet(context, med, L),
        scaleFactor: 0.97,
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
                                  semanticLabel: l10n.statsLowStock),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.statsLeft(med.count),
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
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final AppThemeColors L;

  const _StepButton({
    required this.icon,
    required this.onTap,
    required this.L,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPressable(
      onTap: onTap,
      scaleFactor: 0.9,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: L.fill.withValues(alpha: 0.6),
          shape: BoxShape.circle,
          border: Border.all(color: L.border.withValues(alpha: 0.4)),
        ),
        child: Icon(icon, size: 22, color: L.text),
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
      Rect.fromLTWH(
          0, waterLevel, size.width, size.height * fillPercentage * 0.35),
      highlight,
    );
  }

  @override
  bool shouldRepaint(covariant _LiquidPainter oldDelegate) {
    return oldDelegate.fillPercentage != fillPercentage ||
        oldDelegate.color != color;
  }
}
