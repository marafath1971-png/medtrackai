// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'MedAI';

  @override
  String get greetingHero => '홈';

  @override
  String get homeTab => '홈';

  @override
  String get alarmsTab => '알람';

  @override
  String get dashboardTab => '추세';

  @override
  String get familyTab => '서클';

  @override
  String get scanTab => '스캔';

  @override
  String get countrySelectionTitle => '어디에 계신가요?';

  @override
  String get countrySelectionSubtitle => '현지 의약품 브랜드를 파악하는 데 도움이 됩니다';

  @override
  String get prnLabel => '필요시 복용';

  @override
  String get prnUndoToast => '필요시 복용 기록이 삭제되었습니다';

  @override
  String get dailyLogTitle => '일일 기록';

  @override
  String get noMedicinesScheduled => '이 날에 예정된 약이 없습니다.';

  @override
  String get remaining => '남음';

  @override
  String get refillRequired => '재조제 필요';

  @override
  String get settings => '설정';

  @override
  String get profile => '프로필';

  @override
  String get language => '언어';

  @override
  String get country => '국가';

  @override
  String get saveChanges => '변경사항 저장';

  @override
  String get inventory => '재고';

  @override
  String get noMedicines => '약이 없습니다';

  @override
  String get takeNow => '지금 복용';

  @override
  String get snooze => '다시 알림';

  @override
  String get skip => '건너뛰기';

  @override
  String get pharmacyLabel => '약국';

  @override
  String get pharmacyPhoneLabel => '약국 전화번호';

  @override
  String get rxNumberLabel => '처방전 번호';

  @override
  String get globalSettings => '글로벌 설정';

  @override
  String get religiousObservance => '종교적 배려';

  @override
  String get shabbatMode => '안식일 모드';

  @override
  String get prayerAwareReminders => '기도 시간 배려 알림';

  @override
  String get halalDetection => '할랄 및 젤라틴 감지';

  @override
  String get amoledMode => 'AMOLED 모드(절전)';

  @override
  String get diabetesMode => '당뇨 모드';

  @override
  String get hypertensionMode => '고혈압 모드';

  @override
  String get supportedMarkets => '지원 시장';

  @override
  String get halalSafe => '할랄 적합';

  @override
  String get gelatinWarning => '젤라틴 함유';

  @override
  String get halalUncertain => '할랄 불확실';

  @override
  String get edit => '편집';

  @override
  String get editProfile => '프로필 편집';

  @override
  String get cancel => '취소';

  @override
  String get globalSettingsSubtitle => '국제 시장 설정 관리';

  @override
  String get medicationDisplay => '약 표시';

  @override
  String get showGenericNames => '일반명(INN) 표시';

  @override
  String get showGenericNamesSubtitle => '상품명 대신 국제 일반명을 표시합니다';

  @override
  String get pbsSafetyNet => 'PBS 세이프티넷 추적';

  @override
  String get pbsSafetyNetSubtitle => '호주 — 연간 본인부담금 추적';

  @override
  String get pbsThreshold => '연간 기준액: \$1,622.90';

  @override
  String pbsSpent(Object amount) {
    return '지출: \$$amount';
  }

  @override
  String pbsRemaining(Object amount) {
    return '\$$amount 남음';
  }

  @override
  String get reached => '달성!';

  @override
  String get medsSubsidised => '이제 약이 지원 대상입니다!';

  @override
  String get spentAmountSubtitle =>
      '드래그하여 올해 지출액을 업데이트하세요(올해 모든 PBS 처방의 본인부담금)';

  @override
  String get clinicalModes => '임상 모드';

  @override
  String get clinicalModesSubtitle => '미국 · 영국 · UAE · 말레이시아';

  @override
  String get diabetesModeSubtitle => '인슐린/당뇨병 약과 함께 혈당을 기록';

  @override
  String get hypertensionModeSubtitle => '항고혈압제와 함께 혈압을 기록';

  @override
  String get displaySettings => '디스플레이';

  @override
  String get amoledModeSubtitle =>
      '실제 #000000 배경을 사용해 AMOLED 디스플레이를 최적화하고 배터리를 절약합니다';

  @override
  String get shabbatModeSubtitle => '금요일 일몰부터 토요일 밤까지 진동으로만 알리는 부드러운 알림';

  @override
  String get selectCountry => '국가 선택';

  @override
  String get selectLanguage => '언어 선택';

  @override
  String get aiSafetyProfile => 'AI 안전 프로필';

  @override
  String get verified => '확인됨';

  @override
  String get criticalWarnings => '중대 경고';

  @override
  String get drugInteractions => '약물 상호작용';

  @override
  String get dietaryLifestyleRules => '식이 및 생활 습관 규칙';

  @override
  String get ahaInsight => '발견!';

  @override
  String get generateSafetyProfile => '안전 프로필 생성';

  @override
  String get analyzingClinicalLimits => '임상 한계 분석 중...';

  @override
  String get safetyLoadingSubtitle => 'AI가 상호작용, 위험, 식이 규칙을 확인하는 동안 기다려 주세요.';

  @override
  String get safetyPromptSubtitle =>
      '탭하면 이 약의 위험, 약물 상호작용, 생활 습관 규칙을 즉시 분석합니다.';

  @override
  String get goodMorning => '좋은 아침입니다';

  @override
  String get goodAfternoon => '안녕하세요';

  @override
  String get goodEvening => '좋은 저녁입니다';

  @override
  String hiUser(String name) {
    return '안녕하세요, $name님 👋';
  }

  @override
  String get startJourney => '건강 여정을 시작해 볼까요 ✨';

  @override
  String get allDosesTaken => '오늘 복용을 모두 마쳤어요! 🌟';

  @override
  String dosesOverdue(int count) {
    return '복용이 $count회 지연되었습니다 — 지금 복용하세요 ⚠️';
  }

  @override
  String dosesLeft(int count) {
    return '오늘 $count회 남음';
  }

  @override
  String get healthReportTitle => 'MedAI 건강 리포트';

  @override
  String get medicalSummarySubtitle => '개인 의료 요약 및 복약 순응도 추세';

  @override
  String patientLabel(String name) {
    return '환자: $name';
  }

  @override
  String reportDate(String date) {
    return '날짜: $date';
  }

  @override
  String get overallAdherence => '전체 복약 순응도';

  @override
  String get activeMedications => '복용 중인 약';

  @override
  String get reportPeriod => '리포트 기간';

  @override
  String get last30Days => '최근 30일';

  @override
  String get currentMedications => '현재 복용 약';

  @override
  String get medicineCol => '약';

  @override
  String get doseCol => '용량';

  @override
  String get frequencyCol => '빈도';

  @override
  String get stockRemainingCol => '남은 재고';

  @override
  String get recentSymptoms => '최근 증상 및 컨디션';

  @override
  String get symptomDateCol => '날짜';

  @override
  String get symptomNameCol => '증상';

  @override
  String get severityCol => '심각도';

  @override
  String get notesCol => '메모';

  @override
  String get noSymptomsLogged => '이 기간에 기록된 증상이 없습니다.';

  @override
  String get reportFooter =>
      'MedAI Pro로 생성됨. 이 리포트는 정보 제공용이며 자격을 갖춘 의료 전문가의 검토가 필요합니다.';

  @override
  String get settingsStats => '통계';

  @override
  String get settingsApp => '앱 설정';

  @override
  String get settingsData => '데이터 및 개인정보';

  @override
  String get settingsGlobal => '글로벌 설정';

  @override
  String get settingsProfile => '내 프로필';

  @override
  String get adherenceLabel => '순응도';

  @override
  String get streakLabel => '연속 기록';

  @override
  String streakDays(int count) {
    return '$count일';
  }

  @override
  String get generateClinicalReport => '임상 리포트 생성';

  @override
  String get fetchingAiInsights => 'AI 분석 가져오는 중...';

  @override
  String get aiCoachDisclaimer =>
      '이 대시보드는 AI로 패턴을 분석합니다. 의학적 조언은 항상 의사와 상담하세요.';

  @override
  String get insightsTitle => '인사이트';

  @override
  String get insightsSubtitle => '분석 및 건강 패턴';

  @override
  String get dataSummaryTitle => '내 데이터 요약';

  @override
  String get dataMedicinesLabel => '약';

  @override
  String get dataAlarmsLabel => '설정된 알람';

  @override
  String get dataDaysTrackedLabel => '기록한 일수';

  @override
  String get dataDosesLoggedLabel => '기록한 복용';

  @override
  String get exportAndBackup => '내보내기 및 백업';

  @override
  String get exportPdfReport => 'PDF 리포트 내보내기';

  @override
  String get exportPdfSubtitle => '의사 및 보호자용';

  @override
  String get exportCsv => '기록을 CSV로 내보내기';

  @override
  String exportCsvSubtitle(int count) {
    return '$count건의 복용 기록';
  }

  @override
  String get resetSection => '초기화';

  @override
  String get deleteAllData => '모든 데이터 삭제';

  @override
  String get deleteAllDataSubtitle => '모든 약, 기록, 설정을 삭제합니다';

  @override
  String get deleteConfirmTitle => '모든 데이터를 삭제할까요?';

  @override
  String get deleteConfirmBody => '모든 데이터가 영구적으로 삭제됩니다. 이 작업은 되돌릴 수 없습니다.';

  @override
  String get deleteButton => '모두 삭제';

  @override
  String get legalSection => '법적 고지';

  @override
  String get privacyPolicy => '개인정보 처리방침';

  @override
  String get privacyPolicySubtitle => '건강 데이터를 보호하는 방법';

  @override
  String get termsOfService => '서비스 약관';

  @override
  String get termsOfServiceSubtitle => 'MedAI 이용 규칙';

  @override
  String get appVersionLabel => '앱 버전';

  @override
  String get appVersionValue => '1.0.0+1';

  @override
  String get analysisFailed => '분석 실패';

  @override
  String get somethingWentWrong => '문제가 발생했습니다. 다시 시도해 주세요.';

  @override
  String get retry => '다시 시도';

  @override
  String get onboardingSkip => '건너뛰기';

  @override
  String get onboardingNext => '다음';

  @override
  String get onboardingContinue => '계속';

  @override
  String get onboardingGetStarted => '시작하기';

  @override
  String get onboardingWelcomeTitle => '무너지지 않는\n복약 습관 만들기';

  @override
  String get onboardingWelcomeBody => '연속 기록, 스마트 알림, 그리고 매일 당신을 챙기는 AI.';

  @override
  String get onboardingScanTitle => '어떤 알약도\n몇 초 만에 스캔';

  @override
  String get onboardingScanBodyDemo =>
      '아래를 탭하면 AI가 샘플 약을 즉시 식별하는 모습을 볼 수 있습니다.';

  @override
  String get onboardingScanBodyDone => '이것이 Med AI의 속도입니다. 입력도, 추측도 필요 없습니다.';

  @override
  String get onboardingSimulateScan => '스캔 체험하기 →';

  @override
  String get onboardingPermissionTitle => '당신의 카메라,\n당신의 개인정보';

  @override
  String get onboardingPermissionBody =>
      '카메라는 알약 라벨을 읽는 데만 사용됩니다. 이미지는 안전하게 처리되며 절대 판매되지 않습니다.';

  @override
  String get onboardingPermissionLink => '데이터 보호 방법 알아보기';

  @override
  String get onboardingPersonalizeTitle => '경험을\n맞춤 설정하기';

  @override
  String get onboardingQuizMedCount => '약이 몇 가지인가요?';

  @override
  String get onboardingQuizRole => '누구를 위해 기록하나요?';

  @override
  String get onboardingQuizSchedule => '대부분의 약을 언제 복용하나요?';

  @override
  String get onboardingRoleSelf => '나 자신';

  @override
  String get onboardingRoleCaregiver => '내가 돌보는 사람';

  @override
  String get onboardingScheduleMorning => '아침';

  @override
  String get onboardingScheduleEvening => '저녁';

  @override
  String get onboardingScheduleBoth => '둘 다';

  @override
  String get onboardingSocialTitle => '5만 명 이상의\n건강 챔피언과 함께하세요';

  @override
  String get onboardingSocialQuote =>
      '“Med AI는 우리 가족의 복약 관리 방식을 바꿔놨어요. 스캔 기능만으로도 하루 10분을 절약합니다.”';

  @override
  String get onboardingSocialAttribution => '— App Store 리뷰, 별 5개';

  @override
  String get onboardingAllowCamera => '카메라 접근 허용';

  @override
  String get onboardingTryDemoScan => '데모 스캔 체험';

  @override
  String get loadingHealthData => '건강 데이터를 불러오는 중…';
}
