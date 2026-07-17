import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../providers/app_state.dart';
import '../../../models/constants.dart';
import '../../../theme/med_ai_ui.dart';
import '../../../widgets/common/app_scaffold.dart';
import '../../../widgets/common/premium_page_header.dart';
import '../../../widgets/common/app_shimmer.dart';
import '../../../widgets/common/animated_pressable.dart';
import '../../../widgets/common/app_feedback.dart';
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
        ? 'Add caregiver'
        : step == 2
            ? 'Share QR code'
            : 'Caregiver active';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PremiumPageHeader(
        title: title,
        subtitle: 'Step $step of 3',
        onBack: () {
          HapticEngine.selection();
          onBack();
        },
      ),
      const SizedBox(height: AppSpacing.p16),
      Semantics(
        label: 'Step $step of 3',
        child: Row(
            children: [1, 2, 3]
                .map((n) => Expanded(
                    child: AnimatedContainer(
                        duration: MedAiA11y.motion(
                            context, const Duration(milliseconds: 300)),
                        curve: Curves.easeOutCubic,
                        margin: EdgeInsetsDirectional.only(end: n == 3 ? 0 : 8),
                        height: 6,
                        decoration: BoxDecoration(
                            color: step >= n
                                ? L.text
                                : L.fill.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10)))))
                .toList()),
      ),
      const SizedBox(height: AppSpacing.p32),
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
  Widget build(BuildContext context) => AppScaffold(
        showAurora: context.isDark,
        body: Stack(
          children: [
            SafeArea(
                child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.only(
                        left: AppSpacing.p24, right: AppSpacing.p24, top: AppSpacing.p12, bottom: 120),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AddHeader(step: 1, L: L, onBack: onBack),
                          MedAiSectionHeader(title: 'Choose avatar'),
                          Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: kCgAvatars
                                  .map((a) => Semantics(
                                        button: true,
                                        label: 'Avatar $a',
                                        selected: avatar == a,
                                        child: AnimatedPressable(
                                          onTap: () {
                                            HapticEngine.selection();
                                            onAvatarChange(a);
                                          },
                                          child: MedAiGlass(
                                            padding: EdgeInsets.zero,
                                            radius: 24,
                                            tint: avatar == a ? L.text : L.card,
                                            child: SizedBox(
                                              width: MedAiA11y.minTapTarget,
                                              height: MedAiA11y.minTapTarget,
                                              child: Center(
                                                  child: Text(a,
                                                      style: AppTypography
                                                          .headlineLarge
                                                          .copyWith(
                                                              fontSize: 26,
                                                              color: avatar == a
                                                                  ? L.bg
                                                                  : L.text))),
                                            ),
                                          ),
                                        ),
                                      ))
                                  .toList()),
                          const SizedBox(height: AppSpacing.p32),
                          MedAiSectionHeader(title: 'Full name *'),
                          ValueListenableBuilder<TextEditingValue>(
                              valueListenable: nameCtrl,
                              builder: (context, value, child) {
                                return MedAiGlass(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.gutter, vertical: AppSpacing.p4),
                                  radius: AppRadius.xl,
                                  child: TextField(
                                      controller: nameCtrl,
                                      style: AppTypography.bodySmall.copyWith(
                                          fontSize: 16,
                                          color: L.text,
                                          fontWeight: FontWeight.w600),
                                      decoration: InputDecoration(
                                          border: InputBorder.none,
                                          hintText: 'e.g. Sarah Johnson',
                                          hintStyle: AppTypography.bodySmall
                                              .copyWith(
                                                  color: L.sub.withValues(
                                                      alpha: 0.3)))),
                                );
                              }),
                          const SizedBox(height: AppSpacing.p32),
                          MedAiSectionHeader(title: 'Relationship'),
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
                                  .map((r) => Semantics(
                                        button: true,
                                        label: r,
                                        selected: relation == r,
                                        child: AnimatedPressable(
                                          onTap: () {
                                            HapticEngine.selection();
                                            onRelChange(r);
                                          },
                                          child: MedAiGlass(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: AppSpacing.p16, vertical: AppSpacing.p12),
                                            radius: AppRadius.xl,
                                            tint: relation == r ? L.text : L.card,
                                            child: Text(r,
                                                style: AppTypography.labelLarge
                                                    .copyWith(
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: relation == r
                                                            ? L.bg
                                                            : L.text.withValues(
                                                                alpha: 0.8))),
                                          ),
                                        ),
                                      ))
                                  .toList()),
                          const SizedBox(height: AppSpacing.p32),
                          MedAiSectionHeader(
                              title: 'Phone (optional — for SMS)'),
                          MedAiGlass(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.gutter, vertical: AppSpacing.p4),
                            radius: AppRadius.xl,
                            child: TextField(
                                controller: contactCtrl,
                                keyboardType: TextInputType.phone,
                                style: AppTypography.bodySmall.copyWith(
                                    fontSize: 16,
                                    color: L.text,
                                    fontWeight: FontWeight.w600),
                                decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: '+880 1XXX-XXXXXX',
                                    hintStyle: AppTypography.bodySmall.copyWith(
                                        color: L.sub.withValues(alpha: 0.3)))),
                          ),
                          const SizedBox(height: AppSpacing.p32),
                          MedAiSectionHeader(title: 'Alert after missed dose'),
                          Row(children: [
                            DelayBtn(
                                delay: 0,
                                label: 'Now',
                                current: alertDelay,
                                onTap: onDelayChange,
                                L: L),
                            const SizedBox(width: AppSpacing.p8),
                            DelayBtn(
                                delay: 15,
                                label: '15 min',
                                current: alertDelay,
                                onTap: onDelayChange,
                                L: L),
                            const SizedBox(width: AppSpacing.p8),
                            DelayBtn(
                                delay: 30,
                                label: '30 min',
                                current: alertDelay,
                                onTap: onDelayChange,
                                L: L),
                            const SizedBox(width: AppSpacing.p8),
                            DelayBtn(
                                delay: 60,
                                label: '1 hr',
                                current: alertDelay,
                                onTap: onDelayChange,
                                L: L),
                          ]),
                        ]))),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: MedAiGlass(
                radius: 0,
                showBorder: false,
                padding: EdgeInsets.only(
                    left: AppSpacing.p24,
                    right: AppSpacing.p24,
                    top: AppSpacing.p16,
                    bottom: MediaQuery.of(context).padding.bottom + 16),
                child: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: nameCtrl,
                    builder: (context, value, child) {
                      return MedAiCTA(
                        label: 'Generate QR code',
                        icon: Icons.qr_code_rounded,
                        enabled: value.text.trim().isNotEmpty,
                        semanticsLabel: 'Generate QR code for caregiver',
                        onTap: () {
                          HapticEngine.selection();
                          onNext();
                        },
                      );
                    }),
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
      child: Semantics(
        button: true,
        label: label,
        selected: current == delay,
        child: AnimatedPressable(
            onTap: () {
              HapticEngine.selection();
              onTap(delay);
            },
            child: MedAiGlass(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.p16, horizontal: AppSpacing.p4),
              radius: AppRadius.xl,
              tint: current == delay ? L.text : L.card,
              child: Center(
                child: Text(label,
                    style: AppTypography.labelLarge.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: current == delay
                            ? L.bg
                            : L.text.withValues(alpha: 0.7))),
              ),
            )),
      ));
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
    await Future.delayed(MedAiA11y.motion(context, const Duration(milliseconds: 800)));
    if (!mounted) return;
    widget.onNext();
  }

  Widget _entrance(Widget child) {
    if (MedAiA11y.reducedMotion(context)) return child;
    return child.animate().slideY(begin: 0.1, duration: 400.ms, curve: AppCurves.smooth);
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

    return AppScaffold(
        showAurora: context.isDark,
        body: SafeArea(
            child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p24, vertical: AppSpacing.p12),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AddHeader(
                          step: 2,
                          L: L,
                          onBack: () => Navigator.pop(context)),
                      _entrance(
                        MedAiDepthCard(
                          child: Row(children: [
                            Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                    color: L.greenLight,
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.xl)),
                                child: Center(
                                    child: Text(cg.avatar,
                                        style: AppTypography.headlineLarge
                                            .copyWith(fontSize: 32)))),
                            const SizedBox(width: AppSpacing.p16),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text(cg.name,
                                      style: AppTypography.titleLarge.copyWith(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 20,
                                          color: L.text)),
                                  const SizedBox(height: 2),
                                  Text(
                                      '${cg.relation}${cg.contact.isNotEmpty ? ' · ${cg.contact}' : ''}',
                                      style: AppTypography.labelMedium.copyWith(
                                          color: L.sub.withValues(alpha: 0.8),
                                          fontWeight: FontWeight.w600)),
                                ])),
                          ]),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.p32),
                      Center(
                        child: Text('Scan from caregiver app',
                            style: AppTypography.labelLarge.copyWith(
                                fontSize: 13,
                                color: L.sub.withValues(alpha: 0.6),
                                fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(height: AppSpacing.p24),
                      Center(
                          child: Semantics(
                        label: 'QR code for caregiver invite',
                        child: MedAiDepthCard(
                          padding: const EdgeInsets.all(AppSpacing.p20),
                          radius: AppRadius.squircle,
                          accentGlow: true,
                          color: Colors.white,
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
                        ),
                      )),
                      const SizedBox(height: AppSpacing.p40),
                      Center(
                          child: Text('Or use invite code',
                              style: AppTypography.labelLarge.copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: L.sub.withValues(alpha: 0.5)))),
                      const SizedBox(height: AppSpacing.p12),
                      Center(
                          child: MedAiGlass(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.p24, vertical: AppSpacing.p16),
                        radius: AppRadius.l,
                        child: Text(cg.inviteCode ?? '------',
                            style: AppTypography.displayLarge.copyWith(
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                color: L.text,
                                letterSpacing: 6)),
                      )),
                      const SizedBox(height: AppSpacing.p16),
                      Center(
                          child: Semantics(
                        button: true,
                        label: 'Copy invite code',
                        child: AnimatedPressable(
                          onTap: () {
                            HapticEngine.selection();
                            Clipboard.setData(
                                ClipboardData(text: widget.inviteCode));
                            AppFeedback.toast(context, 'Code copied');
                          },
                          child: MedAiGlass(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.p16, vertical: AppSpacing.p12),
                            radius: AppRadius.xl,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.copy_rounded,
                                    color: L.text, size: 16),
                                const SizedBox(width: AppSpacing.p8),
                                Text('Copy code',
                                    style: AppTypography.labelLarge.copyWith(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: L.text)),
                              ],
                            ),
                          ),
                        ),
                      )),
                      const SizedBox(height: AppSpacing.p48),
                      MedAiDepthCard(
                        color: _scanState == 'idle'
                            ? L.card
                            : L.green.withValues(alpha: 0.1),
                        child: Column(
                          children: [
                            if (_scanState == 'idle') ...[
                              const SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: AppShimmer(
                                      width: 28,
                                      height: 28,
                                      shape: BoxShape.circle)),
                              const SizedBox(height: AppSpacing.p16),
                              Text('Waiting for caregiver to scan...',
                                  style: AppTypography.labelLarge.copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: L.text)),
                            ] else ...[
                              Icon(Icons.check_circle_rounded,
                                  color: L.green, size: 36),
                              const SizedBox(height: AppSpacing.p12),
                              Text('Success! Caregiver added.',
                                  style: AppTypography.labelLarge.copyWith(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                      color: L.green)),
                            ]
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.p32),
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
          width: MedAiA11y.minTapTarget,
          height: MedAiA11y.minTapTarget,
          decoration: BoxDecoration(
            color: L.text.withValues(alpha: 0.05),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(emoji,
                style: AppTypography.bodyMedium.copyWith(fontSize: 22)),
          ),
        ),
        const SizedBox(width: AppSpacing.p16),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: AppTypography.titleLarge.copyWith(
                  fontSize: 15, fontWeight: FontWeight.w800, color: L.text)),
          const SizedBox(height: 2),
          Text(desc,
              style: AppTypography.bodySmall.copyWith(
                  fontSize: 13,
                  color: L.sub.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w500)),
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

  Widget _entrance(BuildContext context, Widget child, {Duration? delay}) {
    if (MedAiA11y.reducedMotion(context)) return child;
    return child
        .animate(delay: delay)
        .fadeIn(duration: AppDurations.fast)
        .slideY(begin: 0.1, end: 0, curve: AppCurves.smooth);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
        showAurora: context.isDark,
        body: SafeArea(
            child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p24, vertical: AppSpacing.p12),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AddHeader(step: 3, L: L, onBack: onDone),
                      Center(
                        child: _entrance(
                          context,
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: L.greenLight,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.favorite_rounded,
                                color: L.green, size: 40),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.p32),
                      _entrance(
                        context,
                        MedAiDepthCard(
                          child: Row(children: [
                            Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                    color: L.text.withValues(alpha: 0.05),
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.l)),
                                child: Center(
                                    child: Text(cg.avatar,
                                        style: AppTypography.headlineLarge
                                            .copyWith(fontSize: 30)))),
                            const SizedBox(width: AppSpacing.p16),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text(cg.name,
                                      style: AppTypography.titleLarge.copyWith(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 20,
                                          color: L.text)),
                                  const SizedBox(height: 2),
                                  Text(
                                      '${cg.relation}${cg.contact.isNotEmpty ? ' · ${cg.contact}' : ''}',
                                      style: AppTypography.labelMedium.copyWith(
                                          color: L.sub.withValues(alpha: 0.8),
                                          fontWeight: FontWeight.w600)),
                                ])),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.p16, vertical: AppSpacing.p8),
                              decoration: BoxDecoration(
                                  color: L.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(99)),
                              child: Text('Active',
                                  style: AppTypography.labelSmall.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: L.green)),
                            ),
                          ]),
                        ),
                        delay: 200.ms,
                      ),
                      const SizedBox(height: AppSpacing.p24),
                      MedAiSectionHeader(title: 'They can now:'),
                      _entrance(
                        context,
                        MedAiDepthCard(
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
                        delay: 400.ms,
                      ),
                      const SizedBox(height: AppSpacing.p48),
                      _entrance(
                        context,
                        MedAiCTA(
                          label: 'Done',
                          semanticsLabel: 'Finish adding caregiver',
                          onTap: () {
                            HapticEngine.light();
                            onDone();
                          },
                        ),
                        delay: 600.ms,
                      ),
                    ]))));
  }
}
