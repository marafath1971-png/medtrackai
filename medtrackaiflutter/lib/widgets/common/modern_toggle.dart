import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../core/utils/haptic_engine.dart';

class ModernToggle extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? activeColor;

  const ModernToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
  });

  @override
  State<ModernToggle> createState() => _ModernToggleState();
}

class _ModernToggleState extends State<ModernToggle> {
  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return GestureDetector(
      onTap: () {
        HapticEngine.selection();
        widget.onChanged(!widget.value);
      },
      child: AnimatedContainer(
        duration: 300.ms,
        curve: Curves.easeOutQuart,
        width: 52,
        height: 30,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: widget.value ? L.text : L.card,
          border: Border.all(color: L.border.withValues(alpha: 0.1)),
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: 300.ms,
              curve: AppCurves.emilOut,
              alignment: widget.value
                  ? AlignmentDirectional.centerEnd
                  : AlignmentDirectional.centerStart,
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.value ? L.bg : L.text,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ).animate(target: widget.value ? 1 : 0).scale(
                    begin: const Offset(0.9, 0.9),
                    end: const Offset(1, 1),
                    curve: AppCurves.emilOut),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GlassToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const GlassToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: GestureDetector(
          onTap: () {
            HapticEngine.selection();
            onChanged(!value);
          },
          child: AnimatedContainer(
            duration: 400.ms,
            curve: Curves.easeOutQuart,
            width: 56,
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color: value ? L.text : L.card.withValues(alpha: 0.22),
              border: Border.all(
                  color: L.border.withValues(alpha: 0.2), width: 1.5),
            ),
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: 400.ms,
                  curve: Curves.easeOutQuart,
                  left: value ? 26 : 4,
                  top: 4,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: value
                          ? L.bg
                          : L.text.withValues(alpha: 0.9),
                      boxShadow: AppShadows.soft,
                    ),
                  ).animate(target: value ? 1 : 0).shimmer(
                      delay: 200.ms,
                      duration: 800.ms,
                      color: Colors.white.withValues(alpha: 0.1)),
                ),
              ],
            ),
          ),
        ),
    );
  }
}
