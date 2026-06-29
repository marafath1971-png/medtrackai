import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../services/growth_tracker.dart';
import '../../theme/app_theme.dart';
import '../mascot_widget.dart';

// ══════════════════════════════════════════════
// RARITY STREAK PLAYER CARDS
// Shield · Star · Flame · Crown · Diamond
// ══════════════════════════════════════════════

enum ShareCardTier { shield, star, flame, crown, diamond }

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
      tier = ShareCardTier.diamond;
      label = 'Diamond · 365 Days';
      color = const Color(0xFFE0F7FA); // Ice blue / Diamond
    } else if (streak >= 100) {
      tier = ShareCardTier.crown;
      label = 'Crown · 100 Days';
      color = const Color(0xFFFFD700); // Royal Gold
    } else if (streak >= 30) {
      tier = ShareCardTier.flame;
      label = 'Flame · 30 Days';
      color = const Color(0xFFFF5722); // Flame Orange
    } else if (streak >= 14) {
      tier = ShareCardTier.star;
      label = 'Star · 14 Days';
      color = const Color(0xFF64B5F6); // Star Blue
    } else {
      tier = ShareCardTier.shield;
      label = 'Shield · 7 Days';
      color = const Color(0xFF4DB6AC); // Shield Green
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
        text: '🔥 My $streak-day medication streak! Adherence: ${(adherencePct * 100).round()}%.\n\nTracked with Medai 💊',
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
    _shimmerCtrl.repeat();
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
    Color accentColor = data.adherenceColor;
    
    // Choose mascot mood based on streak
    String mascotMood = 'content';
    if (data.streakNumber == 0) {
      mascotMood = 'sleepy';
    } else if (data.streakNumber > 0 && data.streakNumber < 30) {
      mascotMood = 'content';
    } else if (data.streakNumber >= 30 && data.streakNumber < 100) {
      mascotMood = 'energetic';
    } else {
      mascotMood = 'happy';
    }

    // Set up card background gradients & borders
    LinearGradient bgGradient;
    Border cardBorder;
    Color glowColor;

    switch (data.tier) {
      case ShareCardTier.shield:
        bgGradient = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D1413), Color(0xFF1E2F2D)],
        );
        cardBorder = Border.all(color: const Color(0xFF4DB6AC).withValues(alpha: 0.3), width: 1.2);
        glowColor = const Color(0xFF4DB6AC).withValues(alpha: 0.08);
        break;
      case ShareCardTier.star:
        bgGradient = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F1418), Color(0xFF1D262F)],
        );
        cardBorder = Border.all(color: const Color(0xFF64B5F6).withValues(alpha: 0.3), width: 1.2);
        glowColor = const Color(0xFF64B5F6).withValues(alpha: 0.08);
        break;
      case ShareCardTier.flame:
        bgGradient = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A0F0A), Color(0xFF33160D)],
        );
        cardBorder = Border.all(color: const Color(0xFFFF5722).withValues(alpha: 0.3), width: 1.4);
        glowColor = const Color(0xFFFF5722).withValues(alpha: 0.10);
        break;
      case ShareCardTier.crown:
        bgGradient = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D0B08), Color(0xFF281F0E)],
        );
        cardBorder = Border.all(color: const Color(0xFFFFCC00).withValues(alpha: 0.4), width: 1.5);
        glowColor = const Color(0xFFFFCC00).withValues(alpha: 0.12);
        break;
      case ShareCardTier.diamond:
        bgGradient = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF11171A), Color(0xFF1A262E)],
        );
        cardBorder = Border.all(color: const Color(0xFFE0F7FA).withValues(alpha: 0.5), width: 1.8);
        glowColor = const Color(0xFFE0F7FA).withValues(alpha: 0.15);
        break;
    }

    final cardContent = Container(
      width: 320,
      height: 568, // 9:16 aspect ratio
      decoration: BoxDecoration(
        gradient: bgGradient,
        borderRadius: BorderRadius.circular(32),
        border: cardBorder,
        boxShadow: [
          BoxShadow(
            color: glowColor,
            blurRadius: 40,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          children: [
            // ── Background Ambient Light Blobs ──
            if (data.tier == ShareCardTier.diamond) ...[
              Positioned(
                top: -50,
                right: -50,
                child: ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFBF5AF2).withValues(alpha: 0.25),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -30,
                left: -30,
                child: ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF00F2FE).withValues(alpha: 0.25),
                    ),
                  ),
                ),
              ),
            ] else ...[
              Positioned(
                top: -60,
                right: -60,
                child: ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accentColor.withValues(alpha: 0.15),
                    ),
                  ),
                ),
              ),
            ],

            // Dot grid overlay for futuristic feel
            Positioned.fill(child: _DotGridPainterWidget()),

            // ── Card Content ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 1. Header tag line
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'MEDAI MILESTONE // SHIELD',
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 9,
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 0.5),
                        ),
                        child: const Text(
                          '[SECURE_v2.026]',
                          style: TextStyle(
                            color: Colors.white30,
                            fontSize: 7,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // 2. Mascot Centerpiece (Concentric Ring Halo)
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer Ring Glow
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: accentColor.withValues(alpha: 0.12),
                              width: 1.0,
                            ),
                          ),
                        ),
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: accentColor.withValues(alpha: 0.2),
                              width: 2.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: accentColor.withValues(alpha: 0.08),
                                blurRadius: 16,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                        MascotWidget(size: 96, mood: mascotMood),
                      ],
                    ),
                  ),

                  // 3. Huge Streak Display
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${data.streakNumber}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 92,
                          fontWeight: FontWeight.bold,
                          height: 0.95,
                          letterSpacing: -4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: accentColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'DAY COMPLIANCE STREAK',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // 4. Biohacking Stats 2x2 Grid
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildGridItem(
                              title: 'ADHERENCE',
                              value: '$score%',
                              color: accentColor,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildGridItem(
                              title: 'TOTAL LOGS',
                              value: '${data.totalDoses} doses',
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _buildGridItem(
                              title: 'SHIELD LEVEL',
                              value: data.tier.name.toUpperCase(),
                              color: accentColor,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildGridItem(
                              title: 'STATUS',
                              value: score >= 90 ? 'OPTIMAL' : 'STABLE',
                              color: score >= 90 ? AppColors.green : AppColors.amber,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // 5. Card Footer
                  Center(
                    child: Text(
                      'JOIN THE ROUTINE AT MEDAI.APP 💊',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    // Apply shifting linear gradient overlay to whole card for Holo tier
    if (data.tier == ShareCardTier.diamond) {
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
                  (_shimmerCtrl.value - 0.25).clamp(0.0, 1.0),
                  _shimmerCtrl.value,
                  (_shimmerCtrl.value + 0.25).clamp(0.0, 1.0),
                  1.0,
                ],
                colors: const [
                  Color(0xFFBF5AF2), // Purple
                  Color(0xFF00F2FE), // Cyan
                  Color(0xFFFF2D55), // Coral Red
                  Color(0xFFFFCC00), // Gold
                  Color(0xFFBF5AF2), // Purple
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

  Widget _buildGridItem({
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.35),
              fontSize: 8,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.bold,
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
        text: '📊 My Medai health score: ${(adherencePct * 100).round()}%\n🔥 $streak-day streak\n\n#Medai #Biohacking #Health',
      );
    } catch (_) {
      entry.remove();
    }
  }

  @override
  Widget build(BuildContext context) {
    final score = (adherencePct * 100).round();
    final isOptimal = adherencePct >= 0.9;
    final accentColor = isOptimal ? AppColors.green : AppColors.amber;
    
    // Choose mascot mood based on streak
    String mascotMood = 'content';
    if (streak == 0) {
      mascotMood = 'sleepy';
    } else if (streak > 0 && streak < 30) {
      mascotMood = 'content';
    } else if (streak >= 30 && streak < 100) {
      mascotMood = 'energetic';
    } else {
      mascotMood = 'happy';
    }

    return Container(
      width: 320,
      height: 420,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B0E14), Color(0xFF181F2A)],
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.08),
            blurRadius: 40,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          children: [
            // Soft background light blob
            Positioned(
              top: -40,
              right: -40,
              child: ImageFiltered(
                imageFilter: ui.ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accentColor.withValues(alpha: 0.15),
                  ),
                ),
              ),
            ),
            
            // Dot Grid overlay
            Positioned.fill(child: _DotGridPainterWidget()),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Row
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Medai',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'HEALTH REPORT',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.3),
                          letterSpacing: 2,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),

                  // Mascot Circular Halo in Middle Left / Right
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Score Column
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$score',
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 76,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -3,
                              height: 1.0,
                            ),
                          ),
                          const Text(
                            'ADHERENCE SCORE',
                            style: TextStyle(
                              color: Color(0xFF6B7280),
                              letterSpacing: 2.0,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      // Dynamic Mascot
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: accentColor.withValues(alpha: 0.15),
                                width: 1.0,
                              ),
                            ),
                          ),
                          MascotWidget(size: 64, mood: mascotMood),
                        ],
                      ),
                    ],
                  ),

                  // Adherence Progress Bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: adherencePct.clamp(0.0, 1.0),
                          backgroundColor: Colors.white.withValues(alpha: 0.05),
                          valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '🔥 $streak-day streak',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          if (topMed.isNotEmpty)
                            Text(
                              '💊 $topMed',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.45),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),

                  // Footer
                  Center(
                    child: Text(
                      'JOIN THE ROUTINE AT MEDAI.APP 💊',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.25),
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                      ),
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
}
