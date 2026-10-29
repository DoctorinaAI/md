// Coverage for the remaining small gaps across lib/src: value semantics of
// the selection types, reconciliation fallbacks, controller geometry
// fallbacks, keyboard extension intents, scope widget updates, toolbar
// anchoring near the screen bottom, render-object housekeeping and a few
// block-painter edge cases (ragged tables, width distribution, filters).
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_md/flutter_md.dart';
import 'package:flutter_md/src/render.dart';
import 'package:flutter_test/flutter_test.dart';

final MarkdownThemeData _theme = MarkdownThemeData(
  textStyle: const TextStyle(fontSize: 14),
);

MarkdownPosition _p(Object doc, int offset, [int block = 0]) =>
    MarkdownPosition(documentId: doc, blockIndex: block, offset: offset);

MarkdownSelectionController _controller(
  Map<Object, String> docs, {
  MarkdownReconciliationPolicy? reconciliation,
}) {
  final c = MarkdownSelectionController(reconciliation: reconciliation)
    ..setDocuments(<MarkdownDocumentRef>[
      for (final e in docs.entries)
        MarkdownDocumentRef(id: e.key, model: Markdown.fromString(e.value)),
    ]);
  addTearDown(c.dispose);
  return c;
}

T _first<T extends MD$Block>(String source) =>
    Markdown.fromString(source).blocks.whereType<T>().first;

/// Runs [body] with [platform] forced (try/finally — the framework's
/// `debugAssertAllFoundationVarsUnset` check runs before user tear-downs).
Future<void> _withPlatform(
  TargetPlatform platform,
  Future<void> Function() body,
) async {
  debugDefaultTargetPlatformOverride = platform;
  try {
    await body();
  } finally {
    debugDefaultTargetPlatformOverride = null;
  }
}

class _Doc extends StatelessWidget {
  const _Doc(this.id);

  final String id;

  @override
  Widget build(BuildContext context) {
    final controller = MarkdownSelectionScope.of(context);
    final model = controller.documents.firstWhere((d) => d.id == id).model;
    return MarkdownWidget(markdown: model, documentId: id);
  }
}

Widget _scopeApp(
  MarkdownSelectionController c, {
  Color? selectionColor,
  Widget child = const SizedBox(width: 400, child: _Doc('d')),
}) =>
    MaterialApp(
      home: Scaffold(
        body: MarkdownSelectionScope(
          controller: c,
          selectionColor: selectionColor,
          child: Align(alignment: Alignment.topLeft, child: child),
        ),
      ),
    );

/// A scriptable surface whose word boundary is always unknown, so the
/// controller falls back to its text heuristic.
class _Surface implements MarkdownSelectionSurface {
  _Surface(this.documentId, this.bounds);

  @override
  final Object documentId;

  final Rect bounds;

  MarkdownPosition? hit;

  @override
  TextDirection get textDirection => TextDirection.ltr;

  @override
  Rect get globalBounds => bounds;

  @override
  MarkdownPosition? positionForGlobal(Offset globalPosition) => hit;

  @override
  (MarkdownPosition, TextAffinity)? hitForGlobal(Offset globalPosition) =>
      switch (hit) {
        final h? => (h, TextAffinity.downstream),
        null => null,
      };

  @override
  bool hitsSelectableGlyphs(Offset globalPosition) => false;

  @override
  bool isLinkAtGlobal(Offset globalPosition) => false;

  @override
  Rect? caretRectFor(MarkdownPosition position, TextAffinity affinity) => null;

  @override
  (int, int, int)? wordBoundaryForGlobal(Offset globalPosition) => null;

  @override
  List<Rect> globalSelectionRects() => const <Rect>[];

  @override
  List<Rect> localSelectionRects() => const <Rect>[];

  @override
  List<Rect> localBoxesForRange(
    int blockIndex,
    int startOffset,
    int endOffset,
  ) =>
      const <Rect>[];

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

/// A [MultiPainterSelectable] that keeps every mixin default.
class _TwoRuns with MultiPainterSelectable implements BlockPainter {
  _TwoRuns()
      : _a = TextPainter(
          text: const TextSpan(text: 'ab', style: TextStyle(fontSize: 14)),
          textDirection: TextDirection.ltr,
        ),
        _b = TextPainter(
          text: const TextSpan(text: 'cd', style: TextStyle(fontSize: 14)),
          textDirection: TextDirection.ltr,
        );

  final TextPainter _a;
  final TextPainter _b;

