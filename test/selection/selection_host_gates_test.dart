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

MarkdownSelectionController _controllerWith(Map<String, String> docs) =>
    MarkdownSelectionController()
      ..setDocuments(<MarkdownDocumentRef>[
        for (final entry in docs.entries)
          MarkdownDocumentRef(
            id: entry.key,
            model: Markdown.fromString(entry.value),
          ),
      ]);

Future<void> _mouseDrag(WidgetTester tester, Offset from, Offset to) async {
  final g = await tester.startGesture(from, kind: PointerDeviceKind.mouse);
  await tester.pump(const Duration(milliseconds: 100));
  await g.moveTo(to);
  await tester.pump(const Duration(milliseconds: 100));
  await g.up();
  await tester.pumpAndSettle();
}

Future<void> _longPressDrag(
  WidgetTester tester,
  Offset from,
  Offset to,
) async {
  final g = await tester.startGesture(from);
  await tester.pump(const Duration(milliseconds: 700));
  await g.moveTo(to);
  await tester.pump(const Duration(milliseconds: 100));
  await g.up();
  await tester.pumpAndSettle();
}

/// Runs [body] with [platform] forced.
///
/// NOTE: reset via try/finally rather than `addTearDown` — the framework's
/// `debugAssertAllFoundationVarsUnset` check runs before user tear-downs, so a
/// tear-down reset arrives too late and fails the test.
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

Widget _scope({
  required MarkdownSelectionController controller,
  required Widget child,
  bool Function(Offset globalPosition)? canStartSelectionAt,
  bool enableTouchGestures = true,
  bool enableTouchConsecutiveTaps = true,
  FocusNode? focusNode,
}) =>
    MaterialApp(
      home: Scaffold(
        body: MarkdownSelectionScope(
          controller: controller,
          canStartSelectionAt: canStartSelectionAt,
          enableTouchGestures: enableTouchGestures,
          enableTouchConsecutiveTaps: enableTouchConsecutiveTaps,
          focusNode: focusNode,
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(width: 400, child: child),
          ),
        ),
      ),
    );

