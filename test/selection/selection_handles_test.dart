import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
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

Widget _wrap(MarkdownSelectionController controller, Widget child) =>
    MaterialApp(
      home: Scaffold(
        body: MarkdownSelectionScope(controller: controller, child: child),
      ),
    );

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

void main() {
  group('selection handles', () {
    testWidgets('moveSelectionEdgeToGlobal adjusts the moving edge',
        (tester) async {
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

      controller.selectAll();
      final fullLength = controller.getText().length;
      expect(fullLength, 22);

      // Pull the end edge back to near the start of the line.
      final tl = tester.getTopLeft(find.byType(MarkdownWidget));
      controller.moveSelectionEdgeToGlobal(tl + const Offset(40, 8),
          isStart: false);
      await tester.pump();

      final text = controller.getText();
      expect(text.length, lessThan(fullLength));
      expect('Hello selectable world', startsWith(text));
    });

    // Ordered (start, end) rendered-text offsets of a single-block selection.
    (int, int) endpoints(MarkdownSelectionController c) {
      final sel = c.selection!;
      final a = sel.base.offset, b = sel.extent.offset;
      return a <= b ? (a, b) : (b, a);
    }

    testWidgets('moveSelectionEdgeToGlobal(isStart: true) moves only the start',
        (tester) async {
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

      controller.selectAll(); // d#0@0 -> d#0@22
      await tester.pump();
      const full = 'Hello selectable world';
      expect(controller.getText(), full);

      // Drag the reading-order START edge rightwards into the line.
      final tl = tester.getTopLeft(find.byType(MarkdownWidget));
      controller.moveSelectionEdgeToGlobal(tl + const Offset(120, 8),
          isStart: true);
      await tester.pump();

      final (start, end) = endpoints(controller);
      expect(end, 22, reason: 'the end edge stayed fixed at the line end');
      expect(start, greaterThan(0), reason: 'the start edge moved inward');
      expect(start, lessThan(22));
      final text = controller.getText();
      expect(text.length, lessThan(full.length));
      expect(full.endsWith(text), isTrue,
          reason: 'moving the start keeps a suffix of the line');
    });

    testWidgets('moveSelectionEdgeToGlobal(isStart: false) moves only the end',
        (tester) async {
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

      controller.selectAll(); // d#0@0 -> d#0@22
      await tester.pump();
      const full = 'Hello selectable world';

      // Drag the reading-order END edge leftwards into the middle of the line.
      final tl = tester.getTopLeft(find.byType(MarkdownWidget));
      controller.moveSelectionEdgeToGlobal(tl + const Offset(120, 8),
          isStart: false);
      await tester.pump();

      final (start, end) = endpoints(controller);
      expect(start, 0, reason: 'the start edge stayed fixed at the line start');
      expect(end, greaterThan(0), reason: 'the end edge moved inward');
      expect(end, lessThan(22));
      final text = controller.getText();
      expect(text.length, lessThan(full.length));
      expect(full.startsWith(text), isTrue,
          reason: 'moving the end keeps a prefix of the line');
    });

    testWidgets('a handle drag onto the other edge nudges to one character',
        (tester) async {
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

      // Select a mid-word range so both edges can be dragged onto each other.
      controller.selectWordAtGlobal(
        tester.getTopLeft(find.byType(MarkdownWidget)) + const Offset(80, 8),
      );
      await tester.pump();
      expect(controller.getText(), 'selectable');
      expect(controller.selection!.isCollapsed, isFalse);
      final beforeLen = controller.getText().length;

      final tl = tester.getTopLeft(find.byType(MarkdownWidget));
      // Drag the directed START (base) onto the END — must nudge, not collapse.
      final endEndpoints = controller.selectionHandleEndpoints()!;
      controller.moveSelectionEdgeToGlobal(
        Offset(
          endEndpoints.endGlobal.center.dx,
          endEndpoints.endGlobal.center.dy,
        ),
        isStart: true,
      );
      await tester.pump();
      expect(controller.selection!.isCollapsed, isFalse,
          reason: 'directed cross nudges to a one-char minimum');
      expect(controller.getText().length, greaterThan(0));
      expect(controller.getText().length, lessThanOrEqualTo(beforeLen));

      // Symmetric: drag END onto START.
      controller.selectWordAtGlobal(tl + const Offset(80, 8));
      await tester.pump();
      final startEndpoints = controller.selectionHandleEndpoints()!;
      controller.moveSelectionEdgeToGlobal(
        Offset(
          startEndpoints.startGlobal.center.dx,
          startEndpoints.startGlobal.center.dy,
        ),
        isStart: false,
      );
      await tester.pump();
      expect(controller.selection!.isCollapsed, isFalse);
      expect(controller.getText().isNotEmpty, isTrue);
    });

    testWidgets('directed edges may cross and flip reading-order handle sides',
        (tester) async {
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
      controller.selectWordAtGlobal(tl + const Offset(80, 8));
      await tester.pump();
      expect(controller.getText(), 'selectable');
      expect(controller.isSelectionReversed, isFalse);

      // Drag the start (base) past the end into the following word.
      final end = controller.selectionHandleEndpoints()!.endGlobal;
      controller.moveSelectionEdgeToGlobal(
        Offset(end.right + 50, end.center.dy),
        isStart: true,
      );
      await tester.pump();

      expect(controller.selection!.isCollapsed, isFalse);
      expect(controller.isSelectionReversed, isTrue,
          reason: 'base may sit after extent in reading order');
      final endpoints = controller.selectionHandleEndpoints();
      expect(endpoints, isNotNull);
      // Handles stay on directed base/extent — start handle follows base,
      // which is now on the right.
      expect(
          endpoints!.startGlobal.left, greaterThan(endpoints.endGlobal.left));
    });

    testWidgets('touch platform shows draggable handles for a selection',
        (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      // NOTE: reset via try/finally rather than addTearDown — in this Flutter
      // version the framework's debugAssertAllFoundationVarsUnset check runs
      // before user tearDowns, so a tearDown reset arrives too late and fails.
      try {
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

        expect(controller.getText(), isNotEmpty);
        // Exactly two handles (start + end) are composited to follow the
        // content — assert the pair specifically, not merely "some widgets".
        expect(find.byType(CompositedTransformFollower), findsNWidgets(2));
        expect(tester.takeException(), isNull);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets(
        'end handle stays on the soft-wrap line end, not next-line start',
        (tester) async {
      final md = Markdown.fromString(
        'The quick brown fox jumps over the lazy dog and then keeps '
        'running across the whole meadow without stopping at all today.',
      );
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

      final rect = tester.getRect(find.byType(MarkdownWidget));
      // Select from the start to the far right of the first visual line so the
      // end edge lands on a soft-wrap boundary.
      await _mouseDrag(
        tester,
        rect.topLeft + const Offset(2, 8),
        rect.topLeft + Offset(rect.width - 4, 8),
      );
      expect(controller.selection, isNotNull);
      expect(controller.selection!.isCollapsed, isFalse);

      final endpoints = controller.selectionHandleEndpoints();
      expect(endpoints, isNotNull);
      // Upstream affinity / box geometry must keep the end handle on the
      // first line's right edge, not snapped to x≈0 of the next line.
      expect(endpoints!.endLocal.left, greaterThan(rect.width / 2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('reverse drag keeps handles on directed base/extent',
        (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
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

        final rect = tester.getRect(find.byType(MarkdownWidget));
        // Drag right-to-left so base is after extent in reading order.
        await _mouseDrag(
          tester,
          rect.topLeft + Offset(rect.width - 4, 8),
          rect.topLeft + const Offset(4, 8),
        );
        expect(controller.selection, isNotNull);
        expect(controller.selection!.isCollapsed, isFalse);
        expect(controller.isSelectionReversed, isTrue,
            reason: 'authored direction is reverse');

        final endpoints = controller.selectionHandleEndpoints();
        expect(endpoints, isNotNull);
        // Directed start handle follows base (right); end follows extent
        // (left).
        expect(
            endpoints!.startGlobal.left, greaterThan(endpoints.endGlobal.left));
        expect(tester.takeException(), isNull);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('desktop platform shows no selection handles', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      try {
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

        expect(controller.getText(), isNotEmpty);
        expect(find.byType(CompositedTransformFollower), findsNothing);
        expect(tester.takeException(), isNull);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets(
      'handles stay when one selection-end surface unmounts',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        try {
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
                itemCount: 10,
                itemBuilder: (_, i) => SizedBox(
                  height: 80,
                  child: _Doc('m$i'),
                ),
              ),
            ),
          ));
          await tester.pumpAndSettle();

          // Span all docs so after virtualizing m0 away, later surfaces still
          // paint the selection and can host a proxied start handle.
          controller.selectAll();
          await tester.pump();
          expect(controller.getText(), contains('Message number 0'));
          expect(controller.getText(), contains('Message number 9'));
          expect(controller.selectionHandleEndpoints(), isNotNull);
          expect(find.byType(CompositedTransformFollower), findsWidgets);

          scroll.jumpTo(80.0 * 7);
          await tester.pumpAndSettle();
          expect(
            find.byWidgetPredicate(
              (w) => w is MarkdownWidget && w.documentId == 'm0',
            ),
            findsNothing,
          );
          expect(
            find.byWidgetPredicate(
              (w) => w is MarkdownWidget && w.documentId == 'm9',
            ),
            findsOneWidget,
          );

          // Model selection intact; start handle proxied onto still-mounted
          // selected spans (m7–m9).
          expect(controller.getText(), contains('Message number 0'));
          expect(controller.selectionHandleEndpoints(), isNotNull);
          expect(find.byType(CompositedTransformFollower), findsWidgets);
          expect(tester.takeException(), isNull);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );
  });
}
