import 'package:flutter/material.dart';
import '../../../../theme/med_ai_ui.dart';
import '../../../../widgets/common/animated_pressable.dart';
import '../../../../core/utils/haptic_engine.dart';

class SettingsSection extends StatelessWidget {
  final String? title;
  final Widget child;
  const SettingsSection({super.key, this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (title != null) MedAiSectionHeader(title: title!),
      MedAiDepthCard(
        padding: EdgeInsets.zero,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: child,
        ),
      ),
      const SizedBox(height: 28),
    ]);
  }
}

class SettingsModalRow extends StatelessWidget {
  final dynamic icon; // String or IconData
  final Color? iconBg;
  final String label;
  final String? sub;
  final Widget? right;
  final VoidCallback? onClick;
  final bool border;
  final bool first, last;

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
    final L = context.L;
    final Color bg = iconBg ?? L.text;
    final isInteractive = onClick != null;

    Widget row = Container(
      constraints: const BoxConstraints(minHeight: MedAiA11y.minTapTarget),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.only(
          topLeft: first ? const Radius.circular(AppRadius.xl) : Radius.zero,
          topRight: first ? const Radius.circular(AppRadius.xl) : Radius.zero,
          bottomLeft: last ? const Radius.circular(AppRadius.xl) : Radius.zero,
          bottomRight: last ? const Radius.circular(AppRadius.xl) : Radius.zero,
        ),
        border: border
            ? Border(
                bottom: BorderSide(
                    color: L.border.withValues(alpha: 0.12), width: 0.5))
            : null,
      ),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
              color: bg.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: bg.withValues(alpha: 0.12), width: 0.5)),
          child: Center(
              child: icon is String
                  ? Text(icon as String,
                      style: AppTypography.titleLarge.copyWith(fontSize: 16))
                  : Icon(icon as IconData, size: 18, color: bg)),
        ),
        const SizedBox(width: 16),
        Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
              Text(label,
                  style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: L.text,
                      fontSize: 15,
                      letterSpacing: -0.2),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1),
              if (sub != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(sub!,
                      style: AppTypography.bodySmall.copyWith(
                          color: L.sub, fontWeight: FontWeight.w500)),
                ),
            ])),
        if (right != null)
          right!
        else if (onClick != null)
          Icon(Icons.chevron_right_rounded,
              size: 20, color: L.sub.withValues(alpha: 0.5)),
      ]),
    );

    if (isInteractive) {
      row = Semantics(
        button: true,
        label: sub != null ? '$label. $sub' : label,
        child: AnimatedPressable(
          onTap: () {
            HapticEngine.selection();
            onClick!();
          },
          scaleFactor: 0.98,
          child: row,
        ),
      );
    }

    return row;
  }
}

class SettingsEditField extends StatelessWidget {
  final String label, placeholder;
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
            border: border
                ? Border(
                    bottom: BorderSide(
                        color: L.border.withValues(alpha: 0.1), width: 0.5))
                : null),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: AppTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                  color: L.sub,
                  fontSize: 12)),
          const SizedBox(height: 6),
          TextField(
            controller: ctrl,
            keyboardType: keyboard,
            style: AppTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
                color: L.text,
                fontSize: 16,
                letterSpacing: -0.2),
            decoration: InputDecoration(
                hintText: placeholder,
                hintStyle: AppTypography.bodyLarge
                    .copyWith(color: L.sub.withValues(alpha: 0.3)),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero),
          ),
        ]),
      ),
    );
  }
}

class SettingsSelectRow extends StatelessWidget {
  final String label;
  final bool isSel, border;
  final VoidCallback onClick;
  final AppThemeColors L;
  final bool first, last;

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
        scaleFactor: 0.98,
        child: Container(
          constraints: const BoxConstraints(minHeight: MedAiA11y.minTapTarget),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
              color: isSel ? L.accent.withValues(alpha: 0.06) : Colors.transparent,
              borderRadius: BorderRadius.only(
                topLeft: first ? const Radius.circular(AppRadius.xl) : Radius.zero,
                topRight: first ? const Radius.circular(AppRadius.xl) : Radius.zero,
                bottomLeft: last ? const Radius.circular(AppRadius.xl) : Radius.zero,
                bottomRight: last ? const Radius.circular(AppRadius.xl) : Radius.zero,
              ),
              border: border
                  ? Border(
                      bottom: BorderSide(
                          color: L.border.withValues(alpha: 0.12), width: 0.5))
                  : null),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(
              child: Text(label,
                  style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: L.text,
                      fontSize: 15,
                      letterSpacing: -0.2),
                  overflow: TextOverflow.ellipsis),
            ),
            if (isSel)
              Icon(Icons.check_circle_rounded, color: L.accent, size: 22)
            else
              Icon(Icons.circle_outlined,
                  color: L.sub.withValues(alpha: 0.25), size: 22),
          ]),
        ),
      ),
    );
  }
}

class SettingsStatCard extends StatelessWidget {
  final String label, val, sub, emoji;
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
    return Semantics(
      label: '$label: $val. $sub',
      child: MedAiDepthCard(
        accentGlow: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: L.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(emoji, style: const TextStyle(fontSize: 14)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(label,
                    style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: L.sub,
                        fontSize: 12,
                        letterSpacing: 0.1),
                    overflow: TextOverflow.ellipsis),
              ),
            ]),
            const Spacer(),
            Text(val,
                style: AppTypography.displayMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 28,
                    color: L.text,
                    letterSpacing: -0.6)),
            const SizedBox(height: 2),
            Text(sub,
                style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: L.sub.withValues(alpha: 0.5),
                    fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
