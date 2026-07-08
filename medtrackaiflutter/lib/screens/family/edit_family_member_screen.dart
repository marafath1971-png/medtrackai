import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../../providers/app_state.dart';
import '../../../theme/med_ai_ui.dart';
import '../../../core/utils/haptic_engine.dart';
import '../../../widgets/common/animated_pressable.dart';
import '../../../widgets/common/app_scaffold.dart';
import '../../../widgets/common/premium_page_header.dart';

class EditFamilyMemberScreen extends StatefulWidget {
  final ManagedProfile member;
  const EditFamilyMemberScreen({super.key, required this.member});

  @override
  State<EditFamilyMemberScreen> createState() => _EditFamilyMemberScreenState();
}

class _EditFamilyMemberScreenState extends State<EditFamilyMemberScreen> {
  late TextEditingController _nameController;
  late TextEditingController _notesController;
  late TextEditingController _pinController;
  String? _photoPath;
  late String _selectedRole;
  late IconData _selectedIcon;
  String _gender = 'Male';
  DateTime? _dob;
  late bool _isCritical;
  bool _isSaving = false;

  final List<Map<String, dynamic>> _roles = [
    {'label': 'Child', 'icon': Icons.child_care_rounded},
    {'label': 'Spouse', 'icon': Icons.favorite_rounded},
    {'label': 'Parent', 'icon': Icons.family_restroom_rounded},
    {'label': 'Senior', 'icon': Icons.elderly_rounded},
    {'label': 'Sibling', 'icon': Icons.people_rounded},
    {'label': 'Guardian', 'icon': Icons.admin_panel_settings_rounded},
    {'label': 'Pet', 'icon': Icons.pets_rounded},
    {'label': 'Other', 'icon': Icons.person_rounded},
  ];

  @override
  void initState() {
    super.initState();
    final m = widget.member;
    _nameController = TextEditingController(text: m.name);
    _notesController = TextEditingController(text: m.notes);
    _pinController = TextEditingController(text: m.pin ?? '');
    _photoPath = m.photoPath;
    _selectedRole = m.relation;
    _dob = m.dateOfBirth;
    _gender = m.gender ?? 'Male';
    _isCritical = m.isCritical;

    _selectedIcon = Icons.person_rounded;
  }

