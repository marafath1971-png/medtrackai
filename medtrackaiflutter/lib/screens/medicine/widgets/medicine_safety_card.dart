import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../theme/med_ai_ui.dart';
import '../../../providers/app_state.dart';
import '../../../core/utils/haptic_engine.dart';
import '../../../widgets/common/app_loading_indicator.dart';

import '../../../l10n/app_localizations.dart';

class MedicineSafetyCard extends StatefulWidget {
  final Medicine med;

  const MedicineSafetyCard({super.key, required this.med});

  @override
  State<MedicineSafetyCard> createState() => _MedicineSafetyCardState();
}

class _MedicineSafetyCardState extends State<MedicineSafetyCard> {
  bool _isLoading = false;
  String? _errorMessage;

  void _runScan() async {
    HapticEngine.selection();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result =
        await context.read<AppState>().analyzeMedicineSafety(widget.med);

    if (mounted) {
      setState(() => _isLoading = false);
      if (result.isFailure) {
        setState(() => _errorMessage = result.failure.toString());
        HapticEngine.heavyImpact();
      } else {
        HapticEngine.success();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final s = AppLocalizations.of(context)!;
    final reduceMotion = MedAiA11y.reducedMotion(context);
    final profile = widget.med.aiSafetyProfile;

    if (profile == null) {
      if (_errorMessage != null) {
        return _buildErrorState(L, s, reduceMotion);
      }
      return _buildScanPrompt(L, s, reduceMotion);
    }

    Widget card = MedAiDepthCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: MedAiSectionHeader(
              title: s.aiSafetyProfile,
              action: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: L.text,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  s.verified.toUpperCase(),
                  style: AppTypography.labelSmall.copyWith(
                    color: L.bg,
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
          ),
          Divider(height: 1, color: L.border.withValues(alpha: 0.5)),

          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (profile.warnings.isNotEmpty)
                  _buildSection(L, '🚨 ${s.criticalWarnings}', profile.warnings,
                      isDanger: true, reduceMotion: reduceMotion),
                if (profile.interactions.isNotEmpty)
                  _buildSection(
                      L, '💊 ${s.drugInteractions}', profile.interactions,
                      isDanger: true, reduceMotion: reduceMotion),
                if (profile.foodRules.isNotEmpty)
                  _buildSection(
                      L, '🍏 ${s.dietaryLifestyleRules}', profile.foodRules,
                      isDanger: false, reduceMotion: reduceMotion),
                if (profile.ahaMoments.isNotEmpty)
                  _buildSection(L, '💡 ${s.ahaInsight}', profile.ahaMoments,
                      isDanger: false, isAha: true, reduceMotion: reduceMotion),
                if (profile.warnings.isEmpty &&
                    profile.interactions.isEmpty &&
                    profile.foodRules.isEmpty &&
                    profile.ahaMoments.isEmpty)
                  Text(
                    'No special safety alerts found for this medication.',
                    style: AppTypography.bodyMedium.copyWith(color: L.sub),
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    if (!reduceMotion) {
      card = card
          .animate()
          .fadeIn(duration: 400.ms)
          .slideY(begin: 0.05, curve: Curves.easeOutQuart);
    }

    return card;
  }

  Widget _buildSection(AppThemeColors L, String title, List<String> items,
      {bool isDanger = false, bool isAha = false, required bool reduceMotion}) {
    // 2026 Viral premium colors
    final Color colorToUse = isAha
        ? const Color(0xFFA855F7) // Purple for Aha
        : isDanger
            ? const Color(0xFFEF4444) // Red for Danger
            : const Color(0xFF34D399); // Teal/Green for normal (food rules)

    // Remove emoji from title if it exists to replace with pure text
    String cleanTitle = title.replaceAll(RegExp(r'[^\w\s&]'), '').trim();

    final emojiIcon = Text(
      isAha ? "💡" : (isDanger ? "⚠️" : "🍏"),
      style: const TextStyle(fontSize: 22),
    );

    final dangerBadge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Text("🛑", style: TextStyle(fontSize: 12)),
          const SizedBox(width: 6),
          Text(
            "DANGER",
            style: AppTypography.labelSmall.copyWith(
              color: Colors.redAccent,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );

    Widget section = MedAiDepthCard(
      accentGlow: isDanger || isAha,
      padding: const EdgeInsets.all(24),
      radius: 32,
      color: L.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: colorToUse.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: colorToUse.withValues(alpha: 0.4),
                          blurRadius: 10,
                          spreadRadius: -2)
                    ]),
                child: emojiIcon,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  cleanTitle.toUpperCase(),
                  style: AppTypography.labelLarge.copyWith(
                    color: colorToUse,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              if (isDanger) dangerBadge,
            ],
          ),
          const SizedBox(height: 20),
          MedAiGlass(
            radius: 24,
            padding: const EdgeInsets.all(20),
            tint: isAha ? Colors.transparent : L.meshBg,
            showBorder: !isAha,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: items.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 6, right: 14),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: colorToUse,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          item,
                          style: AppTypography.bodyMedium.copyWith(
                            color: L.text.withValues(alpha: 0.95),
                            height: 1.6,
                            fontWeight: isDanger ? FontWeight.w700 : FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );

    if (isAha) {
      section = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: LinearGradient(
            colors: [
              const Color(0xFF6366F1).withValues(alpha: 0.15),
              const Color(0xFFA855F7).withValues(alpha: 0.05)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: section,
      );
    }

    if (reduceMotion) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 24),
        child: section,
      );
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      child: section.animate().fadeIn(duration: 600.ms).slideY(
          begin: 0.1, end: 0, curve: Curves.easeOutQuart),
    );
  }

