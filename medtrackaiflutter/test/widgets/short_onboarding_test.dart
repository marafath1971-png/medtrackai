import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The 56-step funnel keeps 42 screens that collect nothing the app reads —
/// including relate_forget, relate_refill, relate_mixing and relate_guilt,
/// which are the same screen four times, and three separate
/// competitor-comparison charts.
///
/// The short variant is a filter over the same steps rather than a second
/// widget tree, so both share every screen's index, analytics id and answer
/// wiring. It ships behind `onboarding_short_flow`, default off, so the long
/// funnel stays live until the short one has been measured against it.
void main() {
  late String flow;
  late List<String> names;
  late Set<int> keep;

  setUpAll(() {
    flow = File('lib/screens/onboarding/onboarding_flow.dart').readAsStringSync();

    final namesBlock =
        RegExp(r'_stepNames = \[(.*?)\];', dotAll: true).firstMatch(flow)!;
    names = RegExp(r"'([a-z_0-9]+)'")
        .allMatches(namesBlock.group(1)!)
        .map((m) => m.group(1)!)
        .toList();

    final keepBlock =
        RegExp(r'_shortFlowSteps = \{(.*?)\};', dotAll: true).firstMatch(flow)!;
    keep = RegExp(r'^\s*(\d+),', multiLine: true)
        .allMatches(keepBlock.group(1)!)
        .map((m) => int.parse(m.group(1)!))
        .toSet();
  });

  group('the short flow keeps what the app consumes', () {
    test('every answer OnboardingPrefs needs is still collected', () {
      // toPrefs() reads these; dropping one silently changes how the app is
      // configured for that user.
      for (final required in ['med_count', 'persona', 'timing']) {
        final idx = names.indexOf(required);
        expect(idx, greaterThan(-1), reason: '$required vanished from the flow');
        expect(keep.contains(idx), isTrue,
            reason: '$required feeds OnboardingPrefs and must be asked');
      }
    });

    test('the paywall headline and adherence baseline inputs survive', () {
      for (final required in ['goal', 'challenge', 'miss_frequency']) {
        expect(keep.contains(names.indexOf(required)), isTrue,
            reason: '$required drives copy the user sees later');
      }
    });

    test('it ends on the step that completes onboarding', () {
      // Simulating _next() showed the flow actually visits welcome_done: the
      // loop bound (`n < _total - 1`) stops it skipping the final index, so
      // that step renders whether or not the set names it. It is the screen
      // that calls _complete() and presents the paywall, so the set names it.
      final last = keep.reduce((a, b) => a > b ? a : b);
      expect(names[last], 'welcome_done');
      expect(keep.contains(names.indexOf('plan_ready')), isTrue);
    });

    test('walking _next() reaches the end without stalling', () {
      // The keep-set alone does not prove the flow is traversable — a gap the
      // navigation cannot cross would strand the user mid-funnel.
      const total = 56;
      var i = 0;
      final visited = <int>[0];
      var guard = 0;

      while (guard++ < total) {
        var n = i + 1;
        while (n < total - 1 && !keep.contains(n)) {
          n++;
        }
        if (n > total - 1) break;
        i = n;
        visited.add(i);
        if (i == total - 1) break;
      }

      expect(visited.last, total - 1, reason: 'the flow must reach its end');
      expect(visited.length, keep.length,
          reason: 'every kept step should be visited exactly once');
    });
  });

  group('it actually cuts', () {
    test('the four near-identical relate_* screens are gone', () {
      for (final n in names.where((n) => n.startsWith('relate_'))) {
        expect(keep.contains(names.indexOf(n)), isFalse,
            reason: '$n is the same screen as its siblings');
      }
    });

    test('the competitor charts are gone', () {
      for (final n in ['accuracy_chart', 'comparison_2x', 'comparison_organizer']) {
        expect(keep.contains(names.indexOf(n)), isFalse);
      }
    });

    test('it is roughly a fifth of the original', () {
      expect(keep.length, lessThanOrEqualTo(14));
      expect(keep.length, greaterThanOrEqualTo(10),
          reason: 'cutting below this drops an answer the app reads');
    });

    test('every kept index is a real step', () {
      for (final i in keep) {
        expect(i, lessThan(names.length));
      }
    });
  });

  group('shipping safely', () {
    test('the flag defaults off', () {
      final rc = File('lib/services/remote_config_service.dart').readAsStringSync();

      expect(rc.contains("'onboarding_short_flow': false"), isTrue,
          reason: 'the long funnel stays live until this is measured');
    });

    test('progress counts enabled steps, not all 56', () {
      // (_i + 1) / 56 would have crept to ~96% and stopped, because the short
      // flow's last step is index 53.
      expect(flow.contains('if (_isStepDisabled(i)) continue;'), isTrue);
    });
  });
}
