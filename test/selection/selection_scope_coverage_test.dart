import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_md/flutter_md.dart';
import 'package:flutter_test/flutter_test.dart';

const String _text = 'Hello selectable world of markdown text';

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

MarkdownSelectionController _ctrl(
  WidgetTester tester, [
  List<String> ids = const <String>['d'],
  String text = _text,
]) {
  final controller = MarkdownSelectionController()
    ..setDocuments(<MarkdownDocumentRef>[
      for (var i = 0; i < ids.length; i++)
        MarkdownDocumentRef(
          id: ids[i],
          model: Markdown.fromString(text),
          order: i,
        ),
    ]);
  addTearDown(controller.dispose);
  return controller;
}

/// A single 400px-wide document pinned to the top-left.
Widget _app(
  MarkdownSelectionController c, {
  bool enabled = true,
  FocusNode? focusNode,
  bool Function(Offset)? canStart,
  bool Function(Object)? owns,
  TextMagnifierConfiguration? magnifier,
  ThemeData? theme,
  MarkdownSelectionContextMenuBuilder? menu = _passThroughMenu,
  MarkdownSelectionAutoscrollConfig autoscroll =
      const MarkdownSelectionAutoscrollConfig(),
}) =>
    MaterialApp(
      theme: theme,
      home: Scaffold(
        body: MarkdownSelectionScope(
          controller: c,
          enabled: enabled,
          focusNode: focusNode,
          canStartSelectionAt: canStart,
          ownsSelectionChrome: owns,
          magnifierConfiguration: magnifier,
          contextMenuBuilder: menu,
          autoscroll: autoscroll,
          child: const Align(
            alignment: Alignment.topLeft,
            child: SizedBox(width: 400, child: _Doc('d')),
          ),
        ),
      ),
    );

/// A 200px-tall list of [ids] documents (plus trailing room to scroll).
Widget _listApp(
  MarkdownSelectionController c,
  ScrollController scroll, {
  List<String> ids = const <String>['d'],
  ThemeData? theme,
  MarkdownSelectionAutoscrollConfig autoscroll =
      const MarkdownSelectionAutoscrollConfig(
    edgeZone: 40,
    maxVelocity: 600,
    useMediaQueryPadding: false,
  ),
}) =>
    MaterialApp(
      theme: theme,
      home: Scaffold(
        body: MarkdownSelectionScope(
          controller: c,
          autoscroll: autoscroll,
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 400,
              height: 200,
              child: ListView(
                controller: scroll,
                children: <Widget>[
                  for (final id in ids) _Doc(id),
                  const SizedBox(height: 3000),
                ],
              ),
            ),
          ),
        ),
      ),
    );

MarkdownSelectionScopeState _state(WidgetTester t) =>
    t.state<MarkdownSelectionScopeState>(
      find.byType(MarkdownSelectionScope).first,
    );

Rect _docRect(WidgetTester t, [int index = 0]) =>
    t.getRect(find.byType(MarkdownWidget).at(index));

/// A point on the word "selectable" of the first line.
Offset _onWord(WidgetTester t) => _docRect(t).topLeft + const Offset(120, 7);

/// A toolbar that never absorbs pointers, so repeated taps / right-clicks at
/// one spot always reach the scope rather than the menu drawn over it.
Widget _passThroughMenu(BuildContext context, MarkdownSelectionScopeState s) =>
    const IgnorePointer(child: SizedBox(key: ValueKey('menu')));

Future<void> _rightClick(WidgetTester tester, Offset at) async {
  await tester.tapAt(
    at,
    buttons: kSecondaryMouseButton,
    kind: PointerDeviceKind.mouse,
  );
  await tester.pump();
}

/// Mouse drag from [from] to [to], holding [frames] frames at the end.
Future<void> _mouseDragHold(
  WidgetTester tester,
  Offset from,
  Offset to, {
  int frames = 20,
}) async {
  final g = await tester.startGesture(from, kind: PointerDeviceKind.mouse);
  await tester.pump(const Duration(milliseconds: 20));
  await g.moveTo(to);
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
  await g.up();
  await tester.pumpAndSettle();
}

