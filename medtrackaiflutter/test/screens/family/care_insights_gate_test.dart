import 'package:flutter_test/flutter_test.dart';
import 'package:medai/screens/family/widgets/monitoring_widgets.dart';

void main() {
  test('your own insights are always open', () {
    expect(
        canViewPatientInsights(
            isMe: true, viewerPremium: false, patientHasFamilyPlan: false),
        isTrue);
  });

  test("someone else's need Pro", () {
    expect(
        canViewPatientInsights(
            isMe: false, viewerPremium: false, patientHasFamilyPlan: false),
        isFalse);
    expect(
        canViewPatientInsights(
            isMe: false, viewerPremium: true, patientHasFamilyPlan: false),
        isTrue);
  });

  test("the patient's Family plan covers a caregiver without Pro", () {
    expect(
        canViewPatientInsights(
            isMe: false, viewerPremium: false, patientHasFamilyPlan: true),
        isTrue);
  });
}
