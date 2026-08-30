import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Caregiver alerting is server-side, and it matters that it stays that way.
///
/// `detectMissedDoses` runs hourly in Cloud Functions, scans monitored users
/// and pushes to each caregiver's FCM token. That works when the patient's
/// phone is asleep, offline, or the app has been force-stopped — none of which
/// a locally scheduled notification survives.
///
/// NotificationService.scheduleCaregiverEscalation looks like a second path but
/// is dead code, and its body tells the patient "an alert has been escalated to
/// your caregiver network" while contacting nobody. Documented rather than
/// deleted, because the channel it declares is registered.
void main() {
  group('the server owns caregiver alerting', () {
    late String functions;

    setUpAll(() {
      functions = File('../functions/index.js').existsSync()
          ? File('../functions/index.js').readAsStringSync()
          : File('functions/index.js').existsSync()
              ? File('functions/index.js').readAsStringSync()
              : '';
    });

    test('a scheduled sweep exists', () {
      if (functions.isEmpty) {
        markTestSkipped('functions/index.js not reachable from this checkout');
        return;
      }

      expect(functions.contains('detectMissedDoses'), isTrue);
      expect(functions.contains("onSchedule('every 60 minutes'"), isTrue,
          reason: 'escalation cannot depend on the patient opening the app');
    });

    test('it pushes to the caregiver token, not the patient', () {
      if (functions.isEmpty) {
        markTestSkipped('functions/index.js not reachable');
        return;
      }

      expect(functions.contains('fcmToken'), isTrue);
    });
  });

  group('the local escalation stays unused', () {
    test('nothing calls scheduleCaregiverEscalation', () {
      final offenders = <String>[];

      void walk(Directory dir) {
        for (final e in dir.listSync()) {
          if (e is Directory) {
            walk(e);
          } else if (e is File && e.path.endsWith('.dart')) {
            if (e.path.endsWith('notification_service.dart')) continue;
            if (e.readAsStringSync().contains('scheduleCaregiverEscalation')) {
              offenders.add(e.path);
            }
          }
        }
      }

      walk(Directory('lib'));

      expect(offenders, isEmpty,
          reason: 'a local notification cannot reach a caregiver, and this one '
              'claims it did: ${offenders.join(", ")}');
    });

    test('it is marked unused at the declaration', () {
      final src = File('lib/services/notification_service.dart').readAsStringSync();
      final idx = src.indexOf('static Future<void> scheduleCaregiverEscalation');
      expect(idx, greaterThan(-1));

      final doc = src.substring((idx - 900).clamp(0, src.length), idx);
      expect(doc.contains('Unused'), isTrue,
          reason: 'the next reader should not wire this up by mistake');
    });
  });
}
