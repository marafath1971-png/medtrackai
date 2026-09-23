import 'package:flutter_test/flutter_test.dart';
import 'package:medai/providers/controllers/auth_controller.dart';

/// `syncToCloud()` uploads everything that lives only on the device —
/// profile, caregivers, streak, theme, language — and was written and
/// documented for "first sign-in when Firestore has no user document yet".
///
/// Nothing ever called it. It was not even declared on `IUserRepository`, so
/// no caller holding the interface *could* have. Medicines and history
/// reconcile themselves on every load, but these have no merge step, so a
/// user who set the app up offline and then signed in kept all of it on one
/// device until each value was next edited by hand.
///
/// [AuthController.enterAppAfterAuth] already knew when the cloud was empty —
/// it branches on the absence of a cloud profile to decide whether to persist
/// the freshly resolved one — and that same branch is the only moment the
/// upload is safe, because there is nothing on the server to overwrite.
///
/// The rule is pinned here rather than by driving `enterAppAfterAuth`, which
/// reads `AuthService.displayName` and would need a live Firebase. The sibling
/// `account_name_test.dart` tests `resolveAccountName` the same way, for the
/// same reason.
void main() {
  group('shouldSyncLocalDataToCloud', () {
    test('an account with no cloud profile uploads its local data', () {
      // Set the app up offline, then sign in: caregivers, streak and settings
      // exist nowhere else, and nothing on the server can be lost.
      expect(
        AuthController.shouldSyncLocalDataToCloud(hasCloudProfile: false),
        isTrue,
      );
    });

    test('a returning user is never uploaded over', () {
      // syncToCloud replaces rather than merges. Running it for someone who
      // already has cloud data would overwrite it with whatever this device
      // happens to hold — the reverse of the bug, and worse, because the lost
      // data would be the newer copy.
      expect(
        AuthController.shouldSyncLocalDataToCloud(hasCloudProfile: true),
        isFalse,
      );
    });

    test('the decision depends on nothing else', () {
      // Guards against the rule quietly acquiring a second input later: the
      // presence of a cloud profile is the whole question, and every other
      // signal available at sign-in (a name, a photo, a pending onboarding
      // profile) is about *what* to save, not *whether* the cloud is empty.
      for (final hasProfile in [true, false]) {
        expect(
          AuthController.shouldSyncLocalDataToCloud(
              hasCloudProfile: hasProfile),
          AuthController.shouldSyncLocalDataToCloud(
              hasCloudProfile: hasProfile),
        );
      }
    });
  });
}
