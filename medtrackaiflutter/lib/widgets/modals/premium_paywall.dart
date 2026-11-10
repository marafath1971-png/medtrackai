import 'package:flutter/material.dart';
import '../../screens/paywall/premium_paywall_overlay.dart';

export '../../screens/paywall/premium_paywall_overlay.dart';

/// Convenience wrapper for displaying the Med AI Pro paywall modal.
class PremiumPaywallModal {
  static Future<void> show(
    BuildContext context, {
    String triggerSource = 'generic',
    PaywallVariant variant = PaywallVariant.featureGate,
    VoidCallback? onSuccess,
    String? personalizedHeadline,
  }) {
    return PremiumPaywallOverlay.show(
      context,
      triggerSource: triggerSource,
      variant: variant,
      onSuccess: onSuccess,
      personalizedHeadline: personalizedHeadline,
    );
  }
}
