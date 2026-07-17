import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/premium_graphics.dart';
import '../../theme/med_ai_ui.dart';
import '../../core/utils/haptic_engine.dart';
import '../../widgets/common/app_shimmer.dart';
import '../../widgets/common/animated_pressable.dart';
import '../../widgets/common/med_ai_animation.dart';
import '../../core/constants/med_ai_assets.dart';
import '../../models/constants.dart';
import '../../services/analytics_service.dart';
import '../../services/growth_tracker.dart';
import '../../providers/app_state.dart';
import '../../services/notification_service.dart';
import '../../services/purchases_service.dart';
import '../../services/remote_config_service.dart';
import '../../screens/onboarding/widgets/ob_video_style_widgets.dart';

// ══════════════════════════════════════════════════════════════
// PREMIUM PAYWALL OVERLAY — 2026 conversion + store compliance
// Apple Guideline 3.1.1 & Google Play Billing Policy
// ══════════════════════════════════════════════════════════════

enum PaywallVariant { onboarding, featureGate }

class PremiumPaywallOverlay extends StatefulWidget {
  final String triggerSource;
  final PaywallVariant variant;
  final VoidCallback? onSuccess;
  final VoidCallback? onDismiss;

  /// Optional headline personalized from onboarding answers, e.g.
  /// "Your plan to never miss a dose is ready".
  final String? personalizedHeadline;

  const PremiumPaywallOverlay({
    super.key,
    this.triggerSource = 'generic',
    this.variant = PaywallVariant.featureGate,
    this.onSuccess,
    this.onDismiss,
    this.personalizedHeadline,
  });

  static Future<void> show(
    BuildContext context, {
    String triggerSource = 'generic',
    PaywallVariant variant = PaywallVariant.featureGate,
    VoidCallback? onSuccess,
    String? personalizedHeadline,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (ctx) => PremiumPaywallOverlay(
        triggerSource: triggerSource,
        variant: variant,
        onSuccess: onSuccess,
        onDismiss: () => Navigator.of(ctx).pop(),
        personalizedHeadline: personalizedHeadline,
      ),
    );
  }

  @override
  State<PremiumPaywallOverlay> createState() => _PremiumPaywallOverlayState();
}

class _PremiumPaywallOverlayState extends State<PremiumPaywallOverlay> {
  int _selectedPlan = 0;
  bool _isLoading = false;
  bool _isLoadingPackages = true;
  List<Package> _packages = [];
  String? _errorMsg;
  bool _purchaseSuccess = false;
  // Default ON: the promised reminder is the #1 objection-handler for trials
  // (Blinkist pattern) — and it must actually fire (see _scheduleTrialReminder).
  bool _trialReminder = true;
  // Exit downsell (weekly plan) shown at most once per paywall presentation.
  bool _exitOfferShown = false;

  static const _features = [
    _Feature(icon: Icons.document_scanner_rounded, label: 'Unlimited AI Scans', sub: 'No daily limit on pill recognition'),
    _Feature(icon: Icons.summarize_rounded, label: 'Doctor Reports (PDF)', sub: 'Export clinical summaries anytime'),
    _Feature(icon: Icons.medication_rounded, label: 'Unlimited Medications', sub: 'Track every med without limits'),
    _Feature(icon: Icons.local_fire_department_rounded, label: 'Streak Freeze Protection', sub: 'Never lose your streak'),
    _Feature(icon: Icons.lock_rounded, label: 'Priority Biometric Lock', sub: 'Advanced HIPAA privacy mode'),
    _Feature(icon: Icons.psychology_alt_rounded, label: 'AI Drug Interactions', sub: 'Full Gemini-powered analysis'),
  ];

  @override
  void initState() {
    super.initState();
    GrowthTracker.trackPaywall('view');
    _loadPackages();
  }

  /// Health & Fitness is the one category where annual dominates revenue
  /// (60.6% — RevenueCat/Adapty 2026), so plans are ordered and pre-selected
  /// annual-first. Weekly stays available as the price-sensitive fallback.
  static int _planRank(Package p) => switch (p.packageType) {
        PackageType.annual => 0,
        PackageType.monthly => 1,
        PackageType.weekly => 2,
        _ => 3,
      };

