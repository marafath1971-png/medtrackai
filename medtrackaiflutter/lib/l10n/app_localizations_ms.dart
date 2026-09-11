// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Malay (`ms`).
class AppLocalizationsMs extends AppLocalizations {
  AppLocalizationsMs([String locale = 'ms']) : super(locale);

  @override
  String get appTitle => 'MedAI';

  @override
  String get greetingHero => 'Utama';

  @override
  String get homeTab => 'Utama';

  @override
  String get alarmsTab => 'Penggera';

  @override
  String get dashboardTab => 'Trend';

  @override
  String get familyTab => 'Kalangan';

  @override
  String get scanTab => 'Imbas';

  @override
  String get homeNextDose => 'Next dose';

  @override
  String get homeSchedule => 'Schedule';

  @override
  String get homeDosesLeft => 'Doses left';

  @override
  String get homeYourMedicines => 'Your medicines';

  @override
  String get homeAddMeds => 'Add meds';

  @override
  String get homeAllClear => 'All clear';

  @override
  String get homeFirstPending => 'First pending';

  @override
  String get countrySelectionTitle => 'Di mana lokasi anda?';

  @override
  String get countrySelectionSubtitle =>
      'Membantu kami mengenal pasti jenama ubat tempatan';

  @override
  String get prnLabel => 'Bila Perlu';

  @override
  String get prnUndoToast => 'Dos PRN dialih keluar';

  @override
  String get dailyLogTitle => 'Log Harian';

  @override
  String get noMedicinesScheduled => 'Tiada ubat dijadualkan untuk hari ini.';

  @override
  String get remaining => 'berbaki';

  @override
  String get refillRequired => 'Perlu Isi Semula';

  @override
  String get settings => 'Tetapan';

  @override
  String get profile => 'Profil';

  @override
  String get language => 'Bahasa';

  @override
  String get country => 'Negara';

  @override
  String get saveChanges => 'SIMPAN PERUBAHAN';

  @override
  String get inventory => 'Inventori';

  @override
  String get noMedicines => 'Tiada ubat';

  @override
  String get takeNow => 'Ambil Sekarang';

  @override
  String get snooze => 'Tunda';

  @override
  String get skip => 'Langkau';

  @override
  String get pharmacyLabel => 'Farmasi';

  @override
  String get pharmacyPhoneLabel => 'Telefon Farmasi';

  @override
  String get rxNumberLabel => 'Nombor Preskripsi';

  @override
  String get globalSettings => 'Tetapan Global';

  @override
  String get religiousObservance => 'Pematuhan Agama';

  @override
  String get shabbatMode => 'Mod Shabbat';

  @override
  String get prayerAwareReminders => 'Peringatan Mengikut Waktu Solat';

  @override
  String get halalDetection => 'Pengesanan Halal & Gelatin';

  @override
  String get amoledMode => 'Mod AMOLED (Jimat Piksel)';

  @override
  String get diabetesMode => 'Mod Diabetes';

  @override
  String get hypertensionMode => 'Mod Hipertensi';

  @override
  String get supportedMarkets => 'Pasaran Disokong';

  @override
  String get halalSafe => 'Selamat Halal';

  @override
  String get gelatinWarning => 'Mengandungi Gelatin';

  @override
  String get halalUncertain => 'Halal Tidak Pasti';

  @override
  String get edit => 'Edit';

  @override
  String get editProfile => 'Edit Profil';

  @override
  String get cancel => 'Batal';

  @override
  String get globalSettingsSubtitle => 'Urus tetapan pasaran antarabangsa';

  @override
  String get medicationDisplay => 'Paparan Ubat';

  @override
  String get showGenericNames => 'Tunjuk Nama Generik (INN)';

  @override
  String get showGenericNamesSubtitle =>
      'Paparkan nama generik antarabangsa dan bukan nama jenama';

  @override
  String get pbsSafetyNet => 'Penjejak PBS Safety Net';

  @override
  String get pbsSafetyNetSubtitle =>
      'Australia — jejak bayaran bersama tahunan';

  @override
  String get pbsThreshold => 'Ambang tahunan: \$1,622.90';

  @override
  String pbsSpent(Object amount) {
    return 'Dibelanjakan: \$$amount';
  }

  @override
  String pbsRemaining(Object amount) {
    return '\$$amount lagi';
  }

  @override
  String get reached => 'Tercapai!';

  @override
  String get medsSubsidised => 'Ubat kini disubsidi!';

  @override
  String get spentAmountSubtitle =>
      'Seret untuk kemas kini jumlah perbelanjaan tahunan anda (bayaran bersama untuk semua preskripsi PBS tahun kalendar ini)';

  @override
  String get clinicalModes => 'Mod Klinikal';

  @override
  String get clinicalModesSubtitle => 'AS · UK · UAE · Malaysia';

  @override
  String get diabetesModeSubtitle =>
      'Log glukosa darah bersama insulin / ubat diabetes';

  @override
  String get hypertensionModeSubtitle =>
      'Log tekanan darah bersama ubat antihipertensi';

  @override
  String get displaySettings => 'Paparan';

  @override
  String get amoledModeSubtitle =>
      'Guna latar #000000 sebenar untuk mengoptimumkan paparan AMOLED dan menjimatkan bateri';

  @override
  String get shabbatModeSubtitle =>
      'Peringatan getaran sahaja yang lembut dari matahari terbenam Jumaat hingga malam Sabtu';

  @override
  String get selectCountry => 'Pilih Negara';

  @override
  String get selectLanguage => 'Pilih Bahasa';

  @override
  String get aiSafetyProfile => 'Profil Keselamatan AI';

  @override
  String get verified => 'Disahkan';

  @override
  String get criticalWarnings => 'Amaran Kritikal';

  @override
  String get drugInteractions => 'Interaksi Ubat';

  @override
  String get dietaryLifestyleRules => 'Peraturan Pemakanan & Gaya Hidup';

  @override
  String get ahaInsight => 'Aha! Cerapan';

  @override
  String get generateSafetyProfile => 'Jana Profil Keselamatan';

  @override
  String get analyzingClinicalLimits => 'Menganalisis Had Klinikal...';

  @override
  String get safetyLoadingSubtitle =>
      'Sila tunggu sementara AI mengesahkan interaksi, bahaya dan peraturan makanan.';

  @override
  String get safetyPromptSubtitle =>
      'Ketik untuk menganalisis ubat ini dengan serta-merta bagi bahaya, interaksi ubat dan peraturan gaya hidup.';

  @override
  String get goodMorning => 'Selamat pagi';

  @override
  String get goodAfternoon => 'Selamat tengah hari';

  @override
  String get goodEvening => 'Selamat petang';

  @override
  String hiUser(String name) {
    return 'Hai, $name 👋';
  }

  @override
  String get startJourney => 'Mari mulakan perjalanan kesihatan anda ✨';

  @override
  String get allDosesTaken => 'Semua dos diambil hari ini! 🌟';

  @override
  String dosesOverdue(int count) {
    return '$count dos tertunggak — ambil sekarang ⚠️';
  }

  @override
  String dosesLeft(int count) {
    return '$count dos lagi hari ini';
  }

  @override
  String get healthReportTitle => 'Laporan Kesihatan MedAI';

  @override
  String get medicalSummarySubtitle =>
      'Ringkasan Perubatan Peribadi & Trend Pematuhan';

  @override
  String patientLabel(String name) {
    return 'Pesakit: $name';
  }

  @override
  String reportDate(String date) {
    return 'Tarikh: $date';
  }

  @override
  String get overallAdherence => 'Pematuhan Keseluruhan';

  @override
  String get activeMedications => 'Ubat Aktif';

  @override
  String get reportPeriod => 'Tempoh Laporan';

  @override
  String get last30Days => '30 Hari Lepas';

  @override
  String get currentMedications => 'Ubat Semasa';

  @override
  String get medicineCol => 'Ubat';

  @override
  String get doseCol => 'Dos';

  @override
  String get frequencyCol => 'Kekerapan';

  @override
  String get stockRemainingCol => 'Stok Berbaki';

  @override
  String get recentSymptoms => 'Simptom & Kesihatan Terkini';

  @override
  String get symptomDateCol => 'Tarikh';

  @override
  String get symptomNameCol => 'Simptom';

  @override
  String get severityCol => 'Keterukan';

  @override
  String get notesCol => 'Nota';

  @override
  String get noSymptomsLogged => 'Tiada simptom direkod dalam tempoh ini.';

  @override
  String get reportFooter =>
      'Dijana oleh MedAI Pro. Laporan ini adalah untuk tujuan maklumat sahaja dan perlu disemak oleh profesional penjagaan kesihatan yang berkelayakan.';

  @override
  String get settingsStats => 'Statistik';

  @override
  String get settingsApp => 'Tetapan Apl';

  @override
  String get settingsData => 'Data & Privasi';

  @override
  String get settingsGlobal => 'Tetapan Global';

  @override
  String get settingsProfile => 'Profil Saya';

  @override
  String get adherenceLabel => 'PEMATUHAN';

  @override
  String get streakLabel => 'RENTETAN';

  @override
  String streakDays(int count) {
    return '$count Hari';
  }

  @override
  String get generateClinicalReport => 'JANA LAPORAN KLINIKAL';

  @override
  String get fetchingAiInsights => 'MENDAPATKAN CERAPAN AI...';

  @override
  String get aiCoachDisclaimer =>
      'Papan pemuka ini menggunakan AI untuk menganalisis corak. Sentiasa rujuk doktor anda untuk nasihat perubatan.';

  @override
  String get insightsTitle => 'Cerapan';

  @override
  String get insightsSubtitle => 'Analitik & corak kesihatan';

