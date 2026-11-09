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
import '../../l10n/app_localizations.dart';
import 'paywall_plans.dart';

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
    _Feature(
        icon: Icons.document_scanner_rounded,
        label: 'Unlimited AI Scans',
        sub: 'No daily limit on pill recognition'),
    // PDF reports and history export are free for everyone: locking people
    // out of their own records is the top 1-star complaint across the
    // category (Medisafe, CareClinic). Pro sells insight, not access.
    _Feature(
        icon: Icons.family_restroom_rounded,
        label: 'Care Circle Insights',
        sub: 'See how everyone you look after is doing'),
    _Feature(
        icon: Icons.forum_rounded,
        label: 'Ask Med AI',
        sub: 'Unlimited answers from your own history'),
    _Feature(
        icon: Icons.medication_rounded,
        label: 'Unlimited Medications',
        sub: 'Track every med without limits'),
    _Feature(
        icon: Icons.local_fire_department_rounded,
        label: 'Streak Freeze Protection',
        sub: 'Never lose your streak'),
    // Not "HIPAA": that statute binds covered entities (providers, insurers and their
    // business associates), not a direct-to-consumer app, so claiming it is a
    // misleading-claims risk. The privacy screen already says "HIPAA-equivalent
    // security practices" — keep this consistent with that.
    _Feature(
        icon: Icons.lock_rounded,
        label: 'Priority Biometric Lock',
        sub: 'Advanced privacy mode'),
    _Feature(
        icon: Icons.psychology_alt_rounded,
        label: 'AI Drug Interactions',
        sub: 'Full Gemini-powered analysis'),
  ];

  @override
  void initState() {
    super.initState();
    GrowthTracker.trackPaywall('view');
    _loadPackages();
  }

  static PlanKind _kindOf(Package p) => planKindOf(
        identifier: p.identifier,
        isAnnual: p.packageType == PackageType.annual,
        isMonthly: p.packageType == PackageType.monthly,
        isWeekly: p.packageType == PackageType.weekly,
        isLifetime: p.packageType == PackageType.lifetime,
      );

  /// Health & Fitness is the one category where annual dominates revenue
  /// (60.6% — RevenueCat/Adapty 2026), so plans are ordered and pre-selected
  /// annual-first. See [planRank].
  static int _planRank(Package p) => planRank(_kindOf(p));

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
        if (_packages.isNotEmpty) {
          _selectedPlan = _selectedPlan.clamp(0, _packages.length - 1);
        }
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
      if (_packages.isEmpty) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMsg = PurchasesService.isMisconfigured
              ? 'In-app purchases are not set up in this build yet.'
              : "Plans didn't load. Check your connection and try again.";
        });
        return;
      }
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
      final weekly =
          _packages.indexWhere((p) => p.packageType == PackageType.weekly);
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
    final l10n = AppLocalizations.of(context)!;
    final L = context.L;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final reduceMotion = MedAiA11y.reducedMotion(context);

    Widget sheet = Semantics(
      scopesRoute: true,
      // Required by the framework whenever scopesRoute is true — without it
      // RenderObject.attach asserts and the whole app falls into the global
      // error boundary ("Something went wrong"). This fired when the paywall
      // was presented over the scanner, taking the app down with it.
      explicitChildNodes: true,
      namesRoute: true,
      label: l10n.paywallMedAiProSubscription,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFFBFBF8),
                Color(0xFFF7F6F3),
              ],
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            border: Border(
              top: BorderSide(color: Color(0xFFE8EAE6)),
            ),
          ),
          child: Stack(
            children: [
              if (!reduceMotion)
                const Positioned(
                  top: -60,
                  left: -40,
                  right: -40,
                  height: 220,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment(0, -0.2),
                          radius: 1.0,
                          colors: [
                            Color(0x66E4F5E7),
                            Color(0x00F7F6F3),
                          ],
                        ),
                      ),
                    ),
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
                            label: l10n.paywallClosePaywall,
                            child: AnimatedPressable(
                              onTap: _dismiss,
                              scaleFactor: 0.92,
                              child: Container(
                                width: AppA11y.minTapTargetCompact,
                                height: AppA11y.minTapTargetCompact,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFFE8EAE6),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  color: Color(0xFF1A1D26),
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
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8EAE6),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      if (_exitOfferShown) ...[
                        _PaywallGlassCard(
                          tint: AppColors.pastelMint,
                          child: Row(
                            children: [
                              const Text('👋', style: TextStyle(fontSize: 22)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  l10n.paywallWaitNotReadyForAYear,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: const Color(0xFF1A1D26),
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
                        if (RemoteConfigService.showTrialTimeline &&
                            _packages.isNotEmpty &&
                            _trialDays(_packages[_selectedPlan]) != null) ...[
                          _buildTrialTimeline(L),
                          const SizedBox(height: 18),
                        ],
                      ],
                      if (widget.variant == PaywallVariant.featureGate) ...[
                        _buildTriggerBanner(),
                        const SizedBox(height: 20),
                      ],
                      _buildFeatureList(L),
                      const SizedBox(height: 20),
                      _buildPlanSelector(L),
                      const SizedBox(height: 14),
                      if (widget.variant == PaywallVariant.onboarding) ...[
                        _buildTrialReminderToggle(),
                        const SizedBox(height: 16),
                      ],
                      if (_errorMsg != null) ...[
                        _PaywallErrorBanner(message: _errorMsg!),
                        const SizedBox(height: 12),
                      ],
                      _buildCtaButton(L),
                      const SizedBox(height: 12),
                      _buildSocialProofRow(),
                      const SizedBox(height: 20),
                      _buildComparisonTable(L),
                      const SizedBox(height: 16),
                      _buildLegalSection(L),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (!reduceMotion) {
      sheet = sheet
          .animate()
          .slideY(
              begin: 0.2, end: 0, duration: 480.ms, curve: AppCurves.expressive)
          .fadeIn(duration: 280.ms);
    }

    return sheet;
  }

  Widget _buildTrialReminderToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EAE6)),
      ),
      child: Semantics(
        label: 'Remind me before the trial ends',
        toggled: _trialReminder,
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.pastelMint,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.notifications_active_rounded,
                size: 18,
                color: AppColors.limeDeep,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trial Ending Reminder',
                    style: AppTypography.bodySmall.copyWith(
                      color: const Color(0xFF1A1D26),
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                  Text(
                    'We will notify you 24 hours before your trial ends.',
                    style: AppTypography.labelSmall.copyWith(
                      color: const Color(0xFF8A9099),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: _trialReminder,
              activeTrackColor: AppColors.limeDeep.withValues(alpha: 0.55),
              thumbColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? AppColors.limeDeep
                    : Colors.white,
              ),
              onChanged: (v) {
                HapticEngine.selection();
                setState(() => _trialReminder = v);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppThemeColors L) {
    final headline =
        (RemoteConfigService.getString('paywall_headline_variant') == 'generic'
                ? null
                : widget.personalizedHeadline) ??
            (widget.variant == PaywallVariant.onboarding
                ? 'Your personalized medication plan is ready.'
                : 'Unlock the full plan made for your medication life.');

    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 140,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.limeDeep.withValues(alpha: 0.25),
              width: 1,
            ),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFF0FDF4),
                Color(0xFFDCFCE7),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.limeDeep.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              SvgPicture.asset(
                PremiumGraphics.paywallPro,
                fit: BoxFit.contain,
                placeholderBuilder: (_) => const MedAiAnimation(
                  kind: MedAiAnimationKind.paywallHero,
                  width: 100,
                  height: 100,
                ),
              ),
              Positioned(
                top: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.limeDeep,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.limeDeep.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded,
                          color: AppColors.limeInk, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'MED AI PRO',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.limeInk,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ).entranceHero(),
        const SizedBox(height: 18),
        Text(
          'Med AI Pro',
          style: AppTypography.displaySmall.copyWith(
            color: const Color(0xFF1A1D26),
            fontWeight: FontWeight.w800,
            fontSize: 30,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          headline,
          style: AppTypography.bodyMedium.copyWith(
            color: const Color(0xFF4B5563),
            fontWeight: FontWeight.w600,
            fontSize: 15,
            height: 1.35,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFE8EAE6)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...List.generate(
                5,
                (i) => const Icon(
                  Icons.star_rounded,
                  color: Color(0xFFF59E0B),
                  size: 15,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '4.8 · Doctor & Caregiver Trusted',
                style: AppTypography.caption.copyWith(
                  color: const Color(0xFF1F2937),
                  fontWeight: FontWeight.w700,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrialTimeline(AppThemeColors L) {
    final selected = _packages.isEmpty ? null : _packages[_selectedPlan];
    final steps = trialTimeline(selected == null ? null : _trialDays(selected));
    if (steps.isEmpty) return const SizedBox.shrink();
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
                        color: AppColors.pastelMint,
                        border: Border.all(color: AppColors.limeDeep),
                      ),
                      child: Center(
                        child: Text(
                          '${i + 1}',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.limeInk,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      day,
                      style: AppTypography.labelSmall.copyWith(
                        color: const Color(0xFF1A1D26),
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      desc,
                      textAlign: TextAlign.center,
                      style: AppTypography.labelSmall.copyWith(
                        color: const Color(0xFF8A9099),
                        fontSize: 11,
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
                  color: const Color(0xFFE8EAE6),
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
      ('Missed-dose alerts to family', true, true),
      ('PDF reports & full history', true, true),
      ('Unlimited AI scans', false, true),
      ('Care circle insights', false, true),
      ('Ask Med AI, unlimited', false, true),
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
                    color: const Color(0xFF8A9099),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Pro',
                  textAlign: TextAlign.center,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.limeDeep,
                    fontWeight: FontWeight.w700,
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
                        color: const Color(0xFF1A1D26),
                        fontSize: 11,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Icon(
                      free ? Icons.check_rounded : Icons.close_rounded,
                      size: 16,
                      color: free
                          ? const Color(0xFF8A9099)
                          : const Color(0xFFE8EAE6),
                    ),
                  ),
                  Expanded(
                    child: Icon(
                      Icons.check_circle_rounded,
                      size: 16,
                      color: pro ? AppColors.limeDeep : const Color(0xFFE8EAE6),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8EAE6)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.verified_user_rounded,
              color: AppColors.limeDeep, size: 16),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Cancel anytime · Your health data is encrypted and never sold',
              style: AppTypography.labelSmall.copyWith(
                color: const Color(0xFF4B5563),
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTriggerBanner() {
    final messages = {
      'scan_limit':
          'Keep scanning with confidence.\nUnlock unlimited AI medicine recognition.',
      'voice_limit':
          'Keep logging by voice.\nUnlock unlimited AI voice logging.',
      'care_insights':
          'See how everyone you look after is doing.\nCare circle insights are on Pro — or free for your whole circle on Family.',
      'ask_ai':
          'Keep asking about your own medicines.\nPro unlocks unlimited Ask Med AI.',
      'unlimited_meds':
          'Track every medicine that matters to you.\nPro unlocks unlimited meds.',
      'streak_freeze':
          'Protect the success you\'ve built.\nStreak Freeze is available on Pro.',
      'onboarding': 'Continue your success plan.\nStart your free trial today.',
      'generic': 'Continue your success plan.\nStart your free trial today.',
    };

    final msg = messages[widget.triggerSource] ?? messages['generic']!;

    return _PaywallGlassCard(
      tint: AppColors.pastelMint,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.limeDeep,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              msg,
              style: AppTypography.bodySmall.copyWith(
                color: const Color(0xFF1A1D26),
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
          // Two very different causes produce an empty package list. A build
          // with no RevenueCat key can never sell anything, so telling that
          // user to "try again later" is advice that can never come true;
          // a transient offerings fetch genuinely is worth retrying.
          PurchasesService.isMisconfigured
              ? 'In-app purchases are not set up in this build yet. '
                  'Everything else works — nothing is charged.'
              : "Plans didn't load. Check your connection and reopen this "
                  'screen to try again.',
          style: AppTypography.labelSmall.copyWith(
            color: const Color(0xFF8A9099),
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    final monthly =
        _packages.where((p) => _kindOf(p) == PlanKind.monthly).firstOrNull;

    Widget tile(int i) {
      final package = _packages[i];
      final isSelected = i == _selectedPlan;
      final kind = _kindOf(package);

      final isAnnual = kind == PlanKind.annual;
      final trialDays = _trialDays(package);
      final savings = isAnnual && monthly != null
          ? annualSavingsPercent(
              annualPrice: package.storeProduct.price,
              monthlyPrice: monthly.storeProduct.price,
              annualCurrency: package.storeProduct.currencyCode,
              monthlyCurrency: monthly.storeProduct.currencyCode,
            )
          : null;
      // Apple bans trial-enable toggles (Guideline 3.1.2); the compliant
      // pattern is a plan that inherently includes a trial, badged. Every
      // other badge is derived from store data — the "Save 58%" this
      // replaced was a constant, true of no particular price.
      final badge = trialDays != null
          ? '$trialDays-day free trial'
          : savings != null
              ? 'Save $savings%'
              : switch (kind) {
                  PlanKind.family => 'Whole circle',
                  PlanKind.lifetime => 'Pay once',
                  _ => null,
                };

      // Daily/weekly breakdown reduces sticker shock (the Lily pattern).
      String? equivalentText;
      if (isAnnual) {
        final perWeek = package.storeProduct.price / 52;
        equivalentText =
            '≈ ${package.storeProduct.currencyCode} ${perWeek.toStringAsFixed(2)}/week';
      } else if (kind == PlanKind.family) {
        equivalentText = 'Pro for all caregivers';
      }

      final periodText =
          periodLabel(kind, isoPeriod: package.storeProduct.subscriptionPeriod);

      return Semantics(
        button: true,
        selected: isSelected,
        label:
            '${planName(kind)}, ${package.storeProduct.priceString} $periodText',
        child: AnimatedPressable(
          onTap: () {
            HapticEngine.selection();
            setState(() => _selectedPlan = i);
          },
          scaleFactor: 0.97,
          child: AnimatedContainer(
            duration: MedAiA11y.motion(context, AppDurations.fast),
            curve: AppCurves.expressive,
            constraints: const BoxConstraints(minHeight: 96),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFF0FDF4) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color:
                    isSelected ? AppColors.limeDeep : const Color(0xFFE8EAE6),
                width: isSelected ? 2.0 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? AppColors.limeDeep.withValues(alpha: 0.16)
                      : const Color(0xFF1A2621).withValues(alpha: 0.04),
                  blurRadius: isSelected ? 18 : 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (badge != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.limeDeep
                              : const Color(0xFFF0F1EE),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badge,
                          style: AppTypography.labelSmall.copyWith(
                            color: isSelected
                                ? AppColors.limeInk
                                : const Color(0xFF8A9099),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                  ],
                ),
                if (badge != null) const SizedBox(height: 6),
                Text(
                  planName(kind),
                  style: AppTypography.labelSmall.copyWith(
                    color: isSelected
                        ? const Color(0xFF111827)
                        : const Color(0xFF6B7280),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
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
                          ? const Color(0xFF065F46)
                          : const Color(0xFF1A1D26),
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                Text(
                  periodText,
                  style: AppTypography.labelSmall.copyWith(
                    color: const Color(0xFF8A9099),
                    fontSize: 11,
                  ),
                ),
                if (equivalentText != null) ...[
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.limeDeep.withValues(alpha: 0.15)
                            : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        equivalentText,
                        style: AppTypography.labelSmall.copyWith(
                          color: isSelected
                              ? const Color(0xFF047857)
                              : const Color(0xFF6B7280),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    Widget cell(int i) => Expanded(
          child: Padding(
            padding: EdgeInsetsDirectional.only(start: i.isEven ? 0 : 8),
            child: tile(i),
          ),
        );

    // Up to three plans fit one row. Four (yearly, family, monthly,
    // lifetime) would squeeze each tile below its price, so they wrap into
    // a 2x2 grid of the same tiles. IntrinsicHeight bounds the stretched
    // rows inside the scroll view so tiles in a row match the tallest.
    if (_packages.length <= 3) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < _packages.length; i++)
              Expanded(
                child: Padding(
                  padding: EdgeInsetsDirectional.only(start: i == 0 ? 0 : 8),
                  child: tile(i),
                ),
              ),
          ],
        ),
      );
    }
    return Column(
      children: [
        for (var r = 0; r < _packages.length; r += 2) ...[
          if (r > 0) const SizedBox(height: 8),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                cell(r),
                if (r + 1 < _packages.length) cell(r + 1) else const Spacer(),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCtaButton(AppThemeColors L) {
    if (_isLoadingPackages) {
      return const AppShimmer(width: double.infinity, height: 58, radius: 18);
    }

    final hasPackages = _packages.isNotEmpty;
    final selected = hasPackages ? _packages[_selectedPlan] : null;
    final trialDays = selected != null ? _trialDays(selected) : null;

    final String buttonText;
    final String? subText;

    if (hasPackages && selected != null) {
      if (trialDays != null && trialDays > 0) {
        buttonText = 'Start $trialDays-Day Free Trial';
        subText =
            '3 days free, then ${selected.storeProduct.priceString} / year · Cancel anytime';
      } else {
        buttonText =
            'Start ${planName(_kindOf(selected))} · ${selected.storeProduct.priceString}';
        subText = 'Cancel anytime in store settings';
      }
    } else {
      buttonText =
          PurchasesService.isMisconfigured ? 'Not available yet' : 'Retry';
      subText = null;
    }

    return _PaywallCTA(
      label: buttonText,
      sublabel: subText,
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
                  color: const Color(0xFF8A9099),
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                  decorationColor: const Color(0xFFE8EAE6),
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
            color: const Color(0xFF8A9099),
            fontSize: 11,
            height: 1.6,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _PaywallLegalLink(label: 'Privacy Policy', url: kPrivacyPolicyUrl),
            Text(
              '  ·  ',
              style: TextStyle(
                color: Color(0xFF8A9099),
                fontSize: 11,
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tint ?? Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.l),
        border: Border.all(color: const Color(0xFFE8EAE6)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A2621).withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
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
        color: AppColors.redDark.withValues(alpha: 0.08),
        borderRadius: AppRadius.roundM,
        border: Border.all(
          color: AppColors.redDark.withValues(alpha: 0.28),
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
                color: const Color(0xFF1A1D26),
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
  final String? sublabel;
  final bool loading;
  final bool enabled;
  final VoidCallback? onTap;

  const _PaywallCTA({
    required this.label,
    this.sublabel,
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
      label: sublabel != null ? '$label. $sublabel' : label,
      child: AnimatedPressable(
        onTap: active ? onTap : null,
        disabled: !active,
        scaleFactor: 0.96,
        lightHaptic: false,
        child: AnimatedContainer(
          duration: MedAiA11y.motion(context, AppDurations.micro),
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            gradient: active
                ? const LinearGradient(
                    begin: AlignmentDirectional.centerStart,
                    end: AlignmentDirectional.centerEnd,
                    colors: [
                      Color(0xFFE2F952),
                      Color(0xFF10B981),
                    ],
                  )
                : null,
            color: active ? null : AppColors.lime.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(999),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.limeInk,
                    ),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            label,
                            style: AppTypography.labelLarge.copyWith(
                              color: active
                                  ? AppColors.limeInk
                                  : AppColors.limeInk.withValues(alpha: 0.5),
                              fontWeight: FontWeight.w800,
                              fontSize: 16.5,
                              letterSpacing: -0.3,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 18,
                            color: active
                                ? AppColors.limeInk
                                : AppColors.limeInk.withValues(alpha: 0.5),
                          ),
                        ],
                      ),
                      if (sublabel != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          sublabel!,
                          style: AppTypography.labelSmall.copyWith(
                            color: active
                                ? AppColors.limeInk.withValues(alpha: 0.8)
                                : AppColors.limeInk.withValues(alpha: 0.4),
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );

    if (active && !reduceMotion && !loading) {
      btn = btn.animate(onPlay: (c) => c.repeat()).shimmer(
            duration: 2800.ms,
            color: Colors.white.withValues(alpha: 0.28),
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
              color: AppColors.pastelMint,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE8EAE6)),
            ),
            child: Center(
              child: Icon(
                feature.icon,
                size: 18,
                color: AppColors.limeInk,
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
                    color: const Color(0xFF1A1D26),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  feature.sub,
                  style: AppTypography.labelSmall.copyWith(
                    color: const Color(0xFF8A9099),
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.check_circle_rounded,
            color: AppColors.limeDeep,
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
            color: const Color(0xFF8A9099),
            fontSize: 11,
            decoration: TextDecoration.underline,
            decorationColor: const Color(0xFFE8EAE6),
          ),
        ),
      ),
    );
  }
}
