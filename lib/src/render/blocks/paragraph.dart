//ignore_for_file: unnecessary_import

import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../nodes.dart';
import '../../theme.dart';
import '../block_painter.dart';
import '../span_builder.dart';

/// A class for painting a paragraph block in markdown.
class BlockPainter$Paragraph
    with ParagraphGestureHandler, SelectableTextBlock
    implements BlockPainter {
  @override
  TextPainter get selectionPainter => painter;

  /// Creates a paragraph painter for [spans], styled by [theme].
  BlockPainter$Paragraph({
    required List<MD$Span> spans,
    required this.theme,
  })  : _selectionHighlightAboveCachedContent =
            markdownSpansPaintOpaqueBackground(spans),
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

  /// Last span hit by the tap down event.
  TextSpan? _lastSpan;

  @override
  void handleTapDown(PointerDownEvent event) {
    _lastSpan = null; // Reset the span on tap down.
    final span = hitTestInlineSpanWithPointerEvent(event, painter);
    if (span case TextSpan textSpan) _lastSpan = textSpan;
  }

  @override
  void handleTapUp(PointerUpEvent event) {
    if (_lastSpan == null) return; // No span was hit on tap down.
    final span = hitTestInlineSpanWithPointerEvent(event, painter);
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
    painter.layout(
      minWidth: 0,
      maxWidth: width,
    );
    return _size = painter.size;
  }

  @override
  void paint(Canvas canvas, Size size, double offset) {
    // If the width is less than required do not paint anything.
    if (size.width < _size.width) return;
    painter.paint(
      canvas,
      Offset(0, offset),
    );
  }

  @override
  void dispose() {
    painter.dispose();
  }
}
