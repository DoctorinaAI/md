import 'dart:ui';

import 'package:flutter/rendering.dart' show LayerLink;
import 'package:flutter_md/flutter_md.dart';
import 'package:flutter_test/flutter_test.dart';

class _Surf implements MarkdownSelectionSurface {
  _Surf(
    this.documentId,
    this.globalBounds,
    this.locals, {
    this.textDirection = TextDirection.ltr,
  });
  @override
  final Object documentId;
  @override
  final Rect globalBounds;
  final List<Rect> locals;
  @override
  final TextDirection textDirection;
  @override
  MarkdownPosition? positionForGlobal(Offset g) => null;
  @override
  (MarkdownPosition, TextAffinity)? hitForGlobal(Offset g) => null;
  @override
  bool hitsSelectableGlyphs(Offset g) => false;
  @override
  bool isLinkAtGlobal(Offset g) => false;
  @override
  Rect? caretRectFor(MarkdownPosition p, TextAffinity a) =>
      Rect.fromLTWH(p.offset * 10.0, 0, 0, 10);
  @override
  (int, int, int)? wordBoundaryForGlobal(Offset g) => null;
  @override
  List<Rect> globalSelectionRects() =>
      [for (final r in locals) r.shift(globalBounds.topLeft)];
  @override
  List<Rect> localSelectionRects() => locals;
  @override
  List<Rect> localBoxesForRange(int b, int s, int e) => const [];
  @override
  void setSelectionHandleLayers({
    LayerLink? startLink,
    Offset? startLocal,
    LayerLink? endLink,
    Offset? endLocal,
  }) {}
  @override
  bool get hasSelectionHandleLeaders => false;
  @override
  void clearSelectionHandleLayersIfLinked({
    required LayerLink startLink,
    required LayerLink endLink,
  }) {}
  @override
  void repaintSelection() {}
}

MarkdownPosition _p(Object d, int b, int o) =>
    MarkdownPosition(documentId: d, blockIndex: b, offset: o);

