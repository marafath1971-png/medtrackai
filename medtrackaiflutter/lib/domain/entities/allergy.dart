/// Canonical handling for the user's medication allergies.
///
/// These strings are interpolated directly into the scanner's safety prompt
/// ("the user has the following known allergies: …"), so what is stored here
/// is what the AI cross-references against a product's ingredients. That makes
/// the stored representation safety-relevant rather than cosmetic:
///
///  * Onboarding used to persist raw option ids, so `nsaids` — not
///    `NSAIDs (Ibuprofen)` — was what the model saw.
///  * Worse, "None that I know of" was stored as the literal `none`, which
///    reached the prompt as a *known allergy* named "none".
///
/// [normalizeAllergies] repairs both on read, so profiles written by older
/// builds are corrected without a data migration.
library;

/// The quick-add presets offered in onboarding and the profile editor, keyed by
/// the legacy option id that older builds persisted.
const Map<String, String> kAllergyPresets = {
  'penicillin': 'Penicillin',
  'sulfa': 'Sulfa drugs',
  'nsaids': 'NSAIDs (Ibuprofen)',
  'aspirin': 'Aspirin',
};

/// Option ids that mean "no allergies" rather than naming one. These must never
/// survive into the stored list — an allergy called "none" is not a real
/// allergy, and passing it to the safety prompt is actively misleading.
const Set<String> kNoAllergySentinels = {'none', 'None', 'none_known'};

/// Upper bound on a single entry. Free text ends up in an AI prompt, so a
/// pathological paste should not be able to dominate it.
const int kMaxAllergyLength = 60;

/// Upper bound on how many allergies are stored.
const int kMaxAllergyCount = 20;

/// Cleans a raw allergy list into what should be stored and shown.
///
/// Maps legacy preset ids to their display labels, drops "none" sentinels and
/// blanks, trims and length-caps free text, removes case-insensitive duplicates
/// while keeping the original order, and caps the total count.
List<String> normalizeAllergies(Iterable<String> raw) {
  final seen = <String>{};
  final result = <String>[];

  for (final entry in raw) {
    final trimmed = entry.trim();
    if (trimmed.isEmpty) continue;
    if (kNoAllergySentinels.contains(trimmed.toLowerCase())) continue;

    // Legacy ids are stored lowercase; anything else is already a label or is
    // user-entered free text.
    final label = kAllergyPresets[trimmed.toLowerCase()] ?? trimmed;
    final capped = label.length > kMaxAllergyLength
        ? label.substring(0, kMaxAllergyLength).trim()
        : label;

    if (seen.add(capped.toLowerCase())) {
      result.add(capped);
      if (result.length >= kMaxAllergyCount) break;
    }
  }

  return result;
}
