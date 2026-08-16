import 'package:flutter_test/flutter_test.dart';
import 'package:medai/services/gemini_service.dart';

/// The scan parser turns raw model output into the ScanResult that becomes a
/// medicine in someone's list. Models wrap JSON in markdown fences, add stray
/// comments, and prepend prose, so the cleaning step has to be forgiving —
/// without corrupting the payload it is cleaning.
void main() {
  group('cleanJsonPayload', () {
    test('strips markdown fences', () {
      expect(GeminiService.cleanJsonPayload('```json\n{"a":1}\n```'),
          '{"a":1}');
    });

    test('strips a line comment that would break json.decode', () {
      final cleaned =
          GeminiService.cleanJsonPayload('{"a":1, // note\n"b":2}');
      expect(cleaned, isNot(contains('// note')));
    });

    test('does NOT mangle URLs', () {
      // A plain replaceAll('//', '') turned https://nhs.uk into https:nhs.uk,
      // corrupting every link in AI-returned medical text.
      final cleaned = GeminiService.cleanJsonPayload(
          '{"description":"See https://nhs.uk/aspirin"}');
      expect(cleaned, contains('https://nhs.uk/aspirin'));
    });

    test('leaves ordinary JSON untouched', () {
      const src = '{"name":"Aspirin","dose":"75 mg"}';
      expect(GeminiService.cleanJsonPayload(src), src);
    });
  });

  group('parseScanResponse', () {
    test('parses a clean JSON response', () {
      final r = GeminiService.parseScanResponse(
          '{"name":"Aspirin","dose":"75 mg","identified":true}');
      expect(r.name, 'Aspirin');
      expect(r.dose, '75 mg');
      expect(r.identified, isTrue);
    });

    test('parses JSON wrapped in markdown fences', () {
      final r = GeminiService.parseScanResponse(
          '```json\n{"name":"Metformin","dose":"500 mg"}\n```');
      expect(r.name, 'Metformin');
    });

    test('ignores prose before and after the JSON block', () {
      final r = GeminiService.parseScanResponse(
          'Here is what I found:\n{"name":"Lisinopril"}\nHope that helps!');
      expect(r.name, 'Lisinopril');
    });

    test('preserves a URL in the parsed result', () {
      final r = GeminiService.parseScanResponse(
          '{"name":"Aspirin","description":"More at https://nhs.uk/aspirin"}');
      expect(r.description, contains('https://nhs.uk/aspirin'));
    });

    test('throws a FormatException when there is no JSON at all', () {
      expect(() => GeminiService.parseScanResponse('I could not identify this.'),
          throwsA(isA<FormatException>()));
    });

    test('throws a FormatException on malformed JSON rather than returning junk',
        () {
      expect(() => GeminiService.parseScanResponse('{"name":"Aspirin",}'),
          throwsA(isA<FormatException>()));
    });

    test('missing fields fall back to defaults instead of throwing', () {
      final r = GeminiService.parseScanResponse('{"name":"Aspirin"}');
      expect(r.name, 'Aspirin');
      expect(r.warnings, isA<String>());
      expect(r.interactions, isA<String>());
    });

    test('a warning containing a comma survives intact', () {
      final r = GeminiService.parseScanResponse(
          '{"name":"X","warnings":"Avoid alcohol, dairy, and grapefruit"}');
      expect(r.warnings, 'Avoid alcohol, dairy, and grapefruit');
    });
  });
}
