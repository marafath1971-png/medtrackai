import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../services/growth_tracker.dart';
import '../../theme/app_theme.dart';

// ══════════════════════════════════════════════
// RARITY STREAK PLAYER CARDS
// Bronze · Silver · Gold · Holo
// ══════════════════════════════════════════════

enum ShareCardTier { bronze, silver, gold, holo }

class ShareCardData {
  final ShareCardTier tier;
  final int streakNumber;
  final String label;
  final Color adherenceColor;
  final String userName;
  final double adherencePct;
  final int totalDoses;

  ShareCardData({
    required this.tier,
    required this.streakNumber,
    required this.label,
    required this.adherenceColor,
    required this.userName,
    required this.adherencePct,
    required this.totalDoses,
  });

  factory ShareCardData.fromStreak({
    required int streak,
    required String userName,
    required double adherencePct,
    required int totalDoses,
  }) {
    ShareCardTier tier;
    String label;
    Color color;

    if (streak >= 365) {
      tier = ShareCardTier.holo;
      label = 'Holo · 365 days';
      color = const Color(0xFFD4B8FF); // Soft violet
    } else if (streak >= 100) {
      tier = ShareCardTier.gold;
      label = 'Gold · 100 days';
      color = const Color(0xFFE8B84B); // Gold/Amber
    } else if (streak >= 30) {
      tier = ShareCardTier.silver;
      label = 'Silver · 30 days';
      color = const Color(0xFFB8BCC4); // Silver
    } else {
      tier = ShareCardTier.bronze;
      label = 'Bronze · 7 days';
      color = const Color(0xFFC97B4A); // Bronze/Coral
    }

    return ShareCardData(
      tier: tier,
      streakNumber: streak,
      label: label,
      adherenceColor: color,
      userName: userName,
      adherencePct: adherencePct,
      totalDoses: totalDoses,
    );
  }
}

class ShareMilestoneCard extends StatefulWidget {
  final ShareCardData data;

  const ShareMilestoneCard({super.key, required this.data});

  static Future<void> share(
    BuildContext context,
    int streak, {
    double adherencePct = 0.95,
    String userName = 'User',
    int totalDosesTaken = 0,
  }) async {
    final cardData = ShareCardData.fromStreak(
      streak: streak,
      userName: userName,
      adherencePct: adherencePct,
      totalDoses: totalDosesTaken > 0 ? totalDosesTaken : streak * 2,
    );

    // Track share milestone funnel
    await GrowthTracker.trackShare('milestone');
    await GrowthTracker.trackShare('view_card');

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
            child: ShareMilestoneCard(data: cardData),
          ),
        ),
      ),
    );
    if (!context.mounted) return;
    Overlay.of(context).insert(overlay);
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      final boundary = boundaryKey.currentContext
          ?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        overlay.remove();
        return;
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/medai_streak_$streak.png');
      await file.writeAsBytes(bytes);

      overlay.remove();

      // Track share sheet opened
      await GrowthTracker.trackShare('open_sheet');

      // ignore: deprecated_member_use
      await Share.shareXFiles(
        [XFile(file.path)],
        text: '🔥 My $streak-day medication streak! Adherence: ${(adherencePct * 100).round()}%.\n\nTracked with MedAI 💊',
      );
    } catch (e) {
      overlay.remove();
      debugPrint('ShareCard error: $e');
    }
  }

  @override
  State<ShareMilestoneCard> createState() => _ShareMilestoneCardState();
}

