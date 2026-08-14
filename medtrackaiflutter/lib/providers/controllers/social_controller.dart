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

class SocialController extends ChangeNotifier {
  final IUserRepository userRepo;

  List<Caregiver> _caregivers = [];
  List<Map<String, dynamic>> _monitoredPatients = [];
  List<MissedAlert> _missedAlerts = [];
  final Map<String, String> _protectorInsights = {};
  StreamSubscription? _cgSub;
  StreamSubscription? _monitoringSub;
  String? _pendingJoinCode;

  SocialController({required this.userRepo});

  List<Caregiver> get caregivers => _caregivers;
  List<Map<String, dynamic>> get monitoredPatients => _monitoredPatients;
  List<MissedAlert> get missedAlerts => _missedAlerts;
  Map<String, String> get protectorInsights => _protectorInsights;
  String? get pendingJoinCode => _pendingJoinCode;

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
    }, onError: (e) {
      appLogger.e('[SocialController] Monitoring stream error', error: e);
    });
  }

  Future<String> createInvite(
      Caregiver cg, String? patientName, String? patientAvatar) async {
    final uid = AuthService.uid;
    if (uid == null) return '';
    try {
      String code = _generateInviteCode();
      for (var i = 0; i < 5; i++) {
        final existing = await userRepo.getRawInvite(code);
        if (existing == null) break;
        code = _generateInviteCode();
      }

      final cgWithCode = cg.copyWith(inviteCode: code);
      await userRepo.createInvite(
        uid,
        cgWithCode,
        patientName: patientName,
        patientAvatar: patientAvatar,
      );

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
      return '';
    }
  }

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

    final patientProfile = await userRepo.getOtherProfile(patientUid);
    final patientName =
        patientProfile?.name ?? invite['patientName'] as String? ?? 'Member';
    final patientAvatar =
        patientProfile?.avatar ?? invite['patientAvatar'] as String? ?? '👤';
    final relation = invite['relation'] as String? ?? 'Family';
    final cgId = invite['cgId'] as int? ?? 0;

    final patientEntry = {
      'uid': patientUid,
      'name': patientName,
      'avatar': patientAvatar,
      'relation': relation,
      'addedAt': DateTime.now().toIso8601String().substring(0, 10),
      'cgId': cgId,
    };

    await userRepo.addMonitoringPatient(patientEntry);
    await userRepo.activatePatientCaregiver(patientUid, cgId, caregiverUid);
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
      appLogger.e('[Social] nudgePatient function failed, writing directly', error: e);
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
    super.dispose();
  }
}
