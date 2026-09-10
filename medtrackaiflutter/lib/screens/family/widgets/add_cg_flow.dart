import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../providers/app_state.dart';
import '../../../models/constants.dart';
import '../../../theme/med_ai_ui.dart';
import '../../../widgets/common/solid_surface.dart';
import '../../../widgets/common/app_scaffold.dart';
import '../../../widgets/common/premium_page_header.dart';
import '../../../widgets/common/app_shimmer.dart';
import '../../../widgets/common/animated_pressable.dart';
import '../../../widgets/common/app_feedback.dart';
import '../../../core/utils/haptic_engine.dart';
import '../../../screens/app_shell.dart' show kShellNavIslandInset;
import '../../../l10n/app_localizations.dart';

class AddHeader extends StatelessWidget {
  final int step;
  final AppThemeColors L;
  final VoidCallback onBack;
  const AddHeader(
      {super.key, required this.step, required this.L, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = step == 1
        ? 'Add caregiver'
        : step == 2
            ? 'Share QR code'
            : 'Caregiver active';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PremiumPageHeader(
        title: title,
        subtitle: l10n.familyStepOf3(step),
        onBack: () {
          HapticEngine.selection();
          onBack();
        },
      ),
      const SizedBox(height: AppSpacing.p16),
      Semantics(
        label: l10n.familyStepOf3(step),
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

  /// The pinned CTA's own height: a 56px button plus the 16px of padding
  /// above and below it in the bar that holds it.
  static const double _ctaHeight = 56 + AppSpacing.p16 * 2;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final keyboardUp = MediaQuery.viewInsetsOf(context).bottom > 0;

    return AppScaffold(
      showAurora: context.isDark,
      // Opt out of Scaffold resizing. The app shell's Scaffold has already
      // shrunk this subtree for the IME; resizing again here shrank it twice
      // and stranded the pinned CTA near the TOP of the screen with the name
      // field behind it. With the opt-out the box keeps the height the shell
      // gave it, so `bottom:` below measures from just above the keyboard.
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          SafeArea(
              // The shell publishes its floating nav island as MediaQuery
              // bottom padding, and this screen already reserves that space
              // itself (below) plus the pinned CTA. Letting SafeArea inset the
              // bottom as well stacked the two, leaving ~195px of dead scroll
              // past the last field.
              bottom: false,
              child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  // Reserve exactly the furniture that actually overlaps
                  // the scroll body, and no more. With the keyboard up the
                  // shell has already shrunk this box and the nav island is
                  // hidden behind the IME, so reserving the full 176px of
                  // nav clearance on top of a halved viewport is what made
                  // the auto-scroll overshoot and strand the form.
                  padding: EdgeInsets.only(
                      left: AppSpacing.p24,
                      right: AppSpacing.p24,
                      top: AppSpacing.p12,
                      bottom: keyboardUp
                          ? _ctaHeight + AppSpacing.p24
                          : kShellNavIslandInset + _ctaHeight),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AddHeader(step: 1, L: L, onBack: onBack),
                        const MedAiFieldLabel(
                            text: 'Full name', hint: 'Required'),
                        ValueListenableBuilder<TextEditingValue>(
                            valueListenable: nameCtrl,
                            builder: (context, value, child) {
                              return MedAiTextField(
                                controller: nameCtrl,
                                hintText: l10n.familyEGSarahJohnson,
                                textCapitalization: TextCapitalization.words,
                              );
                            }),
                        const SizedBox(height: AppSpacing.p24),
                        const MedAiFieldLabel(text: 'Choose avatar'),
                        // One scrolling row rather than a 6x2 grid.
                        // Twelve avatars stacked two deep pushed the
                        // relationship chips and the phone field below the
                        // fold, so the screen opened on decoration while
                        // the form had to be hunted for.
                        SizedBox(
                          height: MedAiA11y.minTapTarget + 10,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            clipBehavior: Clip.none,
                            padding: EdgeInsets.zero,
                            children: kCgAvatars
                                .map((a) => Semantics(
                                      button: true,
                                      label: l10n.familyAvatar2(a),
                                      selected: avatar == a,
                                      child: AnimatedPressable(
                                        onTap: () {
                                          HapticEngine.selection();
                                          onAvatarChange(a);
                                        },
                                        // Solid, not MedAiGlass: light mode
                                        // discards the tint, so a selected
                                        // avatar would look unselected.
                                        child: SolidSurface(
                                          filled: avatar == a,
                                          showBorder: true,
                                          radius: 24,
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
                                .map((w) => Padding(
                                      padding: const EdgeInsetsDirectional.only(
                                          end: 12),
                                      child: w,
                                    ))
                                .toList(),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.p24),
                        const MedAiFieldLabel(text: 'Relationship'),
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
                                        child: SolidSurface(
                                          filled: relation == r,
                                          showBorder: true,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: AppSpacing.p16,
                                              vertical: AppSpacing.p12),
                                          radius: AppRadius.xl,
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
                        const SizedBox(height: AppSpacing.p24),
                        const MedAiFieldLabel(
                            text: 'Phone', hint: 'Optional, for SMS'),
                        MedAiTextField(
                          controller: contactCtrl,
                          keyboardType: TextInputType.phone,
                          hintText: '+1 555 123 4567',
                        ),
                        const SizedBox(height: AppSpacing.p24),
                        const MedAiFieldLabel(text: 'Alert after missed dose'),
                        // Wrap, not a Row of four Expanded buttons. Expanded
                        // cannot shrink below its text, so at a 1.6x text
                        // scale the four fixed columns overflowed the row by
                        // 138px; the same labels also grow in translation.
                        // These now reflow onto a second line instead.
                        Wrap(
                            spacing: AppSpacing.p8,
                            runSpacing: AppSpacing.p8,
                            children: const [
                              (0, 'Now'),
                              (15, '15 min'),
                              (30, '30 min'),
                              (60, '1 hr'),
                            ]
                                .map((o) => DelayBtn(
                                    delay: o.$1,
                                    label: o.$2,
                                    current: alertDelay,
                                    onTap: onDelayChange,
                                    L: L))
                                .toList()),
                      ]))),
          Positioned(
            // This screen opts out of Scaffold resizing (see AppScaffold
            // above), so its box stays full height and the IME overlays it.
            // The CTA therefore has to clear the keyboard itself. With the
            // keyboard down the only furniture below is the shell's floating
            // nav island.
            bottom: keyboardUp ? AppSpacing.p12 : kShellNavIslandInset,
            left: 0,
            right: 0,
            child: MedAiGlass(
              radius: 0,
              showBorder: false,
              padding: EdgeInsets.only(
                  left: AppSpacing.p24,
                  right: AppSpacing.p24,
                  top: AppSpacing.p16,
                  bottom: AppSpacing.p16),
              child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: nameCtrl,
                  builder: (context, value, child) {
                    return MedAiCTA(
                      label: l10n.familyGenerateQrCode,
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
  // Sizes to its own label rather than an equal share of a Row: the four
  // options live in a Wrap now so they can reflow when the text is scaled up
  // or translated, and Expanded is not valid inside one.
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        selected: current == delay,
        child: AnimatedPressable(
            onTap: () {
              HapticEngine.selection();
              onTap(delay);
            },
            child: SolidSurface(
              filled: current == delay,
              showBorder: true,
              padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.p12, horizontal: AppSpacing.p16),
              radius: AppRadius.xl,
              // No Center: inside a Wrap the constraints are unbounded, so
              // Center expanded each option to the full width of the column
              // and the four stacked into a vertical list that ran off the
              // bottom of the screen behind the CTA.
              child: Text(label,
                  style: AppTypography.labelLarge.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: current == delay
                          ? L.bg
                          : L.text.withValues(alpha: 0.7))),
            )),
      );
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

  /// Held so dispose() can detach the listener. Reading the Provider from
  /// dispose() throws "Looking up a deactivated widget's ancestor is unsafe" —
  /// the element is already deactivated by then, so the listener was never
  /// removed and the exception surfaced while finalizing the tree.
  AppState? _state;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkStatus());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _state = Provider.of<AppState>(context, listen: false);
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
    await Future.delayed(
        MedAiA11y.motion(context, const Duration(milliseconds: 800)));
    if (!mounted) return;
    widget.onNext();
  }

  Widget _entrance(Widget child) {
    if (MedAiA11y.reducedMotion(context)) return child;
    return child
        .animate()
        .slideY(begin: 0.1, duration: 400.ms, curve: AppCurves.smooth);
  }

  @override
  void dispose() {
    _state?.removeListener(_onStateChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cg = widget.cg;
    final L = widget.L;

    return AppScaffold(
        showAurora: context.isDark,
        body: SafeArea(
            child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.p24, vertical: AppSpacing.p12),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AddHeader(
                          step: 2, L: L, onBack: () => Navigator.pop(context)),
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
                                          fontWeight: FontWeight.w700,
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
                        child: Text(l10n.familyScanFromCaregiverApp,
                            style: AppTypography.labelLarge.copyWith(
                                fontSize: 13,
                                color: L.sub.withValues(alpha: 0.6),
                                fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(height: AppSpacing.p24),
                      Center(
                          child: Semantics(
                        label: l10n.familyQrCodeForCaregiverInvite,
                        child: MedAiDepthCard(
                          padding: const EdgeInsets.all(AppSpacing.p20),
                          radius: AppRadius.squircle,
                          accentGlow: false,
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
                          child: Text(l10n.familyOrUseInviteCode,
                              style: AppTypography.labelLarge.copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: L.sub.withValues(alpha: 0.5)))),
                      const SizedBox(height: AppSpacing.p12),
                      Center(
                          child: MedAiGlass(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.p24,
                            vertical: AppSpacing.p16),
                        radius: AppRadius.l,
                        // widget.inviteCode, not cg.inviteCode: the QR above
                        // and the copy button below both encode
                        // widget.inviteCode, so reading a different field here
                        // would show the user a code that is not the one they
                        // copy or that the caregiver scans. They agree today;
                        // this keeps one source of truth if they ever stop.
                        child: Text(
                            widget.inviteCode.isEmpty
                                ? '------'
                                : widget.inviteCode,
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
                        label: l10n.familyCopyInviteCode,
                        child: AnimatedPressable(
                          onTap: () {
                            HapticEngine.selection();
                            Clipboard.setData(
                                ClipboardData(text: widget.inviteCode));
                            AppFeedback.toast(context, 'Code copied');
                          },
                          child: MedAiGlass(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.p16,
                                vertical: AppSpacing.p12),
                            radius: AppRadius.xl,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.copy_rounded,
                                    color: L.text, size: 16),
                                const SizedBox(width: AppSpacing.p8),
                                Text(l10n.familyCopyCode,
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
                              Text(l10n.familyWaitingForCaregiverToScan,
                                  style: AppTypography.labelLarge.copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: L.text)),
                            ] else ...[
                              Icon(Icons.check_circle_rounded,
                                  color: L.green, size: 36),
                              const SizedBox(height: AppSpacing.p12),
                              Text(l10n.familySuccessCaregiverAdded,
                                  style: AppTypography.labelLarge.copyWith(
                                      fontWeight: FontWeight.w700,
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
    final l10n = AppLocalizations.of(context)!;
    return AppScaffold(
        showAurora: context.isDark,
        body: SafeArea(
            child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.p24, vertical: AppSpacing.p12),
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
                                          fontWeight: FontWeight.w700,
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
                                  horizontal: AppSpacing.p16,
                                  vertical: AppSpacing.p8),
                              decoration: BoxDecoration(
                                  color: L.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(99)),
                              child: Text(l10n.familyActive,
                                  style: AppTypography.labelSmall.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: L.green)),
                            ),
                          ]),
                        ),
                        delay: 200.ms,
                      ),
                      const SizedBox(height: AppSpacing.p24),
                      MedAiSectionHeader(title: l10n.familyTheyCanNow),
                      _entrance(
                        context,
                        MedAiDepthCard(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                HowItWorksRow(
                                    emoji: '📈',
                                    title: l10n.familySeeYourDailyAdherence,
                                    desc: 'Live dashboard with today\'s doses',
                                    isLast: false,
                                    L: L),
                                HowItWorksRow(
                                    emoji: '🚨',
                                    title: l10n.familyGetMissedDoseAlerts,
                                    desc:
                                        'Notified after ${cg.alertDelay} min if you miss a dose',
                                    isLast: false,
                                    L: L),
                                HowItWorksRow(
                                    emoji: '🔬',
                                    title: l10n.familyViewYourMedicineList,
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
                          label: l10n.familyDone,
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
