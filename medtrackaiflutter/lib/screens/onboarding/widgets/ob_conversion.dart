import 'package:flutter/material.dart';

import '../../../core/constants/med_ai_assets.dart';
import '../../../theme/med_ai_ui.dart';
import '../../../widgets/common/ghost_mascot.dart';

/// Conversion surfaces for onboarding, built on the app's own mascot set.
///
/// Three things drove this rewrite, in order of how much they cost:
///
/// 1. **Unverifiable claims.** The flow asserted "Trusted by 500,000+ people",
///    "93% hit their adherence goal" and "97% adherence" as facts, in seven
///    languages, from hardcoded constants. Play prohibits misrepresentation and
///    health claims draw extra review, so these were a rejection risk on a paid
///    app. They are also weak persuasion: readers discount round numbers they
///    cannot source. What replaces them is specific and true — a claim about
///    what the app *does*, or a number derived from the user's own answers.
///
/// 2. **Stock photography.** Stethoscopes and pill bottles are what every
///    competitor ships, which is the opposite of the personalised feel the flow
///    was reaching for. The mascot set is unique to this app and reads warmer on
///    a medical subject, where clinical photography raises anxiety.
///
/// 3. **Anxiety framing.** Several screens led with what goes wrong ("Know
///    what's *wrong* with your regimen"). Fear converts a first tap and then
///    depresses retention and trust, which is backwards for a subscription.

/// A claim the app can actually stand behind.
///
/// [ClaimKind] separates a capability ("scans a label in a second") from a
/// personalised figure computed from the user's own answers. Neither invents
/// population statistics.
enum ClaimKind {
  /// Something the app does. Verifiable by using it.
  capability,

  /// Derived from this user's answers, and labelled as such.
  personalised,
}

/// Hero block: mascot, headline, and one honest supporting line.
///
/// Replaces the photo-and-gradient heroes. The mascot renders on a transparent
/// PNG over the page background, so there is no green card behind it.
class ObMascotHero extends StatelessWidget {
  final String mascotAsset;
  final String headline;
  final String? support;

  /// Small pill above the headline — a section marker, not a claim.
  final String? eyebrow;
  final double mascotSize;

  const ObMascotHero({
    super.key,
    required this.mascotAsset,
    required this.headline,
    this.support,
    this.eyebrow,
    this.mascotSize = 168,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;

    return Column(
      children: [
        // showGlow paints a soft radial behind the sticker rather than a solid
        // card, which is what kept producing a green rectangle around it.
        GhostMascot(
          asset: mascotAsset,
          size: mascotSize,
          showGlow: true,
          semanticLabel: headline,
        ),
        const SizedBox(height: AppSpacing.p20),
        if (eyebrow != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.pastelMint,
              borderRadius: BorderRadius.circular(AppRadius.max),
            ),
            child: Text(
              eyebrow!.toUpperCase(),
              style: AppTypography.caption.copyWith(
                color: AppColors.accentDeep,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.p12),
        ],
        Text(
          headline,
          textAlign: TextAlign.center,
          style: AppTypography.headlineMedium.copyWith(
            color: L.text,
            fontWeight: FontWeight.w800,
            height: 1.12,
            letterSpacing: -0.6,
          ),
        ),
        if (support != null) ...[
          const SizedBox(height: AppSpacing.p8),
          Text(
            support!,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: L.sub,
              height: 1.45,
            ),
          ),
        ],
      ],
    );
  }
}

