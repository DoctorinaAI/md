//ignore_for_file: unnecessary_import

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../nodes.dart';
import '../../theme.dart';
import '../block_painter.dart';
import '../span_builder.dart';

/// A class for painting a GitHub-style alert (admonition) block in markdown.
class BlockPainter$Alert
    with ParagraphGestureHandler, SelectableTextBlock
    implements BlockPainter {
  @override
  TextPainter get selectionPainter => bodyPainter;
  @override
  Offset get selectionOrigin => _bodyOrigin;

  /// Creates an alert painter of kind [alert] with body [spans], styled by
  /// [theme].
  BlockPainter$Alert({
    required this.alert,
    required List<MD$Span> spans,
    required this.theme,
  })  : _accent = theme.alertColorFor(alert),
        titlePainter = TextPainter(
          text: TextSpan(
            text: alert.title,
            style: theme.textStyle.copyWith(
              color: theme.alertColorFor(alert),
              fontWeight: FontWeight.bold,
            ),
          ),
          textAlign: TextAlign.start,
          textDirection: theme.textDirection,
          textScaler: theme.textScaler,
        ),
        bodyPainter = TextPainter(
          text: paragraphFromMarkdownSpans(spans: spans, theme: theme),
          textAlign: TextAlign.start,
          textDirection: theme.textDirection,
          textScaler: theme.textScaler,
        );

  /// The kind of the alert being painted.
  final MD$AlertType alert;

  /// The theme used to style the alert.
  final MarkdownThemeData theme;

  final Color _accent;

  /// Painter for the alert title (e.g. "Note").
  final TextPainter titlePainter;

  /// Painter for the alert body content.
  final TextPainter bodyPainter;

  /// Padding around the alert's content, inside its rounded background.
  static const double padding = 10.0;

  /// Width of the accent bar on the left edge.
  static const double barWidth = 4.0;

  /// Gap between the accent bar and the content.
  static const double gap = 10.0;

  /// Vertical gap between the title and the body.
  static const double titleGap = 4.0;

  /// Left offset where the title/body content begins.
  double get _contentLeft => padding + barWidth + gap;

  @override
  Size get size => _size;
  Size _size = Size.zero;

  /// Whether the body has any content to paint.
  bool _hasBody = false;

  /// Last span hit by the tap down event.
  TextSpan? _lastSpan;

  Offset get _bodyOrigin =>
      Offset(_contentLeft, padding + titlePainter.height + titleGap);

  TextSpan? _spanForPosition(Offset localPosition) {
    if (!_hasBody) return null;
    final local = localPosition - _bodyOrigin;
    if (local.dx < 0 ||
        local.dy < 0 ||
        local.dx > bodyPainter.width ||
        local.dy > bodyPainter.height) return null;
    final position = bodyPainter.getPositionForOffset(local);
    final span = bodyPainter.text?.getSpanForPosition(position);
    return span is TextSpan ? span : null;
  }

  @override
  void handleTapDown(PointerDownEvent event) {
    _lastSpan = _spanForPosition(event.localPosition);
  }

  @override
  void handleTapUp(PointerUpEvent event) {
    if (_lastSpan == null) return;
    final span = _spanForPosition(event.localPosition);
    if (span != null && _lastSpan == span) {
      if (span case TextSpan(recognizer: TapGestureRecognizer(:var onTap)))
        onTap?.call();
    }
    _lastSpan = null;
  }

  @override
  Size layout(double width) {
    final available = math.max(0.0, width - _contentLeft - padding);
    titlePainter.layout(minWidth: 0, maxWidth: available);
    bodyPainter.layout(minWidth: 0, maxWidth: available);
    _hasBody = bodyPainter.text?.toPlainText().isNotEmpty ?? false;

    final contentWidth = math.max(
      titlePainter.width,
      _hasBody ? bodyPainter.width : 0.0,
    );
    final contentHeight =
        titlePainter.height + (_hasBody ? titleGap + bodyPainter.height : 0.0);
    return _size = Size(
      _contentLeft + contentWidth + padding,
      contentHeight + padding * 2,
    );
  }

  @override
  void paint(Canvas canvas, Size size, double offset) {
    if (size.width < _size.width) return;

    final rect = Rect.fromLTWH(0, offset, size.width, _size.height);
    // Tinted background.
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(6.0)),
      Paint()
        ..color = _accent.withValues(alpha: 0.10)
        ..style = PaintingStyle.fill,
    );
    // Accent bar on the left.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, offset, barWidth, _size.height),
        const Radius.circular(barWidth / 2),
      ),
      Paint()
        ..color = _accent
        ..style = PaintingStyle.fill,
    );

    titlePainter.paint(canvas, Offset(_contentLeft, offset + padding));
    if (_hasBody) {
      bodyPainter.paint(canvas, _bodyOrigin + Offset(0, offset));
    }
  }

  @override
  void dispose() {
    titlePainter.dispose();
    bodyPainter.dispose();
  }
}
