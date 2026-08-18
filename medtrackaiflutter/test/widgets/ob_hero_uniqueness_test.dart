import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:medai/core/constants/premium_photos.dart';

/// Seven onboarding screens showed hero photos drawn from only four scenes, so
/// the same pill-bottle shot appeared three times and the sunset-yoga and
/// vaccination shots twice each — while sixteen bundled photos went unused.
///
/// Repetition inside a single run reads as a rendering fault rather than a
/// design choice, and it undercuts a flow whose whole pitch is that it is
/// personalised to the person answering.
void main() {
  late String flow;

  setUpAll(() {
    flow = File('lib/screens/onboarding/onboarding_flow.dart').readAsStringSync();
  });

  test('no hero scene is used twice in the funnel', () {
    final uses = RegExp(r'ObHeroScene\.(\w+)')
        .allMatches(flow)
        .map((m) => m.group(1)!)
        .toList();

    expect(uses, isNotEmpty, reason: 'the hero screens should still exist');

    final duplicated = <String>{};
    final seen = <String>{};
    for (final u in uses) {
      if (!seen.add(u)) duplicated.add(u);
    }

    expect(duplicated, isEmpty,
        reason: 'a user meets every one of these screens in a single run, so a '
            'repeated photo is visible as a mistake');
  });

  test('every scene resolves to a photo that is actually bundled', () {
    // A missing asset renders as a broken box behind the headline, and the
    // scene enum cannot catch that on its own.
    for (final asset in [
      PremiumPhotos.know,
      PremiumPhotos.thrive,
      PremiumPhotos.family,
      PremiumPhotos.scanFeature,
      PremiumPhotos.routine,
      PremiumPhotos.scanHow,
      PremiumPhotos.finish,
    ]) {
      expect(File(asset).existsSync(), isTrue, reason: '$asset is missing');
    }
  });

  test('the scenes map to distinct files', () {
    // Two enum values pointing at one asset would pass the uniqueness check
    // above while still showing the user the same picture twice.
    final assets = {
      PremiumPhotos.know,
      PremiumPhotos.thrive,
      PremiumPhotos.family,
      PremiumPhotos.scanFeature,
      PremiumPhotos.routine,
      PremiumPhotos.scanHow,
      PremiumPhotos.finish,
    };

    expect(assets.length, 7,
        reason: 'distinct scenes must not share an underlying photo');
  });
}
