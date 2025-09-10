//ignore_for_file: unnecessary_import

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:meta/meta.dart' as meta show internal;

import 'markdown.dart';
import 'nodes.dart';
import 'theme.dart';

@meta.internal
class MarkdownRenderObject extends RenderBox {
  MarkdownRenderObject({
    required Markdown markdown,
    required MarkdownThemeData theme,
  }) : _painter = MarkdownPainter(
          markdown: markdown,
          theme: theme,
        );

  /// Painter for rendering markdown content.
  final MarkdownPainter _painter;

  /// Current size of the render box.
  @override
  Size get size => _size;
  Size _size = Size.zero;

  @override
  bool get isRepaintBoundary => false;

  @override
  bool get alwaysNeedsCompositing => false;

  @override
  bool get sizedByParent => false;

  @override
  set size(Size value) {
    final prev = super.hasSize ? super.size : null;
    super.size = value;
    if (prev == value) return;
    _size = value;
  }

  @override
  void debugResetSize() {
    super.debugResetSize();
    if (!super.hasSize) return;
    _size = super.size;
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      constraints.constrain(_painter.layout(maxWidth: constraints.maxWidth));

  @override
  void performLayout() {
    // Set the size of the render box to match the painter's size.
    size =
        constraints.constrain(_painter.layout(maxWidth: constraints.maxWidth));
  }

  @override
  // ignore: unnecessary_overrides
  void performResize() {
    size = computeDryLayout(constraints);
  }

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  bool hitTestChildren(
    BoxHitTestResult result, {
    required Offset position,
  }) =>
      false;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    var hitTarget = false;
    if (size.contains(position)) {
      hitTarget = hitTestSelf(position);
      result.add(BoxHitTestEntry(this, position));
    }
    return hitTarget;
  }

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    _painter.handleEvent(event);
  }

  @override
  // ignore: unnecessary_overrides
  void attach(PipelineOwner owner) {
    super.attach(owner);
    // Ensure the painter is mounted when the render object is attached.
  }

  /// Updates the render object with a new values.
  /// This method should be called whenever the markdown or theme changes.
  @meta.internal
  void update({
    required Markdown markdown,
    required MarkdownThemeData theme,
  }) {
    if (_painter.update(
      markdown: markdown,
      theme: theme,
    )) {
      // Mark the render object as needing layout.
      markNeedsLayout();
    }
  }

  @override
  @protected
  void detach() {
    super.detach();
  }

  @override
  @protected
  void dispose() {
    super.dispose();
    _painter.dispose();
  }

  @override
  @protected
  void paint(PaintingContext context, Offset offset) {
    if (_painter.isEmpty)
      return; // If the markdown is empty, do not paint anything.

    // ignore: unused_local_variable
    final canvas = context.canvas
      ..save()
      ..translate(offset.dx, offset.dy);
    //..clipRect(Rect.fromLTWH(0, 0, size.width, size.height));

    _painter.paint(canvas, size);

    canvas.restore();
  }
}

/// A painter for rendering markdown content via blocks and spans.
@meta.internal
class MarkdownPainter {
  /// Creates a [MarkdownPainter] instance.
  MarkdownPainter({
    required Markdown markdown,
    required MarkdownThemeData theme,
  })  : _markdown = markdown,
        _theme = theme,
        _isEmpty = markdown.isEmpty,
        _size = Size.zero {
    _rebuild();
  }

  /// Is the markdown entity empty?
  bool get isEmpty => _isEmpty;
  bool _isEmpty;

  /// Current markdown entity to render.
  Markdown _markdown;

  /// Current theme for the markdown widget.
  MarkdownThemeData _theme;

  /// The size of the painted markdown content.
  Size get size => _size;
  Size _size;

  /// Indicates if the layout needs to be recalculated.
  bool _needsLayout = true;

  Float32List _blockOffsets = Float32List(0);
  List<BlockPainter> _blockPainters = const <BlockPainter>[];

