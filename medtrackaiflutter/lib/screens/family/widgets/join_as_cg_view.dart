import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../providers/app_state.dart';
import '../../../theme/med_ai_ui.dart';
import '../../../widgets/common/app_scaffold.dart';
import '../../../widgets/common/animated_pressable.dart';
import '../../../core/utils/haptic_engine.dart';

class JoinAsCaregiverView extends StatefulWidget {
  final AppState state;
  final AppThemeColors L;
  final VoidCallback onBack;
  final Function(Caregiver) onJoined;
  const JoinAsCaregiverView(
      {super.key,
      required this.state,
      required this.L,
      required this.onBack,
      required this.onJoined});

  @override
  State<JoinAsCaregiverView> createState() => _JoinAsCaregiverViewState();

  /// Turns a [SocialController.joinCaregiver] failure into something the user
  /// can act on.
  ///
  /// The previous mapping only matched 'Invalid' and 'your own', so the
  /// "Sign in required" case — the most common one, since joining needs an
  /// authenticated account — fell through to "Connection error" and sent
  /// people to check their network instead of signing in.
  @visibleForTesting
  static String messageForError(Object e) {
    final msg = e.toString();
    if (msg.contains('Sign in required')) {
      return 'Sign in to join a care circle';
    }
    if (msg.contains('your own')) {
      return 'You cannot monitor yourself';
    }
    if (msg.contains('Invalid')) {
      return 'Invalid code — check it and try again';
    }
    return 'Could not join. Check your connection and try again.';
  }

}

class _JoinAsCaregiverViewState extends State<JoinAsCaregiverView> {
  final _codeCtrl = TextEditingController();
  final _scannerCtrl = MobileScannerController();
  bool _isChecking = false;
  String? _error;

  @override
  void dispose() {
    _codeCtrl.dispose();
    _scannerCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkCode(String code) async {
    final trimmed = code.trim();
    if (trimmed.length < 6) {
      setState(() => _error = 'Enter the full 6+ character invite code');
      return;
    }
    setState(() {
      _isChecking = true;
      _error = null;
    });

    try {
      await widget.state.joinCareTeam(trimmed);
      if (!mounted) return;
      final patients = widget.state.monitoredPatients;
      final patient = patients.isNotEmpty
          ? patients.last
          : <String, dynamic>{'name': 'Member', 'relation': 'Family'};
      widget.onJoined(Caregiver(
        id: patient['cgId'] as int? ?? 0,
        name: patient['name'] as String? ?? 'Member',
        relation: patient['relation'] as String? ?? 'Family',
        patientUid: patient['uid'] as String? ?? '',
        addedAt: patient['addedAt'] as String? ?? '',
        avatar: patient['avatar'] as String? ?? '👤',
        status: 'active',
      ));
      widget.state.showToast('Connected to ${patient['name'] ?? 'member'}');
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = JoinAsCaregiverView.messageForError(e));
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final L = widget.L;
    return AppScaffold(
        showAurora: context.isDark,
        body: SafeArea(
            child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.p20),
            child: Row(children: [
              Semantics(
                button: true,
                label: 'Close',
                child: AnimatedPressable(
                  onTap: () {
                    HapticEngine.selection();
                    widget.onBack();
                  },
                  child: Container(
                    width: MedAiA11y.minTapTarget,
                    height: MedAiA11y.minTapTarget,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: L.card,
                      shape: BoxShape.circle,
                      border: Border.all(color: L.border.withValues(alpha: 0.12)),
                    ),
                    child: Icon(Icons.close_rounded, color: L.text, size: 22),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.p16),
              Expanded(
                child: Text('Join as Caregiver',
                    style: AppTypography.titleLarge.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: L.text)),
              ),
            ]),
          ),
          Expanded(
              child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p24),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            'Scan the QR code or enter the invite code to start monitoring.',
                            style: AppTypography.bodySmall.copyWith(
                                fontSize: 14, color: L.sub, height: 1.5)),
                        const SizedBox(height: AppSpacing.p32),
                        Center(
                          child: Semantics(
                            label: 'QR code scanner',
                            child: MedAiDepthCard(
                              padding: EdgeInsets.zero,
                              radius: AppRadius.squircle,
                              accentGlow: false,
                              child: Container(
                                width: 280,
                                height: 280,
                                decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.squircle),
                                  border: Border.all(color: L.green, width: 2.5),
                                ),
                                child: ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.squircle - 2),
                                  child: MobileScanner(
                                    controller: _scannerCtrl,
                                    onDetect: (capture) {
                                      final barcodes = capture.barcodes;
                                      for (final barcode in barcodes) {
                                        if (barcode.rawValue != null) {
                                          final raw = barcode.rawValue!;
                                          final code = raw.contains('code=')
                                              ? raw.split('code=').last
                                              : raw;
                                          if (!_isChecking) _checkCode(code);
                                        }
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.p32),
                        Center(
                            child: Text('OR ENTER CODE',
                                style: AppTypography.labelLarge.copyWith(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: L.sub,
                                    letterSpacing: 1.5))),
                        const SizedBox(height: AppSpacing.p12),
                        Semantics(
                          textField: true,
                          label: 'Invite code',
                          child: MedAiTextField(
                            controller: _codeCtrl,
                            hintText: '000000',
                            textAlign: TextAlign.center,
                            maxLength: 6,
                            textCapitalization: TextCapitalization.characters,
                            style: AppTypography.displayLarge.copyWith(
                              fontFamily: 'monospace',
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: L.text,
                              letterSpacing: 4,
                            ),
                            onChanged: (val) {
                              if (val.length == 6) _checkCode(val);
                            },
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 20,
                            ),
                          ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: AppSpacing.p8),
                          Semantics(
                            liveRegion: true,
                            child: Center(
                                child: Text(_error!,
                                    style: AppTypography.bodySmall.copyWith(
                                        fontSize: 12,
                                        color: L.red,
                                        fontWeight: FontWeight.w600))),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.p40),
                        MedAiCTA(
                          label: 'Verify and Join',
                          loading: _isChecking,
                          semanticsLabel: 'Verify invite code and join care team',
                          onTap: _isChecking
                              ? null
                              : () => _checkCode(_codeCtrl.text),
                        ),
                        const SizedBox(height: AppSpacing.p40),
                      ]))),
        ])));
  }
}
