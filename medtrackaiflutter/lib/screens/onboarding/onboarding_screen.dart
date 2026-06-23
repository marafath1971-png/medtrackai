// ignore_for_file: unused_local_variable, unused_import
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../core/utils/haptic_engine.dart';
import '../../models/constants.dart';
import '../../theme/app_theme.dart';
import '../../services/notification_service.dart';
import '../../services/auth_service.dart';
import '../../core/utils/date_formatter.dart';
import '../../widgets/mascot_widget.dart';
import 'package:medai/widgets/common/animated_pressable.dart';

// ══════════════════════════════════════════════════════
// MED AI — 2026 ONBOARDING
// Single-CTA, gesture-first, interactive, conversion-focused
// ══════════════════════════════════════════════════════

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  int _step = 0;
  late AnimationController _fadeCtrl;
  late AnimationController _bgCtrl;
  late Animation<double> _bgPulse;

  // Store Compliance State
  bool _agreeToPolicies = false;
  bool _acceptDisclaimer = false;

  final Map<String, dynamic> _form = {
    'name': '',
    'goal': '',
    'target_user': '',
    'med_count': '',
    'pain_points': <String>[],
    'forget_freq': '',
    'wakeTime': {'h': 7, 'm': 0},
    'sleepTime': {'h': 22, 'm': 0},
    'notifPerm': false,
    'avatar': '👤',
    'country': '',
  };

  List<_OBStep> get _steps => [
        const _OBStep(id: 'splash', type: 'splash'),
        const _OBStep(id: 'consent', type: 'consent'),
        const _OBStep(
            id: 'goal',
            type: 'single',
            emoji: '🛡️',
            title: "What's your main\nhealth goal?",
            subtitle: 'This shapes your entire AI experience',
            field: 'goal',
            options: kHealthGoals),
        const _OBStep(
            id: 'target_user',
            type: 'single',
            emoji: '🎯',
            title: "Who are you\ntracking for?",
            subtitle: 'You can add family members later',
            field: 'target_user',
            options: kTrackingTargets),
        const _OBStep(
            id: 'name',
            type: 'text',
            emoji: '🤝',
            title: "What's your name?",
            subtitle: "We'll personalise everything for you",
            field: 'name',
            placeholder: 'Your first name'),
        const _OBStep(
            id: 'med_count',
            type: 'single',
            emoji: '💊',
            title: "How many medications\ndo you take?",
            subtitle: 'This helps our AI tailor your schedule',
            field: 'med_count',
            options: kMedCounts),
        const _OBStep(
            id: 'pain_points',
            type: 'multi',
            emoji: '📉',
            title: "Your biggest\nmedication struggle?",
            subtitle: 'Med AI solves all of these for you',
            field: 'pain_points',
            options: kPainPoints),
        const _OBStep(
            id: 'forget_freq',
            type: 'single',
            emoji: '⏰',
            title: "How often do you\nforget a dose?",
            subtitle: "Be honest — no judgment here",
            field: 'forget_freq',
            options: kForgetFreq),
        const _OBStep(id: 'loading_analysis', type: 'loading_analysis'),
        const _OBStep(
            id: 'data_graph',
            type: 'data_graph',
            title: 'Your Adherence Journey',
            subtitle: 'See what Med AI will do for you'),
        const _OBStep(
            id: 'wake_time',
            type: 'time',
            emoji: '☀️',
            title: 'When do you\nwake up?',
            subtitle: 'Used as anchor for your daily tracking',
            field: 'wakeTime'),
        const _OBStep(
            id: 'sleep_time',
            type: 'time',
            emoji: '🌙',
            title: 'When do you\ngo to bed?',
            subtitle: "We won't disturb you while you sleep",
            field: 'sleepTime'),
        const _OBStep(id: 'plan', type: 'plan'),
        const _OBStep(id: 'social_proof', type: 'social_proof'),
        const _OBStep(id: 'notif', type: 'notif'),
        const _OBStep(id: 'commit', type: 'commit'),
        const _OBStep(id: 'paywall', type: 'paywall'),
      ];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _bgCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 4000))
      ..repeat(reverse: true);
    _bgPulse = Tween(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _bgCtrl, curve: Curves.easeInOut));
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _bgCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_step < _steps.length - 1) {
      HapticEngine.selection();
      setState(() => _step++);
      if (_steps[_step].id == 'paywall') {
        context.read<AppState>().logPaywallEvent('paywall_viewed');
      }
      _fadeCtrl.forward(from: 0);
    } else {
      _complete();
    }
  }

  void _back() {
    if (_step > 0 && _steps[_step].type != 'loading_analysis') {
      HapticEngine.selection();
      setState(() => _step--);
      _fadeCtrl.forward(from: 0);
    }
  }

  void _complete() {
    final profile = UserProfile(
      name: _form['name'] ?? '',
      goal: _form['goal'] ?? '',
      targetUser: _form['target_user'] ?? '',
      wakeTime: Map<String, int>.from(_form['wakeTime'] ?? {'h': 7, 'm': 0}),
      sleepTime: Map<String, int>.from(_form['sleepTime'] ?? {'h': 22, 'm': 0}),
      notifPerm: _form['notifPerm'] ?? false,
      avatar: _form['avatar'] ?? '👤',
      country: _form['country'] ?? '',
      promoCode: null,
      appliedPromo: null,
    );
    context.read<AppState>().completeOnboarding(profile);
  }

  bool _canContinue(_OBStep step) {
    if (step.type == 'splash' ||
        step.type == 'social_proof' ||
        step.type == 'notif' ||
        step.type == 'plan' ||
        step.type == 'data_graph' ||
        step.type == 'health_sync') {
      return true;
    }
    if (step.type == 'paywall') return true;
    if (step.type == 'consent') {
      return _agreeToPolicies && _acceptDisclaimer;
    }
    if (step.field == null) return true;
    final v = _form[step.field!];
    if (v == null) return false;
    if (v is String) return v.isNotEmpty;
    if (v is List) return v.isNotEmpty;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_step];
    final isPaywall = step.type == 'paywall';
    final isSplash = step.type == 'splash';
    final isLoading = step.type == 'loading_analysis';
    
    final visibleSteps = _steps.where((s) => s.type != 'splash' && s.type != 'paywall' && s.type != 'loading_analysis').toList();
    final currentVisibleIndex = visibleSteps.indexOf(step);
    final progress = currentVisibleIndex >= 0 ? (currentVisibleIndex + 1) / visibleSteps.length : 0.0;
    
    final L = context.L;

    final monoTheme = Theme.of(context).copyWith(
      scaffoldBackgroundColor: const Color(0xFFF5F5F0),
      colorScheme:
          const ColorScheme.light(primary: Color(0xFF1C1C1E), secondary: Color(0xFF3A7D6A)),
      extensions: [
        AppThemeColors.fromColorScheme(
          const ColorScheme.light(primary: Color(0xFF1C1C1E), secondary: Color(0xFF3A7D6A)),
          Brightness.light,
        ).copyWith(
          bg: const Color(0xFFF5F5F0),
          text: const Color(0xFF1C1C1E),
          sub: const Color(0xFF64736D),
          card: const Color(0xFFFFFFFF),
          border: const Color(0xFFE2E8E4),
          glassBorder: const Color(0xFF1C1C1E).withValues(alpha: 0.1),
          fill: const Color(0xFFEBEBE5),
        )
      ],
    );

    return Theme(
      data: monoTheme,
      child: Builder(
        builder: (context) {
          final L = context.L; // Get the overridden theme
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.dark, // Always dark text for light olive theme
            child: Scaffold(
              backgroundColor: L.bg,
              resizeToAvoidBottomInset: false,
              body: SafeArea(
                child: Column(children: [
            // ── Top Bar (hidden on splash, paywall, loading)
            if (!isSplash && !isPaywall && !isLoading)
              _TopBar(
                step: currentVisibleIndex,
                total: visibleSteps.length,
                progress: progress,
                onBack: _step > 0 ? _back : null,
              ),

            // ── Content
            Expanded(
              child: FadeTransition(
                opacity: _fadeCtrl,
                child: _buildStep(step, L),
              ),
            ),

            // ── Bottom CTA (only visible on non-auto-advancing steps)
            if (!isPaywall && !isSplash && !isLoading && step.type != 'data_graph')
              _BottomCTA(
                step: step,
                canGo: _canContinue(step),
                onTap: () async {
                  if (step.type == 'notif') {
                    final granted =
                        await NotificationService.requestPermission();
                    setState(() => _form['notifPerm'] = granted);
                  }
                  _next();
                },
              ),
          ]),
        ),
      ),
    );
    },
    ),
    );
  }

  Widget _buildStep(_OBStep step, AppThemeColors L) {
    switch (step.type) {
      case 'splash':
        return _SplashStep(onNext: _next, pulse: _bgPulse);
      case 'consent':
        return _ConsentStep(
          agreeToPolicies: _agreeToPolicies,
          acceptDisclaimer: _acceptDisclaimer,
          onAgreeChanged: (val) => setState(() => _agreeToPolicies = val),
          onDisclaimerChanged: (val) => setState(() => _acceptDisclaimer = val),
        );
      case 'text':
        return _TextStep(
            step: step,
            form: _form,
            onChanged: (k, v) => setState(() => _form[k] = v),
            onNext: _next);
      case 'single':
        return _SingleStep(
            step: step,
            form: _form,
            onSelect: (k, v) {
              setState(() => _form[k] = v);
              Future.delayed(const Duration(milliseconds: 300), () {
                if (mounted && _canContinue(step)) _next();
              });
            });
      case 'multi':
        return _MultiStep(
            step: step,
            form: _form,
            onSelect: (k, v) => setState(() => _form[k] = v));
      case 'time':
        return _TimeStep(
            step: step,
            form: _form,
            onChanged: (k, v) => setState(() => _form[k] = v));
      case 'notif':
        return _NotifStep(
            form: _form,
            onChanged: (k, v) => setState(() => _form[k] = v));
      case 'plan':
        return _PlanReadyStep(form: _form, onNext: _next);
      case 'commit':
        return _CommitStep(onNext: _next);
      case 'paywall':
        return _PaywallStep(
          form: _form,
          onComplete: _complete,
          onAuth: _next,
          onBack: _back,
        );
      case 'social_proof':
        return _SocialProofStep(form: _form);
      case 'loading_analysis':
        return _LoadingAnalysisStep(onNext: _next);
      case 'data_graph':
        return _DataGraphStep(
            step: step, form: _form, onNext: _next);
      default:
        return const SizedBox.shrink();
    }
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// DATA MODELS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _OBStep {
  final String id;
  final String type;
  final String title;
  final String subtitle;
  final String emoji;
  final String? field;
  final String? placeholder;
  final List<Map<String, String>>? options;

  const _OBStep({
    required this.id,
    required this.type,
    this.title = '',
    this.subtitle = '',
    this.emoji = '',
    this.field,
    this.placeholder,
    this.options,
  });
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// TOP BAR
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _TopBar extends StatelessWidget {
  final int step, total;
  final double progress;
  final VoidCallback? onBack;

  const _TopBar(
      {required this.step,
      required this.total,
      required this.progress,
      this.onBack});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          AnimatedPressable(
            onTap: onBack,
            child: AnimatedOpacity(
              opacity: onBack != null ? 1.0 : 0.0,
              duration: 200.ms,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: L.fill,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_back_ios_new_rounded,
                    color: L.text, size: 16),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: L.sub.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progress),
                  duration: 400.ms,
                  curve: Curves.easeOutCubic,
                  builder: (_, v, __) => FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: v,
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        color: L.text,
                        borderRadius: BorderRadius.circular(99),
                        boxShadow: [
                          BoxShadow(
                            color: L.text.withValues(alpha: 0.3),
                            blurRadius: 4,
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${step + 1}/$total',
            style: AppTypography.labelSmall.copyWith(fontFamily: 'Courier', 
              color: L.sub,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// BOTTOM CTA — single button, no duplication
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _BottomCTA extends StatelessWidget {
  final _OBStep step;
  final bool canGo;
  final VoidCallback? onTap;

  const _BottomCTA(
      {required this.step, required this.canGo, required this.onTap});

  String get _label {
    switch (step.type) {
      case 'notif':
        return 'Allow Notifications';
      case 'plan':
        return 'See My Plan →';
      case 'social_proof':
        return 'Continue';
      case 'consent':
        return 'Accept & Continue';
      default:
        return 'Continue';
    }
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return AnimatedPressable(
      onTap: canGo ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
        child: AnimatedContainer(
          duration: 250.ms,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 19),
          decoration: BoxDecoration(
            color: canGo ? L.text : L.sub.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(32),
            boxShadow: canGo ? AppShadows.glow(L.text, intensity: 0.12) : null,
          ),
          child: Builder(
            builder: (context) {
              final textWidget = Text(
                _label,
                textAlign: TextAlign.center,
                style: AppTypography.labelLarge.copyWith(fontFamily: 'Courier', 
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: canGo ? L.bg : L.sub.withValues(alpha: 0.4),
                  letterSpacing: 0.2,
                ),
              );

              if (canGo) {
                return textWidget.animate(onPlay: (c) => c.repeat(reverse: true))
                    .shimmer(duration: 2500.ms, delay: 1000.ms, color: Colors.white54);
              }
              return textWidget;
            },
          ),
        ),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// STEP HEADER
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _StepHeader extends StatelessWidget {
  final String emoji, title, subtitle;

  const _StepHeader({
    required this.title,
    this.subtitle = '',
    this.emoji = '',
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (emoji.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(emoji,
                style: AppTypography.displayLarge.copyWith(fontFamily: 'Courier', 
                    fontSize: 44, height: 1.0)),
          ),
        Text(title,
            style: AppTypography.displayLarge.copyWith(fontFamily: 'Courier', 
                fontSize: 30,
                color: L.text,
                letterSpacing: -0.8,
                fontWeight: FontWeight.w800,
                height: 1.2)),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(subtitle,
              style: AppTypography.bodyMedium.copyWith(fontFamily: 'Courier', 
                  fontSize: 15,
                  color: L.sub,
                  height: 1.5,
                  fontWeight: FontWeight.w500)),
        ],
      ],
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// SPLASH — Full-screen brand intro, single tap to start
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _SplashStep extends StatefulWidget {
  final VoidCallback onNext;
  final Animation<double> pulse;
  const _SplashStep({required this.onNext, required this.pulse});

  @override
  State<_SplashStep> createState() => _SplashStepState();
}

class _SplashStepState extends State<_SplashStep>
    with TickerProviderStateMixin {
  late AnimationController _floatCtrl;
  late Animation<double> _float;
  late AnimationController _shimCtrl;

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3200))
      ..repeat(reverse: true);
    _float = Tween(begin: 0.0, end: -8.0)
        .animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));

    _shimCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat();
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    _shimCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final isDark = context.isDark;

    return AnimatedPressable(
      onTap: widget.onNext,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
          // Animated orb background
          AnimatedBuilder(
            animation: widget.pulse,
            builder: (_, __) {
              return Positioned.fill(
                child: CustomPaint(
                  painter: _OrbPainter(
                    progress: widget.pulse.value,
                    color: isDark
                        ? const Color(0xFF1C1C1E)
                        : const Color(0xFFE8E8E8),
                  ),
                ),
              );
            },
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const SizedBox(height: 60),

                // Logo + App name
                AnimatedBuilder(
                  animation: _float,
                  builder: (_, child) => Transform.translate(
                    offset: Offset(0, _float.value),
                    child: child,
                  ),
                  child: Column(
                    children: [
                      const MascotWidget(size: 140, mood: 'energetic'),
                      const SizedBox(height: 20),
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: AppTypography.displayLarge.copyWith(fontFamily: 'Courier', 
                              fontSize: 38,
                              letterSpacing: -1.2,
                              height: 1.0,
                              fontWeight: FontWeight.w900),
                          children: [
                            TextSpan(
                                text: 'Med',
                                style: TextStyle(color: L.text)),
                            TextSpan(
                                text: ' AI',
                                style: TextStyle(
                                    color: L.text,
                                    fontWeight: FontWeight.w200)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Your intelligent medicine companion',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMedium.copyWith(fontFamily: 'Courier', 
                            fontSize: 15,
                            color: L.sub,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  )
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .slideY(
                          begin: 0.2,
                          end: 0,
                          duration: 700.ms,
                          curve: Curves.easeOutCubic),
                ),

                const SizedBox(height: 48),

                // 3 Value props — horizontal cards
                ...[
                  (
                    '🔍',
                    'AI Scan',
                    'Instant medicine identification'
                  ),
                  (
                    '⚡',
                    'Smart Reminders',
                    'Perfectly timed, never annoying'
                  ),
                  (
                    '📈',
                    '98% Adherence',
                    'Average after 30 days with Med AI'
                  ),
                ].asMap().entries.map((e) {
                  final i = e.key;
                  final item = e.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 16),
                    decoration: BoxDecoration(
                      color: L.card,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color: L.glassBorder, width: 1),
                    ),
                    child: Row(children: [
                      Text(item.$1,
                          style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 14),
                      Expanded(
                          child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.$2,
                              style: AppTypography.labelLarge
                                  .copyWith(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: L.text)),
                          const SizedBox(height: 2),
                          Text(item.$3,
                              style: AppTypography.bodySmall
                                  .copyWith(
                                      fontSize: 12,
                                      color: L.sub)),
                        ],
                      )),
                    ]),
                  )
                      .animate(delay: (400 + 100 * i).ms)
                      .fadeIn(duration: 400.ms)
                      .slideX(
                          begin: 0.08,
                          end: 0,
                          curve: Curves.easeOutCubic);
                }),

                const Spacer(),

                // Primary CTA — full-width, single
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: L.text,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: AppShadows.glow(L.text, intensity: 0.15),
                  ),
                  child: Text(
                    'Get Started Free →',
                    textAlign: TextAlign.center,
                    style: AppTypography.labelLarge.copyWith(fontFamily: 'Courier', 
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: L.bg,
                      letterSpacing: 0.2,
                    ),
                  ),
                )
                    .animate(delay: 800.ms)
                    .fadeIn(duration: 500.ms)
                    .slideY(
                        begin: 0.3,
                        end: 0,
                        curve: Curves.easeOutBack),

                const SizedBox(height: 16),
                Text(
                  'Free to start · No credit card required',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(fontFamily: 'Courier', 
                      fontSize: 11, color: L.sub.withValues(alpha: 0.6)),
                ).animate(delay: 900.ms).fadeIn(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Animated orb background painter
class _OrbPainter extends CustomPainter {
  final double progress;
  final Color color;

  _OrbPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * 0.8;
    final cy = size.height * 0.15 + progress * 20;
    final r = size.width * 0.6;

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color.withValues(alpha: 0.6), color.withValues(alpha: 0)],
        radius: 0.8,
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));

    canvas.drawCircle(Offset(cx, cy), r, paint);

    final cx2 = size.width * 0.1;
    final cy2 = size.height * 0.7 - progress * 15;
    final paint2 = Paint()
      ..shader = RadialGradient(
        colors: [color.withValues(alpha: 0.4), color.withValues(alpha: 0)],
        radius: 0.8,
      ).createShader(
          Rect.fromCircle(center: Offset(cx2, cy2), radius: r * 0.7));
    canvas.drawCircle(Offset(cx2, cy2), r * 0.7, paint2);
  }

  @override
  bool shouldRepaint(covariant _OrbPainter old) =>
      old.progress != progress;
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// TEXT STEP
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _TextStep extends StatefulWidget {
  final _OBStep step;
  final Map<String, dynamic> form;
  final Function(String, String) onChanged;
  final VoidCallback onNext;

  const _TextStep(
      {required this.step,
      required this.form,
      required this.onChanged,
      required this.onNext});

  @override
  State<_TextStep> createState() => _TextStepState();
}

