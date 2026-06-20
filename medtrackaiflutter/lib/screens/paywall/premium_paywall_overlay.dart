import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../core/utils/haptic_engine.dart';
import '../../widgets/common/app_shimmer.dart';
import '../../models/constants.dart';
import '../../services/growth_tracker.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../services/purchases_service.dart';
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
  int _selectedPlan = 0;
  bool _isLoading = false;
  bool _isLoadingPackages = true;
  List<Package> _packages = [];
  String? _errorMsg;
  bool _purchaseSuccess = false;

  @override
  void initState() {
    super.initState();
    GrowthTracker.trackPaywall('view');
    _loadPackages();
  }

  Future<void> _loadPackages() async {
    final packages = await PurchasesService.getAvailablePackages();
    if (mounted) {
      setState(() {
        _packages = packages;
        _isLoadingPackages = false;
        
        // Default to monthly or annual if available
        final initial = _packages.indexWhere((p) => 
            p.packageType == PackageType.monthly || 
            p.packageType == PackageType.annual);
        _selectedPlan = initial != -1 ? initial : 0;
      });
    }
  }

  @override
  void dispose() {
    if (!_purchaseSuccess) {
      GrowthTracker.trackPaywall('close');
    }
    super.dispose();
  }

  // Features
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

  Future<void> _handleRestore() async {
    HapticEngine.light();
    setState(() => _isLoading = true);
    final state = Provider.of<AppState>(context, listen: false);
    await state.restorePurchases();
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
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 0.5,
            ),
          ),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
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
      'voice_limit': '🎙️ You\'ve used your 3 free AI voice logs today.\nUpgrade for unlimited voice logging.',
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
    if (_isLoadingPackages) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: AppShimmer(width: double.infinity, height: 100, radius: 16),
        ),
      );
    }

    if (_packages.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          'Subscription plans are currently unavailable.',
          style: AppTypography.labelSmall.copyWith(color: Colors.white.withValues(alpha: 0.5)),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Row(
      children: _packages.asMap().entries.map((e) {
        final i = e.key;
        final package = e.value;
        final isSelected = i == _selectedPlan;
        
        final isPopular = package.packageType == PackageType.monthly;
        final isBestValue = package.packageType == PackageType.annual || package.packageType == PackageType.lifetime;
        final badge = isBestValue ? 'BEST VALUE' : (isPopular ? 'POPULAR' : null);

        // Derive period text
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
          child: GestureDetector(
            onTap: () {
              HapticEngine.selection();
              setState(() => _selectedPlan = i);
            },
            child: AnimatedContainer(
              duration: 250.ms,
              curve: Curves.easeOutCubic,
              margin: EdgeInsets.only(left: i == 0 ? 0 : 8),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
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
                  if (badge != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFCDFF00)
                            : Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        badge,
                        style: AppTypography.labelSmall.copyWith(
                          color: isSelected ? Colors.black : Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
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
                            ? const Color(0xFFCDFF00)
                            : Colors.white.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w900,
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
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCtaButton(AppThemeColors L) {
    if (_isLoadingPackages) {
      return const AppShimmer(width: double.infinity, height: 60, radius: 18);
    }
    
    final hasPackages = _packages.isNotEmpty;
    final buttonText = hasPackages 
        ? 'Start ${_packages[_selectedPlan].storeProduct.title.split(' ').first} · ${_packages[_selectedPlan].storeProduct.priceString}'
        : 'Unavailable';

    return GestureDetector(
      onTap: hasPackages ? _handlePurchase : null,
      child: AnimatedContainer(
        duration: 200.ms,
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          gradient: _isLoading || !hasPackages
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
          boxShadow: _isLoading || !hasPackages
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
                  buttonText,
                  style: AppTypography.labelLarge.copyWith(
                    color: !hasPackages ? Colors.white.withValues(alpha: 0.5) : Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: -0.3,
                  ),
                ),
        ),
      ).animate(onPlay: (c) => c.repeat())
       .shimmer(duration: 2500.ms, color: Colors.white.withValues(alpha: 0.5), blendMode: BlendMode.srcOver),
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
            const _LegalLink(label: 'Privacy Policy', url: kPrivacyPolicyUrl),
            Text(
              '  ·  ',
              style: AppTypography.labelSmall.copyWith(
                color: Colors.white.withValues(alpha: 0.2),
                fontSize: 10,
              ),
            ),
            const _LegalLink(label: 'Terms of Use', url: kTermsOfServiceUrl),
          ],
        ),
      ],
    );
  }
}

// ── Supporting models ─────────────────────────────────────────

// ── Supporting models ─────────────────────────────────────────

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
