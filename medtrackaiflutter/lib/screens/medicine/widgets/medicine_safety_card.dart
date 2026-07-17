import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/haptic_engine.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/app_state.dart';
import '../../../theme/med_ai_ui.dart';
import '../../../widgets/common/app_loading_indicator.dart';
import '../../../widgets/common/animated_pressable.dart';

class MedicineSafetyCard extends StatefulWidget {
  final Medicine med;

  const MedicineSafetyCard({super.key, required this.med});

  @override
  State<MedicineSafetyCard> createState() => _MedicineSafetyCardState();
}

class _MedicineSafetyCardState extends State<MedicineSafetyCard> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _runScan() async {
    HapticEngine.selection();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result =
        await context.read<AppState>().analyzeMedicineSafety(widget.med);

    if (!mounted) return;
    setState(() => _isLoading = false);
    if (result.isFailure) {
      setState(() => _errorMessage = result.failure.toString());
      HapticEngine.heavyImpact();
    } else {
      HapticEngine.success();
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

    Widget card = Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: L.card,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: L.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.p20,
              AppSpacing.p20,
              AppSpacing.p20,
              AppSpacing.p12,
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
                  child: Icon(Icons.verified_user_rounded,
                      size: 18, color: L.text),
                ),
                const SizedBox(width: AppSpacing.p12),
                Expanded(
                  child: Text(
                    'Know your medicine',
                    style: AppTypography.titleMedium.copyWith(
                      color: L.text,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.p12,
                    vertical: AppSpacing.p4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.pastelMint,
                    borderRadius: BorderRadius.circular(AppRadius.max),
                  ),
                  child: Text(
                    s.verified,
                    style: AppTypography.labelSmall.copyWith(
                      color: const Color(0xFF3D6B45),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.p20,
              0,
              AppSpacing.p20,
              AppSpacing.p20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (profile.warnings.isNotEmpty)
                  _SafetyBlock(
                    title: s.criticalWarnings,
                    items: profile.warnings,
                    tint: AppColors.pastelPink,
                    accent: const Color(0xFF9B3D45),
                    icon: Icons.warning_amber_rounded,
                    danger: true,
                  ),
                if (profile.interactions.isNotEmpty) ...[
                  if (profile.warnings.isNotEmpty)
                    const SizedBox(height: AppSpacing.p12),
                  _SafetyBlock(
                    title: s.drugInteractions,
                    items: profile.interactions,
                    tint: AppColors.pastelPink,
                    accent: const Color(0xFF9B3D45),
                    icon: Icons.link_off_rounded,
                    danger: true,
                  ),
                ],
                if (profile.foodRules.isNotEmpty) ...[
                  if (profile.warnings.isNotEmpty ||
                      profile.interactions.isNotEmpty)
                    const SizedBox(height: AppSpacing.p12),
                  _SafetyBlock(
                    title: s.dietaryLifestyleRules,
                    items: profile.foodRules,
                    tint: AppColors.pastelMint,
                    accent: const Color(0xFF3D6B45),
                    icon: Icons.restaurant_rounded,
                  ),
                ],
                if (profile.ahaMoments.isNotEmpty) ...[
                  if (profile.warnings.isNotEmpty ||
                      profile.interactions.isNotEmpty ||
                      profile.foodRules.isNotEmpty)
                    const SizedBox(height: AppSpacing.p12),
                  _SafetyBlock(
                    title: s.ahaInsight,
                    items: profile.ahaMoments,
                    tint: AppColors.pastelLilac,
                    accent: L.text.withValues(alpha: 0.75),
                    icon: Icons.lightbulb_outline_rounded,
                  ),
                ],
                if (profile.warnings.isEmpty &&
                    profile.interactions.isEmpty &&
                    profile.foodRules.isEmpty &&
                    profile.ahaMoments.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.p16),
                    decoration: BoxDecoration(
                      color: AppColors.pastelMint,
                      borderRadius: BorderRadius.circular(AppRadius.l),
                    ),
                    child: Text(
                      'No special safety alerts found for this medication.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: L.text,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
          .fadeIn(duration: AppDurations.fast)
          .slideY(begin: 0.04, end: 0, curve: AppCurves.smooth);
    }
    return card;
  }

  Widget _buildErrorState(
      AppThemeColors L, AppLocalizations s, bool reduceMotion) {
    Widget card = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.p24),
      decoration: BoxDecoration(
        color: AppColors.pastelPink,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.red.withValues(alpha: 0.22)),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline_rounded, color: AppColors.red, size: 28),
          const SizedBox(height: AppSpacing.p12),
          Text(
            s.analysisFailed,
            style: AppTypography.titleMedium.copyWith(
              color: L.text,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.p8),
          Text(
            _errorMessage ?? s.somethingWentWrong,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(color: L.sub, height: 1.4),
          ),
          const SizedBox(height: AppSpacing.p20),
          MedAiCTA(
            label: s.retry,
            onTap: _runScan,
            semanticsLabel: s.retry,
          ),
        ],
      ),
    );

