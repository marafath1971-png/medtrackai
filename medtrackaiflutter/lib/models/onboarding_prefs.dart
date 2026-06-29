/// Onboarding quiz answers persisted across first-run flow.
class OnboardingPrefs {
  final String medCount;
  final String role;
  final String schedule;
  final String reminderIntensity;

  const OnboardingPrefs({
    this.medCount = '1-2',
    this.role = 'self',
    this.schedule = 'morning',
    this.reminderIntensity = 'normal',
  });

  static const storageKeyMedCount = 'onboarding_med_count';
  static const storageKeyRole = 'onboarding_role';
  static const storageKeySchedule = 'onboarding_schedule';
  static const storageKeyReminderIntensity = 'onboarding_reminder_intensity';
  static const storageKeyCompleted = 'onboarding_completed';

  String get personalizedAuthHeadline {
    final roleLabel = role == 'caregiver' ? 'caregiver' : 'health journey';
    final medLabel = switch (medCount) {
      '1-2' => 'your meds',
      '3-5' => 'your ${medCount.split('-').last} meds',
      '6+' => 'your medications',
      _ => 'your meds',
    };
    return "Let's track $medLabel on your $roleLabel";
  }

  Map<String, String> toMap() => {
        storageKeyMedCount: medCount,
        storageKeyRole: role,
        storageKeySchedule: schedule,
        storageKeyReminderIntensity: reminderIntensity,
      };

  factory OnboardingPrefs.fromMap(Map<String, String> map) {
    return OnboardingPrefs(
      medCount: map[storageKeyMedCount] ?? '1-2',
      role: map[storageKeyRole] ?? 'self',
      schedule: map[storageKeySchedule] ?? 'morning',
      reminderIntensity: map[storageKeyReminderIntensity] ?? 'normal',
    );
  }

  OnboardingPrefs copyWith({
    String? medCount,
    String? role,
    String? schedule,
    String? reminderIntensity,
  }) {
    return OnboardingPrefs(
      medCount: medCount ?? this.medCount,
      role: role ?? this.role,
      schedule: schedule ?? this.schedule,
      reminderIntensity: reminderIntensity ?? this.reminderIntensity,
    );
  }
}
