import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../../../providers/app_state.dart';
import '../../../models/constants.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/common/app_shimmer.dart';
import 'package:medai/widgets/common/animated_pressable.dart';
import '../../../core/utils/haptic_engine.dart';

class AddHeader extends StatelessWidget {
  final int step;
  final AppThemeColors L;
  final VoidCallback onBack;
  const AddHeader(
      {super.key, required this.step, required this.L, required this.onBack});
  @override
  Widget build(BuildContext context) {
    final title = step == 1
        ? "Add Caregiver"
        : step == 2
            ? "Share QR Code"
            : "Caregiver Active!";
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        AnimatedPressable(
            onTap: onBack,
            child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: L.card.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_back_ios_new_rounded,
                    color: L.text, size: 18))),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: AppTypography.titleLarge.copyWith(
                  fontSize: 24, fontWeight: FontWeight.w800, color: L.text, letterSpacing: -0.5)),
          Text('Step $step of 3',
              style: AppTypography.labelLarge
                  .copyWith(fontSize: 12, color: L.sub.withValues(alpha: 0.6), fontWeight: FontWeight.w600)),
        ]),
      ]),
      const SizedBox(height: 24),
      Row(
          children: [1, 2, 3]
              .map((n) => Expanded(
                  child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      margin: EdgeInsets.only(right: n == 3 ? 0 : 8),
                      height: 6,
                      decoration: BoxDecoration(
                          color: step >= n
                              ? L.text
                              : L.fill.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10)))))
              .toList()),
      const SizedBox(height: 32),
    ]);
  }
}

