import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../core/utils/haptic_engine.dart';
import '../../widgets/shared/shared_widgets.dart';

// ══════════════════════════════════════════════
// HOOK E: SUPPLEMENT INTERACTION SCANNER (Viral)
// Scan 2+ bottles to see if they create a "God Stack" or a dangerous interaction
// ══════════════════════════════════════════════

class SupplementInteractionScanner extends StatefulWidget {
  const SupplementInteractionScanner({super.key});

  @override
  State<SupplementInteractionScanner> createState() => _SupplementInteractionScannerState();
}

class _SupplementInteractionScannerState extends State<SupplementInteractionScanner> {
  int _scannedItems = 0;
  bool _isScanning = false;
  bool _showAnalysis = false;

  final List<String> _scannedNames = [];

  void _simulateScan() async {
    if (_isScanning) return;
    HapticEngine.selection();
    setState(() => _isScanning = true);

    // Fake scanning delay
    await Future.delayed(const Duration(milliseconds: 1500));

    HapticEngine.medium();
    setState(() {
      _scannedItems++;
      if (_scannedItems == 1) _scannedNames.add('Ashwagandha KSM-66');
      if (_scannedItems == 2) _scannedNames.add('L-Theanine 200mg');
      _isScanning = false;
    });

    if (_scannedItems == 2) {
      // Analyze interaction
      await Future.delayed(const Duration(milliseconds: 800));
      setState(() => _showAnalysis = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Simulated Camera Viewfinder
          Positioned.fill(
            child: Container(
              color: const Color(0xFF0A0A0A), // Very dark grey
              child: Center(
                child: Text(
                  'CAMERA FEED ACTIVE',
                  style: AppTypography.labelSmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.1),
                    letterSpacing: 4,
                  ),
                ),
              ),
            ),
          ),

          // Scanning Reticle
          if (!_showAnalysis)
            Center(
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _isScanning 
                        ? AppColors.limeAccent 
                        : Colors.white.withValues(alpha: 0.3),
                    width: _isScanning ? 3 : 1,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: _isScanning
                    ? Stack(
                        children: [
                          Positioned(
                            top: 0,
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    AppColors.limeAccent.withValues(alpha: 0.0),
                                    AppColors.limeAccent.withValues(alpha: 0.2),
                                    AppColors.limeAccent.withValues(alpha: 0.0),
                                  ],
                                ),
                              ),
                            ).animate(onPlay: (c) => c.repeat()).slideY(begin: -1, end: 1, duration: 1200.ms),
                          ),
                        ],
                      )
                    : null,
              ).animate(target: _isScanning ? 1 : 0).scaleXY(end: 1.05),
            ),

          // Header
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 20,
            right: 20,
            child: Row(
              children: [
                BouncingButton(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.science_rounded, color: AppColors.limeAccent, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'SYNERGY SCANNER',
                        style: AppTypography.labelSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom Bar
          if (!_showAnalysis)
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: Column(
                children: [
                  if (_scannedItems > 0)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.limeAccent.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: AppColors.limeAccent),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${_scannedNames.join(' + ')} added to stack',
                              style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn().slideY(begin: 0.5, end: 0),
                  
                  Text(
                    _scannedItems == 0 
                        ? 'Scan your first supplement'
                        : 'Scan another to check synergy',
                    style: AppTypography.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: _simulateScan,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        color: _isScanning ? Colors.white.withValues(alpha: 0.5) : Colors.transparent,
                      ),
                      child: Center(
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isScanning ? AppColors.limeAccent : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Analysis Overlay
          if (_showAnalysis)
            Positioned.fill(
              child: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.8),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: AppGradients.cyanFlash,
                            shape: BoxShape.circle,
                            boxShadow: AppShadows.glow(const Color(0xFF00E5FF), intensity: 0.5),
                          ),
                          child: const Center(
                            child: Icon(Icons.bolt_rounded, color: Colors.white, size: 40),
                          ),
                        ).animate().scale(curve: Curves.elasticOut, duration: 800.ms),
                        
                        const SizedBox(height: 32),
                        
                        Text(
                          'GOD STACK DETECTED',
                          style: AppTypography.headlineSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ).animate().fadeIn(delay: 300.ms),
                        
                        const SizedBox(height: 16),
                        
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '${_scannedNames[0]} + ${_scannedNames[1]}',
                                style: AppTypography.titleMedium.copyWith(color: Colors.white),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Ashwagandha lowers cortisol while L-Theanine promotes alpha brain waves. Together, they create a state of relaxed, laser-focused flow without the jitters.',
                                textAlign: TextAlign.center,
                                style: AppTypography.bodyMedium.copyWith(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1, end: 0),
                        
                        const SizedBox(height: 40),
                        
                        BouncingButton(
                          onTap: () {
                            HapticEngine.selection();
                            Navigator.pop(context); // Would normally add to database here
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            decoration: BoxDecoration(
                              gradient: AppGradients.neonLime,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: AppShadows.glow(AppColors.limeAccent, intensity: 0.2),
                            ),
                            child: Center(
                              child: Text(
                                'SAVE TO MY STACKS',
                                style: AppTypography.labelLarge.copyWith(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          ),
                        ).animate().fadeIn(delay: 700.ms),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
