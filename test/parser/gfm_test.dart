import 'package:flutter_md/flutter_md.dart';
import 'package:flutter_test/flutter_test.dart';

/// Concatenates the text of every span in a block.
String _spanText(List<MD$Span> spans) => spans.map((s) => s.text).join();

void main() => group('GFM extensions', () {
      group('Alerts', () {
        test('parses every alert type', () {
          const cases = <String, MD$AlertType>{
            'NOTE': MD$AlertType.note,
            'TIP': MD$AlertType.tip,
            'IMPORTANT': MD$AlertType.important,
            'WARNING': MD$AlertType.warning,
            'CAUTION': MD$AlertType.caution,
          };
          for (final entry in cases.entries) {
            final md = markdownDecoder
                .convert('> [!${entry.key}]\n> Body of the alert.');
            expect(md.blocks, hasLength(1),
                reason: 'alert ${entry.key} is a single block');
            expect(
              md.blocks.single,
              isA<MD$Alert>()
                  .having((a) => a.alert, 'alert', entry.value)
                  .having(
                      (a) => _spanText(a.spans), 'body', 'Body of the alert.'),
            );
          }
        });

        test('alert markers are case-insensitive', () {
          for (final marker in ['note', 'Note', 'nOtE']) {
            final md = markdownDecoder.convert('> [!$marker]\n> Text');
            expect(md.blocks.single, isA<MD$Alert>());
            expect((md.blocks.single as MD$Alert).alert, MD$AlertType.note);
          }
        });

        test('marker-only alert has an empty body', () {
          final md = markdownDecoder.convert('> [!WARNING]');
          expect(
            md.blocks.single,
            isA<MD$Alert>()
                .having((a) => a.alert, 'alert', MD$AlertType.warning)
                .having((a) => a.spans, 'spans', isEmpty),
          );
        });

        test('multi-line alert body preserves inline styles and links', () {
          final md = markdownDecoder.convert(
            '> [!TIP]\n'
            '> First line with **bold**\n'
            '> and a [link](https://example.com).',
          );
          final alert = md.blocks.single as MD$Alert;
          expect(alert.alert, MD$AlertType.tip);
          expect(_spanText(alert.spans), contains('bold'));
          expect(
            alert.spans,
            contains(isA<MD$Span>()
                .having((s) => s.style.contains(MD$Style.bold), 'bold', true)),
          );
          expect(
            alert.spans,
            contains(isA<MD$Span>()
                .having((s) => s.style.contains(MD$Style.link), 'link', true)),
          );
        });

        test('unknown alert marker falls back to a plain quote', () {
          final md = markdownDecoder.convert('> [!FOOBAR]\n> body');
          expect(md.blocks.single, isA<MD$Quote>());
        });

        test('regular blockquote is not treated as an alert', () {
          final md = markdownDecoder.convert('> just a normal quote');
          expect(md.blocks.single, isA<MD$Quote>());
        });

        test('alert type exposes a human-readable title', () {
          expect(MD$AlertType.note.title, 'Note');
          expect(MD$AlertType.important.title, 'Important');
          expect(MD$AlertType.caution.title, 'Caution');
        });

        test('MD\$AlertType.tryParse is case-insensitive and safe', () {
          expect(MD$AlertType.tryParse('tip'), MD$AlertType.tip);
          expect(MD$AlertType.tryParse('WARNING'), MD$AlertType.warning);
          expect(MD$AlertType.tryParse('nope'), isNull);
        });
      });

      group('Task lists', () {
        test('unchecked task item', () {
          final md = markdownDecoder.convert('- [ ] todo');
          final list = md.blocks.single as MD$List;
          expect(list.items, hasLength(1));
          final item = list.items.single;
          expect(item.checked, isFalse);
          expect(item.isTask, isTrue);
          expect(item.text, 'todo');
        });

        test('checked task item (lowercase and uppercase x)', () {
          for (final input in ['- [x] done', '- [X] done']) {
            final list =
                markdownDecoder.convert(input).blocks.single as MD$List;
            expect(list.items.single.checked, isTrue);
            expect(list.items.single.text, 'done');
          }
        });

        test('empty brackets are not a task item', () {
          final list =
              markdownDecoder.convert('- [] literal').blocks.single as MD$List;
          expect(list.items.single.checked, isNull);
          expect(list.items.single.isTask, isFalse);
          expect(list.items.single.text, '[] literal');
        });

        test('checkbox with no label yields empty text', () {
          final list =
              markdownDecoder.convert('- [ ]').blocks.single as MD$List;
          expect(list.items.single.checked, isFalse);
          expect(list.items.single.text, isEmpty);
        });

        test('mixed task and non-task items in one list', () {
          final list = markdownDecoder
              .convert('- [ ] a\n- [x] b\n- normal')
              .blocks
              .single as MD$List;
          expect(list.items.map((i) => i.checked).toList(),
              <bool?>[false, true, null]);
        });

        test('nested task items keep their state', () {
          final list = markdownDecoder
              .convert('- [ ] parent\n  - [x] child')
              .blocks
              .single as MD$List;
          expect(list.items.single.checked, isFalse);
          expect(list.items.single.children, hasLength(1));
          expect(list.items.single.children.single.checked, isTrue);
        });

        test('ordered task items are supported', () {
          final list = markdownDecoder
              .convert('1. [x] first\n2. [ ] second')
              .blocks
              .single as MD$List;
          expect(
              list.items.map((i) => i.checked).toList(), <bool?>[true, false]);
        });
      });

      group('Thematic breaks', () {
        for (final input in ['---', '***', '___', '- - -', '* * *', '_ _ _']) {
          test('"$input" is a divider', () {
            expect(markdownDecoder.convert(input).blocks.single,
                isA<MD$Divider>());
          });
        }

        test('four or more markers still form a divider', () {
          expect(
              markdownDecoder.convert('----').blocks.single, isA<MD$Divider>());
          expect(markdownDecoder.convert('**********').blocks.single,
              isA<MD$Divider>());
        });

        test('marker followed by text is NOT a divider', () {
          expect(markdownDecoder.convert('----text').blocks.single,
              isA<MD$Paragraph>());
        });

        test('fewer than three markers is NOT a divider', () {
          expect(
              markdownDecoder.convert('--').blocks.single, isA<MD$Paragraph>());
          expect(
              markdownDecoder.convert('**').blocks.single, isA<MD$Paragraph>());
        });

        test('mixed markers are NOT a divider', () {
          expect(markdownDecoder.convert('-*-').blocks.single,
              isA<MD$Paragraph>());
        });

        test('up to three leading spaces are allowed', () {
          expect(markdownDecoder.convert('   ---').blocks.single,
              isA<MD$Divider>());
        });
      });

      group('Table alignment', () {
        test('captures left / center / right from the delimiter row', () {
          final table = markdownDecoder
              .convert('| a | b | c |\n|:--|:-:|--:|\n| 1 | 2 | 3 |')
              .blocks
              .single as MD$Table;
          expect(table.alignments, <MD$TableColumnAlign>[
            MD$TableColumnAlign.left,
            MD$TableColumnAlign.center,
            MD$TableColumnAlign.right,
          ]);
          expect(table.alignmentFor(0), MD$TableColumnAlign.left);
          expect(table.alignmentFor(2), MD$TableColumnAlign.right);
        });

        test('plain dashes yield no alignment', () {
          final table = markdownDecoder
              .convert('|a|b|\n|---|---|\n|1|2|')
              .blocks
              .single as MD$Table;
          expect(
              table.alignments, everyElement(equals(MD$TableColumnAlign.none)));
        });

        test('alignmentFor is safe for out-of-range indices', () {
          final table = markdownDecoder.convert('|a|\n|:-:|\n|1|').blocks.single
              as MD$Table;
          expect(table.alignmentFor(5), MD$TableColumnAlign.none);
          expect(table.alignmentFor(-1), MD$TableColumnAlign.none);
        });

        test('invalid delimiter row is not a table', () {
          final md = markdownDecoder.convert('|a|b|\n|xx|yy|\n|1|2|');
          expect(md.blocks.every((b) => b is! MD$Table), isTrue);
        });
      });

      group('Inline math (LaTeX)', () {
        test('single command is converted to Unicode', () {
          final md = markdownDecoder.convert(r'$\alpha$');
          expect(_spanText((md.blocks.single as MD$Paragraph).spans), 'α');
        });

        test('arrow within a sentence', () {
          final md = markdownDecoder.convert(r'A $\rightarrow$ B');
          expect(_spanText((md.blocks.single as MD$Paragraph).spans), 'A → B');
        });

        test('multiple commands in one expression', () {
          final md = markdownDecoder.convert(r'$\alpha + \beta \leq \gamma$');
          expect(
              _spanText((md.blocks.single as MD$Paragraph).spans), 'α + β ≤ γ');
        });

        test('inline code is never converted', () {
          final md = markdownDecoder.convert(r'`$\alpha$`');
          final span = (md.blocks.single as MD$Paragraph).spans.single;
          expect(span.text, r'$\alpha$');
          expect(span.style, MD$Style.monospace);
        });

        test('fenced code blocks are never converted', () {
          final md = markdownDecoder.convert('```\n\$\\alpha\$\n```');
          expect((md.blocks.single as MD$Code).text, r'$\alpha$');
        });

        test('currency is left untouched', () {
          final md = markdownDecoder.convert(r'I have $5 and $10 left');
          expect(_spanText((md.blocks.single as MD$Paragraph).spans),
              r'I have $5 and $10 left');
        });

        test('non-command dollar spans are left untouched', () {
          expect(
            _spanText(
                (markdownDecoder.convert(r'$x$').blocks.single as MD$Paragraph)
                    .spans),
            r'$x$',
          );
        });

        test('unknown commands leave the expression literal', () {
          expect(
            _spanText((markdownDecoder.convert(r'$\foobar$').blocks.single
                    as MD$Paragraph)
                .spans),
            r'$\foobar$',
          );
        });
      });
    });
