import '../entities/entities.dart';

abstract class IUserRepository {
  Future<UserProfile?> getProfile();
  Future<UserProfile?> getOtherProfile(String uid);
  Future<void> saveProfile(UserProfile profile);

  Future<List<Caregiver>> getCaregivers();
  Stream<List<Caregiver>> getCaregiversStream();
  Future<void> saveCaregivers(List<Caregiver> caregivers);

  Future<StreakData> getStreakData();
  Future<void> saveStreakData(StreakData data);

  Future<bool> getDarkMode();
  Future<void> saveDarkMode(bool darkMode);

  Future<String> getLanguage();
  Future<void> saveLanguage(String language);

  /// Uploads everything held locally to Firestore.
  ///
  /// For the one moment it is meant for: a user who has been working offline
  /// or signed out, signing in for the first time against an empty cloud.
  /// Medicines and history reconcile themselves on every load, but profile,
  /// caregivers, streak, theme and language have no such merge step — without
  /// this they exist only on the device until each is next edited.
  ///
  /// Must only be called when the cloud is known to be empty; it overwrites
  /// rather than merges.
  Future<void> syncToCloud();

  Future<void> createInvite(String patientUid, Caregiver cg);
  Future<Caregiver?> getInvite(String code);
  Future<Map<String, dynamic>?> getRawInvite(String code);
  Future<void> deleteInvite(String code);
  Future<void> saveFcmToken(String token);

  // ── Monitoring ──
  Stream<List<Map<String, dynamic>>> getMonitoringPatientsStream();
  Stream<List<Medicine>> getPatientMedsStream(String patientUid);
  Stream<Map<String, List<DoseEntry>>> getPatientHistoryStream(
      String patientUid);
  Future<void> nudgePatient(String patientUid);
  Stream<UserProfile?> getProfileStream();

  Future<List<Medicine>> getPatientMeds(String uid);
  Future<Map<String, List<DoseEntry>>> getPatientHistory(String uid);

  /// Caregiver joins a patient's circle via invite code.
  Future<void> addMonitoringPatient(Map<String, dynamic> patient);
  Future<void> activatePatientCaregiver(
      String patientUid, int cgId, String caregiverUid);

  /// Clears a caregiver's uid-keyed access grant on the current user.
  Future<void> revokeCaregiverAccess(String caregiverUid);
}
