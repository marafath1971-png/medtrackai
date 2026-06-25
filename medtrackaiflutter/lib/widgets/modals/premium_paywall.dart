import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';

import '../../core/utils/haptic_engine.dart';
import '../../widgets/common/app_loading_indicator.dart';
import '../../widgets/common/refined_sheet_wrapper.dart';
import '../../services/purchases_service.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class PremiumPaywall extends StatefulWidget {
  const PremiumPaywall({super.key});

  @override
  State<PremiumPaywall> createState() => _PremiumPaywallState();
}

class _PremiumPaywallState extends State<PremiumPaywall> {
  bool _isProcessing = false;
  bool _isLoadingPackages = true;
  List<Package> _packages = [];
  Package? _selectedPackage;

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  Future<void> _loadPackages() async {
    final packages = await PurchasesService.getAvailablePackages();
    if (mounted) {
      setState(() {
        _packages = packages;
        if (_packages.isNotEmpty) {
          _selectedPackage = _packages.first;
        }
        _isLoadingPackages = false;
      });
    }
  }

  Future<void> _handleUnlock(AppState state) async {
    setState(() => _isProcessing = true);
    
    bool success = false;
    if (_selectedPackage != null) {
      success = await PurchasesService.purchasePackage(_selectedPackage!.identifier);
    } else {
      // Mock unlock if no packages (fallback mode)
      await Future.delayed(const Duration(seconds: 2));
      success = true;
    }

    if (!mounted) return;
    
    if (success) {
      await state.unlockPremium();
      if (!mounted) return;
      Navigator.pop(context);
    } else {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final state = Provider.of<AppState>(context, listen: false);

    return RefinedSheetWrapper(
      scrollable: true,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          // Icon/Celebration
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: L.green.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text('💎',
                  style: AppTypography.displayLarge.copyWith(fontSize: 40)),
            ),
          )
              .animate(onPlay: (c) => c.repeat())
              .shimmer(
                  duration: 2.seconds, color: L.green.withValues(alpha: 0.3))
              .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.1, 1.1),
                  duration: 1.seconds,
                  curve: Curves.easeInOut),

          const SizedBox(height: 24),

          // Marketing Text
          Text(
            "World's #1 Advanced AI Medication App",
            textAlign: TextAlign.center,
            style: AppTypography.headlineLarge.copyWith(
              color: L.text,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0),

          const SizedBox(height: 12),

          Text(
            "Never miss a course again. Your healthy life, boosted with precision AI.",
            textAlign: TextAlign.center,
            style: AppTypography.bodyLarge.copyWith(
              color: L.sub,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          )
              .animate()
              .fadeIn(delay: 200.ms, duration: 600.ms)
              .slideY(begin: 0.2, end: 0),

          const SizedBox(height: 40),

          // Benefits List
          _buildBenefit(
              Icons.auto_awesome_rounded, "Advanced AI Label Scanning", L),
          _buildBenefit(Icons.notifications_active_rounded,
              "Unlimited Smart Reminders", L),
          _buildBenefit(
              Icons.family_restroom_rounded, "Full Caregiver Monitoring", L),
          _buildBenefit(
              Icons.cloud_done_rounded, "Global Cloud Sync & Security", L),

          const SizedBox(height: 48),

          // Auth Buttons
          if (!AuthService.isLoggedIn) ...[
            _buildAuthBtn(
              "Continue with Apple",
              null,
              AuthService.signInWithApple,
              L.card,
              L.text,
              icon: Icons.apple_rounded,
            ),
            const SizedBox(height: 12),
            _buildAuthBtn(
              "Continue with Google",
              "assets/images/google_logo.png",
              AuthService.signInWithGoogle,
              L.card,
              L.text,
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                "OR",
                style: AppTypography.labelSmall.copyWith(
                    color: L.sub.withValues(alpha: 0.3),
                    fontWeight: FontWeight.w700,
                    fontSize: 12),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Packages list
          if (_isLoadingPackages)
            const AppLoadingIndicator(size: 24)
          else if (_packages.isNotEmpty)
            ..._packages.map((pkg) => _buildPackageCard(pkg, L))
          else
            // Fallback mock package
            _buildMockPackageCard(L),

          const SizedBox(height: 24),

          // Main Unlock Button
          GestureDetector(
            onTap: _isProcessing
                ? null
                : () {
                    HapticEngine.success();
                    _handleUnlock(state);
                  },
            child: Container(
              width: double.infinity,
              height: 64,
              decoration: BoxDecoration(
                color: L.text,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: L.border.withValues(alpha: 0.1)),
              ),
              child: Center(
                child: _isProcessing
                    ? const AppLoadingIndicator(size: 24)
                    : Text(
                        "Unlock Full Access",
                        style: AppTypography.titleLarge.copyWith(
                          color: L.bg,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: false))
             .shimmer(duration: 2500.ms, delay: 1000.ms, color: Colors.white54),
          )
              .animate()
              .scale(delay: 800.ms, duration: 400.ms, curve: Curves.elasticOut),

          const SizedBox(height: 16),
          Text(
            "Start today and feel the smoothing difference.",
            style: AppTypography.bodySmall.copyWith(
              color: L.sub.withValues(alpha: 0.5),
              fontSize: 13,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefit(IconData icon, String text, AppThemeColors L) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: L.card.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: L.border.withValues(alpha: 0.1)),
            ),
            child: Icon(icon, size: 18, color: L.text),
          ),
          const SizedBox(width: 16),
          Text(
            text,
            style: AppTypography.bodyMedium.copyWith(
              color: L.text,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthBtn(
    String label,
    String? asset,
    Future<dynamic> Function() onTap,
    Color bg,
    Color text, {
    IconData? icon,
  }) {
    final L = context.L;
    return GestureDetector(
      onTap: () async {
        HapticEngine.selection();
        try {
          await onTap();
          if (mounted) Navigator.pop(context);
        } catch (e) {
          debugPrint("Auth Error: $e");
        }
      },
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: L.card.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: L.border.withValues(alpha: 0.1)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (asset != null)
              Image.asset(asset,
                  width: 20,
                  height: 20,
                  errorBuilder: (c, e, s) => const Icon(Icons.login, size: 20))
            else if (icon != null)
              Icon(icon, size: 22, color: text),
            const SizedBox(width: 12),
            Text(
              label,
              style: AppTypography.labelLarge.copyWith(
                color: text,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPackageCard(Package pkg, AppThemeColors L) {
    final isSelected = _selectedPackage?.identifier == pkg.identifier;
    return GestureDetector(
      onTap: () {
        HapticEngine.selection();
        setState(() => _selectedPackage = pkg);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? L.primary.withValues(alpha: 0.1) : L.card.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? L.primary : L.border.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pkg.storeProduct.title.split(' (').first,
                  style: AppTypography.titleMedium.copyWith(
                    color: L.text,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  pkg.storeProduct.description,
                  style: AppTypography.bodySmall.copyWith(
                    color: L.sub,
                  ),
                ),
              ],
            ),
            Text(
              pkg.storeProduct.priceString,
              style: AppTypography.titleLarge.copyWith(
                color: L.text,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMockPackageCard(AppThemeColors L) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: L.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: L.primary, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Lifetime Access",
                style: AppTypography.titleMedium.copyWith(
                  color: L.text,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Unlock all premium features forever",
                style: AppTypography.bodySmall.copyWith(
                  color: L.sub,
                ),
              ),
            ],
          ),
          Text(
            "Free",
            style: AppTypography.titleLarge.copyWith(
              color: L.text,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
