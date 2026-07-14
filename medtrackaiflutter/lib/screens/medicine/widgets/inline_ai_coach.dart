import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../theme/med_ai_ui.dart';
import '../../../../theme/ios_ui.dart';
import '../../../../widgets/common/animated_pressable.dart';
import '../../../../domain/entities/entities.dart';
import '../../../../services/gemini_service.dart';
import '../../../../core/utils/haptic_engine.dart';

class InlineAiCoach extends StatefulWidget {
  final Medicine medicine;
  final BodyImpactSummary? impact; // Can pass impact if available

  const InlineAiCoach({
    super.key,
    required this.medicine,
    this.impact,
  });

  static void show(BuildContext context, Medicine medicine, {BodyImpactSummary? impact}) {
    HapticEngine.selection();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => InlineAiCoach(medicine: medicine, impact: impact),
    );
  }

  @override
  State<InlineAiCoach> createState() => _InlineAiCoachState();
}

class _InlineAiCoachState extends State<InlineAiCoach> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _messages.add({
      'role': 'ai',
      'text': "Hi! I'm your MedAI Coach. What would you like to know about ${widget.medicine.name}?",
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    HapticEngine.light();

    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    // Fabricate a context payload based on current medicine
    final contextEntries = [
      HealthInsight(
        category: 'Medicine Info',
        title: widget.medicine.name,
        body: 'Dose: ${widget.medicine.dose}, Form: ${widget.medicine.form}, Category: ${widget.medicine.category}. '
            'Instructions: ${widget.medicine.intakeInstructions}',
      ),
      if (widget.impact != null)
        HealthInsight(
          category: 'Pharmacokinetics',
          title: 'Mechanism & Specs',
          body: 'Mechanism: ${widget.impact!.mechanismOfAction}. Peaks at ${widget.impact!.peakHours} hours. '
              'Affects ${widget.impact!.bodySystems.join(', ')}.',
        )
    ];

    final result = await GeminiService.askFollowUp(text, contextEntries);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.isSuccess) {
          _messages.add({'role': 'ai', 'text': result.data});
          HapticEngine.success();
        } else {
          _messages.add({'role': 'ai', 'text': "Sorry, I couldn't process that right now. Please try again."});
          HapticEngine.heavyImpact();
        }
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100,
          duration: MedAiA11y.motion(context, const Duration(milliseconds: 300)),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final reduceMotion = MedAiA11y.reducedMotion(context);
    // Suggest prompt chips
    final suggestions = widget.impact?.bodySystems.isNotEmpty == true
        ? [
            "How does it affect my ${widget.impact!.bodySystems.first}?",
            "Can I take this on an empty stomach?",
            "What if I miss a dose?"
          ]
        : [
            "What are common side effects?",
            "How long until it works?",
            "Can I drink coffee with this?"
          ];

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.squircle)),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: MedAiGlass(
          radius: AppRadius.squircle,
          padding: EdgeInsets.zero,
          showBorder: false,
          child: Column(
            children: [
              // iOS sheet grabber
              const Center(child: IOSGrabber()),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 12, 12),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: L.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(Icons.auto_awesome_rounded,
                          color: L.accent, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MedAI Coach',
                            style: AppTypography.titleMedium.copyWith(
                              color: L.text,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            widget.medicine.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.labelSmall.copyWith(
                              color: L.sub,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Semantics(
                      button: true,
                      label: 'Close',
                      child: AnimatedPressable(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 30,
                          height: 30,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: L.fill.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.close_rounded, color: L.sub, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const IOSHairline(),

              // Chat Area
              Expanded(
                child: ListView.builder(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  itemCount: _messages.length + (_isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length && _isLoading) {
                      return _buildTypingIndicator(L, reduceMotion);
                    }

                    final msg = _messages[index];
                    final isAI = msg['role'] == 'ai';
                    final prevSame = index > 0 &&
                        (_messages[index - 1]['role'] == 'ai') == isAI;

                    return Padding(
                      padding: EdgeInsets.only(top: prevSame ? 3 : 10),
                      child: _buildBubble(msg['text']!, isAI, reduceMotion),
                    );
                  },
                ),
              ),

              // Suggestion Chips
              if (_messages.length < 3 && !_isLoading)
                SizedBox(
                  height: 42,
                  child: ListView.separated(
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: suggestions.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final suggestion = suggestions[index];
                      return Semantics(
                        button: true,
                        label: suggestion,
                        child: AnimatedPressable(
                          onTap: () => _sendMessage(suggestion),
                          scaleFactor: 0.97,
                          child: Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 9),
                            decoration: BoxDecoration(
                              color: L.fill.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(AppRadius.max),
                              border: Border.all(
                                  color: L.accent.withValues(alpha: 0.28),
                                  width: 0.7),
                            ),
                            child: Text(
                              suggestion,
                              style: AppTypography.labelSmall.copyWith(
                                color: L.text,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

              // Input Area
              Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom),
                child: IOSComposer(
                  controller: _controller,
                  autofocus: true,
                  hintText: 'Ask a question…',
                  onSubmit: _sendMessage,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBubble(String text, bool isAI, bool reduceMotion) {
    Widget bubble = IOSChatBubble(text: text, isUser: !isAI);

    if (reduceMotion) return bubble;

    return bubble
        .animate()
        .fadeIn(duration: 260.ms)
        .slideY(begin: isAI ? 0.08 : 0.16, end: 0, curve: AppCurves.smooth);
  }

  Widget _buildTypingIndicator(AppThemeColors L, bool reduceMotion) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          decoration: BoxDecoration(
            color: L.card,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(IOSMetrics.bubbleRadius),
              topRight: Radius.circular(IOSMetrics.bubbleRadius),
              bottomLeft: Radius.circular(4),
              bottomRight: Radius.circular(IOSMetrics.bubbleRadius),
            ),
            border:
                Border.all(color: L.border.withValues(alpha: 0.18), width: 0.7),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Dot(delay: 0, color: L.sub, reduceMotion: reduceMotion),
              const SizedBox(width: 4),
              _Dot(delay: 200, color: L.sub, reduceMotion: reduceMotion),
              const SizedBox(width: 4),
              _Dot(delay: 400, color: L.sub, reduceMotion: reduceMotion),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final int delay;
  final Color color;
  final bool reduceMotion;

  const _Dot({required this.delay, required this.color, required this.reduceMotion});

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );

    if (reduceMotion) return dot;

    return dot
        .animate(onPlay: (c) => c.repeat())
        .fade(duration: 600.ms, delay: delay.ms)
        .then()
        .fade(duration: 600.ms, begin: 1.0, end: 0.0);
  }
}
