import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../theme/app_theme.dart';
import 'animated_pressable.dart';
import 'app_bottom_sheet.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PermissionSoftPrompt extends StatelessWidget {
  final String title;
  final String explanation;
  final IconData icon;
  final Color? color;
  final String buttonText;
  final Permission? permission;
  final VoidCallback onGranted;
  final VoidCallback? onDenied;
  final String fallbackExplanation;

  const PermissionSoftPrompt({
    super.key,
    required this.title,
    required this.explanation,
    required this.icon,
    this.color,
    required this.buttonText,
    this.permission,
    required this.onGranted,
    this.onDenied,
    required this.fallbackExplanation,
  });

  static Future<void> show({
    required BuildContext context,
    required String title,
    required String explanation,
    required IconData icon,
    Color? color,
    required String buttonText,
    Permission? permission,
    required VoidCallback onGranted,
    VoidCallback? onDenied,
    required String fallbackExplanation,
  }) async {
    // Check current status first if permission is provided
    if (permission != null) {
      final currentStatus = await permission.status;
      if (currentStatus.isGranted) {
        onGranted();
        return;
      }
    }

    if (!context.mounted) return;

    await AppBottomSheet.show(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => PermissionSoftPrompt(
        title: title,
        explanation: explanation,
        icon: icon,
        color: color,
        buttonText: buttonText,
        permission: permission,
        onGranted: () {
          Navigator.of(ctx).pop();
          onGranted();
        },
        onDenied: onDenied != null
            ? () {
                Navigator.of(ctx).pop();
                onDenied();
              }
            : () => Navigator.of(ctx).pop(),
        fallbackExplanation: fallbackExplanation,
      ),
    );
  }

  Future<void> _requestPermission(BuildContext context) async {
    if (permission == null) {
      onGranted();
      return;
    }

    final status = await permission!.request();
    if (status.isGranted) {
      onGranted();
    } else if (status.isPermanentlyDenied) {
      if (!context.mounted) return;
      _showFallback(context);
    } else {
      if (onDenied != null) onDenied!();
    }
  }

  void _showFallback(BuildContext context) {
    final L = context.L;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: L.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Permission Required',
          style: AppTypography.titleLarge.copyWith(color: L.text),
        ),
        content: Text(
          fallbackExplanation,
          style: AppTypography.bodyMedium.copyWith(color: L.sub),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: TextStyle(color: L.sub)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              openAppSettings();
              if (onDenied != null) onDenied!();
            },
            child: Text('Open Settings', style: TextStyle(color: L.accent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final primaryColor = color ?? L.accent;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primaryColor.withValues(alpha: 0.1),
              boxShadow: AppShadows.glow(primaryColor, intensity: 0.2),
            ),
            child: Center(
              child: Icon(icon, size: 40, color: primaryColor)
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scaleXY(begin: 0.95, end: 1.05, duration: 1000.ms, curve: Curves.easeInOut),
            ),
          ).animate().fade(duration: 400.ms).scale(curve: Curves.easeOutBack),
          const SizedBox(height: 24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.headlineMedium.copyWith(
              color: L.text,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ).animate().fade(delay: 100.ms).slideY(begin: 0.1, end: 0),
          const SizedBox(height: 12),
          Text(
            explanation,
            textAlign: TextAlign.center,
            style: AppTypography.bodyLarge.copyWith(
              color: L.sub.withValues(alpha: 0.8),
              height: 1.4,
            ),
          ).animate().fade(delay: 200.ms).slideY(begin: 0.1, end: 0),
          const SizedBox(height: 32),
          AnimatedPressable(
            onTap: () => _requestPermission(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor, Color.lerp(primaryColor, Colors.white, 0.2)!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(100),
                boxShadow: AppShadows.glow(primaryColor, intensity: 0.3),
              ),
              child: Center(
                child: Text(
                  buttonText,
                  style: AppTypography.labelLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ).animate().fade(delay: 300.ms).slideY(begin: 0.1, end: 0),
          const SizedBox(height: 16),
          AnimatedPressable(
            onTap: () {
              Navigator.of(context).pop();
              if (onDenied != null) onDenied!();
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Not Now',
                style: AppTypography.bodyMedium.copyWith(
                  color: L.sub.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ).animate().fade(delay: 400.ms),
        ],
      ),
    );
  }
}
