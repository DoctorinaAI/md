import 'package:flutter/material.dart';
import 'package:flutter_md/flutter_md.dart';
import 'package:flutter_test/flutter_test.dart';

/// Counts every canvas call; enough to tell "painted something" from
/// "painted nothing".
class _CountingCanvas implements Canvas {
  int calls = 0;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    calls++;
    return null;
  }
}

/// A host painter (e.g. a code fence with a copy button) that exposes no
/// selectable text.
class _OpaqueChild implements BlockPainter {
  @override
  Size size = Size.zero;

  @override
  void handleTapDown(PointerDownEvent event) {}

  @override
  void handleTapUp(PointerUpEvent event) {}

  @override
  Size layout(double width) => size = const Size(40, 20);

  @override
  void paint(Canvas canvas, Size size, double offset) {}

  @override
  void dispose() {}
}

final MarkdownThemeData _theme = MarkdownThemeData(
  textStyle: const TextStyle(fontSize: 14),
);

/// Default-like painter for a nested child (no host builder).
BlockPainter _child(MD$Block b, MarkdownThemeData theme) => b.map(
      paragraph: (p) => BlockPainter$Paragraph(spans: p.spans, theme: theme),
      heading: (h) => BlockPainter$Heading(
        level: h.level,
        spans: h.spans,
        theme: theme,
      ),
      quote: (q) => _quote(q, theme),
      code: (c) => BlockPainter$Code(
        text: c.text,
        language: c.language,
        theme: theme,
      ),
      list: (l) => BlockPainter$List(items: l.items, theme: theme),
      divider: (_) => BlockPainter$Divider(theme: theme),
      table: (t) => BlockPainter$Table(
        header: t.header,
        rows: t.rows,
        alignments: t.alignments,
        theme: theme,
      ),
      alert: (a) => _alert(a, theme),
      spacer: (s) => BlockPainter$Spacer(count: s.count, theme: theme),
    );

BlockPainter$Quote _quote(
  MD$Quote q,
  MarkdownThemeData theme, {
  BlockPainter Function(MD$Block, MarkdownThemeData) build = _child,
}) =>
    BlockPainter$Quote(
      spans: q.spans,
      indent: q.indent,
      theme: theme,
      children: [for (final b in q.blocks) build(b, theme)],
      blocks: q.blocks,
    );

BlockPainter$Alert _alert(
  MD$Alert a,
  MarkdownThemeData theme, {
  BlockPainter Function(MD$Block, MarkdownThemeData) build = _child,
}) =>
    BlockPainter$Alert(
      alert: a.alert,
      spans: a.spans,
      theme: theme,
      children: [for (final b in a.blocks) build(b, theme)],
      blocks: a.blocks,
    );

T _first<T extends MD$Block>(String source) =>
    Markdown.fromString(source).blocks.whereType<T>().first;

const String _wideTable =
    '| Supercalifragilisticexpialidocious | Antidisestablishmentarianism |\n'
    '|---|---|\n'
    '| a | b |\n';

String _quoted(String body) =>
    body.split('\n').map((l) => l.isEmpty ? '>' : '> $l').join('\n');

Future<MarkdownSelectionController> _pumpSelectable(
  WidgetTester tester,
  String source,
  double width,
) async {
  final model = Markdown.fromString(source);
  final controller = MarkdownSelectionController()
    ..setDocuments(<MarkdownDocumentRef>[
      MarkdownDocumentRef(id: 'd', model: model),
    ]);
  addTearDown(controller.dispose);
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: MarkdownSelectionScope(
        controller: controller,
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: width,
            child: MarkdownWidget(markdown: model, documentId: 'd'),
          ),
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
  return controller;
}

