//ignore_for_file: unnecessary_import

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../nodes.dart';
import '../../selection.dart' show markdownBlockRenderedText;
import '../../theme.dart';
import '../block_painter.dart';
import '../inline_image.dart';
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
  ///
  /// [blocks] are the [MD$Quote.blocks] models [children] were built from
  /// (one per child, in order). Optional: they let a child painter that
  /// exposes no selectable text (a host [MarkdownThemeData.builder] result)
  /// still occupy its text in the selection offset space, keeping it equal to
  /// `markdownBlockRenderedText`. Ignored unless it matches [children] in
  /// length.
  BlockPainter$Quote({
    required List<MD$Span> spans,
    required this.indent,
    required this.theme,
    List<BlockPainter> children = const <BlockPainter>[],
    List<MD$Block> blocks = const <MD$Block>[],
  })  : _children = children,
        _modelTexts = blocks.isNotEmpty && blocks.length == children.length
            ? <String>[for (final b in blocks) markdownBlockRenderedText(b)]
            : null,
        _fills = children.isEmpty && markdownSpansPaintOpaqueBackground(spans),
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

  /// Model-side rendered text per child, when [MD$Quote.blocks] were given.
  final List<String>? _modelTexts;

  /// Leaf glyph painter when there are no nested children.
  final TextPainter? _leafPainter;

  /// Inline monospace/highlight fills (or nested code chrome) live in the
  /// content [Picture].
  @override
  bool get selectionHighlightAboveCachedContent =>
      _fills ||
      _hasImages ||
      _children.any(
        (c) =>
            c is SelectableBlockPainter &&
            c.selectionHighlightAboveCachedContent,
      );
  final bool _fills;
  late final bool _hasImages = markdownSpanHasImages(_leafPainter?.text);

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

  /// Paint used for the vertical accent bar(s) on the start side.
  final Paint linePaint;

  @override
  Size get size => _size;
  Size _size = Size.zero;

  @override
  List<SelectableFragment> get fragments {
    if (_fragments == null) _rebuildFragments();
    return _fragments!;
  }

  List<SelectableFragment>? _fragments = const <SelectableFragment>[];

  @override
  String get renderedText {
    if (_renderedText == null) _rebuildFragments();
    return _renderedText!;
  }

  String? _renderedText = '';

  /// Vertical offsets of each nested child within the quote content column.
  List<double> _childOffsets = const <double>[];

  /// Block-local top-left of each nested child.
  List<Offset> _childOrigins = const <Offset>[];

  /// Last span hit by the tap down event.
  InlineSpan? _lastSpan;

  /// Whether the last layout mirrored the block for right-to-left text.
  bool _rtl = false;

  /// The width passed to the last [layout].
  double _width = 0;

  /// Inset from the start edge taken by the accent bars.
  double get _contentLeft => lineIndent + indent * lineIndent;

  /// Block-local x of the content column's left edge: after the bars for
  /// left-to-right text, or at `0` with the bars on the right for RTL.
  double get _columnLeft => _rtl ? 0.0 : _contentLeft;

  /// Block-local x where the leaf glyphs start: right-to-left text sits
  /// against the bars on the right.
  double get _leafLeft => _rtl
      ? math.max(_width - _contentLeft - _leafPainter!.width, 0.0)
      : _contentLeft;

  InlineSpan? _spanForPosition(Offset localPosition) {
    if (_leafPainter != null) {
      final local = localPosition - Offset(_leafLeft, 0);
      if (local.dx < 0 ||
          local.dy < 0 ||
          local.dx > _leafPainter.width ||
          local.dy > _leafPainter.height) {
        return null;
      }
      return markdownSpanAtLocal(_leafPainter, local);
    }
    for (var i = 0; i < _children.length; i++) {
      final child = _children[i];
      final top = _childOffsets[i];
      if (localPosition.dy < top ||
          localPosition.dy >= top + child.size.height) {
        continue;
      }
      return _childSpanAt(child, localPosition - Offset(_columnLeft, top));
    }
    return null;
  }

  @override
  void handleTapDown(PointerDownEvent event) {
    _lastSpan = null;
    final span = _spanForPosition(event.localPosition);
    _lastSpan = span;
  }

  @override
  void handleTapUp(PointerUpEvent event) {
    if (_lastSpan == null) return;
    final span = _spanForPosition(event.localPosition);
    if (span != null && _lastSpan == span) {
      if (markdownSpanRecognizer(span)
          case TapGestureRecognizer(:final onTap)) {
        onTap?.call();
      }
    }
    _lastSpan = null;
  }

  @override
  Size layout(double width) {
    _rtl = theme.textDirection == TextDirection.rtl && width.isFinite;
    _width = width;
    final contentWidth = math.max(width - _contentLeft, 0.0);
    if (_leafPainter != null) {
      layoutMarkdownText(_leafPainter, maxWidth: contentWidth);
      _size = Size(
        _leafPainter.size.width + _contentLeft,
        _leafPainter.size.height,
      );
      _fragments = null;
      _renderedText = null;
      _childOffsets = const <double>[];
      _childOrigins = const <Offset>[];
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
    _childOrigins = <Offset>[
      for (final dy in _childOffsets) Offset(_columnLeft, dy),
    ];
    _fragments = null;
    _renderedText = null;
    return _size;
  }

  /// Built when selection first asks: most documents are never selected.
  void _rebuildFragments() {
    final leaf = _leafPainter;
    if (leaf != null) {
      _fragments = <SelectableFragment>[
        SelectableFragment(leaf, Offset(_leafLeft, 0), 0),
      ];
      _renderedText = markdownModelText(leaf);
      return;
    }
    final (frags, text) =
        nestedBlockFragments(_children, _childOrigins, _modelTexts);
    _fragments = frags;
    _renderedText = text;
  }

  /// Glyph-tight: the gutter beside a short line (or a nested child's own
  /// gutter) is not text, matching paragraphs.
  @override
  bool hitsRenderedTextAt(Offset local) {
    final leaf = _leafPainter;
    if (leaf != null) {
      return painterHitsGlyphBoxes(leaf, local - Offset(_leafLeft, 0));
    }
    return nestedBlocksHitRenderedText(_children, _childOrigins, local);
  }

  @override
  void paint(Canvas canvas, Size size, double offset) {
    // A leaf quote narrower than its text paints nothing. Nested children
    // may legitimately overflow (a wide table), so they are always painted.
    if (_leafPainter != null && size.width < _size.width) return;

    // --- Draw vertical lines --- //
    for (var i = 1; i <= indent; i++) {
      final x = _rtl ? _width - i * lineIndent : i * lineIndent;
      canvas.drawLine(
        Offset(x, offset),
        Offset(x, offset + _size.height),
        linePaint,
      );
    }

    if (_leafPainter != null) {
      paintMarkdownText(_leafPainter, canvas, Offset(_leafLeft, offset));
      return;
    }

    canvas.save();
    canvas.translate(_columnLeft, 0);
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
    _fragments = const <SelectableFragment>[];
    _renderedText = '';
    _leafPainter?.dispose();
    for (final child in _children) {
      child.dispose();
    }
  }
}

/// The span under [local] (block-local to [child]) among the text painters
/// [child] exposes for selection, or null when no painter's box contains it.
///
/// Goes through the selection fragments rather than [child]'s size: a child
/// sizes to its content, which right-to-left text right-aligns within the
/// column, and a list or table child paints several painters.
InlineSpan? _childSpanAt(BlockPainter child, Offset local) {
  final fragments = switch (child) {
    MultiPainterSelectable(:final fragments) => fragments,
    SelectableTextBlock(:final selectionPainter, :final selectionOrigin) =>
      <SelectableFragment>[
        SelectableFragment(selectionPainter, selectionOrigin, 0),
      ],
    _ => const <SelectableFragment>[],
  };
  for (final fragment in fragments) {
    final painter = fragment.painter;
    final inner = local - fragment.origin;
    if (!(Offset.zero & painter.size).contains(inner)) continue;
    return markdownSpanAtLocal(painter, inner);
  }
  return null;
}
