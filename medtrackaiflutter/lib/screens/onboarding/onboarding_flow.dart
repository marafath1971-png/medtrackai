import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../providers/app_state.dart';
import '../../services/analytics_service.dart';
import '../../services/remote_config_service.dart';
import '../../theme/med_ai_ui.dart';
import '../paywall/premium_paywall_overlay.dart';
import 'onboarding_controller.dart';
import 'onboarding_theme.dart';
import 'widgets/ob_eato_widgets.dart';
import 'widgets/ob_hero.dart';
import 'widgets/ob_widgets.dart';
import 'widgets/ob_p0_widgets.dart';
import 'widgets/ob_video_style_widgets.dart';
import 'widgets/ob_unique_widgets.dart';
import 'onboarding_l10n.dart';

/// Lightweight option descriptor for question steps.
class _Opt {
  final String id;
  final String label;
  final String? sub;
  final String? emoji;
  const _Opt(this.id, this.label, {this.sub, this.emoji});
}

/// 55-step, high-converting Eato-style onboarding funnel (see
/// PRODUCT_AUDIT_AND_REDESIGN_BLUEPRINT.md §6), adapted to Med AI's
/// medication-tracking features. Every step fires a funnel analytics event.
class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final OnboardingController _c = OnboardingController();
  int _i = 0;

  /// Localized onboarding string by key (English fallback built in).
  String _obt(String k) => ObL10n.of(context).t(k);

  static const int _total = 56;

  /// Analytics ids, one per step index. Keep in sync with [_stepWidget].
  static const List<String> _stepNames = [
    'welcome', 'rank_intro', 'social_gallery', 'attribution', 'goal',
    'longterm_results', 'persona', 'gender', 'birth_year', 'weight',
    'conditions', 'privacy_reassurance', 'med_count', 'medcount_payoff',
    'supplements', 'interaction_education', 'allergies', 'timing',
    'challenge', 'miss_frequency', 'empathy_stat', 'miss_triggers',
    'work_schedule', 'sleep_schedule', 'relate_forget', 'relate_refill',
    'relate_mixing', 'relate_guilt', 'payoff_bars', 'comparison_reminders',
    'dark_interstitial', 'pill_knowledge', 'scan_intro',
    'comparison_organizer', 'accuracy_chart', 'interaction_known',
    'diagnose', 'family_safety', 'thriving', 'drives_intro', 'motivation',
    'success', 'projection', 'comparison_2x', 'social_proof',
    'personal_summary', 'commit', 'reminder_intensity', 'first_med_method',
    'notifications', 'att_permission', 'rating', 'plan_loader',
    'plan_ready', 'trial_flash', 'welcome_done',
  ];

  double get _progress => (_i + 1) / _total;

  @override
  void initState() {
    super.initState();
    _logStep(0);
  }

  void _logStep(int i) {
    AnalyticsService.logEvent('onboarding_step_viewed', parameters: {
      'step_index': i,
      'step_id': _stepNames[i],
    });
  }

  /// Steps that Remote Config can remove from the funnel without a release.
  /// Index 50 = ATT permission, 51 = rating request (see [_stepNames]).
  bool _isStepDisabled(int i) {
    if (i == 50) return !RemoteConfigService.showAttStep;
    if (i == 51) return !RemoteConfigService.showRatingStep;
    return false;
  }

  // ── Navigation ─────────────────────────────────────────────────────────
  void _next() {
    var n = _i + 1;
    while (n < _total - 1 && _isStepDisabled(n)) {
      n++;
    }
    if (n <= _total - 1) {
      setState(() => _i = n);
      _logStep(_i);
    } else {
      _complete();
    }
  }

  void _back() {
    var n = _i - 1;
    while (n > 0 && _isStepDisabled(n)) {
      n--;
    }
    if (n >= 0) setState(() => _i = n);
  }

  void _skip() => _complete(skipPaywall: true);

  /// Remote Config can remove the skip escape hatch entirely (funnel
  /// experiments consistently show skip buttons depress trial starts).
  VoidCallback? get _maybeSkip =>
      RemoteConfigService.getBool('onboarding_skip_enabled') ? _skip : null;

  /// Native in-app review at the motivation peak (only 3 iOS prompts/year).
  Future<void> _requestReview() async {
    try {
      final review = InAppReview.instance;
      if (await review.isAvailable()) await review.requestReview();
      AnalyticsService.logEvent('onboarding_rating_prompted');
    } catch (_) {/* ignore — proceed regardless */}
    if (mounted) _next();
  }

  /// ATT prompt, asked late — after value is established, never at launch.
  Future<void> _requestTracking() async {
    try {
      await Permission.appTrackingTransparency.request();
    } catch (_) {/* ignore — proceed regardless */}
    if (mounted) _next();
  }

  Future<void> _showPaywall() async {
    final state = context.read<AppState>();
    if (state.isPremium) return;
    // Personalize the paywall headline with the user's stated goal (§5.4).
    final headline = switch (_c.single('goal')) {
      'never_miss' => 'Your plan to never miss a dose is ready.',
      'family' => "Your family's medication safety plan is ready.",
      'condition' => 'Your condition-tracking plan is ready.',
      'understand' => 'Your medication clarity plan is ready.',
      _ => null,
    };
    await PremiumPaywallOverlay.show(
      context,
      triggerSource: 'onboarding',
      variant: PaywallVariant.onboarding,
      personalizedHeadline: headline,
    );
  }

  Future<void> _complete({bool skipPaywall = false}) async {
    AnalyticsService.logEvent('onboarding_completed', parameters: {
      'skipped_paywall': skipPaywall ? 1 : 0,
      'last_step_index': _i,
    });
    final state = context.read<AppState>();
    await state.saveOnboardingPrefs(_c.toPrefs());
    await state.markOnboardingCompleted();
    // Build a UserProfile from the collected answers and stash it as pending.
    // The auth screen persists this under the real uid on first sign-in — a
    // returning user's existing cloud profile takes precedence (see
    // AuthController.enterAppAfterAuth), so this never overwrites real data.
    state.auth.setPendingOnboardingProfile(_buildProfileFromAnswers());
    // Activation hand-off (step 48): remember how the user chose to add
    // their first med so the shell can deep-link straight there after auth.
    final firstMedMethod = _c.single('first_med_method');
    if (firstMedMethod == 'scan' || firstMedMethod == 'search') {
      try {
        final prefs = await SharedPreferences.getInstance();
        // Non-null guaranteed by the guard above; Dart won't promote on
        // value-equality, so assert explicitly.
        await prefs.setString('pending_first_med_method', firstMedMethod!);
      } catch (_) {/* activation nudge is best-effort */}
    }
    // Value-first funnel: when enabled, defer the paywall until the user has
    // actually added their first med (the aha). We drop a marker + persist the
    // goal so the shell can show the same personalized paywall post-activation.
    // Users who skip the paywall entirely still never see it (skipPaywall).
    final deferPaywall = RemoteConfigService.getBool('paywall_after_activation');
    if (deferPaywall && !skipPaywall && !state.isPremium) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('pending_activation_paywall', true);
        final goal = _c.single('goal');
        if (goal != null) await prefs.setString('onboarding_goal', goal);
      } catch (_) {/* deferred paywall is best-effort; falls back to gates */}
    } else if (mounted && !skipPaywall && !state.isPremium) {
      await _showPaywall();
    }
    if (mounted) state.auth.phase = AppPhase.auth;
  }

  /// Assembles a [UserProfile] from the onboarding answers so a brand-new
  /// account starts personalized. Only fields the funnel actually collects are
  /// set; everything else keeps its model default.
  UserProfile _buildProfileFromAnswers() {
    final goal = switch (_c.single('goal')) {
      'never_miss' => 'Never miss a dose',
      'family' => 'Care for my family',
      'condition' => 'Manage a condition',
      'understand' => 'Understand my medicine',
      _ => '',
    };
    final targetUser = switch (_c.single('persona') ?? _c.single('managing_for')) {
      'caregiver' || 'loved_one' => 'Family',
      'family_leader' || 'me_family' => 'Both',
      _ => 'Myself',
    };
    return UserProfile(
      name: _c.name ?? '',
      goal: goal,
      targetUser: targetUser,
      gender: _c.single('gender') ?? '',
      medCount: _c.medCountLabel == 'Not set' ? '' : _c.medCountLabel,
      challenge: _c.challengeLabel == 'Not set' ? '' : _c.challengeLabel,
      allergies: _c.multi('allergies').toList(),
      conditions: _c.multi('conditions').toList(),
    );
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
              begin: const Offset(0.02, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: anim, curve: AppCurves.smooth)),
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
          onSkip: skip ? _maybeSkip : null,
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
                  child: ObOptionCard(
                    label: o.label,
                    subtitle: o.sub,
                    emoji: null,
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
      onSkip: skip ? _maybeSkip : null,
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
    final options = [
      (id: 'never_miss', label: _obt('ob_neverMissADose'), emoji: '💊'),
      (id: 'family', label: "Manage my family's meds", emoji: '👨‍👩‍👧'),
      (id: 'condition', label: _obt('ob_trackAHealthCondition'), emoji: '❤️'),
      (id: 'understand', label: _obt('ob_understandMyMedications'), emoji: '🔍'),
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
          onSkip: _maybeSkip,
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
        final personas = [
          ObPersonaOption(
            id: 'self_manager',
            label: _obt('ob_selfManager'),
            subtitle: _obt('ob_trackingMyOwnMeds'),
            emoji: '🙋',
            tint: Color(0xFF4A9E86),
          ),
          ObPersonaOption(
            id: 'caregiver',
            label: _obt('ob_dedicatedCaregiver'),
            subtitle: _obt('ob_managingForALovedOne'),
            emoji: '🤝',
            tint: Color(0xFF4ABFE2),
          ),
          ObPersonaOption(
            id: 'senior',
            label: _obt('ob_healthFocusedSenior'),
            subtitle: _obt('ob_stayingIndependent'),
            emoji: '👴',
            tint: Color(0xFF8B7BF2),
          ),
          ObPersonaOption(
            id: 'family_leader',
            label: _obt('ob_familyHealthLead'),
            subtitle: _obt('ob_meMyWholeFamily'),
            emoji: '👨‍👩‍👧',
            tint: Color(0xFF34D399),
          ),
        ];
        final enabled = _c.hasAnswer('persona', multiSelect: false);
        return ObScaffold(
          progress: _progress,
          onBack: _back,
          onSkip: _maybeSkip,
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
          onSkip: _maybeSkip,
          ctaEnabled: enabled,
          onCta: enabled ? _next : null,
          ctaLabel: _obt('ob_next'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 6),
              ObHeadline(
                'How many *reminders* do you want?',
                subtitle: _obt('ob_youCanChangeThisAnytimeInSetting'),
              ).obFadeUp(),
              const SizedBox(height: 22),
              ObRadioOptionCard(
                label: _obt('ob_gentle'),
                subtitle: _obt('ob_onlyForCriticalDoses'),
                selected: _c.isSelected(id, 'gentle', multiSelect: false),
                onTap: () => _c.selectSingle(id, 'gentle'),
              ).obFadeUp(delayMs: 40),
              ObRadioOptionCard(
                label: _obt('ob_normal'),
                subtitle: _obt('ob_allScheduledDoses'),
                badge: 'POPULAR',
                selected: _c.isSelected(id, 'normal', multiSelect: false),
                onTap: () => _c.selectSingle(id, 'normal'),
              ).obFadeUp(delayMs: 80),
              ObRadioOptionCard(
                label: _obt('ob_hardcore'),
                subtitle: _obt('ob_dosesRefillsFamilyAlerts'),
                selected: _c.isSelected(id, 'hardcore', multiSelect: false),
                onTap: () => _c.selectSingle(id, 'hardcore'),
              ).obFadeUp(delayMs: 120),
            ],
          ),
        );
      },
    );
  }

  // ── Big-input instrument steps (Eato style) ─────────────────────────────
  Widget _birthYearStep() {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final year = _c.number('birth_year')?.toInt();
        return ObScaffold(
          progress: _progress,
          onBack: _back,
          onSkip: _maybeSkip,
          ctaEnabled: year != null,
          onCta: year != null ? _next : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 6),
              ObHeadline(
                'When is your *birth year*?',
                subtitle:
                    _obt('ob_ageCanChangeHowMedicationsWorkWe'),
              ).obFadeUp(),
              const SizedBox(height: 14),
              ObYearWheelPicker(
                selected: year,
                onChanged: (y) => _c.setNumber('birth_year', y),
              ).obFadeUp(delayMs: 60),
            ],
          ),
        );
      },
    );
  }

  Widget _weightStep() {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final kg = (_c.number('weight_kg') ?? 70).toDouble();
        return ObScaffold(
          progress: _progress,
          onBack: _back,
          onSkip: _maybeSkip,
          onCta: () {
            if (_c.number('weight_kg') == null) _c.setNumber('weight_kg', kg);
            _next();
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 6),
              ObHeadline(
                "What's your *weight*?",
                subtitle:
                    _obt('ob_someDosagesAndInteractionRisksAr'),
              ).obFadeUp(),
              const SizedBox(height: 18),
              ObWeightRuler(
                kg: kg,
                onChanged: (v) => _c.setNumber('weight_kg', v),
              ).obFadeUp(delayMs: 60),
              const SizedBox(height: 18),
              ObFeedbackChip(
                badge: 'Noted',
                title: _obt('ob_doseAwareSafetyIsOn'),
                body:
                    'Our AI will flag anything weight-sensitive in your regimen — automatically.',
                sourceLabel: 'Source of recommendations',
              ).obFadeUp(delayMs: 140),
            ],
          ),
        );
      },
    );
  }

  Widget _sleepStep() {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final wake = (_c.number('wake_hour') ?? 7).toInt();
        final sleep = (_c.number('sleep_hour') ?? 22).toInt();
        return ObScaffold(
          progress: _progress,
          onBack: _back,
          onSkip: _maybeSkip,
          onCta: () {
            if (_c.number('wake_hour') == null) _c.setNumber('wake_hour', wake);
            if (_c.number('sleep_hour') == null) {
              _c.setNumber('sleep_hour', sleep);
            }
            _next();
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 6),
              const ObHeadline(
                "What's your *daily rhythm*?",
                subtitle: "We'll time reminders to your real day.",
              ).obFadeUp(),
              const SizedBox(height: 18),
              ObDualTimeSliders(
                wakeHour: wake,
                sleepHour: sleep,
                onWakeChanged: (v) => _c.setNumber('wake_hour', v),
                onSleepChanged: (v) => _c.setNumber('sleep_hour', v),
              ).obFadeUp(delayMs: 60),
            ],
          ),
        );
      },
    );
  }

  // ── The 55 steps ──────────────────────────────────────────────────────────
  Widget _stepWidget(int i) {
    switch (i) {
      // ░░ PHASE A — HOOK (0–5) ░░
      case 0:
        return _info(
          hero: const ObLaurelWelcome(),
          title: _obt('ob_letSBuildYourCustomPlan'),
          subtitle:
              _obt('ob_aFewQuickQuestionsSoMedAiFitsYou'),
          cta: _obt('ob_getStarted'),
          skip: false,
        );
      case 1:
        return ObRankInterstitial(onContinue: _next);
      case 2:
        return _info(
          hero: const ObMasonryGallery(),
          title: _obt('ob_trustedBy500000People'),
          subtitle: _obt('ob_joinTheCommunityThatNeverMissesW'),
          extra: const [
            ObStatBlock(
              stat: '93%',
              caption:
                  'of Med AI users hit their adherence goal within the first month.',
            ),
          ],
        );
      case 3:
        return _question(
          id: 'attribution',
          title: _obt('ob_howDidYouHearAboutMedAi'),
          multi: false,
          options: [
            _Opt('tiktok', _obt('ob_tiktok'), emoji: '🎵'),
            _Opt('instagram', _obt('ob_instagram'), emoji: '📸'),
            _Opt('appstore', _obt('ob_appStore'), emoji: '📱'),
            _Opt('friend', _obt('ob_friendOrFamily'), emoji: '💬'),
            _Opt('doctor', _obt('ob_doctorOrPharmacist'), emoji: '🩺'),
            _Opt('other', _obt('ob_somewhereElse'), emoji: '✨'),
          ],
        );
      case 4:
        return _largeGoalStep();
      case 5:
        return _info(
          hero: const ObLongTermResultsChart(),
          title: _obt('ob_medAiCreatesLongTermResults'),
          subtitle:
              _obt('ob_76OfMembersMaintainStrongAdheren'),
        );

      // ░░ PHASE B — YOUR PROFILE (6–16) ░░
      case 6:
        return _personaStep();
      case 7:
        return _question(
          id: 'gender',
          title: "What's your *gender*?",
          subtitle:
              _obt('ob_medicationEffectsAndDosingCanDif'),
          multi: false,
          options: [
            _Opt('male', _obt('ob_male'), emoji: '👨'),
            _Opt('female', _obt('ob_female'), emoji: '👩'),
            _Opt('nonbinary', _obt('ob_nonBinary'), emoji: '🌈'),
            _Opt('skip', _obt('ob_preferNotToSay'), emoji: '🤐'),
          ],
        );
      case 8:
        return _birthYearStep();
      case 9:
        return _weightStep();
      case 10:
        return _question(
          id: 'conditions',
          title: _obt('ob_anyConditionsYouAreManaging'),
          subtitle: _obt('ob_selectAllThatApply'),
          multi: true,
          options: [
            _Opt('hypertension', _obt('ob_hypertension'), emoji: '🩸'),
            _Opt('diabetes', _obt('ob_diabetes'), emoji: '🍬'),
            _Opt('cholesterol', _obt('ob_highCholesterol'), emoji: '🫀'),
            _Opt('heart', _obt('ob_heartDisease'), emoji: '❤️'),
            _Opt('mental', _obt('ob_mentalHealth'), emoji: '🧠'),
            _Opt('pain', _obt('ob_chronicPain'), emoji: '🦴'),
            _Opt('none', _obt('ob_noneOfThese'), emoji: '✨'),
          ],
        );
      case 11:
        return _info(
          hero: const ObMascot(feature: 'safety', size: 100),
          title: _obt('ob_thanksForSharing'),
          subtitle:
              _obt('ob_yourHealthDataIsEncryptedAndNeve'),
        );
      case 12:
        return _question(
          id: 'med_count',
          title: _obt('ob_howManyMedicationsDoYouTake'),
          multi: false,
          options: [
            _Opt('one_two', _obt('ob_12'), emoji: '🟢'),
            _Opt('three_five', _obt('ob_35'), emoji: '🟡'),
            _Opt('six_nine', _obt('ob_69'), emoji: '🟠'),
            _Opt('ten_plus', _obt('ob_10OrMore'), emoji: '🔴'),
          ],
        );
      case 13:
        return _info(
          hero: const ObMascot(feature: 'home', size: 108),
          title: "You're in the *right place*",
          extra: const [
            ObSocialProofBanner(
              percent: '75%',
              text:
                  'of new members with your medication load answered the same way.',
            ),
            ObStatBlock(
              stat: '23%',
              caption:
                  'average adherence improvement in the first 2 weeks for people managing several medications.',
            ),
          ],
        );
      case 14:
        return _question(
          id: 'supplements',
          title: _obt('ob_doYouTakeSupplementsToo'),
          subtitle: "We'll check them for interactions with your meds.",
          multi: false,
          options: [
            _Opt('many', _obt('ob_yesSeveral'), emoji: '🌿'),
            _Opt('few', _obt('ob_aFew'), emoji: '🍃'),
            _Opt('none', _obt('ob_no'), emoji: '🚫'),
          ],
        );
      case 15:
        return _info(
          hero: const ObHeroIllustration(scene: ObHeroScene.diagnose, height: 200),
          title: _obt('ob_hiddenInteractionRisks'),
          subtitle:
              _obt('ob_4In10SupplementUsersHaveAtLeastO'),
          extra: const [
            ObStatBlock(
              stat: '4 in 10',
              caption:
                  'supplement users have a potential interaction. Med AI checks yours automatically.',
            ),
          ],
        );
      case 16:
        return _question(
          id: 'allergies',
          title: _obt('ob_anyMedicationAllergies'),
          subtitle: _obt('ob_selectAllThatApplyOurAiWillGuard'),
          multi: true,
          options: [
            _Opt('penicillin', _obt('ob_penicillin'), emoji: '💊'),
            _Opt('sulfa', _obt('ob_sulfaDrugs'), emoji: '🧪'),
            _Opt('nsaids', _obt('ob_nsaidsIbuprofen'), emoji: '🌡️'),
            _Opt('aspirin', _obt('ob_aspirin'), emoji: '⚪'),
            _Opt('none', _obt('ob_noneThatIKnowOf'), emoji: '✅'),
          ],
        );

      // ░░ PHASE C — HABITS & EMPATHY (17–29) ░░
      case 17:
        return _question(
          id: 'timing',
          title: _obt('ob_whenDoYouUsuallyTakeThem'),
          multi: false,
          options: [
            _Opt('morning', _obt('ob_morning'), emoji: '🌅'),
            _Opt('afternoon', _obt('ob_afternoon'), emoji: '☀️'),
            _Opt('evening', _obt('ob_evening'), emoji: '🌙'),
            _Opt('multiple', _obt('ob_multipleTimesADay'), emoji: '⏰'),
          ],
        );
      case 18:
        return _question(
          id: 'challenge',
          title: "What's your biggest *challenge*?",
          multi: false,
          options: [
            _Opt('forgetting', _obt('ob_forgettingDoses'), emoji: '🤔'),
            _Opt('schedule', _obt('ob_aComplexSchedule'), emoji: '🗓️'),
            _Opt('side_effects', _obt('ob_sideEffects'), emoji: '😬'),
            _Opt('refills', _obt('ob_runningOutRefills'), emoji: '📦'),
          ],
        );
      case 19:
        return _question(
          id: 'miss_frequency',
          title: _obt('ob_howOftenDoYouMissADose'),
          multi: false,
          options: [
            _Opt('often', _obt('ob_often'), sub: _obt('ob_aFewTimesAWeek')),
            _Opt('sometimes', _obt('ob_sometimes'), sub: _obt('ob_aFewTimesAMonth')),
            _Opt('rarely', _obt('ob_rarely'), sub: _obt('ob_onceInAWhile')),
            _Opt('never', _obt('ob_almostNever'), sub: _obt('ob_iRarelySlip')),
          ],
        );
      case 20:
        return _info(
          hero: const ObMascot(feature: 'not_alone', size: 108),
          title: "You're *not alone*",
          subtitle:
              "7 in 10 people miss doses. It's not about willpower — it's about systems.",
        );
      case 21:
        return _question(
          id: 'miss_triggers',
          title: _obt('ob_whatUsuallyCausesAMissedDose'),
          subtitle: _obt('ob_selectAllThatApply'),
          multi: true,
          options: [
            _Opt('busy', _obt('ob_busyMornings'), emoji: '🌪️'),
            _Opt('asleep', _obt('ob_stillAsleep'), emoji: '😴'),
            _Opt('away', _obt('ob_awayFromHome'), emoji: '🚗'),
            _Opt('forget', _obt('ob_iJustForget'), emoji: '🤔'),
            _Opt('side_effects', _obt('ob_sideEffects'), emoji: '😬'),
          ],
        );
      case 22:
        return _question(
          id: 'work_schedule',
          title: _obt('ob_whatDoesYourDayLookLike'),
          multi: false,
          options: [
            _Opt('flexible', _obt('ob_flexible'), emoji: '🧘'),
            _Opt('nine_five', _obt('ob_nineToFive'), emoji: '💼'),
            _Opt('shifts', _obt('ob_shifts'), emoji: '🔄'),
            _Opt('home', _obt('ob_caregiverAtHome'), emoji: '🏠'),
            _Opt('retired', _obt('ob_retired'), emoji: '🌤️'),
          ],
        );
      case 23:
        return _sleepStep();
      case 24:
        return _yesNoStep(
          id: 'relate_forget',
          title: "I worry I'll *forget* an important dose",
          subtitle: _obt('ob_doYouRelate'),
        );
      case 25:
        return _yesNoStep(
          id: 'relate_refill',
          title: _obt('ob_managingRefillsFeelsLikeAHassle'),
          subtitle: _obt('ob_doYouRelate'),
        );
      case 26:
        return _yesNoStep(
          id: 'relate_mixing',
          title: _obt('ob_iWorryAboutMixingMedsAndSuppleme'),
          subtitle: _obt('ob_doYouRelate'),
        );
      case 27:
        return _yesNoStep(
          id: 'relate_guilt',
          title: _obt('ob_iFeelGuiltyWhenMyRoutineSlips'),
          subtitle: _obt('ob_doYouRelate'),
        );
      case 28:
        return _info(
          hero: const ObPayoffBars(),
          title: _obt('ob_loseTheAnxietyNotYourStreak'),
          subtitle:
              _obt('ob_78OfMembersReportLessMedicationS'),
        );
      case 29:
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
          title: _obt('ob_remindersThatActuallyWork'),
        );

      // ░░ PHASE D — FEATURE EDUCATION (30–38) ░░
      case 30:
        return ObDarkInterstitial(
          progress: _progress,
          onBack: _back,
          onContinue: _next,
        );
      case 31:
        return _question(
          id: 'pill_knowledge',
          title: "Do you know exactly *what's in* every pill you take?",
          multi: false,
          options: [
            _Opt('know_all', _obt('ob_iKnowAllOfThem'), emoji: '💯'),
            _Opt('check', _obt('ob_iOftenCheck'), emoji: '🔎'),
            _Opt('not_really', _obt('ob_notReally'), emoji: '🤷'),
          ],
        );
      case 32:
        return _info(
          hero: const ObScanIntro(),
          title: _obt('ob_seeWhatAScanReveals'),
          subtitle:
              _obt('ob_medAiIdentifiesYourPillFlagsInte'),
          extra: const [ObScanDemoPreview()],
        );
      case 33:
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
          title: _obt('ob_aSmarterWayToStayOnTrack'),
        );
      case 34:
        return _info(
          hero: const ObAccuracyBarChart(),
          title: _obt('ob_identifyPillsMoreAccurately'),
          subtitle:
              _obt('ob_medAiSScannerOutperformsGenericP'),
        );
      case 35:
        return _question(
          id: 'interaction_known',
          title: _obt('ob_doYouKnowIfYourMedsInteract'),
          multi: false,
          options: [
            _Opt('yes', "Yes, I've checked", emoji: '✅'),
            _Opt('unsure', _obt('ob_notReallySure'), emoji: '🤷'),
            _Opt('no', _obt('ob_noIdea'), emoji: '❓'),
          ],
        );
      case 36:
        return _info(
          hero: const ObHeroIllustration(scene: ObHeroScene.diagnose),
          title: "Know what's *wrong* with your regimen",
          subtitle:
              _obt('ob_diagnoseInteractionRisksInstantl'),
        );
      case 37:
        return _info(
          hero: const ObHeroIllustration(scene: ObHeroScene.family),
          title: _obt('ob_keepLovedOnesSafeFromAnywhere'),
          subtitle:
              _obt('ob_getNotifiedIfSomeoneYouCareForMi'),
        );
      case 38:
        return _info(
          hero: const ObHeroIllustration(scene: ObHeroScene.thriving),
          title: _obt('ob_keepYourHealthThriving'),
          subtitle:
              _obt('ob_getPersonalizedRemindersScanInsi'),
        );

      // ░░ PHASE E — MOTIVATION & PROJECTION (39–46) ░░
      case 39:
        return _info(
          hero: const ObMascot(feature: 'plan', size: 104),
          title: "Let's understand what *drives* you",
          subtitle: _obt('ob_aFewQuickQuestionsToLockInYourMo'),
        );
      case 40:
        return _question(
          id: 'motivation',
          title: _obt('ob_whatMotivatesYouMost'),
          multi: false,
          options: [
            _Opt('healthier', _obt('ob_feelingHealthier'), emoji: '💪'),
            _Opt('peace', _obt('ob_peaceOfMind'), emoji: '🧘'),
            _Opt('independent', _obt('ob_stayingIndependent'), emoji: '🕊️'),
            _Opt('family', _obt('ob_forMyFamily'), emoji: '👨‍👩‍👧'),
          ],
        );
      case 41:
        return _question(
          id: 'success',
          title: _obt('ob_whatDoesSuccessLookLike'),
          multi: false,
          options: [
            _Opt('never_miss', _obt('ob_neverMissingADose'), emoji: '🎯'),
            _Opt('organized', _obt('ob_feelingOrganized'), emoji: '🗂️'),
            _Opt('confident', _obt('ob_feelingInControl'), emoji: '😌'),
            _Opt('energy', _obt('ob_moreEnergyEachDay'), emoji: '⚡'),
          ],
        );
      case 42:
        return _info(
          hero: ObProjectionChart(
            start: _c.inferredAdherence,
            end: _c.projectedAdherence,
          ),
          title: _obt('ob_youHaveGreatPotential'),
          subtitle:
              'Based on your answers, Med AI can take you to ${(_c.projectedAdherence * 100).round()}% adherence — your success is already forming.',
        );
      case 43:
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
              '2× more likely to succeed',
              'Calm, automatic routine',
              'Early safety warnings',
            ],
          ),
          title: _obt('ob_youAre2MoreLikelyToSucceedWithMe'),
          subtitle:
              'People who use Med AI feel more in control — and stay on track.',
        );
      case 44:
        return _info(
          hero: const ObSocialProofCluster(),
          title: _obt('ob_madeForPeopleJustLikeYou'),
          subtitle: _obt('ob_medAiWasBuiltForRealMedicationRo'),
        );
      case 45:
        return _info(
          hero: const ObHeroIllustration(scene: ObHeroScene.thriving, height: 200),
          title: _obt('ob_personalSummaryFromYourAnswers'),
          subtitle: _obt('ob_yourBaselineBeforeMedAiStartsHel'),
          extra: [ObPersonalAdherenceSummary(controller: _c)],
          cta: _obt('ob_startImproving'),
        );
      case 46:
        return _CommitScreen(
          progress: _progress,
          onBack: _back,
          onComplete: _next,
        );

      // ░░ PHASE F — SETUP, PERMISSIONS & PROOF (47–51) ░░
      case 47:
        return _reminderIntensityStep();
      case 48:
        return _question(
          id: 'first_med_method',
          title: _obt('ob_howWillYouAddYourFirstMed'),
          subtitle: "We'll take you straight there after setup.",
          multi: false,
          options: [
            _Opt('scan', _obt('ob_scanItWithAi'), emoji: '📷'),
            _Opt('search', _obt('ob_searchByName'), emoji: '🔎'),
            _Opt('unsure', _obt('ob_notSureYet'), emoji: '💭'),
          ],
        );
      case 49:
        return _info(
          hero: const ObHeroIllustration(scene: ObHeroScene.family, height: 200),
          title: _obt('ob_turnOnReminders'),
          subtitle:
              _obt('ob_thisIsHowMedAiMakesSureYouNeverM'),
          cta: _obt('ob_enableReminders'),
          onCta: _requestNotifications,
        );
      case 50:
        return _info(
          hero: const ObHeroIllustration(scene: ObHeroScene.diagnose, height: 200),
          title: _obt('ob_oneLastPermission'),
          subtitle:
              _obt('ob_allowingTrackingHelpsUsKeepMedAi'),
          cta: _obt('ob_continue'),
          onCta: _requestTracking,
        );
      case 51:
        return _info(
          hero: const ObStars(count: 5),
          title: _obt('ob_giveUsARating'),
          subtitle: _obt('ob_medAiWasDesignedForPeopleLikeYou'),
          cta: _obt('ob_rateMedAi'),
          onCta: _requestReview,
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

      // ░░ PHASE G — ANALYSIS, REVEAL & CONVERT (52–55) ░░
      case 52:
        return _PlanLoaderScreen(
          progress: _progress,
          onDone: _next,
        );
      case 53:
        final planName = _c.name;
        final planLead = (planName != null && planName.isNotEmpty)
            ? '$planName, this'
            : 'This';
        return _info(
          hero: ObProjectionChart(
            start: _c.inferredAdherence,
            end: _c.projectedAdherence,
            endLabel: 'Day 30',
          ),
          title: _obt('ob_yourPersonalizedPlanIsReady'),
          subtitle:
              '$planLead is the start of becoming someone who never misses — a routine built around your life is ready to take you to ${(_c.projectedAdherence * 100).round()}% adherence.',
        );
      case 54:
        return ObTrialFlashInterstitial(
          onContinue: () async {
            await _showPaywall();
            if (mounted) _next();
          },
        );
      case 55:
        return _WelcomeScreen(
          name: _c.name,
          onContinue: () => _complete(skipPaywall: true),
        );

      default:
        return _info(
          hero: const ObMascot(feature: 'welcome', size: 104),
          title: _obt('ob_welcomeToMedAi'),
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
      ctaLabel: ObL10n.of(context).t('ob_holdTheLogoToCommit'),
      child: Column(
        children: [
          const SizedBox(height: 20),
          ObHeadline(
            'Commit to your *health* for the next 90 days',
            subtitle: ObL10n.of(context).t('ob_tapAndHoldTheMedAiLogoToLockInYo'),
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
      ctaLabel: ObL10n.of(context).t('ob_buildingYourPlan'),
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
                    const ObMascot(feature: 'success', size: 132),
                    const SizedBox(height: 28),
                    ObHeadline(
                      name == null
                          ? 'Welcome to *Med AI*!'
                          : 'Welcome, *$name*!',
                      subtitle:
                          "You're in. Let's make every dose a win — starting today.",
                    ).obFadeUp(),
                    const Spacer(),
                    ObPrimaryButton(
                        label: 'Begin my success', onTap: onContinue),
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
