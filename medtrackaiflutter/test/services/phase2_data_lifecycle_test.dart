import 'package:flutter_test/flutter_test.dart';
import 'package:medai/domain/entities/entities.dart';
import 'package:medai/domain/repositories/user_repository.dart';
import 'package:medai/providers/controllers/social_controller.dart';

class MockUserRepository implements IUserRepository {
  List<Caregiver> caregivers = [];
  List<String> deletedInvites = [];
  List<int> removedCaregiverIds = [];
  List<String?> removedCaregiverUids = [];
  List<String> removedMonitoringPatients = [];

  @override
  Future<List<Caregiver>> getCaregivers() async => caregivers;

  @override
  Stream<List<Caregiver>> getCaregiversStream() => Stream.value(caregivers);

  @override
  Future<void> saveCaregivers(List<Caregiver> cgs) async {
    caregivers = List.from(cgs);
  }

  @override
  Future<void> deleteInvite(String code) async {
    deletedInvites.add(code);
  }

  @override
  Future<void> removeCaregiver(int cgId, {String? caregiverUid}) async {
    removedCaregiverIds.add(cgId);
    removedCaregiverUids.add(caregiverUid);
  }

  @override
  Future<void> removeMonitoringPatient(String patientUid) async {
    removedMonitoringPatients.add(patientUid);
  }

  @override
  Future<void> activatePatientCaregiver(
      String patientUid, int cgId, String caregiverUid) async {}

  @override
  Future<void> addMonitoringPatient(Map<String, dynamic> patient) async {}

  @override
  Future<void> createInvite(String patientUid, Caregiver cg) async {}

  @override
  Future<bool> getDarkMode() async => false;

  @override
  Future<Caregiver?> getInvite(String code) async => null;

  @override
  Future<String> getLanguage() async => 'en';

  @override
  Stream<List<Map<String, dynamic>>> getMonitoringPatientsStream() =>
      Stream.value([]);

  @override
  Future<UserProfile?> getOtherProfile(String uid) async => null;

  @override
  Future<Map<String, List<DoseEntry>>> getPatientHistory(String uid) async =>
      {};

  @override
  Stream<Map<String, List<DoseEntry>>> getPatientHistoryStream(
          String patientUid) =>
      Stream.value({});

  @override
  Future<List<Medicine>> getPatientMeds(String uid) async => [];

  @override
  Stream<List<Medicine>> getPatientMedsStream(String patientUid) =>
      Stream.value([]);

  @override
  Future<UserProfile?> getProfile() async => null;

  @override
  Stream<UserProfile?> getProfileStream() => Stream.value(null);

  @override
  Future<Map<String, dynamic>?> getRawInvite(String code) async => null;

  @override
  Future<StreakData> getStreakData() async => const StreakData();

  @override
  Future<void> nudgePatient(String patientUid) async {}

  @override
  Future<void> revokeCaregiverAccess(String caregiverUid) async {}

  @override
  Future<void> saveDarkMode(bool darkMode) async {}

  @override
  Future<void> saveFcmToken(String token) async {}

  @override
  Future<void> saveLanguage(String language) async {}

  @override
  Future<void> saveProfile(UserProfile profile) async {}

  @override
  Future<void> saveStreakData(StreakData data) async {}

  @override
  Future<void> syncToCloud() async {}
}

void main() {
  group('Phase 2 Data Lifecycle & Access Control', () {
    test(
        'UserProfile.copyWith correctly sets and overrides promoCode and appliedPromo',
        () {
      final profile = UserProfile(name: 'Sarah');
      expect(profile.promoCode, isNull);
      expect(profile.appliedPromo, isNull);

      final promoData = {
        'type': 'referral',
        'code': 'FRIEND30',
        'expiresAt':
            DateTime.now().add(const Duration(days: 30)).toIso8601String(),
      };

      final updated = profile.copyWith(
        promoCode: 'FRIEND30',
        appliedPromo: promoData,
        isPremium: true,
      );

      expect(updated.promoCode, 'FRIEND30');
      expect(updated.appliedPromo?['code'], 'FRIEND30');
      expect(updated.isPremium, isTrue);
    });

    test('Caregiver entity serializes and deserializes joinedCaregiverUid', () {
      final cg = Caregiver(
        id: 42,
        name: 'Dr. Jane',
        relation: 'Doctor',
        inviteCode: 'XYZ123',
        joinedCaregiverUid: 'caregiver_uid_999',
      );

      final json = cg.toJson();
      expect(json['joinedCaregiverUid'], 'caregiver_uid_999');

      final deserialized = Caregiver.fromJson(json);
      expect(deserialized.joinedCaregiverUid, 'caregiver_uid_999');
      expect(deserialized.inviteCode, 'XYZ123');
    });

    test(
        'SocialController.removeCaregiver revokes cloud access, deletes invite, and updates roster',
        () async {
      final mockRepo = MockUserRepository();
      mockRepo.caregivers = [
        Caregiver(
          id: 101,
          name: 'Bob',
          relation: 'Father',
          inviteCode: 'INVITE_CODE',
          joinedCaregiverUid: 'bob_auth_uid',
        ),
        Caregiver(
          id: 102,
          name: 'Alice',
          relation: 'Mother',
        ),
      ];

      final controller = SocialController(userRepo: mockRepo);
      await controller.loadData();
      expect(controller.caregivers.length, 2);

      await controller.removeCaregiver(101);

      expect(controller.caregivers.length, 1);
      expect(controller.caregivers.first.id, 102);
      expect(mockRepo.deletedInvites, contains('INVITE_CODE'));
      expect(mockRepo.removedCaregiverIds, contains(101));
      expect(mockRepo.removedCaregiverUids, contains('bob_auth_uid'));
    });

    test(
        'SocialController.stopMonitoringPatient removes patient from monitoredPatients and calls repo',
        () async {
      final mockRepo = MockUserRepository();
      final controller = SocialController(userRepo: mockRepo);

      // Directly add to monitored patients
      controller.monitoredPatients.add({
        'uid': 'patient_abc',
        'name': 'Grandpa',
        'relation': 'Grandparent',
      });

      expect(controller.monitoredPatients.length, 1);

      await controller.stopMonitoringPatient('patient_abc');

      expect(controller.monitoredPatients.isEmpty, isTrue);
      expect(mockRepo.removedMonitoringPatients, contains('patient_abc'));
    });
  });
}