  @override
  String get dataSummaryTitle => 'RINGKASAN DATA ANDA';

  @override
  String get dataMedicinesLabel => 'Ubat';

  @override
  String get dataAlarmsLabel => 'Penggera ditetapkan';

  @override
  String get dataDaysTrackedLabel => 'Hari dijejak';

  @override
  String get dataDosesLoggedLabel => 'Dos direkod';

  @override
  String get exportAndBackup => 'Eksport & Sandaran';

  @override
  String get exportPdfReport => 'Eksport Laporan PDF';

  @override
  String get exportPdfSubtitle => 'Untuk doktor dan penjaga';

  @override
  String get exportCsv => 'Eksport Sejarah sebagai CSV';

  @override
  String exportCsvSubtitle(int count) {
    return '$count rekod dos';
  }

  @override
  String get resetSection => 'Set Semula';

  @override
  String get deleteAllData => 'Padam Semua Data';

  @override
  String get deleteAllDataSubtitle =>
      'Mengalih keluar semua ubat, sejarah & tetapan';

  @override
  String get deleteConfirmTitle => 'Padam Semua Data?';

  @override
  String get deleteConfirmBody =>
      'Ini akan memadamkan semua data anda secara kekal. Tindakan ini tidak boleh dibatalkan.';

  @override
  String get deleteButton => 'Padam Semua';

  @override
  String get legalSection => 'Undang-undang';

  @override
  String get privacyPolicy => 'Dasar Privasi';

  @override
  String get privacyPolicySubtitle =>
      'Cara kami melindungi data kesihatan anda';

  @override
  String get termsOfService => 'Terma Perkhidmatan';

  @override
  String get termsOfServiceSubtitle => 'Peraturan menggunakan MedAI';

  @override
  String get appVersionLabel => 'Versi Apl';

  @override
  String get appVersionValue => '1.0.0+1';

  @override
  String get analysisFailed => 'Analisis Gagal';

  @override
  String get somethingWentWrong => 'Sesuatu tidak kena. Sila cuba lagi.';

  @override
  String get retry => 'Cuba Lagi';

  @override
  String get onboardingSkip => 'Langkau';

  @override
  String get onboardingNext => 'Seterusnya';

  @override
  String get onboardingContinue => 'Teruskan';

  @override
  String get onboardingGetStarted => 'Mula';

  @override
  String get onboardingWelcomeTitle => 'Bina tabiat ubat\nyang tak tergoyah';

  @override
  String get onboardingWelcomeBody =>
      'Rentetan, peringatan pintar dan AI yang memastikan anda kekal di landasan — setiap hari.';

  @override
  String get onboardingScanTitle => 'Imbas apa-apa pil\ndalam beberapa saat';

  @override
  String get onboardingScanBodyDemo =>
      'Ketik di bawah untuk melihat AI mengenal pasti ubat sampel serta-merta.';

  @override
  String get onboardingScanBodyDone =>
      'Begitulah pantasnya Med AI. Tiada menaip, tiada tekaan.';

  @override
  String get onboardingSimulateScan => 'Simulasi imbasan →';

  @override
  String get onboardingPermissionTitle => 'Kamera anda,\nprivasi anda';

  @override
  String get onboardingPermissionBody =>
      'Kami hanya menggunakan kamera untuk membaca label pil. Imej diproses dengan selamat dan tidak pernah dijual.';

  @override
  String get onboardingPermissionLink =>
      'Ketahui cara kami melindungi data anda';

  @override
  String get onboardingPersonalizeTitle => 'Peribadikan\npengalaman anda';

  @override
  String get onboardingQuizMedCount => 'Berapa banyak ubat?';

  @override
  String get onboardingQuizRole => 'Untuk siapa anda menjejak?';

  @override
  String get onboardingQuizSchedule => 'Bila anda ambil kebanyakan ubat?';

  @override
  String get onboardingRoleSelf => 'Diri sendiri';

  @override
  String get onboardingRoleCaregiver => 'Seseorang yang saya jaga';

  @override
  String get onboardingScheduleMorning => 'Pagi';

  @override
  String get onboardingScheduleEvening => 'Malam';

  @override
  String get onboardingScheduleBoth => 'Kedua-duanya';

  @override
  String get onboardingSocialTitle => 'Sertai 50,000+\njuara kesihatan';

  @override
  String get onboardingSocialQuote =>
      '“Med AI mengubah cara keluarga saya menguruskan ubat. Ciri imbasan sahaja menjimatkan 10 minit sehari.”';

  @override
  String get onboardingSocialAttribution => '— Ulasan App Store, 5 bintang';

  @override
  String get onboardingAllowCamera => 'Benarkan Akses Kamera';

  @override
  String get onboardingTryDemoScan => 'Cuba Imbasan Demo';

  @override
  String get loadingHealthData => 'Memuatkan data kesihatan anda…';

  @override
  String get appstateFamilyUpdate => 'Family Update';

  @override
  String get wellnesscontrollerEveningRoutineRisk => 'Evening Routine Risk';

  @override
  String get wellnesscontrollerWeekendPatternChange => 'Weekend Pattern Change';

  @override
  String get alarmsUpcoming => 'Upcoming';

  @override
  String get alarmsLoggedSuccessfully => 'Logged successfully';

  @override
  String get alarmsSlideToRecordDose => 'Slide to record dose →';

  @override
  String get alarmsDoseRecorded => '✓ Dose Recorded';

  @override
  String get alarmsNeedsSchedule => 'Needs schedule';

  @override
  String get alarmsLabel => 'Label';

  @override
  String get alarmsReminders => 'Reminders';

  @override
  String get alarmsPaused => 'Paused';

  @override
  String get alarmsAddReminder => 'Add reminder';

  @override
  String get alarmsSlideToRecordDose2 => 'Slide to record dose';

  @override
  String get alarmsNoRemindersYet => 'No reminders yet';

  @override
  String get alarmsSetReminderFor => 'Set reminder for';

  @override
  String get analysisKnowYourMedicine => 'Know your medicine';

  @override
  String get analysisScanAgain => 'Scan again';

  @override
  String get analysisAiIdentificationAlwaysVerifyWithYour =>
      'AI identification — always verify with your pharmacist or prescriber.';

  @override
  String get analysisScanResult => 'Scan result';

  @override
  String get analysisSmartTrustedBuiltForYou =>
      'Smart · trusted · built for you';

  @override
  String get analysisMorningDose => 'Morning Dose';

  @override
  String get analysisSafetyFirst => 'Safety first';

  @override
  String get analysisAllergyAlerts => 'Allergy alerts';

  @override
  String get analysisChildSafety => 'Child safety';

  @override
  String get analysisPregnancyNursing => 'Pregnancy & nursing';

  @override
  String get analysisSkincareNotes => 'Skincare notes';

  @override
  String get analysisQuickInsights => 'Quick insights';

  @override
  String get analysisTiming => 'Timing';

  @override
  String get analysisEvidence => 'Evidence';

  @override
  String get analysisHalal => 'Halal';

  @override
  String get analysisAllergyRisk => 'Allergy risk';

  @override
  String get analysisSideEffectMap => 'Side-effect map';

  @override
  String get analysisOverview => 'Overview';

  @override
  String get analysisHowThisSupportsYou => 'How this supports you';

  @override
  String get analysisBenefits => 'Benefits';

  @override
  String get analysisInteractions => 'Interactions';

  @override
  String get analysisExpertPerspectives => 'Expert perspectives';

  @override
  String get analysisPersonalisedWithContextFromYourCurrent =>
      'Personalised with context from your current medications.';

  @override
  String get analysisAiAssistant => 'AI Assistant';

  @override
  String get analysisAskAboutInteractionsTiming =>
      'Ask about interactions, timing…';

  @override
  String get analysisAiIsTyping => 'AI is typing';

  @override
  String get analysisIdentified => 'IDENTIFIED';

  @override
  String get analysisAtAGlance => 'AT A GLANCE';

  @override
  String get analysisChildDosingDiffers => 'Child dosing differs';

  @override
  String get analysisAiMatch => 'AI match';

  @override
  String get analysisSideEffects => 'Side effects';

  @override
  String get appshelldartRunningLow => 'Running low';

  @override
  String get appshelldartCameraAccess => 'Camera Access';

  @override
  String get appshelldartDismiss => 'Dismiss';

  @override
  String get appshelldartAddAMedicineByScanning => 'Add a medicine by scanning';

  @override
  String get authHaveAnInviteCode => 'Have an invite code?';

  @override
  String get authApply => 'Apply';

  @override
  String get authByContinuingYouAgreeToOur =>
      'By continuing, you agree to our ';

  @override
  String get authAnd => ' and ';

  @override
  String get authForgotPassword => 'Forgot password?';

  @override
  String get authInviteApplied => 'Invite applied';

  @override
  String get authEmailSent => 'Email Sent';

  @override
  String get authMedAiMascot => 'Med AI mascot';

  @override
  String get authContinueWithApple => 'Continue with Apple';

  @override
  String get authContinueWithGoogle => 'Continue with Google';

  @override
  String get authContinueWithEmail => 'Continue with Email';

  @override
  String get authTerms => 'Terms';

  @override
  String get authHaveAnInviteCode2 => 'Have an invite code';

  @override
  String get authEmailAddress => 'Email address';

  @override
  String get authPassword => 'Password';

  @override
  String get authForgotPassword2 => 'Forgot password';

  @override
  String get authEnterPin => 'Enter PIN';

  @override
  String get dashboardSupplyStatus => 'Supply status';

  @override
  String get dashboardAiInsights => 'AI insights';

  @override
  String get dashboardExportDataAsCsv => 'Export data as CSV';

