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
  }) : painter = TextPainter(
          text: TextSpan(
            text: text,
            style: theme.textStyle.copyWith(
              fontFamily: 'monospace',
              fontSize: theme.textStyle.fontSize ?? kDefaultFontSize,
            ),
          ),
          textAlign: TextAlign.start,
          textDirection: theme.textDirection,
          textScaler: theme.textScaler,
        );

  /// Padding around the code text, inside its rounded background.
  static const double padding = 8.0;

  /// The theme used to style the code block.
  final MarkdownThemeData theme;

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
        ..color = theme.surfaceColor ?? const Color.fromARGB(255, 235, 235, 235)
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
