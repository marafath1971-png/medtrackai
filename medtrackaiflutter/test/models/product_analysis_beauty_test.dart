import 'package:flutter_test/flutter_test.dart';
import 'package:medai/models/product_analysis.dart';

void main() {
  group('ProductAnalysis Beauty & Skincare Intelligence', () {
    test(
        'serializes and deserializes clean score, comedogenic rating, actives, and routine',
        () {
      final analysis = ProductAnalysis(
        id: 'test-beauty-1',
        name: 'Niacinamide 10% + Zinc 1%',
        category: 'Skincare',
        description: 'Water-based serum to boost skin brightness and texture.',
        whyTakeIt:
            'Reduces appearance of blemishes and balances sebum activity.',
        howItWorks:
            'Niacinamide strengthens skin lipid barrier while zinc PCA regulates sebum.',
        benefits: [
          'Reduces blemishes',
          'Minimizes pores',
          'Strengthens barrier'
        ],
        sideEffects: [
          SideEffect(
              effect: 'Mild tingling on first application', severity: 'Low')
        ],
        foodInteractions: [],
        medicineInteractions: [
          'Avoid mixing with direct Vitamin C (L-Ascorbic Acid) in same routine'
        ],
        timing:
            'Apply a few drops to face in morning and evening before heavier creams',
        halalStatus: 'Halal Certified',
        scientificEvidence:
            'Strong clinical evidence supporting 2-5% topical niacinamide for barrier health.',
        allergyAlerts: [],
        allergyRiskLevel: 'None',
        expertPerspectives: [],
        cleanScore: 96,
        comedogenicRating: 0,
        activeIngredients: ['Niacinamide 10%', 'Zinc PCA 1%'],
        skinBenefits: [
          'Blemish Defense',
          'Barrier Support',
          'Glow & Oil Balance'
        ],
        routineType: 'AM & PM',
        identified: true,
        confidence: 'high',
      );

      final json = analysis.toJson();
      expect(json['cleanScore'], 96);
      expect(json['comedogenicRating'], 0);
      expect(json['activeIngredients'], ['Niacinamide 10%', 'Zinc PCA 1%']);
      expect(json['skinBenefits'],
          ['Blemish Defense', 'Barrier Support', 'Glow & Oil Balance']);
      expect(json['routineType'], 'AM & PM');

      final restored = ProductAnalysis.fromJson(json);
      expect(restored.cleanScore, 96);
      expect(restored.comedogenicRating, 0);
      expect(restored.activeIngredients, ['Niacinamide 10%', 'Zinc PCA 1%']);
      expect(restored.skinBenefits,
          ['Blemish Defense', 'Barrier Support', 'Glow & Oil Balance']);
      expect(restored.routineType, 'AM & PM');
      expect(restored.identified, isTrue);
      expect(restored.confidence, 'high');
    });

    test('gracefully handles missing beauty fields from legacy JSON', () {
      final legacyJson = {
        'id': 'legacy-1',
        'name': 'Aspirin',
        'category': 'Medicine',
        'description': 'NSAID pain reliever',
        'whyTakeIt': 'Pain relief',
        'howItWorks': 'Inhibits COX enzymes',
        'benefits': ['Pain relief'],
        'sideEffects': [],
        'foodInteractions': [],
        'medicineInteractions': [],
        'timing': 'With water after food',
        'halalStatus': 'Unknown',
        'scientificEvidence': 'Proven',
        'allergyAlerts': [],
        'allergyRiskLevel': 'None',
        'expertPerspectives': [],
      };

      final restored = ProductAnalysis.fromJson(legacyJson);
      expect(restored.cleanScore, isNull);
      expect(restored.comedogenicRating, isNull);
      expect(restored.activeIngredients, isEmpty);
      expect(restored.skinBenefits, isEmpty);
      expect(restored.routineType, isNull);
      expect(restored.identified, isTrue);
      expect(restored.confidence, 'low');
    });
  });
}
