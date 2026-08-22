import 'package:flutter/material.dart';

import '../../../theme/med_ai_ui.dart';
import '../../../widgets/common/animated_pressable.dart';

/// Shared building blocks for settings surfaces.
///
/// The app has two settings UIs — GlobalSettingsScreen behind the router and
/// SettingsModal behind Home's gear icon — each with its own row styling, and
/// overlapping content: "Delete Account" appears in three places, data export
/// in three, health sync in both. That is worse than untidy. Destructive
/// actions reached by different routes run different code with different
/// confirmations, so which one a user hits depends on how they navigated.
///
/// These widgets give both surfaces one visual language and one set of
/// affordances, so the duplicates can be collapsed onto shared behaviour
/// rather than re-implemented per screen.

/// A titled group of rows.
class SettingsSection extends StatelessWidget {
  final String title;
  final String? caption;
  final List<Widget> children;

  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
    this.caption,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, AppSpacing.p8),
          child: Text(
            title.toUpperCase(),
            style: AppTypography.caption.copyWith(
              color: L.sub,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: L.card,
            borderRadius: BorderRadius.circular(AppRadius.l),
            border:
                Border.all(color: L.border.withValues(alpha: 0.4), width: 0.8),
          ),
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    indent: 56,
                    color: L.border.withValues(alpha: 0.45),
                  ),
                children[i],
              ],
            ],
          ),
        ),
        if (caption != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, AppSpacing.p8, 4, 0),
            child: Text(
              caption!,
              style: AppTypography.caption.copyWith(color: L.sub, height: 1.4),
            ),
          ),
      ],
    );
  }
}

/// One settings row.
///
/// [destructive] is not only a colour: it also enforces the 48dp target and
/// keeps the label legible against the tint, because these rows delete health
/// records and were previously styled ad hoc per screen.
class SettingsRow extends StatelessWidget {
  /// [IconData], or an emoji string the caller's resolver maps to one.
  ///
  /// The settings tabs were written against emoji literals ('🔔', '⚡'), so the
  /// kit accepts them rather than forcing 38 call sites to change shape. An
  /// emoji with no mapping renders as itself instead of vanishing — the blank
  /// chips that shipped were a resolver returning null and the row drawing the
  /// empty tile anyway.
  final Object icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool destructive;
  final Color? tint;

  const SettingsRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.destructive = false,
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final fg = destructive ? const Color(0xFFB4494A) : L.text;
    final resolved = icon is IconData ? icon as IconData : null;
    final iconTint = destructive
        ? const Color(0xFFB4494A).withValues(alpha: 0.12)
        : (tint ?? AppColors.pastelMint);

    final row = Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.p16, vertical: AppSpacing.p12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconTint,
              borderRadius: BorderRadius.circular(AppRadius.xs),
            ),
            child: resolved != null
                ? Icon(resolved,
                    size: 17,
                    color: destructive
                        ? const Color(0xFFB4494A)
                        : AppColors.accentDeep)
                : Center(
                    child: Text('$icon',
                        style: const TextStyle(fontSize: 15))),
          ),
          const SizedBox(width: AppSpacing.p12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: AppTypography.caption
                        .copyWith(color: L.sub, height: 1.35),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.p8),
            trailing!,
          ] else if (onTap != null)
            Icon(Icons.chevron_right_rounded,
                size: 20, color: L.sub.withValues(alpha: 0.7)),
        ],
      ),
    );

    if (onTap == null) {
      return ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: row,
      );
    }

    return AnimatedPressable(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: row,
      ),
    );
  }
}

/// A row whose trailing control is a switch.
///
/// Tapping anywhere on the row toggles it — the switch alone is a small target
/// and the rest of the row was previously inert.
class SettingsToggle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SettingsToggle({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      child: SettingsRow(
        icon: icon,
        title: title,
        subtitle: subtitle,
        onTap: () => onChanged(!value),
        trailing: Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeTrackColor: AppColors.accentDeep,
        ),
      ),
    );
  }
}
