import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../theme/app_theme.dart';
import '../../../models/constants.dart';

class TermsOfServiceScreen extends StatefulWidget {
  const TermsOfServiceScreen({super.key});

  @override
  State<TermsOfServiceScreen> createState() => _TermsOfServiceScreenState();
}

class _TermsOfServiceScreenState extends State<TermsOfServiceScreen> {
  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Scaffold(
      backgroundColor: L.bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            backgroundColor: L.bg,
            expandedHeight: 220,
            pinned: true,
            stretch: true,
            leading: Navigator.canPop(context)
                ? IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded, color: L.text),
                    onPressed: () => Navigator.pop(context),
                  )
                : null,
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.accent.withValues(alpha: 0.15),
                            L.bg
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: -50,
                    right: -50,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.accent.withValues(alpha: 0.2),
                      ),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                        child: Container(color: Colors.transparent),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 40,
                    left: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: L.text.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: L.border.withValues(alpha: 0.1)),
                          ),
                          child: Text(
                            'LEGAL & COMPLIANCE',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Terms of Service',
                          style: AppTypography.displaySmall.copyWith(
                            color: L.text,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Last Updated: June 2026',
                          style: AppTypography.bodySmall.copyWith(
                            color: L.sub,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
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

                // Web link to hosted terms
                GestureDetector(
                  onTap: () async {
                    final url = Uri.parse(kTermsOfServiceUrl);
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.open_in_new_rounded, color: AppColors.accent, size: 18),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'View full terms online at $kTermsOfServiceUrl',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 450.ms),

                const SizedBox(height: 40),
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
                ).animate().fadeIn(delay: 500.ms, duration: 800.ms),
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
    final accentColor = accent ?? AppColors.accent;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: accent != null
            ? accentColor.withValues(alpha: 0.05)
            : L.card.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: accentColor.withValues(alpha: accent != null ? 0.25 : 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
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
    ).animate().fadeIn(delay: delay.ms, duration: 400.ms).slideY(begin: 0.1, end: 0);
  }
}
