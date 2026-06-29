import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../../theme/med_ai_ui.dart';
import '../paywall/premium_paywall_overlay.dart';
import 'onboarding_controller.dart';
import 'onboarding_theme.dart';
import 'widgets/ob_hero.dart';
import 'widgets/ob_widgets.dart';
import 'widgets/ob_p0_widgets.dart';
import 'widgets/ob_video_style_widgets.dart';
import 'widgets/ob_unique_widgets.dart';

/// Lightweight option descriptor for question steps.
class _Opt {
  final String id;
  final String label;
  final String? sub;
  final String? emoji;
  const _Opt(this.id, this.label, {this.sub, this.emoji});
}

/// 38-step, high-converting viral onboarding funnel (Cal AI / Olive style),
/// adapted to Med AI's medication-tracking features and flow.
class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final OnboardingController _c = OnboardingController();
  int _i = 0;

  static const int _total = 40;

  double get _progress => (_i + 1) / _total;

  // ── Navigation ─────────────────────────────────────────────────────────
  void _next() {
    if (_i < _total - 1) {
      setState(() => _i++);
    } else {
      _complete();
    }
  }

  void _back() {
    if (_i > 0) setState(() => _i--);
  }

  void _skip() => _complete(skipPaywall: true);

  Future<void> _showPaywall() async {
    final state = context.read<AppState>();
    if (state.isPremium) return;
    await PremiumPaywallOverlay.show(
      context,
      triggerSource: 'onboarding',
      variant: PaywallVariant.onboarding,
    );
  }

  Future<void> _complete({bool skipPaywall = false}) async {
    final state = context.read<AppState>();
    await state.saveOnboardingPrefs(_c.toPrefs());
    await state.markOnboardingCompleted();
    if (mounted && !skipPaywall && !state.isPremium) {
      await _showPaywall();
    }
    if (mounted) state.auth.phase = AppPhase.auth;
  }

  Future<void> _requestNotifications() async {
    try {
      await Permission.notification.request();
    } catch (_) {/* ignore — proceed regardless */}
    if (mounted) _next();
  }

  // ── Build ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final reduceMotion = MedAiA11y.reducedMotion(context);
    return AnimatedSwitcher(
      duration: reduceMotion ? Duration.zero : AppDurations.fast,
      switchInCurve: AppCurves.expressive,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, anim) {
        if (reduceMotion) return child;
        return FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.04, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: anim, curve: AppCurves.expressive)),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey(_i),
        child: _stepWidget(_i),
      ),
    );
  }

  // ── Reusable step builders ───────────────────────────────────────────────
  Widget _question({
    required String id,
    required String title,
    String? subtitle,
    required bool multi,
    required List<_Opt> options,
    Widget? topHero,
    bool skip = true,
  }) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final enabled = _c.hasAnswer(id, multiSelect: multi);
        return ObScaffold(
          progress: _progress,
          onBack: _i == 0 ? null : _back,
          onSkip: skip ? _skip : null,
          ctaEnabled: enabled,
          onCta: enabled ? _next : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 6),
              if (topHero != null) ...[topHero, const SizedBox(height: 20)],
              ObHeadline(title, subtitle: subtitle).obFadeUp(),
              const SizedBox(height: 22),
              ...List.generate(options.length, (idx) {
                final o = options[idx];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child:                   ObOptionCard(
                    label: o.label,
                    subtitle: o.sub,
                    emoji: o.emoji,
                    multiSelect: multi,
                    selected: _c.isSelected(id, o.id, multiSelect: multi),
                    onTap: () {
                      if (multi) {
                        _c.toggleMulti(id, o.id);
                      } else {
                        _c.selectSingle(id, o.id);
                      }
                    },
                  ).obFadeUp(delayMs: 40 * idx),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _info({
    required Widget hero,
    required String title,
    String? subtitle,
    String cta = 'Continue',
    bool skip = true,
    VoidCallback? onCta,
    List<Widget> extra = const [],
  }) {
    return ObScaffold(
      progress: _progress,
      onBack: _i == 0 ? null : _back,
      onSkip: skip ? _skip : null,
      ctaLabel: cta,
      onCta: onCta ?? _next,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          hero.obFadeUp(),
          const SizedBox(height: 26),
          ObHeadline(title, subtitle: subtitle).obFadeUp(delayMs: 80),
          if (extra.isNotEmpty) ...[
            const SizedBox(height: 22),
            ...extra.map((w) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: w,
                )),
          ],
        ],
      ),
    );
  }

  Widget _largeGoalStep() {
    const id = 'goal';
    const options = [
      (id: 'never_miss', label: 'Never miss a dose', emoji: '💊'),
      (id: 'family', label: "Manage my family's meds", emoji: '👨‍👩‍👧'),
      (id: 'condition', label: 'Track a health condition', emoji: '❤️'),
      (id: 'understand', label: 'Understand my medications', emoji: '🔍'),
    ];
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final enabled = _c.hasAnswer(id, multiSelect: false);
        return ObScaffold(
          progress: _progress,
          onBack: _back,
          onSkip: null,
          ctaEnabled: enabled,
          onCta: enabled ? _next : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 6),
              const ObHeadline(
                'What is your *primary goal*?',
                subtitle: "We'll personalize everything around your answer.",
              ).obFadeUp(),
              const SizedBox(height: 22),
              ObLargeGoalPicker(
                options: options,
                selectedId: _c.single(id),
                onSelect: (v) => _c.selectSingle(id, v),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _yesNoStep({
    required String id,
    required String title,
    String? subtitle,
  }) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final enabled = _c.hasAnswer(id, multiSelect: false);
        return ObScaffold(
          progress: _progress,
          onBack: _back,
          onSkip: _skip,
          ctaEnabled: enabled,
          onCta: enabled ? _next : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              ObHeadline(title, subtitle: subtitle).obFadeUp(),
              const SizedBox(height: 32),
              ObYesNoChoice(
                selectedId: _c.single(id),
                onSelect: (v) => _c.selectSingle(id, v),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _personaStep() {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        const personas = [
          ObPersonaOption(
            id: 'self_manager',
            label: 'Self-Manager',
            subtitle: 'Tracking my own meds',
            emoji: '🙋',
            tint: Color(0xFF4A9E86),
          ),
          ObPersonaOption(
            id: 'caregiver',
            label: 'Dedicated Caregiver',
            subtitle: 'Managing for a loved one',
            emoji: '🤝',
            tint: Color(0xFF4ABFE2),
          ),
          ObPersonaOption(
            id: 'senior',
            label: 'Health-Focused Senior',
            subtitle: 'Staying independent',
            emoji: '👴',
            tint: Color(0xFF8B7BF2),
          ),
          ObPersonaOption(
            id: 'family_leader',
            label: 'Family Health Lead',
            subtitle: 'Me & my whole family',
            emoji: '👨‍👩‍👧',
            tint: Color(0xFF34D399),
          ),
        ];
        final enabled = _c.hasAnswer('persona', multiSelect: false);
        return ObScaffold(
          progress: _progress,
          onBack: _back,
          onSkip: _skip,
          ctaEnabled: enabled,
          onCta: enabled ? _next : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 6),
              const ObHeadline(
                'Choose your *team*',
                subtitle: "We'll personalize your experience.",
              ).obFadeUp(),
              const SizedBox(height: 22),
              ObPersonaGrid(
                options: personas,
                selectedId: _c.single('persona'),
                onSelect: (id) => _c.selectSingle('persona', id),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _reminderIntensityStep() {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        const id = 'reminder_intensity';
        final enabled = _c.hasAnswer(id, multiSelect: false);
        return ObScaffold(
          progress: _progress,
          onBack: _back,
          onSkip: _skip,
          ctaEnabled: enabled,
          onCta: enabled ? _next : null,
          ctaLabel: 'Next',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 6),
              const ObHeadline(
                'How many *reminders* do you want?',
                subtitle: 'You can change this anytime in settings.',
              ).obFadeUp(),
              const SizedBox(height: 22),
              ObRadioOptionCard(
                label: 'Gentle',
                subtitle: 'Only for critical doses',
                selected: _c.isSelected(id, 'gentle', multiSelect: false),
                onTap: () => _c.selectSingle(id, 'gentle'),
              ).obFadeUp(delayMs: 40),
              ObRadioOptionCard(
                label: 'Normal',
                subtitle: 'All scheduled doses',
                badge: 'POPULAR',
                selected: _c.isSelected(id, 'normal', multiSelect: false),
                onTap: () => _c.selectSingle(id, 'normal'),
              ).obFadeUp(delayMs: 80),
              ObRadioOptionCard(
                label: 'Hardcore',
                subtitle: 'Doses, refills & family alerts',
                selected: _c.isSelected(id, 'hardcore', multiSelect: false),
                onTap: () => _c.selectSingle(id, 'hardcore'),
              ).obFadeUp(delayMs: 120),
            ],
          ),
        );
      },
    );
  }

  // ── The 38 steps ──────────────────────────────────────────────────────────
  Widget _stepWidget(int i) {
    switch (i) {
      // ░░ ACT 1 — HOOK ░░
      case 0:
        return _info(
          hero: const ObLaurelWelcome(),
          title: 'Let\'s build your *custom plan*',
          subtitle:
              'A few quick questions so Med AI fits your meds, schedule, and goals.',
          cta: 'Get started',
          skip: false,
        );
      case 1:
        return ObRankInterstitial(onContinue: _next);
      case 2:
        return _info(
          hero: const ObMasonryGallery(),
          title: 'Trusted by *500,000+* people',
          subtitle: 'Join the community that never misses what matters.',
          extra: const [
            ObStatBlock(
              stat: '93%',
              caption:
                  'of Med AI users hit their adherence goal within the first month.',
            ),
          ],
        );
      case 3:
        return _largeGoalStep();

      // ░░ ACT 2 — PERSONALIZE ░░
      case 4:
        return _personaStep();
      case 5:
        return _question(
          id: 'med_count',
          title: 'How many *medications* do you take?',
          multi: false,
          options: const [
            _Opt('one_two', '1–2', emoji: '🟢'),
            _Opt('three_five', '3–5', emoji: '🟡'),
            _Opt('six_nine', '6–9', emoji: '🟠'),
            _Opt('ten_plus', '10 or more', emoji: '🔴'),
          ],
        );
      case 6:
        return _question(
          id: 'timing',
          title: 'When do you usually *take* them?',
          multi: false,
          options: const [
            _Opt('morning', 'Morning', emoji: '🌅'),
            _Opt('afternoon', 'Afternoon', emoji: '☀️'),
            _Opt('evening', 'Evening', emoji: '🌙'),
            _Opt('multiple', 'Multiple times a day', emoji: '⏰'),
          ],
        );
      case 7:
        return _question(
          id: 'challenge',
          title: "What's your biggest *challenge*?",
          multi: false,
          options: const [
            _Opt('forgetting', 'Forgetting doses', emoji: '🤔'),
            _Opt('schedule', 'A complex schedule', emoji: '🗓️'),
            _Opt('side_effects', 'Side effects', emoji: '😬'),
            _Opt('refills', 'Running out / refills', emoji: '📦'),
          ],
        );
      case 8:
        return _question(
          id: 'miss_frequency',
          title: 'How often do you *miss* a dose?',
          multi: false,
          options: const [
            _Opt('often', 'Often', sub: 'A few times a week'),
            _Opt('sometimes', 'Sometimes', sub: 'A few times a month'),
            _Opt('rarely', 'Rarely', sub: 'Once in a while'),
            _Opt('never', 'Almost never', sub: 'I rarely slip'),
          ],
        );
      case 9:
        return _question(
          id: 'age',
          title: "What's your *age* range?",
          subtitle: 'This helps us tailor reminders and safety checks.',
          multi: false,
          options: const [
            _Opt('u30', 'Under 30'),
            _Opt('30s', '30 – 44'),
            _Opt('45s', '45 – 59'),
            _Opt('60p', '60+'),
          ],
        );
      case 10:
        return _question(
          id: 'conditions',
          title: 'Any conditions you are *managing*?',
          subtitle: 'Select all that apply.',
          multi: true,
          options: const [
            _Opt('hypertension', 'Hypertension', emoji: '🩸'),
            _Opt('diabetes', 'Diabetes', emoji: '🍬'),
            _Opt('cholesterol', 'High cholesterol', emoji: '🫀'),
            _Opt('heart', 'Heart disease', emoji: '❤️'),
            _Opt('mental', 'Mental health', emoji: '🧠'),
            _Opt('pain', 'Chronic pain', emoji: '🦴'),
            _Opt('none', 'None of these', emoji: '✨'),
          ],
        );
      case 11:
        return _question(
          id: 'supplements',
          title: 'Do you take *supplements* too?',
          subtitle: "We'll check them for interactions with your meds.",
          multi: false,
          options: const [
            _Opt('many', 'Yes, several', emoji: '🌿'),
            _Opt('few', 'A few', emoji: '🍃'),
            _Opt('none', 'No', emoji: '🚫'),
          ],
        );
      case 12:
        return _info(
          hero: const SizedBox.shrink(),
          title: 'Personal summary from your *answers*',
          subtitle: 'Your baseline before Med AI starts helping.',
          extra: [ObPersonalAdherenceSummary(controller: _c)],
          cta: 'Start improving',
        );

      // ░░ ACT 3 — EDUCATE + CONTRAST ░░
      case 13:
        return _info(
          hero: const ObHeroIllustration(scene: ObHeroScene.thriving),
          title: 'Keep your health *thriving*',
          subtitle:
              'Get personalized reminders, scan insights, and safety tips for every med.',
        );
      case 14:
        return _info(
          hero: const ObLongTermResultsChart(),
          title: 'Med AI creates *long-term* results',
          subtitle:
              '76% of members maintain strong adherence over 6 months — not just a first-week spike.',
        );
      case 15:
        return _info(
          hero: const ObMascotHero(size: 130),
          title: 'Med AI is your *safety net*',
          subtitle:
              'We watch the clock, the interactions, and your refills — so you never have to worry.',
        );
      case 16:
        return _info(
          hero: const ObOrangeScanIntro(),
          title: 'See what a *scan* reveals',
          subtitle:
              'Med AI identifies your pill, flags interactions, and logs your schedule instantly.',
          extra: const [ObScanDemoPreview()],
        );
      case 17:
        return _info(
          hero: const ObComparison(
            leftTitle: 'Pill organizer',
            leftPoints: [
              'Easy to forget to refill it',
              'No reminders',
              'No safety checks',
            ],
            rightTitle: 'Med AI',
            rightPoints: [
              'Smart, timed reminders',
              'Interaction warnings',
              'Auto refill alerts',
            ],
          ),
          title: 'A smarter way to *stay on track*',
        );
      case 18:
        return _info(
          hero: const ObAccuracyBarChart(),
          title: 'Identify pills more *accurately*',
          subtitle:
              'Med AI\'s scanner outperforms generic pill ID apps in head-to-head tests.',
        );
      case 19:
        return _info(
          hero: const ObHeroIllustration(scene: ObHeroScene.diagnose),
          title: "Know what's *wrong* with your regimen",
          subtitle:
              'Diagnose interaction risks instantly and get clear next steps.',
        );
      case 20:
        return _question(
          id: 'interaction_known',
          title: 'Do you know if your meds *interact*?',
          multi: false,
          options: const [
            _Opt('yes', "Yes, I've checked", emoji: '✅'),
            _Opt('unsure', 'Not really sure', emoji: '🤷'),
            _Opt('no', 'No idea', emoji: '❓'),
          ],
        );
      case 21:
        return _info(
          hero: const ObComparison(
            leftTitle: 'Manual tracking',
            leftPoints: [
              'Easy to lose track',
              'No alerts when late',
              'Guesswork on timing',
            ],
            rightTitle: 'Med AI',
            rightPoints: [
              'Adapts to your routine',
              'Nudges before you forget',
              'Perfect timing, every dose',
            ],
          ),
          title: 'Reminders that actually *work*',
        );
      case 22:
        return _info(
          hero: const _BigIconHero(icon: Icons.favorite_rounded),
          title: 'Keep loved ones *safe* from anywhere',
          subtitle:
              'Get notified if someone you care for misses a critical dose — and step in when it matters.',
        );
      case 23:
        return ObDarkInterstitial(
          progress: _progress,
          onBack: _back,
          onContinue: _next,
        );

      // ░░ ACT 4 — MOTIVATE + COMMIT ░░
      case 24:
        return _info(
          hero: const ObMascotHero(size: 120),
          title: "Let's understand what *drives* you",
          subtitle: 'A few quick questions to lock in your motivation.',
        );
      case 25:
        return _question(
          id: 'motivation',
          title: 'What motivates you *most*?',
          multi: false,
          options: const [
            _Opt('healthier', 'Feeling healthier', emoji: '💪'),
            _Opt('peace', 'Peace of mind', emoji: '🧘'),
            _Opt('independent', 'Staying independent', emoji: '🕊️'),
            _Opt('family', 'For my family', emoji: '👨‍👩‍👧'),
          ],
        );
      case 26:
        return _question(
          id: 'success',
          title: 'What does *success* look like?',
          multi: false,
          options: const [
            _Opt('never_miss', 'Never missing a dose', emoji: '🎯'),
            _Opt('organized', 'Feeling organized', emoji: '🗂️'),
            _Opt('confident', 'Feeling in control', emoji: '😌'),
            _Opt('energy', 'More energy each day', emoji: '⚡'),
          ],
        );
      case 27:
        return _info(
          hero: ObProjectionChart(
            start: _c.inferredAdherence,
            end: _c.projectedAdherence,
          ),
          title: 'You have *great potential*',
          subtitle:
              'Based on your answers, Med AI can take you to ${(_c.projectedAdherence * 100).round()}% adherence.',
        );
      case 28:
        return _yesNoStep(
          id: 'relate_forget',
          title: "I worry I'll *forget* an important dose",
          subtitle: 'Do you relate?',
        );
      case 29:
        return _yesNoStep(
          id: 'relate_refill',
          title: 'Managing refills feels like a *hassle*',
          subtitle: 'Do you relate?',
        );
      case 30:
        return _info(
          hero: const ObComparison(
            leftTitle: 'On your own',
            leftPoints: [
              'Relying on memory',
              'Stress & second-guessing',
              'Slow to spot problems',
            ],
            rightTitle: 'With Med AI',
            rightPoints: [
              '2× more likely to stay on track',
              'Calm, automatic routine',
              'Early safety warnings',
            ],
          ),
          title: 'You are *2× more likely* to succeed with Med AI',
        );
      case 31:
        return _info(
          hero: const ObSocialProofCluster(),
          title: 'Made for people *just like you*',
          subtitle: 'Med AI was built for real medication routines — not perfect ones.',
        );
      case 32:
        return _CommitScreen(
          progress: _progress,
          onBack: _back,
          onComplete: _next,
        );

      // ░░ ACT 5 — CONVERT ░░
      case 33:
        return _reminderIntensityStep();
      case 34:
        return _info(
          hero: const _BigIconHero(icon: Icons.notifications_active_rounded),
          title: 'Turn on *reminders*',
          subtitle:
              'This is how Med AI makes sure you never miss a dose. You can change it anytime.',
          cta: 'Enable reminders',
          onCta: _requestNotifications,
        );
      case 35:
        return _info(
          hero: const ObStars(count: 5),
          title: 'Give us a *rating*',
          subtitle: 'Med AI was designed for people like you.',
          extra: const [
            _Testimonial(
              quote:
                  '"I haven\'t missed a single dose since I started. It just works."',
              author: 'Emma K.',
            ),
            _Testimonial(
              quote: '"Finally peace of mind managing my mom\'s meds."',
              author: 'Josie W.',
            ),
          ],
        );
      case 36:
        return _PlanLoaderScreen(
          progress: _progress,
          onDone: _next,
        );
      case 37:
        return _info(
          hero: ObProjectionChart(
            start: _c.inferredAdherence,
            end: _c.projectedAdherence,
            endLabel: 'Day 30',
          ),
          title: 'Your *personalized plan* is ready',
          subtitle:
              'Reach ${(_c.projectedAdherence * 100).round()}% adherence with a routine built around your life.',
        );
      case 38:
        return ObTrialFlashInterstitial(
          onContinue: () async {
            await _showPaywall();
            if (mounted) _next();
          },
        );
      case 39:
        return _WelcomeScreen(
          name: _c.name,
          onContinue: () => _complete(skipPaywall: true),
        );

      default:
        return _info(
          hero: const ObMascotHero(),
          title: 'Welcome to *Med AI*',
          onCta: () => _complete(skipPaywall: true),
        );
    }
  }
}