class AddCgStep1 extends StatelessWidget {
  final TextEditingController nameCtrl, contactCtrl;
  final String relation, avatar;
  final int alertDelay;
  final ValueChanged<String> onRelChange, onAvatarChange;
  final ValueChanged<int> onDelayChange;
  final AppThemeColors L;
  final VoidCallback onBack;
  final Future<void> Function() onNext;
  const AddCgStep1(
      {super.key,
      required this.nameCtrl,
      required this.contactCtrl,
      required this.relation,
      required this.avatar,
      required this.alertDelay,
      required this.onRelChange,
      required this.onAvatarChange,
      required this.onDelayChange,
      required this.L,
      required this.onBack,
      required this.onNext});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: L.meshBg,
        body: Stack(
          children: [
            Positioned(
              top: -100,
              left: -50,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: L.text.withValues(alpha: 0.05),
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(begin: 1.0, end: 1.2, duration: 5.seconds),
            ),
            SafeArea(
                child: SingleChildScrollView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.only(left: 24, right: 24, top: 12, bottom: 120),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AddHeader(step: 1, L: L, onBack: onBack),

                          // Avatar
                          Text('CHOOSE AVATAR',
                              style: AppTypography.labelLarge.copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                  color: L.sub.withValues(alpha: 0.5))),
                          const SizedBox(height: 12),
                          Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: kCgAvatars
                                  .map((a) => AnimatedPressable(
                                        onTap: () {
                                          HapticEngine.selection();
                                          onAvatarChange(a);
                                        },
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(24),
                                          child: BackdropFilter(
                                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                            child: AnimatedContainer(
                                                duration: const Duration(milliseconds: 200),
                                                curve: Curves.easeOutCubic,
                                                width: 52,
                                                height: 52,
                                                decoration: BoxDecoration(
                                                  color: avatar == a
                                                      ? L.text
                                                      : L.card.withValues(alpha: 0.6),
                                                  borderRadius: BorderRadius.circular(24),
                                                  border: avatar == a
                                                      ? null
                                                      : Border.all(color: L.border.withValues(alpha: 0.1)),
                                                  boxShadow: avatar == a ? [
                                                    BoxShadow(color: L.text.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))
                                                  ] : [],
                                                ),
                                                child: Center(
                                                    child: Text(a,
                                                        style: AppTypography
                                                            .headlineLarge
                                                            .copyWith(
                                                                fontSize: 26,
                                                                color: avatar == a
                                                                    ? L.bg
                                                                    : null)))),
                                          ),
                                        ),
                                      ))
                                  .toList()),
                          const SizedBox(height: 32),

                          // Name
                          Text('FULL NAME *',
                              style: AppTypography.labelLarge.copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                  color: L.sub.withValues(alpha: 0.5))),
                          const SizedBox(height: 12),
                          ValueListenableBuilder<TextEditingValue>(
                            valueListenable: nameCtrl,
                            builder: (context, value, child) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                                    decoration: BoxDecoration(
                                        color: L.card.withValues(alpha: 0.6),
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(
                                            color: value.text.isNotEmpty ? L.text : L.border.withValues(alpha: 0.1),
                                            width: 1.5)),
                                    child: TextField(
                                        controller: nameCtrl,
                                        style: AppTypography.bodySmall
                                            .copyWith(fontSize: 16, color: L.text, fontWeight: FontWeight.w600),
                                        decoration: InputDecoration(
                                            border: InputBorder.none,
                                            hintText: 'e.g. Sarah Johnson',
                                            hintStyle: AppTypography.bodySmall.copyWith(
                                                color: L.sub.withValues(alpha: 0.3)))),
                                  ),
                                ),
                              );
                            }
                          ),
                          const SizedBox(height: 32),

                          // Relationship
                          Text('RELATIONSHIP',
                              style: AppTypography.labelLarge.copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                  color: L.sub.withValues(alpha: 0.5))),
                          const SizedBox(height: 12),
                          Wrap(
                              spacing: 8,
                              runSpacing: 10,
                              children: [
                                'Spouse',
                                'Parent',
                                'Son',
                                'Daughter',
                                'Sibling',
                                'Friend',
                                'Doctor',
                                'Caregiver'
                              ]
                                  .map((r) => AnimatedPressable(
                                        onTap: () {
                                          HapticEngine.selection();
                                          onRelChange(r);
                                        },
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(99),
                                          child: BackdropFilter(
                                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                            child: AnimatedContainer(
                                                duration: const Duration(milliseconds: 200),
                                                curve: Curves.easeOutCubic,
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 16, vertical: 10),
                                                decoration: BoxDecoration(
                                                    color: relation == r
                                                        ? L.text
                                                        : L.card.withValues(alpha: 0.6),
                                                    borderRadius: BorderRadius.circular(99),
                                                    border: Border.all(
                                                        color: relation == r ? L.text : L.border.withValues(alpha: 0.1)),
                                                    boxShadow: relation == r ? [
                                                      BoxShadow(color: L.text.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))
                                                    ] : [],
                                                ),
                                                child: Text(r,
                                                    style: AppTypography.labelLarge
                                                        .copyWith(
                                                            fontSize: 13,
                                                            fontWeight: FontWeight.w700,
                                                            color: relation == r
                                                                ? L.bg
                                                                : L.text.withValues(alpha: 0.8)))),
                                          ),
                                        ),
                                      ))
                                  .toList()),
                          const SizedBox(height: 32),

                          // Phone
                          Text('PHONE (OPTIONAL — FOR SMS)',
                              style: AppTypography.labelLarge.copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                  color: L.sub.withValues(alpha: 0.5))),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                                decoration: BoxDecoration(
                                    color: L.card.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                        color: contactCtrl.text.isNotEmpty ? L.text : L.border.withValues(alpha: 0.1),
                                        width: 1.5)),
                                child: TextField(
                                    controller: contactCtrl,
                                    keyboardType: TextInputType.phone,
                                    style: AppTypography.bodySmall
                                        .copyWith(fontSize: 16, color: L.text, fontWeight: FontWeight.w600),
                                    decoration: InputDecoration(
                                        border: InputBorder.none,
                                        hintText: '+880 1XXX-XXXXXX',
                                        hintStyle: AppTypography.bodySmall.copyWith(
                                            color: L.sub.withValues(alpha: 0.3)))),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Alert Delay
                          Text('ALERT AFTER MISSED DOSE',
                              style: AppTypography.labelLarge.copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                  color: L.sub.withValues(alpha: 0.5))),
                          const SizedBox(height: 12),
                          Row(children: [
                            DelayBtn(
                                delay: 0,
                                label: 'Now',
                                current: alertDelay,
                                onTap: onDelayChange,
                                L: L),
                            const SizedBox(width: 8),
                            DelayBtn(
                                delay: 15,
                                label: '15 min',
                                current: alertDelay,
                                onTap: onDelayChange,
                                L: L),
                            const SizedBox(width: 8),
                            DelayBtn(
                                delay: 30,
                                label: '30 min',
                                current: alertDelay,
                                onTap: onDelayChange,
                                L: L),
                            const SizedBox(width: 8),
                            DelayBtn(
                                delay: 60,
                                label: '1 hr',
                                current: alertDelay,
                                onTap: onDelayChange,
                                L: L),
                          ]),
                        ]))),
            
            // Bottom Sticky Button
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                  child: Container(
                    padding: EdgeInsets.only(left: 24, right: 24, top: 16, bottom: MediaQuery.of(context).padding.bottom + 16),
                    decoration: BoxDecoration(
                      color: L.meshBg.withValues(alpha: 0.5),
                      border: Border(top: BorderSide(color: L.border.withValues(alpha: 0.1))),
                    ),
                    child: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: nameCtrl,
                      builder: (context, value, child) {
                        return AnimatedPressable(
                            onTap: value.text.trim().isEmpty ? null : () {
                              HapticEngine.selection();
                              onNext();
                            },
                            child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: value.text.trim().isEmpty
                                      ? L.text.withValues(alpha: 0.1)
                                      : L.text,
                                  borderRadius: BorderRadius.circular(32),
                                ),
                                child: Text('GENERATE QR CODE 🪄',
                                    style: AppTypography.labelLarge.copyWith(
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.0,
                                        color: value.text.trim().isEmpty
                                            ? L.text.withValues(alpha: 0.4)
                                            : L.bg))));
                      }
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}

