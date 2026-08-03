// SPIKE S3 — Custom Selectable RenderBox drawing highlight on canvas.
//
// Question: can ONE RenderBox (a LeafRenderObjectWidget, mirroring
// MarkdownRenderObject) implement Selectable + SelectionRegistrant, map a
// pointer drag to RENDERED-text offsets across multiple internal "blocks",
// paint the highlight under its glyphs, and return the selected text WITH
// block separators (natively solving the S1 glue problem, since it is a single
// selectable that controls its own getSelectedContent)?
//
// Each "block" here is a TextPainter, mirroring how MarkdownPainter holds one
// (or more) TextPainter per MD$Block. Throwaway spike; outside lib/ and test/.
//
// Run: flutter test benchmark/experiments/s3_selectable_renderobject_test.dart
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// A logical position inside the render box: which block + rendered-char offset.
class _Pos implements Comparable<_Pos> {
  const _Pos(this.block, this.offset);
  final int block;
  final int offset;
  @override
  int compareTo(_Pos o) =>
      block != o.block ? block.compareTo(o.block) : offset.compareTo(o.offset);
}

class _Block {
  _Block(this.text, TextStyle style)
      : painter = TextPainter(
          text: TextSpan(text: text, style: style),
          textDirection: TextDirection.ltr,
        );
  final String text;
  final TextPainter painter;
  double top = 0;
  double get height => painter.height;
}

const String _blockSeparator = '\n';

class MdSelectableRenderBox extends RenderBox with Selectable, SelectionRegistrant {
  MdSelectableRenderBox(List<String> blocks, TextStyle style)
      : _blocks = [for (final b in blocks) _Block(b, style)];

  final List<_Block> _blocks;