// ════════════════════════════════════════════════════════════════════════
// CUSTOM FULL-SCREEN STEPS
// ════════════════════════════════════════════════════════════════════════
class _CommitScreen extends StatelessWidget {
  final double progress;
  final VoidCallback onBack;
  final VoidCallback onComplete;
  const _CommitScreen({
    required this.progress,
    required this.onBack,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return ObScaffold(
      progress: progress,
      onBack: onBack,
      ctaEnabled: false,
      onCta: null,
      ctaLabel: 'Hold the logo to commit',
      child: Column(
        children: [
          const SizedBox(height: 20),
          const ObHeadline(
            'Commit to your *health* for the next 90 days',
            subtitle: 'Tap and hold the Med AI logo to lock in your goal.',
          ),
          const SizedBox(height: 40),
          ObCommitOrb(onComplete: onComplete),
        ],
      ),
    );
  }
}

class _PlanLoaderScreen extends StatelessWidget {
  final double progress;
  final VoidCallback onDone;
  const _PlanLoaderScreen({required this.progress, required this.onDone});

  @override
  Widget build(BuildContext context) {
    return ObScaffold(
      progress: progress,
      ctaEnabled: false,
      onCta: null,
      ctaLabel: 'Building your plan…',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          const ObHeadline('Building your *personalized plan*'),
          const SizedBox(height: 36),
          ObPlanLoader(
            steps: const [
              'Reminders',
              'Interactions',
              'Scan',
              'Family alerts',
              'Refills',
            ],
            onDone: onDone,
          ),
        ],
      ),
    );
  }
}

