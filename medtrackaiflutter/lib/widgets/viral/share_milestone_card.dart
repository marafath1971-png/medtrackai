import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../theme/app_theme.dart';

class ShareMilestoneCard extends StatelessWidget {
  final int streak;
  
  const ShareMilestoneCard({super.key, required this.streak});

  static Future<void> share(BuildContext context, int streak) async {
    final GlobalKey boundaryKey = GlobalKey();
    
    // Show a dialog temporarily to render the widget off-screen
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (ctx) => Center(
        child: SingleChildScrollView(
          child: RepaintBoundary(
            key: boundaryKey,
            child: Material(
              color: Colors.transparent,
              child: ShareMilestoneCard(streak: streak),
            ),
          ),
        ),
      ),
    );

    // Wait for render
    await Future.delayed(const Duration(milliseconds: 300));

    try {
      final boundary = boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/med_ai_streak.png');
      await file.writeAsBytes(bytes);

      if (context.mounted) {
        Navigator.of(context).pop(); // Close the invisible dialog
      }

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'I\'m on a $streak-day health streak with Med AI! 🔥',
      );
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      debugPrint('Error sharing: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      height: 480,
      decoration: BoxDecoration(
        gradient: AppGradients.main,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.limeAccent.withValues(alpha: 0.3), width: 2),
        boxShadow: AppShadows.glow(AppColors.limeAccent, intensity: 0.2),
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/app_logo.png', width: 24, height: 24),
              const SizedBox(width: 8),
              Text(
                'Med AI',
                style: AppTypography.displaySmall.copyWith(
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.limeAccent.withValues(alpha: 0.1),
              border: Border.all(color: AppColors.limeAccent.withValues(alpha: 0.5), width: 2),
            ),
            child: const Center(
              child: Icon(Icons.bolt_rounded, size: 64, color: AppColors.limeAccent),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '$streak',
            style: AppTypography.displayXL.copyWith(
              fontSize: 96,
              color: Colors.white,
            ),
          ),
          Text(
            'DAY STREAK',
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.limeAccent,
              letterSpacing: 4.0,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Consistency is the best medicine.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.white70,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Join me on Med AI',
              style: AppTypography.labelSmall.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
