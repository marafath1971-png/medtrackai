import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../theme/med_ai_ui.dart';
import '../../widgets/common/animated_pressable.dart';
import '../../core/utils/haptic_engine.dart';

class AddMedicationScreen extends StatefulWidget {
  const AddMedicationScreen({super.key});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _showSuggestions = false;
  String _selectedSchedule = 'Every day';
  bool _remindMe = true;

  final List<String> _scheduleOptions = [
    'Every day',
    'Specific days',
    'As needed',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final reduceMotion = MedAiA11y.reducedMotion(context);

    return Scaffold(
      backgroundColor: L.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                AppSpacing.p8,
                AppSpacing.gutter,
                AppSpacing.p8,
              ),
              child: Row(
                children: [
                  Semantics(
                    button: true,
                    label: 'Close',
                    child: AnimatedPressable(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: L.fill,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close_rounded, color: L.text, size: 20),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Add medicine',
                    style: AppTypography.titleMedium.copyWith(
                      color: L.text,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 44),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.gutter,
                  AppSpacing.p16,
                  AppSpacing.gutter,
                  AppSpacing.p32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What are you taking?',
                      style: AppTypography.displaySmall.copyWith(
                        color: L.text,
                        fontWeight: FontWeight.w800,
                        fontSize: 28,
                        letterSpacing: -0.6,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.p8),
                    Text(
                      'Search or type the medicine name to get started.',
                      style: AppTypography.bodyMedium.copyWith(color: L.sub),
                    ),
                    const SizedBox(height: AppSpacing.p24),

                    // Name input
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.p16),
                      decoration: BoxDecoration(
                        color: AppColors.pastelSky,
                        borderRadius: BorderRadius.circular(AppRadius.l),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Medication name',
                            style: AppTypography.labelSmall.copyWith(
                              color: L.sub,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextField(
                            controller: _nameController,
                            onChanged: (val) {
                              setState(() => _showSuggestions = val.isNotEmpty);
                            },
                            style: AppTypography.headlineSmall.copyWith(
                              color: L.text,
                              fontWeight: FontWeight.w800,
                            ),
                            decoration: InputDecoration(
                              hintText: 'e.g. Lisinopril',
                              hintStyle: AppTypography.headlineSmall.copyWith(
                                color: L.sub.withValues(alpha: 0.35),
                                fontWeight: FontWeight.w700,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.only(
                                top: AppSpacing.p8,
                                bottom: AppSpacing.p4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (_showSuggestions)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.p8),
                        child: Container(
                          decoration: BoxDecoration(
                            color: L.card,
                            borderRadius: BorderRadius.circular(AppRadius.l),
                            border: Border.all(
                              color: L.border.withValues(alpha: 0.35),
                              width: 0.7,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: [
                              _buildSuggestionItem(
                                'Lisinopril 10mg',
                                Icons.medication_rounded,
                              ),
                              Divider(
                                height: 1,
                                color: L.border.withValues(alpha: 0.25),
                              ),
                              _buildSuggestionItem(
                                'Lisinopril 20mg',
                                Icons.medication_rounded,
                              ),
                              Divider(
                                height: 1,
                                color: L.border.withValues(alpha: 0.25),
                              ),
                              _buildSuggestionItem(
                                'Lisinopril-HCTZ',
                                Icons.medication_liquid_rounded,
                              ),
                            ],
                          ),
                        ),
                      )
                          .animate(
                            target: reduceMotion ? 0 : 1,
                          )
                          .fade(duration: 200.ms)
                          .slideY(begin: -0.06, end: 0),

                    const SizedBox(height: AppSpacing.p32),

                    Text(
                      'Schedule',
                      style: AppTypography.titleMedium.copyWith(
                        color: L.text,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.p4),
                    Text(
                      'When do you take this?',
                      style: AppTypography.bodySmall.copyWith(color: L.sub),
                    ),
                    const SizedBox(height: AppSpacing.p16),

                    Wrap(
                      spacing: AppSpacing.p8,
                      runSpacing: AppSpacing.p8,
                      children: _scheduleOptions.map((option) {
                        final isSelected = _selectedSchedule == option;
                        return AnimatedPressable(
                          onTap: () {
                            HapticEngine.selection();
                            setState(() => _selectedSchedule = option);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.p16,
                              vertical: AppSpacing.p12,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? L.text
                                  : AppColors.pastelMint,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.max),
                            ),
                            child: Text(
                              option,
                              style: AppTypography.labelLarge.copyWith(
                                color: isSelected ? L.bg : L.text,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: AppSpacing.p24),

                    Container(
                      padding: const EdgeInsets.all(AppSpacing.p16),
                      decoration: BoxDecoration(
                        color: AppColors.pastelLilac,
                        borderRadius: BorderRadius.circular(AppRadius.l),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Remind me',
                                  style: AppTypography.titleMedium.copyWith(
                                    color: L.text,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.p4),
                                Text(
                                  'Get a notification when it’s time',
                                  style: AppTypography.bodySmall
                                      .copyWith(color: L.sub),
                                ),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: _remindMe,
                            activeThumbColor: L.accent,
                            onChanged: (val) {
                              HapticEngine.selection();
                              setState(() => _remindMe = val);
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.p40),

                    MedAiCTA(
                      label: 'Add medication',
                      icon: Icons.check_rounded,
                      onTap: () {
                        HapticEngine.success();
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionItem(String name, IconData icon) {
    final L = context.L;
    return AnimatedPressable(
      onTap: () {
        HapticEngine.selection();
        setState(() {
          _nameController.text = name;
          _showSuggestions = false;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.p16,
          vertical: AppSpacing.p12,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.pastelMint,
                borderRadius: BorderRadius.circular(AppRadius.s),
              ),
              child: Icon(icon, color: L.text, size: 18),
            ),
            const SizedBox(width: AppSpacing.p12),
            Expanded(
              child: Text(
                name,
                style: AppTypography.titleMedium.copyWith(
                  color: L.text,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.north_east_rounded,
                size: 16, color: L.sub.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}
