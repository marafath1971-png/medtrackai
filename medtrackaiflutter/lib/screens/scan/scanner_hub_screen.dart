import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'dart:typed_data';
import 'package:flutter/rendering.dart';
import 'package:medai/widgets/common/premium_shimmer.dart';
import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../theme/app_theme.dart';
import '../../theme/ios_ui.dart';
import '../../core/utils/haptic_engine.dart';
import '../../core/utils/manual_add_medicine.dart';
import '../../core/utils/logger.dart';
import '../../services/gemini_service.dart';
import '../analysis/product_analysis_screen.dart';
import '../../services/upc_service.dart';
import '../../widgets/shared/shared_widgets.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import 'scan_history_screen.dart';
import 'ai_accuracy_settings_screen.dart';
import 'scanner_help_screen.dart';

enum ScanMode { camera, barcode, search, voice }

// ══════════════════════════════════════════════════════════
// SCANNER HUB — Professional Cal AI 2026
// ══════════════════════════════════════════════════════════
class ScannerHubScreen extends StatefulWidget {
  final VoidCallback onClose;
  final ScanMode initialMode;
  const ScannerHubScreen({
    super.key,
    required this.onClose,
    this.initialMode = ScanMode.camera,
  });

  @override
  State<ScannerHubScreen> createState() => _ScannerHubScreenState();
}

