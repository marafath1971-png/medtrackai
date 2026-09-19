import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Anything listed under `flutter: assets:` is copied verbatim into the built
/// app, so a secret in one of those files is extractable from the artifact by
/// anyone who downloads it. `.env` is on that list.
///
/// GEMINI_API_KEY lived there. A `kDebugMode` check stopped release builds
/// *using* it, which is why this survived review — the guard was on the wrong
/// verb. Carrying the key is the leak; using it is not.
///
/// This walks the declared asset list and fails on anything that looks like a
/// live credential. Secrets belong in Secret Manager (server side) or in
/// `--dart-define` (compile-time, never written into the bundle).

/// Keys whose values are secret. Client *identifiers* are deliberately absent:
/// OAuth client ids and Firebase app ids are public by design.
const _secretKeyPattern =
    r'(API_KEY|APIKEY|SECRET|TOKEN|PASSWORD|PRIVATE_KEY|ACCESS_KEY)';

/// Values that are placeholders rather than real credentials.
bool _isPlaceholder(String v) {
  final s = v.trim().toLowerCase();
  if (s.isEmpty) return true;
  return s.contains('your_') ||
      s.contains('placeholder') ||
      s.contains('changeme') ||
      s.contains('demo') ||
      s.contains('dummy') ||
      s.contains('example') ||
      s.contains('<') ||
      s == 'null';
}

/// Reads the `flutter: assets:` list out of pubspec.yaml.
///
/// Parsed by hand rather than with package:yaml, which this project only has
/// transitively — importing it directly would leave this test at the mercy of
/// an unrelated dependency bump.
List<String> _declaredAssetEntries() {
  final lines = File('pubspec.yaml').readAsLinesSync();
  final out = <String>[];
  var inAssets = false;

  for (final line in lines) {
    if (RegExp(r'^\s{2}assets:\s*$').hasMatch(line)) {
      inAssets = true;
      continue;
    }
    if (!inAssets) continue;

    final item = RegExp(r'^\s+-\s+(\S+)\s*$').firstMatch(line);
    if (item != null) {
      out.add(item.group(1)!);
      continue;
    }
    // A non-list, non-blank line ends the block.
    if (line.trim().isNotEmpty) break;
  }
  return out;
}

/// Every file that ships, expanding `dir/` entries one level as Flutter does.
List<File> _bundledFiles() {
  final out = <File>[];
  for (final entry in _declaredAssetEntries()) {
    if (entry.endsWith('/')) {
      final dir = Directory(entry);
      if (!dir.existsSync()) continue;
      out.addAll(dir.listSync().whereType<File>());
    } else {
      final f = File(entry);
      if (f.existsSync()) out.add(f);
    }
  }
  return out;
}

void main() {
  test('no bundled asset carries a live secret', () {
    final pattern = RegExp('^\\s*([A-Za-z0-9_]*$_secretKeyPattern[A-Za-z0-9_]*)'
        r'\s*[=:]\s*(.+)$');
    final offenders = <String>[];

    for (final file in _bundledFiles()) {
      // Only text-shaped config files can be scanned meaningfully.
      const scannable = ['.env', '.json', '.yaml', '.yml', '.properties', '.txt'];
      final name = file.path.split('/').last;
      final isEnv = name == '.env' || name.startsWith('.env');
      if (!isEnv && !scannable.any((e) => file.path.endsWith(e))) continue;

      late final List<String> lines;
      try {
        lines = file.readAsLinesSync();
      } on FileSystemException {
        continue; // binary or unreadable — nothing to assert
      }

      for (final line in lines) {
        if (line.trimLeft().startsWith('#')) continue;
        final m = pattern.firstMatch(line);
        if (m == null) continue;
        final key = m.group(1)!;
        final value = m.group(3)!;
        if (_isPlaceholder(value)) continue;
        offenders.add('${file.path}: $key');
      }
    }

    expect(offenders, isEmpty,
        reason: 'these bundled assets carry live secrets and would ship inside '
            'the app, extractable from the artifact:\n  ${offenders.join('\n  ')}\n'
            'Move the value to Secret Manager (server side) or pass it with '
            '--dart-define, which is never written into the bundle.');
  });

  test('the asset list is actually being read', () {
    // If the pubspec parser silently returned nothing, every other assertion
    // here would pass while scanning zero files.
    final entries = _declaredAssetEntries();

    expect(entries, isNotEmpty,
        reason: 'could not read `flutter: assets:` out of pubspec.yaml');
    expect(entries, contains('.env'),
        reason: '.env is the asset this guard exists for; if it stopped being '
            'bundled that is good news, but update this test deliberately');
  });

  test('the scanner actually detects a planted secret', () {
    // A guard that cannot fail is worse than none: it reads as coverage.
    final pattern = RegExp('^\\s*([A-Za-z0-9_]*$_secretKeyPattern[A-Za-z0-9_]*)'
        r'\s*[=:]\s*(.+)$');

    final planted = pattern.firstMatch('GEMINI_API_KEY=AQ.Ab8RN6JmLiveLooking');
    expect(planted, isNotNull, reason: 'pattern must match a real key line');
    expect(_isPlaceholder(planted!.group(3)!), isFalse,
        reason: 'a real-looking value must not be dismissed as a placeholder');

    // And the inverse: the documented placeholder form is ignored.
    final ph = pattern.firstMatch('GEMINI_API_KEY=your_key_here');
    expect(_isPlaceholder(ph!.group(3)!), isTrue);
  });

  test('client identifiers are not treated as secrets', () {
    // OAuth client ids and Firebase app ids are public by design; flagging
    // them would train people to ignore this test.
    final pattern = RegExp('^\\s*([A-Za-z0-9_]*$_secretKeyPattern[A-Za-z0-9_]*)'
        r'\s*[=:]\s*(.+)$');
    expect(pattern.firstMatch('GOOGLE_WEB_CLIENT_ID=8830051234-abc.apps.googleusercontent.com'),
        isNull);
  });
}
