import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// A scanned medicine stores the captured photo's *filesystem path* in
/// `imageUrl` — pill_identifier_screen writes `capturedImage?.path`, and
/// capturedImage is a `File`. So any renderer that assumes an http URL cannot
/// load it.
///
/// The medicine detail hero used a bare `Image.network(med.imageUrl!)`. It
/// failed into its errorBuilder and drew the category icon, which reads as
/// "this medicine has no photo" rather than "the photo failed to load" — while
/// the very same medicine showed its thumbnail correctly on the home card,
/// because that card already used MedImage. That split is what made it
/// visible.
///
/// MedImage branches on the value: empty -> placeholder, http -> network,
/// assets/ -> asset, otherwise -> File. These pin that the detail screen keeps
/// using it, and that the scan still writes a path rather than a URL.
void main() {
  late String detail;

  setUpAll(() {
    detail = File('lib/screens/medicine/medicine_detail_screen.dart')
        .readAsStringSync();
  });

  /// Code only — the fix carries a comment quoting the old call, so a
  /// whole-file grep would match its own documentation.
  String codeOf(String src) => src
      .split('\n')
      .where((l) {
        final t = l.trimLeft();
        return !t.startsWith('//') && !t.startsWith('///');
      })
      .join('\n');

  group('the medicine detail hero renders local photos', () {
    test('it does not hand a local path to a network-only loader', () {
      expect(codeOf(detail).contains('Image.network'), isFalse,
          reason: 'imageUrl is a filesystem path for scanned medicines; '
              'Image.network silently degrades to the category icon');
    });

    test('it renders through the path-aware loader', () {
      expect(codeOf(detail).contains('MedImage('), isTrue);
    });

    test('the category-icon fallback survives as the placeholder', () {
      // Losing this would replace a considered empty state with MedImage's
      // generic broken-image glyph.
      final code = codeOf(detail);
      final i = code.indexOf('MedImage(');
      expect(i, greaterThan(-1));
      expect(code.substring(i, i + 400).contains('_categoryIcon'), isTrue,
          reason: 'the hero had a category-specific empty state; keep it');
    });
  });

  group('the scan still stores a path, not a URL', () {
    test('pill_identifier writes capturedImage.path into imageUrl', () {
      final scan = File('lib/screens/scan/pill_identifier_screen.dart')
          .readAsStringSync();

      expect(scan.contains('imageUrl: capturedImage?.path'), isTrue,
          reason: 'if this ever becomes an uploaded URL the renderer choice '
              'should be revisited deliberately, not silently');
    });
  });
}