void main() {
  group('canStartSelectionAt', () {
    testWidgets('a refused mouse drag never starts a selection',
        (tester) async {
      final controller = _controllerWith({'d': 'Hello selectable world'});
      addTearDown(controller.dispose);

      await tester.pumpWidget(_scope(
        controller: controller,
        canStartSelectionAt: (_) => false,
        child: const _Doc('d'),
      ));
      await tester.pumpAndSettle();

      final box = tester.getRect(find.byType(MarkdownWidget));
      await _mouseDrag(
        tester,
        box.topLeft + const Offset(2, 4),
        box.centerRight - const Offset(2, 0),
      );

      expect(controller.selection, isNull);
      expect(controller.getText(), isEmpty);
    });

    testWidgets('a refused long press never starts a selection',
        (tester) async {
      await _withPlatform(TargetPlatform.android, () async {
        final controller = _controllerWith({'d': 'Hello selectable world'});
        addTearDown(controller.dispose);

        await tester.pumpWidget(_scope(
          controller: controller,
          canStartSelectionAt: (_) => false,
          child: const _Doc('d'),
        ));
        await tester.pumpAndSettle();

        final box = tester.getRect(find.byType(MarkdownWidget));
        await _longPressDrag(
          tester,
          box.topLeft + const Offset(2, 4),
          box.centerRight - const Offset(2, 0),
        );

        expect(controller.selection, isNull);
        expect(controller.getText(), isEmpty);
      });
    });

    testWidgets(
        'a long press on refused chrome does not re-anchor an active range',
        (tester) async {
      await _withPlatform(TargetPlatform.android, () async {
        final controller = _controllerWith({'d': 'Hello selectable world'});
        addTearDown(controller.dispose);

        // Refuse the right half of the widget (pretend it is a link).
        var split = double.infinity;
        await tester.pumpWidget(_scope(
          controller: controller,
          canStartSelectionAt: (global) => global.dx < split,
          child: const _Doc('d'),
        ));
        await tester.pumpAndSettle();
        final box = tester.getRect(find.byType(MarkdownWidget));
        split = box.center.dx;

        // Arm a real selection on the allowed half first.
        await _longPressDrag(
          tester,
          box.topLeft + const Offset(2, 4),
          box.topLeft + const Offset(40, 4),
        );
        final armed = controller.selection;
        expect(armed, isNotNull);
        expect(armed!.isCollapsed, isFalse);

        // Long-pressing refused chrome must not re-anchor the range there.
        await _longPressDrag(
          tester,
          box.centerRight - const Offset(6, 0),
          box.centerRight - const Offset(6, 0),
        );

        expect(
          controller.selection,
          anyOf(isNull, armed),
          reason: 'refused chrome may dismiss, but must not select on it',
        );
      });
    });

    testWidgets('a refused mouse drag does not extend from the refused point',
        (tester) async {
      final controller = _controllerWith({'d': 'Hello selectable world'});
      addTearDown(controller.dispose);

      var split = double.infinity;
      await tester.pumpWidget(_scope(
        controller: controller,
        canStartSelectionAt: (global) => global.dx > split,
        child: const _Doc('d'),
      ));
      await tester.pumpAndSettle();
      final box = tester.getRect(find.byType(MarkdownWidget));
      split = box.center.dx;

      // Start inside the refused left half and drag right into allowed space.
      await _mouseDrag(
        tester,
        box.topLeft + const Offset(2, 4),
        box.centerRight - const Offset(2, 0),
      );

      expect(controller.selection, isNull);
    });

    testWidgets('an allowed point still selects normally', (tester) async {
      final controller = _controllerWith({'d': 'Hello selectable world'});
      addTearDown(controller.dispose);

      await tester.pumpWidget(_scope(
        controller: controller,
        canStartSelectionAt: (_) => true,
        child: const _Doc('d'),
      ));
      await tester.pumpAndSettle();

      final box = tester.getRect(find.byType(MarkdownWidget));
      await _mouseDrag(
        tester,
        box.topLeft + const Offset(2, 4),
        box.centerRight - const Offset(2, 0),
      );

      expect(controller.getText(), 'Hello selectable world');
    });
  });

  group('enableTouchGestures', () {
    testWidgets('false leaves touch long-press to the host', (tester) async {
      await _withPlatform(TargetPlatform.android, () async {
        final controller = _controllerWith({'d': 'Hello selectable world'});
        addTearDown(controller.dispose);

        await tester.pumpWidget(_scope(
          controller: controller,
          enableTouchGestures: false,
          child: const _Doc('d'),
        ));
        await tester.pumpAndSettle();

        final box = tester.getRect(find.byType(MarkdownWidget));
        await _longPressDrag(
          tester,
          box.topLeft + const Offset(2, 4),
          box.centerRight - const Offset(2, 0),
        );

        expect(controller.selection, isNull);
      });
    });

    testWidgets('false keeps mouse drag selection alive', (tester) async {
      await _withPlatform(TargetPlatform.android, () async {
        final controller = _controllerWith({'d': 'Hello selectable world'});
        addTearDown(controller.dispose);

        await tester.pumpWidget(_scope(
          controller: controller,
          enableTouchGestures: false,
          child: const _Doc('d'),
        ));
        await tester.pumpAndSettle();

        final box = tester.getRect(find.byType(MarkdownWidget));
        await _mouseDrag(
          tester,
          box.topLeft + const Offset(2, 4),
          box.centerRight - const Offset(2, 0),
        );

        expect(controller.getText(), 'Hello selectable world');
      });
    });

    testWidgets('false keeps a programmatic selection through focus loss',
        (tester) async {
      final controller = _controllerWith({'d': 'Hello selectable world'});
      addTearDown(controller.dispose);
      final focus = FocusNode();
      addTearDown(focus.dispose);
      final other = FocusNode();
      addTearDown(other.dispose);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Column(
            children: <Widget>[
              MarkdownSelectionScope(
                controller: controller,
                focusNode: focus,
                enableTouchGestures: false,
                child: const SizedBox(width: 400, child: _Doc('d')),
              ),
              Focus(focusNode: other, child: const SizedBox(height: 10)),
            ],
          ),
        ),
      ));
      await tester.pumpAndSettle();

      focus.requestFocus();
      await tester.pumpAndSettle();
      controller.selectAll();
      await tester.pumpAndSettle();
      expect(controller.selection, isNotNull);

      other.requestFocus();
      await tester.pumpAndSettle();

      expect(controller.selection, isNotNull,
          reason: 'host-owned touch entry must not clear on focus loss');
    });
  });

  group('enableTouchConsecutiveTaps', () {
    testWidgets('false keeps the long-press word selection working',
        (tester) async {
      await _withPlatform(TargetPlatform.android, () async {
        final controller = _controllerWith({'d': 'Hello selectable world'});
        addTearDown(controller.dispose);

        await tester.pumpWidget(_scope(
          controller: controller,
          enableTouchConsecutiveTaps: false,
          child: const _Doc('d'),
        ));
        await tester.pumpAndSettle();

        final box = tester.getRect(find.byType(MarkdownWidget));
        await _longPressDrag(
          tester,
          box.topLeft + const Offset(2, 4),
          box.topLeft + const Offset(2, 4),
        );

        expect(controller.getText(), 'Hello');
      });
    });

    testWidgets('false leaves a plain touch tap to the host', (tester) async {
      await _withPlatform(TargetPlatform.android, () async {
        final controller = _controllerWith({'d': 'Hello selectable world'});
        addTearDown(controller.dispose);

        await tester.pumpWidget(_scope(
          controller: controller,
          enableTouchConsecutiveTaps: false,
          child: const _Doc('d'),
        ));
        await tester.pumpAndSettle();

        final box = tester.getRect(find.byType(MarkdownWidget));
        await _longPressDrag(
          tester,
          box.topLeft + const Offset(2, 4),
          box.topLeft + const Offset(2, 4),
        );
        expect(controller.getText(), 'Hello');

        // A bare tap is host territory now — the range survives it.
        await tester.tapAt(box.center);
        await tester.pumpAndSettle();
        expect(controller.getText(), 'Hello');
      });
    });

    testWidgets('true dismisses an active range on a plain touch tap',
        (tester) async {
      await _withPlatform(TargetPlatform.android, () async {
        final controller = _controllerWith({'d': 'Hello selectable world'});
        addTearDown(controller.dispose);

        await tester.pumpWidget(_scope(
          controller: controller,
          child: const _Doc('d'),
        ));
        await tester.pumpAndSettle();

        final box = tester.getRect(find.byType(MarkdownWidget));
        await _longPressDrag(
          tester,
          box.topLeft + const Offset(2, 4),
          box.topLeft + const Offset(2, 4),
        );
        expect(controller.getText(), 'Hello');

        await tester.tapAt(box.center);
        await tester.pumpAndSettle();
        expect(controller.selection, isNull);
      });
    });
  });

  group('ownsSelectionChrome', () {
    testWidgets('a non-owning sibling does not strip the owner handles',
        (tester) async {
      await _withPlatform(TargetPlatform.android, () async {
        final controller = _controllerWith({
          'a': 'First message body text',
          'b': 'Second message body text',
        });
        addTearDown(controller.dispose);

        late MarkdownSelectionScopeState ownerState;

        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 400,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    MarkdownSelectionScope(
                      controller: controller,
                      ownsSelectionChrome: (id) => id == 'a',
                      child: Builder(builder: (context) {
                        ownerState = MarkdownSelectionScope.stateOf(context)!;
                        return const _Doc('a');
                      }),
                    ),
                    MarkdownSelectionScope(
                      controller: controller,
                      ownsSelectionChrome: (id) => id == 'b',
                      child: const _Doc('b'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ));
        await tester.pumpAndSettle();

        final first = tester.getRect(find.byType(MarkdownWidget).first);
        await _longPressDrag(
          tester,
          first.topLeft + const Offset(2, 4),
          first.topLeft + const Offset(60, 4),
        );

        expect(controller.selection, isNotNull);
        expect(controller.selection!.isCollapsed, isFalse);
        expect(controller.selection!.base.documentId, 'a');
        expect(ownerState.selectionHandleLeadersAttached, isTrue);

        // Force every scope to re-sync (what a scroll / rebuild does).
        controller.notifyListeners();
        await tester.pumpAndSettle();

        expect(ownerState.selectionHandleLeadersAttached, isTrue,
            reason: 'the non-owning sibling must not clear foreign leaders');
      });
    });

    testWidgets('a disabled sibling does not strip the owner handles',
        (tester) async {
      await _withPlatform(TargetPlatform.android, () async {
        final controller = _controllerWith({
          'a': 'First message body text',
          'b': 'Second message body text',
        });
        addTearDown(controller.dispose);

        late MarkdownSelectionScopeState ownerState;

        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 400,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    MarkdownSelectionScope(
                      controller: controller,
                      child: Builder(builder: (context) {
                        ownerState = MarkdownSelectionScope.stateOf(context)!;
                        return const _Doc('a');
                      }),
                    ),
                    MarkdownSelectionScope(
                      controller: controller,
                      enabled: false,
                      child: const _Doc('b'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ));
        await tester.pumpAndSettle();

        final first = tester.getRect(find.byType(MarkdownWidget).first);
        await _longPressDrag(
          tester,
          first.topLeft + const Offset(2, 4),
          first.topLeft + const Offset(60, 4),
        );

        expect(ownerState.selectionHandleLeadersAttached, isTrue);
        controller.notifyListeners();
        await tester.pumpAndSettle();
        expect(ownerState.selectionHandleLeadersAttached, isTrue);
      });
    });
  });

  group('glyph-tight hit testing', () {
    testWidgets('empty gutter beside a short line is not selectable ink',
        (tester) async {
      final controller = _controllerWith({'d': 'Hi'});
      addTearDown(controller.dispose);

      await tester.pumpWidget(_scope(
        controller: controller,
        child: const _Doc('d'),
      ));
      await tester.pumpAndSettle();

      final box = tester.getRect(find.byType(MarkdownWidget));
      final onInk = box.topLeft + const Offset(3, 6);
      final onGutter = Offset(box.right - 4, box.top + 6);

      expect(controller.hitsSelectableGlyphs(onInk), isTrue);
      expect(controller.hitsSelectableGlyphs(onGutter), isFalse);
      // Gesture starts stay bubble-wide (tdesktop parity).
      expect(controller.hitsSelectableContent(onGutter), isTrue);
    });

    testWidgets('empty chrome outside every surface does not clamp in',
        (tester) async {
      final controller = _controllerWith({'d': 'Hello selectable world'});
      addTearDown(controller.dispose);

      await tester.pumpWidget(_scope(
        controller: controller,
        child: const _Doc('d'),
      ));
      await tester.pumpAndSettle();

      final box = tester.getRect(find.byType(MarkdownWidget));
      final below = Offset(box.center.dx, box.bottom + 120);

      expect(controller.hitsSelectableContent(below), isFalse);
      expect(
        controller.positionForGlobal(below, requireContainment: true),
        isNull,
      );
      // Extending across a gap still clamps onto the nearest surface.
      expect(controller.positionForGlobal(below), isNotNull);

      controller.startAtGlobal(below);
      expect(controller.selection, isNull);
    });

    testWidgets('a mouse click that misses clears an active range',
        (tester) async {
      final controller = _controllerWith({'d': 'Hello selectable world'});
      addTearDown(controller.dispose);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MarkdownSelectionScope(
            controller: controller,
            child: const Align(
              alignment: Alignment.topLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(width: 400, child: _Doc('d')),
                  SizedBox(width: 400, height: 200),
                ],
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
      expect(controller.selection, isNotNull);

      final g = await tester.startGesture(
        Offset(box.center.dx, box.bottom + 100),
        kind: PointerDeviceKind.mouse,
      );
      await g.up();
      await tester.pumpAndSettle();

      expect(controller.selection, isNull);
    });
  });
}
