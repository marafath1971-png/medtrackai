import 'package:flutter_test/flutter_test.dart';
import 'package:medai/domain/entities/entities.dart';

/// [Medicine.form] is the physical form (tablet, capsule, liquid).
/// [Medicine.category] is a classification (Supplement, General, Medicine) that
/// the scanners set and manual entry leaves blank.
///
/// The constructor used to default category to 'Tablet' — a *form* value — so
/// the detail screen rendered "Form: tablet" beside "Category: Tablet". That
/// default also disagreed with fromJson, which uses '', so the value silently
/// changed across a storage round trip.
const _kStart = '2026-08-15T09:00:00.000';

void main() {
  test('category defaults to empty, not a form value', () {
    final m = Medicine(id: 1, name: 'Metformin', courseStartDate: _kStart);
    expect(m.category, isEmpty);
    expect(m.category.toLowerCase(), isNot('tablet'));
  });

  test('form keeps its own sensible default', () {
    expect(Medicine(id: 1, name: 'Metformin', courseStartDate: _kStart).form, 'tablet');
  });

  test('the constructor default survives a JSON round trip', () {
    final m = Medicine(id: 1, name: 'Metformin', courseStartDate: _kStart);
    final restored = Medicine.fromJson(m.toJson());
    expect(restored.category, m.category,
        reason: 'constructor and fromJson defaults must agree');
    expect(restored.form, m.form);
  });

  test('an explicit category is preserved', () {
    final m = Medicine(id: 1, name: 'Vitamin D', category: 'Supplement', courseStartDate: _kStart);
    expect(m.category, 'Supplement');
    expect(Medicine.fromJson(m.toJson()).category, 'Supplement');
  });

  test('form and category stay independent', () {
    final m = Medicine(
        id: 1,
        name: 'Cough syrup',
        form: 'liquid',
        category: 'Supplement',
        courseStartDate: _kStart);
    expect(m.form, 'liquid');
    expect(m.category, 'Supplement');
  });
}
