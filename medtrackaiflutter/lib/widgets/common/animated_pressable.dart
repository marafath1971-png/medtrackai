import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import '../../core/utils/haptic_engine.dart';

/// A world-class 2026 standard gesture handler providing native iOS-like
/// spring physics, scaling, opacity changes, and haptics.
class AnimatedPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  
  /// Gesture callbacks and behavior passed down to GestureDetector
  final HitTestBehavior? behavior;
  final GestureTapDownCallback? onTapDown;
  final GestureTapUpCallback? onTapUp;
  final GestureTapCancelCallback? onTapCancel;
  
  /// The scale down factor when pressed.
  final double scaleFactor;
  
  /// The opacity when pressed. Set to 1.0 for no opacity change.
  final double opacityFactor;
  
  /// True if haptics should be played on tap.
  final bool hapticEnabled;
  
  /// True if the interaction is disabled.
  final bool disabled;
  
  /// True if a lighter tap haptic should be used, false for standard.
  final bool lightHaptic;
 
  /// Custom padding around the child, making the hit target larger
  final EdgeInsetsGeometry hitTestPadding;
 
  const AnimatedPressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.behavior,
    this.onTapDown,
    this.onTapUp,
    this.onTapCancel,
    this.scaleFactor = 0.97,
    this.opacityFactor = 1.0,
    this.hapticEnabled = true,
    this.disabled = false,
    this.lightHaptic = true,
    this.hitTestPadding = EdgeInsets.zero,
  });
 
  @override
  State<AnimatedPressable> createState() => _AnimatedPressableState();
}
 
class _AnimatedPressableState extends State<AnimatedPressable>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isDebouncing = false;
  
  // Critically damped spring simulation for instant, fluid 80ms response
  final SpringDescription _springDesc = const SpringDescription(
    mass: 1.0,
    stiffness: 700.0,
    damping: 35.0, // Critically damped
  );
 
  @override
  void initState() {
    super.initState();
    // 0 = released, 1 = fully pressed
    _controller = AnimationController(
      vsync: this,
      lowerBound: 0.0,
      upperBound: 1.0,
      value: 0.0,
    );
  }
 
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
 
  void _animateTo(double target) {
    if (!mounted) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = target;
      return;
    }
    final springSim = SpringSimulation(_springDesc, _controller.value, target, _controller.velocity);
    _controller.animateWith(springSim);
  }
 
  void _handleTapDown(TapDownDetails details) {
    if (widget.disabled) return;
    widget.onTapDown?.call(details);
    _animateTo(1.0);
  }
 
  void _handleTapUp(TapUpDetails details) {
    if (widget.disabled) return;
    widget.onTapUp?.call(details);
    
    if (_isDebouncing) {
      _animateTo(0.0);
      return;
    }
 
    if (widget.hapticEnabled) {
      if (widget.lightHaptic) {
        HapticEngine.lightTap();
      } else {
        HapticEngine.selection();
      }
    }
    
    _animateTo(0.0);
    
    _isDebouncing = true;
    widget.onTap?.call();
    
    // 300ms debounce to prevent accidental double taps
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _isDebouncing = false);
      }
    });
  }
 
  void _handleTapCancel() {
    if (widget.disabled) return;
    widget.onTapCancel?.call();
    _animateTo(0.0);
  }
 
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: widget.behavior ?? HitTestBehavior.opaque,
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onLongPress: widget.onLongPress != null ? () {
        if (widget.disabled) return;
        if (widget.hapticEnabled) HapticEngine.heavyImpact();
        widget.onLongPress?.call();
        _animateTo(0.0);
      } : null,
      child: Padding(
        padding: widget.hitTestPadding,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            // Map controller value (0 to 1) to scale and opacity
            final currentScale = 1.0 - ((1.0 - widget.scaleFactor) * _controller.value);
            final currentOpacity = 1.0 - ((1.0 - widget.opacityFactor) * _controller.value);
            
            return Transform.scale(
              scale: currentScale,
              alignment: Alignment.center,
              child: Opacity(
                opacity: currentOpacity,
                child: child,
              ),
            );
          },
          child: widget.child,
        ),
      ),
    );
  }
}
