import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:medai/widgets/common/animated_pressable.dart';

import '../../domain/entities/managed_profile.dart';
import '../../theme/med_ai_ui.dart';
import '../../core/utils/haptic_engine.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/common/premium_page_header.dart';

class ProfilePinScreen extends StatefulWidget {
  final ManagedProfile profile;
  const ProfilePinScreen({super.key, required this.profile});

  @override
  State<ProfilePinScreen> createState() => _ProfilePinScreenState();
}

class _ProfilePinScreenState extends State<ProfilePinScreen> {
  String _enteredPin = '';
  bool _error = false;

  void _onKeyPress(String key) {
    HapticEngine.selection();
    if (_enteredPin.length < 4) {
      setState(() {
        _enteredPin += key;
        _error = false;
      });
      if (_enteredPin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _onBackspace() {
    HapticEngine.light();
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _error = false;
      });
    }
  }

  void _verifyPin() {
    if (_enteredPin == widget.profile.pin) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _error = true;
        _enteredPin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;

    return AppScaffold(
      body: Column(
        children: [
          PremiumPageHeader(
            title: 'Enter PIN',
            subtitle: widget.profile.name,
            onBack: () => Navigator.pop(context, false),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  const Spacer(),
                  Text(widget.profile.avatar, style: const TextStyle(fontSize: 64))
                      .medAiChain(
                    context,
                    (w) => w.animate().scaleXY(
                          begin: 0.95,
                          duration: 500.ms,
                          curve: AppCurves.emilOut,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.p16),
                  Text(
                    'Unlock ${widget.profile.name}',
                    style: AppTypography.headlineLarge.copyWith(
                      color: L.text,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.p8),
                  Text(
                    'Enter profile PIN to switch',
                    style: AppTypography.bodyMedium.copyWith(
                      color: L.sub,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.p32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.p12),
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _enteredPin.length > index
                              ? L.primary
                              : Colors.transparent,
                          border: Border.all(
                            color: _error
                                ? L.error
                                : (_enteredPin.length > index ? L.primary : L.border),
                            width: 2,
                          ),
                        ),
                      );
                    }),
                  ),
                  if (_error) ...[
                    const SizedBox(height: AppSpacing.p16),
                    Text('Incorrect PIN', style: TextStyle(color: L.error)),
                  ],
                  const Spacer(),
                  _buildNumpad(L),
                  const SizedBox(height: AppSpacing.p32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumpad(AppThemeColors L) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p40),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKey('1', L),
              _buildKey('2', L),
              _buildKey('3', L),
            ],
          ),
          const SizedBox(height: AppSpacing.p24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKey('4', L),
              _buildKey('5', L),
              _buildKey('6', L),
            ],
          ),
          const SizedBox(height: AppSpacing.p24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKey('7', L),
              _buildKey('8', L),
              _buildKey('9', L),
            ],
          ),
          const SizedBox(height: AppSpacing.p24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SizedBox(width: 72), // Empty space
              _buildKey('0', L),
              _buildBackspaceKey(L),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKey(String value, AppThemeColors L) {
    return Semantics(
      button: true,
      label: value,
      child: AnimatedPressable(
        onTap: () => _onKeyPress(value),
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: L.fill,
          ),
          child: Center(
            child: ExcludeSemantics(
              child: Text(
                value,
                style: AppTypography.headlineMedium.copyWith(
                  color: L.text,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackspaceKey(AppThemeColors L) {
    return Semantics(
      button: true,
      label: 'Delete',
      child: AnimatedPressable(
        onTap: _onBackspace,
        child: SizedBox(
          width: 72,
          height: 72,
          child: Center(
            child: Icon(Icons.backspace_outlined, color: L.text, size: 28),
          ),
        ),
      ),
    );
  }
}
