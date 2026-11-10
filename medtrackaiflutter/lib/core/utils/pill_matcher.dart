import '../../domain/entities/entities.dart';

/// "Is this pill one of mine?" — checks a pill scan against the user's own
/// medicine list.
///
/// Generic AI pill identifiers answer "what is this?", and reviewers of the
/// category report them getting it right as rarely as one pill in five. The
/// question a patient holding a loose pill actually has is narrower: is this
/// the thing I'm meant to take now? Checking against a short, known list is a
/// far easier problem than open-world identification, and the answer comes
/// with a concrete action (log the dose) or a concrete warning (different
/// strength).
///
/// Deterministic on purpose: the AI supplies what it read off the pill; the
/// comparison with the user's list is plain string and number logic, so it
/// can be tested and it never invents a match.
enum PillMatchKind {
  /// Same medicine and, where both sides state one, the same strength.
  match,

  /// Same medicine, different strength or release form. The dangerous case:
  /// a 10 mg pill in a 5 mg bottle.
  strengthMismatch,

  /// Nothing in the list shares a name with the scan.
  notMine,

  /// The scan did not identify anything to compare.
  unidentified,
}

class PillMatch {
  final PillMatchKind kind;

  /// The user's medicine this scan matched, for [PillMatchKind.match] and
  /// [PillMatchKind.strengthMismatch].
  final Medicine? med;

  /// False when the scanner reported low confidence. A match is still shown,
  /// but the UI must tell the user to check the imprint before relying on it.
  final bool confident;

  /// Whether both sides stated a strength and they agreed. A match on name
  /// alone is still a match, but the UI should say strength was not checked.
  final bool strengthVerified;

  /// Human-readable strengths, for the mismatch message.
  final String scannedStrength;
  final String listedStrength;

  const PillMatch({
    required this.kind,
    this.med,
    this.confident = true,
    this.strengthVerified = false,
    this.scannedStrength = '',
    this.listedStrength = '',
  });
}

// Salt and ester words that do not change which medicine it is:
// "metformin hydrochloride" is metformin.
const _saltWords = {
  'hydrochloride',
  'hcl',
  'sodium',
  'potassium',
  'calcium',
  'magnesium',
  'maleate',
  'besylate',
  'besilate',
  'succinate',
  'tartrate',
  'citrate',
  'sulfate',
  'sulphate',
  'phosphate',
  'acetate',
  'mesylate',
  'fumarate',
  'bromide',
  'chloride',
  'hyclate',
  'monohydrate',
  'dihydrate',
  'trihydrate',
};

// Release forms DO change what you should be taking, so they are pulled out
// of the name and compared alongside strength rather than discarded.
const _releaseWords = {
  'er',
  'xr',
  'sr',
  'cr',
  'la',
  'xl',
  'dr',
  'ir',
  'ec',
  'mr',
};

// Dosage-form words that describe the pill, not the medicine.
const _formWords = {
  'tablet',
  'tablets',
  'tab',
  'tabs',
  'capsule',
  'capsules',
  'cap',
  'caps',
  'pill',
  'pills',
  'oral',
  'film',
  'coated',
  'chewable',
  'softgel',
  'softgels',
  'mg',
  'mcg',
  'g',
  'ml',
  'iu',
  'unit',
  'units',
};

final _strengthRe = RegExp(
  r'(\d+(?:[.,]\d+)?)\s*(mg|mcg|µg|ug|g|iu|units?|ml|%)\b',
  caseSensitive: false,
);

/// Medicine-identity tokens of a name: lowercased words minus salts,
/// release forms, dosage forms and bare numbers.
Set<String> nameTokens(String raw) {
  return raw
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
      .split(RegExp(r'\s+'))
      .where((t) =>
          t.isNotEmpty &&
          !_saltWords.contains(t) &&
          !_releaseWords.contains(t) &&
          !_formWords.contains(t) &&
          !RegExp(r'^\d').hasMatch(t))
      .toSet();
}

/// Release-form tag in a name or dose string ("er", "xr"…), or '' if none.
String releaseTag(String raw) {
  final words = raw.toLowerCase().split(RegExp(r'[^a-z]+'));
  for (final w in words) {
    if (_releaseWords.contains(w) && w != 'ir') return w;
  }
  return '';
}

