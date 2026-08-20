import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// A medicine added from a scan never armed a reminder.
///
/// AppState.addMedicine is what calls _rescheduleNotifications(). The scan
/// result screen called `context.read<MedicationController>().addMedicine(...)`
/// instead, which persists the medicine and its schedule but skips scheduling
/// entirely. The manual-add path went through AppState, so the app reminded
/// users about medicines they typed in and silently forgot the ones they
/// scanned — the flow the whole product is built around.
///
/// Found on a device: the medicine was in the Firestore cache with its Morning
/// schedule intact, and `dumpsys alarm` showed zero alarms for the app.
void main() {
  group('every add path schedules', () {
    test('no screen adds a medicine through the controller directly', () {
      final offenders = <String>[];

      void walk(Directory dir) {
        for (final e in dir.listSync()) {
          if (e is Directory) {
            walk(e);
          } else if (e is File && e.path.endsWith('.dart')) {
            final src = e.readAsStringSync();
            for (final line in src.split('\n')) {
              final t = line.trimLeft();
              if (t.startsWith('//') || t.startsWith('///')) continue;
              if (RegExp(r'MedicationController>\(\)\s*\.addMedicine')
                  .hasMatch(line)) {
                offenders.add(e.path);
              }
            }
          }
        }
      }

      walk(Directory('lib/screens'));
      walk(Directory('lib/widgets'));

      expect(offenders, isEmpty,
          reason: 'these bypass AppState.addMedicine and so never arm a '
              'reminder: ${offenders.join(", ")}');
    });

    test('AppState.addMedicine still reschedules', () {
      // The guard above is only meaningful while this remains true.
      final src = File('lib/providers/app_state.dart').readAsStringSync();
      final idx = src.indexOf('Future<void> addMedicine(');
      expect(idx, greaterThan(-1));

      final body = src.substring(idx, (idx + 500).clamp(0, src.length));
      expect(body.contains('_rescheduleNotifications()'), isTrue,
          reason: 'adding a medicine has to arm its reminders');
    });
  });

  group('snooze actually re-arms', () {
    test('snoozeDose schedules rather than only logging', () {
      // It logged a line, buzzed, and returned — so any caller would have
      // shown a "snoozed" confirmation for a reminder that never came back.
      // Nothing in the UI reaches it today (the notification action handler
      // schedules its own one-off), but a method that looks like it works is
      // a trap for the next caller.
      final src = File('lib/providers/controllers/medication_controller.dart')
          .readAsStringSync();
      final idx = src.indexOf('Future<void> snoozeDose(');
      expect(idx, greaterThan(-1));

      final body = src.substring(idx, (idx + 700).clamp(0, src.length));
      expect(body.contains('scheduleOneOffReminder'), isTrue,
          reason: 'snoozing has to schedule something');
    });

    test('it uses the minutes it was given', () {
      final src = File('lib/providers/controllers/medication_controller.dart')
          .readAsStringSync();
      final idx = src.indexOf('Future<void> snoozeDose(');
      final body = src.substring(idx, (idx + 700).clamp(0, src.length));

      expect(body.contains('Duration(minutes: minutes)'), isTrue,
          reason: 'a hardcoded delay would ignore the caller');
    });
  });
}
