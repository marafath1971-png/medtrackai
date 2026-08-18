import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medai/theme/med_ai_ui.dart';

/// The settings surface painted its cards with a hardcoded `Colors.white`
/// while every row label used `L.text`, which resolves to near-white in dark
/// mode. The result was white text on a white card: the whole screen was
/// unreadable in dark, and no test caught it because both halves were
/// individually correct.
///
/// The same pattern appeared three times — the section card, the tab track,
/// and the icon chip, which blended its tint onto white and so produced a pale
/// square invisible against a dark card.

double _luminance(Color c) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();

  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

double _contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  AppThemeColors colorsFor(Brightness b) => AppThemeColors.fromColorScheme(
        ColorScheme.fromSeed(seedColor: AppColors.accent, brightness: b),
        b,
      );

  group('settings rows are readable in both themes', () {
    for (final entry in {
      'light': Brightness.light,
      'dark': Brightness.dark,
    }.entries) {
      test('${entry.key}: label contrasts with the card', () {
        final L = colorsFor(entry.value);

        expect(_contrast(L.text, L.card), greaterThan(4.5),
            reason: 'a hardcoded white card under L.text gave a ratio near 1 '
                'in dark mode');
      });

      test('${entry.key}: the secondary line stays legible', () {
        // Subtitles carry the meaning of a toggle ("Alert when meds run low"),
        // so they need to clear the large-text minimum at least.
        final L = colorsFor(entry.value);

        expect(_contrast(L.sub, L.card), greaterThan(3.0));
      });
    }
  });

  group('no settings surface hardcodes its background', () {
    test('cards and tracks are theme-driven', () {
      for (final path in [
        'lib/screens/home/widgets/settings/settings_shared.dart',
        'lib/screens/home/widgets/settings/ios_settings_style.dart',
      ]) {
        final src = File(path).readAsStringSync();

        for (final line in src.split('\n')) {
          final t = line.trimLeft();
          if (t.startsWith('//') || t.startsWith('///')) continue;
          expect(t.contains('color: Colors.white,'), isFalse,
              reason: '$path paints a fixed white surface: "$t"');
        }
      }
    });
  });

  group('every settings row renders an icon', () {
    test('no emoji falls through to a blank chip', () {
      // iosSettingsResolveIcon maps emoji to IconData and returns null for
      // anything unlisted, which paints the chip with no glyph. Two rows —
      // Reminder Sound and Persistent Alarms — shipped as blank squares
      // because their emoji were never added to the switch.
      final style =
          File('lib/screens/home/widgets/settings/ios_settings_style.dart')
              .readAsStringSync();
      final mapped = RegExp(r"    '([^']+)' =>")
          .allMatches(style)
          .map((m) => m.group(1)!)
          .toSet();

      final used = <String, String>{};
      for (final f in Directory('lib/screens/home/widgets/settings')
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))) {
        for (final m
            in RegExp(r"icon: '([^']+)'").allMatches(f.readAsStringSync())) {
          used[m.group(1)!] = f.uri.pathSegments.last;
        }
      }

      final unmapped = used.keys.where((e) => !mapped.contains(e)).toList();

      expect(unmapped, isEmpty,
          reason: 'these emoji render no icon: '
              '${unmapped.map((e) => "$e (${used[e]})").join(", ")}');
    });
  });

  group('no screen paints a white surface under theme-driven text', () {
    test('the pattern that broke settings does not exist elsewhere', () {
      // A BoxDecoration fixed to Colors.white with L.text/L.sub drawn on it is
      // white-on-white in dark mode. Eleven of these shipped outside settings
      // — the scan result "Scan again" pill, the category chips over photos,
      // the success sheet, the safety card — each individually plausible,
      // because both halves were correct on their own.
      final offenders = <String>[];

      void walk(Directory dir) {
        for (final e in dir.listSync()) {
          if (e is Directory) {
            walk(e);
          } else if (e is File && e.path.endsWith('.dart')) {
            final src = e.readAsStringSync();
            for (final m in RegExp(
                    r'BoxDecoration\((?:[^()]|\([^()]*\))*?color:\s*Colors\.white\b',
                    dotAll: true)
                .allMatches(src)) {
              final end = (m.start + 700).clamp(0, src.length);
              final seg = src.substring(m.start, end);
              if (RegExp(r'color:\s*L\.(text|sub|onCard)\b').hasMatch(seg)) {
                offenders.add('${e.path}:${'\n'.allMatches(src.substring(0, m.start)).length + 1}');
              }
            }
          }
        }
      }

      walk(Directory('lib/screens'));
      walk(Directory('lib/widgets'));

      expect(offenders, isEmpty,
          reason: 'white surface with themed text on it:\n${offenders.join("\n")}');
    });
  });
}
