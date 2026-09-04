import 'dart:io';

import 'package:flutter/material.dart';

import '../../../theme/med_ai_ui.dart';

/// Identity block at the top of a scan result.
///
/// A scan from voice or name search has no photo, and the previous block still
/// reserved a 16:11 slot for one — roughly 370px of empty gradient behind a
/// faded pill glyph, occupying the most valuable space on the screen to say
/// nothing. Real photos are still shown large; when there is no photo the
/// header collapses to a compact band carrying the category instead.
class ScanIdentityHeader extends StatelessWidget {
  final File? imageFile;
  final String category;
  final String name;

  const ScanIdentityHeader({
    super.key,
    required this.imageFile,
    required this.category,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    if (imageFile != null) return _PhotoHeader(imageFile: imageFile!, category: category);
    return _CompactHeader(category: category, name: name);
  }
}

/// Full-bleed photo — kept for camera and gallery scans, where the image is
/// genuine evidence of what was scanned.
class _PhotoHeader extends StatelessWidget {
  final File imageFile;
  final String category;

  const _PhotoHeader({required this.imageFile, required this.category});

  @override
  Widget build(BuildContext context) {
    final L = context.L;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.squircle),
      child: AspectRatio(
        aspectRatio: 16 / 11,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(imageFile, fit: BoxFit.cover),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 96,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0),
                      Colors.black.withValues(alpha: 0.42),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: AppSpacing.p16,
              bottom: AppSpacing.p16,
              child: _CategoryPill(category: category, onDark: true, L: L),
            ),
          ],
        ),
      ),
    );
  }
}

/// No-photo variant: a short band, not a placeholder for a missing image.
class _CompactHeader extends StatelessWidget {
  final String category;
  final String name;

  const _CompactHeader({required this.category, required this.name});

  @override
  Widget build(BuildContext context) {
    final L = context.L;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.p16),
      decoration: BoxDecoration(
        color: AppColors.pastelSky,
        borderRadius: BorderRadius.circular(AppRadius.l),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: L.card,
              borderRadius: BorderRadius.circular(AppRadius.m),
            ),
            child: Icon(
              Icons.medication_liquid_rounded,
              size: 26,
              color: AppColors.accentDeep,
            ),
          ),
          const SizedBox(width: AppSpacing.p12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'IDENTIFIED',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.accentDeep,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleMedium.copyWith(
                    color: L.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.p8),
          _CategoryPill(category: category, onDark: false, L: L),
        ],
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  final String category;
  final bool onDark;
  final AppThemeColors L;

  const _CategoryPill({
    required this.category,
    required this.onDark,
    required this.L,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        // On a photo this sits over an unpredictable image, so it needs a near
        // opaque ground; on the pastel band a soft card surface is enough.
        color: onDark
            ? Colors.white.withValues(alpha: 0.94)
            : L.card.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppRadius.max),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome_rounded, size: 13, color: L.text),
          const SizedBox(width: 5),
          Text(
            category,
            style: AppTypography.labelSmall.copyWith(
              color: L.text,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Section heading with a tinted icon tile.
///
/// The screen previously introduced each block with a bare bold string, so
/// "Safety first", "Quick insights", "Side-effect map" and "Expert
/// perspectives" all carried identical weight and the eye had no landmarks
/// while scrolling a long result.
class ScanSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color tint;

  const ScanSectionHeader({
    super.key,
    required this.title,
    required this.icon,
    this.subtitle,
    this.tint = AppColors.pastelMint,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: tint,
            borderRadius: BorderRadius.circular(AppRadius.s),
          ),
          child: Icon(icon, size: 19, color: AppColors.accentDeep),
        ),
        const SizedBox(width: AppSpacing.p12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: AppTypography.titleMedium.copyWith(
                  color: L.text,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: AppTypography.bodySmall.copyWith(color: L.sub),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
