import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:meta/meta.dart';

import 'markdown.dart';
import 'nodes.dart';
import 'theme.dart';

@internal
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
  @internal
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
@internal
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
}

@internal
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
@internal
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
}

/// A class for painting a paragraph block in markdown.
@internal
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
}

/// A class for painting a quote block in markdown.
@internal
class BlockPainter$Quote with ParagraphGestureHandler implements BlockPainter {
  BlockPainter$Quote({
    required List<MD$Span> spans,
    required this.indent,
    required this.theme,
  }) : painter = TextPainter(
          text: _paragraphFromMarkdownSpans(
            spans: spans,
            theme: theme,
            textStyle: theme.quoteStyle ?? theme.textStyle,
          ),
          textAlign: TextAlign.start,
          textDirection: theme.textDirection,
          textScaler: theme.textScaler,
        );

  final MarkdownThemeData theme;

  final TextPainter painter;

  final int indent; // Indentation for quote blocks.

  static const double lineIndent = 10.0; // Indentation for quote blocks.

  static final Paint linePaint = Paint()
    ..color = const Color(0x7F7F7F7F) // Gray color for the line.
    ..isAntiAlias = false
    ..strokeWidth = 4.0
    ..style = PaintingStyle.fill;

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

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, offset, size.width, _size.height),
        const Radius.circular(4.0), // Rounded corners for the quote block.
      ),
      Paint()
        ..color = const Color.fromARGB(255, 235, 235, 235)
        ..isAntiAlias = false
        ..style = PaintingStyle.fill,
    );

    {
      // --- Icons.format_quote_outlined --- //
      try {
        const quoteCodePoint = 0xf0a9;
        const quoteFamily = 'MaterialIcons';
        final textStyle = TextStyle(
          fontFamily: quoteFamily,
          fontSize:
              theme.quoteStyle?.fontSize ?? theme.textStyle.fontSize ?? 14.0,
          color: const Color(0xFF7F7F7F), // Gray color for the quote icon.
        );
        final quotePainter = TextPainter(
          text: TextSpan(
            text: String.fromCharCode(quoteCodePoint),
            style: textStyle,
          ),
          textAlign: TextAlign.start,
          textDirection: theme.textDirection,
          textScaler: theme.textScaler,
        )..layout();
        canvas
          ..save()
          ..translate(
            _size.width + quotePainter.width,
            offset + _size.height,
          )
          ..rotate(math.pi);
        quotePainter.paint(
          canvas,
          Offset(
            _size.width,
            _size.height - quotePainter.height,
          ),
        );
        canvas.restore();
        quotePainter.paint(
          canvas,
          Offset(
            size.width - quotePainter.width - 2.0,
            offset + _size.height - quotePainter.height,
          ),
        );
      } on Object {
        for (var i = 1; i <= indent; i++)
          canvas.drawLine(
            Offset(
              i * lineIndent - lineIndent / 2,
              offset + 12,
            ),
            Offset(
              i * lineIndent - lineIndent / 2,
              offset + _size.height - 12,
            ),
            linePaint,
          );
      }
    }

    painter.paint(
      canvas,
      Offset(
        lineIndent + indent * lineIndent,
        offset,
      ),
    );
  }
}

/// A class for painting a list block in markdown.
@internal
class BlockPainter$List with ParagraphGestureHandler implements BlockPainter {
  BlockPainter$List({
    required List<MD$ListItem> items,
    required this.theme,
  }) : painter = TextPainter(
          textAlign: TextAlign.start,
          textDirection: theme.textDirection,
          textScaler: theme.textScaler,
        ) {
    if (items.isEmpty) {
      painter.text = const TextSpan();
    } else {
      final spans = <TextSpan>[];
      drawListSpans(spans: spans, items: items, theme: theme);
      painter.text = TextSpan(children: spans);
    }
  }

  final MarkdownThemeData theme;

  final TextPainter painter;

  static const double indent = 8.0; // Indentation for list blocks.

