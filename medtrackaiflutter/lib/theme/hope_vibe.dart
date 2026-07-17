import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Canonical hopeful / trusted / “made for you” voice for Med AI.
///
/// Use across onboarding, home, scan success, paywall, and share —
/// before and after pay — so users feel this app was built for them
/// and that consistency here becomes real-world success.
abstract final class HopeVibe {
  // ── Brand narrative (one line users should feel) ──
  static const tagline = 'Know it. Trust it. Succeed with it.';
  static const madeForYou = 'Made for you — and people like you';
  static const youveGotThis = "You've got this";
  static const numberOneFeel = 'Your #1 plan for medication success';
  static const worthIt = 'Worth it — because your health is worth it';
  static const manifestation =
      'Every dose you take is a step toward the life you want';

  // ── Home ──
  static const medicinesSubtitle =
      'Built for you — know them, trust them, succeed with them.';
  static const progressToday = 'Your success\ntoday';
  static const progressDone = "You're winning today";
  static const progressEmpty = 'Scan to begin\nyour win streak';
  static const dailyDosesTag = 'YOUR SUCCESS';
  static String streakChip(int n) =>
      n <= 0 ? '🌱 Start your streak' : '🔥 $n-day success streak';

  // ── Med card status lines ──
  static const readyForToday = 'Ready for today — you\'ve got this';
  static const sensitiveAlerts = 'Important alerts — know before you take';
  static String lowStock(int n) => 'Low stock · $n left — refill with peace';
  static String bodyImpactHint(String snippet) =>
      snippet.isEmpty ? 'See how it supports your body' : snippet;

  // ── Know medicine ──
  static const knowTitle = 'Know your medicine';
  static const knowCritical =
      'A quick safety check before this dose — you\'ve got this.';
  static const knowSoft =
      'A quick check so you take this dose with confidence.';
  static const stripCriticalTitle = 'Know before you take';
  static const stripSoftTitle = 'Your dose clarity';

  // ── Body impact ──
  static const bodyImpactTitle = 'How this supports you';
  static const bodyImpactHow = 'How it works in your body';

  // ── Scan success ──
  static const scanSuccessTitle = "You're set up for success";
  static String scanSuccessBody(String name) =>
      '$name is in your tracker.\nKnow it. Take it. Stay consistent — you\'ve got this.';
  static const shareYourWin = 'Share your win';

  // ── Share / recommend (pre + post pay) ──
  static const recommendTitle = 'Recommend Med AI';
  static const recommendSubtitle =
      'Help someone you care about succeed — share the app you trust';
  static String shareStreakTitle(int n) => 'Share your $n-day success streak';
  static const shareStreakSubtitle =
      'Inspire friends on Instagram, TikTok & more';
  static const shareInviteMessage =
      'I found my #1 medication companion — Med AI.\n'
      'Scan. Know. Never miss a dose. Feel in control.\n'
      'If you take medicine, this one is worth it:\n';

  // ── Onboarding peaks ──
  static const welcomeDoneSubtitle =
      "You're in. Let's make every dose a win — starting today.";
  static const thrivingSubtitle =
      'Personalized reminders, scan insights, caregiver peace, and AI that has your back.';
  static const socialProofSubtitle =
      'Built for real medication routines — so you feel safe, confident, and successful.';
  static const startImprovingCta = 'Begin my success plan';

  // ── Paywall (outcome-led, not scarcity-led) ──
  static const paywallHeadlineTrial =
      'Your success plan starts free — cancel anytime.';
  static const paywallHeadlineGate =
      'Unlock the full plan made for your medication life.';
  static const paywallSocial = '4.9 · Trusted by 500K+ people';
  static const paywallGateScan =
      'Keep scanning with confidence.\nUnlock unlimited AI medicine recognition.';
  static const paywallGateVoice =
      'Keep logging by voice.\nUnlock unlimited AI voice logging.';
  static const paywallGateGeneric =
      'Continue your success plan.\nStart your free trial today.';

  // ── Soft pastel surfaces (reference wellness vibe) ──
  static Color softCanvas(AppThemeColors L) => L.bg;

  static BoxDecoration softCard({
    required Color tint,
    double radius = AppRadius.l,
    Color? border,
  }) =>
      BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(radius),
        border: border != null
            ? Border.all(color: border.withValues(alpha: 0.18))
            : null,
        boxShadow: AppShadows.soft,
      );

  static LinearGradient get limeHero => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.lime, AppColors.limeDeep],
      );
}
