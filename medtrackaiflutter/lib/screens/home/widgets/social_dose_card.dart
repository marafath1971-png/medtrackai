import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:io';

import '../../../providers/app_state.dart';
import '../../../theme/med_ai_ui.dart';
import '../../../core/utils/haptic_engine.dart';
import '../../../widgets/common/animated_pressable.dart';

class SocialDoseCard extends StatefulWidget {
  final Medicine med;
  final ScheduleEntry sched;
  final bool taken;
  final bool overdue;
  final bool isNext;
  final VoidCallback onTake;
  final VoidCallback onSnooze;
  final VoidCallback onTap;

  const SocialDoseCard({
    super.key,
    required this.med,
    required this.sched,
    required this.taken,
    required this.overdue,
    required this.isNext,
    required this.onTake,
    required this.onSnooze,
    required this.onTap,
  });

  @override
  State<SocialDoseCard> createState() => _SocialDoseCardState();
}

class _SocialDoseCardState extends State<SocialDoseCard> with SingleTickerProviderStateMixin {
  bool _showHeart = false;
  late AnimationController _heartCtrl;

  @override
  void initState() {
    super.initState();
    _heartCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          if (mounted) setState(() => _showHeart = false);
        }
      });
  }

  @override
  void dispose() {
    _heartCtrl.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    if (widget.taken) return;
    
    // Play TikTok/IG style heart animation
    HapticEngine.success();
    setState(() => _showHeart = true);
    _heartCtrl.forward(from: 0);

    // Give the animation a tiny bit of time before state updates (for visual effect)
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) widget.onTake();
    });
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final timeStr = '${widget.sched.h.toString().padLeft(2, '0')}:${widget.sched.m.toString().padLeft(2, '0')}';
    
    // Determine card background color/gradient
    Color bgColor = L.card;
    if (widget.taken) {
      bgColor = L.card.withValues(alpha: 0.6);
    } else if (widget.isNext) {
      bgColor = L.accent.withValues(alpha: 0.1);
    } else if (widget.overdue) {
      bgColor = L.error.withValues(alpha: 0.05);
    }

    return GestureDetector(
      onDoubleTap: _handleDoubleTap,
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: widget.isNext ? L.accent.withValues(alpha: 0.3) : L.border.withValues(alpha: 0.2),
            width: widget.isNext ? 1.5 : 1.0,
          ),
          boxShadow: AppShadows.soft,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background Visual (if photo exists, use it as a blurred immersive background)
            if (widget.med.imageUrl != null && widget.med.imageUrl!.isNotEmpty && File(widget.med.imageUrl!).existsSync())
              Positioned.fill(
                child: Opacity(
                  opacity: 0.15,
                  child: Image.file(
                    File(widget.med.imageUrl!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              
            // Gradient Overlay to ensure text readability
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      L.bg.withValues(alpha: 0.05),
                      L.bg.withValues(alpha: 0.6),
                    ],
                  ),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top Row: Time & Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: L.fill.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.schedule_rounded, size: 14, color: L.text),
                            const SizedBox(width: 6),
                            Text(
                              timeStr,
                              style: AppTypography.labelMedium.copyWith(
                                color: L.text,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.taken)
                        Icon(Icons.check_circle_rounded, color: Colors.green, size: 24)
                      else if (widget.isNext)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: L.accent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'UP NEXT',
                            style: AppTypography.labelSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        )
                      else if (widget.overdue)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: L.error,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'OVERDUE',
                            style: AppTypography.labelSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Main Content: Med Name & Details
                  Row(
                    children: [
                      // Large Icon/Avatar
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: L.fill.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: widget.med.imageUrl != null && widget.med.imageUrl!.isNotEmpty && File(widget.med.imageUrl!).existsSync()
                            ? ClipOval(
                                child: Image.file(
                                  File(widget.med.imageUrl!),
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Icon(
                                _getMedIcon(widget.med.form),
                                size: 32,
                                color: L.text,
                              ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.med.name,
                              style: AppTypography.headlineMedium.copyWith(
                                color: widget.taken ? L.sub : L.text,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${widget.med.dose} • ${widget.med.intakeInstructions}',
                              style: AppTypography.bodyMedium.copyWith(
                                color: L.text.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Bottom Row: Action Buttons
                  if (!widget.taken)
                    Row(
                      children: [
                        Expanded(
                          child: MedAiCTA(
                            label: 'Log Dose',
                            icon: Icons.check_rounded,
                            onTap: _handleDoubleTap,
                          ),
                        ),
                        const SizedBox(width: 12),
                        AnimatedPressable(
                          onTap: widget.onSnooze,
                          child: Container(
                            height: 54, // Matches MedAiCTA default height
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              color: L.fill.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(Icons.snooze_rounded, color: L.text),
                          ),
                        ),
                      ],
                    ),
                    
                  // "Double tap to log" hint
                  if (!widget.taken)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Center(
                        child: Text(
                          'Double tap to quickly log',
                          style: AppTypography.labelSmall.copyWith(
                            color: L.sub.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // IG Style Heart Animation Overlay
            if (_showHeart)
              Positioned.fill(
                child: Center(
                  child: Icon(
                    Icons.favorite_rounded,
                    color: Colors.redAccent,
                    size: 100,
                  )
                  .animate(controller: _heartCtrl)
                  .scale(begin: const Offset(0.5, 0.5), end: const Offset(1.2, 1.2), duration: 200.ms, curve: Curves.easeOutBack)
                  .then(delay: 200.ms)
                  .scale(begin: const Offset(1.2, 1.2), end: const Offset(0.0, 0.0), duration: 250.ms, curve: Curves.easeInBack)
                  .fadeOut(duration: 250.ms),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getMedIcon(String form) {
    switch (form.toLowerCase()) {
      case 'pill':
      case 'tablet':
      case 'capsule':
        return Icons.medication_rounded;
      case 'liquid':
      case 'syrup':
        return Icons.water_drop_rounded;
      case 'injection':
      case 'syringe':
        return Icons.vaccines_rounded;
      case 'inhaler':
        return Icons.air_rounded;
      case 'drops':
        return Icons.opacity_rounded;
      default:
        return Icons.health_and_safety_rounded;
    }
  }
}
