import 'package:flutter_test/flutter_test.dart';
import 'package:medai/domain/entities/caregiver.dart';
import 'package:medai/screens/family/widgets/escalation_widgets.dart';

void main() {
  test('delay labels match the add-caregiver choices', () {
    expect(alertDelayLabel(0), 'right away');
    expect(alertDelayLabel(15), 'after 15 min');
    expect(alertDelayLabel(30), 'after 30 min');
    expect(alertDelayLabel(60), 'after 1 hr');
  });

  test('the chain shown to the patient is the order the server alerts in', () {
    // functions/missed_dose_rules.js resolveCaregivers: active only,
    // quickest delay first.
    final chain = escalationOrder([
      Caregiver(
          id: 1,
          name: 'Bro',
          relation: 'Sibling',
          status: 'active',
          alertDelay: 60),
      Caregiver(
          id: 2,
          name: 'Pending',
          relation: 'Friend',
          status: 'pending',
          alertDelay: 0),
      Caregiver(
          id: 3,
          name: 'Mom',
          relation: 'Parent',
          status: 'active',
          alertDelay: 15),
    ]);
    expect(chain.map((c) => c.name), ['Mom', 'Bro']);
  });
}
