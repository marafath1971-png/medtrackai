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

  group('psychological pricing and weekly anchoring', () {
    test('weekly to annual equivalent calculates 52 weeks correctly', () {
      // $4.99 * 52 = 259.48
      expect(weeklyToAnnualEquivalent(4.99), closeTo(259.48, 0.01));
      expect(weeklyToAnnualEquivalent(0), 0);
    });

    test('weekly to monthly equivalent calculates (52 / 12) months correctly', () {
      // $4.99 * 52 / 12 = 21.6233...
      expect(weeklyToMonthlyEquivalent(4.99), closeTo(21.62, 0.01));
    });

    test('annual savings vs weekly anchors annual at ~85% discount', () {
      // $39.99 vs ($4.99 * 52 = $259.48) -> 1 - 39.99/259.48 = 84.58% -> 84%
      expect(
        annualSavingsVsWeeklyPercent(annualPrice: 39.99, weeklyPrice: 4.99),
        84,
      );
      // $36.99 vs ($4.99 * 52 = $259.48) -> 1 - 36.99/259.48 = 85.74% -> 85%
      expect(
        annualSavingsVsWeeklyPercent(annualPrice: 36.99, weeklyPrice: 4.99),
        85,
      );
    });

    test('monthly savings vs weekly anchors monthly at ~63% discount', () {
      // $7.99 vs $21.62 ($4.99/wk equivalent) -> 1 - 7.99/21.623 = 63.04% -> 63%
      expect(
        monthlySavingsVsWeeklyPercent(monthlyPrice: 7.99, weeklyPrice: 4.99),
        63,
      );
    });

    test('anchoring guards currency mismatch and null/zero values', () {
      expect(
        annualSavingsVsWeeklyPercent(
          annualPrice: 39.99,
          weeklyPrice: 4.99,
          annualCurrency: 'USD',
          weeklyCurrency: 'EUR',
        ),
        isNull,
      );
      expect(
        annualSavingsVsWeeklyPercent(annualPrice: 39.99, weeklyPrice: 0),
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
