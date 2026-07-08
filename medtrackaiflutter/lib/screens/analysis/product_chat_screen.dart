import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/med_ai_ui.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/common/premium_page_header.dart';
import '../../models/product_analysis.dart';
import '../../core/utils/haptic_engine.dart';
import '../../widgets/shared/shared_widgets.dart';
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

  Widget _messageEntrance(Widget child) {
    if (MedAiA11y.reducedMotion(context)) return child;
    return child
        .animate()
        .fadeIn(duration: AppDurations.fast, curve: AppCurves.smooth)
        .slideY(begin: 0.06, end: 0, curve: AppCurves.smooth);
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
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 2, 20, 8),
            child: MedAiGlass(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              radius: AppRadius.l,
              tint: L.card,
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: L.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.auto_awesome_rounded, color: L.accent, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Smart medication guidance with context from your current regimen.',
                      style: AppTypography.labelSmall.copyWith(
                        color: L.sub,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) {
                  return _buildTypingIndicator(L);
                }
                final msg = _messages[index];
                return _buildMessageBubble(L, msg);
              },
            ),
          ),
          _buildInputArea(L),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(AppThemeColors L, ChatMessage msg) {
    final maxW = MediaQuery.of(context).size.width * 0.8;
    final aiBubble = MedAiGlass(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      radius: AppRadius.xl,
      tint: L.card,
      child: Text(
        msg.text,
        style: AppTypography.bodyMedium.copyWith(
          color: L.text,
          height: 1.6,
        ),
      ),
    );
    final userBubble = MedAiDepthCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      radius: AppRadius.xl,
      color: L.text,
      child: Text(
        msg.text,
        style: AppTypography.bodyMedium.copyWith(
          color: L.bg,
          height: 1.6,
          fontWeight: FontWeight.w500,
        ),
      ),
    );

    return _messageEntrance(
      Align(
        alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Semantics(
          label: msg.isUser ? 'You said' : 'AI assistant said',
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxW),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (!msg.isUser) ...[
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: L.accent.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.smart_toy_rounded, color: L.accent, size: 15),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Flexible(child: msg.isUser ? userBubble : aiBubble),
                  if (msg.isUser) ...[
                    const SizedBox(width: 8),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: L.text.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.person_rounded, color: L.text, size: 14),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator(AppThemeColors L) {
    final reduceMotion = MedAiA11y.reducedMotion(context);

    Widget indicator = MedAiGlass(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      radius: AppRadius.xl,
      tint: L.card,
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

    return Align(
      alignment: Alignment.centerLeft,
      child: Semantics(
        label: 'AI is typing',
        liveRegion: true,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: indicator,
        ),
      ),
    );
  }

  Widget _buildDot(AppThemeColors L, int delay, bool reduceMotion) {
    final dot = Container(
      width: 6,
      height: 6,
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

  Widget _buildInputArea(AppThemeColors L) {
    return MedAiGlass(
      radius: 0,
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      showBorder: false,
      tint: L.bg,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_messages.length == 1)
            SingleChildScrollView(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children:
                    _suggestions.map((s) => _buildSuggestionChip(L, s)).toList(),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: MedAiDepthCard(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  radius: 22,
                  child: TextField(
                    autofocus: true,
                    controller: _controller,
                    style: AppTypography.bodyMedium.copyWith(color: L.text),
                    decoration: InputDecoration(
                      hintText: 'Ask about interactions, timing, organs...',
                      hintStyle: AppTypography.bodyMedium
                          .copyWith(color: L.sub.withValues(alpha: 0.6)),
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Semantics(
                button: true,
                label: 'Send message',
                child: AnimatedPressable(
                  onTap: () => _sendMessage(_controller.text),
                  child: Container(
                    width: MedAiA11y.minTapTarget,
                    height: MedAiA11y.minTapTarget,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [L.text, L.text.withValues(alpha: 0.88)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: AppShadows.glow(L.text, intensity: 0.25),
                    ),
                    child: Icon(Icons.arrow_upward_rounded,
                        color: L.bg, size: 22),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(AppThemeColors L, String text) {
    return Semantics(
      button: true,
      label: text,
      child: MedAiDepthCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        radius: AppRadius.max,
        onTap: () => _sendMessage(text),
        child: Text(
          text,
          style: AppTypography.labelSmall.copyWith(
            color: L.text,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
