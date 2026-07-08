import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:medai/providers/app_state.dart';
import 'package:medai/screens/paywall/premium_paywall_overlay.dart';

import '../../app/app_routes.dart';
import '../../core/utils/haptic_engine.dart';
import '../../services/gemini_service.dart';
import '../../services/growth_tracker.dart';
import '../../services/remote_config_service.dart';
import '../../theme/med_ai_ui.dart';
import '../common/animated_pressable.dart';
import '../shared/shared_widgets.dart' show DopamineBurstOverlay;

// ══════════════════════════════════════════════
// AI QUICK LOG SHEET
// "I took my Vitamin D 10 mins ago" → AI parses → logs dose
// TikTok/Cal AI 2026 — Conversational Health Logging
// ══════════════════════════════════════════════

class AiQuickLogSheet extends StatefulWidget {
  const AiQuickLogSheet({super.key});

  static Future<void> show(BuildContext context) {
    final state = Provider.of<AppState>(context, listen: false);
    if ((state.profile?.voiceLogsUsed ?? 0) >=
            RemoteConfigService.freeTierVoiceLimit &&
        !state.isPremium) {
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
  late AnimationController _burstCtrl;
  bool _showSuccessBurst = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _burstCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !MedAiA11y.reducedMotion(context)) {
        _pulseCtrl.repeat(reverse: true);
      }
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
    if ((state.profile?.voiceLogsUsed ?? 0) >=
            RemoteConfigService.freeTierVoiceLimit &&
        !state.isPremium) {
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
    _burstCtrl.dispose();
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final input = _ctrl.text.trim();
    if (input.isEmpty) return;

    final state = Provider.of<AppState>(context, listen: false);
    if ((state.profile?.voiceLogsUsed ?? 0) >=
            RemoteConfigService.freeTierVoiceLimit &&
        !state.isPremium) {
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
          final action = parsedMap['action'] as String?;
          final medId = parsedMap['med_id'] as int?;
          final confirmation = parsedMap['confirmation'] as String? ?? 'Processed successfully';
          final timeTaken = parsedMap['time_taken'] as String? ?? 'Just now';
          
          if (action == 'schedule_med') {
            final medName = parsedMap['med_name'] as String? ?? 'New Medicine';
            final dosage = parsedMap['dosage'] as String? ?? '';
            final timesList = parsedMap['times'] as List<dynamic>? ?? [];
            
            final schedule = timesList.map((t) {
              final parts = t.toString().split(':');
              final h = int.tryParse(parts.first) ?? 8;
              final m = parts.length > 1 ? (int.tryParse(parts.last) ?? 0) : 0;
              return ScheduleEntry(
                id: DateTime.now().microsecondsSinceEpoch.toString(),
                h: h,
                m: m,
                label: 'Dose',
                days: [1, 2, 3, 4, 5, 6, 7],
              );
            }).toList();
            
            if (schedule.isEmpty) {
              schedule.add(ScheduleEntry(
                id: DateTime.now().microsecondsSinceEpoch.toString(),
                h: 8,
                m: 0,
                label: 'Dose',
                days: [1, 2, 3, 4, 5, 6, 7],
              ));
            }
            
            final newMed = Medicine(
              id: DateTime.now().millisecondsSinceEpoch,
              name: medName,
              dose: dosage,
              courseStartDate: DateTime.now().toIso8601String(),
              schedule: schedule,
            );

            if (!state.canAddMedicine) {
              if (mounted) Navigator.of(context).pop();
              PremiumPaywallOverlay.show(context,
                  triggerSource: 'unlimited_meds');
              return;
            }
            state.addMedicine(newMed);
          } else if (medId != null || action == 'log_dose') {
            if (medId != null) {
              state.logPrnDose(medId, 'AI Log', timeTaken);
            }
          }
          
          state.incrementVoiceLogCount();
          GrowthTracker.trackVoiceLog(success: true, fallback: false);
          setState(() {
            _parsedResult = confirmation;
            _phase = _SheetPhase.success;
            _showSuccessBurst = true;
          });
          _burstCtrl.forward(from: 0);
          HapticEngine.medium();
          // Auto-close after confirmation
          Future.delayed(const Duration(milliseconds: 3500), () {
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
    final reduceMotion = MedAiA11y.reducedMotion(context);

    Widget headerIcon = Container(
      width: MedAiA11y.minTapTargetCompact,
      height: MedAiA11y.minTapTargetCompact,
      decoration: BoxDecoration(
        gradient: AppGradients.accentOrange,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppShadows.glow(L.accent, intensity: 0.3),
      ),
      child: const Center(
        child: Icon(Icons.auto_awesome_rounded, color: Colors.black, size: 22),
      ),
    );
    if (!reduceMotion) {
      headerIcon = headerIcon
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scaleXY(
            begin: 1.0,
            end: 1.05,
            duration: 1500.ms,
            curve: Curves.easeInOutSine,
          );
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.squircle)),
      child: MedAiGlass(
        radius: AppRadius.squircle,
        showBorder: false,
        padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: L.border.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                headerIcon,
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
                child: _isListening && _phase == _SheetPhase.input
                    ? _buildVoiceModePhase(L)
                    : _buildPhaseContent(L),
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
                      text: 'Remind me to take Metformin daily at 8am',
                      onTap: () => _ctrl.text = 'Remind me to take Metformin daily at 8am',
                    ),
                    _ExampleChip(
                      text: 'Schedule Vitamin D every morning',
                      onTap: () => _ctrl.text = 'Schedule Vitamin D every morning',
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
  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
    );
  }

  Widget _buildVoiceModePhase(AppThemeColors L) {
    final reduceMotion = MedAiA11y.reducedMotion(context);

    Widget listeningLabel = Text(
      'LISTENING...',
      style: AppTypography.labelSmall.copyWith(
        color: L.error,
        letterSpacing: 2.0,
        fontWeight: FontWeight.w900,
        fontSize: 11,
      ),
    );
    if (!reduceMotion) {
      listeningLabel = listeningLabel
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .fade(begin: 0.5, end: 1.0, duration: 600.ms);
    }

    Widget stopButton = Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: L.error.withValues(alpha: 0.15),
        border:
            Border.all(color: L.error.withValues(alpha: 0.4), width: 2),
        boxShadow: AppShadows.glow(L.error, intensity: 0.5),
      ),
      child: const Center(
        child: Icon(Icons.stop_rounded, color: Colors.red, size: 36),
      ),
    );
    if (!reduceMotion) {
      stopButton = stopButton
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scaleXY(begin: 0.95, end: 1.05, duration: 800.ms);
    }

    return Column(
      key: const ValueKey('voice'),
      children: [
        const SizedBox(height: 16),
        listeningLabel,
        const SizedBox(height: 16),
        
        // Siri-like Animated Soundwave
        SizedBox(
          height: 80,
          width: double.infinity,
          child: CustomPaint(
            painter: _VoiceWavePainter(
              animationValue: _pulseCtrl.value,
              color: L.accent,
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Transcribed text display
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: L.fill.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: L.border.withValues(alpha: 0.05)),
          ),
          child: Text(
            _ctrl.text.isEmpty ? 'Say what you took, e.g. "I took Vitamin D"' : _ctrl.text,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: _ctrl.text.isEmpty ? L.sub.withValues(alpha: 0.4) : L.text,
              fontStyle: _ctrl.text.isEmpty ? FontStyle.italic : FontStyle.normal,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Big stop recording / confirm button
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Semantics(
              button: true,
              label: 'Stop recording',
              child: AnimatedPressable(
                onTap: () {
                  HapticEngine.selection();
                  setState(() {
                    _isListening = false;
                    _speech.stop();
                  });
                },
                child: stopButton,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
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
        MedAiDepthCard(
          padding: EdgeInsets.zero,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  focusNode: _focus,
                  autofocus: true,
                  maxLines: 3,
                  minLines: 1,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  style: AppTypography.bodyLarge.copyWith(
                    color: L.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: '"I took 2 Tylenol 30 minutes ago..."',
                    hintStyle: AppTypography.bodyLarge.copyWith(
                      color: L.sub.withValues(alpha: 0.4),
                      fontSize: 15,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(18),
                  ),
                ),
              ),
              Semantics(
                button: true,
                label: _isListening ? 'Stop listening' : 'Start voice input',
                child: AnimatedPressable(
                  onTap: _listen,
                  child: AnimatedContainer(
                    duration: MedAiA11y.motion(context, AppDurations.fast),
                    margin: const EdgeInsets.only(right: 12),
                    width: MedAiA11y.minTapTargetCompact,
                    height: MedAiA11y.minTapTargetCompact,
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
                      color:
                          _isListening ? L.error : L.sub.withValues(alpha: 0.7),
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        MedAiCTA(
          label: 'Log with AI',
          icon: Icons.auto_awesome_rounded,
          semanticsLabel: 'Submit AI quick log',
          onTap: _submit,
        ),
      ],
    );
  }

  Widget _buildThinkingPhase(AppThemeColors L) {
    return Column(
      key: const ValueKey('thinking'),
      children: [
        const SizedBox(height: 20),
        _AiOrbVisualizer(L: L),
        const SizedBox(height: 24),
        Text(
          'AI is parsing your log...',
          style: AppTypography.titleMedium.copyWith(
            color: L.text,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '"${_ctrl.text}"',
          textAlign: TextAlign.center,
          style: AppTypography.bodySmall.copyWith(
            color: L.sub.withValues(alpha: 0.65),
            fontStyle: FontStyle.italic,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSuccessPhase(AppThemeColors L) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Column(
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
            const SizedBox(height: 20),
            Text(
              _parsedResult.contains('Scheduled') ? 'Scheduled! 🗓️' : 'Logged Successfully! 🎉',
              style: AppTypography.headlineSmall.copyWith(
                color: L.text,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: L.green.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: L.green.withValues(alpha: 0.20),
                  width: 1.0,
                ),
              ),
              child: Text(
                _parsedResult.isNotEmpty
                    ? _parsedResult
                    : 'Dose recorded successfully',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: L.green,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
        if (_showSuccessBurst)
          Positioned(
            top: 20,
            child: IgnorePointer(
              child: SizedBox(
                width: 150,
                height: 150,
                child: DopamineBurstOverlay(controller: _burstCtrl, medColor: L.green),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildErrorPhase(AppThemeColors L) {
    return Column(
      key: const ValueKey('error'),
      children: [
        const SizedBox(height: 24),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: L.error.withValues(alpha: 0.1),
            border: Border.all(color: L.error.withValues(alpha: 0.3), width: 1.5),
            boxShadow: AppShadows.glow(L.error, intensity: 0.2),
          ),
          child: Center(
            child: Icon(Icons.error_outline_rounded, color: L.error, size: 36),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'We didn\'t catch that',
          textAlign: TextAlign.center,
          style: AppTypography.titleLarge.copyWith(
            color: L.text,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            _errorMsg,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: L.sub.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 24),
        MedAiCTA(
          label: 'Try again',
          secondary: true,
          icon: Icons.refresh_rounded,
          fullWidth: false,
          onTap: () => setState(() {
            _phase = _SheetPhase.input;
            _ctrl.clear();
          }),
        ),
        const SizedBox(height: 12),
        MedAiCTA(
          label: 'Add Medicine Manually',
          secondary: true,
          fullWidth: false,
          onTap: () async {
            HapticEngine.selection();
            await GrowthTracker.trackVoiceLog(success: false, fallback: true);
            if (mounted) {
              final appState = Provider.of<AppState>(context, listen: false);
              if (!appState.canAddMedicine) {
                context.pop();
                PremiumPaywallOverlay.show(context,
                    triggerSource: 'unlimited_meds');
                return;
              }
              final newMed = Medicine(
                id: DateTime.now().millisecondsSinceEpoch,
                name: '',
                brand: '',
                dose: '',
                form: 'Tablet',
                category: 'General',
                notes: '',
                schedule: const [],
                courseStartDate:
                    DateTime.now().toIso8601String().substring(0, 10),
                color: '#10B981',
                count: 0,
                totalCount: 0,
                refillAt: 0,
              );
              await appState.addMedicine(newMed);
              await Future.delayed(const Duration(milliseconds: 250));
              if (!mounted) return;
              context.pop();
              context.push(AppRoutes.medicineDetailPath(newMed.id, edit: true));
            }
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

enum _SheetPhase { input, thinking, success, error }

// ── Siri-style Animated Soundwave Visualizer ───────────────
class _VoiceWavePainter extends CustomPainter {
  final double animationValue;
  final Color color;

  _VoiceWavePainter({required this.animationValue, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final yCenter = size.height / 2;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    
    // Siri-style gradient: transparent edges, glowing accent/white center
    final gradient = LinearGradient(
      colors: [
        Colors.transparent,
        color.withValues(alpha: 0.08),
        color.withValues(alpha: 0.75),
        Colors.white,
        color.withValues(alpha: 0.75),
        color.withValues(alpha: 0.08),
        Colors.transparent,
      ],
      stops: const [0.0, 0.15, 0.4, 0.5, 0.6, 0.85, 1.0],
    );
    final shader = gradient.createShader(rect);

    for (int wave = 0; wave < 5; wave++) {
      final paint = Paint()
        ..shader = shader
        ..style = PaintingStyle.stroke
        ..strokeWidth = wave == 2 ? 3.0 : 1.5;

      final path = Path();
      
      // Calculate dynamic amplitude based on wave index and pulse anim
      final double baseAmp = 8.0 + (wave * 6.0);
      final double pulse = math.sin(animationValue * math.pi * 2 + (wave * math.pi / 2));
      final double amplitude = baseAmp * (0.6 + 0.4 * pulse);
      
      final double frequency = 0.012 + (wave * 0.006);
      final double phaseShift = animationValue * math.pi * 2 + (wave * 1.8);

      path.moveTo(0, yCenter);
      for (double x = 0; x <= size.width; x += 1.5) {
        // Bell curve envelope so the wave is flat at the edges and peaks in the center
        final double envelope = math.sin((x / size.width) * math.pi);
        final y = yCenter + amplitude * envelope * math.sin(frequency * x - phaseShift);
        path.lineTo(x, y);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _VoiceWavePainter oldDelegate) => true;
}

// ── Glowing, Rotating AI Orb Visualizer ───────────────
class _AiOrbVisualizer extends StatefulWidget {
  final AppThemeColors L;
  const _AiOrbVisualizer({required this.L});

  @override
  State<_AiOrbVisualizer> createState() => _AiOrbVisualizerState();
}

class _AiOrbVisualizerState extends State<_AiOrbVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return SizedBox(
          width: 90,
          height: 90,
          child: CustomPaint(
            painter: _AiOrbPainter(
              angle: _ctrl.value * 2 * math.pi,
              color: widget.L.accent,
            ),
          ),
        );
      },
    );
  }
}

class _AiOrbPainter extends CustomPainter {
  final double angle;
  final Color color;

  _AiOrbPainter({required this.angle, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width / 3.2;

    // Soft ambient glow background
    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawCircle(center, baseRadius * 1.6, bgPaint);

    // Overlapping morphing blobs to create a liquid/organic feel
    final time = angle;
    for (int i = 0; i < 3; i++) {
      final blobAngle = time + (i * math.pi * 2 / 3);
      final offsetDistance = baseRadius * 0.18 * math.sin(time * 2 + i);
      final blobCenter = Offset(
        center.dx + offsetDistance * math.cos(blobAngle),
        center.dy + offsetDistance * math.sin(blobAngle),
      );
      final blobRadius = baseRadius * (0.95 + 0.12 * math.cos(time * 1.5 + i));

      final blobPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.9),
            color.withValues(alpha: 0.7),
            color.withValues(alpha: 0.05),
            Colors.transparent,
          ],
          stops: const [0.0, 0.35, 0.85, 1.0],
        ).createShader(Rect.fromCircle(center: blobCenter, radius: blobRadius));

      canvas.drawCircle(blobCenter, blobRadius, blobPaint);
    }

    // Delicate orbital rings that float around the core
    final ringPaint = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(time);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: baseRadius * 2.2, height: baseRadius * 0.7),
      ringPaint,
    );
    canvas.rotate(math.pi / 2.5 + time * 0.5);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: baseRadius * 2.2, height: baseRadius * 0.6),
      ringPaint..color = color.withValues(alpha: 0.2),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AiOrbPainter oldDelegate) => true;
}

class _ExampleChip extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _ExampleChip({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Semantics(
      button: true,
      label: text,
      child: AnimatedPressable(
        onTap: () {
          HapticEngine.selection();
          onTap();
        },
        child: Container(
          constraints: const BoxConstraints(minHeight: MedAiA11y.minTapTargetCompact),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: L.card.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: L.border.withValues(alpha: 0.12),
              width: 1.0,
            ),
            boxShadow: AppShadows.soft,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded,
                  size: 14, color: L.sub.withValues(alpha: 0.6)),
              const SizedBox(width: 6),
              Text(
                text,
                style: AppTypography.bodySmall.copyWith(
                  color: L.text.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
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
    return Semantics(
      button: true,
      label: 'Log $text',
      child: AnimatedPressable(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: MedAiA11y.minTapTargetCompact),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: L.card.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: L.border.withValues(alpha: 0.12),
              width: 1.0,
            ),
            boxShadow: AppShadows.soft,
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
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
