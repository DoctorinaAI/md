import 'package:flutter/foundation.dart';
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

    testWidgets('MarkdownSelectionSurface exposes localBoxesForRange',
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

      final surface = controller.mountedSurfaces.first;
      final boxes = surface.localBoxesForRange(0, 0, 5);
      expect(boxes, isNotEmpty);
      expect(boxes.first.width, greaterThan(0));
      expect(boxes.first.height, greaterThan(0));
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

    testWidgets('desktop mouse drag and double-click do not show toolbar',
        (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      try {
        final controller = MarkdownSelectionController()
          ..setDocuments(<MarkdownDocumentRef>[
            MarkdownDocumentRef(
                id: 'd', model: Markdown.fromString('Hello selectable world')),
          ]);
        final tl = await pumpParagraph(tester, controller);

        // 1. Mouse drag selects without showing toolbar.
        await _mouseDrag(
            tester, tl + const Offset(2, 6), tl + const Offset(120, 6));
        expect(controller.getText(), isNotEmpty);
        final state = tester.state<MarkdownSelectionScopeState>(
            find.byType(MarkdownSelectionScope));
        expect(state.toolbarIsVisible, isFalse,
            reason: 'desktop mouse drag must not pop the toolbar');

        // Clear selection by clicking.
        await _clicks(tester, tl + const Offset(2, 6), 1);
        expect(state.toolbarIsVisible, isFalse);

        await tester.pump(const Duration(milliseconds: 600));

        // 2. Mouse double-click selects word without showing toolbar.
        await _clicks(tester, tl + const Offset(8, 8), 2);
        expect(controller.getText(), 'Hello');
        expect(state.toolbarIsVisible, isFalse,
            reason: 'desktop double-click must not pop the toolbar');

        await tester.pump(const Duration(milliseconds: 600));

        // 3. Mouse triple-click selects block without showing toolbar.
        await _clicks(tester, tl + const Offset(8, 8), 3);
        expect(controller.getText(), 'Hello selectable world');
        expect(state.toolbarIsVisible, isFalse,
            reason: 'desktop triple-click must not pop the toolbar');
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
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

    testWidgets('double-tap re-selects the same word and refreshes the toolbar',
        (tester) async {
      final controller = MarkdownSelectionController()
        ..setDocuments(<MarkdownDocumentRef>[
          MarkdownDocumentRef(
              id: 'd', model: Markdown.fromString('Hello selectable world')),
        ]);
      final tl = await pumpParagraph(tester, controller);
      final pos = tl + const Offset(8, 8);

      await tester.tapAt(pos);
      await tester.pump(const Duration(milliseconds: 40));
      await tester.tapAt(pos);
      await tester.pumpAndSettle();
      expect(controller.getText(), 'Hello');
      final state = tester.state<MarkdownSelectionScopeState>(
          find.byType(MarkdownSelectionScope));
      expect(state.toolbarIsVisible, isTrue);

      state.hideToolbar();
      await tester.pumpAndSettle();
      expect(state.toolbarIsVisible, isFalse);

      // Same word again — must refresh chrome even though the range equals.
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tapAt(pos);
      await tester.pump(const Duration(milliseconds: 40));
      await tester.tapAt(pos);
      await tester.pumpAndSettle();

      expect(controller.getText(), 'Hello');
      expect(state.toolbarIsVisible, isTrue,
          reason: 'equal-range double-tap still re-shows the toolbar');
      expect(tester.takeException(), isNull);
    });

    testWidgets('expand drag hides the toolbar until drag end', (tester) async {
      final controller = MarkdownSelectionController()
        ..setDocuments(<MarkdownDocumentRef>[
          MarkdownDocumentRef(
              id: 'd',
              model: Markdown.fromString('Hello selectable world again')),
        ]);
      final tl = await pumpParagraph(tester, controller);
      final pos = tl + const Offset(8, 8);

      // Establish a selection + toolbar via touch double-tap.
      await tester.tapAt(pos);
      await tester.pump(const Duration(milliseconds: 40));
      await tester.tapAt(pos);
      await tester.pumpAndSettle();
      final state = tester.state<MarkdownSelectionScopeState>(
          find.byType(MarkdownSelectionScope));
      expect(state.toolbarIsVisible, isTrue);

      // Long-press expand hides the menu for the duration of the drag.
      final gesture = await tester.startGesture(pos);
      await tester.pump(const Duration(seconds: 1)); // long-press fire
      await tester.pumpAndSettle();
      expect(state.toolbarIsVisible, isFalse,
          reason: 'toolbar hides while expanding via long-press drag');

      await gesture.moveBy(const Offset(80, 0));
      await tester.pump();
      expect(state.toolbarIsVisible, isFalse);

      await gesture.up();
      await tester.pumpAndSettle();
      expect(controller.selection!.isCollapsed, isFalse);
      expect(state.toolbarIsVisible, isTrue,
          reason: 'toolbar may return when expand drag ends');
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'Android long-press fires forLongPress haptic while handles deferred',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        final log = <MethodCall>[];
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async {
            log.add(call);
            return null;
          },
        );
        try {
          final controller = MarkdownSelectionController()
            ..setDocuments(<MarkdownDocumentRef>[
              MarkdownDocumentRef(
                id: 'd',
                model: Markdown.fromString('Hello selectable world again'),
              ),
            ]);
          final tl = await pumpParagraph(tester, controller);
          final pos = tl + const Offset(8, 8);

          final gesture = await tester.startGesture(pos);
          await tester.pump(const Duration(seconds: 1));
          await tester.pump();

          expect(
            log.where(
              (c) =>
                  c.method == 'HapticFeedback.vibrate' && c.arguments == null,
            ),
            isNotEmpty,
            reason: 'Feedback.forLongPress → vibrate on Android',
          );
          expect(controller.selection, isNotNull);
          expect(controller.selection!.isCollapsed, isFalse);
          // Handles stay deferred until press-end on Android.
          expect(find.byType(CompositedTransformFollower), findsNothing);

          final startTicks = log
              .where(
                (c) =>
                    c.method == 'HapticFeedback.vibrate' &&
                    c.arguments == 'HapticFeedbackType.selectionClick',
              )
              .length;

          // Drag across later words — each range change should CLOCK_TICK.
          await gesture.moveBy(const Offset(160, 0));
          await tester.pump();
          await gesture.moveBy(const Offset(80, 0));
          await tester.pump();

          final dragTicks = log
              .where(
                (c) =>
                    c.method == 'HapticFeedback.vibrate' &&
                    c.arguments == 'HapticFeedbackType.selectionClick',
              )
              .length;
          expect(dragTicks, greaterThan(startTicks),
              reason: 'long-press drag emits selectionClick on range change');

          await gesture.up();
          await tester.pumpAndSettle();
          expect(find.byType(CompositedTransformFollower), findsWidgets);
          expect(tester.takeException(), isNull);
        } finally {
          tester.binding.defaultBinaryMessenger
              .setMockMethodCallHandler(SystemChannels.platform, null);
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );

    testWidgets('losing focus while resumed clears the selection',
        (tester) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      final controller = MarkdownSelectionController()
        ..setDocuments(<MarkdownDocumentRef>[
          MarkdownDocumentRef(
              id: 'd', model: Markdown.fromString('Hello selectable world')),
        ]);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MarkdownSelectionScope(
            controller: controller,
            focusNode: focus,
            child: const Align(
              alignment: Alignment.topLeft,
              child: SizedBox(width: 400, child: _Doc('d')),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      controller.selectAll();
      focus.requestFocus();
      await tester.pump();
      expect(controller.getText(), isNotEmpty);
      expect(focus.hasFocus, isTrue);

      // Ensure the binding reports resumed (SelectableRegion P2 contract).
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      focus.unfocus();
      await tester.pump();
      expect(controller.getText(), isEmpty,
          reason: 'focus loss while resumed clears selection');
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'secondary-click on an active selection keeps the range '
        'and shows toolbar', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      try {
        final controller = MarkdownSelectionController()
          ..setDocuments(<MarkdownDocumentRef>[
            MarkdownDocumentRef(
                id: 'd', model: Markdown.fromString('Hello selectable world')),
          ]);
        final tl = await pumpParagraph(tester, controller);
        controller.selectAll();
        await tester.pumpAndSettle();
        final selected = controller.getText();
        expect(selected, isNotEmpty);

        final center = tl + const Offset(40, 8);
        await tester.tapAt(center, buttons: kSecondaryButton);
        await tester.pumpAndSettle();

        expect(controller.getText(), selected,
            reason: 'secondary-click on selection keeps the range');
        final state = tester.state<MarkdownSelectionScopeState>(
            find.byType(MarkdownSelectionScope));
        expect(state.toolbarIsVisible, isTrue);
        expect(tester.takeException(), isNull);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets(
        'secondary-click on desktop without selection shows toolbar '
        'without selecting text', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      try {
        final controller = MarkdownSelectionController()
          ..setDocuments(<MarkdownDocumentRef>[
            MarkdownDocumentRef(
                id: 'd', model: Markdown.fromString('Hello selectable world')),
          ]);
        final tl = await pumpParagraph(tester, controller);

        final wordPos = tl + const Offset(8, 8);
        final g = await tester.startGesture(wordPos,
            kind: PointerDeviceKind.mouse, buttons: kSecondaryMouseButton);
        await g.up();
        await tester.pumpAndSettle();

        expect(controller.selection, isNull,
            reason:
                'desktop right click without selection must not select text');
        final state = tester.state<MarkdownSelectionScopeState>(
            find.byType(MarkdownSelectionScope));
        expect(state.toolbarIsVisible, isTrue);
        expect(state.contextMenuAnchors.primaryAnchor, wordPos);
        expect(find.byType(AdaptiveTextSelectionToolbar), findsOneWidget);
        expect(
            find.descendant(
              of: find.byType(AdaptiveTextSelectionToolbar),
              matching: find.textContaining(RegExp(r'Select [aA]ll')),
            ),
            findsOneWidget);
        expect(find.text('Copy'), findsNothing);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets(
        'desktop context menu preserves right-click anchor after Select all',
        (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      try {
        final controller = MarkdownSelectionController()
          ..setDocuments(<MarkdownDocumentRef>[
            MarkdownDocumentRef(
                id: 'd', model: Markdown.fromString('Hello selectable world')),
          ]);
        final tl = await pumpParagraph(tester, controller);

        final wordPos = tl + const Offset(40, 8);
        final g = await tester.startGesture(wordPos,
            kind: PointerDeviceKind.mouse, buttons: kSecondaryMouseButton);
        await g.up();
        await tester.pumpAndSettle();

        final state = tester.state<MarkdownSelectionScopeState>(
            find.byType(MarkdownSelectionScope));
        expect(state.toolbarIsVisible, isTrue);
        expect(state.contextMenuAnchors.primaryAnchor, wordPos);

        // Tap "Select All" from the desktop context menu.
        await tester.tap(find.textContaining(RegExp(r'Select [aA]ll')));
        await tester.pumpAndSettle();

        expect(controller.getText(), 'Hello selectable world');
        expect(state.toolbarIsVisible, isTrue);
        expect(state.contextMenuAnchors.primaryAnchor, wordPos,
            reason: 'desktop context menu must keep its right-click anchor');
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('macOS consecutive taps cap at paragraph (4th stays block)',
        (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      try {
        final controller = MarkdownSelectionController()
          ..setDocuments(<MarkdownDocumentRef>[
            MarkdownDocumentRef(
                id: 'd', model: Markdown.fromString('Hello selectable world')),
          ]);
        final tl = await pumpParagraph(tester, controller);
        final pos = tl + const Offset(8, 8);

        await _clicks(tester, pos, 4);
        expect(controller.getText(), 'Hello selectable world',
            reason: 'taps past 3 stay at block granularity on macOS');
        expect(tester.takeException(), isNull);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('double-click drag extends by word', (tester) async {
      final controller = MarkdownSelectionController()
        ..setDocuments(<MarkdownDocumentRef>[
          MarkdownDocumentRef(
              id: 'd',
              model: Markdown.fromString('Hello selectable world today')),
        ]);
      final tl = await pumpParagraph(tester, controller);

      // Double-click on "Hello", then drag toward "selectable".
      final from = tl + const Offset(8, 8);
      final to = tl + const Offset(100, 8);
      final g = await tester.startGesture(from, kind: PointerDeviceKind.mouse);
      await g.up();
      await tester.pump(const Duration(milliseconds: 40));
      final g2 = await tester.startGesture(from, kind: PointerDeviceKind.mouse);
      await tester.pump(const Duration(milliseconds: 50));
      await g2.moveTo(to);
      await tester.pump(const Duration(milliseconds: 50));
      await g2.up();
      await tester.pumpAndSettle();

      final text = controller.getText();
      expect(text, contains('Hello'));
      expect(text, contains('selectable'),
          reason: 'drag after double-tap grows by word');
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

    testWidgets('touch single tap dismisses an active selection',
        (tester) async {
      final controller = MarkdownSelectionController()
        ..setDocuments(<MarkdownDocumentRef>[
          MarkdownDocumentRef(
              id: 'd', model: Markdown.fromString('Hello selectable world')),
        ]);
      final tl = await pumpParagraph(tester, controller);
      final pos = tl + const Offset(8, 8);

      // Establish a ranged selection via touch double-tap.
      await tester.tapAt(pos);
      await tester.pump(const Duration(milliseconds: 40));
      await tester.tapAt(pos);
      await tester.pumpAndSettle();
      expect(controller.getText(), 'Hello');
      expect(controller.selection!.isCollapsed, isFalse);

      // Single tap dismisses immediately (TapAndHorizontalDrag consecutive
      // count — no DoubleTapGestureRecognizer arena wait).
      await tester.pump(const Duration(milliseconds: 40));
      await tester.tapAt(pos);
      await tester.pumpAndSettle();

      expect(controller.selection, anyOf(isNull, isA<MarkdownSelection>()));
      expect(controller.getText(), isEmpty,
          reason: 'touch tap dismisses so the user is never stuck');
      final state = tester.state<MarkdownSelectionScopeState>(
          find.byType(MarkdownSelectionScope));
      expect(state.toolbarIsVisible, isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'long-press / double-tap on chrome does not start a selection',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        try {
          final controller = MarkdownSelectionController()
            ..setDocuments(<MarkdownDocumentRef>[
              MarkdownDocumentRef(
                id: 'd',
                model: Markdown.fromString('Hello selectable world'),
              ),
            ]);

          await tester.pumpWidget(_wrap(
            controller,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ElevatedButton(
                  key: const Key('chrome'),
                  onPressed: () {},
                  child: const Text('Action'),
                ),
                const SizedBox(height: 80),
                const SizedBox(width: 400, child: _Doc('d')),
              ],
            ),
          ));
          await tester.pumpAndSettle();

          final buttonCenter =
              tester.getCenter(find.byKey(const Key('chrome')));

          // Long-press on the button must not clamp onto nearest markdown.
          final longPress = await tester.startGesture(buttonCenter);
          await tester.pump(const Duration(seconds: 1));
          await tester.pump();
          expect(controller.selection, isNull);
          expect(controller.getText(), isEmpty);
          await longPress.up();
          await tester.pumpAndSettle();
          expect(controller.selection, isNull);

          // Double-tap on chrome likewise.
          await tester.tapAt(buttonCenter);
          await tester.pump(const Duration(milliseconds: 40));
          await tester.tapAt(buttonCenter);
          await tester.pumpAndSettle();
          expect(controller.selection, isNull);
          expect(controller.getText(), isEmpty);

          // Control: long-press on the markdown still selects.
          final mdTl = tester.getTopLeft(find.byType(MarkdownWidget));
          final onText = mdTl + const Offset(8, 8);
          final onMd = await tester.startGesture(onText);
          await tester.pump(const Duration(seconds: 1));
          await tester.pump();
          expect(controller.getText(), 'Hello');
          await onMd.up();
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );

    testWidgets(
      'horizontal drag on chrome yields to an ancestor drag recognizer',
      (tester) async {
        // Simulates DismissiblePage competing with a host that wraps the page.
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        try {
          var ancestorDrags = 0;
          final controller = MarkdownSelectionController()
            ..setDocuments(<MarkdownDocumentRef>[
              MarkdownDocumentRef(
                id: 'd',
                model: Markdown.fromString('Hello selectable world'),
              ),
            ]);

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: RawGestureDetector(
                  behavior: HitTestBehavior.translucent,
                  gestures: <Type, GestureRecognizerFactory>{
                    HorizontalDragGestureRecognizer:
                        GestureRecognizerFactoryWithHandlers<
                            HorizontalDragGestureRecognizer>(
                      HorizontalDragGestureRecognizer.new,
                      (HorizontalDragGestureRecognizer instance) {
                        instance.onStart = (_) => ancestorDrags++;
                      },
                    ),
                  },
                  child: MarkdownSelectionScope(
                    controller: controller,
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: 120, key: Key('chrome')),
                        SizedBox(width: 400, child: _Doc('d')),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          final chrome = tester.getCenter(find.byKey(const Key('chrome')));
          final gesture = await tester.startGesture(chrome);
          await tester.pump(const Duration(milliseconds: 20));
          await gesture.moveBy(const Offset(80, 0));
          await tester.pump();
          await gesture.up();
          await tester.pumpAndSettle();

          expect(ancestorDrags, greaterThan(0),
              reason: 'content-gated touch recognizer must not steal chrome '
                  'horizontal swipes from ancestors (dismissible / nested scroll)');
          expect(controller.selection, isNull);
          expect(tester.takeException(), isNull);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );

    testWidgets(
      'horizontal drag with an active selection blocks an ancestor drag '
      'recognizer',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        try {
          var ancestorDrags = 0;
          final controller = MarkdownSelectionController()
            ..setDocuments(<MarkdownDocumentRef>[
              MarkdownDocumentRef(
                id: 'd',
                model: Markdown.fromString('Hello selectable world'),
              ),
            ]);

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: RawGestureDetector(
                  behavior: HitTestBehavior.translucent,
                  gestures: <Type, GestureRecognizerFactory>{
                    HorizontalDragGestureRecognizer:
                        GestureRecognizerFactoryWithHandlers<
                            HorizontalDragGestureRecognizer>(
                      HorizontalDragGestureRecognizer.new,
                      (HorizontalDragGestureRecognizer instance) {
                        instance.onStart = (_) => ancestorDrags++;
                      },
                    ),
                  },
                  child: MarkdownSelectionScope(
                    controller: controller,
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: 120, key: Key('chrome')),
                        SizedBox(width: 400, child: _Doc('d')),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          controller.selectAll();
          await tester.pumpAndSettle();
          expect(controller.selection, isNotNull);
          expect(controller.selection!.isCollapsed, isFalse);

          final chrome = tester.getCenter(find.byKey(const Key('chrome')));
          final gesture = await tester.startGesture(chrome);
          await tester.pump(const Duration(milliseconds: 20));
          await gesture.moveBy(const Offset(80, 0));
          await tester.pump();
          await gesture.up();
          await tester.pumpAndSettle();

          expect(ancestorDrags, 0,
              reason: 'active selection must eagerly claim horizontal drag '
                  'so dismissible does not run');
          expect(tester.takeException(), isNull);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );

    testWidgets(
      'drag through a gap still extends after a valid markdown start',
      (tester) async {
        final controller = MarkdownSelectionController()
          ..setDocuments(<MarkdownDocumentRef>[
            MarkdownDocumentRef(
              id: 'a',
              model: Markdown.fromString('Alpha word here'),
            ),
            MarkdownDocumentRef(
              id: 'b',
              model: Markdown.fromString('Beta word there'),
            ),
          ]);

        await tester.pumpWidget(_wrap(
          controller,
          const Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 400,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Doc('a'),
                  SizedBox(height: 48, key: Key('gap')),
                  _Doc('b'),
                ],
              ),
            ),
          ),
        ));
        await tester.pumpAndSettle();

        final aTl = tester.getTopLeft(find.byWidgetPredicate(
          (w) => w is MarkdownWidget && w.documentId == 'a',
        ));
        final bTl = tester.getTopLeft(find.byWidgetPredicate(
          (w) => w is MarkdownWidget && w.documentId == 'b',
        ));
        final gapCenter = tester.getCenter(find.byKey(const Key('gap')));

        // Starting in the gap must miss.
        await _clicks(tester, gapCenter, 2);
        expect(controller.selection, isNull);

        // Start on A, drag through the gap into B — clamp extend still works.
        final from = aTl + const Offset(8, 8);
        final to = bTl + const Offset(40, 8);
        await _mouseDrag(tester, from, to);
        expect(controller.getText(), contains('Alpha'));
        expect(controller.getText(), contains('Beta'));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('visible toolbar re-anchors when selection changes',
        (tester) async {
      final controller = MarkdownSelectionController()
        ..setDocuments(<MarkdownDocumentRef>[
          MarkdownDocumentRef(
              id: 'd',
              model: Markdown.fromString('Hello selectable world again')),
        ]);
      await pumpParagraph(tester, controller);

      controller.selectAll();
      await tester.pumpAndSettle();
      final state = tester.state<MarkdownSelectionScopeState>(
          find.byType(MarkdownSelectionScope));
      state.showToolbar();
      await tester.pumpAndSettle();
      expect(state.toolbarIsVisible, isTrue);

      final toolbarFinder = find.byType(AdaptiveTextSelectionToolbar);
      expect(toolbarFinder, findsOneWidget);
      final before = tester
          .widget<AdaptiveTextSelectionToolbar>(toolbarFinder)
          .anchors
          .primaryAnchor;

      final tl = tester.getTopLeft(find.byType(MarkdownWidget));
      controller.moveSelectionEdgeToGlobal(tl + const Offset(40, 8),
          isStart: false);
      await tester.pumpAndSettle();

      expect(state.toolbarIsVisible, isTrue,
          reason: 'toolbar stays up while the range shrinks');
      expect(toolbarFinder, findsOneWidget);
      final after = tester
          .widget<AdaptiveTextSelectionToolbar>(toolbarFinder)
          .anchors
          .primaryAnchor;
      expect(after, isNot(equals(before)),
          reason: 'mounted toolbar origin tracks the live selection bounds');
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'visible toolbar re-anchors when an ancestor ListView scrolls '
      '(scope inside scrollable; ScrollNotificationObserver)',
      (tester) async {
        final scrollController = ScrollController();
        addTearDown(scrollController.dispose);
        final controller = MarkdownSelectionController()
          ..setDocuments(<MarkdownDocumentRef>[
            MarkdownDocumentRef(
              id: 'd',
              model: Markdown.fromString('Hello selectable world again'),
            ),
          ]);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ListView(
                controller: scrollController,
                children: <Widget>[
                  const SizedBox(height: 200),
                  MarkdownSelectionScope(
                    controller: controller,
                    child: const SizedBox(width: 400, child: _Doc('d')),
                  ),
                  const SizedBox(height: 1200),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        controller.selectAll();
        await tester.pumpAndSettle();
        final state = tester.state<MarkdownSelectionScopeState>(
          find.byType(MarkdownSelectionScope),
        );
        state.showToolbar();
        await tester.pumpAndSettle();
        expect(state.toolbarIsVisible, isTrue);

        final toolbarFinder = find.byType(AdaptiveTextSelectionToolbar);
        expect(toolbarFinder, findsOneWidget);
        final before = tester
            .widget<AdaptiveTextSelectionToolbar>(toolbarFinder)
            .anchors
            .primaryAnchor;

        scrollController.jumpTo(120);
        await tester.pumpAndSettle();

        expect(state.toolbarIsVisible, isTrue);
        expect(toolbarFinder, findsOneWidget);
        final after = tester
            .widget<AdaptiveTextSelectionToolbar>(toolbarFinder)
            .anchors
            .primaryAnchor;
        expect(after, isNot(equals(before)),
            reason:
                'toolbar follows parent scroll via ScrollNotificationObserver');
        expect(after.dy, closeTo(before.dy - 120, 1.0));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'desktop context menu dismisses when enclosing scrollable scrolls',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
        try {
          final scrollController = ScrollController();
          addTearDown(scrollController.dispose);
          final controller = MarkdownSelectionController()
            ..setDocuments(<MarkdownDocumentRef>[
              MarkdownDocumentRef(
                id: 'd',
                model: Markdown.fromString('Hello selectable world again'),
              ),
            ]);

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: ListView(
                  controller: scrollController,
                  children: <Widget>[
                    const SizedBox(height: 200),
                    MarkdownSelectionScope(
                      controller: controller,
                      child: const SizedBox(width: 400, child: _Doc('d')),
                    ),
                    const SizedBox(height: 1200),
                  ],
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          controller.selectAll();
          await tester.pumpAndSettle();

          final docPos = tester.getTopLeft(find.byType(MarkdownWidget)) +
              const Offset(8, 8);
          final g = await tester.startGesture(docPos,
              kind: PointerDeviceKind.mouse, buttons: kSecondaryMouseButton);
          await g.up();
          await tester.pumpAndSettle();

          final state = tester.state<MarkdownSelectionScopeState>(
            find.byType(MarkdownSelectionScope),
          );
          expect(state.toolbarIsVisible, isTrue);
          expect(find.byType(AdaptiveTextSelectionToolbar), findsOneWidget);

          scrollController.jumpTo(50);
          await tester.pumpAndSettle();

          expect(state.toolbarIsVisible, isFalse,
              reason: 'scrolling on desktop must dismiss the context menu');
          expect(find.byType(AdaptiveTextSelectionToolbar), findsNothing);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );

    testWidgets(
      'toolbar hides when selection scrolls fully out of the host viewport',
      (tester) async {
        final scrollController = ScrollController();
        addTearDown(scrollController.dispose);
        final controller = MarkdownSelectionController()
          ..setDocuments(<MarkdownDocumentRef>[
            MarkdownDocumentRef(
              id: 'd',
              model: Markdown.fromString('Hello selectable world again'),
            ),
          ]);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MarkdownSelectionScope(
                controller: controller,
                child: ListView(
                  controller: scrollController,
                  children: const <Widget>[
                    SizedBox(width: 400, child: _Doc('d')),
                    SizedBox(height: 2000),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        controller.selectAll();
        await tester.pumpAndSettle();
        final state = tester.state<MarkdownSelectionScopeState>(
          find.byType(MarkdownSelectionScope),
        );
        state.showToolbar();
        await tester.pumpAndSettle();
        expect(state.toolbarIsVisible, isTrue);
        expect(find.byType(AdaptiveTextSelectionToolbar), findsOneWidget);

        // Push the selection well above the viewport.
        scrollController.jumpTo(800);
        await tester.pumpAndSettle();

        expect(state.toolbarIsVisible, isFalse,
            reason: 'off-screen selection must not keep a sunk bottom toolbar');
        expect(find.byType(AdaptiveTextSelectionToolbar), findsNothing);
        expect(controller.selection, isNotNull,
            reason: 'hiding the menu must not clear the selection');

        // Scroll the selection back into view — toolbar should restore.
        scrollController.jumpTo(0);
        await tester.pumpAndSettle();

        expect(state.toolbarIsVisible, isTrue,
            reason: 'toolbar restores when selection re-enters the host');
        expect(find.byType(AdaptiveTextSelectionToolbar), findsOneWidget);

        // Intentional dismiss must not restore on a later scroll.
        state.hideToolbar();
        await tester.pumpAndSettle();
        scrollController.jumpTo(800);
        await tester.pumpAndSettle();
        scrollController.jumpTo(0);
        await tester.pumpAndSettle();
        expect(state.toolbarIsVisible, isFalse,
            reason: 'intentional hideToolbar clears scroll-restore intent');
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'toolbar anchors stay inside the host when selection is partly '
      'off-screen',
      (tester) async {
        final scrollController = ScrollController();
        addTearDown(scrollController.dispose);
        final controller = MarkdownSelectionController()
          ..setDocuments(<MarkdownDocumentRef>[
            MarkdownDocumentRef(
              id: 'd',
              model: Markdown.fromString(
                'Line one of a tall selection block\n'
                'Line two of a tall selection block\n'
                'Line three of a tall selection block\n'
                'Line four of a tall selection block\n'
                'Line five of a tall selection block\n'
                'Line six of a tall selection block\n'
                'Line seven of a tall selection block\n'
                'Line eight of a tall selection block',
              ),
            ),
          ]);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 240,
                child: MarkdownSelectionScope(
                  controller: controller,
                  child: ListView(
                    controller: scrollController,
                    children: const <Widget>[
                      SizedBox(width: 400, child: _Doc('d')),
                      SizedBox(height: 800),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        controller.selectAll();
        await tester.pumpAndSettle();
        final state = tester.state<MarkdownSelectionScopeState>(
          find.byType(MarkdownSelectionScope),
        );
        state.showToolbar();
        await tester.pumpAndSettle();
        expect(state.toolbarIsVisible, isTrue);

        // Nudge so part of the selection is above the clip, part still in view.
        scrollController.jumpTo(40);
        await tester.pumpAndSettle();

        expect(state.toolbarIsVisible, isTrue);
        final host = tester.getRect(find.byType(MarkdownSelectionScope));
        final anchors = state.contextMenuAnchors;
        expect(host.contains(anchors.primaryAnchor), isTrue,
            reason: 'primary anchor must stay inside the visible host');
        expect(anchors.secondaryAnchor, isNotNull);
        expect(host.contains(anchors.secondaryAnchor!), isTrue,
            reason: 'secondary anchor must stay inside the visible host');
        expect(anchors.primaryAnchor.dy, isNot(equals(host.bottom)),
            reason: 'must not fall back to the host bottom edge');
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'toolbar pins near the top when a tall selection fills the viewport',
      (tester) async {
        final scrollController = ScrollController();
        addTearDown(scrollController.dispose);
        final controller = MarkdownSelectionController()
          ..setDocuments(<MarkdownDocumentRef>[
            MarkdownDocumentRef(
              id: 'd',
              model: Markdown.fromString(
                List.generate(
                  40,
                  (i) => 'Paragraph $i with enough text to wrap a bit.',
                ).join('\n\n'),
              ),
            ),
          ]);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 320,
                child: MarkdownSelectionScope(
                  controller: controller,
                  child: ListView(
                    controller: scrollController,
                    children: const <Widget>[
                      SizedBox(width: 400, child: _Doc('d')),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        controller.selectAll();
        await tester.pumpAndSettle();
        final state = tester.state<MarkdownSelectionScopeState>(
          find.byType(MarkdownSelectionScope),
        );
        state.showToolbar();
        await tester.pumpAndSettle();

        // Middle of the document — selection paint fills the clip; edges are
        // off-screen.
        final maxScroll = scrollController.position.maxScrollExtent;
        expect(maxScroll, greaterThan(200),
            reason: 'fixture must be taller than the viewport');
        scrollController.jumpTo(maxScroll / 2);
        await tester.pumpAndSettle();

        expect(state.toolbarIsVisible, isTrue);
        final host = tester.getRect(find.byType(MarkdownSelectionScope));
        final anchors = state.contextMenuAnchors;
        expect(anchors.secondaryAnchor, isNotNull);
        expect(
          anchors.secondaryAnchor!.dy - anchors.primaryAnchor.dy,
          lessThan(host.height * 0.35),
          reason: 'tall mid-selection must not use full-height top+bottom '
              'anchors (that sinks the menu to the host bottom)',
        );
        expect(anchors.primaryAnchor.dy, lessThan(host.center.dy),
            reason: 'primary stays in the upper half of the host');
        expect(anchors.secondaryAnchor!.dy, lessThan(host.bottom - 24),
            reason: 'secondary must not sit on the host bottom edge');
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'toolbar sticks to a visible bottom endpoint when the top is off-screen',
      (tester) async {
        final scrollController = ScrollController();
        addTearDown(scrollController.dispose);
        final controller = MarkdownSelectionController()
          ..setDocuments(<MarkdownDocumentRef>[
            MarkdownDocumentRef(
              id: 'd',
              model: Markdown.fromString(
                List.generate(
                  40,
                  (i) => 'Paragraph $i with enough text to wrap a bit.',
                ).join('\n\n'),
              ),
            ),
          ]);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 320,
                child: MarkdownSelectionScope(
                  controller: controller,
                  child: ListView(
                    controller: scrollController,
                    children: const <Widget>[
                      SizedBox(width: 400, child: _Doc('d')),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        controller.selectAll();
        await tester.pumpAndSettle();

        // Keep the extent (bottom) on screen; scroll the base off the top.
        final maxScroll = scrollController.position.maxScrollExtent;
        expect(maxScroll, greaterThan(200));
        scrollController.jumpTo(maxScroll);
        await tester.pumpAndSettle();

        final state = tester.state<MarkdownSelectionScopeState>(
          find.byType(MarkdownSelectionScope),
        );
        state.showToolbar();
        await tester.pumpAndSettle();

        final host = tester.getRect(find.byType(MarkdownSelectionScope));
        final anchors = state.contextMenuAnchors;
        final endRect = controller.selectionEndpointGlobalRect(base: false);
        final startRect = controller.selectionEndpointGlobalRect(base: true);
        expect(endRect, isNotNull);
        expect(host.inflate(8).overlaps(endRect!), isTrue,
            reason: 'fixture keeps the extent caret in the host');
        expect(
          startRect == null || !host.inflate(8).overlaps(startRect),
          isTrue,
          reason: 'fixture scrolls the base caret off-screen',
        );
        expect(anchors.secondaryAnchor, isNotNull);
        final belowAnchor = anchors.secondaryAnchor!;
        expect(
          (belowAnchor - endRect.bottomCenter).distance,
          lessThan(2.0),
          reason: 'single visible bottom endpoint owns the below anchor',
        );
        expect(belowAnchor.dy, greaterThan(host.center.dy - 40),
            reason: 'must not top-pin while the bottom edge is in view');
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'size-changed layout does not read geometry during performLayout',
      (tester) async {
        final controller = MarkdownSelectionController()
          ..setDocuments(<MarkdownDocumentRef>[
            MarkdownDocumentRef(
              id: 'd',
              model: Markdown.fromString('Hello selectable world again'),
            ),
          ]);
        var height = 240.0;
        late void Function(VoidCallback) setHeight;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  setHeight = setState;
                  return SizedBox(
                    height: height,
                    child: MarkdownSelectionScope(
                      controller: controller,
                      child: const Align(
                        alignment: Alignment.topLeft,
                        child: SizedBox(width: 400, child: _Doc('d')),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        controller.selectAll();
        await tester.pumpAndSettle();
        final state = tester.state<MarkdownSelectionScopeState>(
          find.byType(MarkdownSelectionScope),
        );
        state.showToolbar();
        await tester.pumpAndSettle();
        expect(state.toolbarIsVisible, isTrue);

        // Resize without a tap (toolbar overlay would eat pointer events).
        setHeight(() => height = 180);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull,
            reason: 'SizeChangedLayoutNotification must not sync-read '
                'RenderBox.size via toolbar geometry during layout');
        expect(state.toolbarIsVisible, isTrue);
      },
    );

    testWidgets(
      'toolbar hides when a scope inside an ancestor ListView scrolls away',
      (tester) async {
        final scrollController = ScrollController();
        addTearDown(scrollController.dispose);
        final controller = MarkdownSelectionController()
          ..setDocuments(<MarkdownDocumentRef>[
            MarkdownDocumentRef(
              id: 'd',
              model: Markdown.fromString('Hello selectable world again'),
            ),
          ]);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ListView(
                controller: scrollController,
                children: <Widget>[
                  const SizedBox(height: 200),
                  MarkdownSelectionScope(
                    controller: controller,
                    child: const SizedBox(width: 400, child: _Doc('d')),
                  ),
                  const SizedBox(height: 2000),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        controller.selectAll();
        await tester.pumpAndSettle();
        final state = tester.state<MarkdownSelectionScopeState>(
          find.byType(MarkdownSelectionScope),
        );
        state.showToolbar();
        await tester.pumpAndSettle();
        expect(state.toolbarIsVisible, isTrue);

        scrollController.jumpTo(1200);
        await tester.pumpAndSettle();

        expect(find.byType(AdaptiveTextSelectionToolbar), findsNothing);
        expect(controller.toolbarWanted, isTrue,
            reason: 'scroll suppress keeps restore intent on the controller');

        scrollController.jumpTo(0);
        await tester.pumpAndSettle();

        // Scope may have remounted after leaving the viewport cache — read the
        // live state, not the pre-scroll handle.
        final restored = tester.state<MarkdownSelectionScopeState>(
          find.byType(MarkdownSelectionScope),
        );
        expect(restored.toolbarIsVisible, isTrue,
            reason: 'toolbar restores when the scope scrolls back into view');
        expect(find.byType(AdaptiveTextSelectionToolbar), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('dragging near a list edge autoscrolls the ancestor',
        (tester) async {
      final controller = MarkdownSelectionController()
        ..setDocuments(<MarkdownDocumentRef>[
          for (var i = 0; i < 12; i++)
            MarkdownDocumentRef(
              id: 'm$i',
              model: Markdown.fromString('Message number $i with more text'),
              order: i,
            ),
        ]);
      final scroll = ScrollController();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MarkdownSelectionScope(
            controller: controller,
            autoscroll: const MarkdownSelectionAutoscrollConfig(
              edgeZone: 80,
              maxVelocity: 2000,
              useMediaQueryPadding: false,
            ),
            child: SizedBox(
              height: 240,
              child: ListView.builder(
                controller: scroll,
                itemCount: 12,
                itemBuilder: (_, i) => SizedBox(
                  height: 80,
                  child: _Doc('m$i'),
                ),
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(scroll.offset, 0);

      final listRect = tester.getRect(find.byType(ListView));
      final first = find.byType(MarkdownWidget).first;
      final from = tester.getTopLeft(first) + const Offset(4, 8);
      final g = await tester.startGesture(from, kind: PointerDeviceKind.mouse);
      await tester.pump(const Duration(milliseconds: 50));
      await g.moveTo(Offset(listRect.center.dx, listRect.bottom - 4));
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      await g.up();
      await tester.pumpAndSettle();

      expect(scroll.offset, greaterThan(0),
          reason: 'edge-zone drag scrolls the descendant ListView');
      expect(tester.takeException(), isNull);
    });

    testWidgets('shift-click grows the selection toward the clicked point',
        (tester) async {
      final controller = MarkdownSelectionController()
        ..setDocuments(<MarkdownDocumentRef>[
          MarkdownDocumentRef(
              id: 'd', model: Markdown.fromString('Hello selectable world')),
        ]);
      final tl = await pumpParagraph(tester, controller);

      // Caret at the very start of the line.
      await _clicks(tester, tl + const Offset(1, 8), 1);
      expect(controller.getText(), isEmpty, reason: 'a single click collapses');

      // Shift-click into the middle grows a ranged selection from the caret.
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await _clicks(tester, tl + const Offset(120, 8), 1);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      final mid = controller.getText();
      expect(mid, isNotEmpty);
      expect('Hello selectable world'.startsWith(mid), isTrue,
          reason: 'the selection is a prefix anchored at the start caret');
      expect(mid.length, lessThan('Hello selectable world'.length));

      // Shift-click past the line end grows it to the whole line.
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await _clicks(tester, tl + const Offset(399, 8), 1);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      final grown = controller.getText();
      expect(grown, 'Hello selectable world');
      expect(grown.length, greaterThan(mid.length),
          reason: 'clicking further right extends the selection');
      expect(grown.startsWith(mid), isTrue);
      expect(tester.takeException(), isNull);
    });
  });

  group('selection toolbar buttons', () {
    testWidgets('tapping Copy in the toolbar copies the selection',
        (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      // Reset via try/finally (not addTearDown): the framework's foundation-var
      // invariant check runs before user tearDowns in this Flutter version.
      try {
        final md = Markdown.fromString('One two\n\nThree four');
        final controller = MarkdownSelectionController()
          ..setDocuments(
              <MarkdownDocumentRef>[MarkdownDocumentRef(id: 'd', model: md)])
          ..selectAll();

        final data = <MethodCall>[];
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async {
            if (call.method == 'Clipboard.setData') data.add(call);
            return null;
          },
        );
        addTearDown(() => tester.binding.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null));

        await tester.pumpWidget(
            _wrap(controller, const SizedBox(width: 400, child: _Doc('d'))));
        await tester.pumpAndSettle();

        final state = tester.state<MarkdownSelectionScopeState>(
            find.byType(MarkdownSelectionScope));
        state.showToolbar();
        await tester.pumpAndSettle();
        expect(find.text('Copy'), findsOneWidget);

        // Tap the real toolbar button end-to-end.
        await tester.tap(find.text('Copy'));
        await tester.pumpAndSettle();

        expect(data, isNotEmpty);
        expect(data.first.arguments['text'], 'One two\nThree four');
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('tapping Select all in the toolbar selects every document',
        (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      try {
        final md = Markdown.fromString('One two\n\nThree four');
        final controller = MarkdownSelectionController()
          ..setDocuments(
              <MarkdownDocumentRef>[MarkdownDocumentRef(id: 'd', model: md)])
          // Start with only the first paragraph selected.
          ..selection = const MarkdownSelection(
            base: MarkdownPosition(documentId: 'd', blockIndex: 0, offset: 0),
            extent: MarkdownPosition(documentId: 'd', blockIndex: 0, offset: 7),
          );

        await tester.pumpWidget(
            _wrap(controller, const SizedBox(width: 400, child: _Doc('d'))));
        await tester.pumpAndSettle();
        expect(controller.getText(), 'One two');

        final state = tester.state<MarkdownSelectionScopeState>(
            find.byType(MarkdownSelectionScope));
        state.showToolbar();
        await tester.pumpAndSettle();
        expect(find.text('Select all'), findsOneWidget);

        await tester.tap(find.text('Select all'));
        await tester.pumpAndSettle();

        expect(controller.getText(), 'One two\nThree four',
            reason: 'select all now spans both paragraphs');
        final sel = controller.selection!;
        expect(sel.base.offset, 0);
        expect(sel.extent.blockIndex, 2);
        expect(sel.extent.offset, 10);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets(
        'controller.selectAll on desktop updates selection without '
        'showing toolbar', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      try {
        final md = Markdown.fromString('Programmatic select all');
        final controller = MarkdownSelectionController()
          ..setDocuments(
              <MarkdownDocumentRef>[MarkdownDocumentRef(id: 'd', model: md)]);

        await tester.pumpWidget(
            _wrap(controller, const SizedBox(width: 400, child: _Doc('d'))));
        await tester.pumpAndSettle();

        expect(find.byType(AdaptiveTextSelectionToolbar), findsNothing);

        controller.selectAll();
        await tester.pumpAndSettle();

        expect(controller.toolbarWanted, isFalse);
        expect(controller.getText(), 'Programmatic select all');
        final state = tester.state<MarkdownSelectionScopeState>(
            find.byType(MarkdownSelectionScope));
        expect(state.toolbarIsVisible, isFalse);
        expect(find.byType(AdaptiveTextSelectionToolbar), findsNothing);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('controller.selectAll on mobile shows the toolbar with options',
        (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        final md = Markdown.fromString('Mobile select all');
        final controller = MarkdownSelectionController()
          ..setDocuments(
              <MarkdownDocumentRef>[MarkdownDocumentRef(id: 'd', model: md)]);

        await tester.pumpWidget(
            _wrap(controller, const SizedBox(width: 400, child: _Doc('d'))));
        await tester.pumpAndSettle();

        expect(find.byType(AdaptiveTextSelectionToolbar), findsNothing);

        controller.selectAll();
        await tester.pumpAndSettle();

        expect(controller.toolbarWanted, isTrue);
        expect(controller.getText(), 'Mobile select all');
        final state = tester.state<MarkdownSelectionScopeState>(
            find.byType(MarkdownSelectionScope));
        expect(state.toolbarIsVisible, isTrue);
        expect(find.byType(AdaptiveTextSelectionToolbar), findsOneWidget);
        expect(find.text('Copy'), findsOneWidget);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets(
        'assigning controller.selection on desktop does not show toolbar',
        (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      try {
        final md = Markdown.fromString('Assign selection range');
        final controller = MarkdownSelectionController()
          ..setDocuments(
              <MarkdownDocumentRef>[MarkdownDocumentRef(id: 'd', model: md)]);

        await tester.pumpWidget(
            _wrap(controller, const SizedBox(width: 400, child: _Doc('d'))));
        await tester.pumpAndSettle();

        controller.selection = const MarkdownSelection(
          base: MarkdownPosition(documentId: 'd', blockIndex: 0, offset: 0),
          extent: MarkdownPosition(documentId: 'd', blockIndex: 0, offset: 6),
        );
        await tester.pumpAndSettle();

        expect(controller.toolbarWanted, isFalse);
        expect(controller.getText(), 'Assign');
        final state = tester.state<MarkdownSelectionScopeState>(
            find.byType(MarkdownSelectionScope));
        expect(state.toolbarIsVisible, isFalse);
        expect(find.byType(AdaptiveTextSelectionToolbar), findsNothing);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('assigning controller.selection on mobile shows the toolbar',
        (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        final md = Markdown.fromString('Assign on mobile');
        final controller = MarkdownSelectionController()
          ..setDocuments(
              <MarkdownDocumentRef>[MarkdownDocumentRef(id: 'd', model: md)]);

        await tester.pumpWidget(
            _wrap(controller, const SizedBox(width: 400, child: _Doc('d'))));
        await tester.pumpAndSettle();

        controller.selection = const MarkdownSelection(
          base: MarkdownPosition(documentId: 'd', blockIndex: 0, offset: 0),
          extent: MarkdownPosition(documentId: 'd', blockIndex: 0, offset: 6),
        );
        await tester.pumpAndSettle();

        expect(controller.toolbarWanted, isTrue);
        expect(controller.getText(), 'Assign');
        final state = tester.state<MarkdownSelectionScopeState>(
            find.byType(MarkdownSelectionScope));
        expect(state.toolbarIsVisible, isTrue);
        expect(find.byType(AdaptiveTextSelectionToolbar), findsOneWidget);
        expect(find.text('Copy'), findsOneWidget);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('keyboard select all does not show toolbar on desktop',
        (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      try {
        final md = Markdown.fromString('Keyboard select all');
        final controller = MarkdownSelectionController()
          ..setDocuments(
              <MarkdownDocumentRef>[MarkdownDocumentRef(id: 'd', model: md)]);

        await tester.pumpWidget(
            _wrap(controller, const SizedBox(width: 400, child: _Doc('d'))));
        await tester.pumpAndSettle();

        Actions.invoke(
          tester.element(find.byType(MarkdownWidget)),
          const SelectAllTextIntent(SelectionChangedCause.keyboard),
        );
        await tester.pumpAndSettle();

        expect(controller.getText(), 'Keyboard select all');
        final state = tester.state<MarkdownSelectionScopeState>(
            find.byType(MarkdownSelectionScope));
        expect(state.toolbarIsVisible, isFalse);
        expect(find.byType(AdaptiveTextSelectionToolbar), findsNothing);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  });

  group('selection highlight', () {
    testWidgets('paints over an opaque code-block background', (tester) async {
      // Code fences paint opaque chrome inside the content Picture. The
      // under-content highlight pass would be hidden; a second pass paints
      // above only those blocks (`selectionHighlightAboveCachedContent`).
      // Normal paragraphs keep highlight *under* glyphs (SelectionArea order).
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

    testWidgets('paints over table zebra row backgrounds', (tester) async {
      final md = Markdown.fromString(
        '| A | B |\n| --- | --- |\n| 1 | 2 |\n| 3 | 4 |\n| 5 | 6 |\n',
      );
      final controller = MarkdownSelectionController()
        ..setDocuments(
            <MarkdownDocumentRef>[MarkdownDocumentRef(id: 'd', model: md)]);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MarkdownSelectionScope(
            controller: controller,
            selectionColor: const Color(0x80FF0000),
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

      final len = markdownBlockRenderedText(md.blocks.first).length;
      controller.selection = MarkdownSelection(
        base: const MarkdownPosition(documentId: 'd', blockIndex: 0, offset: 0),
        extent: MarkdownPosition(documentId: 'd', blockIndex: 0, offset: len),
      );
      await tester.pumpAndSettle();

      // Highlight covers glyph boxes only (cell padding has zebra fill alone).
      // Even data rows (r % 2 == 0, r != 0) paint zebra under the content
      // Picture; sample a mid-table glyph so the above-pass tint is required.
      late final int r, g, b;
      await tester.runAsync(() async {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(const Key('capture')));
        final image = boundary.toImageSync();
        final width = image.width;
        final height = image.height;
        final data = await image.toByteData();
        image.dispose();
        // Row 2 of 4 (first zebra data row): ~62% down; cell pad is 8px.
        const x = 10;
        final y = (height * 5 ~/ 8).clamp(0, height - 1);
        final i = (y * width + x) * 4;
        r = data!.getUint8(i);
        g = data.getUint8(i + 1);
        b = data.getUint8(i + 2);
      });

      expect(r, greaterThan(g + 20),
          reason: 'selection tint must show through zebra row fills');
      expect(r, greaterThan(b + 20));
      expect(tester.takeException(), isNull);
    });

    testWidgets('paints over inline monospace backgrounds', (tester) async {
      // Only monospace so the sample cannot land on plain selected text.
      final md = Markdown.fromString('`benchmarks?`');
      final controller = MarkdownSelectionController()
        ..setDocuments(
            <MarkdownDocumentRef>[MarkdownDocumentRef(id: 'd', model: md)]);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MarkdownSelectionScope(
            controller: controller,
            selectionColor: const Color(0x80FF0000),
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

      final len = markdownBlockRenderedText(md.blocks.first).length;
      controller.selection = MarkdownSelection(
        base: const MarkdownPosition(documentId: 'd', blockIndex: 0, offset: 0),
        extent: MarkdownPosition(documentId: 'd', blockIndex: 0, offset: len),
      );
      await tester.pumpAndSettle();

      late final int r, g, b;
      await tester.runAsync(() async {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(const Key('capture')));
        final image = boundary.toImageSync();
        final width = image.width;
        final data = await image.toByteData();
        image.dispose();
        const x = 12, y = 8;
        final i = (y * width + x) * 4;
        r = data!.getUint8(i);
        g = data.getUint8(i + 1);
        b = data.getUint8(i + 2);
      });

      expect(r, greaterThan(g + 20),
          reason: 'the red highlight must tint inline monospace chrome');
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

    testWidgets('cursorResolver overrides hover cursor with custom cursor',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 400,
              child: MarkdownWidget(
                markdown: Markdown.fromString('Custom cursor text'),
                cursorResolver: (offset, blockIndex, block) =>
                    SystemMouseCursors.grab,
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
      await gesture.moveTo(tester.getCenter(find.byType(MarkdownWidget)));
      await tester.pumpAndSettle();

      expect(
        RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
        SystemMouseCursors.grab,
      );
    });

    testWidgets('cursorResolver receives block details and updates dynamically',
        (tester) async {
      final doc = Markdown.fromString('# Heading\n\nSecond block text');
      final seenIndices = <int?>[];
      final seenBlocks = <MD$Block?>[];

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 400,
              child: MarkdownWidget(
                markdown: doc,
                cursorResolver: (offset, blockIndex, block) {
                  seenIndices.add(blockIndex);
                  seenBlocks.add(block);
                  if (block is MD$Heading) {
                    return SystemMouseCursors.grab;
                  }
                  return SystemMouseCursors.cell;
                },
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

      // Hover over heading (near the top).
      final widgetTopLeft = tester.getTopLeft(find.byType(MarkdownWidget));
      await gesture.moveTo(widgetTopLeft + const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(
        RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
        SystemMouseCursors.grab,
      );
      expect(seenIndices, contains(0));
      expect(seenBlocks.any((b) => b is MD$Heading), isTrue);

      // Hover over second paragraph (further down).
      final widgetBottom = tester.getBottomLeft(find.byType(MarkdownWidget));
      await gesture.moveTo(widgetBottom - const Offset(-10, 10));
      await tester.pumpAndSettle();

      expect(
        RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
        SystemMouseCursors.cell,
      );
      expect(seenIndices, contains(2));
      expect(seenBlocks.any((b) => b is MD$Paragraph), isTrue);
    });

    testWidgets('cursorResolver returning null falls back to default cursors',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MarkdownTheme(
            data: MarkdownThemeData(
              textStyle: const TextStyle(fontSize: 14),
              onLinkTap: (_, __) {},
              cursorResolver: (offset, blockIndex, block) => null,
            ),
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 400,
                child: MarkdownWidget(
                  markdown:
                      Markdown.fromString('[click me](https://example.com)'),
                ),
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

      await gesture.moveTo(
          tester.getTopLeft(find.byType(MarkdownWidget)) + const Offset(8, 8));
      await tester.pumpAndSettle();

      expect(
        RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
        SystemMouseCursors.click,
      );
    });

    testWidgets('MarkdownWidget.cursorResolver overrides theme cursorResolver',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MarkdownTheme(
            data: MarkdownThemeData(
              textStyle: const TextStyle(fontSize: 14),
              cursorResolver: (offset, blockIndex, block) =>
                  SystemMouseCursors.forbidden,
            ),
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 400,
                child: MarkdownWidget(
                  markdown: Markdown.fromString('Text here'),
                  cursorResolver: (offset, blockIndex, block) =>
                      SystemMouseCursors.grab,
                ),
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

      await gesture.moveTo(tester.getCenter(find.byType(MarkdownWidget)));
      await tester.pumpAndSettle();

      expect(
        RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
        SystemMouseCursors.grab,
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
