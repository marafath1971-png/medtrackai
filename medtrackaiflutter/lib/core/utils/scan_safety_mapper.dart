import '../../domain/entities/ai_safety_profile.dart';
import '../../domain/entities/medicine.dart';
import '../../domain/entities/scan_result.dart';
import '../../models/product_analysis.dart';

/// Maps scan-time safety strings into a persisted [AISafetyProfile]
/// so home / alarms can gate take with "Know your medicine" alerts.
AISafetyProfile safetyProfileFromScan(ScanResult sr) {
  final warnings = _splitBullets(sr.warnings);
  final interactions = _splitBullets(sr.interactions);
  final sideEffects = _splitBullets(sr.sideEffects);
  final foodRules = <String>[
    if (sr.withFood) 'Take with food',
    if (sr.whenToTake.isNotEmpty) 'When: ${sr.whenToTake}',
    if (sr.howToTake.isNotEmpty) sr.howToTake,
  ];

  final aha = <String>[
    if (sr.ahaMoment != null && sr.ahaMoment!.trim().isNotEmpty)
      sr.ahaMoment!.trim(),
    ...sideEffects.take(3),
  ];

  final impact = sr.bodyImpact;

  return AISafetyProfile(
    warnings: warnings,
    interactions: interactions,
    foodRules: foodRules,
    ahaMoments: aha,
    mechanismOfAction: impact?.mechanismOfAction.isNotEmpty == true
        ? impact!.mechanismOfAction
        : (sr.description.isNotEmpty
            ? sr.description
            : 'Details about how this medication works in your body will appear here.'),
    onsetMinutes: impact?.onsetMinutes ?? 0,
    peakHours: impact?.peakHours ?? 0,
    durationHours: impact?.durationHours ?? 0,
    bodySystems: impact?.bodySystems ?? const [],
    timelineEffects: impact?.timelineEffects ?? const [],
    ahaFacts: impact?.ahaFacts ?? const [],
  );
}

/// Maps hub product-analysis safety into a persisted [AISafetyProfile].
AISafetyProfile safetyProfileFromProductAnalysis(ProductAnalysis p) {
  final warnings = <String>[
    if (p.childSafetyAlert != null && p.childSafetyAlert!.trim().isNotEmpty)
      p.childSafetyAlert!.trim(),
    if (p.pregnancyAlert != null && p.pregnancyAlert!.trim().isNotEmpty)
      p.pregnancyAlert!.trim(),
    ...p.allergyAlerts,
  ];
  final interactions = <String>[
    ...p.medicineInteractions,
  ];
  final foodRules = <String>[
    ...p.foodInteractions,
    if (p.timing.isNotEmpty) p.timing,
  ];
  final aha = <String>[
    ...p.benefits.take(2),
    if (p.skincareNotes != null && p.skincareNotes!.trim().isNotEmpty)
      p.skincareNotes!.trim(),
    ...p.sideEffects.map((e) => e.effect).take(2),
  ];

  return AISafetyProfile(
    warnings: warnings,
    interactions: interactions,
    foodRules: foodRules,
    ahaMoments: aha,
    mechanismOfAction: p.howItWorks.isNotEmpty
        ? p.howItWorks
        : (p.description.isNotEmpty
            ? p.description
            : 'Details about how this medication works in your body will appear here.'),
  );
}

List<String> _splitBullets(String raw) {
  if (raw.trim().isEmpty) return const [];
  final lines = raw
      .split(RegExp(r'[\n;]+'))
      .map((e) => e.trim().replaceFirst(RegExp(r'^[•\-\*]\s*'), ''))
      .where((e) => e.isNotEmpty)
      .toList();
  if (lines.length > 1) return lines;
  if (raw.contains(',') && raw.length > 40) {
    return raw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.length > 3)
        .toList();
  }
  return [raw.trim()];
}

extension MedicineKnowSafety on Medicine {
  bool get hasCriticalSafetyAlerts {
    final p = aiSafetyProfile;
    if (p == null) return false;
    return p.warnings.isNotEmpty || p.interactions.isNotEmpty;
  }

  bool get needsPreTakeBriefing {
    final p = aiSafetyProfile;
    if (p == null) {
      return intakeInstructions.isNotEmpty &&
          intakeInstructions != 'None';
    }
    return p.warnings.isNotEmpty ||
        p.interactions.isNotEmpty ||
        p.foodRules.isNotEmpty ||
        p.ahaMoments.isNotEmpty;
  }
}
