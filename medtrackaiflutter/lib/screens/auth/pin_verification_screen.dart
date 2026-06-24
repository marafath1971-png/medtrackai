import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../core/utils/haptic_engine.dart';
import '../../widgets/shared/shared_widgets.dart';

class PinVerificationScreen extends StatefulWidget {
  final String correctPin;
  final String profileName;

  const PinVerificationScreen({super.key, required this.correctPin, required this.profileName});

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

    return Scaffold(
      backgroundColor: L.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BouncingButton(
          onTap: () => Navigator.pop(context, false),
          child: Icon(Icons.arrow_back_ios_new_rounded, color: L.text),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            Icon(Icons.lock_rounded, size: 48, color: L.primary),
            const SizedBox(height: 24),
            Text(
              'Unlock ${widget.profileName}',
              style: AppTypography.headlineMedium.copyWith(color: L.text, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              _isError ? 'Incorrect PIN. Try again.' : 'Enter 4-digit PIN',
              style: AppTypography.bodyLarge.copyWith(color: _isError ? Colors.red : L.sub),
            ).animate(target: _isError ? 1 : 0).shake(hz: 8, curve: Curves.easeInOut),
            const SizedBox(height: 48),

            // PIN Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) {
                final isFilled = i < _enteredPin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFilled ? L.primary : Colors.transparent,
                    border: Border.all(color: isFilled ? L.primary : L.border, width: 2),
                  ),
                );
              }),
            ),

            const Spacer(),

            // Keypad
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
              child: GridView.count(
                shrinkWrap: true,
                crossAxisCount: 3,
                mainAxisSpacing: 24,
                crossAxisSpacing: 24,
                childAspectRatio: 1.2,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  for (var i = 1; i <= 9; i++)
                    _KeypadButton(
                      label: i.toString(),
                      onTap: () => _onDigit(i.toString()),
                      L: L,
                    ),
                  
                  // Empty space
                  const SizedBox.shrink(),
                  
                  _KeypadButton(
                    label: '0',
                    onTap: () => _onDigit('0'),
                    L: L,
                  ),
                  
                  _KeypadButton(
                    icon: Icons.backspace_rounded,
                    onTap: _onBackspace,
                    L: L,
                  ),
                ],
              ),
            ),
          ],
        ).animate().fadeIn().slideY(begin: 0.1, end: 0),
      ),
    );
  }
}

class _KeypadButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback onTap;
  final AppThemeColors L;

  const _KeypadButton({this.label, this.icon, required this.onTap, required this.L});

  @override
  Widget build(BuildContext context) {
    return BouncingButton(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: L.card,
          shape: BoxShape.circle,
          border: Border.all(color: L.border.withValues(alpha: 0.1)),
        ),
        alignment: Alignment.center,
        child: icon != null
            ? Icon(icon, color: L.text, size: 28)
            : Text(
                label!,
                style: AppTypography.headlineMedium.copyWith(color: L.text, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }
}
