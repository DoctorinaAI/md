import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_md/flutter_md.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(
  MarkdownSelectionController controller,
  Widget child, {
  FocusNode? focusNode,
}) =>
    MaterialApp(
      home: Scaffold(
        body: MarkdownSelectionScope(
          controller: controller,
          focusNode: focusNode,
          child: child,
        ),
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
  group('keyboard shortcuts', () {
    testWidgets('Ctrl+A selects all', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      final md = Markdown.fromString('Hello keyboard world');
      final controller = MarkdownSelectionController()
        ..setDocuments(
            <MarkdownDocumentRef>[MarkdownDocumentRef(id: 'd', model: md)]);
      final focus = FocusNode();
      addTearDown(focus.dispose);

      await tester.pumpWidget(_wrap(
        controller,
        const SizedBox(width: 400, child: _Doc('d')),
        focusNode: focus,
      ));
      await tester.pumpAndSettle();
      focus.requestFocus();
      await tester.pump();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();

      debugDefaultTargetPlatformOverride = null;
      expect(controller.getText(), 'Hello keyboard world');
    });

    testWidgets('Esc clears the selection', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      final md = Markdown.fromString('Hello keyboard world');
      final controller = MarkdownSelectionController()
        ..setDocuments(
            <MarkdownDocumentRef>[MarkdownDocumentRef(id: 'd', model: md)])
        ..selectAll();
      final focus = FocusNode();
      addTearDown(focus.dispose);

      await tester.pumpWidget(_wrap(
        controller,
        const SizedBox(width: 400, child: _Doc('d')),
        focusNode: focus,
      ));
      await tester.pumpAndSettle();
      focus.requestFocus();
      await tester.pump();
      expect(controller.getText(), isNotEmpty);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();

      debugDefaultTargetPlatformOverride = null;
      expect(controller.selection, isNull);
    });

    testWidgets('Shift+ArrowRight extends the selection by a character',
        (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      final md = Markdown.fromString('Hello');
      final controller = MarkdownSelectionController()
        ..setDocuments(
            <MarkdownDocumentRef>[MarkdownDocumentRef(id: 'd', model: md)])
        ..selection = const MarkdownSelection.collapsed(
            MarkdownPosition(documentId: 'd', blockIndex: 0, offset: 0));
      final focus = FocusNode();
      addTearDown(focus.dispose);

      await tester.pumpWidget(_wrap(
        controller,
        const SizedBox(width: 400, child: _Doc('d')),
        focusNode: focus,
      ));
      await tester.pumpAndSettle();
      focus.requestFocus();
      await tester.pump();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump();

      debugDefaultTargetPlatformOverride = null;
      expect(controller.selection!.extent.offset, 1);
      expect(controller.getText(), 'H');
    });

    testWidgets('Shift+ArrowRight extends across a block boundary',
        (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      // Reset via try/finally (not addTearDown): the framework's foundation-var
      // invariant check runs before user tearDowns in this Flutter version.
      try {
        // '# Title\nBody text here' → block 0 heading "Title" (len 5), block 1
        // paragraph "Body text here" — adjacent blocks with no spacer between.
        final md = Markdown.fromString('# Title\nBody text here');
        final controller = MarkdownSelectionController()
          ..setDocuments(
              <MarkdownDocumentRef>[MarkdownDocumentRef(id: 'd', model: md)])
          ..selection = const MarkdownSelection(
            base: MarkdownPosition(documentId: 'd', blockIndex: 0, offset: 0),
            extent: MarkdownPosition(documentId: 'd', blockIndex: 0, offset: 5),
          );
        final focus = FocusNode();
        addTearDown(focus.dispose);

        await tester.pumpWidget(_wrap(
          controller,
          const SizedBox(width: 400, child: _Doc('d')),
          focusNode: focus,
        ));
        await tester.pumpAndSettle();
        focus.requestFocus();
        await tester.pump();

        await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
        // pump (not pumpAndSettle) to avoid overlay/magnifier animation loops.
        await tester.pump();

        final extent = controller.selection!.extent;
        expect(extent.documentId, 'd');
        expect(extent.blockIndex, 1,
            reason: 'the extent crossed from block 0 into block 1');
        expect(extent.offset, 0, reason: 'offset resets to block start');
        expect(controller.getText(), 'Title');
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('Ctrl+C copies the selection to the clipboard', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      final md = Markdown.fromString('Copy this text');
      final controller = MarkdownSelectionController()
        ..setDocuments(
            <MarkdownDocumentRef>[MarkdownDocumentRef(id: 'd', model: md)])
        ..selectAll();
      final focus = FocusNode();
      addTearDown(focus.dispose);

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

      await tester.pumpWidget(_wrap(
        controller,
        const SizedBox(width: 400, child: _Doc('d')),
        focusNode: focus,
      ));
      await tester.pumpAndSettle();
      focus.requestFocus();
      await tester.pump();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      debugDefaultTargetPlatformOverride = null;
      expect(data, isNotEmpty);
      expect(data.first.arguments['text'], 'Copy this text');
    });
  });

  group('context toolbar', () {
    testWidgets('right-click over a selection shows a Copy button',
        (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      final md = Markdown.fromString('Toolbar target text');
      final controller = MarkdownSelectionController()
        ..setDocuments(
            <MarkdownDocumentRef>[MarkdownDocumentRef(id: 'd', model: md)])
        ..selectAll();

      await tester.pumpWidget(_wrap(
        controller,
        const SizedBox(width: 400, child: _Doc('d')),
      ));
      await tester.pumpAndSettle();

      final center = tester.getCenter(find.byType(MarkdownWidget));
      final g = await tester.startGesture(center,
          kind: PointerDeviceKind.mouse, buttons: kSecondaryMouseButton);
      await g.up();
      await tester.pumpAndSettle();

      debugDefaultTargetPlatformOverride = null;
      expect(find.text('Copy'), findsOneWidget);
      expect(find.text('Select all'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('showToolbar/hideToolbar via the scope state', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      final md = Markdown.fromString('State driven toolbar');
      final controller = MarkdownSelectionController()
        ..setDocuments(
            <MarkdownDocumentRef>[MarkdownDocumentRef(id: 'd', model: md)])
        ..selectAll();

      await tester.pumpWidget(_wrap(
        controller,
        const SizedBox(width: 400, child: _Doc('d')),
      ));
      await tester.pumpAndSettle();

      final state = tester.state<MarkdownSelectionScopeState>(
          find.byType(MarkdownSelectionScope));
      state.showToolbar();
      await tester.pumpAndSettle();
      expect(find.text('Copy'), findsOneWidget);
      expect(state.toolbarIsVisible, isTrue);

      state.hideToolbar();
      await tester.pumpAndSettle();

      debugDefaultTargetPlatformOverride = null;
      expect(find.text('Copy'), findsNothing);
      expect(state.toolbarIsVisible, isFalse);
    });
  });

  // Deterministic, geometry-free coverage of the controller's keyboard-driven
  // extension primitives (what the Shift+arrow Actions delegate to).
  group('keyboard extension within a block', () {
    MarkdownSelectionController single() => MarkdownSelectionController()
      ..setDocuments(<MarkdownDocumentRef>[
        MarkdownDocumentRef(
            id: 'd', model: Markdown.fromString('Hello selectable world')),
      ]); // one paragraph block, rendered text length 22

    test('extendSelectionByCharacter(forward: false) shrinks by one char', () {
      final c = single()
        ..selection = const MarkdownSelection(
          base: MarkdownPosition(documentId: 'd', blockIndex: 0, offset: 0),
          extent: MarkdownPosition(documentId: 'd', blockIndex: 0, offset: 5),
        );
      c.extendSelectionByCharacter(forward: false);
      expect(c.selection!.extent.offset, 4);
      expect(c.getText(), 'Hell');
    });

    test('extendSelectionByWord(forward: true) grows one word at a time', () {
      final c = single()
        ..selection = const MarkdownSelection.collapsed(
            MarkdownPosition(documentId: 'd', blockIndex: 0, offset: 0));
      c.extendSelectionByWord(forward: true);
      expect(c.getText(), 'Hello');
      c.extendSelectionByWord(forward: true);
      expect(c.getText(), 'Hello selectable');
      expect(c.selection!.extent.offset, 16);
    });

    test('extendSelectionByWord(forward: false) grabs the previous word', () {
      final c = single()
        ..selection = const MarkdownSelection.collapsed(
            MarkdownPosition(documentId: 'd', blockIndex: 0, offset: 22));
      c.extendSelectionByWord(forward: false);
      expect(c.selection!.extent.offset, 17);
      expect(c.getText(), 'world');
    });

    test('extendSelectionToLineBreak reaches the block start/end', () {
      final c = single()
        ..selection = const MarkdownSelection(
          base: MarkdownPosition(documentId: 'd', blockIndex: 0, offset: 0),
          extent: MarkdownPosition(documentId: 'd', blockIndex: 0, offset: 5),
        );
      c.extendSelectionToLineBreak(forward: true); // End
      expect(c.selection!.extent.offset, 22);
      expect(c.getText(), 'Hello selectable world');

      c.selection = const MarkdownSelection(
        base: MarkdownPosition(documentId: 'd', blockIndex: 0, offset: 10),
        extent: MarkdownPosition(documentId: 'd', blockIndex: 0, offset: 22),
      );
      c.extendSelectionToLineBreak(forward: false); // Home
      expect(c.selection!.extent.offset, 0);
      expect(c.getText(), 'Hello sele');
    });
  });

  group('keyboard extension across blocks and documents', () {
    // '# Title\nBody text here' → block 0 heading "Title" (len 5), block 1
    // paragraph "Body text here" (len 14): adjacent, no spacer between them.
    MarkdownSelectionController headingDoc() => MarkdownSelectionController()
      ..setDocuments(<MarkdownDocumentRef>[
        MarkdownDocumentRef(
            id: 'd', model: Markdown.fromString('# Title\nBody text here')),
      ]);

    // Two paragraph blocks per doc (index 0 = paragraph, 1 = spacer, 2 = para).
    MarkdownSelectionController twoDocs() => MarkdownSelectionController()
      ..setDocuments(<MarkdownDocumentRef>[
        MarkdownDocumentRef(
            id: 'a',
            model: Markdown.fromString('Alpha one\n\nAlpha two'),
            order: 0),
        MarkdownDocumentRef(
            id: 'b',
            model: Markdown.fromString('Bravo one\n\nBravo two'),
            order: 1),
      ]);

    test('stepping forward off a block end moves into the next block', () {
      final c = headingDoc()
        ..selection = const MarkdownSelection(
          base: MarkdownPosition(documentId: 'd', blockIndex: 0, offset: 0),
          extent: MarkdownPosition(documentId: 'd', blockIndex: 0, offset: 5),
        );
      c.extendSelectionByCharacter(forward: true);
      final e = c.selection!.extent;
      expect(e.blockIndex, 1, reason: 'blockIndex incremented');
      expect(e.offset, 0, reason: 'offset reset to the block start');
      expect(e.documentId, 'd');
      expect(c.getText(), 'Title');
    });

    test('stepping backward off a block start moves into the previous block',
        () {
      final c = headingDoc()
        ..selection = const MarkdownSelection(
          base: MarkdownPosition(documentId: 'd', blockIndex: 1, offset: 14),
          extent: MarkdownPosition(documentId: 'd', blockIndex: 1, offset: 0),
        );
      c.extendSelectionByCharacter(forward: false);
      final e = c.selection!.extent;
      expect(e.blockIndex, 0, reason: 'blockIndex decremented into block 0');
      expect(e.offset, 5, reason: 'landed at the end of the previous block');
      expect(c.getText(), 'Body text here');
    });

    test('stepping forward off the last block of doc A lands in doc B', () {
      final c = twoDocs()
        ..selection = const MarkdownSelection(
          base: MarkdownPosition(documentId: 'a', blockIndex: 0, offset: 0),
          extent: MarkdownPosition(documentId: 'a', blockIndex: 2, offset: 9),
        );
      c.extendSelectionByCharacter(forward: true);
      final e = c.selection!.extent;
      expect(e.documentId, 'b', reason: 'crossed into the next document');
      expect(e.blockIndex, 0);
      expect(e.offset, 0);
    });

    test('stepping backward off the first block of doc B lands in doc A', () {
      final c = twoDocs()
        ..selection = const MarkdownSelection(
          base: MarkdownPosition(documentId: 'b', blockIndex: 0, offset: 5),
          extent: MarkdownPosition(documentId: 'b', blockIndex: 0, offset: 0),
        );
      c.extendSelectionByCharacter(forward: false);
      final e = c.selection!.extent;
      expect(e.documentId, 'a');
      expect(e.blockIndex, 2, reason: 'end of doc A (last non-empty block)');
      expect(e.offset, 9, reason: 'end of "Alpha two"');
    });

    test('extendSelectionToDocumentBoundary reaches the first/last position',
        () {
      final c = twoDocs()
        ..selection = const MarkdownSelection.collapsed(
            MarkdownPosition(documentId: 'a', blockIndex: 0, offset: 0));
      c.extendSelectionToDocumentBoundary(forward: true);
      final end = c.selection!.extent;
      expect(end.documentId, 'b');
      expect(end.blockIndex, 2);
      expect(end.offset, 9, reason: 'the very last position across all docs');
      expect(c.getText(), 'Alpha one\nAlpha two\n\nBravo one\nBravo two');

      c.selection = const MarkdownSelection.collapsed(
          MarkdownPosition(documentId: 'b', blockIndex: 2, offset: 9));
      c.extendSelectionToDocumentBoundary(forward: false);
      final start = c.selection!.extent;
      expect(start.documentId, 'a');
      expect(start.blockIndex, 0);
      expect(start.offset, 0, reason: 'the first position across all docs');
    });
  });
}
