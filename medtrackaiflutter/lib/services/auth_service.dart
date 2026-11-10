import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/logger.dart';

// ══════════════════════════════════════════════
// AUTH SERVICE
// ══════════════════════════════════════════════

class AuthService {
  static final _auth = FirebaseAuth.instance;
  static final _google = GoogleSignIn.instance;

  /// OAuth **web** client id for this Firebase project (the `client_type: 3`
  /// entry in google-services.json / GoogleService-Info.plist).
  ///
  /// google_sign_in 7.x does not read this from google-services.json: it must
  /// be handed to [GoogleSignIn.initialize]. Without it every Android sign-in
  /// failed with `clientConfigurationError, serverClientId must be provided`,
  /// which — combined with Email/Password being disabled in the console —
  /// meant a fresh install could not get past the auth wall at all.
  ///
  /// It is also what makes the returned idToken addressed to *our* backend, so
  /// [GoogleAuthProvider.credential] produces a token Firebase will accept.
  /// This is a public client identifier, not a secret.
  static const String _serverClientId =
      '789677467574-1csqahgeoho5oa46r3ppf6f8nqf1lc23.apps.googleusercontent.com';

  /// google_sign_in 7.x requires initialize() before any other call, and
  /// calling it twice throws — so it is done once, lazily, and the future is
  /// reused. A failed attempt is cleared so the next tap can retry rather than
  /// being stuck behind a permanently rejected future.
  static Future<void>? _googleInit;

  static Future<void> _ensureGoogleInitialized() {
    return _googleInit ??= _google
        .initialize(serverClientId: _serverClientId)
        .catchError((Object e) {
      _googleInit = null;
      throw e;
    });
  }

  // Stream of auth state changes
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Current user
  static bool get isLoggedIn => currentUser != null;
  static User? get currentUser => _auth.currentUser;
  static String? get uid => currentUser?.uid;
  static String? get email => currentUser?.email;
  static String? get displayName => currentUser?.displayName;
  static String? get photoUrl => currentUser?.photoURL;

  // ── Email/Password ─────────────────────────────────────────────────
  static Future<UserCredential?> signUpWithEmail(
      String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
    } on FirebaseAuthException {
      rethrow;
    }
  }

  static Future<UserCredential?> signInWithEmail(
      String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
          email: email, password: password);
    } on FirebaseAuthException {
      rethrow;
    }
  }

  // ── Google Sign-In ─────────────────────────────────────────────────
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      await _ensureGoogleInitialized();
      final googleUser = await _google.authenticate();
      final googleAuth = googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException {
      rethrow;
    } on PlatformException catch (e) {
      appLogger.e("Google Sign-In Platform Error: ${e.code} - ${e.message}");
      rethrow;
    } catch (e) {
      appLogger.e("Google Sign-In General Error: $e");
      rethrow;
    }
  }

  // ── Apple Sign-In ──────────────────────────────────────────────────
  static Future<UserCredential?> signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final OAuthProvider oAuthProvider = OAuthProvider('apple.com');
      final credential = oAuthProvider.credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException {
      rethrow;
    } on PlatformException catch (e) {
      appLogger.e("Apple Sign-In Platform Error: ${e.code} - ${e.message}");
      rethrow;
    } catch (e) {
      appLogger.e("Apple Sign-In General Error: $e");
      rethrow;
    }
  }

  // ── Password Reset ─────────────────────────────────────────────────
  static Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  static Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _google.signOut(),
    ]);
  }

  // ── DELETE ACCOUNT ──────────────────────────────────────────────────
  static Future<void> deleteAccount() async {
    final user = currentUser;
    if (user != null) {
      try {
        final uid = user.uid;
        final firestore = FirebaseFirestore.instance;
        final userRef = firestore.collection('users').doc(uid);

        // Comply with 2026 Data Protection: explicit erasure of granular subcollections
        final subcollections = [
          'medicines',
          'history',
          'symptoms',
          'caregivers',
          'caregiverAccess',
          'monitoring',
        ];
        for (final sub in subcollections) {
          final snap = await userRef.collection(sub).get();
          for (var doc in snap.docs) {
            await doc.reference.delete();
          }
        }

        // Explicit erasure of nested dependent subcollections
        final depSnap = await userRef.collection('dependents').get();
        for (final depDoc in depSnap.docs) {
          for (final depSub in ['medicines', 'history', 'symptoms']) {
            final nestedSnap = await depDoc.reference.collection(depSub).get();
            for (final nestedDoc in nestedSnap.docs) {
              await nestedDoc.reference.delete();
            }
          }
          await depDoc.reference.delete();
        }

        // Erase outstanding caregiver invites created by this user
        final invitesSnap = await firestore
            .collection('caregiverInvites')
            .where('patientUid', isEqualTo: uid)
            .get();
        for (final inviteDoc in invitesSnap.docs) {
          await inviteDoc.reference.delete();
        }

        // Terminate parent user document
        await userRef.delete();

        // Terminate Auth Identity
        await user.delete();
        await _google.disconnect(); // Disconnect Google Sign-In
        appLogger
            .i("User $uid successfully deleted with all local/remote data.");
      } catch (e) {
        appLogger.e("FATAL: Failed to erase account data - $e");
        rethrow;
      }
    }
  }
}
