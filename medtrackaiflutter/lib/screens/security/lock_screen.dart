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
  String? _errorMessage;

  /// Bumps on every attempt so a hung/stale auth future cannot unlock later.
  int _attempt = 0;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _authenticate();
    });
  }

  Future<void> _authenticate({bool force = false}) async {
    if (!mounted) return;
    if (_isAuthenticating && !force) return;

    final attempt = ++_attempt;
    if (force) {
      await BiometricService.cancelAuthentication();
    }

    setState(() {
      _isAuthenticating = true;
      _errorMessage = null;
    });

    try {
      final success = await BiometricService.authenticate();
      if (!mounted || attempt != _attempt) return;

      setState(() => _isAuthenticating = false);
      if (success) {
        HapticEngine.success();
        context.read<AppState>().unlockApp();
      } else {
        HapticEngine.error();
        setState(
          () => _errorMessage =
              'Authentication didn’t complete. Try again, or use your device PIN.',
        );
      }
    } catch (e) {
      if (!mounted || attempt != _attempt) return;
      setState(() {
        _isAuthenticating = false;
        _errorMessage = 'An error occurred during authentication.';
      });
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
                  AppColors.lime.withValues(alpha: 0.22),
                  AppColors.limeDeep.withValues(alpha: 0.10),
                ],
              ),
              boxShadow: AppShadows.glow(AppColors.limeDeep, intensity: 0.18),
            ),
            child: Center(
              child: _isAuthenticating
                  ? const AppLoadingIndicator(
                      size: 32, color: AppColors.limeDeep)
                  : Icon(
                      _errorMessage != null
                          ? Icons.error_outline_rounded
                          : Icons.lock_person_rounded,
                      color: _errorMessage != null
                          ? L.error
                          : AppColors.limeInk,
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
          // Always offer a way out — never hide the CTA while auth can hang.
          MedAiCTA(
            label: _isAuthenticating
                ? 'Manual retry'
                : (_errorMessage != null ? 'Try again' : 'Unlock now'),
            onTap: () {
              HapticEngine.selection();
              _authenticate(force: true);
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
