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
          textDirection: theme.textDirection,
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
      fontFamily: 'monospace',
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
  void handleTapDown(PointerDownEvent _) {/* Do nothing */}

  @override
  void handleTapUp(PointerUpEvent _) {/* Do nothing */}

  @override
  Size layout(double width) {
    if (width <= padding * 2) {
      // If the width is less than or equal to padding, return zero size.
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
    // If the width is less than required do not paint anything.
    if (size.width < _size.width) return;
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