  final List<VoidCallback> _listeners = <VoidCallback>[];
  _Pos? _start;
  _Pos? _end;
  LayerLink? _startHandle;
  LayerLink? _endHandle;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    _listeners.clear();
    super.dispose(); // SelectionRegistrant.dispose -> unregister -> RenderBox
  }

  void _safeMarkNeedsPaint() {
    if (!_disposed) markNeedsPaint();
  }

  SelectionGeometry _geometry =
      const SelectionGeometry(status: SelectionStatus.none, hasContent: true);

  // ---- ValueListenable<SelectionGeometry> ----
  @override
  SelectionGeometry get value => _geometry;
  @override
  void addListener(VoidCallback l) => _listeners.add(l);
  @override
  void removeListener(VoidCallback l) => _listeners.remove(l);
  void _notify() {
    for (final l in List<VoidCallback>.of(_listeners)) l();
  }

  // ---- full-text helpers (rendered text joined with block separators) ----
  (String, List<int>) _fullTextAndBases() {
    final bases = <int>[];
    final buf = StringBuffer();
    var acc = 0;
    for (var i = 0; i < _blocks.length; i++) {
      if (i > 0) {
        buf.write(_blockSeparator);
        acc += _blockSeparator.length;
      }
      bases.add(acc);
      buf.write(_blocks[i].text);
      acc += _blocks[i].text.length;
    }
    return (buf.toString(), bases);
  }

  int _globalOffset(_Pos p, List<int> bases) => bases[p.block] + p.offset;

  @override
  int get contentLength => _fullTextAndBases().$1.length;

  // ---- hit-testing: local offset -> logical position ----
  _Pos _positionForLocal(Offset local) {
    var blockIndex = 0;
    for (var i = 0; i < _blocks.length; i++) {
      if (local.dy >= _blocks[i].top) blockIndex = i;
    }
    final b = _blocks[blockIndex];
    final tp = b.painter.getPositionForOffset(local - Offset(0, b.top));
    final off = tp.offset.clamp(0, b.text.length);
    return _Pos(blockIndex, off);
  }

  // ---- event handling ----
  @override
  SelectionResult dispatchSelectionEvent(SelectionEvent event) {
    switch (event) {
      case final SelectionEdgeUpdateEvent e:
        final local = globalToLocal(e.globalPosition);
        final pos = _positionForLocal(local);
        if (e.type == SelectionEventType.startEdgeUpdate) {
          _start = pos;
        } else {
          _end = pos;
        }
        _start ??= pos;
        _end ??= pos;
        _recompute();
        return SelectionResult.end;
      case ClearSelectionEvent():
        _start = _end = null;
        _recompute();
        return SelectionResult.none;
      case SelectAllSelectionEvent():
        _start = const _Pos(0, 0);
        _end = _Pos(_blocks.length - 1, _blocks.last.text.length);
        _recompute();
        return SelectionResult.end;
      case final SelectWordSelectionEvent e:
        final pos = _positionForLocal(globalToLocal(e.globalPosition));
        final range =
            _blocks[pos.block].painter.getWordBoundary(TextPosition(offset: pos.offset));
        _start = _Pos(pos.block, range.start);
        _end = _Pos(pos.block, range.end);
        _recompute();
        return SelectionResult.end;
      default:
        return SelectionResult.none;
    }
  }

  (_Pos, _Pos) get _ordered =>
      _start!.compareTo(_end!) <= 0 ? (_start!, _end!) : (_end!, _start!);

  // Local selection range within a given block, in that block's char space.
  TextRange? _rangeInBlock(int block, _Pos s, _Pos e) {
    if (block < s.block || block > e.block) return null;
    final start = block == s.block ? s.offset : 0;
    final end = block == e.block ? e.offset : _blocks[block].text.length;
    if (start == end) return null;
    return TextRange(start: start, end: end);
  }

  List<Rect> _selectionRects() {
    if (_start == null || _end == null) return const <Rect>[];
    final (s, e) = _ordered;
    final rects = <Rect>[];
    for (var i = s.block; i <= e.block; i++) {
      final r = _rangeInBlock(i, s, e);
      if (r == null) continue;
      final boxes = _blocks[i].painter.getBoxesForSelection(
            TextSelection(baseOffset: r.start, extentOffset: r.end),
          );
      for (final box in boxes) {
        rects.add(box.toRect().shift(Offset(0, _blocks[i].top)));
      }
    }
    return rects;
  }

  SelectionPoint _pointFor(_Pos p, TextSelectionHandleType type) {
    final b = _blocks[p.block];
    final caret = b.painter.getOffsetForCaret(
      TextPosition(offset: p.offset),
      Rect.zero,
    );
    return SelectionPoint(
      localPosition: caret + Offset(0, b.top + b.painter.preferredLineHeight),
      lineHeight: b.painter.preferredLineHeight,
      handleType: type,
    );
  }

  void _recompute() {
    if (_start == null || _end == null) {
      _geometry =
          const SelectionGeometry(status: SelectionStatus.none, hasContent: true);
    } else {
      final rects = _selectionRects();
      final collapsed = _start!.compareTo(_end!) == 0;
      _geometry = SelectionGeometry(
        startSelectionPoint: _pointFor(_start!, TextSelectionHandleType.left),
        endSelectionPoint: _pointFor(_end!, TextSelectionHandleType.right),
        selectionRects: rects,
        status: collapsed ? SelectionStatus.collapsed : SelectionStatus.uncollapsed,
        hasContent: true,
      );
    }
    _safeMarkNeedsPaint();
    _notify();
  }

  // ---- content extraction ----
  @override
  SelectedContent? getSelectedContent() {
    if (_start == null || _end == null) return null;
    final (full, bases) = _fullTextAndBases();
    final (s, e) = _ordered;
    final a = _globalOffset(s, bases);
    final b = _globalOffset(e, bases);
    if (a == b) return null;
    return SelectedContent(plainText: full.substring(a, b));
  }

  @override
  SelectedContentRange? getSelection() {
    if (_start == null || _end == null) return null;
    final (_, bases) = _fullTextAndBases();
    return SelectedContentRange(
      startOffset: _globalOffset(_start!, bases),
      endOffset: _globalOffset(_end!, bases),
    );
  }

  // ---- geometry required by the delegate ----
  @override
  List<Rect> get boundingBoxes =>
      <Rect>[for (final b in _blocks) Rect.fromLTWH(0, b.top, size.width, b.height)];

  @override
  void pushHandleLayers(LayerLink? startHandle, LayerLink? endHandle) {
    // Real impl pushes LeaderLayers in paint(); the mouse-drag spike doesn't
    // need visible handles, so we just record + repaint. (Handles are S6.)
    _startHandle = startHandle;
    _endHandle = endHandle;
    _safeMarkNeedsPaint();
  }

  // ---- layout / paint ----
  @override
  void performLayout() {
    var y = 0.0, w = 0.0;
    for (final b in _blocks) {
      b.painter.layout(maxWidth: constraints.maxWidth);
      b.top = y;
      y += b.painter.height;
      w = math.max(w, b.painter.width);
    }
    size = constraints.constrain(Size(w, y));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    // 1) highlight UNDER the glyphs
    final rects = _geometry.selectionRects;
    if (rects.isNotEmpty) {
      final paint = Paint()..color = const Color(0x552196F3);
      for (final r in rects) {
        context.canvas.drawRect(r.shift(offset), paint);
      }
    }
    // 2) glyphs
    for (final b in _blocks) {
      b.painter.paint(context.canvas, offset + Offset(0, b.top));
    }
  }
}