  @override
  String get dashboardConnectHealthData => 'Connect health data';

  @override
  String get dashboardSyncStepsAndHeartRateAlongside =>
      'Sync steps and heart rate alongside your meds.';

  @override
  String get dashboardN7DayTrendBelow => '7-day trend below';

  @override
  String get dashboardYourWeekAtAGlance => 'Your week at a glance';

  @override
  String get dashboardMedicationDiary => 'Medication diary';

  @override
  String get dashboardMenu => 'Menu';

  @override
  String get dashboardDoses => 'Doses';

  @override
  String get dashboardDailyAvg => 'Daily avg';

  @override
  String get dashboardNoDosesLogged => 'No doses logged';

  @override
  String get dashboardLogDosesToUnlockYourWeekly =>
      'Log doses to unlock your weekly trend';

  @override
  String get dashboardDayStreak => 'Day streak';

  @override
  String get dashboardHeartRate => 'Heart rate';

  @override
  String get dashboardDosesThisWeek => 'Doses this week';

  @override
  String get dashboardStepsToday => 'Steps today';

  @override
  String get dashboardSearch => 'Search';

  @override
  String get dashboardAnalytics => 'Analytics';

  @override
  String get dashboardAdherenceHealthTrends => 'Adherence & health trends';

  @override
  String get dashboardOpenDailyLog => 'Open daily log';

  @override
  String get dashboardTimingConsistency => 'Timing consistency';

  @override
  String get dashboardAdherenceTrend => 'Adherence trend';

  @override
  String get dashboardN30DayProgress => '30-Day Progress';

  @override
  String get dashboardN30DaysAgo => '30 days ago';

  @override
  String get dashboardToday => 'Today';

  @override
  String get dashboardAnalyzingYourData => 'Analyzing your data';

  @override
  String get dashboardNoTimingDataYet => 'No timing data yet';

  @override
  String get dashboardRefreshAiInsights => 'Refresh AI insights';

  @override
  String get dashboardAiInsightsWillAppearHere =>
      'AI insights will appear here';

  @override
  String get dashboardNoTrendYet => 'No trend yet';

  @override
  String get dashboardNoInventoryTracked => 'No inventory tracked';

  @override
  String get familyCriticalProfile => 'Critical Profile';

  @override
  String get familyPrioritizeNotificationsAndAlerts =>
      'Prioritize notifications and alerts';

  @override
  String get familyAddCaregiver => 'Add Caregiver';

  @override
  String get familyAvatar => 'Avatar';

  @override
  String get familySaveCaregiver => 'Save Caregiver';

  @override
  String get familyTapToAddPhoto => 'Tap to add photo';

  @override
  String get familyCriticalCareMember => 'Critical Care Member';

  @override
  String get familyPrioritizeAlertsAndMonitoring =>
      'Prioritize alerts and monitoring';

  @override
  String get familyAddMember => 'Add Member';

  @override
  String get familyAddProfilePhoto => 'Add profile photo';

  @override
  String get familySaveProfile => 'Save Profile';

  @override
  String get familyRemoveMember => 'Remove Member';

  @override
  String get familyRemove => 'Remove';

  @override
  String get familyTapToChangePhoto => 'Tap to change photo';

  @override
  String get familyEditMember => 'Edit Member';

  @override
  String get familyChangeProfilePhoto => 'Change profile photo';

  @override
  String get familyUpdateMember => 'Update member';

  @override
  String get familyAddGuardian => 'Add guardian';

  @override
  String get familyUrgentMonitoring => 'Urgent monitoring';

  @override
  String get familySensitiveMedsInThisCircleCaregivers =>
      'Sensitive meds in this circle — caregivers should review warnings before dose time.';

  @override
  String get familySwitchToProfile => 'Switch to Profile';

  @override
  String get familyGenerateAdherencePdf => 'Generate Adherence PDF';

  @override
  String get familyRemoveProfile => 'Remove profile?';

  @override
  String get familyRemoveProfile2 => 'Remove Profile';

  @override
  String get familyProtectors => 'Protectors';

  @override
  String get familyMonitoring => 'Monitoring';

  @override
  String get familyFamily => 'Family';

  @override
  String get familyCare => 'Care';

  @override
  String get familyManaging => 'Managing';

  @override
  String get familyRecentActivity => 'Recent activity';

  @override
  String get familyNoGuardiansFound => 'No guardians found';

  @override
  String get familyProtectYourFamily => 'Protect your family';

  @override
  String get familyJoinFamilyCircle => 'Join family circle';

  @override
  String get familyInviteGuardian => 'Invite guardian';

  @override
  String get familyEnterProfilePinToSwitch => 'Enter profile PIN to switch';

  @override
  String get familyIncorrectPin => 'Incorrect PIN';

  @override
  String get familyDelete => 'Delete';

  @override
  String get familySwitchProfile => 'Switch profile';

  @override
  String get familyManageSchedulesForYourFamily =>
      'Manage schedules for your family';

  @override
  String get familyAddDependent => 'Add dependent';

  @override
  String get familyScanFromCaregiverApp => 'Scan from caregiver app';

  @override
  String get familyOrUseInviteCode => 'Or use invite code';

  @override
  String get familyCopyCode => 'Copy code';

  @override
  String get familyWaitingForCaregiverToScan =>
      'Waiting for caregiver to scan...';

  @override
  String get familySuccessCaregiverAdded => 'Success! Caregiver added.';

  @override
  String get familyActive => 'Active';

  @override
  String get familyEGSarahJohnson => 'e.g. Sarah Johnson';

  @override
  String get familyGenerateQrCode => 'Generate QR code';

  @override
  String get familyQrCodeForCaregiverInvite => 'QR code for caregiver invite';

  @override
  String get familyCopyInviteCode => 'Copy invite code';

  @override
  String get familyTheyCanNow => 'They can now:';

  @override
  String get familySeeYourDailyAdherence => 'See your daily adherence';

  @override
  String get familyGetMissedDoseAlerts => 'Get missed-dose alerts';

  @override
  String get familyViewYourMedicineList => 'View your medicine list';

  @override
  String get familyDone => 'Done';

  @override
  String get familyMedaiProtectorAdvisor => 'MedAI protector advisor';

  @override
  String get familyIntelligentCareAnalysis => 'Intelligent care analysis';

  @override
  String get familyPatternsAnalyzedAcrossLast7Days =>
      'Patterns analyzed across last 7 days';

  @override
  String get familyNew => 'New';

  @override
  String get familySafetySimulationOfHowMissedDoses =>
      'Safety simulation of how missed doses trigger household alerts.';

  @override
  String get familyCriticalAlertSent => 'Critical alert sent';

  @override
  String get familySarahJMissedTheirBloodPressure =>
      'Sarah J. missed their Blood Pressure medication. Please check on them immediately.';

  @override
  String get familyEscalationProtocol => 'Escalation protocol';

  @override
  String get familyPrevious => 'Previous';

  @override
  String get familyCriticalAlert => 'Critical alert';

  @override
  String get familyCritical => 'Critical';

  @override
  String get familySafetyProtocol => 'Safety protocol';

  @override
  String get familyWaiting => 'Waiting';

  @override
  String get familyTestAlertCycle => 'Test Alert Cycle';

  @override
  String get familySimulateAMissedDoseAlert => 'Simulate a missed dose alert';

  @override
  String get familyJoinAsCaregiver => 'Join as Caregiver';

  @override
  String get familyScanTheQrCodeOrEnter =>
      'Scan the QR code or enter the invite code to start monitoring.';

  @override
  String get familyOrEnterCode => 'OR ENTER CODE';

  @override
  String get familyClose => 'Close';

  @override
  String get familyQrCodeScanner => 'QR code scanner';

  @override
  String get familyInviteCode => 'Invite code';

  @override
  String get familyVerifyAndJoin => 'Verify and Join';

  @override
  String get familyWeeklyAdherence => 'Weekly Adherence';

  @override
  String get familyLast7Days => 'Last 7 Days';

  @override
  String get familyProFeature => 'Pro feature';

  @override
  String get familyRemoteMonitoringRequiresAProSubscription =>
      'Remote monitoring requires a Pro subscription.';

  @override
  String get familyUpgradeToPro => 'Upgrade to Pro';

  @override
  String get focusFocusMode => 'Focus mode';

  @override
  String get focusStartFocus => 'Start focus';

  @override
  String get homeAfternoon => 'Afternoon';

  @override
  String get homeNight => 'Night';

  @override
  String get homeLogDose => 'Log Dose';

  @override
  String get homeLogDoseWithAi => 'Log dose with AI';

  @override
  String get homeCompleteYourProfile => 'Complete Your Profile';

  @override
  String get homeUnlockMorePersonalisedInsights =>
      'Unlock more personalised insights';

  @override
  String get homeHowOldAreYou => 'How old are you?';

  @override
  String get homeAddYourAge => 'Add your age';

  @override
  String get homeSetYourGender => 'Set your gender';

  @override
  String get homeWhenDoYouForget => 'When do you forget?';

  @override
  String get homeDoctorVisits => 'Doctor visits';

  @override
  String get homeWhatMotivatesYou => 'What motivates you?';

  @override
  String get homeSave => 'Save';

  @override
  String get homeSaveSelection => 'Save selection';

  @override
  String get homeYesterday => 'Yesterday';

  @override
  String get homeCriticalMedicalAdvisory => 'CRITICAL MEDICAL ADVISORY';

  @override
  String get homeCallEmergencyServices911 => 'CALL EMERGENCY SERVICES (911)';

  @override
  String get homeBreatheRelaxAndCenterYourself =>
      'Breathe, relax, and center yourself.';

