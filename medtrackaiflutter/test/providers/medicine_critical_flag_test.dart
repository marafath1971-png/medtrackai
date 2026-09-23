import 'package:flutter_test/flutter_test.dart';
import 'package:medai/domain/entities/entities.dart';

/// `detectMissedDoses` (functions/index.js) is the server-side caregiver safety
/// net. It scans every scheduled dose of a monitored patient and pushes an FCM
/// alert when one goes unhandled past the grace window — but it opens with:
///
///     if (med.isCritical !== true) continue;
///
/// So the whole path is gated on a single boolean reaching Firestore as `true`.
/// For a long time nothing could set it: [Medicine.isCritical] was read by
/// `fromJson` and `copyWith` and written by no UI anywhere, so it was always
/// false and the scheduled function alerted on nothing. (The `isCritical`
/// toggle that did exist belonged to a family *member*, a different object.)
///
/// The medicine detail screen now owns that toggle. These tests pin the model
/// contract underneath it: flipping the flag has to survive `copyWith` and the
/// JSON round trip, because Firestore stores exactly what `toJson` emits and
/// the function reads exactly that field.
const _kStart = '2026-08-15T09:00:00.000';

Medicine _med({bool isCritical = false}) => Medicine(
      id: 1,
      name: 'Warfarin',
      courseStartDate: _kStart,
      isCritical: isCritical,
    );

void main() {
  test('a medicine is not critical until someone says so', () {
    // The default matters: opting every medicine into caregiver alerts would
    // train recipients to ignore them.
    expect(_med().isCritical, isFalse);
  });

  test('copyWith can turn the flag on and back off', () {
    final marked = _med().copyWith(isCritical: true);
    expect(marked.isCritical, isTrue);

    // copyWith's `bool?` parameter must not treat `false` as "unset" — that
    // would make the toggle one-way and un-turn-off-able.
    expect(marked.copyWith(isCritical: false).isCritical, isFalse);
  });

  test('copyWith leaves the flag alone when unrelated fields change', () {
    final marked = _med(isCritical: true);
    expect(marked.copyWith(count: 30).isCritical, isTrue);
  });

  test('toJson emits the exact field name the scheduled function reads', () {
    // The function does `med.isCritical !== true`, a strict comparison against
    // a real boolean — a truthy string or a differently-cased key never fires.
    final json = _med(isCritical: true).toJson();
    expect(json['isCritical'], isTrue);
    expect(json['isCritical'], isA<bool>());
  });

  test('the flag survives the storage round trip', () {
    final restored = Medicine.fromJson(_med(isCritical: true).toJson());
    expect(restored.isCritical, isTrue);

    final restoredOff = Medicine.fromJson(_med().toJson());
    expect(restoredOff.isCritical, isFalse);
  });
}
