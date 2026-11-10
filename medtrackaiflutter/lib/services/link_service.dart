import 'dart:async';
import 'package:app_links/app_links.dart';
import '../core/utils/logger.dart';

/// Service to handle incoming App Links (Deep Links) for referrals and invites.
class LinkService {
  static final LinkService _instance = LinkService._internal();
  factory LinkService() => _instance;
  LinkService._internal();

  final _appLinks = AppLinks();
  StreamSubscription? _sub;

  /// Callback for when a join code is detected.
  Function(String)? onJoinCodeDetected;

  /// Callback for when a referral code is detected.
  Function(String)? onReferralDetected;

  /// Callback for when a voice command is triggered via deep link.
  Function()? onVoiceCommandDetected;

  /// `medai://steps` — the home-screen steps widget opens the app here.
  Function()? onStepsDetected;

  /// Initialize deep link listening.
  Future<void> init() async {
    // 1. Check for initial link (app opened via link from cold start)
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleUri(initialUri);
      }
    } catch (e) {
      appLogger.e('[LinkService] Failed to get initial app link: $e');
    }

    // 2. Listen for incoming links while app is in foreground/background
    _sub = _appLinks.uriLinkStream.listen(
      (uri) => _handleUri(uri),
      onError: (err) => appLogger.e('[LinkService] Link stream error: $err'),
    );
  }

  void handleUri(Uri uri) {
    appLogger.i('[LinkService] Received link: $uri');

    // Extract action whether URI is universal link (https://medai.app/join)
    // or custom scheme (medai://join or medai:///join).
    String action = '';
    List<String> segments = uri.pathSegments;

    if (uri.scheme == 'medai') {
      if (uri.host.isNotEmpty && uri.host != 'medai.app') {
        action = uri.host;
      } else if (segments.isNotEmpty) {
        action = segments.first;
      }
    } else if (segments.isNotEmpty) {
      action = segments.first;
    }

    if (action == 'steps') {
      onStepsDetected?.call();
    } else if (action == 'voice' || action == 'voice_log') {
      appLogger.i('[LinkService] Voice command detected from deep link');
      onVoiceCommandDetected?.call();
    } else if (action == 'j' || action == 'join') {
      String? code;
      if (uri.queryParameters.containsKey('code')) {
        code = uri.queryParameters['code'];
      } else if (segments.length >= 2) {
        code = segments[1];
      } else if (segments.length == 1 && action != segments.first) {
        code = segments.first;
      }

      if (code != null && code.isNotEmpty) {
        appLogger.i('[LinkService] Join code detected: $code');
        onJoinCodeDetected?.call(code);
      }
    } else if (action == 'r' || action == 'ref') {
      String? code;
      if (uri.queryParameters.containsKey('code')) {
        code = uri.queryParameters['code'];
      } else if (segments.length >= 2) {
        code = segments[1];
      } else if (segments.length == 1 && action != segments.first) {
        code = segments.first;
      }

      if (code != null && code.isNotEmpty) {
        appLogger.i('[LinkService] Referral code detected: $code');
        onReferralDetected?.call(code);
      }
    }
  }

  void _handleUri(Uri uri) => handleUri(uri);

  void dispose() {
    _sub?.cancel();
  }
}
