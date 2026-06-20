import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:ui';
import '../../../providers/app_state.dart';
import '../../../theme/app_theme.dart';
import '../../../core/utils/haptic_engine.dart';
import '../../../widgets/shared/shared_widgets.dart';
import '../../family/add_family_member_screen.dart';

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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          height: 42,
          child: Row(
            children: [
              // Subtle dynamic indicator or title icon
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '🫂',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              VerticalDivider(
                color: L.border.withValues(alpha: 0.15),
                thickness: 1,
                width: 12,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: ListView.builder(
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
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const AddFamilyMemberScreen(),
                            fullscreenDialog: true,
                          ),
                        );
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
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: L.bg.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: L.border.withValues(alpha: 0.15)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 32,
                    offset: const Offset(0, 16),
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Security Gate 🚨',
                    style: AppTypography.labelLarge.copyWith(
                      color: L.text,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter PIN for ${member.name}',
                    style: AppTypography.labelSmall.copyWith(
                      color: L.sub.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 20),
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
                  const SizedBox(height: 16),
                ],
              ),
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
    return GestureDetector(
      onTap: () {
        HapticEngine.selection();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutQuart,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: isSelected
              ? LinearGradient(
                  colors: [color, color.withValues(alpha: 0.85)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : L.fill.withValues(alpha: 0.3),
          border: Border.all(
            color: isSelected
                ? color.withValues(alpha: 0.3)
                : (isCritical ? Colors.red.withValues(alpha: 0.4) : L.border.withValues(alpha: 0.1)),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? Colors.white.withValues(alpha: 0.2) : L.card,
                    border: Border.all(
                      color: isSelected ? Colors.white.withValues(alpha: 0.3) : L.border.withValues(alpha: 0.1),
                      width: 0.5,
                    ),
                  ),
                  child: Center(
                    child: photoPath != null && photoPath!.isNotEmpty && File(photoPath!).existsSync()
                        ? ClipOval(
                            child: Image.file(
                              File(photoPath!),
                              width: 24,
                              height: 24,
                              fit: BoxFit.cover,
                            ),
                          )
                        : (avatar != null && avatar!.isNotEmpty
                            ? (int.tryParse(avatar!) != null
                                ? Icon(
                                    IconData(int.parse(avatar!),
                                        fontFamily: 'MaterialIcons'),
                                    size: 14,
                                    color: isSelected ? Colors.white : L.text,
                                  )
                                : Text(
                                    avatar!,
                                    style: const TextStyle(fontSize: 14),
                                  ))
                            : Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                style: TextStyle(
                                  color: isSelected ? Colors.white : L.text,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 11,
                                ),
                              )),
                  ),
                ),
                if (isCritical)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 6),
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
    );
  }
}

class _AddProfileButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddProfileButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
            const SizedBox(width: 6),
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
    );
  }
}
