import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../domain/entities/body_impact.dart';
import '../../../domain/entities/scan_result.dart';
import '../../../theme/med_ai_ui.dart';
import '../../../widgets/common/animated_pressable.dart';
import '../../../widgets/shared/shared_widgets.dart' show MedImage;
import 'confidence_meter.dart';

/// Full-fidelity scan result — Cal AI / June 2026 detail sheet.
/// Surfaces every field from [ScanResult] in scannable sections.
class ScanResultDetailView extends StatelessWidget {
  final ScanResult result;
  final File? capturedImage;
  final VoidCallback onAddToMedicines;
  final VoidCallback onScanAnother;
  final VoidCallback? onClose;
  final bool onDark;

  const ScanResultDetailView({
    super.key,
    required this.result,
    required this.onAddToMedicines,
    required this.onScanAnother,
    this.capturedImage,
    this.onClose,
    this.onDark = true,
  });

  static double confidenceValue(String raw) {
    final trimmed = raw.trim();
    final pct = double.tryParse(trimmed.replaceAll('%', ''));
    if (pct != null) return (pct / 100).clamp(0.0, 1.0);
    switch (trimmed.toLowerCase()) {
      case 'high':
      case 'very high':
        return 0.92;
      case 'medium':
      case 'moderate':
        return 0.72;
      case 'low':
        return 0.45;
      default:
        return 0.78;
    }
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final reduceMotion = MedAiA11y.reducedMotion(context);
    final name = result.name.isNotEmpty ? result.name : 'Unknown product';
    final confidence = confidenceValue(result.confidence);

    final fg = onDark ? Colors.white : L.text;
    final sub = onDark ? Colors.white.withValues(alpha: 0.62) : L.sub;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (onClose != null)
          Align(
            alignment: Alignment.centerRight,
            child: Semantics(
              button: true,
              label: 'Close results',
              child: AnimatedPressable(
                onTap: onClose,
                child: Container(
                  width: MedAiA11y.minTapTarget,
                  height: MedAiA11y.minTapTarget,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: onDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : L.fill.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close_rounded,
                      color: fg.withValues(alpha: 0.85), size: 22),
                ),
              ),
            ),
          ),
          
        const SizedBox(height: 8),

