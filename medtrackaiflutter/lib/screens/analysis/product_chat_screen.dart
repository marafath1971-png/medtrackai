import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
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
    "Can I take this with coffee?",
    "Can I take this during Ramadan?",
    "Will this affect my kidneys?",
    "Can I take this with protein powder?",
  ];

  @override
  void initState() {
    super.initState();
    _messages.add(ChatMessage(
      text: "Hi! I'm your medical AI. Ask me anything about ${widget.product.name}.",
      isUser: false,
    ));
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

    // Prepare history
    final history = _messages.take(_messages.length - 1).map((m) => {
      'role': m.isUser ? 'User' : 'AI',
      'content': m.text,
    }).toList();

    // Extract User Context
    final meds = context.read<MedicationController>().meds;
    final activeMedsStr = meds.isNotEmpty 
        ? meds.map((m) => '${m.name} (${m.dose})').join(', ') 
        : 'None';
    
    final appState = context.read<AppState>();
    final streak = appState.getStreak();
    
    final userContext = "Active Medications: $activeMedsStr. Current Adherence Streak: $streak days.";

    // Call Gemini
    final result = await GeminiService.chatWithProduct(
      productName: widget.product.name,
      productDetails: "Category: ${widget.product.category}, Description: ${widget.product.description}, Timing: ${widget.product.timing}",
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
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;

    return Scaffold(
      backgroundColor: L.bg,
      appBar: AppBar(
        backgroundColor: L.bg.withValues(alpha: 0.8),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(color: Colors.transparent),
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: L.text, size: 20),
          onPressed: () {
            HapticEngine.selection();
            Navigator.pop(context);
          },
        ),
        title: Column(
          children: [
            Text(
              'AI Assistant',
              style: AppTypography.titleMedium.copyWith(
                color: L.text,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              widget.product.name,
              style: AppTypography.labelSmall.copyWith(
                color: L.sub,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        margin: const EdgeInsets.only(bottom: 24),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: msg.isUser 
              ? L.text 
              : L.card.withValues(alpha: 0.6),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(24),
            topRight: const Radius.circular(24),
            bottomLeft: Radius.circular(msg.isUser ? 24 : 8),
            bottomRight: Radius.circular(msg.isUser ? 8 : 24),
          ),
          border: Border.all(
            color: msg.isUser 
                ? Colors.transparent 
                : L.accent.withValues(alpha: 0.4),
            width: msg.isUser ? 0 : 1.2,
          ),
          boxShadow: msg.isUser 
              ? [BoxShadow(color: L.text.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 4))]
              : AppShadows.glow(L.accent, intensity: 0.1),
        ),
        child: Text(
          msg.text,
          style: AppTypography.bodyMedium.copyWith(
            color: msg.isUser ? L.bg : L.text,
            height: 1.6,
            fontWeight: msg.isUser ? FontWeight.w500 : FontWeight.w400,
          ),
        ),
      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutBack),
    );
  }

  Widget _buildTypingIndicator(AppThemeColors L) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: L.card,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
            bottomLeft: Radius.circular(8),
            bottomRight: Radius.circular(24),
          ),
          border: Border.all(color: L.border),
          boxShadow: L.shadowSoft,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDot(L, 0),
            const SizedBox(width: 4),
            _buildDot(L, 200),
            const SizedBox(width: 4),
            _buildDot(L, 400),
          ],
        ),
      ).animate().fadeIn(duration: 300.ms),
    );
  }

  Widget _buildDot(AppThemeColors L, int delay) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: L.sub,
        shape: BoxShape.circle,
      ),
    ).animate(onPlay: (c) => c.repeat()).fade(duration: 600.ms, delay: delay.ms).scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 600.ms);
  }

  Widget _buildInputArea(AppThemeColors L) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: L.bg.withValues(alpha: 0.8),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_messages.length == 1) // Only show suggestions at the start
                SingleChildScrollView(
  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: _suggestions.map((s) => _buildSuggestionChip(L, s)).toList(),
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        color: L.card.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: L.glassBorder, width: 1.2),
                        boxShadow: AppShadows.subtle,
                      ),
                      child: TextField(
  autofocus: true,
                        controller: _controller,
                        style: AppTypography.bodyMedium.copyWith(color: L.text),
                        decoration: InputDecoration(
                          hintText: "Ask AI a question...",
                          hintStyle: AppTypography.bodyMedium.copyWith(color: L.text.withValues(alpha: 0.4)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 18),
                        ),
                        onSubmitted: _sendMessage,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  BouncingButton(
                    onTap: () => _sendMessage(_controller.text),
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [L.text, L.text.withValues(alpha: 0.8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: AppShadows.glow(L.text, intensity: 0.3),
                      ),
                      child: Icon(Icons.arrow_upward_rounded, color: L.bg, size: 24),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(AppThemeColors L, String text) {
    return AnimatedPressable(
      onTap: () => _sendMessage(text),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: L.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: L.border),
        ),
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
