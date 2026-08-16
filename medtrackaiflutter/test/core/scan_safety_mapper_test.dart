import 'package:flutter_test/flutter_test.dart';
import 'package:medai/core/utils/scan_safety_mapper.dart';
import 'package:medai/domain/entities/entities.dart';

/// This mapper turns free-form AI scan text into the safety profile that gates
/// the pre-take briefing. Dropping a warning here means someone takes a
/// medicine without seeing an interaction the scan actually found.
AISafetyProfile _profile({
  List<String> warnings = const [],
  List<String> interactions = const [],
  List<String> foodRules = const [],
  List<String> ahaMoments = const [],
}) =>
    AISafetyProfile(
      warnings: warnings,
      interactions: interactions,
      foodRules: foodRules,
      ahaMoments: ahaMoments,
    );

BodyImpactSummary _impact(String mechanism) => BodyImpactSummary(
      mechanismOfAction: mechanism,
      onsetMinutes: 30,
      peakHours: 2,
      durationHours: 8,
      bodySystems: const [],
      timelineEffects: const [],
      ahaFacts: const [],
    );

void main() {
  group('splitting AI bullet text', () {
    test('empty text yields no warnings', () {
      final p = safetyProfileFromScan(ScanResult(name: 'X', warnings: ''));
      expect(p.warnings, isEmpty);
    });

    test('a single warning is kept whole', () {
      final p = safetyProfileFromScan(
          ScanResult(name: 'X', warnings: 'May cause drowsiness'));
      expect(p.warnings, ['May cause drowsiness']);
    });

    test('newline-separated warnings split into items', () {
      final p = safetyProfileFromScan(ScanResult(
          name: 'X', warnings: 'Do not drive\nAvoid alcohol\nMay cause nausea'));
      expect(p.warnings,
          ['Do not drive', 'Avoid alcohol', 'May cause nausea']);
    });

    test('semicolons also split', () {
      final p = safetyProfileFromScan(
          ScanResult(name: 'X', warnings: 'Do not drive; Avoid alcohol'));
      expect(p.warnings, ['Do not drive', 'Avoid alcohol']);
    });

    test('bullet and dash markers are stripped', () {
      final p = safetyProfileFromScan(ScanResult(
          name: 'X', warnings: '• Do not drive\n- Avoid alcohol\n* Take with food'));
      expect(p.warnings, ['Do not drive', 'Avoid alcohol', 'Take with food']);
    });

    test('blank lines are dropped rather than becoming empty warnings', () {
      final p = safetyProfileFromScan(
          ScanResult(name: 'X', warnings: 'Do not drive\n\n\nAvoid alcohol'));
      expect(p.warnings, ['Do not drive', 'Avoid alcohol']);
    });

    test('a long comma-separated list splits into items', () {
      final p = safetyProfileFromScan(ScanResult(
          name: 'X',
          warnings:
              'May cause drowsiness, Avoid operating machinery, Do not mix with alcohol'));
      expect(p.warnings.length, 3);
      expect(p.warnings.first, 'May cause drowsiness');
    });

    test('a short fragment in a comma list is not silently dropped', () {
      // The comma branch filtered out fragments of <=3 chars, which discards
      // real dietary interactions like "tea" from a warning the scan found.
      final p = safetyProfileFromScan(ScanResult(
          name: 'X',
          warnings:
              'Avoid grapefruit juice and dairy products, tea, and antacid medication'));
      expect(p.warnings.join(' '), contains('tea'),
          reason: 'no part of a safety warning may be discarded');
    });

    test('a short phrase containing a comma is NOT split', () {
      // The comma heuristic only applies past 40 chars, so ordinary prose
      // stays intact.
      final p = safetyProfileFromScan(
          ScanResult(name: 'X', warnings: 'Take with food, daily'));
      expect(p.warnings, ['Take with food, daily']);
    });
  });

  group('food rules', () {
    test('withFood adds an explicit instruction', () {
      final p =
          safetyProfileFromScan(ScanResult(name: 'X', withFood: true));
      expect(p.foodRules, contains('Take with food'));
    });

    test('timing and how-to-take are carried through', () {
      final p = safetyProfileFromScan(ScanResult(
          name: 'X', whenToTake: 'Morning', howToTake: 'Swallow whole'));
      expect(p.foodRules, contains('When: Morning'));
      expect(p.foodRules, contains('Swallow whole'));
    });

    test('nothing scanned means no food rules', () {
      expect(safetyProfileFromScan(ScanResult(name: 'X')).foodRules, isEmpty);
    });
  });

  group('mechanism of action fallback', () {
    test('body impact wins when present', () {
      final p = safetyProfileFromScan(ScanResult(
        name: 'X',
        description: 'A description',
        bodyImpact: _impact('Blocks enzyme Y'),
      ));
      expect(p.mechanismOfAction, 'Blocks enzyme Y');
    });

    test('falls back to the description', () {
      final p = safetyProfileFromScan(
          ScanResult(name: 'X', description: 'A description'));
      expect(p.mechanismOfAction, 'A description');
    });

    test('falls back to placeholder copy rather than an empty string', () {
      final p = safetyProfileFromScan(ScanResult(name: 'X'));
      expect(p.mechanismOfAction, isNotEmpty);
    });
  });

  group('aha moments', () {
    test('the scan aha moment leads, followed by side effects', () {
      final p = safetyProfileFromScan(ScanResult(
        name: 'X',
        ahaMoment: 'Works within 30 minutes',
        sideEffects: 'Nausea\nDizziness\nDry mouth\nHeadache',
      ));
      expect(p.ahaMoments.first, 'Works within 30 minutes');
      expect(p.ahaMoments.length, 4, reason: 'aha plus at most three effects');
    });

    test('a blank aha moment is not emitted as an empty entry', () {
      final p = safetyProfileFromScan(
          ScanResult(name: 'X', ahaMoment: '   ', sideEffects: 'Nausea'));
      expect(p.ahaMoments, ['Nausea']);
    });
  });

  group('MedicineKnowSafety', () {
    Medicine med({AISafetyProfile? profile, String intake = ''}) => Medicine(
          id: 1,
          name: 'X',
          courseStartDate: '2026-08-16T09:00:00.000',
          intakeInstructions: intake,
          aiSafetyProfile: profile,
        );

    test('no profile and no instructions needs no briefing', () {
      expect(med().needsPreTakeBriefing, isFalse);
      expect(med().hasCriticalSafetyAlerts, isFalse);
    });

    test('"None" instructions do not trigger a briefing', () {
      expect(med(intake: 'None').needsPreTakeBriefing, isFalse);
    });

    test('real instructions trigger a briefing when no profile exists', () {
      expect(med(intake: 'Take with water').needsPreTakeBriefing, isTrue);
    });

    test('warnings are critical', () {
      final m = med(
          profile: _profile(warnings: ['Do not drive']));
      expect(m.hasCriticalSafetyAlerts, isTrue);
      expect(m.needsPreTakeBriefing, isTrue);
    });

    test('interactions are critical', () {
      final m = med(
          profile: _profile(interactions: ['Avoid warfarin']));
      expect(m.hasCriticalSafetyAlerts, isTrue);
    });

    test('food rules alone brief but are not critical', () {
      final m =
          med(profile: _profile(foodRules: ['Take with food']));
      expect(m.hasCriticalSafetyAlerts, isFalse);
      expect(m.needsPreTakeBriefing, isTrue);
    });

    test('an empty profile needs no briefing', () {
      expect(med(profile: _profile()).needsPreTakeBriefing, isFalse);
    });
  });
}
