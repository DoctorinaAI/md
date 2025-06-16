import 'package:flutter/rendering.dart';
import 'package:meta/meta.dart';

import 'markdown.dart';
import 'theme.dart';

@internal
class MarkdownRenderObject extends RenderBox {
  MarkdownRenderObject({
    required this.markdown,
    required this.theme,
    required this.painter,
  });

  /// Current markdown entity to render.
  Markdown markdown;

  /// Current theme for the markdown widget.
  MarkdownThemeData theme;

  /// Text painter used for rendering text.
  final TextPainter painter;

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
  @protected
  void debugResetSize() {
    super.debugResetSize();
    if (!super.hasSize) return;
    _size = super.size;
  }

  @override
  @protected
  Size computeDryLayout(BoxConstraints constraints) => constraints.biggest;

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
      ..translate(offset.dx, offset.dy);

    // Implement the painting logic here.
    // This is where you would use the painter to draw the markdown content.
    // For example:
    // painter.paint(context, offset, size);
    canvas.restore();
  }
}
