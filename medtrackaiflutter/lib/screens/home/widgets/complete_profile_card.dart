import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../providers/app_state.dart';
import '../../../theme/med_ai_ui.dart';
import '../../../models/constants.dart';
import '../../../core/utils/haptic_engine.dart';

class CompleteProfileCard extends StatelessWidget {
  const CompleteProfileCard({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final profile = state.profile;
    if (profile == null) return const SizedBox.shrink();

    final List<_ProfileTask> tasks = [
      _ProfileTask(
        id: 'age',
        title: 'Add your age',
        subtitle: 'For better health insights',
        icon: Icons.cake_rounded,
        isDone: profile.age.isNotEmpty,
        onTap: () => _showAgePicker(context, state),
      ),
      _ProfileTask(
        id: 'gender',
        title: 'Set your gender',
        subtitle: 'Personalises your guidance',
        icon: Icons.person_outline_rounded,
        isDone: profile.gender.isNotEmpty,
        onTap: () => _showSinglePicker(
            context, state, 'gender', 'Select Gender', kGenders),
      ),
      _ProfileTask(
        id: 'forgetting',
        title: 'When do you forget?',
        subtitle: 'Optimises your reminders',
        icon: Icons.psychology_rounded,
        isDone: profile.forgetting.isNotEmpty,
        onTap: () => _showSinglePicker(
            context, state, 'forgetting', 'Forget Pattern', kForgetPatterns),
      ),
      _ProfileTask(
        id: 'doctor',
        title: 'Doctor visits',
        subtitle: 'Track your medical frequency',
        icon: Icons.medical_services_outlined,
        isDone: profile.doctorVisits.isNotEmpty,
        onTap: () => _showSinglePicker(
            context, state, 'doctorVisits', 'Doctor Visits', kDoctorVisits),
      ),
      _ProfileTask(
        id: 'motivation',
        title: 'What motivates you?',
        subtitle: profile.motivation.isEmpty
            ? 'Personalised encouragement'
            : profile.motivation.join(', '),
        icon: Icons.wb_sunny_outlined,
        isDone: profile.motivation.isNotEmpty,
        onTap: () => _showMultiPicker(
            context, state, 'motivation', 'Select Motivation', kMotivation),
      ),
    ];

    final doneCount = tasks.where((t) => t.isDone).length;
    if (doneCount == tasks.length) return const SizedBox.shrink();

    final progress = doneCount / tasks.length;
    final L = context.L;
    final reduceMotion = MedAiA11y.reducedMotion(context);

    Widget card = Container(
      margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding, vertical: AppSpacing.m),
      child: MedAiGlass(
        padding: EdgeInsets.zero,
        radius: 28,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.p20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Complete Your Profile',
                          style: AppTypography.titleLarge.copyWith(fontSize: 18),
                        ),
                        const SizedBox(height: AppSpacing.p4),
                        Text(
                          'Unlock more personalised insights',
                          style: AppTypography.bodySmall.copyWith(color: L.sub),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.p12, vertical: AppSpacing.p8),
                    decoration: BoxDecoration(
                      color: L.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${(progress * 100).toInt()}%',
                      style: AppTypography.labelLarge.copyWith(
                          color: L.secondary, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: L.border,
              color: L.secondary,
              minHeight: 3,
            ),
            const SizedBox(height: AppSpacing.p8),
            ...tasks
                .where((t) => !t.isDone)
                .take(2)
                .map((task) => _TaskItem(task: task, L: L)),
            const SizedBox(height: AppSpacing.p8),
          ],
        ),
      ),
    );

    if (reduceMotion) return card;
    return card
        .animate()
        .fadeIn(duration: AppDurations.fast, curve: AppCurves.smooth)
        .slideY(begin: 0.1, end: 0, curve: AppCurves.smooth);
  }

  void _showAgePicker(BuildContext context, AppState state) {
    final controller = TextEditingController(text: state.profile?.age ?? '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (c) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: MedAiGlass(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(c).viewInsets.bottom,
              left: 24,
              right: 24,
              top: 24),
          radius: 32,
          showBorder: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('How old are you?', style: AppTypography.headlineMedium),
              const SizedBox(height: AppSpacing.p24),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'e.g. 35',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: AppSpacing.p24),
              MedAiCTA(
                label: 'Save',
                semanticsLabel: 'Save age',
                onTap: () {
                  state.saveProfile(
                      state.profile!.copyWith(age: controller.text));
                  Navigator.pop(c);
                  HapticEngine.success();
                },
              ),
              const SizedBox(height: AppSpacing.p32),
            ],
          ),
        ),
      ),
    );
  }

  void _showSinglePicker(BuildContext context, AppState state, String field,
      String title, List<Map<String, String>> options) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (c) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: MedAiGlass(
          padding: const EdgeInsets.all(AppSpacing.p24),
          radius: 32,
          showBorder: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: AppTypography.headlineMedium),
              const SizedBox(height: AppSpacing.p16),
              ...options.map((opt) => Semantics(
                    button: true,
                    label: opt['v'],
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      minVerticalPadding: 12,
                      leading: Text(opt['e']!,
                          style: AppTypography.displayLarge
                              .copyWith(fontSize: 24)),
                      title: Text(opt['v']!),
                      onTap: () {
                        final Map<String, dynamic> updates = {field: opt['v']};
                        state.updateProfileFromMap(updates);
                        Navigator.pop(c);
                        HapticEngine.selection();
                      },
                    ),
                  )),
              const SizedBox(height: AppSpacing.p24),
            ],
          ),
        ),
      ),
    );
  }

  void _showMultiPicker(BuildContext context, AppState state, String field,
      String title, List<Map<String, String>> options) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (c) => StatefulBuilder(
        builder: (context, setModalState) {
          final profile = state.profile;
          final selected = List<String>.from(profile?.motivation ?? []);
          final L = context.L;

          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            child: MedAiGlass(
              padding: const EdgeInsets.all(AppSpacing.p24),
              radius: 32,
              showBorder: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: AppTypography.headlineMedium),
                  const SizedBox(height: AppSpacing.p16),
                  ...options.map((opt) {
                    final val = opt['v']!;
                    final isSel = selected.contains(val);
                    return CheckboxListTile(
                      secondary: Text(opt['e']!,
                          style: AppTypography.displayLarge
                              .copyWith(fontSize: 24)),
                      title: Text(val),
                      value: isSel,
                      activeColor: L.secondary,
                      onChanged: (checked) {
                        setModalState(() {
                          if (checked == true) {
                            if (!selected.contains(val)) selected.add(val);
                          } else {
                            selected.remove(val);
                          }
                        });
                        HapticEngine.selection();
                      },
                    );
                  }),
                  const SizedBox(height: AppSpacing.p24),
                  MedAiCTA(
                    label: 'Save selection',
                    onTap: () {
                      state.updateProfileFromMap({field: selected});
                      Navigator.pop(c);
                      HapticEngine.success();
                    },
                  ),
                  const SizedBox(height: AppSpacing.p16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProfileTask {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isDone;
  final VoidCallback onTap;

  _ProfileTask({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isDone,
    required this.onTap,
  });
}

class _TaskItem extends StatelessWidget {
  final _ProfileTask task;
  final AppThemeColors L;
  const _TaskItem({required this.task, required this.L});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${task.title}. ${task.subtitle}',
      child: ListTile(
        onTap: task.onTap,
        minVerticalPadding: 12,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
        leading: Container(
          width: 44,
          height: 44,
          padding: const EdgeInsets.all(AppSpacing.p12),
          decoration: BoxDecoration(
            color: L.bg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(task.icon, color: L.secondary, size: 20),
        ),
        title: Text(task.title, style: AppTypography.labelLarge),
        subtitle: Text(task.subtitle,
            style: AppTypography.bodySmall.copyWith(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right_rounded, size: 20),
      ),
    );
  }
}
