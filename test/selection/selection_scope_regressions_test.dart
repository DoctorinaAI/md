import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_md/flutter_md.dart';
import 'package:flutter_test/flutter_test.dart';

MarkdownSelectionController _ctrl(String text) => MarkdownSelectionController()
  ..setDocuments(<MarkdownDocumentRef>[
    MarkdownDocumentRef(id: 'd', model: Markdown.fromString(text)),
  ]);

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

Widget _app(
  MarkdownSelectionController c, {
  bool enabled = true,
  bool Function(Offset)? canStart,
  String? text,
}) =>
    MaterialApp(
      home: Scaffold(
        body: MarkdownSelectionScope(
          controller: c,
          enabled: enabled,
          canStartSelectionAt: canStart,
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 400,
              child: MarkdownWidget(
                markdown: Markdown.fromString(
                  text ?? 'Hello selectable world of markdown text',
                ),
                documentId: 'd',
              ),
            ),
          ),
        ),
      ),
    );

const _range = MarkdownSelection(
  base: MarkdownPosition(documentId: 'd', blockIndex: 0, offset: 0),
  extent: MarkdownPosition(documentId: 'd', blockIndex: 0, offset: 5),
);

const _widerRange = MarkdownSelection(
  base: MarkdownPosition(documentId: 'd', blockIndex: 0, offset: 0),
  extent: MarkdownPosition(documentId: 'd', blockIndex: 0, offset: 6),
);

MarkdownSelectionScopeState _state(WidgetTester t) =>
    t.state<MarkdownSelectionScopeState>(find.byType(MarkdownSelectionScope));