class _TextStepState extends State<_TextStep> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
        text: widget.form[widget.step.field!]?.toString() ?? '');
    _ctrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final hasVal = _ctrl.text.trim().isNotEmpty;

    return AnimatedPressable(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _StepHeader(
              emoji: widget.step.emoji,
              title: widget.step.title,
              subtitle: widget.step.subtitle),
          const SizedBox(height: 32),
          AnimatedContainer(
            duration: 200.ms,
            decoration: BoxDecoration(
              color: L.fill,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: hasVal ? L.text : L.sub.withValues(alpha: 0.15),
                  width: 1.5),
            ),
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              style: AppTypography.displayLarge.copyWith(fontFamily: 'Courier', 
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: L.text,
                  letterSpacing: -0.3),
              onChanged: (v) => widget.onChanged(widget.step.field!, v),
              onSubmitted: (_) {
                if (hasVal) widget.onNext();
              },
              decoration: InputDecoration(
                hintText: widget.step.placeholder,
                hintStyle: AppTypography.displayLarge.copyWith(fontFamily: 'Courier', 
                    fontSize: 22,
                    fontWeight: FontWeight.w300,
                    color: L.sub.withValues(alpha: 0.35),
                    letterSpacing: -0.3),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
              ),
            ),
          ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.04, end: 0),
        ]),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// SINGLE SELECT STEP
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _SingleStep extends StatelessWidget {
  final _OBStep step;
  final Map<String, dynamic> form;
  final Function(String, String) onSelect;

  const _SingleStep(
      {required this.step, required this.form, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final selected = form[step.field!]?.toString() ?? '';
    final isGrid = (step.options?.length ?? 0) > 4;

    return SingleChildScrollView(
  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      physics:
          const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StepHeader(
                emoji: step.emoji,
                title: step.title,
                subtitle: step.subtitle),
            const SizedBox(height: 24),
            if (isGrid)
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.15,
                children: step.options!.map((opt) {
                  final val = opt['c'] ?? opt['v']!;
                  return _OptionCard(
                      opt: opt,
                      isSelected: selected == val,
                      isGrid: true,
                      onTap: () => onSelect(step.field!, val));
                }).toList(),
              )
            else
              ...step.options!.asMap().entries.map((e) {
                final i = e.key;
                final opt = e.value;
                final val = opt['c'] ?? opt['v']!;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _OptionCard(
                    opt: opt,
                    isSelected: selected == val,
                    isGrid: false,
                    onTap: () => onSelect(step.field!, val),
                  ),
                )
                    .animate(delay: (i * 50).ms)
                    .fadeIn(duration: 300.ms)
                    .slideX(begin: 0.04, end: 0);
              }),
          ]),
    );
  }
}

