import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/med_ai_ui.dart';

class AiScannerViewfinder extends StatefulWidget {
  const AiScannerViewfinder({super.key});

  @override
  State<AiScannerViewfinder> createState() => _AiScannerViewfinderState();
}

class _AiScannerViewfinderState extends State<AiScannerViewfinder>
    with SingleTickerProviderStateMixin {
  late AnimationController _laserController;
  late Animation<double> _laserAnimation;

  final List<String> _statusTexts = [
    "Scanning label...",
    "Extracting dosage...",
    "Analyzing interactions...",
    "Medication identified."
  ];

  int _statusIndex = 0;

  @override
  void initState() {
    super.initState();
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _laserAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _laserController, curve: Curves.easeInOutSine),
    );

    _cycleStatusText();
  }

  void _cycleStatusText() async {
    for (int i = 0; i < _statusTexts.length; i++) {
      if (!mounted) return;
      setState(() => _statusIndex = i);
      await Future.delayed(const Duration(milliseconds: 2500));
    }
    // Simulate finishing scan
    if (mounted) {
      Navigator.of(context).pop(_statusTexts.last); // or push next screen
    }
  }

  @override
  void dispose() {
    _laserController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.white),
          tooltip: 'Close scanner',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          // Simulated Camera Feed (Blurred Background)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/bottle_mockup.png'), // Fallback or placeholder
                  fit: BoxFit.cover,
                ),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                child: Container(color: Colors.black.withValues(alpha: 0.1)),
              ),
            ),
          ),
          
          // Dark Overlay with Cut-out
          Positioned.fill(
            child: CustomPaint(
              painter: _ScannerOverlayPainter(),
            ),
          ),

          // Scanner Cutout Area Content
          Center(
            child: SizedBox(
              width: 280,
              height: 400,
              child: Stack(
                children: [
                  // Laser Line
                  AnimatedBuilder(
                    animation: _laserAnimation,
                    builder: (context, child) {
                      return Positioned(
                        top: _laserAnimation.value * 380, // Height minus laser thickness
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: L.accent,
                            boxShadow: [
                              BoxShadow(
                                color: L.accent.withValues(alpha: 0.8),
                                blurRadius: 12,
                                spreadRadius: 2,
                              )
                            ],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    },
                  ),
                  
                  // Scanning Corners
                  _buildCorner(Alignment.topLeft),
                  _buildCorner(Alignment.topRight),
                  _buildCorner(Alignment.bottomLeft),
                  _buildCorner(Alignment.bottomRight),
                ],
              ),
            ),
          ),

          // Status Text (Crossfading)
          Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 800),
                child: MedAiGlass(
                  key: ValueKey<int>(_statusIndex),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  radius: 30,
                  child: Text(
                    _statusTexts[_statusIndex],
                    style: AppTypography.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorner(Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          border: Border(
            top: alignment.y < 0 ? const BorderSide(color: Colors.white, width: 3) : BorderSide.none,
            bottom: alignment.y > 0 ? const BorderSide(color: Colors.white, width: 3) : BorderSide.none,
            left: alignment.x < 0 ? const BorderSide(color: Colors.white, width: 3) : BorderSide.none,
            right: alignment.x > 0 ? const BorderSide(color: Colors.white, width: 3) : BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    final cutOutRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: 280,
      height: 400,
    );

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(cutOutRect, const Radius.circular(24)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
