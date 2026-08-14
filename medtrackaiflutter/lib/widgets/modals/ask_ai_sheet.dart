import 'package:flutter/material.dart';
import '../../theme/med_ai_ui.dart';
import '../../services/gemini_service.dart';
import '../../domain/entities/entities.dart';
import '../../core/utils/haptic_engine.dart';
import '../common/app_loading_indicator.dart';
import '../common/refined_sheet_wrapper.dart';
import '../common/animated_pressable.dart';

class AskAiSheet extends StatefulWidget {
  final List<HealthInsight> contextInsights;

  const AskAiSheet({super.key, required this.contextInsights});

  @override
  State<AskAiSheet> createState() => _AskAiSheetState();
}

class _AskAiSheetState extends State<AskAiSheet> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    HapticEngine.selection();
    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _isLoading = true;
      _controller.clear();
    });

    final result =
        await GeminiService.askFollowUp(text, widget.contextInsights);

    if (mounted) {
      setState(() {
        _isLoading = false;
        result.fold(
          (success) => _messages.add({'role': 'ai', 'content': success}),
          (error) => _messages.add({'role': 'ai', 'content': error.message}),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;

    return RefinedSheetWrapper(
      title: 'AI Health Coach',
      icon: Semantics(
        label: 'AI coach icon',
        child: Container(
          width: MedAiA11y.minTapTarget,
          height: MedAiA11y.minTapTarget,
          decoration: BoxDecoration(
            color: L.accent.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: L.accent.withValues(alpha: 0.25)),
          ),
          child: Icon(Icons.auto_awesome_rounded, color: L.accent, size: 20),
        ),
      ),
      scrollable: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: _messages.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 48, horizontal: 32),
                        child: Text(
                          'Ask me anything about your current health insights or medications.',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySmall.copyWith(
                              color: L.sub,
                              fontSize: 13,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    )
                  : ListView.builder(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        final isAi = msg['role'] == 'ai';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Align(
                            alignment: isAi
                                ? AlignmentDirectional.centerStart
                                : AlignmentDirectional.centerEnd,
                            child: Semantics(
                              label: isAi ? 'AI response' : 'Your message',
                              // Solid for the user bubble: MedAiGlass drops
                              // its tint in light mode, so L.bg text on the
                              // intended dark fill came out cream-on-white.
                              child: _ChatBubble(
                                isAi: isAi,
                                child: Text(
                                  msg['content']!,
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: isAi ? L.text : L.bg,
                                    fontSize: 14,
                                    fontWeight: isAi
                                        ? FontWeight.w600
                                        : FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.only(bottom: 16, top: 8),
              child: Semantics(
                liveRegion: true,
                label: 'Coach is thinking',
                child: Row(
                  children: [
                    const AppLoadingIndicator(size: 14),
                    const SizedBox(width: 8),
                    Text('Coach is thinking…',
                        style: AppTypography.labelLarge.copyWith(
                            color: L.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          Semantics(
            label: 'Ask a question',
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: MedAiTextField(
                    controller: _controller,
                    autofocus: true,
                    onSubmitted: (_) => _sendMessage(),
                    hintText: 'Ask a question...',
                  ),
                ),
                const SizedBox(width: 8),
                Semantics(
                  button: true,
                  label: 'Send message',
                  child: AnimatedPressable(
                    onTap: _sendMessage,
                    child: Container(
                      width: MedAiA11y.minTapTarget,
                      height: MedAiA11y.minTapTarget,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.lime,
                        borderRadius: BorderRadius.circular(AppInputs.radius),
                      ),
                      child: Icon(Icons.send_rounded,
                          color: AppColors.limeInk, size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

/// Chat bubble surface.
///
/// The AI bubble keeps the frosted [MedAiGlass] look. The user bubble must be
/// solid: MedAiGlass ignores `tint` in light mode and always paints `L.card`,
/// so the intended dark fill never appeared while the text still flipped to
/// `L.bg` — the user's own messages rendered cream-on-white.
class _ChatBubble extends StatelessWidget {
  final bool isAi;
  final Widget child;

  const _ChatBubble({required this.isAi, required this.child});

  @override
  Widget build(BuildContext context) {
    const padding = EdgeInsets.symmetric(horizontal: 16, vertical: 12);

    if (isAi) {
      return MedAiGlass(
        padding: padding,
        radius: AppRadius.l,
        tint: context.L.card,
        child: child,
      );
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: context.L.text,
        borderRadius: BorderRadius.circular(AppRadius.l),
        boxShadow: AppShadows.soft,
      ),
      child: child,
    );
  }
}
