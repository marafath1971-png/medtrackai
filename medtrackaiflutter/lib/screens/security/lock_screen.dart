import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../providers/app_state.dart';
import '../../theme/med_ai_ui.dart';
import '../../core/utils/haptic_engine.dart';
import '../../services/biometric_service.dart';
import '../../core/constants/med_ai_assets.dart';
import '../../widgets/common/ghost_mascot.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/common/app_loading_indicator.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen>
    with WidgetsBindingObserver {
  bool _isAuthenticating = false;
  String? _errorMessage;

  /// Bumps on every attempt so a hung/stale auth future cannot unlock later.
  int _attempt = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _authenticate();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// The system prompt cannot be shown while the Activity is stopping, and
  /// asking anyway leaves the app waiting 25s for a dialog that never
  /// appeared. A call arriving during the unlock did exactly that:
  ///
  ///   App backgrounded
  ///   BiometricPromptCompat: Unable to start authentication.
  ///     Called after onSaveInstanceState()
  ///   Biometric authentication timed out after 25s
  ///
  /// So the prompt is cancelled on the way out and re-offered on return
  /// rather than left hanging.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (!mounted) return;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      if (_isAuthenticating) {
        // Invalidate the in-flight attempt so its late result cannot unlock
        // the app after the user has switched away.
        _attempt++;
        BiometricService.cancelAuthentication();
        setState(() => _isAuthenticating = false);
      }
      return;
    }

    if (state == AppLifecycleState.resumed &&
        !_isAuthenticating &&
        _errorMessage == null) {
      // Back in the foreground with nothing in flight: offer the prompt
      // again, rather than leaving a lock screen the user cannot dismiss.
      _authenticate(force: true);
    }
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
          // The mascot carries the state instead of a bare icon. A failed
          // unlock is a routine speed bump — the previous red error glyph over
          // red body text made a locked app look like something had gone
          // seriously wrong with the user's health data.
          SizedBox(
            height: 108,
            child: Center(
              child: _isAuthenticating
                  ? const AppLoadingIndicator(
                      size: 32, color: AppColors.limeDeep)
                  : GhostMascot(
                      // A guard when locked; a shrug when auth didn't take.
                      asset: _errorMessage != null
                          ? MedAiAssets.mascotSearchTime
                          : MedAiAssets.mascotShieldGuard,
                      size: 104,
                      showGlow: true,
                      semanticLabel: _errorMessage != null
                          ? 'Unlock did not complete'
                          : 'App locked',
                    ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _isAuthenticating ? 'Authenticating…' : 'App locked',
            style: AppTypography.headlineMedium.copyWith(
              fontWeight: FontWeight.w700,
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
                // Deliberately not L.error. A biometric prompt that was
                // dismissed or timed out is an ordinary retry, and full-width
                // red body copy framed it as a failure of the app itself.
                color: L.sub,
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
