import 'health_facts.dart';

/// Guardrails and parsing for Ask Med AI that must not depend on the model.
///
/// Anything safety-relevant is decided here, in code, before or after the
/// model runs — never left to a prompt instruction the model may not follow.

final _citeRe = RegExp(r'\[(F\d+)\]');

/// The fact ids an answer cites, in first-mention order, limited to ids that
/// were actually supplied. A citation to a fact that does not exist is the
/// model inventing a source, so it is dropped rather than shown.
List<String> citedFactIds(String answer, Iterable<String> knownIds) {
  final known = knownIds.toSet();
  final out = <String>[];
  for (final m in _citeRe.allMatches(answer)) {
    final id = m.group(1)!;
    if (known.contains(id) && !out.contains(id)) out.add(id);
  }
  return out;
}

/// The answer with its inline "[F3]" markers removed, for display — the
/// cited facts are shown as chips underneath instead.
String stripCitations(String answer) => answer
    .replaceAll(_citeRe, '')
    .replaceAllMapped(RegExp(r' +([.,;:!?])'), (m) => m.group(1)!)
    .replaceAll(RegExp(r'[ \t]{2,}'), ' ')
    .trim();

const _emergencyTerms = [
  'chest pain',
  'can\'t breathe',
  'cant breathe',
  'cannot breathe',
  'trouble breathing',
  'difficulty breathing',
  'short of breath',
  'overdose',
  'overdosed',
  'took too many',
  'taken too many',
  'double dose',
  'took double',
  'fainted',
  'passed out',
  'unconscious',
  'seizure',
  'suicid',
  'kill myself',
  'end my life',
  'self harm',
  'self-harm',
  'swelling of my throat',
  'throat is swelling',
  'anaphyla',
  'stroke',
  'face drooping',
  'slurred speech',
];

/// Whether a question describes a possible emergency. Checked on the device
/// before anything is sent, so the emergency advice appears instantly and
/// never depends on the network or on the model following instructions.
bool isEmergencyQuestion(String q) {
  final t = q.toLowerCase();
  return _emergencyTerms.any(t.contains);
}

const emergencyReply =
    'This could be an emergency. Please call your local emergency number '
    'now, or your poison control centre if you may have taken too much of '
    'something. Don\'t wait for an app to answer this.';

/// The prompt for one question. Facts are the only source of truth; see
/// [buildHealthFacts] for how they are computed.
String buildAskPrompt({
  required List<HealthFact> facts,
  required List<(String, String)> conversation,
  required String question,
}) {
  final factLines = facts.map((f) => '[${f.id}] ${f.text}').join('\n');
  final convo = conversation.isEmpty
      ? '(none)'
      : conversation.map((m) => '${m.$1}: ${m.$2}').join('\n');
  return '''
Task: answer a question about the user's OWN medication record, using only the facts below.

FACTS (computed by the app from the user's logged data — the only source of truth):
$factLines

RULES:
1. Use only the FACTS. Quote their numbers exactly; do not calculate new numbers, estimate, or assume anything not stated.
2. After each sentence that uses a fact, cite it like [F2].
3. If the facts do not answer the question, say plainly what the record does not show, and suggest what they could log or who to ask.
4. Never advise starting, stopping, skipping, doubling, or re-timing a dose, and never judge whether a medicine is right for them. For those, say to ask their doctor or pharmacist.
5. Be warm and brief: at most 4 short sentences, plain text, no markdown, no lists.

EARLIER IN THIS CONVERSATION:
$convo

QUESTION: $question''';
}