class _OptionCard extends StatefulWidget {
  final Map<String, String> opt;
  final bool isSelected, isGrid;
  final VoidCallback onTap;

  const _OptionCard(
      {required this.opt,
      required this.isSelected,
      required this.isGrid,
      required this.onTap});

  @override
  State<_OptionCard> createState() => _OptionCardState();
}

class _OptionCardState extends State<_OptionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return AnimatedPressable(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        HapticEngine.selection();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: 150.ms,
        child: AnimatedContainer(
          duration: 200.ms,
          width: double.infinity,
          padding: EdgeInsets.symmetric(
              horizontal: widget.isGrid ? 12 : 20, vertical: 16),
          decoration: BoxDecoration(
            color: widget.isSelected ? L.text : L.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: widget.isSelected
                    ? L.text
                    : L.sub.withValues(alpha: 0.14),
                width: 1.5),
          ),
          child: widget.isGrid
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.opt['e'] != null)
                      Text(widget.opt['e']!,
                          style: const TextStyle(fontSize: 28)),
                    if (widget.opt['e'] != null) const SizedBox(height: 10),
                    Text(widget.opt['v']!,
                        textAlign: TextAlign.center,
                        style: AppTypography.labelLarge.copyWith(fontFamily: 'Courier', 
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: widget.isSelected ? L.bg : L.text)),
                  ],
                )
              : Row(children: [
                  if (widget.opt['e'] != null)
                    Text(widget.opt['e']!,
                        style: const TextStyle(fontSize: 22)),
                  if (widget.opt['e'] != null) const SizedBox(width: 14),
                  Expanded(
                      child: Text(widget.opt['v']!,
                          style: AppTypography.bodyMedium.copyWith(fontFamily: 'Courier', 
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color:
                                  widget.isSelected ? L.bg : L.text))),
                  if (widget.isSelected)
                    Icon(Icons.check_circle_rounded,
                            color: L.bg, size: 18)
                        .animate()
                        .scale(duration: 200.ms, curve: Curves.easeOutBack),
                ]),
        ),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MULTI SELECT STEP
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _MultiStep extends StatelessWidget {
  final _OBStep step;
  final Map<String, dynamic> form;
  final Function(String, List<String>) onSelect;

  const _MultiStep(
      {required this.step, required this.form, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final selected = List<String>.from(form[step.field!] ?? []);
    final L = context.L;

    return SingleChildScrollView(
  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      physics:
          const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _StepHeader(
            emoji: step.emoji,
            title: step.title,
            subtitle: step.subtitle),
        const SizedBox(height: 24),
        ...(step.options ?? []).asMap().entries.map((e) {
          final i = e.key;
          final opt = e.value;
          final isSel = selected.contains(opt['v']!);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _MultiOptionRow(
              opt: opt,
              isSelected: isSel,
              onTap: () {
                HapticEngine.selection();
                final newSel = isSel
                    ? (selected..remove(opt['v']!))
                    : [...selected, opt['v']!];
                onSelect(step.field!, newSel);
              },
            ),
          )
              .animate(delay: (i * 50).ms)
              .fadeIn(duration: 300.ms)
              .slideX(begin: 0.04, end: 0);
        }),
      ]),
    );
  }
}

class _MultiOptionRow extends StatefulWidget {
  final Map<String, String> opt;
  final bool isSelected;
  final VoidCallback onTap;

  const _MultiOptionRow(
      {required this.opt,
      required this.isSelected,
      required this.onTap});

  @override
  State<_MultiOptionRow> createState() => _MultiOptionRowState();
}

