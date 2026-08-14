/// Bundled HD photos — one unique file per role (never reused across screens).
abstract final class PremiumPhotos {
  static const welcome = 'assets/photos/ob_welcome.jpg';
  static const know = 'assets/photos/ob_know.jpg';
  static const family = 'assets/photos/ob_family.jpg';
  static const thrive = 'assets/photos/ob_thrive.jpg';
  static const routine = 'assets/photos/ob_routine.jpg';
  static const community = 'assets/photos/ob_community.jpg';

  /// Scan intro panel (ObScanIntro).
  static const scan = 'assets/photos/ob_scan.jpg';

  /// “How it works” onboarding step — unique from [scan].
  static const scanHow = 'assets/photos/ob_scan_how.jpg';

  /// Scan hero scene illustration — unique from [scan] / [scanHow].
  static const scanFeature = 'assets/photos/ob_scan_feature.jpg';

  static const rank = 'assets/photos/ob_rank.jpg';
  static const finish = 'assets/photos/ob_finish.jpg';
  static const homeMorning = 'assets/photos/home_morning.jpg';

  /// Mosaic-only tiles — never used as full-bleed heroes.
  static const gallery = [
    'assets/photos/gallery_01.jpg',
    'assets/photos/gallery_02.jpg',
    'assets/photos/gallery_03.jpg',
    'assets/photos/gallery_04.jpg',
    'assets/photos/gallery_05.jpg',
    'assets/photos/gallery_06.jpg',
    'assets/photos/gallery_07.jpg',
    'assets/photos/gallery_08.jpg',
  ];
}