  @override
  String get homeFocusModeBreatheRelaxAndCenter =>
      'Focus mode. Breathe, relax, and center yourself.';

  @override
  String get homeDoseLogged => 'Dose logged';

  @override
  String get homeOpenSettings => 'Open settings';

  @override
  String get homeMadeForYou => 'MADE FOR YOU';

  @override
  String get homeCoaching => 'Coaching';

  @override
  String get homeMedaiCompanion => 'MedAI companion';

  @override
  String get homeLive => 'Live';

  @override
  String get homeMascotShop => 'Mascot shop';

  @override
  String get homeMedaiCompanionTapForANew =>
      'MedAI companion. Tap for a new coaching message.';

  @override
  String get homeRecentlyUploaded => 'Recently uploaded';

  @override
  String get homeNoMedications => 'No medications';

  @override
  String get homeScanAMedicine => 'Scan a medicine';

  @override
  String get homeOrEnterItManually => 'Or enter it manually';

  @override
  String get homeDailyProgress => 'Daily Progress';

  @override
  String get homeMood => 'Mood';

  @override
  String get homePreviousWeek => 'Previous week';

  @override
  String get homeNextWeek => 'Next week';

  @override
  String get homeBodyImpact => 'Body Impact 🧬';

  @override
  String get homeVisualizeMedicationAbsorption =>
      'Visualize medication absorption 🚀';

  @override
  String get homeBodyImpactVisualizerVisualizeMedicationAbsorption =>
      'Body impact visualizer. Visualize medication absorption.';

  @override
  String get homeWarning => 'Warning';

  @override
  String get homeInteraction => 'Interaction';

  @override
  String get homeHowToTake => 'How to take';

  @override
  String get homeImportant => 'Important';

  @override
  String get homeRefill => 'Refill';

  @override
  String get homeOnTrack => 'On track';

  @override
  String get homeBodyImpact2 => 'Body impact';

  @override
  String get homeAdd => 'Add';

  @override
  String get homeAddFamilyProfile => 'Add family profile';

  @override
  String get homeShortTermCourse => 'Short-term course';

  @override
  String get homeRecoveryModeActive => 'Recovery mode active';

  @override
  String get homeEnjoyingMedai => 'Enjoying MedAI?';

  @override
  String get homeYourFeedbackHelpsUsImproveFor =>
      'Your feedback helps us improve for everyone.';

  @override
  String get homeNotifications => 'Notifications';

  @override
  String get homeDoseReminders => 'Dose Reminders';

  @override
  String get homeReminderSound => 'Reminder Sound';

  @override
  String get homeHaptics => 'Haptics';

  @override
  String get homePersistentAlarms => 'Persistent Alarms';

  @override
  String get homeRefillAlerts => 'Refill Alerts';

  @override
  String get homeReminderTiming => 'Reminder Timing';

  @override
  String get homeCaregiverProfiles => 'Caregiver & Profiles';

  @override
  String get homeFamilyDependents => 'Family & Dependents';

  @override
  String get homeAestheticsTheme => 'Aesthetics & Theme';

  @override
  String get homeAppAppearance => 'App Appearance';

  @override
  String get homeHealthWellness => 'Health & Wellness';

  @override
  String get homeHealthDataAccess => 'Health Data Access';

  @override
  String get homeSecurity => 'Security';

  @override
  String get homeBiometricLock => 'Biometric Lock';

  @override
  String get homeSupportFeedback => 'Support & Feedback';

  @override
  String get homeInviteFriendsGiveAFreeMonth =>
      'Invite friends — give a free month';

  @override
  String get homeAppInfo => 'App Info';

  @override
  String get homePrivacy => 'Privacy';

  @override
  String get homeDeleteAccount => 'Delete Account';

  @override
  String get homeYourData => 'Your data';

  @override
  String get homeYourSuccessPlan => 'Your success plan';

  @override
  String get homeUnlockAiInsightsFamilyCareUnlimited =>
      'Unlock AI insights, family care & unlimited scans.';

  @override
  String get homePro => 'PRO';

  @override
  String get homeMedai1001 => 'MedAI 1.0.0+1';

  @override
  String get homeMadeByTheMedaiTeam => 'Made by the MedAI team';

  @override
  String get homeUpgradeToMedaiPro => 'Upgrade to MedAI Pro';

  @override
  String get homeName => 'Name';

  @override
  String get homeAge => 'Age';

  @override
  String get homeGender => 'Gender';

  @override
  String get homePrimaryGoal => 'Primary Goal';

  @override
  String get homeYourInfo => 'Your Info';

  @override
  String get homeHealthGoal => 'Health Goal';

  @override
  String get homeConditions => 'Conditions';

  @override
  String get homeSubscription => 'Subscription';

  @override
  String get homeManageSubscription => 'Manage Subscription';

  @override
  String get homeRestorePurchases => 'Restore Purchases';

  @override
  String get homeDataReports => 'Data & Reports';

  @override
  String get homeClinicalPdfReport => 'Clinical PDF Report';

  @override
  String get homeMedWrapped2026 => 'Med Wrapped 2026';

  @override
  String get homeExportCsvData => 'Export CSV Data';

  @override
  String get homeAccount => 'Account';

  @override
  String get homeSignOut => 'Sign Out';

  @override
  String get homeSignInWithGoogle => 'Sign in with Google';

  @override
  String get homeSignInWithApple => 'Sign in with Apple';

  @override
  String get homeContactSupport => 'Contact Support';

  @override
  String get homeRateMedai => 'Rate MedAI';

  @override
  String get homeLegalPrivacy => 'Legal & Privacy';

  @override
  String get homeOpenSourceLicenses => 'Open Source Licenses';

  @override
  String get homeDeveloperOptions => 'Developer Options';

  @override
  String get homeGrowthAnalyticsDashboard => 'Growth & Analytics Dashboard';

  @override
  String get homeYourSuccessScore => 'Your success score';

  @override
  String get homeSmartPatterns => 'Smart patterns';

  @override
  String get homeLeft => 'left';

  @override
  String get homePrecisionOverview => 'Precision Overview';

  @override
  String get homeDosesTaken => 'Doses Taken';

  @override
  String get homeN7DayRate => '7-Day Rate';

  @override
  String get homeCurrentStreak => 'Current Streak';

  @override
  String get homeThisWeek => 'This Week';

  @override
  String get homeHealthStory => 'Health Story';

  @override
  String get homeNoSymptomsRecorded => 'No symptoms recorded';

  @override
  String get homeInventoryForecast => 'Inventory Forecast';

  @override
  String get homeNoMedicationsTracked => 'No medications tracked';

  @override
  String get homeMadeForYouManageWithConfidence =>
      'Made for you — manage with confidence';

  @override
  String get homeYourSuccessSettingsRemindersSafetyAnd =>
      'Your success settings — reminders, safety, and share.';

  @override
  String get homeCloseSettings => 'Close settings';

  @override
  String get homeYourStreak => 'Your streak';

  @override
  String get homeDays => 'days';

  @override
  String get homeBest => 'Best';

  @override
  String get homeTotalLogged => 'Total logged';

  @override
  String get homeShareStreak => 'Share streak';

  @override
  String get homeGoPro => 'Go Pro';

  @override
  String get homeUnlockUnlimitedScansInteractionChecksAnd =>
      'Unlock unlimited scans, interaction checks, and more with Pro.';

  @override
  String get homeCloseVoiceAssistant => 'Close voice assistant';

  @override
  String get loadingPreparingYourHealthWorkspace =>
      'Preparing your health workspace';

  @override
  String get medicineAddMedicine => 'Add medicine';

  @override
  String get medicineWhatAreYouTaking => 'What are you taking?';

  @override
  String get medicineSearchOrTypeTheMedicineName =>
      'Search or type the medicine name to get started.';

  @override
  String get medicineWhenDoYouTakeThis => 'When do you take this?';

  @override
  String get medicineRemindMe => 'Remind me';

  @override
  String get medicineGetANotificationWhenItS =>
      'Get a notification when it’s time';

  @override
  String get medicineMedicationName => 'Medication name';

  @override
  String get medicineEGLisinopril => 'e.g. Lisinopril';

  @override
  String get medicineAddMedication => 'Add medication';

  @override
  String get medicineCompleteTheFullCourse => 'Complete the full course';

  @override
  String get medicineThisAntibioticMustBeFinishedEntirely =>
      'This antibiotic must be finished entirely. Do not stop early, even if symptoms improve — unfinished courses can drive resistance.';

  @override
  String get medicineStockLevel => 'Stock level';

  @override
  String get medicineRestock => 'Restock';

  @override
  String get medicineUnits => 'Units';

  @override
  String get medicineActiveDays => 'ACTIVE DAYS';

  @override
  String get medicineMealRitual => 'MEAL RITUAL';

  @override
  String get medicineN28DayActivityLog => '28 DAY ACTIVITY LOG';

  @override
  String get medicineMissed => 'Missed';

  @override
  String get medicineTaken => 'Taken';

  @override
  String get medicineAccentColor => 'ACCENT COLOR';

  @override
  String get medicineCategory => 'CATEGORY';

  @override
  String get medicineLogging => 'Logging...';

  @override
  String get medicineLogged => 'Logged!';

  @override
  String get medicineEditMedicine => 'Edit medicine';

  @override
  String get medicineCancelEditing => 'Cancel editing';

  @override
  String get medicineViewFullAiAnalysis => 'View Full AI Analysis';

  @override
  String get medicineRestockInventory => 'Restock inventory';

  @override
  String get medicineConfirmRestock => 'Confirm restock';

  @override
  String get medicineAddSlot => 'Add slot';

  @override
  String get medicineEditReminder => 'Edit Reminder';

