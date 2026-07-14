import 'package:flutter/material.dart';

/// Purrent-style cream canvas from the analytics reference.
class DashboardPurrentSurface extends StatelessWidget {
  final Widget child;

  const DashboardPurrentSurface({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ColoredBox(
      color: isDark ? const Color(0xFF12141C) : const Color(0xFFF7F7F9),
      child: child,
    );
  }
}
