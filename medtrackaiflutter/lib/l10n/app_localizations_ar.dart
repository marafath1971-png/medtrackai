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
}
