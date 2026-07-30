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
}
