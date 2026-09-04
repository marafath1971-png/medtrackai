import 'dart:io';

import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:medai/theme/med_ai_ui.dart';

/// 413 ad-hoc `fontSize:` overrides had accumulated across the screens, 75 of
/// them at 10px or below — including the "Missed" and "Taken" legends on the
/// medicine history chart, which is content rather than decoration.
///
/// This app is used by people managing several medications, often older
/// adults. 10px is below what is comfortably readable for them, and the
/// existing guidance ("use instead of ad-hoc fontSize 9–11", written above
/// AppTypography.caption) was ignored 75 times because nothing enforced it.
void main() {
  // AppTypography styles are GoogleFonts calls, which touch ServicesBinding
  // to resolve a font. Without this they throw before the size can be read.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('the floor is a real minimum', () {
    test('it matches the smallest platform label size', () {
      // Material labelSmall and iOS caption2 both sit at 11.
      expect(AppTypography.minFontSize, 11);
    });

    test('the scale itself declares nothing smaller', () {
      // Reading AppTypography.caption.fontSize would need a real font load —
      // GoogleFonts hits ServicesBinding and fails in a plain unit test — so
      // this checks the declarations in source instead, which is what a
      // developer would change.
      final src = File('lib/theme/app_tokens.dart').readAsStringSync();
      final block = src.substring(src.indexOf('class AppTypography'));

      final tooSmall = RegExp(r'fontSize:\s*(\d+(?:\.\d+)?)')
          .allMatches(block)
          .map((m) => double.parse(m.group(1)!))
          .where((v) => v < 11)
          .toList();

      expect(tooSmall, isEmpty,
          reason: 'the scale must not offer a size below the floor: $tooSmall');
    });
  });

  group('no screen overrides below the floor', () {
    test('every literal fontSize is at least 11', () {
      final offenders = <String>[];

      void walk(Directory dir) {
        for (final e in dir.listSync()) {
          if (e is Directory) {
            walk(e);
          } else if (e is File && e.path.endsWith('.dart')) {
            final lines = e.readAsStringSync().split('\n');
            for (var i = 0; i < lines.length; i++) {
              final t = lines[i].trimLeft();
              if (t.startsWith('//') || t.startsWith('///')) continue;
              for (final m
                  in RegExp(r'fontSize:\s*(\d+(?:\.\d+)?)').allMatches(lines[i])) {
                final size = double.parse(m.group(1)!);
                if (size < AppTypography.minFontSize) {
                  offenders.add('${e.path}:${i + 1} -> ${m.group(1)}');
                }
              }
            }
          }
        }
      }

      walk(Directory('lib/screens'));
      walk(Directory('lib/widgets'));

      expect(offenders, isEmpty,
          reason: 'text below ${AppTypography.minFontSize}px is not reliably '
              'readable for this app\'s users:\n${offenders.join("\n")}');
    });
  });

  group('weight stays legible at small sizes', () {
    test('nothing sets w900 on text 13px or smaller', () {
      // Nineteen w900 overrides sat at 11-13px — the heaviest weight at the
      // smallest size, where Outfit's counters close up and the text reads as
      // a smudge rather than words.
      //
      // Only w900 is barred. w800 at 11px is deliberate in places: the
      // settings tab strip uses w800 for the selected item against w600 for
      // the rest, so the weight carries state. Banning it would delete a
      // signal rather than fix a defect.
      final offenders = <String>[];

      void walk(Directory dir) {
        for (final e in dir.listSync()) {
          if (e is Directory) {
            walk(e);
          } else if (e is File && e.path.endsWith('.dart')) {
            final lines = e.readAsStringSync().split('\n');
            for (var i = 0; i < lines.length; i++) {
              if (!lines[i].contains('FontWeight.w900')) continue;
              final t = lines[i].trimLeft();
              if (t.startsWith('//') || t.startsWith('///')) continue;

              final lo = (i - 4).clamp(0, lines.length);
              final hi = (i + 5).clamp(0, lines.length);
              final window = lines.sublist(lo, hi).join('\n');
              final m = RegExp(r'fontSize:\s*(\d+(?:\.\d+)?)').firstMatch(window);
              if (m != null &&
                  double.parse(m.group(1)!) <= AppTypography.smallTextCeiling) {
                offenders.add('${e.path}:${i + 1} (${m.group(1)}px)');
              }
            }
          }
        }
      }

      walk(Directory('lib/screens'));
      walk(Directory('lib/widgets'));

      expect(offenders, isEmpty,
          reason: 'heavy weight on small text is hard to read:\n'
              '${offenders.join("\n")}');
    });

    test('the cap is below the heaviest available weight', () {
      // A cap equal to w900 would not be a cap.
      expect(AppTypography.maxWeightAtSmallSize.index,
          lessThan(FontWeight.w900.index));
    });
  });

  group('weight carries hierarchy', () {
    test('heavy weight is the exception, not the default', () {
      // Before: w800 was the single most common weight at 319 uses, against a
      // scale that declares it twice. When most text is extra-bold, weight
      // stops signalling importance — everything shouts, so nothing does.
      final counts = <String, int>{};

      void walk(Directory dir) {
        for (final e in dir.listSync()) {
          if (e is Directory) {
            walk(e);
          } else if (e is File && e.path.endsWith('.dart')) {
            for (final line in e.readAsStringSync().split('\n')) {
              if (line.trimLeft().startsWith('//')) continue;
              for (final m
                  in RegExp(r'FontWeight\.(w\d00)').allMatches(line)) {
                counts[m.group(1)!] = (counts[m.group(1)] ?? 0) + 1;
              }
            }
          }
        }
      }

      walk(Directory('lib/screens'));
      walk(Directory('lib/widgets'));

      final heavy = (counts['w800'] ?? 0) + (counts['w900'] ?? 0);
      final total = counts.values.fold(0, (a, b) => a + b);

      expect(heavy / total, lessThan(0.25),
          reason: 'heavy weights are ${(heavy / total * 100).round()}% of all '
              'weight declarations ($counts) — emphasis only reads as emphasis '
              'while most text is lighter than it');
    });

    test('the scale defaults match how screens actually use it', () {
      // titleMedium shipped at w500 and 54 of its 123 call sites overrode to
      // w800, jumping two steps because the default was wrong for a title
      // sitting above body text. A default nobody accepts is not a default.
      final src = File('lib/theme/app_tokens.dart').readAsStringSync();

      for (final style in ['titleMedium', 'labelMedium']) {
        final i = src.indexOf('get $style =>');
        expect(i, greaterThan(-1));
        final block = src.substring(i, (i + 400).clamp(0, src.length));
        expect(block.contains('FontWeight.w600'), isTrue,
            reason: '$style should default to the weight its callers wanted');
      }
    });
  });
}
