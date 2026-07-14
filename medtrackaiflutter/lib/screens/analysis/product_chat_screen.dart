import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/med_ai_ui.dart';
import '../../theme/ios_ui.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/common/premium_page_header.dart';
import '../../models/product_analysis.dart';
import '../../core/utils/haptic_engine.dart';
import '../../services/gemini_service.dart';
import '../../core/utils/result.dart';
import 'package:provider/provider.dart';
import '../../providers/controllers/medication_controller.dart';
import '../../providers/app_state.dart';

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}

class ProductChatScreen extends StatefulWidget {
  final ProductAnalysis product;

  const ProductChatScreen({super.key, required this.product});

  @override
  State<ProductChatScreen> createState() => _ProductChatScreenState();
}

class _ProductChatScreenState extends State<ProductChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;

  final List<String> _suggestions = [
    'Can I take this with coffee?',
    'Can I take this during Ramadan?',
    'Will this affect my kidneys?',
    'Can I take this with protein powder?',
  ];

  @override
  void initState() {
    super.initState();
    _messages.add(ChatMessage(
      text:
          "Hi! I'm your medical AI. Ask me anything about ${widget.product.name}.",
      isUser: false,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    HapticEngine.selection();
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isTyping = true;
    });
    _controller.clear();
    _scrollToBottom();

    final history = _messages.take(_messages.length - 1).map((m) => {
          'role': m.isUser ? 'User' : 'AI',
          'content': m.text,
        }).toList();

    final meds = context.read<MedicationController>().meds;
    final activeMedsStr = meds.isNotEmpty
        ? meds.map((m) => '${m.name} (${m.dose})').join(', ')
        : 'None';

    final appState = context.read<AppState>();
    final streak = appState.getStreak();

    final userContext =
        'Active Medications: $activeMedsStr. Current Adherence Streak: $streak days.';

    final result = await GeminiService.chatWithProduct(
      productName: widget.product.name,
      productDetails:
          'Category: ${widget.product.category}, Description: ${widget.product.description}, Timing: ${widget.product.timing}',
      query: text,
      chatHistory: history,
      userContext: userContext,
    );

    if (!mounted) return;

    setState(() {
      _isTyping = false;
      String response = "I'm sorry, I couldn't process that right now.";
      if (result is Success<String>) {
        response = result.value;
      }
      _messages.add(ChatMessage(text: response, isUser: false));
    });
    HapticEngine.light();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final duration = MedAiA11y.motion(context, const Duration(milliseconds: 300));
        if (duration == Duration.zero) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        } else {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: duration,
            curve: Curves.easeOut,
          );
        }
      }
    });
  }

  Widget _messageEntrance(Widget child, bool isUser) {
    if (MedAiA11y.reducedMotion(context)) return child;
    // Sent messages pop from the composer; received ones ease in — iOS feel.
    return child
        .animate()
        .fadeIn(duration: AppDurations.fast, curve: AppCurves.smooth)
        .slideY(begin: isUser ? 0.18 : 0.06, end: 0, curve: AppCurves.smooth);
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;

    return AppScaffold(
      showAurora: true,
      body: Column(
        children: [
          PremiumPageHeader(
            title: 'AI Assistant',
            subtitle: widget.product.name,
            onBack: () {
              HapticEngine.selection();
              Navigator.pop(context);
            },
          ),
          _contextBanner(L),
          Expanded(
            child: ListView.builder(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) {
                  return _buildTypingIndicator(L);
                }
                final msg = _messages[index];
                // Tighter grouping when the same sender speaks consecutively.
                final prevSame = index > 0 &&
                    _messages[index - 1].isUser == msg.isUser;
                return Padding(
                  padding: EdgeInsets.only(top: prevSame ? 3 : 10),
                  child: _messageEntrance(
                    Semantics(
                      label: msg.isUser ? 'You said' : 'AI assistant said',
                      child: IOSChatBubble(text: msg.text, isUser: msg.isUser),
                    ),
                    msg.isUser,
                  ),
                );
              },
            ),
          ),
          if (_messages.length == 1 && !_isTyping) _suggestionRow(L),
          IOSComposer(
            controller: _controller,
            autofocus: true,
            hintText: 'Ask about interactions, timing…',
            onSubmit: _sendMessage,
          ),
        ],
      ),
    );
  }

  Widget _contextBanner(AppThemeColors L) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: L.accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: L.accent.withValues(alpha: 0.18), width: 0.7),
        ),
        child: Row(
          children: [
            Icon(Icons.auto_awesome_rounded, color: L.accent, size: 15),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Personalised with context from your current medications.',
                style: AppTypography.labelSmall.copyWith(
                  color: L.sub,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _suggestionRow(AppThemeColors L) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) => _buildSuggestionChip(L, _suggestions[i]),
      ),
    );
  }

  Widget _buildTypingIndicator(AppThemeColors L) {
    final reduceMotion = MedAiA11y.reducedMotion(context);

    Widget indicator = Container(
      decoration: BoxDecoration(
        color: L.card,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(IOSMetrics.bubbleRadius),
          topRight: Radius.circular(IOSMetrics.bubbleRadius),
          bottomLeft: Radius.circular(4),
          bottomRight: Radius.circular(IOSMetrics.bubbleRadius),
        ),
        border: Border.all(color: L.border.withValues(alpha: 0.18), width: 0.7),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDot(L, 0, reduceMotion),
          const SizedBox(width: 4),
          _buildDot(L, 200, reduceMotion),
          const SizedBox(width: 4),
          _buildDot(L, 400, reduceMotion),
        ],
      ),
    );

    if (!reduceMotion) {
      indicator = indicator.animate().fadeIn(duration: AppDurations.fast);
    }

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Semantics(
          label: 'AI is typing',
          liveRegion: true,
          child: indicator,
        ),
      ),
    );
  }

  Widget _buildDot(AppThemeColors L, int delay, bool reduceMotion) {
    final dot = Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(color: L.sub, shape: BoxShape.circle),
    );
    if (reduceMotion) return dot;
    return dot
        .animate(onPlay: (c) => c.repeat())
        .fade(duration: 600.ms, delay: delay.ms)
        .scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1.2, 1.2),
          duration: 600.ms,
        );
  }

  Widget _buildSuggestionChip(AppThemeColors L, String text) {
    return Semantics(
      button: true,
      label: text,
      child: GestureDetector(
        onTap: () => _sendMessage(text),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: L.fill.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppRadius.max),
            border: Border.all(color: L.accent.withValues(alpha: 0.28), width: 0.7),
          ),
          child: Text(
            text,
            style: AppTypography.labelSmall.copyWith(
              color: L.text,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
