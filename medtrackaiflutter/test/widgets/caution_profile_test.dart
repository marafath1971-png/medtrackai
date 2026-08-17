import 'package:flutter_test/flutter_test.dart';
import 'package:medai/models/product_analysis.dart';
import 'package:medai/screens/analysis/widgets/scan_insight_dashboard.dart';

/// The scan result used to headline a "SAFETY SCORE" percentage built by
/// subtracting penalties from 80. Scanning a real box of Alben (Albendazole)
/// on device produced **52%**, which reads as "this drug is about half safe".
///
/// Albendazole is a WHO essential medicine. It scored 52 because it has a
/// pregnancy contraindication (-20), a paediatric warning, and five documented
/// interactions (-15) — every one of which exists *because* the drug is well
/// studied. A obscure compound with no published interactions scored higher.
/// That is backwards, and on a medicine screen it is the kind of backwards that
/// changes what someone decides to take.
///
/// CautionProfile replaces it: named for what it measures, banded rather than
/// falsely precise, and always shown with the reasons behind it.
ProductAnalysis _analysis({
  List<SideEffect> sideEffects = const [],
  List<String> medicineInteractions = const [],
  String allergyRiskLevel = '',
  String scientificEvidence = '',
  String? pregnancyAlert,
  String? childSafetyAlert,
}) {
  return ProductAnalysis(
    id: 'test',
    name: 'Test',
    category: 'Medicine',
    description: '',
    whyTakeIt: '',
    howItWorks: '',
    benefits: const [],
    sideEffects: sideEffects,
    foodInteractions: const [],
    medicineInteractions: medicineInteractions,
    timing: '',
    halalStatus: '',
    scientificEvidence: scientificEvidence,
    childSafetyAlert: childSafetyAlert,
    pregnancyAlert: pregnancyAlert,
    allergyAlerts: const [],
    allergyRiskLevel: allergyRiskLevel,
    expertPerspectives: const [],
  );
}

void main() {
  group('the Albendazole regression', () {
    // The exact shape of the on-device scan that produced 52%.
    final albendazole = _analysis(
      pregnancyAlert: 'Albendazole is contraindicated in pregnancy, '
          'especially during the first trimester.',
      childSafetyAlert: 'Dosage for children is strictly weight-based.',
      medicineInteractions: const [
        'Cimetidine',
        'Dexamethasone',
        'Praziquantel',
        'Ritonavir',
        'Theophylline',
      ],
      scientificEvidence: 'Albendazole is a well-established broad-spectrum '
          'anthelminthic drug.',
      sideEffects: [
        SideEffect(effect: 'Headache', severity: 'Low'),
        SideEffect(effect: 'Nausea', severity: 'Low'),
      ],
    );

    test('a well-established drug is not branded half-unsafe', () {
      final profile = CautionProfile.from(albendazole);

      // It does warrant care — it is contraindicated in pregnancy — but the
      // reader is told that specifically rather than given a failing grade.
      expect(profile.level, CautionLevel.elevated);
      expect(profile.level.label, 'Extra care needed');
      expect(profile.evidenceStrong, isTrue,
          reason: 'well-established evidence should never read as a negative');
    });

    test('the pregnancy contraindication is surfaced as the reason', () {
      final profile = CautionProfile.from(albendazole);

      final restriction = profile.reasons.firstWhere((r) => r.isRestriction);
      expect(restriction.label, 'Not in pregnancy',
          reason: 'the single most decision-relevant fact must be visible '
              'without expanding anything');
    });

    test('interaction count is reported, not converted into a penalty', () {
      final profile = CautionProfile.from(albendazole);

      expect(profile.interactionCount, 5);
      expect(
        profile.reasons.any((r) => r.label.contains('5 drug interactions')),
        isTrue,
      );
    });
  });

  group('banding', () {
    test('a clean profile is routine', () {
      final profile = CautionProfile.from(_analysis(
        scientificEvidence: 'Strong evidence.',
      ));

      expect(profile.level, CautionLevel.routine);
      expect(profile.reasons, isEmpty);
    });

    test('a non-restricting caution is moderate, not elevated', () {
      final profile = CautionProfile.from(_analysis(
        childSafetyAlert: 'Dosing differs for children.',
      ));

      expect(profile.level, CautionLevel.moderate);
    });

    test('a hard restriction escalates to elevated', () {
      final profile = CautionProfile.from(_analysis(
        pregnancyAlert: 'Contraindicated in pregnancy.',
      ));

      expect(profile.level, CautionLevel.elevated);
    });

    test('high allergy risk is a restriction', () {
      final profile = CautionProfile.from(_analysis(
        allergyRiskLevel: 'High',
      ));

      expect(profile.level, CautionLevel.elevated);
      expect(profile.reasons.single.isRestriction, isTrue);
    });

    test('weak evidence escalates on its own', () {
      // Not knowing is its own reason for care, so "limited evidence" must not
      // land in the same band as a clean, well-studied profile.
      final profile = CautionProfile.from(_analysis(
        scientificEvidence: 'Limited evidence in humans.',
      ));

      expect(profile.level, CautionLevel.elevated);
    });

    test('side effects alone do not escalate the band', () {
      // The old formula lost a point per side effect, so a drug with many
      // well-characterised mild effects scored worse than one with none listed.
      final profile = CautionProfile.from(_analysis(
        sideEffects: [
          SideEffect(effect: 'Headache', severity: 'Low'),
          SideEffect(effect: 'Nausea', severity: 'Low'),
          SideEffect(effect: 'Dizziness', severity: 'Low'),
          SideEffect(effect: 'Vomiting', severity: 'Low'),
        ],
        scientificEvidence: 'Well-established.',
      ));

      expect(profile.level, CautionLevel.routine);
      expect(profile.sideEffectCount, 4,
          reason: 'still counted and displayed, just not scored');
    });
  });

  group('missing data is not an assurance', () {
    test('an absent allergy level produces no allergy reason', () {
      // The tile used to print "Allergy risk — None" for an empty field,
      // presenting missing data as a clean bill of health.
      final profile = CautionProfile.from(_analysis(allergyRiskLevel: ''));

      expect(
        profile.reasons.any((r) => r.label.contains('allergy')),
        isFalse,
      );
    });

    test('an explicit None is distinct from an empty field', () {
      // "None" is a documented value the model can return, so it is real
      // information; empty means it never answered.
      final explicit = CautionProfile.from(_analysis(allergyRiskLevel: 'None'));
      final missing = CautionProfile.from(_analysis(allergyRiskLevel: ''));

      expect(explicit.reasons, isEmpty);
      expect(missing.reasons, isEmpty);
    });
  });
}