/// Strengths in a dose string, normalised so 0.5 g == 500 mg == 500000 mcg.
Set<String> strengths(String raw) {
  final out = <String>{};
  for (final m in _strengthRe.allMatches(raw)) {
    var value = double.tryParse(m.group(1)!.replaceAll(',', '.'));
    if (value == null) continue;
    var unit = m.group(2)!.toLowerCase();
    switch (unit) {
      case 'g':
        value *= 1000;
        unit = 'mg';
      case 'mcg' || 'µg' || 'ug':
        value /= 1000;
        unit = 'mg';
      case 'unit' || 'units':
        unit = 'iu';
    }
    // Drop float noise: 0.1 g -> 100.0000001 mg must equal 100 mg.
    final rounded = (value * 1000).round() / 1000;
    final text = rounded == rounded.roundToDouble()
        ? rounded.toInt().toString()
        : rounded.toString();
    out.add('$text$unit');
  }
  return out;
}

bool _sameMedicine(Set<String> a, Set<String> b) {
  if (a.isEmpty || b.isEmpty) return false;
  // Every identity word of the shorter name appears in the longer one:
  // "Tylenol" ⊂ "Tylenol Extra Strength", but "Vitamin D" ⊄ "Vitamin B12".
  final (small, big) = a.length <= b.length ? (a, b) : (b, a);
  return small.every(big.contains);
}

/// Compares a scan with the user's medicines. See [PillMatchKind].
PillMatch matchScannedPill(ScanResult scan, List<Medicine> meds) {
  final scannedNames = [scan.name, scan.genericName, scan.brand]
      .where((n) => n.trim().isNotEmpty)
      .map(nameTokens)
      .where((t) => t.isNotEmpty)
      .toList();
  if (!scan.identified || scannedNames.isEmpty) {
    return const PillMatch(kind: PillMatchKind.unidentified, confident: false);
  }

  final confident = scan.confidence.toLowerCase() != 'low';
  final scanDoseText = '${scan.dose} ${scan.dosePerTake}';
  final scanStrengths = strengths(scanDoseText);
  final scanRelease = releaseTag('${scan.name} ${scan.brand} ${scan.dose}');

  PillMatch? mismatch;
  PillMatch? unverified;

  for (final med in meds) {
    final medNames = [med.name, med.genericName, med.brand]
        .where((n) => n.trim().isNotEmpty)
        .map(nameTokens)
        .where((t) => t.isNotEmpty);
    final same =
        medNames.any((m) => scannedNames.any((s) => _sameMedicine(s, m)));
    if (!same) continue;

    final medStrengths = strengths(med.dose);
    final medRelease = releaseTag('${med.name} ${med.brand} ${med.dose}');
    final releaseDiffers = scanRelease != medRelease &&
        scanRelease.isNotEmpty &&
        medRelease.isNotEmpty;
    final bothStated = scanStrengths.isNotEmpty && medStrengths.isNotEmpty;
    final strengthDiffers =
        bothStated && scanStrengths.intersection(medStrengths).isEmpty;

    if (strengthDiffers || releaseDiffers) {
      mismatch ??= PillMatch(
        kind: PillMatchKind.strengthMismatch,
        med: med,
        confident: confident,
        scannedStrength: [scan.dose.trim(), scanRelease.toUpperCase()]
            .where((s) => s.isNotEmpty)
            .join(' '),
        listedStrength: [med.dose.trim(), medRelease.toUpperCase()]
            .where((s) => s.isNotEmpty)
            .join(' '),
      );
      continue;
    }

    final result = PillMatch(
      kind: PillMatchKind.match,
      med: med,
      confident: confident,
      strengthVerified: bothStated,
      scannedStrength: scan.dose.trim(),
      listedStrength: med.dose.trim(),
    );
    // Prefer a medicine whose strength was actually confirmed over one that
    // merely shares the name — a user can have two strengths of one drug.
    if (bothStated) return result;
    unverified ??= result;
  }

  return unverified ??
      mismatch ??
      PillMatch(kind: PillMatchKind.notMine, confident: confident);
}

/// Today's untaken dose of [medId] closest to [now], or null.
///
/// Past-due doses win ties with upcoming ones: the pill in hand is most
/// likely the one the user is late for.
DoseItem? doseToLog({
  required List<DoseItem> doses,
  required Map<String, bool> takenToday,
  required int medId,
  required DateTime now,
}) {
  final nowMin = now.hour * 60 + now.minute;
  DoseItem? best;
  int? bestDist;
  for (final d in doses) {
    if (d.med.id != medId) continue;
    if (takenToday[d.key] == true) continue;
    final at = d.sched.h * 60 + d.sched.m;
    // Upcoming doses count as slightly further away than past-due ones.
    final dist = at <= nowMin ? nowMin - at : (at - nowMin) + 1;
    if (bestDist == null || dist < bestDist) {
      best = d;
      bestDist = dist;
    }
  }
  return best;
}
