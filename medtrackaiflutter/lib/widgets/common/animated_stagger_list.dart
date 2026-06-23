import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// A premium list wrapper that subtly staggers the entry of its children.
/// Used for lists, grids, or columns on page load.
/// Emphasizes fade over movement, keeping the experience calm.
class AnimatedStaggerList extends StatelessWidget {
  final List<Widget> children;
  
  /// Duration of the fade/slide per item. Default: 200ms
  final Duration itemDuration;
  
  /// Delay between each item. Default: 30ms (very subtle stagger)
  final Duration staggerDelay;
  
  /// Whether to add a slight slide-up effect. Default: true (4px slide)
  final bool slide;
  
  /// Vertical distance for slide. Default: 4.0
  final double slideDistance;

  const AnimatedStaggerList({
    super.key,
    required this.children,
    this.itemDuration = const Duration(milliseconds: 200),
    this.staggerDelay = const Duration(milliseconds: 30),
    this.slide = true,
    this.slideDistance = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    // We limit the stagger index so very long lists don't delay infinitely
    // and don't cause performance jank on huge lists.
    const maxStaggerItems = 15;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: children.asMap().entries.map((entry) {
        final index = entry.key;
        final child = entry.value;
        final effectiveIndex = index > maxStaggerItems ? maxStaggerItems : index;

        Widget animatedChild = child.animate(delay: staggerDelay * effectiveIndex)
            .fadeIn(duration: itemDuration, curve: Curves.easeOutCubic);
            
        if (slide) {
          animatedChild = (animatedChild as Animate).slideY(
            begin: slideDistance / 100.0, // slight percentage of height usually, but we use literal small val
            end: 0,
            duration: itemDuration,
            curve: Curves.easeOutCubic,
          );
        }

        return animatedChild;
      }).toList(),
    );
  }
}
