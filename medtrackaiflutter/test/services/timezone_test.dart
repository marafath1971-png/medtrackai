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

  group('the wall-clock semantics of the scheduler', () {
    test('TZDateTime.from re-expresses an instant, it does not keep the hour',
        () {
      // This is why the UTC fallback did not simply shift every alarm by the
      // device offset: the conversion preserves the absolute instant, so an
      // 08:00 dose armed on a UTC+6 device still fired at 08:00 there.
      final ny = tz.getLocation('America/New_York');
      final local = DateTime.utc(2026, 8, 18, 8);
      final converted = tz.TZDateTime.from(local, ny);

      expect(converted.hour, isNot(local.hour),
          reason: 'the wall clock moves when the zone differs');
      expect(converted.toUtc(), local,
          reason: 'the instant is what is preserved');
    });

    test('a matching zone does preserve the wall clock', () {
      // The shipping case once refreshTimeZone resolves correctly.
      final dhaka = tz.getLocation('Asia/Dhaka');
      final wall = tz.TZDateTime(dhaka, 2026, 8, 18, 8);

      expect(wall.hour, 8);
      expect(wall.timeZoneOffset.inHours, 6);
    });

    test('a stale zone is what actually breaks reminders', () {
      // Scheduled notifications are absolute instants derived from tz.local
      // when they were armed. Fly from Dhaka to New York and an 08:00 dose
      // keeps firing on Dhaka's clock — 22:00 the previous evening locally —
      // until the zone is re-resolved and the reminders re-armed.
      final dhaka = tz.getLocation('Asia/Dhaka');
      final ny = tz.getLocation('America/New_York');
      final armedInDhaka = tz.TZDateTime(dhaka, 2026, 8, 18, 8);
      final seenInNy = tz.TZDateTime.from(armedInDhaka, ny);

      expect(seenInNy.hour, isNot(8));
      expect(seenInNy.day, 17);
    });
  });

  group('the zone is re-resolved when the app resumes', () {
    test('the shell refreshes and re-arms on a zone change', () {
      // refreshTimeZone previously ran only from loadFromStorage — a cold
      // start — so an app left resident kept a stale zone indefinitely.
      final src = File('lib/screens/app_shell.dart').readAsStringSync();

      expect(src.contains('_resyncTimeZone'), isTrue);
      expect(src.contains('refreshNotifications'), isTrue,
          reason: 're-resolving the zone is pointless without re-arming');
    });
  });
}