  static BlockPainter _defaultBlockBuilder(
    MD$Block block,
    MarkdownThemeData theme,
  ) =>
      block.map<BlockPainter>(
        paragraph: (p) => BlockPainter$Paragraph(
          spans: p.spans,
          theme: theme,
        ),
        heading: (h) => BlockPainter$Heading(
          level: h.level,
          spans: h.spans,
          theme: theme,
        ),
        quote: (q) => BlockPainter$Quote(
          spans: q.spans,
          indent: q.indent,
          theme: theme,
        ),
        code: (c) => BlockPainter$Code(
          language: c.language,
          text: c.text,
          theme: theme,
        ),
        list: (l) => BlockPainter$List(
          items: l.items,
          theme: theme,
        ),
        divider: (d) => BlockPainter$Divider(
          theme: theme,
        ),
        table: (t) => BlockPainter$Table(
          header: t.header,
          rows: t.rows,
          theme: theme,
        ),
        spacer: (s) => BlockPainter$Spacer(
          count: s.count,
          theme: theme,
        ),
      );

  /// Rebuilds the block painters from the markdown blocks.
  /// This method is called whenever the markdown or theme changes.
  void _rebuild() {
    _needsLayout = true; // Mark that layout needs to be recalculated.
    _size = Size.zero; // Reset size before rebuilding.
    final filter = _theme.blockFilter;
    final filtered =
        filter != null ? _markdown.blocks.where(filter) : _markdown.blocks;
    final builder = _theme.builder ?? _defaultBlockBuilder;
    _blockPainters = filtered
        .map<BlockPainter>(
          (block) =>
              builder(block, _theme) ?? _defaultBlockBuilder(block, _theme),
        )
        .toList(growable: false);
    _blockOffsets = Float32List(_blockPainters.length);
  }

  /// Update the painter with new values.
  /// If the values are the same,
  /// no update is required and the method returns false.
  bool update({
    required Markdown markdown,
    required MarkdownThemeData theme,
  }) {
    if (identical(_markdown, markdown) && identical(_theme, theme))
      return false;
    _lastSize = null;
    _lastPicture = null;
    _markdown = markdown;
    _theme = theme;
    _isEmpty = markdown.isEmpty;
    _rebuild();
    return true; // Indicate that the painter was updated.
  }

  /// Layouts the markdown content with the given width.
  Size layout({required double maxWidth}) {
    if (_isEmpty) {
      _size = Size.zero;
      _needsLayout = false; // No need to layout if the markdown is empty.
      return _size; // If the markdown is empty, return zero size.
    }
    var width = .0, height = .0;
    final blocks = _blockPainters;
    if (_blockOffsets.length != blocks.length) {
      // Resize the block sizes array
      // if it does not match the number of painters.
      _blockOffsets = Float32List(blocks.length);
    }
    final offsets = _blockOffsets;
    for (var i = 0; i < blocks.length; i++) {
      offsets[i] = height;
      final block = blocks[i];
      final size = block.layout(maxWidth);
      width = math.max(width, size.width);
      height += size.height;
    }
    _needsLayout = false; // No need to layout if the markdown is empty.
    return _size = Size(width, height);
  }

  /// Get the painter from the array by the vertical local position (dy).
  /* static BlockPainter? _getPainterByHeight(
    Iterable<BlockPainter> painters,
    double dy,
  ) {
    var offset = .0;
    BlockPainter? result;
    for (var painter in painters) {
      if (dy < offset) break;
      result = painter;
      offset += painter.size.height; // Update the offset for the next block.
    }
    return result;
  } */