  @override
  List<SelectableFragment> fragments = const <SelectableFragment>[];

  @override
  String get renderedText => 'ab\ncd';

  @override
  Size size = Size.zero;

  @override
  void handleTapDown(PointerDownEvent event) {}

  @override
  void handleTapUp(PointerUpEvent event) {}

  @override
  Size layout(double width) {
    _a.layout(maxWidth: width);
    _b.layout(maxWidth: width);
    fragments = <SelectableFragment>[
      SelectableFragment(_a, Offset.zero, 0),
      SelectableFragment(_b, Offset(0, _a.height), 3),
    ];
    return size = Size(width, _a.height + _b.height);
  }

  @override
  void paint(Canvas canvas, Size size, double offset) {}

  @override
  void dispose() {
    _a.dispose();
    _b.dispose();
  }
}

/// An image stream completer that remembers its listeners, so a test can
/// deliver a frame to a listener that has since been removed.
class _ManualCompleter extends ImageStreamCompleter {
  final List<ImageStreamListener> added = <ImageStreamListener>[];

  @override
  void addListener(ImageStreamListener listener) {
    added.add(listener);
    super.addListener(listener);
  }
}

class _ManualProvider extends ImageProvider<_ManualProvider> {
  final _ManualCompleter completer = _ManualCompleter();

  @override
  Future<_ManualProvider> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<_ManualProvider>(this);