  Future<void> _pickImage() async {
    HapticEngine.selection();
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}${p.extension(picked.path)}';
      final savedFile = await File(picked.path).copy(p.join(appDir.path, fileName));
      setState(() {
        _photoPath = savedFile.path;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 5),
      firstDate: DateTime(1900),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.black,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _dob = picked);
    }
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      context.read<AppState>().showToast('Please enter a name', type: 'error');
      return;
    }

    if (_dob == null) {
      context.read<AppState>().showToast('Please select a date of birth', type: 'error');
      return;
    }

    final pinVal = _pinController.text.trim();
    if (pinVal.isNotEmpty && pinVal.length < 4) {
      context.read<AppState>().showToast('PIN must be 4 digits', type: 'error');
      return;
    }

    setState(() => _isSaving = true);
    HapticEngine.selection();

    try {
      final updatedMember = widget.member.copyWith(
        name: name,
        relation: _selectedRole,
        avatar: _selectedIcon.codePoint.toString(),
        dateOfBirth: _dob,
        gender: _gender,
        notes: _notesController.text.trim(),
        isCritical: _isCritical,
        pin: pinVal.isEmpty ? null : pinVal,
        photoPath: _photoPath,
      );

      await context.read<AppState>().updateFamilyMember(updatedMember);
      
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        context.read<AppState>().showToast('Failed to save. Try again.', type: 'error');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _handleDelete() async {
    HapticEngine.heavyImpact();
    // Use the 2026 custom alert dialog instead of standard!
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.L.bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Remove Member', style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.w900)),
        content: Text('Are you sure you want to remove ${widget.member.name} from your protectors? This action cannot be undone.', style: AppTypography.bodySmall),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: context.L.sub)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<AppState>().removeFamilyMember(widget.member.id);
              if (mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: context.L.error, foregroundColor: Colors.white),
            child: const Text('Remove'),
          )
        ],
      )
    );
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
              title: 'Edit Member',
              subtitle: widget.member.name,
              onBack: () {
                HapticEngine.selection();
                Navigator.of(context).pop();
              },
              trailing: Semantics(
                button: true,
                label: 'Remove member',
                child: AnimatedPressable(
                  onTap: _handleDelete,
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: L.error.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: L.error.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      color: L.error,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
            // Avatar Preview & Role
            Center(
              child: Column(
                children: [
                  Semantics(
                    button: true,
                    label: 'Change profile photo',
                    child: AnimatedPressable(
                      onTap: _pickImage,
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: L.card,
                          boxShadow: AppShadows.soft,
                          border: Border.all(
                              color: L.border.withValues(alpha: 0.1)),
                        ),
                        child: Center(
                          child: _photoPath != null
                              ? ClipOval(
                                  child: Image.file(
                                    File(_photoPath!),
                                    width: 90,
                                    height: 90,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Icon(
                                  _selectedIcon,
                                  size: 42,
                                  color: L.text,
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap to change photo',
                    style: TextStyle(color: L.sub.withValues(alpha: 0.4), fontSize: 11),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _selectedRole.toUpperCase(),
                    style: AppTypography.labelSmall.copyWith(
                      fontFamily: 'Courier',
                      color: L.sub.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Basic Info Section
            _buildSectionHeader('BASIC INFORMATION', L),
            const SizedBox(height: 12),
            _buildInputField(
              controller: _nameController,
              hint: 'Full Name',
              L: L,
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildSelectorField(
                    label: _dob == null ? 'Date of Birth' : '${_dob!.day}/${_dob!.month}/${_dob!.year}',
                    icon: Icons.calendar_today_rounded,
                    onTap: _selectDate,
                    L: L,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildGenderPicker(L),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Role Selector Grid
            _buildSectionHeader('RELATIONSHIP', L),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.4,
              children: _roles.map((role) {
                final isSelected = _selectedRole == role['label'];
                return AnimatedPressable(
                  onTap: () {
                    HapticEngine.selection();
                    setState(() {
                      _selectedRole = role['label']!;
                      _selectedIcon = role['icon'];
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected ? L.text : L.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? L.text : L.border.withValues(alpha: 0.1),
                      ),
                      boxShadow: isSelected ? [
                        BoxShadow(color: L.text.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 6))
                      ] : null,
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            role['icon'],
                            size: 16,
                            color: isSelected ? L.bg : L.text,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            role['label']!,
                            style: AppTypography.labelSmall.copyWith(
                              fontFamily: 'Courier',
                              color: isSelected ? L.bg : L.text,
                              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // Medical Notes
            _buildSectionHeader('MEDICAL NOTES / ALLERGIES', L),
            const SizedBox(height: 12),
            _buildInputField(
              controller: _notesController,
              hint: 'e.g. Penicillin allergy, diabetic...',
              maxLines: 3,
              L: L,
            ),
            const SizedBox(height: 24),

            // PIN Code
            _buildSectionHeader('PIN CODE (OPTIONAL)', L),
            const SizedBox(height: 12),
            _buildInputField(
              controller: _pinController,
              hint: '4-digit PIN (e.g. 1234)',
              maxLines: 1,
              keyboardType: TextInputType.number,
              maxLength: 4,
              L: L,
            ),
            const SizedBox(height: 24),

            // Critical Care Toggle
            MedAiDepthCard(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Critical Care Member',
                          style: AppTypography.labelMedium.copyWith(
                              fontWeight: FontWeight.w900, color: L.text),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Prioritize alerts and monitoring',
                          style: AppTypography.labelSmall
                              .copyWith(color: L.sub.withValues(alpha: 0.6)),
                        ),
                      ],
                    ),
                  ),
                  Semantics(
                    toggled: _isCritical,
                    label: 'Critical care member',
                    child: Switch.adaptive(
                      value: _isCritical,
                      activeTrackColor: L.text,
                      onChanged: (v) => setState(() => _isCritical = v),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            MedAiCTA(
              label: 'Update member',
              loading: _isSaving,
              semanticsLabel: 'Save family member changes',
              onTap: _isSaving ? null : _handleSave,
            ),
            const SizedBox(height: 40),
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
    int maxLines = 1,
    TextInputType? keyboardType,
    int? maxLength,
    required dynamic L,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: L.card.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: L.border.withValues(alpha: 0.08)),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        maxLength: maxLength,
        buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: L.sub.withValues(alpha: 0.3)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
          counterText: '',
        ),
        style: AppTypography.labelMedium.copyWith(color: L.text, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildSelectorField({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required dynamic L,
  }) {
    return AnimatedPressable(
      onTap: onTap,
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: L.card.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: L.border.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: L.sub.withValues(alpha: 0.6)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: label.contains('/') ? L.text : L.sub.withValues(alpha: 0.5),
                  fontWeight: label.contains('/') ? FontWeight.w800 : FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderPicker(dynamic L) {
    return AnimatedPressable(
      onTap: () {
        HapticEngine.selection();
        setState(() => _gender = _gender == 'Male' ? 'Female' : 'Male');
      },
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: L.card.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: L.border.withValues(alpha: 0.08)),
        ),
        child: Center(
          child: Text(
            _gender.toUpperCase(),
            style: AppTypography.labelSmall.copyWith(
              fontFamily: 'Courier',
              color: L.text,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}
