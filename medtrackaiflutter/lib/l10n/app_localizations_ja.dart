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
}
