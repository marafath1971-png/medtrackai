import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medai/models/product_analysis.dart';
import 'package:medai/screens/analysis/widgets/scan_share_card.dart';

void main() {
  testWidgets(
      'ScanShareCard renders product name, score, chips and action buttons',
      (tester) async {
    final product = ProductAnalysis(
      id: 'share-card-test',
      name: 'Niacinamide 10% + Zinc 1%',
      category: 'Skincare',
      description: 'High-strength vitamin and mineral blemish formula.',
      whyTakeIt: 'Reduces appearance of skin blemishes.',
      howItWorks: 'Regulates sebum and balances skin.',
      benefits: ['Sebum control', 'Smoother texture'],
      sideEffects: [],
      foodInteractions: [],
      medicineInteractions: [],
      timing: 'Apply to entire face morning and evening.',
      halalStatus: 'Halal Certified',
      scientificEvidence: 'Extensive dermatological studies.',
      allergyAlerts: [],
      allergyRiskLevel: 'None',
      expertPerspectives: [],
      cleanScore: 95,
      comedogenicRating: 0,
      activeIngredients: const ['Niacinamide', 'Zinc PCA'],
      skinBenefits: const ['Pore Reduction', 'Oil Balance'],
      routineType: 'AM/PM Routine',
      identified: true,
      confidence: 'high',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ScanShareCard(product: product),
          ),
        ),
      ),
    );

    // Fire the 420ms delayed future, then settle all animations
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    // Verify header and product info
    expect(find.text('MedAI'), findsNWidgets(2));
    expect(find.text('AI Product Scan'), findsOneWidget);
    expect(find.text('Niacinamide 10% + Zinc 1%'), findsOneWidget);

    // Verify clean score
    expect(find.text('95'), findsOneWidget);
    expect(find.text('/100'), findsOneWidget);
    expect(find.text('Exceptional'), findsOneWidget);

    // Verify chips
    expect(find.text('Ultra-clean formula ✓'), findsOneWidget);

    // Verify action buttons
    expect(find.text('Save to Camera Roll'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);
  });
}
