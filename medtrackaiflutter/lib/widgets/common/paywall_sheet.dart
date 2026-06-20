import 'package:flutter/material.dart';
import '../../screens/paywall/premium_paywall_overlay.dart';

class PaywallSheet extends StatelessWidget {
  const PaywallSheet({super.key});

  static Future<void> show(BuildContext context) async {
    await PremiumPaywallOverlay.show(context, triggerSource: 'generic_paywall');
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