  void handleEvent(PointerEvent event) {
    if (_blockPainters.isEmpty) return;
    // event.buttons, event.kind, event.position
    // event.localPosition, event.delta, event.down

    // Only handle pointer down events for now.
    // You can extend this to handle other pointer events if needed.
    if (event is! PointerDownEvent && event is! PointerUpEvent) return;

    final pos = event.localPosition;
    {
      // Binary search to find the block painter by the vertical position.
      final dy = pos.dy;
      var min = 0;
      var max = _blockPainters.length;
      var idx = 0;
      while (min < max) {
        final mid = min + ((max - min) >> 1);
        final offset = _blockOffsets[mid];
        //final comp = offset.compareTo(dy);
        var comp = 0;
        if (offset > dy) {
          // The offset is greater than the position.
          comp = 1;
        } else {
          idx = mid; // Remember the index of the block painter.
          // The offset is less than or equal to the position.
          comp = offset < dy ? -1 : 0;
        }
        if (comp == 0) {
          break; // Found the exact match.
        } else if (comp < 0) {
          min = mid + 1;
        } else {
          max = mid;
        }
      }
      switch (event) {
        case PointerDownEvent():
          final blockTapEvent = PointerDownEvent(
            // Adjust the position by the block offset.
            position: Offset(
              pos.dx,
              pos.dy - _blockOffsets[idx],
            ),
            viewId: event.viewId,
            timeStamp: event.timeStamp,
            pointer: event.pointer,
            kind: event.kind,
            device: event.device,
            buttons: event.buttons,
            obscured: event.obscured,
            pressure: event.pressure,
            pressureMin: event.pressureMin,
            pressureMax: event.pressureMax,
            distanceMax: event.distanceMax,
            size: event.size,
            radiusMajor: event.radiusMajor,
            radiusMinor: event.radiusMinor,
            radiusMin: event.radiusMin,
            radiusMax: event.radiusMax,
            orientation: event.orientation,
            tilt: event.tilt,
            embedderId: event.embedderId,
          );
          _blockPainters[idx].handleTapDown(blockTapEvent);
        case PointerUpEvent():
          final blockTapEvent = PointerUpEvent(
            // Adjust the position by the block offset.
            position: Offset(
              pos.dx,
              pos.dy - _blockOffsets[idx],
            ),
            viewId: event.viewId,
            timeStamp: event.timeStamp,
            pointer: event.pointer,
            kind: event.kind,
            device: event.device,
            buttons: event.buttons,
            obscured: event.obscured,
            pressure: event.pressure,
            pressureMin: event.pressureMin,
            pressureMax: event.pressureMax,
            distanceMax: event.distanceMax,
            size: event.size,
            radiusMajor: event.radiusMajor,
            radiusMinor: event.radiusMinor,
            radiusMin: event.radiusMin,
            radiusMax: event.radiusMax,
            orientation: event.orientation,
            tilt: event.tilt,
            embedderId: event.embedderId,
          );
          _blockPainters[idx].handleTapUp(blockTapEvent);
      }
    }

    // We can use the position to determine which block was hit.
    //_getPainterByHeight(_blockPainters, pos.dy)?.handleEvent(event);

    // Handle taps for the links with urls.
    /* switch (event) {
      case PointerDownEvent(down: true):
      // Handle pointer down events.
      default:
        // Handle other pointer events if needed.
        break;
    } */
  }

  /// The last size and picture used for painting.
  /// This is used to avoid unnecessary recreation of the canvas picture.
  /// If the size is the same as the last painted size,
  Size? _lastSize;

  /// The last picture used for painting,
  /// to avoid unnecessary recreation of the canvas picture.
  /// If the size is the same as the last painted size,
  /// we can reuse the last picture.
  Picture? _lastPicture;

  /// The markdown content to paint.
  void paint(Canvas canvas, Size size) {
    assert(
      !_needsLayout,
      'MarkdownPainter.paint() called without layout.',
    );
    assert(
      size.isFinite,
      'MarkdownPainter.paint() called with non-finite size: $size',
    );

    // Do not paint if the markdown is empty,
    // or if the size is empty or infinite.
    if (_isEmpty || size.isEmpty || size.isInfinite) return;

    if (_lastSize == size && _lastPicture != null) {
      // If the size is the same as the last painted size,
      // we can reuse the last picture.
      canvas.drawPicture(_lastPicture!);
      return;
    }

    final recorder = PictureRecorder();
    final $canvas = Canvas(recorder);

    // Paint each block painter on the canvas.
    var overflow = _size.height > size.height;
    var offset = .0;
    for (var painter in _blockPainters) {
      if (overflow && offset > size.height) {
        // If the painter's height exceeds the available height,
        // we stop painting further blocks.
        break;
      }
      painter.paint($canvas, size, offset);
      offset += painter.size.height; // Update the offset for the next block.
    }

    final picture = recorder.endRecording();
    canvas.drawPicture(picture);
    _lastSize = size;
    _lastPicture = picture;
  }

  void dispose() {
    _lastPicture?.dispose();
    _lastPicture = null;
    for (final painter in _blockPainters) {
      painter.dispose();
    }
    _blockPainters = const <BlockPainter>[];
  }
}

/* InlineSpan _imageFromMarkdownSpan({
  required MD$Span span,
  required MarkdownThemeData theme,
}) {
  final url = span.extra?['url'];
  if (url is! String || url.isEmpty) return const TextSpan();
  ImageProvider? provider;
  if (url.startsWith('http://') || url.startsWith('https://')) {
    provider = NetworkImage(url);
  } else if (url.startsWith('asset://')) {
    provider = AssetImage(Uri.parse(url).toFilePath());
  } else if (kIsWeb) {
    provider = NetworkImage(url);
  } else {
    return const TextSpan();
  }
  return WidgetSpan(
    alignment: PlaceholderAlignment.middle,
    child: SizedBox.square(
      dimension: 48, // Fixed size for the image.
      child: Image(
        image: provider,
        width: 48,
        height: 48,
        filterQuality: FilterQuality.medium,
        fit: BoxFit.scaleDown,
      ),
    ),
  );
} */

