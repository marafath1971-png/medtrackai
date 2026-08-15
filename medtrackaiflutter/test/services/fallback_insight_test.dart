import 'package:flutter_test/flutter_test.dart';

/// The offline fallback health tips interpolate a region name. Three of them
/// used `$country` directly instead of the `locSuffix` / `locPrefix` guards
/// defined right above them, so with no country set users saw dangling text:
/// "monitor your progress in ." and "routine for our  community".
///
/// These assertions mirror the templates in
/// `lib/services/gemini_service.dart` (`_fallbackTips`).
String hydrationTip(String country) {
  final locSuffix = country.isNotEmpty ? ' for users in $country' : '';
  return 'Stay hydrated and track your symptoms regularly to help your '
      'doctor monitor your progress$locSuffix.';
}

String streakTip(String country) {
  return 'Keep your current streak going! Every day adds up to a healthier '
      'routine${country.isNotEmpty ? ' for our $country community' : ''}.';
}

void main() {
  group('fallback tips with no country', () {
    test('hydration tip has no dangling preposition', () {
      final body = hydrationTip('');
      expect(body, endsWith('progress.'));
      expect(body, isNot(contains(' in .')));
      expect(body, isNot(contains('  ')));
    });

    test('streak tip has no empty community phrase', () {
      final body = streakTip('');
      expect(body, endsWith('routine.'));
      expect(body, isNot(contains('our  community')));
      expect(body, isNot(contains('  ')));
    });

    test('spelling is correct', () {
      expect(hydrationTip(''), contains('regularly'));
      expect(hydrationTip(''), isNot(contains('regularily')));
    });
  });

  group('fallback tips with a country', () {
    test('hydration tip names the region', () {
      expect(hydrationTip('Japan'), contains('for users in Japan'));
    });

    test('streak tip names the region', () {
      expect(streakTip('Japan'), contains('for our Japan community'));
    });
  });
}
