import 'package:permission_handler/permission_handler.dart';
import '../../widgets/common/permission_soft_prompt.dart';
import 'package:medai/widgets/common/premium_shimmer.dart';
import 'dart:io';
import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:path/path.dart' as p;

import '../../theme/app_theme.dart';
import '../../core/utils/haptic_engine.dart';
import '../../widgets/shared/shared_widgets.dart';
import '../../services/gemini_service.dart';
import '../../domain/entities/scan_result.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';

// ══════════════════════════════════════════════
// HOOK E: SUPPLEMENT INTERACTION SCANNER (Viral)
// Gen Z Premium UI / Glassmorphic OLED 
// ══════════════════════════════════════════════

class SupplementInteractionScanner extends StatefulWidget {
  const SupplementInteractionScanner({super.key});

  @override
  State<SupplementInteractionScanner> createState() => _SupplementInteractionScannerState();
}

class _SupplementInteractionScannerState extends State<SupplementInteractionScanner> with SingleTickerProviderStateMixin {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _cameraError = false;

  bool _isScanning = false;
  bool _showAnalysis = false;
  
  ScanResult? _scanResult;
  String _errorMessage = '';

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 1500)
    )..repeat(reverse: true);
    _initCamera();
  }

  Future<void> _initCamera() async {
    await PermissionSoftPrompt.show(
      context: context,
      title: 'Camera Access',
      explanation: 'We need your camera to identify supplements and check for interactions.',
      icon: Icons.camera_alt_rounded,
      buttonText: 'Enable Camera',
      permission: Permission.camera,
      fallbackExplanation: 'Camera permission is required to identify supplements. Please enable it in Settings.',
      onGranted: _setupCameraState,
      onDenied: () {
        if (mounted) setState(() => _cameraError = true);
      },
    );
  }

  Future<void> _setupCameraState() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _controller = CameraController(
          _cameras![0],
          ResolutionPreset.high,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.jpeg,
        );

        await _controller!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
            _cameraError = false;
          });
        }
      } else {
        if (mounted) setState(() => _cameraError = true);
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
      if (mounted) setState(() => _cameraError = true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  Future<File?> _compressImage(File file) async {
    final tempDir = await path_provider.getTemporaryDirectory();
    final targetPath = p.join(
        tempDir.path, "${DateTime.now().millisecondsSinceEpoch}_stack_comp.jpg");

    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 50,
      minWidth: 800,
      minHeight: 800,
    );

    return result != null ? File(result.path) : null;
  }

  Future<void> _captureAndScan() async {
    if (_isScanning) return;
    if (_controller == null || !_controller!.value.isInitialized) return;

    HapticEngine.selection();
    setState(() {
      _isScanning = true;
      _errorMessage = '';
    });

    try {
      final XFile image = await _controller!.takePicture();
      final file = File(image.path);
      final compressedFile = await _compressImage(file) ?? file;
      
      if (!mounted) return;
      final state = context.read<AppState>();
      final result = await GeminiService.scanMedicine(
        compressedFile,
        hint: 'Multiple supplements. Identify the stack and describe their synergy or interactions.',
        profile: state.profile,
      );

      result.fold(
        (success) {
          if (!mounted) return;
          HapticEngine.successScan();
          setState(() {
            _scanResult = success;
            _showAnalysis = true;
            _isScanning = false;
          });
        },
        (failure) {
          HapticEngine.selection();
          setState(() {
            _errorMessage = 'Could not analyze stack. Try again.';
            _isScanning = false;
          });
        },
      );
    } catch (e) {
      HapticEngine.selection();
      setState(() {
        _errorMessage = 'Camera error. Try again.';
        _isScanning = false;
      });
    }
  }

  Widget _buildCameraFeed() {
    final L = context.L;
    if (_cameraError) {
      return Container(
        color: L.bg,
        child: Center(
          child: Text(
            'CAMERA UNAVAILABLE ⚠️',
            style: AppTypography.labelSmall.copyWith(
              color: L.error,
              letterSpacing: 2,
            ),
          ),
        ),
      );
    }

    if (!_isCameraInitialized || _controller == null) {
      return Container(
        color: L.bg,
        child: Center(
          child: ContextualLoader(message: "Scanning interactions..."),
        ),
      );
    }

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _controller!.value.previewSize!.height,
          child: CameraPreview(_controller!),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    
    return Scaffold(
      backgroundColor: L.bg,
      body: Stack(
        children: [
          // 1. Live Camera Feed
          Positioned.fill(
            child: _buildCameraFeed(),
          ),

          // 2. Futuristic Scanning Reticle
          if (!_showAnalysis)
            Positioned.fill(
              child: SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        final pulseAlpha = _isScanning ? 0.6 + (_pulseController.value * 0.4) : 0.4;
                        return CustomPaint(
                          size: const Size(double.infinity, 250),
                          painter: _ScannerCornersPainter(
                            color: _isScanning ? AppColors.accent.withValues(alpha: pulseAlpha) : context.L.text.withValues(alpha: pulseAlpha),
                            strokeWidth: _isScanning ? 4.0 : 2.5,
                            cornerLen: 40,
                          ),
                          child: _isScanning
                              ? Stack(
                                  children: [
                                    Positioned.fill(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              AppColors.accent.withValues(alpha: 0.0),
                                              AppColors.accent.withValues(alpha: 0.3),
                                              AppColors.accent.withValues(alpha: 0.0),
                                            ],
                                          ),
                                        ),
                                      ).animate(onPlay: (c) => c.repeat()).slideY(begin: -1, end: 1, duration: 1000.ms, curve: Curves.easeInOutSine),
                                    ),
                                  ],
                                )
                              : const SizedBox(height: 250),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),

          // 3. Header
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
                      color: L.card.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                      border: Border.all(color: L.border.withValues(alpha: 0.2)),
                    ),
                    child: Icon(Icons.close_rounded, color: L.text, size: 20),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: L.card.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: L.border.withValues(alpha: 0.2)),
                    boxShadow: AppShadows.glass,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bolt_rounded, color: AppColors.accent, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'SYNERGY SCANNER',
                        style: AppTypography.labelSmall.copyWith(
                          color: L.text,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 4. Bottom Controls
          if (!_showAnalysis)
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: Column(
                children: [
                  if (_errorMessage.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: L.error.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: L.error.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        _errorMessage,
                        style: AppTypography.labelMedium.copyWith(
                          color: L.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ).animate().fadeIn().slideY(begin: 0.2, end: 0),
                  
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: context.L.bg.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _isScanning ? 'ANALYZING STACK 🧬...' : 'ALIGN BOTTLES IN FRAME 🎯',
                      style: AppTypography.labelMedium.copyWith(
                        color: context.L.text,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ).animate().fadeIn(),
                  
                  const SizedBox(height: 24),
                  
                  BouncingButton(
                    onTap: _captureAndScan,
                    scaleFactor: 0.92,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _isScanning ? AppColors.accent : context.L.text, 
                          width: 4
                        ),
                        boxShadow: _isScanning ? AppShadows.glow(AppColors.accent, intensity: 0.5) : [],
                        color: _isScanning ? AppColors.accent.withValues(alpha: 0.2) : Colors.transparent,
                      ),
                      child: Center(
                        child: AnimatedContainer(
                          duration: 300.ms,
                          width: _isScanning ? 32 : 64,
                          height: _isScanning ? 32 : 64,
                          decoration: BoxDecoration(
                            shape: _isScanning ? BoxShape.rectangle : BoxShape.circle,
                            borderRadius: _isScanning ? BorderRadius.circular(8) : BorderRadius.circular(32),
                            color: _isScanning ? AppColors.accent : context.L.text,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // 5. Gen Z Premium AI Analysis Overlay
          if (_showAnalysis && _scanResult != null)
            Positioned.fill(
              child: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                  child: Container(
                    color: L.bg.withValues(alpha: 0.88),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Floating Header Icon with pulsing shadow glow
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Container(
                              width: 88,
                              height: 88,
                              decoration: BoxDecoration(
                                color: L.card,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.accent.withValues(alpha: 0.5), width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.accent.withValues(
                                        alpha: 0.4 + (_pulseController.value * 0.3)),
                                    blurRadius: 20 + (_pulseController.value * 10),
                                    spreadRadius: 1 + (_pulseController.value * 2),
                                  )
                                ],
                              ),
                              child: const Center(
                                child: Text('⚡️', style: TextStyle(fontSize: 40)),
                              ),
                            );
                          },
                        ).animate().scale(curve: Curves.elasticOut, duration: 900.ms),
                        
                        const SizedBox(height: 24),
                        
                        // Title
                        Text(
                          'SYNERGY REPORT',
                          style: AppTypography.headlineMedium.copyWith(
                            color: L.text,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3.0,
                          ),
                        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                        
                        const SizedBox(height: 32),
                        
                        // Glassmorphic Result Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                L.card.withValues(alpha: 0.8),
                                L.card.withValues(alpha: 0.45),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: L.border.withValues(alpha: 0.15)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                _scanResult!.name.isNotEmpty ? _scanResult!.name.toUpperCase() : 'UNKNOWN STACK 🧪',
                                textAlign: TextAlign.center,
                                style: AppTypography.titleLarge.copyWith(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                  fontSize: 20,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(height: 1, color: L.border.withValues(alpha: 0.15)),
                              const SizedBox(height: 16),
                              Text(
                                _scanResult!.interactions.isNotEmpty 
                                  ? _scanResult!.interactions 
                                  : 'No specific synergy or interactions found for this combination. 🤷‍♂️',
                                textAlign: TextAlign.center,
                                style: AppTypography.bodyLarge.copyWith(
                                  color: L.text.withValues(alpha: 0.8),
                                  fontWeight: FontWeight.w600,
                                  height: 1.6,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),
                        
                        const SizedBox(height: 48),
                        
                        // Action Button
                        BouncingButton(
                          onTap: () {
                            HapticEngine.selection();
                            setState(() {
                              _showAnalysis = false;
                              _scanResult = null;
                            });
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  L.secondary,
                                  L.secondary.withValues(alpha: 0.85),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(100),
                              boxShadow: [
                                BoxShadow(
                                  color: L.secondary.withValues(alpha: 0.35),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                )
                              ]
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('📸', style: TextStyle(fontSize: 18)),
                                const SizedBox(width: 8),
                                Text(
                                  'SCAN ANOTHER',
                                  style: AppTypography.labelLarge.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ).animate().fadeIn(delay: 600.ms).scale(curve: Curves.easeOutBack),
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

// ══════════════════════════════════════════════
// VIEWFINDER CORNERS PAINTER
// ══════════════════════════════════════════════
class _ScannerCornersPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double cornerLen;

  const _ScannerCornersPainter({
    required this.color,
    required this.strokeWidth,
    this.cornerLen = 28,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const r = 24.0;
    final L = cornerLen;
    final w = size.width;
    final h = size.height;

    // Top-Left
    canvas.drawLine(const Offset(r, 0), Offset(r + L, 0), paint);
    canvas.drawLine(const Offset(0, r), Offset(0, r + L), paint);
    canvas.drawArc(const Rect.fromLTWH(0, 0, r * 2, r * 2), math.pi, math.pi / 2, false, paint);
    // Top-Right
    canvas.drawLine(Offset(w - r - L, 0), Offset(w - r, 0), paint);
    canvas.drawLine(Offset(w, r), Offset(w, r + L), paint);
    canvas.drawArc(Rect.fromLTWH(w - r * 2, 0, r * 2, r * 2), 3 * math.pi / 2, math.pi / 2, false, paint);
    // Bottom-Left
    canvas.drawLine(Offset(r, h), Offset(r + L, h), paint);
    canvas.drawLine(Offset(0, h - r - L), Offset(0, h - r), paint);
    canvas.drawArc(Rect.fromLTWH(0, h - r * 2, r * 2, r * 2), math.pi / 2, math.pi / 2, false, paint);
    // Bottom-Right
    canvas.drawLine(Offset(w - r - L, h), Offset(w - r, h), paint);
    canvas.drawLine(Offset(w, h - r - L), Offset(w, h - r), paint);
    canvas.drawArc(Rect.fromLTWH(w - r * 2, h - r * 2, r * 2, r * 2), 0, math.pi / 2, false, paint);
  }

  @override
  bool shouldRepaint(_ScannerCornersPainter old) =>
      old.color != color || old.strokeWidth != strokeWidth;
}
