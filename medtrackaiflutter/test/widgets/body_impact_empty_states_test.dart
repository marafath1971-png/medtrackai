import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Two defects on the medicine detail screen's "Target organs" card, both
/// reported from a real device screenshot.
///
/// 1. The body silhouette was painted in hardcoded `Colors.white` at 5%
///    opacity — a dark-theme assumption. The card renders on `L.card`, which
///    is near-white in light mode, so the entire body was invisible: only the
///    laser bar and the node chips (which carry their own colours) showed,
///    leaving an empty panel with a floating "Systemic" label.
///
/// 2. Below it, PharmaTimelineWidget rendered a *shimmering loading skeleton*
///    whenever `durationHours <= 0`. That is a terminal state, not a transient
///    one — scan_safety_mapper defaults it to 0 when the AI returns no
///    pharmacokinetics, and nothing ever fills it in. The card promised
///    "loading, wait" forever.
///
/// Asserted on source because both live deep in a detail screen that needs a
/// full AppState, router and localization graph to pump. Kept behavioural in
/// intent: the silhouette must be theme-driven, and the empty state must not
/// animate like a loader.
void main() {
  late String map;
  late String timeline;

  setUpAll(() {
    map = File('lib/widgets/biohacking/interactive_body_map.dart')
        .readAsStringSync();
    timeline = File('lib/widgets/biohacking/pharma_timeline_widget.dart')
        .readAsStringSync();
  });

  /// Code only — both fixes quote the old behaviour in explanatory comments,
  /// so a whole-file grep would match its own documentation.
  String codeOf(String src) => src
      .split('\n')
      .where((l) {
        final t = l.trimLeft();
        return !t.startsWith('//') && !t.startsWith('///');
      })
      .join('\n');

  group('the body silhouette is visible in light mode', () {
    test('it is not painted in hardcoded white', () {
      expect(codeOf(map).contains('Colors.white.withValues'), isFalse,
          reason: 'white at 5% on a near-white card is invisible; the '
              'silhouette must follow the theme');
    });

    test('the painter takes a theme colour', () {
      final code = codeOf(map);
      expect(code.contains('required this.ink'), isTrue);
      expect(code.contains('_BodySilhouettePainter(ink:'), isTrue,
          reason: 'the call site must pass the theme ink, not a constant');
    });

    test('it repaints when the theme changes', () {
      // A const-false shouldRepaint would keep the dark-mode body after a
      // theme switch.
      expect(codeOf(map).contains('oldDelegate.ink != ink'), isTrue);
    });
  });

  group('the missing-timeline state is honest', () {
    test('it does not shimmer like a loader', () {
      final code = codeOf(timeline);
      final i = code.indexOf('_buildNoDataPlaceholder');
      expect(i, greaterThan(-1));
      final body = code.substring(i, code.indexOf('Widget build(', i));

      expect(body.contains('.shimmer('), isFalse,
          reason: 'durationHours <= 0 is terminal; a shimmer promises data '
              'that will never arrive');
      expect(body.contains('repeat('), isFalse);
    });

    test('it says the data is absent', () {
      final code = codeOf(timeline);
      expect(code.contains('biohackingNoTimelineData'), isTrue,
          reason: 'the user should be told there is no timeline, not shown '
              'grey blocks');
    });

    test('the message is localized, not hardcoded English', () {
      final arb = File('lib/l10n/app_en.arb').readAsStringSync();
      expect(arb.contains('"biohackingNoTimelineData"'), isTrue);
      expect(arb.contains('"biohackingNoTimelineDataBody"'), isTrue);
    });
  });
}
