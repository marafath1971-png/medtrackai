import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../core/utils/haptic_engine.dart';
import '../../widgets/shared/shared_widgets.dart';
import '../auth/pin_verification_screen.dart';
import 'add_dependent_screen.dart';
import '../../services/biometric_service.dart';

class ProfileSwitcherSheet extends StatelessWidget {
  const ProfileSwitcherSheet({super.key});

  static void show(BuildContext context) {
    HapticEngine.selection();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (c) => const ProfileSwitcherSheet(),
    );
  }

  void _switchProfile(BuildContext context, ManagedProfile? profile, String? requiredPin) async {
    final state = context.read<AppState>();
    
    if (requiredPin != null && requiredPin.isNotEmpty) {
      // 1. Try Biometrics first
      final bioSuccess = await BiometricService.authenticate(
        reason: 'Authenticate to access ${profile?.name ?? "profile"}',
      );
      
      // 2. If biometric fails or cancelled, fallback to PIN
      if (!bioSuccess) {
        if (!context.mounted) return;
        final pinSuccess = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PinVerificationScreen(correctPin: requiredPin, profileName: profile?.name ?? '')),
        );
        if (pinSuccess != true) return;
      }
    }

    HapticEngine.success();
    state.setActiveProfile(profile);
    if (!context.mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final state = context.watch<AppState>();
    final familyMembers = state.profile?.familyMembers ?? [];
    final activeProfile = state.activeProfile;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        decoration: BoxDecoration(
          color: L.bg.withValues(alpha: 0.8),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(color: L.border.withValues(alpha: 0.1)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: L.border.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Switch Profile',
                style: AppTypography.headlineMedium.copyWith(
                  color: L.text,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Manage schedules for your family',
                style: AppTypography.bodyMedium.copyWith(color: L.sub),
              ),
              const SizedBox(height: 24),

              // Main User Profile
              _ProfileTile(
                name: state.profile?.name ?? 'My Profile',
                relation: 'Main Account',
                avatar: state.profile?.avatar ?? '😊',
                isActive: activeProfile == null,
                isLocked: false,
                onTap: () => _switchProfile(context, null, null),
                L: L,
              ),

              const SizedBox(height: 12),
              
              // Dependents
              ...familyMembers.map((member) {
                final isLocked = member.pin != null && member.pin!.isNotEmpty;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ProfileTile(
                    name: member.name,
                    relation: member.relation,
                    avatar: member.avatar,
                    isActive: activeProfile?.id == member.id,
                    isLocked: isLocked,
                    onTap: () => _switchProfile(context, member, member.pin),
                    L: L,
                  ),
                );
              }),

              const SizedBox(height: 12),

              BouncingButton(
                onTap: () {
                  HapticEngine.selection();
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddDependentScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: L.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: L.border.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: L.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.add_rounded, color: L.primary),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Add Dependent',
                        style: AppTypography.bodyLarge.copyWith(color: L.text, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ).animate().fadeIn().slideY(begin: 0.1, end: 0),
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final String name;
  final String relation;
  final String avatar;
  final bool isActive;
  final bool isLocked;
  final VoidCallback onTap;
  final AppThemeColors L;

  const _ProfileTile({
    required this.name,
    required this.relation,
    required this.avatar,
    required this.isActive,
    required this.isLocked,
    required this.onTap,
    required this.L,
  });

  @override
  Widget build(BuildContext context) {
    return BouncingButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive ? L.primary.withValues(alpha: 0.1) : L.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? L.primary : L.border.withValues(alpha: 0.1),
            width: isActive ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(avatar, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        name,
                        style: AppTypography.titleMedium.copyWith(
                          color: L.text,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (isLocked) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.lock_rounded, size: 14, color: L.sub),
                      ],
                    ],
                  ),
                  Text(relation, style: AppTypography.labelSmall.copyWith(color: L.sub)),
                ],
              ),
            ),
            if (isActive)
              Icon(Icons.check_circle_rounded, color: L.primary),
          ],
        ),
      ),
    );
  }
}
