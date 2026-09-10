// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'MedAI';

  @override
  String get greetingHero => 'ホーム';

  @override
  String get homeTab => 'ホーム';

  @override
  String get alarmsTab => 'アラーム';

  @override
  String get dashboardTab => '傾向';

  @override
  String get familyTab => 'サークル';

  @override
  String get scanTab => 'スキャン';

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
  String get countrySelectionTitle => 'お住まいの地域は？';

  @override
  String get countrySelectionSubtitle => '地域の医薬品ブランドを特定するのに役立ちます';

  @override
  String get prnLabel => '頓服';

  @override
  String get prnUndoToast => '頓服の記録を取り消しました';

  @override
  String get dailyLogTitle => 'デイリーログ';

  @override
  String get noMedicinesScheduled => 'この日に予定されている薬はありません。';

  @override
  String get remaining => '残り';

  @override
  String get refillRequired => '補充が必要';

  @override
  String get settings => '設定';

  @override
  String get profile => 'プロフィール';

  @override
  String get language => '言語';

  @override
  String get country => '国';

  @override
  String get saveChanges => '変更を保存';

  @override
  String get inventory => '在庫';

  @override
  String get noMedicines => '薬がありません';

  @override
  String get takeNow => '今すぐ服用';

  @override
  String get snooze => 'スヌーズ';

  @override
  String get skip => 'スキップ';

  @override
  String get pharmacyLabel => '薬局';

  @override
  String get pharmacyPhoneLabel => '薬局の電話番号';

  @override
  String get rxNumberLabel => '処方番号';

  @override
  String get globalSettings => 'グローバル設定';

  @override
  String get religiousObservance => '宗教的配慮';

  @override
  String get shabbatMode => '安息日モード';

  @override
  String get prayerAwareReminders => '礼拝に配慮したリマインダー';

  @override
  String get halalDetection => 'ハラルとゼラチンの検出';

  @override
  String get amoledMode => 'AMOLEDモード（省電力）';

  @override
  String get diabetesMode => '糖尿病モード';

  @override
  String get hypertensionMode => '高血圧モード';

  @override
  String get supportedMarkets => '対応地域';

  @override
  String get halalSafe => 'ハラル対応';

  @override
  String get gelatinWarning => 'ゼラチンを含む';

  @override
  String get halalUncertain => 'ハラル不明';

  @override
  String get edit => '編集';

  @override
  String get editProfile => 'プロフィールを編集';

  @override
  String get cancel => 'キャンセル';

  @override
  String get globalSettingsSubtitle => '各国の市場設定を管理';

  @override
  String get medicationDisplay => '薬の表示';

  @override
  String get showGenericNames => '一般名（INN）を表示';

  @override
  String get showGenericNamesSubtitle => '商品名の代わりに国際一般名を表示します';

  @override
  String get pbsSafetyNet => 'PBSセーフティネット追跡';

  @override
  String get pbsSafetyNetSubtitle => 'オーストラリア — 年間自己負担額を記録';

  @override
  String get pbsThreshold => '年間しきい値：\$1,622.90';

  @override
  String pbsSpent(Object amount) {
    return '支出：\$$amount';
  }

  @override
  String pbsRemaining(Object amount) {
    return 'あと\$$amount';
  }

  @override
  String get reached => '達成！';

  @override
  String get medsSubsidised => '薬が補助対象になりました！';

  @override
  String get spentAmountSubtitle => 'スライドして今年の支出額を更新（今年のすべてのPBS処方の自己負担額）';

  @override
  String get clinicalModes => '臨床モード';

  @override
  String get clinicalModesSubtitle => '米国・英国・UAE・マレーシア';

  @override
  String get diabetesModeSubtitle => 'インスリンや糖尿病薬とあわせて血糖値を記録';

  @override
  String get hypertensionModeSubtitle => '降圧薬とあわせて血圧を記録';

  @override
  String get displaySettings => '表示';

  @override
  String get amoledModeSubtitle =>
      '真の#000000背景を使ってAMOLEDディスプレイを最適化し、バッテリーを節約します';

  @override
  String get shabbatModeSubtitle => '金曜の日没から土曜の夜まで、振動のみの穏やかなリマインダー';

  @override
  String get selectCountry => '国を選択';

  @override
  String get selectLanguage => '言語を選択';

  @override
  String get aiSafetyProfile => 'AI安全性プロファイル';

  @override
  String get verified => '確認済み';

  @override
  String get criticalWarnings => '重大な警告';

  @override
  String get drugInteractions => '薬物相互作用';

  @override
  String get dietaryLifestyleRules => '食事・生活のルール';

  @override
  String get ahaInsight => '気づき！';

  @override
  String get generateSafetyProfile => '安全性プロファイルを生成';

  @override
  String get analyzingClinicalLimits => '臨床的な上限を分析中...';

  @override
  String get safetyLoadingSubtitle => 'AIが相互作用、危険性、食事のルールを確認しています。しばらくお待ちください。';

  @override
  String get safetyPromptSubtitle => 'タップすると、この薬の危険性、薬物相互作用、生活上のルールをすぐに分析します。';

  @override
  String get goodMorning => 'おはようございます';

  @override
  String get goodAfternoon => 'こんにちは';

  @override
  String get goodEvening => 'こんばんは';

  @override
  String hiUser(String name) {
    return 'こんにちは、$nameさん 👋';
  }

  @override
  String get startJourney => '健康への第一歩を始めましょう ✨';

  @override
  String get allDosesTaken => '今日の服用はすべて完了です！🌟';

  @override
  String dosesOverdue(int count) {
    return '$count回分の服用が遅れています — 今すぐ服用してください ⚠️';
  }

  @override
  String dosesLeft(int count) {
    return '今日はあと$count回分';
  }

  @override
  String get healthReportTitle => 'MedAI健康レポート';

  @override
  String get medicalSummarySubtitle => '個人の医療サマリーと服薬遵守の傾向';

  @override
  String patientLabel(String name) {
    return '患者：$name';
  }

  @override
  String reportDate(String date) {
    return '日付：$date';
  }

  @override
  String get overallAdherence => '全体の服薬遵守率';

  @override
  String get activeMedications => '服用中の薬';

  @override
  String get reportPeriod => 'レポート期間';

  @override
  String get last30Days => '過去30日間';

  @override
  String get currentMedications => '現在の薬';

  @override
  String get medicineCol => '薬';

  @override
  String get doseCol => '用量';

  @override
  String get frequencyCol => '頻度';

  @override
  String get stockRemainingCol => '残りの在庫';

  @override
  String get recentSymptoms => '最近の症状と体調';

  @override
  String get symptomDateCol => '日付';

  @override
  String get symptomNameCol => '症状';

  @override
  String get severityCol => '重症度';

  @override
  String get notesCol => 'メモ';

  @override
  String get noSymptomsLogged => 'この期間に記録された症状はありません。';

  @override
  String get reportFooter =>
      'MedAI Proにより生成。このレポートは情報提供のみを目的としており、有資格の医療専門家による確認が必要です。';

  @override
  String get settingsStats => '統計';

  @override
  String get settingsApp => 'アプリ設定';

  @override
  String get settingsData => 'データとプライバシー';

  @override
  String get settingsGlobal => 'グローバル設定';

  @override
  String get settingsProfile => 'マイプロフィール';

  @override
  String get adherenceLabel => '服薬遵守';

  @override
  String get streakLabel => '連続記録';

  @override
  String streakDays(int count) {
    return '$count日';
  }

  @override
  String get generateClinicalReport => '臨床レポートを生成';

  @override
  String get fetchingAiInsights => 'AI分析を取得中...';

  @override
  String get aiCoachDisclaimer =>
      'このダッシュボードはAIでパターンを分析します。医療上の助言は必ず医師にご相談ください。';

  @override
  String get insightsTitle => '分析';

  @override
  String get insightsSubtitle => '分析と健康パターン';

  @override
  String get dataSummaryTitle => 'データの概要';

  @override
  String get dataMedicinesLabel => '薬';

  @override
  String get dataAlarmsLabel => '設定したアラーム';

  @override
  String get dataDaysTrackedLabel => '記録日数';

  @override
  String get dataDosesLoggedLabel => '記録した服用回数';

  @override
  String get exportAndBackup => 'エクスポートとバックアップ';

  @override
  String get exportPdfReport => 'PDFレポートをエクスポート';

  @override
  String get exportPdfSubtitle => '医師や介護者向け';

  @override
  String get exportCsv => '履歴をCSVでエクスポート';

  @override
  String exportCsvSubtitle(int count) {
    return '$count件の服用記録';
  }

  @override
  String get resetSection => 'リセット';

  @override
  String get deleteAllData => 'すべてのデータを削除';

  @override
  String get deleteAllDataSubtitle => 'すべての薬、履歴、設定を削除します';

  @override
  String get deleteConfirmTitle => 'すべてのデータを削除しますか？';

  @override
  String get deleteConfirmBody => 'すべてのデータが完全に削除されます。この操作は取り消せません。';

  @override
  String get deleteButton => 'すべて削除';

  @override
  String get legalSection => '法的事項';

  @override
  String get privacyPolicy => 'プライバシーポリシー';

  @override
  String get privacyPolicySubtitle => '健康データの保護方法';

  @override
  String get termsOfService => '利用規約';

  @override
  String get termsOfServiceSubtitle => 'MedAIの利用ルール';

  @override
  String get appVersionLabel => 'アプリのバージョン';

  @override
  String get appVersionValue => '1.0.0+1';

  @override
  String get analysisFailed => '分析に失敗しました';

  @override
  String get somethingWentWrong => '問題が発生しました。もう一度お試しください。';

  @override
  String get retry => '再試行';

  @override
  String get onboardingSkip => 'スキップ';

  @override
  String get onboardingNext => '次へ';

  @override
  String get onboardingContinue => '続ける';

  @override
  String get onboardingGetStarted => 'はじめる';

  @override
  String get onboardingWelcomeTitle => '揺るがない\n服薬習慣を築く';

  @override
  String get onboardingWelcomeBody => '連続記録、スマートなリマインダー、そして毎日あなたを支えるAI。';

  @override
  String get onboardingScanTitle => 'どんな錠剤も\n数秒でスキャン';

  @override
  String get onboardingScanBodyDemo => '下をタップして、AIがサンプルの薬を瞬時に識別する様子をご覧ください。';

  @override
  String get onboardingScanBodyDone => 'これがMed AIの速さです。入力も推測も不要。';

  @override
  String get onboardingSimulateScan => 'スキャンを試す →';

  @override
  String get onboardingPermissionTitle => 'あなたのカメラ、\nあなたのプライバシー';

  @override
  String get onboardingPermissionBody =>
      'カメラは錠剤のラベルを読み取るためだけに使用します。画像は安全に処理され、販売されることはありません。';

  @override
  String get onboardingPermissionLink => 'データ保護の仕組みを見る';

  @override
  String get onboardingPersonalizeTitle => '体験を\nパーソナライズ';

  @override
  String get onboardingQuizMedCount => '薬は何種類ですか？';

  @override
  String get onboardingQuizRole => '誰のために記録しますか？';

  @override
  String get onboardingQuizSchedule => '薬はいつ服用しますか？';

  @override
  String get onboardingRoleSelf => '自分';

  @override
  String get onboardingRoleCaregiver => '介護している人';

  @override
  String get onboardingScheduleMorning => '朝';

  @override
  String get onboardingScheduleEvening => '夜';

  @override
  String get onboardingScheduleBoth => '両方';

  @override
  String get onboardingSocialTitle => '5万人以上の\n健康チャンピオンに参加';

  @override
  String get onboardingSocialQuote =>
      '「Med AIは家族の服薬管理を変えてくれました。スキャン機能だけで1日10分節約できています。」';

  @override
  String get onboardingSocialAttribution => '— App Storeレビュー、星5つ';

  @override
  String get onboardingAllowCamera => 'カメラへのアクセスを許可';

  @override
  String get onboardingTryDemoScan => 'デモスキャンを試す';

  @override
  String get loadingHealthData => '健康データを読み込んでいます…';

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
