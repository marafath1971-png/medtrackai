import 'package:flutter/material.dart';
import '../../domain/entities/managed_profile.dart';
import '../../theme/app_theme.dart';
import 'package:medai/widgets/common/animated_pressable.dart';

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

    return Scaffold(
      backgroundColor: L.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: L.text),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            Text(widget.profile.avatar, style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              'Unlock ${widget.profile.name}',
              style: TextStyle(
                fontFamily: 'Courier',
                color: L.text,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter profile PIN to switch',
              style: TextStyle(
                fontFamily: 'Courier',
                color: L.sub,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _enteredPin.length > index
                        ? L.primary
                        : Colors.transparent,
                    border: Border.all(
                      color: _error ? L.error : (_enteredPin.length > index ? L.primary : L.border),
                      width: 2,
                    ),
                  ),
                );
              }),
            ),
            if (_error) ...[
              const SizedBox(height: 16),
              Text('Incorrect PIN', style: TextStyle(color: L.error)),
            ],
            const Spacer(),
            _buildNumpad(L),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildNumpad(AppThemeColors L) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
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
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKey('4', L),
              _buildKey('5', L),
              _buildKey('6', L),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKey('7', L),
              _buildKey('8', L),
              _buildKey('9', L),
            ],
          ),
          const SizedBox(height: 24),
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
    return AnimatedPressable(
      onTap: () => _onKeyPress(value),
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: L.fill,
        ),
        child: Center(
          child: Text(
            value,
            style: TextStyle(
              fontFamily: 'Courier',
              color: L.text,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackspaceKey(AppThemeColors L) {
    return AnimatedPressable(
      onTap: _onBackspace,
      child: SizedBox(
        width: 72,
        height: 72,
        child: Center(
          child: Icon(Icons.backspace_outlined, color: L.text, size: 28),
        ),
      ),
    );
  }
}
