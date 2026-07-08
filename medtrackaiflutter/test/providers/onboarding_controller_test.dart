import 'package:flutter_test/flutter_test.dart';
import 'package:medai/screens/onboarding/onboarding_controller.dart';

/// Tests for the onboarding answer store and its derivations — the values
/// that personalize the plan reveal and paywall (blueprint §6).
void main() {
  group('answer storage', () {
    test('single-select stores and replaces', () {
      final c = OnboardingController();
      c.selectSingle('goal', 'never_miss');
      expect(c.single('goal'), 'never_miss');
      c.selectSingle('goal', 'family');
      expect(c.single('goal'), 'family');
      expect(c.hasAnswer('goal', multiSelect: false), isTrue);
      expect(c.hasAnswer('missing', multiSelect: false), isFalse);
    });

    test('multi-select toggles membership', () {
      final c = OnboardingController();
      c.toggleMulti('conditions', 'diabetes');
      c.toggleMulti('conditions', 'heart');
      expect(c.multi('conditions'), {'diabetes', 'heart'});
      c.toggleMulti('conditions', 'diabetes');
      expect(c.multi('conditions'), {'heart'});
      expect(c.isSelected('conditions', 'heart', multiSelect: true), isTrue);
    });

    test('numbers store big-input values (birth year, weight, sleep)', () {
      final c = OnboardingController();
      c.setNumber('birth_year', 1993);
      c.setNumber('weight_kg', 70.5);
      expect(c.number('birth_year'), 1993);
      expect(c.number('weight_kg'), 70.5);
      expect(c.number('missing'), isNull);
    });
  });

  group('toPrefs derivations', () {
    test('med_count buckets map to stored ranges', () {
      final c = OnboardingController();
      c.selectSingle('med_count', 'three_five');
      expect(c.toPrefs().medCount, '3-5');
      c.selectSingle('med_count', 'ten_plus');
      expect(c.toPrefs().medCount, '6+');
    });

    test('caregiver personas derive caregiver role', () {
      final c = OnboardingController();
      c.selectSingle('persona', 'caregiver');
      expect(c.toPrefs().role, 'caregiver');

      final c2 = OnboardingController();
      c2.selectSingle('persona', 'family_leader');
      expect(c2.toPrefs().role, 'caregiver');

      final c3 = OnboardingController();
      c3.selectSingle('persona', 'self_manager');
      expect(c3.toPrefs().role, 'self');
    });

    test('unanswered funnel still produces safe defaults', () {
      final prefs = OnboardingController().toPrefs();
      expect(prefs.medCount, '1-2');
      expect(prefs.role, 'self');
      expect(prefs.schedule, 'morning');
      expect(prefs.reminderIntensity, 'normal');
    });
  });

  group('projection maths (paywall inputs)', () {
    test('inferredAdherence tracks miss frequency and stays in 0..1', () {
      final c = OnboardingController();
      expect(c.inferredAdherence, inInclusiveRange(0.0, 1.0));
      c.selectSingle('miss_frequency', 'often');
      final often = c.inferredAdherence;
      c.selectSingle('miss_frequency', 'never');
      final never = c.inferredAdherence;
      expect(often, lessThan(never));
      expect(c.projectedAdherence, greaterThan(never));
    });

    test('adherenceScore is clamped to 28..88 at the extremes', () {
      final worst = OnboardingController()
        ..selectSingle('miss_frequency', 'often')
        ..selectSingle('interaction_known', 'no')
        ..selectSingle('challenge', 'forgetting')
        ..selectSingle('supplements', 'many')
        ..selectSingle('timing', 'multiple');
      expect(worst.adherenceScore, inInclusiveRange(28, 88));

      final best = OnboardingController()
        ..selectSingle('miss_frequency', 'never')
        ..selectSingle('interaction_known', 'yes');
      expect(best.adherenceScore, inInclusiveRange(28, 88));
      expect(best.adherenceScore, greaterThan(worst.adherenceScore));
    });
  });
}
