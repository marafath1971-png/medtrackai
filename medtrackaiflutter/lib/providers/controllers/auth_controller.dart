import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/user_repository.dart';
import '../../models/onboarding_prefs.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/haptic_engine.dart';

class AuthController extends ChangeNotifier {
  final IUserRepository userRepo;

  AppPhase _phase = AppPhase.loading;
  UserProfile? _profileValue;

  /// Single funnel for profile writes so device-level side effects (currently
  /// the [HapticEngine] kill switch) stay in sync with the stored preference.
  /// A null profile (logout / deletion) restores the default-on behaviour.
  UserProfile? get _profile => _profileValue;
  set _profile(UserProfile? p) {
    _profileValue = p;
    HapticEngine.isEnabled = p?.hapticsEnabled ?? true;
    // Refill alerts fire from MedicationController, which cannot see the
    // profile, so the preference is mirrored onto the service here. Without
    // this the Settings toggle was decorative: notifRefill was written and
    // read back but never consulted before posting an alert.
    NotificationService.refillAlertsEnabled = p?.notifRefill ?? true;
  }
  bool _isLocked = false;
  String _language = 'en';
  bool _isPurchasing = false;
  OnboardingPrefs _onboardingPrefs = const OnboardingPrefs();

  /// Profile built from onboarding answers, held until the user authenticates.
  /// Persisted under the real uid in [enterAppAfterAuth] for new accounts.
  UserProfile? _pendingOnboardingProfile;

  AuthController({required this.userRepo});

  /// Stash the onboarding-built profile so it can be saved once the user
  /// signs in (we only have a real uid to save under after auth).
  void setPendingOnboardingProfile(UserProfile p) {
    _pendingOnboardingProfile = p;
  }

  /// The signed-in account's name, or null if it cannot be determined.
  String? _accountDisplayName() =>
      resolveAccountName(AuthService.displayName, AuthService.email);