  @override
  ImageStreamCompleter loadImage(
    _ManualProvider key,
    ImageDecoderCallback decode,
  ) =>
      completer;
}

ui.Image _pixel() {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawRect(
    const Rect.fromLTWH(0, 0, 1, 1),
    Paint()..color = const Color(0xFF000000),
  );
  final picture = recorder.endRecording();
  final image = picture.toImageSync(1, 1);
  picture.dispose();
  return image;
}

void main() {
  group('Coverage gaps', () {
    group('selection value types', () {
      test('MarkdownPosition equality, hash, copyWith and toString', () {
        final a = _p('d', 3, 1);
        expect(a, _p('d', 3, 1));
        expect(a.hashCode, _p('d', 3, 1).hashCode);
        expect(a, isNot(_p('d', 4, 1)));
        expect(a.copyWith(), a);
        expect(a.copyWith(offset: 7), _p('d', 7, 1));
        expect(a.copyWith(blockIndex: 2, documentId: 'e'), _p('e', 3, 2));
        expect(a.toString(), 'MarkdownPosition(d#1@3)');
      });

      test('MarkdownSelection equality, hash and toString', () {
        final s = MarkdownSelection(base: _p('d', 0), extent: _p('d', 2));
        final same = MarkdownSelection(base: _p('d', 0), extent: _p('d', 2));
        expect(s, same);
        expect(s.hashCode, same.hashCode);
        expect(s, isNot(MarkdownSelection.collapsed(_p('d', 0))));
        expect(s.toString(), contains('->'));
        expect(s.toString(), contains('MarkdownPosition(d#0@2)'));
      });

      test('MarkdownSelectedContent empty / plain-text helpers', () {
        const empty =
            MarkdownSelectedContent(documents: <MarkdownSelectedDocument>[]);
        expect(empty.isEmpty, isTrue);
        expect(empty.isNotEmpty, isFalse);
        expect(empty.toPlainText(), isEmpty);

        final c = _controller(<Object, String>{'d': 'Hello world'})
          ..selection = MarkdownSelection(base: _p('d', 0), extent: _p('d', 5));
        final content = c.selectedContent();
        expect(content.isEmpty, isFalse);
        expect(content.isNotEmpty, isTrue);
        expect(content.toPlainText(), 'Hello');
      });

      test('a divider renders no text', () {
        expect(markdownBlockRenderedText(_first<MD$Divider>('---')), isEmpty);
      });

      test('markup formatter reconstructs dividers and drops spacers', () {
        final md = Markdown.fromString('Above\n\n---\n\nBelow');
        final divider = md.blocks.whereType<MD$Divider>().single;
        final spacer = md.blocks.whereType<MD$Spacer>().first;
        // Extraction skips empty structural blocks, but a hand-built content
        // (a custom pipeline) may carry them; the formatter must cope.
        final content = MarkdownSelectedContent(
          documents: <MarkdownSelectedDocument>[
            MarkdownSelectedDocument(
              documentId: 'd',
              blocks: <MarkdownSelectedBlock>[
                for (final b in <MD$Block>[divider, spacer])
                  MarkdownSelectedBlock(
                    blockIndex: md.blocks.indexOf(b),
                    type: b.type,
                    text: '',
                    renderedRange: const TextRange(start: 0, end: 0),
                    block: b,
                  ),
              ],
            ),
          ],
        );
        expect(const MarkdownMarkupFormatter().format(content), '---');
      });
    });

    group('reconciliation', () {
      test('content-anchored clamps into an emptied document', () {
        final c = _controller(<Object, String>{'d': 'Hello world'})
          ..selection = MarkdownSelection(base: _p('d', 1), extent: _p('d', 4));
        c.putDocument('d', Markdown.fromString(''));
        expect(c.selection, MarkdownSelection.collapsed(_p('d', 0)));
        expect(c.getText(), isEmpty);
      });

      test('content-anchored clamps when the block text vanished', () {
        final c = _controller(<Object, String>{'d': 'Hello world'})
          ..selection =
              MarkdownSelection(base: _p('d', 2), extent: _p('d', 11));
        c.putDocument('d', Markdown.fromString('Bye'));
        // No block matches the old text: offsets clamp into block 0.
        expect(c.selection,
            MarkdownSelection(base: _p('d', 2), extent: _p('d', 3)));
        expect(c.getText(), 'e');
      });

      test('append fast path keeps anchors on a streamed append', () {
        final c = _controller(
          <Object, String>{'d': 'Hello'},
          reconciliation: const MarkdownReconciliationPolicy.appendFastPath(),
        )..selection = MarkdownSelection(base: _p('d', 0), extent: _p('d', 5));
        c.putDocument('d', Markdown.fromString('Hello world'));
        expect(c.selection,
            MarkdownSelection(base: _p('d', 0), extent: _p('d', 5)));
        expect(c.getText(), 'Hello');
      });

      test('updating the base document keeps a foreign extent', () {
        final c = _controller(<Object, String>{'a': 'Alpha', 'b': 'Beta'})
          ..selection = MarkdownSelection(base: _p('a', 2), extent: _p('b', 2));
        c.putDocument('a', Markdown.fromString('Alpha more'));
        expect(c.selection!.extent, _p('b', 2));
        expect(c.selection!.base, _p('a', 2));
        // The grown base block extends the selection with it.
        expect(c.getText(), 'pha more\n\nBe');
      });

      test('putDocument with a new order re-sorts documents', () {
        final c = _controller(<Object, String>{'a': 'A', 'b': 'B'});
        final model = c.documents.first.model;
        var notified = 0;
        c.addListener(() => notified++);
        c.putDocument('a', model, order: 10);
        expect(c.documents.map((d) => d.id), <Object>['b', 'a']);
        expect(notified, 1);
        // Same model and order: nothing to do.
        c.putDocument('a', model, order: 10);
        expect(notified, 1);
      });
    });

    group('controller', () {
      test('formatter getter reflects the configured formatter', () {
        final c = MarkdownSelectionController(
          formatter: const MarkdownMarkupFormatter(),
        );
        addTearDown(c.dispose);
        expect(c.formatter, isA<MarkdownMarkupFormatter>());
        c.formatter = const MarkdownPlainTextFormatter();
        expect(c.formatter, isA<MarkdownPlainTextFormatter>());
      });

      test('wordRangeIn at the end after trailing punctuation', () {
        expect(MarkdownSelectionController.wordRangeIn('ab!', 3), (2, 3));
        expect(MarkdownSelectionController.wordRangeIn('ab  ', 4), (2, 4));
      });

      test('a point above a surface clamps to it', () {
        final c = _controller(<Object, String>{'d': 'Hello world'});
        final surface = _Surface('d', const Rect.fromLTWH(0, 100, 200, 40))
          ..hit = _p('d', 0);
        c.attachSurface(surface);
        addTearDown(() => c.detachSurface(surface));
        expect(c.positionForGlobal(const Offset(10, 20)), _p('d', 0));
        expect(
          c.positionForGlobal(const Offset(10, 20), requireContainment: true),
          isNull,
        );
      });

      test('wordSelectionAt falls back to the text heuristic', () {
        final c = _controller(<Object, String>{'d': 'Hello world'});
        final surface = _Surface('d', const Rect.fromLTWH(0, 0, 200, 40))
          ..hit = _p('d', 8);
        c.attachSurface(surface);
        addTearDown(() => c.detachSurface(surface));
        final sel = c.wordSelectionAt(const Offset(10, 10));
        expect(sel, MarkdownSelection(base: _p('d', 6), extent: _p('d', 11)));
      });

      test('wordSelectionAt on an unregistered document is null', () {
        final c = _controller(<Object, String>{'d': 'Hello world'});
        final surface = _Surface('ghost', const Rect.fromLTWH(0, 0, 200, 40))
          ..hit = _p('ghost', 1);
        c.attachSurface(surface);
        addTearDown(() => c.detachSurface(surface));
        expect(c.wordSelectionAt(const Offset(10, 10)), isNull);
      });

      test('extendSelectionToAdjacentLine is a no-op without geometry', () {
        final c = _controller(<Object, String>{'d': 'Hello world'})
          ..extendSelectionToAdjacentLine(forward: true);
        expect(c.selection, isNull);
        // A selection, but no mounted surface: no rects to step from.
        final sel = MarkdownSelection(base: _p('d', 0), extent: _p('d', 3));
        c
          ..selection = sel
          ..extendSelectionToAdjacentLine(forward: true);
        expect(c.selection, sel);
      });

      test('group clearExternal clears every member', () {
        final group = MarkdownSelectionGroup();
        final a = MarkdownSelectionController(group: group)
          ..setDocuments(<MarkdownDocumentRef>[
            MarkdownDocumentRef(id: 'a', model: Markdown.fromString('Alpha')),
          ]);
        final b = MarkdownSelectionController(group: group)
          ..setDocuments(<MarkdownDocumentRef>[
            MarkdownDocumentRef(id: 'b', model: Markdown.fromString('Beta')),
          ]);
        addTearDown(a.dispose);
        addTearDown(b.dispose);
        a.selectAll();
        expect(a.selection, isNotNull);
        group.clearExternal();
        expect(a.selection, isNull);
        expect(b.selection, isNull);
      });
    });

    group('scope', () {
      testWidgets('a new selectionColor is pushed to the controller',
          (tester) async {
        final c = _controller(<Object, String>{'d': 'Hello world'});
        await tester
            .pumpWidget(_scopeApp(c, selectionColor: const Color(0xFF00FF00)));
        expect(c.selectionColor, const Color(0xFF00FF00));
        await tester
            .pumpWidget(_scopeApp(c, selectionColor: const Color(0xFFFF0000)));
        expect(c.selectionColor, const Color(0xFFFF0000));
      });

      testWidgets('keyboard extension intents move the extent', (tester) async {
        await _withPlatform(TargetPlatform.linux, () async {
          final c = _controller(<Object, String>{'d': 'Hello keyboard world'});
          await tester.pumpWidget(_scopeApp(c));
          await tester.pumpAndSettle();
          final ctx = tester.element(find.byType(MarkdownWidget));
          c.selection = MarkdownSelection.collapsed(_p('d', 0));

          Actions.invoke(
            ctx,
            const ExtendSelectionToNextWordBoundaryIntent(
              forward: true,
              collapseSelection: false,
            ),
          );
          expect(c.getText(), 'Hello');

          // Collapsing variants are ignored (no caret navigation).
          Actions.invoke(
            ctx,
            const ExtendSelectionToNextWordBoundaryIntent(
              forward: true,
              collapseSelection: true,
            ),
          );
          Actions.invoke(
            ctx,
            const ExtendSelectionToLineBreakIntent(
              forward: true,
              collapseSelection: true,
            ),
          );
          Actions.invoke(
            ctx,
            const ExtendSelectionVerticallyToAdjacentLineIntent(
              forward: true,
              collapseSelection: true,
            ),
          );
          Actions.invoke(
            ctx,
            const ExtendSelectionToDocumentBoundaryIntent(
              forward: false,
              collapseSelection: true,
            ),
          );
          expect(c.getText(), 'Hello');

          Actions.invoke(
            ctx,
            const ExtendSelectionToLineBreakIntent(
              forward: true,
              collapseSelection: false,
            ),
          );
          expect(c.getText(), 'Hello keyboard world');

          Actions.invoke(
            ctx,
            const ExtendSelectionToDocumentBoundaryIntent(
              forward: false,
              collapseSelection: false,
            ),
          );
          expect(c.selection!.isCollapsed, isTrue);
        });
      });

      testWidgets('adjacent-line intent steps the extent to the next line',
          (tester) async {
        await _withPlatform(TargetPlatform.linux, () async {
          final c = _controller(<Object, String>{'d': 'first line\nsecond'});
          await tester.pumpWidget(_scopeApp(c));
          await tester.pumpAndSettle();
          final ctx = tester.element(find.byType(MarkdownWidget));
          c.selection = MarkdownSelection(base: _p('d', 0), extent: _p('d', 2));
          await tester.pump();

          Actions.invoke(
            ctx,
            const ExtendSelectionVerticallyToAdjacentLineIntent(
              forward: true,
              collapseSelection: false,
            ),
          );
          await tester.pump();
          final down = c.getText();
          expect(down, startsWith('first line\n'));
          expect(down.length, greaterThan('first line\n'.length));

          // Back up: from the second line to the first.
          Actions.invoke(
            ctx,
            const ExtendSelectionVerticallyToAdjacentLineIntent(
              forward: false,
              collapseSelection: false,
            ),
          );
          await tester.pump();
          expect(c.getText(), isNot(contains('\n')));
          expect(c.getText(), startsWith('f'));
        });
      });

      testWidgets('toolbar flips above an extent at the screen bottom',
          (tester) async {
        final ids = <String>[for (var i = 0; i < 60; i++) 'doc$i'];
        final c = MarkdownSelectionController()
          ..setDocuments(<MarkdownDocumentRef>[
            for (var i = 0; i < ids.length; i++)
              MarkdownDocumentRef(
                id: ids[i],
                model: Markdown.fromString('Line ${ids[i]}'),
                order: i,
              ),
          ]);
        addTearDown(c.dispose);
        final scroll = ScrollController();
        addTearDown(scroll.dispose);
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: MarkdownSelectionScope(
              controller: c,
              child: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: 400,
                  height: 600,
                  child: ListView(
                    controller: scroll,
                    children: <Widget>[for (final id in ids) _Doc(id)],
                  ),
                ),
              ),
            ),
          ),
        ));
        await tester.pumpAndSettle();
        c.selectAll();
        await tester.pump();
        // Scroll to the end: the first document (the base) is gone, the
        // extent sits at the very bottom of the screen with no room for a
        // menu below it.
        scroll.jumpTo(scroll.position.maxScrollExtent);
        await tester.pumpAndSettle();
        final extent = c.selectionEndpointGlobalRect(base: false)!;
        final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
        expect(screen.height - extent.bottom, lessThan(48));

        final state = tester.state<MarkdownSelectionScopeState>(
            find.byType(MarkdownSelectionScope));
        final anchors = state.contextMenuAnchors;
        expect(anchors.primaryAnchor, extent.topCenter);
        expect(anchors.secondaryAnchor, extent.bottomCenter);
      });
    });

    group('render object', () {
      testWidgets('housekeeping: repaint, children, system fonts',
          (tester) async {
        await tester.pumpWidget(Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 300,
              child: MarkdownWidget(markdown: Markdown.fromString('Hello')),
            ),
          ),
        ));
        final ro = tester
            .renderObject<MarkdownRenderObject>(find.byType(MarkdownWidget));
        expect(ro.debugNeedsPaint, isFalse);
        ro.repaintSelection();
        expect(ro.debugNeedsPaint, isTrue);
        await tester.pump();

        // A leaf: there are never children to hit.
        expect(
          // ignore: invalid_use_of_protected_member
          ro.hitTestChildren(BoxHitTestResult(), position: Offset.zero),
          isFalse,
        );

        // A system font change drops cached layouts and re-lays out.
        expect(ro.debugNeedsLayout, isFalse);
        await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
          SystemChannels.system.name,
          SystemChannels.system.codec
              .encodeMessage(<String, Object?>{'type': 'fontsChange'}),
          (_) {},
        );
        expect(ro.debugNeedsLayout, isTrue);
        expect(ro.debugPainter.needsLayout, isTrue);
        await tester.pump();
        expect(ro.debugNeedsLayout, isFalse);

        // Once detached and disposed, a stray repaint request is ignored.
        await tester.pumpWidget(const SizedBox());
        expect(ro.repaintSelection, returnsNormally);
      });
    });

    group('painters', () {
      test('MarkdownPainter exposes its size and honours blockFilter', () {
        final md = Markdown.fromString('# Title\n\nBody text');
        final all = MarkdownPainter(markdown: md, theme: _theme);
        final filtered = MarkdownPainter(
          markdown: md,
          theme: _theme.copyWith(blockFilter: (b) => b is! MD$Heading),
        );
        addTearDown(all.dispose);
        addTearDown(filtered.dispose);
        final full = all.layout(maxWidth: 300);
        final less = filtered.layout(maxWidth: 300);
        expect(all.size, full);
        expect(filtered.size, less);
        expect(less.height, lessThan(full.height));
      });

      test('MarkdownPainter.paint rejects a non-finite size', () {
        final painter = MarkdownPainter(
          markdown: Markdown.fromString('Body'),
          theme: _theme,
        );
        addTearDown(painter.dispose);
        painter.layout(maxWidth: 300);
        final recorder = ui.PictureRecorder();
        expect(
          () => painter.paint(Canvas(recorder), Size.infinite),
          throwsAssertionError,
        );
        recorder.endRecording().dispose();
      });

      test('divider and code painters ignore taps', () {
        final divider = BlockPainter$Divider(theme: _theme);
        final code = BlockPainter$Code(
          text: 'let x = 1;',
          language: null,
          theme: _theme,
        );
        final dSize = divider.layout(300);
        final cSize = code.layout(300);
        const down = PointerDownEvent(position: Offset(5, 5));
        const up = PointerUpEvent(position: Offset(5, 5));
        expect(() {
          divider
            ..handleTapDown(down)
            ..handleTapUp(up);
          code
            ..handleTapDown(down)
            ..handleTapUp(up);
        }, returnsNormally);
        expect(divider.size, dSize);
        expect(code.size, cSize);
      });

      test('a custom MultiPainterSelectable paints highlight under glyphs', () {
        final runs = _TwoRuns()..layout(200);
        addTearDown(runs.dispose);
        expect(runs.selectionHighlightAboveCachedContent, isFalse);
        expect(runs.offsetForLocalPosition(Offset(1, runs._a.height + 1)),
            inInclusiveRange(3, 5));
      });

      test('a table row with fewer cells than the header lays out', () {
        final table = _first<MD$Table>('| a | b |\n|---|---|\n| c | d |');
        final short = MD$TableRow(
          text: '| c |',
          cells: <List<MD$Span>>[table.rows.first.cells.first],
        );
        final painter = BlockPainter$Table(
          header: table.header,
          rows: <MD$TableRow>[short],
          alignments: table.alignments,
          theme: _theme,
        );
        final full = BlockPainter$Table(
          header: table.header,
          rows: table.rows,
          alignments: table.alignments,
          theme: _theme,
        );
        final size = painter.layout(300);
        expect(size.width, greaterThan(0));
        // The missing cell takes no text but keeps the row geometry.
        expect(size, full.layout(300));
        expect(painter.renderedText, startsWith('a\tb\nc'));
      });

      test('a too-wide table shares the spare width between columns', () {
        final table = _first<MD$Table>(
          '| Name | Description |\n'
          '|---|---|\n'
          '| Short | a rather long sentence that wraps across lines |',
        );
        BlockPainter$Table make() => BlockPainter$Table(
              header: table.header,
              rows: table.rows,
              alignments: table.alignments,
              theme: _theme,
            );
        final natural = make().layout(double.infinity);
        // At zero width every column falls back to its minimum (one word).
        final minimum = make().layout(0);
        final narrow = make();
        final width = (natural.width + minimum.width) / 2;
        expect(minimum.width, lessThan(width));
        final size = narrow.layout(width);
        // Fits exactly: minimum widths plus a share of the remaining space.
        expect(size.width, moreOrLessEquals(width, epsilon: 0.01));
        expect(size.height, greaterThan(natural.height),
            reason: 'the long cell wraps');
      });

      test('paragraphFromMarkdownSpans applies the spanFilter', () {
        final spans = _first<MD$Paragraph>('keep **drop** keep').spans;
        final text = paragraphFromMarkdownSpans(
          spans: spans,
          theme: _theme.copyWith(
            spanFilter: (s) => !s.style.contains(MD$Style.bold),
          ),
        );
        expect(text.toPlainText(), 'keep  keep');
      });
    });

    group('images', () {
      test('a frame delivered after dispose is released', () {
        final provider = _ManualProvider();
        addTearDown(() => PaintingBinding.instance.imageCache.clear());
        final image = MarkdownProviderImage(provider);
        var notified = 0;
        image
          ..addListener(() => notified++)
          ..layout(const MarkdownImageConstraints(
            maxWidth: 100,
            textStyle: TextStyle(fontSize: 10),
          ));
        // The image cache listens first; the image's own listener is last.
        final listener = provider.completer.added.last;
        image.dispose();

        final frame = ImageInfo(image: _pixel());
        listener.onImage(frame, false);
        expect(image.imageInfo, isNull);
        expect(frame.image.debugDisposed, isTrue);
        expect(notified, 0);
      });
    });
  });
}