class DelayBtn extends StatelessWidget {
  final int delay, current;
  final String label;
  final ValueChanged<int> onTap;
  final AppThemeColors L;
  const DelayBtn(
      {super.key,
      required this.delay,
      required this.current,
      required this.label,
      required this.onTap,
      required this.L});
  @override
  Widget build(BuildContext context) => Expanded(
      child: AnimatedPressable(
          onTap: () {
            HapticEngine.selection();
            onTap(delay);
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: current == delay ? L.text : L.card.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(24),
                  border: current == delay ? null : Border.all(color: L.border.withValues(alpha: 0.1)),
                ),
                child: Text(label,
                    style: AppTypography.labelLarge.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: current == delay
                            ? L.bg
                            : L.text.withValues(alpha: 0.7))),
              ),
            ),
          )));
}

class AddCgStep2 extends StatefulWidget {
  final Caregiver cg;
  final String inviteCode;
  final AppThemeColors L;
  final VoidCallback onNext;
  const AddCgStep2(
      {super.key,
      required this.cg,
      required this.inviteCode,
      required this.L,
      required this.onNext});

  @override
  State<AddCgStep2> createState() => _AddCgStep2State();
}

class _AddCgStep2State extends State<AddCgStep2> {
  String _scanState = 'idle';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkStatus());
  }

  void _checkStatus() {
    if (!mounted) return;
    final state = Provider.of<AppState>(context, listen: false);

    final currentCg = state.caregivers.firstWhere(
      (c) => c.inviteCode == widget.inviteCode || c.id == widget.cg.id,
      orElse: () => widget.cg,
    );

    if (currentCg.status == 'active' && _scanState == 'idle') {
      _handleActivation();
    } else {
      state.addListener(_onStateChange);
      
      // For demonstration: simulate caregiver joining after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _scanState == 'idle') {
          state.activateCaregiver(widget.cg.id);
        }
      });
    }
  }

  void _onStateChange() {
    if (!mounted) return;
    final state = Provider.of<AppState>(context, listen: false);
    final currentCg = state.caregivers.firstWhere(
      (c) => c.inviteCode == widget.inviteCode || c.id == widget.cg.id,
      orElse: () => widget.cg,
    );

    if (currentCg.status == 'active' && _scanState == 'idle') {
      state.removeListener(_onStateChange);
      _handleActivation();
    }
  }

  void _handleActivation() async {
    setState(() => _scanState = 'done');
    HapticEngine.heavy();
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    widget.onNext();
  }

  @override
  void dispose() {
    Provider.of<AppState>(context, listen: false).removeListener(_onStateChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cg = widget.cg;
    final L = widget.L;

    return Scaffold(
        backgroundColor: L.meshBg,
        body: SafeArea(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AddHeader(
                          step: 2, L: L, onBack: () => Navigator.pop(context)),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                            decoration: BoxDecoration(
                              color: L.card.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: L.border.withValues(alpha: 0.1)),
                            ),
                            child: Row(children: [
                              Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                      color: L.greenLight,
                                      borderRadius: BorderRadius.circular(24)),
                                  child: Center(
                                      child: Text(cg.avatar,
                                          style: AppTypography.headlineLarge
                                              .copyWith(fontSize: 32)))),
                              const SizedBox(width: 16),
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                    Text(cg.name,
                                        style: AppTypography.titleLarge.copyWith(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 20,
                                            color: L.text)),
                                    const SizedBox(height: 2),
                                    Text(
                                        '${cg.relation}${cg.contact.isNotEmpty ? ' · ${cg.contact}' : ''}',
                                        style: AppTypography.labelMedium
                                            .copyWith(color: L.sub.withValues(alpha: 0.8), fontWeight: FontWeight.w600)),
                                  ])),
                            ]),
                          ),
                        ),
                      ).animate().slideY(begin: 0.1, duration: 400.ms, curve: Curves.easeOutBack),
                      const SizedBox(height: 32),
                      
                      Center(
                        child: Text(
                            'Scan from Caregiver App',
                            style: AppTypography.labelLarge.copyWith(
                                fontSize: 13, color: L.sub.withValues(alpha: 0.6), fontWeight: FontWeight.w800, letterSpacing: 1.0)),
                      ).animate().fadeIn(delay: 100.ms),
                      const SizedBox(height: 24),
                      
                      // QR Code Card
                      Center(
                          child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(color: L.border.withValues(alpha: 0.1)),
                          boxShadow: [
                            BoxShadow(
                                color: L.green.withValues(alpha: 0.2),
                                blurRadius: 40,
                                spreadRadius: -10,
                                offset: const Offset(0, 20)),
                          ],
                        ),
                        child: QrImageView(
                          data: widget.inviteCode,
                          size: 220,
                          eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: Color(0xFF1C1C1E)),
                          dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.circle,
                              color: Color(0xFF1C1C1E)),
                        ),
                      ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack)
                        .then().shimmer(duration: 2.seconds, color: L.green.withValues(alpha: 0.1))),
                      
                      const SizedBox(height: 40),
                      Center(
                          child: Text('OR USE INVITE CODE',
                              style: AppTypography.labelLarge.copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: L.sub.withValues(alpha: 0.5),
                                  letterSpacing: 2.0))),
                      const SizedBox(height: 12),
                      Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                                    decoration: BoxDecoration(
                              color: L.card.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: L.border.withValues(alpha: 0.1)),
                                                    ),
                                                    child: Text(cg.inviteCode ?? '------',
                              style: AppTypography.displayLarge.copyWith(
                                  fontFamily: 'Courier',
                                  fontSize: 34,
                                  fontWeight: FontWeight.w900,
                                  color: L.text,
                                  letterSpacing: 8)),
                                                  ),
                            ),
                          )),
                      const SizedBox(height: 16),
                      Center(
                          child: AnimatedPressable(
                        onTap: () {
                          HapticEngine.selection();
                          Clipboard.setData(ClipboardData(text: widget.inviteCode));
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Code copied! ✓', style: TextStyle(fontWeight: FontWeight.w700, color: L.bg)),
                                backgroundColor: L.text,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ));
                        },
                        child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: L.text.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.copy_rounded, color: L.text, size: 16),
                                const SizedBox(width: 8),
                                Text('Copy Code',
                                    style: AppTypography.labelLarge.copyWith(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: L.text,
                                        letterSpacing: 0.5)),
                              ],
                            )),
                      )),
                      const SizedBox(height: 48),
                      
                      // Loading Status
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            decoration: BoxDecoration(
                              color: _scanState == 'idle' ? L.card.withValues(alpha: 0.6) : L.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: _scanState == 'idle' ? L.border.withValues(alpha: 0.1) : L.green.withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              children: [
                                if (_scanState == 'idle') ...[
                                  const SizedBox(
                                      width: 28,
                                      height: 28,
                                      child: AppShimmer(width: 28, height: 28, shape: BoxShape.circle)),
                                  const SizedBox(height: 16),
                                  Text('Waiting for caregiver to scan...',
                                      style: AppTypography.labelLarge.copyWith(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: L.text)),
                                ] else ...[
                                  Icon(Icons.check_circle_rounded, color: L.green, size: 36)
                                    .animate().scale(curve: Curves.elasticOut, duration: 800.ms),
                                  const SizedBox(height: 12),
                                  Text('Success! Caregiver added.',
                                      style: AppTypography.labelLarge.copyWith(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                          color: L.green))
                                    .animate().fadeIn(),
                                ]
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ]))));
  }
}

