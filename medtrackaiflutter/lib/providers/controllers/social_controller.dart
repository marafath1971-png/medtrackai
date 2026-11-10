import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/user_repository.dart';
import '../../services/auth_service.dart';
import '../../services/gemini_service.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/haptic_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SocialController extends ChangeNotifier {
  final IUserRepository userRepo;

  List<Caregiver> _caregivers = [];
  List<Map<String, dynamic>> _monitoredPatients = [];
  List<MissedAlert> _missedAlerts = [];
  final Map<String, String> _protectorInsights = {};
  StreamSubscription? _cgSub;
  StreamSubscription? _monitoringSub;
  StreamSubscription? _escalationSub;
  List<EscalationAlert> _escalations = [];
  final Set<String> _acknowledging = {};
  String? _pendingJoinCode;

  SocialController({required this.userRepo});

  List<Caregiver> get caregivers => _caregivers;
  List<Map<String, dynamic>> get monitoredPatients => _monitoredPatients;
  List<MissedAlert> get missedAlerts => _missedAlerts;
  Map<String, String> get protectorInsights => _protectorInsights;
  String? get pendingJoinCode => _pendingJoinCode;

  /// Missed-dose alerts the server sent to this user as a caregiver, limited
  /// to the ones still worth acting on (see [EscalationAlert.relevant]).
  List<EscalationAlert> get escalations =>
      EscalationAlert.relevant(_escalations, DateTime.now());

  /// Whether an "I'm on it" call is in flight for [alertId].
  bool isAcknowledging(String alertId) => _acknowledging.contains(alertId);

  /// Resets in-memory caregiver/social data and cancels subscriptions.
  void clear() {
    _cgSub?.cancel();
    _cgSub = null;
    _monitoringSub?.cancel();
    _monitoringSub = null;
    _escalationSub?.cancel();
    _escalationSub = null;
    _escalations = [];
    _acknowledging.clear();
    _caregivers = [];
    _monitoredPatients = [];
    _missedAlerts = [];
    _protectorInsights.clear();
    _pendingJoinCode = null;
    notifyListeners();
  }

  static const _codeChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  String _generateInviteCode() {
    final r = Random.secure();
    return List.generate(
      6,
      (_) => _codeChars[r.nextInt(_codeChars.length)],
    ).join();
  }

  void addMissedAlert(MissedAlert alert) {
    _missedAlerts = [alert, ..._missedAlerts].take(20).toList();
    notifyListeners();
  }

  void setPendingJoinCode(String? code) {
    _pendingJoinCode = code;
    notifyListeners();
  }

  Future<void> loadData() async {
    try {
      _caregivers = await userRepo.getCaregivers();
      _listenToCaregivers();
      _listenToMonitoring();
      _listenToEscalations();
      notifyListeners();
    } catch (e) {
      appLogger.e('[SocialController] Data load failed', error: e);
    }
  }

  void _listenToCaregivers() {
    _cgSub?.cancel();
    _cgSub = userRepo.getCaregiversStream().listen((list) {
      _caregivers = list;
      notifyListeners();
    });
  }

  void _listenToMonitoring() {
    _monitoringSub?.cancel();
    final uid = AuthService.uid;
    if (uid == null) return;

    _monitoringSub = userRepo.getMonitoringPatientsStream().listen((patients) {
      _monitoredPatients = patients;
      notifyListeners();
      _backfillAccessGrants(patients, uid);
    }, onError: (e) {
      appLogger.e('[SocialController] Monitoring stream error', error: e);
    });
  }

  /// Streams the escalation records that reached this user.
  ///
  /// Server-written (see detectMissedDoses); the security rule lets a
  /// caregiver read only documents whose `alertedUids` contains them, which
  /// is exactly this query. Backed by the composite index in
  /// firestore.indexes.json.
  void _listenToEscalations() {
    _escalationSub?.cancel();
    final uid = AuthService.uid;
    if (uid == null) return;
    _escalationSub = FirebaseFirestore.instance
        .collection('missedDoseAlerts')
        .where('alertedUids', arrayContains: uid)
        .orderBy('dayKey', descending: true)
        .limit(30)
        .snapshots()
        .listen((snap) {
      _escalations = snap.docs
          .map((d) => EscalationAlert.fromMap(d.id, d.data()))
          .toList();
      notifyListeners();
    }, onError: (e) {
      appLogger.e('[SocialController] Escalation stream error', error: e);
    });
  }

  /// "I'm on it": claims a missed-dose alert for this caregiver.
  ///
  /// The server stops the escalation chain and tells every other caregiver
  /// already alerted. Returns the name of whoever had already claimed it, or
  /// null when this call claimed it. Throws if the call failed, so the screen
  /// can say so rather than implying the family was told.
  Future<String?> acknowledgeEscalation(String alertId) async {
    if (_acknowledging.contains(alertId)) return null;
    _acknowledging.add(alertId);
    notifyListeners();
    try {
      final res = await FirebaseFunctions.instance
          .httpsCallable('acknowledgeMissedDose')
          .call({'alertId': alertId});
      HapticEngine.success();
      final data = res.data;
      return data is Map ? data['alreadyHandledBy'] as String? : null;
    } finally {
      _acknowledging.remove(alertId);
      notifyListeners();
    }
  }

  /// Re-issues the uid-keyed access grant for relationships formed before
  /// grants existed.
  ///
  /// Those caregivers joined when `isActiveCaregiver()` read the cgId-keyed
  /// roster — a lookup that could never match — so they have a monitoring entry
  /// but no grant, and would stay locked out of the patient's data after the
  /// rule started requiring one. The write is idempotent (merge on a fixed doc
  /// id), so repeating it on every load costs one no-op write per patient and
  /// needs no migration or version flag.
  void _backfillAccessGrants(
      List<Map<String, dynamic>> patients, String caregiverUid) {
    for (final p in patients) {
      final patientUid = p['uid'] as String?;
      if (patientUid == null || patientUid.isEmpty) continue;
      if (_grantsBackfilled.contains(patientUid)) continue;
      _grantsBackfilled.add(patientUid);

      final cgId = p['cgId'] as int? ?? 0;
      // Best-effort: a failure here leaves the caregiver exactly as they were,
      // and the next load retries.
      userRepo
          .activatePatientCaregiver(patientUid, cgId, caregiverUid)
          .catchError((e) => appLogger
              .w('[SocialController] access grant backfill failed: $e'));
    }
  }

  /// Patients whose grant this session already re-issued.
  final Set<String> _grantsBackfilled = {};

  /// Why an invite could not be created.
  ///
  /// The last failure is exposed because [createInvite] can only answer with a
  /// code or an empty string, and the two ways of getting an empty string need
  /// opposite advice: signing in fixes one, retrying fixes the other. The
  /// screen previously said "Check your connection and try again" for both, so
  /// a signed-out user was sent to debug their wifi — the same defect already
  /// fixed on the join side of this flow.
  String? lastInviteError;

  /// [patientName] and [patientAvatar] are accepted but deliberately unused:
  /// the invite document no longer carries identifying information, because it
  /// is readable by anyone holding the code. The caregiver resolves the real
  /// name from the patient's profile once their access grant exists.
  Future<String> createInvite(
      Caregiver cg, String? patientName, String? patientAvatar) async {
    lastInviteError = null;
    final uid = AuthService.uid;
    if (uid == null) {
      lastInviteError = 'signed_out';
      return '';
    }
    try {
      String code = _generateInviteCode();
      for (var i = 0; i < 5; i++) {
        final existing = await userRepo.getRawInvite(code);
        if (existing == null) break;
        code = _generateInviteCode();
      }

      final cgWithCode = cg.copyWith(inviteCode: code);
      await userRepo.createInvite(uid, cgWithCode);

      final idx = _caregivers.indexWhere((c) => c.id == cg.id);
      if (idx != -1) {
        _caregivers[idx] = _caregivers[idx].copyWith(inviteCode: code);
      } else {
        _caregivers = [..._caregivers, cgWithCode];
      }
      await userRepo.saveCaregivers(_caregivers);
      notifyListeners();
      return code;
    } catch (e) {
      appLogger.e('[SocialController] createInvite failed', error: e);
      // A permission denial is not transient and never resolves by waiting:
      // it means the security rules reject the write, or App Check is
      // enforced and this build has no valid attestation token. Telling the
      // user to try again in a moment is advice that cannot come true, and it
      // hides the one detail that makes the cause findable.
      final code = e is FirebaseException ? e.code : '';
      lastInviteError =
          (code == 'permission-denied' || code == 'unauthenticated')
              ? 'denied'
              : 'failed';
      return '';
    }
  }

  /// Message for the last [createInvite] failure.
  ///
  /// Static and on the controller so the mapping is testable without Firebase.
  static String inviteErrorMessage(String? reason) => switch (reason) {
        'signed_out' =>
          'Sign in to create an invite — the code is tied to your account.',
        'denied' =>
          'Invites are blocked by the server right now. This is a setup '
              'problem on our side, not something retrying will fix.',
        _ => 'Could not create the invite. Please try again in a moment.',
      };

  Future<void> joinCaregiver(String code) async {
    final caregiverUid = AuthService.uid;
    if (caregiverUid == null) {
      throw Exception('Sign in required');
    }

    final normalized = code.trim().toUpperCase();
    if (normalized.length < 6) {
      throw Exception('Invalid code');
    }

    final invite = await userRepo.getRawInvite(normalized);
    if (invite == null) {
      throw Exception('Invalid code');
    }

    final patientUid = invite['patientUid'] as String?;
    if (patientUid == null || patientUid.isEmpty) {
      throw Exception('Invalid code');
    }
    if (patientUid == caregiverUid) {
      throw Exception('Cannot monitor your own profile');
    }

    if (_monitoredPatients.any((p) => p['uid'] == patientUid)) {
      HapticEngine.success();
      return;
    }

    final relation = invite['relation'] as String? ?? 'Family';
    final cgId = invite['cgId'] as int? ?? 0;

    // Activate first. The invite no longer carries the patient's name, and the
    // security rule only permits reading their profile once this grant exists
    // — so the order matters: reading first would be denied and fall back to a
    // placeholder.
    await userRepo.activatePatientCaregiver(patientUid, cgId, caregiverUid);

    final patientProfile = await userRepo.getOtherProfile(patientUid);
    final patientName = patientProfile?.name.isNotEmpty == true
        ? patientProfile!.name
        : 'Member';
    final patientAvatar = patientProfile?.avatar.isNotEmpty == true
        ? patientProfile!.avatar
        : '👤';

    final patientEntry = {
      'uid': patientUid,
      'name': patientName,
      'avatar': patientAvatar,
      'relation': relation,
      'addedAt': DateTime.now().toIso8601String().substring(0, 10),
      'cgId': cgId,
    };

    await userRepo.addMonitoringPatient(patientEntry);
    await userRepo.deleteInvite(normalized);

    _monitoredPatients = [..._monitoredPatients, patientEntry];
    notifyListeners();

    HapticEngine.success();
  }

  Future<void> addCaregiver(Caregiver cg) async {
    _caregivers.add(cg);
    await userRepo.saveCaregivers(_caregivers);
    notifyListeners();
  }

  Future<void> removeCaregiver(int id) async {
    final idx = _caregivers.indexWhere((c) => c.id == id);
    if (idx == -1) return;
    final cg = _caregivers[idx];
    if (cg.inviteCode != null && cg.inviteCode!.isNotEmpty) {
      await userRepo
          .deleteInvite(cg.inviteCode!)
          .catchError((e) => appLogger.w('[Social] Delete invite failed: $e'));
    }
    await userRepo.removeCaregiver(id, caregiverUid: cg.joinedCaregiverUid);
    _caregivers.removeAt(idx);
    await userRepo.saveCaregivers(_caregivers);
    notifyListeners();
  }

  Future<void> stopMonitoringPatient(String patientUid) async {
    _monitoredPatients.removeWhere((p) => p['uid'] == patientUid);
    notifyListeners();
    await userRepo.removeMonitoringPatient(patientUid);
  }

  Future<void> activateCaregiver(int id) async {
    final idx = _caregivers.indexWhere((c) => c.id == id);
    if (idx != -1) {
      _caregivers[idx] = _caregivers[idx].copyWith(status: 'active');
      await userRepo.saveCaregivers(_caregivers);
      notifyListeners();
    }
  }

  void markAlertsAsSeen() {
    _missedAlerts = [];
    notifyListeners();
  }

  Future<List<Medicine>> getPatientMeds(String uid) async {
    return await userRepo.getPatientMeds(uid);
  }

  Future<Map<String, List<DoseEntry>>> getPatientHistory(String uid) async {
    return await userRepo.getPatientHistory(uid);
  }

  Future<void> nudgePatient(String uid) async {
    appLogger.i('[Social] Nudging patient: $uid');
    HapticEngine.selection();
    // The `nudgePatient` function verifies the caregiver→patient link, records
    // the nudge, and sends the FCM push. Falls back to a direct Firestore write
    // so the nudge is still recorded if the callable is unreachable.
    try {
      await FirebaseFunctions.instance
          .httpsCallable('nudgePatient')
          .call({'patientUid': uid});
    } catch (e) {
      appLogger.e('[Social] nudgePatient function failed, writing directly',
          error: e);
      await userRepo.nudgePatient(uid);
    }
  }

  Future<void> fetchProtectorInsight(Caregiver cg, List<Medicine> meds,
      Map<String, List<DoseEntry>> history) async {
    final insight = await GeminiService.getProtectorInsight(
      patientName: 'Member',
      meds: meds,
      history: history,
    );
    _protectorInsights[cg.id.toString()] = insight;
    notifyListeners();
  }

  Future<void> joinCareTeam(String code) => joinCaregiver(code);

  /// Task Phase 2.4: Caregiver Telemetry Alert.
  /// Calls the secure `alertMyCaregivers` function — the server resolves the
  /// caregiver list from the patient's own record and fans out FCM pushes, so
  /// the client never targets users directly (no spoofing / arbitrary sends).
  Future<void> notifyCaregiversOfMissedDose(Medicine med) async {
    final uid = AuthService.uid;
    if (uid == null) return;
    // Skip the round-trip when there are no active caregivers to notify.
    if (!_caregivers.any((c) => c.status == 'active')) return;
    try {
      await FirebaseFunctions.instance
          .httpsCallable('alertMyCaregivers')
          .call({'medName': med.name});
      appLogger.i('[Social] Missed-dose alert dispatched for ${med.name}');
    } catch (e) {
      appLogger.e('[Social] alertMyCaregivers failed', error: e);
    }
  }

  @override
  void dispose() {
    _cgSub?.cancel();
    _monitoringSub?.cancel();
    _escalationSub?.cancel();
    super.dispose();
  }
}
