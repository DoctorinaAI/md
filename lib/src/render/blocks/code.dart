//ignore_for_file: unnecessary_import

import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../theme.dart';
import '../block_painter.dart';

/// A class for painting a code block in markdown.
class BlockPainter$Code with SelectableTextBlock implements BlockPainter {
  @override
  TextPainter get selectionPainter => painter;
  @override
  Offset get selectionOrigin => const Offset(padding, padding);

  /// Opaque fence chrome sits in the content [Picture]; highlight must paint
  /// above that picture or it disappears under the fill.
  @override
  bool get selectionHighlightAboveCachedContent => true;

  /// Creates a code-block painter for [text] in [language], styled by [theme].
  BlockPainter$Code({
    required String text,
    required String? language,
    required this.theme,
  })  : _background = theme.highlighter?.backgroundFor(language) ??
            theme.surfaceColor ??
            const Color.fromARGB(255, 235, 235, 235),
        painter = TextPainter(
          text: _buildSpan(text, language, theme),
          textAlign: TextAlign.start,
          // Code reads left-to-right even inside right-to-left documents.
          textDirection: TextDirection.ltr,
          textScaler: theme.textScaler,
        );

  /// Builds the code span: plain monospace text, or, when the theme carries a
  /// [MarkdownThemeData.highlighter], a tree of colored token spans whose
  /// concatenated text still equals [text] (so selection stays aligned).
  static TextSpan _buildSpan(
    String text,
    String? language,
    MarkdownThemeData theme,
  ) {
    final baseStyle = theme.textStyle.copyWith(
      fontFamily: theme.monospaceFontFamily,
      fontFamilyFallback: theme.monospaceFallbackChain,
      fontSize: theme.textStyle.fontSize ?? kDefaultFontSize,
    );
    final highlighter = theme.highlighter;
    if (highlighter == null) return TextSpan(text: text, style: baseStyle);
    final effectiveBase = highlighter.baseStyleFor(language, baseStyle);
    return TextSpan(
      style: effectiveBase,
      children: highlighter.highlight(text, language, effectiveBase),
    );
  }

  /// Padding around the code text, inside its rounded background.
  static const double padding = 8.0;

  /// The theme used to style the code block.
  final MarkdownThemeData theme;

  /// Background color of the code block surface.
  final Color _background;

  /// The text painter that owns the code's glyphs.
  final TextPainter painter;

  @override
  Size get size => _size;
  Size _size = Size.zero;

  @override
  List<Rect> boxesForRange(int start, int end) =>
      _size.isEmpty ? const <Rect>[] : super.boxesForRange(start, end);

  @override
  bool hitsRenderedTextAt(Offset local) =>
      !_size.isEmpty && super.hitsRenderedTextAt(local);

  @override
  bool isLinkAtLocal(Offset local) =>
      !_size.isEmpty && super.isLinkAtLocal(local);

  @override
  Rect caretRectFor(int offset, TextAffinity affinity) =>
      _size.isEmpty ? Rect.zero : super.caretRectFor(offset, affinity);

  @override
  void handleTapDown(PointerDownEvent _) {/* Do nothing */}

  @override
  void handleTapUp(PointerUpEvent _) {/* Do nothing */}

  @override
  Size layout(double width) {
    if (width <= padding * 2) {
      // Too narrow for the padding: the block takes no space and paints
      // nothing. The painter is still laid out (unconstrained, so a long fence
      // does not wrap per glyph) so caret / position queries stay valid, but
      // the selection overrides below keep it inert.
      painter.layout();
      _size = Size.zero;
      return _size;
    }
    painter.layout(
      minWidth: 0,
      maxWidth: width - padding * 2,
    );
    return _size = Size(
      painter.size.width + padding * 2, // Add padding to the width.
      painter.size.height + padding * 2, // Add padding to the height.
    );
  }

  @override
  void paint(Canvas canvas, Size size, double offset) {
    // If the width is less than required do not paint anything. An empty size
    // means [layout] was too narrow for the padding and skipped laying out
    // the text, which must then not be painted either.
    if (_size.isEmpty || size.width < _size.width) return;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, offset, size.width, _size.height),
        const Radius.circular(padding),
      ),
      Paint()
        ..color = _background
        ..isAntiAlias = false
        ..style = PaintingStyle.fill,
    );
    painter.paint(
      canvas,
      Offset(padding, offset + padding),
    );
  }

  @override
  void dispose() {
    painter.dispose();
  }
}
