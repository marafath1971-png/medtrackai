import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../theme/med_ai_ui.dart';
import '../../core/utils/haptic_engine.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/common/premium_page_header.dart';
import '../../widgets/common/animated_pressable.dart';

class PinVerificationScreen extends StatefulWidget {
  final String correctPin;
  final String profileName;

  const PinVerificationScreen({
    super.key,
    required this.correctPin,
    required this.profileName,
  });

  @override
  State<PinVerificationScreen> createState() => _PinVerificationScreenState();
}

class _PinVerificationScreenState extends State<PinVerificationScreen> {
  String _enteredPin = '';
  bool _isError = false;

  void _onDigit(String d) {
    if (_enteredPin.length < 4) {
      HapticEngine.selection();
      setState(() {
        _enteredPin += d;
        _isError = false;
      });

      if (_enteredPin.length == 4) {
        _verify();
      }
    }
  }

  void _onBackspace() {
    if (_enteredPin.isNotEmpty) {
      HapticEngine.selection();
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _isError = false;
      });
    }
  }

  void _verify() {
    if (_enteredPin == widget.correctPin) {
      HapticEngine.success();
      Navigator.pop(context, true);
    } else {
      HapticEngine.error();
      setState(() {
        _isError = true;
        _enteredPin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final reduceMotion = MedAiA11y.reducedMotion(context);

    Widget body = Column(
      children: [
        PremiumPageHeader(
          title: 'Enter PIN',
          subtitle: widget.profileName,
          onBack: () => Navigator.pop(context, false),
        ),
        const Spacer(),
          Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.pastelMint,
              border: Border.all(
                color: AppColors.limeDeep.withValues(alpha: 0.35),
              ),
            ),
            child: const Icon(Icons.lock_rounded, size: 32, color: AppColors.limeInk),
          ),
          const SizedBox(height: 24),
          Text(
            'Unlock ${widget.profileName}',
            style: AppTypography.headlineLarge.copyWith(
              color: L.text,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 8),
          Semantics(
            liveRegion: true,
            child: Text(
              _isError ? 'Incorrect PIN. Try again.' : 'Enter 4-digit PIN',
              style: AppTypography.bodyLarge.copyWith(
                color: _isError ? L.error : L.sub,
              ),
            ),
          ).let((w) {
            if (reduceMotion || !_isError) return w;
            return w.animate().shake(hz: 8, curve: Curves.easeInOut);
          }),
          const SizedBox(height: 48),
          Semantics(
            label: 'PIN entry, ${_enteredPin.length} of 4 digits entered',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) {
                final isFilled = i < _enteredPin.length;
                return AnimatedContainer(
                  duration: MedAiA11y.motion(context, AppDurations.micro),
                  curve: AppCurves.emilOut,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFilled
                        ? (_isError ? L.error : AppColors.limeDeep)
                        : Colors.transparent,
                    border: Border.all(
                      color: isFilled
                          ? (_isError ? L.error : AppColors.limeDeep)
                          : L.border.withValues(alpha: 0.6),
                      width: 2,
                    ),
                  ),
                );
              }),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 0, 32, 24),
            child: GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.15,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (var i = 1; i <= 9; i++)
                  _KeypadButton(
                    label: i.toString(),
                    onTap: () => _onDigit(i.toString()),
                    L: L,
                  ),
                const SizedBox.shrink(),
                _KeypadButton(
                  label: '0',
                  onTap: () => _onDigit('0'),
                  L: L,
                ),
                _KeypadButton(
                  icon: Icons.backspace_rounded,
                  onTap: _onBackspace,
                  semanticsLabel: 'Delete',
                  L: L,
                ),
              ],
            ),
          ),
        ],
    );

    if (!reduceMotion) {
      body = body.animate().fadeIn().slideY(begin: 0.06, end: 0, curve: AppCurves.emilOut);
    }

    return AppScaffold(
      showAurora: false,
      body: body,
    );
  }
}

class _KeypadButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final String? semanticsLabel;
  final VoidCallback onTap;
  final AppThemeColors L;

  const _KeypadButton({
    this.label,
    this.icon,
    this.semanticsLabel,
    required this.onTap,
    required this.L,
  });

  @override
  Widget build(BuildContext context) {
    final text = semanticsLabel ?? label ?? 'Key';

    return Semantics(
      button: true,
      label: text,
      child: AnimatedPressable(
        onTap: onTap,
        scaleFactor: 0.94,
        child: Container(
          constraints: const BoxConstraints(
            minWidth: AppA11y.minTapTarget,
            minHeight: AppA11y.minTapTarget,
          ),
          decoration: BoxDecoration(
            color: L.card,
            shape: BoxShape.circle,
            border: Border.all(
              color: L.border.withValues(alpha: 0.35),
              width: 0.5,
            ),
            boxShadow: AppShadows.soft,
          ),
          alignment: Alignment.center,
          child: icon != null
              ? Icon(icon, color: L.text, size: 26)
              : Text(
                  label!,
                  style: AppTypography.headlineMedium.copyWith(
                    color: L.text,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                  ),
                ),
        ),
      ),
    );
  }
}

extension _Let<T> on T {
  R let<R>(R Function(T) fn) => fn(this);
}
