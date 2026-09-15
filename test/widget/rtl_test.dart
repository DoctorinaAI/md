import 'package:flutter/material.dart';
import 'package:flutter_md/flutter_md.dart';
import 'package:flutter_test/flutter_test.dart';

const double _width = 400;

MarkdownThemeData _theme(TextDirection direction) => MarkdownThemeData(
      textStyle: const TextStyle(fontSize: 14),
      textDirection: direction,
    );

T _block<T extends MD$Block>(String source) =>
    Markdown.fromString(source).blocks.whereType<T>().first;

/// The bounding box of the highlight rectangles for `[start, end)`.
Rect _bounds(SelectableBlockPainter painter, int start, int end) =>
    painter.boxesForRange(start, end).reduce((a, b) => a.expandToInclude(b));

Rect _allBounds(SelectableBlockPainter painter) =>
    _bounds(painter, 0, painter.renderedText.length);

Future<void> _pumpRtl(
  WidgetTester tester,
  String source, {
  required void Function(String title, String url) onLinkTap,
  bool loose = false,
}) async {
  final markdown = MarkdownWidget(markdown: Markdown.fromString(source));
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: MarkdownTheme(
          data: MarkdownThemeData(
            textStyle: const TextStyle(fontSize: 14),
            textDirection: TextDirection.rtl,
            onLinkTap: onLinkTap,
          ),
          child: Center(
            child: SizedBox(
              width: _width,
              child: loose
                  ? Align(alignment: Alignment.centerRight, child: markdown)
                  : markdown,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Right-to-left layout', () {
    group('paragraph', () {
      BlockPainter$Paragraph paint(TextDirection direction) =>
          BlockPainter$Paragraph(
            spans: _block<MD$Paragraph>('שלום עולם').spans,
            theme: _theme(direction),
          )..layout(_width);

      test('aligns RTL text to the right edge', () {
        final box = _allBounds(paint(TextDirection.rtl));
        expect(box.right, closeTo(_width, 0.5));
        expect(box.left, greaterThan(0));
      });

      test('keeps LTR text against the left edge', () {
        final box = _allBounds(paint(TextDirection.ltr));
        expect(box.left, closeTo(0, 0.5));
        expect(box.right, lessThan(_width));
      });

      test('maps the right edge to the start of RTL text', () {
        final painter = paint(TextDirection.rtl);
        expect(painter.offsetForLocalPosition(const Offset(_width - 1, 7)), 0);
        expect(
          painter.offsetForLocalPosition(Offset(_allBounds(painter).left, 7)),
          painter.renderedText.length,
        );
      });
    });

    test('heading aligns to the right edge', () {
      final heading = _block<MD$Heading>('# כותרת');
      final painter = BlockPainter$Heading(
        level: heading.level,
        spans: heading.spans,
        theme: _theme(TextDirection.rtl),
      )..layout(_width);
      expect(_allBounds(painter).right, closeTo(_width, 0.5));
    });

    test('quote text sits left of the right-hand indent', () {
      final quote = _block<MD$Quote>('> ציטוט');
      final painter = BlockPainter$Quote(
        spans: quote.spans,
        indent: quote.indent,
        theme: _theme(TextDirection.rtl),
      )..layout(_width);
      final indent = BlockPainter$Quote.lineIndent * (quote.indent + 1);
      expect(_allBounds(painter).right, closeTo(_width - indent, 0.5));
    });

    test('alert body sits left of the right-hand accent bar', () {
      final alert = _block<MD$Alert>('> [!NOTE]\n> גוף ההתראה');
      final painter = BlockPainter$Alert(
        alert: alert.alert,
        spans: alert.spans,
        theme: _theme(TextDirection.rtl),
      )..layout(_width);
      const inset = BlockPainter$Alert.padding +
          BlockPainter$Alert.barWidth +
          BlockPainter$Alert.gap;
      expect(_allBounds(painter).right, closeTo(_width - inset, 0.5));
    });

    group('list', () {
      BlockPainter$List paint(TextDirection direction) => BlockPainter$List(
            items: _block<MD$List>('- אחד\n- שתיים').items,
            theme: _theme(direction),
          )..layout(_width);

      test('puts RTL item content left of a right-hand bullet', () {
        final painter = paint(TextDirection.rtl);
        final first = _bounds(painter, 0, 3);
        // Clear of the base indent and the bullet, but still near the right.
        expect(first.right, lessThan(_width - 8));
        expect(first.right, greaterThan(_width - 60));
      });

      test('keeps LTR item content right of a left-hand bullet', () {
        final painter = paint(TextDirection.ltr);
        final first = _bounds(painter, 0, 3);
        expect(first.left, greaterThan(8));
        expect(first.left, lessThan(60));
      });
    });

    group('table', () {
      const source = '| א | ב |\n|---|---|\n| 1 | 2 |';

      BlockPainter$Table paint(TextDirection direction) {
        final table = _block<MD$Table>(source);
        return BlockPainter$Table(
          header: table.header,
          rows: table.rows,
          alignments: table.alignments,
          theme: _theme(direction),
        )..layout(_width);
      }

      test('places the first RTL column on the right edge', () {
        final painter = paint(TextDirection.rtl);
        // Rendered text is "א\tב\n1\t2".
        final firstHeader = _bounds(painter, 0, 1);
        final secondHeader = _bounds(painter, 2, 3);
        expect(firstHeader.center.dx, greaterThan(secondHeader.center.dx));
        expect(_allBounds(painter).right, greaterThan(_width / 2));
      });

      test('keeps the first LTR column on the left edge', () {
        final painter = paint(TextDirection.ltr);
        final firstHeader = _bounds(painter, 0, 1);
        final secondHeader = _bounds(painter, 2, 3);
        expect(firstHeader.center.dx, lessThan(secondHeader.center.dx));
      });

      test('maps RTL taps back to the mirrored cells', () {
        final painter = paint(TextDirection.rtl);
        final firstData = _bounds(painter, 4, 5);
        expect(painter.offsetForLocalPosition(firstData.center),
            inInclusiveRange(4, 5));
      });
    });

    test('code blocks stay left-to-right', () {
      final code = _block<MD$Code>('```\nprint(1)\n```');
      final painter = BlockPainter$Code(
        text: code.text,
        language: code.language,
        theme: _theme(TextDirection.rtl),
      )..layout(_width);
      expect(_allBounds(painter).left, closeTo(BlockPainter$Code.padding, 0.5));
    });

    group('link taps', () {
      // Short enough to fit on one line, so the text only reaches the right
      // edge when the block is right-aligned. A tap past either end of a line
      // snaps to the nearest glyph, so the taps below aim just inside the
      // text: the first link is the rightmost glyph, the second the leftmost.
      const source = '[ראשון](https://a.example) ביניים '
          '[שני](https://b.example)';

      double contentWidth() => BlockPainter$Paragraph(
            spans: _block<MD$Paragraph>(source).spans,
            theme: _theme(TextDirection.rtl),
          ).layout(_width).width;

      testWidgets('hit the mirrored links under tight constraints',
          (tester) async {
        final tapped = <String>[];
        await _pumpRtl(tester, source, onLinkTap: (_, url) => tapped.add(url));
        final box = find.byType(MarkdownWidget);
        expect(tester.getSize(box).width, _width);

        final textLeft = _width - contentWidth();
        await tester.tapAt(tester.getTopLeft(box) + Offset(textLeft + 4, 7));
        await tester.tapAt(tester.getTopRight(box) + const Offset(-4, 7));
        expect(tapped, ['https://b.example', 'https://a.example']);
      });

      testWidgets('hug the content under loose constraints', (tester) async {
        final tapped = <String>[];
        await _pumpRtl(
          tester,
          source,
          onLinkTap: (_, url) => tapped.add(url),
          loose: true,
        );
        final box = find.byType(MarkdownWidget);
        expect(tester.takeException(), isNull);
        expect(tester.getSize(box).width, closeTo(contentWidth(), 0.5));

        await tester.tapAt(tester.getTopLeft(box) + const Offset(4, 7));
        await tester.tapAt(tester.getTopRight(box) + const Offset(-4, 7));
        expect(tapped, ['https://b.example', 'https://a.example']);
      });
    });
  });
}
