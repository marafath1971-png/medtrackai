import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_routes.dart';
import '../../providers/app_state.dart';
import '../../theme/med_ai_ui.dart';
import '../../core/utils/haptic_engine.dart';
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

  void _switchProfile(
      BuildContext context, ManagedProfile? profile, String? requiredPin) async {
    final state = context.read<AppState>();

    if (requiredPin != null && requiredPin.isNotEmpty) {
      final bioSuccess = await BiometricService.authenticate(
        reason: 'Authenticate to access ${profile?.name ?? "profile"}',
      );

      if (!bioSuccess) {
        if (!context.mounted) return;
        final pinSuccess = await context.push<bool>(
          AppRoutes.authPinVerify,
          extra: PinVerificationRouteArgs(
            correctPin: requiredPin,
            profileName: profile?.name ?? '',
          ),
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
    final reduceMotion = MedAiA11y.reducedMotion(context);
    final state = context.watch<AppState>();
    final familyMembers = state.profile?.familyMembers ?? [];
    final activeProfile = state.activeProfile;

    Widget content = Column(
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
          'Switch profile',
          style: AppTypography.headlineMedium.copyWith(
            color: L.text,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Manage schedules for your family',
          style: AppTypography.bodyMedium.copyWith(color: L.sub),
        ),
        const SizedBox(height: 24),
        _ProfileTile(
          name: state.profile?.name ?? 'My Profile',
          relation: 'Main Account',
          avatar: state.profile?.avatar ?? '😊',
          isActive: activeProfile == null,
          isLocked: false,
          onTap: () => _switchProfile(context, null, null),
        ),
        const SizedBox(height: 12),
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
            ),
          );
        }),
        const SizedBox(height: 12),
        Semantics(
          button: true,
          label: 'Add dependent',
          child: MedAiDepthCard(
            padding: const EdgeInsets.all(16),
            radius: AppRadius.l,
            onTap: () {
              HapticEngine.selection();
              Navigator.pop(context);
              context.push(AppRoutes.familyAddDependent);
            },
            child: Row(
              children: [
                Container(
                  width: MedAiA11y.minTapTargetCompact,
                  height: MedAiA11y.minTapTargetCompact,
                  decoration: BoxDecoration(
                    color: L.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.add_rounded, color: L.primary),
                ),
                const SizedBox(width: 16),
                Text(
                  'Add dependent',
                  style: AppTypography.bodyLarge.copyWith(
                      color: L.text, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    if (!reduceMotion) {
      content = content
          .animate()
          .fadeIn(duration: AppDurations.fast, curve: AppCurves.smooth)
          .slideY(begin: 0.1, end: 0, curve: AppCurves.smooth);
    }

    return ClipRRect(
      borderRadius:
          const BorderRadius.vertical(top: Radius.circular(AppRadius.squircle)),
      child: MedAiGlass(
        radius: AppRadius.squircle,
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        showBorder: false,
        child: SafeArea(child: content),
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

  const _ProfileTile({
    required this.name,
    required this.relation,
    required this.avatar,
    required this.isActive,
    required this.isLocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Semantics(
      button: true,
      selected: isActive,
      label: '$name, $relation${isLocked ? ', locked' : ''}',
      child: MedAiDepthCard(
        padding: const EdgeInsets.all(16),
        radius: AppRadius.l,
        color: isActive ? L.primary.withValues(alpha: 0.08) : null,
        onTap: () {
          HapticEngine.selection();
          onTap();
        },
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
                      Flexible(
                        child: Text(
                          name,
                          style: AppTypography.titleMedium.copyWith(
                            color: L.text,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isLocked) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.lock_rounded, size: 14, color: L.sub),
                      ],
                    ],
                  ),
                  Text(relation,
                      style: AppTypography.labelSmall.copyWith(color: L.sub)),
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
