import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medai/models/product_analysis.dart';
import 'package:medai/screens/analysis/widgets/scan_beauty_profile_card.dart';

void main() {
  testWidgets(
      'ScanBeautyProfileCard renders clean score, pore clog risk, and actives',
      (tester) async {
    final product = ProductAnalysis(
      id: 'beauty-card-1',
      name: 'Salicylic Acid 2% Masque',
      category: 'Skincare',
      description: 'Charcoal and clay facial masque for blemish-prone skin.',
      whyTakeIt: 'Targets lackluster tone and textural irregularities.',
      howItWorks:
          'BHA exfoliates pore walls to unclog sebum and dead skin cells.',
      benefits: ['Deep pore cleansing', 'Smooth skin texture'],
      sideEffects: [],
      foodInteractions: [],
      medicineInteractions: [],
      timing: 'Use once or twice a week on thoroughly clean, dry skin.',
      halalStatus: 'Halal Certified',
      scientificEvidence:
          'Strong evidence for 2% salicylic acid in acne management.',
      allergyAlerts: [],
      allergyRiskLevel: 'None',
      expertPerspectives: [],
      cleanScore: 92,
      comedogenicRating: 1,
      activeIngredients: const [
        'Salicylic Acid 2%',
        'Amazonian Clay',
        'Activated Charcoal'
      ],
      skinBenefits: const ['Pore Decongestion', 'Blemish Defense'],
      routineType: 'PM Routine',
      identified: true,
      confidence: 'high',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ScanBeautyProfileCard(product: product),
          ),
        ),
      ),
    );

    expect(find.text('Beauty & Clean Profile'), findsOneWidget);
    expect(find.text('92'), findsOneWidget);
    expect(find.text('Clean Formulation'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('Very Low Risk (1/5)'), findsOneWidget);
    expect(find.text('Salicylic Acid 2%'), findsOneWidget);
    expect(find.text('Pore Decongestion'), findsOneWidget);
    expect(find.text('PM Routine'), findsOneWidget);
  });
}
