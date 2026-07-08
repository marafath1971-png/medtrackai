import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/premium_graphics.dart';
import '../../../theme/med_ai_ui.dart';
import '../../../models/constants.dart';
import '../../../widgets/common/app_scaffold.dart';
import '../../../widgets/common/premium_page_header.dart';
import '../../../core/utils/haptic_engine.dart';

class TermsOfServiceScreen extends StatefulWidget {
  const TermsOfServiceScreen({super.key});

  @override
  State<TermsOfServiceScreen> createState() => _TermsOfServiceScreenState();
}

class _TermsOfServiceScreenState extends State<TermsOfServiceScreen> {
  Widget _entrance(Widget child, {int delay = 0}) {
    if (MedAiA11y.reducedMotion(context)) return child;
    return child
        .animate(delay: delay.ms)
        .fadeIn(duration: AppDurations.fast)
        .slideY(begin: 0.08, end: 0, curve: AppCurves.smooth);
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;

    return AppScaffold(
      showAurora: true,
      body: CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: PremiumPageHeader(
              title: 'Terms of Service',
              subtitle: 'Last updated: June 2026',
              onBack: () => Navigator.pop(context),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: L.card,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: L.border.withValues(alpha: 0.35)),
                ),
                child: SvgPicture.asset(
                  PremiumGraphics.healthInsights,
                  height: 120,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildCard(
                  icon: Icons.gavel_rounded,
                  title: '1. Acceptance of Terms',
                  content:
                      'By downloading, accessing, or using $kAppName ("App"), you agree to be bound by these Terms of Service. If you do not agree with any part of these terms, you must not use the App.',
                  delay: 50,
                  L: L,
                ),
                _buildCard(
                  icon: Icons.medical_information_rounded,
                  title: '2. Not Medical Advice',
                  content:
                      'The App is a medication tracking and health information management tool. IT DOES NOT PROVIDE MEDICAL ADVICE, DIAGNOSES, OR CLINICAL TREATMENT RECOMMENDATIONS.\n\nAI-generated insights (powered by Google Gemini) are for informational purposes only. You must always consult a licensed physician or pharmacist before making any medical decisions, changing dosages, or stopping medications. In a medical emergency, immediately contact your local emergency services.',
                  accent: AppColors.red,
                  delay: 100,
                  L: L,
                ),
                _buildCard(
                  icon: Icons.person_rounded,
                  title: '3. User Accounts',
                  content:
                      'You are responsible for maintaining the confidentiality of your account credentials (including biometric locks) and for all activities that occur under your account. You must notify us immediately of any unauthorised access.',
                  delay: 150,
                  L: L,
                ),
                _buildCard(
                  icon: Icons.auto_awesome_rounded,
                  title: '4. Acceptable Use',
                  content:
                      'You agree NOT to:\n• Use the App for unlawful medical practices\n• Attempt to reverse engineer, decompile, or hack the App or its AI systems\n• Intentionally submit false or malicious data to the AI scanning engine\n• Share your premium subscription inappropriately',
                  delay: 200,
                  L: L,
                ),
                _buildCard(
                  icon: Icons.subscriptions_rounded,
                  title: '5. Premium Subscriptions',
                  content:
                      'Certain features (e.g., unlimited AI scans, advanced clinical reports) require a Premium subscription. Payments are processed via your Apple ID or Google Play account. Subscriptions auto-renew unless canceled at least 24 hours before the end of the current period. You can manage subscriptions in your device settings.',
                  delay: 250,
                  L: L,
                ),
                _buildCard(
                  icon: Icons.health_and_safety_rounded,
                  title: '6. Apple Health & Health Connect',
                  content:
                      'If you opt-in, the App integrates with Apple HealthKit and Google Health Connect to read and write health data (e.g., heart rate, steps, blood glucose). We use this data solely to provide you with insights regarding your medication adherence and its potential impact on your vitals. We do not sell this data.',
                  delay: 300,
                  L: L,
                ),
                _buildCard(
                  icon: Icons.warning_amber_rounded,
                  title: '7. Limitation of Liability',
                  content:
                      'TO THE MAXIMUM EXTENT PERMITTED BY LAW, WE SHALL NOT BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES, INCLUDING BUT NOT LIMITED TO PERSONAL INJURY, WRONGFUL DEATH, OR HEALTH DETERIORATION ARISING FROM YOUR USE OF THE APP OR RELIANCE ON ITS AI-GENERATED CONTENT.',
                  delay: 350,
                  L: L,
                ),
                _buildCard(
                  icon: Icons.email_rounded,
                  title: '8. Contact Information',
                  content:
                      'If you have questions about these Terms, please contact our support team:\n\n📧 $kSupportEmail\n🌐 $kTermsOfServiceUrl',
                  delay: 400,
                  L: L,
                ),
                const SizedBox(height: 24),
                _entrance(
                  Semantics(
                    button: true,
                    label: 'View full terms online',
                    child: MedAiGlass(
                      onTap: () async {
                        HapticEngine.selection();
                        final url = Uri.parse(kTermsOfServiceUrl);
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url,
                              mode: LaunchMode.externalApplication);
                        }
                      },
                      child: Row(
                        children: [
                          Icon(Icons.open_in_new_rounded,
                              color: L.accent, size: 18),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'View full terms online at $kTermsOfServiceUrl',
                              style: AppTypography.bodySmall.copyWith(
                                color: L.accent,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                                decorationColor: L.accent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  delay: 450,
                ),
                const SizedBox(height: 40),
                _entrance(
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.verified_user_rounded,
                            color: L.sub.withValues(alpha: 0.3), size: 32),
                        const SizedBox(height: 12),
                        Text(
                          '$kAppName\nSecure · Private · Transparent',
                          textAlign: TextAlign.center,
                          style: AppTypography.labelMedium.copyWith(
                            color: L.sub.withValues(alpha: 0.5),
                            fontWeight: FontWeight.w800,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  delay: 500,
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String title,
    required String content,
    required int delay,
    required AppThemeColors L,
    Color? accent,
  }) {
    final accentColor = accent ?? L.accent;
    return _entrance(
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Semantics(
          label: title,
          child: MedAiDepthCard(
            color: accent != null
                ? accentColor.withValues(alpha: 0.05)
                : null,
            accentGlow: accent != null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: MedAiA11y.minTapTarget,
                      height: MedAiA11y.minTapTarget,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 20, color: accentColor),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        title,
                        style: AppTypography.titleMedium.copyWith(
                          color: L.text,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  content,
                  style: AppTypography.bodySmall.copyWith(
                    color: L.sub,
                    height: 1.7,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      delay: delay,
    );
  }
}
