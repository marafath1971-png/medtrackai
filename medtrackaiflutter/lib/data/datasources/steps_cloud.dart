import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/utils/logger.dart';
import '../../domain/entities/step_day.dart';
import '../../services/auth_service.dart';

/// Why a partner code could not be redeemed.
enum StepJoinResult { joined, signedOut, notFound, ownCode, failed }

/// Step data shared between two walkers.
///
/// An interface so the controller can be tested against an in-memory fake;
/// the security model it relies on lives in `firestore.rules` and is covered
/// by `test_rules/steps.test.js`.
abstract class StepsCloud {
  String? get uid;

  Future<void> saveDay(StepDay day);

  /// The people who have let this user see their steps.
  Stream<List<StepPartner>> watchPartners();

  /// The last [limit] days of [ownerUid]'s steps, keyed by date.
  Stream<Map<String, StepDay>> watchDays(String ownerUid, {int limit = 30});

  /// Creates a one-time pairing code, or null if signed out or offline.
  Future<String?> createInvite();

  Future<StepJoinResult> redeemInvite(
    String code, {
    required String myName,
    required String myAvatar,
  });

  Future<void> unpair(String partnerUid);

  Future<void> sendCheer(String partnerUid, StepCheerKind kind);

  Stream<List<StepCheer>> watchCheers();

  Future<void> consumeCheer(String id);
}

/// Firestore layout:
///
/// - `users/{uid}/stepDays/{yyyy-MM-dd}` — the owner's daily totals.
/// - `users/{uid}/stepPartners/{partnerUid}` — a grant: `partnerUid` may read
///   `uid`'s stepDays. Pairing writes one in each direction.
/// - `users/{uid}/stepCheers/{id}` — taps of encouragement from a partner.
/// - `stepInvites/{code}` — a 24-hour pairing code naming only its owner.
class FirestoreStepsCloud implements StepsCloud {
  // Resolved on use, not at construction: AppState builds this before
  // Firebase is initialised in tests, and nothing here is touched until a
  // signed-in user opens the steps feature.
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  @override
  String? get uid {
    try {
      return AuthService.uid;
    } catch (_) {
      return null;
    }
  }

  DocumentReference<Map<String, dynamic>> _user(String id) =>
      _db.collection('users').doc(id);

  @override
  Future<void> saveDay(StepDay day) async {
    final me = uid;
    if (me == null) return;
    await _user(me).collection('stepDays').doc(day.dateKey).set({
      ...day.toJson(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Stream<List<StepPartner>> watchPartners() {
    final me = uid;
    if (me == null) return const Stream.empty();
    return _user(me).collection('stepPartners').snapshots().map((snap) {
      final docs = snap.docs.toList()
        ..sort((a, b) =>
            _millis(b.data()['since']).compareTo(_millis(a.data()['since'])));
      return [
        for (final d in docs)
          StepPartner(
            uid: d.id,
            name: d.data()['name'] as String? ?? '',
            avatar: d.data()['avatar'] as String? ?? '',
          ),
      ];
    });
  }

  static int _millis(Object? ts) =>
      ts is Timestamp ? ts.millisecondsSinceEpoch : 0;

  @override
  Stream<Map<String, StepDay>> watchDays(String ownerUid, {int limit = 30}) {
    return _user(ownerUid)
        .collection('stepDays')
        .orderBy(FieldPath.documentId, descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => {
              for (final d in snap.docs) d.id: StepDay.fromJson(d.id, d.data()),
            });
  }

  // No 0/O or 1/I: the code is read aloud and typed by hand.
  static const _codeChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  static String _newCode() {
    final r = Random.secure();
    return List.generate(6, (_) => _codeChars[r.nextInt(_codeChars.length)])
        .join();
  }

  @override
  Future<String?> createInvite() async {
    final me = uid;
    if (me == null) return null;
    try {
      for (var attempt = 0; attempt < 5; attempt++) {
        final code = _newCode();
        final ref = _db.collection('stepInvites').doc(code);
        if ((await ref.get()).exists) continue;
        await ref.set({
          'ownerUid': me,
          'createdAt': FieldValue.serverTimestamp(),
        });
        return code;
      }
    } catch (e) {
      appLogger.w('[Steps] invite creation failed: $e');
    }
    return null;
  }

  @override
  Future<StepJoinResult> redeemInvite(
    String code, {
    required String myName,
    required String myAvatar,
  }) async {
    final me = uid;
    if (me == null) return StepJoinResult.signedOut;
    final inviteRef = _db.collection('stepInvites').doc(code);
    try {
      final invite = await inviteRef.get();
      final owner = invite.data()?['ownerUid'] as String?;
      if (!invite.exists || owner == null) return StepJoinResult.notFound;
      if (owner == me) return StepJoinResult.ownCode;

      // One batch, so there is never a moment where only one of the two can
      // see the other. The rules check the grant against the invite as it
      // was before the batch, and the invite's deletion against the grant as
      // it will be after — see stepPartners / stepInvites in firestore.rules.
      final batch = _db.batch();
      batch.set(_user(owner).collection('stepPartners').doc(me), {
        'uid': me,
        'name': myName,
        'avatar': myAvatar,
        'inviteCode': code,
        'since': FieldValue.serverTimestamp(),
      });
      batch.set(_user(me).collection('stepPartners').doc(owner), {
        'uid': owner,
        'name': '',
        'avatar': '',
        'since': FieldValue.serverTimestamp(),
      });
      batch.delete(inviteRef);
      await batch.commit();
      return StepJoinResult.joined;
    } on FirebaseException catch (e) {
      appLogger.w('[Steps] invite redemption failed: ${e.code}');
      // An expired code is still on the server but unreadable.
      return e.code == 'permission-denied'
          ? StepJoinResult.notFound
          : StepJoinResult.failed;
    } catch (e) {
      appLogger.w('[Steps] invite redemption failed: $e');
      return StepJoinResult.failed;
    }
  }

  @override
  Future<void> unpair(String partnerUid) async {
    final me = uid;
    if (me == null) return;
    final batch = _db.batch()
      ..delete(_user(me).collection('stepPartners').doc(partnerUid))
      ..delete(_user(partnerUid).collection('stepPartners').doc(me));
    await batch.commit();
  }

  @override
  Future<void> sendCheer(String partnerUid, StepCheerKind kind) async {
    final me = uid;
    if (me == null) return;
    await _user(partnerUid).collection('stepCheers').add({
      'fromUid': me,
      'kind': kind.name,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Stream<List<StepCheer>> watchCheers() {
    final me = uid;
    if (me == null) return const Stream.empty();
    return _user(me)
        .collection('stepCheers')
        .limit(10)
        .snapshots()
        .map((snap) => [
              for (final d in snap.docs)
                StepCheer(
                  id: d.id,
                  fromUid: d.data()['fromUid'] as String? ?? '',
                  kind: d.data()['kind'] == 'nudge'
                      ? StepCheerKind.nudge
                      : StepCheerKind.cheer,
                ),
            ]);
  }

  @override
  Future<void> consumeCheer(String id) async {
    final me = uid;
    if (me == null) return;
    await _user(me).collection('stepCheers').doc(id).delete();
  }
}