  /// Create a list of spans from the list items.
  static void drawListSpans({
    required List<TextSpan> spans,
    required List<MD$ListItem> items,
    required MarkdownThemeData theme,
  }) {
    final filter = theme.spanFilter ?? (span) => true;
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final filtered = item.spans.where(filter).toList(growable: false);
      // Skip empty spans
      if (filtered.isEmpty) continue;
      if (spans.isNotEmpty) spans.add(const TextSpan(text: '\n'));
      spans
        ..add(
          TextSpan(
            text: '${' ' * item.indent}${switch (item.marker) {
              '-' => '•',
              '*' => '•',
              '+' => '•',
              _ => item.marker,
            }} ',
            style: theme.textStyle,
          ),
        )
        ..addAll(
          filtered.map<TextSpan>(
            (span) => TextSpan(
              text: span.text,
              style: theme.textStyleFor(span.style),
              recognizer: span.style.contains(MD$Style.link)
                  ? _buildTapRecognizer(span, theme.onLinkTap)
                  : null,
            ),
          ),
        );
      if (item.children.isEmpty) continue;
      drawListSpans(
        spans: spans,
        items: item.children,
        theme: theme,
      ); // Recursively draw children if any.
    }
  }

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
      maxWidth: math.max(width - indent, 0), // Adjust width for indentation.
    );
    return _size = Size(
      painter.size.width + indent, // Add indentation to the width.
      painter.size.height,
    );
  }

  @override
  void paint(Canvas canvas, Size size, double offset) {
    // If the width is less than required do not paint anything.
    if (size.width < _size.width) return;
    painter.paint(
      canvas,
      Offset(indent, offset),
    );
  }
}

/// A class for painting a spacer block in markdown.
@internal
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
    final height = theme.textStyle.fontSize ?? 14.0;
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
}

/// A class for painting a spacer block in markdown.
@internal
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
    final height = theme.textStyle.fontSize ?? 14.0;
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
}

/// A class for painting a code block in markdown.
@internal
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
              fontSize: theme.textStyle.fontSize ?? 14.0,
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
        ..color = const Color.fromARGB(255, 235, 235, 235)
        ..isAntiAlias = false
        ..style = PaintingStyle.fill,
    );
    painter.paint(
      canvas,
      Offset(padding, offset + padding),
    );
  }
}

/// A class for painting a table block in markdown.
@internal
class BlockPainter$Table implements BlockPainter {
  BlockPainter$Table({
    required this.header,
    required this.rows,
    required this.theme,
  })  : columns = header.cells.length,
        painter = TextPainter(
          textAlign: TextAlign.start,
          textDirection: theme.textDirection,
          textScaler: theme.textScaler,
        );

  /// Padding for the table cells.
  static const double padding = 4.0;

  /// The theme for the markdown table.
  final MarkdownThemeData theme;

  /// Text painter for rendering the table content.
  final TextPainter painter;

  /// The number of columns in the table.
  final int columns;

  /// The header row of the table.
  final MD$TableRow header;

  /// The rows of the table.
  final List<MD$TableRow> rows;

  @override
  Size get size => _size;
  Size _size = Size.zero;

  @override
  void handleTapDown(PointerDownEvent _) {/* Do nothing */}

  @override
  void handleTapUp(PointerUpEvent _) {/* Do nothing */}

  @override
  Size layout(double width) {
    if (columns < 1) return _size = Size.zero;
    return _size = Size(
      width, // The width of the table is the same as the available width.
      (header.cells.length + rows.length) *
          ((theme.textStyle.fontSize ?? 14.0) + padding * 2),
    );
  }

  @override
  void paint(Canvas canvas, Size size, double offset) {
    // If the width is less than required do not paint anything.
    if (size.width < _size.width || columns < 1) return;

    // Draw the header row.
    final columnWidth = size.width / columns;
    final cellMaxWidth = columnWidth - padding * 2;
    final rowHeight = (theme.textStyle.fontSize ?? 14.0) + padding * 2;
    canvas.drawRRect(
      RRect.fromLTRBR(
        0, // Left
        offset, // Top
        size.width, // Right
        offset + _size.height, // Bottom
        const Radius.circular(padding), // Radius for rounded corners
      ),
      Paint()
        ..color = const Color.fromARGB(255, 235, 235, 235)
        ..style = PaintingStyle.fill
        ..isAntiAlias = false,
    );

    for (var i = 0; i < columns; i++) {
      final cell = header.cells[i];
      painter
        ..text = TextSpan(
          text: cell.map((span) => span.text).join(),
          style: theme.textStyle.copyWith(
            fontWeight: FontWeight.bold,
          ),
        )
        ..layout(
          minWidth: 0,
          maxWidth: cellMaxWidth,
        );
      painter.paint(
        canvas,
        Offset(
          i * columnWidth + padding,
          offset + rowHeight - padding - painter.height / 2,
        ),
      );
    }

    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      for (var j = 0; j < columns; j++) {
        if (j >= row.cells.length) continue; // Skip if the cell is missing.
        final cell = row.cells[j];
        painter
          ..text = TextSpan(
            text: cell.map((span) => span.text).join(),
            style: theme.textStyle,
          )
          ..layout(
            minWidth: 0,
            maxWidth: cellMaxWidth,
          );
        painter.paint(
          canvas,
          Offset(
            j * columnWidth + padding,
            offset + rowHeight * (i + 2) - painter.height / 2,
          ),
        );
      }
    }
  }
}
