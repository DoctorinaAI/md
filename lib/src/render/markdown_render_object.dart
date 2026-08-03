//ignore_for_file: unnecessary_import

import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show MouseTrackerAnnotation;
import 'package:meta/meta.dart' as meta show internal;

import '../markdown.dart';
import '../selection.dart';
import '../theme.dart';
import 'markdown_painter.dart';

/// Default color used to paint the selection highlight over the glyphs.
const Color _kSelectionColor = Color(0x552196F3);

@meta.internal
class MarkdownRenderObject extends RenderBox
    implements MarkdownSelectionSurface, MouseTrackerAnnotation {
  MarkdownRenderObject({
    required Markdown markdown,
    required MarkdownThemeData theme,
  }) : _painter = MarkdownPainter(
          markdown: markdown,
          theme: theme,
        );

  /// Painter for rendering markdown content.
  final MarkdownPainter _painter;

  /// The selection controller this render object participates in, if any.
  MarkdownSelectionController? _controller;

  /// The stable document id used to anchor selection positions.
  Object? _documentId;

  final Paint _highlightPaint = Paint()..color = _kSelectionColor;

  // Selection-handle leader layers pushed during paint so native handles
  // (drawn by the scope's SelectionOverlay) follow the content as it scrolls.
  LayerLink? _startHandleLink;
  Offset? _startHandleLocal;
  LayerLink? _endHandleLink;
  Offset? _endHandleLocal;

  void _onSelectionChange() {
    if (!_disposed) markNeedsPaint();
  }

  bool _disposed = false;

  void _attachController() {
    final controller = _controller;
    if (controller == null) return;
    controller.addListener(_onSelectionChange);
    if (attached) controller.attachSurface(this);
  }

  void _detachController() {
    final controller = _controller;
    if (controller == null) return;
    controller.removeListener(_onSelectionChange);
    controller.detachSurface(this);
  }

  /// Wires (or rewires) this render object to a selection [controller] under
  /// [documentId]. Passing a null controller makes it non-selectable (inert).
  @meta.internal
  void updateSelection(
    MarkdownSelectionController? controller,
    Object? documentId,
  ) {
    if (identical(controller, _controller) && documentId == _documentId) return;
    _detachController();
    _controller = controller;
    _documentId = documentId;
    _attachController();
    if (attached) {
      markNeedsCompositingBitsUpdate();
      markNeedsPaint();
    }
  }

  // --- MarkdownSelectionSurface ---

  @override
  Object get documentId => _documentId!;

  @override
  Rect get globalBounds => localToGlobal(Offset.zero) & size;

  @override
  MarkdownPosition? positionForGlobal(Offset globalPosition) {
    final id = _documentId;
    if (id == null) return null;
    final local = globalToLocal(globalPosition);
    final hit = _painter.positionForLocal(local);
    if (hit == null) return null;
    return MarkdownPosition(
      documentId: id,
      blockIndex: hit.$1,
      offset: hit.$2,
    );
  }

  @override
  (int, int, int)? wordBoundaryForGlobal(Offset globalPosition) {
    if (_documentId == null) return null;
    final wb = _painter.wordBoundaryForLocal(globalToLocal(globalPosition));
    if (wb == null) return null;
    return (wb.$1, wb.$2.start, wb.$2.end);
  }

  @override
  List<Rect> globalSelectionRects() {
    final local = localSelectionRects();
    if (local.isEmpty) return const <Rect>[];
    final origin = localToGlobal(Offset.zero);
    return <Rect>[for (final rect in local) rect.shift(origin)];
  }

  @override
  List<Rect> localSelectionRects() {
    final controller = _controller;
    final id = _documentId;
    if (controller == null || id == null) return const <Rect>[];
    return _painter.selectionBoxes((s) => controller.rangeFor(id, s));
  }

  @override
  void setSelectionHandleLayers({
    LayerLink? startLink,
    Offset? startLocal,
    LayerLink? endLink,
    Offset? endLocal,
  }) {
    var changed = false;
    if (!identical(startLink, _startHandleLink) ||
        startLocal != _startHandleLocal) {
      _startHandleLink = startLink;
      _startHandleLocal = startLocal;
      changed = true;
    }
    if (!identical(endLink, _endHandleLink) || endLocal != _endHandleLocal) {
      _endHandleLink = endLink;
      _endHandleLocal = endLocal;
      changed = true;
    }
    if (changed && !_disposed && attached) markNeedsPaint();
  }

  @override
  void repaintSelection() {
    if (!_disposed && attached) markNeedsPaint();
  }

  // --- MouseTrackerAnnotation (I-beam cursor over selectable text) ---

  /// Whether the pointer is currently hovering an actionable link (updated in
  /// [handleEvent]); drives the click (hand) cursor.
  bool _hoverLink = false;

  /// Presents the click (hand) cursor over links, the text (I-beam) cursor
  /// while this document participates in a selection controller (so users see
  /// the content is selectable), and otherwise defers to what is behind it.
  @override
  MouseCursor get cursor {
    if (_hoverLink) return SystemMouseCursors.click;
    return _controller != null ? SystemMouseCursors.text : MouseCursor.defer;
  }

  @override
  void Function(PointerEnterEvent)? get onEnter => null;

  @override
  void Function(PointerExitEvent)? get onExit => null;

  @override
  bool get validForMouseTracker => !_disposed && attached;

  /// Current size of the render box.
  @override
  Size get size => _size;
  Size _size = Size.zero;

  @override
  bool get isRepaintBoundary => _controller != null;

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
    // Track hover so the cursor can switch to the hand over links. A repaint is
    // what prompts MouseTracker to re-read [cursor] (same mechanism as
    // RenderMouseRegion); we only repaint when the link state actually flips.
    if (event is PointerHoverEvent) {
      final link = _painter.isLinkAtLocal(event.localPosition);
      if (link != _hoverLink) {
        _hoverLink = link;
        if (!_disposed && attached) markNeedsPaint();
      }
    }
    _painter.handleEvent(event);
  }

  /// Handles system font changes by marking the render object as needing layout
  void _handleSystemFontsChange() {
    // Invalidate cached layouts in painter and all block painters
    _painter.invalidateLayout();
    // Request new layout and paint
    markNeedsLayout();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    PaintingBinding.instance.systemFonts.addListener(_handleSystemFontsChange);
    _controller?.attachSurface(this);
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
    PaintingBinding.instance.systemFonts
        .removeListener(_handleSystemFontsChange);
    _controller?.detachSurface(this);
    super.detach();
  }

  @override
  @protected
  void dispose() {
    _disposed = true;
    _controller?.removeListener(_onSelectionChange);
    super.dispose();
    _painter.dispose();
  }

  @override
  @protected
  void paint(PaintingContext context, Offset offset) {
    if (_painter.isEmpty)
      return; // If the markdown is empty, do not paint anything.

    final canvas = context.canvas
      ..save()
      ..translate(offset.dx, offset.dy);
    //..clipRect(Rect.fromLTWH(0, 0, size.width, size.height));

    _painter.paint(canvas, size);

    // Paint the selection highlight OUTSIDE the cached content Picture, but ON
    // TOP of the glyphs, so a translucent highlight stays visible even over
    // opaque block/inline backgrounds (code fences, `inline code`, ==mark==).
    // Still outside the Picture, so drag/streaming repaints never rebuild the
    // glyph cache (the S7 invariant holds).
    final controller = _controller;
    final id = _documentId;
    if (controller != null && id != null) {
      _highlightPaint.color = controller.selectionColor ?? _kSelectionColor;
      _painter.paintHighlight(
        canvas,
        (source) => controller.rangeFor(id, source),
        _highlightPaint,
      );
    }

    canvas.restore();

    // Push handle leader layers (empty layers) so the scope's SelectionOverlay
    // handles follow this content as it scrolls.
    final startLink = _startHandleLink;
    final startLocal = _startHandleLocal;
    if (startLink != null && startLocal != null) {
      context.pushLayer(
        LeaderLayer(link: startLink, offset: offset + startLocal),
        _paintNothing,
        Offset.zero,
      );
    }
    final endLink = _endHandleLink;
    final endLocal = _endHandleLocal;
    if (endLink != null && endLocal != null) {
      context.pushLayer(
        LeaderLayer(link: endLink, offset: offset + endLocal),
        _paintNothing,
        Offset.zero,
      );
    }
  }
}

/// A no-op paint callback for pushing childless [LeaderLayer]s.
void _paintNothing(PaintingContext context, Offset offset) {}
