import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';

import '../../theme/app_theme.dart';
import '../../core/utils/haptic_engine.dart';
import '../../widgets/shared/shared_widgets.dart';

class FocusModeScreen extends StatefulWidget {
  const FocusModeScreen({super.key});

  @override
  State<FocusModeScreen> createState() => _FocusModeScreenState();
}

class _FocusModeScreenState extends State<FocusModeScreen> with SingleTickerProviderStateMixin {
  late ConfettiController _confettiController;
  Timer? _sessionTimer;
  Timer? _breathTimer;
  
  int _remainingSeconds = 60; // default 1 minute
  int _selectedDurationIndex = 0;
  final List<int> _durations = [60, 300, 600]; // 1m, 5m, 10m
  
  bool _isActive = false;
  bool _isFinished = false;
  bool _isInhaling = true;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
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

    // Breath cycle timer: 4s inhale, 4s exhale
    _breathTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) return;
      setState(() {
        _isInhaling = !_isInhaling;
      });
      if (_isInhaling) {
        HapticEngine.selection(); // Light tick for inhale
      } else {
        HapticEngine.light(); // Lighter tick for exhale
      }
    });

    // Session timer
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
    _confettiController.play();
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

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    
    // Liquid glass ambient background
    final bgGradient = RadialGradient(
      center: const Alignment(0, 0),
      radius: 1.2,
      colors: [
        _isActive 
            ? (_isInhaling ? AppColors.cyanAccent.withValues(alpha: 0.15) : AppColors.lavenderAccent.withValues(alpha: 0.15))
            : L.primary.withValues(alpha: 0.05),
        L.bg,
      ],
    );

    return Scaffold(
      backgroundColor: L.bg,
      body: Stack(
        children: [
          // Ambient Background
          AnimatedContainer(
            duration: const Duration(seconds: 4),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(gradient: bgGradient),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    children: [
                      BouncingButton(
                        onTap: () {
                          if (_isActive) {
                             _stopSession();
                          } else {
                             Navigator.pop(context);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: L.card,
                            shape: BoxShape.circle,
                            border: Border.all(color: L.border.withValues(alpha: 0.1)),
                          ),
                          child: Icon(_isActive ? Icons.close_rounded : Icons.arrow_back_rounded, color: L.text, size: 20),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            'FOCUS MODE',
                            style: AppTypography.labelSmall.copyWith(
                              color: L.sub.withValues(alpha: 0.6),
                              letterSpacing: 2.0,
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 44), // Balance header
                    ],
                  ),
                ),
                
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Timer Display
                        Text(
                          _formatTime(_remainingSeconds),
                          style: AppTypography.displayLarge.copyWith(
                            color: L.text,
                            fontSize: 72,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -2.0,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Status Text
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 500),
                          child: Text(
                            _isFinished 
                                ? 'Session Complete' 
                                : (_isActive 
                                    ? (_isInhaling ? 'Inhale...' : 'Exhale...') 
                                    : 'Ready to focus'),
                            key: ValueKey<String>(_isFinished ? 'done' : (_isActive ? (_isInhaling ? 'in' : 'out') : 'ready')),
                            style: AppTypography.titleMedium.copyWith(
                              color: L.sub,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 60),
                        
                        // Breathing Orb
                        SizedBox(
                          width: 240,
                          height: 240,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Outer Glow
                              AnimatedContainer(
                                duration: const Duration(seconds: 4),
                                curve: Curves.easeInOut,
                                width: _isActive ? (_isInhaling ? 240 : 160) : 180,
                                height: _isActive ? (_isInhaling ? 240 : 160) : 180,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.cyanAccent.withValues(alpha: 0.1),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.cyanAccent.withValues(alpha: 0.2),
                                      blurRadius: 40,
                                      spreadRadius: 20,
                                    )
                                  ]
                                ),
                              ),
                              // Inner Core
                              AnimatedContainer(
                                duration: const Duration(seconds: 4),
                                curve: Curves.easeInOut,
                                width: _isActive ? (_isInhaling ? 180 : 100) : 120,
                                height: _isActive ? (_isInhaling ? 180 : 100) : 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [
                                      AppColors.cyanAccent,
                                      AppColors.lavenderAccent,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: AppShadows.glow(AppColors.cyanAccent, intensity: 0.4),
                                ),
                                child: ClipOval(
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                    child: Container(color: Colors.transparent),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 80),
                        
                        // Controls
                        if (!_isActive && !_isFinished) ...[
                          // Duration Selector
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(_durations.length, (index) {
                              final isSelected = _selectedDurationIndex == index;
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: BouncingButton(
                                  onTap: () => _setDuration(index),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected ? L.text : L.card,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: isSelected ? Colors.transparent : L.border.withValues(alpha: 0.1)),
                                    ),
                                    child: Text(
                                      '${_durations[index] ~/ 60}m',
                                      style: AppTypography.labelLarge.copyWith(
                                        color: isSelected ? L.bg : L.text,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 40),
                          
                          // Start Button
                          BouncingButton(
                            onTap: _startSession,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [AppColors.cyanAccent, AppColors.cyanAccent.withValues(alpha: 0.8)],
                                ),
                                borderRadius: BorderRadius.circular(32),
                                boxShadow: AppShadows.glow(AppColors.cyanAccent, intensity: 0.3),
                              ),
                              child: Text(
                                'START FOCUS',
                                style: AppTypography.labelLarge.copyWith(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          ),
                        ],
                        
                        if (_isFinished) ...[
                          BouncingButton(
                            onTap: () {
                              HapticEngine.selection();
                              Navigator.pop(context);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                              decoration: BoxDecoration(
                                color: L.card,
                                borderRadius: BorderRadius.circular(32),
                                border: Border.all(color: L.border.withValues(alpha: 0.1)),
                              ),
                              child: Text(
                                'DONE',
                                style: AppTypography.labelLarge.copyWith(
                                  color: L.text,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Confetti
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
                AppColors.cyanAccent,
                AppColors.lavenderAccent,
                AppColors.coralAccent,
                Colors.white,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
