import 'package:flutter/material.dart';

import '../../../../theme/med_ai_ui.dart';
import '../../../../widgets/common/animated_pressable.dart';

/// Premium settings tokens — soft pastel wellness aesthetic (reference-aligned).
abstract final class IosSettingsTokens {
  static const double groupRadius = 22;
  static const double groupInset = 20;
  static const double sectionGap = 20;
  static const double headerGap = 10;
  static const double rowHPad = 16;
  static const double rowVPad = 14;
  static const double iconSize = 36;
  static const double iconRadius = 12;
  static const double iconGap = 14;
  static const double separatorInset = 66;
  static const double chevronSize = 16;

  static const Color systemOrange = Color(0xFFE8A04A);
  static const Color systemRed = Color(0xFFC45C5C);
  static const Color systemPurple = Color(0xFF8B7BB8);
  static const Color systemPink = Color(0xFFD48A9A);
  static const Color systemTeal = Color(0xFF5BA8C8);
  static const Color systemIndigo = Color(0xFF6B7BB8);
  static const Color systemGray = Color(0xFF8A9099);
  static const Color canvas = Color(0xFFF7F6F3);
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
        title,
        style: AppTypography.titleMedium.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
          height: 1.2,
          color: L.text,
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
          fontWeight: FontWeight.w500,
          height: 1.4,
          color: L.sub.withValues(alpha: 0.8),
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
    final soft = Color.alphaBlend(
      background.withValues(alpha: 0.18),
      Colors.white,
    );
    return Container(
      width: IosSettingsTokens.iconSize,
      height: IosSettingsTokens.iconSize,
      decoration: BoxDecoration(
        color: soft,
        borderRadius: BorderRadius.circular(IosSettingsTokens.iconRadius),
      ),
      child: Icon(
        icon,
        size: 18,
        color: background == IosSettingsTokens.systemGray
            ? AppColors.accentDeep
            : background,
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
      padding: const EdgeInsetsDirectional.only(
        start: IosSettingsTokens.separatorInset,
      ),
      child: Divider(
        height: 0.5,
        thickness: 0.5,
        color: L.border.withValues(alpha: 0.18),
      ),
    );
  }
}

/// Soft pill segmented control — reference floating dock energy.
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
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A2621).withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: _buildSegments(context, L, expand: !useScroll),
    );

    if (!useScroll) return track;

    return LayoutBuilder(
      builder: (context, constraints) {
        final minTrackWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width - 40;
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
        return SizedBox(width: 78, child: segment);
      }),
    );
  }

  Widget _buildSegment(BuildContext context, AppThemeColors L, int index) {
    final selected = index == selectedIndex;
    return Semantics(
      button: true,
      selected: selected,
      label: labels[index],
      child: AnimatedPressable(
        onTap: () => onSelected(index),
        scaleFactor: 0.97,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          curve: AppCurves.emilOut,
          constraints: const BoxConstraints(
            minHeight: MedAiA11y.minTapTargetCompact,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.p8,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
                    colors: [AppColors.lime, AppColors.limeDeep],
                  )
                : null,
            color: selected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.limeDeep.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icons[index],
                size: 16,
                color: selected
                    ? AppColors.limeInk
                    : L.sub.withValues(alpha: 0.85),
              ),
              const SizedBox(height: 3),
              Text(
                labels[index],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTypography.labelSmall.copyWith(
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected
                      ? AppColors.limeInk
                      : L.sub.withValues(alpha: 0.85),
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
  if (iconBg != null) return iconBg.withValues(alpha: 1);

  if (icon is IconData) {
    return switch (icon) {
      Icons.delete_forever_rounded || Icons.logout_rounded =>
        IosSettingsTokens.systemRed,
      Icons.notifications_active_rounded || Icons.notifications_rounded =>
        IosSettingsTokens.systemOrange,
      Icons.shield_outlined || Icons.lock_rounded => AppColors.accentDeep,
      Icons.favorite_rounded || Icons.monitor_heart_rounded =>
        IosSettingsTokens.systemPink,
      Icons.palette_rounded || Icons.auto_awesome_rounded =>
        IosSettingsTokens.systemPurple,
      Icons.medication_rounded || Icons.science_outlined => AppColors.sageGreen,
      Icons.family_restroom_rounded => IosSettingsTokens.systemTeal,
      Icons.bar_chart_rounded || Icons.insert_chart_rounded =>
        IosSettingsTokens.systemIndigo,
      _ => AppColors.accentDeep,
    };
  }

  final token = icon is String ? icon : null;
  return switch (token) {
    '🗑️' || '🚪' => IosSettingsTokens.systemRed,
    '🔔' || '⚡' || '⏰' => IosSettingsTokens.systemOrange,
    '🛡️' || '🔐' => AppColors.accentDeep,
    '❤️' || '🩺' => IosSettingsTokens.systemPink,
    '✨' || '🚀' || '🎬' => IosSettingsTokens.systemPurple,
    '💊' => AppColors.sageGreen,
    '👨‍👩‍👧' => IosSettingsTokens.systemTeal,
    '📊' || '📈' => IosSettingsTokens.systemIndigo,
    '🎯' || '🎂' || '🧬' || '🌐' => AppColors.accentDeep,
    _ => AppColors.accentDeep,
  };
}

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