class HowItWorksRow extends StatelessWidget {
  final String emoji, title, desc;
  final bool isLast;
  final AppThemeColors L;
  const HowItWorksRow(
      {super.key,
      required this.emoji,
      required this.title,
      required this.desc,
      required this.isLast,
      required this.L});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      margin: EdgeInsets.only(bottom: isLast ? 0 : 16),
      decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(
                      color: L.border.withValues(alpha: 0.05), width: 1))),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: L.text.withValues(alpha: 0.05),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(emoji,
                style: AppTypography.bodyMedium.copyWith(fontSize: 22)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: AppTypography.titleLarge.copyWith(
                  fontSize: 15, fontWeight: FontWeight.w800, color: L.text)),
          const SizedBox(height: 2),
          Text(desc,
              style:
                  AppTypography.bodySmall.copyWith(fontSize: 13, color: L.sub.withValues(alpha: 0.8), fontWeight: FontWeight.w500)),
        ]))
      ]),
    );
  }
}

class AddCgStep3 extends StatelessWidget {
  final Caregiver cg;
  final AppThemeColors L;
  final VoidCallback onDone;
  const AddCgStep3(
      {super.key, required this.cg, required this.L, required this.onDone});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: L.meshBg,
        body: SafeArea(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AddHeader(step: 3, L: L, onBack: onDone),
                      
                      Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: L.greenLight,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.favorite_rounded, color: L.green, size: 40),
                        ).animate()
                         .scale(duration: 600.ms, curve: Curves.elasticOut)
                         .then().shimmer(duration: 2.seconds),
                      ),
                      const SizedBox(height: 32),
                      
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            margin: const EdgeInsets.only(bottom: 32),
                            decoration: BoxDecoration(
                              color: L.card.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: L.border.withValues(alpha: 0.1)),
                            ),
                            child: Row(children: [
                              Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                      color: L.text.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(20)),
                                  child: Center(
                                      child: Text(cg.avatar,
                                          style: AppTypography.headlineLarge
                                              .copyWith(fontSize: 30)))),
                              const SizedBox(width: 16),
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                    Text(cg.name,
                                        style: AppTypography.titleLarge.copyWith(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 20,
                                            color: L.text)),
                                    const SizedBox(height: 2),
                                    Text(
                                        '${cg.relation}${cg.contact.isNotEmpty ? ' · ${cg.contact}' : ''}',
                                        style: AppTypography.labelMedium
                                            .copyWith(color: L.sub.withValues(alpha: 0.8), fontWeight: FontWeight.w600)),
                                  ])),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                    color: L.green.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(99)),
                                child: Text('Active',
                                    style: AppTypography.labelSmall.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: L.green,
                                        letterSpacing: 0.5)),
                              ),
                            ]),
                          ),
                        ),
                      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                      
                      Text('THEY CAN NOW:',
                          style: AppTypography.labelLarge.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                              color: L.sub.withValues(alpha: 0.5))).animate().fadeIn(delay: 400.ms),
                      const SizedBox(height: 16),
                      
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: L.card.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: L.border.withValues(alpha: 0.1)),
                            ),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  HowItWorksRow(
                                      emoji: '📈',
                                      title: 'See your daily adherence',
                                      desc: 'Live dashboard with today\'s doses',
                                      isLast: false,
                                      L: L),
                                  HowItWorksRow(
                                      emoji: '🚨',
                                      title: 'Get missed-dose alerts',
                                      desc:
                                          'Notified after ${cg.alertDelay} min if you miss a dose',
                                      isLast: false,
                                      L: L),
                                  HowItWorksRow(
                                      emoji: '🔬',
                                      title: 'View your medicine list',
                                      desc: 'All your medications at a glance',
                                      isLast: true,
                                      L: L),
                                ]),
                          ),
                        ),
                      ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),
                      const SizedBox(height: 48),
                      
                      AnimatedPressable(
                          onTap: () {
                            HapticEngine.light();
                            onDone();
                          },
                          child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: L.text,
                                borderRadius: BorderRadius.circular(32),
                              ),
                              child: Text('Done',
                                  style: AppTypography.labelLarge.copyWith(
                                      fontWeight: FontWeight.w900,
                                      color: L.bg,
                                      letterSpacing: 1.0)))).animate().fadeIn(delay: 800.ms).slideY(begin: 0.1),
                    ]))));
  }
}
