import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../theme/app_theme.dart';

// ══════════════════════════════════════════════
// VIRAL SHARE CARD — "Player Card" Premium Style
// TikTok/Cal AI 2026 Design Language
// ══════════════════════════════════════════════

enum ShareCardTheme {
  defaultTheme,
  godMode,
  flowState,
  deepSleep,
}

class ShareMilestoneCard extends StatelessWidget {
  final int streak;
  final double adherencePct;
  final String userName;
  final int totalDosesTaken;
  final ShareCardTheme theme;

  const ShareMilestoneCard({
    super.key,
    required this.streak,
    this.adherencePct = 0.95,
    this.userName = '',
    this.totalDosesTaken = 0,
    this.theme = ShareCardTheme.defaultTheme,
  });

  static Future<void> share(
    BuildContext context,
    int streak, {
    double adherencePct = 0.95,
    String userName = '',
    int totalDosesTaken = 0,
    ShareCardTheme theme = ShareCardTheme.defaultTheme,
  }) async {
    final GlobalKey boundaryKey = GlobalKey();

    // Render off-screen
    final overlay = OverlayEntry(
      builder: (_) => Positioned(
        left: -9999,
        top: -9999,
        child: RepaintBoundary(
          key: boundaryKey,
          child: Material(
            color: Colors.transparent,
            child: ShareMilestoneCard(
              streak: streak,
              adherencePct: adherencePct,
              userName: userName,
              totalDosesTaken: totalDosesTaken,
              theme: theme,
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(overlay);
    await Future.delayed(const Duration(milliseconds: 400));

    try {
      final boundary = boundaryKey.currentContext
          ?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        overlay.remove();
        return;
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/med_ai_milestone.png');
      await file.writeAsBytes(bytes);

      overlay.remove();

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text:
              '🔥 $streak-day medication streak! My consistency score: ${(adherencePct * 100).round()}%.\n\nTracking my health journey with Med AI 💊\n#MedAI #HealthGoals #Consistency',
        ),
      );
    } catch (e) {
      overlay.remove();
      debugPrint('ShareCard error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final score = (adherencePct * 100).round();
    final milestoneLabel = _getThemeMilestoneLabel(theme, streak);
    final gradientColors = _getThemeGradient(theme, streak);
    final tagline = _getThemeTagline(theme);

    return Container(
      width: 360,
      height: 520,
      decoration: BoxDecoration(
        color: const Color(0xFF000000),
        borderRadius: BorderRadius.circular(36),
        border: Border.all(
          color: gradientColors[0].withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withValues(alpha: 0.3),
            blurRadius: 60,
            spreadRadius: -10,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(36),
        child: Stack(
          children: [
            // — Ambient background glow
            Positioned(
              top: -60,
              left: -40,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      gradientColors[0].withValues(alpha: 0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -80,
              right: -40,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      gradientColors[1].withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // — Dot grid pattern overlay
            Positioned.fill(child: _DotGridPainterWidget()),

            // — Content
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Image.asset(
                            'assets/images/app_logo.png',
                            width: 26,
                            height: 26,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Med AI',
                            style: AppTypography.titleLarge.copyWith(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: gradientColors[0].withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: gradientColors[0].withValues(alpha: 0.4),
                              width: 0.8),
                        ),
                        child: Text(
                          milestoneLabel,
                          style: AppTypography.labelSmall.copyWith(
                            color: gradientColors[0],
                            fontSize: 9,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 36),

                  // User name
                  if (userName.isNotEmpty) ...[
                    Text(
                      userName.toUpperCase(),
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 10,
                        letterSpacing: 2.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Big streak number
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: gradientColors,
                    ).createShader(bounds),
                    child: Text(
                      '$streak',
                      style: AppTypography.displayXL.copyWith(
                        fontSize: 96,
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        height: 0.9,
                        letterSpacing: -4,
                      ),
                    ),
                  ),
                  Text(
                    'DAY STREAK',
                    style: AppTypography.labelMedium.copyWith(
                      color: Colors.white.withValues(alpha: 0.5),
                      letterSpacing: 4.0,
                      fontSize: 12,
                    ),
                  ),

                  const Spacer(),

                  // Stats row
                  Row(
                    children: [
                      _StatChip(
                        label: 'ADHERENCE',
                        value: '$score%',
                        color: gradientColors[0],
                      ),
                      const SizedBox(width: 12),
                      _StatChip(
                        label: 'DOSES TAKEN',
                        value: totalDosesTaken > 0
                            ? '$totalDosesTaken'
                            : '${streak * 2}',
                        color: gradientColors[1],
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Bottom motivational bar
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                          width: 0.5),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '"$tagline"',
                            style: AppTypography.bodySmall.copyWith(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              height: 1.4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.local_fire_department_rounded,
                          color: gradientColors[0],
                          size: 28,
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
    );
  }

  String _getThemeMilestoneLabel(ShareCardTheme theme, int streak) {
    switch (theme) {
      case ShareCardTheme.godMode:
        return 'GOD MODE';
      case ShareCardTheme.flowState:
        return 'FLOW STATE';
      case ShareCardTheme.deepSleep:
        return 'DEEP SLEEP';
      case ShareCardTheme.defaultTheme:
        if (streak >= 365) return '1 YEAR LEGEND';
        if (streak >= 100) return '100 DAY CHAMPION';
        if (streak >= 30) return '30 DAY WARRIOR';
        if (streak >= 14) return '2 WEEK STREAK';
        if (streak >= 7) return 'WEEK WARRIOR';
        return 'HEALTH STREAK';
    }
  }

  List<Color> _getThemeGradient(ShareCardTheme theme, int streak) {
    switch (theme) {
      case ShareCardTheme.godMode:
        return [const Color(0xFFFF3D00), const Color(0xFFFFD700)]; // Fire
      case ShareCardTheme.flowState:
        return [const Color(0xFF00E5FF), const Color(0xFF7C4DFF)]; // Cyan-Purple
      case ShareCardTheme.deepSleep:
        return [const Color(0xFF5C6BC0), const Color(0xFF1A237E)]; // Midnight
      case ShareCardTheme.defaultTheme:
        if (streak >= 365) return [const Color(0xFFFFD700), const Color(0xFFFFA500)];
        if (streak >= 100) return [const Color(0xFFE040FB), const Color(0xFF7C4DFF)];
        if (streak >= 30) return [const Color(0xFF00E5FF), const Color(0xFF00B0FF)];
        if (streak >= 14) return [const Color(0xFF69FF47), const Color(0xFF00E676)];
        if (streak >= 7) return [const Color(0xFFFF6D00), const Color(0xFFFF3D00)];
        return [const Color(0xFFCDFF00), const Color(0xFF76FF03)];
    }
  }

  String _getThemeTagline(ShareCardTheme theme) {
    switch (theme) {
      case ShareCardTheme.godMode:
        return 'Unstoppable momentum. Biohacking limits.';
      case ShareCardTheme.flowState:
        return 'Locked in. Cognitive optimization achieved.';
      case ShareCardTheme.deepSleep:
        return 'Recovery engineered. Circadian rhythm locked.';
      case ShareCardTheme.defaultTheme:
        return 'Consistency is the ultimate competitive advantage.';
    }
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: color.withValues(alpha: 0.2), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 8,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTypography.headlineMedium.copyWith(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _DotGridPainterWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _DotGridPainter());
  }
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeCap = StrokeCap.round;

    const spacing = 20.0;
    const dotRadius = 1.2;

    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter old) => false;
}

// ══════════════════════════════════════════════
// ADHERENCE SHARE CARD — for biohacking content
// ══════════════════════════════════════════════
class ShareAdherenceCard extends StatelessWidget {
  final double adherencePct;
  final int streak;
  final String topMed;

  const ShareAdherenceCard({
    super.key,
    required this.adherencePct,
    required this.streak,
    this.topMed = '',
  });

  static Future<void> share(
    BuildContext context, {
    required double adherencePct,
    required int streak,
    String topMed = '',
  }) async {
    final GlobalKey key = GlobalKey();
    final entry = OverlayEntry(
      builder: (_) => Positioned(
        left: -9999,
        top: -9999,
        child: RepaintBoundary(
          key: key,
          child: Material(
            color: Colors.transparent,
            child: ShareAdherenceCard(
              adherencePct: adherencePct,
              streak: streak,
              topMed: topMed,
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(entry);
    await Future.delayed(const Duration(milliseconds: 400));

    try {
      final boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        entry.remove();
        return;
      }
      final image = await boundary.toImage(pixelRatio: 3.0);
      final bytes =
          (await image.toByteData(format: ui.ImageByteFormat.png))!
              .buffer
              .asUint8List();
      final dir = await getTemporaryDirectory();
      final f = File('${dir.path}/med_ai_score.png');
      await f.writeAsBytes(bytes);
      entry.remove();
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(f.path)],
          text:
              '📊 My Med AI health score: ${(adherencePct * 100).round()}%\n🔥 $streak-day streak\n\n#MedAI #Biohacking #Health',
        ),
      );
    } catch (_) {
      entry.remove();
    }
  }

  @override
  Widget build(BuildContext context) {
    final score = (adherencePct * 100).round();
    final isOptimal = adherencePct >= 0.9;

    return Container(
      width: 360,
      height: 400,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isOptimal
              ? const Color(0xFF10B981).withValues(alpha: 0.4)
              : const Color(0xFFF59E0B).withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Image.asset('assets/images/app_logo.png',
                      width: 24, height: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Med AI',
                    style: AppTypography.labelLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'HEALTH REPORT',
                    style: AppTypography.labelSmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.4),
                      letterSpacing: 2,
                      fontSize: 8,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                '$score',
                style: AppTypography.displayXL.copyWith(
                  color: isOptimal
                      ? const Color(0xFF10B981)
                      : const Color(0xFFF59E0B),
                  fontSize: 80,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -4,
                  height: 1,
                ),
              ),
              Text(
                'ADHERENCE SCORE',
                style: AppTypography.labelSmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.4),
                  letterSpacing: 3,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 20),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: adherencePct.clamp(0.0, 1.0),
                  backgroundColor:
                      Colors.white.withValues(alpha: 0.06),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isOptimal
                        ? const Color(0xFF10B981)
                        : const Color(0xFFF59E0B),
                  ),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text(
                    '🔥 $streak-day streak',
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (topMed.isNotEmpty) ...[
                    const SizedBox(width: 16),
                    Text(
                      '💊 $topMed',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
