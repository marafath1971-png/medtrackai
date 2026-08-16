import 'package:flutter/material.dart';

import '../../theme/med_ai_ui.dart';

/// A surface whose fill is actually painted, for content that must contrast
/// with it.
///
/// [MedAiGlass] honours its `tint` only in dark mode — in light mode it always
/// paints `L.card`. Three separate screens hit that trap by tinting a surface
/// dark and colouring their content to match, producing white-on-white: the
/// "Continue with Apple" button rendered as an empty pill, selected caregiver
/// chips looked unselected, and users could not read their own chat messages.
///
/// Each screen fixed it with its own near-identical private widget. This is
/// that fix, once, in a place tests can reach.
///
/// Use [SolidSurface] whenever the child's colour depends on the fill being
/// dark. For decorative tinting where the content is readable either way,
/// [MedAiGlass] is still the right choice.
class SolidSurface extends StatelessWidget {
  const SolidSurface({
    super.key,
    required this.filled,
    required this.child,
    this.radius = AppRadius.l,
    this.padding = EdgeInsets.zero,
    this.showBorder = false,
    this.glassWhenUnfilled = false,
    this.blur = 24,
  });

  /// When true the surface paints a genuinely dark fill (`L.text`) and the
  /// child is expected to be light. When false it paints `L.card`.
  final bool filled;

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;

  /// Draws a border that thickens when [filled] — used by selection chips so
  /// the active state reads at a glance.
  final bool showBorder;

  /// Render the unfilled state as frosted glass rather than a flat card. The
  /// auth buttons and AI chat bubbles want this; selection chips do not.
  final bool glassWhenUnfilled;

  final double blur;

  @override
  Widget build(BuildContext context) {
    final L = context.L;

    if (!filled && glassWhenUnfilled) {
      return MedAiGlass(
        radius: radius,
        blur: blur,
        tint: L.card,
        padding: padding,
        child: child,
      );
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: filled ? L.text : L.card,
        borderRadius: BorderRadius.circular(radius),
        border: showBorder
            ? Border.all(
                color: filled ? L.text : L.glassBorder.withValues(alpha: 0.22),
                width: filled ? 1.5 : 0.5,
              )
            : null,
        boxShadow: AppShadows.soft,
      ),
      child: child,
    );
  }
}