        Text(
          'Scan Result',
          style: AppTypography.labelMedium.copyWith(
            color: sub.withValues(alpha: 0.9),
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),

        const SizedBox(height: 10),

        // Header Card
        _entrance(
          reduceMotion,
          _PrimaryHeroCard(
            name: name,
            brand: result.brand,
            genericName: result.genericName,
            identified: result.identified,
            confidence: confidence,
            capturedImage: capturedImage,
            imageUrl: result.imageUrl,
            onDark: onDark,
          ),
          delay: 50.ms,
        ),

        if (result.ahaMoment != null && result.ahaMoment!.isNotEmpty) ...[
          const SizedBox(height: 20),
          _entrance(
            reduceMotion,
            _InsightBanner(text: result.ahaMoment!, onDark: onDark),
            delay: 100.ms,
          ),
        ],

        const SizedBox(height: 24),

        _entrance(
          reduceMotion,
          _QuickFactsGrid(result: result, onDark: onDark),
          delay: 120.ms,
        ),

        // Dosage & Supply
        if (_hasDosingInfo || _hasPackInfo) ...[
          const SizedBox(height: 20),
          _entrance(
            reduceMotion,
            _GroupedSection(
              title: 'Dosage & Supply',
              icon: Icons.medication_liquid_rounded,
              onDark: onDark,
              children: [
                if (_hasDosingInfo) _GroupedItem(icon: Icons.schedule_rounded, label: 'How to take', text: _dosingBody, onDark: onDark),
                if (_hasPackInfo) _GroupedItem(icon: Icons.inventory_2_outlined, label: 'Pack info', text: _packBody, onDark: onDark),
              ],
            ),
            delay: 140.ms,
          ),
        ],

        // Safety Profile
        if (result.warnings.isNotEmpty || result.sideEffects.isNotEmpty || result.interactions.isNotEmpty) ...[
          const SizedBox(height: 20),
          _entrance(
            reduceMotion,
            _GroupedSection(
              title: 'Safety Profile',
              icon: Icons.health_and_safety_rounded,
              accent: AppColors.amber,
              onDark: onDark,
              children: [
                _SafetySnapshot(
                  warningCount: _estimatedBulletCount(result.warnings),
                  interactionCount: _estimatedBulletCount(result.interactions),
                  sideEffectCount: _estimatedBulletCount(result.sideEffects),
                  onDark: onDark,
                ),
                if (result.warnings.isNotEmpty) _GroupedItem(icon: Icons.warning_amber_rounded, label: 'Warnings', text: result.warnings, accent: AppColors.amber, onDark: onDark),
                if (result.sideEffects.isNotEmpty) _GroupedItem(icon: Icons.healing_outlined, label: 'Side effects', text: result.sideEffects, onDark: onDark),
                if (result.interactions.isNotEmpty) _GroupedItem(icon: Icons.link_off_rounded, label: 'Interactions', text: result.interactions, accent: AppColors.red, onDark: onDark),
              ],
            ),
            delay: 160.ms,
          ),
        ],

        // Details
        if (result.description.isNotEmpty || result.storage.isNotEmpty) ...[
          const SizedBox(height: 20),
          _entrance(
            reduceMotion,
            _GroupedSection(
              title: 'Details',
              icon: Icons.info_outline_rounded,
              onDark: onDark,
              children: [
                if (result.description.isNotEmpty) _GroupedItem(icon: Icons.article_outlined, label: 'Overview', text: result.description, onDark: onDark),
                if (result.storage.isNotEmpty) _GroupedItem(icon: Icons.ac_unit_outlined, label: 'Storage', text: result.storage, onDark: onDark),
              ],
            ),
            delay: 180.ms,
          ),
        ],

        if (_hasRegulatoryInfo) ...[
          const SizedBox(height: 20),
          _entrance(
            reduceMotion,
            _RegulatorySection(result: result, onDark: onDark),
            delay: 200.ms,
          ),
        ],

        if (result.bodyImpact != null &&
            result.bodyImpact!.mechanismOfAction.isNotEmpty) ...[
          const SizedBox(height: 20),
          _entrance(
            reduceMotion,
            _BodyImpactSection(impact: result.bodyImpact!, onDark: onDark),
            delay: 220.ms,
          ),
        ],

        const SizedBox(height: 40),

        // CTAs in a premium action panel
        _entrance(
          reduceMotion,
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: onDark ? Colors.white.withValues(alpha: 0.04) : L.card,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(
                color: onDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : L.border.withValues(alpha: 0.5),
              ),
              boxShadow: AppShadows.premium,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'What would you like to do next?',
                  textAlign: TextAlign.center,
                  style: AppTypography.labelLarge.copyWith(
                    color: fg.withValues(alpha: 0.95),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                MedAiCTA(
                  label: 'Add to My Medicines',
                  icon: Icons.add_rounded,
                  onTap: onAddToMedicines,
                ),
                const SizedBox(height: 16),
                MedAiCTA(
                  label: 'Scan another',
                  secondary: true,
                  onTap: onScanAnother,
                ),
              ],
            ),
          ),
          delay: 240.ms,
        ),

        const SizedBox(height: 20),

        Text(
          'AI identification — always verify with your pharmacist or prescriber.',
          textAlign: TextAlign.center,
          style: AppTypography.bodySmall.copyWith(
            color: sub.withValues(alpha: 0.9),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  bool get _hasDosingInfo =>
      result.howToTake.isNotEmpty ||
      result.whenToTake.isNotEmpty ||
      result.frequency.isNotEmpty ||
      result.dosePerTake.isNotEmpty;

  String get _dosingBody {
    final parts = <String>[];
    if (result.dosePerTake.isNotEmpty) parts.add('Dose: ${result.dosePerTake}');
    if (result.howToTake.isNotEmpty) parts.add(result.howToTake);
    if (result.whenToTake.isNotEmpty) parts.add('When: ${result.whenToTake}');
    if (result.frequency.isNotEmpty) parts.add('Frequency: ${result.frequency}');
    if (result.withFood) parts.add('Take with food');
    return parts.join('\n\n');
  }

  bool get _hasPackInfo =>
      result.pillCount > 0 ||
      result.packSize > 0 ||
      result.courseDurationDays != null ||
      result.scheduleSlots.isNotEmpty;

  String get _packBody {
    final parts = <String>[];
    if (result.packSize > 0) {
      parts.add('Pack size: ${result.packSize} ${result.unit}');
    }
    if (result.pillCount > 0 && result.pillCount != result.packSize) {
      parts.add('Count: ${result.pillCount} ${result.unit}');
    }
    if (result.refillAlert > 0) {
      parts.add('Refill alert at ${result.refillAlert} remaining');
    }
    if (result.volumeAmount > 0) {
      parts.add('Volume: ${result.volumeAmount} ${result.volumeUnit}');
    }
    if (result.courseType.isNotEmpty) {
      parts.add('Course: ${result.courseType}');
    }
    if (result.courseDurationDays != null && result.courseDurationDays! > 0) {
      parts.add('Duration: ${result.courseDurationDays} days');
    }
    if (result.scheduleSlots.isNotEmpty) {
      parts.add('Suggested schedule:');
      for (final slot in result.scheduleSlots) {
        final label = slot['label']?.toString() ?? 'Dose';
        final h = slot['h'] ?? 8;
        final m = slot['m'] ?? 0;
        parts.add('• $label — ${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}');
      }
    }
    return parts.join('\n');
  }

  bool get _hasRegulatoryInfo =>
      result.din.isNotEmpty ||
      result.halalStatus != 'unknown' ||
      result.halalNote.isNotEmpty;

  int _estimatedBulletCount(String raw) {
    if (raw.trim().isEmpty) return 0;
    final lines = raw
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final bullets = lines.where((e) => e.startsWith('•') || e.startsWith('-')).length;
    if (bullets > 0) return bullets;
    return lines.length.clamp(1, 8);
  }

  static Widget _entrance(bool reduceMotion, Widget child, {Duration? delay}) {
    if (reduceMotion) return child;
    return child
        .animate(delay: delay)
        .fadeIn(duration: AppDurations.fast, curve: AppCurves.smooth)
        .slideY(begin: 0.06, end: 0, curve: AppCurves.smooth);
  }
}

class _PrimaryHeroCard extends StatelessWidget {
  final String name;
  final String brand;
  final String genericName;
  final bool identified;
  final double confidence;
  final File? capturedImage;
  final String? imageUrl;
  final bool onDark;

  const _PrimaryHeroCard({
    required this.name,
    required this.brand,
    required this.genericName,
    required this.identified,
    required this.confidence,
    required this.capturedImage,
    required this.imageUrl,
    required this.onDark,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final fg = onDark ? Colors.white : L.text;
    final sub = onDark ? Colors.white.withValues(alpha: 0.62) : L.sub;
    final hasImage = capturedImage != null || (imageUrl != null && imageUrl!.isNotEmpty);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: onDark
              ? [
                  Colors.white.withValues(alpha: 0.06),
                  Colors.white.withValues(alpha: 0.02),
                ]
              : [
                  L.card,
                  L.card.withValues(alpha: 0.92),
                ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: onDark ? Colors.white.withValues(alpha: 0.12) : L.border,
          width: 1,
        ),
        boxShadow: AppShadows.premium,
      ),
      child: Column(
        children: [
          if (hasImage) ...[
            _HeroImage(
              capturedImage: capturedImage,
              imageUrl: imageUrl,
              onDark: onDark,
            ),
            const SizedBox(height: 18),
          ],
          _StatusBadge(identified: identified, onDark: onDark),
          const SizedBox(height: 14),
          Text(
            name,
            textAlign: TextAlign.center,
            style: AppTypography.displaySmall.copyWith(
              color: fg,
              fontWeight: FontWeight.w800,
              fontSize: 28,
              letterSpacing: -0.6,
              height: 1.1,
            ),
          ),
          if (brand.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              brand,
              textAlign: TextAlign.center,
              style: AppTypography.titleMedium.copyWith(
                color: sub,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (genericName.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Generic: $genericName',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(color: sub, height: 1.4),
            ),
          ],
          const SizedBox(height: 20),
          ConfidenceMeter(confidence: confidence, onDark: onDark),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool identified;
  final bool onDark;

  const _StatusBadge({required this.identified, required this.onDark});

  @override
  Widget build(BuildContext context) {
    final color = identified ? AppColors.sageGreen : AppColors.amber;
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppRadius.max),
          border: Border.all(color: color.withValues(alpha: 0.35), width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              identified ? Icons.check_circle_rounded : Icons.help_outline_rounded,
              color: color,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              identified ? 'Identified' : 'Partial match',
              style: AppTypography.labelMedium.copyWith(
                color: onDark ? Colors.white : context.L.text,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  final File? capturedImage;
  final String? imageUrl;
  final bool onDark;

  const _HeroImage({
    this.capturedImage,
    this.imageUrl,
    required this.onDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 184,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: onDark
              ? Colors.white.withValues(alpha: 0.15)
              : context.L.border.withValues(alpha: 0.3),
          width: 1.4,
        ),
        boxShadow: AppShadows.premium,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: capturedImage != null
            ? Image.file(capturedImage!, fit: BoxFit.cover)
            : MedImage(
                imageUrl: imageUrl!,
                borderRadius: 0,
                fit: BoxFit.cover,
              ),
      ),
    );
  }
}

class _InsightBanner extends StatelessWidget {
  final String text;
  final bool onDark;

  const _InsightBanner({required this.text, required this.onDark});

  @override
  Widget build(BuildContext context) {
    return MedAiGlass(
      radius: AppRadius.l,
      padding: const EdgeInsets.all(16),
      tint: AppColors.accent.withValues(alpha: onDark ? 0.12 : 0.08),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_rounded, color: AppColors.accent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodyMedium.copyWith(
                color: onDark ? Colors.white : context.L.text,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickFactsGrid extends StatelessWidget {
  final ScanResult result;
  final bool onDark;

  const _QuickFactsGrid({required this.result, required this.onDark});

  @override
  Widget build(BuildContext context) {
    final facts = <(IconData, String, String)>[];

    void add(IconData icon, String label, String value) {
      if (value.isNotEmpty) facts.add((icon, label, value));
    }

    add(Icons.medication_rounded, 'Dosage', result.dose);
    add(Icons.straighten_rounded, 'Dose per take', result.dosePerTake);
    add(Icons.category_rounded, 'Form', _formLabel);
    add(Icons.label_outline_rounded, 'Category', result.category);
    add(Icons.repeat_rounded, 'Frequency', result.frequency);
    add(Icons.wb_sunny_outlined, 'When', result.whenToTake);

    if (result.isAntibiotic) {
      add(Icons.coronavirus_outlined, 'Type', 'Antibiotic');
    }
    if (result.isLiquid) add(Icons.water_drop_outlined, 'Format', 'Liquid');
    if (result.isSpray) add(Icons.air_outlined, 'Format', 'Spray');
    if (result.isSachet) add(Icons.inventory_outlined, 'Format', 'Sachet');

    if (facts.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: facts.map((f) => _FactChip(
            icon: f.$1,
            label: f.$2,
            value: f.$3,
            onDark: onDark,
          )).toList(),
    );
  }

  String get _formLabel {
    if (result.form.isEmpty) return '';
    return result.form[0].toUpperCase() + result.form.substring(1);
  }
}

class _FactChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool onDark;

  const _FactChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.onDark,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return MedAiGlass(
      radius: AppRadius.m,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      tint: onDark ? Colors.white.withValues(alpha: 0.08) : L.card,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.sageGreen),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: onDark
                      ? Colors.white.withValues(alpha: 0.5)
                      : L.sub,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTypography.labelMedium.copyWith(
                  color: onDark ? Colors.white : L.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GroupedSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  final Color? accent;
  final bool onDark;

  const _GroupedSection({
    required this.title,
    required this.icon,
    required this.children,
    this.accent,
    required this.onDark,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final accentColor = accent ?? AppColors.sageGreen;
    final fg = onDark ? Colors.white : L.text;

    return MedAiGlass(
      radius: AppRadius.l,
      padding: const EdgeInsets.all(20),
      tint: onDark ? Colors.white.withValues(alpha: 0.04) : L.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: accentColor),
              ),
              const SizedBox(width: 14),
              Text(
                title,
                style: AppTypography.titleMedium.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children.map((child) => Padding(
            padding: EdgeInsets.only(bottom: child == children.last ? 0 : 20),
            child: child,
          )),
        ],
      ),
    );
  }
}

class _GroupedItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String text;
  final Color? accent;
  final bool onDark;

  const _GroupedItem({
    required this.icon,
    required this.label,
    required this.text,
    this.accent,
    required this.onDark,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final sub = onDark ? Colors.white.withValues(alpha: 0.7) : L.sub;
    final fg = onDark ? Colors.white : L.text;
    final accentColor =
        accent ?? (onDark ? Colors.white.withValues(alpha: 0.5) : L.sub.withValues(alpha: 0.5));
    final bg = accentColor.withValues(alpha: onDark ? 0.12 : 0.08);
    final border = accentColor.withValues(alpha: onDark ? 0.38 : 0.24);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.m),
        border: Border.all(color: border, width: 0.7),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: accentColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.labelMedium.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  text,
                  style: AppTypography.bodySmall.copyWith(
                    color: sub,
                    height: 1.5,
                    fontSize: 14,
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

class _SafetySnapshot extends StatelessWidget {
  final int warningCount;
  final int interactionCount;
  final int sideEffectCount;
  final bool onDark;

  const _SafetySnapshot({
    required this.warningCount,
    required this.interactionCount,
    required this.sideEffectCount,
    required this.onDark,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _SafetyCountChip(
          label: 'Warnings',
          value: warningCount,
          color: AppColors.amber,
          onDark: onDark,
        ),
        _SafetyCountChip(
          label: 'Interactions',
          value: interactionCount,
          color: AppColors.red,
          onDark: onDark,
        ),
        _SafetyCountChip(
          label: 'Side effects',
          value: sideEffectCount,
          color: AppColors.purple,
          onDark: onDark,
        ),
      ],
    );
  }
}

class _SafetyCountChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final bool onDark;

  const _SafetyCountChip({
    required this.label,
    required this.value,
    required this.color,
    required this.onDark,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final textColor = onDark ? Colors.white : L.text;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: onDark ? 0.16 : 0.12),
        borderRadius: BorderRadius.circular(AppRadius.max),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 0.7),
      ),
      child: Text(
        '$label: $value',
        style: AppTypography.labelSmall.copyWith(
          color: textColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _RegulatorySection extends StatelessWidget {
  final ScanResult result;
  final bool onDark;

  const _RegulatorySection({required this.result, required this.onDark});

  @override
  Widget build(BuildContext context) {
    final parts = <String>[];
    if (result.din.isNotEmpty) parts.add('DIN: ${result.din}');
    if (result.halalStatus != 'unknown') {
      parts.add('Halal status: ${_formatHalal(result.halalStatus)}');
    }
    if (result.halalNote.isNotEmpty) parts.add(result.halalNote);

    return _GroupedSection(
      title: 'Regulatory',
      icon: Icons.verified_user_outlined,
      onDark: onDark,
      children: [
        _GroupedItem(
          icon: Icons.rule_rounded,
          label: 'Information',
          text: parts.join('\\n\\n'),
          onDark: onDark,
        ),
      ],
    );
  }

  String _formatHalal(String status) {
    return status
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}

class _BodyImpactSection extends StatelessWidget {
  final BodyImpactSummary impact;
  final bool onDark;

  const _BodyImpactSection({required this.impact, required this.onDark});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final fg = onDark ? Colors.white : L.text;
    final sub = onDark ? Colors.white.withValues(alpha: 0.7) : L.sub;

    final systems = impact.bodySystems;
    final facts = impact.ahaFacts;

    return MedAiGlass(
      radius: AppRadius.l,
      padding: const EdgeInsets.all(18),
      tint: onDark ? Colors.white.withValues(alpha: 0.06) : L.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.biotech_rounded,
                  size: 18, color: AppColors.accent),
              const SizedBox(width: 10),
              Text(
                'Body impact',
                style: AppTypography.titleMedium.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            impact.mechanismOfAction,
            style: AppTypography.bodySmall.copyWith(color: sub, height: 1.55),
          ),
          if (impact.onsetMinutes > 0 ||
              impact.peakHours > 0 ||
              impact.durationHours > 0) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (impact.onsetMinutes > 0)
                  _TimelineChip(
                      label: 'Onset', value: '${impact.onsetMinutes} min'),
                if (impact.peakHours > 0)
                  _TimelineChip(
                      label: 'Peak', value: '${impact.peakHours}h'),
                if (impact.durationHours > 0)
                  _TimelineChip(
                      label: 'Duration', value: '${impact.durationHours}h'),
              ],
            ),
          ],
          if (systems.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Systems: ${systems.join(', ')}',
              style: AppTypography.labelSmall.copyWith(color: sub),
            ),
          ],
          if (facts.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...facts.map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ', style: TextStyle(color: AppColors.accent)),
                    Expanded(
                      child: Text(f,
                          style: AppTypography.bodySmall
                              .copyWith(color: sub, height: 1.4)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TimelineChip extends StatelessWidget {
  final String label;
  final String value;

  const _TimelineChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.s),
      ),
      child: Text(
        '$label · $value',
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.accent,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