class _ShareMilestoneCardState extends State<ShareMilestoneCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    if (widget.data.tier == ShareCardTier.holo) {
      _shimmerCtrl.repeat();
    }
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final int score = (data.adherencePct * 100).round();
    
    // Theme Colors matching mockups
    Color accentColor = data.adherenceColor;
    BoxBorder borderTreatment;
    
    switch (data.tier) {
      case ShareCardTier.bronze:
        borderTreatment = Border.all(color: Colors.white.withValues(alpha: 0.06), width: 0.8);
        break;
      case ShareCardTier.silver:
        borderTreatment = Border.all(color: Colors.white.withValues(alpha: 0.06), width: 0.8);
        break;
      case ShareCardTier.gold:
        borderTreatment = Border.all(color: const Color(0xFFFFC107).withValues(alpha: 0.25), width: 1.0);
        break;
      case ShareCardTier.holo:
        borderTreatment = Border.all(color: const Color(0xFFD4B8FF).withValues(alpha: 0.35), width: 1.2);
        break;
    }

    final cardContent = Container(
      width: 320,
      height: 568, // 9:16 aspect ratio roughly (fits Instagram/TikTok stories)
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(28),
        border: borderTreatment,
        boxShadow: [
          if (data.tier == ShareCardTier.gold || data.tier == ShareCardTier.holo)
            BoxShadow(
              color: accentColor.withValues(alpha: 0.15),
              blurRadius: 40,
              spreadRadius: -5,
              offset: const Offset(0, 10),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(27),
        child: Stack(
          children: [
            // Ambient flat circles for Holo tier background (as placeholder + shimmering overlay)
            if (data.tier == ShareCardTier.holo) ...[
              // Top-right soft purple circle
              Positioned(
                top: -30,
                right: -30,
                child: ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFA78BFA).withValues(alpha: 0.15),
                    ),
                  ),
                ),
              ),
              // Bottom-left soft pink circle
              Positioned(
                bottom: 20,
                left: -20,
                child: ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFF0729E).withValues(alpha: 0.15),
                    ),
                  ),
                ),
              ),
            ],

            // Dot grid overlay for high-tech biohacking feel
            Positioned.fill(child: _DotGridPainterWidget()),

            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        data.label.toUpperCase(),
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Icon(
                        Icons.medication_rounded,
                        color: data.tier == ShareCardTier.bronze || data.tier == ShareCardTier.silver
                            ? const Color(0xFF5F5E5A)
                            : accentColor,
                        size: 18,
                      ),
                    ],
                  ),

                  // Streak Number Display
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${data.streakNumber}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 84,
                          fontWeight: FontWeight.bold,
                          height: 1.0,
                          letterSpacing: -3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'day streak',
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),

                  // User Adherence Row
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.userName.isNotEmpty ? data.userName : 'Alex',
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$score% adherence',
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    // Apply shimmering linear gradient wrapper for Holo tier
    if (data.tier == ShareCardTier.holo) {
      return AnimatedBuilder(
        animation: _shimmerCtrl,
        builder: (context, child) {
          return ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (bounds) {
              return LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: [
                  0.0,
                  (_shimmerCtrl.value - 0.2).clamp(0.0, 1.0),
                  _shimmerCtrl.value,
                  (_shimmerCtrl.value + 0.2).clamp(0.0, 1.0),
                  1.0,
                ],
                colors: const [
                  Color(0xFFD4B8FF), // Purple
                  Color(0xFFFBBF24), // Gold
                  Color(0xFFF0729E), // Pink
                  Color(0xFF60A5FA), // Blue
                  Color(0xFFD4B8FF), // Purple
                ],
              ).createShader(bounds);
            },
            child: cardContent,
          );
        },
      );
    }

    return cardContent;
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
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeCap = StrokeCap.round;

    const spacing = 16.0;
    const dotRadius = 1.0;

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
    await Future.delayed(const Duration(milliseconds: 500));

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
      final f = File('${dir.path}/medai_adherence.png');
      await f.writeAsBytes(bytes);
      entry.remove();
      
      // Track share sheet opened
      await GrowthTracker.trackShare('open_sheet');

      // ignore: deprecated_member_use
      await Share.shareXFiles(
        [XFile(f.path)],
        text: '📊 My Med AI health score: ${(adherencePct * 100).round()}%\n🔥 $streak-day streak\n\n#MedAI #Biohacking #Health',
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
      width: 320,
      height: 400,
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isOptimal
              ? AppColors.green.withValues(alpha: 0.4)
              : AppColors.amber.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(27),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Med AI',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'HEALTH REPORT',
                    style: TextStyle(
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
                style: TextStyle(
                  color: isOptimal
                      ? AppColors.green
                      : AppColors.amber,
                  fontSize: 72,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -3,
                  height: 1.0,
                ),
              ),
              const Text(
                'ADHERENCE SCORE',
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  letterSpacing: 2.5,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
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
                        ? AppColors.green
                        : AppColors.amber,
                  ),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text(
                    '🔥 $streak-day streak',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  if (topMed.isNotEmpty) ...[
                    const SizedBox(width: 16),
                    Text(
                      '💊 $topMed',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 13,
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
