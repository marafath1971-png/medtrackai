import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/constants.dart';
import '../../services/auth_service.dart';
import '../../services/referral_service.dart';
import '../../providers/app_state.dart';
import '../../theme/med_ai_ui.dart';
import '../../widgets/common/app_loading_indicator.dart';
import '../../services/smart_alert_service.dart';
import '../../widgets/shared/shared_widgets.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/common/med_ai_mascot.dart';
import '../../core/utils/haptic_engine.dart';

// ══════════════════════════════════════════════
// AUTH SCREEN — Sign In / Sign Up (2026)
// ══════════════════════════════════════════════

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isSignUp = false;
  bool _loading = false;
  String? _error;
  bool _showPass = false;
  bool _loadingApple = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _onAuthSuccess() async {
    HapticEngine.success();
    if (!MedAiA11y.reducedMotion(context)) {
      await Future.delayed(const Duration(milliseconds: 250));
    }
    if (!mounted) return;
    // Resolve the profile (returning user's cloud profile, or the freshly
    // onboarded one) and enter the app. Without this the phase never advances
    // past `auth` and the user is stranded on the sign-in screen.
    await context.read<AppState>().enterAppAfterAuth();
  }

  /// Lets a referred user enter their invite code manually — the reliable path
  /// when a deep link didn't open the app. Stored as a pending inbound code and
  /// redeemed on first app load (see AppShell._redeemPendingReferral).
  Future<void> _enterInviteCode() async {
    HapticEngine.selection();
    final ctrl = TextEditingController();
    final L = context.L;
    final code = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: L.card,
        title: Text('Have an invite code?',
            style: AppTypography.titleMedium.copyWith(color: L.text)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(hintText: 'e.g. AB3K9P'),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: TextStyle(color: L.sub))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text),
              child: Text('Apply', style: TextStyle(color: L.accent))),
        ],
      ),
    );
    ctrl.dispose();
    if (code == null || code.trim().isEmpty) return;
    await ReferralService.setPendingInbound(code);
    if (!mounted) return;
    SmartAlertService.show(
      context,
      title: 'Invite applied',
      message: 'Your free month unlocks after you set up your account.',
    );
  }

  Future<void> _submit() async {
    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      if (_isSignUp) {
        await AuthService.signUpWithEmail(
            _emailCtrl.text.trim(), _passCtrl.text);
      } else {
        await AuthService.signInWithEmail(
            _emailCtrl.text.trim(), _passCtrl.text);
      }
      await _onAuthSuccess();
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _friendlyError(e.code));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _googleSignIn() async {
    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      await AuthService.signInWithGoogle();
      await _onAuthSuccess();
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _friendlyError(e.code));
    } catch (e) {
      setState(() => _error = 'Google sign-in failed. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _appleSignIn() async {
    setState(() {
      _error = null;
      _loadingApple = true;
    });
    try {
      await AuthService.signInWithApple();
      await _onAuthSuccess();
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _friendlyError(e.code));
    } catch (e) {
      final msg = e.toString();
      if (!msg.contains('AuthorizationErrorCode.canceled') &&
          !msg.contains('com.apple.AuthenticationServices') &&
          !msg.contains('canceled')) {
        setState(() => _error = 'Apple sign-in failed. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _loadingApple = false);
    }
  }

  Future<void> _forgotPassword() async {
    if (_emailCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Enter your email first');
      return;
    }
    await AuthService.sendPasswordResetEmail(_emailCtrl.text.trim());
    if (mounted) {
      SmartAlertService.show(
        context,
        title: 'Email Sent',
        message: 'Password reset email sent ✓',
        type: AlertType.success,
      );
    }
  }

  void _showEmailSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EmailAuthSheet(
        isSignUp: _isSignUp,
        emailCtrl: _emailCtrl,
        passCtrl: _passCtrl,
        showPass: _showPass,
        loading: _loading,
        error: _error,
        onToggleSignUp: () {
          setState(() {
            _isSignUp = !_isSignUp;
            _error = null;
          });
          Navigator.pop(ctx);
          _showEmailSheet();
        },
        onTogglePass: () => setState(() => _showPass = !_showPass),
        onSubmit: () async {
          Navigator.pop(ctx);
          await _submit();
        },
        onForgot: _forgotPassword,
      ),
    );
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with that email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'email-already-in-use':
        return 'An account already exists with that email';
      case 'weak-password':
        return 'Password must be at least 6 characters';
      case 'invalid-email':
        return 'Please enter a valid email';
      case 'network-request-failed':
        return 'No internet connection';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final prefs = context.watch<AppState>().onboardingPrefs;
    final topPad = MediaQuery.of(context).padding.top;

    return AppScaffold(
      showAurora: true,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: topPad + 16),
                  Hero(
                    tag: 'medai-logo',
                    child: MedAiMascot(
                      size: 72,
                      semanticLabel: 'Med AI mascot',
                    ),
                  ).entranceHero(),
                  const SizedBox(height: 28),
                  Text(
                    _isSignUp ? 'Create your account' : 'Welcome back',
                    style: AppTypography.headlineLarge.copyWith(
                      color: L.text,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                    ),
                  ).entranceCard(0),
                  const SizedBox(height: 8),
                  Text(
                    prefs.personalizedAuthHeadline,
                    style: AppTypography.bodyLarge.copyWith(
                      color: L.sub,
                      height: 1.45,
                    ),
                  ).entranceCard(1),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    _AuthErrorBanner(message: _error!),
                  ],
                  const SizedBox(height: 28),
                  if (Theme.of(context).platform == TargetPlatform.iOS) ...[
                    _SocialAuthBtn(
                      label: 'Continue with Apple',
                      icon: Icons.apple_rounded,
                      variant: _SocialVariant.dark,
                      loading: _loadingApple,
                      onTap: _appleSignIn,
                    ).entranceCard(2),
                    const SizedBox(height: 12),
                  ],
                  _SocialAuthBtn(
                    label: 'Continue with Google',
                    imageAsset: 'assets/images/google_logo.png',
                    loading: _loading,
                    onTap: _googleSignIn,
                  ).entranceCard(3),
                  const SizedBox(height: 12),
                  _SocialAuthBtn(
                    label: 'Continue with Email',
                    icon: Icons.mail_outline_rounded,
                    onTap: _showEmailSheet,
                  ).entranceCard(4),
                  const SizedBox(height: 28),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      children: [
                        Text(
                          'By continuing, you agree to our ',
                          style: AppTypography.bodySmall.copyWith(
                            fontSize: 12,
                            color: L.sub.withValues(alpha: 0.6),
                          ),
                        ),
                        const _LegalLink(
                          label: 'Terms',
                          url: kTermsOfServiceUrl,
                        ),
                        Text(
                          ' and ',
                          style: AppTypography.bodySmall.copyWith(
                            fontSize: 12,
                            color: L.sub.withValues(alpha: 0.6),
                          ),
                        ),
                        const _LegalLink(
                          label: 'Privacy Policy',
                          url: kPrivacyPolicyUrl,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Semantics(
                      button: true,
                      label: 'Have an invite code',
                      child: AnimatedPressable(
                        onTap: _enterInviteCode,
                        hitTestPadding: const EdgeInsets.all(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Text(
                            'Have an invite code?',
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 13,
                              color: L.accent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _SocialVariant { light, dark }

class _SocialAuthBtn extends StatelessWidget {
  final String label;
  final IconData? icon;
  final String? imageAsset;
  final _SocialVariant variant;
  final bool loading;
  final VoidCallback onTap;

  const _SocialAuthBtn({
    required this.label,
    this.icon,
    this.imageAsset,
    this.variant = _SocialVariant.light,
    this.loading = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final isDark = variant == _SocialVariant.dark;

    return Semantics(
      button: true,
      enabled: !loading,
      label: label,
      child: AnimatedPressable(
        onTap: loading ? null : onTap,
        disabled: loading,
        scaleFactor: 0.98,
        child: MedAiGlass(
          radius: AppRadius.l,
          blur: 24,
          tint: isDark ? L.text : L.card,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (loading)
                AppLoadingIndicator(
                  size: 20,
                  color: isDark ? Colors.white : L.text,
                )
              else if (imageAsset != null)
                Image.asset(imageAsset!, width: 20, height: 20)
              else if (icon != null)
                Icon(icon, size: 22, color: isDark ? Colors.white : L.text),
              const SizedBox(width: 12),
              Text(
                label,
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : L.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthErrorBanner extends StatelessWidget {
  final String message;
  const _AuthErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: L.error.withValues(alpha: 0.1),
        borderRadius: AppRadius.roundM,
        border: Border.all(color: L.error.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: L.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall.copyWith(
                color: L.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ).entranceCard(0);
  }
}

class _LegalLink extends StatelessWidget {
  final String label;
  final String url;
  const _LegalLink({required this.label, required this.url});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Semantics(
      link: true,
      label: label,
      child: AnimatedPressable(
        onTap: () async {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) launchUrl(uri);
        },
        scaleFactor: 0.98,
        child: Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            fontSize: 12,
            color: L.text,
            fontWeight: FontWeight.w700,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }
}

class _EmailAuthSheet extends StatelessWidget {
  final bool isSignUp;
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final bool showPass;
  final bool loading;
  final String? error;
  final VoidCallback onToggleSignUp;
  final VoidCallback onTogglePass;
  final VoidCallback onSubmit;
  final VoidCallback onForgot;

  const _EmailAuthSheet({
    required this.isSignUp,
    required this.emailCtrl,
    required this.passCtrl,
    required this.showPass,
    required this.loading,
    required this.error,
    required this.onToggleSignUp,
    required this.onTogglePass,
    required this.onSubmit,
    required this.onForgot,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: L.card.withValues(alpha: context.isDark ? 0.88 : 0.94),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(
                top: BorderSide(color: L.glassBorder.withValues(alpha: 0.35)),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: L.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    isSignUp ? 'Sign up with email' : 'Sign in with email',
                    style: AppTypography.headlineSmall.copyWith(
                      color: L.text,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _AuthField(
                    controller: emailCtrl,
                    label: 'Email address',
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    L: L,
                  ),
                  const SizedBox(height: 12),
                  _AuthField(
                    controller: passCtrl,
                    label: 'Password',
                    obscure: !showPass,
                    autofillHints: isSignUp
                        ? const [AutofillHints.newPassword]
                        : const [AutofillHints.password],
                    suffix: Semantics(
                      button: true,
                      label: showPass ? 'Hide password' : 'Show password',
                      child: AnimatedPressable(
                        onTap: onTogglePass,
                        hitTestPadding: const EdgeInsets.all(8),
                        child: Icon(
                          showPass
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          color: L.sub,
                          size: 20,
                        ),
                      ),
                    ),
                    L: L,
                  ),
                  if (!isSignUp) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: Semantics(
                        button: true,
                        label: 'Forgot password',
                        child: AnimatedPressable(
                          onTap: onForgot,
                          hitTestPadding: const EdgeInsets.all(4),
                          child: Text(
                            'Forgot password?',
                            style: AppTypography.labelMedium.copyWith(
                              color: AppThemeColors2026.electric,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    _AuthErrorBanner(message: error!),
                  ],
                  const SizedBox(height: 20),
                  MedAiCTA(
                    label: isSignUp ? 'Create Account' : 'Sign In',
                    loading: loading,
                    onTap: loading ? null : onSubmit,
                    semanticsLabel:
                        isSignUp ? 'Create account' : 'Sign in with email',
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Semantics(
                      button: true,
                      label: isSignUp
                          ? 'Switch to sign in'
                          : 'Switch to sign up',
                      child: AnimatedPressable(
                        onTap: onToggleSignUp,
                        hitTestPadding: const EdgeInsets.all(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            isSignUp
                                ? 'Already have an account? Sign In'
                                : "Don't have an account? Sign Up",
                            style: AppTypography.labelMedium.copyWith(
                              color: L.sub,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscure;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final Widget? suffix;
  final AppThemeColors L;

  const _AuthField({
    required this.controller,
    required this.label,
    required this.L,
    this.obscure = false,
    this.keyboardType,
    this.autofillHints,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      textField: true,
      label: label,
      child: Container(
        constraints: const BoxConstraints(minHeight: AppA11y.minTapTarget),
        decoration: BoxDecoration(
          color: L.fill,
          borderRadius: AppRadius.roundL,
          border: Border.all(color: L.border.withValues(alpha: 0.35), width: 0.5),
        ),
        child: TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          autofillHints: autofillHints,
          style: AppTypography.bodyLarge.copyWith(
            color: L.text,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: AppTypography.bodySmall.copyWith(color: L.sub),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 16,
            ),
            suffixIcon: suffix != null
                ? Padding(
                    padding: const EdgeInsetsDirectional.only(end: 12),
                    child: suffix,
                  )
                : null,
            suffixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
          ),
        ),
      ),
    );
  }
}
