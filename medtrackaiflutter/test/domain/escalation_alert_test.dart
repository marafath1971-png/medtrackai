import 'package:flutter_test/flutter_test.dart';
import 'package:medai/domain/entities/escalation_alert.dart';

EscalationAlert _a(String id, String day, String time, {String? ack}) =>
    EscalationAlert(
      id: id,
      patientUid: 'p',
      displayName: 'Dad',
      medName: 'Warfarin',
      time: time,
      dayKey: day,
      alertedUids: const ['me'],
      acknowledgedBy: ack,
    );

void main() {
  final today = DateTime(2026, 9, 29, 10);

  test('open alerts come before handled ones, newest dose first', () {
    final out = EscalationAlert.relevant([
      _a('handled', '2026-09-29', '09:00', ack: 'mom'),
      _a('old-open', '2026-09-28', '20:00'),
      _a('new-open', '2026-09-29', '08:00'),
    ], today);
    expect(out.map((a) => a.id), ['new-open', 'old-open', 'handled']);
  });

  test('alerts older than yesterday are dropped', () {
    final out = EscalationAlert.relevant([
      _a('stale', '2026-09-26', '08:00'),
      _a('today', '2026-09-29', '08:00'),
    ], today);
    expect(out.map((a) => a.id), ['today']);
  });

  test("a patient a timezone ahead can be dated tomorrow and still shows", () {
    final out =
        EscalationAlert.relevant([_a('ahead', '2026-09-30', '07:30')], today);
    expect(out, hasLength(1));
  });

  test('fromMap tolerates missing and malformed fields', () {
    final a = EscalationAlert.fromMap('x', {
      'alertedUids': ['a', 3, null, 'b'],
      'medName': '',
    });
    expect(a.alertedUids, ['a', 'b']);
    expect(a.medName, 'a medication');
    expect(a.displayName, 'Someone you care for');
    expect(a.isAcknowledged, isFalse);
    expect(a.reached, 2);
  });
}
