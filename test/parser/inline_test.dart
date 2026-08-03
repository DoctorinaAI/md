import 'package:flutter_md/flutter_md.dart';
import 'package:flutter_test/flutter_test.dart';

/// Parses [input] and returns the spans of its single paragraph block.
List<MD$Span> _spans(String input) {
  final md = markdownDecoder.convert(input);
  return (md.blocks.single as MD$Paragraph).spans;
}

/// The concatenated visible text of a single-paragraph [input].
String _visible(String input) => _spans(input).map((s) => s.text).join();

/// The style of the (single) span whose text equals [text].
MD$Style _styleOf(List<MD$Span> spans, String text) =>
    spans.firstWhere((s) => s.text == text).style;

void main() => group('Inline parsing', () {
      group('Basic emphasis', () {
        test('italic with *', () {
          final spans = _spans('*italic*');
          expect(spans.single.text, 'italic');
          expect(spans.single.style, MD$Style.italic);
        });

        test('italic with _', () {
          expect(_spans('_italic_').single.style, MD$Style.italic);
        });

        test('bold with **', () {
          final spans = _spans('**bold**');
          expect(spans.single.text, 'bold');
          expect(spans.single.style, MD$Style.bold);
        });

        test('underline with __', () {
          expect(_spans('__under__').single.style, MD$Style.underline);
        });

        test('strikethrough with ~~', () {
          expect(_spans('~~strike~~').single.style, MD$Style.strikethrough);
        });

        test('highlight with ==', () {
          expect(_spans('==mark==').single.style, MD$Style.highlight);
        });

        test('spoiler with ||', () {
          expect(_spans('||hidden||').single.style, MD$Style.spoiler);
        });

        test('monospace with backticks', () {
          expect(_spans('`code`').single.style, MD$Style.monospace);
        });

        test('all inline styles in one line', () {
          final spans = _spans('*i* **b** _u_ __U__ ~~s~~ ==h== ||sp|| `c`');
          expect(_styleOf(spans, 'i'), MD$Style.italic);
          expect(_styleOf(spans, 'b'), MD$Style.bold);
          expect(_styleOf(spans, 'u'), MD$Style.italic);
          expect(_styleOf(spans, 'U'), MD$Style.underline);
          expect(_styleOf(spans, 's'), MD$Style.strikethrough);
          expect(_styleOf(spans, 'h'), MD$Style.highlight);
          expect(_styleOf(spans, 'sp'), MD$Style.spoiler);
          expect(_styleOf(spans, 'c'), MD$Style.monospace);
        });
      });

      group('Combined & nested styles', () {
        test('bold inside italic', () {
          final spans = _spans('_a **b** c_');
          expect(_styleOf(spans, 'b').contains(MD$Style.italic), isTrue);
          expect(_styleOf(spans, 'b').contains(MD$Style.bold), isTrue);
        });

        test('rich combination keeps every style', () {
          final spans = _spans('_`You` **can** __combine__ ~~them~~_');
          expect(_styleOf(spans, 'You').contains(MD$Style.monospace), isTrue);
          expect(_styleOf(spans, 'You').contains(MD$Style.italic), isTrue);
          expect(_styleOf(spans, 'can').contains(MD$Style.bold), isTrue);
          expect(
              _styleOf(spans, 'combine').contains(MD$Style.underline), isTrue);
          expect(
              _styleOf(spans, 'them').contains(MD$Style.strikethrough), isTrue);
        });
      });

      group('Stray & unterminated markers stay literal', () {
        test('lone asterisk (multiplication) is not emphasis', () {
          expect(_visible('5 * 6 = 30'), '5 * 6 = 30');
          expect(_spans('5 * 6 = 30').every((s) => s.style.isEmpty), isTrue);
        });

        test('unterminated bold does not leak', () {
          final spans = _spans('**bold never closed');
          expect(_visible('**bold never closed'), '**bold never closed');
          expect(spans.every((s) => s.style.isEmpty), isTrue);
        });

        test('unterminated strikethrough does not leak', () {
          expect(_spans('~~strike me').every((s) => s.style.isEmpty), isTrue);
        });

        test('unterminated backtick does not leak monospace', () {
          expect(
            _spans('Use the `find command').every((s) => s.style.isEmpty),
            isTrue,
          );
        });

        test('lone double markers surrounded by spaces are literal', () {
          expect(_spans('a ~~ b').every((s) => s.style.isEmpty), isTrue);
          expect(_spans('a == b').every((s) => s.style.isEmpty), isTrue);
        });

        test('double marker with a space-flanked closer stays literal', () {
          // The closing `**` is preceded by a space, so it is not
          // right-flanking and cannot close: the whole run is literal. The
          // inner `*` of the run must not degrade into a stray italic.
          expect(_visible('a **bold ** x'), 'a **bold ** x');
          expect(_spans('a **bold ** x').every((s) => s.style.isEmpty), isTrue);
        });

        test('double marker with a closer after a soft break stays literal',
            () {
          // Same rule across a soft line break: the closing `**` follows a
          // newline (whitespace), so it cannot close and stays literal.
          expect(_visible('a **bold\n** x'), 'a **bold\n** x');
          expect(
              _spans('a **bold\n** x').every((s) => s.style.isEmpty), isTrue);
        });

        test('double underline with a space-flanked closer stays literal', () {
          expect(_visible('a __bold __ x'), 'a __bold __ x');
          expect(_spans('a __bold __ x').every((s) => s.style.isEmpty), isTrue);
        });
      });

      group('Double markers still emphasize when properly flanked', () {
        // Regression guards: the fix for space-flanked closers must not break
        // legitimate double/triple/nested emphasis.
        test('triple *** is bold + italic', () {
          final spans = _spans('***both***');
          expect(spans.single.text, 'both');
          expect(spans.single.style.contains(MD$Style.bold), isTrue);
          expect(spans.single.style.contains(MD$Style.italic), isTrue);
        });

        test('italic nested inside bold', () {
          final spans = _spans('**b *bi* b**');
          expect(_styleOf(spans, 'bi').contains(MD$Style.bold), isTrue);
          expect(_styleOf(spans, 'bi').contains(MD$Style.italic), isTrue);
          expect(_styleOf(spans, 'b '), MD$Style.bold);
        });

        test('bold spanning a soft line break is closed', () {
          final spans = _spans('x **a\nb** y');
          expect(_styleOf(spans, 'a\nb'), MD$Style.bold);
          expect(_visible('x **a\nb** y'), 'x a\nb y');
        });
      });

      group('Intraword underscores (snake_case)', () {
        test('single identifier is preserved', () {
          expect(_visible('flutter_test_package'), 'flutter_test_package');
          expect(
            _spans('flutter_test_package').every((s) => s.style.isEmpty),
            isTrue,
          );
        });

        test('stray underscore mid-sentence does not italicize', () {
          expect(_visible('the object_id value'), 'the object_id value');
          expect(
            _spans('the object_id value').every((s) => s.style.isEmpty),
            isTrue,
          );
        });

        test('asterisks still emphasize intraword', () {
          // `*` (unlike `_`) may emphasize within a word.
          final spans = _spans('a*b*c');
          expect(_styleOf(spans, 'b'), MD$Style.italic);
        });
      });

      group('Links & images', () {
        test('basic link exposes url in extra', () {
          final spans = _spans('[text](https://example.com)');
          expect(spans.single.style, MD$Style.link);
          expect(spans.single.text, 'text');
          expect(
              spans.single.extra, containsPair('url', 'https://example.com'));
        });

        test('link with double-quoted title', () {
          final spans = _spans('[a](https://x.com "Title")');
          expect(spans.single.extra, containsPair('url', 'https://x.com'));
          expect(spans.single.extra, containsPair('alt', 'Title'));
        });

        test('link with single-quoted title', () {
          final spans = _spans("[a](https://x.com 'My Title')");
          expect(spans.single.extra, containsPair('alt', 'My Title'));
        });

        test('angle-bracketed url preserves spaces', () {
          final spans = _spans('[a](<my file.pdf>)');
          expect(spans.single.extra, containsPair('url', 'my file.pdf'));
        });

        test('url containing balanced parentheses', () {
          final spans = _spans('[a](https://x.com/a_(b)_c)');
          expect(
              spans.single.extra, containsPair('url', 'https://x.com/a_(b)_c'));
        });

        test('image exposes src and image style', () {
          final spans = _spans('![alt](https://x.com/i.png)');
          expect(spans.single.style, MD$Style.image);
          expect(
              spans.single.extra, containsPair('src', 'https://x.com/i.png'));
        });

        test('emphasis wrapping a link merges styles', () {
          final spans = _spans('**[bold link](https://x.com)**');
          expect(spans.single.style.contains(MD$Style.link), isTrue);
          expect(spans.single.style.contains(MD$Style.bold), isTrue);
        });

        test('link inside a longer sentence', () {
          final spans = _spans('see [docs](https://x.com) now');
          expect(spans.map((s) => s.text).join(), 'see docs now');
          expect(
            spans.firstWhere((s) => s.text == 'docs').style,
            MD$Style.link,
          );
        });
      });

      group('Inline code is literal', () {
        test('markdown inside code is not parsed', () {
          final spans = _spans('`**not bold** _nor italic_`');
          expect(spans.single.style, MD$Style.monospace);
          expect(spans.single.text, '**not bold** _nor italic_');
        });

        test('code span among styled text', () {
          final spans = _spans('run `dart test` please');
          expect(
            spans.firstWhere((s) => s.text == 'dart test').style,
            MD$Style.monospace,
          );
        });
      });

      group('Escaping', () {
        test('escaped asterisks are literal', () {
          expect(_visible(r'\*not italic\*'), '*not italic*');
        });

        test('escaped backtick is literal', () {
          expect(_visible(r'\`not code\`'), '`not code`');
        });

        test('escaped underscore is literal', () {
          expect(_visible(r'a\_b\_c'), 'a_b_c');
        });
      });
    });
