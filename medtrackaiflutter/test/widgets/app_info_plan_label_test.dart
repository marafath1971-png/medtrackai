import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The App Info row asserted the user's plan instead of checking it.
///
/// It read `'Version 2.0 · Premium Enabled'` as a constant, so a free account
/// was told it was premium — on the very screen whose Biometric Lock toggle
/// then opened the paywall when tapped. The version was fabricated too:
/// pubspec says 1.0.0+1, the row claimed 2.0.
///
/// Asserted on the source because the row is buried in a settings tree that
/// needs a full AppState, Provider graph and localization delegates to pump.
/// Kept narrow and behavioural in intent: the label must be *derived*, and the
/// fabricated strings must not come back.
void main() {
  late String src;

  /// Code only. The fix carries a comment quoting the old fabricated string to
  /// explain what it replaced, so a whole-file grep matches its own
  /// documentation and fails against correct code.
  late String code;

  setUpAll(() {
    src = File('lib/screens/home/widgets/settings/app_tab.dart')
        .readAsStringSync();
    code = src.split('\n').where((l) {
      final t = l.trimLeft();
      return !t.startsWith('//') && !t.startsWith('///');
    }).join('\n');
  });

  group('the App Info row reports the real plan', () {
    test('the fabricated constant is gone', () {
      expect(code.contains('Premium Enabled'), isFalse,
          reason: 'a hardcoded plan claim tells a free user they are premium');
      expect(code.contains('Version 2.0'), isFalse,
          reason: 'pubspec is 1.0.0+1; "Version 2.0" was invented');
    });

    test('the plan is read from isPremium, not asserted', () {
      expect(src.contains('s.isPremium'), isTrue,
          reason: 'the label must be derived from the same flag that gates '
              'the paywall, or the two can disagree');
    });

    test('the version comes from the shared constant', () {
      // kAppVersion lives in models/constants.dart and is already what
      // global_settings_screen renders. A second literal would drift.
      expect(src.contains(r'$kAppVersion'), isTrue);
      expect(src.contains('models/constants.dart'), isTrue,
          reason: 'the constant has to actually be imported');
    });

    test('both plan states are represented', () {
      expect(src.contains('Free plan'), isTrue,
          reason: 'a non-premium account needs an honest label, not silence');
    });
  });

  group('the shared version constant matches pubspec', () {
    test('kAppVersion is not drifting from the manifest', () {
      final constants = File('lib/models/constants.dart').readAsStringSync();
      final m = RegExp(r"kAppVersion = '([^']+)'").firstMatch(constants);
      expect(m, isNotNull);
      final declared = m!.group(1)!;

      final pubspec = File('pubspec.yaml').readAsStringSync();
      final pm =
          RegExp(r'^version:\s*([0-9.]+)', multiLine: true).firstMatch(pubspec);
      expect(pm, isNotNull);

      expect(declared, pm!.group(1),
          reason: 'the version shown in Settings must match the build');
    });
  });
}
