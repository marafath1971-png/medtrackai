import 'package:flutter/material.dart';

import '../../theme/med_ai_ui.dart';

/// Global 2026 scaffold — layered depth with optional aurora atmosphere.
///
/// Stacks a subtle animated aurora field, ambient accent wash, and content
/// for a premium, living background without overwhelming readability.
class AppScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final bool extendBody;
  final bool extendBodyBehindAppBar;

  /// When true, paints ambient wash + optional aurora behind content.
  final bool showMeshOverlay;
  /// Subtle drifting color field (June 2026 "living UI" trend).
  final bool showAurora;
  final Color? backgroundColor;

  const AppScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    this.showMeshOverlay = true,
    this.showAurora = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final bg = backgroundColor ?? L.bg;
    final reduceMotion = MedAiA11y.reducedMotion(context);

    return Scaffold(
      backgroundColor: bg,
      extendBody: extendBody,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      body: showMeshOverlay || showAurora
          ? Stack(
              fit: StackFit.expand,
              children: [
                if (showAurora && !reduceMotion)
                  AuroraBackground(
                    opacity: context.isDark ? 0.55 : 0.35,
                  ),
                if (showMeshOverlay) const _AmbientWash(),
                body,
              ],
            )
          : body,
    );
  }
}

/// Static accent wash — top-right vignette for depth without motion.
class _AmbientWash extends StatelessWidget {
  const _AmbientWash();

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final isDark = context.isDark;

    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0.95, -1.0),
            radius: 1.15,
            colors: [
              L.accent.withValues(alpha: isDark ? 0.09 : 0.06),
              L.bg.withValues(alpha: 0.0),
            ],
          ),
        ),
      ),
    );
  }
}
