import 'package:flutter_test/flutter_test.dart';
import 'package:medai/core/utils/ask_med_ai.dart';
import 'package:medai/core/utils/health_facts.dart';

void main() {
  test('only citations to supplied facts are kept, once each, in order', () {
    expect(
      citedFactIds('You took 90% [F3]. Evenings slip [F5][F3]. See [F99].',
          ['F1', 'F3', 'F5']),
      ['F3', 'F5'],
    );
  });

  test('citation markers are removed for display', () {
    expect(stripCitations('You took 90% [F3]. Evenings slip [F5].'),
        'You took 90%. Evenings slip.');
  });

  test('emergencies are caught before anything is sent', () {
    expect(isEmergencyQuestion('I think I took too many of my pills'), isTrue);
    expect(isEmergencyQuestion('Having chest pain after my dose'), isTrue);
    expect(isEmergencyQuestion('Which dose do I miss most?'), isFalse);
  });

  test('the prompt carries every fact with its id and the question', () {
    final p = buildAskPrompt(
      facts: const [HealthFact('F1', 'Streak', 'Current streak: 4 days.')],
      conversation: const [('User', 'hi'), ('Assistant', 'hello')],
      question: 'How am I doing?',
    );
    expect(p, contains('[F1] Current streak: 4 days.'));
    expect(p, contains('QUESTION: How am I doing?'));
    expect(p, contains('User: hi'));
  });

  test('the prompt avoids phrases the AI proxy rejects as injection', () {
    // functions/index.js geminiProxy refuses prompts containing these.
    final p =
        buildAskPrompt(facts: const [], conversation: const [], question: 'q')
            .toLowerCase();
    for (final phrase in [
      'ignore previous',
      'forget all',
      'new instructions',
      'you are now',
      'as a different',
    ]) {
      expect(p, isNot(contains(phrase)), reason: phrase);
    }
  });
}
