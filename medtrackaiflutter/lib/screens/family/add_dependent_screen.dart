import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:go_router/go_router.dart';

import '../../providers/app_state.dart';
import '../../theme/med_ai_ui.dart';
import '../../core/utils/haptic_engine.dart';
import '../../widgets/common/animated_pressable.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/common/premium_page_header.dart';

class AddDependentScreen extends StatefulWidget {
  const AddDependentScreen({super.key});

  @override
  State<AddDependentScreen> createState() => _AddDependentScreenState();
}

class _AddDependentScreenState extends State<AddDependentScreen> {
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _relationCtrl = TextEditingController();
  final TextEditingController _pinCtrl = TextEditingController();
  IconData _selectedAvatar = Icons.health_and_safety_rounded;
  bool _isCritical = false;
  bool _isSaving = false;

  final List<Map<String, dynamic>> _avatars = [
    {'label': 'Caregiver', 'icon': Icons.health_and_safety_rounded},
    {'label': 'Senior', 'icon': Icons.elderly_rounded},
    {'label': 'Child', 'icon': Icons.child_care_rounded},
    {'label': 'Support', 'icon': Icons.support_agent_rounded},
    {'label': 'Pet', 'icon': Icons.pets_rounded},
    {'label': 'Other', 'icon': Icons.person_rounded},
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _relationCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  void _popOrGoCircle() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/circle');
    }
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      context.read<AppState>().showToast('Please enter a name', type: 'error');
      return;
    }

    final pinVal = _pinCtrl.text.trim();
    if (pinVal.isNotEmpty && pinVal.length < 4) {
      context.read<AppState>().showToast('PIN must be 4 digits', type: 'error');
      return;
    }

    setState(() => _isSaving = true);
    HapticEngine.success();

    try {
      final newProfile = ManagedProfile(
        id: const Uuid().v4(),
        name: name,
        relation: _relationCtrl.text.trim().isEmpty
            ? 'Caregiver / Dependent'
            : _relationCtrl.text.trim(),
        avatar: _selectedAvatar.codePoint.toString(),
        isCritical: _isCritical,
        pin: pinVal.isEmpty ? null : pinVal,
      );

      await context.read<AppState>().addFamilyMember(newProfile);

      if (mounted) _popOrGoCircle();
    } catch (e) {
      if (mounted) {
        context
            .read<AppState>()
            .showToast('Failed to save. Try again.', type: 'error');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;

    return AppScaffold(
      showAurora: true,
      body: CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverToBoxAdapter(
            child: PremiumPageHeader(
              title: 'Add Caregiver',
              subtitle: 'Invite someone to help with care',
              onBack: () {
                HapticEngine.selection();
                _popOrGoCircle();
              },
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p24, vertical: AppSpacing.p12),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const MedAiSectionHeader(title: 'Avatar'),
                const SizedBox(height: AppSpacing.p12),
                SizedBox(
                  height: 88,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _avatars.length,
                    clipBehavior: Clip.none,
                    itemBuilder: (context, i) {
                      final avatar = _avatars[i]['icon'] as IconData;
                      final label = _avatars[i]['label'] as String;
                      final isSelected = _selectedAvatar == avatar;

                      return Semantics(
                        button: true,
                        selected: isSelected,
                        label: label,
                        child: AnimatedPressable(
                          onTap: () {
                            HapticEngine.selection();
                            setState(() => _selectedAvatar = avatar);
                          },
                          child: AnimatedContainer(
                            duration: MedAiA11y.motion(
                                context, AppDurations.micro),
                            margin: const EdgeInsetsDirectional.only(end: AppSpacing.p12),
                            width: 72,
                            constraints: const BoxConstraints(
                                minHeight: MedAiA11y.minTapTarget),
                            decoration: BoxDecoration(
                              color: isSelected ? L.text : L.card,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? L.text
                                    : L.border.withValues(alpha: 0.1),
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: L.text.withValues(alpha: 0.15),
                                        blurRadius: 12,
                                        offset: const Offset(0, 6),
                                      )
                                    ]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  avatar,
                                  color: isSelected ? L.bg : L.text,
                                  size: 26,
                                ),
                                const SizedBox(height: AppSpacing.p4),
                                Text(
                                  label,
                                  style: AppTypography.labelSmall.copyWith(
                                    color: isSelected ? L.bg : L.sub,
                                    fontSize: 10,
                                    fontWeight: isSelected
                                        ? FontWeight.w900
                                        : FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.p32),
                _buildSectionHeader('BASIC DETAILS', L),
                const SizedBox(height: AppSpacing.p12),
                _buildInputField(
                  controller: _nameCtrl,
                  hint: 'Full Name (e.g. Dr. Sarah)',
                  icon: Icons.person_outline_rounded,
                  L: L,
                ),
                const SizedBox(height: AppSpacing.p16),
                _buildInputField(
                  controller: _relationCtrl,
                  hint: 'Role (e.g. Nurse, Grandparent)',
                  icon: Icons.assignment_ind_outlined,
                  L: L,
                ),
                const SizedBox(height: AppSpacing.p32),
                _buildSectionHeader('SECURITY & PREFERENCES', L),
                const SizedBox(height: AppSpacing.p12),
                MedAiDepthCard(
                  padding: const EdgeInsets.all(AppSpacing.p20),
                  child: Row(
                    children: [
                      Container(
                        width: MedAiA11y.minTapTargetCompact,
                        height: MedAiA11y.minTapTargetCompact,
                        decoration: BoxDecoration(
                          color: L.error.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.warning_amber_rounded,
                            color: L.error, size: 20),
                      ),
                      const SizedBox(width: AppSpacing.p16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Critical Profile',
                              style: AppTypography.labelMedium.copyWith(
                                color: L.text,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              'Prioritize notifications and alerts',
                              style: AppTypography.labelSmall.copyWith(
                                color: L.sub.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Semantics(
                        toggled: _isCritical,
                        label: 'Critical profile',
                        child: Switch.adaptive(
                          value: _isCritical,
                          activeTrackColor: L.error,
                          onChanged: (v) {
                            HapticEngine.selection();
                            setState(() => _isCritical = v);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.p16),
                _buildInputField(
                  controller: _pinCtrl,
                  hint: '4-Digit PIN (Optional)',
                  icon: Icons.lock_outline_rounded,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  obscureText: true,
                  L: L,
                ),
                const SizedBox(height: AppSpacing.p40),
                MedAiCTA(
                  label: 'Save Caregiver',
                  loading: _isSaving,
                  semanticsLabel: 'Save caregiver profile',
                  onTap: _isSaving ? null : _save,
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom + 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, dynamic L) {
    return Text(
      title,
      style: AppTypography.labelSmall.copyWith(
        fontFamily: 'Courier',
        color: L.sub.withValues(alpha: 0.6),
        fontWeight: FontWeight.w900,
        letterSpacing: 2.0,
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int? maxLength,
    TextInputType? keyboardType,
    bool obscureText = false,
    required dynamic L,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: L.card.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: L.border.withValues(alpha: 0.08)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
      constraints: const BoxConstraints(minHeight: MedAiA11y.minTapTarget),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: L.sub.withValues(alpha: 0.6), size: 22),
          const SizedBox(width: AppSpacing.p16),
          Expanded(
            child: TextField(
              controller: controller,
              maxLength: maxLength,
              keyboardType: keyboardType,
              obscureText: obscureText,
              buildCounter: (context,
                      {required currentLength,
                      required isFocused,
                      maxLength}) =>
                  null,
              style: AppTypography.labelMedium.copyWith(
                color: L.text,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: L.sub.withValues(alpha: 0.3)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.p16),
                isDense: true,
                counterText: '',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
