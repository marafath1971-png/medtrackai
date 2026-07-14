import 'package:flutter/material.dart';
import '../../../../theme/med_ai_ui.dart';

/// Apple HIG-aligned tokens for inset grouped settings lists.
abstract final class IosSettingsTokens {
  static const double groupRadius = 12;
  static const double groupInset = 16;
  static const double sectionGap = 24;
  static const double headerGap = 8;
  static const double rowHPad = 16;
  static const double rowVPad = 11;
  static const double iconSize = 30;
  static const double iconRadius = 7;
  static const double iconGap = 12;
  static const double separatorInset = 58;
  static const double chevronSize = 14;

  // iOS system accent colors (Settings-style icon tiles).
  static const Color systemBlue = Color(0xFF007AFF);
  static const Color systemGreen = Color(0xFF34C759);
  static const Color systemOrange = Color(0xFFFF9500);
  static const Color systemRed = Color(0xFFFF3B30);
  static const Color systemPurple = Color(0xFFAF52DE);
  static const Color systemPink = Color(0xFFFF2D55);
  static const Color systemTeal = Color(0xFF5AC8FA);
  static const Color systemIndigo = Color(0xFF5856D6);
  static const Color systemGray = Color(0xFF8E8E93);
}

class IosSettingsSectionHeader extends StatelessWidget {
  final String title;
  final String? footer;

  const IosSettingsSectionHeader({
    super.key,
    required this.title,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Padding(
      padding: const EdgeInsets.only(
        left: IosSettingsTokens.groupInset,
        right: IosSettingsTokens.groupInset,
        bottom: IosSettingsTokens.headerGap,
      ),
      child: Text(
        title.toUpperCase(),
        style: AppTypography.labelSmall.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.08,
          height: 1.2,
          color: L.sub.withValues(alpha: 0.85),
        ),
      ),
    );
  }
}

class IosSettingsSectionFooter extends StatelessWidget {
  final String text;

  const IosSettingsSectionFooter({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Padding(
      padding: const EdgeInsets.only(
        left: IosSettingsTokens.groupInset,
        right: IosSettingsTokens.groupInset,
        top: IosSettingsTokens.headerGap,
      ),
      child: Text(
        text,
        style: AppTypography.bodySmall.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          height: 1.35,
          color: L.sub.withValues(alpha: 0.75),
        ),
      ),
    );
  }
}

class IosSettingsIcon extends StatelessWidget {
  final IconData icon;
  final Color background;

  const IosSettingsIcon({
    super.key,
    required this.icon,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: IosSettingsTokens.iconSize,
      height: IosSettingsTokens.iconSize,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(IosSettingsTokens.iconRadius),
      ),
      child: Icon(
        icon,
        size: 17,
        color: Colors.white,
      ),
    );
  }
}

class IosInsetSeparator extends StatelessWidget {
  const IosInsetSeparator({super.key});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Padding(
      padding: const EdgeInsets.only(left: IosSettingsTokens.separatorInset),
      child: Divider(
        height: 0.5,
        thickness: 0.5,
        color: L.border.withValues(alpha: 0.22),
      ),
    );
  }
}

/// iOS-style segmented tab track for settings sub-navigation.
class IosSettingsSegmentedBar extends StatelessWidget {
  final List<String> labels;
  final List<IconData> icons;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final bool scrollable;

  const IosSettingsSegmentedBar({
    super.key,
    required this.labels,
    required this.icons,
    required this.selectedIndex,
    required this.onSelected,
    this.scrollable = false,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    assert(labels.length == icons.length);
    final useScroll = scrollable || labels.length > 4;

    final track = Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: L.fill.withValues(alpha: context.isDark ? 0.55 : 0.9),
        borderRadius: BorderRadius.circular(9),
      ),
      child: _buildSegments(context, L, expand: !useScroll),
    );

    if (!useScroll) return track;