class _MultiOptionRowState extends State<_MultiOptionRow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return AnimatedPressable(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: 150.ms,
        child: AnimatedContainer(
          duration: 200.ms,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: widget.isSelected ? L.text : L.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: widget.isSelected
                    ? L.text
                    : L.sub.withValues(alpha: 0.14),
                width: 1.5),
          ),
          child: Row(children: [
            AnimatedContainer(
              duration: 200.ms,
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isSelected ? L.bg : Colors.transparent,
                border: Border.all(
                    color: widget.isSelected
                        ? L.bg
                        : L.sub.withValues(alpha: 0.3),
                    width: 2),
              ),
              child: widget.isSelected
                  ? Icon(Icons.check_rounded, color: L.text, size: 14)
                  : null,
            ),
            const SizedBox(width: 14),
            if (widget.opt['e'] != null)
              Text(widget.opt['e']!,
                  style: const TextStyle(fontSize: 20)),
            if (widget.opt['e'] != null) const SizedBox(width: 10),
            Expanded(
              child: Text(widget.opt['v']!,
                  style: AppTypography.bodyMedium.copyWith(fontFamily: 'Courier', 
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: widget.isSelected ? L.bg : L.text)),
            ),
          ]),
        ),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// TIME STEP
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _TimeStep extends StatelessWidget {
  final _OBStep step;
  final Map<String, dynamic> form;
  final Function(String, Map<String, int>) onChanged;

  const _TimeStep(
      {required this.step,
      required this.form,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final time =
        Map<String, int>.from(form[step.field!] ?? {'h': 8, 'm': 0});
    final h = time['h'] ?? 8;
    final m = time['m'] ?? 0;

    return SingleChildScrollView(
  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      physics:
          const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _StepHeader(
            emoji: step.emoji,
            title: step.title,
            subtitle: step.subtitle),
        const SizedBox(height: 32),

        // Quick time presets
        Row(children: kQuickTimes.map((qt) {
          final isActive = h == qt['h'] && m == qt['m'];
          return Expanded(
              child: AnimatedPressable(
            onTap: () {
              HapticEngine.selection();
              onChanged(step.field!, {
                'h': qt['h'] as int,
                'm': qt['m'] as int
              });
            },
            child: AnimatedContainer(
              duration: 200.ms,
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isActive ? L.text : L.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: isActive
                        ? L.text
                        : L.sub.withValues(alpha: 0.12),
                    width: 1.5),
              ),
              child: Column(children: [
                Text(qt['emoji'] as String,
                    style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 4),
                Text(qt['label'] as String,
                    style: AppTypography.labelSmall.copyWith(fontFamily: 'Courier', 
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isActive
                            ? L.bg
                            : L.sub.withValues(alpha: 0.6))),
              ]),
            ),
          ));
        }).toList()),
        const SizedBox(height: 24),

        // Central time display — tappable wheel feel
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: L.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: L.sub.withValues(alpha: 0.1), width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              _TimeCounter(
                  value: h,
                  min: 0,
                  max: 23,
                  onChanged: (v) =>
                      onChanged(step.field!, {'h': v, 'm': m})),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(':',
                    style: AppTypography.displayLarge.copyWith(fontFamily: 'Courier', 
                        fontSize: 36,
                        color: L.sub.withValues(alpha: 0.4))),
              ),
              _TimeCounter(
                  value: m,
                  min: 0,
                  max: 59,
                  onChanged: (v) =>
                      onChanged(step.field!, {'h': h, 'm': v})),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: L.fill,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(h >= 12 ? 'PM' : 'AM',
                    style: AppTypography.labelLarge.copyWith(fontFamily: 'Courier', 
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: L.text)),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

class _TimeCounter extends StatelessWidget {
  final int value, min, max;
  final ValueChanged<int> onChanged;

  const _TimeCounter(
      {required this.value,
      required this.min,
      required this.max,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Column(children: [
      AnimatedPressable(
        onTap: () {
          HapticEngine.selection();
          onChanged(value < max ? value + 1 : min);
        },
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Icon(Icons.keyboard_arrow_up_rounded,
              color: L.sub, size: 24),
        ),
      ),
      Text(value.toString().padLeft(2, '0'),
          style: AppTypography.displayLarge.copyWith(fontFamily: 'Courier', 
              fontSize: 44,
              color: L.text,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.5)),
      AnimatedPressable(
        onTap: () {
          HapticEngine.selection();
          onChanged(value > min ? value - 1 : max);
        },
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Icon(Icons.keyboard_arrow_down_rounded,
              color: L.sub, size: 24),
        ),
      ),
    ]);
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// LOADING ANALYSIS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _LoadingAnalysisStep extends StatefulWidget {
  final VoidCallback onNext;
  const _LoadingAnalysisStep({required this.onNext});

  @override
  State<_LoadingAnalysisStep> createState() => _LoadingAnalysisStepState();
}

class _LoadingAnalysisStepState extends State<_LoadingAnalysisStep>
    with SingleTickerProviderStateMixin {
  int _idx = 0;
  double _manualProgress = 0;
  late AnimationController _spinCtrl;

  int _subIdx = 0;
  Timer? _subTimer;

  final List<String> _subStages = [
    'Scanning health records...',
    'Analyzing adherence vectors...',
    'Optimizing dosages...',
    'Calculating correlations...',
    'Evaluating interactions...',
    'Building safety profiles...',
    'Simulating 30-day outcomes...',
    'Finalizing recommendations...',
  ];

  final List<(String, String)> _stages = [
    ('🔍', 'Analyzing your health profile...'),
    ('📊', 'Calculating adherence patterns...'),
    ('🧠', 'Building AI recommendations...'),
    ('⚡', 'Optimizing your reminder schedule...'),
    ('🛡️', 'Generating your 30-day projection...'),
    ('✅', 'Your plan is ready!'),
  ];

  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
    _subTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (mounted) setState(() => _subIdx = (_subIdx + 1) % _subStages.length);
    });
    _run();
  }

  Future<void> _run() async {
    final delays = [1200, 800, 1500, 1000, 1400, 600];
    for (int i = 0; i < _stages.length; i++) {
      await Future.delayed(Duration(milliseconds: delays[i]));
      if (!mounted) return;
      setState(() {
        _idx = i;
        _manualProgress = (i + 1) / _stages.length;
      });
    }
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) widget.onNext();
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    _subTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final stage = _stages[_idx];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated ring
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                RotationTransition(
                  turns: _spinCtrl,
                  child: CustomPaint(
                    size: const Size(120, 120),
                    painter: _ArcPainter(
                        progress: _manualProgress, color: L.text),
                  ),
                ),
                Text(stage.$1, style: const TextStyle(fontSize: 36)),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms),

          const SizedBox(height: 40),

          AnimatedSwitcher(
            duration: 400.ms,
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(
                        begin: const Offset(0, 0.2),
                        end: Offset.zero)
                    .animate(anim),
                child: child,
              ),
            ),
            child: Column(
              key: ValueKey(_idx),
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(stage.$2,
                    textAlign: TextAlign.center,
                    style: AppTypography.headlineMedium.copyWith(fontFamily: 'Courier', 
                        fontSize: 20,
                        color: L.text,
                        letterSpacing: -0.5,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                if (_idx < _stages.length - 1)
                  Text(_subStages[_subIdx],
                      style: AppTypography.bodySmall.copyWith(fontFamily: 'Courier', 
                          fontSize: 12,
                          color: L.sub.withValues(alpha: 0.6),
                          letterSpacing: 0.2,
                          fontStyle: FontStyle.italic))
                      .animate(key: ValueKey(_subIdx))
                      .fadeIn(duration: 100.ms),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: _manualProgress),
              duration: 800.ms,
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => LinearProgressIndicator(
                value: v,
                minHeight: 3,
                backgroundColor: L.sub.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation(L.text),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double progress;
  final Color color;
  _ArcPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(8, 8, size.width - 16, size.height - 16);
    final bg = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, math.pi * 2, false, bg);

    final fg = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
        rect, -math.pi / 2, math.pi * 2 * progress, false, fg);
  }

  @override
  bool shouldRepaint(covariant _ArcPainter old) =>
      old.progress != progress;
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// INTERACTIVE DATA GRAPH STEP
// Shows before → after adherence with animated, touchable chart
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _DataGraphStep extends StatefulWidget {
  final _OBStep step;
  final Map<String, dynamic> form;
  final VoidCallback onNext;

  const _DataGraphStep(
      {required this.step, required this.form, required this.onNext});

  @override
  State<_DataGraphStep> createState() => _DataGraphStepState();
}

