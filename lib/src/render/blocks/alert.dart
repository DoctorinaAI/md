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

/// A class for painting a GitHub-style alert (admonition) block in markdown.
class BlockPainter$Alert
    with ParagraphGestureHandler, MultiPainterSelectable
    implements BlockPainter {
  /// Creates an alert painter of kind [alert] with body [spans], styled by
  /// [theme]. When [children] is non-empty, those painters replace the leaf
  /// body painter (fenced code inside `> [!NOTE]`, etc.).
  BlockPainter$Alert({
    required this.alert,
    required List<MD$Span> spans,
    required this.theme,
    List<BlockPainter> children = const <BlockPainter>[],
  })  : _children = children,
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

  /// Width of the accent bar on the left edge.
  static const double barWidth = 4.0;

  /// Gap between the accent bar and the content.
  static const double gap = 10.0;

  /// Vertical gap between the title and the body.
  static const double titleGap = 4.0;

  /// Left offset where the title/body content begins.
  double get _contentLeft => padding + barWidth + gap;

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

  /// Last span hit by the tap down event.
  TextSpan? _lastSpan;

  Offset get _bodyOrigin => Offset(_contentLeft, _bodyTop);

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
      final origin = Offset(_contentLeft, _bodyTop + _childOffsets[i]);
      if (!(origin & child.size).contains(localPosition)) continue;
      final inner = localPosition - origin;
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
        final span = painter.text?.getSpanForPosition(position);
        return span is TextSpan ? span : null;
      }
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
    final frags = <SelectableFragment>[];
    final parts = <String>[];
    var textStart = 0;
    for (var i = 0; i < _children.length; i++) {
      final child = _children[i];
      final origin = Offset(_contentLeft, _bodyTop + _childOffsets[i]);
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
    _renderedText = parts.join('\n');
    _fragments = frags;
  }

  @override
  void paint(Canvas canvas, Size size, double offset) {
    if (size.width < _size.width) return;

    final rect = Rect.fromLTWH(0, offset, size.width, _size.height);
    // Tinted background.
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(6.0)),
      Paint()
        ..color = _accent.withValues(alpha: 0.10)
        ..style = PaintingStyle.fill,
    );
    // Accent bar on the left.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, offset, barWidth, _size.height),
        const Radius.circular(barWidth / 2),
      ),
      Paint()
        ..color = _accent
        ..style = PaintingStyle.fill,
    );

    titlePainter.paint(canvas, Offset(_contentLeft, offset + padding));
    if (!_hasBody) return;

    if (_bodyPainter != null) {
      _bodyPainter.paint(canvas, _bodyOrigin + Offset(0, offset));
      return;
    }

    canvas.save();
    canvas.translate(_contentLeft, 0);
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