/// A capability card — what the app does, stated plainly.
///
/// This is the honest replacement for the stat cards. "Reads a label in about a
/// second" is checkable by the user in the next thirty seconds, so it builds
/// trust instead of spending it.
class ObCapabilityCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String detail;
  final Color tint;

  const ObCapabilityCard({
    super.key,
    required this.icon,
    required this.title,
    required this.detail,
    this.tint = AppColors.pastelMint,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.p16),
      decoration: BoxDecoration(
        color: L.card,
        borderRadius: BorderRadius.circular(AppRadius.l),
        border: Border.all(color: L.border.withValues(alpha: 0.4), width: 0.8),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(AppRadius.s),
            ),
            child: Icon(icon, size: 22, color: AppColors.accentDeep),
          ),
          const SizedBox(width: AppSpacing.p12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTypography.titleMedium.copyWith(
                    color: L.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: AppTypography.bodySmall.copyWith(
                    color: L.sub,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Reflects the user's own answers back at them.
///
/// This is the part that legitimately raises intent: not "500,000 people trust
/// us", but "you told us you take 4 medicines and forget the evening dose —
/// here is the routine we built for that". Every value comes from the session,
/// so nothing is asserted about anyone else.
class ObPersonalPlanCard extends StatelessWidget {
  final List<({String label, String value})> rows;
  final String title;
  final String? footnote;

  const ObPersonalPlanCard({
    super.key,
    required this.rows,
    this.title = 'Built from your answers',
    this.footnote,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.p20),
      decoration: BoxDecoration(
        color: L.card,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A2621).withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded,
                  size: 16, color: AppColors.accentDeep),
              const SizedBox(width: 6),
              Text(
                title.toUpperCase(),
                style: AppTypography.caption.copyWith(
                  color: AppColors.accentDeep,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.p16),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              Divider(
                height: AppSpacing.p20,
                color: L.border.withValues(alpha: 0.4),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    rows[i].label,
                    style: AppTypography.bodySmall.copyWith(color: L.sub),
                  ),
                ),
                const SizedBox(width: AppSpacing.p12),
                Flexible(
                  child: Text(
                    rows[i].value,
                    textAlign: TextAlign.end,
                    style: AppTypography.bodyMedium.copyWith(
                      color: L.text,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (footnote != null) ...[
            const SizedBox(height: AppSpacing.p16),
            Text(
              footnote!,
              style: AppTypography.caption.copyWith(
                color: L.sub,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Trial terms, stated before the purchase rather than after.
///
/// Play requires subscription price, period and renewal terms to be clear
/// before purchase, and hiding them is also the top driver of refunds and
/// chargebacks — both of which cost more than the conversions they buy.
class ObTrialTerms extends StatelessWidget {
  final String price;
  final String period;
  final int trialDays;

  const ObTrialTerms({
    super.key,
    required this.price,
    required this.period,
    this.trialDays = 7,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.p16),
          decoration: BoxDecoration(
            color: AppColors.pastelMint.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppRadius.l),
          ),
          child: Row(
            children: [
              Icon(Icons.lock_open_rounded,
                  size: 18, color: AppColors.accentDeep),
              const SizedBox(width: AppSpacing.p8),
              Expanded(
                child: Text(
                  trialDays > 0
                      ? 'Free for $trialDays days, then $price/$period. '
                          'Cancel anytime before it ends.'
                      : '$price/$period. Cancel anytime.',
                  style: AppTypography.bodySmall.copyWith(
                    color: L.text,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Mascot mapping for onboarding beats.
///
/// Centralised so a beat's character stays consistent if steps are reordered,
/// and so every referenced asset can be checked by one test.
abstract final class ObMascots {
  static const welcome = MedAiAssets.mascotBuddyWave;
  static const goal = MedAiAssets.mascotDeterminedPill;
  static const scan = MedAiAssets.mascotSearchTime;
  static const remind = MedAiAssets.mascotAlarmPanic;
  static const protect = MedAiAssets.mascotShieldGuard;
  static const family = MedAiAssets.mascotCaregiverElder;
  static const streak = MedAiAssets.mascotTrophyWin;
  static const plan = MedAiAssets.mascotDashboardStats;
  static const commit = MedAiAssets.mascotHugHeart;
  static const done = MedAiAssets.mascotCheerStars;

  /// Every mascot this module can render — the list a bundling test walks.
  static const all = <String>[
    welcome, goal, scan, remind, protect,
    family, streak, plan, commit, done,
  ];
}
