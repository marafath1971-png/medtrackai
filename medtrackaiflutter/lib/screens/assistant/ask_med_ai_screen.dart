import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/ask_med_ai.dart';
import '../../core/utils/haptic_engine.dart';
import '../../core/utils/health_facts.dart';
import '../../providers/app_state.dart';
import '../../services/gemini_service.dart';
import '../../services/remote_config_service.dart';
import '../../theme/ios_ui.dart';
import '../../theme/med_ai_ui.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/common/premium_page_header.dart';
import '../paywall/premium_paywall_overlay.dart';

class _Msg {
  final String text;
  final bool isUser;
  final List<HealthFact> sources;
  final bool isError;
  const _Msg(this.text,
      {required this.isUser, this.sources = const [], this.isError = false});
}

/// Ask Med AI — questions about your own medication record, answered from
/// facts computed on the device and shown as sources under each reply.
///
/// What a general chatbot cannot do: it has never seen your dose history.
/// What this deliberately does not do: advise dose changes (see the prompt
/// rules in buildAskPrompt) or answer emergencies (caught on the device
/// before anything is sent — see isEmergencyQuestion).
class AskMedAiScreen extends StatefulWidget {
  const AskMedAiScreen({super.key});

  @override
  State<AskMedAiScreen> createState() => _AskMedAiScreenState();
}

