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
          expect((_blocks('## Heading ##').single as MD$Heading).text, 'Heading');
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
            contains(isA<MD$Span>().having((s) => s.style, 'style', MD$Style.bold)),
          );
        });
      });

      group('Fenced code', () {
        test('backtick fence with language', () {
          final code = _blocks('```dart\nvoid main() {}\n```').single as MD$Code;
          expect(code.language, 'dart');
          expect(code.text, 'void main() {}');
        });

        test('tilde fence is supported', () {
          final code = _blocks('~~~python\nprint(1)\n~~~').single as MD$Code;
          expect(code.language, 'python');
          expect(code.text, 'print(1)');
        });

        test('code content is never interpreted as markdown', () {
          final code =
              _blocks('```\n# not a heading\n- not a list\n```').single as MD$Code;
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
            contains(isA<MD$Span>().having((s) => s.style, 'style', MD$Style.italic)),
          );
        });

        test('list items may contain links', () {
          final list = _blocks('- see [docs](https://x.com)').single as MD$List;
          expect(
            list.items.single.spans,
            contains(isA<MD$Span>().having((s) => s.style, 'style', MD$Style.link)),
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
            contains(isA<MD$Span>().having((s) => s.style, 'style', MD$Style.bold)),
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
