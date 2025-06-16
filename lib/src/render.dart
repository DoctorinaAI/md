import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:meta/meta.dart';

import 'markdown.dart';
import 'theme.dart';

@internal
class MarkdownRenderObject extends RenderBox {
  MarkdownRenderObject({
    required Markdown markdown,
    required MarkdownThemeData theme,
    required TextPainter painter,
  })  : _painter = painter,
        _theme = theme,
        _markdown = markdown {
    _updateInlineSpans();
  }

  /// Current markdown entity to render.
  Markdown _markdown;

  /// Current theme for the markdown widget.
  MarkdownThemeData _theme;

  /// Text painter used for rendering text.
  final TextPainter _painter;

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

  /// Updates the inline spans in the text painter.
  void _updateInlineSpans() {
    // Update the text painter with the current markdown text.
    _painter.text = TextSpan(
      text: _markdown.text,
      /* style: _theme.textStyle, */
    );
  }

  @override
  @protected
  void debugResetSize() {
    super.debugResetSize();
    if (!super.hasSize) return;
    _size = super.size;
  }

  @override
  @protected
  Size computeDryLayout(BoxConstraints constraints) => constraints.biggest;

  /* @override
  double computeMinIntrinsicWidth(double height) {
    return 0;
  } */

  @override
  void performLayout() {
    // Layout the text painter with the current size.
    _painter
      ..text = TextSpan(text: _markdown.text)
      ..layout(
        minWidth: 0,
        maxWidth: size.width,
      );
    // Set the size of the render box to match the painter's size.
    size = constraints.constrainDimensions(_painter.width, _painter.height);
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
    required TextDirection direction,
    required TextScaler textScaler,
  }) {
    if (identical(_markdown, markdown) &&
        identical(_theme, theme) &&
        identical(_painter.textDirection, direction) &&
        identical(_painter.textScaler, textScaler)) return;
    this
      .._markdown = markdown
      .._theme = theme
      .._painter.textDirection = direction
      .._painter.textScaler = textScaler;
    // Update the inline spans in the text painter.
    _updateInlineSpans();
    // Mark the render object as needing layout.
    markNeedsLayout();
  }

  @override
  @protected
  void detach() {
    super.detach();
  }

  @override
  @protected
  void paint(PaintingContext context, Offset offset) {
    // ignore: unused_local_variable
    final canvas = context.canvas
      ..save()
      ..translate(offset.dx, offset.dy)
      ..clipRect(Rect.fromLTWH(0, 0, size.width, size.height));

    _painter
      ..layout(
        minWidth: 0,
        maxWidth: size.width,
      )
      ..paint(canvas, Offset.zero);

    // Implement the painting logic here.
    // This is where you would use the painter to draw the markdown content.
    // For example:
    // painter.paint(context, offset, size);
    canvas.restore();
  }
}
