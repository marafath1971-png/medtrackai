// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hebrew (`he`).
class AppLocalizationsHe extends AppLocalizations {
  AppLocalizationsHe([String locale = 'he']) : super(locale);

  @override
  String get appTitle => 'MedAI';

  @override
  String get greetingHero => 'בית';

  @override
  String get homeTab => 'בית';

  @override
  String get alarmsTab => 'התראות';

  @override
  String get dashboardTab => 'מגמות';

  @override
  String get familyTab => 'מעגל';

  @override
  String get scanTab => 'סריקה';

  @override
  String get countrySelectionTitle => 'היכן אתם נמצאים?';

  @override
  String get countrySelectionSubtitle => 'עוזר לנו לזהות מותגי תרופות מקומיים';

  @override
  String get prnLabel => 'לפי הצורך';

  @override
  String get prnUndoToast => 'מנת \"לפי הצורך\" הוסרה';

  @override
  String get dailyLogTitle => 'יומן יומי';

  @override
  String get noMedicinesScheduled => 'אין תרופות מתוזמנות ליום זה.';

  @override
  String get remaining => 'נותרו';

  @override
  String get refillRequired => 'נדרש חידוש';

  @override
  String get settings => 'הגדרות';

  @override
  String get profile => 'פרופיל';

  @override
  String get language => 'שפה';

  @override
  String get country => 'מדינה';

  @override
  String get saveChanges => 'שמירת שינויים';

  @override
  String get inventory => 'מלאי';

  @override
  String get noMedicines => 'אין תרופות';

  @override
  String get takeNow => 'קח עכשיו';

  @override
  String get snooze => 'נודניק';

  @override
  String get skip => 'דלג';

  @override
  String get pharmacyLabel => 'בית מרקחת';

  @override
  String get pharmacyPhoneLabel => 'טלפון בית מרקחת';

  @override
  String get rxNumberLabel => 'מספר מרשם';

  @override
  String get globalSettings => 'הגדרות גלובליות';

  @override
  String get religiousObservance => 'התחשבות דתית';

  @override
  String get shabbatMode => 'מצב שבת';

  @override
  String get prayerAwareReminders => 'תזכורות מותאמות לזמני תפילה';

  @override
  String get halalDetection => 'זיהוי חלאל וג\'לטין';

  @override
  String get amoledMode => 'מצב AMOLED (חיסכון בפיקסלים)';

  @override
  String get diabetesMode => 'מצב סוכרת';

  @override
  String get hypertensionMode => 'מצב יתר לחץ דם';

  @override
  String get supportedMarkets => 'שווקים נתמכים';

  @override
  String get halalSafe => 'כשר לחלאל';

  @override
  String get gelatinWarning => 'מכיל ג\'לטין';

  @override
  String get halalUncertain => 'חלאל לא ודאי';

  @override
  String get edit => 'עריכה';

  @override
  String get editProfile => 'עריכת פרופיל';

  @override
  String get cancel => 'ביטול';

  @override
  String get globalSettingsSubtitle => 'ניהול הגדרות שוק בינלאומיות';

  @override
  String get medicationDisplay => 'תצוגת תרופות';

  @override
  String get showGenericNames => 'הצגת שמות גנריים (INN)';

  @override
  String get showGenericNamesSubtitle =>
      'הצגת שמות בינלאומיים גנריים במקום שמות מסחריים';

  @override
  String get pbsSafetyNet => 'מעקב PBS Safety Net';

  @override
  String get pbsSafetyNetSubtitle => 'אוסטרליה — מעקב אחר השתתפות עצמית שנתית';

  @override
  String get pbsThreshold => 'סף שנתי: \$1,622.90';

  @override
  String pbsSpent(Object amount) {
    return 'הוצא: \$$amount';
  }

  @override
  String pbsRemaining(Object amount) {
    return 'נותרו \$$amount';
  }

  @override
  String get reached => 'הושג!';

  @override
  String get medsSubsidised => 'התרופות מסובסדות כעת!';

  @override
  String get spentAmountSubtitle =>
      'החליקו כדי לעדכן את סכום ההוצאה השנתי (השתתפות עצמית עבור כל מרשמי PBS בשנה קלנדרית זו)';

  @override
  String get clinicalModes => 'מצבים קליניים';

  @override
  String get clinicalModesSubtitle =>
      'ארה\"ב · בריטניה · איחוד האמירויות · מלזיה';

  @override
  String get diabetesModeSubtitle =>
      'תיעוד רמת סוכר בדם לצד אינסולין / תרופות לסוכרת';

  @override
  String get hypertensionModeSubtitle => 'תיעוד לחץ דם לצד תרופות ליתר לחץ דם';

  @override
  String get displaySettings => 'תצוגה';

