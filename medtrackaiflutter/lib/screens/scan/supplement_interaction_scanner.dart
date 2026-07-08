import 'package:permission_handler/permission_handler.dart';
import '../../widgets/common/permission_soft_prompt.dart';
import 'package:medai/widgets/common/premium_shimmer.dart';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:path/path.dart' as p;

import '../../theme/med_ai_ui.dart';
import '../../core/utils/haptic_engine.dart';
import '../../widgets/common/animated_pressable.dart';
import '../../services/gemini_service.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../screens/paywall/premium_paywall_overlay.dart';
import '../../services/remote_config_service.dart';
import 'widgets/scan_result_detail_view.dart';
import 'package:go_router/go_router.dart';
import '../../app/app_routes.dart';

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

    // Same free-tier scan fence as the pill scanner — without this, the
    // supplement scanner was an unmetered bypass around the scan limit.
    final gateState = context.read<AppState>();
    if (!gateState.isPremium &&
        (gateState.profile?.scansUsed ?? 0) >=
            RemoteConfigService.freeTierScanLimit) {
      HapticEngine.light();
      await PremiumPaywallOverlay.show(context, triggerSource: 'scan_limit');
      return;
    }

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
          // Count against the free-tier scan allowance.
          state.incrementScanCount();
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
            'Camera unavailable',
            style: AppTypography.labelSmall.copyWith(
              color: L.error,
              letterSpacing: 0.1,
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
                Semantics(
                  button: true,
                  label: 'Close',
                  child: AnimatedPressable(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: MedAiA11y.minTapTarget,
                      height: MedAiA11y.minTapTarget,
                      decoration: BoxDecoration(
                        color: L.card.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: L.border.withValues(alpha: 0.2)),
                      ),
                      child: Icon(Icons.close_rounded, color: L.text, size: 20),
                    ),
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
                        'Synergy scanner',
                        style: AppTypography.labelSmall.copyWith(
                          color: L.text,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.1,
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
                      _isScanning ? 'Analyzing stack…' : 'Align bottles in frame',
                      style: AppTypography.labelMedium.copyWith(
                        color: context.L.text,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ).animate().fadeIn(),
                  
                  const SizedBox(height: 24),
                  
                  Semantics(
                    button: true,
                    label: _isScanning ? 'Analyzing' : 'Capture scan',
                    child: AnimatedPressable(
                      onTap: _captureAndScan,
                      scaleFactor: 0.92,
                      child: Container(
                        width: MedAiA11y.minTapTarget + 32,
                        height: MedAiA11y.minTapTarget + 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _isScanning
                                ? AppColors.accent
                                : context.L.text,
                            width: 4,
                          ),
                          boxShadow: _isScanning
                              ? AppShadows.glow(AppColors.accent, intensity: 0.5)
                              : [],
                          color: _isScanning
                              ? AppColors.accent.withValues(alpha: 0.2)
                              : Colors.transparent,
                        ),
                        child: Center(
                          child: AnimatedContainer(
                            duration: 300.ms,
                            width: _isScanning ? 32 : 64,
                            height: _isScanning ? 32 : 64,
                            decoration: BoxDecoration(
                              shape: _isScanning
                                  ? BoxShape.rectangle
                                  : BoxShape.circle,
                              borderRadius: _isScanning
                                  ? BorderRadius.circular(8)
                                  : BorderRadius.circular(32),
                              color: _isScanning
                                  ? AppColors.accent
                                  : context.L.text,
                            ),
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
              child: Container(
                color: L.bg.withValues(alpha: 0.94),
                child: SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                    child: ScanResultDetailView(
                      result: _scanResult!,
                      onDark: false,
                      onClose: () => setState(() {
                        _showAnalysis = false;
                        _scanResult = null;
                      }),
                      onScanAnother: () => setState(() {
                        _showAnalysis = false;
                        _scanResult = null;
                      }),
                      onAddToMedicines: () async {
                        HapticEngine.success();
                        final sr = _scanResult!;
                        final newMed = Medicine(
                          id: DateTime.now().millisecondsSinceEpoch,
                          name: sr.name.isNotEmpty ? sr.name : 'Supplement stack',
                          brand: sr.brand,
                          genericName: sr.genericName,
                          dose: sr.dose,
                          form: sr.form,
                          category: sr.category.isNotEmpty ? sr.category : 'Supplement',
                          notes: sr.description,
                          intakeInstructions: sr.howToTake,
                          courseStartDate:
                              DateTime.now().toIso8601String().substring(0, 10),
                          color: '#8B5CF6',
                        );
                        final appState = context.read<AppState>();
                        if (!appState.canAddMedicine) {
                          await PremiumPaywallOverlay.show(context,
                              triggerSource: 'unlimited_meds');
                          return;
                        }
                        await appState.addMedicine(newMed);
                        if (!context.mounted) return;
                        context.push(AppRoutes.medicineDetailPath(newMed.id, edit: true));
                      },
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