/// Builds a tap recognizer for the given markdown span.
TapGestureRecognizer? _buildTapRecognizer(
  MD$Span span,
  void Function(String title, String url)? onTap,
) {
  if (onTap == null) return null;
  if (span.extra case <String, Object?>{'url': String url}) {
    return TapGestureRecognizer()
      ..onTap = () {
        onTap(span.extra?['alt']?.toString() ?? span.text, url);
      };
  }
  return null;
}

/// Helper function to create a [TextSpan] from markdown spans.
/// This function filters the spans based on the theme's span filter,
/// and applies the appropriate text style to each span.
TextSpan _paragraphFromMarkdownSpans({
  required Iterable<MD$Span> spans,
  required MarkdownThemeData theme,
  TextStyle? textStyle,
}) {
  final style = textStyle ?? theme.textStyle;
  final spanFilter = theme.spanFilter;
  final filtered = spanFilter != null ? spans.where(spanFilter) : spans;
  final mapper = textStyle != null
      ? (MD$Span span) {
          return TextSpan(
            text: span.text,
            style: theme.textStyleFor(span.style).merge(style),
            recognizer: span.style.contains(MD$Style.link)
                ? _buildTapRecognizer(span, theme.onLinkTap)
                : null,
          );
        }
      : (MD$Span span) {
          return TextSpan(
            text: span.text,
            style: theme.textStyleFor(span.style),
            recognizer: span.style.contains(MD$Style.link)
                ? _buildTapRecognizer(span, theme.onLinkTap)
                : null,
          );
        };
  return TextSpan(
    style: textStyle ?? theme.textStyle,
    children: filtered.map<InlineSpan>(mapper).toList(growable: false),
  );
}

/// A class for painting blocks in markdown.
/// You can implement this interface to create custom block painters.
abstract interface class BlockPainter {
  /// The current size of the block.
  /// Available only after [layout].
  abstract final Size size;

  /// Handle tap pointer down events for the block.
  void handleTapDown(PointerDownEvent event);

  /// Handle tap pointer up events for the block.
  void handleTapUp(PointerUpEvent event);

  /// Measure the block size with the given width.
  Size layout(double width);

  /// Paint the block on the canvas at the given offset.
  /// [canvas] is the canvas to paint on
  /// [size] the whole size of the markdown content
  /// [offset] is the vertical offset to paint the block at
  void paint(Canvas canvas, Size size, double offset);

  /// Dispose all resources used by the painter.
  void dispose();
}

@meta.internal
mixin ParagraphGestureHandler {
  /// Handle tap events with a [TextPainter].
  @protected
  InlineSpan? hitTestInlineSpanWithPointerEvent(
      PointerEvent event, TextPainter painter) {
    final pos = painter.getPositionForOffset(event.localPosition);
    //final int index = pos.offset;
    final span = painter.text?.getSpanForPosition(pos);
    //final plainText = span?.toPlainText();
    //print('[${pos.offset}] $plainText');
    return span;
  }
}

/// A class for painting a paragraph block in markdown.
@meta.internal
class BlockPainter$Paragraph
    with ParagraphGestureHandler
    implements BlockPainter {
  BlockPainter$Paragraph({
    required List<MD$Span> spans,
    required this.theme,
  }) : painter = TextPainter(
          text: _paragraphFromMarkdownSpans(
            spans: spans,
            theme: theme,
          ),
          textAlign: TextAlign.start,
          textDirection: theme.textDirection,
          textScaler: theme.textScaler,
        );

  final MarkdownThemeData theme;

  final TextPainter painter;

  @override
  Size get size => _size;
  Size _size = Size.zero;

  /// Last span hit by the tap down event.
  TextSpan? _lastSpan;

  @override
  void handleTapDown(PointerDownEvent event) {
    _lastSpan = null; // Reset the span on tap down.
    final span = hitTestInlineSpanWithPointerEvent(event, painter);
    if (span case TextSpan textSpan) _lastSpan = textSpan;
  }

  @override
  void handleTapUp(PointerUpEvent event) {
    if (_lastSpan == null) return; // No span was hit on tap down.
    final span = hitTestInlineSpanWithPointerEvent(event, painter);
    if (span != null && _lastSpan == span) {
      // If the span is the same as the one hit on tap down,
      // call the tap recognizer.
      if (span case TextSpan(recognizer: TapGestureRecognizer(:var onTap)))
        onTap?.call();
    }
    _lastSpan = null; // Clear the span after handling the tap.
  }

  @override
  Size layout(double width) {
    painter.layout(
      minWidth: 0,
      maxWidth: width,
    );
    return _size = painter.size;
  }

  @override
  void paint(Canvas canvas, Size size, double offset) {
    // If the width is less than required do not paint anything.
    if (size.width < _size.width) return;
    painter.paint(
      canvas,
      Offset(0, offset),
    );
  }

  @override
  void dispose() {
    painter.dispose();
  }
}

