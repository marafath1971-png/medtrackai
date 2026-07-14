import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/app_routes.dart';
import '../../providers/app_state.dart';
import '../../screens/paywall/premium_paywall_overlay.dart';
import '../../services/growth_tracker.dart';
import 'haptic_engine.dart';

/// Starts the manual "add a medicine by hand" flow: creates a blank [Medicine],
/// persists it, and opens the detail screen in edit mode so the user can fill
/// in name / dose / schedule without needing a scan or a network call.
///
/// This is the offline-friendly, privacy-friendly activation path. It respects
/// the free-tier med limit and shows the paywall when the user is over it.
///
/// [source] is passed to analytics so we can compare which entry point
/// (home empty state, scanner hub, voice fallback) drives manual adds.
Future<void> startManualAddMedicine(
  BuildContext context, {
  String source = 'unknown',
}) async {
  HapticEngine.selection();
  final appState = Provider.of<AppState>(context, listen: false);

  // Gate on the free-tier limit, mirroring the scan add-med gates.
  if (!appState.canAddMedicine) {
    PremiumPaywallOverlay.show(context, triggerSource: 'unlimited_meds');
    return;
  }

  final newMed = Medicine(
    id: DateTime.now().millisecondsSinceEpoch,
    name: '',
    brand: '',
    dose: '',
    form: 'Tablet',
    category: 'General',
    notes: '',
    schedule: const [],
    courseStartDate: DateTime.now().toIso8601String().substring(0, 10),
    color: '#10B981',
    count: 0,
    totalCount: 0,
    refillAt: 0,
  );

  await appState.addMedicine(newMed);
  await GrowthTracker.trackManualAddStarted(source: source);

  if (!context.mounted) return;
  context.push(AppRoutes.medicineDetailPath(newMed.id, edit: true));
}
