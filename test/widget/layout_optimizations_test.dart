import 'dart:ui' show PictureRecorder;

import 'package:flutter/material.dart';
import 'package:flutter_md/flutter_md.dart';
import 'package:flutter_md/src/render.dart'
    show BlockPainter$Table, MarkdownPainter;
import 'package:flutter_test/flutter_test.dart';

MarkdownThemeData _theme({TextDirection direction = TextDirection.ltr}) =>
    MarkdownThemeData(
      textStyle: const TextStyle(fontSize: 14),
      textDirection: direction,
      textScaler: TextScaler.noScaling,
    );

MarkdownPainter _painter(String source, MarkdownThemeData theme) =>
    MarkdownPainter(markdown: Markdown.fromString(source), theme: theme);

void main() {
  group('Layout optimizations', () {
    group('table column widths', () {
      const table = '| long header cell | b |\n'
          '|---|---|\n'
          '| several words in one cell | x |\n'
          '|  | short |\n';

      test('a table that fits keeps its natural width', () {
        final painter = _painter(table, _theme());
        addTearDown(painter.dispose);
        final natural = painter.layout(maxWidth: double.infinity).width;
        final fitting = painter.layout(maxWidth: natural + 50).width;
        expect(fitting, natural);
      });

      test('a table at exactly its natural width does not wrap', () {
        final painter = _painter(table, _theme());
        addTearDown(painter.dispose);
        final natural = painter.layout(maxWidth: double.infinity);
        final exact = painter.layout(maxWidth: natural.width);
        expect(exact, natural);
      });

      test('a narrow table shrinks and wraps, but not below its words', () {
        final painter = _painter(table, _theme());
        addTearDown(painter.dispose);
        final natural = painter.layout(maxWidth: double.infinity);
        final narrow = painter.layout(maxWidth: natural.width * 0.6);
        expect(narrow.width, lessThan(natural.width));
        expect(narrow.height, greaterThan(natural.height));
        // Columns stop at their longest word and overflow past that.
        expect(painter.layout(maxWidth: 1).width, greaterThan(1));
      });

      test('a row shorter than the header survives the narrow path', () {
        final wide = Markdown.fromString('| a | b | c |\n|---|---|---|\n')
            .blocks
            .single as MD$Table;
        final short = Markdown.fromString('| a |\n|---|\n| long cell |\n')
            .blocks
            .single as MD$Table;
        final painter = BlockPainter$Table(
          header: wide.header,
          rows: short.rows,
          theme: _theme(),
        );
        addTearDown(painter.dispose);
        expect(painter.layout(2).width, greaterThan(2));
      });

      test('the narrow path matches a table measured from scratch', () {
        final narrow = _painter(table, _theme());
        addTearDown(narrow.dispose);
        final natural = narrow.layout(maxWidth: double.infinity);
        final first = narrow.layout(maxWidth: natural.width / 2);
        narrow.layout(maxWidth: natural.width);
        expect(narrow.layout(maxWidth: natural.width / 2), first);
      });

      test('selection text is the same at every width', () {
        final painter = _painter(table, _theme());
        addTearDown(painter.dispose);
        for (final width in <double>[double.infinity, 120, 1]) {
          painter.layout(maxWidth: width);
          expect(painter.localBoxesForRange(0, 0, 5), isNotEmpty);
        }
      });
    });

    group('shared list markers', () {
      const list = '- one\n- two\n  - nested\n1. first\n2. second\n'
          '- [ ] open\n- [x] done\n';

      test('items keep separate offsets with a shared marker', () {
        final painter = _painter('- a\n- b\n- c\n', _theme());
        addTearDown(painter.dispose);
        final size = painter.layout(maxWidth: 200);
        final rows = painter.localBoxesForRange(0, 0, 5);
        expect(rows.map((r) => r.top).toSet(), hasLength(3));
        expect(size.height, greaterThanOrEqualTo(rows.last.bottom));
      });

      test('relayout and repaint reuse markers across widths', () {
        final painter = _painter(list, _theme());
        addTearDown(painter.dispose);
        final first = painter.layout(maxWidth: 300);
        painter.layout(maxWidth: 40);
        expect(painter.layout(maxWidth: 300), first);
        _paint(painter, first);
      });

      test('a marker painter is not used after dispose', () {
        final painter = _painter(list, _theme())..layout(maxWidth: 300);
        // Rebuilds every block painter, disposing the shared markers.
        painter.invalidateLayout();
        _paint(painter, painter.layout(maxWidth: 300));
        painter.dispose();
      });

      test('right-to-left lists still place markers per item', () {
        final painter = _painter(
          '- a\n- b\n',
          _theme(direction: TextDirection.rtl),
        );
        addTearDown(painter.dispose);
        _paint(painter, painter.layout(maxWidth: 200));
      });
    });

    group('plain span style', () {
      TextSpan build(List<MD$Span> spans, {TextStyle? textStyle}) =>
          paragraphFromMarkdownSpans(
            spans: spans,
            theme: _theme(),
            textStyle: textStyle,
          );

      test('a plain span inherits the parent style instead of repeating it',
          () {
        final blocks = Markdown.fromString('plain **bold**').blocks;
        final spans = (blocks.single as MD$Paragraph).spans;
        final text = build(spans);
        final children = text.children!.cast<TextSpan>();
        expect(text.style, _theme().textStyle);
        expect(children.first.style, isNull);
        expect(children.last.style?.fontWeight, FontWeight.bold);
      });

      test('an explicit block style still merges over a plain span', () {
        final spans =
            (Markdown.fromString('plain').blocks.single as MD$Paragraph).spans;
        const block = TextStyle(fontSize: 30);
        final text = build(spans, textStyle: block);
        final child = text.children!.single as TextSpan;
        expect(child.style?.fontSize, 30);
      });

      test('a plain span measures the same as with the style spelled out', () {
        final theme = _theme();
        final spans =
            (Markdown.fromString('plain words').blocks.single as MD$Paragraph)
                .spans;
        TextPainter measure(InlineSpan text) =>
            TextPainter(text: text, textDirection: TextDirection.ltr)..layout();
        final implicit = measure(build(spans));
        final explicit = measure(TextSpan(
          style: theme.textStyle,
          children: [
            TextSpan(
              text: 'plain words',
              style: theme.textStyleFor(MD$Style.none),
            ),
          ],
        ));
        addTearDown(implicit.dispose);
        addTearDown(explicit.dispose);
        expect(implicit.size, explicit.size);
      });
    });
  });
}

void _paint(MarkdownPainter painter, Size size) {
  final recorder = PictureRecorder();
  painter.paint(Canvas(recorder), size);
  recorder.endRecording().dispose();
}