class _DataGraphStepState extends State<_DataGraphStep>
    with TickerProviderStateMixin {
  late AnimationController _lineCtrl;
  late AnimationController _shineCtrl;
  bool _showAfter = false;
  int? _hoveredIdx;

  // "Before" adherence curve (fragmented, low)
  final List<double> _before = [
    0.45, 0.62, 0.38, 0.55, 0.40, 0.70, 0.35, 0.60, 0.42, 0.65, 0.48, 0.72
  ];

  // "After" adherence curve (smooth rise to 98%)
  final List<double> _after = [
    0.55, 0.68, 0.72, 0.79, 0.82, 0.86, 0.88, 0.91, 0.94, 0.96, 0.97, 0.98
  ];

  @override
  void initState() {
    super.initState();
    _lineCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _shineCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat();
    _lineCtrl.forward();
  }

  @override
  void dispose() {
    _lineCtrl.dispose();
    _shineCtrl.dispose();
    super.dispose();
  }

  void _toggle() {
    HapticEngine.selection();
    setState(() {
      _showAfter = !_showAfter;
      _hoveredIdx = null;
    });
    _lineCtrl.forward(from: 0);
  }

  List<double> get _data => _showAfter ? _after : _before;
  double get _avgAdherence {
    final avg =
        _data.fold(0.0, (a, b) => a + b) / _data.length;
    return avg * 100;
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final accentColor = _showAfter ? L.green : L.red;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Toggle row — before/after switch
                Row(children: [
                  AnimatedPressable(
                    onTap: _showAfter ? _toggle : null,
                    child: AnimatedContainer(
                      duration: 250.ms,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: !_showAfter ? L.text : L.fill,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text('Without Med AI',
                          style: AppTypography.labelLarge.copyWith(fontFamily: 'Courier', 
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: !_showAfter
                                  ? L.bg
                                  : L.sub)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedPressable(
                    onTap: !_showAfter ? _toggle : null,
                    child: AnimatedContainer(
                      duration: 250.ms,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: _showAfter ? L.text : L.fill,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text('With Med AI ✨',
                          style: AppTypography.labelLarge.copyWith(fontFamily: 'Courier', 
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _showAfter ? L.bg : L.sub)),
                    ),
                  ),
                ]),

                const SizedBox(height: 20),

                // Big adherence number
                AnimatedSwitcher(
                  duration: 500.ms,
                  child: RichText(
                    key: ValueKey(_showAfter),
                    text: TextSpan(
                      style: AppTypography.displayLarge.copyWith(fontFamily: 'Courier', 
                          fontSize: 56,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -2,
                          height: 1.0),
                      children: [
                        TextSpan(
                            text: _avgAdherence.toStringAsFixed(0),
                            style: TextStyle(color: accentColor)),
                        TextSpan(
                            text: '%',
                            style: TextStyle(
                                color:
                                    accentColor.withValues(alpha: 0.5),
                                fontSize: 32)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedSwitcher(
                  duration: 300.ms,
                  child: Text(
                    _showAfter
                        ? 'Projected adherence with Med AI'
                        : 'Average adherence without a tracker',
                    key: ValueKey(_showAfter),
                    style: AppTypography.bodyMedium.copyWith(fontFamily: 'Courier', 
                        fontSize: 13, color: L.sub),
                  ),
                ),

                const SizedBox(height: 24),

                // Interactive chart
                GestureDetector(
                  onHorizontalDragUpdate: (d) {
                    final w = context.size?.width ?? 300;
                    final relX = (d.localPosition.dx - 24).clamp(
                        0.0, w - 48);
                    final idx = ((relX / (w - 48)) * (_data.length - 1))
                        .round()
                        .clamp(0, _data.length - 1);
                    if (_hoveredIdx != idx) {
                      HapticEngine.selection();
                      setState(() => _hoveredIdx = idx);
                    }
                  },
                  onHorizontalDragEnd: (_) =>
                      setState(() => _hoveredIdx = null),
                  onTapDown: (d) {
                    final w = context.size?.width ?? 300;
                    final relX = (d.localPosition.dx - 24).clamp(
                        0.0, w - 48);
                    final idx = ((relX / (w - 48)) * (_data.length - 1))
                        .round()
                        .clamp(0, _data.length - 1);
                    setState(() => _hoveredIdx = idx);
                  },
                  onTapUp: (_) => setState(() => _hoveredIdx = null),
                  child: AnimatedBuilder(
                    animation: _lineCtrl,
                    builder: (_, __) => CustomPaint(
                      size: const Size(double.infinity, 180),
                      painter: _AdherenceChartPainter(
                        data: _data,
                        progress: _lineCtrl.value,
                        hoveredIdx: _hoveredIdx,
                        lineColor: accentColor,
                        fillColor:
                            accentColor.withValues(alpha: 0.12),
                        gridColor:
                            L.sub.withValues(alpha: 0.08),
                        textColor: L.sub,
                      ),
                    ),
                  ),
                ),

                // Month labels
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(
                      6,
                      (i) => Text(months[i * 2],
                          style: AppTypography.labelSmall.copyWith(fontFamily: 'Courier', 
                              fontSize: 10, color: L.sub)),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Tooltip if hovered
                if (_hoveredIdx != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: L.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: accentColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(children: [
                      Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                              color: accentColor,
                              shape: BoxShape.circle)),
                      const SizedBox(width: 10),
                      Text(months[_hoveredIdx!],
                          style: AppTypography.labelLarge
                              .copyWith(fontSize: 13, color: L.text)),
                      const Spacer(),
                      Text(
                          '${(_data[_hoveredIdx!] * 100).toStringAsFixed(0)}%',
                          style: AppTypography.labelLarge.copyWith(fontFamily: 'Courier', 
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: accentColor)),
                    ]),
                  )
                      .animate()
                      .fadeIn(duration: 200.ms)
                      .slideY(begin: 0.1, end: 0),

                const SizedBox(height: 24),

                // Stats row
                Row(children: [
                  Expanded(
                      child: _StatCard(
                    label: _showAfter ? 'Med AI Users' : 'Average User',
                    value: _showAfter ? '98%' : '52%',
                    suffix: 'adherence',
                    color: accentColor,
                  )),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _StatCard(
                    label: 'Improvement',
                    value: _showAfter ? '+46%' : '---',
                    suffix: 'in 30 days',
                    color: accentColor,
                  )),
                ]),

                const SizedBox(height: 16),

                // Insight text
                AnimatedSwitcher(
                  duration: 400.ms,
                  child: Container(
                    key: ValueKey(_showAfter),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color: accentColor.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      _showAfter
                          ? '💡 People using Med AI reach 98% adherence within 30 days. Late doses dropped by 94% on average.'
                          : '⚠️ Without a tracker, most people only take 52% of medications correctly. This significantly impacts health outcomes.',
                      style: AppTypography.bodyMedium.copyWith(fontFamily: 'Courier', 
                          fontSize: 14,
                          color: L.text,
                          height: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Bottom CTA — only one button here
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
          child: AnimatedPressable(
            onTap: widget.onNext,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 19),
              decoration: BoxDecoration(
                color: L.text,
                borderRadius: BorderRadius.circular(32),
                boxShadow: AppShadows.glow(L.text, intensity: 0.12),
              ),
              child: Text(
                _showAfter
                    ? "I want this for myself →"
                    : "See what Med AI does →",
                textAlign: TextAlign.center,
                style: AppTypography.labelLarge.copyWith(fontFamily: 'Courier', 
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: L.bg,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value, suffix;
  final Color color;

  const _StatCard(
      {required this.label,
      required this.value,
      required this.suffix,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: L.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: L.glassBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: AppTypography.labelSmall
                .copyWith(fontSize: 10, color: L.sub, letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Text(value,
            style: AppTypography.displayLarge.copyWith(fontFamily: 'Courier', 
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: color,
                letterSpacing: -1)),
        Text(suffix,
            style: AppTypography.bodySmall
                .copyWith(fontSize: 11, color: L.sub)),
      ]),
    );
  }
}

// Custom chart painter
class _AdherenceChartPainter extends CustomPainter {
  final List<double> data;
  final double progress;
  final int? hoveredIdx;
  final Color lineColor, fillColor, gridColor, textColor;

  _AdherenceChartPainter({
    required this.data,
    required this.progress,
    required this.hoveredIdx,
    required this.lineColor,
    required this.fillColor,
    required this.gridColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final n = data.length;

    // Grid lines
    for (int i = 0; i <= 4; i++) {
      final y = h - (h * (i / 4));
      final p = Paint()
        ..color = gridColor
        ..strokeWidth = 0.8;
      canvas.drawLine(Offset(0, y), Offset(w, y), p);
    }

    // Convert to screen points (only up to progress)
    final visibleCount = ((n - 1) * progress).ceil() + 1;
    final pts = List.generate(
        visibleCount.clamp(0, n),
        (i) => Offset(
              w * (i / (n - 1)),
              h - (h * data[i].clamp(0.0, 1.0) * 0.88 + h * 0.06),
            ));

    if (pts.length < 2) return;

    // Fill path
    final fillPath = Path()..moveTo(pts.first.dx, h);
    for (int i = 0; i < pts.length; i++) {
      if (i == 0) {
        fillPath.lineTo(pts[i].dx, pts[i].dy);
      } else {
        final prev = pts[i - 1];
        final cp1 = Offset((prev.dx + pts[i].dx) / 2, prev.dy);
        final cp2 = Offset((prev.dx + pts[i].dx) / 2, pts[i].dy);
        fillPath.cubicTo(
            cp1.dx, cp1.dy, cp2.dx, cp2.dy, pts[i].dx, pts[i].dy);
      }
    }
    fillPath.lineTo(pts.last.dx, h);
    fillPath.close();
    canvas.drawPath(fillPath, Paint()..color = fillColor);

    // Line path
    final linePath = Path();
    linePath.moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length; i++) {
      final prev = pts[i - 1];
      final cp1 = Offset((prev.dx + pts[i].dx) / 2, prev.dy);
      final cp2 = Offset((prev.dx + pts[i].dx) / 2, pts[i].dy);
      linePath.cubicTo(
          cp1.dx, cp1.dy, cp2.dx, cp2.dy, pts[i].dx, pts[i].dy);
    }
    // Line path with Glow
    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    // Outer Glow
    canvas.drawPath(
        linePath,
        Paint()
          ..color = lineColor.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6.0
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0));

    canvas.drawPath(linePath, linePaint);

    // Hover indicator
    if (hoveredIdx != null && hoveredIdx! < pts.length) {
      final hpt = pts[hoveredIdx!];
      canvas.drawCircle(
          hpt,
          5,
          Paint()
            ..color = lineColor
            ..style = PaintingStyle.fill);
      canvas.drawCircle(
          hpt,
          9,
          Paint()
            ..color = lineColor.withValues(alpha: 0.25)
            ..style = PaintingStyle.fill);
      // Vertical line
      canvas.drawLine(
          Offset(hpt.dx, 0),
          Offset(hpt.dx, h),
          Paint()
            ..color = lineColor.withValues(alpha: 0.25)
            ..strokeWidth = 1.5
            ..strokeCap = StrokeCap.round);
    }
  }

  @override
  bool shouldRepaint(covariant _AdherenceChartPainter old) =>
      old.progress != progress ||
      old.hoveredIdx != hoveredIdx ||
      old.data != data;
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// NOTIF STEP
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _NotifStep extends StatelessWidget {
  final Map<String, dynamic> form;
  final Function(String, dynamic) onChanged;

  const _NotifStep(
      {required this.form, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: L.fill,
            shape: BoxShape.circle,
          ),
          child: const Center(
              child: Text('🔔', style: TextStyle(fontSize: 46))),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.06, 1.06),
                duration: 2.seconds,
                curve: Curves.easeInOut),
        const SizedBox(height: 36),
        Text('Never miss\na dose again',
            textAlign: TextAlign.center,
            style: AppTypography.displayLarge.copyWith(fontFamily: 'Courier', 
                fontSize: 34,
                color: L.text,
                letterSpacing: -1.2,
                height: 1.1)),
        const SizedBox(height: 16),
        Text(
            'Smart reminders adapt to your schedule — morning, evening, or whenever you need.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(fontFamily: 'Courier', 
                fontSize: 15, color: L.sub, height: 1.6)),
        const SizedBox(height: 40),

        // Visual reminder preview
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: L.card,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: L.glassBorder),
          ),
          child: Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: L.fill,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                  child: Text('💊',
                      style: TextStyle(fontSize: 22))),
            ),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Med AI Reminder',
                    style: AppTypography.labelLarge.copyWith(fontFamily: 'Courier', 
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: L.text)),
                Text('Time to take your Aspirin 100mg',
                    style: AppTypography.bodySmall.copyWith(fontFamily: 'Courier', 
                        fontSize: 12, color: L.sub)),
              ],
            )),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: L.text,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text('Mark Done',
                  style: AppTypography.labelSmall.copyWith(fontFamily: 'Courier', 
                      fontSize: 10, color: L.bg)),
            )
          ]),
        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),
      ]),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// PLAN READY STEP
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _PlanReadyStep extends StatefulWidget {
  final Map<String, dynamic> form;
  final VoidCallback onNext;
  const _PlanReadyStep({required this.form, required this.onNext});

  @override
  State<_PlanReadyStep> createState() => _PlanReadyStepState();
}

class _PlanReadyStepState extends State<_PlanReadyStep> {
  int pct = 0;
  
  final List<String> loaderTexts = [
    "Analyzing your responses...",
    "Building your health profile...",
    "Optimising your daily routine...",
    "Activating safeguards..."
  ];

  @override
  void initState() {
    super.initState();
    _startLoader();
  }

