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

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
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
              title: 'Privacy Policy',
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
                _entrance(
                  Semantics(
                    button: true,
                    label: 'View full privacy policy online',
                    child: MedAiGlass(
                      onTap: () async {
                        HapticEngine.selection();
                        final url = Uri.parse(kPrivacyPolicyUrl);
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
                              'View full policy online at $kPrivacyPolicyUrl',
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
                  delay: 600,
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
                  ),
                  delay: 650,
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
