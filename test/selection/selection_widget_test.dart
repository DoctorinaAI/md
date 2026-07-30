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
