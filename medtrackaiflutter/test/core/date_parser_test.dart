import 'package:flutter_test/flutter_test.dart';
import 'package:medai/core/utils/date_parser.dart';
import 'package:medai/domain/entities/user_profile.dart';
import 'package:medai/domain/entities/symptom.dart';
import 'package:medai/domain/entities/managed_profile.dart';

class MockTimestamp {
  final DateTime _dateTime;
  MockTimestamp(this._dateTime);
  DateTime toDate() => _dateTime;
}

void main() {
  group('tryParseDateTime Utility', () {
    test('parses ISO-8601 strings', () {
      final dt = tryParseDateTime('2026-09-26T12:00:00.000Z');
      expect(dt, isNotNull);
      expect(dt!.year, equals(2026));
      expect(dt.month, equals(9));
      expect(dt.day, equals(26));
    });

    test('returns null on invalid string without throwing', () {
      expect(tryParseDateTime('not-a-date'), isNull);
      expect(tryParseDateTime(''), isNull);
      expect(tryParseDateTime('   '), isNull);
    });

    test('returns null on null without throwing', () {
      expect(tryParseDateTime(null), isNull);
    });

    test('parses milliseconds epoch integers', () {
      final now = DateTime.now();
      final dt = tryParseDateTime(now.millisecondsSinceEpoch);
      expect(dt, isNotNull);
      expect(dt!.millisecondsSinceEpoch, equals(now.millisecondsSinceEpoch));
    });

    test('supports duck-typed Firestore Timestamp with toDate()', () {
      final expected = DateTime(2026, 5, 20, 15, 30);
      final fakeTimestamp = MockTimestamp(expected);
      final dt = tryParseDateTime(fakeTimestamp);
      expect(dt, equals(expected));
    });
  });

  group('Entity resilient deserialization against Firestore data variations',
      () {
    test('UserProfile.fromJson handles Timestamp and null dates safely', () {
      final mockCreated = MockTimestamp(DateTime(2026, 1, 1));
      final json = {
        'name': 'Test User',
        'age': '30',
        'gender': 'Male',
        'goal': 'never_miss',
        'targetUser': 'Myself',
        'createdAt': mockCreated,
        'lastReviewPromptedAt': '2026-06-01T10:00:00Z',
        'lastNudgeAt': null,
      };

      final profile = UserProfile.fromJson(json);
      expect(profile.createdAt.year, equals(2026));
      expect(profile.lastReviewPromptedAt, isNotNull);
      expect(profile.lastNudgeAt, isNull);
    });

    test('Symptom.fromJson handles Timestamp and null gracefully', () {
      final mockTime = MockTimestamp(DateTime(2026, 8, 15));
      final json = {
        'id': 'sym_1',
        'name': 'Headache',
        'severity': 3,
        'timestamp': mockTime,
      };

      final symptom = Symptom.fromJson(json);
      expect(symptom.name, equals('Headache'));
      expect(symptom.timestamp.year, equals(2026));
    });

    test('ManagedProfile.fromJson handles Timestamp dateOfBirth safely', () {
      final mockDob = MockTimestamp(DateTime(1995, 4, 12));
      final json = {
        'id': 'm1',
        'name': 'Alex',
        'dateOfBirth': mockDob,
      };

      final member = ManagedProfile.fromJson(json);
      expect(member.name, equals('Alex'));
      expect(member.dateOfBirth?.year, equals(1995));
    });
  });
}
