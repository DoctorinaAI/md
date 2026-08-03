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

    testWidgets('touch platform shows draggable handles for a selection',
        (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
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
      // Two handles are composited to follow the content.
      expect(find.byType(CompositedTransformFollower), findsWidgets);
      expect(tester.takeException(), isNull);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('desktop platform shows no selection handles', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
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
      debugDefaultTargetPlatformOverride = null;
    });
  });
}
