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
    if (code.length < 6) return;
    setState(() {
      _isChecking = true;
      _error = null;
    });

    try {
      await widget.state.joinCareTeam(code);
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
      setState(() => _error = e.toString().contains('Invalid')
          ? 'Invalid code'
          : e.toString().contains('your own')
              ? 'You cannot monitor yourself'
              : 'Connection error');
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
                              accentGlow: true,
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
                          child: MedAiGlass(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p16),
                            radius: AppRadius.xl,
                            child: TextField(
                              controller: _codeCtrl,
                              style: AppTypography.displayLarge.copyWith(
                                  fontFamily: 'monospace',
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: L.text,
                                  letterSpacing: 4),
                              textAlign: TextAlign.center,
                              onChanged: (val) {
                                if (val.length == 6) _checkCode(val);
                              },
                              decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: '000000'),
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
