import 'package:flutter_test/flutter_test.dart';
import 'package:medai/domain/entities/entities.dart';

void main() {
  test('Medicine.fromJson with Map<dynamic, dynamic> nested objects', () {
    final Map<dynamic, dynamic> innerProductAnalysis = <dynamic, dynamic>{};
    innerProductAnalysis['id'] = '1';
    innerProductAnalysis['name'] = 'Magnesium Glycinate';
    innerProductAnalysis['category'] = 'Supplement';
    innerProductAnalysis['description'] = 'A highly bioavailable form of magnesium.';
    innerProductAnalysis['whyTakeIt'] = 'Why take it';
    innerProductAnalysis['howItWorks'] = 'How it works';
    innerProductAnalysis['benefits'] = ['Better Sleep'];
    innerProductAnalysis['sideEffects'] = <dynamic>[];
    innerProductAnalysis['foodInteractions'] = <dynamic>[];
    innerProductAnalysis['medicineInteractions'] = <dynamic>[];
    innerProductAnalysis['timing'] = 'Bedtime';
    innerProductAnalysis['halalStatus'] = 'Halal';
    innerProductAnalysis['scientificEvidence'] = 'Strong';
    innerProductAnalysis['expertPerspectives'] = <dynamic>[
      <dynamic, dynamic>{
        'role': 'Doctor',
        'explanation': 'Medical perspective',
        'icon': '👩‍⚕️',
      }
    ];

    final Map<String, dynamic> stringKeyedMap = {
      'id': 12345,
      'name': 'Test Magnesium',
      'courseStartDate': '2026-06-21T16:02:53',
      'productAnalysis': innerProductAnalysis,
    };

    final deserialized = Medicine.fromJson(stringKeyedMap);
    expect(deserialized.name, 'Test Magnesium');
    expect(deserialized.productAnalysis!.name, 'Magnesium Glycinate');
  });
}
