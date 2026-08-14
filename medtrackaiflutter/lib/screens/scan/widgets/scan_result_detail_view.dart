import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../domain/entities/body_impact.dart';
import '../../../domain/entities/scan_result.dart';
import '../../../theme/med_ai_ui.dart';
import '../../../widgets/common/animated_pressable.dart';
import '../../../widgets/shared/shared_widgets.dart' show MedImage;
import 'premium_scan_result_chrome.dart';

/// Post-scan medicine result — 100% premium redesign matching reference
/// wellness UI (pastel tiles, large %, soft cards, airy spacing).
class ScanResultDetailView extends StatelessWidget {
  final ScanResult result;
  final File? capturedImage;
  final VoidCallback onAddToMedicines;
  final VoidCallback onScanAnother;
  final VoidCallback? onClose;
  final bool onDark;
  final bool showInlineActions;

  const ScanResultDetailView({
    super.key,
    required this.result,
    required this.onAddToMedicines,
    required this.onScanAnother,
    this.capturedImage,
    this.onClose,
    this.onDark = false,
    this.showInlineActions = true,
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
    final pct = (confidence * 100).round();
    final category = result.category.isNotEmpty ? result.category : 'Medicine';

    final statusLabel = !result.identified
        ? 'Review carefully'
        : (result.warnings.isNotEmpty ? 'Use with care' : 'Looking good');
    final statusTint = !result.identified
        ? AppColors.pastelSun
        : (result.warnings.isNotEmpty
            ? AppColors.pastelPink
            : AppColors.pastelMint);
    final statusIcon = !result.identified
        ? Icons.help_outline_rounded
        : (result.warnings.isNotEmpty
            ? Icons.priority_high_rounded
            : Icons.verified_rounded);
    // Category-aware kicker: tailor the eyebrow to what was scanned so
    // supplements and skincare feel first-class, not shoehorned into "pill".
    final catLower = category.toLowerCase();
    final (kindLabel, kindIcon) = catLower.contains('supplement') ||
            catLower.contains('vitamin')
        ? ('Supplement', Icons.eco_rounded)
        : (catLower.contains('skin') ||
                catLower.contains('cream') ||
                catLower.contains('cosmetic'))
            ? ('Skincare', Icons.spa_rounded)
            : ('Medicine', Icons.medication_rounded);
    // Ink is darkened tint-family so the label reads on the pastel chip and
    // the danger case (pink) carries genuine red weight, not soft text.
    final statusInk = !result.identified
        ? AppColors.amber
        : (result.warnings.isNotEmpty ? AppColors.red : AppColors.accentDeep);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (onClose != null)
          Align(
            alignment: AlignmentDirectional.centerEnd,
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
                    color: L.fill,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close_rounded, color: L.text, size: 22),
                ),
              ),
            ),
          ),

        _in(
          reduceMotion,
          _PhotoHero(
            capturedImage: capturedImage,
            imageUrl: result.imageUrl,
            category: category,
          ),
          40.ms,
        ),

        const SizedBox(height: AppSpacing.p20),
        // Reference-style eyebrow — small, confident, brand-colored kicker
        // above the product name (mirrors the mockup's "⚡ DAILY DOSES" tag).
        Row(
          children: [
            Icon(kindIcon, size: 14, color: AppColors.accentDeep),
            const SizedBox(width: 6),
            Text(
              kindLabel.toUpperCase(),
              style: AppTypography.caption.copyWith(
                color: AppColors.accentDeep,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.p8),
        Text(
          name,
          style: AppTypography.displaySmall.copyWith(
            color: L.text,
            fontWeight: FontWeight.w800,
            fontSize: 30,
            letterSpacing: -0.8,
            height: 1.08,
          ),
        ),
        if (result.brand.isNotEmpty || result.genericName.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.p8),
          Text(
            [
              if (result.brand.isNotEmpty) result.brand,
              if (result.genericName.isNotEmpty) result.genericName,
            ].join(' · '),
            style: AppTypography.bodyMedium.copyWith(
              color: L.sub,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.p12),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.p12,
              vertical: AppSpacing.p8,
            ),
            decoration: BoxDecoration(
              color: statusTint,
              borderRadius: BorderRadius.circular(AppRadius.max),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon, size: 14, color: statusInk),
                const SizedBox(width: 6),
                Text(
                  statusLabel,
                  style: AppTypography.labelSmall.copyWith(
                    color: statusInk,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.p20),
        _in(
          reduceMotion,
          ScanConfidenceHero(
            percent: pct,
            accent: result.identified ? AppColors.sageGreen : AppColors.amber,
            caption: result.identified
                ? 'Smart match based on your scan — verify with a pharmacist when unsure.'
                : 'Not confirmed yet — try another angle or search by name.',
            title: 'Scan confidence',
          ),
          60.ms,
        ),

        // ── LOW-CONFIDENCE RECOVERY ───────────────────────────────────
        // When the scan didn't confirm a match, the honest next step is to
        // rescan or search — not to track a guessed "Identified Pill". Guide
        // the user rather than leaving a sparse, half-empty result.
        if (!result.identified) ...[
          const SizedBox(height: AppSpacing.p16),
          _in(
            reduceMotion,
            ScanSoftSection(
              title: 'Not confirmed yet',
              subtitle: 'Let’s get you a sharper match.',
              tint: AppColors.pastelSun,
              icon: Icons.search_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Try a straight-on photo of the label in good light, or '
                    'scan another angle. You can still track it manually and '
                    'fill in the details yourself.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: L.text.withValues(alpha: 0.88),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.p12),
                  MedAiCTA(
                    label: 'Scan again',
                    icon: Icons.qr_code_scanner_rounded,
                    secondary: true,
                    fullWidth: false,
                    onTap: onScanAnother,
                  ),
                ],
              ),
            ),
            70.ms,
          ),
        ],

        // ── SAFETY FIRST ──────────────────────────────────────────────
        // In a medication app the warning IS the point of the scan, so
        // danger/interaction cues surface immediately after the hero —
        // above general info — matching the reference safety-led layout.
        if (result.warnings.isNotEmpty || result.interactions.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.p24),
          Row(
            children: [
              Icon(
                Icons.shield_outlined,
                size: 18,
                color: AppColors.red,
              ),
              const SizedBox(width: AppSpacing.p8),
              Text(
                'Safety first',
                style: AppTypography.headlineSmall.copyWith(
                  color: L.text,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.p12),
        ],

        if (result.warnings.isNotEmpty) ...[
          _in(
            reduceMotion,
            ScanSoftSection(
              title: 'Important warnings',
              subtitle: 'Know before you take — you’ve got this.',
              tint: AppColors.pastelPink,
              icon: Icons.priority_high_rounded,
              child: Text(
                result.warnings,
                style: AppTypography.bodyMedium.copyWith(
                  color: L.text.withValues(alpha: 0.88),
                  height: 1.5,
                ),
              ),
            ),
            80.ms,
          ),
        ],

        if (result.interactions.isNotEmpty) ...[
          if (result.warnings.isNotEmpty)
            const SizedBox(height: AppSpacing.p12),
          _in(
            reduceMotion,
            ScanSoftSection(
              title: 'Interactions',
              subtitle: 'Check against what you already take.',
              tint: AppColors.pastelSun,
              icon: Icons.link_off_rounded,
              child: Text(
                result.interactions,
                style: AppTypography.bodyMedium.copyWith(
                  color: L.text.withValues(alpha: 0.88),
                  height: 1.5,
                ),
              ),
            ),
            100.ms,
          ),
        ],

        const SizedBox(height: AppSpacing.p24),
        Text(
          'Know your medicine',
          style: AppTypography.headlineSmall.copyWith(
            color: L.text,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: AppSpacing.p4),
        Text(
          'Details built for you — clear, trusted, and ready to track.',
          style: AppTypography.bodySmall.copyWith(color: L.sub, height: 1.4),
        ),

        if (_insightTiles.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.p16),
          _in(
            reduceMotion,
            ScanInsightGrid(tiles: _insightTiles),
            120.ms,
          ),
        ],

        // ── DID YOU KNOW? ─────────────────────────────────────────────
        // The AI returns a one-line awareness fact on every scan; surface
        // it as a small delight moment instead of dropping it silently.
        if (result.ahaMoment != null && result.ahaMoment!.trim().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.p16),
          _in(
            reduceMotion,
            Container(
              padding: const EdgeInsets.all(AppSpacing.p16),
              decoration: BoxDecoration(
                color: AppColors.pastelMint,
                borderRadius: BorderRadius.circular(AppRadius.l),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.72),
                      borderRadius: AppRadius.roundS,
                    ),
                    child: Icon(
                      Icons.lightbulb_outline_rounded,
                      size: 18,
                      color: L.text,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.p12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Did you know?',
                          style: AppTypography.labelSmall.copyWith(
                            color: L.sub,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          result.ahaMoment!.trim(),
                          style: AppTypography.bodyMedium.copyWith(
                            color: L.text.withValues(alpha: 0.9),
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            140.ms,
          ),
        ],

        if (_sideEffectBubbles.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.p24),
          Text(
            'Side-effect map',
            style: AppTypography.titleMedium.copyWith(
              color: L.text,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.p12),
          _in(
            reduceMotion,
            ScanBubbleRow(items: _sideEffectBubbles),
            140.ms,
          ),
        ],

        if (_hasDosingInfo) ...[
          const SizedBox(height: AppSpacing.p12),
          _in(
            reduceMotion,
            ScanSoftSection(
              title: 'How to take',
              subtitle: 'Timing and instructions for confidence.',
              tint: AppColors.pastelSky,
              icon: Icons.schedule_rounded,
              child: _BulletLines(lines: _dosingLines),
            ),
            160.ms,
          ),
        ],

        if (_hasPackInfo) ...[
          const SizedBox(height: AppSpacing.p12),
          _in(
            reduceMotion,
            ScanSoftSection(
              title: 'Pack & course',
              tint: AppColors.pastelMint,
              icon: Icons.inventory_2_outlined,
              child: _BulletLines(lines: _packLines),
            ),
            180.ms,
          ),
        ],

        if (result.description.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.p12),
          _in(
            reduceMotion,
            ScanSoftSection(
              title: 'About',
              tint: AppColors.pastelMint,
              icon: Icons.menu_book_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.description,
                    style: AppTypography.bodyMedium.copyWith(
                      color: L.sub,
                      height: 1.5,
                    ),
                  ),
                  if (result.storage.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.p12),
                    Text(
                      'Storage · ${result.storage}',
                      style: AppTypography.labelMedium.copyWith(
                        color: L.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            200.ms,
          ),
        ],

        if (result.bodyImpact != null &&
            result.bodyImpact!.mechanismOfAction.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.p12),
          _in(
            reduceMotion,
            _BodyImpactPremium(impact: result.bodyImpact!),
            220.ms,
          ),
        ],

        if (_hasRegulatoryInfo) ...[
          const SizedBox(height: AppSpacing.p12),
          _in(
            reduceMotion,
            ScanSoftSection(
              title: 'Regulatory',
              tint: const Color(0xFFF3F0EA),
              icon: Icons.verified_outlined,
              child: _BulletLines(lines: _regulatoryLines),
            ),
            240.ms,
          ),
        ],

        const SizedBox(height: AppSpacing.p24),
        Text(
          'AI identification — always verify with your pharmacist or prescriber.',
          textAlign: TextAlign.center,
          style: AppTypography.bodySmall.copyWith(
            color: L.sub.withValues(alpha: 0.9),
            height: 1.5,
          ),
        ),

        if (showInlineActions) ...[
          const SizedBox(height: AppSpacing.p24),
          _in(
            reduceMotion,
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MedAiCTA(
                  label: 'Track medicine',
                  icon: Icons.add_rounded,
                  onTap: onAddToMedicines,
                ),
                const SizedBox(height: AppSpacing.p12),
                MedAiCTA(
                  label: 'Scan another',
                  secondary: true,
                  onTap: onScanAnother,
                ),
              ],
            ),
            260.ms,
          ),
        ],
      ],
    );
  }

  List<ScanInsightTile> get _insightTiles {
    final tiles = <ScanInsightTile>[];
    void add(String label, String value, Color tint, IconData icon) {
      if (value.trim().isEmpty) return;
      tiles.add(ScanInsightTile(
        label: label,
        value: value,
        tint: tint,
        icon: icon,
      ));
    }

    add(
      'Dosage',
      result.dose.isNotEmpty ? result.dose : result.dosePerTake,
      AppColors.pastelSky,
      Icons.medication_rounded,
    );
    add(
      'Form',
      _formLabel,
      AppColors.pastelMint,
      Icons.category_rounded,
    );
    add(
      'Frequency',
      result.frequency,
      AppColors.pastelSun,
      Icons.repeat_rounded,
    );
    add(
      'When',
      result.whenToTake.isNotEmpty ? result.whenToTake : categoryFallback,
      AppColors.pastelMint,
      Icons.wb_sunny_outlined,
    );
    return tiles.take(4).toList();
  }

  String get categoryFallback =>
      result.category.isNotEmpty ? result.category : 'As directed';

  String get _formLabel {
    if (result.form.isEmpty) return '';
    return result.form[0].toUpperCase() + result.form.substring(1);
  }

  List<({String label, Color color})> get _sideEffectBubbles {
    if (result.sideEffects.trim().isEmpty) return const [];
    final parts = result.sideEffects
        .split(RegExp(r'[,;\n•]+'))
        .map((e) => e.trim())
        .where((e) => e.length > 2)
        .take(6)
        .toList();
    const colors = [
      AppColors.pastelSky,
      AppColors.pastelSun,
      AppColors.pastelPink,
      AppColors.pastelMint,
      AppColors.pastelMint,
      Color(0xFFF3F0EA),
    ];
    return [
      for (var i = 0; i < parts.length; i++)
        (label: parts[i], color: colors[i % colors.length]),
    ];
  }

  bool get _hasDosingInfo =>
      result.howToTake.isNotEmpty ||
      result.whenToTake.isNotEmpty ||
      result.frequency.isNotEmpty ||
      result.dosePerTake.isNotEmpty;

  List<String> get _dosingLines {
    final parts = <String>[];
    if (result.dosePerTake.isNotEmpty) parts.add('Dose: ${result.dosePerTake}');
    if (result.howToTake.isNotEmpty) parts.add(result.howToTake);
    if (result.whenToTake.isNotEmpty) parts.add('When: ${result.whenToTake}');
    if (result.frequency.isNotEmpty) {
      parts.add('Frequency: ${result.frequency}');
    }
    if (result.withFood) parts.add('Take with food');
    return parts;
  }

  bool get _hasPackInfo =>
      result.pillCount > 0 ||
      result.packSize > 0 ||
      result.courseDurationDays != null ||
      result.scheduleSlots.isNotEmpty;

  List<String> get _packLines {
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
      for (final slot in result.scheduleSlots) {
        final label = slot['label']?.toString() ?? 'Dose';
        final h = slot['h'] ?? 8;
        final m = slot['m'] ?? 0;
        parts.add(
          '$label — ${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}',
        );
      }
    }
    return parts;
  }

  bool get _hasRegulatoryInfo =>
      result.din.isNotEmpty ||
      result.halalStatus != 'unknown' ||
      result.halalNote.isNotEmpty;

  List<String> get _regulatoryLines {
    final parts = <String>[];
    if (result.din.isNotEmpty) parts.add('DIN: ${result.din}');
    if (result.halalStatus != 'unknown') {
      parts.add('Halal: ${_formatHalal(result.halalStatus)}');
    }
    if (result.halalNote.isNotEmpty) parts.add(result.halalNote);
    return parts;
  }

  String _formatHalal(String status) {
    return status
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  static Widget _in(bool reduceMotion, Widget child, Duration delay) {
    if (reduceMotion) return child;
    return child
        .animate(delay: delay)
        .fadeIn(duration: AppDurations.fast, curve: AppCurves.emilOut)
        .slideY(begin: 0.04, end: 0, curve: AppCurves.emilOut);
  }
}

