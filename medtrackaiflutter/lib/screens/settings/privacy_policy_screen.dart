import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../theme/app_theme.dart';
import '../../../models/constants.dart';
import '../../../widgets/common/animated_pressable.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Scaffold(
      backgroundColor: L.bg,
      body: CustomScrollView(
  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                          'Privacy Policy',
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
                // Medical Disclaimer — Apple 5.1.3 Required
                _buildCard(
                  icon: Icons.local_hospital_rounded,
                  title: 'Medical Disclaimer',
                  content:
                      '$kAppName is a medication tracking and health information tool ONLY. It does NOT provide medical diagnoses, clinical advice, or treatment recommendations. All AI-generated insights are for informational purposes only and may be inaccurate.\n\nAlways consult a licensed physician, pharmacist, or qualified healthcare professional before making any medical decision. Do not use this app as a substitute for professional medical advice. In an emergency, call your local emergency services immediately (e.g. 911, 999, 112).',
                  accent: AppColors.red,
                  delay: 50,
                  L: L,
                ),

                _buildCard(
                  icon: Icons.shield_rounded,
                  title: '1. Information We Collect',
                  content:
                      'We collect only what is necessary to operate the app:\n\n• Account data: email address, display name, profile photo (if provided)\n• Health data: medication names, dosages, schedules, adherence logs, and vitals you manually enter or import from Apple Health / Google Health Connect\n• Device data: device model, OS version, crash logs (via Firebase Crashlytics)\n• Usage data: feature interactions, scan counts, and session duration (via Firebase Analytics) — fully anonymised\n• Camera/microphone: used only in real-time during scanning or voice input; images are processed and not stored permanently without your consent\n• We do NOT collect: government IDs, precise location (unless you grant permission), financial data, or contact lists.',
                  delay: 100,
                  L: L,
                ),

                _buildCard(
                  icon: Icons.auto_awesome_rounded,
                  title: '2. AI & Scan Processing',
                  content:
                      'When you scan a medicine or use the AI assistant, your image or query is sent to Google\'s Gemini API for processing. This data is:\n\n• Transmitted over TLS encryption\n• Processed by Google under their Privacy Policy (policies.google.com)\n• Not used to train public AI models\n• Not linked to your identity — requests are anonymous\n\nGemini API responses are informational only. Medai does not verify AI-generated medical content for clinical accuracy.',
                  delay: 150,
                  L: L,
                ),

                _buildCard(
                  icon: Icons.people_rounded,
                  title: '3. Family & Caregiver Sharing',
                  content:
                      'If you add a family member or caregiver to your Circle, you explicitly grant them permission to view your medication schedule and adherence logs. You can revoke this access at any time from the Family Hub.\n\nShared data is encrypted in transit and at rest. Caregivers cannot modify your medication data without your consent.',
                  delay: 200,
                  L: L,
                ),

                _buildCard(
                  icon: Icons.business_rounded,
                  title: '4. Third-Party Services',
                  content:
                      'We integrate the following third-party services:\n\n• Firebase (Google) — Authentication, database, storage, analytics, crash reporting\n• RevenueCat — In-app purchase management\n• Google Gemini API — AI analysis engine\n• Apple HealthKit / Google Health Connect — Health data sync (opt-in only)\n\nEach service operates under its own privacy policy. We do not sell your data to advertisers or data brokers.',
                  delay: 250,
                  L: L,
                ),

                _buildCard(
                  icon: Icons.lock_clock_rounded,
                  title: '5. Data Retention',
                  content:
                      '• Active account data: retained as long as your account exists\n• Deleted account data: permanently erased within 30 days of account deletion request\n• Anonymised analytics: retained for up to 24 months for product improvement\n• Crash logs: retained for 90 days\n\nYou can request immediate deletion at any time from Settings → Delete Account Permanently.',
                  delay: 300,
                  L: L,
                ),

                _buildCard(
                  icon: Icons.security_rounded,
                  title: '6. Security',
                  content:
                      'Your data is protected using:\n\n• AES-256 encryption for stored data\n• TLS 1.3 for all data in transit\n• Firebase Security Rules limiting data access\n• Biometric lock (FaceID / Fingerprint) for app access\n• Optional PIN lock\n\nNo security system is 100% infallible. In the event of a data breach, we will notify affected users within 72 hours as required by GDPR.',
                  delay: 350,
                  L: L,
                ),

                _buildCard(
                  icon: Icons.gavel_rounded,
                  title: '7. Your Rights (GDPR / CCPA)',
                  content:
                      'Depending on your region, you have the right to:\n\n• Access: Request a copy of your personal data\n• Rectification: Correct inaccurate data\n• Erasure: Request deletion of your account and all associated data\n• Portability: Export your data as a CSV or PDF report\n• Objection: Opt out of analytics data collection at any time from Settings\n• Withdraw consent: Remove Health Connect / HealthKit access at any time\n\nTo exercise any right, contact us at $kSupportEmail',
                  delay: 400,
                  L: L,
                ),

                _buildCard(
                  icon: Icons.child_care_rounded,
                  title: '8. Children\'s Privacy',
                  content:
                      '$kAppName is not intended for children under 13 years of age (or 16 in the EU). We do not knowingly collect personal data from children. If you believe a child has provided us with personal data, contact us immediately and we will delete it.',
                  delay: 450,
                  L: L,
                ),

                _buildCard(
                  icon: Icons.cloud_off_rounded,
                  title: '9. Your Data, Your Control',
                  content:
                      'You own your data at all times. You may:\n\n• Export your full health history as a clinical PDF or CSV report\n• Delete your account and all data permanently\n• Revoke Health integration access\n• Disable analytics from Settings → Privacy\n\nWe comply with GDPR (EU), CCPA (California), PIPEDA (Canada), and follow HIPAA-equivalent security practices.',
                  delay: 500,
                  L: L,
                ),

                _buildCard(
                  icon: Icons.email_rounded,
                  title: '10. Contact & Updates',
                  content:
                      'For privacy enquiries, data requests, or concerns:\n\n📧 $kSupportEmail\n🌐 $kPrivacyPolicyUrl\n\nWe may update this Privacy Policy from time to time. We will notify you of material changes via in-app notification. Continued use of the app after changes constitutes acceptance.',
                  delay: 550,
                  L: L,
                ),

                const SizedBox(height: 24),

                // Web link to hosted policy
                AnimatedPressable(
                  onTap: () async {
                    final url = Uri.parse(kPrivacyPolicyUrl);
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
                            'View full policy online at $kPrivacyPolicyUrl',
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
                ).animate().fadeIn(delay: 600.ms),

                const SizedBox(height: 40),
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.verified_user_rounded,
                          color: L.sub.withValues(alpha: 0.3), size: 32),
                      const SizedBox(height: 12),
                      Text(
                        '$kAppName\nSecure · Private · GDPR Compliant',
                        textAlign: TextAlign.center,
                        style: AppTypography.labelMedium.copyWith(
                          color: L.sub.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w800,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 650.ms, duration: 800.ms),
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
