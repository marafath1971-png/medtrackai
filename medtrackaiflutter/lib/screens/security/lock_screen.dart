import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../providers/app_state.dart';
import '../../theme/med_ai_ui.dart';
import '../../core/utils/haptic_engine.dart';
import '../../services/biometric_service.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/common/app_loading_indicator.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  bool _isAuthenticating = false;
  bool _showRecoveryButton = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _authenticate();
    });
  }

  Future<void> _authenticate() async {
    if (!mounted || _isAuthenticating) return;
    setState(() {
      _isAuthenticating = true;
      _showRecoveryButton = false;
      _errorMessage = null;
    });

    final timer = Timer(const Duration(seconds: 5), () {
      if (mounted && _isAuthenticating) {
        setState(() => _showRecoveryButton = true);
      }
    });

    try {
      final success = await BiometricService.authenticate();
      timer.cancel();
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
          _showRecoveryButton = false;
        });
        if (success) {
          HapticEngine.success();
          context.read<AppState>().unlockApp();
        } else {
          HapticEngine.error();
          setState(
            () => _errorMessage = 'Authentication failed. Please try again.',
          );
        }
      }
    } catch (e) {
      timer.cancel();
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
          _showRecoveryButton = false;
          _errorMessage = 'An error occurred during authentication.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final reduceMotion = MedAiA11y.reducedMotion(context);

    Widget card = MedAiGlass(
      radius: AppRadius.squircle,
      blur: 32,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  L.accent.withValues(alpha: 0.16),
                  AppThemeColors2026.electric.withValues(alpha: 0.10),
                ],
              ),
              boxShadow: AppShadows.glow(L.accent, intensity: 0.2),
            ),
            child: Center(
              child: _isAuthenticating
                  ? AppLoadingIndicator(size: 32, color: L.accent)
                  : Icon(
                      _errorMessage != null
                          ? Icons.error_outline_rounded
                          : Icons.lock_person_rounded,
                      color: _errorMessage != null ? L.error : L.accent,
                      size: 40,
                    ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _isAuthenticating ? 'Authenticating…' : 'App locked',
            style: AppTypography.headlineMedium.copyWith(
              fontWeight: FontWeight.w800,
              color: L.text,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 12),
          Semantics(
            liveRegion: true,
            child: Text(
              _errorMessage ??
                  'Authenticate to access your health data and medication history.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: _errorMessage != null ? L.error : L.sub,
                height: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 32),
          if (!_isAuthenticating || _showRecoveryButton)
            MedAiCTA(
              label: _isAuthenticating
                  ? 'Manual retry'
                  : (_errorMessage != null ? 'Try again' : 'Unlock now'),
              onTap: () {
                HapticEngine.selection();
                _authenticate();
              },
              semanticsLabel: 'Unlock with biometrics',
            ),
        ],
      ),
    );

    if (!reduceMotion) {
      card = card
          .animate()
          .scale(
            begin: const Offset(0.96, 0.96),
            end: const Offset(1, 1),
            duration: 500.ms,
            curve: AppCurves.expressive,
          )
          .fadeIn(duration: 400.ms);
    }

    return AppScaffold(
      showAurora: true,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.88,
            child: card,
          ),
        ),
      ),
    );
  }
}
