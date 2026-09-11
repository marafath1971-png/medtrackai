import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../../core/utils/logger.dart';
import '../../l10n/app_localizations.dart';

class GlobalErrorBoundary extends StatefulWidget {
  final Widget child;

  const GlobalErrorBoundary({super.key, required this.child});

  @override
  State<GlobalErrorBoundary> createState() => _GlobalErrorBoundaryState();
}

class _GlobalErrorBoundaryState extends State<GlobalErrorBoundary> {
  bool _hasError = false;
  Object? _lastError;

  // Plain styles only — never GoogleFonts / AppTypography here.
  // Font loading failures in the recovery UI were painting a pure black screen.
  static const _titleStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: Colors.white,
    letterSpacing: -0.4,
    decoration: TextDecoration.none,
  );
  static const _bodyStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: Color(0xB3FFFFFF),
    height: 1.5,
    decoration: TextDecoration.none,
  );
  static const _metaStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: Color(0x66FFFFFF),
    decoration: TextDecoration.none,
  );

  @override
  void initState() {
    super.initState();

    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      try {
        FirebaseCrashlytics.instance.recordFlutterError(details);
      } catch (_) {/* crashlytics must never blank the UI */}
      if (originalOnError != null) originalOnError(details);
    };

    // Visible fallback — never SizedBox.shrink() (that is a black hole).
    ErrorWidget.builder = (FlutterErrorDetails details) {
      _handleError(details.exception, details.stack ?? StackTrace.current);
      return Material(
        color: const Color(0xFF12141C),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'This section failed to load.\nTap Resume on the recovery screen.',
                textAlign: TextAlign.center,
                style: _bodyStyle,
              ),
            ),
          ),
        ),
      );
    };
  }

  void _handleError(Object error, StackTrace stack) {
    appLogger.e('[GlobalErrorBoundary] Caught exception: $error',
        stackTrace: stack);
    try {
      // Non-fatal — leaf widget errors must not kill the whole session.
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: false);
    } catch (_) {}
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _hasError) return;
      setState(() {
        _hasError = true;
        _lastError = error;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        // The lookup MUST happen inside this MaterialApp.
        //
        // This boundary is mounted above MaterialApp in runApp(), so the
        // enclosing context has no Localizations and no Directionality
        // ancestor. Reading l10n there threw on null, ErrorWidget.builder took
        // over, and its fallback Text — also lacking Directionality — rendered
        // nothing: a pure black screen.
        //
        // Same failure the plain TextStyles above already guard against. The
        // recovery UI must depend on nothing that can itself fail.
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(builder: (context) {
          final l10n = AppLocalizations.of(context)!;
          return Scaffold(
            backgroundColor: const Color(0xFF12141C),
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SafeArea(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.sentiment_dissatisfied_rounded,
                        size: 64,
                        color: Colors.white70,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        l10n.commonSomethingWentWrong,
                        textAlign: TextAlign.center,
                        style: _titleStyle,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.commonWeVeHitATemporaryIssue,
                        textAlign: TextAlign.center,
                        style: _bodyStyle,
                      ),
                      const SizedBox(height: 48),
                      _ActionButton(
                        label: l10n.commonResumeSession,
                        onTap: () {
                          setState(() {
                            _hasError = false;
                            _lastError = null;
                          });
                        },
                        primary: true,
                      ),
                      const SizedBox(height: 16),
                      _ActionButton(
                        label: l10n.commonRestartApp,
                        onTap: () => SystemNavigator.pop(),
                        primary: false,
                      ),
                      if (_lastError != null) ...[
                        const SizedBox(height: 24),
                        Text(
                          _lastError.toString().split('\n').first,
                          style: _metaStyle,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      );
    }

    return widget.child;
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool primary;

  const _ActionButton({
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: primary ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: primary ? null : Border.all(color: Colors.white24),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: primary ? const Color(0xFF12141C) : Colors.white70,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }
}
