import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_md/flutter_md.dart';
import 'package:flutter_test/flutter_test.dart';

class _Doc extends StatelessWidget {
  const _Doc(this.id, {this.markdown, super.key});

  final String id;
  final Markdown? markdown;

  @override
  Widget build(BuildContext context) {
    final controller = MarkdownSelectionScope.of(context);
    final model =
        markdown ?? controller.documents.firstWhere((d) => d.id == id).model;
    return MarkdownWidget(markdown: model, documentId: id);
  }
}

Future<void> _mouseDrag(WidgetTester tester, Offset from, Offset to) async {
  final g = await tester.startGesture(from, kind: PointerDeviceKind.mouse);
  await tester.pump(const Duration(milliseconds: 100));
  await g.moveTo(to);
  await tester.pump(const Duration(milliseconds: 100));
  await g.up();
  await tester.pumpAndSettle();
}

void main() {
  group('registry ordering', () {
    test('sparse explicit orders keep their reading order', () {
      final controller = MarkdownSelectionController()
        ..setDocuments(<MarkdownDocumentRef>[
          MarkdownDocumentRef(
            id: 'a',
            model: Markdown.fromString('Alpha'),
            order: 10,
          ),
          MarkdownDocumentRef(
            id: 'b',
            model: Markdown.fromString('Bravo'),
            order: 20,
          ),
        ]);
      addTearDown(controller.dispose);

      expect(controller.documents.map((d) => d.id), <String>['a', 'b']);
    });

    test('an order-less putDocument appends after sparse explicit orders', () {
      final controller = MarkdownSelectionController()
        ..setDocuments(<MarkdownDocumentRef>[
          MarkdownDocumentRef(
            id: 'a',
            model: Markdown.fromString('Alpha'),
            order: 10,
          ),
          MarkdownDocumentRef(
            id: 'b',
            model: Markdown.fromString('Bravo'),
            order: 20,
          ),
        ])
        // The heal-register path on RenderObject.attach passes no order.
        ..putDocument('c', Markdown.fromString('Charlie'));
      addTearDown(controller.dispose);

      expect(
        controller.documents.map((d) => d.id),
        <String>['a', 'b', 'c'],
        reason: 'a document with no order must not jump ahead of ordered ones',
      );
    });

    test('colliding orders keep a stable, registration-based reading order',
        () {
      final controller = MarkdownSelectionController()
        ..setDocuments(<MarkdownDocumentRef>[
          MarkdownDocumentRef(
            id: 'a',
            model: Markdown.fromString('Alpha'),
            order: 1,
          ),
          MarkdownDocumentRef(
            id: 'b',
            model: Markdown.fromString('Bravo'),
            order: 1,
          ),
          MarkdownDocumentRef(
            id: 'c',
            model: Markdown.fromString('Charlie'),
            order: 1,
          ),
        ]);
      addTearDown(controller.dispose);

      final first = controller.documents.map((d) => d.id).toList();
      // Any re-sort (a model update, a new registration) must not reshuffle
      // documents that share an order.
      controller
        ..putDocument('b', Markdown.fromString('Bravo two'), order: 1)
        ..putDocument('d', Markdown.fromString('Delta'), order: 1);
      final second = controller.documents
          .map((d) => d.id)
          .where((id) => id != 'd')
          .toList();

      expect(second, first);
    });

    test('rangeFor returns null for an unregistered document', () {
      final controller = MarkdownSelectionController()
        ..setDocuments(<MarkdownDocumentRef>[
          MarkdownDocumentRef(id: 'a', model: Markdown.fromString('Alpha')),
        ]);
      addTearDown(controller.dispose);

      controller.selection = const MarkdownSelection(
        base: MarkdownPosition(documentId: 'a', blockIndex: 0, offset: 0),
        extent: MarkdownPosition(documentId: 'a', blockIndex: 0, offset: 5),
      );

      expect(controller.rangeFor('a', 0), isNotNull);
      expect(controller.rangeFor('ghost', 0), isNull);
    });

    test('an unregistered endpoint does not paint every registered body', () {
      final controller = MarkdownSelectionController()
        ..setDocuments(<MarkdownDocumentRef>[
          MarkdownDocumentRef(id: 'a', model: Markdown.fromString('Alpha')),
          MarkdownDocumentRef(id: 'b', model: Markdown.fromString('Bravo')),
          MarkdownDocumentRef(id: 'c', model: Markdown.fromString('Charlie')),
        ]);
      addTearDown(controller.dispose);

      controller.selection = const MarkdownSelection(
        base: MarkdownPosition(documentId: 'ghost', blockIndex: 0, offset: 0),
        extent: MarkdownPosition(documentId: 'c', blockIndex: 0, offset: 3),
      );

      expect(controller.rangeFor('a', 0), isNull);
      expect(controller.rangeFor('b', 0), isNull);
      expect(controller.rangeFor('c', 0), isNull);
    });
  });

  group('surface lifecycle', () {
    testWidgets('two surfaces on one id keep the first hittable',
        (tester) async {
      final md = Markdown.fromString('Shared document body');
      final controller = MarkdownSelectionController()
        ..setDocuments(
            <MarkdownDocumentRef>[MarkdownDocumentRef(id: 'd', model: md)]);
      addTearDown(controller.dispose);

      var showSecond = true;
      late StateSetter setStateFn;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MarkdownSelectionScope(
            controller: controller,
            child: StatefulBuilder(builder: (context, setState) {
              setStateFn = setState;
              return Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: 400,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const _Doc('d', key: ValueKey('first')),
                      if (showSecond) const _Doc('d', key: ValueKey('second')),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(MarkdownWidget), findsNWidgets(2));
      expect(controller.mountedSurfaces.length, 1,
          reason: 'one primary surface per document id');

      final firstRect = tester.getRect(find.byKey(const ValueKey('first')));
      final hit = firstRect.topLeft + const Offset(2, 4);
      expect(controller.hitsSelectableContent(hit), isTrue);

      // Dropping the later (overlapping) mount must not unregister the first.
      setStateFn(() => showSecond = false);
      await tester.pumpAndSettle();

      expect(controller.mountedSurfaces.length, 1);
      expect(controller.hitsSelectableContent(hit), isTrue);
    });

    testWidgets('a mounted surface heals a missing registry entry',
        (tester) async {
      final controller = MarkdownSelectionController();
      addTearDown(controller.dispose);
      final md = Markdown.fromString('Never registered by the app');

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MarkdownSelectionScope(
            controller: controller,
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 400,
                child: _Doc('orphan', markdown: md),
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(controller.documents.map((d) => d.id), <String>['orphan']);

      final box = tester.getRect(find.byType(MarkdownWidget));
      await _mouseDrag(
        tester,
        box.topLeft + const Offset(2, 4),
        box.centerRight - const Offset(2, 0),
      );
      expect(controller.getText(), 'Never registered by the app');
    });

    testWidgets('recycling a widget onto another id keeps both models intact',
        (tester) async {
      final a = Markdown.fromString('Alpha body');
      final b = Markdown.fromString('Bravo body');
      final controller = MarkdownSelectionController()
        ..setDocuments(<MarkdownDocumentRef>[
          MarkdownDocumentRef(id: 'a', model: a, order: 0),
          MarkdownDocumentRef(id: 'b', model: b, order: 1),
        ]);
      addTearDown(controller.dispose);

      var showA = true;
      late StateSetter setStateFn;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MarkdownSelectionScope(
            controller: controller,
            child: StatefulBuilder(builder: (context, setState) {
              setStateFn = setState;
              // No key: the element is recycled onto the other document,
              // exactly like ListView.builder reusing a slot while scrolling.
              return Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: 400,
                  child: MarkdownWidget(
                    markdown: showA ? a : b,
                    documentId: showA ? 'a' : 'b',
                  ),
                ),
              );
            }),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      setStateFn(() => showA = false);
      await tester.pumpAndSettle();

      expect(
        controller.documents.firstWhere((d) => d.id == 'a').model.text,
        a.text,
        reason: 'the outgoing document must keep its own model',
      );
      expect(
        controller.documents.firstWhere((d) => d.id == 'b').model.text,
        b.text,
      );
      expect(controller.mountedSurfaces.single.documentId, 'b');
    });

    testWidgets('removeDocument during dispose flushes on detach',
        (tester) async {
      final md = Markdown.fromString('Disappearing body');
      final controller = MarkdownSelectionController()
        ..setDocuments(
            <MarkdownDocumentRef>[MarkdownDocumentRef(id: 'd', model: md)]);
      addTearDown(controller.dispose);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MarkdownSelectionScope(
            controller: controller,
            child: const Align(
              alignment: Alignment.topLeft,
              child: SizedBox(width: 400, child: _Doc('d')),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Parent State.dispose can run before the child render object detaches.
      controller.removeDocument('d');
      expect(controller.documents, hasLength(1),
          reason: 'deferred while the surface is still mounted');

      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      await tester.pumpAndSettle();

      expect(controller.documents, isEmpty);
      expect(controller.mountedSurfaces, isEmpty);
    });

    testWidgets('a virtualized endpoint keeps the highlight while off-screen',
        (tester) async {
      final docs = <MarkdownDocumentRef>[
        for (var i = 0; i < 20; i++)
          MarkdownDocumentRef(
            id: 'm$i',
            model: Markdown.fromString('Message number $i body text'),
            order: i,
          ),
      ];
      final controller = MarkdownSelectionController()..setDocuments(docs);
      addTearDown(controller.dispose);
      final scroll = ScrollController();
      addTearDown(scroll.dispose);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MarkdownSelectionScope(
            controller: controller,
            child: SizedBox(
              height: 200,
              child: ListView.builder(
                controller: scroll,
                itemCount: docs.length,
                itemBuilder: (context, i) => _Doc('m$i'),
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Select from the first message into the third.
      final first = tester.getRect(find.byType(MarkdownWidget).first);
      await _mouseDrag(
        tester,
        first.topLeft + const Offset(2, 4),
        first.bottomRight + const Offset(-2, 40),
      );
      final selected = controller.getText();
      expect(selected, isNotEmpty);
      expect(controller.selection!.base.documentId, 'm0');

      // Scroll the base endpoint out of the cache extent and back.
      scroll.jumpTo(1500);
      await tester.pumpAndSettle();
      expect(controller.selection, isNotNull,
          reason: 'virtualization must not drop the range');
      expect(controller.getText(), selected);
      // No mounted body outside the selected span may paint a highlight.
      for (var i = 10; i < 20; i++) {
        expect(controller.rangeFor('m$i', 0), isNull);
      }

      scroll.jumpTo(0);
      await tester.pumpAndSettle();
      expect(controller.getText(), selected);
      expect(tester.takeException(), isNull);
    });
  });

  group('controller lifecycle', () {
    testWidgets('disposing the controller after the surfaces unmount is safe',
        (tester) async {
      final controller = MarkdownSelectionController()
        ..setDocuments(<MarkdownDocumentRef>[
          MarkdownDocumentRef(
            id: 'd',
            model: Markdown.fromString('Body text'),
          ),
        ]);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MarkdownSelectionScope(
            controller: controller,
            child: const Align(
              alignment: Alignment.topLeft,
              child: SizedBox(width: 400, child: _Doc('d')),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      await tester.pumpAndSettle();
      controller.dispose();

      expect(tester.takeException(), isNull);
    });

    test('a group keeps one selection across controllers', () {
      final group = MarkdownSelectionGroup();
      final a = MarkdownSelectionController(group: group)
        ..setDocuments(<MarkdownDocumentRef>[
          MarkdownDocumentRef(
            id: 'a',
            model: Markdown.fromString('Alpha body'),
          ),
        ]);
      final b = MarkdownSelectionController(group: group)
        ..setDocuments(<MarkdownDocumentRef>[
          MarkdownDocumentRef(
            id: 'b',
            model: Markdown.fromString('Bravo body'),
          ),
        ]);
      addTearDown(a.dispose);
      addTearDown(b.dispose);

      a.selectAll();
      expect(a.selection, isNotNull);
      b.selectAll();
      expect(b.selection, isNotNull);
      expect(a.selection, isNull, reason: 'the group claims exclusivity');
    });

    test('moveSelectionEdgeToGlobal with no mounted surface is a no-op', () {
      final controller = MarkdownSelectionController()
        ..setDocuments(<MarkdownDocumentRef>[
          MarkdownDocumentRef(
            id: 'd',
            model: Markdown.fromString('Body text'),
          ),
        ]);
      addTearDown(controller.dispose);
      controller.selectAll();
      final before = controller.selection;

      controller.moveSelectionEdgeToGlobal(
        const Offset(10, 10),
        isStart: true,
      );

      expect(controller.selection, before);
    });

    test('selectAll over an empty leading document does not throw', () {
      final controller = MarkdownSelectionController()
        ..setDocuments(<MarkdownDocumentRef>[
          MarkdownDocumentRef(id: 'e', model: Markdown.fromString('')),
          MarkdownDocumentRef(id: 'd', model: Markdown.fromString('Body')),
        ]);
      addTearDown(controller.dispose);

      controller.selectAll();

      expect(controller.getText(), isNotNull);
    });
  });

  group('host notification safety', () {
    testWidgets(
        'removeDocument flush during unmount does not crash a host that '
        'setStates from onSelectionChanged', (tester) async {
      final controller = MarkdownSelectionController()
        ..setDocuments(<MarkdownDocumentRef>[
          MarkdownDocumentRef(id: 'd', model: Markdown.fromString('Body text')),
        ]);
      addTearDown(controller.dispose);

      var show = true;
      var changes = 0;
      late StateSetter set;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(builder: (context, setState) {
            set = setState;
            return MarkdownSelectionScope(
              controller: controller,
              onSelectionChanged: (_) => setState(() => changes++),
              child: show
                  ? const Align(
                      alignment: Alignment.topLeft,
                      child: SizedBox(width: 400, child: _Doc('d')),
                    )
                  : const SizedBox.shrink(),
            );
          }),
        ),
      ));
      await tester.pumpAndSettle();

      controller.selectAll();
      await tester.pumpAndSettle();
      expect(controller.selection, isNotNull);

      // App drops the document while the surface is still mounted, then the
      // widget unmounts in the same frame — the deferred remove flushes from
      // RenderObject.detach, inside layout.
      controller.removeDocument('d');
      set(() => show = false);
      await tester.pumpAndSettle();

      expect(controller.selection, isNull);
      expect(changes, greaterThan(0));
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'a streaming model update that reconciles the selection does '
        'not crash a host that setStates from onSelectionChanged',
        (tester) async {
      var model = Markdown.fromString('Hello streaming world');
      final controller = MarkdownSelectionController(
        reconciliation: const MarkdownReconciliationPolicy.clearOnChange(),
      )..setDocuments(
          <MarkdownDocumentRef>[MarkdownDocumentRef(id: 'd', model: model)]);
      addTearDown(controller.dispose);

      var changes = 0;
      late StateSetter set;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(builder: (context, setState) {
            set = setState;
            return MarkdownSelectionScope(
              controller: controller,
              onSelectionChanged: (_) => setState(() => changes++),
              child: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: 400,
                  child: MarkdownWidget(markdown: model, documentId: 'd'),
                ),
              ),
            );
          }),
        ),
      ));
      await tester.pumpAndSettle();

      controller.selectAll();
      await tester.pumpAndSettle();
      expect(controller.selection, isNotNull);
      changes = 0;

      // A streaming token arrives: MarkdownWidget.updateRenderObject pushes the
      // new model into the registry during build, reconciliation drops the
      // range, and the host is notified mid-build.
      set(() => model = Markdown.fromString('Hello streaming world!'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