class _AskMedAiScreenState extends State<AskMedAiScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final List<_Msg> _messages = [];
  bool _thinking = false;

  static const _suggestions = [
    'How am I doing this month?',
    'Which dose do I miss most?',
    'When will I run out?',
    'What\'s left for today?',
  ];

  @override
  void initState() {
    super.initState();
    _messages.add(const _Msg(
      'Ask me about your own medicines — how consistent you\'ve been, which '
      'doses slip, what\'s left today, when you\'ll run out. Every answer '
      'shows the facts from your record it used.',
      isUser: false,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  List<HealthFact> _facts(AppState s) => buildHealthFacts(
        meds: s.activeMeds,
        history: s.history,
        symptoms: s.symptoms,
        streak: s.getStreak(),
        now: DateTime.now(),
      );

  static String _quotaKey() {
    final d = DateTime.now();
    return 'ask_ai_${d.year}-${d.month}-${d.day}';
  }

  Future<int> _usedToday() async {
    try {
      final p = await SharedPreferences.getInstance();
      return p.getInt(_quotaKey()) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> _countQuestion() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setInt(_quotaKey(), (p.getInt(_quotaKey()) ?? 0) + 1);
    } catch (_) {/* a missed count never blocks an answer */}
  }

  Future<void> _send(String raw) async {
    final q = raw.trim();
    if (q.isEmpty || _thinking) return;
    final state = context.read<AppState>();
    HapticEngine.selection();

    // Emergencies are answered here, instantly, and never sent anywhere.
    if (isEmergencyQuestion(q)) {
      _controller.clear();
      setState(() {
        _messages.add(_Msg(q, isUser: true));
        _messages.add(const _Msg(emergencyReply, isUser: false, isError: true));
      });
      HapticEngine.alertWarning();
      _toBottom();
      return;
    }

    if (!state.isPremium &&
        await _usedToday() >= RemoteConfigService.freeTierAskAiDaily) {
      if (!mounted) return;
      await PremiumPaywallOverlay.show(context, triggerSource: 'ask_ai');
      return;
    }
    if (!mounted) return;

    final facts = _facts(state);
    final convo = _messages
        .skip(1) // the greeting
        .where((m) => !m.isError)
        .map((m) => (m.isUser ? 'User' : 'Assistant', m.text))
        .toList();
    final recent = convo.length > 6 ? convo.sublist(convo.length - 6) : convo;

    _controller.clear();
    setState(() {
      _messages.add(_Msg(q, isUser: true));
      _thinking = true;
    });
    _toBottom();

    final result = await GeminiService.askAboutMyRecord(
      buildAskPrompt(facts: facts, conversation: recent, question: q),
    );
    if (!mounted) return;

    final byId = {for (final f in facts) f.id: f};
    setState(() {
      _thinking = false;
      _messages.add(result.fold(
        (value) => _Msg(
          stripCitations(value),
          isUser: false,
          sources: [for (final id in citedFactIds(value, byId.keys)) byId[id]!],
        ),
        (failure) => _Msg(failure.message, isUser: false, isError: true),
      ));
    });
    if (result.isSuccess) {
      await _countQuestion();
      HapticEngine.light();
    }
    _toBottom();
  }

  void _toBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final d = MedAiA11y.motion(context, const Duration(milliseconds: 300));
      if (d == Duration.zero) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      } else {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: d, curve: Curves.easeOut);
      }
    });
  }

  void _showAllFacts() {
    HapticEngine.selection();
    final facts = _facts(context.read<AppState>());
    _FactsSheet.show(context,
        title: 'What Med AI can see',
        intro: 'These facts are worked out on your phone from what you\'ve '
            'logged. Only these are sent with your question.',
        facts: facts);
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return AppScaffold(
      showAurora: true,
      body: Column(
        children: [
          PremiumPageHeader(
            title: 'Ask Med AI',
            subtitle: 'Answers from your own record',
            onBack: () {
              HapticEngine.selection();
              Navigator.pop(context);
            },
          ),
          _banner(L),
          Expanded(
            child: ListView.builder(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              itemCount: _messages.length + (_thinking ? 1 : 0),
              itemBuilder: (context, i) {
                if (i == _messages.length) return _typing(L);
                final m = _messages[i];
                final prevSame = i > 0 && _messages[i - 1].isUser == m.isUser;
                Widget bubble = Semantics(
                  label: m.isUser ? 'You asked' : 'Med AI answered',
                  child: IOSChatBubble(text: m.text, isUser: m.isUser),
                );
                if (!MedAiA11y.reducedMotion(context)) {
                  bubble = bubble
                      .animate()
                      .fadeIn(duration: AppDurations.fast)
                      .slideY(begin: m.isUser ? 0.18 : 0.06, end: 0);
                }
                return Padding(
                  padding: EdgeInsets.only(top: prevSame ? 3 : 10),
                  child: Column(
                    crossAxisAlignment: m.isUser
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      bubble,
                      if (m.sources.isNotEmpty) _sources(L, m.sources),
                    ],
                  ),
                );
              },
            ),
          ),
          if (_messages.length == 1 && !_thinking) _suggestionRow(L),
          IOSComposer(
            controller: _controller,
            hintText: 'Ask about your medicines…',
            enabled: !_thinking,
            onSubmit: _send,
          ),
        ],
      ),
    );
  }

  Widget _banner(AppThemeColors L) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
      child: Semantics(
        button: true,
        label: 'See what Med AI can see',
        child: GestureDetector(
          onTap: _showAllFacts,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: L.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: L.accent.withValues(alpha: 0.18), width: 0.7),
            ),
            child: Row(
              children: [
                Icon(Icons.fact_check_rounded, color: L.accent, size: 15),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Answers use only your logged data. Not medical advice — '
                    'ask your doctor or pharmacist before changing anything.',
                    style: AppTypography.labelSmall.copyWith(
                      color: L.sub,
                      height: 1.3,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text('See data',
                    style: AppTypography.labelSmall.copyWith(
                        color: L.accent, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sources(AppThemeColors L, List<HealthFact> sources) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 4),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('Based on',
              style: AppTypography.labelSmall
                  .copyWith(color: L.sub, fontSize: 11)),
          for (final f in sources)
            Semantics(
              button: true,
              label: 'Source: ${f.text}',
              child: GestureDetector(
                onTap: () {
                  HapticEngine.selection();
                  _FactsSheet.show(context,
                      title: f.label, intro: null, facts: [f]);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: L.fill,
                    borderRadius: BorderRadius.circular(AppRadius.max),
                    border: Border.all(
                        color: L.border.withValues(alpha: 0.4), width: 0.7),
                  ),
                  child: Text(
                    f.label,
                    style: AppTypography.labelSmall.copyWith(
                      color: L.text,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _suggestionRow(AppThemeColors L) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) => Semantics(
          button: true,
          label: _suggestions[i],
          child: GestureDetector(
            onTap: () => _send(_suggestions[i]),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: L.fill.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppRadius.max),
                border: Border.all(
                    color: L.accent.withValues(alpha: 0.28), width: 0.7),
              ),
              child: Text(
                _suggestions[i],
                style: AppTypography.labelSmall.copyWith(
                  color: L.text,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _typing(AppThemeColors L) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Semantics(
          label: 'Med AI is thinking',
          liveRegion: true,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: L.card,
              borderRadius: BorderRadius.circular(IOSMetrics.bubbleRadius),
              border: Border.all(
                  color: L.border.withValues(alpha: 0.18), width: 0.7),
            ),
            child: Text('Checking your record…',
                style: AppTypography.labelSmall.copyWith(color: L.sub)),
          ),
        ),
      ),
    );
  }
}

class _FactsSheet extends StatelessWidget {
  final String title;
  final String? intro;
  final List<HealthFact> facts;
  const _FactsSheet(
      {required this.title, required this.intro, required this.facts});

  static Future<void> show(BuildContext context,
      {required String title,
      required String? intro,
      required List<HealthFact> facts}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FactsSheet(title: title, intro: intro, facts: facts),
    );
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Container(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.75),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: BoxDecoration(
        color: L.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: L.border.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(title,
                style: AppTypography.titleLarge
                    .copyWith(color: L.text, fontWeight: FontWeight.w700)),
            if (intro != null) ...[
              const SizedBox(height: 8),
              Text(intro!,
                  style: AppTypography.bodySmall
                      .copyWith(color: L.sub, height: 1.4)),
            ],
            const SizedBox(height: 16),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: facts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => Text(
                  facts[i].text,
                  style: AppTypography.bodyMedium
                      .copyWith(color: L.text, height: 1.4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