/// A class for painting a paragraph block in markdown.
@meta.internal
class BlockPainter$Heading
    with ParagraphGestureHandler
    implements BlockPainter {
  BlockPainter$Heading({
    required int level,
    required List<MD$Span> spans,
    required this.theme,
  }) : painter = TextPainter(
          text: _paragraphFromMarkdownSpans(
            spans: spans,
            theme: theme,
            textStyle: theme.headingStyleFor(level),
          ),
          textAlign: TextAlign.start,
          textDirection: theme.textDirection,
          textScaler: theme.textScaler,
        );

  final MarkdownThemeData theme;

  final TextPainter painter;

  @override
  Size get size => _size;
  Size _size = Size.zero;

  /// Last span hit by the tap down event.
  TextSpan? _lastSpan;

  @override
  void handleTapDown(PointerDownEvent event) {
    _lastSpan = null; // Reset the span on tap down.
    final span = hitTestInlineSpanWithPointerEvent(event, painter);
    if (span case TextSpan textSpan) _lastSpan = textSpan;
  }

  @override
  void handleTapUp(PointerUpEvent event) {
    if (_lastSpan == null) return; // No span was hit on tap down.
    final span = hitTestInlineSpanWithPointerEvent(event, painter);
    if (span != null && _lastSpan == span) {
      // If the span is the same as the one hit on tap down,
      // call the tap recognizer.
      if (span case TextSpan(recognizer: TapGestureRecognizer(:var onTap)))
        onTap?.call();
    }
    _lastSpan = null; // Clear the span after handling the tap.
  }

  @override
  Size layout(double width) {
    painter.layout(
      minWidth: 0,
      maxWidth: width,
    );
    return _size = painter.size;
  }

  @override
  void paint(Canvas canvas, Size size, double offset) {
    // If the width is less than required do not paint anything.
    if (size.width < _size.width) return;
    painter.paint(
      canvas,
      Offset(0, offset),
    );
  }

  @override
  void dispose() {
    painter.dispose();
  }
}

/// A class for painting a quote block in markdown.
@meta.internal
class BlockPainter$Quote with ParagraphGestureHandler implements BlockPainter {
  BlockPainter$Quote({
    required List<MD$Span> spans,
    required this.indent,
    required this.theme,
  })  : painter = TextPainter(
          text: _paragraphFromMarkdownSpans(
            spans: spans,
            theme: theme,
            textStyle: theme.quoteStyle ?? theme.textStyle,
          ),
          textAlign: TextAlign.start,
          textDirection: theme.textDirection,
          textScaler: theme.textScaler,
        ),
        linePaint = Paint()
          ..color = theme.dividerColor ??
              const Color(0x7F7F7F7F) // Gray color for the line.
          ..isAntiAlias = false
          ..strokeWidth = 4.0
          ..style = PaintingStyle.fill;

  final MarkdownThemeData theme;

  final TextPainter painter;

  final int indent; // Indentation for quote blocks.

  static const double lineIndent = 10.0; // Indentation for quote blocks.

  final Paint linePaint;

  @override
  Size get size => _size;
  Size _size = Size.zero;

  /// Last span hit by the tap down event.
  TextSpan? _lastSpan;

  @override
  void handleTapDown(PointerDownEvent event) {
    _lastSpan = null; // Reset the span on tap down.
    final span = hitTestInlineSpanWithPointerEvent(event, painter);
    if (span case TextSpan textSpan) _lastSpan = textSpan;
  }

