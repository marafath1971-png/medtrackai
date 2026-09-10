import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// Play reviews the hosted policy, users read the in-app one. If they drift
/// apart the app is making two different promises about the same data, which
/// is the compliance failure, not a formatting nit.
///
/// The hosted pages are generated from the Dart screens, so parity is checked
/// by section title rather than by byte: the wording lives in one place.
/// The section titles are localized, so the screens name an ARB key rather
/// than the English text. Resolve those keys against the English template so
/// this still compares the words a reader actually sees.
Map<String, String> _arb() {
  final raw = File('lib/l10n/app_en.arb').readAsStringSync();
  final decoded = jsonDecode(raw) as Map<String, dynamic>;
  return {
    for (final e in decoded.entries)
      if (!e.key.startsWith('@') && e.value is String)
        e.key: e.value as String,
  };
}

List<String> _titles(String dart) {
  final arb = _arb();
  final literal =
      RegExp(r"title:\s*'((?:[^'\\]|\\.)*)'\s*,\s*(?:body|content|text):");
  final key =
      RegExp(r"title:\s*l10n\.(\w+)\s*,\s*(?:body|content|text):");
  final out = <String>[
    for (final m in literal.allMatches(dart)) m.group(1)!.replaceAll(r"\'", "'"),
  ];
  for (final m in key.allMatches(dart)) {
    final v = arb[m.group(1)!];
    expect(v, isNotNull,
        reason: 'the screen references l10n.${m.group(1)} but app_en.arb '
            'has no such key');
    out.add(v!);
  }
  return out;
}

/// Undo the HTML entity escaping applied when the pages were generated, so a
/// title containing an apostrophe compares as text rather than as `&#x27;`.
String _unescape(String html) => html
    .replaceAll('&#x27;', "'")
    .replaceAll('&amp;', '&')
    .replaceAll('&quot;', '"')
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>');

void main() {
  final root = Directory.current.parent.path;

  group('the hosted policy matches the app', () {
    test('privacy.html exists and covers every in-app section', () {
      final page = File('$root/docs/legal/privacy.html');
      expect(page.existsSync(), isTrue,
          reason: 'Play requires a publicly reachable privacy policy');

      final html = _unescape(page.readAsStringSync());
      final titles = _titles(
          File('lib/screens/settings/privacy_policy_screen.dart')
              .readAsStringSync());

      expect(titles, isNotEmpty);
      for (final t in titles) {
        final probe = t.replaceAll(RegExp(r'^\d+\.\s*'), '').split(' ').first;
        expect(html.contains(probe), isTrue,
            reason: 'hosted policy is missing the "$t" section');
      }
    });

    test('terms.html exists and covers every in-app section', () {
      final page = File('$root/docs/legal/terms.html');
      expect(page.existsSync(), isTrue);

      final html = _unescape(page.readAsStringSync());
      final titles = _titles(
          File('lib/screens/settings/terms_of_service_screen.dart')
              .readAsStringSync());

      expect(titles, isNotEmpty);
      for (final t in titles) {
        final probe = t.replaceAll(RegExp(r'^\d+\.\s*'), '').split(' ').first;
        expect(html.contains(probe), isTrue,
            reason: 'hosted terms are missing the "$t" section');
      }
    });

    test('no unresolved Dart interpolation reached the hosted pages', () {
      for (final f in ['privacy.html', 'terms.html']) {
        final html = File('$root/docs/legal/$f').readAsStringSync();
        expect(RegExp(r'\$k[A-Za-z]').hasMatch(html), isFalse,
            reason: '$f still contains a raw Dart constant');
        expect(html.contains(r'\n'), isFalse,
            reason: '$f contains literal escape sequences');
      }
    });
  });
}
