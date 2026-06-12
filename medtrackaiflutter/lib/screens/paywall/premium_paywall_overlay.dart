import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../services/purchases_service.dart';
import '../../core/utils/haptic_engine.dart';
import '../../widgets/common/app_shimmer.dart';


// ══════════════════════════════════════════════════════════════
// PREMIUM PAYWALL OVERLAY
// Apple Guideline 3.1.1 & Google Play Billing Policy Compliant
// ══════════════════════════════════════════════════════════════

class PremiumPaywallOverlay extends StatefulWidget {
  final String triggerSource; // e.g. 'scan_limit', 'report_export', 'unlimited_meds'
  final VoidCallback? onSuccess;
  final VoidCallback? onDismiss;

  const PremiumPaywallOverlay({
    super.key,
    this.triggerSource = 'generic',
    this.onSuccess,
    this.onDismiss,
  });

  static Future<void> show(
    BuildContext context, {
    String triggerSource = 'generic',
    VoidCallback? onSuccess,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (ctx) => PremiumPaywallOverlay(
        triggerSource: triggerSource,
        onSuccess: onSuccess,
        onDismiss: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  @override
  State<PremiumPaywallOverlay> createState() => _PremiumPaywallOverlayState();
}

class _PremiumPaywallOverlayState extends State<PremiumPaywallOverlay> {
  int _selectedPlan = 1; // Default: monthly
  bool _isLoading = false;
  String? _errorMsg;

  // Plan definitions
  static const _plans = [
    _PlanOption(
      id: '\$rc_weekly',
      label: 'Weekly',
      price: '\$1.99',
      period: '/ week',
      badge: null,
      annualEquiv: '\$103/yr',
    ),
    _PlanOption(
      id: '\$rc_monthly',
      label: 'Monthly',
      price: '\$6.99',
      period: '/ month',
      badge: 'POPULAR',
      annualEquiv: '\$84/yr',
    ),
    _PlanOption(
      id: '\$rc_lifetime',
      label: 'Lifetime',
      price: '\$49.99',
      period: 'one-time',
      badge: 'BEST VALUE',
      annualEquiv: null,
    ),
  ];

  static const _features = [
    _Feature(icon: '🔬', label: 'Unlimited AI Scans', sub: 'No daily limit on pill recognition'),
    _Feature(icon: '📊', label: 'Doctor Reports (PDF)', sub: 'Export clinical summaries anytime'),
    _Feature(icon: '💊', label: 'Unlimited Medications', sub: 'Track every med without limits'),
    _Feature(icon: '🔥', label: 'Streak Freeze Protection', sub: 'Never lose your streak'),
    _Feature(icon: '🔒', label: 'Priority Biometric Lock', sub: 'Advanced HIPAA privacy mode'),
    _Feature(icon: '🤖', label: 'AI Drug Interactions', sub: 'Full Gemini-powered analysis'),
  ];

  Future<void> _handlePurchase() async {
    if (_isLoading) return;
    HapticEngine.medium();
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      final packageId = _plans[_selectedPlan].id;
      final success = await PurchasesService.purchasePackage(packageId);
      if (!mounted) return;

      if (success) {
        HapticEngine.success();
        widget.onSuccess?.call();
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

  Future<void> _handleRestore() async {
    HapticEngine.light();
    setState(() => _isLoading = true);
    await PurchasesService.restorePurchases();
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.92,
          ),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.88),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 0.5),
              left: BorderSide(color: Colors.white.withValues(alpha: 0.05), width: 0.5),
              right: BorderSide(color: Colors.white.withValues(alpha: 0.05), width: 0.5),
            ),
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 16, 24, bottomPad + 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Drag handle ──
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Header ──
                  _buildHeader(L),
                  const SizedBox(height: 24),

                  // ── Trigger context message ──
                  _buildTriggerBanner(),
                  const SizedBox(height: 24),

                  // ── Feature list ──
                  _buildFeatureList(L),
                  const SizedBox(height: 24),

                  // ── Plan selector ──
                  _buildPlanSelector(L),
                  const SizedBox(height: 20),

                  // ── Error message ──
                  if (_errorMsg != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _errorMsg!,
                        style: AppTypography.labelSmall.copyWith(
                          color: L.error,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  // ── CTA Button ──
                  _buildCtaButton(L),
                  const SizedBox(height: 12),

                  // ── Restore & Legal ──
                  _buildLegalSection(L),
                ],
              ),
            ),
          ),
        ),
      ),
    )
        .animate()
        .slideY(begin: 0.3, end: 0, duration: 500.ms, curve: Curves.easeOutBack)
        .fadeIn(duration: 300.ms);
  }

  Widget _buildHeader(AppThemeColors L) {
    return Column(
      children: [
        // Crown badge
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFCDFF00), Color(0xFF86FF00)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFCDFF00).withValues(alpha: 0.4),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Center(
            child: Text('👑', style: TextStyle(fontSize: 30)),
          ),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scaleXY(end: 1.06, duration: 2000.ms, curve: Curves.easeInOutSine),
        const SizedBox(height: 16),
        Text(
          'Med AI Pro',
          style: AppTypography.displaySmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 32,
            letterSpacing: -1.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Your complete medication intelligence.',
          style: AppTypography.bodyMedium.copyWith(
            color: Colors.white.withValues(alpha: 0.5),
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTriggerBanner() {
    final messages = {
      'scan_limit': '🔬 You\'ve used your 3 free AI scans today.\nUpgrade for unlimited pill recognition.',
      'report_export': '📊 Doctor reports are a Pro feature.\nUnlock PDF exports for your physician.',
      'unlimited_meds': '💊 Free plan is limited to 3 active meds.\nPro gives you unlimited tracking.',
      'streak_freeze': '🔥 Save your streak with a Streak Freeze.\nAvailable on Pro plans.',
      'generic': '✨ Unlock everything Med AI has to offer.',
    };

    final msg = messages[widget.triggerSource] ?? messages['generic']!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFCDFF00).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFCDFF00).withValues(alpha: 0.25),
          width: 0.5,
        ),
      ),
      child: Text(
        msg,
        style: AppTypography.bodySmall.copyWith(
          color: Colors.white.withValues(alpha: 0.8),
          fontWeight: FontWeight.w500,
          height: 1.5,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildFeatureList(AppThemeColors L) {
    return Column(
      children: _features
          .asMap()
          .entries
          .map((e) => _FeatureRow(feature: e.value)
              .animate(delay: (e.key * 60).ms)
              .fadeIn(duration: 400.ms)
              .slideX(begin: -0.1, end: 0, curve: Curves.easeOutCubic))
          .toList(),
    );
  }

  Widget _buildPlanSelector(AppThemeColors L) {
    return Row(
      children: _plans.asMap().entries.map((e) {
        final i = e.key;
        final plan = e.value;
        final isSelected = i == _selectedPlan;

        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticEngine.selection();
              setState(() => _selectedPlan = i);
            },
            child: AnimatedContainer(
              duration: 250.ms,
              curve: Curves.easeOutCubic,
              margin: EdgeInsets.only(left: i == 0 ? 0 : 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFCDFF00).withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFCDFF00).withValues(alpha: 0.6)
                      : Colors.white.withValues(alpha: 0.08),
                  width: isSelected ? 1.0 : 0.5,
                ),
              ),
              child: Column(
                children: [
                  if (plan.badge != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFCDFF00)
                            : Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        plan.badge!,
                        style: AppTypography.labelSmall.copyWith(
                          color: isSelected ? Colors.black : Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  Text(
                    plan.label,
                    style: AppTypography.labelSmall.copyWith(
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.45),
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    plan.price,
                    style: AppTypography.titleMedium.copyWith(
                      color: isSelected
                          ? const Color(0xFFCDFF00)
                          : Colors.white.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    plan.period,
                    style: AppTypography.labelSmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.35),
                      fontSize: 10,
                    ),
                  ),
                  if (plan.annualEquiv != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      plan.annualEquiv!,
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.25),
                        fontSize: 9,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCtaButton(AppThemeColors L) {
    final plan = _plans[_selectedPlan];

    return GestureDetector(
      onTap: _handlePurchase,
      child: AnimatedContainer(
        duration: 200.ms,
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          gradient: _isLoading
              ? LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.08),
                    Colors.white.withValues(alpha: 0.04),
                  ],
                )
              : const LinearGradient(
                  colors: [Color(0xFFCDFF00), Color(0xFF86FF00)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: _isLoading
              ? null
              : [
                  BoxShadow(
                    color: const Color(0xFFCDFF00).withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Center(
          child: _isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: AppShimmer(
                    width: 22,
                    height: 22,
                    shape: BoxShape.circle,
                  ),
                )
              : Text(
                  'Start ${plan.label} · ${plan.price}',
                  style: AppTypography.labelLarge.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: -0.3,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildLegalSection(AppThemeColors L) {
    return Column(
      children: [
        // Restore purchases
        GestureDetector(
          onTap: _handleRestore,
          child: Text(
            'Restore Purchases',
            style: AppTypography.labelSmall.copyWith(
              color: Colors.white.withValues(alpha: 0.35),
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
              decorationColor: Colors.white.withValues(alpha: 0.2),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Apple Guideline 3.1.1 compliant disclosure
        Text(
          'Subscription auto-renews unless cancelled at least 24 hours before the end of the current period. '
          'Manage or cancel any time in your device\'s App Store / Play Store account settings.',
          style: AppTypography.labelSmall.copyWith(
            color: Colors.white.withValues(alpha: 0.22),
            fontSize: 10,
            height: 1.6,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),

        // Privacy & Terms links
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const _LegalLink(label: 'Privacy Policy', url: 'https://yourapp.com/privacy'),
            Text(
              '  ·  ',
              style: AppTypography.labelSmall.copyWith(
                color: Colors.white.withValues(alpha: 0.2),
                fontSize: 10,
              ),
            ),
            const _LegalLink(label: 'Terms of Use', url: 'https://yourapp.com/terms'),
          ],
        ),
      ],
    );
  }
}

// ── Supporting models ─────────────────────────────────────────

class _PlanOption {
  final String id;
  final String label;
  final String price;
  final String period;
  final String? badge;
  final String? annualEquiv;

  const _PlanOption({
    required this.id,
    required this.label,
    required this.price,
    required this.period,
    this.badge,
    this.annualEquiv,
  });
}

class _Feature {
  final String icon;
  final String label;
  final String sub;

  const _Feature({required this.icon, required this.label, required this.sub});
}

// ── Feature Row ───────────────────────────────────────────────

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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(feature.icon, style: const TextStyle(fontSize: 18)),
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
                const SizedBox(height: 1),
                Text(
                  feature.sub,
                  style: AppTypography.labelSmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle_rounded,
              color: Color(0xFFCDFF00), size: 18),
        ],
      ),
    );
  }
}

// ── Legal link (opens URL) ────────────────────────────────────

class _LegalLink extends StatelessWidget {
  final String label;
  final String url;
  const _LegalLink({required this.label, required this.url});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Launch URL — add url_launcher if needed
        HapticEngine.light();
      },
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: Colors.white.withValues(alpha: 0.3),
          fontSize: 10,
          decoration: TextDecoration.underline,
          decorationColor: Colors.white.withValues(alpha: 0.15),
        ),
      ),
    );
  }
}
