import 'package:flutter_test/flutter_test.dart';
import 'package:medai/domain/entities/allergy.dart';
import 'package:medai/domain/entities/user_profile.dart';

/// Allergy strings are interpolated into the scanner's safety prompt ("the user
/// has the following known allergies: …") and cross-referenced against a
/// product's ingredients, so the stored representation is safety-relevant.
///
/// Two defects motivated [normalizeAllergies]:
///  * onboarding persisted raw option ids, so the model saw `nsaids` rather
///    than `NSAIDs (Ibuprofen)`;
///  * "None that I know of" was stored as the literal `none`, which reached the
///    prompt as a known allergy named "none".
void main() {
  group('normalizeAllergies', () {
    test('maps legacy option ids to display labels', () {
      expect(
        normalizeAllergies(['penicillin', 'sulfa', 'nsaids', 'aspirin']),
        ['Penicillin', 'Sulfa drugs', 'NSAIDs (Ibuprofen)', 'Aspirin'],
      );
    });

    test('regression: the "none" sentinel never survives', () {
      // This is the one that mattered: "none" reaching the prompt told the AI
      // the user was allergic to a substance called "none".
      expect(normalizeAllergies(['none']), isEmpty);
      expect(normalizeAllergies(['None']), isEmpty);
      expect(normalizeAllergies(['none_known']), isEmpty);
      expect(normalizeAllergies(['penicillin', 'none']), ['Penicillin']);
    });

    test('keeps free-text entries the presets do not cover', () {
      expect(
        normalizeAllergies(['Codeine', 'Latex']),
        ['Codeine', 'Latex'],
      );
    });

    test('preserves a mix of presets and free text, in order', () {
      expect(
        normalizeAllergies(['sulfa', 'Codeine', 'aspirin']),
        ['Sulfa drugs', 'Codeine', 'Aspirin'],
      );
    });

    test('trims whitespace and drops blanks', () {
      expect(
        normalizeAllergies(['  Codeine  ', '', '   ', '\n']),
        ['Codeine'],
      );
    });

    test('removes case-insensitive duplicates, keeping first occurrence', () {
      expect(
        normalizeAllergies(['Codeine', 'codeine', 'CODEINE']),
        ['Codeine'],
      );
    });

    test('a preset id and its label do not both survive', () {
      // Onboarding stores the id; the editor stores the label. A profile
      // touched by both must not list the allergy twice.
      expect(normalizeAllergies(['penicillin', 'Penicillin']), ['Penicillin']);
    });

    test('caps overlong free text', () {
      final long = 'a' * 200;
      final result = normalizeAllergies([long]);

      expect(result.single.length, lessThanOrEqualTo(kMaxAllergyLength));
    });

    test('caps the total number of entries', () {
      final many = List.generate(50, (i) => 'Allergy $i');

      expect(normalizeAllergies(many).length, kMaxAllergyCount);
    });

    test('an empty list stays empty', () {
      expect(normalizeAllergies(const []), isEmpty);
    });
  });

  group('UserProfile.fromJson migration', () {
    test('repairs a legacy profile written with ids and "none"', () {
      final profile = UserProfile.fromJson({
        'name': 'Test',
        'allergies': ['penicillin', 'nsaids', 'none'],
      });

      expect(profile.allergies, ['Penicillin', 'NSAIDs (Ibuprofen)']);
    });

    test('a profile whose only answer was "none" ends up with no allergies',
        () {
      final profile = UserProfile.fromJson({
        'name': 'Test',
        'allergies': ['none'],
      });

      expect(profile.allergies, isEmpty,
          reason: 'no allergies must mean an empty list, not ["none"]');
    });

    test('leaves an already-correct profile untouched', () {
      final profile = UserProfile.fromJson({
        'name': 'Test',
        'allergies': ['Penicillin', 'Codeine'],
      });

      expect(profile.allergies, ['Penicillin', 'Codeine']);
    });

    test('a missing allergies key yields an empty list', () {
      expect(UserProfile.fromJson({'name': 'Test'}).allergies, isEmpty);
    });
  });
}
