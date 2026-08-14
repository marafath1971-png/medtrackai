import 'package:permission_handler/permission_handler.dart';
import '../../widgets/common/permission_soft_prompt.dart';
import '../../widgets/common/premium_shimmer.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import 'package:go_router/go_router.dart';
import '../../app/app_routes.dart';
import '../../theme/med_ai_ui.dart';
import '../../core/utils/haptic_engine.dart';
import '../../core/utils/scan_safety_mapper.dart';
import '../../widgets/common/animated_pressable.dart';
import '../../services/gemini_service.dart';
import '../../providers/app_state.dart';
import '../../screens/paywall/premium_paywall_overlay.dart';
import '../../services/remote_config_service.dart';
import '../../widgets/modals/scan_success_sheet.dart';
import 'widgets/scan_result_detail_view.dart';

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
  File? _capturedImage;
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
    if (!mounted) return;
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

    // Free-tier gate (blueprint §5): the scan limit is the primary paywall
    // fence. Limit is Remote-Config-driven so it can be experimented on.
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
    if (!MedAiA11y.reducedMotion(context)) {
      _beamCtrl.repeat();
    }

    try {
      final XFile image = await _controller!.takePicture();
      final file = File(image.path);
      final compressedFile = await _compressImage(file) ?? file;
      
      if (!mounted) return;
      final state = context.read<AppState>();
      setState(() => _capturedImage = compressedFile);
      final result = await GeminiService.scanMedicine(
        compressedFile,
        hint:
            'This is a single loose pill. Identify its generic name, brand name, dosage strength, shape, color, and any visible imprint codes. Return structured data.',
        profile: state.profile,
      );

      result.fold(
        (success) {
          if (!mounted) return;
          // Count the successful scan against the free-tier allowance.
          state.incrementScanCount();
          HapticEngine.successScan();
          _beamCtrl.stop();
          setState(() {
            _scanResult = success;
            _showAnalysis = true;
            _isScanning = false;
          });
        },
        (failure) {
          if (!mounted) return;
          HapticEngine.selection();
          _beamCtrl.stop();
          setState(() {
            _errorMessage = 'Could not identify pill. Try better lighting.';
            _isScanning = false;
          });
        },
      );
    } catch (e) {
      if (!mounted) return;
      HapticEngine.selection();
      _beamCtrl.stop();
      setState(() {
        _errorMessage = 'Camera error. Please try again.';
        _isScanning = false;
      });
    } finally {
      if (mounted && _isScanning) {
        _beamCtrl.stop();
        setState(() => _isScanning = false);
      }
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
                'Camera Unavailable',
                style: AppTypography.labelMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w700,
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

    final preview = _controller?.value.previewSize;
    if (preview == null) {
      return SizedBox.expand(
        child: Container(
          color: const Color(0xFF0A0A0A),
          child: const Center(
            child: ContextualLoader(
              message: 'Starting camera...',
              isDark: true,
            ),
          ),
        ),
      );
    }

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: preview.height,
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

          // ── Minimal vignette
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.85,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.45),
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
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    children: [
                      Semantics(
                        button: true,
                        label: 'Close',
                        child: AnimatedPressable(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.35),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.12),
                                width: 0.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pill Identifier',
                              style: AppTypography.headlineMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                                fontSize: 24,
                              ),
                            ),
                            Text(
                              'Shape, color & imprint',
                              style: AppTypography.bodySmall.copyWith(
                                color: Colors.white.withValues(alpha: 0.72),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
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
                        color: AppColors.red.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: AppColors.red.withValues(alpha: 0.5),
                            width: 0.8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_rounded,
                              color: AppColors.red, size: 18),
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
                        ? 'Analyzing Pill…'
                        : 'Place a Single Pill in the Frame',
                    style: AppTypography.titleMedium.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Shape · Color · Imprint',
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w500,
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
                              ? AppColors.sageGreen
                              : Colors.white.withValues(alpha: 0.8),
                          width: 3,
                        ),
                      ),
                      child: Center(
                        child: AnimatedContainer(
                          duration: 200.ms,
                          width: _isScanning ? 32 : 58,
                          height: _isScanning ? 32 : 58,
                          decoration: BoxDecoration(
                            shape: _isScanning
                                ? BoxShape.rectangle
                                : BoxShape.circle,
                            borderRadius: _isScanning
                                ? BorderRadius.circular(8)
                                : null,
                            color: _isScanning ? AppColors.sageGreen : Colors.white,
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
              capturedImage: _capturedImage,
              onScanAnother: () async {
                setState(() {
                  _showAnalysis = false;
                  _scanResult = null;
                  _capturedImage = null;
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
    const strokeW = 2.0;
    final col = isScanning
        ? AppColors.sageGreen
        : Colors.white.withValues(alpha: 0.65);

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
                          AppColors.sageGreen.withValues(alpha: 0.0),
                          AppColors.sageGreen.withValues(alpha: 0.85),
                          AppColors.sageGreen.withValues(alpha: 0.0),
                        ],
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
// Pill Result Overlay — full detail sheet
// ──────────────────────────────────────────────
class _PillResultOverlay extends StatelessWidget {
  final ScanResult scanResult;
  final File? capturedImage;
  final VoidCallback onScanAnother;

  const _PillResultOverlay({
    required this.scanResult,
    required this.onScanAnother,
    this.capturedImage,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final botPad = MediaQuery.paddingOf(context).bottom;
    return Positioned.fill(
      child: Container(
        color: L.bg,
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.gutter,
                  AppSpacing.p12,
                  AppSpacing.gutter,
                  botPad + 120,
                ),
                child: ScanResultDetailView(
                  result: scanResult,
                  capturedImage: capturedImage,
                  onDark: false,
                  showInlineActions: false,
                  onClose: onScanAnother,
                  onScanAnother: onScanAnother,
                  onAddToMedicines: () => _addToMedicines(context),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.gutter,
                    AppSpacing.p12,
                    AppSpacing.gutter,
                    botPad + AppSpacing.p16,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        L.bg.withValues(alpha: 0),
                        L.bg.withValues(alpha: 0.92),
                        L.bg,
                      ],
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: L.card,
                      borderRadius:
                          BorderRadius.circular(AppRadius.squircle),
                      border: Border.all(
                        color: L.border.withValues(alpha: 0.55),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Semantics(
                            button: true,
                            label: 'Track medicine',
                            child: AnimatedPressable(
                              onTap: () => _addToMedicines(context),
                              child: Container(
                                constraints: const BoxConstraints(
                                  minHeight: MedAiA11y.minTapTarget,
                                ),
                                decoration: BoxDecoration(
                                  color: L.text,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.max),
                                ),
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.add_rounded,
                                          color: Colors.white, size: 20),
                                      const SizedBox(width: AppSpacing.p8),
                                      Text(
                                        'Track medicine',
                                        style: AppTypography.labelMedium
                                            .copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Semantics(
                          button: true,
                          label: 'Scan another',
                          child: AnimatedPressable(
                            onTap: onScanAnother,
                            child: Container(
                              width: MedAiA11y.minTapTarget,
                              height: MedAiA11y.minTapTarget,
                              decoration: const BoxDecoration(
                                color: AppColors.pastelMint,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.qr_code_scanner_rounded,
                                  color: L.text, size: 22),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addToMedicines(BuildContext context) async {
    HapticEngine.selection();
    final appState = context.read<AppState>();
    final sr = scanResult;
    final name = sr.name.isNotEmpty ? sr.name : 'Identified Pill';

    var schedule = sr.scheduleSlots.map((slot) {
      return ScheduleEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString() +
            slot['label'].toString(),
        h: (slot['h'] as num?)?.toInt() ?? 8,
        m: (slot['m'] as num?)?.toInt() ?? 0,
        label: slot['label']?.toString() ?? 'Dose',
        days: const [0, 1, 2, 3, 4, 5, 6],
        enabled: true,
        ritual: sr.withFood ? Ritual.withBreakfast : Ritual.none,
      );
    }).toList();

    // Home only shows scheduled doses — never leave an empty schedule.
    if (schedule.isEmpty) {
      schedule = [
        ScheduleEntry(
          id: 'scan_${DateTime.now().millisecondsSinceEpoch}',
          h: 8,
          m: 0,
          label: 'Morning Dose',
          days: const [0, 1, 2, 3, 4, 5, 6],
          enabled: true,
          ritual: sr.withFood ? Ritual.withBreakfast : Ritual.none,
        ),
      ];
    }

    final halalSafe = sr.halalStatus == 'halal' ||
        sr.halalStatus == 'unknown' ||
        sr.halalStatus.isEmpty;

    final newMed = Medicine(
      id: DateTime.now().millisecondsSinceEpoch,
      name: name,
      brand: sr.brand,
      genericName: sr.genericName,
      din: sr.din,
      dose: sr.dose.isNotEmpty ? sr.dose : sr.dosePerTake,
      form: sr.form.isNotEmpty ? sr.form : 'tablet',
      category: sr.category.isNotEmpty ? sr.category : 'General',
      notes: sr.description.isNotEmpty
          ? sr.description
          : 'Identified by AI Pill Scanner',
      intakeInstructions: [
        if (sr.howToTake.isNotEmpty) sr.howToTake,
        if (sr.whenToTake.isNotEmpty) sr.whenToTake,
        if (sr.storage.isNotEmpty) 'Storage: ${sr.storage}',
      ].join('\n'),
      schedule: schedule,
      courseStartDate: DateTime.now().toIso8601String().substring(0, 10),
      courseDurationDays: sr.courseDurationDays,
      count: sr.pillCount > 0 ? sr.pillCount : 30,
      totalCount: sr.packSize > 0 ? sr.packSize : 30,
      refillAt: sr.refillAlert > 0 ? sr.refillAlert : 7,
      unit: sr.unit,
      isSachet: sr.isSachet,
      isHalalSafe: halalSafe,
      isHalalCertified: sr.halalStatus == 'halal' ? true : null,
      imageUrl: capturedImage?.path ?? sr.imageUrl,
      color: '#10B981',
      aiSafetyProfile: safetyProfileFromScan(sr),
    );

    if (!appState.canAddMedicine) {
      await PremiumPaywallOverlay.show(context,
          triggerSource: 'unlimited_meds');
      return;
    }
    await appState.addMedicine(newMed);
    if (!context.mounted) return;

    appState.showToast("You're set — ${newMed.name} is tracking");

    final next = await ScanSuccessSheet.show(context, med: newMed);
    if (!context.mounted) return;

    if (next == 'detail') {
      appState.setPendingDetailMedId(newMed.id);
    } else {
      appState.clearPendingDetailMedId();
    }

    // Leave scanner stack — Home dose list shows the new reminder today.
    context.go(AppRoutes.home);
  }
}
