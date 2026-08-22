import 'package:flutter/material.dart';

import '../../../../core/utils/haptic_engine.dart';
import '../../../../theme/med_ai_ui.dart';
import '../../../../widgets/common/animated_pressable.dart';
import '../../../settings/widgets/settings_kit.dart';
import 'ios_settings_style.dart';

class SettingsSection extends StatelessWidget {
  final String? title;
  final String? footer;
  final Widget child;

  const SettingsSection({
    super.key,
    this.title,
    this.footer,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null) IosSettingsSectionHeader(title: title!),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: IosSettingsTokens.groupInset,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              // Was a hardcoded Colors.white while the row labels use L.text,
              // which flips to near-white in dark mode — white text on a white
              // card. The whole settings surface was unreadable in dark.
              color: context.L.card,
              borderRadius:
                  BorderRadius.circular(IosSettingsTokens.groupRadius),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1A2621).withValues(alpha: 0.045),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius:
                  BorderRadius.circular(IosSettingsTokens.groupRadius),
              child: child,
            ),
          ),
        ),
        if (footer != null) IosSettingsSectionFooter(text: footer!),
        const SizedBox(height: IosSettingsTokens.sectionGap),
      ],
    );
  }
}

class SettingsModalRow extends StatelessWidget {
  final dynamic icon;
  final Color? iconBg;
  final String label;
  final String? sub;
  final Widget? right;
  final VoidCallback? onClick;
  final bool border;
  final bool first;
  final bool last;

  const SettingsModalRow({
    super.key,
    required this.icon,
    this.iconBg,
    required this.label,
    this.sub,
    this.right,
    this.onClick,
    this.border = true,
    this.first = false,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    // Delegates to SettingsRow so there is one row implementation rather than
    // two that drift. This wrapper keeps the emoji-to-IconData resolution and
    // the first/last/border grouping the 38 existing call sites pass, so none
    // of them had to change shape.
    final resolved = iosSettingsResolveIcon(icon);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SettingsRow(
          icon: resolved ?? icon,
          title: label,
          subtitle: sub,
          trailing: right,
          tint: iconBg,
          onTap: onClick == null
              ? null
              : () {
                  HapticEngine.selection();
                  onClick!();
                },
        ),
        if (border) const IosInsetSeparator(),
      ],
    );
  }
}

class SettingsEditField extends StatelessWidget {
  final String label;
  final String placeholder;
  final TextEditingController ctrl;
  final AppThemeColors L;
  final TextInputType keyboard;
  final bool border;

  const SettingsEditField({
    super.key,
    required this.label,
    required this.ctrl,
    required this.placeholder,
    required this.L,
    this.keyboard = TextInputType.text,
    this.border = true,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      textField: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: IosSettingsTokens.rowHPad,
              vertical: AppSpacing.p12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MedAiLabeledField(
                  label: label,
                  controller: ctrl,
                  hintText: placeholder,
                  keyboardType: keyboard,
                ),
              ],
            ),
          ),
          if (border) const IosInsetSeparator(),
        ],
      ),
    );
  }
}

class SettingsSelectRow extends StatelessWidget {
  final String label;
  final bool isSel;
  final bool border;
  final VoidCallback onClick;
  final AppThemeColors L;
  final bool first;
  final bool last;

  const SettingsSelectRow({
    super.key,
    required this.label,
    required this.isSel,
    required this.onClick,
    required this.L,
    this.border = true,
    this.first = false,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSel,
      label: label,
      child: AnimatedPressable(
        onTap: () {
          HapticEngine.selection();
          onClick();
        },
        scaleFactor: 0.99,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              constraints: const BoxConstraints(
                minHeight: MedAiA11y.minTapTargetCompact,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: IosSettingsTokens.rowHPad,
                vertical: IosSettingsTokens.rowVPad,
              ),
              color: isSel
                  ? AppColors.pastelMint.withValues(alpha: 0.65)
                  : Colors.transparent,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                        color: L.text,
                        fontSize: 16,
                        letterSpacing: -0.3,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isSel)
                    Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.lime, AppColors.limeDeep],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: AppColors.limeInk,
                        size: 16,
                      ),
                    )
                  else
                    const SizedBox(width: AppSpacing.p20),
                ],
              ),
            ),
            if (border) const IosInsetSeparator(),
          ],
        ),
      ),
    );
  }
}

class SettingsStatCard extends StatelessWidget {
  final String label;
  final String val;
  final String sub;
  final String emoji;
  final AppThemeColors L;

  const SettingsStatCard({
    super.key,
    required this.label,
    required this.val,
    required this.sub,
    required this.emoji,
    required this.L,
  });

  @override
  Widget build(BuildContext context) {
    final icon = _mapStatIcon(emoji);
    final color = iosSettingsIconColor(emoji, null);
    final tint = _tintFor(emoji);

    return Semantics(
      label: '$label: $val. $sub',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tint,
          borderRadius: BorderRadius.circular(IosSettingsTokens.groupRadius),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A2621).withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.p12,
            AppSpacing.p12,
            AppSpacing.p12,
            AppSpacing.p12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IosSettingsIcon(icon: icon, background: color),
                  const Spacer(),
                  Icon(
                    Icons.arrow_outward_rounded,
                    size: 14,
                    color: L.sub.withValues(alpha: 0.4),
                  ),
                ],
              ),
              const Spacer(flex: 2),
              Text(
                label,
                maxLines: 1,
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: L.sub,
                  fontSize: 12,
                  height: 1.2,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  val,
                  maxLines: 1,
                  style: AppTypography.displayMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 28,
                    color: L.text,
                    letterSpacing: -0.8,
                    height: 1.0,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sub,
                maxLines: 1,
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w500,
                  color: L.sub.withValues(alpha: 0.8),
                  fontSize: 12,
                  height: 1.2,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _tintFor(String token) {
    return switch (token) {
      '✅' => AppColors.pastelMint,
      '📈' => AppColors.pastelSky,
      '🔥' => AppColors.pastelSun,
      '📅' => AppColors.pastelSky,
      _ => AppColors.pastelMint,
    };
  }

  IconData _mapStatIcon(String token) {
    return switch (token) {
      '✅' => Icons.check_circle_rounded,
      '📈' => Icons.show_chart_rounded,
      '🔥' => Icons.local_fire_department_rounded,
      '📅' => Icons.calendar_month_rounded,
      _ => Icons.insights_rounded,
    };
  }
}
