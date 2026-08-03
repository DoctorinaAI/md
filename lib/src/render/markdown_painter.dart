//ignore_for_file: unnecessary_import

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:meta/meta.dart' as meta show internal;

import '../markdown.dart';
import '../nodes.dart';
import '../theme.dart';
import 'block_painter.dart';
import 'blocks/alert.dart';
import 'blocks/code.dart';
import 'blocks/divider.dart';
import 'blocks/heading.dart';
import 'blocks/list.dart';
import 'blocks/paragraph.dart';
import 'blocks/quote.dart';
import 'blocks/spacer.dart';
import 'blocks/table.dart';

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

  /// Source `Markdown.blocks` index for each painter (differs from the painter
  /// index whenever a `blockFilter` drops blocks).
  List<int> _sourceIndices = const <int>[];

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
          alignments: t.alignments,
          theme: theme,
        ),
        alert: (a) => BlockPainter$Alert(
          alert: a.alert,
          spans: a.spans,
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
    final builder = _theme.builder ?? _defaultBlockBuilder;
    final blocks = _markdown.blocks;
    final painters = <BlockPainter>[];
    final sources = <int>[];
    for (var i = 0; i < blocks.length; i++) {
      final block = blocks[i];
      if (filter != null && !filter(block)) continue;
      painters
          .add(builder(block, _theme) ?? _defaultBlockBuilder(block, _theme));
      sources.add(i);
    }
    _blockPainters = painters;
    _sourceIndices = sources;
    _blockOffsets = Float32List(_blockPainters.length);
  }

  /// Binary-searches the painter index whose vertical band contains [dy].
  int _blockIndexForDy(double dy) {
    var min = 0;
    var max = _blockOffsets.length;
    var idx = 0;
    while (min < max) {
      final mid = min + ((max - min) >> 1);
      final offset = _blockOffsets[mid];
      if (offset > dy) {
        max = mid;
      } else {
        idx = mid;
        if (offset == dy) break;
        min = mid + 1;
      }
    }
    return idx;
  }

  /// Maps a content-local [local] offset to `(sourceBlockIndex, offset)`, or
  /// null if the hit block does not support selection.
  (int, int)? positionForLocal(Offset local) {
    if (_blockPainters.isEmpty) return null;
    final idx = _blockIndexForDy(local.dy);
    final painter = _blockPainters[idx];
    if (painter is! SelectableBlockPainter) return null;
    final blockLocal = Offset(local.dx, local.dy - _blockOffsets[idx]);
    final len = painter.renderedText.length;
    final offset = painter.offsetForLocalPosition(blockLocal).clamp(0, len);
    return (_sourceIndices[idx], offset);
  }

  /// Paints the selection highlight of every selectable block, using [rangeOf]
  /// to look up the selected rendered range for a source block index.
  void paintHighlight(
    Canvas canvas,
    TextRange? Function(int sourceIndex) rangeOf,
    Paint paint,
  ) {
    for (var i = 0; i < _blockPainters.length; i++) {
      final painter = _blockPainters[i];
      if (painter is! SelectableBlockPainter) continue;
      final range = rangeOf(_sourceIndices[i]);
      if (range == null || range.start >= range.end) continue;
      final top = _blockOffsets[i];
      for (final rect in painter.boxesForRange(range.start, range.end)) {
        canvas.drawRect(rect.shift(Offset(0, top)), paint);
      }
    }
  }

  /// Content-local rectangles covering the selection described by [rangeOf], in
  /// reading order. Same geometry [paintHighlight] draws, collected instead of
  /// painted — used to position selection handles, the magnifier and toolbar.
  List<Rect> selectionBoxes(TextRange? Function(int sourceIndex) rangeOf) {
    final out = <Rect>[];
    for (var i = 0; i < _blockPainters.length; i++) {
      final painter = _blockPainters[i];
      if (painter is! SelectableBlockPainter) continue;
      final range = rangeOf(_sourceIndices[i]);
      if (range == null || range.start >= range.end) continue;
      final top = _blockOffsets[i];
      for (final rect in painter.boxesForRange(range.start, range.end)) {
        out.add(rect.shift(Offset(0, top)));
      }
    }
    return out;
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

  /// Invalidate cached layouts when system fonts change.
  /// This forces TextPainters to recreate their layouts with new fonts.
  void invalidateLayout() {
    _needsLayout = true;
    _lastSize = null;
    _lastPicture = null;
    // Dispose and rebuild all block painters to recreate TextPainters
    // with the new system fonts
    for (final painter in _blockPainters) {
      painter.dispose();
    }
    _rebuild();
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

  /// Routes a tap-down / tap-up to the block under the pointer, re-basing the
  /// event's position into that block's local space (only taps are handled; the
  /// block painters use it to fire link recognizers).
  void handleEvent(PointerEvent event) {
    if (_blockPainters.isEmpty) return;
    if (event is! PointerDownEvent && event is! PointerUpEvent) return;

    final pos = event.localPosition;
    final idx = _blockIndexForDy(pos.dy);
    final blockLocal = Offset(pos.dx, pos.dy - _blockOffsets[idx]);
    switch (event) {
      case final PointerDownEvent down:
        _blockPainters[idx].handleTapDown(_rebased(down, blockLocal));
      case final PointerUpEvent up:
        _blockPainters[idx].handleTapUp(_rebased(up, blockLocal));
    }
  }

  /// Copies [event] with its position moved to [localPosition] (block-local),
  /// preserving every other pointer field. `PointerEvent` has no `copyWith`, so
  /// the passthrough is spelled out; the return type follows the input type.
  static T _rebased<T extends PointerEvent>(T event, Offset localPosition) {
    final rebased = switch (event) {
      PointerUpEvent() => PointerUpEvent(
          position: localPosition,
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
        ),
      _ => PointerDownEvent(
          position: localPosition,
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
        ),
    };
    return rebased as T;
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
