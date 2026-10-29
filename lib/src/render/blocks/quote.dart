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
///
/// Leaf quotes (inline [spans] only) paint a single [TextPainter]. Quotes with
/// nested [children] (e.g. fenced code inside `>`) stack those painters under
/// the accent bar and expose them as [MultiPainterSelectable] fragments.
class BlockPainter$Quote
    with ParagraphGestureHandler, MultiPainterSelectable
    implements BlockPainter {
  /// Creates a quote painter for [spans] nested [indent] levels deep, styled
  /// by [theme]. When [children] is non-empty, those painters are stacked
  /// instead of [spans].
  BlockPainter$Quote({
    required List<MD$Span> spans,
    required this.indent,
    required this.theme,
    List<BlockPainter> children = const <BlockPainter>[],
  })  : _children = children,
        _selectionHighlightAboveCachedContent = children.isNotEmpty
            ? children.any(
                (c) =>
                    c is SelectableBlockPainter &&
                    c.selectionHighlightAboveCachedContent,
              )
            : markdownSpansPaintOpaqueBackground(spans),
        _leafPainter = children.isEmpty
            ? TextPainter(
                text: paragraphFromMarkdownSpans(
                  spans: spans,
                  theme: theme,
                  textStyle: theme.quoteStyle ?? theme.textStyle,
                ),
                textAlign: TextAlign.start,
                textDirection: theme.textDirection,
                textScaler: theme.textScaler,
              )
            : null,
        linePaint = Paint()
          ..color = theme.dividerColor ??
              const Color(0x7F7F7F7F) // Gray color for the line.
          ..isAntiAlias = false
          ..strokeWidth = 4.0
          ..style = PaintingStyle.fill;

  /// Nested block painters when the quote model carries [MD$Quote.blocks].
  final List<BlockPainter> _children;

  /// Leaf glyph painter when there are no nested children.
  final TextPainter? _leafPainter;

  /// Inline monospace/highlight fills (or nested code chrome) live in the
  /// content [Picture].
  @override
  bool get selectionHighlightAboveCachedContent =>
      _selectionHighlightAboveCachedContent;
  final bool _selectionHighlightAboveCachedContent;

  /// The theme used to style the quote.
  final MarkdownThemeData theme;

  /// Nesting depth of the quote (0 for a top-level quote).
  final int indent;

  /// Horizontal space taken by each nesting level's accent bar.
  static const double lineIndent = 10.0;

  /// Theme for a nested [child] under a quote: prose blocks inherit
  /// [MarkdownThemeData.quoteStyle] as their base [MarkdownThemeData.textStyle]
  /// (matching leaf quotes). Code/tables/spacers/nested quotes keep [theme] so
  /// chrome and recursive quote handling stay correct.
  static MarkdownThemeData inheritFrom(
    MarkdownThemeData theme,
    MD$Block child,
  ) =>
      switch (child) {
        MD$Code() ||
        MD$Table() ||
        MD$Divider() ||
        MD$Spacer() ||
        MD$Quote() ||
        MD$Alert() =>
          theme,
        MD$Paragraph() ||
        MD$Heading() ||
        MD$List() =>
          theme.copyWith(textStyle: theme.quoteStyle ?? theme.textStyle),
      };

  /// Paint used for the vertical accent bar(s) on the left.
  final Paint linePaint;

  @override
  Size get size => _size;
  Size _size = Size.zero;

  @override
  List<SelectableFragment> get fragments => _fragments;
  List<SelectableFragment> _fragments = const <SelectableFragment>[];

  @override
  String get renderedText => _renderedText;
  String _renderedText = '';

  /// Vertical offsets of each nested child within the quote content column.
  List<double> _childOffsets = const <double>[];

  /// Last span hit by the tap down event.
  TextSpan? _lastSpan;

  double get _contentLeft => lineIndent + indent * lineIndent;

  InlineSpan? _spanForPosition(Offset localPosition) {
    if (_leafPainter != null) {
      final local = localPosition - Offset(_contentLeft, 0);
      if (local.dx < 0 ||
          local.dy < 0 ||
          local.dx > _leafPainter.width ||
          local.dy > _leafPainter.height) {
        return null;
      }
      final position = _leafPainter.getPositionForOffset(local);
      return _leafPainter.text?.getSpanForPosition(position);
    }
    for (var i = 0; i < _children.length; i++) {
      final child = _children[i];
      final origin = Offset(_contentLeft, _childOffsets[i]);
      final rect = origin & child.size;
      if (!rect.contains(localPosition)) continue;
      final inner = localPosition - origin;
      if (child is BlockPainter$Quote) {
        return child._spanForPosition(inner);
      }
      if (child case final SelectableTextBlock textBlock) {
        final painter = textBlock.selectionPainter;
        final local = inner - textBlock.selectionOrigin;
        if (local.dx < 0 ||
            local.dy < 0 ||
            local.dx > painter.width ||
            local.dy > painter.height) {
          continue;
        }
        final position = painter.getPositionForOffset(local);
        return painter.text?.getSpanForPosition(position);
      }
    }
    return null;
  }

  @override
  void handleTapDown(PointerDownEvent event) {
    _lastSpan = null;
    final span = _spanForPosition(event.localPosition);
    if (span case TextSpan textSpan) _lastSpan = textSpan;
  }

  @override
  void handleTapUp(PointerUpEvent event) {
    if (_lastSpan == null) return;
    final span = _spanForPosition(event.localPosition);
    if (span != null && _lastSpan == span) {
      if (span case TextSpan(recognizer: TapGestureRecognizer(:var onTap))) {
        onTap?.call();
      }
    }
    _lastSpan = null;
  }

  @override
  Size layout(double width) {
    final contentWidth = math.max(width - _contentLeft, 0.0);
    if (_leafPainter != null) {
      _leafPainter.layout(minWidth: 0, maxWidth: contentWidth);
      _size = Size(
        _leafPainter.size.width + _contentLeft,
        _leafPainter.size.height,
      );
      _fragments = <SelectableFragment>[
        SelectableFragment(_leafPainter, Offset(_contentLeft, 0), 0),
      ];
      _renderedText = _leafPainter.plainText;
      _childOffsets = const <double>[];
      return _size;
    }

    final offsets = List<double>.filled(_children.length, 0.0);
    var y = 0.0;
    var maxChildWidth = 0.0;
    for (var i = 0; i < _children.length; i++) {
      offsets[i] = y;
      final childSize = _children[i].layout(contentWidth);
      maxChildWidth = math.max(maxChildWidth, childSize.width);
      y += childSize.height;
    }
    _childOffsets = offsets;
    _size = Size(maxChildWidth + _contentLeft, y);
    _rebuildFragments();
    return _size;
  }

  void _rebuildFragments() {
    final frags = <SelectableFragment>[];
    final parts = <String>[];
    var textStart = 0;
    for (var i = 0; i < _children.length; i++) {
      final child = _children[i];
      final origin = Offset(_contentLeft, _childOffsets[i]);
      if (child is MultiPainterSelectable) {
        final text = child.renderedText;
        if (text.isNotEmpty) {
          for (final f in child.fragments) {
            frags.add(SelectableFragment(
              f.painter,
              origin + f.origin,
              textStart + f.textStart,
            ));
          }
          parts.add(text);
          textStart += text.length + 1;
        }
      } else if (child case final SelectableTextBlock textBlock) {
        final text = textBlock.renderedText;
        if (text.isNotEmpty) {
          frags.add(SelectableFragment(
            textBlock.selectionPainter,
            origin + textBlock.selectionOrigin,
            textStart,
          ));
          parts.add(text);
          textStart += text.length + 1;
        }
      }
    }
    // Drop the trailing +1 from the last non-empty part.
    _renderedText = parts.join('\n');
    _fragments = frags;
  }

  @override
  void paint(Canvas canvas, Size size, double offset) {
    // If the width is less than required do not paint anything.
    if (size.width < _size.width) return;

    // --- Draw vertical lines --- //
    for (var i = 1; i <= indent; i++) {
      canvas.drawLine(
        Offset(
          i * lineIndent,
          offset,
        ),
        Offset(
          i * lineIndent,
          offset + _size.height,
        ),
        linePaint,
      );
    }

    if (_leafPainter != null) {
      _leafPainter.paint(canvas, Offset(_contentLeft, offset));
      return;
    }

    canvas.save();
    canvas.translate(_contentLeft, 0);
    final childWidth = size.width - _contentLeft;
    for (var i = 0; i < _children.length; i++) {
      _children[i].paint(
        canvas,
        Size(childWidth, _children[i].size.height),
        offset + _childOffsets[i],
      );
    }
    canvas.restore();
  }

  @override
  void dispose() {
    _leafPainter?.dispose();
    for (final child in _children) {
      child.dispose();
    }
  }
}
