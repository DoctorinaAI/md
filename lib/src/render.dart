import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
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
  Size computeDryLayout(BoxConstraints constraints) => constraints.biggest;

  @override
  void performLayout() {
    // Set the size of the render box to match the painter's size.
    size =
        constraints.constrain(_painter.layout(maxWidth: constraints.maxWidth));
  }

  @override
  // ignore: unnecessary_overrides
  void performResize() {
    super.performResize();
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
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {}

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
      ..translate(offset.dx, offset.dy)
      ..clipRect(Rect.fromLTWH(0, 0, size.width, size.height));

    _painter.paint(canvas: canvas);

    // Implement the painting logic here.
    // This is where you would use the painter to draw the markdown content.
    // For example:
    // painter.paint(context, offset, size);
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
        _size = Size.zero;

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

  List<BlockPainter> _blockPainters = const <BlockPainter>[];

  /// Update the painter with new values.
  /// If the values are the same,
  /// no update is required and the method returns false.
  bool update({
    required Markdown markdown,
    required MarkdownThemeData theme,
  }) {
    if (identical(_markdown, markdown) && identical(_theme, theme))
      return false;
    _markdown = markdown;
    _theme = theme;
    _isEmpty = markdown.isEmpty;
    _blockPainters = _markdown.blocks
        .map<BlockPainter>(
          (b) => b.map(
            paragraph: (p) => BlockPainter$Paragraph(
              spans: p.spans,
              theme: _theme,
            ),
            heading: (h) => BlockPainter$Spacer(
              count: h.level,
              theme: _theme,
            ),
            quote: (q) => BlockPainter$Spacer(
              count: 1,
              theme: _theme,
            ),
            code: (c) => BlockPainter$Spacer(
              count: 1,
              theme: _theme,
            ),
            list: (l) => BlockPainter$Spacer(
              count: 1,
              theme: _theme,
            ),
            divider: (d) => BlockPainter$Spacer(
              count: 1,
              theme: _theme,
            ),
            table: (t) => BlockPainter$Spacer(
              count: 1,
              theme: _theme,
            ),
            spacer: (s) => BlockPainter$Spacer(
              count: 1,
              theme: _theme,
            ),
          ),
        )
        .toList(growable: false);
    return true; // Indicate that the painter was updated.
  }

  /// Layouts the markdown content with the given width.
  Size layout({required double maxWidth}) {
    if (_isEmpty) {
      _size = Size.zero;
      return _size; // If the markdown is empty, return zero size.
    }
    var width = .0, height = .0;
    for (var p in _blockPainters) {
      final size = p.layout(maxWidth);
      width = math.max(width, size.width);
      height += size.height;
    }
    return _size = Size(width, height);
  }

  /// The markdown content to paint.
  void paint({required Canvas canvas}) {
    if (_isEmpty) return; // If the markdown is empty, do not paint anything.

    // Paint each block painter on the canvas.
    var offset = .0;
    for (var painter in _blockPainters) {
      painter.paint(canvas, offset);
      offset += painter.size.height; // Update the offset for the next block.
    }
  }
}

/// A class for painting blocks in markdown.
@internal
sealed class BlockPainter {
  const BlockPainter();

  abstract final Size size;

  Size layout(double width);

  void paint(Canvas canvas, double offset);
}

/// A class for painting a paragraph block in markdown.
@internal
class BlockPainter$Paragraph extends BlockPainter {
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

  @override
  Size layout(double width) {
    painter.layout(
      minWidth: 0,
      maxWidth: width,
    );
    return _size = painter.size;
  }

  @override
  void paint(Canvas canvas, double offset) {
    painter.paint(
      canvas,
      Offset(0, offset),
    ); // Paint the text at the given offset.
  }
}

/// A class for painting a spacer block in markdown.
@internal
class BlockPainter$Spacer extends BlockPainter {
  BlockPainter$Spacer({
    required this.count,
    required this.theme,
  });

  final int count;

  final MarkdownThemeData theme;

  @override
  Size get size => _size;
  Size _size = Size.zero;

  final TextPainter painter = TextPainter(
    textAlign: TextAlign.start,
    textDirection: TextDirection.ltr,
    textScaler: TextScaler.noScaling,
  );

  @override
  Size layout(double width) {
    final height = theme.textStyle.fontSize ?? 14.0;
    return _size = Size(0, height * count);
  }

  @override
  void paint(Canvas canvas, double offset) {}
}

TextSpan _paragraphFromMarkdownSpans({
  required List<MD$Span> spans,
  required MarkdownThemeData theme,
}) =>
    TextSpan(
      style: theme.textStyle,
      children: spans
          .map((span) =>
              TextSpan(text: span.text, style: theme.textStyleFor(span.style)))
          .toList(growable: false),
    );
