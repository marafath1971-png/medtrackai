import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uuid/uuid.dart';

import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../core/utils/haptic_engine.dart';
import '../../widgets/shared/shared_widgets.dart';

class AddDependentScreen extends StatefulWidget {
  const AddDependentScreen({super.key});

  @override
  State<AddDependentScreen> createState() => _AddDependentScreenState();
}

class _AddDependentScreenState extends State<AddDependentScreen> {
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _relationCtrl = TextEditingController();
  final TextEditingController _pinCtrl = TextEditingController();
  String _selectedAvatar = '👨‍⚕️';
  bool _isCritical = false;

  final List<String> _avatars = ['👨‍⚕️', '👩‍🦳', '👴', '👶', '👦', '👧', '🐶', '🐱'];

  void _save() {
    if (_nameCtrl.text.trim().isEmpty) return;

    HapticEngine.success();
    final newProfile = ManagedProfile(
      id: const Uuid().v4(),
      name: _nameCtrl.text.trim(),
      relation: _relationCtrl.text.trim().isEmpty ? 'Dependent' : _relationCtrl.text.trim(),
      avatar: _selectedAvatar,
      isCritical: _isCritical,
      pin: _pinCtrl.text.trim().isEmpty ? null : _pinCtrl.text.trim(),
    );

    context.read<AppState>().addDependent(newProfile);
    Navigator.pop(context);
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
          onTap: () => Navigator.pop(context),
          child: Icon(Icons.close_rounded, color: L.text),
        ),
        title: Text(
          'Add Dependent',
          style: AppTypography.titleMedium.copyWith(color: L.text),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Avatar', style: AppTypography.labelMedium.copyWith(color: L.sub)),
            const SizedBox(height: 12),
            SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _avatars.length,
                itemBuilder: (context, i) {
                  final avatar = _avatars[i];
                  final isSelected = _selectedAvatar == avatar;
                  return BouncingButton(
                    onTap: () {
                      HapticEngine.selection();
                      setState(() => _selectedAvatar = avatar);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      width: 60,
                      decoration: BoxDecoration(
                        color: isSelected ? L.primary.withValues(alpha: 0.1) : L.card,
                        border: Border.all(color: isSelected ? L.primary : L.border.withValues(alpha: 0.1)),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(avatar, style: const TextStyle(fontSize: 28)),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            Text('Name', style: AppTypography.labelMedium.copyWith(color: L.sub)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameCtrl,
              style: AppTypography.bodyLarge.copyWith(color: L.text),
              decoration: InputDecoration(
                hintText: 'e.g. Grandpa Joe',
                hintStyle: AppTypography.bodyLarge.copyWith(color: L.sub),
                filled: true,
                fillColor: L.card,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),
            Text('Relation', style: AppTypography.labelMedium.copyWith(color: L.sub)),
            const SizedBox(height: 8),
            TextField(
              controller: _relationCtrl,
              style: AppTypography.bodyLarge.copyWith(color: L.text),
              decoration: InputDecoration(
                hintText: 'e.g. Grandparent',
                hintStyle: AppTypography.bodyLarge.copyWith(color: L.sub),
                filled: true,
                fillColor: L.card,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Critical Profile', style: AppTypography.labelMedium.copyWith(color: L.text)),
                      Text('Prioritize alerts for this dependent', style: AppTypography.labelSmall.copyWith(color: L.sub)),
                    ],
                  ),
                ),
                Switch(
                  value: _isCritical,
                  activeThumbColor: L.primary,
                  onChanged: (val) {
                    HapticEngine.selection();
                    setState(() => _isCritical = val);
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('PIN Lock (Optional)', style: AppTypography.labelMedium.copyWith(color: L.sub)),
            const SizedBox(height: 8),
            TextField(
              controller: _pinCtrl,
              style: AppTypography.bodyLarge.copyWith(color: L.text),
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              decoration: InputDecoration(
                hintText: '4-digit PIN',
                hintStyle: AppTypography.bodyLarge.copyWith(color: L.sub),
                filled: true,
                fillColor: L.card,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 40),
            BouncingButton(
              onTap: _save,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [L.primary, L.secondary]),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: L.primary.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  'CREATE PROFILE',
                  style: AppTypography.labelMedium.copyWith(
                    color: L.onPrimary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
          ],
        ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0),
      ),
    );
  }
}