  @override
  String get medicineHistory => 'History';

  @override
  String get medicineScore => 'Score';

  @override
  String get medicineForm => 'Form';

  @override
  String get medicineUnit => 'Unit';

  @override
  String get medicineStart => 'Start';

  @override
  String get medicineSpecifications => 'Specifications';

  @override
  String get medicineQuickRefill10 => 'Quick refill (+10)';

  @override
  String get medicineRemoveMedicine => 'Remove medicine';

  @override
  String get medicineVisuals => 'Visuals';

  @override
  String get medicineIdentity => 'Identity';

  @override
  String get medicineMedicineName => 'Medicine Name';

  @override
  String get medicineBrandName => 'Brand Name';

  @override
  String get medicineConfiguration => 'Configuration';

  @override
  String get medicineDosage => 'Dosage';

  @override
  String get medicineIntakeInstructions => 'Intake Instructions';

  @override
  String get medicineInventoryRefills => 'Inventory & refills';

  @override
  String get medicineCurrentCount => 'Current Count';

  @override
  String get medicineTotalBoxCount => 'Total Box Count';

  @override
  String get medicineRefillAlertAt => 'Refill Alert At';

  @override
  String get medicinePharmacyDetails => 'Pharmacy details';

  @override
  String get medicinePharmacyName => 'Pharmacy Name';

  @override
  String get medicinePrice => 'Price';

  @override
  String get medicineSaveReminder => 'Save reminder';

  @override
  String get medicineNone => 'None';

  @override
  String get medicineDidYouKnow => 'Did you know?';

  @override
  String get medicineAskAiAssistantAboutThis => 'Ask AI Assistant About This';

  @override
  String get medicineCourseCompleted => 'Course Completed!';

  @override
  String get medicineAchievementUnlocked => 'Achievement Unlocked';

  @override
  String get medicineN100AdherenceForThisCourse =>
      '100% Adherence for this course';

  @override
  String get medicineArchiveFinish => 'ARCHIVE & FINISH';

  @override
  String get medicineMedaiCoach => 'MedAI Coach';

  @override
  String get medicineMechanismSpecs => 'Mechanism & Specs';

  @override
  String get medicineAskAQuestion => 'Ask a question…';

  @override
  String get medicineWaitInteractionAlert => 'Wait! Interaction Alert';

  @override
  String get medicineGotIt => 'Got it';

  @override
  String get medicineAdjustTime => 'Adjust Time';

  @override
  String get medicineNoSpecialSafetyAlertsFoundFor =>
      'No special safety alerts found for this medication.';

  @override
  String get medicineAlert => 'Alert';

  @override
  String get onboardingDedicatedCaregiver => 'Dedicated Caregiver';

  @override
  String get onboardingFamilyHealthLead => 'Family Health Lead';

  @override
  String get onboardingHealthFocusedSenior => 'Health-Focused Senior';

  @override
  String get onboardingSelfManager => 'Self-Manager';

  @override
  String get onboardingSmartRemindersNotSetUpYet =>
      'Smart reminders not set up yet';

  @override
  String get onboardingYou => 'YOU\\';

  @override
  String get onboardingManageMyFamilySMeds => 'Manage my family\'s meds';

  @override
  String get onboardingKnowItTrustItSucceedWith =>
      'Know it. *Trust it.* Succeed with it.';

  @override
  String get onboardingWhatSYourGender => 'What\'s your *gender*?';

  @override
  String get onboardingYouReInTheRightPlace => 'You\'re in the *right place*';

  @override
  String get onboardingWhatSYourBiggestChallenge =>
      'What\'s your biggest *challenge*?';

  @override
  String get onboardingYouReNotAlone => 'You\'re *not alone*';

  @override
  String get onboardingIWorryILlForgetAn =>
      'I worry I\'ll *forget* an important dose';

  @override
  String get onboardingDoYouKnowExactlyWhatS =>
      'Do you know exactly *what\'s in* every pill you take?';

  @override
  String get onboardingKnowWhatSWrongWithYour =>
      'Know what\'s *wrong* with your regimen';

  @override
  String get onboardingLetSUnderstandWhatDrivesYou =>
      'Let\'s understand what *drives* you';

  @override
  String get onboardingBeginMySuccess => 'Begin my success';

  @override
  String get onboardingSlideTheRuler => 'Slide the ruler';

  @override
  String get onboardingIUsuallyWakeUp => 'I usually wake up';

  @override
  String get onboardingIUsuallyGoToSleep => 'I usually go to sleep';

  @override
  String get onboardingMedAiAssistant => 'Med AI assistant';

  @override
  String get onboardingHoldToCommitToYourHealth =>
      'Hold to commit to your health goal';

  @override
  String get onboardingHoldToCommit => 'Hold to commit';

  @override
  String get onboardingHowMedAiHelpsYouNstay =>
      'How Med AI helps you\\nstay on track';

  @override
  String get onboardingThreeQuietMovesOneCalmRoutine =>
      'Three quiet moves. One calm routine.';

  @override
  String get onboardingAtorvastatin20mg => 'Atorvastatin 20mg';

  @override
  String get onboardingN94MatchIdentified => '94% match · Identified';

  @override
  String get onboardingYourScore => 'Your score';

  @override
  String get onboardingRemind => 'Remind';

  @override
  String get onboardingProtect => 'Protect';

  @override
  String get onboardingGoBack => 'Go back';

  @override
  String get onboardingAdherenceBaseline => 'Adherence baseline';

  @override
  String get onboardingMemoryOnly => 'Memory only';

  @override
  String get onboardingMedAiPlan => 'Med AI plan';

  @override
  String get onboardingMedCount => 'Med count';

  @override
  String get onboardingChallenge => 'Challenge';

  @override
  String get onboardingYes => 'Yes';

  @override
  String get onboardingMedAi => 'Med AI';

  @override
  String get onboardingYour1Plan => 'YOUR #1 PLAN';

  @override
  String get onboardingMedicationCompanion => 'Medication companion';

  @override
  String get onboardingScanKnowNeverMissADose =>
      'Scan. Know. Never miss a dose.';

  @override
  String get onboardingBuiltForPeopleManagingMoreThan =>
      'Built for people managing more than one medicine';

  @override
  String get onboardingFreeTrial => 'FREE TRIAL';

  @override
  String get onboardingFullAccessCancelAnytime =>
      'Full access. Cancel anytime.';

  @override
  String get onboardingOtherApps => 'Other apps';

  @override
  String get onboardingSkipOnboarding => 'Skip onboarding';

  @override
  String get paywallWaitNotReadyForAYear =>
      'Wait — not ready for a year? Try Med AI Pro by the week. Cancel anytime.';

  @override
  String get paywallRemindMeBeforeTheTrialEnds =>
      'Remind me before the trial ends';

  @override
  String get paywallMedAiPro => 'Med AI Pro';

  @override
  String get paywallFree => 'Free';

  @override
  String get paywallCancelAnytimeYourHealthDataIs =>
      'Cancel anytime · Your health data is never sold';

  @override
  String get paywallSubscriptionAutoRenewsUnlessCancelledAt =>
      'Subscription auto-renews unless cancelled at least 24 hours before the end of the current period. ';

  @override
  String get paywallUnlimitedAiScans => 'Unlimited AI Scans';

  @override
  String get paywallDoctorReportsPdf => 'Doctor Reports (PDF)';

  @override
  String get paywallUnlimitedMedications => 'Unlimited Medications';

  @override
  String get paywallStreakFreezeProtection => 'Streak Freeze Protection';

  @override
  String get paywallPriorityBiometricLock => 'Priority Biometric Lock';

  @override
  String get paywallAiDrugInteractions => 'AI Drug Interactions';

  @override
  String get paywallYourMedAiProTrialEnds =>
      'Your Med AI Pro trial ends tomorrow';

  @override
  String get paywallMedAiProSubscription => 'Med AI Pro subscription';

  @override
  String get paywallClosePaywall => 'Close paywall';

  @override
  String get paywallTermsOfUse => 'Terms of Use';

  @override
  String get scanConfidenceTarget => 'Confidence Target';

  @override
  String get scanFaster => 'Faster';

  @override
  String get scanMoreAccurate => 'More Accurate';

  @override
  String get scanAiAccuracy => 'AI Accuracy';

  @override
  String get scanRecognitionThreshold => 'Recognition Threshold';

  @override
  String get scanProcessingModes => 'Processing Modes';

  @override
  String get scanDeepSemanticAnalysis => 'Deep Semantic Analysis';

  @override
  String get scanAutoCropImages => 'Auto-Crop Images';

  @override
  String get scanClinicalMode => 'Clinical Mode';

  @override
  String get scanPrivacyModeNoLogging => 'Privacy Mode (No Logging)';

  @override
  String get scanCloseScanner => 'Close scanner';

  @override
  String get scanCameraUnavailable => 'Camera Unavailable';

  @override
  String get scanPillIdentifier => 'Pill Identifier';

  @override
  String get scanShapeColorImprint => 'Shape, color & imprint';

  @override
  String get scanShapeColorImprint2 => 'Shape · Color · Imprint';

  @override
  String get scanTrackMedicine => 'Track medicine';

  @override
  String get scanScanAnother => 'Scan another';

  @override
  String get scanScanHistory => 'Scan History';

  @override
  String get scanNoHistoryYet => 'No history yet';

  @override
  String get scanScanningTips => 'Scanning Tips';

  @override
  String get scanGoodLightingIsKey => 'Good Lighting is Key';

  @override
  String get scanKeepItCentered => 'Keep it Centered';

  @override
  String get scanScanTheNdcOrBarcode => 'Scan the NDC or Barcode';

  @override
  String get scanTryVoiceMode => 'Try Voice Mode';

