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
import '../span_builder.dart';

/// A class for painting a GitHub-style alert (admonition) block in markdown.
class BlockPainter$Alert
    with ParagraphGestureHandler, MultiPainterSelectable
    implements BlockPainter {
  /// Creates an alert painter of kind [alert] with body [spans], styled by
  /// [theme]. When [children] is non-empty, those painters replace the leaf
  /// body painter (fenced code inside `> [!NOTE]`, etc.).
  ///
  /// [blocks] are the [MD$Alert.blocks] models [children] were built from
  /// (one per child, in order). Optional: they let a child painter that
  /// exposes no selectable text (a host [MarkdownThemeData.builder] result)
  /// still occupy its text in the selection offset space, keeping it equal to
  /// `markdownBlockRenderedText`. Ignored unless it matches [children] in
  /// length.
  BlockPainter$Alert({
    required this.alert,
    required List<MD$Span> spans,
    required this.theme,
    List<BlockPainter> children = const <BlockPainter>[],
    List<MD$Block> blocks = const <MD$Block>[],
  })  : _children = children,
        _modelTexts = blocks.isNotEmpty && blocks.length == children.length
            ? <String>[for (final b in blocks) markdownBlockRenderedText(b)]
            : null,
        _accent = theme.alertColorFor(alert),
        _selectionHighlightAboveCachedContent = children.isNotEmpty
            ? children.any(
                (c) =>
                    c is SelectableBlockPainter &&
                    c.selectionHighlightAboveCachedContent,
              )
            : markdownSpansPaintOpaqueBackground(spans),
        titlePainter = TextPainter(
          text: TextSpan(
            text: alert.title,
            style: theme.textStyle.copyWith(
              color: theme.alertColorFor(alert),
              fontWeight: FontWeight.bold,
            ),
          ),
          textAlign: TextAlign.start,
          textDirection: theme.textDirection,
          textScaler: theme.textScaler,
        ),
        _bodyPainter = children.isEmpty
            ? TextPainter(
                text: paragraphFromMarkdownSpans(spans: spans, theme: theme),
                textAlign: TextAlign.start,
                textDirection: theme.textDirection,
                textScaler: theme.textScaler,
              )
            : null;

  /// Nested body painters when the alert model carries [MD$Alert.blocks].
  final List<BlockPainter> _children;

  /// Model-side rendered text per child, when [MD$Alert.blocks] were given.
  final List<String>? _modelTexts;

  /// Leaf body painter when there are no nested children.
  final TextPainter? _bodyPainter;

  /// Alert chrome and optional inline monospace/highlight fills sit in the
  /// content [Picture].
  @override
  bool get selectionHighlightAboveCachedContent =>
      _selectionHighlightAboveCachedContent;
  final bool _selectionHighlightAboveCachedContent;

  /// The kind of the alert being painted.
  final MD$AlertType alert;

  /// The theme used to style the alert.
  final MarkdownThemeData theme;

  final Color _accent;

  /// Painter for the alert title (e.g. "Note").
  final TextPainter titlePainter;

  /// Padding around the alert's content, inside its rounded background.
  static const double padding = 10.0;

  /// Width of the accent bar on the start edge.
  static const double barWidth = 4.0;

  /// Gap between the accent bar and the content.
  static const double gap = 10.0;

  /// Vertical gap between the title and the body.
  static const double titleGap = 4.0;

  /// Inset from the start edge where the title/body content begins.
  double get _contentLeft => padding + barWidth + gap;

  /// Whether the last layout mirrored the block for right-to-left text.
  bool _rtl = false;

  /// The width passed to the last [layout].
  double _width = 0;

  /// Block-local x of the content column's left edge: after the bar for
  /// left-to-right text, or the trailing padding with the bar on the right
  /// for RTL.
  double get _columnLeft => _rtl ? padding : _contentLeft;

  /// Block-local x where [painter]'s glyphs start: after the bar for
  /// left-to-right text, or flush against the right-hand bar for RTL.
  double _contentX(TextPainter painter) =>
      _rtl ? math.max(_width - _contentLeft - painter.width, 0) : _contentLeft;

  @override
  Size get size => _size;
  Size _size = Size.zero;

  @override
  List<SelectableFragment> get fragments => _fragments;
  List<SelectableFragment> _fragments = const <SelectableFragment>[];

  @override
  String get renderedText => _renderedText;
  String _renderedText = '';

  /// Whether the body has any content to paint.
  bool _hasBody = false;

  /// Top of the body column within the alert (below the title).
  double _bodyTop = 0;

  /// Vertical offsets of each nested child within the body column.
  List<double> _childOffsets = const <double>[];

  /// Block-local top-left of each nested child.
  List<Offset> _childOrigins = const <Offset>[];

  /// Last span hit by the tap down event.
  TextSpan? _lastSpan;

  Offset get _bodyOrigin => Offset(_contentX(_bodyPainter!), _bodyTop);

  TextSpan? _spanForPosition(Offset localPosition) {
    if (!_hasBody) return null;
    if (_bodyPainter != null) {
      final local = localPosition - _bodyOrigin;
      if (local.dx < 0 ||
          local.dy < 0 ||
          local.dx > _bodyPainter.width ||
          local.dy > _bodyPainter.height) {
        return null;
      }
      final position = _bodyPainter.getPositionForOffset(local);
      final span = _bodyPainter.text?.getSpanForPosition(position);
      return span is TextSpan ? span : null;
    }
    for (var i = 0; i < _children.length; i++) {
      final child = _children[i];
      final top = _bodyTop + _childOffsets[i];
      if (localPosition.dy < top ||
          localPosition.dy >= top + child.size.height) {
        continue;
      }
      final span =
          _childSpanAt(child, localPosition - Offset(_columnLeft, top));
      return span is TextSpan ? span : null;
    }
    return null;
  }

  @override
  void handleTapDown(PointerDownEvent event) {
    _lastSpan = _spanForPosition(event.localPosition);
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
    _rtl = theme.textDirection == TextDirection.rtl && width.isFinite;
    _width = width;
    final available = math.max(0.0, width - _contentLeft - padding);
    titlePainter.layout(minWidth: 0, maxWidth: available);
    _bodyTop = padding + titlePainter.height + titleGap;

    double bodyWidth = 0;
    double bodyHeight = 0;
    if (_bodyPainter != null) {
      _bodyPainter.layout(minWidth: 0, maxWidth: available);
      _hasBody = _bodyPainter.text?.toPlainText().isNotEmpty ?? false;
      if (_hasBody) {
        bodyWidth = _bodyPainter.width;
        bodyHeight = _bodyPainter.height;
        _fragments = <SelectableFragment>[
          SelectableFragment(_bodyPainter, _bodyOrigin, 0),
        ];
        _renderedText = _bodyPainter.plainText;
      } else {
        _fragments = const <SelectableFragment>[];
        _renderedText = '';
      }
      _childOffsets = const <double>[];
      _childOrigins = const <Offset>[];
    } else {
      final offsets = List<double>.filled(_children.length, 0.0);
      var y = 0.0;
      for (var i = 0; i < _children.length; i++) {
        offsets[i] = y;
        final childSize = _children[i].layout(available);
        bodyWidth = math.max(bodyWidth, childSize.width);
        y += childSize.height;
      }
      _childOffsets = offsets;
      bodyHeight = y;
      _hasBody = bodyHeight > 0;
      _rebuildFragments();
    }

    final contentWidth = math.max(titlePainter.width, bodyWidth);
    final contentHeight =
        titlePainter.height + (_hasBody ? titleGap + bodyHeight : 0.0);
    return _size = Size(
      _contentLeft + contentWidth + padding,
      contentHeight + padding * 2,
    );
  }

  void _rebuildFragments() {
    _childOrigins = <Offset>[
      for (final dy in _childOffsets) Offset(_columnLeft, _bodyTop + dy),
    ];
    final (frags, text) =
        nestedBlockFragments(_children, _childOrigins, _modelTexts);
    _fragments = frags;
    _renderedText = text;
  }

  /// Glyph-tight: the gutter beside a short body line (or a nested child's
  /// own gutter) is not text, matching paragraphs. The title is not
  /// selectable and never hits.
  @override
  bool hitsRenderedTextAt(Offset local) {
    if (!_hasBody) return false;
    final body = _bodyPainter;
    if (body != null) return painterHitsGlyphBoxes(body, local - _bodyOrigin);
    return nestedBlocksHitRenderedText(_children, _childOrigins, local);
  }

  @override
  void paint(Canvas canvas, Size size, double offset) {
    // A leaf alert narrower than its text paints nothing. Nested children
    // may legitimately overflow (a wide table), so they are always painted.
    if (_bodyPainter != null && size.width < _size.width) return;

    final rect = Rect.fromLTWH(0, offset, size.width, _size.height);
    // Tinted background.
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(6.0)),
      Paint()
        ..color = _accent.withValues(alpha: 0.10)
        ..style = PaintingStyle.fill,
    );
    // Accent bar on the start edge.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          _rtl ? size.width - barWidth : 0,
          offset,
          barWidth,
          _size.height,
        ),
        const Radius.circular(barWidth / 2),
      ),
      Paint()
        ..color = _accent
        ..style = PaintingStyle.fill,
    );

    titlePainter.paint(
      canvas,
      Offset(_contentX(titlePainter), offset + padding),
    );
    if (!_hasBody) return;

    if (_bodyPainter != null) {
      _bodyPainter.paint(canvas, _bodyOrigin + Offset(0, offset));
      return;
    }

    canvas.save();
    canvas.translate(_columnLeft, 0);
    final childWidth = size.width - _contentLeft - padding;
    for (var i = 0; i < _children.length; i++) {
      _children[i].paint(
        canvas,
        Size(childWidth, _children[i].size.height),
        offset + _bodyTop + _childOffsets[i],
      );
    }
    canvas.restore();
  }

  @override
  void dispose() {
    titlePainter.dispose();
    _bodyPainter?.dispose();
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
    return painter.text?.getSpanForPosition(
      painter.getPositionForOffset(inner),
    );
  }
  return null;
}