class _ScannerHubScreenState extends State<ScannerHubScreen>
    with TickerProviderStateMixin {
  ScanMode _mode = ScanMode.camera;
  bool _isScanning = false;
  bool _barcodeFound = false;

  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  final MobileScannerController _barcodeCtrl = MobileScannerController();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _voiceText = '';

  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  final GlobalKey _cameraKey = GlobalKey();

  late AnimationController _scanLineCtrl;
  late AnimationController _breathCtrl;
  late AnimationController _cornerCtrl;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    _scanLineCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600))
      ..forward();
    _breathCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2400))
      ..forward();
    _cornerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _cornerCtrl.forward();
    _initSpeech();
  }

  void _initSpeech() async {
    try {
      await _speech.initialize();
    } catch (e) {
      appLogger.e('Speech init: $e');
    }
  }

  @override
  void dispose() {
    _scanLineCtrl.dispose();
    _breathCtrl.dispose();
    _cornerCtrl.dispose();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _barcodeCtrl.dispose();
    super.dispose();
  }

  // ── Image Pick ──
  Future<void> _pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final XFile? img = await _picker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (img != null && mounted) {
        setState(() => _selectedImage = File(img.path));
        _analyze(
          'Analyze this medicine, pill, or supplement packaging. Identify: medication name, dosage, active ingredients, usage, side effects, drug interactions. Be detailed and professional.',
          image: _selectedImage,
        );
      }
    } catch (e) {
      if (mounted) {
        _showError('Camera unavailable. Please try again.');
      }
    }
  }

  // ── Capture Screen ──
  Future<void> _captureScreen() async {
    try {
      final RenderRepaintBoundary boundary =
          _cameraKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List pngBytes = byteData!.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/scan_capture_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(pngBytes);

      if (mounted) {
        setState(() => _selectedImage = file);
        _analyze(
          'Analyze this medicine, pill, or supplement packaging. Identify: medication name, dosage, active ingredients, usage, side effects, drug interactions.',
          image: _selectedImage,
        );
      }
    } catch (e) {
      if (mounted) _showError('Failed to capture screen.');
    }
  }

  // ── Voice ──
  void _toggleVoice() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      if (_voiceText.isNotEmpty && _voiceText != 'Listening...') {
        _analyze(
          'Analyze this medicine or supplement: "$_voiceText". Provide comprehensive details: dosage, active ingredients, uses, side effects, and interactions.',
        );
      }
      return;
    }
    final ok = await _speech.initialize();
    if (ok) {
      HapticEngine.light();
      setState(() {
        _isListening = true;
        _voiceText = 'Listening...';
      });
      _speech.listen(onResult: (v) {
        if (mounted) setState(() => _voiceText = v.recognizedWords);
      });
    }
  }

  // ── Flash ──
  bool _isFlashOn = false;

  void _toggleFlash() {
    if (_mode == ScanMode.barcode || _mode == ScanMode.camera) {
      _barcodeCtrl.toggleTorch();
      setState(() => _isFlashOn = !_isFlashOn);
      HapticEngine.light();
    }
  }

  // ── Core Analyzer ──
  void _analyze(String prompt, {File? image}) async {
    if (_isScanning) return;
    HapticEngine.heavyImpact();
    setState(() => _isScanning = true);

    final allergies = context.read<AppState>().profile?.allergies ?? [];
    final result = await GeminiService.analyzeProductInsight(prompt, image: image, allergies: allergies);

    if (!mounted) return;
    setState(() {
      _isScanning = false;
      _selectedImage = null;
      _barcodeFound = false;
    });

    result.fold(
      (product) {
        HapticEngine.success();
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductAnalysisScreen(product: product, imageFile: image),
          ),
        );
      },
      (failure) {
        HapticEngine.error();
        if (mounted) _showError(failure.message);
      },
    );
  }

  void _triggerScan() {
    if (_mode == ScanMode.search) {
      final q = _searchCtrl.text.trim();
      if (q.isEmpty) return;
      _analyze('Analyze medicine or supplement: "$q". Provide comprehensive dosage, ingredients, uses, side effects, and interactions.');
      return;
    }
    if (_mode == ScanMode.camera) {
      if (_selectedImage != null) {
        _analyze(
          'Analyze this medicine, pill, or supplement packaging. Identify: medication name, dosage, active ingredients, usage, side effects, drug interactions.',
          image: _selectedImage,
        );
      } else {
        _captureScreen();
      }
      return;
    }
    if (_mode == ScanMode.voice) {
      _toggleVoice();
      return;
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ));
  }

  void _switchMode(ScanMode m) {
    if (m == _mode) return;
    HapticEngine.selection();
    _cornerCtrl.forward(from: 0);
    setState(() {
      _mode = m;
      _isScanning = false;
      _selectedImage = null;
      _barcodeFound = false;
      _voiceText = '';
      if (_isListening) {
        _speech.stop();
        _isListening = false;
      }
    });
    if (m == ScanMode.search) {
      Future.delayed(200.ms, () => _searchFocus.requestFocus());
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final topPad = MediaQuery.of(context).padding.top;
    final botPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: context.L.bg,
      body: Stack(
        children: [
          // ── Live Background ──────────────────────────────
          Positioned.fill(child: _buildBackground(size)),



          // ── Viewfinder or Mode Content ────────────────────
          Positioned(
            top: topPad + 72,
            left: 0,
            right: 0,
            bottom: botPad + 210,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildMainArea(size),
            ),
          ),

          if (_isScanning && _mode != ScanMode.search && _mode != ScanMode.voice)
            const _SmartScanningOverlay(),


          // ── Top Bar ───────────────────────────────────────
          Positioned(
            top: topPad,
            left: 0,
            right: 0,
            child: _TopBar(
              onClose: widget.onClose,
            ).animate().fadeIn(duration: 400.ms),
          ),

          // ── Bottom Controls ───────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _BottomControls(
              mode: _mode,
              isScanning: _isScanning,
              isListening: _isListening,
              hasImage: _selectedImage != null,
              barcodeFound: _barcodeFound,
              isFlashOn: _isFlashOn,
              botPad: botPad,
              onModeSelect: _switchMode,
              onTrigger: _isScanning ? null : _triggerScan,
              onFlashToggle: _toggleFlash,
              onGalleryTap: () => _pickImage(source: ImageSource.gallery),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground(Size size) {
    return Stack(
      children: [
        // Live camera feed runs in all modes for a premium feel
        Positioned.fill(
          child: RepaintBoundary(
            key: _cameraKey,
            child: MobileScanner(
              controller: _barcodeCtrl,
              onDetect: (capture) async {
                if (_mode == ScanMode.barcode && !_barcodeFound && capture.barcodes.isNotEmpty) {
                  final bc = capture.barcodes.first;
                  if (bc.rawValue != null) {
                    setState(() => _barcodeFound = true);
                    final name = await UPCService.lookupBarcode(bc.rawValue!);
                    final prompt = name != null
                        ? 'Analyze medicine or supplement: "$name". Provide comprehensive details.'
                        : 'Identify and analyze the medicine with barcode: ${bc.rawValue}. Be professional and thorough.';
                    _analyze(prompt);
                  }
                }
              },
            ),
          ),
        ),
        
        // Picked image overlay
        if (_selectedImage != null)
          Positioned.fill(
            child: Image.file(_selectedImage!, fit: BoxFit.cover),
          ),

        // Dark frosted glass overlay for Search, Voice, or Picked Image
        if (_mode == ScanMode.search || _mode == ScanMode.voice || (_selectedImage != null && !_isScanning))
          Positioned.fill(
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.55),
                ),
              ),
            ),
          )
        else if (_isScanning && _selectedImage != null)
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.3)),
          ),
      ],
    );
  }

  Widget _buildMainArea(Size size) {
    switch (_mode) {
      case ScanMode.search:
        return SingleChildScrollView(
  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isScanning)
                  const _SearchProcessingAnimation()
                else
                  _SearchInput(
                    controller: _searchCtrl,
                    focusNode: _searchFocus,
                    onSubmit: _triggerScan,
                  ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.08, end: 0),
                if (!_isScanning) ...[
                  const SizedBox(height: 20),
                  TextButton.icon(
                    onPressed: () => startManualAddMedicine(
                      context,
                      source: 'scanner_search',
                    ),
                    icon: const Icon(Icons.edit_note_rounded,
                        color: Colors.white70, size: 20),
                    label: const Text(
                      "Can't find it? Add manually",
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      case ScanMode.voice:
        return Center(
          child: _VoiceVisual(
            isListening: _isListening,
            text: _voiceText,
            breathCtrl: _breathCtrl,
          ),
        );
      default:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: _Viewfinder(
            isScanning: _isScanning,
            hasImage: _selectedImage != null,
            cornerCtrl: _cornerCtrl,
            isBarcode: _mode == ScanMode.barcode,
            scanLineCtrl: _scanLineCtrl,
          ),
        );
    }
  }
}

// Removed _AnimatedBg as we now use blurred live camera background for premium feel
// ══════════════════════════════════════════════


// ══════════════════════════════════════════════
// VIEWFINDER — Cal AI corner brackets
// ══════════════════════════════════════════════
class _Viewfinder extends StatelessWidget {
  final bool isScanning;
  final bool hasImage;
  final AnimationController cornerCtrl;
  final AnimationController scanLineCtrl;
  final bool isBarcode;

  const _Viewfinder({
    required this.isScanning,
    required this.hasImage,
    required this.cornerCtrl,
    required this.scanLineCtrl,
    required this.isBarcode,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: cornerCtrl,
      builder: (_, child) => Opacity(
        opacity: cornerCtrl.value,
        child: child,
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _CornersPainter(
                color: Colors.white,
                strokeWidth: 2.5,
                cornerLen: 40,
              ),
            ),
          ),
          if (isScanning)
            LayoutBuilder(
              builder: (context, constraints) {
                return AnimatedBuilder(
                  animation: scanLineCtrl,
                  builder: (context, _) {
                    return Align(
                      alignment: Alignment(0, scanLineCtrl.value * 2 - 1),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.6),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          Center(
            child: hasImage
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.auto_awesome_rounded,
                          size: 36, color: Colors.white.withValues(alpha: 0.8)),
                    ],
                  )
                : isBarcode
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.qr_code_rounded,
                              size: 40,
                              color: Colors.white.withValues(alpha: 0.15)),
                        ],
                      )
                    : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _CornersPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double cornerLen;

  const _CornersPainter({
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

    const r = 18.0;
    final L = cornerLen;
    final w = size.width;
    final h = size.height;

    // TL
    canvas.drawLine(Offset(r, 0), Offset(r + L, 0), paint);
    canvas.drawLine(Offset(0, r), Offset(0, r + L), paint);
    canvas.drawArc(const Rect.fromLTWH(0, 0, r * 2, r * 2), pi, pi / 2, false, paint);
    // TR
    canvas.drawLine(Offset(w - r - L, 0), Offset(w - r, 0), paint);
    canvas.drawLine(Offset(w, r), Offset(w, r + L), paint);
    canvas.drawArc(Rect.fromLTWH(w - r * 2, 0, r * 2, r * 2), 3 * pi / 2, pi / 2, false, paint);
    // BL
    canvas.drawLine(Offset(r, h), Offset(r + L, h), paint);
    canvas.drawLine(Offset(0, h - r - L), Offset(0, h - r), paint);
    canvas.drawArc(Rect.fromLTWH(0, h - r * 2, r * 2, r * 2), pi / 2, pi / 2, false, paint);
    // BR
    canvas.drawLine(Offset(w - r - L, h), Offset(w - r, h), paint);
    canvas.drawLine(Offset(w, h - r - L), Offset(w, h - r), paint);
    canvas.drawArc(Rect.fromLTWH(w - r * 2, h - r * 2, r * 2, r * 2), 0, pi / 2, false, paint);
  }

  @override
  bool shouldRepaint(_CornersPainter old) =>
      old.color != color || old.strokeWidth != strokeWidth;
}

// ══════════════════════════════════════════════
// TOP BAR
// ══════════════════════════════════════════════
class _TopBar extends StatelessWidget {
  final VoidCallback onClose;
  const _TopBar({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back Button
          AnimatedPressable(
            onTap: onClose,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1.0),
                  ),
                  child: const Center(
                    child: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ),
          ),
          
          // Premium title block
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Scanner',
                style: AppTypography.titleLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                'AI medicine recognition',
                style: AppTypography.labelSmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          
          // Menu Button
          AnimatedPressable(
            onTap: () {
              HapticEngine.selection();
              _showScannerMenu(context);
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1.0),
                  ),
                  child: const Center(
                    child: Icon(Icons.more_vert_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showScannerMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _ScannerMenuSheet(),
    );
  }
}

// ══════════════════════════════════════════════
// BOTTOM CONTROLS
// ══════════════════════════════════════════════
class _BottomControls extends StatelessWidget {
  final ScanMode mode;
  final bool isScanning;
  final bool isListening;
  final bool hasImage;
  final bool barcodeFound;
  final bool isFlashOn;
  final double botPad;
  final ValueChanged<ScanMode> onModeSelect;
  final VoidCallback? onTrigger;
  final VoidCallback onFlashToggle;
  final VoidCallback onGalleryTap;

  const _BottomControls({
    required this.mode,
    required this.isScanning,
    required this.isListening,
    required this.hasImage,
    required this.barcodeFound,
    required this.isFlashOn,
    required this.botPad,
    required this.onModeSelect,
    required this.onTrigger,
    required this.onFlashToggle,
    required this.onGalleryTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 0, 24, botPad + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mode pills row (Cal AI style: one pill with items inside)
          ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(32),
                ),
                child: SingleChildScrollView(
  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ModePill(icon: Icons.camera_alt_rounded, label: 'Scan Meds', mode: ScanMode.camera, current: mode, onTap: onModeSelect),
                      const SizedBox(width: 4),
                      _ModePill(icon: Icons.qr_code_scanner_rounded, label: 'Barcode', mode: ScanMode.barcode, current: mode, onTap: onModeSelect),
                      const SizedBox(width: 4),
                      _ModePill(icon: Icons.search_rounded, label: 'Search', mode: ScanMode.search, current: mode, onTap: onModeSelect),
                      const SizedBox(width: 4),
                      _ModePill(icon: Icons.mic_rounded, label: 'Voice', mode: ScanMode.voice, current: mode, onTap: onModeSelect),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Shutter Row
          if (mode == ScanMode.barcode)
            _BarcodeStatus(found: barcodeFound, scanning: isScanning)
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Flash button
                AnimatedPressable(
                  onTap: onFlashToggle,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: isFlashOn ? Colors.white : Colors.black.withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                            color: isFlashOn ? Colors.black : Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Main Shutter
                _Shutter(
                  mode: mode,
                  isScanning: isScanning,
                  isListening: isListening,
                  hasImage: hasImage,
                  onTap: onTrigger,
                ),

                // Gallery Button
                AnimatedPressable(
                  onTap: onGalleryTap,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(Icons.photo_library_outlined, color: Colors.white, size: 22),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ModePill extends StatelessWidget {
  final IconData icon;
  final String label;
  final ScanMode mode;
  final ScanMode current;
  final ValueChanged<ScanMode> onTap;

  const _ModePill({
    required this.icon,
    required this.label,
    required this.mode,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final on = current == mode;
    return BouncingButton(
      scaleFactor: 0.95,
      onTap: () {
        HapticEngine.selection();
        onTap(mode);
      },
      child: AnimatedContainer(
        duration: 250.ms,
        padding: on 
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
            : const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: on ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 18,
                color: on ? Colors.black : Colors.white.withValues(alpha: 0.8)),
            if (on) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Shutter extends StatelessWidget {
  final ScanMode mode;
  final bool isScanning;
  final bool isListening;
  final bool hasImage;
  final VoidCallback? onTap;

  const _Shutter({
    required this.mode,
    required this.isScanning,
    required this.isListening,
    required this.hasImage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BouncingButton(
      scaleFactor: 0.95,
      onTap: () {
        if (onTap != null && !isScanning) {
          HapticEngine.selection();
          onTap!();
        }
      },
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
        ),
        child: Center(
          child: isScanning
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: mode == ScanMode.voice && isListening ? AppColors.red : Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: mode == ScanMode.search || mode == ScanMode.voice 
                     ? Icon(
                         mode == ScanMode.voice ? (isListening ? Icons.stop_rounded : Icons.mic_rounded) : Icons.search_rounded, 
                         color: mode == ScanMode.voice && isListening ? Colors.white : Colors.black, 
                         size: 30
                       )
                     : const SizedBox.shrink(),
                ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════
// BARCODE STATUS
// ══════════════════════════════════════════════
class _BarcodeStatus extends StatelessWidget {
  final bool found;
  final bool scanning;

  const _BarcodeStatus({required this.found, required this.scanning});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: AnimatedContainer(
          duration: 300.ms,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: found || scanning
                  ? Colors.white.withValues(alpha: 0.8)
                  : Colors.white.withValues(alpha: 0.15),
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (scanning) ...[
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: ContextualLoader(message: "Analyzing...", isDark: true),
                ),
                const SizedBox(width: 12),
              ] else ...[
                Icon(
                  found ? Icons.check_circle_rounded : Icons.qr_code_scanner_rounded,
                  size: 20,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
              ],
              Text(
                found
                    ? 'Barcode detected!'
                    : scanning
                        ? 'Analyzing…'
                        : 'Aim at barcode',
                style: AppTypography.labelSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  letterSpacing: 0.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════
// SEARCH INPUT
// ══════════════════════════════════════════════
class _SearchInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSubmit;

  const _SearchInput({required this.controller, required this.focusNode, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Search',
          style: AppTypography.displaySmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 30,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Manually search for any medicine or supplement.',
          style: AppTypography.bodyMedium.copyWith(
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 24),
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.0),
              ),
              child: Row(
                children: [
                  Icon(Icons.search_rounded,
                      size: 22, color: Colors.white.withValues(alpha: 0.7)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
  autofocus: true,
                      controller: controller,
                      focusNode: focusNode,
                      style: AppTypography.titleMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      cursorColor: Colors.white,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Metformin, Vitamin C...',
                        hintStyle: AppTypography.titleMedium.copyWith(
                          color: Colors.white.withValues(alpha: 0.3),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onSubmitted: (_) => onSubmit(),
                    ),
                  ),
                  AnimatedPressable(
                    onTap: onSubmit,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_forward_rounded,
                          color: Colors.black, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════
// VOICE VISUAL
// ══════════════════════════════════════════════
class _VoiceVisual extends StatelessWidget {
  final bool isListening;
  final String text;
  final AnimationController breathCtrl;

  const _VoiceVisual({required this.isListening, required this.text, required this.breathCtrl});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: breathCtrl,
            builder: (_, __) {
              final pulse = isListening ? breathCtrl.value : 0.0;
              return ClipRRect(
                borderRadius: BorderRadius.circular(60),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    width: 100 + pulse * 20,
                    height: 100 + pulse * 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isListening
                          ? AppColors.accent.withValues(alpha: 0.25)
                          : Colors.white.withValues(alpha: 0.10),
                      border: Border.all(
                        color: isListening
                            ? AppColors.accent.withValues(alpha: 0.8)
                            : Colors.white.withValues(alpha: 0.25),
                        width: isListening ? 2.0 : 1.0,
                      ),
                    ),
                    child: Icon(
                      isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          Text(
            text.isEmpty
                ? 'Speak a medicine name'
                : text,
            style: AppTypography.headlineSmall.copyWith(
              color: text.isEmpty
                  ? Colors.white.withValues(alpha: 0.5)
                  : Colors.white,
              fontWeight: text.isEmpty ? FontWeight.w500 : FontWeight.w700,
              height: 1.3,
              letterSpacing: -0.2,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════
// 3D INTERACTIVE APP ICON
// ══════════════════════════════════════════════
class _Animated3DIcon extends StatefulWidget {
  const _Animated3DIcon();

  @override
  State<_Animated3DIcon> createState() => _Animated3DIconState();
}

class _Animated3DIconState extends State<_Animated3DIcon> {
  double _tiltX = 0;
  double _tiltY = 0;
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          _isHovering = true;
          _tiltY += details.delta.dx * 0.02;
          _tiltX += details.delta.dy * 0.02;
          _tiltX = _tiltX.clamp(-0.4, 0.4);
          _tiltY = _tiltY.clamp(-0.4, 0.4);
        });
      },
      onPanEnd: (_) {
        setState(() {
          _isHovering = false;
          _tiltX = 0;
          _tiltY = 0;
        });
      },
      onPanCancel: () {
        setState(() {
          _isHovering = false;
          _tiltX = 0;
          _tiltY = 0;
        });
      },
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: _tiltX),
        duration: _isHovering ? 100.ms : 600.ms,
        curve: Curves.easeOutExpo,
        builder: (context, valX, child) {
          return TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: _tiltY),
            duration: _isHovering ? 100.ms : 600.ms,
            curve: Curves.easeOutExpo,
            builder: (context, valY, child) {
              return Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.003)
                  ..rotateX(-valX)
                  ..rotateY(valY),
                alignment: FractionalOffset.center,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.4),
                        blurRadius: 15,
                        offset: Offset(valY * 15, valX * 15 + 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/images/app_logo.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════
// 2026 SMART SCANNING OVERLAY (Continuous Rolling Terminal)
// ══════════════════════════════════════════════
class _SmartScanningOverlay extends StatefulWidget {
  const _SmartScanningOverlay();

  @override
  State<_SmartScanningOverlay> createState() => _SmartScanningOverlayState();
}

class _SmartScanningOverlayState extends State<_SmartScanningOverlay> {
  final List<String> _steps = [
    'Initializing AI Vision Models...',
    'Isolating Object Contours...',
    'Enhancing Texture & Edges...',
    'Reading Text & Typography...',
    'Cross-Referencing Global DBs...',
    'Checking Active Ingredients...',
    'Evaluating Drug Interactions...',
    'Verifying Allergy Safety...',
    'Synthesizing Final Insights...',
  ];
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _playSteps();
  }

  void _playSteps() async {
    for (int i = 0; i < _steps.length; i++) {
      if (!mounted) return;
      setState(() => _currentStep = i);
      
      // Variable speed processing simulation (600ms to 1400ms)
      final delay = 600 + (DateTime.now().millisecondsSinceEpoch % 800);
      await Future.delayed(Duration(milliseconds: delay));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 24,
      top: 140,
      bottom: 240,
      width: 260,
      child: ShaderMask(
        shaderCallback: (rect) {
          return const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black, Colors.black, Colors.transparent],
            stops: [0.0, 0.15, 0.85, 1.0],
          ).createShader(rect);
        },
        blendMode: BlendMode.dstIn,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutExpo,
          alignment: Alignment.bottomRight, // Anchors to bottom, pushes up
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(_currentStep + 1, (index) {
              final isCurrent = index == _currentStep;
              return Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: _ScanningRow(
                  text: _steps[index],
                  isActive: isCurrent,
                  key: ValueKey('step_$index'),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _ScanningRow extends StatelessWidget {
  final String text;
  final bool isActive;

  const _ScanningRow({super.key, required this.text, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(
          child: _TerminalText(text: text, isActive: isActive),
        ),
        const SizedBox(width: 14),
        if (isActive)
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.5), width: 1.5),
            ),
            child: const Padding(
              padding: EdgeInsets.all(4.0),
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: AppColors.accent,
              ),
            ),
          ).animate()
           .shimmer(duration: 900.ms, color: Colors.white.withValues(alpha: 0.5))
        else
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.green.withValues(alpha: 0.5), width: 1.5),
            ),
            child: const Icon(Icons.check_rounded, color: AppColors.green, size: 14),
          ).animate().scale(curve: Curves.easeOutBack, duration: 400.ms),
      ],
    ).animate()
      .slideX(begin: 0.3, end: 0, curve: Curves.easeOutExpo, duration: 600.ms)
      .fadeIn(duration: 400.ms);
  }
}

class _TerminalText extends StatefulWidget {
  final String text;
  final bool isActive;
  const _TerminalText({required this.text, required this.isActive});
  @override
  State<_TerminalText> createState() => _TerminalTextState();
}

class _TerminalTextState extends State<_TerminalText> {
  Timer? _timer;
  String _hash = '';

  @override
  void initState() {
    super.initState();
    if (widget.isActive) _startHash();
  }

  void _startHash() {
    _timer = Timer.periodic(const Duration(milliseconds: 60), (timer) {
      if (!mounted) return;
      if (!widget.isActive) {
        timer.cancel();
        setState(() => _hash = '');
        return;
      }
      setState(() {
        _hash = ' 0x${(100 + (DateTime.now().millisecondsSinceEpoch % 899)).toRadixString(16).toUpperCase()}';
      });
    });
  }

  @override
  void didUpdateWidget(_TerminalText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive && !widget.isActive) {
      _timer?.cancel();
      _hash = '';
    } else if (!oldWidget.isActive && widget.isActive) {
      _startHash();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      '${widget.text}$_hash',
      textAlign: TextAlign.right,
      style: AppTypography.labelSmall.copyWith(
        fontFamily: 'Courier',
        color: widget.isActive ? Colors.white : Colors.white.withValues(alpha: 0.45),
        fontWeight: widget.isActive ? FontWeight.w700 : FontWeight.w500,
        fontSize: widget.isActive ? 13 : 12,
        letterSpacing: 0.5,
        height: 1.4,
      ),
    );
  }
}

// ══════════════════════════════════════════════
// 2026 PREMIUM TEXT SEARCH PROCESSING ANIMATION
// ══════════════════════════════════════════════
class _SearchProcessingAnimation extends StatefulWidget {
  const _SearchProcessingAnimation();

  @override
  State<_SearchProcessingAnimation> createState() => _SearchProcessingAnimationState();
}

class _SearchProcessingAnimationState extends State<_SearchProcessingAnimation> with SingleTickerProviderStateMixin {
  final List<String> _stages = [
    'Parsing Query Semantics...',
    'Querying Global Drug Index...',
    'Cross-referencing Safety Protocols...',
    'Fetching Interactions Data...',
    'Synthesizing Results...',
  ];
  int _currentStage = 0;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))
      ..forward();
    _playStages();
  }

  void _playStages() async {
    for (int i = 0; i < _stages.length; i++) {
      if (!mounted) return;
      setState(() => _currentStage = i);
      await Future.delayed(Duration(milliseconds: 800 + (i * 200)));
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Premium Animated Icon Ring
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (context, child) {
              return Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.3 + (_pulseCtrl.value * 0.4)),
                    width: 2.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: _pulseCtrl.value * 0.4),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.travel_explore_rounded,
                  color: Colors.white,
                  size: 44,
                ),
              );
            },
          ).animate().scale(curve: Curves.easeOutBack, duration: 600.ms),
          
          const SizedBox(height: 48),
          
          // Sleek cycling text
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            switchInCurve: Curves.easeOutExpo,
            transitionBuilder: (child, anim) => SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(anim),
              child: FadeTransition(opacity: anim, child: child),
            ),
            child: Text(
              _stages[_currentStage],
              key: ValueKey(_currentStage),
              textAlign: TextAlign.center,
              style: AppTypography.titleMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Custom segmented progress bar
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(_stages.length, (index) {
              final isActive = index <= _currentStage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 4,
                width: isActive ? 24 : 12,
                decoration: BoxDecoration(
                  color: isActive ? AppColors.accent : Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: isActive
                      ? [BoxShadow(color: AppColors.accent.withValues(alpha: 0.6), blurRadius: 8)]
                      : null,
                ),
              );
            }),
          ).animate().fadeIn(delay: 300.ms),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1), curve: Curves.easeOutExpo);
  }
}

// ══════════════════════════════════════════════
// 2026 PREMIUM SCANNER MENU SHEET
// ══════════════════════════════════════════════
class _ScannerMenuSheet extends StatelessWidget {
  const _ScannerMenuSheet();

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          padding: EdgeInsets.fromLTRB(
              0, 0, 0, 24 + MediaQuery.of(context).padding.bottom),
          decoration: BoxDecoration(
            color: L.bg.withValues(alpha: 0.86),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(
              top: BorderSide(
                  color: L.border.withValues(alpha: 0.16),
                  width: IOSMetrics.hairline),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const IOSGrabber(),
              const SizedBox(height: 8),
              Text(
                'Scanner Options',
                style: AppTypography.titleLarge.copyWith(
                  color: L.text,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: IOSInsetGroup(
                  children: [
                    IOSGroupedRow(
                      icon: Icons.history_rounded,
                      title: 'Scan History',
                      subtitle: 'View your previously scanned medications',
                      showChevron: true,
                      onTap: () {
                        HapticEngine.selection();
                        Navigator.pop(context);
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ScanHistoryScreen()));
                      },
                    ),
                    IOSGroupedRow(
                      icon: Icons.auto_awesome_rounded,
                      title: 'AI Accuracy Settings',
                      subtitle: 'Adjust confidence thresholds for recognition',
                      showChevron: true,
                      onTap: () {
                        HapticEngine.selection();
                        Navigator.pop(context);
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const AiAccuracySettingsScreen()));
                      },
                    ),
                    IOSGroupedRow(
                      icon: Icons.help_outline_rounded,
                      title: 'Help & Tips',
                      subtitle: 'Learn how to scan perfectly every time',
                      showChevron: true,
                      onTap: () {
                        HapticEngine.selection();
                        Navigator.pop(context);
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ScannerHelpScreen()));
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