  @override
  void handleTapUp(PointerUpEvent event) {
    if (_lastSpan == null) return; // No span was hit on tap down.
    final span = hitTestInlineSpanWithPointerEvent(event, painter);
    if (span != null && _lastSpan == span) {
      // If the span is the same as the one hit on tap down,
      // call the tap recognizer.
      if (span case TextSpan(recognizer: TapGestureRecognizer(:var onTap)))
        onTap?.call();
    }
    _lastSpan = null; // Clear the span after handling the tap.
  }

  @override
  Size layout(double width) {
    // Adjust width for indentation.
    painter.layout(
      minWidth: 0,
      maxWidth: math.max(width - lineIndent - indent * lineIndent, 0),
    );
    return _size = Size(
      painter.size.width + lineIndent + indent * lineIndent,
      painter.size.height,
    );
  }

  @override
  void paint(Canvas canvas, Size size, double offset) {
    // If the width is less than required do not paint anything.
    if (size.width < _size.width) return;

    // --- Draw vertical lines --- //
    for (var i = 1; i <= indent; i++)
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

    painter.paint(
      canvas,
      Offset(
        lineIndent + indent * lineIndent,
        offset,
      ),
    );
  }

  @override
  void dispose() {
    painter.dispose();
  }
}

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
@meta.internal
class BlockPainter$List with ParagraphGestureHandler implements BlockPainter {
  BlockPainter$List({
    required List<MD$ListItem> items,
    required this.theme,
  })  : _items = items,
        _painters = <_ListItemMetrics>[];

  final MarkdownThemeData theme;
  final List<MD$ListItem> _items;
  final List<_ListItemMetrics> _painters;

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
        final bulletPainter = TextPainter(
          text: TextSpan(
              text: '${switch (item.marker) {
                '-' => '•',
                '*' => '•',
                '+' => '•',
                _ => item.marker,
              }} ',
              style: theme.textStyle),
          textDirection: theme.textDirection,
          textScaler: theme.textScaler,
        )..layout();

        final contentPainter = TextPainter(
          text: _paragraphFromMarkdownSpans(spans: item.spans, theme: theme),
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
    return _size = Size(maxContentWidth, currentHeight);
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
  }
}

/// A class for painting a spacer block in markdown.
@meta.internal
class BlockPainter$Spacer implements BlockPainter {
  BlockPainter$Spacer({
    required this.count,
    required this.theme,
  });

  final int count;

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

/// A class for painting a spacer block in markdown.
@meta.internal
class BlockPainter$Divider implements BlockPainter {
  BlockPainter$Divider({
    required this.theme,
  }) : _paint = Paint()
          ..color = theme.textStyle.color ?? const Color(0xFF000000)
          ..isAntiAlias = false
          ..strokeWidth = 1.0
          ..style = PaintingStyle.fill;

  final Paint _paint;
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

/// A class for painting a code block in markdown.
@meta.internal
class BlockPainter$Code implements BlockPainter {
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

  static const double padding = 8.0; // Padding for code blocks.

  final MarkdownThemeData theme;

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

/// A class for painting a table block in markdown.
@meta.internal
class BlockPainter$Table with ParagraphGestureHandler implements BlockPainter {
  BlockPainter$Table({
    required this.header,
    required this.rows,
    required this.theme,
  })  : columns = header.cells.length,
        _columnWidths = List<double>.filled(header.cells.length, 0.0),
        _rowHeights = List<double>.filled(rows.length + 1, 0.0),
        _borderPaint = Paint()
          ..color = theme.dividerColor ?? const Color(0x1F000000)
          ..style = PaintingStyle.stroke
          ..isAntiAlias = false
          ..strokeWidth = 1.0,
        _rowBackgroundPaint = Paint()
          ..style = PaintingStyle.fill
          ..isAntiAlias = false
          ..color =
              theme.surfaceColor ?? const Color.fromARGB(255, 235, 235, 235);

  /// Padding for table cells.
  static const double padding = 8.0;

  /// The theme for the markdown table.
  final MarkdownThemeData theme;

  /// The number of columns in the table.
  final int columns;

  final List<double> _columnWidths;
  final List<double> _rowHeights;
  final Paint _borderPaint;
  final Paint _rowBackgroundPaint;

  Float32List? _borderPoints;

  /// The header row of the table.
  final MD$TableRow header;

  /// The rows of the table.
  final List<MD$TableRow> rows;

  @override
  Size get size => _size;
  Size _size = Size.zero;

  List<List<TextPainter>> _cellPainters = const [];

