//ignore_for_file: unnecessary_import

import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../theme.dart';
import '../block_painter.dart';

/// A class for painting a spacer block in markdown.
class BlockPainter$Divider implements BlockPainter {
  /// Creates a thematic-break (horizontal rule) painter styled by [theme].
  BlockPainter$Divider({
    required this.theme,
  }) : _paint = Paint()
          ..color = theme.textStyle.color ?? const Color(0xFF000000)
          ..isAntiAlias = false
          ..strokeWidth = 1.0
          ..style = PaintingStyle.fill;

  final Paint _paint;

  /// The theme used to color and size the divider.
  final MarkdownThemeData theme;

  @override
  Size get size => _size;
  Size _size = Size.zero;

  @override
  void handleTapDown(PointerDownEvent _) {/* Do nothing */}

  @override
  void handleTapUp(PointerUpEvent _) {/* Do nothing */}

  @override
  Size layout(double width) {
    final height = theme.textStyle.fontSize ?? kDefaultFontSize;
    return _size = Size(0, height);
  }

  @override
  void paint(Canvas canvas, Size size, double offset) {
    // Draw a horizontal line across the width of the canvas.
    final center = offset + _size.height / 2;
    canvas.drawLine(
      Offset(0, center),
      Offset(size.width, center),
      _paint,
    );
  }

  @override
  void dispose() {
    // Noting to dispose
  }
}
