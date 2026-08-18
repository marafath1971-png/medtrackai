import 'package:flutter_test/flutter_test.dart';
import 'package:medai/screens/app_shell.dart';

/// The scan action was a 44px circle inside the nav Row, between "Trends" and
/// "Alarms", captioned "Scan" in the same small grey type as the tabs beside
/// it. The app's single most important action therefore read as one of five
/// equal destinations, and 44px is under the 48dp minimum touch target.
///
/// Centring it also split the four tabs into an awkward 2 + 2. It now floats
/// free above the island's right end, where a primary action belongs and where
/// the thumb already rests.
void main() {
  group('the FAB is a primary action, not a tab', () {
    test('it clears the 48dp minimum touch target', () {
      // The old inline button was 44.
      expect(kScanFabDiameter, greaterThanOrEqualTo(48));
    });

    test('it is large enough to outrank a nav icon', () {
      // Nav icons sit around 24px; a primary action has to read as a different
      // class of control, not a slightly bigger tab.
      expect(kScanFabDiameter, greaterThan(48));
    });
  });

  group('content clearance', () {
    test('the inset covers the island and the FAB floating above it', () {
      // The FAB no longer overlaps the bar, so content must clear both or the
      // last row of a scrolled list finishes underneath the button.
      expect(kShellNavIslandInset,
          greaterThanOrEqualTo(kShellNavIslandHeight + kScanFabDiameter));
    });

    test('the island height is the value the layout actually uses', () {
      // The inset is derived from this, so a drift here silently changes the
      // clearance on every tab.
      expect(kShellNavIslandHeight, 80);
    });

    test('the inset stays a plausible bottom padding', () {
      // A runaway constant here silently eats the bottom of every tab.
      expect(kShellNavIslandInset, lessThan(200));
    });
  });
}