  Future<void> _loadPackages() async {
    final packages = await PurchasesService.getAvailablePackages();
    if (mounted) {
      setState(() {
        _packages = List.of(packages)
          ..sort((a, b) => _planRank(a).compareTo(_planRank(b)));
        // Remote Config: hide weekly in geos/experiments where it cannibalizes
        // annual (weekly stays available as price-sensitive fallback default).
        if (!RemoteConfigService.showWeeklyPlan) {
          _packages = _packages
              .where((p) => p.packageType != PackageType.weekly)
              .toList();
        }
        _isLoadingPackages = false;
        // Remote Config: which plan is pre-selected (annual by default —
        // health is the one category where annual dominates revenue).
        final preferred = switch (RemoteConfigService.defaultPlan) {
          'monthly' => PackageType.monthly,
          'weekly' => PackageType.weekly,
          _ => PackageType.annual,
        };
        final idx = _packages.indexWhere((p) => p.packageType == preferred);
        _selectedPlan = idx != -1 ? idx : 0;
      });
    }
  }

  /// Days in the selected package's introductory free trial, if any.
  int? _trialDays(Package p) {
    final intro = p.storeProduct.introductoryPrice;
    if (intro == null || intro.price != 0) return null;
    final units = intro.periodNumberOfUnits;
    return switch (intro.periodUnit) {
      PeriodUnit.day => units,
      PeriodUnit.week => units * 7,
      PeriodUnit.month => units * 30,
      PeriodUnit.year => units * 365,
      _ => null,
    };
  }

  @override
  void dispose() {
    if (!_purchaseSuccess) {
      GrowthTracker.trackPaywall('close');
    }
    super.dispose();
  }

  Future<void> _handlePurchase() async {
    if (_isLoading) return;
    HapticEngine.medium();
    final state = Provider.of<AppState>(context, listen: false);

    await GrowthTracker.trackPaywall('attempt');
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      if (_packages.isEmpty) return;
      final packageId = _packages[_selectedPlan].identifier;
      final success = await state.purchasePremium(packageId);
      if (!mounted) return;

      if (success) {
        HapticEngine.success();
        _purchaseSuccess = true;
        await GrowthTracker.trackPaywall('success');
        // Conversion event for Firebase A/B tests & funnels (was never
        // called anywhere — experiments need this as their goal metric).
        await AnalyticsService.logSubscriptionStart(packageId);
        await _scheduleTrialReminder(_packages[_selectedPlan]);
        widget.onSuccess?.call();
        if (!mounted) return;
        Navigator.of(context).pop();
      } else {
        setState(() {
          _errorMsg = 'Purchase could not be completed. Please try again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMsg = 'An error occurred. Please try again.';
        _isLoading = false;
      });
    }
  }

  /// Schedule the promised "before your trial ends" push. Fires the day
  /// before billing; cuts refund complaints and builds trust (Blinkist -55%).
  Future<void> _scheduleTrialReminder(Package package) async {
    if (!_trialReminder || !RemoteConfigService.trialReminderEnabled) return;
    final days = _trialDays(package);
    if (days == null || days < 2) return;
    try {
      await NotificationService.scheduleOneOffReminder(
        id: 990021,
        title: 'Your Med AI Pro trial ends tomorrow',
        body:
            'You\'re on day ${days - 1} of $days. Keep Pro or cancel anytime in your store settings — no surprises.',
        scheduledDate: DateTime.now().add(Duration(days: days - 1)),
        payload: 'trial_reminder',
      );
    } catch (_) {/* never block a successful purchase on a reminder */}
  }