  @override
  String get scanCanTFindItAddManually => 'Can\'t find it? Add manually';

  @override
  String get scanScanner => 'Scanner';

  @override
  String get scanAiMedicineRecognition => 'AI medicine recognition';

  @override
  String get scanManuallySearchForAnyMedicineOr =>
      'Manually search for any medicine or supplement.';

  @override
  String get scanScannerOptions => 'Scanner Options';

  @override
  String get scanScanMeds => 'Scan Meds';

  @override
  String get scanBarcode => 'Barcode';

  @override
  String get scanVoice => 'Voice';

  @override
  String get scanChooseFromLibrary => 'Choose from library';

  @override
  String get scanMetforminVitaminC => 'Metformin, Vitamin C...';

  @override
  String get scanSearchMedication => 'Search medication';

  @override
  String get scanAiAccuracySettings => 'AI Accuracy Settings';

  @override
  String get scanHelpTips => 'Help & Tips';

  @override
  String get scanSynergyScanner => 'Synergy scanner';

  @override
  String get scanTryAStraightOnPhotoOf =>
      'Try a straight-on photo of the label in good light, or scan another angle. You can still track it manually and fill in the details yourself.';

  @override
  String get scanDetailsBuiltForYouClearTrusted =>
      'Details built for you — clear, trusted, and ready to track.';

  @override
  String get scanCloseResults => 'Close results';

  @override
  String get scanScanConfidence => 'Scan confidence';

  @override
  String get scanNotConfirmedYet => 'Not confirmed yet';

  @override
  String get scanImportantWarnings => 'Important warnings';

  @override
  String get scanPackCourse => 'Pack & course';

  @override
  String get scanAbout => 'About';

  @override
  String get scanRegulatory => 'Regulatory';

  @override
  String get settingsResetCache => 'Reset cache?';

  @override
  String get settingsThisWillClearLocalTemporaryFiles =>
      'This will clear local temporary files. Your medications and health records will remain safe.';

  @override
  String get settingsLocalization => 'Localization';

  @override
  String get settingsDiabetesMetrics => 'Diabetes Metrics';

  @override
  String get settingsHypertensionTracking => 'Hypertension Tracking';

  @override
  String get settingsVitalConnectivity => 'Vital connectivity';

  @override
  String get settingsAutoSyncHealth => 'Auto-Sync Health';

  @override
  String get settingsThisDevice => 'This device';

  @override
  String get settingsClearLocalCache => 'Clear Local Cache';

  @override
  String get settingsSystem => 'System';

  @override
  String get settingsMedicalDisclaimer => 'Medical Disclaimer';

  @override
  String get settingsN1InformationWeCollect => '1. Information We Collect';

  @override
  String get settingsN2AiScanProcessing => '2. AI & Scan Processing';

  @override
  String get settingsN3FamilyCaregiverSharing =>
      '3. Family & Caregiver Sharing';

  @override
  String get settingsN4ThirdPartyServices => '4. Third-Party Services';

  @override
  String get settingsN5DataRetention => '5. Data Retention';

  @override
  String get settingsN6Security => '6. Security';

  @override
  String get settingsN7YourRightsGdprCcpa => '7. Your Rights (GDPR / CCPA)';

  @override
  String get settingsN8Children => '8. Children\\';

  @override
  String get settingsN9YourDataYourControl => '9. Your Data, Your Control';

  @override
  String get settingsN10ContactUpdates => '10. Contact & Updates';

  @override
  String get settingsViewFullPrivacyPolicyOnline =>
      'View full privacy policy online';

  @override
  String get settingsN1AcceptanceOfTerms => '1. Acceptance of Terms';

  @override
  String get settingsN2NotMedicalAdvice => '2. Not Medical Advice';

  @override
  String get settingsN3UserAccounts => '3. User Accounts';

  @override
  String get settingsN4AcceptableUse => '4. Acceptable Use';

  @override
  String get settingsN5PremiumSubscriptions => '5. Premium Subscriptions';

  @override
  String get settingsN6AppleHealthHealthConnect =>
      '6. Apple Health & Health Connect';

  @override
  String get settingsN7LimitationOfLiability => '7. Limitation of Liability';

  @override
  String get settingsN8ContactInformation => '8. Contact Information';

  @override
  String get settingsViewFullTermsOnline => 'View full terms online';

  @override
  String get settingsMoreThemesComingSoon => 'More themes coming soon!';

  @override
  String get settingsUnlockExclusiveAestheticsWithStreaks =>
      'Unlock exclusive aesthetics with streaks.';

  @override
  String get settingsAppIcons => 'App Icons';

  @override
  String get settingsDeleteAccount => 'Delete account?';

  @override
  String get settingsThisPermanentlyErasesYourMedicationHistory =>
      'This permanently erases your medication history, schedules and health records from this device and our servers. It cannot be undone, and support cannot restore it.';

  @override
  String get settingsKeepMyAccount => 'Keep my account';

  @override
  String get settingsDeleteForever => 'Delete forever';

  @override
  String get socialMedBuddies => 'Med buddies';

  @override
  String get socialNoBuddiesConnectedYet => 'No buddies connected yet';

  @override
  String get socialYourArchetype => 'YOUR ARCHETYPE';

  @override
  String get socialCalculatedBasedOnYourHistoricalDose =>
      'Calculated based on your historical dose logging timestamp profiles.';

  @override
  String get socialHabitArchitectureLocked => 'Habit Architecture Locked.';

  @override
  String get socialKeepSharingYourConsistencyYouInspire =>
      'Keep sharing your consistency. You inspire others to optimize their routines.';

  @override
  String get socialTapLeftToGoBackRight =>
      'Tap left to go back, right to go forward';

  @override
  String get socialYourYearInConsistencyQuantified =>
      'Your year in consistency, quantified.';

  @override
  String get socialTotalDosesLoggedAndVerifiedBy =>
      'Total doses logged and verified by AI.';

  @override
  String get socialDayStreakWasYourMaximumMomentum =>
      'Day streak was your maximum momentum.';

  @override
  String get socialOverallAdherenceScoreThisYear =>
      'Overall adherence score this year.';

  @override
  String get socialShareWrapped => 'Share Wrapped';

  @override
  String get statsWeeklyPerformance => 'Weekly performance';

  @override
  String get statsShareWithYourDoctor => 'Share with your doctor';

  @override
  String get statsExportAClinicalPdfOfYour =>
      'Export a clinical PDF of your adherence & meds';

  @override
  String get statsSymptoms => 'Symptoms';

  @override
  String get statsTrendAnalysis => 'Trend analysis';

  @override
  String get statsExplore => 'Explore';

  @override
  String get statsStockLevelsRefillAlerts => 'Stock levels & refill alerts';

  @override
  String get statsMonthlyWrapped => 'Monthly wrapped';

  @override
  String get statsViewYourStats => 'View your stats';

  @override
  String get statsSocial => 'Social';

  @override
  String get statsMedBuddiesLeaderboards => 'Med buddies & leaderboards';

  @override
  String get statsAchievements => 'Achievements';

  @override
  String get statsTrophyCase => 'Trophy case';

  @override
  String get statsWeeklyPerformanceTrendChart =>
      'Weekly performance trend chart';

  @override
  String get statsShareMedicationReportWithYourDoctor =>
      'Share medication report with your doctor';

  @override
  String get statsNoMedicationsToTrack => 'No medications to track';

  @override
  String get statsLowStock => 'Low stock';

  @override
  String get statsTapRightToGoForwardLeft =>
      'Tap right to go forward, left to go back';

  @override
  String get statsYouTook => 'You took';

  @override
  String get statsYourLongestStreak => 'Your longest streak';

  @override
  String get statsLongevityScore => 'Longevity Score';

  @override
  String get statsShareToIgStory => 'Share to IG Story';

  @override
  String get statsYourBadges => 'Your badges';

  @override
  String get statsShareToInstagramTiktok => 'Share to Instagram / TikTok';

  @override
  String get statsAdjustNotifications => 'ADJUST NOTIFICATIONS';

  @override
  String get visualizerShowingASampleMedicineScanOr =>
      'Showing a sample medicine. Scan or analyse a medicine to see your own organ map.';

  @override
  String get visualizerN0hDose => '0h · dose';

  @override
  String get visualizerN24hCleared => '24h · cleared';

  @override
  String get visualizerIllustrativeModelBasedOnTypicalPharmacokinetics =>
      'Illustrative model based on typical pharmacokinetics — not medical advice.';

  @override
  String get visualizerSampleIbuprofen400mg => 'Sample: Ibuprofen 400mg';

  @override
  String get visualizerOrganImpactMap => 'Organ impact map';

  @override
  String get exportserviceClinicalSummaryReport => 'Clinical Summary Report';

  @override
  String get exportserviceGeneratedOn => 'Generated on';

  @override
  String get exportservicePatient => 'PATIENT';

  @override
  String get exportserviceN30DayAdherence => '30-DAY ADHERENCE';

  @override
  String get exportserviceActivePrescriptionsRegimens =>
      'Active Prescriptions & Regimens';

  @override
  String get exportserviceNoActiveMedicationsRecorded =>
      'No active medications recorded.';

  @override
  String get exportserviceClinicalAdherenceLogLast7Days =>
      'Clinical Adherence Log (Last 7 Days)';

  @override
  String get exportserviceDisclaimerThisReportIsAutomaticallyGenerated =>
      'Disclaimer: This report is automatically generated by Medai based on user-entered data. It is intended to assist in personal health management and should not be used as a substitute for professional medical advice, diagnosis, or treatment.';

  @override
  String get exportserviceNoAdherenceDataFoundForThe =>
      'No adherence data found for the last 7 days.';

