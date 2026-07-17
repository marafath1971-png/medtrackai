import 'package:flutter/material.dart';

import '../../theme/med_ai_ui.dart';
import '../shared/shared_widgets.dart';
import 'med_ai_logo.dart';

class UnifiedHeader extends StatelessWidget implements PreferredSizeWidget {
  final Widget? leading;
  final String? title;
  final Widget? titleWidget;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget? bottom;
  final double? bottomHeight;
  final Color? backgroundColor;
  final bool showBrand;
  final bool isScrolled;
  final bool blurred;
  final bool showBorder;
  final bool showProBadge;
  final bool showBack;
  final VoidCallback? onBack;
  final VoidCallback? onTap;

  const UnifiedHeader({
    super.key,
    this.leading,
    this.title,
    this.titleWidget,
    this.subtitle,
    this.actions,
    this.bottom,
    this.bottomHeight,
    this.blurred = true,
    this.showBorder = true,
    this.backgroundColor,
    this.showBrand = false,
    this.isScrolled = false,
    this.showProBadge = false,
    this.showBack = false,
    this.onBack,
    this.onTap,
  });

  @override
  Size get preferredSize =>
      Size.fromHeight(80 + (bottomHeight ?? (bottom != null ? 60 : 0)));

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final topPad = MediaQuery.of(context).padding.top;
    final motion = MedAiA11y.motion(context, AppDurations.micro);

    return MedAiGlass(
      radius: 0,
      blur: Design2026.glassBlur,
      showBorder: showBorder && (isScrolled || blurred),
      padding: EdgeInsets.fromLTRB(20, topPad + 12, 20, 16),
      tint: (backgroundColor ?? L.bg)
          .withValues(alpha: isScrolled || blurred ? 0.82 : 0.0),
      child: SafeArea(
        bottom: false,
        child: AnimatedContainer(
          duration: motion,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (showBack) ...[
                Semantics(
                  button: true,
                  label: 'Back',
                  child: AnimatedPressable(
                    onTap: onBack ?? () => Navigator.maybePop(context),
                    child: Container(
                      width: MedAiA11y.minTapTarget,
                      height: MedAiA11y.minTapTarget,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: L.fill.withValues(alpha: 0.45),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.arrow_back_ios_new_rounded,
                          color: L.text, size: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ] else if (leading != null) ...[
                leading!,
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showBrand) ...[
                      _buildBrandRow(L),
                    ] else ...[
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: AppTypography.bodySmall.copyWith(
                            color: L.sub,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      if (title != null || titleWidget != null)
                        titleWidget ??
                            Text(
                              title!,
                              style: AppTypography.headlineMedium.copyWith(
                                color: L.text,
                                fontWeight: FontWeight.w800,
                                fontSize: 24,
                                height: 1.1,
                                letterSpacing: -0.5,
                              ),
                            ),
                    ],
                  ],
                ),
              ),
              if (actions != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: actions!
                      .map((a) => Padding(
                            padding: const EdgeInsetsDirectional.only(start: 8),
                            child: a,
                          ))
                      .toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBrandRow(AppThemeColors L) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        MedAiLogo.badge(size: 32, borderRadius: 8),
        const SizedBox(width: 10),
        Text(
          'MedAI',
          style: AppTypography.displayLarge.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: L.text,
            letterSpacing: -1.0,
            height: 1.0,
          ),
        ),
        if (showProBadge) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: L.text,
              borderRadius: BorderRadius.circular(AppRadius.s),
              boxShadow: AppShadows.soft,
            ),
            child: Text(
              'Pro',
              style: AppTypography.labelSmall.copyWith(
                color: L.bg,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class HeaderActionBtn extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final Color? backgroundColor;
  final String? semanticsLabel;

  const HeaderActionBtn({
    super.key,
    required this.child,
    required this.onTap,
    this.backgroundColor,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: AnimatedPressable(
        onTap: onTap,
        scaleFactor: 0.96,
        child: Container(
          width: MedAiA11y.minTapTarget,
          height: MedAiA11y.minTapTarget,
          decoration: BoxDecoration(
            color: backgroundColor ?? L.card,
            borderRadius: BorderRadius.circular(AppRadius.m),
            border: Border.all(color: L.border.withValues(alpha: 0.3), width: 0.5),
            boxShadow: AppShadows.soft,
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class SliverUnifiedHeader extends StatelessWidget {
  final String title;
  final Widget? background;
  final List<Widget>? actions;
  final VoidCallback? onBack;
  final double expandedHeight;

  const SliverUnifiedHeader({
    super.key,
    required this.title,
    this.background,
    this.actions,
    this.onBack,
    this.expandedHeight = 320,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return SliverAppBar(
      expandedHeight: expandedHeight,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: onBack != null
          ? Center(
              child: HeaderActionBtn(
                onTap: onBack!,
                backgroundColor: L.bg.withValues(alpha: 0.6),
                semanticsLabel: 'Back',
                child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
              ),
            )
          : null,
      actions: [
        if (actions != null) ...[
          ...actions!,
          const SizedBox(width: 12),
        ],
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        centerTitle: true,
        titlePadding: const EdgeInsetsDirectional.only(
          bottom: 16,
          start: 40,
          end: 40,
        ),
        title: Text(
          title,
          style: AppTypography.headlineMedium.copyWith(
            fontWeight: FontWeight.w800,
            color: L.text,
            letterSpacing: -0.5,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        background: background,
      ),
    );
  }
}
