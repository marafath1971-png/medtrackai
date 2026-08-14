import 'dart:async';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';

import '../../theme/med_ai_ui.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../core/utils/haptic_engine.dart';
import '../../widgets/shared/shared_widgets.dart';

class FocusModeScreen extends StatefulWidget {
  const FocusModeScreen({super.key});

  @override
  State<FocusModeScreen> createState() => _FocusModeScreenState();
}

class _FocusModeScreenState extends State<FocusModeScreen> {
  late ConfettiController _confettiController;
  Timer? _sessionTimer;
  Timer? _breathTimer;

  int _remainingSeconds = 60;
  int _selectedDurationIndex = 0;
  final List<int> _durations = [60, 300, 600];

  bool _isActive = false;
  bool _isFinished = false;
  bool _isInhaling = true;

  Duration get _breathDuration =>
      MedAiA11y.reducedMotion(context)
          ? Duration.zero
          : const Duration(seconds: 4);

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    _remainingSeconds = _durations[_selectedDurationIndex];
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _breathTimer?.cancel();
    _confettiController.dispose();
    super.dispose();
  }

  void _startSession() {
    HapticEngine.heavyImpact();
    setState(() {
      _isActive = true;
      _isFinished = false;
      _isInhaling = true;
    });

    _breathTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) return;
      setState(() {
        _isInhaling = !_isInhaling;
      });
      if (_isInhaling) {
        HapticEngine.selection();
      } else {
        HapticEngine.light();
      }
    });

    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _finishSession();
      }
    });
  }

  void _stopSession() {
    HapticEngine.selection();
    _breathTimer?.cancel();
    _sessionTimer?.cancel();
    setState(() {
      _isActive = false;
      _remainingSeconds = _durations[_selectedDurationIndex];
      _isInhaling = true;
    });
  }

  void _finishSession() {
    _breathTimer?.cancel();
    _sessionTimer?.cancel();
    HapticEngine.doseTaken();
    if (!MedAiA11y.reducedMotion(context)) {
      _confettiController.play();
    }
    setState(() {
      _isActive = false;
      _isFinished = true;
    });
  }

  void _setDuration(int index) {
    if (_isActive) return;
    HapticEngine.selection();
    setState(() {
      _selectedDurationIndex = index;
      _remainingSeconds = _durations[index];
    });
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  double _outerOrbSize(bool reduceMotion) {
    if (reduceMotion) return 200;
    if (!_isActive) return 180;
    return _isInhaling ? 240 : 160;
  }

  double _innerOrbSize(bool reduceMotion) {
    if (reduceMotion) return 120;
    if (!_isActive) return 120;
    return _isInhaling ? 180 : 100;
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final reduceMotion = MedAiA11y.reducedMotion(context);

    final bgGradient = RadialGradient(
      center: const Alignment(0, 0),
      radius: 1.2,
      colors: [
        _isActive
            ? (_isInhaling
                ? AppColors.lime.withValues(alpha: 0.18)
                : AppColors.pastelSky.withValues(alpha: 0.35))
            : L.primary.withValues(alpha: 0.05),
        L.bg,
      ],
    );

    return AppScaffold(
      showAurora: true,
      body: Stack(
        children: [
          AnimatedContainer(
            duration: _breathDuration,
            curve: Curves.easeInOut,
            decoration: BoxDecoration(gradient: bgGradient),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 16),
                  child: Row(
                    children: [
                      Semantics(
                        button: true,
                        label: _isActive ? 'Stop session' : 'Back',
                        child: AnimatedPressable(
                          onTap: () {
                            if (_isActive) {
                              _stopSession();
                            } else {
                              Navigator.pop(context);
                            }
                          },
                          child: Container(
                            width: MedAiA11y.minTapTarget,
                            height: MedAiA11y.minTapTarget,
                            decoration: BoxDecoration(
                              color: L.card,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: L.border.withValues(alpha: 0.1)),
                            ),
                            child: Icon(
                              _isActive
                                  ? Icons.close_rounded
                                  : Icons.arrow_back_rounded,
                              color: L.text,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            'Focus mode',
                            style: AppTypography.titleMedium.copyWith(
                              color: L.text,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: MedAiA11y.minTapTarget),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Semantics(
                          liveRegion: true,
                          label:
                              'Timer ${_formatTime(_remainingSeconds)}. ${_isFinished ? 'Session complete' : (_isActive ? (_isInhaling ? 'Inhale' : 'Exhale') : 'Ready to focus')}',
                          child: Text(
                            _formatTime(_remainingSeconds),
                            style: AppTypography.displayLarge.copyWith(
                              color: L.text,
                              fontSize: 72,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        AnimatedSwitcher(
                          duration: MedAiA11y.motion(
                              context, const Duration(milliseconds: 500)),
                          child: Text(
                            _isFinished
                                ? 'Session Complete'
                                : (_isActive
                                    ? (_isInhaling ? 'Inhale...' : 'Exhale...')
                                    : 'Ready to focus'),
                            key: ValueKey<String>(_isFinished
                                ? 'done'
                                : (_isActive
                                    ? (_isInhaling ? 'in' : 'out')
                                    : 'ready')),
                            style: AppTypography.titleMedium.copyWith(
                              color: L.sub,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 60),
                        Semantics(
                          label: _isActive
                              ? 'Breathing guide, ${_isInhaling ? 'inhale' : 'exhale'}'
                              : 'Breathing guide',
                          child: SizedBox(
                            width: 240,
                            height: 240,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                AnimatedContainer(
                                  duration: _breathDuration,
                                  curve: Curves.easeInOut,
                                  width: _outerOrbSize(reduceMotion),
                                  height: _outerOrbSize(reduceMotion),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.cyanAccent
                                        .withValues(alpha: 0.1),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.cyanAccent
                                            .withValues(alpha: 0.2),
                                        blurRadius: 40,
                                        spreadRadius: 20,
                                      )
                                    ],
                                  ),
                                ),
                                AnimatedContainer(
                                  duration: _breathDuration,
                                  curve: Curves.easeInOut,
                                  width: _innerOrbSize(reduceMotion),
                                  height: _innerOrbSize(reduceMotion),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      colors: [
                                        AppColors.lime,
                                        AppColors.limeDeep,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    boxShadow: AppShadows.glow(
                                        AppColors.limeDeep,
                                        intensity: 0.28),
                                  ),
                                  child: ClipOval(
                                    child: Container(
                                      color: Colors.white.withValues(alpha: 0.12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 80),
                        if (!_isActive && !_isFinished) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children:
                                List.generate(_durations.length, (index) {
                              final isSelected =
                                  _selectedDurationIndex == index;
                              final label = '${_durations[index] ~/ 60} minutes';
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                child: Semantics(
                                  button: true,
                                  selected: isSelected,
                                  label: label,
                                  child: AnimatedPressable(
                                    onTap: () => _setDuration(index),
                                    child: Container(
                                      constraints: const BoxConstraints(
                                          minHeight: MedAiA11y.minTapTarget),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: isSelected ? L.text : L.card,
                                        borderRadius:
                                            BorderRadius.circular(20),
                                        border: Border.all(
                                            color: isSelected
                                                ? Colors.transparent
                                                : L.border
                                                    .withValues(alpha: 0.1)),
                                      ),
                                      child: Text(
                                        '${_durations[index] ~/ 60}m',
                                        style:
                                            AppTypography.labelLarge.copyWith(
                                          color: isSelected ? L.bg : L.text,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 40),
                          MedAiCTA(
                            label: 'Start focus',
                            fullWidth: false,
                            semanticsLabel: 'Start focus session',
                            onTap: _startSession,
                          ),
                        ],
                        if (_isFinished) ...[
                          MedAiCTA(
                            label: 'Done',
                            secondary: true,
                            fullWidth: false,
                            onTap: () {
                              HapticEngine.selection();
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!reduceMotion)
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                emissionFrequency: 0.05,
                numberOfParticles: 20,
                maxBlastForce: 100,
                minBlastForce: 80,
                gravity: 0.3,
                colors: const [
                  AppColors.lime,
                  AppColors.limeDeep,
                  AppColors.pastelSky,
                  Colors.white,
                ],
              ),
            ),
        ],
      ),
    );
  }
}
