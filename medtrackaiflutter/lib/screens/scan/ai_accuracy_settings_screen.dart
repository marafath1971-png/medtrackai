import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../theme/app_theme.dart';
import '../../../core/utils/haptic_engine.dart';
import '../../../widgets/shared/shared_widgets.dart';
import 'package:provider/provider.dart';
import '../../../providers/app_state.dart';
// ══════════════════════════════════════════════════════════════════════
// 2026 PREMIUM AI ACCURACY SETTINGS
// ══════════════════════════════════════════════════════════════════════
class AiAccuracySettingsScreen extends StatefulWidget {
  const AiAccuracySettingsScreen({super.key});

  @override
  State<AiAccuracySettingsScreen> createState() => _AiAccuracySettingsScreenState();
}

class _AiAccuracySettingsScreenState extends State<AiAccuracySettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final state = context.watch<AppState>();
    final profile = state.profile;
    if (profile == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: L.bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: AnimatedPressable(
              onTap: () {
                HapticEngine.selection();
                Navigator.pop(context);
              },
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: L.fill.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_back_ios_new_rounded, color: L.text, size: 18),
              ),
            ),
            flexibleSpace: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
                  title: Text(
                    'AI Accuracy',
                    style: AppTypography.titleLarge.copyWith(
                      color: L.text,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSectionHeader('Recognition Threshold', L),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: L.card,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: L.border.withValues(alpha: 0.05)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
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
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppColors.accent,
                          inactiveTrackColor: L.border.withValues(alpha: 0.2),
                          thumbColor: Colors.white,
                          trackHeight: 6,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                        ),
                        child: Slider(
                          value: profile.aiConfidenceThreshold,
                          min: 50,
                          max: 100,
                          onChanged: (val) {
                            state.auth.saveProfile(profile.copyWith(aiConfidenceThreshold: val));
                            HapticEngine.selection();
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Faster', style: AppTypography.labelSmall.copyWith(color: L.sub)),
                          Text('More Accurate', style: AppTypography.labelSmall.copyWith(color: L.sub)),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0),
                
                const SizedBox(height: 32),
                _buildSectionHeader('Processing Modes', L),
                const SizedBox(height: 12),
                
                Container(
                  decoration: BoxDecoration(
                    color: L.card,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: L.border.withValues(alpha: 0.05)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildSwitchTile(
                        title: 'Deep Semantic Analysis',
                        subtitle: 'Uses Gemini Pro for advanced label parsing',
                        value: profile.aiDeepAnalysis,
                        onChanged: (val) {
                          state.auth.saveProfile(profile.copyWith(aiDeepAnalysis: val));
                          HapticEngine.selection();
                        },
                        L: L,
                      ),
                      Divider(height: 1, color: L.border.withValues(alpha: 0.1), indent: 16, endIndent: 16),
                      _buildSwitchTile(
                        title: 'Auto-Crop Images',
                        subtitle: 'Automatically frames the pill or bottle',
                        value: profile.aiAutoCrop,
                        onChanged: (val) {
                          state.auth.saveProfile(profile.copyWith(aiAutoCrop: val));
                          HapticEngine.selection();
                        },
                        L: L,
                      ),
                      Divider(height: 1, color: L.border.withValues(alpha: 0.1), indent: 16, endIndent: 16),
                      _buildSwitchTile(
                        title: 'Clinical Mode',
                        subtitle: 'Prioritize NDC codes and FDA databases',
                        value: profile.aiClinicalMode,
                        onChanged: (val) {
                          state.auth.saveProfile(profile.copyWith(aiClinicalMode: val));
                          HapticEngine.selection();
                        },
                        L: L,
                      ),
                      Divider(height: 1, color: L.border.withValues(alpha: 0.1), indent: 16, endIndent: 16),
                      _buildSwitchTile(
                        title: 'Privacy Mode (No Logging)',
                        subtitle: 'Do not save scan history or images locally',
                        value: profile.aiPrivacyMode,
                        onChanged: (val) {
                          state.auth.saveProfile(profile.copyWith(aiPrivacyMode: val));
                          HapticEngine.selection();
                        },
                        L: L,
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 100.ms, duration: 300.ms).slideY(begin: 0.05, end: 0),
                
                const SizedBox(height: 48),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, AppThemeColors L) {
    return Text(
      title,
      style: AppTypography.labelLarge.copyWith(
        color: L.sub.withValues(alpha: 0.6),
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required AppThemeColors L,
  }) {
    return Padding(
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
    );
  }
}
