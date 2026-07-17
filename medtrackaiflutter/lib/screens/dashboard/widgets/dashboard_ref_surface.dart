import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

/// Calm dashboard backdrop — flat theme bg (Cal AI: no pastel mesh).
class DashboardRefSurface extends StatelessWidget {
  final Widget child;

  const DashboardRefSurface({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return ColoredBox(
      color: L.bg,
      child: child,
    );
  }
}