  @override
  String get amoledModeSubtitle =>
      'שימוש ברקע #000000 אמיתי לאופטימיזציה של מסכי AMOLED וחיסכון בסוללה';

  @override
  String get shabbatModeSubtitle =>
      'תזכורות עדינות ברטט בלבד מכניסת שבת ועד מוצאי שבת';

  @override
  String get selectCountry => 'בחר מדינה';

  @override
  String get selectLanguage => 'בחר שפה';

  @override
  String get aiSafetyProfile => 'פרופיל בטיחות AI';

  @override
  String get verified => 'מאומת';

  @override
  String get criticalWarnings => 'אזהרות קריטיות';

  @override
  String get drugInteractions => 'אינטראקציות בין תרופות';

  @override
  String get dietaryLifestyleRules => 'כללי תזונה ואורח חיים';

  @override
  String get ahaInsight => 'תובנה!';

  @override
  String get generateSafetyProfile => 'יצירת פרופיל בטיחות';

  @override
  String get analyzingClinicalLimits => 'מנתח מגבלות קליניות...';

  @override
  String get safetyLoadingSubtitle =>
      'אנא המתינו בזמן ש-AI מאמת אינטראקציות, סכנות וכללי תזונה.';

  @override
  String get safetyPromptSubtitle =>
      'הקישו כדי לנתח מיד את התרופה הזו לאיתור סכנות, אינטראקציות בין תרופות וכללי אורח חיים.';

  @override
  String get goodMorning => 'בוקר טוב';

  @override
  String get goodAfternoon => 'צהריים טובים';

  @override
  String get goodEvening => 'ערב טוב';

  @override
  String hiUser(String name) {
    return 'היי, $name 👋';
  }

  @override
  String get startJourney => 'בואו נתחיל את מסע הבריאות שלכם ✨';

  @override
  String get allDosesTaken => 'כל המנות נלקחו היום! 🌟';

  @override
  String dosesOverdue(int count) {
    return '$count מנות באיחור — קחו אותן עכשיו ⚠️';
  }

  @override
  String dosesLeft(int count) {
    return 'נותרו $count מנות היום';
  }

  @override
  String get healthReportTitle => 'דוח בריאות MedAI';

  @override
  String get medicalSummarySubtitle => 'סיכום רפואי אישי ומגמות היענות';

  @override
  String patientLabel(String name) {
    return 'מטופל: $name';
  }

  @override
  String reportDate(String date) {
    return 'תאריך: $date';
  }

  @override
  String get overallAdherence => 'היענות כוללת';

  @override
  String get activeMedications => 'תרופות פעילות';

  @override
  String get reportPeriod => 'תקופת הדוח';

  @override
  String get last30Days => '30 הימים האחרונים';

  @override
  String get currentMedications => 'תרופות נוכחיות';

  @override
  String get medicineCol => 'תרופה';

  @override
  String get doseCol => 'מנה';

  @override
  String get frequencyCol => 'תדירות';

  @override
  String get stockRemainingCol => 'מלאי שנותר';

  @override
  String get recentSymptoms => 'תסמינים ורווחה לאחרונה';

  @override
  String get symptomDateCol => 'תאריך';

  @override
  String get symptomNameCol => 'תסמין';

  @override
  String get severityCol => 'חומרה';

  @override
  String get notesCol => 'הערות';

  @override
  String get noSymptomsLogged => 'לא תועדו תסמינים בתקופה זו.';

  @override
  String get reportFooter =>
      'הופק על ידי MedAI Pro. דוח זה נועד למטרות מידע בלבד ויש לבדוק אותו על ידי איש מקצוע רפואי מוסמך.';

  @override
  String get settingsStats => 'סטטיסטיקה';

  @override
  String get settingsApp => 'הגדרות אפליקציה';

  @override
  String get settingsData => 'נתונים ופרטיות';

  @override
  String get settingsGlobal => 'הגדרות גלובליות';

  @override
  String get settingsProfile => 'הפרופיל שלי';

  @override
  String get adherenceLabel => 'היענות';

  @override
  String get streakLabel => 'רצף';

  @override
  String streakDays(int count) {
    return '$count ימים';
  }

  @override
  String get generateClinicalReport => 'הפקת דוח קליני';

  @override
  String get fetchingAiInsights => 'מאחזר תובנות AI...';

  @override
  String get aiCoachDisclaimer =>
      'לוח מחוונים זה משתמש ב-AI לניתוח דפוסים. התייעצו תמיד עם הרופא לקבלת ייעוץ רפואי.';

  @override
  String get insightsTitle => 'תובנות';

  @override
  String get insightsSubtitle => 'אנליטיקה ודפוסי בריאות';

  @override
  String get dataSummaryTitle => 'סיכום הנתונים שלך';

  @override
  String get dataMedicinesLabel => 'תרופות';

  @override
  String get dataAlarmsLabel => 'התראות שהוגדרו';