    return LayoutBuilder(
      builder: (context, constraints) {
        final minTrackWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width - 32;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: minTrackWidth),
            child: track,
          ),
        );
      },
    );
  }

  Widget _buildSegments(
    BuildContext context,
    AppThemeColors L, {
    required bool expand,
  }) {
    return Row(
      children: List.generate(labels.length, (index) {
        final segment = _buildSegment(context, L, index);
        if (expand) return Expanded(child: segment);
        return SizedBox(width: 76, child: segment);
      }),
    );
  }

  Widget _buildSegment(BuildContext context, AppThemeColors L, int index) {
    final selected = index == selectedIndex;
    return Semantics(
      button: true,
      selected: selected,
      label: labels[index],
      child: GestureDetector(
        onTap: () => onSelected(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          constraints: const BoxConstraints(
            minHeight: MedAiA11y.minTapTargetCompact,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
          decoration: BoxDecoration(
            color: selected
                ? (context.isDark ? L.card : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
            boxShadow: selected && !context.isDark
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icons[index],
                size: 15,
                color: selected ? L.text : L.sub.withValues(alpha: 0.9),
              ),
              const SizedBox(height: 2),
              Text(
                labels[index],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTypography.labelSmall.copyWith(
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? L.text : L.sub.withValues(alpha: 0.9),
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Color iosSettingsIconColor(dynamic icon, Color? iconBg) {
  // Explicit override always wins (callers that intentionally set a status color).
  if (iconBg != null) {
    return iconBg.withValues(alpha: 1);
  }

  // Cal AI de-noise: settings icons are MONOCHROME by default. Only true
  // destructive/exit actions keep a status color (red). Everything else uses
  // one neutral tone so the list reads calm, not rainbow. (Was: a different
  // bright system color per emoji — the main source of visual noise.)
  const neutral = IosSettingsTokens.systemGray;

  if (icon is IconData) {
    return switch (icon) {
      Icons.delete_forever_rounded || Icons.logout_rounded =>
        IosSettingsTokens.systemRed,
      _ => neutral,
    };
  }

  final token = icon is String ? icon : null;
  return switch (token) {
    // Keep red ONLY for destructive/critical signals.
    '🗑️' || '🚪' => IosSettingsTokens.systemRed,
    _ => neutral,
  };
}

// ── Legacy rainbow mapping removed ─────────────────────────────────────
// The per-emoji bright-color switch (🎯→orange, 🩺→red, 🎂→pink, 🧬→purple…)
// was the main source of settings visual noise. Replaced by the monochrome
// default in iosSettingsIconColor above, per CAL_AI_DESIGN_SPEC.md. If you ever
// want the iOS-style rainbow back, it's in git history before this commit.


IconData? iosSettingsResolveIcon(dynamic icon) {
  if (icon is IconData) return icon;
  if (icon is! String) return null;
  return switch (icon) {
    '🌐' => Icons.language_rounded,
    '🎯' => Icons.flag_rounded,
    '🩺' => Icons.monitor_heart_rounded,
    '🎂' => Icons.cake_rounded,
    '🧬' => Icons.biotech_rounded,
    '💳' => Icons.credit_card_rounded,
    '🔄' => Icons.autorenew_rounded,
    '🎬' => Icons.rocket_launch_rounded,
    '📊' => Icons.insert_chart_rounded,
    '🚪' => Icons.logout_rounded,
    '🗑️' => Icons.delete_forever_rounded,
    '💬' => Icons.support_agent_rounded,
    '⭐' => Icons.star_rounded,
    '🔐' => Icons.lock_rounded,
    '📜' => Icons.description_rounded,
    'ℹ️' => Icons.info_outline_rounded,
    '🚀' => Icons.rocket_launch_rounded,
    '🔔' => Icons.notifications_active_rounded,
    '⚡' => Icons.bolt_rounded,
    '⏰' => Icons.alarm_rounded,
    '👨‍👩‍👧' => Icons.family_restroom_rounded,
    '✨' => Icons.palette_rounded,
    '❤️' => Icons.favorite_rounded,
    '💊' => Icons.medication_rounded,
    '🛡️' => Icons.shield_outlined,
    '📄' => Icons.picture_as_pdf_rounded,
    '📥' => Icons.download_rounded,
    '⚖️' => Icons.gavel_rounded,
    _ => null,
  };
}