void main() {
  group('Block painters', () {
    group('code narrower than its padding', () {
      test('is inert for selection on a first narrow layout', () {
        final code =
            BlockPainter$Code(text: 'abc', language: null, theme: _theme);
        addTearDown(code.dispose);
        expect(code.layout(10), Size.zero);
        expect(code.boxesForRange(0, 3), isEmpty);
        expect(code.hitsRenderedTextAt(const Offset(1, 1)), isFalse);
        expect(code.isLinkAtLocal(const Offset(1, 1)), isFalse);
        expect(code.caretRectFor(1, TextAffinity.downstream), Rect.zero);
        expect(
          () => code.positionAndAffinityForLocal(const Offset(1, 1)),
          returnsNormally,
        );
        expect(code.renderedText, 'abc');
      });

      test('drops the stale wide layout after narrowing', () {
        final code =
            BlockPainter$Code(text: 'abc', language: null, theme: _theme);
        addTearDown(code.dispose);
        code.layout(400);
        expect(code.boxesForRange(0, 3), isNotEmpty);
        code.layout(10);
        expect(code.boxesForRange(0, 3), isEmpty);
        expect(code.hitsRenderedTextAt(const Offset(10, 10)), isFalse);
        code.layout(400);
        expect(code.boxesForRange(0, 3), isNotEmpty);
      });

      test('keeps its text but adds no fragment inside a quote', () {
        final q = _first<MD$Quote>(_quoted('text\n```\ncode\n```\n'));
        expect(q.blocks, isNotEmpty);
        final quote = _quote(q, _theme);
        addTearDown(quote.dispose);
        quote.layout(30); // content width 10: the fence collapses.
        expect(quote.renderedText, markdownBlockRenderedText(q));
        expect(quote.fragments.map((f) => f.painter.plainText), ['text']);
        final codeStart = quote.renderedText.indexOf('code');
        expect(quote.boxesForRange(codeStart, codeStart + 4), isEmpty);
        expect(
          () => quote.boxesForRange(0, quote.renderedText.length),
          returnsNormally,
        );
      });

      testWidgets('select all in a 14px document does not throw',
          (tester) async {
        final controller =
            await _pumpSelectable(tester, 'hi\n\n```\ncode\n```\n', 14);
        controller.selectAll();
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(controller.getText(), contains('code'));
      });

      testWidgets('select all in a narrow alert with a fence does not throw',
          (tester) async {
        final controller = await _pumpSelectable(
          tester,
          '> [!NOTE]\n> hi\n> ```\n> code\n> ```\n',
          45,
        );
        controller.selectAll();
        await tester.pump();
        expect(tester.takeException(), isNull);
      });
    });

    group('nested children that overflow', () {
      test('a quote with a too-wide table still paints', () {
        final q = _first<MD$Quote>(_quoted('```\nx\n```\n\n$_wideTable'));
        expect(q.blocks.whereType<MD$Table>(), isNotEmpty);
        final quote = _quote(q, _theme);
        addTearDown(quote.dispose);
        expect(quote.layout(200).width, greaterThan(200));
        final canvas = _CountingCanvas();
        quote.paint(canvas, const Size(200, 1000), 0);
        expect(canvas.calls, greaterThan(0));
        expect(quote.renderedText, markdownBlockRenderedText(q));
      });

      test('an alert with a too-wide table still paints', () {
        final a = _first<MD$Alert>(
          '> [!NOTE]\n${_quoted('```\nx\n```\n\n$_wideTable')}',
        );
        expect(a.blocks.whereType<MD$Table>(), isNotEmpty);
        final alert = _alert(a, _theme);
        addTearDown(alert.dispose);
        expect(alert.layout(200).width, greaterThan(200));
        final canvas = _CountingCanvas();
        alert.paint(canvas, const Size(200, 1000), 0);
        expect(canvas.calls, greaterThan(2)); // more than the chrome
        expect(alert.renderedText, markdownBlockRenderedText(a));
      });

      test('a leaf quote wider than the paint size still skips painting', () {
        final q = _first<MD$Quote>('> hello world');
        final quote = _quote(q, _theme);
        addTearDown(quote.dispose);
        final size = quote.layout(400);
        final canvas = _CountingCanvas();
        quote.paint(canvas, Size(size.width - 1, 100), 0);
        expect(canvas.calls, 0);
      });
    });

    group('host child painters without selectable text', () {
      BlockPainter opaqueCode(MD$Block b, MarkdownThemeData theme) =>
          b is MD$Code ? _OpaqueChild() : _child(b, theme);

      test('keep the quote offset space equal to the model', () {
        final q = _first<MD$Quote>(_quoted('```\ncode\n```\nafter'));
        final quote = _quote(q, _theme, build: opaqueCode);
        addTearDown(quote.dispose);
        quote.layout(300);
        final model = markdownBlockRenderedText(q);
        expect(quote.renderedText, model);
        final after = model.indexOf('after');
        expect(after, greaterThan(0));
        expect(quote.fragments.single.textStart, after);
        expect(quote.boxesForRange(after, after + 5), isNotEmpty);
        expect(quote.boxesForRange(0, 4), isEmpty);
      });

      test('keep the alert offset space equal to the model', () {
        final a = _first<MD$Alert>(
          '> [!TIP]\n${_quoted('```\ncode\n```\nafter')}',
        );
        final alert = _alert(a, _theme, build: opaqueCode);
        addTearDown(alert.dispose);
        alert.layout(300);
        expect(alert.renderedText, markdownBlockRenderedText(a));
      });

      test('without blocks, fall back to the selectable children only', () {
        final q = _first<MD$Quote>(_quoted('```\ncode\n```\nafter'));
        final quote = BlockPainter$Quote(
          spans: q.spans,
          indent: q.indent,
          theme: _theme,
          children: [for (final b in q.blocks) opaqueCode(b, _theme)],
        );
        addTearDown(quote.dispose);
        quote.layout(300);
        expect(quote.renderedText, 'after');
      });
    });

    group('glyph-tight hover', () {
      const wrapping = 'aaaa aaaa aaaa aaaa b';

      /// A point in the empty gutter after the short last line of [painter],
      /// expressed in [painter]-local coordinates.
      Offset gutter(BlockPainter$Paragraph painter) =>
          Offset(painter.size.width - 2, painter.size.height - 3);

      test('a leaf quote ignores the gutter after a short line', () {
        final q = _first<MD$Quote>('> $wrapping');
        final quote = _quote(q, _theme);
        final para = BlockPainter$Paragraph(spans: q.spans, theme: _theme);
        addTearDown(quote.dispose);
        addTearDown(para.dispose);
        quote.layout(120); // 20px of bars + a 100px text column
        para.layout(100);
        expect(para.size.height, greaterThan(20), reason: 'must wrap');
        const shift = Offset(20, 0);
        expect(quote.hitsRenderedTextAt(gutter(para) + shift), isFalse);
        expect(quote.hitsRenderedTextAt(const Offset(4, 4) + shift), isTrue);
        expect(quote.hitsRenderedTextAt(const Offset(4, 4)), isFalse);
      });

      test('a leaf alert ignores the gutter and the title', () {
        final a = _first<MD$Alert>('> [!NOTE]\n> $wrapping');
        final alert = _alert(a, _theme);
        final para = BlockPainter$Paragraph(spans: a.spans, theme: _theme);
        addTearDown(alert.dispose);
        addTearDown(para.dispose);
        // contentLeft 24 + 100 + right padding 10.
        alert.layout(134);
        para.layout(100);
        expect(para.size.height, greaterThan(20), reason: 'must wrap');
        final body = alert.fragments.single.origin;
        expect(alert.hitsRenderedTextAt(body + gutter(para)), isFalse);
        expect(alert.hitsRenderedTextAt(body + const Offset(4, 4)), isTrue);
        // The title row is chrome, not selectable text.
        expect(alert.hitsRenderedTextAt(const Offset(30, 14)), isFalse);
      });

      test('nested paragraphs use their own glyph boxes', () {
        final q = _first<MD$Quote>(_quoted('```\nx\n```\n$wrapping'));
        final quote = _quote(q, _theme);
        addTearDown(quote.dispose);
        quote.layout(120);
        final frag = quote.fragments.last;
        expect(frag.painter.plainText, wrapping);
        final inner = Offset(
          frag.painter.width - 2,
          frag.painter.height - 3,
        );
        expect(quote.hitsRenderedTextAt(frag.origin + inner), isFalse);
        expect(
          quote.hitsRenderedTextAt(frag.origin + const Offset(4, 4)),
          isTrue,
        );
        // The code fence keeps its own (glyph) policy too.
        final code = quote.fragments.first;
        expect(
          quote.hitsRenderedTextAt(code.origin + const Offset(2, 4)),
          isTrue,
        );
      });

      test('right-to-left leaf quote hits its right-aligned glyphs', () {
        final rtl = MarkdownThemeData(
          textStyle: const TextStyle(fontSize: 14),
          textDirection: TextDirection.rtl,
        );
        final q = _first<MD$Quote>('> שלום');
        final quote = _quote(q, rtl);
        addTearDown(quote.dispose);
        quote.layout(300);
        final frag = quote.fragments.single;
        expect(frag.origin.dx, greaterThan(200));
        expect(
          quote.hitsRenderedTextAt(frag.origin + const Offset(2, 4)),
          isTrue,
        );
        expect(quote.hitsRenderedTextAt(const Offset(4, 4)), isFalse);
      });
    });

    group('multi-painter carets', () {
      test('caret at a separator and past the end stays in range', () {
        final l = _first<MD$List>('- one\n- two\n');
        final list = BlockPainter$List(items: l.items, theme: _theme);
        addTearDown(list.dispose);
        list.layout(300);
        expect(list.renderedText, 'one\ntwo');
        final first = list.fragments.first;
        final last = list.fragments.last;
        // Offset 3 is the '\n' separator: end of the first item.
        final sep = list.caretRectFor(3, TextAffinity.upstream);
        expect(sep.top, closeTo(first.origin.dy, 0.5));
        expect(sep.left, greaterThan(first.origin.dx));
        final end = list.caretRectFor(999, TextAffinity.downstream);
        expect(end.top, closeTo(last.origin.dy, 0.5));
        expect(end.height, greaterThan(0));
      });
    });

    group('nested link taps', () {
      test('a link in a nested quote paragraph fires in LTR and RTL', () {
        for (final direction in TextDirection.values) {
          final taps = <String>[];
          final theme = MarkdownThemeData(
            textStyle: const TextStyle(fontSize: 14),
            textDirection: direction,
            onLinkTap: (title, url) => taps.add(url),
          );
          final q = _first<MD$Quote>(_quoted('```\nx\n```\n[go](u)'));
          final quote = _quote(q, theme);
          addTearDown(quote.dispose);
          quote.layout(300);
          final link = quote.fragments.last;
          expect(link.painter.plainText, 'go');
          final at = link.origin + const Offset(3, 4);
          quote
            ..handleTapDown(PointerDownEvent(position: at))
            ..handleTapUp(PointerUpEvent(position: at));
          expect(taps, ['u'], reason: '$direction');
          // A tap in the empty column beside the link does nothing.
          final away = Offset(
            direction == TextDirection.ltr ? 290 : 30,
            at.dy,
          );
          quote
            ..handleTapDown(PointerDownEvent(position: away))
            ..handleTapUp(PointerUpEvent(position: away));
          expect(taps, ['u'], reason: '$direction');
        }
      });
    });
  });
}