  @override
  String get geminiserviceDailyTip => 'Daily Tip';

  @override
  String get notificationserviceKeepItUp => 'Keep it up! 🏆';

  @override
  String get notificationserviceCaregiverEscalation =>
      '🚨 CAREGIVER ESCALATION 🚨';

  @override
  String get notificationserviceGoodMorning => 'Good morning! ☀️';

  @override
  String get notificationserviceHowAreYouFeeling => 'How are you feeling? ✨';

  @override
  String get reportserviceN30DayStabilityMatrix => '30-DAY STABILITY MATRIX';

  @override
  String get reportserviceMedaiClinicalReport => 'MEDAI CLINICAL REPORT';

  @override
  String get reportserviceComprehensiveMedicationBiometricSummary =>
      'Comprehensive medication & biometric summary';

  @override
  String get reportserviceThisReportWasGeneratedByMedai =>
      'This report was generated by MedAI. It is intended for clinical reference only and does not constitute medical advice.';

  @override
  String get iosuiSendMessage => 'Send message';

  @override
  String get biohackingTargetOrgans => 'Target organs';

  @override
  String get biohackingTapToReveal => 'Tap to reveal';

  @override
  String get biohackingBioimpactTimeline => 'Bioimpact timeline';

  @override
  String get biohackingExitRecordMode => 'Exit Record Mode';

  @override
  String get biohackingN0hOnset => '0h (Onset)';

  @override
  String get biohackingN24hResidual => '24h (Residual)';

  @override
  String get biohackingGeneralInformationTag => 'General Information Tag';

  @override
  String get biohackingDisclaimerVisualizerIsForEducationalPurposes =>
      'Disclaimer: Visualizer is for educational purposes and maps standard pharmacokinetics. Seek medical advice for personalized biology.';

  @override
  String get biohackingRecordMode => 'Record Mode';

  @override
  String get biohackingDismissOrganInfo => 'Dismiss organ info';

  @override
  String get commonSnoozeNextDose30Minutes => 'Snooze next dose 30 minutes';

  @override
  String get commonUndo => 'Undo';

  @override
  String get commonYouReOffline => 'You’re offline';

  @override
  String get commonConnectionIssue => 'Connection issue';

  @override
  String get commonThisSectionFailedToLoadNtap =>
      'This section failed to load.\\nTap Resume on the recovery screen.';

  @override
  String get commonSomethingWentWrong => 'Something went wrong';

  @override
  String get commonWeVeHitATemporaryIssue =>
      'We\'ve hit a temporary issue. Your data is safe — resume to keep going.';

  @override
  String get commonResumeSession => 'RESUME SESSION';

  @override
  String get commonRestartApp => 'RESTART APP';

  @override
  String get commonDrugInteraction => 'Drug interaction';

  @override
  String get commonDismissInteractionWarning => 'Dismiss interaction warning';

  @override
  String get commonImportantHealthNotice => 'Important Health Notice';

  @override
  String get commonIUnderstandAccept => 'I Understand & Accept';

  @override
  String get commonByContinuingYouAgreeToOur =>
      'By continuing, you agree to our Terms of Service and Privacy Policy.';

  @override
  String get commonSetTime => 'Set Time';

  @override
  String get commonPermissionRequired => 'Permission Required';

  @override
  String get commonNotNow => 'Not Now';

  @override
  String get commonBack => 'Back';

  @override
  String get commonShareAchievement => 'Share Achievement';

  @override
  String get homeQuickLog => 'QUICK LOG';

  @override
  String get modalsAiDataProcessing => 'AI Data Processing';

  @override
  String get modalsMedAiUsesGoogleGeminiAi =>
      'Med AI uses Google Gemini AI to analyze your imagery and data. By hitting continue, you agree to securely share your photo and prompts with our AI processing partner.';

  @override
  String get modalsSecurityIcon => 'Security icon';

  @override
  String get modalsAskMeAnythingAboutYourCurrent =>
      'Ask me anything about your current health insights or medications.';

  @override
  String get modalsCoachIsThinking => 'Coach is thinking…';

  @override
  String get modalsAiHealthCoach => 'AI Health Coach';

  @override
  String get modalsAiCoachIcon => 'AI coach icon';

  @override
  String get modalsCoachIsThinking2 => 'Coach is thinking';

  @override
  String get modalsAskAQuestion => 'Ask a question';

  @override
  String get modalsAskAQuestion2 => 'Ask a question...';

  @override
  String get modalsClinicalReportReady => 'Clinical Report Ready';

  @override
  String get modalsValueRealization => 'Value Realization';

  @override
  String get modalsGeneratePdfReport => 'Generate PDF Report';

  @override
  String get modalsPrn => 'PRN';

  @override
  String get modalsPreviousDay => 'Previous day';

  @override
  String get modalsNextDay => 'Next day';

  @override
  String get modalsMedications => 'MEDICATIONS';

  @override
  String get modalsNoDosesScheduled => 'No doses scheduled';

  @override
  String get modalsSymptomsLogs => 'SYMPTOMS & LOGS';

  @override
  String get modalsRemovePrnDose => 'Remove PRN dose';

  @override
  String get modalsDeleteSymptom => 'Delete symptom';

  @override
  String get modalsNothingHereYet => 'Nothing here yet';

  @override
  String get modalsDoseLogged => 'DOSE LOGGED ✓';

  @override
  String get modalsShare => 'Share';

  @override
  String get modalsAwesome => 'Awesome!';

  @override
  String get modalsSensitiveAlertsOnFileReadThese =>
      'Sensitive alerts on file — read these before you take this dose.';

  @override
  String get modalsAiGuidanceAlwaysVerifyWithYour =>
      'AI guidance — always verify with your pharmacist or doctor.';

  @override
  String get modalsWarnings => 'Warnings';

  @override
  String get modalsBeforeYouTake => 'Before you take';

  @override
  String get modalsGoodToKnow => 'Good to know';

  @override
  String get modalsMascotWardrobe => 'Mascot Wardrobe';

  @override
  String get modalsCustomizeYourAiBuddy => 'Customize your AI buddy';

  @override
  String get modalsEquipped => 'EQUIPPED';

  @override
  String get modalsOwned => 'OWNED';

  @override
  String get modalsSheetHandle => 'Sheet handle';

  @override
  String get modalsPharmacistAiThinking => 'Pharmacist AI thinking...';

  @override
  String get modalsAiAdvice => 'AI ADVICE';

  @override
  String get modalsInformationalOnlyAlwaysConsultYourDoctor =>
      '⚠️ Informational only. Always consult your doctor or pharmacist for advice.';

  @override
  String get modalsInformationalOnlyAlwaysConsultYourDoctor2 =>
      'Informational only. Always consult your doctor or pharmacist for advice.';

  @override
  String get modalsSkipDose => 'Skip Dose';

  @override
  String get modalsSafetySaved => 'Safety saved';

  @override
  String get modalsReminderOn => 'Reminder on';

  @override
  String get modalsSeeItOnHome => 'See it on Home';

  @override
  String get modalsReviewMedicineDetails => 'Review medicine details';

  @override
  String get modalsShareYourWin => 'Share your win';

  @override
  String get modalsN30DayPerformance => '30-DAY PERFORMANCE';

  @override
  String get modalsPatientInsight => 'PATIENT INSIGHT';

  @override
  String get modalsHealthTrends => 'Health Trends';

  @override
  String get modalsN30DayAdherenceChart => '30 day adherence chart';

  @override
  String get modalsViewDetailedDailyLog => 'View Detailed Daily Log';

  @override
  String get sharedMarkAsTaken => 'Mark as taken';

  @override
  String get sharedLate => 'Late';

  @override
  String get sharedLog => 'Log';

  @override
  String get viralAiQuickLog => 'AI Quick Log';

  @override
  String get viralJustTellMeWhatYouTook => 'Just tell me what you took';

  @override
  String get viralOrQuicklyLogAMeal => 'Or quickly log a meal:';

  @override
  String get viralListening => 'LISTENING...';

  @override
  String get viralAiIsParsingYourLog => 'AI is parsing your log...';

  @override
  String get viralWeDidn => 'We didn\\';

  @override
  String get viralStopRecording => 'Stop recording';

  @override
  String get viralITook2Tylenol30Minutes =>
      '\"I took 2 Tylenol 30 minutes ago...\"';

  @override
  String get viralLogWithAi => 'Log with AI';

  @override
  String get viralTryAgain => 'Try again';

  @override
  String get viralAddMedicineManually => 'Add Medicine Manually';

  @override
  String get viralGetPremiumFreezes => 'Get premium freezes';

  @override
  String get viralStartNewStreak => 'Start new streak';

  @override
  String get viralMedaiMilestoneShield => 'MEDAI MILESTONE // SHIELD';

  @override
  String get viralSecureV2026 => '[SECURE_v2.026]';

  @override
  String get viralDayComplianceStreak => 'DAY COMPLIANCE STREAK';

  @override
  String get viralJoinTheRoutineAtMedaiApp =>
      'JOIN THE ROUTINE AT MEDAI.APP 💊';

  @override
  String get viralHealthReport => 'HEALTH REPORT';

  @override
  String get viralAdherenceScore => 'ADHERENCE SCORE';

  @override
  String get viralTotalLogs => 'TOTAL LOGS';

  @override
  String get viralShieldLevel => 'SHIELD LEVEL';

  @override
  String get viralStatus => 'STATUS';

  @override
  String alarmsActive(Object activeCount) {
    return '$activeCount active';
  }

  @override
  String alarmsAlarmForRemoved(Object name) {
    return 'Alarm for $name removed';
  }

