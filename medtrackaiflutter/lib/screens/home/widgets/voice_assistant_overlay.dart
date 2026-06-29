import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../providers/app_state.dart';
import '../../../core/utils/haptic_engine.dart';
import '../../../theme/med_ai_ui.dart';
import '../../../widgets/common/animated_pressable.dart';

class VoiceAssistantOverlay extends StatelessWidget {
  final VoidCallback? onDismiss;
  const VoiceAssistantOverlay({super.key, this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (!state.isVoiceActive) return const SizedBox.shrink();

    final L = context.L;
    final reduceMotion = MedAiA11y.reducedMotion(context);

    Widget backdrop = Positioned.fill(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: Colors.black.withValues(alpha: 0.6),
        ),
      ),
    );
    if (!reduceMotion) {
      backdrop = backdrop.animate().fadeIn(duration: AppDurations.fast);
    }

    Widget transcript = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Semantics(
        liveRegion: true,
        label: state.voiceTranscript,
        child: Text(
          state.voiceTranscript,
          textAlign: TextAlign.center,
          style: AppTypography.titleLarge.copyWith(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
    if (!reduceMotion) {
      transcript = transcript
          .animate()
          .slideY(begin: 0.2, duration: AppDurations.fast)
          .fadeIn();
    }

    return Stack(
      children: [
        backdrop,
        Positioned.fill(
          child: SafeArea(
            child: Column(
              children: [
                const Spacer(),
                _buildAnimatedMic(state, L, reduceMotion),
                const SizedBox(height: 48),
                transcript,
                const SizedBox(height: 16),
                if (state.voiceFeedback.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: Text(
                      state.voiceFeedback,
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyLarge.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                        height: 1.5,
                      ),
                    ),
                  ).maybeAnimate(reduceMotion),
                const Spacer(),
                Semantics(
                  button: true,
                  label: 'Close voice assistant',
                  child: AnimatedPressable(
                    onTap: () {
                      HapticEngine.selection();
                      state.closeVoiceAssistant();
                      onDismiss?.call();
                    },
                    child: Container(
                      width: MedAiA11y.minTapTarget,
                      height: MedAiA11y.minTapTarget,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded,
                          color: Colors.white, size: 28),
                    ),
                  ),
                ).maybeAnimate(reduceMotion, delay: 1.seconds),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedMic(
      AppState state, AppThemeColors L, bool reduceMotion) {
    IconData icon = Icons.mic_rounded;
    Color color = Colors.white;
    final isThinking = state.voiceStatus == 'thinking';
    final isSuccess = state.voiceStatus == 'success';
    final isError = state.voiceStatus == 'error';

    if (isThinking) icon = Icons.auto_awesome;
    if (isSuccess) {
      icon = Icons.check_circle_rounded;
      color = Colors.greenAccent;
    }
    if (isError) {
      icon = Icons.error_outline_rounded;
      color = Colors.redAccent;
    }

    Widget mic = Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 20,
            spreadRadius: 5,
          )
        ],
      ),
      child: Icon(icon, color: color, size: 48),
    );

    if (!reduceMotion) {
      mic = mic
          .animate(onPlay: (c) => isThinking ? c.repeat() : null)
          .shimmer(
              duration: isThinking ? 1.5.seconds : 0.ms,
              color: Colors.white12)
          .shake(hz: isError ? 4 : 0, duration: 400.ms)
          .scale(
              begin: const Offset(0.8, 0.8),
              end: const Offset(1, 1),
              duration: 400.ms,
              curve: Curves.elasticOut);
    }

    final rings = reduceMotion || state.voiceStatus != 'listening'
        ? const <Widget>[]
        : [1.0, 1.3, 1.6].map((scale) {
            return Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2), width: 2),
              ),
            )
                .animate(onPlay: (c) => c.repeat())
                .scale(
                    begin: const Offset(1, 1),
                    end: Offset(scale, scale),
                    duration: 2.seconds)
                .fadeOut(duration: 2.seconds);
          }).toList();

    return Stack(
      alignment: Alignment.center,
      children: [
        ...rings,
        mic,
      ],
    );
  }
}

extension on Widget {
  Widget maybeAnimate(bool reduceMotion, {Duration delay = Duration.zero}) {
    if (reduceMotion) return this;
    return animate(delay: delay).fadeIn();
  }
}