  Future<void> _handleRestore() async {
    HapticEngine.light();
    setState(() => _isLoading = true);
    final state = Provider.of<AppState>(context, listen: false);
    await state.restorePurchases();
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  void _dismiss() {
    HapticEngine.light();
    // Exit offer (Remote Config, default OFF): instead of closing, downsell
    // to the weekly plan once. Uses only real store SKUs — no fake discounts,
    // so it stays App Review-safe. Test on Android first (see blueprint §5).
    if (!_exitOfferShown &&
        !_purchaseSuccess &&
        widget.variant == PaywallVariant.onboarding &&
        RemoteConfigService.getBool('paywall_exit_offer_enabled')) {
      final weekly = _packages
          .indexWhere((p) => p.packageType == PackageType.weekly);
      if (weekly != -1) {
        setState(() {
          _exitOfferShown = true;
          _selectedPlan = weekly;
        });
        GrowthTracker.trackPaywall('exit_offer_shown');
        return;
      }
    }
    widget.onDismiss?.call();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final reduceMotion = MedAiA11y.reducedMotion(context);

    Widget sheet = Semantics(
      scopesRoute: true,
      namesRoute: true,
      label: 'Med AI Pro subscription',
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF1C1309).withValues(alpha: 0.94), // Dark Gold
                  AppColors.bgDark.withValues(alpha: 0.98),
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              border: Border(
                top: BorderSide(color: L.glassBorder.withValues(alpha: 0.2)),
              ),
            ),
            child: Stack(
              children: [
                if (!reduceMotion)
                  const Positioned(
                    top: -40,
                    left: -20,
                    right: -20,
                    height: 200,
                    child: IgnorePointer(
                      child: AuroraBackground(opacity: 0.35),
                    ),
                  ),
                SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(24, 12, 24, bottomPad + 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            const Spacer(),
                            Semantics(
                              button: true,
                              label: 'Close paywall',
                              child: AnimatedPressable(
                                onTap: _dismiss,
                                scaleFactor: 0.92,
                                child: Container(
                                  width: AppA11y.minTapTargetCompact,
                                  height: AppA11y.minTapTargetCompact,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.08),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.12),
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.close_rounded,
                                    color: Colors.white.withValues(alpha: 0.7),
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Center(
                          child: Container(
                            width: 36,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        if (widget.variant == PaywallVariant.onboarding)
                          const ObPaywallFeatureGrid(),
                        if (widget.variant == PaywallVariant.onboarding)
                          const SizedBox(height: 12),
                        if (_exitOfferShown) ...[
                          _PaywallGlassCard(
                            tint: AppColors.eatoGold.withValues(alpha: 0.10),
                            child: Row(
                              children: [
                                const Text('👋',
                                    style: TextStyle(fontSize: 22)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Wait — not ready for a year? Try Med AI Pro by the week. Cancel anytime.',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: Colors.white
                                          .withValues(alpha: 0.9),
                                      fontWeight: FontWeight.w600,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        _buildHeader(L),
                        const SizedBox(height: 20),
                        if (widget.variant == PaywallVariant.onboarding) ...[
                          if (RemoteConfigService.showTrialTimeline) ...[
                            _buildTrialTimeline(L),
                            const SizedBox(height: 20),
                          ],
                          _buildComparisonTable(L),
                          const SizedBox(height: 20),
                          _buildSocialProofRow(),
                          const SizedBox(height: 20),
                        ],
                        if (widget.variant == PaywallVariant.featureGate) ...[
                          _buildTriggerBanner(),
                          const SizedBox(height: 24),
                        ],
                        _buildFeatureList(L),
                        const SizedBox(height: 24),
                        _buildPlanSelector(L),
                        if (widget.variant == PaywallVariant.onboarding) ...[
                          const SizedBox(height: 16),
                          _buildTrialReminderToggle(),
                        ],
                        const SizedBox(height: 20),
                        if (_errorMsg != null) ...[
                          _PaywallErrorBanner(message: _errorMsg!),
                          const SizedBox(height: 12),
                        ],
                        _buildCtaButton(L),
                        const SizedBox(height: 12),
                        _buildLegalSection(L),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (!reduceMotion) {
      sheet = sheet
          .animate()
          .slideY(begin: 0.2, end: 0, duration: 480.ms, curve: AppCurves.expressive)
          .fadeIn(duration: 280.ms);
    }

    return sheet;
  }

  Widget _buildTrialReminderToggle() {
    return Semantics(
      label: 'Remind me before the trial ends',
      toggled: _trialReminder,
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Remind me before the trial ends',
              style: AppTypography.bodySmall.copyWith(
                color: Colors.white.withValues(alpha: 0.75),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch.adaptive(
            value: _trialReminder,
            activeTrackColor: AppColors.eatoGold.withValues(alpha: 0.45),
            thumbColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? AppColors.eatoGold
                  : Colors.white,
            ),
            onChanged: (v) {
              HapticEngine.selection();
              setState(() => _trialReminder = v);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AppThemeColors L) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 150,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            color: Colors.white.withValues(alpha: 0.03),
          ),
          child: SvgPicture.asset(
            PremiumGraphics.paywallPro,
            fit: BoxFit.contain,
            placeholderBuilder: (_) => const MedAiAnimation(
              kind: MedAiAnimationKind.paywallHero,
              width: 100,
              height: 100,
            ),
          ),
        ).entranceHero(),
        const SizedBox(height: 16),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.white, AppColors.eatoGold],
          ).createShader(bounds),
          blendMode: BlendMode.srcIn,
          child: Text(
            'Med AI Pro',
            style: AppTypography.displaySmall.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 32,
              letterSpacing: -0.8,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          // A/B: 'personalized' uses the onboarding-goal headline;
          // 'generic' forces the default copy for comparison.
          (RemoteConfigService.getString('paywall_headline_variant') ==
                      'generic'
                  ? null
                  : widget.personalizedHeadline) ??
              (widget.variant == PaywallVariant.onboarding
                  ? 'Your success plan starts free — cancel anytime.'
                  : 'Unlock the full plan made for your medication life.'),
          style: AppTypography.bodyMedium.copyWith(
            color: Colors.white.withValues(alpha: 0.55),
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTrialTimeline(AppThemeColors L) {
    const steps = [
      ('Today', 'Full Pro access free'),
      ('Day 5', 'Reminder before trial ends'),
      ('Day 7', 'Plan begins unless cancelled'),
    ];
    return Row(
      children: steps.asMap().entries.map((e) {
        final i = e.key;
        final (day, desc) = e.value;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.eatoGold.withValues(alpha: 0.25),
                            AppColors.amberDark.withValues(alpha: 0.15),
                          ],
                        ),
                        border: Border.all(color: AppColors.eatoGold),
                        boxShadow: AppShadows.glow(
                          AppColors.eatoGold,
                          intensity: 0.2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${i + 1}',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.eatoGold,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      day,
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      desc,
                      textAlign: TextAlign.center,
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 9,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              if (i < steps.length - 1)
                Container(
                  width: 16,
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.15),
                  margin: const EdgeInsets.only(bottom: 40),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildComparisonTable(AppThemeColors L) {
    const rows = [
      ('Unlimited AI scans', false, true),
      ('PDF doctor reports', false, true),
      ('Streak freeze', false, true),
      ('Unlimited medications', false, true),
    ];
    return _PaywallGlassCard(
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(flex: 3, child: SizedBox()),
              Expanded(
                child: Text(
                  'Free',
                  textAlign: TextAlign.center,
                  style: AppTypography.labelSmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Pro',
                  textAlign: TextAlign.center,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.eatoGold,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...rows.map((row) {
            final (label, free, pro) = row;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      label,
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 11,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Icon(
                      free ? Icons.check_rounded : Icons.close_rounded,
                      size: 16,
                      color: free
                          ? Colors.white.withValues(alpha: 0.5)
                          : Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  Expanded(
                    child: Icon(
                      Icons.check_circle_rounded,
                      size: 16,
                      color: pro ? AppColors.eatoGold : Colors.white24,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSocialProofRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ...List.generate(
          5,
          (_) => const Icon(Icons.star_rounded, color: AppColors.amberDark, size: 16),
        ),
        const SizedBox(width: 8),
        Text(
          '4.9 · Trusted by 500K+ people',
          style: AppTypography.labelSmall.copyWith(
            color: Colors.white.withValues(alpha: 0.6),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildTriggerBanner() {
    final messages = {
      'scan_limit':
          'Keep scanning with confidence.\nUnlock unlimited AI medicine recognition.',
      'voice_limit':
          'Keep logging by voice.\nUnlock unlimited AI voice logging.',
      'report_export':
          'Share clear reports with your doctor.\nUnlock PDF exports on Pro.',
      'unlimited_meds':
          'Track every medicine that matters to you.\nPro unlocks unlimited meds.',
      'streak_freeze':
          'Protect the success you\'ve built.\nStreak Freeze is available on Pro.',
      'onboarding':
          'Continue your success plan.\nStart your free trial today.',
      'generic':
          'Continue your success plan.\nStart your free trial today.',
    };

    final msg = messages[widget.triggerSource] ?? messages['generic']!;

    return _PaywallGlassCard(
      tint: AppColors.eatoGold.withValues(alpha: 0.08),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.eatoGold.withValues(alpha: 0.15),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.eatoGold,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              msg,
              style: AppTypography.bodySmall.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
                fontWeight: FontWeight.w500,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureList(AppThemeColors L) {
    final reduceMotion = MedAiA11y.reducedMotion(context);
    return Column(
      children: _features.asMap().entries.map((e) {
        final row = _FeatureRow(feature: e.value);
        if (reduceMotion) return row;
        return row
            .animate(delay: (e.key * 50).ms)
            .fadeIn(duration: 360.ms, curve: AppCurves.expressive)
            .slideX(begin: -0.06, end: 0, curve: AppCurves.expressive);
      }).toList(),
    );
  }

  Widget _buildPlanSelector(AppThemeColors L) {
    if (_isLoadingPackages) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: AppShimmer(width: double.infinity, height: 100, radius: 16),
        ),
      );
    }

    if (_packages.isEmpty) {
      return _PaywallGlassCard(
        child: Text(
          'Subscription plans are currently unavailable.',
          style: AppTypography.labelSmall.copyWith(
            color: Colors.white.withValues(alpha: 0.5),
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Row(
      children: _packages.asMap().entries.map((e) {
        final i = e.key;
        final package = e.value;
        final isSelected = i == _selectedPlan;

        final isAnnual = package.packageType == PackageType.annual;
        final trialDays = _trialDays(package);
        // Apple bans trial-enable toggles (Guideline 3.1.2); the compliant
        // pattern is a plan that inherently includes a trial, badged.
        final badge = trialDays != null
            ? '$trialDays-day free trial'
            : isAnnual
                ? 'Save 58%'
                : (package.packageType == PackageType.lifetime
                    ? 'Best value'
                    : null);

        // Daily/weekly breakdown reduces sticker shock (the Lily pattern).
        String? equivalentText;
        if (isAnnual) {
          final perWeek = package.storeProduct.price / 52;
          equivalentText =
              '≈ ${package.storeProduct.currencyCode} ${perWeek.toStringAsFixed(2)}/week';
        }

        String periodText = '';
        if (package.packageType == PackageType.weekly) {
          periodText = '/ week';
        } else if (package.packageType == PackageType.monthly) {
          periodText = '/ month';
        } else if (package.packageType == PackageType.annual) {
          periodText = '/ year';
        } else {
          periodText = 'one-time';
        }

        return Expanded(
          child: Semantics(
            button: true,
            selected: isSelected,
            label:
                '${package.storeProduct.title}, ${package.storeProduct.priceString}$periodText',
            child: AnimatedPressable(
              onTap: () {
                HapticEngine.selection();
                setState(() => _selectedPlan = i);
              },
              scaleFactor: 0.97,
              child: AnimatedContainer(
                duration: MedAiA11y.motion(context, AppDurations.fast),
                curve: AppCurves.expressive,
                margin: EdgeInsetsDirectional.only(start: i == 0 ? 0 : 8),
                constraints: const BoxConstraints(minHeight: 88),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.eatoGold.withValues(alpha: 0.18),
                            AppColors.amberDark.withValues(alpha: 0.08),
                          ],
                        )
                      : null,
                  color: isSelected
                      ? null
                      : Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(AppRadius.l),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.eatoGold.withValues(alpha: 0.65)
                        : Colors.white.withValues(alpha: 0.08),
                    width: isSelected ? 1.5 : 0.5,
                  ),
                  boxShadow: isSelected
                      ? AppShadows.glow(AppColors.eatoGold, intensity: 0.25)
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (badge != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.eatoGold
                              : Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badge,
                          style: AppTypography.labelSmall.copyWith(
                            color: isSelected ? Colors.black : Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    Text(
                      package.storeProduct.title.split(' ').first,
                      style: AppTypography.labelSmall.copyWith(
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.45),
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        package.storeProduct.priceString,
                        style: AppTypography.titleMedium.copyWith(
                          color: isSelected
                              ? AppColors.eatoGold
                              : Colors.white.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    Text(
                      periodText,
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.35),
                        fontSize: 10,
                      ),
                    ),
                    if (equivalentText != null) ...[
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          equivalentText,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.eatoGold.withValues(alpha: 0.8),
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCtaButton(AppThemeColors L) {
    if (_isLoadingPackages) {
      return const AppShimmer(width: double.infinity, height: 58, radius: 18);
    }

    final hasPackages = _packages.isNotEmpty;
    final selected = hasPackages ? _packages[_selectedPlan] : null;
    final buttonText = hasPackages
        ? 'Start ${selected!.storeProduct.title.split(' ').first} · ${selected.storeProduct.priceString}'
        : 'Unavailable';

    return _PaywallCTA(
      label: buttonText,
      loading: _isLoading,
      enabled: hasPackages && !_isLoading,
      onTap: hasPackages ? _handlePurchase : null,
    );
  }

  Widget _buildLegalSection(AppThemeColors L) {
    return Column(
      children: [
        Semantics(
          button: true,
          label: 'Restore purchases',
          child: AnimatedPressable(
            onTap: _handleRestore,
            hitTestPadding: const EdgeInsets.all(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Restore Purchases',
                style: AppTypography.labelSmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.white.withValues(alpha: 0.25),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Subscription auto-renews unless cancelled at least 24 hours before the end of the current period. '
          'Manage or cancel any time in your device\'s App Store / Play Store account settings.',
          style: AppTypography.labelSmall.copyWith(
            color: Colors.white.withValues(alpha: 0.28),
            fontSize: 10,
            height: 1.6,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _PaywallLegalLink(label: 'Privacy Policy', url: kPrivacyPolicyUrl),
            Text(
              '  ·  ',
              style: AppTypography.labelSmall.copyWith(
                color: Colors.white.withValues(alpha: 0.2),
                fontSize: 10,
              ),
            ),
            _PaywallLegalLink(label: 'Terms of Use', url: kTermsOfServiceUrl),
          ],
        ),
      ],
    );
  }
}

// ── Shared paywall primitives ─────────────────────────────────

class _Feature {
  final IconData icon;
  final String label;
  final String sub;
  const _Feature({required this.icon, required this.label, required this.sub});
}

class _PaywallGlassCard extends StatelessWidget {
  final Widget child;
  final Color? tint;
  const _PaywallGlassCard({required this.child, this.tint});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.l),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: tint ?? Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(AppRadius.l),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 0.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _PaywallErrorBanner extends StatelessWidget {
  final String message;
  const _PaywallErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.redDark.withValues(alpha: 0.12),
        borderRadius: AppRadius.roundM,
        border: Border.all(
          color: AppColors.redDark.withValues(alpha: 0.35),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.redDark, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaywallCTA extends StatelessWidget {
  final String label;
  final bool loading;
  final bool enabled;
  final VoidCallback? onTap;

  const _PaywallCTA({
    required this.label,
    this.loading = false,
    this.enabled = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = enabled && !loading && onTap != null;
    final reduceMotion = MedAiA11y.reducedMotion(context);

    Widget btn = Semantics(
      button: true,
      enabled: active,
      label: label,
      child: AnimatedPressable(
        onTap: active ? onTap : null,
        disabled: !active,
        scaleFactor: 0.96,
        lightHaptic: false,
        child: AnimatedContainer(
          duration: MedAiA11y.motion(context, AppDurations.micro),
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: AppA11y.minTapTarget),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            gradient: active
                ? const LinearGradient(
                    begin: AlignmentDirectional.centerStart,
                    end: AlignmentDirectional.centerEnd,
                    colors: [
                      AppColors.eatoGold,
                      AppColors.amberDark,
                    ],
                  )
                : LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.08),
                      Colors.white.withValues(alpha: 0.04),
                    ],
                  ),
            borderRadius: AppRadius.roundXL,
            boxShadow: active
                ? AppShadows.glow(AppColors.eatoGold, intensity: 0.4)
                : null,
          ),
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.bgDark,
                    ),
                  )
                : Text(
                    label,
                    style: AppTypography.labelLarge.copyWith(
                      color: active
                          ? AppColors.bgDark
                          : Colors.white.withValues(alpha: 0.45),
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      letterSpacing: -0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
          ),
        ),
      ),
    );

    if (active && !reduceMotion && !loading) {
      btn = btn.animate(onPlay: (c) => c.repeat()).shimmer(
            duration: 2800.ms,
            color: Colors.white.withValues(alpha: 0.25),
          );
    }

    return btn;
  }
}

class _FeatureRow extends StatelessWidget {
  final _Feature feature;
  const _FeatureRow({required this.feature});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.1),
                  Colors.white.withValues(alpha: 0.04),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
                width: 0.5,
              ),
            ),
            child: Center(
              child: Icon(
                feature.icon,
                size: 18,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.label,
                  style: AppTypography.labelMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  feature.sub,
                  style: AppTypography.labelSmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.42),
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.check_circle_rounded,
            color: AppColors.eatoGold,
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _PaywallLegalLink extends StatelessWidget {
  final String label;
  final String url;
  const _PaywallLegalLink({required this.label, required this.url});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      link: true,
      label: label,
      child: AnimatedPressable(
        onTap: () async {
          HapticEngine.light();
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) launchUrl(uri);
        },
        hitTestPadding: const EdgeInsets.all(6),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: Colors.white.withValues(alpha: 0.35),
            fontSize: 10,
            decoration: TextDecoration.underline,
            decorationColor: Colors.white.withValues(alpha: 0.2),
          ),
        ),
      ),
    );
  }
}
