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

/// A class for painting a quote block in markdown.
class BlockPainter$Quote
    with ParagraphGestureHandler, SelectableTextBlock
    implements BlockPainter {
  @override
  TextPainter get selectionPainter => painter;
  @override
  Offset get selectionOrigin => Offset(_dx, 0);

  /// Creates a quote painter for [spans] nested [indent] levels deep, styled
  /// by [theme].
  BlockPainter$Quote({
    required List<MD$Span> spans,
    required this.indent,
    required this.theme,
  })  : painter = TextPainter(
          text: paragraphFromMarkdownSpans(
            spans: spans,
            theme: theme,
            textStyle: theme.quoteStyle ?? theme.textStyle,
          ),
          textAlign: TextAlign.start,
          textDirection: theme.textDirection,
          textScaler: theme.textScaler,
        ),
        linePaint = Paint()
          ..color = theme.dividerColor ??
              const Color(0x7F7F7F7F) // Gray color for the line.
          ..isAntiAlias = false
          ..strokeWidth = 4.0
          ..style = PaintingStyle.fill;

  /// The theme used to style the quote.
  final MarkdownThemeData theme;

  /// The text painter that owns the quote's glyphs.
  final TextPainter painter;

  /// Nesting depth of the quote (0 for a top-level quote).
  final int indent;

  /// Horizontal space taken by each nesting level's accent bar.
  static const double lineIndent = 10.0;

  /// Paint used for the vertical accent bar(s) on the start side.
  final Paint linePaint;

  @override
  Size get size => _size;
  Size _size = Size.zero;

  /// Whether the last layout mirrored the block for right-to-left text.
  bool _rtl = false;

  /// The width passed to the last [layout].
  double _width = 0;

  /// Block-local x where the glyphs are painted.
  double _dx = 0;

  /// Last span hit by the tap down event.
  TextSpan? _lastSpan;

  @override
  void handleTapDown(PointerDownEvent event) {
    _lastSpan = null; // Reset the span on tap down.
    final span = hitTestInlineSpanWithPointerEvent(
      event,
      painter,
      origin: selectionOrigin,
    );
    if (span case TextSpan textSpan) _lastSpan = textSpan;
  }

  @override
  void handleTapUp(PointerUpEvent event) {
    if (_lastSpan == null) return; // No span was hit on tap down.
    final span = hitTestInlineSpanWithPointerEvent(
      event,
      painter,
      origin: selectionOrigin,
    );
    if (span != null && _lastSpan == span) {
      // If the span is the same as the one hit on tap down,
      // call the tap recognizer.
      if (span case TextSpan(recognizer: TapGestureRecognizer(:var onTap)))
        onTap?.call();
    }
    _lastSpan = null; // Clear the span after handling the tap.
  }

  @override
  Size layout(double width) {
    final textIndent = lineIndent + indent * lineIndent;
    // Adjust width for indentation.
    painter.layout(
      minWidth: 0,
      maxWidth: math.max(width - textIndent, 0),
    );
    _rtl = theme.textDirection == TextDirection.rtl && width.isFinite;
    _width = width;
    _dx = _rtl ? math.max(width - textIndent - painter.width, 0) : textIndent;
    return _size = Size(
      painter.size.width + textIndent,
      painter.size.height,
    );
  }

  @override
  void paint(Canvas canvas, Size size, double offset) {
    // If the width is less than required do not paint anything.
    if (size.width < _size.width) return;

    // --- Draw vertical lines --- //
    for (var i = 1; i <= indent; i++) {
      final x = _rtl ? _width - i * lineIndent : i * lineIndent;
      canvas.drawLine(
        Offset(x, offset),
        Offset(x, offset + _size.height),
        linePaint,
      );
    }

    painter.paint(
      canvas,
      Offset(_dx, offset),
    );
  }

  @override
  void dispose() {
    painter.dispose();
  }
}
