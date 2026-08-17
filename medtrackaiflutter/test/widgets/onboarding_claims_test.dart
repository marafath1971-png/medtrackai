import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:medai/screens/onboarding/onboarding_controller.dart';
import 'package:medai/screens/onboarding/widgets/ob_conversion.dart';

/// Onboarding shipped three claims it could not support, in seven languages:
/// "Trusted by 500,000+ people", a competitor benchmark ("outperforms generic
/// pill ID apps in head-to-head tests", with a 1.65x chart), and a medical
/// outcome promise ("Med AI can take you to 97% adherence"). All were hardcoded
/// constants. On a paid health app those are a Play rejection risk and, in the
/// case of the outcome claim, the category regulators scrutinise hardest.
///
/// It also had a conversion bug: the Skip link called
/// `_complete(skipPaywall: true)`, so tapping it on step 1 of 56 permanently
/// removed that session from the paywall funnel.
void main() {
  group('adherenceTarget is a goal, not a prediction', () {
    test('it moves with the user answer instead of being fixed', () {
      // The old getter returned a flat 0.97 no matter what anyone answered
      // while the copy claimed it was "based on your answers".
      final often = OnboardingController()
        ..selectSingle('miss_frequency', 'often');
      final never = OnboardingController()
        ..selectSingle('miss_frequency', 'never');

      expect(often.adherenceTarget, lessThan(never.adherenceTarget),
          reason: 'someone who misses often should not be shown the same '
              'target as someone who never misses');
    });

    test('it never promises near-perfection', () {
      // 'never' already self-reports 0.93, so the floor keeps it there rather
      // than inventing a higher number; nobody is shown a 97% promise.
      for (final answer in ['often', 'sometimes', 'rarely', 'never']) {
        final c = OnboardingController()..selectSingle('miss_frequency', answer);

        expect(c.adherenceTarget, lessThan(0.94),
            reason: '97% read as a guarantee of a clinical outcome');
      }
    });

    test('it never falls below the stated baseline', () {
      // Not strictly greater: the cap can meet the baseline for someone who
      // already reports near-perfect adherence, and offering them a *lower*
      // target than they claim is the only genuinely wrong outcome.
      for (final answer in ['often', 'sometimes', 'rarely', 'never']) {
        final c = OnboardingController()..selectSingle('miss_frequency', answer);

        expect(c.adherenceTarget, greaterThanOrEqualTo(c.inferredAdherence),
            reason: 'a target below the current baseline is not a goal');
      }
    });

    test('someone who misses often is offered real headroom', () {
      final c = OnboardingController()
        ..selectSingle('miss_frequency', 'often');

      expect(c.adherenceTarget, greaterThan(c.inferredAdherence + 0.05),
          reason: 'the plan has to be worth paying for');
    });

    test('an unanswered funnel still produces a sane target', () {
      final c = OnboardingController();

      expect(c.adherenceTarget, greaterThan(0));
      expect(c.adherenceTarget, lessThanOrEqualTo(0.92));
    });
  });

  group('claim copy', () {
    late String strings;

    setUpAll(() {
      strings = File('lib/screens/onboarding/onboarding_l10n.dart')
          .readAsStringSync();
    });

    test('no fabricated user count survives in any locale', () {
      // The figure was translated into all seven locales, so fixing only the
      // English string would have left it shipping everywhere else — which is
      // exactly what the first run of this test caught.
      //
      // Checks displayed values only. The map key still contains "500000"
      // (`ob_trustedBy500000People`); renaming it would touch every locale
      // block for no user-visible gain, and a key is never rendered.
      for (final variant in ['500,000', '500.000', '50만', '50万']) {
        expect(strings.contains(variant), isFalse,
            reason: '"$variant" asserts an install count with no source');
      }
    });

    test('the head-to-head competitor claim is gone from English', () {
      expect(strings.contains('outperforms generic pill ID apps'), isFalse,
          reason: 'an internal benchmark that cannot be produced on request is '
              'false advertising, and naming competitors invites their counsel');
    });

    test('no copy promises to take the user to an adherence number', () {
      for (final phrase in [
        'can take you to',
        'will take you to',
        'ready to take you to',
      ]) {
        expect(strings.contains(phrase), isFalse,
            reason: '"$phrase" frames a health outcome as a guarantee');
      }
    });
  });

  group('skip must not bypass the offer', () {
    test('skip no longer opts the session out of the paywall', () {
      final flow = File('lib/screens/onboarding/onboarding_flow.dart')
          .readAsStringSync();

      // The specific regression: `void _skip() => _complete(skipPaywall: true);`
      expect(
        RegExp(r'void _skip\(\)\s*=>\s*_complete\(skipPaywall:\s*true\)')
            .hasMatch(flow),
        isFalse,
        reason: 'Skip was visible from step 1 and permanently removed the user '
            'from the funnel; it should end the questions, not the offer',
      );
    });
  });

  group('mascot assets', () {
    test('every onboarding mascot is a real bundled file', () {
      // GhostMascot degrades to a plain tinted disc when an asset is missing,
      // so a typo silently reverts a screen to the generic look.
      for (final asset in ObMascots.all) {
        expect(File(asset).existsSync(), isTrue, reason: '$asset is missing');
      }
    });

    test('the beats map to distinct characters', () {
      // Reusing one mascot across every step loses the per-beat personality
      // that motivated using the set at all.
      expect(ObMascots.all.toSet().length, greaterThanOrEqualTo(8));
    });
  });
}
