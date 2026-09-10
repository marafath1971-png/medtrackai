// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'MedAI';

  @override
  String get greetingHero => 'الرئيسية';

  @override
  String get homeTab => 'الرئيسية';

  @override
  String get alarmsTab => 'المنبّهات';

  @override
  String get dashboardTab => 'الاتجاهات';

  @override
  String get familyTab => 'الدائرة';

  @override
  String get scanTab => 'مسح';

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
  String get countrySelectionTitle => 'أين موقعك؟';

  @override
  String get countrySelectionSubtitle =>
      'يساعدنا في تحديد ماركات الأدوية المحلية';

  @override
  String get prnLabel => 'عند الحاجة';

  @override
  String get prnUndoToast => 'تمت إزالة جرعة عند الحاجة';

  @override
  String get dailyLogTitle => 'السجل اليومي';

  @override
  String get noMedicinesScheduled => 'لا توجد أدوية مجدولة لهذا اليوم.';

  @override
  String get remaining => 'متبقٍ';

  @override
  String get refillRequired => 'يلزم إعادة التعبئة';

  @override
  String get settings => 'الإعدادات';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get language => 'اللغة';

  @override
  String get country => 'الدولة';

  @override
  String get saveChanges => 'حفظ التغييرات';

  @override
  String get inventory => 'المخزون';

  @override
  String get noMedicines => 'لا توجد أدوية';

  @override
  String get takeNow => 'تناول الآن';

  @override
  String get snooze => 'غفوة';

  @override
  String get skip => 'تخطٍّ';

  @override
  String get pharmacyLabel => 'الصيدلية';

  @override
  String get pharmacyPhoneLabel => 'هاتف الصيدلية';

  @override
  String get rxNumberLabel => 'رقم الوصفة';

  @override
  String get globalSettings => 'الإعدادات العامة';

  @override
  String get religiousObservance => 'المراعاة الدينية';

  @override
  String get shabbatMode => 'وضع السبت';

  @override
  String get prayerAwareReminders => 'تذكيرات تراعي أوقات الصلاة';

  @override
  String get halalDetection => 'كشف الحلال والجيلاتين';

  @override
  String get amoledMode => 'وضع AMOLED (توفير البكسل)';

  @override
  String get diabetesMode => 'وضع السكري';

  @override
  String get hypertensionMode => 'وضع ارتفاع ضغط الدم';

  @override
  String get supportedMarkets => 'الأسواق المدعومة';

  @override
  String get halalSafe => 'حلال آمن';

  @override
  String get gelatinWarning => 'يحتوي على جيلاتين';

  @override
  String get halalUncertain => 'حلال غير مؤكد';

  @override
  String get edit => 'تعديل';

  @override
  String get editProfile => 'تعديل الملف الشخصي';

  @override
  String get cancel => 'إلغاء';

  @override
  String get globalSettingsSubtitle => 'إدارة إعدادات الأسواق الدولية';

  @override
  String get medicationDisplay => 'عرض الأدوية';

  @override
  String get showGenericNames => 'إظهار الأسماء العلمية (INN)';

  @override
  String get showGenericNamesSubtitle =>
      'عرض الأسماء الدولية غير المسجّلة بدلاً من الأسماء التجارية';

  @override
  String get pbsSafetyNet => 'متتبّع PBS Safety Net';

  @override
  String get pbsSafetyNetSubtitle => 'أستراليا — تتبّع المساهمة السنوية';

  @override
  String get pbsThreshold => 'الحد السنوي: \$1,622.90';

  @override
  String pbsSpent(Object amount) {
    return 'المصروف: \$$amount';
  }

  @override
  String pbsRemaining(Object amount) {
    return 'يتبقى \$$amount';
  }

  @override
  String get reached => 'تم الوصول!';

  @override
  String get medsSubsidised => 'الأدوية مدعومة الآن!';

  @override
  String get spentAmountSubtitle =>
      'اسحب لتحديث مبلغ إنفاقك السنوي (المساهمات لكل وصفات PBS خلال هذه السنة الميلادية)';

  @override
  String get clinicalModes => 'الأوضاع السريرية';

  @override
  String get clinicalModesSubtitle =>
      'الولايات المتحدة · المملكة المتحدة · الإمارات · ماليزيا';

  @override
  String get diabetesModeSubtitle =>
      'سجّل سكر الدم مع الإنسولين / أدوية السكري';

  @override
  String get hypertensionModeSubtitle => 'سجّل ضغط الدم مع أدوية ارتفاع الضغط';

  @override
  String get displaySettings => 'العرض';

  @override
  String get amoledModeSubtitle =>
      'استخدم خلفية #000000 حقيقية لتحسين شاشات AMOLED وتوفير البطارية';

  @override
  String get shabbatModeSubtitle =>
      'تذكيرات لطيفة بالاهتزاز فقط من غروب الجمعة حتى ليلة السبت';

  @override
  String get selectCountry => 'اختر الدولة';

  @override
  String get selectLanguage => 'اختر اللغة';

  @override
  String get aiSafetyProfile => 'ملف السلامة بالذكاء الاصطناعي';

  @override
  String get verified => 'مُتحقَّق';

  @override
  String get criticalWarnings => 'تحذيرات حرجة';

  @override
  String get drugInteractions => 'التفاعلات الدوائية';

  @override
  String get dietaryLifestyleRules => 'قواعد الغذاء ونمط الحياة';

  @override
  String get ahaInsight => 'استنتاج مهم!';

  @override
  String get generateSafetyProfile => 'إنشاء ملف السلامة';

  @override
  String get analyzingClinicalLimits => 'جارٍ تحليل الحدود السريرية...';

  @override
  String get safetyLoadingSubtitle =>
      'يرجى الانتظار بينما يتحقق الذكاء الاصطناعي من التفاعلات والمخاطر وقواعد الطعام.';

  @override
  String get safetyPromptSubtitle =>
      'اضغط لتحليل هذا الدواء فورًا بحثًا عن المخاطر والتفاعلات الدوائية وقواعد نمط الحياة.';

  @override
  String get goodMorning => 'صباح الخير';

  @override
  String get goodAfternoon => 'مساء الخير';

  @override
  String get goodEvening => 'مساء الخير';

  @override
  String hiUser(String name) {
    return 'مرحبًا، $name 👋';
  }

  @override
  String get startJourney => 'لنبدأ رحلتك الصحية ✨';

  @override
  String get allDosesTaken => 'تم تناول كل الجرعات اليوم! 🌟';

  @override
  String dosesOverdue(int count) {
    return '$count جرعات متأخرة — تناولها الآن ⚠️';
  }

  @override
  String dosesLeft(int count) {
    return 'يتبقى $count جرعات اليوم';
  }

  @override
  String get healthReportTitle => 'تقرير MedAI الصحي';

  @override
  String get medicalSummarySubtitle => 'ملخص طبي شخصي واتجاهات الالتزام';

  @override
  String patientLabel(String name) {
    return 'المريض: $name';
  }

  @override
  String reportDate(String date) {
    return 'التاريخ: $date';
  }

  @override
  String get overallAdherence => 'الالتزام الإجمالي';

  @override
  String get activeMedications => 'الأدوية النشطة';

  @override
  String get reportPeriod => 'فترة التقرير';

  @override
  String get last30Days => 'آخر 30 يومًا';

  @override
  String get currentMedications => 'الأدوية الحالية';

  @override
  String get medicineCol => 'الدواء';

  @override
  String get doseCol => 'الجرعة';

  @override
  String get frequencyCol => 'التكرار';

  @override
  String get stockRemainingCol => 'المخزون المتبقي';

  @override
  String get recentSymptoms => 'الأعراض والحالة الصحية الأخيرة';

  @override
  String get symptomDateCol => 'التاريخ';

  @override
  String get symptomNameCol => 'العرض';

  @override
  String get severityCol => 'الشدة';

  @override
  String get notesCol => 'ملاحظات';

  @override
  String get noSymptomsLogged => 'لم تُسجَّل أعراض في هذه الفترة.';

  @override
  String get reportFooter =>
      'تم الإنشاء بواسطة MedAI Pro. هذا التقرير لأغراض إعلامية فقط ويجب مراجعته من قبل أخصائي رعاية صحية مؤهل.';

  @override
  String get settingsStats => 'الإحصائيات';

  @override
  String get settingsApp => 'إعدادات التطبيق';

  @override
  String get settingsData => 'البيانات والخصوصية';

  @override
  String get settingsGlobal => 'الإعدادات العامة';

  @override
  String get settingsProfile => 'ملفي الشخصي';

  @override
  String get adherenceLabel => 'الالتزام';

  @override
  String get streakLabel => 'التتابع';

  @override
  String streakDays(int count) {
    return '$count يومًا';
  }

  @override
  String get generateClinicalReport => 'إنشاء تقرير سريري';

  @override
  String get fetchingAiInsights => 'جارٍ جلب تحليلات الذكاء الاصطناعي...';

  @override
  String get aiCoachDisclaimer =>
      'تستخدم هذه اللوحة الذكاء الاصطناعي لتحليل الأنماط. استشر طبيبك دائمًا للحصول على المشورة الطبية.';

  @override
  String get insightsTitle => 'التحليلات';

  @override
  String get insightsSubtitle => 'التحليلات وأنماط الصحة';

  @override
  String get dataSummaryTitle => 'ملخص بياناتك';

  @override
  String get dataMedicinesLabel => 'الأدوية';

  @override
  String get dataAlarmsLabel => 'المنبّهات المضبوطة';

  @override
  String get dataDaysTrackedLabel => 'أيام التتبّع';

  @override
  String get dataDosesLoggedLabel => 'الجرعات المسجّلة';

  @override
  String get exportAndBackup => 'التصدير والنسخ الاحتياطي';

  @override
  String get exportPdfReport => 'تصدير تقرير PDF';

  @override
  String get exportPdfSubtitle => 'للأطباء ومقدّمي الرعاية';

  @override
  String get exportCsv => 'تصدير السجل كملف CSV';

  @override
  String exportCsvSubtitle(int count) {
    return '$count سجل جرعات';
  }

  @override
  String get resetSection => 'إعادة تعيين';

  @override
  String get deleteAllData => 'حذف كل البيانات';

  @override
  String get deleteAllDataSubtitle => 'يزيل كل الأدوية والسجل والإعدادات';

  @override
  String get deleteConfirmTitle => 'حذف كل البيانات؟';

  @override
  String get deleteConfirmBody =>
      'سيؤدي هذا إلى حذف كل بياناتك نهائيًا. لا يمكن التراجع عن ذلك.';

  @override
  String get deleteButton => 'حذف كل شيء';

  @override
  String get legalSection => 'قانوني';

  @override
  String get privacyPolicy => 'سياسة الخصوصية';

  @override
  String get privacyPolicySubtitle => 'كيف نحمي بياناتك الصحية';

  @override
  String get termsOfService => 'شروط الخدمة';

  @override
  String get termsOfServiceSubtitle => 'قواعد استخدام MedAI';

  @override
  String get appVersionLabel => 'إصدار التطبيق';

  @override
  String get appVersionValue => '1.0.0+1';

  @override
  String get analysisFailed => 'فشل التحليل';

  @override
  String get somethingWentWrong => 'حدث خطأ ما. يرجى المحاولة مرة أخرى.';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get onboardingSkip => 'تخطٍّ';

  @override
  String get onboardingNext => 'التالي';

  @override
  String get onboardingContinue => 'متابعة';

  @override
  String get onboardingGetStarted => 'ابدأ';

  @override
  String get onboardingWelcomeTitle => 'ابنِ عادات دواء\nلا تنكسر';

  @override
  String get onboardingWelcomeBody =>
      'سلاسل التتابع وتذكيرات ذكية وذكاء اصطناعي يبقيك على المسار — كل يوم.';

  @override
  String get onboardingScanTitle => 'امسح أي حبة\nفي ثوانٍ';

  @override
  String get onboardingScanBodyDemo =>
      'اضغط بالأسفل لترى الذكاء الاصطناعي يتعرّف على دواء تجريبي فورًا.';

  @override
  String get onboardingScanBodyDone =>
      'هكذا تكون سرعة Med AI. بلا كتابة ولا تخمين.';

  @override
  String get onboardingSimulateScan => 'محاكاة المسح ←';

  @override
  String get onboardingPermissionTitle => 'كاميرتك،\nخصوصيتك';

  @override
  String get onboardingPermissionBody =>
      'نستخدم الكاميرا فقط لقراءة ملصقات الحبوب. تُعالَج الصور بأمان ولا تُباع أبدًا.';

  @override
  String get onboardingPermissionLink => 'تعرّف على كيفية حماية بياناتك';

  @override
  String get onboardingPersonalizeTitle => 'خصّص\nتجربتك';

  @override
  String get onboardingQuizMedCount => 'كم عدد الأدوية؟';

  @override
  String get onboardingQuizRole => 'لمن تتابع الأدوية؟';

  @override
  String get onboardingQuizSchedule => 'متى تتناول معظم الأدوية؟';

  @override
  String get onboardingRoleSelf => 'لنفسي';

  @override
  String get onboardingRoleCaregiver => 'شخص أرعاه';

  @override
  String get onboardingScheduleMorning => 'صباحًا';

  @override
  String get onboardingScheduleEvening => 'مساءً';

  @override
  String get onboardingScheduleBoth => 'كلاهما';

  @override
  String get onboardingSocialTitle => 'انضم إلى أكثر من 50,000\nبطل صحي';

  @override
  String get onboardingSocialQuote =>
      '«غيّر Med AI طريقة إدارة عائلتي للأدوية. ميزة المسح وحدها توفّر لنا 10 دقائق يوميًا.»';

  @override
  String get onboardingSocialAttribution => '— مراجعة App Store، 5 نجوم';

  @override
  String get onboardingAllowCamera => 'السماح بالوصول إلى الكاميرا';

  @override
  String get onboardingTryDemoScan => 'جرّب مسحًا تجريبيًا';

  @override
  String get loadingHealthData => 'جارٍ تحميل بياناتك الصحية…';

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
}
