import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:medai/domain/entities/entities.dart';
import 'package:medai/services/notification_service.dart';

/// Two Settings switches moved, persisted, restored on relaunch — and changed
/// nothing about the app's behaviour.
///
/// **Dose Reminders.** The toggle saved `notifPerm` but never re-armed, and
/// `_rescheduleNotifications` returned early on `!notifPerm` *before* reaching
/// its `cancelAll()`. So switching reminders off stored the preference and left
/// every previously scheduled notification firing. Uninstalling was the only
/// way to stop them.
///
/// **Refill Alerts.** `notifRefill` was written to storage and read back on
/// load, but nothing ever consulted it: both `showRefillAlert` call sites in
/// MedicationController fired unconditionally. The switch was decorative.
void main() {
  setUp(() {
    NotificationService.refillAlertsEnabled = true;
  });

  tearDown(() {
    NotificationService.refillAlertsEnabled = true;
  });

  group('refill alerts respect the preference', () {
    test('the service exposes a gate at all', () {
      // The bug was the absence of this: nothing downstream of the toggle
      // could see the user's choice.
      expect(NotificationService.refillAlertsEnabled, isTrue);

      NotificationService.refillAlertsEnabled = false;
      expect(NotificationService.refillAlertsEnabled, isFalse);
    });

    test('a disabled gate short-circuits before any platform call', () async {
      // showRefillAlert would otherwise hit the plugin, which is unavailable
      // in tests — completing without throwing proves the early return runs.
      NotificationService.refillAlertsEnabled = false;

      await expectLater(
        NotificationService.showRefillAlert(
          med: Medicine(
            id: 1,
            name: 'Metformin',
            category: 'General',
            courseStartDate: '2026-08-18',
            schedule: const [],
          ),
        ),
        completes,
      );
    });
  });

  group('the profile drives the gate', () {
    test('notifRefill defaults to on for a new profile', () {
      // A user who never opens Settings must still get low-stock warnings.
      final p = UserProfile(name: 'Test');

      expect(p.notifRefill, isTrue);
    });

    test('copyWith carries the preference', () {
      final off = UserProfile(name: 'Test').copyWith(notifRefill: false);

      expect(off.notifRefill, isFalse);
    });

    test('it survives a serialisation round trip', () {
      // The toggle persisted correctly all along — the value simply had no
      // consumer, so a round-trip test alone would never have caught this.
      final off = UserProfile(name: 'Test').copyWith(notifRefill: false);
      final back = UserProfile.fromJson(off.toJson());

      expect(back.notifRefill, isFalse);
    });
  });

  group('turning reminders off cancels them', () {
    test('the disabled branch cancels instead of returning early', () {
      // The early return sat *above* cancelAll(), so the defect is only
      // visible as ordering in the source.
      final src = File('lib/providers/app_state.dart').readAsStringSync();

      final branch = src.indexOf('if (!profile!.notifPerm)');
      expect(branch, greaterThan(-1),
          reason: 'the notifPerm branch should still exist');

      final cancel =
          src.indexOf('await NotificationService.cancelAll();', branch);
      expect(cancel, greaterThan(branch));
      expect(cancel - branch, lessThan(400),
          reason: 'the disabled branch must cancel notifications rather than '
              'returning and leaving every scheduled reminder armed');
    });
  });
}
