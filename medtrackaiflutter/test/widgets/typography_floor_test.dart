import 'dart:io';

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
}
