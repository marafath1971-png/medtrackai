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
                                ? Alignment.centerLeft
                                : Alignment.centerRight,
                            child: Semantics(
                              label: isAi ? 'AI response' : 'Your message',
                              child: MedAiGlass(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                radius: AppRadius.l,
                                tint: isAi ? L.card : L.text,
                                showBorder: isAi,
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
            child: MedAiGlass(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              radius: AppRadius.xl,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      onSubmitted: (_) => _sendMessage(),
                      style: AppTypography.bodyMedium.copyWith(
                          color: L.text,
                          fontSize: 14,
                          fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        hintText: 'Ask a question...',
                        hintStyle: AppTypography.bodyMedium.copyWith(
                            color: L.sub.withValues(alpha: 0.5), fontSize: 14),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                      ),
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: 'Send message',
                    child: AnimatedPressable(
                      onTap: _sendMessage,
                      child: Container(
                        width: MedAiA11y.minTapTarget,
                        height: MedAiA11y.minTapTarget,
                        alignment: Alignment.center,
                        child: Icon(Icons.send_rounded,
                            color: L.text, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
