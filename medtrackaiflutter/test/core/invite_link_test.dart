import 'package:flutter_test/flutter_test.dart';
import 'package:medai/core/utils/invite_link.dart';

/// The invite QR encoded the bare 6-character code, so a caregiver pointing
/// their phone's own camera at it saw the text "AB3K9P" and had no way to act
/// on it — and the caregiver is by definition someone who does not have the
/// app yet.
///
/// The encoder and the decoder used to live apart: the QR wrote one shape and
/// the scanner recovered it with `raw.split('code=').last`, which returns the
/// entire input unchanged for any payload lacking that substring. These pin
/// the round trip, which is the property that actually matters.
void main() {
  group('inviteJoinUrl', () {
    test('produces an openable link, not a bare code', () {
      final url = inviteJoinUrl('AB3K9P');

      expect(url.startsWith('https://'), isTrue);
      expect(url.contains('AB3K9P'), isTrue);
    });

    test('points at the domain that serves the App Links association', () {
      // public/.well-known/{assetlinks.json,apple-app-site-association} are
      // hosted here; a different host would open a web page instead.
      expect(inviteJoinUrl('AB3K9P').startsWith(kInviteHost), isTrue);
    });

    test('escapes the code rather than splicing it in raw', () {
      expect(inviteJoinUrl('A B/C').contains(' '), isFalse);
      expect(inviteJoinUrl('A B/C').contains('A%20B%2FC'), isTrue);
    });
  });

  group('parseInviteCode round-trips what inviteJoinUrl builds', () {
    test('the generated link decodes back to the original code', () {
      for (final code in ['AB3K9P', '000000', 'ZZZ999']) {
        expect(parseInviteCode(inviteJoinUrl(code)), code,
            reason: 'the QR the app writes must be readable by the scanner '
                'the app ships');
      }
    });
  });

  group('parseInviteCode accepts every shape a scanner can hand back', () {
    test('the query form', () {
      expect(parseInviteCode('https://medai.app/j?code=AB3K9P'), 'AB3K9P');
    });

    test('the path form LinkService also parses', () {
      // regression: split('code=') returned the whole URL for this shape, so
      // the "code" passed on was "https://medai.app/j/AB3K9P".
      expect(parseInviteCode('https://medai.app/j/AB3K9P'), 'AB3K9P');
      expect(parseInviteCode('https://medai.app/join/AB3K9P'), 'AB3K9P');
    });

    test('a bare code typed by hand', () {
      expect(parseInviteCode('AB3K9P'), 'AB3K9P');
      expect(parseInviteCode('  ab3k9p  '), 'AB3K9P');
    });

    test('an unrelated URL is not mistaken for a code', () {
      // The old parser returned this verbatim and the caller then tried to
      // redeem it, because it is longer than six characters.
      expect(parseInviteCode('https://example.com/hello'), isNull);
      expect(parseInviteCode('https://medai.app/privacy'), isNull);
    });

    test('empty input yields nothing', () {
      expect(parseInviteCode(''), isNull);
      expect(parseInviteCode('   '), isNull);
    });
  });
}