  @override
  String alarmsOff(Object inactiveSchedulesCount) {
    return '$inactiveSchedulesCount off';
  }

  @override
  String alarmsReminderAt(Object displayName, Object timeLabel) {
    return '$displayName reminder at $timeLabel';
  }

  @override
  String alarmsSetReminderFor2(Object name) {
    return 'Set reminder for $name';
  }

  @override
  String analysisReportedSizedByHowOften(Object sideEffectsCount) {
    return '$sideEffectsCount reported — sized by how often.';
  }

  @override
  String authUnlock(Object profileName) {
    return 'Unlock $profileName';
  }

  @override
  String authPinEntryOf4DigitsEntered(Object enteredPinCount) {
    return 'PIN entry, $enteredPinCount of 4 digits entered';
  }

  @override
  String dashboardN30DayAdherencePercent(Object pct, Object statusLabel) {
    return '30-day adherence $pct percent, $statusLabel';
  }

  @override
  String familyAreYouSureYouWantTo(Object name) {
    return 'Are you sure you want to remove $name from your protectors? This action cannot be undone.';
  }

  @override
  String familyMissedMedicationAlerts(Object unseenCount) {
    return '$unseenCount missed medication alerts';
  }

  @override
  String familyProfiles(Object profile) {
    return '$profile profiles';
  }

  @override
  String familyManage(Object name) {
    return 'Manage $name';
  }

  @override
  String familyThisWillStopAllRemindersFor(Object name) {
    return 'This will stop all reminders for $name. History for this member will be preserved in the cloud.';
  }

  @override
  String familyAlerts(Object missedAlertsCount) {
    return '$missedAlertsCount alerts';
  }

  @override
  String familyUnlock(Object name) {
    return 'Unlock $name';
  }

  @override
  String familyStepOf3(Object step) {
    return 'Step $step of 3';
  }

  @override
  String familyAvatar2(Object a) {
    return 'Avatar $a';
  }

  @override
  String familyMissedDoseAlertFor(Object medName) {
    return 'Missed dose alert for $medName';
  }

  @override
  String familyMissedAt(Object doseLabel, Object time) {
    return 'Missed $doseLabel at $time';
  }

  @override
  String familyMonitoring2(Object relation) {
    return '$relation · Monitoring';
  }

  @override
  String familyMonitoringActive(Object relation) {
    return '$relation · Monitoring active';
  }

  @override
  String familyNudge(Object name) {
    return 'Nudge $name';
  }

  @override
  String homeYouLoggedASevereSymptomOf(Object name, Object severity) {
    return 'You logged a severe symptom of $name (Severity: $severity/10) recently. If you are experiencing chest pain, difficulty breathing, sudden weakness, or any life-threatening symptoms, seek medical help immediately.';
  }

  @override
  String homeMarkedAsTaken(Object name) {
    return '$name marked as taken.';
  }

  @override
  String homeNextDose2(Object name, Object timeLabel) {
    return 'Next dose: $name, $timeLabel';
  }

  @override
  String homeMeds(Object focusCount) {
    return '$focusCount meds';
  }

  @override
  String homeEnterPinFor(Object name) {
    return 'Enter PIN for $name';
  }

  @override
  String homeSwitchToProfile(Object name) {
    return 'Switch to $name profile';
  }

  @override
  String homeRecoveryCourseForDayOf(Object name, Object day, Object totalDays) {
    return 'Recovery course for $name, day $day of $totalDays';
  }

  @override
  String homeMedicinesTracked(Object select) {
    return '$select medicines tracked';
  }

  @override
  String homeRefill2(Object name) {
    return 'Refill $name';
  }

  @override
  String loadingMascot(Object kAppName) {
    return '$kAppName mascot';
  }

  @override
  String medicineRestock2(Object name) {
    return 'Restock $name';
  }

  @override
  String medicineAddUnitsTo(Object name) {
    return 'Add units to $name';
  }

  @override
  String medicineGreatJobFinishingYourCourseOf(Object name) {
    return 'Great job finishing your course of $name. You\\\'ve successfully completed all prescribed doses.';
  }

  @override
  String scanConfidenceTargetPercent(Object toInt) {
    return 'Confidence target, $toInt percent';
  }

  @override
  String scanAdded(Object date) {
    return 'Added: $date';
  }

  @override
  String scanMode(Object label) {
    return '$label mode';
  }

  @override
  String scanAiConfidencePercent(Object pct) {
    return 'AI confidence $pct percent';
  }

  @override
  String scanAiConfidence(Object pct) {
    return 'Ai Confidence $pct%';
  }

  @override
  String scanStorage(Object storage) {
    return 'Storage · $storage';
  }

  @override
  String settingsEmailUsAt(Object kSupportEmail) {
    return 'Email us at $kSupportEmail';
  }

  @override
  String settingsVersionStable(Object kAppVersion) {
    return 'VERSION $kAppVersion • STABLE';
  }

  @override
  String settingsViewFullPolicyOnlineAt(Object kPrivacyPolicyUrl) {
    return 'View full policy online at $kPrivacyPolicyUrl';
  }

  @override
  String settingsNsecurePrivateGdprCompliant(Object kAppName) {
    return '$kAppName\\nSecure · Private · GDPR Compliant';
  }

  @override
  String settingsViewFullTermsOnlineAt(Object kTermsOfServiceUrl) {
    return 'View full terms online at $kTermsOfServiceUrl';
  }

  @override
  String settingsNsecurePrivateTransparent(Object kAppName) {
    return '$kAppName\\nSecure · Private · Transparent';
  }

  @override
  String settingsTypeToConfirm(Object confirmWord) {
    return 'Type $confirmWord to confirm';
  }

  @override
  String socialInviteAFriendOrCaregiverTo(Object myStreak) {
    return 'Invite a friend or caregiver to build accountability together. Your current streak is $myStreak days.';
  }

  @override
  String socialSlideOf6(Object currentSlide) {
    return 'Slide $currentSlide of 6';
  }

  @override
  String statsLeft(Object count) {
    return '$count left';
  }

  @override
  String statsSlideOf3(Object currentPage) {
    return 'Slide $currentPage of 3';
  }

  @override
  String statsDayCurrentStreak(Object streak) {
    return '$streak day current streak';
  }

  @override
  String statsDaysAgo(Object seriesCount) {
    return '$seriesCount days ago';
  }

  @override
  String visualizerShowOrganMapFor(Object name) {
    return 'Show organ map for $name';
  }

  @override
  String visualizerPercentActiveTapForDetail(Object name, Object pct) {
    return '$name, $pct percent active. Tap for detail.';
  }

  @override
  String visualizerActive(Object pct) {
    return '$pct% active';
  }

  @override
  String visualizerTimeSinceDoseHours(Object toStringAsFixed) {
    return 'Time since dose $toStringAsFixed hours';
  }

  @override
  String biohackingHowAffectsYourBody(Object medName) {
    return 'How $medName affects your body';
  }

  @override
  String biohackingTimeH(Object toStringAsFixed) {
    return 'Time: ${toStringAsFixed}h';
  }

  @override
  String commonDue(Object label, Object time) {
    return '$label, due $time';
  }

  @override
  String modalsOfDosesLogged(Object takenCount, Object allDosesToShowCount) {
    return '$takenCount of $allDosesToShowCount doses logged';
  }

  @override
  String modalsSeverity10(Object severity) {
    return 'Severity: $severity/10';
  }

  @override
  String modalsLogged(Object medName) {
    return '$medName Logged';
  }

  @override
  String modalsMoreOpenMedicineDetailsToRead(Object itemsCount) {
    return '+$itemsCount more — open medicine details to read all';
  }

  @override
  String modalsDoseFor(Object statusLabel, Object name) {
    return '$statusLabel dose for $name';
  }

  @override
  String modalsWas(Object schedTime) {
    return 'was $schedTime';
  }

  @override
  String modalsAvg(Object value) {
    return '$value% AVG';
  }

  @override
  String viralLog(Object text) {
    return 'Log $text';
  }

  @override
  String viralDayStreak(Object streak) {
    return '🔥 $streak-day streak';
  }

  @override
  String commonShareRecommendation(
      Object name, Object feel, Object tagline, Object invite, Object url) {
    return '$name found $feel.\n$tagline\n\n$invite$url';
  }

  @override
  String commonDayUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'days',
      one: 'day',
    );
    return '$_temp0';
  }

  @override
  String statsInventoryRemaining(Object name, Object count) {
    return '$name, $count remaining';
  }

  @override
  String statsInventoryRemainingLowStock(Object name, Object count) {
    return '$name, $count remaining, low stock';
  }

  @override
  String commonShopItemEquipped(Object name) {
    return '$name, equipped';
  }

  @override
  String commonShopItemOwned(Object name) {
    return '$name, owned';
  }

  @override
  String commonShopItemCost(Object name, Object cost) {
    return '$name, costs $cost coins';
  }

  @override
  String settingsProfileAge(Object age) {
    return 'Age $age';
  }

  @override
  String get settingsProfileAgeNotSet => 'Age not set';

  @override
  String settingsProfileAgeAndGender(Object age, Object gender) {
    return '$age · $gender';
  }

  @override
  String focusTimerStatus(Object time, Object status) {
    return 'Timer $time. $status';
  }

  @override
  String get focusSessionComplete => 'Session complete';

  @override
  String get focusInhale => 'Inhale';

  @override
  String get focusExhale => 'Exhale';

  @override
  String get focusReadyToFocus => 'Ready to focus';

  @override
  String get biohackingNoTimelineData => 'Timeline not available';

  @override
  String get biohackingNoTimelineDataBody =>
      'We don\'t have pharmacokinetic data for this medicine, so there\'s no absorption timeline to show.';
}