  Widget _buildErrorState(AppThemeColors L, AppLocalizations s, bool reduceMotion) {
    Widget card = MedAiDepthCard(
      padding: const EdgeInsets.all(24),
      color: L.error.withValues(alpha: 0.05),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: L.bg,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: L.error.withValues(alpha: 0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 4)),
              ],
            ),
            child: Icon(Icons.error_outline_rounded, color: L.error, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            s.analysisFailed,
            style: AppTypography.titleMedium.copyWith(
              color: L.error,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? s.somethingWentWrong,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: L.sub,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          MedAiCTA(
            label: s.retry,
            onTap: _runScan,
            semanticsLabel: s.retry,
          ),
        ],
      ),
    );

    if (reduceMotion) return card;

    return card
        .animate()
        .fadeIn(duration: 600.ms)
        .shake(duration: 400.ms, curve: Curves.easeInOut);
  }

  Widget _buildScanPrompt(AppThemeColors L, AppLocalizations s, bool reduceMotion) {
    final sparkle = _isLoading
        ? const AppLoadingIndicator(size: 32)
        : const Text("✨", style: TextStyle(fontSize: 32));

    Widget card = Semantics(
      button: true,
      enabled: !_isLoading,
      label: s.generateSafetyProfile,
      child: MedAiDepthCard(
        accentGlow: true,
        padding: const EdgeInsets.all(32),
        radius: 32,
        onTap: _isLoading ? null : _runScan,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFFA855F7).withValues(alpha: 0.5),
                      blurRadius: 20,
                      spreadRadius: -5),
                ],
              ),
              child: sparkle,
            ),
            const SizedBox(height: 24),
            Text(
              _isLoading ? s.analyzingClinicalLimits : s.generateSafetyProfile,
              style: AppTypography.titleLarge.copyWith(
                color: L.text,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _isLoading
                  ? s.safetyLoadingSubtitle
                  : "Tap to unlock deep clinical insights, potential side-effects, and AHA moments.",
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: L.text.withValues(alpha: 0.8),
                height: 1.6,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );

    card = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6366F1).withValues(alpha: 0.1),
            const Color(0xFFA855F7).withValues(alpha: 0.05)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: card,
    );

    if (reduceMotion) return card;

    return card
        .animate()
        .fadeIn(duration: 600.ms)
        .slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuart);
  }
}
