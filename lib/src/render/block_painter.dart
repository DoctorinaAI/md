//ignore_for_file: unnecessary_import

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

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

/// A [BlockPainter] that supports text selection. All coordinates are local to
/// the block's top-left corner (as passed to [paint]'s `offset`).
///
/// The [renderedText] should match [markdownBlockRenderedText] for the same
/// block so that hit-testing, highlighting, and model-side extraction agree on
/// the offset space.
///
/// Caveat: a [MarkdownThemeData.spanFilter] that drops text-bearing spans
/// shifts the painter's offset space relative to the (unfiltered) model, so the
/// on-screen highlight stays correct but copied text may be misaligned. Avoid
/// dropping text-bearing spans when selection is enabled.
abstract interface class SelectableBlockPainter implements BlockPainter {
  /// The block's rendered plain text.
  String get renderedText;

  /// Maps a block-local [local] offset to a rendered-text index.
  int offsetForLocalPosition(Offset local);

  /// Highlight rectangles (block-local) for the rendered range `[start, end)`.
  List<Rect> boxesForRange(int start, int end);

  /// The word range (in rendered-text space) at a block-local [local] point,
  /// using the platform's word segmentation (`TextPainter.getWordBoundary`) so
  /// double-click/tap selects real words (keeping intra-word punctuation such as
  /// apostrophes, matching native text fields).
  TextRange wordBoundaryForLocal(Offset local);

  /// Whether an actionable link (a span carrying a tap recognizer) sits under
  /// the block-local [local] point — used to show the click (hand) cursor.
  bool isLinkAtLocal(Offset local);
}

/// Provides [SelectableBlockPainter] for a block backed by a single
/// [TextPainter]. Subclasses supply [selectionPainter] and, when the glyphs are
/// not painted at the block origin, [selectionOrigin].
mixin SelectableTextBlock implements SelectableBlockPainter {
  /// The text painter that owns the selectable glyphs.
  TextPainter get selectionPainter;

  /// Block-local origin where [selectionPainter] is painted.
  Offset get selectionOrigin => Offset.zero;

  @override
  String get renderedText => selectionPainter.plainText;

  @override
  int offsetForLocalPosition(Offset local) =>
      selectionPainter.getPositionForOffset(local - selectionOrigin).offset;

  @override
  List<Rect> boxesForRange(int start, int end) => selectionPainter
      .getBoxesForSelection(TextSelection(baseOffset: start, extentOffset: end))
      .map((box) => box.toRect().shift(selectionOrigin))
      .toList(growable: false);

  @override
  TextRange wordBoundaryForLocal(Offset local) {
    final offset =
        selectionPainter.getPositionForOffset(local - selectionOrigin).offset;
    return selectionPainter.getWordBoundary(TextPosition(offset: offset));
  }

  @override
  bool isLinkAtLocal(Offset local) =>
      _spanHasRecognizerAt(selectionPainter, local - selectionOrigin);
}

/// One selectable text run inside a multi-painter block (a list item or a table
/// cell): the [painter] that owns its glyphs, the block-local [origin] where it
/// is painted, and the [textStart] index of its text within the block's
/// [markdownBlockRenderedText] linearization.
class SelectableFragment {
  /// Creates a fragment for [painter] painted at [origin], whose text begins at
  /// [textStart] in the block's rendered text.
  SelectableFragment(this.painter, this.origin, this.textStart);

  /// The text painter that owns this run's glyphs.
  final TextPainter painter;

  /// Block-local top-left where [painter] is painted.
  final Offset origin;

  /// Index of this run's first character in the block's rendered text.
  final int textStart;

  /// Length of this run's text.
  int get length => painter.plainText.length;

  /// One-past-the-last index of this run's text in the block's rendered text.
  int get textEnd => textStart + length;
}

