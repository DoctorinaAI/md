import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_md/flutter_md.dart';
import 'package:flutter_test/flutter_test.dart';

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

Future<void> _mouseDrag(WidgetTester tester, Offset from, Offset to) async {
  final g = await tester.startGesture(from, kind: PointerDeviceKind.mouse);
  await tester.pump(const Duration(milliseconds: 100));
  await g.moveTo(to);
  await tester.pump(const Duration(milliseconds: 100));
  await g.up();
  await tester.pumpAndSettle();
}

List<MarkdownDocumentRef> _messages(int count) => <MarkdownDocumentRef>[
      for (var i = 0; i < count; i++)
        MarkdownDocumentRef(
          id: 'm$i',
          model: Markdown.fromString('Message number $i body text here'),
          order: i,
        ),
    ];

void main() {
  group('handle proxies', () {
    testWidgets('an unmounted base edge proxies onto visible selection',
        (tester) async {
      await _withPlatform(TargetPlatform.android, () async {
        final docs = _messages(30);
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

        // Base in m0, extent far down the list.
        controller.selection = const MarkdownSelection(
          base: MarkdownPosition(documentId: 'm0', blockIndex: 0, offset: 0),
          extent:
              MarkdownPosition(documentId: 'm12', blockIndex: 0, offset: 10),
        );
        await tester.pumpAndSettle();

        // Scroll the base out of the built range; the extent stays visible.
        scroll.jumpTo(600);
        await tester.pumpAndSettle();

        expect(
          controller.selectionEndpointGlobalRect(base: true),
          isNull,
          reason: 'the true base caret is unmounted',
        );
        final endpoints = controller.selectionHandleEndpoints();
        expect(endpoints, isNotNull,
            reason: 'handles must still be placeable via a proxy');
        expect(endpoints!.startGlobal.height, greaterThan(0));
        expect(endpoints.endGlobal.height, greaterThan(0));
        expect(tester.takeException(), isNull);
      });
    });

    testWidgets('both endpoints unmounted still keeps the range',
        (tester) async {
      final docs = _messages(40);
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

      controller.selection = const MarkdownSelection(
        base: MarkdownPosition(documentId: 'm0', blockIndex: 0, offset: 0),
        extent: MarkdownPosition(documentId: 'm2', blockIndex: 0, offset: 5),
      );
      await tester.pumpAndSettle();
      final text = controller.getText();
      expect(text, isNotEmpty);

      scroll.jumpTo(2000);
      await tester.pumpAndSettle();

      expect(controller.getText(), text);
      expect(controller.selectionHandleEndpoints(), isNull,
          reason: 'nothing visible paints the selection any more');
      expect(tester.takeException(), isNull);
    });
  });

  group('desktop context menu', () {
    testWidgets('right-click does not mutate the selection', (tester) async {
      await _withPlatform(TargetPlatform.macOS, () async {
        final controller = MarkdownSelectionController()
          ..setDocuments(<MarkdownDocumentRef>[
            MarkdownDocumentRef(
              id: 'd',
              model: Markdown.fromString('Hello selectable world'),
            ),
          ]);
        addTearDown(controller.dispose);

        await tester.pumpWidget(MaterialApp(
          theme: ThemeData(platform: TargetPlatform.macOS),
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

        final box = tester.getRect(find.byType(MarkdownWidget));
        await _mouseDrag(
          tester,
          box.topLeft + const Offset(2, 4),
          box.topLeft + const Offset(40, 4),
        );
        final before = controller.selection;
        expect(before, isNotNull);

        final g = await tester.startGesture(
          box.centerRight - const Offset(10, 0),
          kind: PointerDeviceKind.mouse,
          buttons: kSecondaryMouseButton,
        );
        await g.up();
        await tester.pumpAndSettle();

        expect(controller.selection, before,
            reason: 'secondary click must not select a word or collapse');
        expect(find.text('Copy'), findsOneWidget);
      });
    });

    testWidgets('a desktop mouse drag does not pop the toolbar',
        (tester) async {
      await _withPlatform(TargetPlatform.linux, () async {
        final controller = MarkdownSelectionController()
          ..setDocuments(<MarkdownDocumentRef>[
            MarkdownDocumentRef(
              id: 'd',
              model: Markdown.fromString('Hello selectable world'),
            ),
          ]);
        addTearDown(controller.dispose);

        late MarkdownSelectionScopeState state;
        await tester.pumpWidget(MaterialApp(
          theme: ThemeData(platform: TargetPlatform.linux),
          home: Scaffold(
            body: MarkdownSelectionScope(
              controller: controller,
              child: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: 400,
                  child: Builder(builder: (context) {
                    state = MarkdownSelectionScope.stateOf(context)!;
                    return const _Doc('d');
                  }),
                ),
              ),
            ),
          ),
        ));
        await tester.pumpAndSettle();

        final box = tester.getRect(find.byType(MarkdownWidget));
        await _mouseDrag(
          tester,
          box.topLeft + const Offset(2, 4),
          box.centerRight - const Offset(2, 0),
        );

        expect(controller.getText(), isNotEmpty);
        expect(state.toolbarIsVisible, isFalse);
        expect(controller.toolbarWanted, isFalse);
      });
    });

    testWidgets('an ancestor scroll dismisses the desktop toolbar',
        (tester) async {
      await _withPlatform(TargetPlatform.linux, () async {
        final docs = _messages(30);
        final controller = MarkdownSelectionController()..setDocuments(docs);
        addTearDown(controller.dispose);
        final scroll = ScrollController();
        addTearDown(scroll.dispose);

        late MarkdownSelectionScopeState state;
        await tester.pumpWidget(MaterialApp(
          theme: ThemeData(platform: TargetPlatform.linux),
          home: Scaffold(
            body: MarkdownSelectionScope(
              controller: controller,
              child: SizedBox(
                height: 200,
                child: Builder(builder: (context) {
                  state = MarkdownSelectionScope.stateOf(context)!;
                  return ListView.builder(
                    controller: scroll,
                    itemCount: docs.length,
                    itemBuilder: (context, i) => _Doc('m$i'),
                  );
                }),
              ),
            ),
          ),
        ));
        await tester.pumpAndSettle();

        final first = tester.getRect(find.byType(MarkdownWidget).first);
        await _mouseDrag(
          tester,
          first.topLeft + const Offset(2, 4),
          first.topLeft + const Offset(60, 4),
        );
        state.showToolbar(first.center);
        await tester.pumpAndSettle();
        expect(state.toolbarIsVisible, isTrue);

        scroll.jumpTo(120);
        await tester.pumpAndSettle();

        expect(state.toolbarIsVisible, isFalse);
      });
    });
  });

  group('enabled flag', () {
    testWidgets('disabling hides chrome and enabling restores it',
        (tester) async {
      await _withPlatform(TargetPlatform.android, () async {
        final controller = MarkdownSelectionController()
          ..setDocuments(<MarkdownDocumentRef>[
            MarkdownDocumentRef(
              id: 'd',
              model: Markdown.fromString('Hello selectable world'),
            ),
          ]);
        addTearDown(controller.dispose);

        var enabled = true;
        late StateSetter setStateFn;
        late MarkdownSelectionScopeState state;

        await tester.pumpWidget(MaterialApp(
          theme: ThemeData(platform: TargetPlatform.android),
          home: Scaffold(
            body: StatefulBuilder(builder: (context, setState) {
              setStateFn = setState;
              return MarkdownSelectionScope(
                controller: controller,
                enabled: enabled,
                child: Align(
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    width: 400,
                    child: Builder(builder: (context) {
                      state = MarkdownSelectionScope.stateOf(context)!;
                      return const _Doc('d');
                    }),
                  ),
                ),
              );
            }),
          ),
        ));
        await tester.pumpAndSettle();

        controller.selectAll();
        await tester.pumpAndSettle();
        expect(controller.toolbarWanted, isTrue);
        expect(state.selectionHandleLeadersAttached, isTrue);

        setStateFn(() => enabled = false);
        await tester.pumpAndSettle();
        expect(state.toolbarIsVisible, isFalse);
        expect(state.selectionHandleLeadersAttached, isFalse);
        expect(controller.toolbarWanted, isTrue,
            reason: 'the restore intent survives a disable');

        setStateFn(() => enabled = true);
        await tester.pumpAndSettle();
        expect(state.selectionHandleLeadersAttached, isTrue);
      });
    });

    testWidgets('a disabled scope does not select on drag', (tester) async {
      final controller = MarkdownSelectionController()
        ..setDocuments(<MarkdownDocumentRef>[
          MarkdownDocumentRef(
            id: 'd',
            model: Markdown.fromString('Hello selectable world'),
          ),
        ]);
      addTearDown(controller.dispose);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MarkdownSelectionScope(
            controller: controller,
            enabled: false,
            child: const Align(
              alignment: Alignment.topLeft,
              child: SizedBox(width: 400, child: _Doc('d')),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final box = tester.getRect(find.byType(MarkdownWidget));
      await _mouseDrag(
        tester,
        box.topLeft + const Offset(2, 4),
        box.centerRight - const Offset(2, 0),
      );

      expect(controller.selection, isNull);
    });
  });

  group('autoscroll through virtualization', () {
    testWidgets('dragging to the edge builds and selects new messages',
        (tester) async {
      final docs = _messages(60);
      final controller = MarkdownSelectionController()..setDocuments(docs);
      addTearDown(controller.dispose);
      final scroll = ScrollController();
      addTearDown(scroll.dispose);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MarkdownSelectionScope(
            controller: controller,
            autoscroll: const MarkdownSelectionAutoscrollConfig(
              edgeZone: 40,
              maxVelocity: 3000,
              useMediaQueryPadding: false,
            ),
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

      final viewport = tester.getRect(find.byType(Scrollable));
      final gesture = await tester.startGesture(
        viewport.topLeft + const Offset(4, 6),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump(const Duration(milliseconds: 20));
      await gesture.moveTo(Offset(viewport.center.dx, viewport.bottom - 4));
      // Hold at the edge across many frames: items attach and detach
      // underneath the pointer while the selection keeps extending.
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pumpAndSettle();

      expect(scroll.offset, greaterThan(0));
      expect(controller.selection, isNotNull);
      expect(controller.selection!.base.documentId, 'm0');
      expect(controller.selection!.extent.documentId, isNot('m0'),
          reason: 'the drag must have extended across messages');
      expect(tester.takeException(), isNull);
    });

    testWidgets('the ticker stops when the drag ends', (tester) async {
      final docs = _messages(40);
      final controller = MarkdownSelectionController()..setDocuments(docs);
      addTearDown(controller.dispose);
      final scroll = ScrollController();
      addTearDown(scroll.dispose);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MarkdownSelectionScope(
            controller: controller,
            autoscroll: const MarkdownSelectionAutoscrollConfig(
              edgeZone: 40,
              maxVelocity: 3000,
              useMediaQueryPadding: false,
            ),
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

      final viewport = tester.getRect(find.byType(Scrollable));
      final gesture = await tester.startGesture(
        viewport.topLeft + const Offset(4, 6),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump(const Duration(milliseconds: 20));
      await gesture.moveTo(Offset(viewport.center.dx, viewport.bottom - 4));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pumpAndSettle();

      final settled = scroll.offset;
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(scroll.offset, settled,
          reason: 'the frame ticker must not outlive the drag');
    });
  });
}
