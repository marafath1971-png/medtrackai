import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import '../../../app/app_routes.dart';
import '../../../providers/app_state.dart';
import '../../../theme/med_ai_ui.dart';
import '../../../widgets/common/animated_pressable.dart';
import '../../../core/utils/haptic_engine.dart';

class ProfileSelectorRibbon extends StatelessWidget {
  const ProfileSelectorRibbon({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final primaryProfile = state.profile;
    final familyMembers = primaryProfile?.familyMembers ?? [];
    final activeProfile = state.activeProfile;
    final L = context.L;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p16, vertical: AppSpacing.p8),
      child: MedAiGlass(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p4, vertical: AppSpacing.p8),
        radius: 20,
        child: SizedBox(
          height: 42,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.only(start: AppSpacing.p12),
                child: Icon(
                  Icons.people_alt_rounded,
                  size: 16,
                  color: L.sub.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(width: AppSpacing.p8),
              Expanded(
                child: ListView.builder(
  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: familyMembers.length + 2, // Primary + Members + Add
                  itemBuilder: (context, index) {
                    // 1. Primary Profile ("Me")
                    if (index == 0) {
                      final isSelected = activeProfile == null;
                      return _ProfileAvatar(
                        name: 'Me',
                        isSelected: isSelected,
                        onTap: () => state.switchProfile(null),
                        color: L.accent,
                      );
                    }

                    // 2. Family Members
                    if (index <= familyMembers.length) {
                      final member = familyMembers[index - 1];
                      final isSelected = activeProfile?.id == member.id;

                      return _ProfileAvatar(
                        name: member.name,
                        avatar: member.avatar,
                        photoPath: member.photoPath,
                        isCritical: member.isCritical,
                        isSelected: isSelected,
                        onTap: () {
                          if (member.pin != null && member.pin!.isNotEmpty) {
                            _showPinGateDialog(context, member, state);
                          } else {
                            state.switchProfile(member);
                          }
                        },
                        color: _getProfileColor(index),
                      );
                    }

                    // 3. Add Button
                    return _AddProfileButton(
                      onTap: () {
                        HapticEngine.selection();
                        context.push(AppRoutes.familyAddMemberPath(dialog: true));
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPinGateDialog(BuildContext context, ManagedProfile member, AppState state) {
    final L = context.L;
    final pinController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: MedAiGlass(
            padding: const EdgeInsets.all(AppSpacing.p24),
            radius: 28,
            child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Enter PIN',
                    style: AppTypography.titleMedium.copyWith(
                      color: L.text,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.p8),
                  Text(
                    'Enter PIN for ${member.name}',
                    style: AppTypography.labelSmall.copyWith(
                      color: L.sub.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.p20),
                  TextField(
                    controller: pinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 4,
                    textAlign: TextAlign.center,
                    autofocus: true,
                    style: TextStyle(
                      color: L.text,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '••••',
                      hintStyle: TextStyle(
                        color: L.sub.withValues(alpha: 0.2),
                        letterSpacing: 8,
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: L.border.withValues(alpha: 0.2)),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: L.text),
                      ),
                    ),
                    onChanged: (val) {
                      if (val.length == 4) {
                        if (val == member.pin) {
                          HapticEngine.selection();
                          Navigator.of(context).pop();
                          state.switchProfile(member);
                        } else {
                          HapticEngine.error();
                          pinController.clear();
                          state.showToast('Incorrect PIN', type: 'error');
                        }
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.p16),
                ],
              ),
            ),
          );
      },
    );
  }

  Color _getProfileColor(int index) {
    final colors = [
      const Color(0xFF3A7D6A), // Sage Green
      const Color(0xFFC07B65), // Terracotta
      const Color(0xFF8E9B7B), // Olive
      const Color(0xFFD4B26F), // Muted Amber
      const Color(0xFF9E8A78), // Earth Brown
    ];
    return colors[index % colors.length];
  }
}

class _ProfileAvatar extends StatelessWidget {
  final String name;
  final String? avatar;
  final String? photoPath;
  final bool isCritical;
  final bool isSelected;
  final VoidCallback onTap;
  final Color color;

  const _ProfileAvatar({
    required this.name,
    this.avatar,
    this.photoPath,
    this.isCritical = false,
    required this.isSelected,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Semantics(
      button: true,
      selected: isSelected,
      label: 'Switch to $name profile',
      child: AnimatedPressable(
        onTap: () {
          HapticEngine.selection();
          onTap();
        },
        child: AnimatedContainer(
          duration: MedAiA11y.motion(context, const Duration(milliseconds: 250)),
          curve: Curves.easeOutQuart,
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.p4),
          constraints: const BoxConstraints(minHeight: MedAiA11y.minTapTarget),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p12, vertical: AppSpacing.p4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: isSelected ? L.accent : Colors.transparent,
          border: Border.all(
            color: isSelected
                ? L.accent
                : (isCritical
                    ? L.error.withValues(alpha: 0.35)
                    : L.border.withValues(alpha: 0.35)),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? Colors.white.withValues(alpha: 0.2) : L.card,
                    border: Border.all(
                      color: isSelected 
                          ? Colors.white.withValues(alpha: 0.3) 
                          : L.border.withValues(alpha: 0.1),
                      width: 0.5,
                    ),
                  ),
                  child: Center(
                    child: photoPath != null && photoPath!.isNotEmpty && File(photoPath!).existsSync()
                        ? ClipOval(
                            child: Image.file(
                              File(photoPath!),
                              width: 28,
                              height: 28,
                              fit: BoxFit.cover,
                            ),
                          )
                        : (avatar != null && avatar!.isNotEmpty
                            ? (int.tryParse(avatar!) != null
                                ? Icon(
                                    Icons.person_rounded,
                                    size: 16,
                                    color: isSelected ? Colors.white : L.text,
                                  )
                                : Text(
                                    avatar!,
                                    style: const TextStyle(fontSize: 16),
                                  ))
                            : Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                style: TextStyle(
                                  color: isSelected ? Colors.white : L.text,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              )),
                  ),
                ),
                if (isCritical)
                  PositionedDirectional(
                    top: -2,
                    end: -2,
                    child: ExcludeSemantics(
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: AppSpacing.p8),
            Text(
              name,
              style: AppTypography.labelSmall.copyWith(
                fontSize: 12,
                color: isSelected ? Colors.white : L.text.withValues(alpha: 0.8),
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}

class _AddProfileButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddProfileButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Semantics(
      button: true,
      label: 'Add family profile',
      child: AnimatedPressable(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.p4),
          constraints:
              const BoxConstraints(minHeight: MedAiA11y.minTapTarget),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p12, vertical: AppSpacing.p4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: L.fill.withValues(alpha: 0.15),
          border: Border.all(
            color: L.border.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: L.fill.withValues(alpha: 0.3),
              ),
              child: Icon(Icons.add_rounded, color: L.sub, size: 14),
            ),
            const SizedBox(width: AppSpacing.p8),
            Text(
              'Add',
              style: AppTypography.labelSmall.copyWith(
                fontSize: 12,
                color: L.sub.withValues(alpha: 0.8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}
