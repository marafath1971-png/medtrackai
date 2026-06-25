import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'dart:ui';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../../providers/app_state.dart';
import '../../../theme/app_theme.dart';
import '../../../core/utils/haptic_engine.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../widgets/common/app_shimmer.dart';
import 'package:medai/widgets/common/animated_pressable.dart';

class AddFamilyMemberScreen extends StatefulWidget {
  const AddFamilyMemberScreen({super.key});

  @override
  State<AddFamilyMemberScreen> createState() => _AddFamilyMemberScreenState();
}

class _AddFamilyMemberScreenState extends State<AddFamilyMemberScreen> {
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();
  final _pinController = TextEditingController();
  String? _photoPath;
  String _selectedRole = 'Child';
  IconData _selectedIcon = Icons.child_care_rounded;
  String _gender = 'Male';
  DateTime? _dob;
  bool _isCritical = false;
  bool _isSaving = false;

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
      final newMember = ManagedProfile(
        id: const Uuid().v4(),
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

      await context.read<AppState>().addFamilyMember(newMember);
      
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

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Scaffold(
      backgroundColor: L.meshBg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              color: L.meshBg.withValues(alpha: 0.5),
            ),
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: L.text),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Add Member',
          style: AppTypography.labelLarge.copyWith(
            color: L.text,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Background subtle glowing orb for premium feel
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: L.text.withValues(alpha: 0.05),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(begin: 0.9, end: 1.1, duration: 4.seconds),
          ),
          SafeArea(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar Preview & Role
                  Center(
                    child: Column(
                      children: [
                        AnimatedPressable(
                          onTap: _pickImage,
                          child: Container(
                            width: 100,
                            height: 100,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [L.text.withValues(alpha: 0.3), L.text.withValues(alpha: 0.05)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: L.card,
                                border: Border.all(color: L.border.withValues(alpha: 0.1)),
                              ),
                              child: Center(
                                child: _photoPath != null
                                    ? ClipOval(
                                        child: Image.file(
                                          File(_photoPath!),
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : Icon(
                                        _selectedIcon,
                                        size: 46,
                                        color: L.text,
                                      ),
                              ),
                            ),
                          ),
                        ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: L.text.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            'Tap to add photo',
                            style: AppTypography.labelSmall.copyWith(
                              color: L.text.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _selectedRole.toUpperCase(),
                          style: AppTypography.labelSmall.copyWith(
                            fontFamily: 'Courier',
                            color: L.sub.withValues(alpha: 0.5),
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Basic Info Section
                  _buildSectionHeader('BASIC INFORMATION', L),
                  const SizedBox(height: 16),
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
                  const SizedBox(height: 40),

                  // Role Selector Grid
                  _buildSectionHeader('RELATIONSHIP', L),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 2.2,
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
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: isSelected ? 0 : 20, sigmaY: isSelected ? 0 : 20),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOutCubic,
                              decoration: BoxDecoration(
                                color: isSelected ? L.text : L.card.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected ? L.text : L.border.withValues(alpha: 0.1),
                                ),
                                boxShadow: isSelected ? [
                                  BoxShadow(color: L.text.withValues(alpha: 0.2), blurRadius: 16, offset: const Offset(0, 6))
                                ] : [],
                              ),
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      role['icon'],
                                      size: 18,
                                      color: isSelected ? L.bg : L.text,
                                    ),
                                    const SizedBox(width: 10),
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
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 40),

                  // Medical Notes
                  _buildSectionHeader('MEDICAL NOTES / ALLERGIES', L),
                  const SizedBox(height: 16),
                  _buildInputField(
                    controller: _notesController,
                    hint: 'e.g. Penicillin allergy, diabetic...',
                    maxLines: 3,
                    L: L,
                  ),
                  const SizedBox(height: 40),

                  // PIN Code
                  _buildSectionHeader('PIN CODE (OPTIONAL)', L),
                  const SizedBox(height: 16),
                  _buildInputField(
                    controller: _pinController,
                    hint: '4-digit PIN (e.g. 1234)',
                    maxLines: 1,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    L: L,
                  ),
                  const SizedBox(height: 40),

                  // Critical Care Toggle
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: L.card.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: L.border.withValues(alpha: 0.1)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Critical Care Member',
                                    style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w900, color: L.text),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Prioritize alerts and monitoring',
                                    style: AppTypography.labelSmall.copyWith(color: L.sub.withValues(alpha: 0.6)),
                                  ),
                                ],
                              ),
                            ),
                            Switch.adaptive(
                              value: _isCritical,
                              activeTrackColor: L.text,
                              onChanged: (v) => setState(() => _isCritical = v),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            padding: EdgeInsets.only(
              left: 24, 
              right: 24, 
              top: 16, 
              bottom: MediaQuery.of(context).padding.bottom + 16,
            ),
            decoration: BoxDecoration(
              color: L.meshBg.withValues(alpha: 0.6),
              border: Border(
                top: BorderSide(color: L.border.withValues(alpha: 0.1)),
              )
            ),
            child: SizedBox(
              width: double.infinity,
              height: 64,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: L.text,
                  foregroundColor: L.bg,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                  elevation: 0,
                  shadowColor: Colors.transparent,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: AppShimmer(
                          width: 24,
                          height: 24,
                          shape: BoxShape.circle,
                        ),
                      )
                    : Text(
                        'Confirm Member',
                        style: AppTypography.labelLarge.copyWith(
                          fontFamily: 'Courier',
                          fontWeight: FontWeight.w900,
                          color: L.bg,
                          letterSpacing: 1.5,
                        ),
                      ),
              ),
            ).animate().slideY(begin: 1.0, end: 0, duration: 400.ms, curve: Curves.easeOutCubic),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, dynamic L) {
    return Text(
      title,
      style: AppTypography.labelSmall.copyWith(
        fontFamily: 'Courier',
        color: L.sub.withValues(alpha: 0.5),
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: L.card.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: L.border.withValues(alpha: 0.1)),
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
        ),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: L.card.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: L.border.withValues(alpha: 0.1)),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: L.card.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: L.border.withValues(alpha: 0.1)),
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
        ),
      ),
    );
  }
}
