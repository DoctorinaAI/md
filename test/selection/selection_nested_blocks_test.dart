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

Future<MarkdownSelectionController> _pump(
  WidgetTester tester,
  String source, {
  double width = 400,
}) async {
  final controller = MarkdownSelectionController()
    ..setDocuments(<MarkdownDocumentRef>[
      MarkdownDocumentRef(id: 'd', model: Markdown.fromString(source)),
    ]);
  addTearDown(controller.dispose);

  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: MarkdownSelectionScope(
        controller: controller,
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: width, child: const _Doc('d')),
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
  return controller;
}

Future<void> _mouseDrag(WidgetTester tester, Offset from, Offset to) async {
  final g = await tester.startGesture(from, kind: PointerDeviceKind.mouse);
  await tester.pump(const Duration(milliseconds: 100));
  await g.moveTo(to);
  await tester.pump(const Duration(milliseconds: 100));
  await g.up();
  await tester.pumpAndSettle();
}

const _quoteWithFence = '''
> Intro line before the fence
> ```dart
> void main() {}
> ```
> Outro line after the fence
''';

const _alertWithFence = '''
> [!NOTE]
> Take care here
> ```sh
> echo hi
> ```
''';

void main() {
  group('quote / alert with nested fenced code', () {
    test('a quote body with a fence parses into nested blocks', () {
      final md = Markdown.fromString(_quoteWithFence);
      expect(md.blocks, hasLength(1));
      final quote = md.blocks.single as MD$Quote;
      expect(quote.spans, isEmpty);
      expect(quote.blocks.whereType<MD$Code>(), hasLength(1));
      expect(
        quote.blocks.whereType<MD$Code>().single.language,
        'dart',
      );
    });

    test('an alert body with a fence parses into nested blocks', () {
      final md = Markdown.fromString(_alertWithFence);
      final alert = md.blocks.single as MD$Alert;
      expect(alert.alert, MD$AlertType.note);
      expect(alert.spans, isEmpty);
      expect(alert.blocks.whereType<MD$Code>(), hasLength(1));
    });

    test('a plain quote keeps the leaf inline shape', () {
      final md = Markdown.fromString('> just prose\n> more prose');
      final quote = md.blocks.single as MD$Quote;
      expect(quote.blocks, isEmpty);
      expect(quote.spans, isNotEmpty);
    });

    test('markdownBlockRenderedText walks nested children', () {
      final quote = Markdown.fromString(_quoteWithFence).blocks.single;
      final text = markdownBlockRenderedText(quote);
      expect(text, contains('Intro line before the fence'));
      expect(text, contains('void main() {}'));
      expect(text, contains('Outro line after the fence'));
    });

    testWidgets('the painter fragments agree with markdownBlockRenderedText',
        (tester) async {
      // The whole selection layer indexes a block by
      // `markdownBlockRenderedText`; the painter must expose exactly that
      // string, or highlight geometry and copied text drift apart.
      for (final source in <String>[_quoteWithFence, _alertWithFence]) {
        final controller = await _pump(tester, source);
        final block = controller.documents.single.model.blocks.single;
        final expected = markdownBlockRenderedText(block);

        // Selecting every character must reproduce the block text verbatim.
        controller.selection = MarkdownSelection(
          base: const MarkdownPosition(
            documentId: 'd',
            blockIndex: 0,
            offset: 0,
          ),
          extent: MarkdownPosition(
            documentId: 'd',
            blockIndex: 0,
            offset: expected.length,
          ),
        );
        await tester.pumpAndSettle();
        expect(controller.getText(), expected);
      }
    });

    testWidgets('selecting the whole nested quote yields every child line',
        (tester) async {
      final controller = await _pump(tester, _quoteWithFence);

      final box = tester.getRect(find.byType(MarkdownWidget));
      await _mouseDrag(
        tester,
        box.topLeft + const Offset(2, 3),
        box.bottomRight - const Offset(2, 3),
      );

      final text = controller.getText();
      expect(text, contains('Intro line before the fence'));
      expect(text, contains('void main() {}'));
      expect(text, contains('Outro line after the fence'));
    });

    testWidgets('a highlight range inside the nested fence has geometry',
        (tester) async {
      final controller = await _pump(tester, _quoteWithFence);
      final block = controller.documents.single.model.blocks.single;
      final text = markdownBlockRenderedText(block);
      final start = text.indexOf('void main');
      expect(start, greaterThan(-1));

      final surface = controller.mountedSurfaces.single;
      final boxes = surface.localBoxesForRange(0, start, start + 9);
      expect(boxes, isNotEmpty);
      for (final box in boxes) {
        expect(box.width, greaterThan(0));
        expect(box.height, greaterThan(0));
      }
    });

    testWidgets('a nested quote paints without exceptions', (tester) async {
      await _pump(tester, '> outer\n> > inner\n> ```\n> code\n> ```');
      expect(tester.takeException(), isNull);
    });

    testWidgets('an unterminated fence inside a quote does not hang',
        (tester) async {
      await _pump(tester, '> before\n> ```\n> never closed');
      expect(tester.takeException(), isNull);
    });

    test('a quote whose body is only a fence still renders text', () {
      final md = Markdown.fromString('> ```\n> x\n> ```');
      final quote = md.blocks.single as MD$Quote;
      expect(markdownBlockRenderedText(quote), contains('x'));
    });

    testWidgets('a custom theme builder also builds nested children',
        (tester) async {
      final seen = <String>[];
      final theme = MarkdownThemeData(
        textStyle: const TextStyle(fontSize: 10, height: 2),
        builder: (block, theme) {
          seen.add(block.type);
          return null; // fall back to the default painter
        },
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 400,
              child: MarkdownWidget(
                markdown: Markdown.fromString(_quoteWithFence),
                theme: theme,
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(seen, contains('quote'));
      expect(
        seen,
        contains('code'),
        reason: 'a host that swaps the code painter expects it inside > too',
      );
      expect(tester.takeException(), isNull);
    });

    test('the markup formatter round-trips a nested fence', () {
      final md = Markdown.fromString(_quoteWithFence);
      final controller = MarkdownSelectionController()
        ..formatter = const MarkdownMarkupFormatter()
        ..setDocuments(
            <MarkdownDocumentRef>[MarkdownDocumentRef(id: 'd', model: md)]);
      addTearDown(controller.dispose);
      controller.selectAll();

      final out = controller.getText();
      expect(out, startsWith('> '));
      expect(out, contains('void main() {}'));
    });
  });
}
