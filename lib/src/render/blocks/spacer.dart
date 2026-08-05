//ignore_for_file: unnecessary_import

import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../theme.dart';
import '../block_painter.dart';

/// A class for painting a spacer block in markdown.
class BlockPainter$Spacer implements BlockPainter {
  /// Creates a spacer painter [count] blank lines tall, sized by [theme].
  BlockPainter$Spacer({
    required this.count,
    required this.theme,
  });

  /// Number of blank lines this spacer occupies.
  final int count;

  /// The theme whose text size determines the spacer's height.
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
    return _size = Size(0, height * count);
  }

  @override
  void paint(Canvas canvas, Size size, double offset) {
    // Do not paint anything
    /* canvas.drawRect(
      Rect.fromLTWH(0, offset, size.width, _size.height),
      Paint()..color = theme.textStyle.color ?? const Color(0x00000000),
    ); */
  }

  @override
  void dispose() {
    // Noting to dispose
  }
}
