//ignore_for_file: unnecessary_import

import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../nodes.dart';
import '../../theme.dart';
import '../block_painter.dart';
import '../inline_image.dart';
import '../span_builder.dart';

/// A class for painting a paragraph block in markdown.
class BlockPainter$Paragraph
    with ParagraphGestureHandler, SelectableTextBlock
    implements BlockPainter {
  @override
  TextPainter get selectionPainter => painter;
  @override
  Offset get selectionOrigin => Offset(_dx, 0);

  /// Creates a paragraph painter for [spans], styled by [theme].
  BlockPainter$Paragraph({
    required List<MD$Span> spans,
    required this.theme,
  })  : _selectionHighlightAboveCachedContent =
            markdownSpansPaintOpaqueBackground(
          spans,
          images: theme.imageResolver != null,
        ),
        painter = TextPainter(
          text: paragraphFromMarkdownSpans(
            spans: spans,
            theme: theme,
          ),
          textAlign: TextAlign.start,
          textDirection: theme.textDirection,
          textScaler: theme.textScaler,
        );

  /// Inline monospace/highlight fills live in the content [Picture]; paint the
  /// selection tint above that picture when present.
  @override
  bool get selectionHighlightAboveCachedContent =>
      _selectionHighlightAboveCachedContent;
  final bool _selectionHighlightAboveCachedContent;

  /// The theme used to style the paragraph.
  final MarkdownThemeData theme;

  /// The text painter that owns the paragraph's glyphs.
  final TextPainter painter;

  @override
  Size get size => _size;
  Size _size = Size.zero;

  /// Block-local x where the glyphs are painted: `0` for left-to-right text,
  /// or the offset that puts right-to-left text against the right edge.
  double _dx = 0;

  /// Last span hit by the tap down event.
  InlineSpan? _lastSpan;

  @override
  void handleTapDown(PointerDownEvent event) {
    _lastSpan = null; // Reset the span on tap down.
    final span = hitTestInlineSpanWithPointerEvent(
      event,
      painter,
      origin: selectionOrigin,
    );
    _lastSpan = span;
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
      if (markdownSpanRecognizer(span) case TapGestureRecognizer(:final onTap))
        onTap?.call();
    }
    _lastSpan = null; // Clear the span after handling the tap.
  }

  @override
  Size layout(double width) {
    layoutMarkdownText(painter, maxWidth: width);
    _dx = theme.textDirection == TextDirection.rtl && width.isFinite
        ? (width - painter.width).clamp(0.0, width)
        : 0.0;
    return _size = painter.size;
  }

  @override
  void paint(Canvas canvas, Size size, double offset) {
    // If the width is less than required do not paint anything.
    if (size.width < _size.width) return;
    paintMarkdownText(painter, canvas, Offset(_dx, offset));
  }

  @override
  void dispose() {
    painter.dispose();
  }
}
