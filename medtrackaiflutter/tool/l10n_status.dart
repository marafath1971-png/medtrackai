// Reports localization progress.
//
//   dart tool/l10n_status.dart              # summary
//   dart tool/l10n_status.dart --untranslated   # keys still showing English
//   dart tool/l10n_status.dart --hardcoded      # user-facing strings not yet extracted
//
// "Untranslated" means a locale's value is byte-identical to the English one.
// That is a heuristic — a few short strings legitimately match across languages
// (e.g. "OK") — but for this app it reliably finds the placeholders that were
// added in English and still need a real translation.

import 'dart:convert';
import 'dart:io';

const _locales = ['es', 'ar', 'he', 'ja', 'ko', 'ms'];

void main(List<String> args) {
  final root = Directory.current.path;
  final en = _load('$root/lib/l10n/app_en.arb');

  final keys = en.keys.where((k) => !k.startsWith('@')).toList();

  if (args.contains('--hardcoded')) {
    _reportHardcoded(root);
    return;
  }

  print('English keys: ${keys.length}\n');

  final untranslatedByLocale = <String, List<String>>{};
  for (final loc in _locales) {
    final data = _load('$root/lib/l10n/app_$loc.arb');
    final missing = <String>[];
    final same = <String>[];
    for (final k in keys) {
      if (!data.containsKey(k)) {
        missing.add(k);
      } else if (data[k] == en[k] && (en[k] as String).length > 3) {
        same.add(k);
      }
    }
    untranslatedByLocale[loc] = [...missing, ...same];
    final done = keys.length - missing.length - same.length;
    final pct = (done / keys.length * 100).toStringAsFixed(0);
    print('  $loc  $done/${keys.length}  ($pct%)'
        '${missing.isEmpty ? '' : '  ${missing.length} missing'}'
        '${same.isEmpty ? '' : '  ${same.length} still English'}');
  }

  if (args.contains('--untranslated')) {
    for (final loc in _locales) {
      final list = untranslatedByLocale[loc]!;
      if (list.isEmpty) continue;
      print('\n$loc needs:');
      for (final k in list) {
        print('  $k = ${jsonEncode(en[k])}');
      }
    }
  } else {
    print('\nRun with --untranslated to list the keys, '
        'or --hardcoded to find strings not yet extracted.');
  }
}

Map<String, dynamic> _load(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

/// Rough scan for user-facing literals still hardcoded in the UI. Skips things
/// that are clearly not display copy: asset paths, keys, single words used as
/// enum-ish values, and anything inside a debug/log call.
void _reportHardcoded(String root) {
  final dirs = [
    Directory('$root/lib/screens'),
    Directory('$root/lib/widgets'),
  ];
  final literal = RegExp(r"'([A-Z][a-z][^']{4,60})'");
  final skip = RegExp(
      r'assets/|\.png|\.jpg|\.svg|appLogger|debugPrint|print\(|Icons\.|Key\(|"\$');

  final hits = <String, int>{};
  for (final dir in dirs) {
    if (!dir.existsSync()) continue;
    for (final f in dir.listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart')) continue;
      for (final line in f.readAsLinesSync()) {
        if (skip.hasMatch(line)) continue;
        for (final m in literal.allMatches(line)) {
          hits[m.group(1)!] = (hits[m.group(1)] ?? 0) + 1;
        }
      }
    }
  }

  final sorted = hits.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  print('Hardcoded user-facing strings (top 40 by occurrence):\n');
  for (final e in sorted.take(40)) {
    print('  ${e.value.toString().padLeft(3)}x  ${e.key}');
  }
  print('\nTotal distinct: ${hits.length}');
}
