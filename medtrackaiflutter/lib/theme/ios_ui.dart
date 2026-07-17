import 'package:flutter/material.dart';

import 'med_ai_ui.dart';

/// iOS Human-Interface-Guidelines idiom kit, tuned to the app's dark
/// "premium" palette. These primitives give the AI chat and scan-result
/// surfaces a native-iOS *layout language* — iMessage bubbles, inset-grouped
/// tables, hairline separators, uppercase footnote headers — without throwing
/// away the existing theme colors.
class IOSMetrics {
  /// Apple's canonical 0.5pt separator. Rendered as a physical hairline.
  static const double hairline = 0.5;

  /// Inset-grouped table side margin (iOS uses ~16–20pt).
  static const double groupInset = 16;

  /// Continuous-corner radius for grouped cards.
  static const double groupRadius = 12;

  /// iMessage bubble corner radius.
  static const double bubbleRadius = 20;
}

/// A single hairline divider matching iOS table separators.
class IOSHairline extends StatelessWidget {
  final double indent;
  final double endIndent;

  const IOSHairline({super.key, this.indent = 0, this.endIndent = 0});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Padding(
      padding: EdgeInsetsDirectional.only(start: indent, end: endIndent),
      child: SizedBox(
        height: IOSMetrics.hairline,
        child: ColoredBox(color: L.border.withValues(alpha: 0.16)),
      ),
    );
  }
}

/// Inset-grouped container. Children are stacked and automatically separated by
/// hairlines (indented to align under leading content), like a grouped
/// `UITableView`.
class IOSInsetGroup extends StatelessWidget {
  final List<Widget> children;

  /// Left indent for the hairline separators (aligns under row text).
  final double separatorIndent;

  const IOSInsetGroup({
    super.key,
    required this.children,
    this.separatorIndent = 58,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      rows.add(children[i]);
      if (i != children.length - 1) {
        rows.add(IOSHairline(indent: separatorIndent));
      }
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: L.card,
        borderRadius: BorderRadius.circular(IOSMetrics.groupRadius),
        border: Border.all(color: L.border.withValues(alpha: 0.14), width: 0.7),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(IOSMetrics.groupRadius),
        child: Column(mainAxisSize: MainAxisSize.min, children: rows),
      ),
    );
  }
}

/// A single row in an [IOSInsetGroup] — leading icon tile, title + optional
/// subtitle, optional trailing chevron.
class IOSGroupedRow extends StatelessWidget {
  final IconData? icon;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool showChevron;
  final VoidCallback? onTap;

  const IOSGroupedRow({
    super.key,
    this.icon,
    this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.showChevron = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final tint = iconColor ?? L.accent;

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: subtitle != null
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: tint),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    color: L.text,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    style: AppTypography.bodySmall.copyWith(
                      color: L.sub,
                      height: 1.4,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          if (showChevron) ...[
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded,
                size: 20, color: L.sub.withValues(alpha: 0.5)),
          ],
        ],
      ),
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: L.accent.withValues(alpha: 0.08),
        highlightColor: L.text.withValues(alpha: 0.04),
        child: content,
      ),
    );
  }
}


/// iMessage-style chat bubble with a directional tail. [isUser] bubbles use the
/// accent fill (like the blue sender bubble); AI bubbles use a grouped-gray
/// fill (like the received bubble).
class IOSChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final double maxWidthFraction;

  const IOSChatBubble({
    super.key,
    required this.text,
    required this.isUser,
    this.maxWidthFraction = 0.76,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final maxW = MediaQuery.of(context).size.width * maxWidthFraction;
    final bg = isUser ? L.accent : L.card;
    final fg = isUser ? Colors.white : L.text;

    return Align(
      alignment: isUser
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxW),
        child: CustomPaint(
          painter: _BubbleTailPainter(
            color: bg,
            isUser: isUser,
            borderColor: isUser ? null : L.border.withValues(alpha: 0.18),
          ),
          child: Padding(
            padding: EdgeInsetsDirectional.only(
              start: isUser ? 16 : 18,
              end: isUser ? 18 : 16,
              top: 10,
              bottom: 10,
            ),
            child: Text(
              text,
              style: AppTypography.bodyMedium.copyWith(
                color: fg,
                height: 1.35,
                fontSize: 15.5,
                fontWeight: isUser ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  final Color color;
  final bool isUser;
  final Color? borderColor;

  _BubbleTailPainter({
    required this.color,
    required this.isUser,
    this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const r = IOSMetrics.bubbleRadius;
    const tail = 7.0;
    final body = RRect.fromRectAndCorners(
      Rect.fromLTWH(
          isUser ? 0 : tail, 0, size.width - tail, size.height),
      topLeft: const Radius.circular(r),
      topRight: const Radius.circular(r),
      bottomLeft: Radius.circular(isUser ? r : 4),
      bottomRight: Radius.circular(isUser ? 4 : r),
    );

    final path = Path()..addRRect(body);
    // Tail near the bottom corner on the sender's side.
    if (isUser) {
      final x = size.width;
      final y = size.height;
      path.moveTo(x - tail - 2, y - 14);
      path.quadraticBezierTo(x, y - 6, x, y);
      path.quadraticBezierTo(x - 3, y, x - tail - 6, y - 4);
      path.close();
    } else {
      final y = size.height;
      path.moveTo(tail + 2, y - 14);
      path.quadraticBezierTo(0, y - 6, 0, y);
      path.quadraticBezierTo(3, y, tail + 6, y - 4);
      path.close();
    }

    canvas.drawPath(path, Paint()..color = color);
    if (borderColor != null) {
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.7
          ..color = borderColor!,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BubbleTailPainter old) =>
      old.color != color || old.isUser != isUser || old.borderColor != borderColor;
}

/// iOS message composer: rounded capsule field with an inline circular send
/// button, sitting on a hairline-topped bar.
class IOSComposer extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onSubmit;
  final bool autofocus;
  final bool enabled;

  const IOSComposer({
    super.key,
    required this.controller,
    required this.onSubmit,
    this.hintText = 'Message',
    this.autofocus = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Container(
      decoration: BoxDecoration(
        color: L.bg.withValues(alpha: 0.92),
        border: Border(
          top: BorderSide(
              color: L.border.withValues(alpha: 0.16),
              width: IOSMetrics.hairline),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(minHeight: 38),
                  decoration: BoxDecoration(
                    color: L.fill.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: L.border.withValues(alpha: 0.2), width: 0.7),
                  ),
                  child: TextField(
                    controller: controller,
                    autofocus: autofocus,
                    enabled: enabled,
                    minLines: 1,
                    maxLines: 5,
                    textCapitalization: TextCapitalization.sentences,
                    style: AppTypography.bodyMedium
                        .copyWith(color: L.text, fontSize: 16),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: hintText,
                      hintStyle: AppTypography.bodyMedium.copyWith(
                          color: L.sub.withValues(alpha: 0.7), fontSize: 16),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 9),
                    ),
                    onSubmitted: enabled ? onSubmit : null,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Semantics(
                button: true,
                label: 'Send message',
                child: GestureDetector(
                  onTap: enabled ? () => onSubmit(controller.text) : null,
                  child: Container(
                    width: 34,
                    height: 34,
                    margin: const EdgeInsets.only(bottom: 2),
                    decoration: BoxDecoration(
                      color: L.accent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_upward_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The iOS bottom-sheet grabber handle.
class IOSGrabber extends StatelessWidget {
  const IOSGrabber({super.key});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Container(
      width: 36,
      height: 5,
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      decoration: BoxDecoration(
        color: L.sub.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