  void _startLoader() {
    int current = 0;
    Timer.periodic(const Duration(milliseconds: 40), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (current >= 100) {
        timer.cancel();
        setState(() => pct = 100);
      } else {
        setState(() => pct = current++);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    
    if (pct < 100) {
      String text = loaderTexts[(pct / 25).floor().clamp(0, 3)];
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: L.glassBorder, width: 8),
              ),
              child: Center(
                child: Text('$pct%', style: AppTypography.displayLarge.copyWith(fontFamily: 'Courier', color: L.text, fontSize: 32)),
              ),
            ),
            const SizedBox(height: 32),
            Text(text, style: AppTypography.titleMedium.copyWith(fontFamily: 'Courier', color: L.sub, fontSize: 18), textAlign: TextAlign.center,)
          ],
        ),
      );
    }

    final name = widget.form['name']?.toString() ?? '';
    final goal = widget.form['goal']?.toString() ?? '';
    final wt = widget.form['wakeTime'] as Map<String, int>? ?? {'h': 7, 'm': 0};
    final painPoints = widget.form['pain_points'] as List<dynamic>? ?? [];
    final medCount = widget.form['med_count']?.toString() ?? '';

    String formatTime(int h, int m) {
      final ampm = h >= 12 ? 'PM' : 'AM';
      final h12 = h % 12 == 0 ? 12 : h % 12;
      return '$h12:${m.toString().padLeft(2, '0')} $ampm';
    }

    final highlights = [
      if (goal.isNotEmpty) 'Goal: $goal',
      if (medCount.isNotEmpty) 'Medication load: $medCount daily',
      'Wake reminder: ${formatTime(wt['h']!, wt['m']!)}',
      if (painPoints.isNotEmpty) 'Addressing struggle: ${painPoints.first}',
      'AI adherence track: Activated',
    ];

    return SingleChildScrollView(
  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(children: [
        const SizedBox(height: 16),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: L.secondary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Text(
              '🎯',
              style: TextStyle(fontSize: 38),
            ),
          ),
        ).animate(onPlay: (c) => c.repeat(reverse: true)).slideY(begin: -0.05, end: 0.05, duration: 2000.ms, curve: Curves.easeInOut),
        const SizedBox(height: 20),
        Text(
          'Your plan is ready${name.isNotEmpty ? ", $name" : ""}!',
          textAlign: TextAlign.center,
          style: AppTypography.displayLarge.copyWith(fontSize: 28, color: L.text, letterSpacing: -1.0, height: 1.15),
        ).animate().fadeIn().slideY(begin: 0.1, end: 0),
        const SizedBox(height: 8),
        Text(
          'Personalised just for you ✨',
          textAlign: TextAlign.center,
          style: AppTypography.titleMedium.copyWith(fontSize: 15, color: L.secondary, fontWeight: FontWeight.w700),
        ).animate(delay: 100.ms).fadeIn(),
        const SizedBox(height: 28),

        Column(
          children: highlights.map((h) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: L.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: L.border, width: 1.0),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: L.secondary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.check_rounded,
                          size: 13,
                          color: L.secondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        h,
                        style: AppTypography.bodyMedium.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: L.text,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ).animate(delay: 200.ms).fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0),
        const SizedBox(height: 18),
        
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: L.secondary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: L.secondary.withValues(alpha: 0.15), width: 1.0),
          ),
          child: Column(
            children: [
              Text(
                '94%',
                style: AppTypography.displayLarge.copyWith(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: L.secondary,
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'of users like you improved adherence in 2 weeks',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 13,
                  color: L.sub,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ).animate(delay: 400.ms).fadeIn(),
        const SizedBox(height: 32),
        
        _OBButton(
          label: 'See My Plan →',
          onTap: widget.onNext,
        ).animate(delay: 600.ms).fadeIn(),
      ]),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// COMMIT STEP (Hold to Commit)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _CommitStep extends StatefulWidget {
  final VoidCallback onNext;
  const _CommitStep({required this.onNext});

  @override
  State<_CommitStep> createState() => _CommitStepState();
}

class _CommitStepState extends State<_CommitStep> {
  int held = 0;
  bool isHolding = false;
  Timer? _timer;

  void _startHold(TapDownDetails _) {
    setState(() => isHolding = true);
    _timer = Timer.periodic(const Duration(milliseconds: 50), (t) {
      if (!isHolding) {
        t.cancel();
        return;
      }
      setState(() {
        held += 4;
        if (held >= 100) {
          held = 100;
          t.cancel();
          HapticEngine.success();
          Future.delayed(const Duration(milliseconds: 500), widget.onNext);
        }
      });
    });
  }

  void _endHold(dynamic _) {
    setState(() {
      isHolding = false;
      if (held < 100) held = 0;
    });
    _timer?.cancel();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Commit to Your Health", textAlign: TextAlign.center, style: AppTypography.displayLarge.copyWith(fontFamily: 'Courier', fontSize: 28, color: L.text, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          Text("Hold the button below to confirm you're ready to start building better habits.", textAlign: TextAlign.center, style: AppTypography.bodyMedium.copyWith(fontFamily: 'Courier', fontSize: 16, color: L.sub)),
          const SizedBox(height: 60),
          
          GestureDetector(
            onTapDown: _startHold,
            onTapUp: _endHold,
            onTapCancel: () => _endHold(null),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 160, height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: held == 100 ? const Color(0xFF1C1C1E) : L.card,
                border: Border.all(color: held == 100 ? const Color(0xFF1C1C1E) : L.glassBorder, width: 4),
                boxShadow: held > 0 ? AppShadows.glow(const Color(0xFF1C1C1E), intensity: 0.3) : AppShadows.soft,
              ),
              transform: Matrix4.diagonal3Values(isHolding && held < 100 ? 0.95 : 1.0, isHolding && held < 100 ? 0.95 : 1.0, 1.0),
              transformAlignment: Alignment.center,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.antiAlias,
                children: [
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      height: 160 * (held / 100),
                      color: const Color(0xFF1C1C1E).withValues(alpha: 0.2),
                    ),
                  ),
                  MascotWidget(size: 80, mood: held == 100 ? 'energetic' : (isHolding ? 'energetic' : 'content')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            held == 100 ? "Committed!" : isHolding ? "Keep holding..." : "Press and hold",
            style: AppTypography.labelLarge.copyWith(fontFamily: 'Courier', color: held > 0 ? const Color(0xFF1C1C1E) : L.sub, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _SocialProofStep extends StatelessWidget {
  final Map<String, dynamic> form;
  const _SocialProofStep({required this.form});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final name = form['name']?.toString() ?? '';

    final testimonials = [
      (
        'Sarah K.',
        '⭐⭐⭐⭐⭐',
        '"I haven\'t missed a single dose in 3 months. The AI reminders are perfectly timed."',
        '🧑‍💼'
      ),
      (
        'Marcus T.',
        '⭐⭐⭐⭐⭐',
        '"Finally an app that understands complex pill schedules. It changed my life."',
        '👨‍🔬'
      ),
      (
        'Aiko N.',
        '⭐⭐⭐⭐⭐',
        '"I manage meds for my mom. This app makes it stress-free and reliable."',
        '👩'
      ),
    ];

    final stats = [
      ('2.4M+', 'Active users'),
      ('98%', 'Avg adherence'),
      ('4.9★', 'App Store rating'),
    ];

    return SingleChildScrollView(
  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name.isNotEmpty
                ? '$name, you\'re in great\ncompany'
                : 'You\'re joining\n2.4M+ people',
            style: AppTypography.displayLarge.copyWith(fontFamily: 'Courier', 
                fontSize: 30,
                color: L.text,
                letterSpacing: -0.8,
                height: 1.2),
          ),
          const SizedBox(height: 8),
          Text('See what real users say about Med AI',
              style: AppTypography.bodyMedium
                  .copyWith(fontSize: 14, color: L.sub)),
          const SizedBox(height: 24),

          // Stats row
          Row(children: stats.asMap().entries.map((e) {
            final i = e.key;
            final s = e.value;
            return Expanded(
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: L.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: L.glassBorder),
                ),
                child: Column(children: [
                  Text(s.$1,
                      style: AppTypography.displayLarge.copyWith(fontFamily: 'Courier', 
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: L.text,
                          letterSpacing: -0.5)),
                  Text(s.$2,
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall
                          .copyWith(fontSize: 10, color: L.sub)),
                ]),
              ),
            ).animate(delay: (i * 100).ms).fadeIn(duration: 400.ms).slideX(begin: 0.1, end: 0);
          }).toList()),

          const SizedBox(height: 20),

          ...testimonials.asMap().entries.map((e) {
            final i = e.key;
            final t = e.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: L.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: L.glassBorder),
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(t.$4,
                          style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 12),
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.$1,
                                style: AppTypography.labelLarge
                                    .copyWith(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: L.text)),
                            Text(t.$2,
                                style: const TextStyle(fontSize: 11)),
                          ]),
                    ]),
                    const SizedBox(height: 12),
                    Text(t.$3,
                        style: AppTypography.bodyMedium.copyWith(fontFamily: 'Courier', 
                            fontSize: 14,
                            color: L.text.withValues(alpha: 0.85),
                            fontStyle: FontStyle.italic,
                            height: 1.5)),
                  ]),
            )
                .animate(delay: (150 * i).ms)
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.08, end: 0);
          }),
        ],
      ),
    );
  }
}

class PromoCode {
  final double discount;
  final String label;
  final String type; // 'trial' | 'percent' | 'forever'

  const PromoCode({
    required this.discount,
    required this.label,
    required this.type,
  });
}

const Map<String, PromoCode> kPromoCodes = {
  'WELCOME': PromoCode(discount: 100, label: 'Free 30 days', type: 'trial'),
  'HEALTH50': PromoCode(discount: 50, label: '50% off first month', type: 'percent'),
  'PILL30': PromoCode(discount: 30, label: '30% off', type: 'percent'),
  'MEDAI': PromoCode(discount: 100, label: 'Free 14 days', type: 'trial'),
  'FRIEND': PromoCode(discount: 20, label: '20% off forever', type: 'percent'),
};

class _PaywallStep extends StatefulWidget {
  final Map<String, dynamic> form;
  final VoidCallback onComplete;
  final VoidCallback onAuth;
  final VoidCallback onBack;

  const _PaywallStep({
    required this.form,
    required this.onComplete,
    required this.onAuth,
    required this.onBack,
  });

  @override
  State<_PaywallStep> createState() => _PaywallStepState();
}

class _PaywallStepState extends State<_PaywallStep> {
  int _innerStep = 0;
  String _plan = 'annual';
  