  @override
  String get dataDaysTrackedLabel => 'ימים שתועדו';

  @override
  String get dataDosesLoggedLabel => 'מנות שתועדו';

  @override
  String get exportAndBackup => 'ייצוא וגיבוי';

  @override
  String get exportPdfReport => 'ייצוא דוח PDF';

  @override
  String get exportPdfSubtitle => 'לרופאים ולמטפלים';

  @override
  String get exportCsv => 'ייצוא היסטוריה כ-CSV';

  @override
  String exportCsvSubtitle(int count) {
    return '$count רשומות מנות';
  }

  @override
  String get resetSection => 'איפוס';

  @override
  String get deleteAllData => 'מחיקת כל הנתונים';

  @override
  String get deleteAllDataSubtitle => 'מסיר את כל התרופות, ההיסטוריה וההגדרות';

  @override
  String get deleteConfirmTitle => 'למחוק את כל הנתונים?';

  @override
  String get deleteConfirmBody =>
      'פעולה זו תמחק לצמיתות את כל הנתונים שלך. לא ניתן לבטל אותה.';

  @override
  String get deleteButton => 'מחק הכול';

  @override
  String get legalSection => 'משפטי';

  @override
  String get privacyPolicy => 'מדיניות פרטיות';

  @override
  String get privacyPolicySubtitle => 'כיצד אנו מגנים על נתוני הבריאות שלך';

  @override
  String get termsOfService => 'תנאי שימוש';

  @override
  String get termsOfServiceSubtitle => 'כללים לשימוש ב-MedAI';

  @override
  String get appVersionLabel => 'גרסת אפליקציה';

  @override
  String get appVersionValue => '1.0.0+1';

  @override
  String get analysisFailed => 'הניתוח נכשל';

  @override
  String get somethingWentWrong => 'משהו השתבש. אנא נסו שוב.';

  @override
  String get retry => 'נסה שוב';

  @override
  String get onboardingSkip => 'דלג';

  @override
  String get onboardingNext => 'הבא';

  @override
  String get onboardingContinue => 'המשך';

  @override
  String get onboardingGetStarted => 'בואו נתחיל';

  @override
  String get onboardingWelcomeTitle => 'בנו הרגלי תרופות\nבלתי שבירים';

  @override
  String get onboardingWelcomeBody =>
      'רצפים, תזכורות חכמות ו-AI ששומר עליכם במסלול — כל יום.';

  @override
  String get onboardingScanTitle => 'סרקו כל כדור\nתוך שניות';

  @override
  String get onboardingScanBodyDemo =>
      'הקישו למטה כדי לראות את ה-AI מזהה תרופה לדוגמה באופן מיידי.';

  @override
  String get onboardingScanBodyDone =>
      'ככה מהיר Med AI. בלי הקלדה, בלי ניחושים.';

  @override
  String get onboardingSimulateScan => 'הדמיית סריקה ←';

  @override
  String get onboardingPermissionTitle => 'המצלמה שלכם,\nהפרטיות שלכם';

  @override
  String get onboardingPermissionBody =>
      'אנו משתמשים במצלמה רק כדי לקרוא תוויות של כדורים. התמונות מעובדות באופן מאובטח ולעולם אינן נמכרות.';

  @override
  String get onboardingPermissionLink => 'למדו כיצד אנו מגנים על הנתונים שלכם';

  @override
  String get onboardingPersonalizeTitle => 'התאימו אישית\nאת החוויה שלכם';

  @override
  String get onboardingQuizMedCount => 'כמה תרופות?';

  @override
  String get onboardingQuizRole => 'עבור מי אתם עוקבים?';

  @override
  String get onboardingQuizSchedule => 'מתי אתם נוטלים את רוב התרופות?';

  @override
  String get onboardingRoleSelf => 'עבור עצמי';

  @override
  String get onboardingRoleCaregiver => 'מישהו שאני מטפל בו';

  @override
  String get onboardingScheduleMorning => 'בוקר';

  @override
  String get onboardingScheduleEvening => 'ערב';

  @override
  String get onboardingScheduleBoth => 'שניהם';

  @override
  String get onboardingSocialTitle => 'הצטרפו ל-50,000+\nאלופי בריאות';

  @override
  String get onboardingSocialQuote =>
      '\"Med AI שינה את האופן שבו המשפחה שלי מנהלת תרופות. תכונת הסריקה לבדה חוסכת לנו 10 דקות ביום.\"';

  @override
  String get onboardingSocialAttribution => '— ביקורת App Store, 5 כוכבים';

  @override
  String get onboardingAllowCamera => 'אפשר גישה למצלמה';

  @override
  String get onboardingTryDemoScan => 'נסו סריקת הדגמה';

  @override
  String get loadingHealthData => 'טוען את נתוני הבריאות שלך…';
}
