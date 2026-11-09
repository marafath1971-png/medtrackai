import 'package:flutter_test/flutter_test.dart';
import 'package:medai/screens/paywall/paywall_plans.dart';

void main() {
  group('plan identity and order', () {
    test('a custom package named family is the Family plan', () {
      expect(planKindOf(identifier: 'family_annual'), PlanKind.family);
      expect(planKindOf(identifier: r'$rc_custom_FAMILY'), PlanKind.family);
    });

    test('annual leads, then family, then monthly, lifetime last', () {
      final kinds = [
        PlanKind.lifetime,
        PlanKind.monthly,
        PlanKind.family,
        PlanKind.annual,
      ]..sort((a, b) => planRank(a).compareTo(planRank(b)));
      expect(kinds, [
        PlanKind.annual,
        PlanKind.family,
        PlanKind.monthly,
        PlanKind.lifetime,
      ]);
    });

    test('a custom plan reads its period from the store', () {
      expect(periodLabel(PlanKind.family, isoPeriod: 'P1Y'), '/ year');
      expect(periodLabel(PlanKind.family, isoPeriod: 'P1M'), '/ month');
      expect(periodLabel(PlanKind.lifetime), 'one-time');
    });
  });

  group('annual savings badge', () {
    test('is computed from the real prices', () {
      // 39.99/yr vs 9.99/mo -> 1 - 39.99/119.88 = 66.6% -> 66
      expect(annualSavingsPercent(annualPrice: 39.99, monthlyPrice: 9.99), 66);
    });

    test('is absent without a monthly plan to compare against', () {
      expect(annualSavingsPercent(annualPrice: 39.99, monthlyPrice: 0), isNull);
    });

    test('is absent when annual is not actually cheaper', () {
      expect(annualSavingsPercent(annualPrice: 119.88, monthlyPrice: 9.99),
          isNull);
    });

    test('never compares prices in different currencies', () {
      expect(
        annualSavingsPercent(
          annualPrice: 3999,
          monthlyPrice: 9.99,
          annualCurrency: 'JPY',
          monthlyCurrency: 'USD',
        ),
        isNull,
      );
    });
  });

  group('trial timeline', () {
    test('a 7-day trial reminds on day 6, when the push is scheduled', () {
      expect(trialTimeline(7), [
        ('Today', 'Full Pro access free'),
        ('Day 6', 'Reminder before trial ends'),
        ('Day 7', 'Plan begins unless cancelled'),
      ]);
    });

    test('a 2-day trial reminds tomorrow and starts plan on day 3', () {
      expect(trialTimeline(2), [
        ('Today', '2-day free trial begins'),
        ('Tomorrow', 'Reminder before trial ends'),
        ('Day 3', 'Plan begins unless cancelled'),
      ]);
    });

    test('a 3-day trial is described as 3 days, not 7', () {
      expect(trialTimeline(3).last.$1, 'Day 3');
    });

    test('no trial means no timeline', () {
      expect(trialTimeline(null), isEmpty);
      expect(trialTimeline(0), isEmpty);
    });
  });
}