class MdSelectableWidget extends LeafRenderObjectWidget {
  const MdSelectableWidget({required this.blocks, required this.style, super.key});
  final List<String> blocks;
  final TextStyle style;

  @override
  MdSelectableRenderBox createRenderObject(BuildContext context) =>
      MdSelectableRenderBox(blocks, style)
        ..registrar = SelectionContainer.maybeOf(context);

  @override
  void updateRenderObject(BuildContext context, MdSelectableRenderBox ro) {
    ro.registrar = SelectionContainer.maybeOf(context);
  }
}

void main() {
  const style = TextStyle(fontSize: 20, color: Color(0xFF000000));

  testWidgets('S3 single selectable box spans blocks with separators', (tester) async {
    String? captured;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SelectionArea(
          onSelectionChanged: (c) => captured = c?.plainText,
          child: const Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 400,
              child: MdSelectableWidget(
                blocks: <String>['Heading', 'Body paragraph', 'Third line'],
                style: style,
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    final box = tester.renderObject<RenderBox>(find.byType(MdSelectableWidget));
    // Exactly one RenderBox for the widget (leaf) — the S1/render tests invariant.
    expect(box, isA<MdSelectableRenderBox>());

    // Drag-select from the very top-left to the bottom-right (everything).
    final topLeft = tester.getTopLeft(find.byType(MdSelectableWidget));
    final bottomRight = tester.getBottomRight(find.byType(MdSelectableWidget));
    final g = await tester.startGesture(topLeft + const Offset(1, 3),
        kind: PointerDeviceKind.mouse);
    await tester.pump(const Duration(milliseconds: 200));
    await g.moveTo(bottomRight - const Offset(1, 3));
    await tester.pump(const Duration(milliseconds: 200));
    await g.up();
    await tester.pumpAndSettle();

    debugPrint('S3 captured = ${captured?.replaceAll('\n', r'\n')}');
    // Glue solved natively: ONE selectable inserts its own separators.
    expect(captured, 'Heading\nBody paragraph\nThird line');
  });

  testWidgets('S3 partial cross-block selection', (tester) async {
    String? captured;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SelectionArea(
          onSelectionChanged: (c) => captured = c?.plainText,
          child: const Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 400,
              child: MdSelectableWidget(
                blocks: <String>['ABCDEF', 'GHIJKL'],
                style: style,
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    // Start mid-first-block, end mid-second-block.
    final box = tester.renderObject<RenderBox>(find.byType(MdSelectableWidget));
    final origin = tester.getTopLeft(find.byType(MdSelectableWidget));
    final half = box.size.height / 2;
    final g = await tester.startGesture(
        origin + Offset(box.size.width * 0.45, half * 0.5),
        kind: PointerDeviceKind.mouse);
    await tester.pump(const Duration(milliseconds: 200));
    await g.moveTo(origin + Offset(box.size.width * 0.55, half * 1.5));
    await tester.pump(const Duration(milliseconds: 200));
    await g.up();
    await tester.pumpAndSettle();

    debugPrint('S3 partial captured = ${captured?.replaceAll('\n', r'\n')}');
    // Whatever the exact chars, the block boundary must carry a separator.
    expect(captured, isNotNull);
    expect(captured, contains('\n'),
        reason: 'cross-block selection carries the block separator');
    // And the selected text is drawn from RENDERED text (letters we laid out).
    expect(captured!.replaceAll('\n', ''), matches(RegExp(r'^[A-L]+$')));
  });
}