class _WelcomeScreen extends StatelessWidget {
  final String? name;
  final VoidCallback onContinue;
  const _WelcomeScreen({required this.name, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    final p = ObPalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            p.electric.withValues(alpha: 0.12),
            p.accent.withValues(alpha: 0.18),
            p.bg,
          ],
          stops: const [0.0, 0.35, 0.75],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (!MedAiA11y.reducedMotion(context))
            AuroraBackground(colors: p.aurora, opacity: 0.42),
          Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
                child: Column(
                  children: [
                    const Spacer(),
                    const ObMascotHero(size: 160),
                    const SizedBox(height: 28),
                    ObHeadline(
                      name == null
                          ? 'Welcome to *Med AI*!'
                          : 'Welcome, *$name*!',
                      subtitle: "Let's keep you safe, on time, every day.",
                    ).obFadeUp(),
                    const Spacer(),
                    ObPrimaryButton(label: "Let's go", onTap: onContinue),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// SMALL HERO HELPERS
// ════════════════════════════════════════════════════════════════════════
class _BigIconHero extends StatelessWidget {
  final IconData icon;
  const _BigIconHero({required this.icon});

  @override
  Widget build(BuildContext context) {
    final p = ObPalette.of(context);
    return Center(
      child: Container(
        width: 110,
        height: 110,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              p.accent.withValues(alpha: 0.18),
              p.electric.withValues(alpha: 0.10),
            ],
          ),
          boxShadow: AppShadows.glow(p.accent, intensity: 0.2),
        ),
        child: Icon(icon, size: 52, color: p.accent),
      ),
    );
  }
}

class _Testimonial extends StatelessWidget {
  final String quote;
  final String author;
  const _Testimonial({required this.quote, required this.author});

  @override
  Widget build(BuildContext context) {
    final p = ObPalette.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(AppRadius.l),
        border: Border.all(color: p.border.withValues(alpha: 0.6), width: 0.5),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ObStars(count: 5),
          const SizedBox(height: 8),
          Text(quote, style: AppTypography.bodyMedium.copyWith(color: p.text)),
          const SizedBox(height: 6),
          Text('— $author',
              style: AppTypography.labelMedium.copyWith(color: p.sub)),
        ],
      ),
    );
  }
}