  /// Last span hit by the tap down event.
  TextSpan? _lastSpan;

  @override
  void handleTapDown(PointerDownEvent event) {
    _lastSpan = null; // Reset the span on tap down.
    final span = _getSpanForOffset(event.localPosition);
    if (span != null) {
      _lastSpan = span;
    }
  }

  @override
  void handleTapUp(PointerUpEvent event) {
    if (_lastSpan == null) return; // No span was hit on tap down.
    final span = _getSpanForOffset(event.localPosition);
    if (span != null && _lastSpan == span) {
      // If the span is the same as the one hit on tap down,
      // call the tap recognizer.
      if (span case TextSpan(recognizer: TapGestureRecognizer(:var onTap)))
        onTap?.call();
    }
    _lastSpan = null; // Clear the span after handling the tap.
  }

  TextSpan? _getSpanForOffset(Offset position) {
    final rowHeights =
        List.generate(_cellPainters.length, (r) => _rowHeights[r]);

    double currentY = 0.0;

    for (int r = 0; r < _cellPainters.length; r++) {
      final rowHeight = rowHeights[r];
      double currentX = 0.0;

      if (position.dy >= currentY && position.dy < currentY + rowHeight) {
        // In this row.
        for (int c = 0; c < _cellPainters[r].length; c++) {
          final painter = _cellPainters[r][c];
          if (painter.text == null) {
            currentX += _columnWidths[c];
            continue;
          }
          final columnWidth = _columnWidths[c];

          if (position.dx >= currentX && position.dx < currentX + columnWidth) {
            // In this cell.
            final verticalPadding = (rowHeight - painter.height) / 2;
            final horizontalPadding =
                (r == 0) ? (columnWidth - painter.width) / 2 : padding;

            final painterOffset = Offset(
                currentX + horizontalPadding, currentY + verticalPadding);
            final localPosition = position - painterOffset;

            // Check if inside the actual painted text area.
            if (localPosition.dx < 0 ||
                localPosition.dx > painter.width ||
                localPosition.dy < 0 ||
                localPosition.dy > painter.height) {
              currentX += columnWidth;
              continue;
            }

            final textPosition = painter.getPositionForOffset(localPosition);
            final span = painter.text!.getSpanForPosition(textPosition);
            if (span is TextSpan) {
              return span;
            }
            return null; // Found cell, but no span.
          }
          currentX += columnWidth;
        }
      }
      currentY += rowHeight;
    }
    return null;
  }

  @override
  Size layout(double width) {
    if (columns < 1) return _size = Size.zero;

    // Dispose old painters
    for (final row in _cellPainters) {
      for (final painter in row) {
        painter.dispose();
      }
    }

    final allRows = [header, ...rows];
    final naturalWidths = List<double>.filled(columns, 0.0);
    final minWidths = List<double>.filled(columns, 0.0);

    // Create painters for each row and column and calculate natural widths
    _cellPainters = List.generate(allRows.length, (r) {
      final row = allRows[r];
      return List.generate(columns, (c) {
        if (c >= row.cells.length) {
          return TextPainter(textDirection: theme.textDirection);
        }
        final cell = row.cells[c];
        final style = (r == 0)
            ? theme.textStyle.copyWith(fontWeight: FontWeight.bold)
            : null;
        final textPainter = TextPainter(
          text: _paragraphFromMarkdownSpans(
              spans: cell, theme: theme, textStyle: style),
          textAlign: (r == 0) ? TextAlign.center : TextAlign.start,
          textDirection: theme.textDirection,
          textScaler: theme.textScaler,
        );

        // Calculate natural width
        textPainter.layout(maxWidth: double.infinity);
        naturalWidths[c] =
            math.max(naturalWidths[c], textPainter.width + padding * 2);

        // Calculate min width (longest word)
        final cellText = cell.map((s) => s.text).join();
        final words = cellText.split(RegExp(r'\s+'));
        if (words.isNotEmpty) {
          final longestWord =
              words.reduce((a, b) => a.length > b.length ? a : b);
          final wordPainter = TextPainter(
            text: TextSpan(text: longestWord, style: style),
            textDirection: theme.textDirection,
          )..layout();
          minWidths[c] =
              math.max(minWidths[c], wordPainter.width + padding * 2);
          wordPainter.dispose();
        }

        return textPainter;
      });
    });

    _columnWidths.setAll(0, _distributeWidths(naturalWidths, minWidths, width));

    final totalWidth = _columnWidths.reduce((a, b) => a + b);

    // Layout painters with final widths and calculate row heights

    double totalHeight = 0.0;
    for (int r = 0; r < allRows.length; r++) {
      double rowHeight = 0.0;
      for (int c = 0; c < columns; c++) {
        final painter = _cellPainters[r][c];
        if (painter.text == null) continue;
        painter.layout(maxWidth: math.max(0.0, _columnWidths[c] - padding * 2));
        rowHeight = math.max(
          rowHeight,
          painter.height,
        );
      }

      _rowHeights[r] = rowHeight + padding * 2;
      totalHeight += _rowHeights[r];
    }

    // Cache border points
    final points = Float32List(((allRows.length - 1) + (columns - 1)) * 4);
    var pointIndex = 0;
    // Horizontal lines
    double lineY = 0;
    for (int r = 0; r < allRows.length - 1; r++) {
      lineY += _rowHeights[r];
      points[pointIndex++] = 0;
      points[pointIndex++] = lineY;
      points[pointIndex++] = totalWidth;
      points[pointIndex++] = lineY;
    }
    // Vertical lines
    double lineX = 0;
    for (int c = 0; c < columns - 1; c++) {
      lineX += _columnWidths[c];
      points[pointIndex++] = lineX;
      points[pointIndex++] = 0;
      points[pointIndex++] = lineX;
      points[pointIndex++] = totalHeight;
    }
    _borderPoints = points;

    return _size = Size(totalWidth, totalHeight);
  }