    if (reduceMotion) return card;
    return card.animate().fadeIn(duration: AppDurations.fast);
  }

  Widget _buildScanPrompt(
      AppThemeColors L, AppLocalizations s, bool reduceMotion) {
    Widget card = Semantics(
      button: true,
      enabled: !_isLoading,
      label: s.generateSafetyProfile,
      child: AnimatedPressable(
        onTap: _isLoading ? null : _runScan,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.p24),
          decoration: BoxDecoration(
            color: AppColors.pastelSky,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: L.border.withValues(alpha: 0.4)),
          ),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  shape: BoxShape.circle,
                ),
                child: _isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: AppLoadingIndicator(size: 28),
                      )
                    : Icon(Icons.auto_awesome_rounded,
                        size: 26, color: L.text),
              ),
              const SizedBox(height: AppSpacing.p16),
              Text(
                _isLoading
                    ? s.analyzingClinicalLimits
                    : 'Know your medicine',
                textAlign: TextAlign.center,
                style: AppTypography.titleMedium.copyWith(
                  color: L.text,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.p8),
              Text(
                _isLoading
                    ? s.safetyLoadingSubtitle
                    : 'Tap to unlock warnings, interactions, and how to take with confidence.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: L.sub,
                  height: 1.45,
                ),
              ),
              if (!_isLoading) ...[
                const SizedBox(height: AppSpacing.p16),
                Text(
                  s.generateSafetyProfile,
                  style: AppTypography.labelMedium.copyWith(
                    color: L.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (reduceMotion) return card;
    return card
        .animate()
        .fadeIn(duration: AppDurations.fast)
        .slideY(begin: 0.04, end: 0, curve: AppCurves.smooth);
  }
}

class _SafetyBlock extends StatelessWidget {
  final String title;
  final List<String> items;
  final Color tint;
  final Color accent;
  final IconData icon;
  final bool danger;

  const _SafetyBlock({
    required this.title,
    required this.items,
    required this.tint,
    required this.accent,
    required this.icon,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final cleanTitle =
        title.replaceAll(RegExp(r'[^\w\s&/-]'), '').trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.p16),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(AppRadius.l),
        border: danger
            ? Border.all(color: accent.withValues(alpha: 0.22))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: accent),
              const SizedBox(width: AppSpacing.p8),
              Expanded(
                child: Text(
                  cleanTitle,
                  style: AppTypography.labelMedium.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (danger)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.p8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(AppRadius.max),
                  ),
                  child: Text(
                    'Alert',
                    style: AppTypography.labelSmall.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.p12),
          for (final item in items.take(6))
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.p8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 7),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.p12),
                  Expanded(
                    child: Text(
                      item,
                      style: AppTypography.bodyMedium.copyWith(
                        color: L.text,
                        height: 1.4,
                        fontWeight:
                            danger ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
