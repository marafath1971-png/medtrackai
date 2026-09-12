/// One definition of the caregiver-invite link, used by both ends.
///
/// The QR used to encode the bare 6-character code. That works for this app's
/// own scanner and for nothing else: pointing a phone's built-in camera at it
/// yields the text "AB3K9P" and no way to act on it. A caregiver being invited
/// does not have the app yet — that is the whole point of the invite — so the
/// code has to arrive as something their camera can open.
///
/// The query form is deliberate. `LinkService` parses `/j/<code>` and
/// `?code=<code>` alike, but the in-app scanner receives the raw payload and
/// has to recover the code from it, and a path segment is easy to mistake for
/// the code itself. Keeping the builder and the parser in one file is what
/// stops the two ends drifting apart.
library;

/// Domain that serves the App Links association files
/// (`public/.well-known/`), so this URL opens the app rather than a web page.
const String kInviteHost = 'https://medai.app';

/// The shareable, scannable link for [code].
String inviteJoinUrl(String code) =>
    '$kInviteHost/j?code=${Uri.encodeComponent(code.trim())}';

/// Recovers an invite code from whatever a scanner hands back.
///
/// Accepts the full link, either deep-link shape, or a bare code typed by
/// hand, and returns null when there is nothing usable. Previously the caller
/// did `raw.split('code=').last`, which returned the entire URL unchanged for
/// any payload without that exact substring — so a `/j/<code>` link scanned in
/// app would be passed on as the "code" and fail to redeem.
String? parseInviteCode(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;

  final uri = Uri.tryParse(trimmed);
  if (uri != null && uri.hasScheme) {
    final q = uri.queryParameters['code'];
    if (q != null && q.trim().isNotEmpty) return q.trim().toUpperCase();

    final segs = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segs.length >= 2 && (segs.first == 'j' || segs.first == 'join')) {
      return segs[1].trim().toUpperCase();
    }
    // A URL we do not recognise is not a code.
    return null;
  }

  return trimmed.toUpperCase();
}
