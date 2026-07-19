import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../theme/med_ai_ui.dart';
import '../../../widgets/common/animated_pressable.dart';

/// Shared premium scan-result chrome — reference wellness aesthetic:
/// soft pastels, large radius cards, bold type, airy whitespace.
abstract final class ScanResultChrome {
  // Reference wellness cards sit at ~22-28px; map to shared AppRadius tokens
  // so the scan surface tracks the design system (xl=28 cards, l=24 tiles).
  static const double cardRadius = AppRadius.xl; // 28
  static const double tileRadius = AppRadius.l; // 24
  static const EdgeInsets pagePad =
      EdgeInsets.symmetric(horizontal: AppSpacing.gutter);

  static BoxDecoration pastelCard(Color tint, {Color? border}) => BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(cardRadius),
        border: border != null
            ? Border.all(color: border.withValues(alpha: 0.16))
            : null,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A2621).withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      );

  static BoxDecoration whiteCard(AppThemeColors L) => BoxDecoration(
        color: L.card,
        borderRadius: BorderRadius.circular(cardRadius),
        border: Border.all(color: L.border.withValues(alpha: 0.35), width: 0.7),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A2621).withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      );
}

/// Large confidence / safety score — reference “89% progress” treatment.
class ScanConfidenceHero extends StatelessWidget {
  final int percent;
  final String caption;
  final Color accent;
  final String? title;

  const ScanConfidenceHero({
    super.key,
    required this.percent,
    required this.caption,
    required this.accent,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final pct = percent.clamp(0, 100);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.p20),
      decoration: ScanResultChrome.pastelCard(AppColors.pastelMint),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (title ?? 'AI MATCH').toUpperCase(),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.accentDeep,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.p8),
                Text(
                  '$pct%',
                  style: AppTypography.displayMedium.copyWith(
                    color: L.text,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.5,
                    height: 1,
                  ),
                ),
                const SizedBox(height: AppSpacing.p8),
                Text(
                  caption,
                  style: AppTypography.bodySmall.copyWith(
                    color: L.sub,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.p12),
          SizedBox(
            width: 88,
            height: 88,
            child: CustomPaint(
              painter: _DotGridPainter(
                fraction: pct / 100,
                active: accent,
                idle: accent.withValues(alpha: 0.18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  final double fraction;
  final Color active;
  final Color idle;

  _DotGridPainter({
    required this.fraction,
    required this.active,
    required this.idle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const cols = 6;
    const rows = 6;
    final total = cols * rows;
    final lit = (total * fraction.clamp(0.0, 1.0)).round();
    final gapX = size.width / (cols + 1);
    final gapY = size.height / (rows + 1);
    final r = math.min(gapX, gapY) * 0.28;

    var i = 0;
    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < cols; x++) {
        final paint = Paint()..color = i < lit ? active : idle;
        canvas.drawCircle(
          Offset(gapX * (x + 1), gapY * (y + 1)),
          r,
          paint,
        );
        i++;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotGridPainter old) =>
      old.fraction != fraction || old.active != active || old.idle != idle;
}

/// Reference 2×2 insight tile with outward arrow.
class ScanInsightTile extends StatelessWidget {
  final String label;
  final String value;
  final Color tint;
  final IconData icon;
  final VoidCallback? onTap;

  const ScanInsightTile({
    super.key,
    required this.label,
    required this.value,
    required this.tint,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final child = Container(
      padding: const EdgeInsets.all(AppSpacing.p16),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(ScanResultChrome.tileRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(AppRadius.s),
                ),
                child: Icon(icon, size: 18, color: L.text),
              ),
              const Spacer(),
              Icon(
                Icons.arrow_outward_rounded,
                size: 16,
                color: L.sub.withValues(alpha: 0.45),
              ),
            ],
          ),
          const Spacer(),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.labelSmall.copyWith(
              color: L.sub,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.titleMedium.copyWith(
              color: L.text,
              fontWeight: FontWeight.w800,
              height: 1.15,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) {
      return SizedBox(height: 132, child: child);
    }
    return SizedBox(
      height: 132,
      child: AnimatedPressable(onTap: onTap, child: child),
    );
  }
}

class ScanInsightGrid extends StatelessWidget {
  final List<ScanInsightTile> tiles;

  const ScanInsightGrid({super.key, required this.tiles});

  @override
  Widget build(BuildContext context) {
    if (tiles.isEmpty) return const SizedBox.shrink();
    final rows = <Widget>[];
    for (var i = 0; i < tiles.length; i += 2) {
      final left = tiles[i];
      final right = i + 1 < tiles.length ? tiles[i + 1] : null;
      rows.add(
        Row(
          children: [
            Expanded(child: left),
            const SizedBox(width: AppSpacing.p12),
            Expanded(child: right ?? const SizedBox.shrink()),
          ],
        ),
      );
      if (i + 2 < tiles.length) {
        rows.add(const SizedBox(height: AppSpacing.p12));
      }
    }
    return Column(children: rows);
  }
}

/// Soft bubble chips — reference mood/stat bubbles.
class ScanBubbleRow extends StatelessWidget {
  final List<({String label, Color color})> items;

  const ScanBubbleRow({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final L = context.L;
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.p8),
        itemBuilder: (context, i) {
          final item = items[i];
          final size = 52.0 + (i % 3) * 6.0;
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: size,
                height: size,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: item.color,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  item.label.length > 8
                      ? '${item.label.substring(0, 7)}…'
                      : item.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: AppTypography.caption.copyWith(
                    color: L.text,
                    fontWeight: FontWeight.w700,
                    fontSize: 9,
                    height: 1.1,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Soft section card with pastel accent dot.
class ScanSoftSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Color tint;
  final Widget child;
  final IconData? icon;

  const ScanSoftSection({
    super.key,
    required this.title,
    required this.tint,
    required this.child,
    this.subtitle,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.p20),
      decoration: ScanResultChrome.pastelCard(tint),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(AppRadius.s),
                  ),
                  child: Icon(icon, size: 18, color: L.text),
                ),
                const SizedBox(width: AppSpacing.p12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.titleMedium.copyWith(
                        color: L.text,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
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
          ),
          const SizedBox(height: AppSpacing.p16),
          child,
        ],
      ),
    );
  }
}

/// Floating premium action bar — reference soft pill dock.
class ScanFloatingBar extends StatelessWidget {
  final Widget child;
  final double bottomPad;

  const ScanFloatingBar({
    super.key,
    required this.child,
    required this.bottomPad,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.p12,
        AppSpacing.gutter,
        bottomPad + AppSpacing.p12,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0),
            Colors.white.withValues(alpha: 0.92),
            Colors.white,
          ],
          stops: const [0, 0.35, 1],
        ),
      ),
      child: child,
    );
  }
}
