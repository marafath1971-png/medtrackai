import 'package:flutter/material.dart';

import '../../theme/med_ai_ui.dart';
import 'animated_pressable.dart';

class RefinedSheetWrapper extends StatelessWidget {
  final Widget child;
  final String? title;
  final Widget? icon;
  final bool scrollable;
  final EdgeInsets? padding;

  const RefinedSheetWrapper({
    super.key,
    required this.child,
    this.title,
    this.icon,
    this.scrollable = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    Widget content = Padding(
      padding: padding ??
          const EdgeInsets.fromLTRB(AppSpacing.screenPadding, 0,
              AppSpacing.screenPadding, AppSpacing.l),
      child: child,
    );

    if (scrollable) {
      content = SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const ClampingScrollPhysics(),
        child: content,
      );
    }

    return ClipRRect(
      borderRadius:
          const BorderRadius.vertical(top: Radius.circular(AppRadius.squircle)),
      child: MedAiGlass(
        radius: AppRadius.squircle,
        padding: EdgeInsets.only(
          bottom: bottomInset > 0 ? bottomInset : bottomPadding,
        ),
        showBorder: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: L.border.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            if (title != null) ...[
              const SizedBox(height: AppSpacing.l),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenPadding),
                child: Row(
                  children: [
                    if (icon != null) ...[
                      icon!,
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Text(
                        title!,
                        style: AppTypography.titleLarge.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: L.text,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    Semantics(
                      button: true,
                      label: 'Close',
                      child: AnimatedPressable(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: MedAiA11y.minTapTarget,
                          height: MedAiA11y.minTapTarget,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: L.fill.withValues(alpha: 0.4),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.close_rounded,
                              color: L.sub, size: 22),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            Flexible(child: content),
          ],
        ),
      ),
    );
  }
}
