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

    testWidgets('a handle drag past the other edge never collapses',
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
      await tester.pump();
      const full = 'Hello selectable world';
      final before = controller.selection;

      final tl = tester.getTopLeft(find.byType(MarkdownWidget));
      // Drag the START edge past the END (far right) — would collapse, so the
      // move is dropped and the selection is left untouched.
      controller.moveSelectionEdgeToGlobal(tl + const Offset(399, 8),
          isStart: true);
      await tester.pump();
      expect(controller.selection, before,
          reason: 'a collapsing move is a no-op');
      expect(controller.getText(), full);
      expect(controller.selection!.isCollapsed, isFalse);

      // Symmetric: drag the END edge past the START (far left) — also dropped.
      controller.moveSelectionEdgeToGlobal(tl + const Offset(1, 8),
          isStart: false);
      await tester.pump();
      expect(controller.selection, before);
      expect(controller.getText(), full);
      expect(controller.selection!.isCollapsed, isFalse);
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
  });
}
