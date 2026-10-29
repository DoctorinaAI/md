import 'package:flutter_md/flutter_md.dart';
import 'package:flutter_test/flutter_test.dart';

List<MD$Block> _blocks(String input) => markdownDecoder.convert(input).blocks;

void main() => group('Block parsing', () {
      group('Headings', () {
        test('levels 1 through 6', () {
          for (var level = 1; level <= 6; level++) {
            final block = _blocks('${'#' * level} Title').single as MD$Heading;
            expect(block.level, level);
            expect(block.text, 'Title');
          }
        });

        test('heading without a space is a paragraph', () {
          expect(_blocks('#hashtag').single, isA<MD$Paragraph>());
        });

        test('seven or more hashes is a paragraph', () {
          expect(_blocks('####### seven').single, isA<MD$Paragraph>());
        });

        test('bare hash is an empty heading', () {
          final h = _blocks('#').single as MD$Heading;
          expect(h.level, 1);
          expect(h.text, isEmpty);
        });

        test('trailing hashes are stripped', () {
          expect(
              (_blocks('## Heading ##').single as MD$Heading).text, 'Heading');
          expect((_blocks('### Title ###').single as MD$Heading).text, 'Title');
        });

        test('inline styles inside a heading are parsed', () {
          final h = _blocks('# Title with **bold**').single as MD$Heading;
          expect(
            h.spans,
            contains(isA<MD$Span>()
                .having((s) => s.text, 'text', 'bold')
                .having((s) => s.style, 'style', MD$Style.bold)),
          );
        });
      });

      group('Blockquotes', () {
        test('single line quote', () {
          expect(_blocks('> quoted').single, isA<MD$Quote>());
        });

        test('multi-line quote is merged', () {
          final q = _blocks('> A\n> B\n> C').single as MD$Quote;
          expect(q.text, 'A\nB\nC');
        });

        test('quote with inline styles', () {
          final q = _blocks('> quote with **bold**').single as MD$Quote;
          expect(
            q.spans,
            contains(
                isA<MD$Span>().having((s) => s.style, 'style', MD$Style.bold)),
          );
        });

        test('fenced code inside a quote is a nested MD\$Code', () {
          final q = _blocks(
            '> ```yaml\n'
            '> webview_flutter: ^4.0.7\n'
            '> ```',
          ).single as MD$Quote;
          expect(q.spans, isEmpty);
          expect(q.blocks, hasLength(1));
          final code = q.blocks.single as MD$Code;
          expect(code.language, 'yaml');
          expect(code.text, 'webview_flutter: ^4.0.7');
          expect(
            q.spans.where((s) => s.style.contains(MD$Style.monospace)),
            isEmpty,
          );
        });

        test('tilde fence inside a quote is nested code', () {
          final q = _blocks('> ~~~\n> hi\n> ~~~').single as MD$Quote;
          expect(q.blocks.single, isA<MD$Code>());
          expect((q.blocks.single as MD$Code).text, 'hi');
        });

        test('prose plus fenced code inside a quote', () {
          final q = _blocks(
            '> before\n'
            '> ```\n'
            '> code\n'
            '> ```\n'
            '> after',
          ).single as MD$Quote;
          expect(q.blocks.whereType<MD$Paragraph>(), hasLength(2));
          expect(q.blocks.whereType<MD$Code>(), hasLength(1));
          expect(
            (q.blocks.whereType<MD$Code>().single).text,
            'code',
          );
        });

        test('quoted fence preserves code indentation', () {
          final q = _blocks(
            '> ```py\n'
            '> def f():\n'
            '>     return 1\n'
            '> ```',
          ).single as MD$Quote;
          expect((q.blocks.single as MD$Code).text, 'def f():\n    return 1');
        });

        test('alert fence preserves code indentation', () {
          final a = _blocks(
            '> [!NOTE]\n'
            '> ```py\n'
            '> if x:\n'
            '>     y()\n'
            '> ```',
          ).single as MD$Alert;
          expect((a.blocks.single as MD$Code).text, 'if x:\n    y()');
        });

        test('quote marker without a space still nests a fence', () {
          final q = _blocks('>```\n>  x\n>```').single as MD$Quote;
          expect((q.blocks.single as MD$Code).text, ' x');
        });

        test('fence inside a nested quote is nested code', () {
          final q = _blocks('> > ```\n> > a `b` c\n> > ```').single as MD$Quote;
          final inner = q.blocks.single as MD$Quote;
          expect((inner.blocks.single as MD$Code).text, 'a `b` c');
          expect(markdownBlockRenderedText(q), 'a `b` c');
        });

        test('rendered text of a nested quote skips spacers', () {
          final md = Markdown.fromString(
            '> *a*\n>\n> ```\n> x\n> ```\n> b',
          );
          expect(markdownBlockRenderedText(md.blocks.single), 'a\nx\nb');
        });

        test('Markdown.text renders nested prose spans', () {
          expect(
            Markdown.fromString('> **bold** text\n> ```\n> x\n> ```').text,
            'bold text\nx',
          );
          expect(
            Markdown.fromString('> [!TIP]\n> _a_\n> ```\n> x\n> ```').text,
            'a\nx',
          );
        });

        test('CRLF quoted fence', () {
          final q = _blocks('> ```\r\n> x\r\n> ```\r\n').first as MD$Quote;
          expect((q.blocks.single as MD$Code).text, 'x');
        });

        test('an indented or tab-separated quoted fence still nests', () {
          final spaced =
              _blocks('> intro\n>  ```\n>  code\n>  ```').single as MD$Quote;
          expect(spaced.blocks.last, isA<MD$Code>());
          final tab = _blocks('>\t```\n>\tcode\n>\t```').single as MD$Quote;
          // Code content keeps its tab verbatim.
          expect((tab.blocks.single as MD$Code).text, '\tcode');
          // An indented closing fence closes the block.
          final close = _blocks('> ```\n> a\n>  ```\n> b').single as MD$Quote;
          expect((close.blocks.first as MD$Code).text, 'a');
          expect(close.blocks.last, isA<MD$Paragraph>());
          // Four spaces is not a fence.
          final code = _blocks('> a\n>     ```\n>     b').single as MD$Quote;
          expect(code.blocks, isEmpty);
        });

        test('fence-like lines inside quoted code stay verbatim', () {
          final tilde =
              _blocks('> ```\n>   ~~~\n>   x\n> ```').single as MD$Quote;
          expect((tilde.blocks.single as MD$Code).text, '  ~~~\n  x');
          final ticks = _blocks('> ~~~\n>   ```js\n> ~~~').single as MD$Quote;
          expect((ticks.blocks.single as MD$Code).text, '  ```js');
          final tabs = _blocks('> ```\n>\t\tx\n> ```').single as MD$Quote;
          expect((tabs.blocks.single as MD$Code).text, '\t\tx');
        });

        test('indented inline code in a quote is not a fence', () {
          final q = _blocks('> say\n>  ```a``` b\n> more').single as MD$Quote;
          expect(q.blocks, isEmpty);
          expect(q.spans.map((s) => s.text).join(), contains('a'));
          expect(q.spans.map((s) => s.text).join(), contains('more'));
        });

        test('uneven list indents keep every item', () {
          final list = _blocks('- a\n    - b\n  - c\n- d').single as MD$List;
          expect(list.items.map((i) => i.text), <String>['a', 'd']);
          expect(
            list.items.first.children.map((i) => i.text),
            <String>['b', 'c'],
          );
          expect(markdownBlockRenderedText(list), 'a\nb\nc\nd');
        });

        test('blank lines around an alert body add no gaps', () {
          final a =
              _blocks('> [!TIP]\n>\n> ```\n> b\n> ```\n>').single as MD$Alert;
          expect(a.blocks.single, isA<MD$Code>());
        });
      });

      group('Fenced code', () {
        test('backtick fence with language', () {
          final code =
              _blocks('```dart\nvoid main() {}\n```').single as MD$Code;
          expect(code.language, 'dart');
          expect(code.text, 'void main() {}');
        });

        test('tilde fence is supported', () {
          final code = _blocks('~~~python\nprint(1)\n~~~').single as MD$Code;
          expect(code.language, 'python');
          expect(code.text, 'print(1)');
        });

        test('code content is never interpreted as markdown', () {
          final code = _blocks('```\n# not a heading\n- not a list\n```').single
              as MD$Code;
          expect(code.text, '# not a heading\n- not a list');
        });

        test('multi-line code preserves line breaks', () {
          final code = _blocks('```\na\nb\nc\n```').single as MD$Code;
          expect(code.text, 'a\nb\nc');
        });

        test('empty language for a bare fence', () {
          final code = _blocks('```\nx\n```').single as MD$Code;
          expect(code.language, isEmpty);
        });
      });

      group('Lists', () {
        test('unordered markers -, *, + all parse', () {
          for (final marker in ['-', '*', '+']) {
            final list = _blocks('$marker item').single as MD$List;
            expect(list.items, hasLength(1));
            expect(list.items.single.text, 'item');
          }
        });

        test('ordered list preserves its markers', () {
          final list = _blocks('1. one\n2. two\n3. three').single as MD$List;
          expect(list.items, hasLength(3));
          expect(list.items.map((i) => i.marker).toList(), ['1.', '2.', '3.']);
        });

        test('nested unordered list', () {
          final list = _blocks(
            '- a\n'
            '- b\n'
            '  - b1\n'
            '  - b2\n'
            '- c',
          ).single as MD$List;
          expect(list.items, hasLength(3));
          expect(list.items[1].children, hasLength(2));
        });

        test('inline styles inside list items', () {
          final list = _blocks('- item with *italic*').single as MD$List;
          expect(
            list.items.single.spans,
            contains(isA<MD$Span>()
                .having((s) => s.style, 'style', MD$Style.italic)),
          );
        });

        test('list items may contain links', () {
          final list = _blocks('- see [docs](https://x.com)').single as MD$List;
          expect(
            list.items.single.spans,
            contains(
                isA<MD$Span>().having((s) => s.style, 'style', MD$Style.link)),
          );
        });
      });

      group('Tables', () {
        test('basic table with header and rows', () {
          final table = _blocks(
            '| Name | Age |\n'
            '| ---- | --- |\n'
            '| Bob  | 30  |\n'
            '| Ann  | 25  |',
          ).single as MD$Table;
          expect(table.header.cells, hasLength(2));
          expect(table.rows, hasLength(2));
        });

        test('table cells parse inline styles', () {
          final table = _blocks(
            '| A | B |\n'
            '| - | - |\n'
            '| **x** | _y_ |',
          ).single as MD$Table;
          final firstCell = table.rows.single.cells.first;
          expect(
            firstCell,
            contains(
                isA<MD$Span>().having((s) => s.style, 'style', MD$Style.bold)),
          );
        });

        test('a table without a delimiter row is not a table', () {
          expect(
            _blocks('| a | b |\n| c | d |').every((b) => b is! MD$Table),
            isTrue,
          );
        });
      });

      group('Spacers & paragraphs', () {
        test('consecutive blank lines collapse into one spacer', () {
          final blocks = _blocks('a\n\n\n\nb');
          expect(blocks.whereType<MD$Spacer>(), hasLength(1));
          expect(blocks.whereType<MD$Spacer>().single.count, 3);
        });

        test('soft line breaks are preserved within a paragraph', () {
          final p = _blocks('line one\nline two').single as MD$Paragraph;
          expect(p.text, 'line one\nline two');
        });

        test('a blank line separates two paragraphs', () {
          final blocks = _blocks('first\n\nsecond');
          expect(blocks.whereType<MD$Paragraph>(), hasLength(2));
        });
      });
    });