void main() {
  group('Selection controller edge cases', () {
    test('reversed selection proxies an unmounted base onto the visible end',
        () {
      final c = MarkdownSelectionController()
        ..setDocuments([
          MarkdownDocumentRef(id: 'a', model: Markdown.fromString('aaaa')),
          MarkdownDocumentRef(id: 'b', model: Markdown.fromString('bbbb')),
          MarkdownDocumentRef(id: 'c', model: Markdown.fromString('cccc')),
        ]);
      // a and b mounted, c (below) scrolled off.
      c
        ..attachSurface(_Surf('a', const Rect.fromLTWH(0, 0, 100, 20),
            [const Rect.fromLTWH(20, 0, 20, 10)]))
        ..attachSurface(_Surf('b', const Rect.fromLTWH(0, 100, 100, 20),
            [const Rect.fromLTWH(0, 0, 40, 10)]));
      // Reversed: base at end (doc c, unmounted), extent at doc a offset 2.
      c.selection =
          MarkdownSelection(base: _p('c', 0, 3), extent: _p('a', 0, 3));
      expect(c.isSelectionReversed, isTrue);
      final e = c.selectionHandleEndpoints()!;
      // Base is the reading END -> should proxy onto doc b (bottom-most
      // visible selection), not onto doc a where the extent handle sits.
      expect(e.startSurface.documentId, 'b');
    });

    test('reconcile dropping the range clears toolbarWanted', () {
      final c = MarkdownSelectionController(
          reconciliation: const MarkdownReconciliationPolicy.clearOnChange())
        ..setDocuments([
          MarkdownDocumentRef(id: 'a', model: Markdown.fromString('hello')),
        ]);
      c.selection =
          MarkdownSelection(base: _p('a', 0, 0), extent: _p('a', 0, 3));
      expect(c.toolbarWanted, isTrue); // android in tests
      c.putDocument('a', Markdown.fromString('hello world'));
      expect(c.selection, isNull);
      expect(c.toolbarWanted, isFalse);
    });

    test('an unrelated document update keeps a caret toolbar', () {
      final c = MarkdownSelectionController()
        ..setDocuments([
          MarkdownDocumentRef(id: 'a', model: Markdown.fromString('hello')),
          MarkdownDocumentRef(id: 'b', model: Markdown.fromString('x')),
        ]);
      c
        ..selection =
            MarkdownSelection(base: _p('a', 0, 2), extent: _p('a', 0, 2))
        ..toolbarWanted = true;
      // Another message streams in: the caret and its menu stay.
      c.putDocument('b', Markdown.fromString('xy'));
      expect(c.selection!.isCollapsed, isTrue);
      expect(c.toolbarWanted, isTrue);
    });

    test('removeDocument dropping the range clears toolbarWanted', () {
      final c = MarkdownSelectionController()
        ..setDocuments([
          MarkdownDocumentRef(id: 'a', model: Markdown.fromString('hello')),
        ]);
      c.selection =
          MarkdownSelection(base: _p('a', 0, 0), extent: _p('a', 0, 3));
      c.removeDocument('a');
      expect(c.selection, isNull);
      expect(c.toolbarWanted, isFalse);
    });

    test('selectAll skips a trailing empty document', () {
      final c = MarkdownSelectionController()
        ..setDocuments([
          MarkdownDocumentRef(id: 'a', model: Markdown.fromString('hello')),
          MarkdownDocumentRef(id: 'b', model: Markdown.fromString('')),
        ]);
      expect(c.documents.last.model.blocks, isEmpty);
      c.selectAll();
      expect(c.getText(), 'hello');
    });

    test('an identical commit does not notify', () {
      final c = MarkdownSelectionController()
        ..setDocuments([
          MarkdownDocumentRef(id: 'a', model: Markdown.fromString('hello')),
        ]);
      c.extendTo(_p('a', 0, 3));
      var n = 0;
      c.addListener(() => n++);
      for (var i = 0; i < 10; i++) {
        c.extendTo(_p('a', 0, 3));
      }
      expect(n, 0);
    });

    test('reconcile collapsing the range clears toolbarWanted', () {
      final c = MarkdownSelectionController()
        ..setDocuments([
          MarkdownDocumentRef(
              id: 'a', model: Markdown.fromString('hello world')),
        ]);
      c.selection =
          MarkdownSelection(base: _p('a', 0, 8), extent: _p('a', 0, 10));
      c.putDocument('a', Markdown.fromString('hello'));
      expect(c.selection!.isCollapsed, isTrue);
      expect(c.toolbarWanted, isFalse);
    });

    test('content anchor prefers the nearest duplicate block', () {
      final c = MarkdownSelectionController()
        ..setDocuments([
          MarkdownDocumentRef(
              id: 'a', model: Markdown.fromString('Yes\n\nfoo\n\nYes')),
        ]);
      // Blocks: 0 Yes, 1 spacer, 2 foo, 3 spacer, 4 Yes. Select last "Yes".
      c.selection =
          MarkdownSelection(base: _p('a', 4, 0), extent: _p('a', 4, 3));
      // Edit the middle block (not an append).
      c.putDocument('a', Markdown.fromString('Yes\n\nbar baz\n\nYes'));
      expect(c.selection!.base.blockIndex, 4);
      expect(c.selection!.extent.blockIndex, 4);
    });

    test('reversed RTL selection proxies an unmounted base onto the end', () {
      final c = MarkdownSelectionController()
        ..setDocuments([
          MarkdownDocumentRef(id: 'a', model: Markdown.fromString('aaaa')),
          MarkdownDocumentRef(id: 'b', model: Markdown.fromString('bbbb')),
          MarkdownDocumentRef(id: 'c', model: Markdown.fromString('cccc')),
        ]);
      c
        ..attachSurface(_Surf('a', const Rect.fromLTWH(0, 0, 100, 20),
            [const Rect.fromLTWH(20, 0, 20, 10)],
            textDirection: TextDirection.rtl))
        ..attachSurface(_Surf('b', const Rect.fromLTWH(0, 100, 100, 20),
            [const Rect.fromLTWH(0, 0, 40, 10)],
            textDirection: TextDirection.rtl));
      c.selection =
          MarkdownSelection(base: _p('c', 0, 3), extent: _p('a', 0, 3));
      final e = c.selectionHandleEndpoints()!;
      expect(e.startSurface.documentId, 'b');
      expect(e.endSurface.documentId, 'a');
    });

    test('forward selection proxies an unmounted extent onto the end', () {
      final c = MarkdownSelectionController()
        ..setDocuments([
          MarkdownDocumentRef(id: 'a', model: Markdown.fromString('aaaa')),
          MarkdownDocumentRef(id: 'b', model: Markdown.fromString('bbbb')),
          MarkdownDocumentRef(id: 'c', model: Markdown.fromString('cccc')),
        ]);
      c
        ..attachSurface(_Surf('a', const Rect.fromLTWH(0, 0, 100, 20),
            [const Rect.fromLTWH(20, 0, 20, 10)]))
        ..attachSurface(_Surf('b', const Rect.fromLTWH(0, 100, 100, 20),
            [const Rect.fromLTWH(0, 0, 40, 10)]));
      c.selection =
          MarkdownSelection(base: _p('a', 0, 2), extent: _p('c', 0, 3));
      final e = c.selectionHandleEndpoints()!;
      expect(e.startSurface.documentId, 'a');
      expect(e.endSurface.documentId, 'b');
    });

    test('a repeated selectAll notifies again', () {
      final c = MarkdownSelectionController()
        ..setDocuments([
          MarkdownDocumentRef(id: 'a', model: Markdown.fromString('hello')),
        ]);
      c.selectAll();
      var n = 0;
      c.addListener(() => n++);
      c.selectAll();
      expect(n, 1);
    });

    test('an affinity-only commit notifies', () {
      final c = MarkdownSelectionController()
        ..setDocuments([
          MarkdownDocumentRef(id: 'a', model: Markdown.fromString('hello')),
        ]);
      c.selectAll();
      var n = 0;
      c.addListener(() => n++);
      c.extendTo(_p('a', 0, 5), affinity: TextAffinity.downstream);
      expect(n, 1);
    });

    test('selectAll over only empty documents is a no-op', () {
      final c = MarkdownSelectionController()
        ..setDocuments([
          MarkdownDocumentRef(id: 'a', model: Markdown.fromString('')),
        ]);
      c.selectAll();
      expect(c.selection, isNull);
    });
  });
}
