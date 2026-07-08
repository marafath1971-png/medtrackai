/// Central registry for 2026 premium asset paths.
class MedAiAssets {
  MedAiAssets._();

  // Rive (hero loops — fallbacks render if missing)
  static const riveSplashLogo = 'assets/rive/splash_logo.riv';
  static const riveOnboardingStreak = 'assets/rive/onboarding_streak.riv';
  static const riveOnboardingScan = 'assets/rive/onboarding_scan.riv';
  static const riveOnboardingFamily = 'assets/rive/onboarding_family.riv';
  static const rivePaywallHero = 'assets/rive/paywall_hero.riv';

  // Lottie
  static const lottieCelebrationCheck = 'assets/lottie/celebration_check.json';
  static const lottieEmptyMeds = 'assets/lottie/empty_meds.json';

  // Illustrations (PNG fallbacks)
  static const illustrationGhostScan = 'assets/images/ghost_scan.png';
  static const illustrationHomeLogo = 'assets/images/home_logo.png';
  static const illustrationAppLogo = 'assets/images/app_logo.png';
  static const illustrationAppIcon = 'assets/images/app_icon.png';
  static const illustrationAppIconBlue = 'assets/images/app_icon_blue.png';
  // Pill-less ghost mascot for the home/dashboard fuel-gauge hero. Must be a
  // transparent-background silhouette so the liquid fill traces the ghost
  // shape. Falls back to an icon via errorBuilder if the file is absent.
  static const illustrationMascot = 'assets/images/mascot.png';

  // SVG icons
  static const iconScan = 'assets/icons/scan.svg';
  static const iconHome = 'assets/icons/home.svg';
  static const iconAnalytics = 'assets/icons/analytics.svg';
  static const iconAlarms = 'assets/icons/alarms.svg';
  static const iconFamily = 'assets/icons/family.svg';
  static const iconStreak = 'assets/icons/streak.svg';
  static const iconPill = 'assets/icons/pill.svg';
  static const iconShield = 'assets/icons/shield.svg';
  static const iconCamera = 'assets/icons/camera.svg';
  static const iconVoice = 'assets/icons/voice.svg';
  static const iconBarcode = 'assets/icons/barcode.svg';
  static const iconSearch = 'assets/icons/search.svg';
}

enum MedAiAnimationKind {
  splashLogo,
  onboardingStreak,
  onboardingScan,
  onboardingFamily,
  paywallHero,
  celebrationCheck,
  emptyMeds,
}