/// Provides [SelectableBlockPainter] for a block whose text is spread across
/// several [TextPainter]s painted at different origins (lists, tables).
///
/// [fragments] must be listed in the same order their text appears in
/// [markdownBlockRenderedText], with each fragment's `textStart` matching that
/// linearization (the gaps between fragments are the `\n`/`\t` separators, which
/// have no glyphs of their own). [renderedText] must equal that linearization.
mixin MultiPainterSelectable implements SelectableBlockPainter {
  /// The selectable runs of this block, in rendered-text order. Rebuilt on each
  /// [BlockPainter.layout].
  List<SelectableFragment> get fragments;

  @override
  int offsetForLocalPosition(Offset local) {
    final fragment = _nearestFragment(local);
    if (fragment == null) return 0;
    final inner =
        fragment.painter.getPositionForOffset(local - fragment.origin).offset;
    return fragment.textStart + inner.clamp(0, fragment.length);
  }

  @override
  List<Rect> boxesForRange(int start, int end) {
    final out = <Rect>[];
    for (final fragment in fragments) {
      final localStart = start.clamp(fragment.textStart, fragment.textEnd) -
          fragment.textStart;
      final localEnd =
          end.clamp(fragment.textStart, fragment.textEnd) - fragment.textStart;
      if (localEnd <= localStart) continue;
      final boxes = fragment.painter.getBoxesForSelection(
          TextSelection(baseOffset: localStart, extentOffset: localEnd));
      for (final box in boxes) {
        out.add(box.toRect().shift(fragment.origin));
      }
    }
    return out;
  }

  @override
  TextRange wordBoundaryForLocal(Offset local) {
    final fragment = _nearestFragment(local);
    if (fragment == null) return const TextRange(start: 0, end: 0);
    final inner =
        fragment.painter.getPositionForOffset(local - fragment.origin).offset;
    final wb = fragment.painter.getWordBoundary(TextPosition(offset: inner));
    // Keep the word within its own fragment (never cross a cell/item boundary).
    return TextRange(
      start: fragment.textStart + wb.start.clamp(0, fragment.length),
      end: fragment.textStart + wb.end.clamp(0, fragment.length),
    );
  }

  @override
  bool isLinkAtLocal(Offset local) {
    for (final fragment in fragments) {
      if ((fragment.origin & fragment.painter.size).contains(local)) {
        return _spanHasRecognizerAt(fragment.painter, local - fragment.origin);
      }
    }
    return false;
  }

  SelectableFragment? _nearestFragment(Offset local) {
    SelectableFragment? best;
    var bestDistance = double.infinity;
    for (final fragment in fragments) {
      final distance =
          _distanceToRect(local, fragment.origin & fragment.painter.size);
      if (distance < bestDistance) {
        bestDistance = distance;
        best = fragment;
        if (distance == 0) break;
      }
    }
    return best;
  }
}

/// Whether the span under a text-local [local] point in [painter] carries a tap
/// recognizer (i.e. an actionable link). False for points outside the text box.
bool _spanHasRecognizerAt(TextPainter painter, Offset local) {
  final size = painter.size;
  if (local.dx < 0 ||
      local.dy < 0 ||
      local.dx > size.width ||
      local.dy > size.height) {
    return false;
  }
  final span =
      painter.text?.getSpanForPosition(painter.getPositionForOffset(local));
  return span is TextSpan && span.recognizer != null;
}

/// Shortest distance from [point] to [rect] (0 when the point is inside).
double _distanceToRect(Offset point, Rect rect) {
  final dx = point.dx < rect.left
      ? rect.left - point.dx
      : (point.dx > rect.right ? point.dx - rect.right : 0.0);
  final dy = point.dy < rect.top
      ? rect.top - point.dy
      : (point.dy > rect.bottom ? point.dy - rect.bottom : 0.0);
  if (dx == 0) return dy;
  if (dy == 0) return dx;
  return math.sqrt(dx * dx + dy * dy);
}

/// Mixin for block painters backed by a [TextPainter] that want to fire link
/// (or other) tap recognizers: [hitTestInlineSpanWithPointerEvent] resolves the
/// [InlineSpan] under a pointer so [BlockPainter.handleTapDown] /
/// [BlockPainter.handleTapUp] can match down and up on the same span.
mixin ParagraphGestureHandler {
  /// The [InlineSpan] under [event] within [painter], or null if none.
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
