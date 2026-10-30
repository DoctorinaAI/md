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
import '../inline_image.dart';
import '../span_builder.dart';

/// A helper class to store layout information for a single list item.
class _ListItemMetrics {
  _ListItemMetrics({
    required this.bulletPainter,
    required this.contentPainter,
    required this.offset,
    required this.contentOffset,
  });

  final TextPainter bulletPainter;
  final TextPainter contentPainter;

  /// Block-local top-left of the bullet.
  final Offset offset;

  /// Block-local top-left of the item content.
  final Offset contentOffset;

  late final double height =
      math.max(bulletPainter.height, contentPainter.height);
  late final Size size =
      Size(bulletPainter.width + contentPainter.width, height);
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
        _fills = _listItemsPaintOpaqueBackground(items);

  /// Inline monospace/highlight fills in item text live in the content
  /// [Picture].
  @override
  bool get selectionHighlightAboveCachedContent => _fills || _hasImages;
  final bool _fills;

  /// Whether the item text holds a picture.
  bool _hasImages = false;

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

  /// The item text painters in depth-first order, built by the first layout
  /// and kept: the text of an item is the same at every width.
  final List<TextPainter> _contentPainters = <TextPainter>[];

  /// The width of the last layout, when it can be reused as is.
  double? _laidOutWidth;

  /// The laid-out marker painters, by marker text.
  final Map<String, TextPainter> _bullets = <String, TextPainter>{};

  @override
  List<SelectableFragment> get fragments => _fragments ??= _buildFragments();
  List<SelectableFragment>? _fragments = const <SelectableFragment>[];

  @override
  String get renderedText => _renderedText ??=
      fragments.map((f) => markdownModelText(f.painter)).join('\n');
  String? _renderedText = '';

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
      final contentOffset = metrics.contentOffset;
      final contentRect = contentOffset & metrics.contentPainter.size;
      if (contentRect.contains(localPosition)) {
        return markdownSpanAtLocal(
          metrics.contentPainter,
          localPosition - contentOffset,
        );
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
      if (markdownSpanRecognizer(newSpan)
          case TapGestureRecognizer(:final onTap)) {
        onTap?.call();
      }
    }

    _lastSpan = null; // Clear the span after handling the tap.
  }

  @override
  Size layout(double width) {
    // Pictures can change size between two layouts at one width.
    if (width == _laidOutWidth) return _size;
    _laidOutWidth = theme.imageResolver == null ? width : null;
    _painters.clear();

    double currentHeight = 0;
    double maxContentWidth = 0;
    var next = 0;
    // Right-to-left lists put the bullet on the right, content to its left.
    final rtl = theme.textDirection == TextDirection.rtl && width.isFinite;

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
        // Unconstrained, so one painter serves every item with this marker,
        // at any width.
        final bulletPainter = _bullets[bulletText] ??= TextPainter(
          text: TextSpan(text: '$bulletText ', style: theme.textStyle),
          textDirection: theme.textDirection,
          textScaler: theme.textScaler,
        )..layout();

        final TextPainter contentPainter;
        if (next < _contentPainters.length) {
          contentPainter = _contentPainters[next];
        } else {
          contentPainter = TextPainter(
            text: paragraphFromMarkdownSpans(spans: item.spans, theme: theme),
            textDirection: theme.textDirection,
            textScaler: theme.textScaler,
          );
          _contentPainters.add(contentPainter);
          _hasImages = _hasImages ||
              (theme.imageResolver != null &&
                  markdownSpanHasImages(contentPainter.text));
        }
        next++;
        layoutMarkdownText(
          contentPainter,
          maxWidth: math.max(0, width - indent - bulletPainter.width),
        );

        final bulletX = rtl ? width - indent - bulletPainter.width : indent;
        final metrics = _ListItemMetrics(
          bulletPainter: bulletPainter,
          contentPainter: contentPainter,
          offset: Offset(bulletX, currentHeight),
          contentOffset: Offset(
            rtl
                ? math.max(bulletX - contentPainter.width, 0)
                : indent + bulletPainter.width,
            currentHeight,
          ),
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
    _fragments = null;
    _renderedText = null;
    return _size = Size(maxContentWidth, currentHeight);
  }

  /// The selectable fragments of the laid-out item metrics, built when
  /// selection first asks. Items (depth-first, matching
  /// `markdownBlockRenderedText`) are joined by `\n`.
  List<SelectableFragment> _buildFragments() {
    final frags = <SelectableFragment>[];
    var textPos = 0;
    for (final metrics in _painters) {
      if (frags.isNotEmpty) textPos += 1; // the '\n' item separator
      frags.add(SelectableFragment(
        metrics.contentPainter,
        metrics.contentOffset,
        textPos,
      ));
      textPos += markdownModelText(metrics.contentPainter).length;
    }
    return frags;
  }

  @override
  void paint(Canvas canvas, Size size, double offset) {
    final dy = Offset(0, offset);
    for (final metrics in _painters) {
      metrics.bulletPainter.paint(canvas, metrics.offset + dy);
      paintMarkdownText(
        metrics.contentPainter,
        canvas,
        metrics.contentOffset + dy,
      );
    }
  }

  @override
  void dispose() {
    for (final painter in _contentPainters) {
      painter.dispose();
    }
    _contentPainters.clear();
    _painters.clear();
    _laidOutWidth = null;
    for (final painter in _bullets.values) {
      painter.dispose();
    }
    _bullets.clear();
    _fragments = const <SelectableFragment>[];
    _renderedText = '';
  }
}