  /// Derives a greeting name from what the auth provider gave us.
  ///
  /// Static and pure so the fallback order is testable without Firebase.
  /// Google and Apple sign-in populate [displayName]; email sign-up often does
  /// not, so the local part of the address is used as a last resort — but only
  /// when it reads like a name. "j.smith" becomes "J Smith"; "user1234" and
  /// "no-reply" are rejected, because a wrong name is worse than none.
  @visibleForTesting
  static String? resolveAccountName(String? displayName, String? email) {
    final dn = displayName?.trim();
    if (dn != null && dn.isNotEmpty) {
      // Providers sometimes return the full address as the display name.
      if (!dn.contains('@')) return dn;
    }

    final local = email?.trim().split('@').first ?? '';
    if (local.isEmpty || local.length < 2) return null;

    // Reject anything carrying digits at all: real names do not contain them,
    // and "user1234" -> "User1234" is a worse greeting than none. An earlier
    // version allowed up to half the characters to be digits, which let
    // user1234@ through because four of eight is not "more than half".
    if (RegExp(r'\d').hasMatch(local)) return null;
    if (RegExp(r'^(no-?reply|admin|info|support|contact|test)$',
            caseSensitive: false)
        .hasMatch(local)) {
      return null;
    }

    // "j.smith" / "jane_doe" / "jane-doe" -> "J Smith" / "Jane Doe".
    final parts =
        local.split(RegExp(r'[._\-+]')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return null;

    return parts
        .map((p) => p[0].toUpperCase() + p.substring(1).toLowerCase())
        .join(' ');
  }

  /// Called after a successful sign-in / sign-up. Returning users (a cloud
  /// profile already exists) resume with it untouched; brand-new users get the
  /// onboarding-built profile persisted. Either way we land in [AppPhase.app]
  /// with a non-null profile, so the app shell never renders profile-less.
  Future<void> enterAppAfterAuth() async {
    UserProfile? existing;
    try {
      existing = await userRepo.getProfile();
    } catch (e) {
      appLogger.w('[AuthController] getProfile after auth failed: $e');
    }
    // Fall back to the signed-in account's own name before giving up on one.
    //
    // A brand-new user with no onboarding name previously landed on
    // `UserProfile(name: '')`, so every greeting read "Good evening, there"
    // even though Firebase already knew who they were: Google and Apple sign-in
    // both populate displayName, and email sign-up carries one whenever the
    // user supplied it. Only the local part of an email is used as a last
    // resort — showing a full address as someone's name is worse than "there".
    final accountName = _accountDisplayName();
    var resolved = existing ?? _pendingOnboardingProfile ?? UserProfile(name: '');
    if (resolved.name.trim().isEmpty && accountName != null) {
      resolved = resolved.copyWith(name: accountName);
    }
    // Same gap as the name: UserProfile.photoUrl existed, the profile screen
    // rendered it, AuthService.photoUrl exposed it — and nothing ever assigned
    // one, so every user fell back to an initial on a coloured disc even after
    // signing in with a Google account that has a picture.
    final accountPhoto = AuthService.photoUrl?.trim();
    if ((resolved.photoUrl == null || resolved.photoUrl!.isEmpty) &&
        accountPhoto != null &&
        accountPhoto.isNotEmpty) {
      resolved = resolved.copyWith(photoUrl: accountPhoto);
    }
    _profile = resolved;
    if (resolved.preferredLanguage.isNotEmpty) {
      _language = resolved.preferredLanguage;
    }
    // Only persist for new accounts — never overwrite a returning user's data.
    if (existing == null) {
      try {
        await userRepo.saveProfile(resolved);
      } catch (e) {
        appLogger.e('[AuthController] saveProfile after auth failed: $e');
      }
    }
    _pendingOnboardingProfile = null;
    _isLocked = resolved.biometricEnabled;
    _phase = AppPhase.app;
    notifyListeners();
  }

  OnboardingPrefs get onboardingPrefs => _onboardingPrefs;

  AppPhase get phase => _phase;
  set phase(AppPhase p) {
    _phase = p;
    notifyListeners();
  }

  UserProfile? get profile => _profile;
  set profile(UserProfile? p) {
    _profile = p;
    notifyListeners();
  }

  bool get isLocked => _isLocked;
  set isLocked(bool v) {
    _isLocked = v;
    notifyListeners();
  }

  String get language => _language;
  bool get darkMode => _profile?.amoledMode ?? false;

  bool get isPurchasing => _isPurchasing;
  set isPurchasing(bool v) {
    _isPurchasing = v;
    notifyListeners();
  }

  bool get isAuthenticated => AuthService.uid != null;

  Future<void> loadProfile() async {
    try {
      await _loadOnboardingPrefs();
      _profile = await userRepo.getProfile();
      _language = await userRepo.getLanguage();
      if (_profile != null) {
        _phase = AppPhase.app;
        _isLocked = _profile?.biometricEnabled ?? false;
      } else {
        _phase = AppPhase.onboarding;
      }
      notifyListeners();
    } catch (e) {
      appLogger.e('[AuthController] Profile load failed', error: e);
      _phase = AppPhase.onboarding;
      notifyListeners();
    }
  }

  Future<void> _loadOnboardingPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _onboardingPrefs = OnboardingPrefs.fromMap({
        OnboardingPrefs.storageKeyMedCount:
            prefs.getString(OnboardingPrefs.storageKeyMedCount) ?? '1-2',
        OnboardingPrefs.storageKeyRole:
            prefs.getString(OnboardingPrefs.storageKeyRole) ?? 'self',
        OnboardingPrefs.storageKeySchedule:
            prefs.getString(OnboardingPrefs.storageKeySchedule) ?? 'morning',
        OnboardingPrefs.storageKeyReminderIntensity:
            prefs.getString(OnboardingPrefs.storageKeyReminderIntensity) ??
                'normal',
      });
    } catch (e) {
      appLogger.w('[AuthController] Failed to hydrate onboarding prefs: $e');
    }
  }

  Future<void> saveOnboardingPrefs(OnboardingPrefs prefs) async {
    _onboardingPrefs = prefs;
    final sp = await SharedPreferences.getInstance();
    for (final entry in prefs.toMap().entries) {
      await sp.setString(entry.key, entry.value);
    }
    notifyListeners();
  }

  Future<void> markOnboardingCompleted() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(OnboardingPrefs.storageKeyCompleted, true);
  }

  Future<void> updateProfileFromMap(Map<String, dynamic> data) async {
    if (_profile == null) return;
    final updated = _profile!.copyWith(
      name: data['name'] ?? _profile!.name,
      // mapping logic simplified just for stability
    );
    await saveProfile(updated);
  }

  Future<void> saveProfile(UserProfile p) async {
    _profile = p;
    _phase = AppPhase.app;
    if (p.preferredLanguage != _language) {
      _language = p.preferredLanguage;
      await userRepo.saveLanguage(_language);
    }
    await userRepo.saveProfile(p);
    notifyListeners();
  }

  void incrementScanCount() {
    if (_profile == null) return;
    _profile = _profile!.copyWith(
      scansUsed: (_profile!.scansUsed) + 1,
    );
    userRepo.saveProfile(_profile!);
    notifyListeners();
  }

  void incrementVoiceLogCount() {
    if (_profile == null) return;
    _profile = _profile!.copyWith(
      voiceLogsUsed: (_profile!.voiceLogsUsed) + 1,
    );
    userRepo.saveProfile(_profile!);
    notifyListeners();
  }

  Future<void> logout() async {
    await AuthService.signOut();
    _profile = null;
    _phase = AppPhase.auth;
    notifyListeners();
  }

  Future<void> completeOnboarding(UserProfile profile) async {
    _profile = profile;
    _phase = AppPhase.app;
    await userRepo.saveProfile(profile);
    notifyListeners();
  }

  void skipAuth() {
    _phase = AppPhase.app;
    notifyListeners();
  }

  /// DEV PREVIEW ONLY — sets a transient demo profile and jumps to the app
  /// without persisting. Used to review redesigned screens.
  void devPreview(UserProfile p) {
    _profile = p;
    _phase = AppPhase.app;
    notifyListeners();
  }

  void skipAuthOnboarding() {
    _phase = AppPhase.onboarding;
    notifyListeners();
  }

  Future<void> updateProfile(
      {String? name,
      String? accentColor,
      bool? amoledMode,
      bool? biometricEnabled}) async {
    if (_profile == null) return;
    _profile = _profile!.copyWith(
      name: name ?? _profile!.name,
      accentColor: accentColor ?? _profile!.accentColor,
      amoledMode: amoledMode ?? _profile!.amoledMode,
      biometricEnabled: biometricEnabled ?? _profile!.biometricEnabled,
    );
    await userRepo.saveProfile(_profile!);
    notifyListeners();
  }

  void toggleDarkMode() {
    if (_profile == null) return;
    updateProfile(amoledMode: !(_profile!.amoledMode));
  }

  void toggleBiometricLock(bool v) {
    if (_profile == null) return;
    updateProfile(biometricEnabled: v);
  }

  Future<void> manageSubscription() async {
    // Bridge to platform-specific store logic if needed
    appLogger.i('[Auth] Opening subscription management');
  }

  Future<void> signInWithGoogle() async {
    final user = await AuthService.signInWithGoogle();
    if (user != null) await loadProfile();
  }

  Future<void> signInWithApple() async {
    final user = await AuthService.signInWithApple();
    if (user != null) await loadProfile();
  }

  Future<void> updateAccentColor(String color) =>
      updateProfile(accentColor: color);
  Future<void> updateAppIcon(String icon) async {
    if (_profile == null) return;
    _profile = _profile!.copyWith(appIcon: icon);
    await userRepo.saveProfile(_profile!);
    notifyListeners();
  }

  Future<void> updateReminderSound(String sound) async {
    if (_profile == null) return;
    _profile = _profile!.copyWith(reminderSound: sound);
    await userRepo.saveProfile(_profile!);
    notifyListeners();
  }

  Future<void> incrementDosesMarked() async {
    if (_profile == null) return;
    _profile = _profile!.copyWith(
      dosesMarked: (_profile!.dosesMarked) + 1,
    );
    await userRepo.saveProfile(_profile!);
    notifyListeners();
  }

  void setLanguage(String lang) {
    if (_profile == null) return;
    updateProfile(); // Trigger background sync if needed
    userRepo.saveLanguage(lang);
    notifyListeners();
  }

  Future<void> deleteAccount() async {
    await AuthService.deleteAccount();
    _profile = null;
    _phase = AppPhase.auth;
    notifyListeners();
  }
}
