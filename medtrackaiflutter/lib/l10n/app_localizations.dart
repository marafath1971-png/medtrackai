import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_he.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_ms.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('es'),
    Locale('he'),
    Locale('ja'),
    Locale('ko'),
    Locale('ms')
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'MedAI'**
  String get appTitle;

  /// No description provided for @greetingHero.
  ///
  /// In en, this message translates to:
  /// **'Hero'**
  String get greetingHero;

  /// No description provided for @homeTab.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTab;

  /// No description provided for @alarmsTab.
  ///
  /// In en, this message translates to:
  /// **'Alarms'**
  String get alarmsTab;

  /// No description provided for @dashboardTab.
  ///
  /// In en, this message translates to:
  /// **'Trends'**
  String get dashboardTab;

  /// No description provided for @familyTab.
  ///
  /// In en, this message translates to:
  /// **'Circle'**
  String get familyTab;

  /// No description provided for @scanTab.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get scanTab;

  /// Stat card label showing when the next dose is due
  ///
  /// In en, this message translates to:
  /// **'Next dose'**
  String get homeNextDose;

  /// Stat card label shown instead of 'Next dose' when viewing a day other than today
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get homeSchedule;

  /// Stat card label for the number of doses remaining today
  ///
  /// In en, this message translates to:
  /// **'Doses left'**
  String get homeDosesLeft;

  /// Section heading above the user's medicine list
  ///
  /// In en, this message translates to:
  /// **'Your medicines'**
  String get homeYourMedicines;

  /// Shown in place of a dose time when the user has no medicines yet
  ///
  /// In en, this message translates to:
  /// **'Add meds'**
  String get homeAddMeds;

  /// Shown in place of a dose time when every dose for the day is done
  ///
  /// In en, this message translates to:
  /// **'All clear'**
  String get homeAllClear;

  /// Stat card label pointing at the earliest dose not yet taken
  ///
  /// In en, this message translates to:
  /// **'First pending'**
  String get homeFirstPending;

  /// No description provided for @countrySelectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Where are you located?'**
  String get countrySelectionTitle;

  /// No description provided for @countrySelectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Helps us identify local medicine brands'**
  String get countrySelectionSubtitle;

  /// No description provided for @prnLabel.
  ///
  /// In en, this message translates to:
  /// **'As Needed'**
  String get prnLabel;

  /// No description provided for @prnUndoToast.
  ///
  /// In en, this message translates to:
  /// **'PRN dose removed'**
  String get prnUndoToast;

  /// No description provided for @dailyLogTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily Log'**
  String get dailyLogTitle;

  /// No description provided for @noMedicinesScheduled.
  ///
  /// In en, this message translates to:
  /// **'No medicines scheduled for this day.'**
  String get noMedicinesScheduled;

  /// No description provided for @remaining.
  ///
  /// In en, this message translates to:
  /// **'remaining'**
  String get remaining;

  /// No description provided for @refillRequired.
  ///
  /// In en, this message translates to:
  /// **'Refill Required'**
  String get refillRequired;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get country;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'SAVE CHANGES'**
  String get saveChanges;

  /// No description provided for @inventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get inventory;

  /// No description provided for @noMedicines.
  ///
  /// In en, this message translates to:
  /// **'No medicines'**
  String get noMedicines;

  /// No description provided for @takeNow.
  ///
  /// In en, this message translates to:
  /// **'Take Now'**
  String get takeNow;

  /// No description provided for @snooze.
  ///
  /// In en, this message translates to:
  /// **'Snooze'**
  String get snooze;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @pharmacyLabel.
  ///
  /// In en, this message translates to:
  /// **'Pharmacy'**
  String get pharmacyLabel;

  /// No description provided for @pharmacyPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Pharmacy Phone'**
  String get pharmacyPhoneLabel;

  /// No description provided for @rxNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Rx Number'**
  String get rxNumberLabel;

  /// No description provided for @globalSettings.
  ///
  /// In en, this message translates to:
  /// **'Global Settings'**
  String get globalSettings;

  /// No description provided for @religiousObservance.
  ///
  /// In en, this message translates to:
  /// **'Religious Observance'**
  String get religiousObservance;

  /// No description provided for @shabbatMode.
  ///
  /// In en, this message translates to:
  /// **'Shabbat Mode'**
  String get shabbatMode;

  /// No description provided for @prayerAwareReminders.
  ///
  /// In en, this message translates to:
  /// **'Prayer-Aware Reminders'**
  String get prayerAwareReminders;

  /// No description provided for @halalDetection.
  ///
  /// In en, this message translates to:
  /// **'Halal & Gelatin Detection'**
  String get halalDetection;

  /// No description provided for @amoledMode.
  ///
  /// In en, this message translates to:
  /// **'AMOLED Mode (Pixel Save)'**
  String get amoledMode;

  /// No description provided for @diabetesMode.
  ///
  /// In en, this message translates to:
  /// **'Diabetes Mode'**
  String get diabetesMode;

  /// No description provided for @hypertensionMode.
  ///
  /// In en, this message translates to:
  /// **'Hypertension Mode'**
  String get hypertensionMode;

  /// No description provided for @supportedMarkets.
  ///
  /// In en, this message translates to:
  /// **'Supported Markets'**
  String get supportedMarkets;

  /// No description provided for @halalSafe.
  ///
  /// In en, this message translates to:
  /// **'Halal Safe'**
  String get halalSafe;

  /// No description provided for @gelatinWarning.
  ///
  /// In en, this message translates to:
  /// **'Contains Gelatin'**
  String get gelatinWarning;

  /// No description provided for @halalUncertain.
  ///
  /// In en, this message translates to:
  /// **'Halal Uncertain'**
  String get halalUncertain;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @globalSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage international market settings'**
  String get globalSettingsSubtitle;

  /// No description provided for @medicationDisplay.
  ///
  /// In en, this message translates to:
  /// **'Medication Display'**
  String get medicationDisplay;

  /// No description provided for @showGenericNames.
  ///
  /// In en, this message translates to:
  /// **'Show Generic (INN) Names'**
  String get showGenericNames;

  /// No description provided for @showGenericNamesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Display international non-proprietary names instead of brand names'**
  String get showGenericNamesSubtitle;

  /// No description provided for @pbsSafetyNet.
  ///
  /// In en, this message translates to:
  /// **'PBS Safety Net Tracker'**
  String get pbsSafetyNet;

  /// No description provided for @pbsSafetyNetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Australia — track annual co-payment spend'**
  String get pbsSafetyNetSubtitle;

  /// No description provided for @pbsThreshold.
  ///
  /// In en, this message translates to:
  /// **'Annual threshold: \$1,622.90'**
  String get pbsThreshold;

  /// No description provided for @pbsSpent.
  ///
  /// In en, this message translates to:
  /// **'Spent: \${amount}'**
  String pbsSpent(Object amount);

  /// No description provided for @pbsRemaining.
  ///
  /// In en, this message translates to:
  /// **'\${amount} to go'**
  String pbsRemaining(Object amount);

  /// No description provided for @reached.
  ///
  /// In en, this message translates to:
  /// **'Reached!'**
  String get reached;

  /// No description provided for @medsSubsidised.
  ///
  /// In en, this message translates to:
  /// **'Meds now subsidised!'**
  String get medsSubsidised;

  /// No description provided for @spentAmountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Drag to update your annual spent amount (co-payments for all PBS prescriptions this calendar year)'**
  String get spentAmountSubtitle;

  /// No description provided for @clinicalModes.
  ///
  /// In en, this message translates to:
  /// **'Clinical Modes'**
  String get clinicalModes;

  /// No description provided for @clinicalModesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'USA · UK · UAE · Malaysia'**
  String get clinicalModesSubtitle;

  /// No description provided for @diabetesModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Log blood glucose alongside insulin / diabetes medications'**
  String get diabetesModeSubtitle;

  /// No description provided for @hypertensionModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Log blood pressure alongside antihypertensive medications'**
  String get hypertensionModeSubtitle;

  /// No description provided for @displaySettings.
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get displaySettings;

  /// No description provided for @amoledModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use true #000000 background to optimise AMOLED displays and save battery'**
  String get amoledModeSubtitle;

  /// No description provided for @shabbatModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Gentle vibrate-only reminders from Friday sunset to Saturday night'**
  String get shabbatModeSubtitle;

  /// No description provided for @selectCountry.
  ///
  /// In en, this message translates to:
  /// **'Select Country'**
  String get selectCountry;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @aiSafetyProfile.
  ///
  /// In en, this message translates to:
  /// **'AI Safety Profile'**
  String get aiSafetyProfile;

  /// No description provided for @verified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verified;

  /// No description provided for @criticalWarnings.
  ///
  /// In en, this message translates to:
  /// **'Critical Warnings'**
  String get criticalWarnings;

  /// No description provided for @drugInteractions.
  ///
  /// In en, this message translates to:
  /// **'Drug Interactions'**
  String get drugInteractions;

  /// No description provided for @dietaryLifestyleRules.
  ///
  /// In en, this message translates to:
  /// **'Dietary & Lifestyle Rules'**
  String get dietaryLifestyleRules;

  /// No description provided for @ahaInsight.
  ///
  /// In en, this message translates to:
  /// **'Aha! Insight'**
  String get ahaInsight;

  /// No description provided for @generateSafetyProfile.
  ///
  /// In en, this message translates to:
  /// **'Generate Safety Profile'**
  String get generateSafetyProfile;

  /// No description provided for @analyzingClinicalLimits.
  ///
  /// In en, this message translates to:
  /// **'Analyzing Clinical Limits...'**
  String get analyzingClinicalLimits;

  /// No description provided for @safetyLoadingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Please wait while AI verifies interactions, dangers, and food rules.'**
  String get safetyLoadingSubtitle;

  /// No description provided for @safetyPromptSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap to instantly analyze this medication for dangers, drug interactions, and lifestyle rules.'**
  String get safetyPromptSubtitle;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get goodEvening;

  /// No description provided for @hiUser.
  ///
  /// In en, this message translates to:
  /// **'Hi, {name} 👋'**
  String hiUser(String name);

  /// No description provided for @startJourney.
  ///
  /// In en, this message translates to:
  /// **'Let\'s start your health journey ✨'**
  String get startJourney;

  /// No description provided for @allDosesTaken.
  ///
  /// In en, this message translates to:
  /// **'All doses taken today! 🌟'**
  String get allDosesTaken;

  /// No description provided for @dosesOverdue.
  ///
  /// In en, this message translates to:
  /// **'{count} doses overdue — take them now ⚠️'**
  String dosesOverdue(int count);

  /// No description provided for @dosesLeft.
  ///
  /// In en, this message translates to:
  /// **'{count} doses left today'**
  String dosesLeft(int count);

  /// No description provided for @healthReportTitle.
  ///
  /// In en, this message translates to:
  /// **'MedAI Health Report'**
  String get healthReportTitle;

  /// No description provided for @medicalSummarySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Personal Medical Summary & Adherence Trends'**
  String get medicalSummarySubtitle;

  /// No description provided for @patientLabel.
  ///
  /// In en, this message translates to:
  /// **'Patient: {name}'**
  String patientLabel(String name);

  /// No description provided for @reportDate.
  ///
  /// In en, this message translates to:
  /// **'Date: {date}'**
  String reportDate(String date);

  /// No description provided for @overallAdherence.
  ///
  /// In en, this message translates to:
  /// **'Overall Adherence'**
  String get overallAdherence;

  /// No description provided for @activeMedications.
  ///
  /// In en, this message translates to:
  /// **'Active Medications'**
  String get activeMedications;

  /// No description provided for @reportPeriod.
  ///
  /// In en, this message translates to:
  /// **'Report Period'**
  String get reportPeriod;

  /// No description provided for @last30Days.
  ///
  /// In en, this message translates to:
  /// **'Last 30 Days'**
  String get last30Days;

  /// No description provided for @currentMedications.
  ///
  /// In en, this message translates to:
  /// **'Current Medications'**
  String get currentMedications;

  /// No description provided for @medicineCol.
  ///
  /// In en, this message translates to:
  /// **'Medicine'**
  String get medicineCol;

  /// No description provided for @doseCol.
  ///
  /// In en, this message translates to:
  /// **'Dose'**
  String get doseCol;

  /// No description provided for @frequencyCol.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get frequencyCol;

  /// No description provided for @stockRemainingCol.
  ///
  /// In en, this message translates to:
  /// **'Stock Remaining'**
  String get stockRemainingCol;

  /// No description provided for @recentSymptoms.
  ///
  /// In en, this message translates to:
  /// **'Recent Symptoms & Well-being'**
  String get recentSymptoms;

  /// No description provided for @symptomDateCol.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get symptomDateCol;

  /// No description provided for @symptomNameCol.
  ///
  /// In en, this message translates to:
  /// **'Symptom'**
  String get symptomNameCol;

  /// No description provided for @severityCol.
  ///
  /// In en, this message translates to:
  /// **'Severity'**
  String get severityCol;

  /// No description provided for @notesCol.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesCol;

  /// No description provided for @noSymptomsLogged.
  ///
  /// In en, this message translates to:
  /// **'No symptoms logged in this period.'**
  String get noSymptomsLogged;

  /// No description provided for @reportFooter.
  ///
  /// In en, this message translates to:
  /// **'Generated by MedAI Pro. This report is for informational purposes only and should be reviewed by a qualified healthcare professional.'**
  String get reportFooter;

  /// No description provided for @settingsStats.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get settingsStats;

  /// No description provided for @settingsApp.
  ///
  /// In en, this message translates to:
  /// **'App Settings'**
  String get settingsApp;

  /// No description provided for @settingsData.
  ///
  /// In en, this message translates to:
  /// **'Data & Privacy'**
  String get settingsData;

  /// No description provided for @settingsGlobal.
  ///
  /// In en, this message translates to:
  /// **'Global Settings'**
  String get settingsGlobal;

  /// No description provided for @settingsProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get settingsProfile;

  /// No description provided for @adherenceLabel.
  ///
  /// In en, this message translates to:
  /// **'ADHERENCE'**
  String get adherenceLabel;

  /// No description provided for @streakLabel.
  ///
  /// In en, this message translates to:
  /// **'STREAK'**
  String get streakLabel;

  /// No description provided for @streakDays.
  ///
  /// In en, this message translates to:
  /// **'{count} Days'**
  String streakDays(int count);

  /// No description provided for @generateClinicalReport.
  ///
  /// In en, this message translates to:
  /// **'GENERATE CLINICAL REPORT'**
  String get generateClinicalReport;

  /// No description provided for @fetchingAiInsights.
  ///
  /// In en, this message translates to:
  /// **'FETCHING AI INSIGHTS...'**
  String get fetchingAiInsights;

  /// No description provided for @aiCoachDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'This dashboard uses AI to analyze patterns. Always consult your doctor for medical advice.'**
  String get aiCoachDisclaimer;

  /// No description provided for @insightsTitle.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get insightsTitle;

  /// No description provided for @insightsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Analytics & health patterns'**
  String get insightsSubtitle;

  /// No description provided for @dataSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'YOUR DATA SUMMARY'**
  String get dataSummaryTitle;

  /// No description provided for @dataMedicinesLabel.
  ///
  /// In en, this message translates to:
  /// **'Medicines'**
  String get dataMedicinesLabel;

  /// No description provided for @dataAlarmsLabel.
  ///
  /// In en, this message translates to:
  /// **'Alarms set'**
  String get dataAlarmsLabel;

  /// No description provided for @dataDaysTrackedLabel.
  ///
  /// In en, this message translates to:
  /// **'Days tracked'**
  String get dataDaysTrackedLabel;

  /// No description provided for @dataDosesLoggedLabel.
  ///
  /// In en, this message translates to:
  /// **'Doses logged'**
  String get dataDosesLoggedLabel;

  /// No description provided for @exportAndBackup.
  ///
  /// In en, this message translates to:
  /// **'Export & Backup'**
  String get exportAndBackup;

  /// No description provided for @exportPdfReport.
  ///
  /// In en, this message translates to:
  /// **'Export PDF Report'**
  String get exportPdfReport;

  /// No description provided for @exportPdfSubtitle.
  ///
  /// In en, this message translates to:
  /// **'For doctors and caregivers'**
  String get exportPdfSubtitle;

  /// No description provided for @exportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export History as CSV'**
  String get exportCsv;

  /// No description provided for @exportCsvSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count} dose records'**
  String exportCsvSubtitle(int count);

  /// No description provided for @resetSection.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get resetSection;

  /// No description provided for @deleteAllData.
  ///
  /// In en, this message translates to:
  /// **'Delete All Data'**
  String get deleteAllData;

  /// No description provided for @deleteAllDataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Removes all medicines, history & settings'**
  String get deleteAllDataSubtitle;

  /// No description provided for @deleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete All Data?'**
  String get deleteConfirmTitle;

  /// No description provided for @deleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete all your data. This cannot be undone.'**
  String get deleteConfirmBody;

  /// No description provided for @deleteButton.
  ///
  /// In en, this message translates to:
  /// **'Delete Everything'**
  String get deleteButton;

  /// No description provided for @legalSection.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get legalSection;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @privacyPolicySubtitle.
  ///
  /// In en, this message translates to:
  /// **'How we protect your health data'**
  String get privacyPolicySubtitle;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @termsOfServiceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Rules for using MedAI'**
  String get termsOfServiceSubtitle;

  /// No description provided for @appVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get appVersionLabel;

  /// No description provided for @appVersionValue.
  ///
  /// In en, this message translates to:
  /// **'1.0.0+1'**
  String get appVersionValue;

  /// No description provided for @analysisFailed.
  ///
  /// In en, this message translates to:
  /// **'Analysis Failed'**
  String get analysisFailed;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get somethingWentWrong;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get onboardingContinue;

  /// No description provided for @onboardingGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get onboardingGetStarted;

  /// No description provided for @onboardingWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Build unbreakable\nmed habits'**
  String get onboardingWelcomeTitle;

  /// No description provided for @onboardingWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Streaks, smart reminders, and AI that keeps you on track — every single day.'**
  String get onboardingWelcomeBody;

  /// No description provided for @onboardingScanTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan any pill\nin seconds'**
  String get onboardingScanTitle;

  /// No description provided for @onboardingScanBodyDemo.
  ///
  /// In en, this message translates to:
  /// **'Tap below to see AI identify a sample medication instantly.'**
  String get onboardingScanBodyDemo;

  /// No description provided for @onboardingScanBodyDone.
  ///
  /// In en, this message translates to:
  /// **'That\'s how fast Med AI works. No typing, no guesswork.'**
  String get onboardingScanBodyDone;

  /// No description provided for @onboardingSimulateScan.
  ///
  /// In en, this message translates to:
  /// **'Simulate scan →'**
  String get onboardingSimulateScan;

  /// No description provided for @onboardingPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Your camera,\nyour privacy'**
  String get onboardingPermissionTitle;

  /// No description provided for @onboardingPermissionBody.
  ///
  /// In en, this message translates to:
  /// **'We only use the camera to read pill labels. Images are processed securely and never sold.'**
  String get onboardingPermissionBody;

  /// No description provided for @onboardingPermissionLink.
  ///
  /// In en, this message translates to:
  /// **'Learn how we protect your data'**
  String get onboardingPermissionLink;

  /// No description provided for @onboardingPersonalizeTitle.
  ///
  /// In en, this message translates to:
  /// **'Personalize\nyour experience'**
  String get onboardingPersonalizeTitle;

  /// No description provided for @onboardingQuizMedCount.
  ///
  /// In en, this message translates to:
  /// **'How many medications?'**
  String get onboardingQuizMedCount;

  /// No description provided for @onboardingQuizRole.
  ///
  /// In en, this message translates to:
  /// **'Who are you tracking for?'**
  String get onboardingQuizRole;

  /// No description provided for @onboardingQuizSchedule.
  ///
  /// In en, this message translates to:
  /// **'When do you take most meds?'**
  String get onboardingQuizSchedule;

  /// No description provided for @onboardingRoleSelf.
  ///
  /// In en, this message translates to:
  /// **'Myself'**
  String get onboardingRoleSelf;

  /// No description provided for @onboardingRoleCaregiver.
  ///
  /// In en, this message translates to:
  /// **'Someone I care for'**
  String get onboardingRoleCaregiver;

  /// No description provided for @onboardingScheduleMorning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get onboardingScheduleMorning;

  /// No description provided for @onboardingScheduleEvening.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get onboardingScheduleEvening;

  /// No description provided for @onboardingScheduleBoth.
  ///
  /// In en, this message translates to:
  /// **'Both'**
  String get onboardingScheduleBoth;

  /// No description provided for @onboardingSocialTitle.
  ///
  /// In en, this message translates to:
  /// **'Join 50,000+\nhealth champions'**
  String get onboardingSocialTitle;

  /// No description provided for @onboardingSocialQuote.
  ///
  /// In en, this message translates to:
  /// **'\"Med AI changed how my family manages medications. The scan feature alone saves us 10 minutes a day.\"'**
  String get onboardingSocialQuote;

  /// No description provided for @onboardingSocialAttribution.
  ///
  /// In en, this message translates to:
  /// **'— App Store review, 5 stars'**
  String get onboardingSocialAttribution;

  /// No description provided for @onboardingAllowCamera.
  ///
  /// In en, this message translates to:
  /// **'Allow Camera Access'**
  String get onboardingAllowCamera;

  /// No description provided for @onboardingTryDemoScan.
  ///
  /// In en, this message translates to:
  /// **'Try Demo Scan'**
  String get onboardingTryDemoScan;

  /// No description provided for @loadingHealthData.
  ///
  /// In en, this message translates to:
  /// **'Loading your health data…'**
  String get loadingHealthData;

  /// No description provided for @appstateFamilyUpdate.
  ///
  /// In en, this message translates to:
  /// **'Family Update'**
  String get appstateFamilyUpdate;

  /// No description provided for @wellnesscontrollerEveningRoutineRisk.
  ///
  /// In en, this message translates to:
  /// **'Evening Routine Risk'**
  String get wellnesscontrollerEveningRoutineRisk;

  /// No description provided for @wellnesscontrollerWeekendPatternChange.
  ///
  /// In en, this message translates to:
  /// **'Weekend Pattern Change'**
  String get wellnesscontrollerWeekendPatternChange;

  /// No description provided for @alarmsUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get alarmsUpcoming;

  /// No description provided for @alarmsLoggedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Logged successfully'**
  String get alarmsLoggedSuccessfully;

  /// No description provided for @alarmsSlideToRecordDose.
  ///
  /// In en, this message translates to:
  /// **'Slide to record dose →'**
  String get alarmsSlideToRecordDose;

  /// No description provided for @alarmsDoseRecorded.
  ///
  /// In en, this message translates to:
  /// **'✓ Dose Recorded'**
  String get alarmsDoseRecorded;

  /// No description provided for @alarmsNeedsSchedule.
  ///
  /// In en, this message translates to:
  /// **'Needs schedule'**
  String get alarmsNeedsSchedule;

  /// No description provided for @alarmsLabel.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get alarmsLabel;

  /// No description provided for @alarmsReminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get alarmsReminders;

  /// No description provided for @alarmsPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get alarmsPaused;

  /// No description provided for @alarmsAddReminder.
  ///
  /// In en, this message translates to:
  /// **'Add reminder'**
  String get alarmsAddReminder;

  /// No description provided for @alarmsSlideToRecordDose2.
  ///
  /// In en, this message translates to:
  /// **'Slide to record dose'**
  String get alarmsSlideToRecordDose2;

  /// No description provided for @alarmsNoRemindersYet.
  ///
  /// In en, this message translates to:
  /// **'No reminders yet'**
  String get alarmsNoRemindersYet;

  /// No description provided for @alarmsSetReminderFor.
  ///
  /// In en, this message translates to:
  /// **'Set reminder for'**
  String get alarmsSetReminderFor;

  /// No description provided for @analysisKnowYourMedicine.
  ///
  /// In en, this message translates to:
  /// **'Know your medicine'**
  String get analysisKnowYourMedicine;

  /// No description provided for @analysisScanAgain.
  ///
  /// In en, this message translates to:
  /// **'Scan again'**
  String get analysisScanAgain;

  /// No description provided for @analysisAiIdentificationAlwaysVerifyWithYour.
  ///
  /// In en, this message translates to:
  /// **'AI identification — always verify with your pharmacist or prescriber.'**
  String get analysisAiIdentificationAlwaysVerifyWithYour;

  /// No description provided for @analysisScanResult.
  ///
  /// In en, this message translates to:
  /// **'Scan result'**
  String get analysisScanResult;

  /// No description provided for @analysisSmartTrustedBuiltForYou.
  ///
  /// In en, this message translates to:
  /// **'Smart · trusted · built for you'**
  String get analysisSmartTrustedBuiltForYou;

  /// No description provided for @analysisMorningDose.
  ///
  /// In en, this message translates to:
  /// **'Morning Dose'**
  String get analysisMorningDose;

  /// No description provided for @analysisSafetyFirst.
  ///
  /// In en, this message translates to:
  /// **'Safety first'**
  String get analysisSafetyFirst;

  /// No description provided for @analysisAllergyAlerts.
  ///
  /// In en, this message translates to:
  /// **'Allergy alerts'**
  String get analysisAllergyAlerts;

  /// No description provided for @analysisChildSafety.
  ///
  /// In en, this message translates to:
  /// **'Child safety'**
  String get analysisChildSafety;

  /// No description provided for @analysisPregnancyNursing.
  ///
  /// In en, this message translates to:
  /// **'Pregnancy & nursing'**
  String get analysisPregnancyNursing;

  /// No description provided for @analysisSkincareNotes.
  ///
  /// In en, this message translates to:
  /// **'Skincare notes'**
  String get analysisSkincareNotes;

  /// No description provided for @analysisQuickInsights.
  ///
  /// In en, this message translates to:
  /// **'Quick insights'**
  String get analysisQuickInsights;

  /// No description provided for @analysisTiming.
  ///
  /// In en, this message translates to:
  /// **'Timing'**
  String get analysisTiming;

  /// No description provided for @analysisEvidence.
  ///
  /// In en, this message translates to:
  /// **'Evidence'**
  String get analysisEvidence;

  /// No description provided for @analysisHalal.
  ///
  /// In en, this message translates to:
  /// **'Halal'**
  String get analysisHalal;

  /// No description provided for @analysisAllergyRisk.
  ///
  /// In en, this message translates to:
  /// **'Allergy risk'**
  String get analysisAllergyRisk;

  /// No description provided for @analysisSideEffectMap.
  ///
  /// In en, this message translates to:
  /// **'Side-effect map'**
  String get analysisSideEffectMap;

  /// No description provided for @analysisOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get analysisOverview;

  /// No description provided for @analysisHowThisSupportsYou.
  ///
  /// In en, this message translates to:
  /// **'How this supports you'**
  String get analysisHowThisSupportsYou;

  /// No description provided for @analysisBenefits.
  ///
  /// In en, this message translates to:
  /// **'Benefits'**
  String get analysisBenefits;

  /// No description provided for @analysisInteractions.
  ///
  /// In en, this message translates to:
  /// **'Interactions'**
  String get analysisInteractions;

  /// No description provided for @analysisExpertPerspectives.
  ///
  /// In en, this message translates to:
  /// **'Expert perspectives'**
  String get analysisExpertPerspectives;

  /// No description provided for @analysisPersonalisedWithContextFromYourCurrent.
  ///
  /// In en, this message translates to:
  /// **'Personalised with context from your current medications.'**
  String get analysisPersonalisedWithContextFromYourCurrent;

  /// No description provided for @analysisAiAssistant.
  ///
  /// In en, this message translates to:
  /// **'AI Assistant'**
  String get analysisAiAssistant;

  /// No description provided for @analysisAskAboutInteractionsTiming.
  ///
  /// In en, this message translates to:
  /// **'Ask about interactions, timing…'**
  String get analysisAskAboutInteractionsTiming;

  /// No description provided for @analysisAiIsTyping.
  ///
  /// In en, this message translates to:
  /// **'AI is typing'**
  String get analysisAiIsTyping;

  /// No description provided for @analysisIdentified.
  ///
  /// In en, this message translates to:
  /// **'IDENTIFIED'**
  String get analysisIdentified;

  /// No description provided for @analysisAtAGlance.
  ///
  /// In en, this message translates to:
  /// **'AT A GLANCE'**
  String get analysisAtAGlance;

  /// No description provided for @analysisChildDosingDiffers.
  ///
  /// In en, this message translates to:
  /// **'Child dosing differs'**
  String get analysisChildDosingDiffers;

  /// No description provided for @analysisAiMatch.
  ///
  /// In en, this message translates to:
  /// **'AI match'**
  String get analysisAiMatch;

  /// No description provided for @analysisSideEffects.
  ///
  /// In en, this message translates to:
  /// **'Side effects'**
  String get analysisSideEffects;

  /// No description provided for @appshelldartRunningLow.
  ///
  /// In en, this message translates to:
  /// **'Running low'**
  String get appshelldartRunningLow;

  /// No description provided for @appshelldartCameraAccess.
  ///
  /// In en, this message translates to:
  /// **'Camera Access'**
  String get appshelldartCameraAccess;

  /// No description provided for @appshelldartDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get appshelldartDismiss;

  /// No description provided for @appshelldartAddAMedicineByScanning.
  ///
  /// In en, this message translates to:
  /// **'Add a medicine by scanning'**
  String get appshelldartAddAMedicineByScanning;

  /// No description provided for @authHaveAnInviteCode.
  ///
  /// In en, this message translates to:
  /// **'Have an invite code?'**
  String get authHaveAnInviteCode;

  /// No description provided for @authApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get authApply;

  /// No description provided for @authByContinuingYouAgreeToOur.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to our '**
  String get authByContinuingYouAgreeToOur;

  /// No description provided for @authAnd.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get authAnd;

  /// No description provided for @authForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get authForgotPassword;

  /// No description provided for @authInviteApplied.
  ///
  /// In en, this message translates to:
  /// **'Invite applied'**
  String get authInviteApplied;

  /// No description provided for @authEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Email Sent'**
  String get authEmailSent;

  /// No description provided for @authMedAiMascot.
  ///
  /// In en, this message translates to:
  /// **'Med AI mascot'**
  String get authMedAiMascot;

  /// No description provided for @authContinueWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get authContinueWithApple;

  /// No description provided for @authContinueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get authContinueWithGoogle;

  /// No description provided for @authContinueWithEmail.
  ///
  /// In en, this message translates to:
  /// **'Continue with Email'**
  String get authContinueWithEmail;

  /// No description provided for @authTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get authTerms;

  /// No description provided for @authHaveAnInviteCode2.
  ///
  /// In en, this message translates to:
  /// **'Have an invite code'**
  String get authHaveAnInviteCode2;

  /// No description provided for @authEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get authEmailAddress;

  /// No description provided for @authPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPassword;

  /// No description provided for @authForgotPassword2.
  ///
  /// In en, this message translates to:
  /// **'Forgot password'**
  String get authForgotPassword2;

  /// No description provided for @authEnterPin.
  ///
  /// In en, this message translates to:
  /// **'Enter PIN'**
  String get authEnterPin;

  /// No description provided for @dashboardSupplyStatus.
  ///
  /// In en, this message translates to:
  /// **'Supply status'**
  String get dashboardSupplyStatus;

  /// No description provided for @dashboardAiInsights.
  ///
  /// In en, this message translates to:
  /// **'AI insights'**
  String get dashboardAiInsights;

  /// No description provided for @dashboardExportDataAsCsv.
  ///
  /// In en, this message translates to:
  /// **'Export data as CSV'**
  String get dashboardExportDataAsCsv;

  /// No description provided for @dashboardConnectHealthData.
  ///
  /// In en, this message translates to:
  /// **'Connect health data'**
  String get dashboardConnectHealthData;

  /// No description provided for @dashboardSyncStepsAndHeartRateAlongside.
  ///
  /// In en, this message translates to:
  /// **'Sync steps and heart rate alongside your meds.'**
  String get dashboardSyncStepsAndHeartRateAlongside;

  /// No description provided for @dashboardN7DayTrendBelow.
  ///
  /// In en, this message translates to:
  /// **'7-day trend below'**
  String get dashboardN7DayTrendBelow;

  /// No description provided for @dashboardYourWeekAtAGlance.
  ///
  /// In en, this message translates to:
  /// **'Your week at a glance'**
  String get dashboardYourWeekAtAGlance;

  /// No description provided for @dashboardMedicationDiary.
  ///
  /// In en, this message translates to:
  /// **'Medication diary'**
  String get dashboardMedicationDiary;

  /// No description provided for @dashboardMenu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get dashboardMenu;

  /// No description provided for @dashboardDoses.
  ///
  /// In en, this message translates to:
  /// **'Doses'**
  String get dashboardDoses;

  /// No description provided for @dashboardDailyAvg.
  ///
  /// In en, this message translates to:
  /// **'Daily avg'**
  String get dashboardDailyAvg;

  /// No description provided for @dashboardNoDosesLogged.
  ///
  /// In en, this message translates to:
  /// **'No doses logged'**
  String get dashboardNoDosesLogged;

  /// No description provided for @dashboardLogDosesToUnlockYourWeekly.
  ///
  /// In en, this message translates to:
  /// **'Log doses to unlock your weekly trend'**
  String get dashboardLogDosesToUnlockYourWeekly;

  /// No description provided for @dashboardDayStreak.
  ///
  /// In en, this message translates to:
  /// **'Day streak'**
  String get dashboardDayStreak;

  /// No description provided for @dashboardHeartRate.
  ///
  /// In en, this message translates to:
  /// **'Heart rate'**
  String get dashboardHeartRate;

  /// No description provided for @dashboardDosesThisWeek.
  ///
  /// In en, this message translates to:
  /// **'Doses this week'**
  String get dashboardDosesThisWeek;

  /// No description provided for @dashboardStepsToday.
  ///
  /// In en, this message translates to:
  /// **'Steps today'**
  String get dashboardStepsToday;

  /// No description provided for @dashboardSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get dashboardSearch;

  /// No description provided for @dashboardAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get dashboardAnalytics;

  /// No description provided for @dashboardAdherenceHealthTrends.
  ///
  /// In en, this message translates to:
  /// **'Adherence & health trends'**
  String get dashboardAdherenceHealthTrends;

  /// No description provided for @dashboardOpenDailyLog.
  ///
  /// In en, this message translates to:
  /// **'Open daily log'**
  String get dashboardOpenDailyLog;

  /// No description provided for @dashboardTimingConsistency.
  ///
  /// In en, this message translates to:
  /// **'Timing consistency'**
  String get dashboardTimingConsistency;

  /// No description provided for @dashboardAdherenceTrend.
  ///
  /// In en, this message translates to:
  /// **'Adherence trend'**
  String get dashboardAdherenceTrend;

  /// No description provided for @dashboardN30DayProgress.
  ///
  /// In en, this message translates to:
  /// **'30-Day Progress'**
  String get dashboardN30DayProgress;

  /// No description provided for @dashboardN30DaysAgo.
  ///
  /// In en, this message translates to:
  /// **'30 days ago'**
  String get dashboardN30DaysAgo;

  /// No description provided for @dashboardToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dashboardToday;

  /// No description provided for @dashboardAnalyzingYourData.
  ///
  /// In en, this message translates to:
  /// **'Analyzing your data'**
  String get dashboardAnalyzingYourData;

  /// No description provided for @dashboardNoTimingDataYet.
  ///
  /// In en, this message translates to:
  /// **'No timing data yet'**
  String get dashboardNoTimingDataYet;

  /// No description provided for @dashboardRefreshAiInsights.
  ///
  /// In en, this message translates to:
  /// **'Refresh AI insights'**
  String get dashboardRefreshAiInsights;

  /// No description provided for @dashboardAiInsightsWillAppearHere.
  ///
  /// In en, this message translates to:
  /// **'AI insights will appear here'**
  String get dashboardAiInsightsWillAppearHere;

  /// No description provided for @dashboardNoTrendYet.
  ///
  /// In en, this message translates to:
  /// **'No trend yet'**
  String get dashboardNoTrendYet;

  /// No description provided for @dashboardNoInventoryTracked.
  ///
  /// In en, this message translates to:
  /// **'No inventory tracked'**
  String get dashboardNoInventoryTracked;

  /// No description provided for @familyCriticalProfile.
  ///
  /// In en, this message translates to:
  /// **'Critical Profile'**
  String get familyCriticalProfile;

  /// No description provided for @familyPrioritizeNotificationsAndAlerts.
  ///
  /// In en, this message translates to:
  /// **'Prioritize notifications and alerts'**
  String get familyPrioritizeNotificationsAndAlerts;

  /// No description provided for @familyAddCaregiver.
  ///
  /// In en, this message translates to:
  /// **'Add Caregiver'**
  String get familyAddCaregiver;

  /// No description provided for @familyAvatar.
  ///
  /// In en, this message translates to:
  /// **'Avatar'**
  String get familyAvatar;

  /// No description provided for @familySaveCaregiver.
  ///
  /// In en, this message translates to:
  /// **'Save Caregiver'**
  String get familySaveCaregiver;

  /// No description provided for @familyTapToAddPhoto.
  ///
  /// In en, this message translates to:
  /// **'Tap to add photo'**
  String get familyTapToAddPhoto;

  /// No description provided for @familyCriticalCareMember.
  ///
  /// In en, this message translates to:
  /// **'Critical Care Member'**
  String get familyCriticalCareMember;

  /// No description provided for @familyPrioritizeAlertsAndMonitoring.
  ///
  /// In en, this message translates to:
  /// **'Prioritize alerts and monitoring'**
  String get familyPrioritizeAlertsAndMonitoring;

  /// No description provided for @familyAddMember.
  ///
  /// In en, this message translates to:
  /// **'Add Member'**
  String get familyAddMember;

  /// No description provided for @familyAddProfilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Add profile photo'**
  String get familyAddProfilePhoto;

  /// No description provided for @familySaveProfile.
  ///
  /// In en, this message translates to:
  /// **'Save Profile'**
  String get familySaveProfile;

  /// No description provided for @familyRemoveMember.
  ///
  /// In en, this message translates to:
  /// **'Remove Member'**
  String get familyRemoveMember;

  /// No description provided for @familyRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get familyRemove;

  /// No description provided for @familyTapToChangePhoto.
  ///
  /// In en, this message translates to:
  /// **'Tap to change photo'**
  String get familyTapToChangePhoto;

  /// No description provided for @familyEditMember.
  ///
  /// In en, this message translates to:
  /// **'Edit Member'**
  String get familyEditMember;

  /// No description provided for @familyChangeProfilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change profile photo'**
  String get familyChangeProfilePhoto;

  /// No description provided for @familyUpdateMember.
  ///
  /// In en, this message translates to:
  /// **'Update member'**
  String get familyUpdateMember;

  /// No description provided for @familyAddGuardian.
  ///
  /// In en, this message translates to:
  /// **'Add guardian'**
  String get familyAddGuardian;

  /// No description provided for @familyUrgentMonitoring.
  ///
  /// In en, this message translates to:
  /// **'Urgent monitoring'**
  String get familyUrgentMonitoring;

  /// No description provided for @familySensitiveMedsInThisCircleCaregivers.
  ///
  /// In en, this message translates to:
  /// **'Sensitive meds in this circle — caregivers should review warnings before dose time.'**
  String get familySensitiveMedsInThisCircleCaregivers;

  /// No description provided for @familySwitchToProfile.
  ///
  /// In en, this message translates to:
  /// **'Switch to Profile'**
  String get familySwitchToProfile;

  /// No description provided for @familyGenerateAdherencePdf.
  ///
  /// In en, this message translates to:
  /// **'Generate Adherence PDF'**
  String get familyGenerateAdherencePdf;

  /// No description provided for @familyRemoveProfile.
  ///
  /// In en, this message translates to:
  /// **'Remove profile?'**
  String get familyRemoveProfile;

  /// No description provided for @familyRemoveProfile2.
  ///
  /// In en, this message translates to:
  /// **'Remove Profile'**
  String get familyRemoveProfile2;

  /// No description provided for @familyProtectors.
  ///
  /// In en, this message translates to:
  /// **'Protectors'**
  String get familyProtectors;

  /// No description provided for @familyMonitoring.
  ///
  /// In en, this message translates to:
  /// **'Monitoring'**
  String get familyMonitoring;

  /// No description provided for @familyFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get familyFamily;

  /// No description provided for @familyCare.
  ///
  /// In en, this message translates to:
  /// **'Care'**
  String get familyCare;

  /// No description provided for @familyManaging.
  ///
  /// In en, this message translates to:
  /// **'Managing'**
  String get familyManaging;

  /// No description provided for @familyRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent activity'**
  String get familyRecentActivity;

  /// No description provided for @familyNoGuardiansFound.
  ///
  /// In en, this message translates to:
  /// **'No guardians found'**
  String get familyNoGuardiansFound;

  /// No description provided for @familyProtectYourFamily.
  ///
  /// In en, this message translates to:
  /// **'Protect your family'**
  String get familyProtectYourFamily;

  /// No description provided for @familyJoinFamilyCircle.
  ///
  /// In en, this message translates to:
  /// **'Join family circle'**
  String get familyJoinFamilyCircle;

  /// No description provided for @familyInviteGuardian.
  ///
  /// In en, this message translates to:
  /// **'Invite guardian'**
  String get familyInviteGuardian;

  /// No description provided for @familyEnterProfilePinToSwitch.
  ///
  /// In en, this message translates to:
  /// **'Enter profile PIN to switch'**
  String get familyEnterProfilePinToSwitch;

  /// No description provided for @familyIncorrectPin.
  ///
  /// In en, this message translates to:
  /// **'Incorrect PIN'**
  String get familyIncorrectPin;

  /// No description provided for @familyDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get familyDelete;

  /// No description provided for @familySwitchProfile.
  ///
  /// In en, this message translates to:
  /// **'Switch profile'**
  String get familySwitchProfile;

  /// No description provided for @familyManageSchedulesForYourFamily.
  ///
  /// In en, this message translates to:
  /// **'Manage schedules for your family'**
  String get familyManageSchedulesForYourFamily;

  /// No description provided for @familyAddDependent.
  ///
  /// In en, this message translates to:
  /// **'Add dependent'**
  String get familyAddDependent;

  /// No description provided for @familyScanFromCaregiverApp.
  ///
  /// In en, this message translates to:
  /// **'Scan from caregiver app'**
  String get familyScanFromCaregiverApp;

  /// No description provided for @familyOrUseInviteCode.
  ///
  /// In en, this message translates to:
  /// **'Or use invite code'**
  String get familyOrUseInviteCode;

  /// No description provided for @familyCopyCode.
  ///
  /// In en, this message translates to:
  /// **'Copy code'**
  String get familyCopyCode;

  /// No description provided for @familyWaitingForCaregiverToScan.
  ///
  /// In en, this message translates to:
  /// **'Waiting for caregiver to scan...'**
  String get familyWaitingForCaregiverToScan;

  /// No description provided for @familySuccessCaregiverAdded.
  ///
  /// In en, this message translates to:
  /// **'Success! Caregiver added.'**
  String get familySuccessCaregiverAdded;

  /// No description provided for @familyActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get familyActive;

  /// No description provided for @familyEGSarahJohnson.
  ///
  /// In en, this message translates to:
  /// **'e.g. Sarah Johnson'**
  String get familyEGSarahJohnson;

  /// No description provided for @familyGenerateQrCode.
  ///
  /// In en, this message translates to:
  /// **'Generate QR code'**
  String get familyGenerateQrCode;

  /// No description provided for @familyQrCodeForCaregiverInvite.
  ///
  /// In en, this message translates to:
  /// **'QR code for caregiver invite'**
  String get familyQrCodeForCaregiverInvite;

  /// No description provided for @familyCopyInviteCode.
  ///
  /// In en, this message translates to:
  /// **'Copy invite code'**
  String get familyCopyInviteCode;

  /// No description provided for @familyTheyCanNow.
  ///
  /// In en, this message translates to:
  /// **'They can now:'**
  String get familyTheyCanNow;

  /// No description provided for @familySeeYourDailyAdherence.
  ///
  /// In en, this message translates to:
  /// **'See your daily adherence'**
  String get familySeeYourDailyAdherence;

  /// No description provided for @familyGetMissedDoseAlerts.
  ///
  /// In en, this message translates to:
  /// **'Get missed-dose alerts'**
  String get familyGetMissedDoseAlerts;

  /// No description provided for @familyViewYourMedicineList.
  ///
  /// In en, this message translates to:
  /// **'View your medicine list'**
  String get familyViewYourMedicineList;

  /// No description provided for @familyDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get familyDone;

  /// No description provided for @familyMedaiProtectorAdvisor.
  ///
  /// In en, this message translates to:
  /// **'MedAI protector advisor'**
  String get familyMedaiProtectorAdvisor;

  /// No description provided for @familyIntelligentCareAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Intelligent care analysis'**
  String get familyIntelligentCareAnalysis;

  /// No description provided for @familyPatternsAnalyzedAcrossLast7Days.
  ///
  /// In en, this message translates to:
  /// **'Patterns analyzed across last 7 days'**
  String get familyPatternsAnalyzedAcrossLast7Days;

  /// No description provided for @familyNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get familyNew;

  /// No description provided for @familySafetySimulationOfHowMissedDoses.
  ///
  /// In en, this message translates to:
  /// **'Safety simulation of how missed doses trigger household alerts.'**
  String get familySafetySimulationOfHowMissedDoses;

  /// No description provided for @familyCriticalAlertSent.
  ///
  /// In en, this message translates to:
  /// **'Critical alert sent'**
  String get familyCriticalAlertSent;

  /// No description provided for @familySarahJMissedTheirBloodPressure.
  ///
  /// In en, this message translates to:
  /// **'Sarah J. missed their Blood Pressure medication. Please check on them immediately.'**
  String get familySarahJMissedTheirBloodPressure;

  /// No description provided for @familyEscalationProtocol.
  ///
  /// In en, this message translates to:
  /// **'Escalation protocol'**
  String get familyEscalationProtocol;

  /// No description provided for @familyPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get familyPrevious;

  /// No description provided for @familyCriticalAlert.
  ///
  /// In en, this message translates to:
  /// **'Critical alert'**
  String get familyCriticalAlert;

  /// No description provided for @familyCritical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get familyCritical;

  /// No description provided for @familySafetyProtocol.
  ///
  /// In en, this message translates to:
  /// **'Safety protocol'**
  String get familySafetyProtocol;

  /// No description provided for @familyWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get familyWaiting;

  /// No description provided for @familyTestAlertCycle.
  ///
  /// In en, this message translates to:
  /// **'Test Alert Cycle'**
  String get familyTestAlertCycle;

  /// No description provided for @familySimulateAMissedDoseAlert.
  ///
  /// In en, this message translates to:
  /// **'Simulate a missed dose alert'**
  String get familySimulateAMissedDoseAlert;

  /// No description provided for @familyJoinAsCaregiver.
  ///
  /// In en, this message translates to:
  /// **'Join as Caregiver'**
  String get familyJoinAsCaregiver;

  /// No description provided for @familyScanTheQrCodeOrEnter.
  ///
  /// In en, this message translates to:
  /// **'Scan the QR code or enter the invite code to start monitoring.'**
  String get familyScanTheQrCodeOrEnter;

  /// No description provided for @familyOrEnterCode.
  ///
  /// In en, this message translates to:
  /// **'OR ENTER CODE'**
  String get familyOrEnterCode;

  /// No description provided for @familyClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get familyClose;

  /// No description provided for @familyQrCodeScanner.
  ///
  /// In en, this message translates to:
  /// **'QR code scanner'**
  String get familyQrCodeScanner;

  /// No description provided for @familyInviteCode.
  ///
  /// In en, this message translates to:
  /// **'Invite code'**
  String get familyInviteCode;

  /// No description provided for @familyVerifyAndJoin.
  ///
  /// In en, this message translates to:
  /// **'Verify and Join'**
  String get familyVerifyAndJoin;

  /// No description provided for @familyWeeklyAdherence.
  ///
  /// In en, this message translates to:
  /// **'Weekly Adherence'**
  String get familyWeeklyAdherence;

  /// No description provided for @familyLast7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 Days'**
  String get familyLast7Days;

  /// No description provided for @familyProFeature.
  ///
  /// In en, this message translates to:
  /// **'Pro feature'**
  String get familyProFeature;

  /// No description provided for @familyRemoteMonitoringRequiresAProSubscription.
  ///
  /// In en, this message translates to:
  /// **'Remote monitoring requires a Pro subscription.'**
  String get familyRemoteMonitoringRequiresAProSubscription;

  /// No description provided for @familyUpgradeToPro.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Pro'**
  String get familyUpgradeToPro;

  /// No description provided for @focusFocusMode.
  ///
  /// In en, this message translates to:
  /// **'Focus mode'**
  String get focusFocusMode;

  /// No description provided for @focusStartFocus.
  ///
  /// In en, this message translates to:
  /// **'Start focus'**
  String get focusStartFocus;

  /// No description provided for @homeAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Afternoon'**
  String get homeAfternoon;

  /// No description provided for @homeNight.
  ///
  /// In en, this message translates to:
  /// **'Night'**
  String get homeNight;

  /// No description provided for @homeLogDose.
  ///
  /// In en, this message translates to:
  /// **'Log Dose'**
  String get homeLogDose;

  /// No description provided for @homeLogDoseWithAi.
  ///
  /// In en, this message translates to:
  /// **'Log dose with AI'**
  String get homeLogDoseWithAi;

  /// No description provided for @homeCompleteYourProfile.
  ///
  /// In en, this message translates to:
  /// **'Complete Your Profile'**
  String get homeCompleteYourProfile;

  /// No description provided for @homeUnlockMorePersonalisedInsights.
  ///
  /// In en, this message translates to:
  /// **'Unlock more personalised insights'**
  String get homeUnlockMorePersonalisedInsights;

  /// No description provided for @homeHowOldAreYou.
  ///
  /// In en, this message translates to:
  /// **'How old are you?'**
  String get homeHowOldAreYou;

  /// No description provided for @homeAddYourAge.
  ///
  /// In en, this message translates to:
  /// **'Add your age'**
  String get homeAddYourAge;

  /// No description provided for @homeSetYourGender.
  ///
  /// In en, this message translates to:
  /// **'Set your gender'**
  String get homeSetYourGender;

  /// No description provided for @homeWhenDoYouForget.
  ///
  /// In en, this message translates to:
  /// **'When do you forget?'**
  String get homeWhenDoYouForget;

  /// No description provided for @homeDoctorVisits.
  ///
  /// In en, this message translates to:
  /// **'Doctor visits'**
  String get homeDoctorVisits;

  /// No description provided for @homeWhatMotivatesYou.
  ///
  /// In en, this message translates to:
  /// **'What motivates you?'**
  String get homeWhatMotivatesYou;

  /// No description provided for @homeSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get homeSave;

  /// No description provided for @homeSaveSelection.
  ///
  /// In en, this message translates to:
  /// **'Save selection'**
  String get homeSaveSelection;

  /// No description provided for @homeYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get homeYesterday;

  /// No description provided for @homeCriticalMedicalAdvisory.
  ///
  /// In en, this message translates to:
  /// **'CRITICAL MEDICAL ADVISORY'**
  String get homeCriticalMedicalAdvisory;

  /// No description provided for @homeCallEmergencyServices911.
  ///
  /// In en, this message translates to:
  /// **'CALL EMERGENCY SERVICES (911)'**
  String get homeCallEmergencyServices911;

  /// No description provided for @homeBreatheRelaxAndCenterYourself.
  ///
  /// In en, this message translates to:
  /// **'Breathe, relax, and center yourself.'**
  String get homeBreatheRelaxAndCenterYourself;

  /// No description provided for @homeFocusModeBreatheRelaxAndCenter.
  ///
  /// In en, this message translates to:
  /// **'Focus mode. Breathe, relax, and center yourself.'**
  String get homeFocusModeBreatheRelaxAndCenter;

  /// No description provided for @homeDoseLogged.
  ///
  /// In en, this message translates to:
  /// **'Dose logged'**
  String get homeDoseLogged;

  /// No description provided for @homeOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get homeOpenSettings;

  /// No description provided for @homeMadeForYou.
  ///
  /// In en, this message translates to:
  /// **'MADE FOR YOU'**
  String get homeMadeForYou;

  /// No description provided for @homeCoaching.
  ///
  /// In en, this message translates to:
  /// **'Coaching'**
  String get homeCoaching;

  /// No description provided for @homeMedaiCompanion.
  ///
  /// In en, this message translates to:
  /// **'MedAI companion'**
  String get homeMedaiCompanion;

  /// No description provided for @homeLive.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get homeLive;

  /// No description provided for @homeMascotShop.
  ///
  /// In en, this message translates to:
  /// **'Mascot shop'**
  String get homeMascotShop;

  /// No description provided for @homeMedaiCompanionTapForANew.
  ///
  /// In en, this message translates to:
  /// **'MedAI companion. Tap for a new coaching message.'**
  String get homeMedaiCompanionTapForANew;

  /// No description provided for @homeRecentlyUploaded.
  ///
  /// In en, this message translates to:
  /// **'Recently uploaded'**
  String get homeRecentlyUploaded;

  /// No description provided for @homeNoMedications.
  ///
  /// In en, this message translates to:
  /// **'No medications'**
  String get homeNoMedications;

  /// No description provided for @homeScanAMedicine.
  ///
  /// In en, this message translates to:
  /// **'Scan a medicine'**
  String get homeScanAMedicine;

  /// No description provided for @homeOrEnterItManually.
  ///
  /// In en, this message translates to:
  /// **'Or enter it manually'**
  String get homeOrEnterItManually;

  /// No description provided for @homeDailyProgress.
  ///
  /// In en, this message translates to:
  /// **'Daily Progress'**
  String get homeDailyProgress;

  /// No description provided for @homeMood.
  ///
  /// In en, this message translates to:
  /// **'Mood'**
  String get homeMood;

  /// No description provided for @homePreviousWeek.
  ///
  /// In en, this message translates to:
  /// **'Previous week'**
  String get homePreviousWeek;

  /// No description provided for @homeNextWeek.
  ///
  /// In en, this message translates to:
  /// **'Next week'**
  String get homeNextWeek;

  /// No description provided for @homeBodyImpact.
  ///
  /// In en, this message translates to:
  /// **'Body Impact 🧬'**
  String get homeBodyImpact;

  /// No description provided for @homeVisualizeMedicationAbsorption.
  ///
  /// In en, this message translates to:
  /// **'Visualize medication absorption 🚀'**
  String get homeVisualizeMedicationAbsorption;

  /// No description provided for @homeBodyImpactVisualizerVisualizeMedicationAbsorption.
  ///
  /// In en, this message translates to:
  /// **'Body impact visualizer. Visualize medication absorption.'**
  String get homeBodyImpactVisualizerVisualizeMedicationAbsorption;

  /// No description provided for @homeWarning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get homeWarning;

  /// No description provided for @homeInteraction.
  ///
  /// In en, this message translates to:
  /// **'Interaction'**
  String get homeInteraction;

  /// No description provided for @homeHowToTake.
  ///
  /// In en, this message translates to:
  /// **'How to take'**
  String get homeHowToTake;

  /// No description provided for @homeImportant.
  ///
  /// In en, this message translates to:
  /// **'Important'**
  String get homeImportant;

  /// No description provided for @homeRefill.
  ///
  /// In en, this message translates to:
  /// **'Refill'**
  String get homeRefill;

  /// No description provided for @homeOnTrack.
  ///
  /// In en, this message translates to:
  /// **'On track'**
  String get homeOnTrack;

  /// No description provided for @homeBodyImpact2.
  ///
  /// In en, this message translates to:
  /// **'Body impact'**
  String get homeBodyImpact2;

  /// No description provided for @homeAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get homeAdd;

  /// No description provided for @homeAddFamilyProfile.
  ///
  /// In en, this message translates to:
  /// **'Add family profile'**
  String get homeAddFamilyProfile;

  /// No description provided for @homeShortTermCourse.
  ///
  /// In en, this message translates to:
  /// **'Short-term course'**
  String get homeShortTermCourse;

  /// No description provided for @homeRecoveryModeActive.
  ///
  /// In en, this message translates to:
  /// **'Recovery mode active'**
  String get homeRecoveryModeActive;

  /// No description provided for @homeEnjoyingMedai.
  ///
  /// In en, this message translates to:
  /// **'Enjoying MedAI?'**
  String get homeEnjoyingMedai;

  /// No description provided for @homeYourFeedbackHelpsUsImproveFor.
  ///
  /// In en, this message translates to:
  /// **'Your feedback helps us improve for everyone.'**
  String get homeYourFeedbackHelpsUsImproveFor;

  /// No description provided for @homeNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get homeNotifications;

  /// No description provided for @homeDoseReminders.
  ///
  /// In en, this message translates to:
  /// **'Dose Reminders'**
  String get homeDoseReminders;

  /// No description provided for @homeReminderSound.
  ///
  /// In en, this message translates to:
  /// **'Reminder Sound'**
  String get homeReminderSound;

  /// No description provided for @homeHaptics.
  ///
  /// In en, this message translates to:
  /// **'Haptics'**
  String get homeHaptics;

  /// No description provided for @homePersistentAlarms.
  ///
  /// In en, this message translates to:
  /// **'Persistent Alarms'**
  String get homePersistentAlarms;

  /// No description provided for @homeRefillAlerts.
  ///
  /// In en, this message translates to:
  /// **'Refill Alerts'**
  String get homeRefillAlerts;

  /// No description provided for @homeReminderTiming.
  ///
  /// In en, this message translates to:
  /// **'Reminder Timing'**
  String get homeReminderTiming;

  /// No description provided for @homeCaregiverProfiles.
  ///
  /// In en, this message translates to:
  /// **'Caregiver & Profiles'**
  String get homeCaregiverProfiles;

  /// No description provided for @homeFamilyDependents.
  ///
  /// In en, this message translates to:
  /// **'Family & Dependents'**
  String get homeFamilyDependents;

  /// No description provided for @homeAestheticsTheme.
  ///
  /// In en, this message translates to:
  /// **'Aesthetics & Theme'**
  String get homeAestheticsTheme;

  /// No description provided for @homeAppAppearance.
  ///
  /// In en, this message translates to:
  /// **'App Appearance'**
  String get homeAppAppearance;

  /// No description provided for @homeHealthWellness.
  ///
  /// In en, this message translates to:
  /// **'Health & Wellness'**
  String get homeHealthWellness;

  /// No description provided for @homeHealthDataAccess.
  ///
  /// In en, this message translates to:
  /// **'Health Data Access'**
  String get homeHealthDataAccess;

  /// No description provided for @homeSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get homeSecurity;

  /// No description provided for @homeBiometricLock.
  ///
  /// In en, this message translates to:
  /// **'Biometric Lock'**
  String get homeBiometricLock;

  /// No description provided for @homeSupportFeedback.
  ///
  /// In en, this message translates to:
  /// **'Support & Feedback'**
  String get homeSupportFeedback;

  /// No description provided for @homeInviteFriendsGiveAFreeMonth.
  ///
  /// In en, this message translates to:
  /// **'Invite friends — give a free month'**
  String get homeInviteFriendsGiveAFreeMonth;

  /// No description provided for @homeAppInfo.
  ///
  /// In en, this message translates to:
  /// **'App Info'**
  String get homeAppInfo;

  /// No description provided for @homePrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get homePrivacy;

  /// No description provided for @homeDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get homeDeleteAccount;

  /// No description provided for @homeYourData.
  ///
  /// In en, this message translates to:
  /// **'Your data'**
  String get homeYourData;

  /// No description provided for @homeYourSuccessPlan.
  ///
  /// In en, this message translates to:
  /// **'Your success plan'**
  String get homeYourSuccessPlan;

  /// No description provided for @homeUnlockAiInsightsFamilyCareUnlimited.
  ///
  /// In en, this message translates to:
  /// **'Unlock AI insights, family care & unlimited scans.'**
  String get homeUnlockAiInsightsFamilyCareUnlimited;

  /// No description provided for @homePro.
  ///
  /// In en, this message translates to:
  /// **'PRO'**
  String get homePro;

  /// No description provided for @homeMedai1001.
  ///
  /// In en, this message translates to:
  /// **'MedAI 1.0.0+1'**
  String get homeMedai1001;

  /// No description provided for @homeMadeByTheMedaiTeam.
  ///
  /// In en, this message translates to:
  /// **'Made by the MedAI team'**
  String get homeMadeByTheMedaiTeam;

  /// No description provided for @homeUpgradeToMedaiPro.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to MedAI Pro'**
  String get homeUpgradeToMedaiPro;

  /// No description provided for @homeName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get homeName;

  /// No description provided for @homeAge.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get homeAge;

  /// No description provided for @homeGender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get homeGender;

  /// No description provided for @homePrimaryGoal.
  ///
  /// In en, this message translates to:
  /// **'Primary Goal'**
  String get homePrimaryGoal;

  /// No description provided for @homeYourInfo.
  ///
  /// In en, this message translates to:
  /// **'Your Info'**
  String get homeYourInfo;

  /// No description provided for @homeHealthGoal.
  ///
  /// In en, this message translates to:
  /// **'Health Goal'**
  String get homeHealthGoal;

  /// No description provided for @homeConditions.
  ///
  /// In en, this message translates to:
  /// **'Conditions'**
  String get homeConditions;

  /// No description provided for @homeSubscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get homeSubscription;

  /// No description provided for @homeManageSubscription.
  ///
  /// In en, this message translates to:
  /// **'Manage Subscription'**
  String get homeManageSubscription;

  /// No description provided for @homeRestorePurchases.
  ///
  /// In en, this message translates to:
  /// **'Restore Purchases'**
  String get homeRestorePurchases;

  /// No description provided for @homeDataReports.
  ///
  /// In en, this message translates to:
  /// **'Data & Reports'**
  String get homeDataReports;

  /// No description provided for @homeClinicalPdfReport.
  ///
  /// In en, this message translates to:
  /// **'Clinical PDF Report'**
  String get homeClinicalPdfReport;

  /// No description provided for @homeMedWrapped2026.
  ///
  /// In en, this message translates to:
  /// **'Med Wrapped 2026'**
  String get homeMedWrapped2026;

  /// No description provided for @homeExportCsvData.
  ///
  /// In en, this message translates to:
  /// **'Export CSV Data'**
  String get homeExportCsvData;

  /// No description provided for @homeAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get homeAccount;

  /// No description provided for @homeSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get homeSignOut;

  /// No description provided for @homeSignInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get homeSignInWithGoogle;

  /// No description provided for @homeSignInWithApple.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Apple'**
  String get homeSignInWithApple;

  /// No description provided for @homeContactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get homeContactSupport;

  /// No description provided for @homeRateMedai.
  ///
  /// In en, this message translates to:
  /// **'Rate MedAI'**
  String get homeRateMedai;

  /// No description provided for @homeLegalPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Legal & Privacy'**
  String get homeLegalPrivacy;

  /// No description provided for @homeOpenSourceLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open Source Licenses'**
  String get homeOpenSourceLicenses;

  /// No description provided for @homeDeveloperOptions.
  ///
  /// In en, this message translates to:
  /// **'Developer Options'**
  String get homeDeveloperOptions;

  /// No description provided for @homeGrowthAnalyticsDashboard.
  ///
  /// In en, this message translates to:
  /// **'Growth & Analytics Dashboard'**
  String get homeGrowthAnalyticsDashboard;

  /// No description provided for @homeYourSuccessScore.
  ///
  /// In en, this message translates to:
  /// **'Your success score'**
  String get homeYourSuccessScore;

  /// No description provided for @homeSmartPatterns.
  ///
  /// In en, this message translates to:
  /// **'Smart patterns'**
  String get homeSmartPatterns;

  /// No description provided for @homeLeft.
  ///
  /// In en, this message translates to:
  /// **'left'**
  String get homeLeft;

  /// No description provided for @homePrecisionOverview.
  ///
  /// In en, this message translates to:
  /// **'Precision Overview'**
  String get homePrecisionOverview;

  /// No description provided for @homeDosesTaken.
  ///
  /// In en, this message translates to:
  /// **'Doses Taken'**
  String get homeDosesTaken;

  /// No description provided for @homeN7DayRate.
  ///
  /// In en, this message translates to:
  /// **'7-Day Rate'**
  String get homeN7DayRate;

  /// No description provided for @homeCurrentStreak.
  ///
  /// In en, this message translates to:
  /// **'Current Streak'**
  String get homeCurrentStreak;

  /// No description provided for @homeThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get homeThisWeek;

  /// No description provided for @homeHealthStory.
  ///
  /// In en, this message translates to:
  /// **'Health Story'**
  String get homeHealthStory;

  /// No description provided for @homeNoSymptomsRecorded.
  ///
  /// In en, this message translates to:
  /// **'No symptoms recorded'**
  String get homeNoSymptomsRecorded;

  /// No description provided for @homeInventoryForecast.
  ///
  /// In en, this message translates to:
  /// **'Inventory Forecast'**
  String get homeInventoryForecast;

  /// No description provided for @homeNoMedicationsTracked.
  ///
  /// In en, this message translates to:
  /// **'No medications tracked'**
  String get homeNoMedicationsTracked;

  /// No description provided for @homeMadeForYouManageWithConfidence.
  ///
  /// In en, this message translates to:
  /// **'Made for you — manage with confidence'**
  String get homeMadeForYouManageWithConfidence;

  /// No description provided for @homeYourSuccessSettingsRemindersSafetyAnd.
  ///
  /// In en, this message translates to:
  /// **'Your success settings — reminders, safety, and share.'**
  String get homeYourSuccessSettingsRemindersSafetyAnd;

  /// No description provided for @homeCloseSettings.
  ///
  /// In en, this message translates to:
  /// **'Close settings'**
  String get homeCloseSettings;

  /// No description provided for @homeYourStreak.
  ///
  /// In en, this message translates to:
  /// **'Your streak'**
  String get homeYourStreak;

  /// No description provided for @homeDays.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get homeDays;

  /// No description provided for @homeBest.
  ///
  /// In en, this message translates to:
  /// **'Best'**
  String get homeBest;

  /// No description provided for @homeTotalLogged.
  ///
  /// In en, this message translates to:
  /// **'Total logged'**
  String get homeTotalLogged;

  /// No description provided for @homeShareStreak.
  ///
  /// In en, this message translates to:
  /// **'Share streak'**
  String get homeShareStreak;

  /// No description provided for @homeGoPro.
  ///
  /// In en, this message translates to:
  /// **'Go Pro'**
  String get homeGoPro;

  /// No description provided for @homeUnlockUnlimitedScansInteractionChecksAnd.
  ///
  /// In en, this message translates to:
  /// **'Unlock unlimited scans, interaction checks, and more with Pro.'**
  String get homeUnlockUnlimitedScansInteractionChecksAnd;

  /// No description provided for @homeCloseVoiceAssistant.
  ///
  /// In en, this message translates to:
  /// **'Close voice assistant'**
  String get homeCloseVoiceAssistant;

  /// No description provided for @loadingPreparingYourHealthWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Preparing your health workspace'**
  String get loadingPreparingYourHealthWorkspace;

  /// No description provided for @medicineAddMedicine.
  ///
  /// In en, this message translates to:
  /// **'Add medicine'**
  String get medicineAddMedicine;

  /// No description provided for @medicineWhatAreYouTaking.
  ///
  /// In en, this message translates to:
  /// **'What are you taking?'**
  String get medicineWhatAreYouTaking;

  /// No description provided for @medicineSearchOrTypeTheMedicineName.
  ///
  /// In en, this message translates to:
  /// **'Search or type the medicine name to get started.'**
  String get medicineSearchOrTypeTheMedicineName;

  /// No description provided for @medicineWhenDoYouTakeThis.
  ///
  /// In en, this message translates to:
  /// **'When do you take this?'**
  String get medicineWhenDoYouTakeThis;

  /// No description provided for @medicineRemindMe.
  ///
  /// In en, this message translates to:
  /// **'Remind me'**
  String get medicineRemindMe;

  /// No description provided for @medicineGetANotificationWhenItS.
  ///
  /// In en, this message translates to:
  /// **'Get a notification when it’s time'**
  String get medicineGetANotificationWhenItS;

  /// No description provided for @medicineMedicationName.
  ///
  /// In en, this message translates to:
  /// **'Medication name'**
  String get medicineMedicationName;

  /// No description provided for @medicineEGLisinopril.
  ///
  /// In en, this message translates to:
  /// **'e.g. Lisinopril'**
  String get medicineEGLisinopril;

  /// No description provided for @medicineAddMedication.
  ///
  /// In en, this message translates to:
  /// **'Add medication'**
  String get medicineAddMedication;

  /// No description provided for @medicineCompleteTheFullCourse.
  ///
  /// In en, this message translates to:
  /// **'Complete the full course'**
  String get medicineCompleteTheFullCourse;

  /// No description provided for @medicineThisAntibioticMustBeFinishedEntirely.
  ///
  /// In en, this message translates to:
  /// **'This antibiotic must be finished entirely. Do not stop early, even if symptoms improve — unfinished courses can drive resistance.'**
  String get medicineThisAntibioticMustBeFinishedEntirely;

  /// No description provided for @medicineStockLevel.
  ///
  /// In en, this message translates to:
  /// **'Stock level'**
  String get medicineStockLevel;

  /// No description provided for @medicineRestock.
  ///
  /// In en, this message translates to:
  /// **'Restock'**
  String get medicineRestock;

  /// No description provided for @medicineUnits.
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get medicineUnits;

  /// No description provided for @medicineActiveDays.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE DAYS'**
  String get medicineActiveDays;

  /// No description provided for @medicineMealRitual.
  ///
  /// In en, this message translates to:
  /// **'MEAL RITUAL'**
  String get medicineMealRitual;

  /// No description provided for @medicineN28DayActivityLog.
  ///
  /// In en, this message translates to:
  /// **'28 DAY ACTIVITY LOG'**
  String get medicineN28DayActivityLog;

  /// No description provided for @medicineMissed.
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get medicineMissed;

  /// No description provided for @medicineTaken.
  ///
  /// In en, this message translates to:
  /// **'Taken'**
  String get medicineTaken;

  /// No description provided for @medicineAccentColor.
  ///
  /// In en, this message translates to:
  /// **'ACCENT COLOR'**
  String get medicineAccentColor;

  /// No description provided for @medicineCategory.
  ///
  /// In en, this message translates to:
  /// **'CATEGORY'**
  String get medicineCategory;

  /// No description provided for @medicineLogging.
  ///
  /// In en, this message translates to:
  /// **'Logging...'**
  String get medicineLogging;

  /// No description provided for @medicineLogged.
  ///
  /// In en, this message translates to:
  /// **'Logged!'**
  String get medicineLogged;

  /// No description provided for @medicineEditMedicine.
  ///
  /// In en, this message translates to:
  /// **'Edit medicine'**
  String get medicineEditMedicine;

  /// No description provided for @medicineCancelEditing.
  ///
  /// In en, this message translates to:
  /// **'Cancel editing'**
  String get medicineCancelEditing;

  /// No description provided for @medicineViewFullAiAnalysis.
  ///
  /// In en, this message translates to:
  /// **'View Full AI Analysis'**
  String get medicineViewFullAiAnalysis;

  /// No description provided for @medicineRestockInventory.
  ///
  /// In en, this message translates to:
  /// **'Restock inventory'**
  String get medicineRestockInventory;

  /// No description provided for @medicineConfirmRestock.
  ///
  /// In en, this message translates to:
  /// **'Confirm restock'**
  String get medicineConfirmRestock;

  /// No description provided for @medicineAddSlot.
  ///
  /// In en, this message translates to:
  /// **'Add slot'**
  String get medicineAddSlot;

  /// No description provided for @medicineEditReminder.
  ///
  /// In en, this message translates to:
  /// **'Edit Reminder'**
  String get medicineEditReminder;

  /// No description provided for @medicineHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get medicineHistory;

  /// No description provided for @medicineScore.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get medicineScore;

  /// No description provided for @medicineForm.
  ///
  /// In en, this message translates to:
  /// **'Form'**
  String get medicineForm;

  /// No description provided for @medicineUnit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get medicineUnit;

  /// No description provided for @medicineStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get medicineStart;

  /// No description provided for @medicineSpecifications.
  ///
  /// In en, this message translates to:
  /// **'Specifications'**
  String get medicineSpecifications;

  /// No description provided for @medicineQuickRefill10.
  ///
  /// In en, this message translates to:
  /// **'Quick refill (+10)'**
  String get medicineQuickRefill10;

  /// No description provided for @medicineRemoveMedicine.
  ///
  /// In en, this message translates to:
  /// **'Remove medicine'**
  String get medicineRemoveMedicine;

  /// No description provided for @medicineVisuals.
  ///
  /// In en, this message translates to:
  /// **'Visuals'**
  String get medicineVisuals;

  /// No description provided for @medicineIdentity.
  ///
  /// In en, this message translates to:
  /// **'Identity'**
  String get medicineIdentity;

  /// No description provided for @medicineMedicineName.
  ///
  /// In en, this message translates to:
  /// **'Medicine Name'**
  String get medicineMedicineName;

  /// No description provided for @medicineBrandName.
  ///
  /// In en, this message translates to:
  /// **'Brand Name'**
  String get medicineBrandName;

  /// No description provided for @medicineConfiguration.
  ///
  /// In en, this message translates to:
  /// **'Configuration'**
  String get medicineConfiguration;

  /// No description provided for @medicineDosage.
  ///
  /// In en, this message translates to:
  /// **'Dosage'**
  String get medicineDosage;

  /// No description provided for @medicineIntakeInstructions.
  ///
  /// In en, this message translates to:
  /// **'Intake Instructions'**
  String get medicineIntakeInstructions;

  /// No description provided for @medicineInventoryRefills.
  ///
  /// In en, this message translates to:
  /// **'Inventory & refills'**
  String get medicineInventoryRefills;

  /// No description provided for @medicineCurrentCount.
  ///
  /// In en, this message translates to:
  /// **'Current Count'**
  String get medicineCurrentCount;

  /// No description provided for @medicineTotalBoxCount.
  ///
  /// In en, this message translates to:
  /// **'Total Box Count'**
  String get medicineTotalBoxCount;

  /// No description provided for @medicineRefillAlertAt.
  ///
  /// In en, this message translates to:
  /// **'Refill Alert At'**
  String get medicineRefillAlertAt;

  /// No description provided for @medicinePharmacyDetails.
  ///
  /// In en, this message translates to:
  /// **'Pharmacy details'**
  String get medicinePharmacyDetails;

  /// No description provided for @medicinePharmacyName.
  ///
  /// In en, this message translates to:
  /// **'Pharmacy Name'**
  String get medicinePharmacyName;

  /// No description provided for @medicinePrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get medicinePrice;

  /// No description provided for @medicineSaveReminder.
  ///
  /// In en, this message translates to:
  /// **'Save reminder'**
  String get medicineSaveReminder;

  /// No description provided for @medicineNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get medicineNone;

  /// No description provided for @medicineDidYouKnow.
  ///
  /// In en, this message translates to:
  /// **'Did you know?'**
  String get medicineDidYouKnow;

  /// No description provided for @medicineAskAiAssistantAboutThis.
  ///
  /// In en, this message translates to:
  /// **'Ask AI Assistant About This'**
  String get medicineAskAiAssistantAboutThis;

  /// No description provided for @medicineCourseCompleted.
  ///
  /// In en, this message translates to:
  /// **'Course Completed!'**
  String get medicineCourseCompleted;

  /// No description provided for @medicineAchievementUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Achievement Unlocked'**
  String get medicineAchievementUnlocked;

  /// No description provided for @medicineN100AdherenceForThisCourse.
  ///
  /// In en, this message translates to:
  /// **'100% Adherence for this course'**
  String get medicineN100AdherenceForThisCourse;

  /// No description provided for @medicineArchiveFinish.
  ///
  /// In en, this message translates to:
  /// **'ARCHIVE & FINISH'**
  String get medicineArchiveFinish;

  /// No description provided for @medicineMedaiCoach.
  ///
  /// In en, this message translates to:
  /// **'MedAI Coach'**
  String get medicineMedaiCoach;

  /// No description provided for @medicineMechanismSpecs.
  ///
  /// In en, this message translates to:
  /// **'Mechanism & Specs'**
  String get medicineMechanismSpecs;

  /// No description provided for @medicineAskAQuestion.
  ///
  /// In en, this message translates to:
  /// **'Ask a question…'**
  String get medicineAskAQuestion;

  /// No description provided for @medicineWaitInteractionAlert.
  ///
  /// In en, this message translates to:
  /// **'Wait! Interaction Alert'**
  String get medicineWaitInteractionAlert;

  /// No description provided for @medicineGotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get medicineGotIt;

  /// No description provided for @medicineAdjustTime.
  ///
  /// In en, this message translates to:
  /// **'Adjust Time'**
  String get medicineAdjustTime;

  /// No description provided for @medicineNoSpecialSafetyAlertsFoundFor.
  ///
  /// In en, this message translates to:
  /// **'No special safety alerts found for this medication.'**
  String get medicineNoSpecialSafetyAlertsFoundFor;

  /// No description provided for @medicineAlert.
  ///
  /// In en, this message translates to:
  /// **'Alert'**
  String get medicineAlert;

  /// No description provided for @onboardingDedicatedCaregiver.
  ///
  /// In en, this message translates to:
  /// **'Dedicated Caregiver'**
  String get onboardingDedicatedCaregiver;

  /// No description provided for @onboardingFamilyHealthLead.
  ///
  /// In en, this message translates to:
  /// **'Family Health Lead'**
  String get onboardingFamilyHealthLead;

  /// No description provided for @onboardingHealthFocusedSenior.
  ///
  /// In en, this message translates to:
  /// **'Health-Focused Senior'**
  String get onboardingHealthFocusedSenior;

  /// No description provided for @onboardingSelfManager.
  ///
  /// In en, this message translates to:
  /// **'Self-Manager'**
  String get onboardingSelfManager;

  /// No description provided for @onboardingSmartRemindersNotSetUpYet.
  ///
  /// In en, this message translates to:
  /// **'Smart reminders not set up yet'**
  String get onboardingSmartRemindersNotSetUpYet;

  /// No description provided for @onboardingYou.
  ///
  /// In en, this message translates to:
  /// **'YOU\\'**
  String get onboardingYou;

  /// No description provided for @onboardingManageMyFamilySMeds.
  ///
  /// In en, this message translates to:
  /// **'Manage my family\'s meds'**
  String get onboardingManageMyFamilySMeds;

  /// No description provided for @onboardingKnowItTrustItSucceedWith.
  ///
  /// In en, this message translates to:
  /// **'Know it. *Trust it.* Succeed with it.'**
  String get onboardingKnowItTrustItSucceedWith;

  /// No description provided for @onboardingWhatSYourGender.
  ///
  /// In en, this message translates to:
  /// **'What\'s your *gender*?'**
  String get onboardingWhatSYourGender;

  /// No description provided for @onboardingYouReInTheRightPlace.
  ///
  /// In en, this message translates to:
  /// **'You\'re in the *right place*'**
  String get onboardingYouReInTheRightPlace;

  /// No description provided for @onboardingWhatSYourBiggestChallenge.
  ///
  /// In en, this message translates to:
  /// **'What\'s your biggest *challenge*?'**
  String get onboardingWhatSYourBiggestChallenge;

  /// No description provided for @onboardingYouReNotAlone.
  ///
  /// In en, this message translates to:
  /// **'You\'re *not alone*'**
  String get onboardingYouReNotAlone;

  /// No description provided for @onboardingIWorryILlForgetAn.
  ///
  /// In en, this message translates to:
  /// **'I worry I\'ll *forget* an important dose'**
  String get onboardingIWorryILlForgetAn;

  /// No description provided for @onboardingDoYouKnowExactlyWhatS.
  ///
  /// In en, this message translates to:
  /// **'Do you know exactly *what\'s in* every pill you take?'**
  String get onboardingDoYouKnowExactlyWhatS;

  /// No description provided for @onboardingKnowWhatSWrongWithYour.
  ///
  /// In en, this message translates to:
  /// **'Know what\'s *wrong* with your regimen'**
  String get onboardingKnowWhatSWrongWithYour;

  /// No description provided for @onboardingLetSUnderstandWhatDrivesYou.
  ///
  /// In en, this message translates to:
  /// **'Let\'s understand what *drives* you'**
  String get onboardingLetSUnderstandWhatDrivesYou;

  /// No description provided for @onboardingBeginMySuccess.
  ///
  /// In en, this message translates to:
  /// **'Begin my success'**
  String get onboardingBeginMySuccess;

  /// No description provided for @onboardingSlideTheRuler.
  ///
  /// In en, this message translates to:
  /// **'Slide the ruler'**
  String get onboardingSlideTheRuler;

  /// No description provided for @onboardingIUsuallyWakeUp.
  ///
  /// In en, this message translates to:
  /// **'I usually wake up'**
  String get onboardingIUsuallyWakeUp;

  /// No description provided for @onboardingIUsuallyGoToSleep.
  ///
  /// In en, this message translates to:
  /// **'I usually go to sleep'**
  String get onboardingIUsuallyGoToSleep;

  /// No description provided for @onboardingMedAiAssistant.
  ///
  /// In en, this message translates to:
  /// **'Med AI assistant'**
  String get onboardingMedAiAssistant;

  /// No description provided for @onboardingHoldToCommitToYourHealth.
  ///
  /// In en, this message translates to:
  /// **'Hold to commit to your health goal'**
  String get onboardingHoldToCommitToYourHealth;

  /// No description provided for @onboardingHoldToCommit.
  ///
  /// In en, this message translates to:
  /// **'Hold to commit'**
  String get onboardingHoldToCommit;

  /// No description provided for @onboardingHowMedAiHelpsYouNstay.
  ///
  /// In en, this message translates to:
  /// **'How Med AI helps you\\nstay on track'**
  String get onboardingHowMedAiHelpsYouNstay;

  /// No description provided for @onboardingThreeQuietMovesOneCalmRoutine.
  ///
  /// In en, this message translates to:
  /// **'Three quiet moves. One calm routine.'**
  String get onboardingThreeQuietMovesOneCalmRoutine;

  /// No description provided for @onboardingAtorvastatin20mg.
  ///
  /// In en, this message translates to:
  /// **'Atorvastatin 20mg'**
  String get onboardingAtorvastatin20mg;

  /// No description provided for @onboardingN94MatchIdentified.
  ///
  /// In en, this message translates to:
  /// **'94% match · Identified'**
  String get onboardingN94MatchIdentified;

  /// No description provided for @onboardingYourScore.
  ///
  /// In en, this message translates to:
  /// **'Your score'**
  String get onboardingYourScore;

  /// No description provided for @onboardingRemind.
  ///
  /// In en, this message translates to:
  /// **'Remind'**
  String get onboardingRemind;

  /// No description provided for @onboardingProtect.
  ///
  /// In en, this message translates to:
  /// **'Protect'**
  String get onboardingProtect;

  /// No description provided for @onboardingGoBack.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get onboardingGoBack;

  /// No description provided for @onboardingAdherenceBaseline.
  ///
  /// In en, this message translates to:
  /// **'Adherence baseline'**
  String get onboardingAdherenceBaseline;

  /// No description provided for @onboardingMemoryOnly.
  ///
  /// In en, this message translates to:
  /// **'Memory only'**
  String get onboardingMemoryOnly;

  /// No description provided for @onboardingMedAiPlan.
  ///
  /// In en, this message translates to:
  /// **'Med AI plan'**
  String get onboardingMedAiPlan;

  /// No description provided for @onboardingMedCount.
  ///
  /// In en, this message translates to:
  /// **'Med count'**
  String get onboardingMedCount;

  /// No description provided for @onboardingChallenge.
  ///
  /// In en, this message translates to:
  /// **'Challenge'**
  String get onboardingChallenge;

  /// No description provided for @onboardingYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get onboardingYes;

  /// No description provided for @onboardingMedAi.
  ///
  /// In en, this message translates to:
  /// **'Med AI'**
  String get onboardingMedAi;

  /// No description provided for @onboardingYour1Plan.
  ///
  /// In en, this message translates to:
  /// **'YOUR #1 PLAN'**
  String get onboardingYour1Plan;

  /// No description provided for @onboardingMedicationCompanion.
  ///
  /// In en, this message translates to:
  /// **'Medication companion'**
  String get onboardingMedicationCompanion;

  /// No description provided for @onboardingScanKnowNeverMissADose.
  ///
  /// In en, this message translates to:
  /// **'Scan. Know. Never miss a dose.'**
  String get onboardingScanKnowNeverMissADose;

  /// No description provided for @onboardingBuiltForPeopleManagingMoreThan.
  ///
  /// In en, this message translates to:
  /// **'Built for people managing more than one medicine'**
  String get onboardingBuiltForPeopleManagingMoreThan;

  /// No description provided for @onboardingFreeTrial.
  ///
  /// In en, this message translates to:
  /// **'FREE TRIAL'**
  String get onboardingFreeTrial;

  /// No description provided for @onboardingFullAccessCancelAnytime.
  ///
  /// In en, this message translates to:
  /// **'Full access. Cancel anytime.'**
  String get onboardingFullAccessCancelAnytime;

  /// No description provided for @onboardingOtherApps.
  ///
  /// In en, this message translates to:
  /// **'Other apps'**
  String get onboardingOtherApps;

  /// No description provided for @onboardingSkipOnboarding.
  ///
  /// In en, this message translates to:
  /// **'Skip onboarding'**
  String get onboardingSkipOnboarding;

  /// No description provided for @paywallWaitNotReadyForAYear.
  ///
  /// In en, this message translates to:
  /// **'Wait — not ready for a year? Try Med AI Pro by the week. Cancel anytime.'**
  String get paywallWaitNotReadyForAYear;

  /// No description provided for @paywallRemindMeBeforeTheTrialEnds.
  ///
  /// In en, this message translates to:
  /// **'Remind me before the trial ends'**
  String get paywallRemindMeBeforeTheTrialEnds;

  /// No description provided for @paywallMedAiPro.
  ///
  /// In en, this message translates to:
  /// **'Med AI Pro'**
  String get paywallMedAiPro;

  /// No description provided for @paywallFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get paywallFree;

  /// No description provided for @paywallCancelAnytimeYourHealthDataIs.
  ///
  /// In en, this message translates to:
  /// **'Cancel anytime · Your health data is never sold'**
  String get paywallCancelAnytimeYourHealthDataIs;

  /// No description provided for @paywallSubscriptionAutoRenewsUnlessCancelledAt.
  ///
  /// In en, this message translates to:
  /// **'Subscription auto-renews unless cancelled at least 24 hours before the end of the current period. '**
  String get paywallSubscriptionAutoRenewsUnlessCancelledAt;

  /// No description provided for @paywallUnlimitedAiScans.
  ///
  /// In en, this message translates to:
  /// **'Unlimited AI Scans'**
  String get paywallUnlimitedAiScans;

  /// No description provided for @paywallDoctorReportsPdf.
  ///
  /// In en, this message translates to:
  /// **'Doctor Reports (PDF)'**
  String get paywallDoctorReportsPdf;

  /// No description provided for @paywallUnlimitedMedications.
  ///
  /// In en, this message translates to:
  /// **'Unlimited Medications'**
  String get paywallUnlimitedMedications;

  /// No description provided for @paywallStreakFreezeProtection.
  ///
  /// In en, this message translates to:
  /// **'Streak Freeze Protection'**
  String get paywallStreakFreezeProtection;

  /// No description provided for @paywallPriorityBiometricLock.
  ///
  /// In en, this message translates to:
  /// **'Priority Biometric Lock'**
  String get paywallPriorityBiometricLock;

  /// No description provided for @paywallAiDrugInteractions.
  ///
  /// In en, this message translates to:
  /// **'AI Drug Interactions'**
  String get paywallAiDrugInteractions;

  /// No description provided for @paywallYourMedAiProTrialEnds.
  ///
  /// In en, this message translates to:
  /// **'Your Med AI Pro trial ends tomorrow'**
  String get paywallYourMedAiProTrialEnds;

  /// No description provided for @paywallMedAiProSubscription.
  ///
  /// In en, this message translates to:
  /// **'Med AI Pro subscription'**
  String get paywallMedAiProSubscription;

  /// No description provided for @paywallClosePaywall.
  ///
  /// In en, this message translates to:
  /// **'Close paywall'**
  String get paywallClosePaywall;

  /// No description provided for @paywallTermsOfUse.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get paywallTermsOfUse;

  /// No description provided for @scanConfidenceTarget.
  ///
  /// In en, this message translates to:
  /// **'Confidence Target'**
  String get scanConfidenceTarget;

  /// No description provided for @scanFaster.
  ///
  /// In en, this message translates to:
  /// **'Faster'**
  String get scanFaster;

  /// No description provided for @scanMoreAccurate.
  ///
  /// In en, this message translates to:
  /// **'More Accurate'**
  String get scanMoreAccurate;

  /// No description provided for @scanAiAccuracy.
  ///
  /// In en, this message translates to:
  /// **'AI Accuracy'**
  String get scanAiAccuracy;

  /// No description provided for @scanRecognitionThreshold.
  ///
  /// In en, this message translates to:
  /// **'Recognition Threshold'**
  String get scanRecognitionThreshold;

  /// No description provided for @scanProcessingModes.
  ///
  /// In en, this message translates to:
  /// **'Processing Modes'**
  String get scanProcessingModes;

  /// No description provided for @scanDeepSemanticAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Deep Semantic Analysis'**
  String get scanDeepSemanticAnalysis;

  /// No description provided for @scanAutoCropImages.
  ///
  /// In en, this message translates to:
  /// **'Auto-Crop Images'**
  String get scanAutoCropImages;

  /// No description provided for @scanClinicalMode.
  ///
  /// In en, this message translates to:
  /// **'Clinical Mode'**
  String get scanClinicalMode;

  /// No description provided for @scanPrivacyModeNoLogging.
  ///
  /// In en, this message translates to:
  /// **'Privacy Mode (No Logging)'**
  String get scanPrivacyModeNoLogging;

  /// No description provided for @scanCloseScanner.
  ///
  /// In en, this message translates to:
  /// **'Close scanner'**
  String get scanCloseScanner;

  /// No description provided for @scanCameraUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Camera Unavailable'**
  String get scanCameraUnavailable;

  /// No description provided for @scanPillIdentifier.
  ///
  /// In en, this message translates to:
  /// **'Pill Identifier'**
  String get scanPillIdentifier;

  /// No description provided for @scanShapeColorImprint.
  ///
  /// In en, this message translates to:
  /// **'Shape, color & imprint'**
  String get scanShapeColorImprint;

  /// No description provided for @scanShapeColorImprint2.
  ///
  /// In en, this message translates to:
  /// **'Shape · Color · Imprint'**
  String get scanShapeColorImprint2;

  /// No description provided for @scanTrackMedicine.
  ///
  /// In en, this message translates to:
  /// **'Track medicine'**
  String get scanTrackMedicine;

  /// No description provided for @scanScanAnother.
  ///
  /// In en, this message translates to:
  /// **'Scan another'**
  String get scanScanAnother;

  /// No description provided for @scanScanHistory.
  ///
  /// In en, this message translates to:
  /// **'Scan History'**
  String get scanScanHistory;

  /// No description provided for @scanNoHistoryYet.
  ///
  /// In en, this message translates to:
  /// **'No history yet'**
  String get scanNoHistoryYet;

  /// No description provided for @scanScanningTips.
  ///
  /// In en, this message translates to:
  /// **'Scanning Tips'**
  String get scanScanningTips;

  /// No description provided for @scanGoodLightingIsKey.
  ///
  /// In en, this message translates to:
  /// **'Good Lighting is Key'**
  String get scanGoodLightingIsKey;

  /// No description provided for @scanKeepItCentered.
  ///
  /// In en, this message translates to:
  /// **'Keep it Centered'**
  String get scanKeepItCentered;

  /// No description provided for @scanScanTheNdcOrBarcode.
  ///
  /// In en, this message translates to:
  /// **'Scan the NDC or Barcode'**
  String get scanScanTheNdcOrBarcode;

  /// No description provided for @scanTryVoiceMode.
  ///
  /// In en, this message translates to:
  /// **'Try Voice Mode'**
  String get scanTryVoiceMode;

  /// No description provided for @scanCanTFindItAddManually.
  ///
  /// In en, this message translates to:
  /// **'Can\'t find it? Add manually'**
  String get scanCanTFindItAddManually;

  /// No description provided for @scanScanner.
  ///
  /// In en, this message translates to:
  /// **'Scanner'**
  String get scanScanner;

  /// No description provided for @scanAiMedicineRecognition.
  ///
  /// In en, this message translates to:
  /// **'AI medicine recognition'**
  String get scanAiMedicineRecognition;

  /// No description provided for @scanManuallySearchForAnyMedicineOr.
  ///
  /// In en, this message translates to:
  /// **'Manually search for any medicine or supplement.'**
  String get scanManuallySearchForAnyMedicineOr;

  /// No description provided for @scanScannerOptions.
  ///
  /// In en, this message translates to:
  /// **'Scanner Options'**
  String get scanScannerOptions;

  /// No description provided for @scanScanMeds.
  ///
  /// In en, this message translates to:
  /// **'Scan Meds'**
  String get scanScanMeds;

  /// No description provided for @scanBarcode.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get scanBarcode;

  /// No description provided for @scanVoice.
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get scanVoice;

  /// No description provided for @scanChooseFromLibrary.
  ///
  /// In en, this message translates to:
  /// **'Choose from library'**
  String get scanChooseFromLibrary;

  /// No description provided for @scanMetforminVitaminC.
  ///
  /// In en, this message translates to:
  /// **'Metformin, Vitamin C...'**
  String get scanMetforminVitaminC;

  /// No description provided for @scanSearchMedication.
  ///
  /// In en, this message translates to:
  /// **'Search medication'**
  String get scanSearchMedication;

  /// No description provided for @scanAiAccuracySettings.
  ///
  /// In en, this message translates to:
  /// **'AI Accuracy Settings'**
  String get scanAiAccuracySettings;

  /// No description provided for @scanHelpTips.
  ///
  /// In en, this message translates to:
  /// **'Help & Tips'**
  String get scanHelpTips;

  /// No description provided for @scanSynergyScanner.
  ///
  /// In en, this message translates to:
  /// **'Synergy scanner'**
  String get scanSynergyScanner;

  /// No description provided for @scanTryAStraightOnPhotoOf.
  ///
  /// In en, this message translates to:
  /// **'Try a straight-on photo of the label in good light, or scan another angle. You can still track it manually and fill in the details yourself.'**
  String get scanTryAStraightOnPhotoOf;

  /// No description provided for @scanDetailsBuiltForYouClearTrusted.
  ///
  /// In en, this message translates to:
  /// **'Details built for you — clear, trusted, and ready to track.'**
  String get scanDetailsBuiltForYouClearTrusted;

  /// No description provided for @scanCloseResults.
  ///
  /// In en, this message translates to:
  /// **'Close results'**
  String get scanCloseResults;

  /// No description provided for @scanScanConfidence.
  ///
  /// In en, this message translates to:
  /// **'Scan confidence'**
  String get scanScanConfidence;

  /// No description provided for @scanNotConfirmedYet.
  ///
  /// In en, this message translates to:
  /// **'Not confirmed yet'**
  String get scanNotConfirmedYet;

  /// No description provided for @scanImportantWarnings.
  ///
  /// In en, this message translates to:
  /// **'Important warnings'**
  String get scanImportantWarnings;

  /// No description provided for @scanPackCourse.
  ///
  /// In en, this message translates to:
  /// **'Pack & course'**
  String get scanPackCourse;

  /// No description provided for @scanAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get scanAbout;

  /// No description provided for @scanRegulatory.
  ///
  /// In en, this message translates to:
  /// **'Regulatory'**
  String get scanRegulatory;

  /// No description provided for @settingsResetCache.
  ///
  /// In en, this message translates to:
  /// **'Reset cache?'**
  String get settingsResetCache;

  /// No description provided for @settingsThisWillClearLocalTemporaryFiles.
  ///
  /// In en, this message translates to:
  /// **'This will clear local temporary files. Your medications and health records will remain safe.'**
  String get settingsThisWillClearLocalTemporaryFiles;

  /// No description provided for @settingsLocalization.
  ///
  /// In en, this message translates to:
  /// **'Localization'**
  String get settingsLocalization;

  /// No description provided for @settingsDiabetesMetrics.
  ///
  /// In en, this message translates to:
  /// **'Diabetes Metrics'**
  String get settingsDiabetesMetrics;

  /// No description provided for @settingsHypertensionTracking.
  ///
  /// In en, this message translates to:
  /// **'Hypertension Tracking'**
  String get settingsHypertensionTracking;

  /// No description provided for @settingsVitalConnectivity.
  ///
  /// In en, this message translates to:
  /// **'Vital connectivity'**
  String get settingsVitalConnectivity;

  /// No description provided for @settingsAutoSyncHealth.
  ///
  /// In en, this message translates to:
  /// **'Auto-Sync Health'**
  String get settingsAutoSyncHealth;

  /// No description provided for @settingsThisDevice.
  ///
  /// In en, this message translates to:
  /// **'This device'**
  String get settingsThisDevice;

  /// No description provided for @settingsClearLocalCache.
  ///
  /// In en, this message translates to:
  /// **'Clear Local Cache'**
  String get settingsClearLocalCache;

  /// No description provided for @settingsSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsSystem;

  /// No description provided for @settingsMedicalDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Medical Disclaimer'**
  String get settingsMedicalDisclaimer;

  /// No description provided for @settingsN1InformationWeCollect.
  ///
  /// In en, this message translates to:
  /// **'1. Information We Collect'**
  String get settingsN1InformationWeCollect;

  /// No description provided for @settingsN2AiScanProcessing.
  ///
  /// In en, this message translates to:
  /// **'2. AI & Scan Processing'**
  String get settingsN2AiScanProcessing;

  /// No description provided for @settingsN3FamilyCaregiverSharing.
  ///
  /// In en, this message translates to:
  /// **'3. Family & Caregiver Sharing'**
  String get settingsN3FamilyCaregiverSharing;

  /// No description provided for @settingsN4ThirdPartyServices.
  ///
  /// In en, this message translates to:
  /// **'4. Third-Party Services'**
  String get settingsN4ThirdPartyServices;

  /// No description provided for @settingsN5DataRetention.
  ///
  /// In en, this message translates to:
  /// **'5. Data Retention'**
  String get settingsN5DataRetention;

  /// No description provided for @settingsN6Security.
  ///
  /// In en, this message translates to:
  /// **'6. Security'**
  String get settingsN6Security;

  /// No description provided for @settingsN7YourRightsGdprCcpa.
  ///
  /// In en, this message translates to:
  /// **'7. Your Rights (GDPR / CCPA)'**
  String get settingsN7YourRightsGdprCcpa;

  /// No description provided for @settingsN8Children.
  ///
  /// In en, this message translates to:
  /// **'8. Children\\'**
  String get settingsN8Children;

  /// No description provided for @settingsN9YourDataYourControl.
  ///
  /// In en, this message translates to:
  /// **'9. Your Data, Your Control'**
  String get settingsN9YourDataYourControl;

  /// No description provided for @settingsN10ContactUpdates.
  ///
  /// In en, this message translates to:
  /// **'10. Contact & Updates'**
  String get settingsN10ContactUpdates;

  /// No description provided for @settingsViewFullPrivacyPolicyOnline.
  ///
  /// In en, this message translates to:
  /// **'View full privacy policy online'**
  String get settingsViewFullPrivacyPolicyOnline;

  /// No description provided for @settingsN1AcceptanceOfTerms.
  ///
  /// In en, this message translates to:
  /// **'1. Acceptance of Terms'**
  String get settingsN1AcceptanceOfTerms;

  /// No description provided for @settingsN2NotMedicalAdvice.
  ///
  /// In en, this message translates to:
  /// **'2. Not Medical Advice'**
  String get settingsN2NotMedicalAdvice;

  /// No description provided for @settingsN3UserAccounts.
  ///
  /// In en, this message translates to:
  /// **'3. User Accounts'**
  String get settingsN3UserAccounts;

  /// No description provided for @settingsN4AcceptableUse.
  ///
  /// In en, this message translates to:
  /// **'4. Acceptable Use'**
  String get settingsN4AcceptableUse;

  /// No description provided for @settingsN5PremiumSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'5. Premium Subscriptions'**
  String get settingsN5PremiumSubscriptions;

  /// No description provided for @settingsN6AppleHealthHealthConnect.
  ///
  /// In en, this message translates to:
  /// **'6. Apple Health & Health Connect'**
  String get settingsN6AppleHealthHealthConnect;

  /// No description provided for @settingsN7LimitationOfLiability.
  ///
  /// In en, this message translates to:
  /// **'7. Limitation of Liability'**
  String get settingsN7LimitationOfLiability;

  /// No description provided for @settingsN8ContactInformation.
  ///
  /// In en, this message translates to:
  /// **'8. Contact Information'**
  String get settingsN8ContactInformation;

  /// No description provided for @settingsViewFullTermsOnline.
  ///
  /// In en, this message translates to:
  /// **'View full terms online'**
  String get settingsViewFullTermsOnline;

  /// No description provided for @settingsMoreThemesComingSoon.
  ///
  /// In en, this message translates to:
  /// **'More themes coming soon!'**
  String get settingsMoreThemesComingSoon;

  /// No description provided for @settingsUnlockExclusiveAestheticsWithStreaks.
  ///
  /// In en, this message translates to:
  /// **'Unlock exclusive aesthetics with streaks.'**
  String get settingsUnlockExclusiveAestheticsWithStreaks;

  /// No description provided for @settingsAppIcons.
  ///
  /// In en, this message translates to:
  /// **'App Icons'**
  String get settingsAppIcons;

  /// No description provided for @settingsDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account?'**
  String get settingsDeleteAccount;

  /// No description provided for @settingsThisPermanentlyErasesYourMedicationHistory.
  ///
  /// In en, this message translates to:
  /// **'This permanently erases your medication history, schedules and health records from this device and our servers. It cannot be undone, and support cannot restore it.'**
  String get settingsThisPermanentlyErasesYourMedicationHistory;

  /// No description provided for @settingsKeepMyAccount.
  ///
  /// In en, this message translates to:
  /// **'Keep my account'**
  String get settingsKeepMyAccount;

  /// No description provided for @settingsDeleteForever.
  ///
  /// In en, this message translates to:
  /// **'Delete forever'**
  String get settingsDeleteForever;

  /// No description provided for @socialMedBuddies.
  ///
  /// In en, this message translates to:
  /// **'Med buddies'**
  String get socialMedBuddies;

  /// No description provided for @socialNoBuddiesConnectedYet.
  ///
  /// In en, this message translates to:
  /// **'No buddies connected yet'**
  String get socialNoBuddiesConnectedYet;

  /// No description provided for @socialYourArchetype.
  ///
  /// In en, this message translates to:
  /// **'YOUR ARCHETYPE'**
  String get socialYourArchetype;

  /// No description provided for @socialCalculatedBasedOnYourHistoricalDose.
  ///
  /// In en, this message translates to:
  /// **'Calculated based on your historical dose logging timestamp profiles.'**
  String get socialCalculatedBasedOnYourHistoricalDose;

  /// No description provided for @socialHabitArchitectureLocked.
  ///
  /// In en, this message translates to:
  /// **'Habit Architecture Locked.'**
  String get socialHabitArchitectureLocked;

  /// No description provided for @socialKeepSharingYourConsistencyYouInspire.
  ///
  /// In en, this message translates to:
  /// **'Keep sharing your consistency. You inspire others to optimize their routines.'**
  String get socialKeepSharingYourConsistencyYouInspire;

  /// No description provided for @socialTapLeftToGoBackRight.
  ///
  /// In en, this message translates to:
  /// **'Tap left to go back, right to go forward'**
  String get socialTapLeftToGoBackRight;

  /// No description provided for @socialYourYearInConsistencyQuantified.
  ///
  /// In en, this message translates to:
  /// **'Your year in consistency, quantified.'**
  String get socialYourYearInConsistencyQuantified;

  /// No description provided for @socialTotalDosesLoggedAndVerifiedBy.
  ///
  /// In en, this message translates to:
  /// **'Total doses logged and verified by AI.'**
  String get socialTotalDosesLoggedAndVerifiedBy;

  /// No description provided for @socialDayStreakWasYourMaximumMomentum.
  ///
  /// In en, this message translates to:
  /// **'Day streak was your maximum momentum.'**
  String get socialDayStreakWasYourMaximumMomentum;

  /// No description provided for @socialOverallAdherenceScoreThisYear.
  ///
  /// In en, this message translates to:
  /// **'Overall adherence score this year.'**
  String get socialOverallAdherenceScoreThisYear;

  /// No description provided for @socialShareWrapped.
  ///
  /// In en, this message translates to:
  /// **'Share Wrapped'**
  String get socialShareWrapped;

  /// No description provided for @statsWeeklyPerformance.
  ///
  /// In en, this message translates to:
  /// **'Weekly performance'**
  String get statsWeeklyPerformance;

  /// No description provided for @statsShareWithYourDoctor.
  ///
  /// In en, this message translates to:
  /// **'Share with your doctor'**
  String get statsShareWithYourDoctor;

  /// No description provided for @statsExportAClinicalPdfOfYour.
  ///
  /// In en, this message translates to:
  /// **'Export a clinical PDF of your adherence & meds'**
  String get statsExportAClinicalPdfOfYour;

  /// No description provided for @statsSymptoms.
  ///
  /// In en, this message translates to:
  /// **'Symptoms'**
  String get statsSymptoms;

  /// No description provided for @statsTrendAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Trend analysis'**
  String get statsTrendAnalysis;

  /// No description provided for @statsExplore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get statsExplore;

  /// No description provided for @statsStockLevelsRefillAlerts.
  ///
  /// In en, this message translates to:
  /// **'Stock levels & refill alerts'**
  String get statsStockLevelsRefillAlerts;

  /// No description provided for @statsMonthlyWrapped.
  ///
  /// In en, this message translates to:
  /// **'Monthly wrapped'**
  String get statsMonthlyWrapped;

  /// No description provided for @statsViewYourStats.
  ///
  /// In en, this message translates to:
  /// **'View your stats'**
  String get statsViewYourStats;

  /// No description provided for @statsSocial.
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get statsSocial;

  /// No description provided for @statsMedBuddiesLeaderboards.
  ///
  /// In en, this message translates to:
  /// **'Med buddies & leaderboards'**
  String get statsMedBuddiesLeaderboards;

  /// No description provided for @statsAchievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get statsAchievements;

  /// No description provided for @statsTrophyCase.
  ///
  /// In en, this message translates to:
  /// **'Trophy case'**
  String get statsTrophyCase;

  /// No description provided for @statsWeeklyPerformanceTrendChart.
  ///
  /// In en, this message translates to:
  /// **'Weekly performance trend chart'**
  String get statsWeeklyPerformanceTrendChart;

  /// No description provided for @statsShareMedicationReportWithYourDoctor.
  ///
  /// In en, this message translates to:
  /// **'Share medication report with your doctor'**
  String get statsShareMedicationReportWithYourDoctor;

  /// No description provided for @statsNoMedicationsToTrack.
  ///
  /// In en, this message translates to:
  /// **'No medications to track'**
  String get statsNoMedicationsToTrack;

  /// No description provided for @statsLowStock.
  ///
  /// In en, this message translates to:
  /// **'Low stock'**
  String get statsLowStock;

  /// No description provided for @statsTapRightToGoForwardLeft.
  ///
  /// In en, this message translates to:
  /// **'Tap right to go forward, left to go back'**
  String get statsTapRightToGoForwardLeft;

  /// No description provided for @statsYouTook.
  ///
  /// In en, this message translates to:
  /// **'You took'**
  String get statsYouTook;

  /// No description provided for @statsYourLongestStreak.
  ///
  /// In en, this message translates to:
  /// **'Your longest streak'**
  String get statsYourLongestStreak;

  /// No description provided for @statsLongevityScore.
  ///
  /// In en, this message translates to:
  /// **'Longevity Score'**
  String get statsLongevityScore;

  /// No description provided for @statsShareToIgStory.
  ///
  /// In en, this message translates to:
  /// **'Share to IG Story'**
  String get statsShareToIgStory;

  /// No description provided for @statsYourBadges.
  ///
  /// In en, this message translates to:
  /// **'Your badges'**
  String get statsYourBadges;

  /// No description provided for @statsShareToInstagramTiktok.
  ///
  /// In en, this message translates to:
  /// **'Share to Instagram / TikTok'**
  String get statsShareToInstagramTiktok;

  /// No description provided for @statsAdjustNotifications.
  ///
  /// In en, this message translates to:
  /// **'ADJUST NOTIFICATIONS'**
  String get statsAdjustNotifications;

  /// No description provided for @visualizerShowingASampleMedicineScanOr.
  ///
  /// In en, this message translates to:
  /// **'Showing a sample medicine. Scan or analyse a medicine to see your own organ map.'**
  String get visualizerShowingASampleMedicineScanOr;

  /// No description provided for @visualizerN0hDose.
  ///
  /// In en, this message translates to:
  /// **'0h · dose'**
  String get visualizerN0hDose;

  /// No description provided for @visualizerN24hCleared.
  ///
  /// In en, this message translates to:
  /// **'24h · cleared'**
  String get visualizerN24hCleared;

  /// No description provided for @visualizerIllustrativeModelBasedOnTypicalPharmacokinetics.
  ///
  /// In en, this message translates to:
  /// **'Illustrative model based on typical pharmacokinetics — not medical advice.'**
  String get visualizerIllustrativeModelBasedOnTypicalPharmacokinetics;

  /// No description provided for @visualizerSampleIbuprofen400mg.
  ///
  /// In en, this message translates to:
  /// **'Sample: Ibuprofen 400mg'**
  String get visualizerSampleIbuprofen400mg;

  /// No description provided for @visualizerOrganImpactMap.
  ///
  /// In en, this message translates to:
  /// **'Organ impact map'**
  String get visualizerOrganImpactMap;

  /// No description provided for @exportserviceClinicalSummaryReport.
  ///
  /// In en, this message translates to:
  /// **'Clinical Summary Report'**
  String get exportserviceClinicalSummaryReport;

  /// No description provided for @exportserviceGeneratedOn.
  ///
  /// In en, this message translates to:
  /// **'Generated on'**
  String get exportserviceGeneratedOn;

  /// No description provided for @exportservicePatient.
  ///
  /// In en, this message translates to:
  /// **'PATIENT'**
  String get exportservicePatient;

  /// No description provided for @exportserviceN30DayAdherence.
  ///
  /// In en, this message translates to:
  /// **'30-DAY ADHERENCE'**
  String get exportserviceN30DayAdherence;

  /// No description provided for @exportserviceActivePrescriptionsRegimens.
  ///
  /// In en, this message translates to:
  /// **'Active Prescriptions & Regimens'**
  String get exportserviceActivePrescriptionsRegimens;

  /// No description provided for @exportserviceNoActiveMedicationsRecorded.
  ///
  /// In en, this message translates to:
  /// **'No active medications recorded.'**
  String get exportserviceNoActiveMedicationsRecorded;

  /// No description provided for @exportserviceClinicalAdherenceLogLast7Days.
  ///
  /// In en, this message translates to:
  /// **'Clinical Adherence Log (Last 7 Days)'**
  String get exportserviceClinicalAdherenceLogLast7Days;

  /// No description provided for @exportserviceDisclaimerThisReportIsAutomaticallyGenerated.
  ///
  /// In en, this message translates to:
  /// **'Disclaimer: This report is automatically generated by Medai based on user-entered data. It is intended to assist in personal health management and should not be used as a substitute for professional medical advice, diagnosis, or treatment.'**
  String get exportserviceDisclaimerThisReportIsAutomaticallyGenerated;

  /// No description provided for @exportserviceNoAdherenceDataFoundForThe.
  ///
  /// In en, this message translates to:
  /// **'No adherence data found for the last 7 days.'**
  String get exportserviceNoAdherenceDataFoundForThe;

  /// No description provided for @geminiserviceDailyTip.
  ///
  /// In en, this message translates to:
  /// **'Daily Tip'**
  String get geminiserviceDailyTip;

  /// No description provided for @notificationserviceKeepItUp.
  ///
  /// In en, this message translates to:
  /// **'Keep it up! 🏆'**
  String get notificationserviceKeepItUp;

  /// No description provided for @notificationserviceCaregiverEscalation.
  ///
  /// In en, this message translates to:
  /// **'🚨 CAREGIVER ESCALATION 🚨'**
  String get notificationserviceCaregiverEscalation;

  /// No description provided for @notificationserviceGoodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning! ☀️'**
  String get notificationserviceGoodMorning;

  /// No description provided for @notificationserviceHowAreYouFeeling.
  ///
  /// In en, this message translates to:
  /// **'How are you feeling? ✨'**
  String get notificationserviceHowAreYouFeeling;

  /// No description provided for @reportserviceN30DayStabilityMatrix.
  ///
  /// In en, this message translates to:
  /// **'30-DAY STABILITY MATRIX'**
  String get reportserviceN30DayStabilityMatrix;

  /// No description provided for @reportserviceMedaiClinicalReport.
  ///
  /// In en, this message translates to:
  /// **'MEDAI CLINICAL REPORT'**
  String get reportserviceMedaiClinicalReport;

  /// No description provided for @reportserviceComprehensiveMedicationBiometricSummary.
  ///
  /// In en, this message translates to:
  /// **'Comprehensive medication & biometric summary'**
  String get reportserviceComprehensiveMedicationBiometricSummary;

  /// No description provided for @reportserviceThisReportWasGeneratedByMedai.
  ///
  /// In en, this message translates to:
  /// **'This report was generated by MedAI. It is intended for clinical reference only and does not constitute medical advice.'**
  String get reportserviceThisReportWasGeneratedByMedai;

  /// No description provided for @iosuiSendMessage.
  ///
  /// In en, this message translates to:
  /// **'Send message'**
  String get iosuiSendMessage;

  /// No description provided for @biohackingTargetOrgans.
  ///
  /// In en, this message translates to:
  /// **'Target organs'**
  String get biohackingTargetOrgans;

  /// No description provided for @biohackingTapToReveal.
  ///
  /// In en, this message translates to:
  /// **'Tap to reveal'**
  String get biohackingTapToReveal;

  /// No description provided for @biohackingBioimpactTimeline.
  ///
  /// In en, this message translates to:
  /// **'Bioimpact timeline'**
  String get biohackingBioimpactTimeline;

  /// No description provided for @biohackingExitRecordMode.
  ///
  /// In en, this message translates to:
  /// **'Exit Record Mode'**
  String get biohackingExitRecordMode;

  /// No description provided for @biohackingN0hOnset.
  ///
  /// In en, this message translates to:
  /// **'0h (Onset)'**
  String get biohackingN0hOnset;

  /// No description provided for @biohackingN24hResidual.
  ///
  /// In en, this message translates to:
  /// **'24h (Residual)'**
  String get biohackingN24hResidual;

  /// No description provided for @biohackingGeneralInformationTag.
  ///
  /// In en, this message translates to:
  /// **'General Information Tag'**
  String get biohackingGeneralInformationTag;

  /// No description provided for @biohackingDisclaimerVisualizerIsForEducationalPurposes.
  ///
  /// In en, this message translates to:
  /// **'Disclaimer: Visualizer is for educational purposes and maps standard pharmacokinetics. Seek medical advice for personalized biology.'**
  String get biohackingDisclaimerVisualizerIsForEducationalPurposes;

  /// No description provided for @biohackingRecordMode.
  ///
  /// In en, this message translates to:
  /// **'Record Mode'**
  String get biohackingRecordMode;

  /// No description provided for @biohackingDismissOrganInfo.
  ///
  /// In en, this message translates to:
  /// **'Dismiss organ info'**
  String get biohackingDismissOrganInfo;

  /// No description provided for @commonSnoozeNextDose30Minutes.
  ///
  /// In en, this message translates to:
  /// **'Snooze next dose 30 minutes'**
  String get commonSnoozeNextDose30Minutes;

  /// No description provided for @commonUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get commonUndo;

  /// No description provided for @commonYouReOffline.
  ///
  /// In en, this message translates to:
  /// **'You’re offline'**
  String get commonYouReOffline;

  /// No description provided for @commonConnectionIssue.
  ///
  /// In en, this message translates to:
  /// **'Connection issue'**
  String get commonConnectionIssue;

  /// No description provided for @commonThisSectionFailedToLoadNtap.
  ///
  /// In en, this message translates to:
  /// **'This section failed to load.\\nTap Resume on the recovery screen.'**
  String get commonThisSectionFailedToLoadNtap;

  /// No description provided for @commonSomethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get commonSomethingWentWrong;

  /// No description provided for @commonWeVeHitATemporaryIssue.
  ///
  /// In en, this message translates to:
  /// **'We\'ve hit a temporary issue. Your data is safe — resume to keep going.'**
  String get commonWeVeHitATemporaryIssue;

  /// No description provided for @commonResumeSession.
  ///
  /// In en, this message translates to:
  /// **'RESUME SESSION'**
  String get commonResumeSession;

  /// No description provided for @commonRestartApp.
  ///
  /// In en, this message translates to:
  /// **'RESTART APP'**
  String get commonRestartApp;

  /// No description provided for @commonDrugInteraction.
  ///
  /// In en, this message translates to:
  /// **'Drug interaction'**
  String get commonDrugInteraction;

  /// No description provided for @commonDismissInteractionWarning.
  ///
  /// In en, this message translates to:
  /// **'Dismiss interaction warning'**
  String get commonDismissInteractionWarning;

  /// No description provided for @commonImportantHealthNotice.
  ///
  /// In en, this message translates to:
  /// **'Important Health Notice'**
  String get commonImportantHealthNotice;

  /// No description provided for @commonIUnderstandAccept.
  ///
  /// In en, this message translates to:
  /// **'I Understand & Accept'**
  String get commonIUnderstandAccept;

  /// No description provided for @commonByContinuingYouAgreeToOur.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to our Terms of Service and Privacy Policy.'**
  String get commonByContinuingYouAgreeToOur;

  /// No description provided for @commonSetTime.
  ///
  /// In en, this message translates to:
  /// **'Set Time'**
  String get commonSetTime;

  /// No description provided for @commonPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Permission Required'**
  String get commonPermissionRequired;

  /// No description provided for @commonNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not Now'**
  String get commonNotNow;

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @commonShareAchievement.
  ///
  /// In en, this message translates to:
  /// **'Share Achievement'**
  String get commonShareAchievement;

  /// No description provided for @homeQuickLog.
  ///
  /// In en, this message translates to:
  /// **'QUICK LOG'**
  String get homeQuickLog;

  /// No description provided for @modalsAiDataProcessing.
  ///
  /// In en, this message translates to:
  /// **'AI Data Processing'**
  String get modalsAiDataProcessing;

  /// No description provided for @modalsMedAiUsesGoogleGeminiAi.
  ///
  /// In en, this message translates to:
  /// **'Med AI uses Google Gemini AI to analyze your imagery and data. By hitting continue, you agree to securely share your photo and prompts with our AI processing partner.'**
  String get modalsMedAiUsesGoogleGeminiAi;

  /// No description provided for @modalsSecurityIcon.
  ///
  /// In en, this message translates to:
  /// **'Security icon'**
  String get modalsSecurityIcon;

  /// No description provided for @modalsAskMeAnythingAboutYourCurrent.
  ///
  /// In en, this message translates to:
  /// **'Ask me anything about your current health insights or medications.'**
  String get modalsAskMeAnythingAboutYourCurrent;

  /// No description provided for @modalsCoachIsThinking.
  ///
  /// In en, this message translates to:
  /// **'Coach is thinking…'**
  String get modalsCoachIsThinking;

  /// No description provided for @modalsAiHealthCoach.
  ///
  /// In en, this message translates to:
  /// **'AI Health Coach'**
  String get modalsAiHealthCoach;

  /// No description provided for @modalsAiCoachIcon.
  ///
  /// In en, this message translates to:
  /// **'AI coach icon'**
  String get modalsAiCoachIcon;

  /// No description provided for @modalsCoachIsThinking2.
  ///
  /// In en, this message translates to:
  /// **'Coach is thinking'**
  String get modalsCoachIsThinking2;

  /// No description provided for @modalsAskAQuestion.
  ///
  /// In en, this message translates to:
  /// **'Ask a question'**
  String get modalsAskAQuestion;

  /// No description provided for @modalsAskAQuestion2.
  ///
  /// In en, this message translates to:
  /// **'Ask a question...'**
  String get modalsAskAQuestion2;

  /// No description provided for @modalsClinicalReportReady.
  ///
  /// In en, this message translates to:
  /// **'Clinical Report Ready'**
  String get modalsClinicalReportReady;

  /// No description provided for @modalsValueRealization.
  ///
  /// In en, this message translates to:
  /// **'Value Realization'**
  String get modalsValueRealization;

  /// No description provided for @modalsGeneratePdfReport.
  ///
  /// In en, this message translates to:
  /// **'Generate PDF Report'**
  String get modalsGeneratePdfReport;

  /// No description provided for @modalsPrn.
  ///
  /// In en, this message translates to:
  /// **'PRN'**
  String get modalsPrn;

  /// No description provided for @modalsPreviousDay.
  ///
  /// In en, this message translates to:
  /// **'Previous day'**
  String get modalsPreviousDay;

  /// No description provided for @modalsNextDay.
  ///
  /// In en, this message translates to:
  /// **'Next day'**
  String get modalsNextDay;

  /// No description provided for @modalsMedications.
  ///
  /// In en, this message translates to:
  /// **'MEDICATIONS'**
  String get modalsMedications;

  /// No description provided for @modalsNoDosesScheduled.
  ///
  /// In en, this message translates to:
  /// **'No doses scheduled'**
  String get modalsNoDosesScheduled;

  /// No description provided for @modalsSymptomsLogs.
  ///
  /// In en, this message translates to:
  /// **'SYMPTOMS & LOGS'**
  String get modalsSymptomsLogs;

  /// No description provided for @modalsRemovePrnDose.
  ///
  /// In en, this message translates to:
  /// **'Remove PRN dose'**
  String get modalsRemovePrnDose;

  /// No description provided for @modalsDeleteSymptom.
  ///
  /// In en, this message translates to:
  /// **'Delete symptom'**
  String get modalsDeleteSymptom;

  /// No description provided for @modalsNothingHereYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get modalsNothingHereYet;

  /// No description provided for @modalsDoseLogged.
  ///
  /// In en, this message translates to:
  /// **'DOSE LOGGED ✓'**
  String get modalsDoseLogged;

  /// No description provided for @modalsShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get modalsShare;

  /// No description provided for @modalsAwesome.
  ///
  /// In en, this message translates to:
  /// **'Awesome!'**
  String get modalsAwesome;

  /// No description provided for @modalsSensitiveAlertsOnFileReadThese.
  ///
  /// In en, this message translates to:
  /// **'Sensitive alerts on file — read these before you take this dose.'**
  String get modalsSensitiveAlertsOnFileReadThese;

  /// No description provided for @modalsAiGuidanceAlwaysVerifyWithYour.
  ///
  /// In en, this message translates to:
  /// **'AI guidance — always verify with your pharmacist or doctor.'**
  String get modalsAiGuidanceAlwaysVerifyWithYour;

  /// No description provided for @modalsWarnings.
  ///
  /// In en, this message translates to:
  /// **'Warnings'**
  String get modalsWarnings;

  /// No description provided for @modalsBeforeYouTake.
  ///
  /// In en, this message translates to:
  /// **'Before you take'**
  String get modalsBeforeYouTake;

  /// No description provided for @modalsGoodToKnow.
  ///
  /// In en, this message translates to:
  /// **'Good to know'**
  String get modalsGoodToKnow;

  /// No description provided for @modalsMascotWardrobe.
  ///
  /// In en, this message translates to:
  /// **'Mascot Wardrobe'**
  String get modalsMascotWardrobe;

  /// No description provided for @modalsCustomizeYourAiBuddy.
  ///
  /// In en, this message translates to:
  /// **'Customize your AI buddy'**
  String get modalsCustomizeYourAiBuddy;

  /// No description provided for @modalsEquipped.
  ///
  /// In en, this message translates to:
  /// **'EQUIPPED'**
  String get modalsEquipped;

  /// No description provided for @modalsOwned.
  ///
  /// In en, this message translates to:
  /// **'OWNED'**
  String get modalsOwned;

  /// No description provided for @modalsSheetHandle.
  ///
  /// In en, this message translates to:
  /// **'Sheet handle'**
  String get modalsSheetHandle;

  /// No description provided for @modalsPharmacistAiThinking.
  ///
  /// In en, this message translates to:
  /// **'Pharmacist AI thinking...'**
  String get modalsPharmacistAiThinking;

  /// No description provided for @modalsAiAdvice.
  ///
  /// In en, this message translates to:
  /// **'AI ADVICE'**
  String get modalsAiAdvice;

  /// No description provided for @modalsInformationalOnlyAlwaysConsultYourDoctor.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Informational only. Always consult your doctor or pharmacist for advice.'**
  String get modalsInformationalOnlyAlwaysConsultYourDoctor;

  /// No description provided for @modalsInformationalOnlyAlwaysConsultYourDoctor2.
  ///
  /// In en, this message translates to:
  /// **'Informational only. Always consult your doctor or pharmacist for advice.'**
  String get modalsInformationalOnlyAlwaysConsultYourDoctor2;

  /// No description provided for @modalsSkipDose.
  ///
  /// In en, this message translates to:
  /// **'Skip Dose'**
  String get modalsSkipDose;

  /// No description provided for @modalsSafetySaved.
  ///
  /// In en, this message translates to:
  /// **'Safety saved'**
  String get modalsSafetySaved;

  /// No description provided for @modalsReminderOn.
  ///
  /// In en, this message translates to:
  /// **'Reminder on'**
  String get modalsReminderOn;

  /// No description provided for @modalsSeeItOnHome.
  ///
  /// In en, this message translates to:
  /// **'See it on Home'**
  String get modalsSeeItOnHome;

  /// No description provided for @modalsReviewMedicineDetails.
  ///
  /// In en, this message translates to:
  /// **'Review medicine details'**
  String get modalsReviewMedicineDetails;

  /// No description provided for @modalsShareYourWin.
  ///
  /// In en, this message translates to:
  /// **'Share your win'**
  String get modalsShareYourWin;

  /// No description provided for @modalsN30DayPerformance.
  ///
  /// In en, this message translates to:
  /// **'30-DAY PERFORMANCE'**
  String get modalsN30DayPerformance;

  /// No description provided for @modalsPatientInsight.
  ///
  /// In en, this message translates to:
  /// **'PATIENT INSIGHT'**
  String get modalsPatientInsight;

  /// No description provided for @modalsHealthTrends.
  ///
  /// In en, this message translates to:
  /// **'Health Trends'**
  String get modalsHealthTrends;

  /// No description provided for @modalsN30DayAdherenceChart.
  ///
  /// In en, this message translates to:
  /// **'30 day adherence chart'**
  String get modalsN30DayAdherenceChart;

  /// No description provided for @modalsViewDetailedDailyLog.
  ///
  /// In en, this message translates to:
  /// **'View Detailed Daily Log'**
  String get modalsViewDetailedDailyLog;

  /// No description provided for @sharedMarkAsTaken.
  ///
  /// In en, this message translates to:
  /// **'Mark as taken'**
  String get sharedMarkAsTaken;

  /// No description provided for @sharedLate.
  ///
  /// In en, this message translates to:
  /// **'Late'**
  String get sharedLate;

  /// No description provided for @sharedLog.
  ///
  /// In en, this message translates to:
  /// **'Log'**
  String get sharedLog;

  /// No description provided for @viralAiQuickLog.
  ///
  /// In en, this message translates to:
  /// **'AI Quick Log'**
  String get viralAiQuickLog;

  /// No description provided for @viralJustTellMeWhatYouTook.
  ///
  /// In en, this message translates to:
  /// **'Just tell me what you took'**
  String get viralJustTellMeWhatYouTook;

  /// No description provided for @viralOrQuicklyLogAMeal.
  ///
  /// In en, this message translates to:
  /// **'Or quickly log a meal:'**
  String get viralOrQuicklyLogAMeal;

  /// No description provided for @viralListening.
  ///
  /// In en, this message translates to:
  /// **'LISTENING...'**
  String get viralListening;

  /// No description provided for @viralAiIsParsingYourLog.
  ///
  /// In en, this message translates to:
  /// **'AI is parsing your log...'**
  String get viralAiIsParsingYourLog;

  /// No description provided for @viralWeDidn.
  ///
  /// In en, this message translates to:
  /// **'We didn\\'**
  String get viralWeDidn;

  /// No description provided for @viralStopRecording.
  ///
  /// In en, this message translates to:
  /// **'Stop recording'**
  String get viralStopRecording;

  /// No description provided for @viralITook2Tylenol30Minutes.
  ///
  /// In en, this message translates to:
  /// **'\"I took 2 Tylenol 30 minutes ago...\"'**
  String get viralITook2Tylenol30Minutes;

  /// No description provided for @viralLogWithAi.
  ///
  /// In en, this message translates to:
  /// **'Log with AI'**
  String get viralLogWithAi;

  /// No description provided for @viralTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get viralTryAgain;

  /// No description provided for @viralAddMedicineManually.
  ///
  /// In en, this message translates to:
  /// **'Add Medicine Manually'**
  String get viralAddMedicineManually;

  /// No description provided for @viralGetPremiumFreezes.
  ///
  /// In en, this message translates to:
  /// **'Get premium freezes'**
  String get viralGetPremiumFreezes;

  /// No description provided for @viralStartNewStreak.
  ///
  /// In en, this message translates to:
  /// **'Start new streak'**
  String get viralStartNewStreak;

  /// No description provided for @viralMedaiMilestoneShield.
  ///
  /// In en, this message translates to:
  /// **'MEDAI MILESTONE // SHIELD'**
  String get viralMedaiMilestoneShield;

  /// No description provided for @viralSecureV2026.
  ///
  /// In en, this message translates to:
  /// **'[SECURE_v2.026]'**
  String get viralSecureV2026;

  /// No description provided for @viralDayComplianceStreak.
  ///
  /// In en, this message translates to:
  /// **'DAY COMPLIANCE STREAK'**
  String get viralDayComplianceStreak;

  /// No description provided for @viralJoinTheRoutineAtMedaiApp.
  ///
  /// In en, this message translates to:
  /// **'JOIN THE ROUTINE AT MEDAI.APP 💊'**
  String get viralJoinTheRoutineAtMedaiApp;

  /// No description provided for @viralHealthReport.
  ///
  /// In en, this message translates to:
  /// **'HEALTH REPORT'**
  String get viralHealthReport;

  /// No description provided for @viralAdherenceScore.
  ///
  /// In en, this message translates to:
  /// **'ADHERENCE SCORE'**
  String get viralAdherenceScore;

  /// No description provided for @viralTotalLogs.
  ///
  /// In en, this message translates to:
  /// **'TOTAL LOGS'**
  String get viralTotalLogs;

  /// No description provided for @viralShieldLevel.
  ///
  /// In en, this message translates to:
  /// **'SHIELD LEVEL'**
  String get viralShieldLevel;

  /// No description provided for @viralStatus.
  ///
  /// In en, this message translates to:
  /// **'STATUS'**
  String get viralStatus;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'ar',
        'en',
        'es',
        'he',
        'ja',
        'ko',
        'ms'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'he':
      return AppLocalizationsHe();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'ms':
      return AppLocalizationsMs();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
