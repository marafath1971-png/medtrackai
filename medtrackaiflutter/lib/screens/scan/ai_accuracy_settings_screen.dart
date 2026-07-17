import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/haptic_engine.dart';
import '../../../providers/app_state.dart';
import '../../../theme/med_ai_ui.dart';
import '../../../widgets/common/app_scaffold.dart';
import '../../../widgets/common/premium_page_header.dart';

class AiAccuracySettingsScreen extends StatefulWidget {
  const AiAccuracySettingsScreen({super.key});

  @override
  State<AiAccuracySettingsScreen> createState() =>
      _AiAccuracySettingsScreenState();
}

class _AiAccuracySettingsScreenState extends State<AiAccuracySettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final reduceMotion = MedAiA11y.reducedMotion(context);
    final state = context.watch<AppState>();
    final profile = state.profile;
    if (profile == null) return const SizedBox.shrink();

    return AppScaffold(
      showAurora: false,
      body: CustomScrollView(
        physics:
            const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverToBoxAdapter(
            child: PremiumPageHeader(
              title: 'AI Accuracy',
              subtitle: 'Fine-tune scan recognition',
              onBack: () {
                HapticEngine.selection();
                Navigator.pop(context);
              },
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                MedAiSectionHeader(title: 'Recognition Threshold'),
                _entrance(
                  reduceMotion,
                  MedAiDepthCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Confidence Target',
                              style: AppTypography.titleMedium.copyWith(
                                color: L.text,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                '${profile.aiConfidenceThreshold.toInt()}%',
                                style: AppTypography.labelLarge.copyWith(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Semantics(
                          slider: true,
                          label:
                              'Confidence target, ${profile.aiConfidenceThreshold.toInt()} percent',
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: AppColors.accent,
                              inactiveTrackColor:
                                  L.border.withValues(alpha: 0.2),
                              thumbColor: Colors.white,
                              trackHeight: 6,
                              thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 12),
                            ),
                            child: Slider(
                              value: profile.aiConfidenceThreshold,
                              min: 50,
                              max: 100,
                              onChanged: (val) {
                                state.auth.saveProfile(
                                    profile.copyWith(
                                        aiConfidenceThreshold: val));
                                HapticEngine.selection();
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Faster',
                                style: AppTypography.labelSmall
                                    .copyWith(color: L.sub)),
                            Text('More Accurate',
                                style: AppTypography.labelSmall
                                    .copyWith(color: L.sub)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                MedAiSectionHeader(title: 'Processing Modes'),
                _entrance(
                  reduceMotion,
                  MedAiDepthCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _SwitchTile(
                          title: 'Deep Semantic Analysis',
                          subtitle:
                              'Uses Gemini Pro for advanced label parsing',
                          value: profile.aiDeepAnalysis,
                          onChanged: (val) {
                            state.auth.saveProfile(
                                profile.copyWith(aiDeepAnalysis: val));
                            HapticEngine.selection();
                          },
                        ),
                        Divider(
                            height: 1,
                            color: L.border.withValues(alpha: 0.1),
                            indent: 16,
                            endIndent: 16),
                        _SwitchTile(
                          title: 'Auto-Crop Images',
                          subtitle:
                              'Automatically frames the pill or bottle',
                          value: profile.aiAutoCrop,
                          onChanged: (val) {
                            state.auth.saveProfile(
                                profile.copyWith(aiAutoCrop: val));
                            HapticEngine.selection();
                          },
                        ),
                        Divider(
                            height: 1,
                            color: L.border.withValues(alpha: 0.1),
                            indent: 16,
                            endIndent: 16),
                        _SwitchTile(
                          title: 'Clinical Mode',
                          subtitle:
                              'Prioritize NDC codes and FDA databases',
                          value: profile.aiClinicalMode,
                          onChanged: (val) {
                            state.auth.saveProfile(
                                profile.copyWith(aiClinicalMode: val));
                            HapticEngine.selection();
                          },
                        ),
                        Divider(
                            height: 1,
                            color: L.border.withValues(alpha: 0.1),
                            indent: 16,
                            endIndent: 16),
                        _SwitchTile(
                          title: 'Privacy Mode (No Logging)',
                          subtitle:
                              'Do not save scan history or images locally',
                          value: profile.aiPrivacyMode,
                          onChanged: (val) {
                            state.auth.saveProfile(
                                profile.copyWith(aiPrivacyMode: val));
                            HapticEngine.selection();
                          },
                        ),
                      ],
                    ),
                  ),
                  delay: 100.ms,
                ),
                const SizedBox(height: 48),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _entrance(bool reduceMotion, Widget child, {Duration? delay}) {
    if (reduceMotion) return child;
    return child
        .animate(delay: delay)
        .fadeIn(duration: AppDurations.fast, curve: AppCurves.smooth)
        .slideY(begin: 0.05, end: 0, curve: AppCurves.smooth);
  }
}

class _SwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Semantics(
      toggled: value,
      label: title,
      hint: subtitle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.titleMedium.copyWith(
                      color: L.text,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: L.sub.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            CupertinoSwitch(
              value: value,
              activeTrackColor: AppColors.accent,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}
