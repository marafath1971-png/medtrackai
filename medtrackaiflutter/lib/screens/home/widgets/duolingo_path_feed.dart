import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;
import '../../../domain/entities/medicine.dart';
import '../../../providers/app_state.dart';
import '../../../theme/app_theme.dart';
import '../../../core/utils/haptic_engine.dart';
import '../../../services/smart_alert_service.dart';
import '../../medicine/medicine_detail_screen.dart';
import '../../../theme/med_ai_ui.dart';
import '../../../widgets/shared/shared_widgets.dart';

class DuolingoPathFeed extends StatelessWidget {
  final List<DoseItem> doses;
  final Map<String, bool> takenMap;
  final String? globalNextEntryKey;
  final AppState state;
  final DateTime selectedDate;
  final Function(Medicine) onView;
  final VoidCallback? onTakeDose;

  const DuolingoPathFeed({
    super.key,
    required this.doses,
    required this.takenMap,
    this.globalNextEntryKey,
    required this.state,
    required this.selectedDate,
    required this.onView,
    this.onTakeDose,
  });

  @override
  Widget build(BuildContext context) {
    if (doses.isEmpty) return const SliverToBoxAdapter(child: SizedBox());

    return SliverPadding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final d = doses[index];
            final isTaken = takenMap[d.key] == true;
            final isNext = d.key == globalNextEntryKey && !isTaken;
            final now = DateTime.now();
            final doseMins = d.sched.h * 60 + d.sched.m;
            final nowMins = now.hour * 60 + now.minute;
            final isOverdue = !isTaken && doseMins < nowMins;
            final isLocked = !isTaken && !isNext && !isOverdue; // Future doses

            // Calculate winding path offset
            // We use a sine wave to stagger the nodes left and right
            final offsetX = math.sin(index * 1.2) * 70.0;
            
            // Add a fun mascot occasionally
            final showMascot = index % 3 == 1;

            return SizedBox(
              height: 180, // Taller for spacing
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // The Path Line connecting nodes
                  if (index < doses.length - 1)
                    Positioned(
                      top: 90, // center of current node
                      bottom: -90, // center of next node
                      child: CustomPaint(
                        size: const Size(150, 180),
                        painter: _PathLinePainter(
                          startX: offsetX,
                          endX: math.sin((index + 1) * 1.2) * 70.0,
                          isCompleted: isTaken,
                          context: context,
                        ),
                      ),
                    ),

                  // Mascot decoration (if applicable)
                  if (showMascot)
                    Positioned(
                      left: offsetX > 0 ? 30 : null,
                      right: offsetX < 0 ? 30 : null,
                      bottom: 40,
                      child: Icon(
                        Icons.pets_rounded, // Stand-in for mascot
                        size: 48,
                        color: context.L.border.withValues(alpha: 0.3),
                      ),
                    ),

                  // The Dose Node
                  Positioned(
                    top: 20,
                    child: Transform.translate(
                      offset: Offset(offsetX, 0),
                      child: _DuolingoNode(
                        dose: d,
                        isTaken: isTaken,
                        isNext: isNext,
                        isOverdue: isOverdue,
                        isLocked: isLocked,
                        onTap: () {
                          if (isLocked) {
                            HapticEngine.selection();
                            SmartAlertService.show(
                              context,
                              title: 'Locked',
                              message: 'This dose is scheduled for later.',
                              type: AlertType.info,
                              icon: Icons.lock_clock_rounded,
                            );
                            return;
                          }
                          
                          HapticEngine.heavyImpact();
                          if (!isTaken) {
                            state.toggleDose(d, date: selectedDate);
                            onTakeDose?.call();
                            SmartAlertService.show(
                              context,
                              title: 'Awesome!',
                              message: 'You earned +10 XP for taking ${d.med.name}.',
                              type: AlertType.success,
                              icon: Icons.star_rounded,
                            );
                          } else {
                            onView(d.med);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          childCount: doses.length,
        ),
      ),
    );
  }
}

class _PathLinePainter extends CustomPainter {
  final double startX;
  final double endX;
  final bool isCompleted;
  final BuildContext context;

  _PathLinePainter({
    required this.startX,
    required this.endX,
    required this.isCompleted,
    required this.context,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isCompleted ? context.L.accent.withValues(alpha: 0.8) : context.L.border.withValues(alpha: 0.3)
      ..strokeWidth = 16 // Thicker line like duolingo
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(size.width / 2 + startX, 0);
    
    // Create a smooth bezier curve between the nodes
    path.cubicTo(
      size.width / 2 + startX, size.height / 2, 
      size.width / 2 + endX, size.height / 2, 
      size.width / 2 + endX, size.height,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PathLinePainter oldDelegate) {
    return oldDelegate.startX != startX || 
           oldDelegate.endX != endX || 
           oldDelegate.isCompleted != isCompleted;
  }
}

class _DuolingoNode extends StatelessWidget {
  final DoseItem dose;
  final bool isTaken;
  final bool isNext;
  final bool isOverdue;
  final bool isLocked;
  final VoidCallback onTap;

  const _DuolingoNode({
    required this.dose,
    required this.isTaken,
    required this.isNext,
    required this.isOverdue,
    required this.isLocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    
    Color nodeColor = L.accent; // Default vibrant color
    if (isTaken) nodeColor = Colors.amber.shade500; // Gold for complete
    if (isOverdue) nodeColor = L.error;
    if (isLocked) nodeColor = L.border.withValues(alpha: 0.6); // Gray for future
    
    // 3D Shadow calculation
    Color shadowColor = HSLColor.fromColor(nodeColor).withLightness(HSLColor.fromColor(nodeColor).lightness * 0.7).toColor();

    final icon = isTaken 
        ? Icons.check_rounded 
        : (isLocked ? Icons.lock_rounded : Icons.medication_rounded);

    final timeStr = '${dose.sched.h.toString().padLeft(2, '0')}:${dose.sched.m.toString().padLeft(2, '0')}';

    Widget node = GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // The floating label
          if (isNext || isOverdue)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppShadows.soft,
                border: Border.all(color: nodeColor.withValues(alpha: 0.3)),
              ),
              child: Text(
                isOverdue ? 'Overdue' : 'Take Now',
                style: AppTypography.labelMedium.copyWith(
                  color: nodeColor,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
             .moveY(begin: 0, end: -6, duration: 800.ms, curve: Curves.easeInOut),
             
          // The circular 3D button
          Container(
            width: 85,
            height: 85,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: nodeColor,
              boxShadow: [
                // The 3D drop shadow (lip)
                BoxShadow(
                  color: shadowColor,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: (dose.med.imageUrl != null && dose.med.imageUrl!.isNotEmpty && !isLocked)
                ? ClipOval(
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: MedImage(
                            imageUrl: dose.med.imageUrl,
                            fit: BoxFit.cover,
                            borderRadius: 0,
                          ),
                        ),
                        if (isTaken)
                          Positioned.fill(
                            child: Container(
                              color: Colors.black.withValues(alpha: 0.3),
                              child: Center(
                                child: Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 40,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  )
                : Center(
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
          ),
          
          const SizedBox(height: 16),
          
          // Time and Name
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppShadows.soft,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeStr,
                  style: AppTypography.labelSmall.copyWith(
                    color: L.sub,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  dose.med.name,
                  style: AppTypography.labelMedium.copyWith(
                    color: L.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    // Bouncing animation for current/next node
    if (isNext && !MedAiA11y.reducedMotion(context)) {
      node = node.animate(onPlay: (c) => c.repeat(reverse: true))
                 .scaleXY(begin: 1.0, end: 1.03, duration: 1.seconds, curve: Curves.easeInOut)
                 .shimmer(delay: 2.seconds, duration: 1.seconds, color: Colors.white30);
    }
    
    return node;
  }
}