class _PhotoHero extends StatelessWidget {
  final File? capturedImage;
  final String? imageUrl;
  final String category;

  const _PhotoHero({
    required this.capturedImage,
    required this.imageUrl,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final hasImage =
        capturedImage != null || (imageUrl != null && imageUrl!.isNotEmpty);

    return ClipRRect(
      borderRadius: BorderRadius.circular(ScanResultChrome.cardRadius),
      child: AspectRatio(
        aspectRatio: 16 / 11,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: AppColors.pastelSky,
              child: hasImage
                  ? (capturedImage != null
                      ? Image.file(capturedImage!, fit: BoxFit.cover)
                      : MedImage(
                          imageUrl: imageUrl!,
                          borderRadius: 0,
                          fit: BoxFit.cover,
                        ))
                  : Center(
                      child: Icon(
                        Icons.medication_rounded,
                        size: 64,
                        color: L.sub.withValues(alpha: 0.4),
                      ),
                    ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 80,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0),
                      Colors.black.withValues(alpha: 0.35),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: AppSpacing.p16,
              bottom: AppSpacing.p16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.p12,
                  vertical: AppSpacing.p8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(AppRadius.max),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome_rounded, size: 14, color: L.text),
                    const SizedBox(width: 6),
                    Text(
                      category,
                      style: AppTypography.labelSmall.copyWith(
                        color: L.text,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BulletLines extends StatelessWidget {
  final List<String> lines;
  const _BulletLines({required this.lines});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    if (lines.isEmpty) return const SizedBox.shrink();
    if (lines.length == 1) {
      return Text(
        lines.first,
        style: AppTypography.bodyMedium.copyWith(color: L.sub, height: 1.5),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in lines)
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
                    decoration: const BoxDecoration(
                      color: AppColors.sageGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.p12),
                Expanded(
                  child: Text(
                    line.replaceFirst(RegExp(r'^[•\-]\s*'), ''),
                    style: AppTypography.bodyMedium
                        .copyWith(color: L.sub, height: 1.45),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _BodyImpactPremium extends StatelessWidget {
  final BodyImpactSummary impact;
  const _BodyImpactPremium({required this.impact});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return ScanSoftSection(
      title: 'How this supports you',
      subtitle: 'Body systems & timing',
      tint: AppColors.pastelMint,
      icon: Icons.monitor_heart_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            impact.mechanismOfAction,
            style: AppTypography.bodyMedium.copyWith(color: L.sub, height: 1.5),
          ),
          if (impact.onsetMinutes > 0 ||
              impact.peakHours > 0 ||
              impact.durationHours > 0) ...[
            const SizedBox(height: AppSpacing.p16),
            Wrap(
              spacing: AppSpacing.p8,
              runSpacing: AppSpacing.p8,
              children: [
                if (impact.onsetMinutes > 0)
                  _chip('Onset', '${impact.onsetMinutes} min'),
                if (impact.peakHours > 0) _chip('Peak', '${impact.peakHours}h'),
                if (impact.durationHours > 0)
                  _chip('Duration', '${impact.durationHours}h'),
              ],
            ),
          ],
          if (impact.bodySystems.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.p12),
            ScanBubbleRow(
              items: [
                for (var i = 0; i < impact.bodySystems.take(5).length; i++)
                  (
                    label: impact.bodySystems[i],
                    color: const [
                      AppColors.pastelSky,
                      AppColors.pastelMint,
                      AppColors.pastelSun,
                      AppColors.pastelMint,
                      AppColors.pastelPink,
                    ][i % 5],
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip(String label, String value) {
    return Builder(
      builder: (context) {
        final L = context.L;
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.p12,
            vertical: AppSpacing.p8,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(AppRadius.max),
          ),
          child: Text(
            '$label · $value',
            style: AppTypography.labelSmall.copyWith(
              color: L.text,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      },
    );
  }
}