  final TextEditingController _promoController = TextEditingController();
  PromoCode? _appliedPromo;
  String _promoError = '';

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  void _verifyPromo() {
    final code = _promoController.text.trim().toUpperCase();
    if (code.isEmpty) return;
    
    if (kPromoCodes.containsKey(code)) {
      HapticEngine.success();
      setState(() {
        _appliedPromo = kPromoCodes[code];
        _promoError = '';
      });
    } else {
      HapticEngine.error();
      setState(() {
        _appliedPromo = null;
        _promoError = 'Invalid code. Try WELCOME for a free trial.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_innerStep == 0) {
      return _PaywallStep1(
        form: widget.form,
        plan: _plan,
        promoController: _promoController,
        appliedPromo: _appliedPromo,
        promoError: _promoError,
        onPlanToggle: (p) => setState(() => _plan = p),
        onApplyPromo: _verifyPromo,
        onNext: () => setState(() => _innerStep = 1),
        onSkip: widget.onComplete,
        onAuth: widget.onAuth,
        onBack: widget.onBack,
      );
    } else if (_innerStep == 1) {
      return _PaywallStep2(
        form: widget.form,
        plan: _plan,
        appliedPromo: _appliedPromo,
        onNext: () => setState(() => _innerStep = 2),
        onBack: () => setState(() => _innerStep = 0),
      );
    } else {
      return _PaywallStep3(
        form: widget.form,
        plan: _plan,
        appliedPromo: _appliedPromo,
        onComplete: widget.onComplete,
        onBack: () => setState(() => _innerStep = 1),
      );
    }
  }
}

class _PaywallStep1 extends StatelessWidget {
  final Map<String, dynamic> form;
  final String plan;
  final TextEditingController promoController;
  final PromoCode? appliedPromo;
  final String promoError;
  final Function(String) onPlanToggle;
  final VoidCallback onApplyPromo;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final VoidCallback onAuth;
  final VoidCallback onBack;

  const _PaywallStep1({
    required this.form,
    required this.plan,
    required this.promoController,
    required this.appliedPromo,
    required this.promoError,
    required this.onPlanToggle,
    required this.onApplyPromo,
    required this.onNext,
    required this.onSkip,
    required this.onAuth,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;

    final features = [
      ('🔍', 'AI Medicine Scanner'),
      ('⏰', 'Smart Reminders'),
      ('🛡️', 'Streak Protection'),
      ('📦', 'Unlimited Medicines'),
      ('⚠️', 'Low Stock Alerts'),
      ('🧠', 'AI Health Insights'),
      ('👪', 'Family Sharing'),
      ('🔐', 'Private & Secure'),
    ];

    double annualPrice = 7.58;
    double annualTotal = 91.00;
    double monthlyPrice = 9.90;

    if (appliedPromo != null && appliedPromo!.type == 'percent') {
      final discountFactor = 1 - (appliedPromo!.discount / 100);
      annualPrice *= discountFactor;
      annualTotal *= discountFactor;
      monthlyPrice *= discountFactor;
    }

    final plans = [
      {
        'id': 'annual',
        'label': 'Annual',
        'sub': 'Best value',
        'price': fmtCurrency(annualPrice, context),
        'per': '/month',
        'total': 'Billed ${fmtCurrency(annualTotal, context)}/year',
        'save': 'Save 24%',
      },
      {
        'id': 'monthly',
        'label': 'Monthly',
        'sub': 'Flexible',
        'price': fmtCurrency(monthlyPrice, context),
        'per': '/month',
        'total': 'Cancel anytime',
        'save': null,
      },
    ];

    return SingleChildScrollView(
  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      physics: const ClampingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MEDAI PRO',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF3A7D6A),
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Start your free trial",
                  style: AppTypography.displayLarge.copyWith(
                    fontSize: 26,
                    color: L.text,
                    letterSpacing: -0.5,
                    height: 1.1,
                  ),
                ),
              ],
            ),
              AnimatedPressable(
                onTap: onSkip,
                child: Text(
                  'Skip',
                  style: AppTypography.bodyMedium.copyWith(
                    color: L.sub.withValues(alpha: 0.7),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),

        // Features grid
        GridView.builder(
  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2.8),
          itemCount: features.length,
          itemBuilder: (_, i) {
            final f = features[i];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: L.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: L.border, width: 1.0),
              ),
              child: Row(children: [
                Text(f.$1, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    f.$2,
                    style: AppTypography.labelLarge.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: L.text,
                    ),
                    maxLines: 2,
                  ),
                ),
              ]),
            );
          },
        ),

        const SizedBox(height: 24),

        // Plan selector
        Row(
          children: plans.map((p) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: p['id'] == 'annual' ? 8.0 : 0.0),
                child: _PaywallPlanCard(
                  planData: p,
                  isSelected: plan == p['id'],
                  onTap: () => onPlanToggle(p['id'] as String),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 20),

        // Promo code input
        Row(
          children: [
            Expanded(
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: L.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: appliedPromo != null
                        ? L.secondary
                        : (promoError.isNotEmpty ? L.error : L.border),
                    width: 1.5,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: TextField(
                  controller: promoController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'Promo code (try WELCOME)',
                    hintStyle: TextStyle(color: L.sub.withValues(alpha: 0.5), fontSize: 13),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  style: TextStyle(color: L.text, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedPressable(
              onTap: onApplyPromo,
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  color: appliedPromo != null ? L.secondary.withValues(alpha: 0.12) : L.card,
                  border: Border.all(color: appliedPromo != null ? L.secondary : L.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    appliedPromo != null ? '✓' : 'Apply',
                    style: TextStyle(
                      color: appliedPromo != null ? L.secondary : L.text,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (promoError.isNotEmpty) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(promoError, style: TextStyle(color: L.error, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ],
        if (appliedPromo != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text('🎉 ${appliedPromo!.label} applied!', style: TextStyle(color: L.secondary, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],

        const SizedBox(height: 24),

        // Primary CTA
        _OBButton(
          label: appliedPromo != null && appliedPromo!.type == 'trial'
              ? 'Start Trial — ${appliedPromo!.label} →'
              : 'Start Free Trial →',
          onTap: onNext,
        ),

        const SizedBox(height: 10),

        Center(
          child: Text(
            'No charge today · Cancel anytime',
            style: AppTypography.bodySmall.copyWith(fontSize: 12, color: L.sub),
          ),
        ),

        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedPressable(
              onTap: () => context.read<AppState>().openTermsOfService(),
              child: Text(
                'Terms of Service',
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 11,
                  color: L.sub.withValues(alpha: 0.6),
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            Text(
              '  ·  ',
              style: TextStyle(color: L.sub.withValues(alpha: 0.4), fontSize: 11),
            ),
            AnimatedPressable(
              onTap: () => context.read<AppState>().openPrivacyPolicy(),
              child: Text(
                'Privacy Policy',
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 11,
                  color: L.sub.withValues(alpha: 0.6),
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Auth options
        _AuthButtons(onAuth: onAuth),

        const SizedBox(height: 20),

        // Skip — very small, low contrast
        Center(
          child: AnimatedPressable(
            onTap: onSkip,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'Continue with free plan',
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 12,
                  color: L.sub.withValues(alpha: 0.45),
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _PaywallStep2 extends StatelessWidget {
  final Map<String, dynamic> form;
  final String plan;
  final PromoCode? appliedPromo;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const _PaywallStep2({
    required this.form,
    required this.plan,
    required this.appliedPromo,
    required this.onNext,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;

    final trustPoints = [
      ('🔒', 'No charge today', 'Your trial starts immediately, completely free'),
      ('📨', 'Reminder 3 days before', 'We\'ll email you before anything charges'),
      ('❌', 'Cancel any time', 'Cancel in the app — no questions asked'),
      ('🔐', 'Secure payment', '256-bit encryption, trusted by thousands'),
    ];

    return SingleChildScrollView(
  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      physics: const ClampingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedPressable(
            onTap: onBack,
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_back_ios_new_rounded, color: L.sub, size: 14),
                const SizedBox(width: 6),
                Text('Back', style: TextStyle(color: L.sub, fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "We've got you covered",
            style: AppTypography.displayLarge.copyWith(
              fontSize: 26,
              color: L.text,
              letterSpacing: -0.5,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your trust matters. Here\'s what happens next.',
            style: AppTypography.bodyMedium.copyWith(fontSize: 14, color: L.sub),
          ),
          const SizedBox(height: 24),

          Column(
            children: trustPoints.map((tp) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: L.card,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: L.border, width: 1.0),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tp.$1, style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tp.$2,
                              style: AppTypography.labelLarge.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: L.text,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              tp.$3,
                              style: AppTypography.bodySmall.copyWith(
                                fontSize: 12,
                                color: L.sub,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // Testimonial card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: L.secondary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: L.secondary.withValues(alpha: 0.15), width: 1.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '"I haven\'t missed a single dose in 3 months. The reminders are perfectly timed."',
                  style: AppTypography.bodyMedium.copyWith(
                    color: L.text,
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '— Sarah K., managing Type 2 Diabetes ⭐⭐⭐⭐⭐',
                  style: AppTypography.bodySmall.copyWith(
                    color: L.sub,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          _OBButton(
            label: 'I Understand, Continue →',
            onTap: onNext,
          ),
        ],
      ),
    );
  }
}

class _PaywallStep3 extends StatelessWidget {
  final Map<String, dynamic> form;
  final String plan;
  final PromoCode? appliedPromo;
  final VoidCallback onComplete;
  final VoidCallback onBack;

  const _PaywallStep3({
    required this.form,
    required this.plan,
    required this.appliedPromo,
    required this.onComplete,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;

    final trialDays = appliedPromo != null && appliedPromo!.type == 'trial'
        ? (appliedPromo!.label.contains('30') ? 30 : 14)
        : 7;

    final today = DateTime.now();
    final trialEnd = today.add(Duration(days: trialDays));
    final reminderDate = trialEnd.subtract(const Duration(days: 3));

    String formatDate(DateTime d) {
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[d.month - 1]} ${d.day}';
    }

    double annualPrice = 7.58;
    double annualTotal = 91.00;
    double monthlyPrice = 9.90;

    if (appliedPromo != null && appliedPromo!.type == 'percent') {
      final discountFactor = 1 - (appliedPromo!.discount / 100);
      annualPrice *= discountFactor;
      annualTotal *= discountFactor;
      monthlyPrice *= discountFactor;
    }

    final String billingAmountDesc = plan == 'annual'
        ? '${fmtCurrency(annualTotal, context)}/year billed'
        : '${fmtCurrency(monthlyPrice, context)}/month billed';

    final steps = [
      ('🚀', 'Today', formatDate(today), 'MedAI Pro trial starts. Unlock all tools.'),
      ('📧', 'Day ${trialDays - 3}', formatDate(reminderDate), 'We email you a reminder 3 days before trial ends.'),
      ('💳', 'Day $trialDays', formatDate(trialEnd), billingAmountDesc),
    ];

    return SingleChildScrollView(
  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      physics: const ClampingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedPressable(
            onTap: onBack,
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_back_ios_new_rounded, color: L.sub, size: 14),
                const SizedBox(width: 6),
                Text('Back', style: TextStyle(color: L.sub, fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Here's exactly\nwhat happens",
            style: AppTypography.displayLarge.copyWith(
              fontSize: 28,
              color: L.text,
              letterSpacing: -1.0,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'No surprises. No confusion.',
            style: AppTypography.bodyMedium.copyWith(fontSize: 14, color: L.sub),
          ),
          const SizedBox(height: 32),

          // Vertical timeline
          Stack(
            children: [
              Positioned(
                left: 20,
                top: 40,
                bottom: 40,
                width: 2,
                child: Opacity(
                  opacity: 0.3,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [L.secondary, L.accent, L.text],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
              ),
              Column(
                children: steps.asMap().entries.map((e) {
                  final i = e.key;
                  final s = e.value;
                  final isFirst = i == 0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isFirst ? L.secondary : L.card,
                            border: Border.all(
                              color: isFirst ? L.secondary : L.border,
                              width: 2.0,
                            ),
                          ),
                          child: Center(
                            child: Text(s.$1, style: const TextStyle(fontSize: 18)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: L.card,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isFirst ? L.secondary : L.border,
                                width: 1.0,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      s.$2,
                                      style: AppTypography.labelLarge.copyWith(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: isFirst ? L.secondary : L.text,
                                      ),
                                    ),
                                    Text(
                                      s.$3,
                                      style: AppTypography.bodySmall.copyWith(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: L.sub,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  s.$4,
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontSize: 13,
                                    color: isFirst ? L.text : L.sub,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Checkout Summary Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: L.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: L.border, width: 1.0),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Free trial', style: TextStyle(color: L.text, fontSize: 13, fontWeight: FontWeight.bold)),
                    Text('$trialDays days FREE', style: TextStyle(color: L.secondary, fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
                if (appliedPromo != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Promo', style: TextStyle(color: L.sub, fontSize: 12)),
                      Text('🎉 ${appliedPromo!.label}', style: TextStyle(color: L.secondary, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Then', style: TextStyle(color: L.text, fontSize: 13, fontWeight: FontWeight.bold)),
                    Text(
                      plan == 'annual'
                          ? '${fmtCurrency(annualPrice, context)}/mo'
                          : '${fmtCurrency(monthlyPrice, context)}/mo',
                      style: TextStyle(color: L.sub, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Action button
          _OBButton(
            label: 'Start My $trialDays-Day Free Trial 🚀',
            onTap: () async {
              HapticEngine.selection();
              await context.read<AppState>().purchasePremium(plan);
              onComplete();
            },
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              'Cancel any time before ${formatDate(trialEnd)} to avoid being charged.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(fontSize: 11, color: L.sub, height: 1.4),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: AnimatedPressable(
              onTap: () async {
                HapticEngine.light();
                await context.read<AppState>().restorePurchases();
                if (context.mounted && context.read<AppState>().isPremium) {
                  onComplete();
                }
              },
              child: Text(
                'Restore Purchases',
                style: AppTypography.labelSmall.copyWith(
                  color: L.sub,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                  decorationColor: L.sub.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaywallPlanCard extends StatefulWidget {
  final Map<String, dynamic> planData;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaywallPlanCard({
    required this.planData,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_PaywallPlanCard> createState() => _PaywallPlanCardState();
}

class _PaywallPlanCardState extends State<_PaywallPlanCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final p = widget.planData;
    return AnimatedPressable(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: 100.ms,
        child: AnimatedContainer(
          duration: 200.ms,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.isSelected ? L.text : L.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: widget.isSelected ? L.text : L.border,
              width: 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (p['save'] != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: widget.isSelected ? L.bg : const Color(0xFFE2EEEA),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    p['save']!,
                    style: AppTypography.labelSmall.copyWith(
                      fontSize: 9,
                      color: widget.isSelected ? L.text : const Color(0xFF3A7D6A),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
              ],
              Text(
                p['price'] as String,
                style: AppTypography.displayLarge.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: widget.isSelected ? L.bg : L.text,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                p['per'] as String,
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 11,
                  color: widget.isSelected ? L.bg.withValues(alpha: 0.6) : L.sub,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                p['total'] as String,
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 10,
                  color: widget.isSelected ? L.bg.withValues(alpha: 0.6) : L.sub,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthButtons extends StatelessWidget {
  final VoidCallback onAuth;
  const _AuthButtons({required this.onAuth});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _PaywallAuthBtn(
        label: 'Continue with Apple',
        icon: Icons.apple_rounded,
        onTap: () async {
          await AuthService.signInWithApple();
          onAuth();
        },
      ),
      const SizedBox(height: 10),
      _PaywallAuthBtn(
        label: 'Continue with Google',
        asset: 'assets/images/google_logo.png',
        onTap: () async {
          await AuthService.signInWithGoogle();
          onAuth();
        },
      ),
    ]);
  }
}

class _PaywallAuthBtn extends StatefulWidget {
  final String label;
  final String? asset;
  final IconData? icon;
  final VoidCallback onTap;

  const _PaywallAuthBtn({
    required this.label,
    this.asset,
    this.icon,
    required this.onTap,
  });

  @override
  State<_PaywallAuthBtn> createState() => _PaywallAuthBtnState();
}

class _PaywallAuthBtnState extends State<_PaywallAuthBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return AnimatedPressable(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: 100.ms,
        child: Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withValues(alpha: 0.08), width: 1.0),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.asset != null) ...[
                Image.asset(
                  widget.asset!,
                  width: 18,
                  height: 18,
                ),
                const SizedBox(width: 10),
              ] else if (widget.icon != null) ...[
                Icon(widget.icon, color: Colors.black, size: 20),
                const SizedBox(width: 10),
              ],
              Text(
                widget.label,
                style: AppTypography.labelLarge.copyWith(
                  fontFamily: 'Courier',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OBButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _OBButton({
    required this.label,
    required this.onTap,
  });

  @override
  State<_OBButton> createState() => _OBButtonState();
}

class _OBButtonState extends State<_OBButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return AnimatedPressable(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: 100.ms,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: L.text,
            borderRadius: BorderRadius.circular(32),
          ),
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            style: AppTypography.labelLarge.copyWith(
              fontFamily: 'Courier', 
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: L.bg,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// CONSENT STEP
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _ConsentStep extends StatefulWidget {
  final bool agreeToPolicies;
  final bool acceptDisclaimer;
  final ValueChanged<bool> onAgreeChanged;
  final ValueChanged<bool> onDisclaimerChanged;

  const _ConsentStep({
    required this.agreeToPolicies,
    required this.acceptDisclaimer,
    required this.onAgreeChanged,
    required this.onDisclaimerChanged,
  });

  @override
  State<_ConsentStep> createState() => _ConsentStepState();
}

class _ConsentStepState extends State<_ConsentStep> {
  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return SingleChildScrollView(
  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _StepHeader(
            emoji: '⚖️',
            title: 'Terms & Safety Notice',
            subtitle: 'Please review and accept to start using Med AI.',
          ),
          const SizedBox(height: 24),
          // Shield/Notice Box
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: L.card,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: L.border.withValues(alpha: 0.08), width: 1.5),
              boxShadow: L.shadowSoft,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: L.secondary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Text('⚕️', style: TextStyle(fontSize: 22, color: L.secondary)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'MEDICAL DISCLAIMER',
                        style: AppTypography.labelLarge.copyWith(fontFamily: 'Courier', 
                          fontSize: 12,
                          color: L.secondary,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Med AI uses advanced AI to help you identify, track, and manage your medications. AI insights are for informational purposes only and may contain errors. This app is not a clinical medical tool and does not provide diagnoses or treatment decisions. Always consult your doctor, pharmacist, or a qualified medical professional for health choices.',
                  style: AppTypography.bodySmall.copyWith(fontFamily: 'Courier', 
                    color: L.text.withValues(alpha: 0.85),
                    fontSize: 13,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08, end: 0),
          const SizedBox(height: 24),
          // Checkboxes/Switches
          _ConsentRow(
            labelWidget: RichText(
              text: TextSpan(
                style: AppTypography.bodyMedium.copyWith(fontFamily: 'Courier', 
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: L.text,
                ),
                children: [
                  const TextSpan(text: 'I agree to the '),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: AnimatedPressable(
                      onTap: () => context.read<AppState>().openTermsOfService(),
                      child: Text(
                        'Terms of Service',
                        style: TextStyle(
                          color: L.secondary,
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const TextSpan(text: ' & '),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: AnimatedPressable(
                      onTap: () => context.read<AppState>().openPrivacyPolicy(),
                      child: Text(
                        'Privacy Policy',
                        style: TextStyle(
                          color: L.secondary,
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            isSelected: widget.agreeToPolicies,
            onTap: () {
              HapticEngine.selection();
              widget.onAgreeChanged(!widget.agreeToPolicies);
            },
          ).animate(delay: 100.ms).fadeIn(duration: 300.ms).slideX(begin: 0.04, end: 0),
          const SizedBox(height: 12),
          _ConsentRow(
            labelWidget: Text(
              'I understand and accept the medical disclaimer.',
              style: AppTypography.bodyMedium.copyWith(fontFamily: 'Courier', 
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: L.text,
              ),
            ),
            isSelected: widget.acceptDisclaimer,
            onTap: () {
              HapticEngine.selection();
              widget.onDisclaimerChanged(!widget.acceptDisclaimer);
            },
          ).animate(delay: 200.ms).fadeIn(duration: 300.ms).slideX(begin: 0.04, end: 0),
        ],
      ),
    );
  }
}

class _ConsentRow extends StatefulWidget {
  final Widget labelWidget;
  final bool isSelected;
  final VoidCallback onTap;

  const _ConsentRow({
    required this.labelWidget,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_ConsentRow> createState() => _ConsentRowState();
}

class _ConsentRowState extends State<_ConsentRow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return AnimatedPressable(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: 150.ms,
        child: AnimatedContainer(
          duration: 200.ms,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: widget.isSelected ? L.text : L.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: widget.isSelected ? L.text : L.sub.withValues(alpha: 0.14),
              width: 1.5,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: 200.ms,
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.isSelected ? L.bg : Colors.transparent,
                  border: Border.all(
                    color: widget.isSelected ? L.bg : L.sub.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: widget.isSelected
                    ? Icon(Icons.check_rounded, color: L.text, size: 14)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: widget.labelWidget,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
