import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_md/flutter_md.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _mouseDrag(WidgetTester tester, Offset from, Offset to) async {
  final g = await tester.startGesture(from, kind: PointerDeviceKind.mouse);
  await tester.pump(const Duration(milliseconds: 200));
  await g.moveTo(to);
  await tester.pump(const Duration(milliseconds: 200));
  await g.up();
  await tester.pumpAndSettle();
}

/// Taps [times] times in quick succession at [pos] (a mouse click, then a
/// double- or triple-click when times > 1).
Future<void> _clicks(WidgetTester tester, Offset pos, int times) async {
  for (var i = 0; i < times; i++) {
    final g = await tester.startGesture(pos, kind: PointerDeviceKind.mouse);
    await g.up();
    if (i < times - 1) await tester.pump(const Duration(milliseconds: 40));
  }
  await tester.pumpAndSettle();
}

Widget _wrap(MarkdownSelectionController controller, Widget child) =>
    MaterialApp(
      home: Scaffold(
        body: MarkdownSelectionScope(controller: controller, child: child),
      ),
    );

void main() {
  group('selection widget integration', () {
    testWidgets('drag selects a single paragraph', (tester) async {
      final md = Markdown.fromString('Hello selectable world');
      final controller = MarkdownSelectionController()
        ..setDocuments(
            <MarkdownDocumentRef>[MarkdownDocumentRef(id: 'd', model: md)]);

      await tester.pumpWidget(_wrap(
        controller,
        const Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: 400, child: _Doc('d')),
        ),
      ));
      await tester.pumpAndSettle();

      final tl = tester.getTopLeft(find.byType(MarkdownWidget));
      final br = tester.getBottomRight(find.byType(MarkdownWidget));
      await _mouseDrag(
          tester, tl + const Offset(1, 3), br - const Offset(1, 3));

      expect(controller.getText(), 'Hello selectable world');
      expect(tester.takeException(), isNull);
    });

    testWidgets('drag spans two MarkdownWidgets with a document separator',
        (tester) async {
      final a = Markdown.fromString('First message body');
      final b = Markdown.fromString('Second message body');
      final controller = MarkdownSelectionController()
        ..setDocuments(<MarkdownDocumentRef>[
          MarkdownDocumentRef(id: 'a', model: a),
          MarkdownDocumentRef(id: 'b', model: b),
        ]);

      await tester.pumpWidget(_wrap(
        controller,
        const Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 400,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[_Doc('a'), _Doc('b')],
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final first = find.byType(MarkdownWidget).first;
      final last = find.byType(MarkdownWidget).last;
      await _mouseDrag(
        tester,
        tester.getTopLeft(first) + const Offset(1, 3),
        tester.getBottomRight(last) - const Offset(1, 3),
      );

      expect(controller.getText(), 'First message body\n\nSecond message body');
      expect(tester.takeException(), isNull);
    });

    testWidgets('cross-widget selection survives ListView disposal',
        (tester) async {
      final controller = MarkdownSelectionController()
        ..setDocuments(<MarkdownDocumentRef>[
          for (var i = 0; i < 10; i++)
            MarkdownDocumentRef(
              id: 'm$i',
              model: Markdown.fromString('Message number $i'),
              order: i,
            ),
        ]);
      final scroll = ScrollController();

      await tester.pumpWidget(_wrap(
        controller,
        SizedBox(
          height: 200,
          child: ListView.builder(
            controller: scroll,
            cacheExtent: 0,
            itemCount: 10,
            itemBuilder: (_, i) => SizedBox(
              height: 80,
              child: _Doc('m$i'),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final p0 = tester.getTopLeft(find.byType(MarkdownWidget).first) +
          const Offset(1, 3);
      final p1 = tester.getCenter(find.byType(MarkdownWidget).at(1));
      await _mouseDrag(tester, p0, p1);
      final before = controller.getText();
      expect(before, contains('Message number 0'));
      expect(before, contains('Message number 1'));

      scroll.jumpTo(80.0 * 7); // dispose the first messages
      await tester.pumpAndSettle();
      expect(
          find.byWidgetPredicate(
              (w) => w is MarkdownWidget && w.documentId == 'm0'),
          findsNothing);

      // Text is derived from the model registry → intact after disposal.
      expect(controller.getText(), before);
      expect(controller.getText(), contains('Message number 0'));
      expect(tester.takeException(), isNull);
    });

    testWidgets('selecting in one controller clears the other (group)',
        (tester) async {
      final group = MarkdownSelectionGroup();
      final a = Markdown.fromString('Alpha body text');
      final b = Markdown.fromString('Bravo body text');
      final ca = MarkdownSelectionController(group: group)
        ..setDocuments(
            <MarkdownDocumentRef>[MarkdownDocumentRef(id: 'a', model: a)]);
      final cb = MarkdownSelectionController(group: group)
        ..setDocuments(
            <MarkdownDocumentRef>[MarkdownDocumentRef(id: 'b', model: b)]);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              MarkdownSelectionScope(
                controller: ca,
                child: const SizedBox(width: 400, child: _Doc('a')),
              ),
              MarkdownSelectionScope(
                controller: cb,
                child: const SizedBox(width: 400, child: _Doc('b')),
              ),
            ],
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Select in controller B first.
      final bw = find
          .byWidgetPredicate((w) => w is MarkdownWidget && w.documentId == 'b');
      await _mouseDrag(
        tester,
        tester.getTopLeft(bw) + const Offset(1, 3),
        tester.getBottomRight(bw) - const Offset(1, 3),
      );
      expect(cb.getText(), isNotEmpty);

      // Now select in controller A — B must be cleared.
      final aw = find
          .byWidgetPredicate((w) => w is MarkdownWidget && w.documentId == 'a');
      await _mouseDrag(
        tester,
        tester.getTopLeft(aw) + const Offset(1, 3),
        tester.getBottomRight(aw) - const Offset(1, 3),
      );
      expect(ca.getText(), isNotEmpty);
      expect(cb.selection, isNull,
          reason: 'group cleared the other controller');
      expect(tester.takeException(), isNull);
    });

    testWidgets('MarkdownWidget without documentId stays inert',
        (tester) async {
      final md = Markdown.fromString('Not selectable here');
      final controller = MarkdownSelectionController()
        ..setDocuments(
            <MarkdownDocumentRef>[MarkdownDocumentRef(id: 'x', model: md)]);
      await tester.pumpWidget(_wrap(
        controller,
        SizedBox(width: 400, child: MarkdownWidget(markdown: md)),
      ));
      await tester.pumpAndSettle();

      final tl = tester.getTopLeft(find.byType(MarkdownWidget));
      final br = tester.getBottomRight(find.byType(MarkdownWidget));
      await _mouseDrag(
          tester, tl + const Offset(1, 3), br - const Offset(1, 3));

      expect(controller.getText(), '', reason: 'no documentId => inert');
      expect(tester.takeException(), isNull);
    });

    testWidgets('drag with only an empty (zero-size) document does not crash',
        (tester) async {
      // Regression: positionForGlobal's nearest-surface fallback used to invert
      // num.clamp for a zero-area surface, throwing ArgumentError mid-drag.
      final controller = MarkdownSelectionController()
        ..setDocuments(const <MarkdownDocumentRef>[
          MarkdownDocumentRef(id: 'e', model: Markdown.empty()),
        ]);
      await tester.pumpWidget(_wrap(
        controller,
        const SizedBox(width: 400, height: 200, child: _Doc('e')),
      ));
      await tester.pumpAndSettle();

      await _mouseDrag(tester, const Offset(20, 20), const Offset(220, 160));
      expect(tester.takeException(), isNull);
      expect(controller.getText(), '');
    });

    testWidgets('drag past an empty document still selects a real one',
        (tester) async {
      final controller = MarkdownSelectionController()
        ..setDocuments(<MarkdownDocumentRef>[
          const MarkdownDocumentRef(
              id: 'empty', model: Markdown.empty(), order: 0),
          MarkdownDocumentRef(
              id: 'real',
              model: Markdown.fromString('Real content here'),
              order: 1),
        ]);
      await tester.pumpWidget(_wrap(
        controller,
        const Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 400,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[_Doc('empty'), _Doc('real')],
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final realWidget = find.byWidgetPredicate(
          (w) => w is MarkdownWidget && w.documentId == 'real');
      await _mouseDrag(
        tester,
        tester.getTopLeft(realWidget) + const Offset(1, 3),
        tester.getBottomRight(realWidget) - const Offset(1, 3),
      );
      expect(tester.takeException(), isNull);
      expect(controller.getText(), 'Real content here');
    });

    testWidgets('drag selects the cells of a table', (tester) async {
      final md =
          Markdown.fromString('| A | B |\n|---|---|\n| 1 | 2 |\n| 3 | 4 |');
      final table = md.blocks.firstWhere((b) => b.type == 'table');
      final controller = MarkdownSelectionController()
        ..setDocuments(
            <MarkdownDocumentRef>[MarkdownDocumentRef(id: 'd', model: md)]);

      await tester.pumpWidget(_wrap(
        controller,
        const Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: 400, child: _Doc('d')),
        ),
      ));
      await tester.pumpAndSettle();

      final tl = tester.getTopLeft(find.byType(MarkdownWidget));
      final br = tester.getBottomRight(find.byType(MarkdownWidget));
      await _mouseDrag(
          tester, tl + const Offset(2, 2), br - const Offset(2, 2));

      expect(controller.getText(), markdownBlockRenderedText(table));
      expect(controller.getText(), 'A\tB\n1\t2\n3\t4');
      expect(tester.takeException(), isNull);
    });

    testWidgets('drag selects the items of a list', (tester) async {
      final md = Markdown.fromString('- alpha\n- beta\n- gamma');
      final controller = MarkdownSelectionController()
        ..setDocuments(
            <MarkdownDocumentRef>[MarkdownDocumentRef(id: 'd', model: md)]);

      await tester.pumpWidget(_wrap(
        controller,
        const Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: 400, child: _Doc('d')),
        ),
      ));
      await tester.pumpAndSettle();

      final tl = tester.getTopLeft(find.byType(MarkdownWidget));
      final br = tester.getBottomRight(find.byType(MarkdownWidget));
      await _mouseDrag(
          tester, tl + const Offset(2, 2), br - const Offset(2, 2));

      expect(controller.getText(), 'alpha\nbeta\ngamma');
      expect(tester.takeException(), isNull);
    });

    testWidgets('selection spanning a table includes its cells',
        (tester) async {
      final md = Markdown.fromString(
          'Intro line\n\n| A | B |\n|---|---|\n| 1 | 2 |\n\nOutro line');
      final controller = MarkdownSelectionController()
        ..setDocuments(
            <MarkdownDocumentRef>[MarkdownDocumentRef(id: 'd', model: md)]);

      await tester.pumpWidget(_wrap(
        controller,
        const Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: 400, child: _Doc('d')),
        ),
      ));
      await tester.pumpAndSettle();

      final tl = tester.getTopLeft(find.byType(MarkdownWidget));
      final br = tester.getBottomRight(find.byType(MarkdownWidget));
      await _mouseDrag(
          tester, tl + const Offset(2, 2), br - const Offset(2, 2));

      expect(controller.getText(), 'Intro line\nA\tB\n1\t2\nOutro line');
      expect(tester.takeException(), isNull);
    });
  });

  group('selection gestures', () {
    Future<Offset> pumpParagraph(
      WidgetTester tester,
      MarkdownSelectionController controller,
    ) async {
      await tester.pumpWidget(_wrap(
        controller,
        const Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: 400, child: _Doc('d')),
        ),
      ));
      await tester.pumpAndSettle();
      return tester.getTopLeft(find.byType(MarkdownWidget));
    }

    testWidgets('double-click selects the word under the pointer',
        (tester) async {
      final controller = MarkdownSelectionController()
        ..setDocuments(<MarkdownDocumentRef>[
          MarkdownDocumentRef(
              id: 'd', model: Markdown.fromString('Hello selectable world')),
        ]);
      final tl = await pumpParagraph(tester, controller);

      await _clicks(tester, tl + const Offset(8, 8), 2);
      expect(controller.getText(), 'Hello');
      expect(tester.takeException(), isNull);
    });

    testWidgets('double-click keeps intra-word punctuation (apostrophe)',
        (tester) async {
      final controller = MarkdownSelectionController()
        ..setDocuments(<MarkdownDocumentRef>[
          MarkdownDocumentRef(
              id: 'd', model: Markdown.fromString("can't stop here")),
        ]);
      final tl = await pumpParagraph(tester, controller);

      await _clicks(tester, tl + const Offset(8, 8), 2);
      // The platform word segmentation keeps the apostrophe inside the word,
      // unlike the plain punctuation-splitting heuristic.
      expect(controller.getText(), "can't");
      expect(tester.takeException(), isNull);
    });

    testWidgets('touch double-tap selects a word and shows the toolbar',
        (tester) async {
      final controller = MarkdownSelectionController()
        ..setDocuments(<MarkdownDocumentRef>[
          MarkdownDocumentRef(
              id: 'd', model: Markdown.fromString('Hello selectable world')),
        ]);
      final tl = await pumpParagraph(tester, controller);

      final pos = tl + const Offset(8, 8);
      await tester.tapAt(pos); // default gesture kind is touch
      await tester.pump(const Duration(milliseconds: 40));
      await tester.tapAt(pos);
      await tester.pumpAndSettle();

      expect(controller.getText(), 'Hello');
      final state = tester.state<MarkdownSelectionScopeState>(
          find.byType(MarkdownSelectionScope));
      expect(state.toolbarIsVisible, isTrue,
          reason: 'a mobile double-tap pops the selection toolbar');
      expect(tester.takeException(), isNull);
    });

    testWidgets('triple-click selects the whole block', (tester) async {
      final controller = MarkdownSelectionController()
        ..setDocuments(<MarkdownDocumentRef>[
          MarkdownDocumentRef(
              id: 'd', model: Markdown.fromString('Hello selectable world')),
        ]);
      final tl = await pumpParagraph(tester, controller);

      await _clicks(tester, tl + const Offset(8, 8), 3);
      expect(controller.getText(), 'Hello selectable world');
      expect(tester.takeException(), isNull);
    });

    testWidgets('single click clears an existing selection', (tester) async {
      final controller = MarkdownSelectionController()
        ..setDocuments(<MarkdownDocumentRef>[
          MarkdownDocumentRef(
              id: 'd', model: Markdown.fromString('Hello selectable world')),
        ]);
      final tl = await pumpParagraph(tester, controller);

      await _clicks(tester, tl + const Offset(8, 8), 2);
      expect(controller.getText(), isNotEmpty);

      await _clicks(tester, tl + const Offset(8, 8), 1);
      expect(controller.getText(), isEmpty,
          reason: 'a single click collapses the selection');
      expect(tester.takeException(), isNull);
    });

    testWidgets('shift-click extends the selection', (tester) async {
      final controller = MarkdownSelectionController()
        ..setDocuments(<MarkdownDocumentRef>[
          MarkdownDocumentRef(
              id: 'd', model: Markdown.fromString('Hello selectable world')),
        ]);
      final tl = await pumpParagraph(tester, controller);

      // Place a caret near the start, then Shift-click further along.
      await _clicks(tester, tl + const Offset(4, 8), 1);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await _clicks(tester, tl + const Offset(60, 8), 1);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);

      expect(controller.getText(), isNotEmpty,
          reason: 'shift-click should grow a selection from the caret');
      expect(tester.takeException(), isNull);
    });
  });

  group('selection highlight', () {
    testWidgets('paints over an opaque code-block background', (tester) async {
      // Regression: the highlight used to draw BENEATH the block picture, so a
      // code fence's opaque background hid it. It now draws on top.
      final md = Markdown.fromString('```\ncode\n```');
      final controller = MarkdownSelectionController()
        ..setDocuments(
            <MarkdownDocumentRef>[MarkdownDocumentRef(id: 'd', model: md)]);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MarkdownSelectionScope(
            controller: controller,
            selectionColor: const Color(0x80FF0000), // translucent red
            child: const Align(
              alignment: Alignment.topLeft,
              child: RepaintBoundary(
                key: Key('capture'),
                child: SizedBox(width: 400, child: _Doc('d')),
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Select the whole code block.
      final len = markdownBlockRenderedText(md.blocks.first).length;
      controller.selection = MarkdownSelection(
        base: const MarkdownPosition(documentId: 'd', blockIndex: 0, offset: 0),
        extent: MarkdownPosition(documentId: 'd', blockIndex: 0, offset: len),
      );
      await tester.pumpAndSettle();

      // Sample a pixel over the first code glyph (block padding is 8px).
      // `toByteData` drives the engine, so it must run under `runAsync`.
      late final int r, g, b;
      await tester.runAsync(() async {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(const Key('capture')));
        final image = boundary.toImageSync();
        final width = image.width;
        final data = await image.toByteData();
        image.dispose();
        const x = 12, y = 12;
        final i = (y * width + x) * 4;
        r = data!.getUint8(i);
        g = data.getUint8(i + 1);
        b = data.getUint8(i + 2);
      });

      expect(r, greaterThan(g + 20),
          reason: 'the red highlight must tint the code background');
      expect(r, greaterThan(b + 20));
      expect(tester.takeException(), isNull);
    });
  });

  group('selection cursor', () {
    testWidgets('selectable content shows the text (I-beam) cursor',
        (tester) async {
      final controller = MarkdownSelectionController()
        ..setDocuments(<MarkdownDocumentRef>[
          MarkdownDocumentRef(
              id: 'd', model: Markdown.fromString('Selectable text here')),
        ]);
      await tester.pumpWidget(_wrap(
        controller,
        const Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: 400, child: _Doc('d')),
        ),
      ));
      await tester.pumpAndSettle();

      final gesture =
          await tester.createGesture(kind: PointerDeviceKind.mouse, pointer: 1);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(tester.getCenter(find.byType(MarkdownWidget)));
      await tester.pumpAndSettle();

      expect(
        RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
        SystemMouseCursors.text,
      );
    });

    testWidgets('an actionable link shows the click (hand) cursor',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MarkdownTheme(
            data: MarkdownThemeData(
              textStyle: const TextStyle(fontSize: 14),
              onLinkTap: (_, __) {},
            ),
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 400,
                child: MarkdownWidget(
                    markdown:
                        Markdown.fromString('[click me](https://example.com)')),
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final gesture =
          await tester.createGesture(kind: PointerDeviceKind.mouse, pointer: 1);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      // Hover over the link glyphs (near the start of the line).
      await gesture.moveTo(
          tester.getTopLeft(find.byType(MarkdownWidget)) + const Offset(8, 8));
      await tester.pumpAndSettle();

      expect(
        RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
        SystemMouseCursors.click,
      );
    });

    testWidgets('inert content keeps the default cursor', (tester) async {
      final md = Markdown.fromString('Not selectable');
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(width: 400, child: MarkdownWidget(markdown: md)),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final gesture =
          await tester.createGesture(kind: PointerDeviceKind.mouse, pointer: 1);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(tester.getCenter(find.byType(MarkdownWidget)));
      await tester.pumpAndSettle();

      expect(
        RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
        SystemMouseCursors.basic,
      );
    });
  });
}

/// A MarkdownWidget that resolves its controller from the ambient scope.
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
