import 'dart:ui';
import 'package:flutter/material.dart';

/// A custom scroll behavior that enforces Apple-like momentum scrolling
/// and rubber-banding globally across the entire app for a premium feel.
class SpringScrollBehavior extends ScrollBehavior {
  const SpringScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return const ClampingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      );
    }
    return const BouncingScrollPhysics(
      decelerationRate: ScrollDecelerationRate.normal,
      parent: AlwaysScrollableScrollPhysics(),
    );
  }

  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) {
    // Disable Android's default glowing overscroll indicator in favor of rubber-banding
    return child;
  }
}
