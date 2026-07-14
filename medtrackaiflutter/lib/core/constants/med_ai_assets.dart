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

  // ── Ghost mascots (30) ─────────────────────────────────────────────
  // Extracted from the sticker sheet by scripts/extract_mascots.py into
  // assets/mascots/. Use Image.asset(...) with an errorBuilder so screens
  // degrade gracefully if a file is missing. Paths are stable even before the
  // PNGs exist, so screens can reference them now and light up post-extraction.
  static const _m = 'assets/mascots/mascot_';
  // row 1 — core emotions
  static const mascotHappyPill = '${_m}happy_pill.png';
  static const mascotWinkPill = '${_m}wink_pill.png';
  static const mascotCheerStars = '${_m}cheer_stars.png';
  static const mascotSleepyPill = '${_m}sleepy_pill.png';
  static const mascotDeterminedPill = '${_m}determined_pill.png';
  static const mascotLovePill = '${_m}love_pill.png';
  // row 2 — clinical / actions
  static const mascotDoctor = '${_m}doctor.png';
  static const mascotShieldGuard = '${_m}shield_guard.png';
  static const mascotSearchTime = '${_m}search_time.png';
  static const mascotPhoneLove = '${_m}phone_love.png';
  static const mascotMegaphoneAlert = '${_m}megaphone_alert.png';
  static const mascotHugHeart = '${_m}hug_heart.png';
  // row 3 — meds / scheduling
  static const mascotMedsBottle = '${_m}meds_bottle.png';
  static const mascotPillWater = '${_m}pill_water.png';
  static const mascotBlisterPack = '${_m}blister_pack.png';
  static const mascotCalendarWorry = '${_m}calendar_worry.png';
  static const mascotAlarmPanic = '${_m}alarm_panic.png';
  static const mascotSuccessCheck = '${_m}success_check.png';
  // row 4 — data / social
  static const mascotDashboardStats = '${_m}dashboard_stats.png';
  static const mascotFitnessBand = '${_m}fitness_band.png';
  static const mascotAiChat = '${_m}ai_chat.png';
  static const mascotFamilyCry = '${_m}family_cry.png';
  static const mascotCaregiverElder = '${_m}caregiver_elder.png';
  static const mascotBuddyWave = '${_m}buddy_wave.png';
  // row 5 — rewards / lifestyle
  static const mascotHomeHeart = '${_m}home_heart.png';
  static const mascotTrophyWin = '${_m}trophy_win.png';
  static const mascotRewardCoins = '${_m}reward_coins.png';
  static const mascotShoppingRefill = '${_m}shopping_refill.png';
  static const mascotCoolShades = '${_m}cool_shades.png';
  static const mascotMeditateCalm = '${_m}meditate_calm.png';

  /// Maps an app feature/context to the best-fit mascot. Central mapping so
  /// screens ask by intent ('streak', 'scan', 'caregiver') and stay consistent.
  static String mascotFor(String feature) {
    switch (feature) {
      case 'scan':
      case 'ai':
        return mascotAiChat;
      case 'doctor':
      case 'report':
        return mascotDoctor;
      case 'streak':
      case 'milestone':
        return mascotTrophyWin;
      case 'reward':
        return mascotRewardCoins;
      case 'caregiver':
      case 'family':
        return mascotCaregiverElder;
      case 'family_empty':
        return mascotFamilyCry;
      case 'safety':
      case 'privacy':
      case 'guard':
        return mascotShieldGuard;
      case 'together':
      case 'community':
      case 'not_alone':
        return mascotHugHeart;
      case 'plan':
      case 'goal':
      case 'determined':
        return mascotDeterminedPill;
      case 'reminder':
      case 'alarm':
        return mascotAlarmPanic;
      case 'missed':
        return mascotCalendarWorry;
      case 'refill':
        return mascotShoppingRefill;
      case 'add_med':
        return mascotBlisterPack;
      case 'dose_taken':
      case 'success':
        return mascotSuccessCheck;
      case 'stats':
      case 'analytics':
        return mascotDashboardStats;
      case 'night':
      case 'reduced_motion':
        return mascotSleepyPill;
      case 'home':
      case 'welcome':
        return mascotHomeHeart;
      case 'calm':
      case 'focus':
        return mascotMeditateCalm;
      case 'love':
      case 'like':
        return mascotLovePill;
      default:
        return mascotHappyPill;
    }
  }
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
