import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../theme/app_theme.dart';
import '../../../core/utils/haptic_engine.dart';
import '../../../services/gemini_service.dart';
import 'package:provider/provider.dart';
import 'package:medai/providers/app_state.dart';
import 'package:medai/screens/paywall/premium_paywall_overlay.dart';
import '../../services/growth_tracker.dart';
import '../../screens/medicine/medicine_detail_screen.dart';

// ══════════════════════════════════════════════
// AI QUICK LOG SHEET
// "I took my Vitamin D 10 mins ago" → AI parses → logs dose
// TikTok/Cal AI 2026 — Conversational Health Logging
// ══════════════════════════════════════════════

class AiQuickLogSheet extends StatefulWidget {
  const AiQuickLogSheet({super.key});

  static Future<void> show(BuildContext context) {
    final state = Provider.of<AppState>(context, listen: false);
    if ((state.profile?.voiceLogsUsed ?? 0) >= 3 &&
        !(state.profile?.isPremium ?? false)) {
      return PremiumPaywallOverlay.show(context, triggerSource: 'voice_limit');
    }
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AiQuickLogSheet(),
    );
  }

  @override
  State<AiQuickLogSheet> createState() => _AiQuickLogSheetState();
}

class _AiQuickLogSheetState extends State<AiQuickLogSheet>
    with TickerProviderStateMixin {
  final TextEditingController _ctrl = TextEditingController();
  final FocusNode _focus = FocusNode();

  _SheetPhase _phase = _SheetPhase.input;
  String _parsedResult = '';
  String _errorMsg = '';

  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _speechEnabled = false;

  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initSpeech();
      GrowthTracker.trackVoiceLog(success: false, fallback: false);
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _focus.requestFocus();
      });
    });
  }

  void _initSpeech() async {
    _speech = stt.SpeechToText();
    _speechEnabled = await _speech.initialize(
      onStatus: (val) {
        if (val == 'done' || val == 'notListening') {
          setState(() => _isListening = false);
        }
      },
      onError: (val) => setState(() {
        _isListening = false;
        _errorMsg = 'Microphone access denied or error: ${val.errorMsg}';
      }),
    );
    setState(() {});
  }

  void _listen() async {
    final state = Provider.of<AppState>(context, listen: false);
    if ((state.profile?.voiceLogsUsed ?? 0) >= 3 &&
        !(state.profile?.isPremium ?? false)) {
      Navigator.of(context).pop();
      PremiumPaywallOverlay.show(context, triggerSource: 'voice_limit');
      return;
    }
    if (!_speechEnabled) {
      bool available = await _speech.initialize();
      if (!available) {
        setState(() {
          _errorMsg = 'Speech recognition not available on this device.';
          _phase = _SheetPhase.error;
        });
        return;
      }
      _speechEnabled = true;
    }

    if (!_isListening) {
      HapticEngine.selection();
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (val) => setState(() {
          _ctrl.text = val.recognizedWords;
          // Auto-submit if the user stopped talking and we got a final result
          if (val.hasConfidenceRating && val.confidence > 0 && val.recognizedWords.isNotEmpty) {
             // Optional auto-submit here, but better to let them confirm
          }
        }),
        listenOptions: stt.SpeechListenOptions(
          cancelOnError: true,
          listenFor: const Duration(seconds: 15),
          pauseFor: const Duration(seconds: 3),
        ),
      );
    } else {
      HapticEngine.selection();
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  @override
  void dispose() {
    if (_isListening) _speech.cancel();
    _pulseCtrl.dispose();
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final input = _ctrl.text.trim();
    if (input.isEmpty) return;

    final state = Provider.of<AppState>(context, listen: false);
    if ((state.profile?.voiceLogsUsed ?? 0) >= 3 &&
        !(state.profile?.isPremium ?? false)) {
      Navigator.of(context).pop();
      PremiumPaywallOverlay.show(context, triggerSource: 'voice_limit');
      return;
    }

    HapticEngine.selection();
    setState(() => _phase = _SheetPhase.thinking);

    try {
      // Check for emergency keywords first
      if (GeminiService.detectHighRiskQuery(input)) {
        setState(() {
          _phase = _SheetPhase.error;
          _errorMsg =
              'This sounds like a medical emergency. Please call 911 or contact your healthcare provider immediately.';
        });
        return;
      }

      final result = await GeminiService.parseConversationalLog(input, state.meds);
      result.fold(
        (parsedMap) {
          final medId = parsedMap['med_id'] as int?;
          final confirmation = parsedMap['confirmation'] as String? ?? 'Dose recorded successfully';
          final timeTaken = parsedMap['time_taken'] as String? ?? 'Just now';
          
          if (medId != null) {
            state.logPrnDose(medId, 'AI Log', timeTaken);
          }
          
          state.incrementVoiceLogCount();
          GrowthTracker.trackVoiceLog(success: true, fallback: false);
          setState(() {
            _parsedResult = confirmation;
            _phase = _SheetPhase.success;
          });
          HapticEngine.medium();
          // Auto-close after confirmation
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) Navigator.of(context).pop();
          });
        },
        (err) {
          setState(() {
            _phase = _SheetPhase.error;
            _errorMsg =
                'Could not understand that. Try: "I took 1 Aspirin at 8am"';
          });
        },
      );
    } catch (e) {
      setState(() {
        _phase = _SheetPhase.error;
        _errorMsg = 'AI service unavailable. Please try again.';
      });
    }
  }

  void _logMeal(Ritual meal) {
    HapticEngine.selection();
    final state = Provider.of<AppState>(context, listen: false);
    state.logMeal(meal);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottom),
          decoration: BoxDecoration(
            color: L.bg.withValues(alpha: 0.85),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(36)),
            border: Border.all(
              color: AppColors.accent.withValues(alpha: 0.25),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.05),
                blurRadius: 40,
                spreadRadius: 10,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: L.border.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              // Header
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: AppGradients.accentOrange,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: AppShadows.glow(AppColors.accent,
                          intensity: 0.3),
                    ),
                    child: const Center(
                      child: Icon(Icons.auto_awesome_rounded,
                          color: Colors.black, size: 22),
                    ),
                  )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scaleXY(
                          begin: 1.0,
                          end: 1.05,
                          duration: 1500.ms,
                          curve: Curves.easeInOutSine),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Quick Log',
                          style: AppTypography.titleLarge.copyWith(
                            color: L.text,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'Just tell me what you took',
                          style: AppTypography.bodySmall.copyWith(
                            color: L.sub.withValues(alpha: 0.6),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Phase switcher
              AnimatedSwitcher(
                duration: 400.ms,
                switchInCurve: Curves.easeOutExpo,
                child: _buildPhaseContent(L),
              ),

              const SizedBox(height: 20),

              // Example chips
              if (_phase == _SheetPhase.input) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _ExampleChip(
                      text: 'I took 1 Aspirin',
                      onTap: () => _ctrl.text = 'I took 1 Aspirin',
                    ),
                    _ExampleChip(
                      text: 'Took my Metformin 500mg',
                      onTap: () => _ctrl.text = 'Took my Metformin 500mg',
                    ),
                    _ExampleChip(
                      text: 'Just had my morning vitamins',
                      onTap: () =>
                          _ctrl.text = 'Just had my morning vitamins',
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Or quickly log a meal:',
                    style: AppTypography.labelMedium.copyWith(
                      color: L.sub.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  child: Row(
                    children: [
                      _MealChip(
                        icon: '🍳',
                        text: 'Breakfast',
                        onTap: () => _logMeal(Ritual.afterBreakfast),
                      ),
                      const SizedBox(width: 8),
                      _MealChip(
                        icon: '🍱',
                        text: 'Lunch',
                        onTap: () => _logMeal(Ritual.afterLunch),
                      ),
                      const SizedBox(width: 8),
                      _MealChip(
                        icon: '🍽️',
                        text: 'Dinner',
                        onTap: () => _logMeal(Ritual.afterDinner),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhaseContent(AppThemeColors L) {
    switch (_phase) {
      case _SheetPhase.input:
        return _buildInputPhase(L);
      case _SheetPhase.thinking:
        return _buildThinkingPhase(L);
      case _SheetPhase.success:
        return _buildSuccessPhase(L);
      case _SheetPhase.error:
        return _buildErrorPhase(L);
    }
  }

  Widget _buildInputPhase(AppThemeColors L) {
    return Column(
      key: const ValueKey('input'),
      children: [
        Container(
          decoration: BoxDecoration(
            color: L.fill.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _focus.hasFocus
                  ? AppColors.accent.withValues(alpha: 0.4)
                  : L.border.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  focusNode: _focus,
                  maxLines: 3,
                  minLines: 1,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  style: AppTypography.bodyLarge.copyWith(
                    color: L.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: '"I took 2 Tylenol 30 minutes ago..."',
                    hintStyle: AppTypography.bodyLarge.copyWith(
                      fontFamily: 'Courier',
                      color: L.sub.withValues(alpha: 0.35),
                      fontSize: 15,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(18),
                  ),
                ),
              ),
              // Microphone button
              GestureDetector(
                onTap: _listen,
                child: AnimatedContainer(
                  duration: 250.ms,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isListening 
                        ? L.error.withValues(alpha: 0.2)
                        : L.border.withValues(alpha: 0.1),
                    boxShadow: _isListening
                        ? AppShadows.glow(L.error, intensity: 0.4)
                        : null,
                  ),
                  child: Icon(
                    _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                    color: _isListening ? L.error : L.sub.withValues(alpha: 0.7),
                    size: 24,
                  ),
                ).animate(target: _isListening ? 1 : 0)
                  .scaleXY(end: 1.1)
                  .shimmer(duration: 800.ms, color: L.error.withValues(alpha: 0.5)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _submit,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              gradient: AppGradients.accentOrange,
              borderRadius: BorderRadius.circular(18),
              boxShadow:
                  AppShadows.glow(AppColors.accent, intensity: 0.25),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.auto_awesome_rounded,
                    color: Colors.black, size: 18),
                const SizedBox(width: 10),
                Text(
                  'LOG WITH AI',
                  style: AppTypography.labelLarge.copyWith(
                    fontFamily: 'Courier',
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildThinkingPhase(AppThemeColors L) {
    return Column(
      key: const ValueKey('thinking'),
      children: [
        const SizedBox(height: 20),
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.accent.withValues(alpha: 0.1),
            border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.3),
                width: 1.5),
          ),
          child: const Center(
            child: Icon(Icons.auto_awesome_rounded,
                color: AppColors.accent, size: 32),
          ),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scaleXY(begin: 1.0, end: 1.15, duration: 800.ms)
            .then()
            .shimmer(
                duration: 1500.ms,
                color: AppColors.accent.withValues(alpha: 0.5)),
        const SizedBox(height: 16),
        Text(
          'AI is parsing your log...',
          style: AppTypography.titleMedium.copyWith(
            color: L.text,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '"${_ctrl.text}"',
          textAlign: TextAlign.center,
          style: AppTypography.bodySmall.copyWith(
            fontFamily: 'Courier',
            color: L.sub.withValues(alpha: 0.5),
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSuccessPhase(AppThemeColors L) {
    return Column(
      key: const ValueKey('success'),
      children: [
        const SizedBox(height: 20),
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppGradients.healthGreen,
            boxShadow: AppShadows.glow(L.success, intensity: 0.4),
          ),
          child: const Center(
            child: Icon(Icons.check_rounded, color: Colors.white, size: 36),
          ),
        )
            .animate()
            .scale(
                begin: const Offset(0.5, 0.5),
                end: const Offset(1, 1),
                curve: Curves.elasticOut,
                duration: 600.ms),
        const SizedBox(height: 16),
        Text(
          'Logged! ✅',
          style: AppTypography.titleLarge.copyWith(
            color: L.text,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: L.success.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: L.success.withValues(alpha: 0.2),
                width: 0.8),
          ),
          child: Text(
            _parsedResult.isNotEmpty
                ? _parsedResult
                : 'Dose recorded successfully',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: L.success,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildErrorPhase(AppThemeColors L) {
    return Column(
      key: const ValueKey('error'),
      children: [
        const SizedBox(height: 20),
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: L.error.withValues(alpha: 0.1),
            border: Border.all(color: L.error.withValues(alpha: 0.3)),
          ),
          child: Center(
            child: Icon(Icons.warning_rounded, color: L.error, size: 32),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _errorMsg,
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium.copyWith(
            color: L.sub.withValues(alpha: 0.7),
            fontWeight: FontWeight.w600,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => setState(() {
            _phase = _SheetPhase.input;
            _ctrl.clear();
          }),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: L.fill,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: L.border.withValues(alpha: 0.1)),
            ),
            child: Text(
              'Try again',
              style: AppTypography.labelLarge.copyWith(
                color: L.text,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () async {
            HapticEngine.selection();
            await GrowthTracker.trackVoiceLog(success: false, fallback: true);
            if (mounted) {
              Navigator.of(context).pop();
              final appState = Provider.of<AppState>(context, listen: false);
              final newMed = Medicine(
                id: DateTime.now().millisecondsSinceEpoch,
                name: '',
                brand: '',
                dose: '',
                form: 'Tablet',
                category: 'General',
                notes: '',
                schedule: const [],
                courseStartDate: DateTime.now().toIso8601String().substring(0, 10),
                color: '#10B981',
                count: 0,
                totalCount: 0,
                refillAt: 0,
              );
              await appState.addMedicine(newMed);
              if (!mounted) return;
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
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: L.border.withValues(alpha: 0.2)),
            ),
            child: Text(
              'Add Medicine Manually',
              style: AppTypography.labelLarge.copyWith(
                color: L.text,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

enum _SheetPhase { input, thinking, success, error }

class _ExampleChip extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _ExampleChip({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return GestureDetector(
      onTap: () {
        HapticEngine.selection();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: L.fill.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: L.border.withValues(alpha: 0.1), width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded,
                size: 14, color: L.sub.withValues(alpha: 0.5)),
            const SizedBox(width: 6),
            Text(
              text,
              style: AppTypography.bodySmall.copyWith(
                color: L.sub.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MealChip extends StatelessWidget {
  final String icon;
  final String text;
  final VoidCallback onTap;

  const _MealChip({required this.icon, required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: L.fill,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: L.border.withValues(alpha: 0.1), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(
              text,
              style: AppTypography.labelLarge.copyWith(
                color: L.text,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
