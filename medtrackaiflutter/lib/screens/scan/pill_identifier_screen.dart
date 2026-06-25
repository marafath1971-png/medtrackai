import 'package:permission_handler/permission_handler.dart';
import '../../widgets/common/permission_soft_prompt.dart';
import '../../widgets/common/premium_shimmer.dart';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import '../../theme/app_theme.dart';
import '../../core/utils/haptic_engine.dart';
import '../../widgets/shared/shared_widgets.dart';
import '../../services/gemini_service.dart';
import '../../providers/app_state.dart';
import '../medicine/medicine_detail_screen.dart';

// ══════════════════════════════════════════════
// PILL IDENTIFIER SCANNER — Cal AI Style
// Scan a single loose pill to identify by shape, color, and imprint
// ══════════════════════════════════════════════

class PillIdentifierScanner extends StatefulWidget {
  const PillIdentifierScanner({super.key});

  @override
  State<PillIdentifierScanner> createState() => _PillIdentifierScannerState();
}

class _PillIdentifierScannerState extends State<PillIdentifierScanner>
    with TickerProviderStateMixin {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _cameraError = false;

  bool _isScanning = false;
  bool _showAnalysis = false;

  ScanResult? _scanResult;
  String _errorMessage = '';

  late AnimationController _beamCtrl;

  @override
  void initState() {
    super.initState();
    _beamCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _initCamera();
  }

  Future<void> _initCamera() async {
    await PermissionSoftPrompt.show(
      context: context,
      title: 'Camera Access',
      explanation: 'We need your camera to identify pills and medications accurately.',
      icon: Icons.camera_alt_rounded,
      buttonText: 'Enable Camera',
      permission: Permission.camera,
      fallbackExplanation: 'Camera permission is required to identify pills. Please enable it in Settings.',
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

  Future<void> _resetCamera() async {
    await _controller?.dispose();
    _controller = null;
    setState(() => _isCameraInitialized = false);
    await _initCamera();
  }

  @override
  void dispose() {
    _beamCtrl.dispose();
    _controller?.dispose();
    super.dispose();
  }

  Future<File?> _compressImage(File file) async {
    final tempDir = await path_provider.getTemporaryDirectory();
    final targetPath = p.join(
        tempDir.path, "${DateTime.now().millisecondsSinceEpoch}_pill_comp.jpg");
    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 85,
      minWidth: 1200,
      minHeight: 1200,
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
    _beamCtrl.repeat();

    try {
      final XFile image = await _controller!.takePicture();
      final file = File(image.path);
      final compressedFile = await _compressImage(file) ?? file;
      
      if (!mounted) return;
      final state = context.read<AppState>();
      final result = await GeminiService.scanMedicine(
        compressedFile,
        hint:
            'This is a single loose pill. Identify its generic name, brand name, dosage strength, shape, color, and any visible imprint codes. Return structured data.',
        profile: state.profile,
      );

      result.fold(
        (success) {
          if (!mounted) return;
          HapticEngine.successScan();
          _beamCtrl.stop();
          setState(() {
            _scanResult = success;
            _showAnalysis = true;
            _isScanning = false;
          });
        },
        (failure) {
          HapticEngine.selection();
          _beamCtrl.stop();
          setState(() {
            _errorMessage = 'Could not identify pill. Try better lighting.';
            _isScanning = false;
          });
        },
      );
    } catch (e) {
      HapticEngine.selection();
      _beamCtrl.stop();
      setState(() {
        _errorMessage = 'Camera error. Please try again.';
        _isScanning = false;
      });
    }
  }

  Widget _buildCameraFeed() {
    if (_cameraError) {
      return Container(
        color: const Color(0xFF0A0A0A),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.no_photography_rounded,
                  color: Colors.white.withValues(alpha: 0.3), size: 48),
              const SizedBox(height: 16),
              Text(
                'Camera unavailable',
                style: AppTypography.labelSmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.5),
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isCameraInitialized || _controller == null) {
      return Container(
        color: const Color(0xFF0A0A0A),
        child: const Center(
          child: ContextualLoader(
            message: 'Initializing camera...',
            isDark: true,
          ),
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Live Camera Feed
          Positioned.fill(child: _buildCameraFeed()),

          // ── Dark vignette overlay
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.8,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.6),
                  ],
                ),
              ),
            ),
          ),

          // ── Scanning Reticle (hidden when result shown)
          if (!_showAnalysis) ...[
            Center(
              child: _ScanReticle(isScanning: _isScanning, beamCtrl: _beamCtrl),
            ),

            // ── Header
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
                        color: Colors.black.withValues(alpha: 0.55),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                            width: 0.8),
                      ),
                      child: const Icon(Icons.close_rounded,
                          color: Colors.white, size: 22),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                          width: 0.8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                  color: AppColors.accent.withValues(alpha: 0.6),
                                  blurRadius: 6)
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'PILL IDENTIFIER',
                          style: AppTypography.labelSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Bottom Controls
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 40,
              left: 20,
              right: 20,
              child: Column(
                children: [
                  if (_errorMessage.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: Colors.red.withValues(alpha: 0.5),
                            width: 0.8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_rounded,
                              color: Colors.redAccent, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage,
                              style: AppTypography.bodySmall
                                  .copyWith(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn().slideY(begin: 0.3, end: 0),
                  Text(
                    _isScanning
                        ? 'Analyzing pill...'
                        : 'Place a single pill in the frame',
                    style: AppTypography.titleMedium.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Shape • Color • Imprint',
                    style: AppTypography.labelSmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.4),
                      letterSpacing: 1.5,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Shutter button
                  AnimatedPressable(
                    onTap: _captureAndScan,
                    child: AnimatedContainer(
                      duration: 200.ms,
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _isScanning
                              ? AppColors.accent
                              : Colors.white.withValues(alpha: 0.8),
                          width: 3.5,
                        ),
                      ),
                      child: Center(
                        child: AnimatedContainer(
                          duration: 200.ms,
                          width: _isScanning ? 32 : 62,
                          height: _isScanning ? 32 : 62,
                          decoration: BoxDecoration(
                            shape: _isScanning
                                ? BoxShape.rectangle
                                : BoxShape.circle,
                            borderRadius: _isScanning
                                ? BorderRadius.circular(8)
                                : null,
                            color: _isScanning ? AppColors.accent : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ── Result Overlay
          if (_showAnalysis && _scanResult != null)
            _PillResultOverlay(
              scanResult: _scanResult!,
              onScanAnother: () async {
                setState(() {
                  _showAnalysis = false;
                  _scanResult = null;
                });
                await _resetCamera();
              },
            ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Scan Reticle
// ──────────────────────────────────────────────
class _ScanReticle extends StatelessWidget {
  final bool isScanning;
  final AnimationController beamCtrl;

  const _ScanReticle({required this.isScanning, required this.beamCtrl});

  @override
  Widget build(BuildContext context) {
    const size = 220.0;
    const cornerLen = 28.0;
    const strokeW = 2.5;
    final col = isScanning ? AppColors.accent : Colors.white.withValues(alpha: 0.7);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // Corner brackets
          CustomPaint(
            size: const Size(size, size),
            painter: _CornerPainter(color: col, len: cornerLen, width: strokeW),
          ),
          // Scan beam
          if (isScanning)
            ClipRect(
              child: AnimatedBuilder(
                animation: beamCtrl,
                builder: (_, __) => Positioned(
                  top: (size - 4) * beamCtrl.value,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.accent.withValues(alpha: 0.0),
                          AppColors.accent.withValues(alpha: 0.9),
                          AppColors.accent.withValues(alpha: 0.0),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.5),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
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

class _CornerPainter extends CustomPainter {
  final Color color;
  final double len;
  final double width;

  const _CornerPainter(
      {required this.color, required this.len, required this.width});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final r = 8.0;
    final w = size.width;
    final h = size.height;

    // TL
    canvas.drawLine(Offset(r, 0), Offset(len, 0), paint);
    canvas.drawLine(Offset(0, r), Offset(0, len), paint);
    // TR
    canvas.drawLine(Offset(w - len, 0), Offset(w - r, 0), paint);
    canvas.drawLine(Offset(w, r), Offset(w, len), paint);
    // BL
    canvas.drawLine(Offset(0, h - len), Offset(0, h - r), paint);
    canvas.drawLine(Offset(r, h), Offset(len, h), paint);
    // BR
    canvas.drawLine(Offset(w, h - len), Offset(w, h - r), paint);
    canvas.drawLine(Offset(w - len, h), Offset(w - r, h), paint);
  }

  @override
  bool shouldRepaint(_CornerPainter old) => old.color != color;
}

// ──────────────────────────────────────────────
// Pill Result Overlay — Professional Cal AI style
// ──────────────────────────────────────────────
class _PillResultOverlay extends StatefulWidget {
  final ScanResult scanResult;
  final VoidCallback onScanAnother;

  const _PillResultOverlay({
    required this.scanResult,
    required this.onScanAnother,
  });

  @override
  State<_PillResultOverlay> createState() => _PillResultOverlayState();
}

class _PillResultOverlayState extends State<_PillResultOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _scanAnimationController;

  @override
  void initState() {
    super.initState();
    _scanAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scanAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name =
        widget.scanResult.name.isNotEmpty ? widget.scanResult.name : 'Unknown Pill';

    return Positioned.fill(
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            color: Colors.black.withValues(alpha: 0.88),
            child: SafeArea(
              child: SingleChildScrollView(
  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Success badge
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: AppColors.accent.withValues(alpha: 0.4),
                              width: 0.8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                      color: AppColors.accent
                                          .withValues(alpha: 0.6),
                                      blurRadius: 6)
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'PILL IDENTIFIED',
                              style: AppTypography.labelSmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 400.ms),
                    ),

                    const SizedBox(height: 28),

                    // Pill Image with sweeping scanner animation
                    if (widget.scanResult.imageUrl != null && widget.scanResult.imageUrl!.isNotEmpty) ...[
                      Center(
                        child: Container(
                          height: 180,
                          width: 240,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.15), width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 15,
                              )
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(23),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: MedImage(
                                    imageUrl: widget.scanResult.imageUrl!,
                                    borderRadius: 0,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.black.withValues(alpha: 0.1),
                                          Colors.transparent,
                                          Colors.black.withValues(alpha: 0.4),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                // Sweeping laser line
                                Positioned.fill(
                                  child: AnimatedBuilder(
                                    animation: _scanAnimationController,
                                    builder: (context, child) {
                                      return FractionalTranslation(
                                        translation:
                                            Offset(0, _scanAnimationController.value - 0.5),
                                        child: Container(
                                          height: 3,
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                AppColors.accent.withValues(alpha: 0.0),
                                                AppColors.accent,
                                                AppColors.accent.withValues(alpha: 0.0),
                                              ],
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppColors.accent.withValues(alpha: 0.8),
                                                blurRadius: 10,
                                                spreadRadius: 2,
                                              )
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                    ],

                    // ── Medicine name
                    Text(
                      name,
                      style: AppTypography.displaySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 32,
                        letterSpacing: -1.0,
                        height: 1.1,
                      ),
                    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),

                    const SizedBox(height: 8),

                    // ── Interactions / category
                    if (widget.scanResult.interactions.isNotEmpty)
                      Text(
                        widget.scanResult.interactions,
                        style: AppTypography.bodyMedium.copyWith(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ).animate().fadeIn(delay: 150.ms),

                    const SizedBox(height: 28),

                    // ── Info grid
                    _InfoGrid(scanResult: widget.scanResult),

                    const SizedBox(height: 32),

                    // ── Side effects (if any)
                    if (widget.scanResult.sideEffects.isNotEmpty) ...[
                      _SectionLabel('Common Side Effects'),
                      const SizedBox(height: 10),
                      Text(
                        widget.scanResult.sideEffects,
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.7),
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 28),
                    ],

                    // ── Actions
                    BouncingButton(
                      onTap: () => _addToMedicines(context),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          gradient: AppGradients.accentOrange,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: AppShadows.glow(AppColors.accent,
                              intensity: 0.3),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_rounded,
                                color: Colors.white, size: 20),
                            const SizedBox(width: 10),
                            Text(
                              'Add to My Medicines',
                              style: AppTypography.labelLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),

                    const SizedBox(height: 12),

                    BouncingButton(
                      onTap: widget.onScanAnother,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                              width: 0.8),
                        ),
                        child: Center(
                          child: Text(
                            'Scan Another Pill',
                            style: AppTypography.labelLarge.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 400.ms),

                    const SizedBox(height: 16),

                    // Disclaimer
                    Text(
                      '⚠️  AI identification. Always verify with a pharmacist.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 11,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _addToMedicines(BuildContext context) async {
    HapticEngine.selection();
    final appState = context.read<AppState>();
    final name =
        widget.scanResult.name.isNotEmpty ? widget.scanResult.name : 'Identified Pill';
    final newMed = Medicine(
      id: DateTime.now().millisecondsSinceEpoch,
      name: name,
      brand: '',
      dose: '',
      form: 'Tablet',
      category: 'General',
      notes: 'Identified by AI Pill Scanner',
      schedule: const [],
      courseStartDate: DateTime.now().toIso8601String().substring(0, 10),
      color: '#FF6B35',
      count: 0,
      totalCount: 0,
      refillAt: 0,
    );
    await appState.addMedicine(newMed);
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MedicineDetailScreen(
          medId: newMed.id,
          initialEditMode: true,
          onBack: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  final ScanResult scanResult;
  const _InfoGrid({required this.scanResult});

  @override
  Widget build(BuildContext context) {
    final items = <(IconData, String, String)>[
      if (scanResult.dose.isNotEmpty)
        (Icons.medication_rounded, 'Dosage', scanResult.dose),
      if (scanResult.form.isNotEmpty)
        (Icons.category_rounded, 'Form', scanResult.form),
      if (scanResult.category.isNotEmpty)
        (Icons.class_rounded, 'Category', scanResult.category),
      if (scanResult.confidence.isNotEmpty)
        (Icons.verified_rounded, 'Confidence', scanResult.confidence),
    ];

    if (items.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: items.map((item) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.08),
                Colors.white.withValues(alpha: 0.02),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.12), width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.$1, size: 16, color: AppColors.accent),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.$2.toUpperCase(),
                    style: AppTypography.labelSmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 9.5,
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.$3,
                    style: AppTypography.labelMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.06, end: 0);
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: AppTypography.labelSmall.copyWith(
        color: Colors.white.withValues(alpha: 0.4),
        fontSize: 10,
        letterSpacing: 1.5,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}