  @override
  void paint(Canvas canvas, Size size, double offset) {
    // If the width is less than required do not paint anything.
    if (columns < 1) return;

    double currentY = offset;
    final rowHeights =
        List.generate(_cellPainters.length, (r) => _rowHeights[r]);

    for (int r = 0; r < _cellPainters.length; r++) {
      double currentX = 0;

      // Draw background for even data rows.
      if (r % 2 == 0 && r != 0) {
        canvas.drawRect(
          Rect.fromLTWH(0, currentY, _size.width, rowHeights[r]),
          _rowBackgroundPaint,
        );
      }

      for (int c = 0; c < columns; c++) {
        final painter = _cellPainters[r][c];
        if (painter.text == null) {
          currentX += _cellPainters[r].length > c ? _columnWidths[c] : 0;
          continue;
        }

        final verticalPadding = (rowHeights[r] - painter.height) / 2;
        final horizontalPadding = (r == 0)
            ? (_columnWidths[c] - painter.width) / 2 // Center for header rows
            : padding; // Left align for data rows

        painter.paint(
          canvas,
          Offset(
            currentX + horizontalPadding,
            currentY + verticalPadding,
          ),
        );
        currentX += _columnWidths[c];
      }
      currentY += rowHeights[r];
    }

    // Draw inner borders
    if (_borderPoints != null) {
      canvas.save();
      canvas.translate(0, offset);
      canvas.drawRawPoints(PointMode.lines, _borderPoints!, _borderPaint);
      canvas.restore();
    }

    // Draw outer borders
    canvas.drawRect(
      Rect.fromLTRB(
        0,
        offset,
        _size.width,
        offset + _size.height,
      ),
      _borderPaint,
    );
  }

  @override
  void dispose() {
    for (final row in _cellPainters) {
      for (final painter in row) {
        painter.dispose();
      }
    }
    _cellPainters = const [];
  }

  /// Helper function to distribute widths among columns, respecting minimums.
  /// If total minimum width exceeds availableWidth,
  /// it returns the minimum widths as-is,
  /// implying that the content will overflow and require scrolling.
  List<double> _distributeWidths(
      List<double> natural, List<double> min, double availableWidth) {
    final totalNatural = natural.reduce((a, b) => a + b);
    final totalMin = min.reduce((a, b) => a + b);

    if (totalNatural <= availableWidth) {
      return natural;
    }

    if (totalMin <= availableWidth) {
      final remainingSpace = availableWidth - totalMin;
      final extraSpacePerColumn = [
        for (var i = 0; i < natural.length; i++) natural[i] - min[i]
      ];
      final totalExtraSpace = extraSpacePerColumn.reduce((a, b) => a + b);

      if (totalExtraSpace <= 0.001) return min;

      return [
        for (var i = 0; i < natural.length; i++)
          min[i] + remainingSpace * (extraSpacePerColumn[i] / totalExtraSpace)
      ];
    }
    return min;
  }
}
