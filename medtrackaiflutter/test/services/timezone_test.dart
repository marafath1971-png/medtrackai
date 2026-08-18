import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Every medication reminder is scheduled as `tz.TZDateTime.from(date,
/// tz.local)`, so `tz.local` decides what hour the alarm actually fires.
///
/// refreshTimeZone resolved it with `timezoneInfo.toString()`. TimezoneInfo
/// declares no toString override, so that produced the literal string
/// "Instance of 'TimezoneInfo'". tz.getLocation() threw on it, an empty catch
/// swallowed the exception, and tz.local stayed at its UTC default — so every
/// reminder fired offset by the device's whole UTC offset. Six hours early in
/// Dhaka, and silently, because nothing logged the failure.
void main() {
  setUpAll(tzdata.initializeTimeZones);

  group('the plugin value that gets passed to getLocation', () {
    test('toString is not an IANA name', () {
      // The exact call the old code made.
      final info = TimezoneInfo(identifier: 'Asia/Dhaka');

      expect(info.toString(), isNot('Asia/Dhaka'),
          reason: 'if this ever starts matching, the original code was fine '
              'and this test should be revisited');
      expect(() => tz.getLocation(info.toString()), throwsA(anything),
          reason: 'this is the throw the empty catch was hiding');
    });

    test('identifier is', () {
      final info = TimezoneInfo(identifier: 'Asia/Dhaka');

      expect(info.identifier, 'Asia/Dhaka');
      expect(tz.getLocation(info.identifier).name, 'Asia/Dhaka');
    });
  });

  group('a resolved zone changes when the alarm fires', () {
    test('UTC and Dhaka disagree by the offset a user would notice', () {
      // Why the silent fallback mattered: an 08:00 dose in Dhaka scheduled
      // against UTC lands at 14:00 local.
      final dhaka = tz.getLocation('Asia/Dhaka');
      final local = tz.TZDateTime(dhaka, 2026, 8, 18, 8);
      final utc = tz.TZDateTime.utc(2026, 8, 18, 8);

      expect(local.toUtc().hour, isNot(utc.hour));
      expect(local.timeZoneOffset.inHours, 6);
    });
  });

  group('the failure is no longer silent', () {
    late String src;

    setUpAll(() {
      src = File('lib/services/notification_service.dart').readAsStringSync();
    });

    test('the identifier is used, not toString', () {
      expect(src.contains('timezoneInfo.identifier'), isTrue);
      expect(src.contains('timezoneInfo.toString()'), isFalse,
          reason: 'toString yields "Instance of \'TimezoneInfo\'"');
    });

    test('a failed lookup is logged rather than swallowed', () {
      // The original catch body was the comment "// Fallback or ignore".
      // Anchor on the method, not its call site in init().
      final catchIdx = src.indexOf('static Future<void> refreshTimeZone()');
      final tail = src.substring(
          catchIdx, (catchIdx + 1400).clamp(0, src.length));

      expect(tail.contains('appLogger.e'), isTrue,
          reason: 'reminders firing in UTC has to be visible somewhere');
    });

    test('callers can tell whether the zone resolved', () {
      expect(src.contains('timeZoneResolved'), isTrue);
    });
  });
}