void main() {
  group('Selection scope coverage', () {
    group('didUpdateWidget', () {
      testWidgets('focus listener follows a swapped focus node',
          (tester) async {
        final controller = _ctrl(tester);
        final first = FocusNode(debugLabel: 'first');
        final second = FocusNode(debugLabel: 'second');
        addTearDown(first.dispose);
        addTearDown(second.dispose);

        await tester.pumpWidget(_app(controller, focusNode: first));
        await tester.pumpAndSettle();
        await tester.pumpWidget(_app(controller, focusNode: second));
        await tester.pumpAndSettle();

        // selectAll focuses the scope's *current* node.
        _state(tester).selectAll();
        await tester.pump();
        expect(second.hasFocus, isTrue);
        expect(first.hasFocus, isFalse);
        expect(controller.selection, isNotNull);

        // Losing focus on the new node clears: the listener moved with it.
        second.unfocus();
        await tester.pump();
        expect(controller.selection, isNull);
      });

      testWidgets('a new autoscroll config is used by the next drag',
          (tester) async {
        final controller = _ctrl(tester);
        final scroll = ScrollController();
        addTearDown(scroll.dispose);
        var firstCalls = 0;
        var secondCalls = 0;
        // Resolvers returning null: no target, so nothing may scroll.
        MarkdownSelectionAutoscrollConfig config(void Function() onCall) =>
            MarkdownSelectionAutoscrollConfig(
              edgeZone: 40,
              useMediaQueryPadding: false,
              targetResolver: (_) {
                onCall();
                return null;
              },
            );

        await tester.pumpWidget(_listApp(
          controller,
          scroll,
          autoscroll: config(() => firstCalls++),
        ));
        await tester.pumpAndSettle();
        final viewport = tester.getRect(find.byType(Scrollable));
        final from = _docRect(tester).topLeft + const Offset(4, 6);
        final to = Offset(viewport.center.dx, viewport.bottom - 2);

        await _mouseDragHold(tester, from, to);
        expect(firstCalls, greaterThan(0));
        expect(scroll.offset, 0, reason: 'null target must not scroll');
        expect(controller.selection!.isCollapsed, isFalse);

        await tester.pumpWidget(_listApp(
          controller,
          scroll,
          autoscroll: config(() => secondCalls++),
        ));
        await tester.pumpAndSettle();
        final before = firstCalls;
        await _mouseDragHold(tester, from, to);
        expect(secondCalls, greaterThan(0));
        expect(firstCalls, before, reason: 'old resolver must be dropped');
        expect(scroll.offset, 0);
      });

      testWidgets('a disabled autoscroll config never scrolls', (tester) async {
        final controller = _ctrl(tester);
        final scroll = ScrollController();
        addTearDown(scroll.dispose);
        await tester.pumpWidget(_listApp(
          controller,
          scroll,
          autoscroll: MarkdownSelectionAutoscrollConfig.disabled,
        ));
        await tester.pumpAndSettle();
        final viewport = tester.getRect(find.byType(Scrollable));
        await _mouseDragHold(
          tester,
          _docRect(tester).topLeft + const Offset(4, 6),
          Offset(viewport.center.dx, viewport.bottom - 2),
          frames: 30,
        );
        expect(scroll.offset, 0);
        expect(controller.selection!.isCollapsed, isFalse,
            reason: 'the drag still selects');
      });
    });

    group('toolbar', () {
      testWidgets('iOS: tapping the active selection toggles the toolbar',
          (tester) async {
        await _withPlatform(TargetPlatform.iOS, () async {
          final controller = _ctrl(tester);
          await tester.pumpWidget(_app(controller));
          await tester.pumpAndSettle();

          controller.selectWordAtGlobal(_onWord(tester));
          await tester.pumpAndSettle();
          final selected = controller.selection;
          expect(controller.getText(), 'selectable');
          expect(_state(tester).toolbarIsVisible, isFalse);

          await tester.tapAt(_onWord(tester));
          await tester.pump(const Duration(milliseconds: 500));
          expect(_state(tester).toolbarIsVisible, isTrue);
          expect(controller.selection, selected,
              reason: 'the tap must not collapse the range');

          await tester.tapAt(_onWord(tester));
          await tester.pump(const Duration(milliseconds: 500));
          expect(_state(tester).toolbarIsVisible, isFalse);
          expect(controller.selection, selected);
        });
      });

      testWidgets('showToolbar while disabled keeps only the intent',
          (tester) async {
        final controller = _ctrl(tester);
        await tester.pumpWidget(_app(controller, enabled: false));
        await tester.pumpAndSettle();
        controller.selectAll();
        await tester.pump();

        _state(tester).showToolbar();
        await tester.pump();
        expect(_state(tester).toolbarIsVisible, isFalse);
        expect(controller.toolbarWanted, isTrue);

        await tester.pumpWidget(_app(controller));
        await tester.pumpAndSettle();
        expect(_state(tester).toolbarIsVisible, isTrue,
            reason: 'enabling restores the wanted toolbar');
      });

      testWidgets('showToolbar for a foreign document stays hidden',
          (tester) async {
        final controller = _ctrl(tester);
        await tester.pumpWidget(_app(controller, owns: (_) => false));
        await tester.pumpAndSettle();
        controller.selectAll();
        await tester.pump();

        _state(tester).showToolbar();
        await tester.pump();
        expect(_state(tester).toolbarIsVisible, isFalse);
        expect(controller.toolbarWanted, isTrue);
      });

      testWidgets('enabling a non-owning scope does not restore the toolbar',
          (tester) async {
        final controller = _ctrl(tester);
        await tester.pumpWidget(
          _app(controller, enabled: false, owns: (_) => false),
        );
        await tester.pumpAndSettle();
        controller
          ..selectAll()
          ..toolbarWanted = true;
        await tester.pump();

        await tester.pumpWidget(_app(controller, owns: (_) => false));
        await tester.pumpAndSettle();
        expect(_state(tester).toolbarIsVisible, isFalse);
        expect(controller.toolbarWanted, isTrue,
            reason: 'the owning scope may still restore it');
      });

      testWidgets('showToolbar with the selection scrolled away defers',
          (tester) async {
        final controller = _ctrl(tester);
        final scroll = ScrollController();
        addTearDown(scroll.dispose);
        await tester.pumpWidget(_listApp(controller, scroll));
        await tester.pumpAndSettle();
        controller.selectWordAtGlobal(_onWord(tester));
        await tester.pump();
        scroll.jumpTo(1000);
        await tester.pumpAndSettle();

        _state(tester).showToolbar();
        await tester.pump();
        expect(_state(tester).toolbarIsVisible, isFalse);
        expect(controller.toolbarWanted, isTrue);
      });
    });

    group('toolbar anchors', () {
      Future<TextSelectionToolbarAnchors> anchorsWithBaseOffscreen(
        WidgetTester tester, {
        ThemeData? theme,
      }) async {
        final controller =
            _ctrl(tester, <String>['a', 'b', 'c', 'd', 'e', 'f']);
        final scroll = ScrollController();
        addTearDown(scroll.dispose);
        await tester.pumpWidget(_listApp(
          controller,
          scroll,
          ids: const <String>['a', 'b', 'c', 'd', 'e', 'f'],
          theme: theme,
        ));
        await tester.pumpAndSettle();
        controller.selectAll();
        await tester.pump();
        // Base (top of "a") scrolls out; extent stays inside the viewport.
        final docHeight = _docRect(tester).height;
        scroll.jumpTo(docHeight * 4.5);
        await tester.pumpAndSettle();
        final extent = controller.selectionEndpointGlobalRect(base: false);
        final viewport = tester.getRect(find.byType(Scrollable));
        expect(extent, isNotNull);
        expect(viewport.overlaps(extent!), isTrue);
        return _state(tester).contextMenuAnchors;
      }

      testWidgets('iOS parks the primary anchor at the screen top',
          (tester) async {
        await _withPlatform(TargetPlatform.iOS, () async {
          final anchors = await anchorsWithBaseOffscreen(tester);
          expect(anchors.primaryAnchor.dy, 8,
              reason: 'touch forces the below placement');
          expect(anchors.secondaryAnchor!.dy,
              greaterThan(anchors.primaryAnchor.dy));
        });
      });

      testWidgets('mobile theme on a desktop target anchors below only',
          (tester) async {
        // Mobile theme (not a desktop menu) on a desktop target platform.
        await _withPlatform(TargetPlatform.linux, () async {
          final anchors = await anchorsWithBaseOffscreen(
            tester,
            theme: ThemeData(platform: TargetPlatform.android),
          );
          expect(anchors.primaryAnchor, anchors.secondaryAnchor);
        });
      });
    });

    group('handles', () {
      testWidgets('dragging the start handle moves the start + magnifies',
          (tester) async {
        await _withPlatform(TargetPlatform.android, () async {
          final infos = <MagnifierInfo>[];
          final magnifier = TextMagnifierConfiguration(
            magnifierBuilder: (context, controller, info) {
              infos.add(info.value);
              info.addListener(() => infos.add(info.value));
              return const SizedBox(key: ValueKey('magnifier'));
            },
          );
          final controller = _ctrl(tester);
          await tester.pumpWidget(_app(controller, magnifier: magnifier));
          await tester.pumpAndSettle();

          controller.selectWordAtGlobal(_onWord(tester));
          _state(tester).showToolbar();
          await tester.pumpAndSettle();
          expect(_state(tester).toolbarIsVisible, isTrue);
          final before = controller.selection!;
          final e = controller.selectionHandleEndpoints()!;
          final grab = e.startGlobal.bottomLeft + const Offset(-8, 10);

          final g = await tester.startGesture(grab);
          await tester.pump();
          await g.moveBy(const Offset(-30, 0));
          await tester.pump();
          await g.moveBy(const Offset(-30, 0));
          await tester.pump();
          expect(find.byKey(const ValueKey('magnifier')), findsOneWidget);
          expect(_state(tester).toolbarIsVisible, isFalse,
              reason: 'the toolbar hides while a handle drags');
          expect(infos, isNotEmpty);
          expect(infos.last.fieldBounds, e.startSurface.globalBounds);

          await g.up();
          await tester.pumpAndSettle();
          expect(find.byKey(const ValueKey('magnifier')), findsNothing);
          expect(_state(tester).toolbarIsVisible, isTrue);
          final after = controller.selection!;
          expect(after.extent, before.extent,
              reason: 'only the start edge moves');
          expect(controller.getText(), endsWith('selectable'));
          expect(controller.getText().length, greaterThan(10));
        });
      });

      testWidgets('dragging the end handle moves the end', (tester) async {
        await _withPlatform(TargetPlatform.android, () async {
          final controller = _ctrl(tester);
          await tester.pumpWidget(_app(controller));
          await tester.pumpAndSettle();

          controller.selectWordAtGlobal(_onWord(tester));
          await tester.pumpAndSettle();
          final e = controller.selectionHandleEndpoints()!;
          final grab = e.endGlobal.bottomRight + const Offset(8, 10);

          final g = await tester.startGesture(grab);
          await tester.pump();
          await g.moveBy(const Offset(40, 0));
          await tester.pump();
          await g.moveBy(const Offset(40, 0));
          await tester.pump();
          await g.up();
          await tester.pumpAndSettle();
          expect(controller.getText(), startsWith('selectable '));
          expect(_state(tester).toolbarIsVisible, isTrue);
        });
      });

      testWidgets('an end handle held at the edge autoscrolls and extends',
          (tester) async {
        await _withPlatform(TargetPlatform.android, () async {
          final ids = <String>[for (var i = 0; i < 12; i++) 'm$i'];
          final controller = _ctrl(tester, ids);
          final scroll = ScrollController();
          addTearDown(scroll.dispose);
          await tester.pumpWidget(_listApp(controller, scroll, ids: ids));
          await tester.pumpAndSettle();

          controller.selectWordAtGlobal(_onWord(tester));
          await tester.pumpAndSettle();
          final e = controller.selectionHandleEndpoints()!;
          final grab = e.endGlobal.bottomRight + const Offset(8, 10);
          final viewport = tester.getRect(find.byType(Scrollable));

          final g = await tester.startGesture(grab);
          await tester.pump();
          await g.moveTo(Offset(viewport.center.dx, viewport.bottom - 4));
          for (var i = 0; i < 30; i++) {
            await tester.pump(const Duration(milliseconds: 16));
          }
          expect(scroll.offset, greaterThan(0));
          final extent = controller.selection!.extent;
          expect(extent.documentId, isNot('m0'),
              reason: 'the end edge follows the scrolled content');
          await g.up();
          await tester.pumpAndSettle();
        });
      });
    });

    group('autoscroll', () {
      testWidgets('a start handle held at the top edge scrolls back',
          (tester) async {
        await _withPlatform(TargetPlatform.android, () async {
          final ids = <String>[for (var i = 0; i < 12; i++) 'm$i'];
          final controller = _ctrl(tester, ids);
          final scroll = ScrollController(initialScrollOffset: 300);
          addTearDown(scroll.dispose);
          await tester.pumpWidget(_listApp(controller, scroll, ids: ids));
          await tester.pumpAndSettle();
          final viewport = tester.getRect(find.byType(Scrollable));

          // A word on a document in the middle of the viewport.
          controller.selectWordAtGlobal(
            Offset(viewport.left + 120, viewport.center.dy),
          );
          await tester.pumpAndSettle();
          final before = controller.selection!;
          expect(before.isCollapsed, isFalse);
          final e = controller.selectionHandleEndpoints()!;
          final grab = e.startGlobal.bottomLeft + const Offset(-8, 10);

          final g = await tester.startGesture(grab);
          await tester.pump();
          await g.moveTo(Offset(viewport.center.dx, viewport.top + 4));
          for (var i = 0; i < 20; i++) {
            await tester.pump(const Duration(milliseconds: 16));
          }
          expect(scroll.offset, lessThan(300));
          final after = controller.selection!;
          expect(after.extent, before.extent, reason: 'the end edge stays put');
          expect(controller.getText().length, greaterThan(10),
              reason: 'the start edge follows the content upwards');
          await g.up();
          await tester.pumpAndSettle();
        });
      });

      testWidgets('an unusable resolved target is re-resolved', (tester) async {
        final controller = _ctrl(tester);
        final scroll = ScrollController();
        addTearDown(scroll.dispose);
        var calls = 0;
        await tester.pumpWidget(_listApp(
          controller,
          scroll,
          autoscroll: MarkdownSelectionAutoscrollConfig(
            edgeZone: 40,
            useMediaQueryPadding: false,
            targetResolver: (_) {
              calls++;
              return MarkdownCallbackAutoscrollTarget(
                viewportOf: () => null, // never drivable
                onScrollDelta: (delta) => delta,
              );
            },
          ),
        ));
        await tester.pumpAndSettle();
        final viewport = tester.getRect(find.byType(Scrollable));
        final g = await tester.startGesture(
          _docRect(tester).topLeft + const Offset(4, 6),
          kind: PointerDeviceKind.mouse,
        );
        await tester.pump(const Duration(milliseconds: 20));
        await g.moveTo(Offset(viewport.center.dx, viewport.bottom - 2));
        await tester.pump(const Duration(milliseconds: 16));
        final first = calls;
        await g.moveBy(const Offset(1, 0));
        await tester.pump(const Duration(milliseconds: 16));
        await g.moveBy(const Offset(-1, 0));
        await tester.pump(const Duration(milliseconds: 16));
        expect(first, greaterThan(0));
        expect(calls, greaterThan(first),
            reason: 'a cached target without a viewport is not reused');
        expect(scroll.offset, 0);
        await g.up();
        await tester.pumpAndSettle();
      });

      testWidgets('a drag whose bodies all unmount stops quietly',
          (tester) async {
        final controller = _ctrl(tester);
        final scroll = ScrollController();
        addTearDown(scroll.dispose);
        final showDoc = ValueNotifier<bool>(true);
        addTearDown(showDoc.dispose);
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: MarkdownSelectionScope(
              controller: controller,
              autoscroll: const MarkdownSelectionAutoscrollConfig(
                edgeZone: 40,
                useMediaQueryPadding: false,
              ),
              child: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: 400,
                  height: 200,
                  child: ValueListenableBuilder<bool>(
                    valueListenable: showDoc,
                    builder: (context, show, _) => ListView(
                      controller: scroll,
                      children: <Widget>[
                        if (show) const _Doc('d') else const SizedBox(),
                        const SizedBox(height: 3000),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ));
        await tester.pumpAndSettle();
        final viewport = tester.getRect(find.byType(Scrollable));
        final doc = _docRect(tester);
        final g = await tester.startGesture(
          doc.topLeft + const Offset(4, 6),
          kind: PointerDeviceKind.mouse,
        );
        await tester.pump(const Duration(milliseconds: 20));
        await g.moveTo(doc.topLeft + const Offset(200, 6));
        await tester.pump(const Duration(milliseconds: 16));
        expect(controller.selection!.isCollapsed, isFalse);

        showDoc.value = false;
        await tester.pump();
        expect(controller.mountedSurfaces, isEmpty);
        await g.moveTo(Offset(viewport.center.dx, viewport.bottom - 2));
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 16));
        }
        expect(scroll.offset, 0, reason: 'nothing mounted to scroll for');
        expect(tester.takeException(), isNull);
        await g.up();
        await tester.pumpAndSettle();
      });

      testWidgets('a body outside this scope falls back to its scrollable',
          (tester) async {
        // Two scopes share one controller; "b" (outside the dragged scope)
        // attaches first, so a pointer outside every body resolves to it.
        final controller = _ctrl(tester, <String>['b', 'a']);
        final scroll = ScrollController();
        addTearDown(scroll.dispose);
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    MarkdownSelectionScope(
                      controller: controller,
                      child: const _Doc('b'),
                    ),
                    MarkdownSelectionScope(
                      controller: controller,
                      // Bodies are short: let the scrollable decide alone.
                      autoscroll: const MarkdownSelectionAutoscrollConfig(
                        edgeZone: 40,
                        maxVelocity: 600,
                        useMediaQueryPadding: false,
                        useHostUnionGate: false,
                      ),
                      child: SizedBox(
                        height: 200,
                        child: ListView(
                          controller: scroll,
                          children: const <Widget>[
                            _Doc('a'),
                            SizedBox(height: 3000),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ));
        await tester.pumpAndSettle();
        expect(controller.mountedSurfaces.length, 2);
        final viewport = tester.getRect(find.byType(Scrollable));
        await _mouseDragHold(
          tester,
          _docRect(tester, 1).topLeft + const Offset(4, 6),
          Offset(viewport.center.dx, viewport.bottom + 20),
          frames: 20,
        );
        expect(scroll.offset, greaterThan(0),
            reason: 'the nearest scrollable under the dragging scope moves');
      });
    });

    group('gestures', () {
      testWidgets('shift + mouse drag extends the existing range',
          (tester) async {
        final controller = _ctrl(tester);
        await tester.pumpWidget(_app(controller));
        await tester.pumpAndSettle();
        controller.selectWordAtGlobal(_onWord(tester));
        await tester.pump();
        final base = controller.selection!.base;
        final rect = _docRect(tester);

        await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
        try {
          await _mouseDragHold(
            tester,
            rect.topLeft + const Offset(200, 8),
            rect.topLeft + const Offset(300, 8),
            frames: 2,
          );
        } finally {
          await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
        }
        expect(controller.selection!.base, base,
            reason: 'shift-drag keeps the anchor');
        expect(controller.getText(), startsWith('selectable'));
        expect(controller.getText().length, greaterThan(10));
      });

      testWidgets('iOS: a gated double-tap drag leaves the range untouched',
          (tester) async {
        // iOS keeps the range on the first tap (it toggles the toolbar), so
        // the second tap + drag reaches the gate with the range still live.
        await _withPlatform(TargetPlatform.iOS, () async {
          final controller = _ctrl(tester);
          await tester.pumpWidget(_app(controller, canStart: (_) => false));
          await tester.pumpAndSettle();
          controller.selectAll();
          await tester.pump();
          final before = controller.selection;
          final at = _onWord(tester);

          await tester.tapAt(at);
          await tester.pump(const Duration(milliseconds: 50));
          final g = await tester.startGesture(at);
          await tester.pump(const Duration(milliseconds: 50));
          await g.moveBy(const Offset(60, 0));
          await tester.pump();
          await g.moveBy(const Offset(60, 0));
          await tester.pump();
          await g.up();
          await tester.pumpAndSettle();
          expect(controller.selection, before,
              reason: 'the host owns the point: no re-anchor, no extend');
          expect(controller.getText(), _text);
        });
      });

      testWidgets('an open mouse gate dismisses a caret toolbar off text',
          (tester) async {
        await _withPlatform(TargetPlatform.android, () async {
          final controller = _ctrl(tester);
          await tester.pumpWidget(_app(controller, canStart: (_) => true));
          await tester.pumpAndSettle();
          // Android right-click off a selection: caret + toolbar.
          await _rightClick(tester, _onWord(tester));
          expect(controller.selection!.isCollapsed, isTrue);
          expect(_state(tester).toolbarIsVisible, isTrue);

          final off = _docRect(tester).bottomLeft + const Offset(20, 100);
          expect(controller.hitsSelectableContent(off), isFalse);
          await tester.tapAt(off, kind: PointerDeviceKind.mouse);
          await tester.pumpAndSettle();
          expect(_state(tester).toolbarIsVisible, isFalse,
              reason: 'the gate admits the click while the menu is open');
        });
      });

      testWidgets('double-click drag from a block gap extends by character',
          (tester) async {
        final controller = _ctrl(tester, const <String>['d'],
            'First paragraph here\n\nSecond paragraph here');
        await tester.pumpWidget(_app(controller));
        await tester.pumpAndSettle();
        final rect = _docRect(tester);
        controller.selectWordAtGlobal(rect.topLeft + const Offset(20, 7));
        await tester.pump();
        expect(controller.getText(), 'First');
        final base = controller.selection!.base;

        // The spacer between the paragraphs: inside the body, but no word.
        final gap = rect.topLeft + const Offset(200, 27);
        expect(controller.hitsSelectableContent(gap), isTrue);
        expect(controller.wordSelectionAt(gap), isNull);

        final g = await tester.startGesture(gap, kind: PointerDeviceKind.mouse);
        await tester.pump(const Duration(milliseconds: 30));
        await g.up();
        await tester.pump(const Duration(milliseconds: 30));
        await g.down(gap);
        await tester.pump(const Duration(milliseconds: 30));
        await g.moveTo(rect.topLeft + const Offset(100, 41));
        await tester.pump(const Duration(milliseconds: 30));
        await g.up();
        await tester.pumpAndSettle();

        final sel = controller.selection!;
        expect(sel.base, base, reason: 'no word anchor: keep the range base');
        expect(sel.extent.blockIndex, 2);
        expect(controller.getText(), startsWith('First paragraph here'));
        expect(controller.getText(), contains('Second'));
      });

      testWidgets('an open mouse gate clicks off the text to clear',
          (tester) async {
        final controller = _ctrl(tester);
        await tester.pumpWidget(_app(controller, canStart: (_) => true));
        await tester.pumpAndSettle();
        controller.selectAll();
        await tester.pump();
        // Below the document: no selectable content under the pointer.
        final off = _docRect(tester).bottomLeft + const Offset(20, 100);
        expect(controller.hitsSelectableContent(off), isFalse);

        await tester.tapAt(off, kind: PointerDeviceKind.mouse);
        await tester.pumpAndSettle();
        expect(controller.selection, isNull);
      });

      testWidgets('Linux mouse clicks cycle word / block / caret',
          (tester) async {
        await _withPlatform(TargetPlatform.linux, () async {
          final controller = _ctrl(tester);
          await tester.pumpWidget(_app(controller));
          await tester.pumpAndSettle();
          final at = _onWord(tester);

          Future<void> clicks(int n) async {
            for (var i = 0; i < n; i++) {
              await tester.tapAt(at, kind: PointerDeviceKind.mouse);
              await tester.pump(const Duration(milliseconds: 50));
            }
          }

          await clicks(4); // 4 -> 1: a caret
          await tester.pump(const Duration(seconds: 1));
          expect(controller.selection?.isCollapsed ?? true, isTrue);

          await clicks(6); // 6 -> 3: the block
          await tester.pumpAndSettle();
          expect(controller.getText(), _text);
        });
      });
    });

    group('secondary tap', () {
      testWidgets('macOS: a second right-click on the same spot hides',
          (tester) async {
        await _withPlatform(TargetPlatform.macOS, () async {
          final controller = _ctrl(tester);
          await tester.pumpWidget(_app(controller));
          await tester.pumpAndSettle();
          controller.selectWordAtGlobal(_onWord(tester));
          await tester.pump();
          final sel = controller.selection;

          await _rightClick(tester, _onWord(tester));
          expect(_state(tester).toolbarIsVisible, isTrue);
          await _rightClick(tester, _onWord(tester));
          expect(_state(tester).toolbarIsVisible, isFalse);
          expect(controller.selection, sel);

          // A different spot while open re-shows instead of hiding.
          await _rightClick(tester, _onWord(tester));
          expect(_state(tester).toolbarIsVisible, isTrue);
          await _rightClick(tester, _onWord(tester) + const Offset(20, 0));
          expect(_state(tester).toolbarIsVisible, isTrue);
        });
      });

      testWidgets('Linux: a right-click while open hides', (tester) async {
        await _withPlatform(TargetPlatform.linux, () async {
          final controller = _ctrl(tester);
          await tester.pumpWidget(_app(controller));
          await tester.pumpAndSettle();
          controller.selectWordAtGlobal(_onWord(tester));
          await tester.pump();

          await _rightClick(tester, _onWord(tester));
          expect(_state(tester).toolbarIsVisible, isTrue);
          await _rightClick(tester, _onWord(tester) + const Offset(20, 0));
          expect(_state(tester).toolbarIsVisible, isFalse);
          expect(controller.getText(), 'selectable');
        });
      });

      testWidgets('Android: right-click on / off the selection',
          (tester) async {
        await _withPlatform(TargetPlatform.android, () async {
          final controller = _ctrl(tester);
          await tester.pumpWidget(_app(controller));
          await tester.pumpAndSettle();
          controller.selectWordAtGlobal(_onWord(tester));
          await tester.pump();
          final sel = controller.selection;

          await _rightClick(tester, _onWord(tester));
          expect(_state(tester).toolbarIsVisible, isTrue);
          expect(controller.selection, sel, reason: 'on selection: keep');

          final off = _docRect(tester).topLeft + const Offset(250, 8);
          await _rightClick(tester, off);
          expect(controller.selection!.isCollapsed, isTrue,
              reason: 'off selection: caret at the click');
          expect(_state(tester).toolbarIsVisible, isTrue);
        });
      });

      testWidgets('iOS: right-click off the selection selects a word',
          (tester) async {
        await _withPlatform(TargetPlatform.iOS, () async {
          final controller = _ctrl(tester);
          await tester.pumpWidget(_app(controller));
          await tester.pumpAndSettle();

          await _rightClick(tester, _onWord(tester));
          expect(controller.getText(), 'selectable');
          expect(_state(tester).toolbarIsVisible, isTrue);
        });
      });

      for (final (platform, wantWord) in <(TargetPlatform, bool)>[
        (TargetPlatform.windows, false),
        (TargetPlatform.macOS, true),
      ]) {
        testWidgets(
            'mobile theme on ${platform.name}: right-click '
            '${wantWord ? 'selects a word' : 'places a caret'}',
            (tester) async {
          await _withPlatform(platform, () async {
            final controller = _ctrl(tester);
            await tester.pumpWidget(_app(
              controller,
              theme: ThemeData(platform: TargetPlatform.android),
            ));
            await tester.pumpAndSettle();

            await _rightClick(tester, _onWord(tester));
            if (wantWord) {
              expect(controller.getText(), 'selectable');
            } else {
              expect(controller.selection!.isCollapsed, isTrue);
            }
            expect(_state(tester).toolbarIsVisible, isTrue);
          });
        });
      }

      testWidgets('mobile theme on Linux: right-click toggles', (tester) async {
        await _withPlatform(TargetPlatform.linux, () async {
          final controller = _ctrl(tester);
          await tester.pumpWidget(_app(
            controller,
            theme: ThemeData(platform: TargetPlatform.android),
          ));
          await tester.pumpAndSettle();

          await _rightClick(tester, _onWord(tester));
          expect(controller.selection!.isCollapsed, isTrue);
          expect(_state(tester).toolbarIsVisible, isTrue);
          await _rightClick(tester, _onWord(tester));
          expect(_state(tester).toolbarIsVisible, isFalse);
        });
      });
    });
  });
}
