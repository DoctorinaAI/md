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

/// A helper class to store layout information for a single list item.
class _ListItemMetrics {
  _ListItemMetrics({
    required this.bulletPainter,
    required this.contentPainter,
    required this.offset,
  });

  final TextPainter bulletPainter;
  final TextPainter contentPainter;
  final Offset offset;

  late final double height =
      math.max(bulletPainter.height, contentPainter.height);
  late final Size size =
      Size(bulletPainter.width + contentPainter.width, height);

  void dispose() {
    bulletPainter.dispose();
    contentPainter.dispose();
  }
}

/// A class for painting a list block in markdown.
class BlockPainter$List
    with ParagraphGestureHandler, MultiPainterSelectable
    implements BlockPainter {
  /// Creates a list painter for [items] (bulleted, ordered or task list),
  /// styled by [theme].
  BlockPainter$List({
    required List<MD$ListItem> items,
    required this.theme,
  })  : _items = items,
        _painters = <_ListItemMetrics>[],
        _selectionHighlightAboveCachedContent =
            _listItemsPaintOpaqueBackground(items);

  /// Inline monospace/highlight fills in item text live in the content
  /// [Picture].
  @override
  bool get selectionHighlightAboveCachedContent =>
      _selectionHighlightAboveCachedContent;
  final bool _selectionHighlightAboveCachedContent;

  static bool _listItemsPaintOpaqueBackground(List<MD$ListItem> items) {
    for (final item in items) {
      if (markdownSpansPaintOpaqueBackground(item.spans)) return true;
      if (_listItemsPaintOpaqueBackground(item.children)) return true;
    }
    return false;
  }

  /// The theme used to style the list.
  final MarkdownThemeData theme;
  final List<MD$ListItem> _items;
  final List<_ListItemMetrics> _painters;

  @override
  List<SelectableFragment> get fragments => _fragments;
  List<SelectableFragment> _fragments = const <SelectableFragment>[];

  @override
  String get renderedText => _renderedText;
  String _renderedText = '';

  // Indentation for the entire list block.
  static const double _baseIndent = 8.0;

  // Indentation for each level of nesting.
  static const double _levelIndent = 16.0;

  @override
  Size get size => _size;
  Size _size = Size.zero;

  /// Last span hit by the tap down event.
  InlineSpan? _lastSpan;

  InlineSpan? _getSpanForPosition(Offset localPosition) {
    for (final metrics in _painters) {
      final contentOffset =
          metrics.offset + Offset(metrics.bulletPainter.width, 0);
      final contentRect = contentOffset & metrics.contentPainter.size;
      if (contentRect.contains(localPosition)) {
        final painterPosition = localPosition - contentOffset;
        final textPosition =
            metrics.contentPainter.getPositionForOffset(painterPosition);
        return metrics.contentPainter.text?.getSpanForPosition(textPosition);
      }
    }
    return null;
  }

  @override
  void handleTapDown(PointerDownEvent event) {
    _lastSpan = null; // Reset the span on tap down.
    _lastSpan = _getSpanForPosition(event.localPosition);
  }

  @override
  void handleTapUp(PointerUpEvent event) {
    if (_lastSpan == null) return; // No span was hit on tap down.
    final newSpan = _getSpanForPosition(event.localPosition);
    if (newSpan != null && _lastSpan == newSpan) {
      if (newSpan
          case TextSpan(recognizer: final TapGestureRecognizer recognizer)) {
        recognizer.onTap?.call();
      }
    }

    _lastSpan = null; // Clear the span after handling the tap.
  }

  @override
  Size layout(double width) {
    for (final painter in _painters) {
      painter.dispose();
    }
    _painters.clear();

    double currentHeight = 0;
    double maxContentWidth = 0;

    void layoutItems(List<MD$ListItem> items, int level) {
      final indent = _baseIndent + level * _levelIndent;
      for (final item in items) {
        // Task-list items render a checkbox instead of a bullet/number.
        final bulletText = switch (item.checked) {
          true => '☑',
          false => '☐',
          null => switch (item.marker) {
              '-' || '*' || '+' => '•',
              _ => item.marker,
            },
        };
        final bulletPainter = TextPainter(
          text: TextSpan(text: '$bulletText ', style: theme.textStyle),
          textDirection: theme.textDirection,
          textScaler: theme.textScaler,
        )..layout();

        final contentPainter = TextPainter(
          text: paragraphFromMarkdownSpans(spans: item.spans, theme: theme),
          textDirection: theme.textDirection,
          textScaler: theme.textScaler,
        )..layout(maxWidth: math.max(0, width - indent - bulletPainter.width));

        final metrics = _ListItemMetrics(
          bulletPainter: bulletPainter,
          contentPainter: contentPainter,
          offset: Offset(indent, currentHeight),
        );
        _painters.add(metrics);

        currentHeight += metrics.height;
        maxContentWidth =
            math.max(maxContentWidth, indent + metrics.size.width);

        if (item.children.isNotEmpty) {
          layoutItems(item.children, level + 1);
        }
      }
    }

    layoutItems(_items, 0);
    _rebuildFragments();
    return _size = Size(maxContentWidth, currentHeight);
  }

  /// Rebuilds the selectable fragments from the laid-out item metrics. Items
  /// (depth-first, matching `markdownBlockRenderedText`) are joined by `\n`.
  void _rebuildFragments() {
    final frags = <SelectableFragment>[];
    var textPos = 0;
    for (final metrics in _painters) {
      if (frags.isNotEmpty) textPos += 1; // the '\n' item separator
      final origin = metrics.offset + Offset(metrics.bulletPainter.width, 0);
      frags.add(SelectableFragment(metrics.contentPainter, origin, textPos));
      textPos += metrics.contentPainter.plainText.length;
    }
    _fragments = frags;
    _renderedText = frags.map((f) => f.painter.plainText).join('\n');
  }

  @override
  void paint(Canvas canvas, Size size, double offset) {
    for (final metrics in _painters) {
      final bulletOffset = metrics.offset + Offset(0, offset);
      metrics.bulletPainter.paint(canvas, bulletOffset);

      final contentOffset =
          bulletOffset + Offset(metrics.bulletPainter.width, 0);
      metrics.contentPainter.paint(canvas, contentOffset);
    }
  }

  @override
  void dispose() {
    for (final metrics in _painters) {
      metrics.dispose();
    }
    _painters.clear();
    _fragments = const <SelectableFragment>[];
  }
}