void main() {
  group('Selection scope regressions', () {
    testWidgets('disabling mid long-press aborts the drag', (tester) async {
      await _withPlatform(TargetPlatform.android, () async {
        final c = _ctrl('Hello selectable world of markdown text');
        addTearDown(c.dispose);
        await tester.pumpWidget(_app(c));
        await tester.pumpAndSettle();
        final box = tester.getRect(find.byType(MarkdownWidget));

        final g = await tester.startGesture(box.topLeft + const Offset(20, 8));
        await tester.pump(const Duration(milliseconds: 700));
        expect(c.selection, isNotNull);
        // Host disables the scope while the finger is still down.
        await tester.pumpWidget(_app(c, enabled: false));
        await g.up();
        await tester.pumpAndSettle();
        await tester.pumpWidget(_app(c));
        await tester.pumpAndSettle();

        // Programmatic range on mobile normally presents toolbar + handles.
        c.selection = const MarkdownSelection(
          base: MarkdownPosition(documentId: 'd', blockIndex: 0, offset: 6),
          extent: MarkdownPosition(documentId: 'd', blockIndex: 0, offset: 16),
        );
        await tester.pumpAndSettle();
        expect(c.toolbarWanted, isTrue);
        expect(find.byType(CompositedTransformFollower), findsNWidgets(2),
            reason: 'handles stay hidden: _deferHandleShow never reset');
        expect(_state(tester).toolbarIsVisible, isTrue,
            reason: 'toolbar restore skipped: _dragGlobal never reset');
      });
    });

    testWidgets('long-press then programmatic range shows handles',
        (tester) async {
      await _withPlatform(TargetPlatform.android, () async {
        final c = _ctrl('Hello selectable world of markdown text');
        addTearDown(c.dispose);
        await tester.pumpWidget(_app(c));
        await tester.pumpAndSettle();
        c.selection = _range;
        await tester.pumpAndSettle();
        expect(find.byType(CompositedTransformFollower), findsNWidgets(2));
        expect(_state(tester).toolbarIsVisible, isTrue);
      });
    });

    testWidgets('controller swap removes the old toolbar', (tester) async {
      await _withPlatform(TargetPlatform.android, () async {
        final a = _ctrl('Hello selectable world of markdown text');
        final b = _ctrl('Hello selectable world of markdown text');
        addTearDown(a.dispose);
        addTearDown(b.dispose);
        await tester.pumpWidget(_app(a));
        await tester.pumpAndSettle();
        a.selection = _range;
        await tester.pumpAndSettle();
        expect(_state(tester).toolbarIsVisible, isTrue);

        await tester.pumpWidget(_app(b));
        await tester.pumpAndSettle();
        expect(b.selection, isNull);
        expect(_state(tester).toolbarIsVisible, isFalse,
            reason: 'menu for controller A must not survive swap to B');
      });
    });

    testWidgets('desktop right-click menu survives a streamed update',
        (tester) async {
      await _withPlatform(TargetPlatform.macOS, () async {
        final c = _ctrl('Hello selectable world');
        addTearDown(c.dispose);
        await tester.pumpWidget(_app(c, text: 'Hello selectable world'));
        await tester.pumpAndSettle();
        final box = tester.getRect(find.byType(MarkdownWidget));
        final p = box.topLeft + const Offset(20, 8);
        final g = await tester.startGesture(p,
            kind: PointerDeviceKind.mouse, buttons: kSecondaryButton);
        await g.up();
        await tester.pumpAndSettle();
        expect(_state(tester).toolbarIsVisible, isTrue);

        // A streaming chunk lands in an unrelated way (same doc grows).
        c.putDocument('d', Markdown.fromString('Hello selectable world!'));
        await tester.pumpAndSettle();
        expect(_state(tester).toolbarIsVisible, isTrue,
            reason: 'desktop right-click menu must survive a document update');
      });
    });

    testWidgets('desktop right-click menu survives a resize', (tester) async {
      await _withPlatform(TargetPlatform.macOS, () async {
        final c = _ctrl('Hello selectable world');
        addTearDown(c.dispose);
        await tester.pumpWidget(_app(c, text: 'Hello selectable world'));
        await tester.pumpAndSettle();
        final box = tester.getRect(find.byType(MarkdownWidget));
        final g = await tester.startGesture(box.topLeft + const Offset(20, 8),
            kind: PointerDeviceKind.mouse, buttons: kSecondaryButton);
        await g.up();
        await tester.pumpAndSettle();
        expect(_state(tester).toolbarIsVisible, isTrue);

        // Widget-side growth only (streaming), no controller notify needed.
        await tester.pumpWidget(
            _app(c, text: 'Hello selectable world\n\nand a second paragraph'));
        await tester.pumpAndSettle();
        expect(_state(tester).toolbarIsVisible, isTrue,
            reason: 'desktop right-click menu must survive a size change');
      });
    });

    testWidgets('long press on host-refused chrome shows no toolbar',
        (tester) async {
      await _withPlatform(TargetPlatform.android, () async {
        final c = _ctrl('Hello selectable world of markdown text');
        addTearDown(c.dispose);
        late Rect box;
        await tester
            .pumpWidget(_app(c, canStart: (g) => g.dx < box.left + 100));
        await tester.pumpAndSettle();
        box = tester.getRect(find.byType(MarkdownWidget));
        c.selection = _range;
        await tester.pumpAndSettle();
        _state(tester).hideToolbar();
        await tester.pumpAndSettle();
        expect(_state(tester).toolbarIsVisible, isFalse);

        // Long-press where the host refuses selection (e.g. a link).
        final g = await tester.startGesture(box.topLeft + const Offset(200, 8));
        await tester.pump(const Duration(milliseconds: 700));
        await g.up();
        await tester.pumpAndSettle();
        expect(c.selection, _range);
        expect(_state(tester).toolbarIsVisible, isFalse,
            reason: 'refused long press must not present our toolbar');
      });
    });

    testWidgets('Esc with no selection reaches the enclosing dialog',
        (tester) async {
      final c = _ctrl('Hello');
      addTearDown(c.dispose);
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => Dialog(
                child: MarkdownSelectionScope(
                  controller: c,
                  focusNode: focus,
                  child: MarkdownWidget(
                    markdown: Markdown.fromString('Hello'),
                    documentId: 'd',
                  ),
                ),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      focus.requestFocus();
      await tester.pump();
      expect(c.selection, isNull);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing,
          reason: 'Esc with nothing selected should fall through');
    });
  });
  group('teardown', () {
    // A host clears the controller from a body's dispose (chat_scroll_view
    // does, when a message leaves the list). The scope above that body is
    // deactivated by then and still listening: its listener must not look up
    // an ancestor (Theme.of) or the clear throws.
    for (final platform in <TargetPlatform>[
      TargetPlatform.android,
      TargetPlatform.macOS,
    ]) {
      testWidgets(
          'a clear from a disposing child does not look up ancestors '
          '(${platform.name})', (tester) async {
        await _withPlatform(platform, () async {
          final c = _ctrl('Hello selectable world');
          addTearDown(c.dispose);
          await tester.pumpWidget(MaterialApp(
            home: MarkdownSelectionScope(
              controller: c,
              child: _ClearOnDispose(c),
            ),
          ));
          c.selection = const MarkdownSelection(
            base: MarkdownPosition(documentId: 'd', blockIndex: 0, offset: 0),
            extent: MarkdownPosition(documentId: 'd', blockIndex: 0, offset: 5),
          );
          await tester.pump();

          await tester.pumpWidget(const SizedBox());
          expect(tester.takeException(), isNull);
          expect(c.selection, isNull);
        });
      });

      // The listener takes other branches with a live range: the toolbar
      // restore and the overlay sync, both of which reach for the context.
      testWidgets(
          're-registering a document from a disposing child keeps the range '
          '(${platform.name})', (tester) async {
        await _withPlatform(platform, () async {
          final c = _ctrl('Hello selectable world');
          addTearDown(c.dispose);
          await tester.pumpWidget(MaterialApp(
            home: MarkdownSelectionScope(
              controller: c,
              child: _OnDispose(() {
                c.putDocument(
                  'd',
                  Markdown.fromString('Hello selectable world, updated'),
                );
                c.toolbarWanted = true;
              }),
            ),
          ));
          c.selection = _range;
          await tester.pump();

          await tester.pumpWidget(const SizedBox());
          await tester.pump();
          expect(tester.takeException(), isNull);
          expect(c.selection, _range);
        });
      });

      testWidgets(
          'removing the document from a disposing child does not look up '
          'ancestors (${platform.name})', (tester) async {
        await _withPlatform(platform, () async {
          final c = _ctrl('Hello selectable world');
          addTearDown(c.dispose);
          await tester.pumpWidget(MaterialApp(
            home: MarkdownSelectionScope(
              controller: c,
              child: _OnDispose(() => c.removeDocument('d')),
            ),
          ));
          c.selection = _range;
          await tester.pump();

          await tester.pumpWidget(const SizedBox());
          await tester.pump();
          expect(tester.takeException(), isNull);
        });
      });
    }

    testWidgets('a scope that outlives the disposing child still works',
        (tester) async {
      final c = _ctrl('Hello selectable world');
      addTearDown(c.dispose);
      Widget app({required bool child}) => MaterialApp(
            theme: ThemeData(platform: TargetPlatform.android),
            home: MarkdownSelectionScope(
              controller: c,
              child: child ? _OnDispose(c.clear) : const SizedBox(),
            ),
          );
      await tester.pumpWidget(app(child: true));
      c.selection = _range;
      await tester.pump();

      await tester.pumpWidget(app(child: false));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(c.selection, isNull);

      c.selection = _range;
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('platform', () {
    Finder handles() => find.byWidgetPredicate(
          (w) => w.runtimeType.toString().contains('SelectionHandleOverlay'),
        );

    Widget app(
      MarkdownSelectionController c,
      TargetPlatform platform, {
      Key? scopeKey,
    }) =>
        MaterialApp(
          theme: ThemeData(platform: platform),
          home: Scaffold(
            body: MarkdownSelectionScope(
              key: scopeKey,
              controller: c,
              child: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: 400,
                  child: MarkdownWidget(
                    markdown: Markdown.fromString('Hello selectable world'),
                    documentId: 'd',
                    controller: c,
                  ),
                ),
              ),
            ),
          ),
        );

    testWidgets('follows a theme platform change while mounted',
        (tester) async {
      final c = _ctrl('Hello selectable world');
      addTearDown(c.dispose);
      await tester.pumpWidget(app(c, TargetPlatform.android));
      await tester.pumpAndSettle();
      c.selection = _range;
      await tester.pumpAndSettle();
      expect(handles(), findsWidgets, reason: 'android shows handles');

      await tester.pumpWidget(app(c, TargetPlatform.macOS));
      await tester.pumpAndSettle();
      c.selection = _widerRange;
      await tester.pumpAndSettle();
      expect(handles(), findsNothing, reason: 'macOS has none');

      await tester.pumpWidget(app(c, TargetPlatform.android));
      await tester.pumpAndSettle();
      c.selection = _range;
      await tester.pumpAndSettle();
      expect(handles(), findsWidgets, reason: 'back on android');
      expect(tester.takeException(), isNull);
    });

    testWidgets('reads the platform of a new parent after a reparent',
        (tester) async {
      final c = _ctrl('Hello selectable world');
      addTearDown(c.dispose);
      final key = GlobalKey<MarkdownSelectionScopeState>();
      Widget scope() => MarkdownSelectionScope(
            key: key,
            controller: c,
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 400,
                child: MarkdownWidget(
                  markdown: Markdown.fromString('Hello selectable world'),
                  documentId: 'd',
                  controller: c,
                ),
              ),
            ),
          );
      Widget tree({required bool moved}) => MaterialApp(
            theme: ThemeData(platform: TargetPlatform.macOS),
            home: Scaffold(
              body: Column(
                children: <Widget>[
                  Expanded(child: moved ? const SizedBox() : scope()),
                  Expanded(
                    child: Theme(
                      data: ThemeData(platform: TargetPlatform.android),
                      child: moved ? scope() : const SizedBox(),
                    ),
                  ),
                ],
              ),
            ),
          );
      await tester.pumpWidget(tree(moved: false));
      await tester.pumpAndSettle();
      c.selection = _range;
      await tester.pumpAndSettle();
      expect(handles(), findsNothing);

      await tester.pumpWidget(tree(moved: true));
      await tester.pumpAndSettle();
      c.selection = _widerRange;
      await tester.pumpAndSettle();
      expect(handles(), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });
}

/// Runs [callback] from `dispose`, like a chat body that leaves the list.
class _OnDispose extends StatefulWidget {
  const _OnDispose(this.callback);

  final VoidCallback callback;

  @override
  State<_OnDispose> createState() => _OnDisposeState();
}

class _OnDisposeState extends State<_OnDispose> {
  @override
  void dispose() {
    widget.callback();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

/// Clears [controller] when it is disposed, like a chat body that leaves the
/// list.
class _ClearOnDispose extends StatefulWidget {
  const _ClearOnDispose(this.controller);

  final MarkdownSelectionController controller;

  @override
  State<_ClearOnDispose> createState() => _ClearOnDisposeState();
}

class _ClearOnDisposeState extends State<_ClearOnDispose> {
  @override
  void dispose() {
    widget.controller.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}
