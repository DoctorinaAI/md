// Corner-case regression tests targeting the parser paths that were rewritten
// for performance (hand-rolled list-line parsing, block-loop first-code-unit
// guards, manual link-target scanning, escape rebuilding, and the inline-math
// fast bail). These lock the behaviour of those paths independently of the
// golden snapshot, and document the exact edge semantics.
import 'package:flutter_md/flutter_md.dart';
import 'package:flutter_test/flutter_test.dart';

List<MD$Block> _blocks(String input) => markdownDecoder.convert(input).blocks;

MD$Paragraph _para(String input) => _blocks(input).single as MD$Paragraph;

List<MD$Span> _spans(String input) => _para(input).spans;

MD$List _list(String input) => _blocks(input).single as MD$List;

String _text(List<MD$Span> spans) => spans.map((s) => s.text).join();

void main() {
  group('List-line parsing (hand-rolled)', () {
    test('ordered marker with dot', () {
      final list = _list('1. one\n2. two');
      expect(list.items, hasLength(2));
      expect(list.items.first.marker, '1.');
      expect(list.items.first.text, 'one');
      expect(list.items[1].marker, '2.');
    });

    test('ordered marker with parenthesis', () {
      final list = _list('1) one\n2) two');
      expect(list.items.first.marker, '1)');
      expect(list.items[1].marker, '2)');
    });

    test('up to nine digits is a valid ordered marker', () {
      final list = _list('123456789. item');
      expect(list.items.single.marker, '123456789.');
      expect(list.items.single.text, 'item');
    });

    test('ten or more digits is not a list', () {
      expect(_blocks('1234567890. item').single, isA<MD$Paragraph>());
    });

    test('bullet markers *, +, - are recognised', () {
      for (final marker in const ['*', '+', '-']) {
        final list = _list('$marker item');
        expect(list.items.single.marker, marker);
        expect(list.items.single.text, 'item');
      }
    });

    test('marker not followed by whitespace is not a list', () {
      expect(_blocks('-x').single, isA<MD$Paragraph>());
      expect(_blocks('1.x').single, isA<MD$Paragraph>());
      expect(_blocks('+y').single, isA<MD$Paragraph>());
    });

    test('arrow "-> text" is a paragraph, not a list', () {
      expect(_blocks('-> arrow').single, isA<MD$Paragraph>());
    });

    test('emphasis at line start is a paragraph, not a list', () {
      final para = _para('*emphasis here*');
      expect(
        para.spans,
        contains(isA<MD$Span>()
            .having((s) => s.text, 'text', 'emphasis here')
            .having((s) => s.style, 'style', MD$Style.italic)),
      );
    });

    test('nested items track their indent width', () {
      final list = _list('- a\n  - b\n    - c');
      final a = list.items.single;
      expect(a.text, 'a');
      expect(a.children.single.text, 'b');
      expect(a.children.single.indent, 2);
      expect(a.children.single.children.single.text, 'c');
      expect(a.children.single.children.single.indent, 4);
    });

    test('indent beyond eight columns ends the list', () {
      // Nine leading spaces is past the {0,8} cap, so the line is not part of
      // the list and becomes a separate paragraph.
      final blocks = _blocks('- a\n         - too deep');
      expect(blocks.first, isA<MD$List>());
      expect(blocks.any((b) => b is MD$Paragraph), isTrue);
    });

    test('tab indentation is accepted', () {
      final list = _list('- a\n\t- b');
      expect(list.items.single.children.single.text, 'b');
    });

    test('task-list checkbox states', () {
      final list = _list('- [ ] todo\n- [x] done\n- [X] also');
      expect(list.items[0].checked, isFalse);
      expect(list.items[0].isTask, isTrue);
      expect(list.items[0].text, 'todo');
      expect(list.items[1].checked, isTrue);
      expect(list.items[2].checked, isTrue);
    });

    test('plain item has null checked (not a task)', () {
      final list = _list('- plain');
      expect(list.items.single.checked, isNull);
      expect(list.items.single.isTask, isFalse);
    });
  });

  group('Block-loop first-code-unit guards', () {
    test('underscore-led line is a paragraph with italic', () {
      final para = _para('_italic_ at the start');
      expect(_text(para.spans), '_italic_ at the start'.replaceAll('_', ''));
      expect(
        para.spans,
        contains(
            isA<MD$Span>().having((s) => s.style, 'style', MD$Style.italic)),
      );
    });

    test('thematic breaks: ---, ***, ___, spaced', () {
      for (final rule in const ['---', '***', '___', '- - -', '* * *']) {
        expect(_blocks(rule).single, isA<MD$Divider>(), reason: rule);
      }
    });

    test('two dashes is not a thematic break', () {
      expect(_blocks('--').single, isA<MD$Paragraph>());
    });

    test('single pipe line without delimiter row is a paragraph', () {
      expect(_blocks('| a | b |').single, isA<MD$Paragraph>());
    });

    test('headings still parse after the guard refactor', () {
      expect((_blocks('### Title').single as MD$Heading).level, 3);
    });

    test('quote still parses after the guard refactor', () {
      expect(_blocks('> quoted').single, isA<MD$Quote>());
    });

    test('digit-led prose is a paragraph', () {
      expect(_blocks('1st place and 2nd place').single, isA<MD$Paragraph>());
    });
  });

  group('Link-target parsing (manual scan)', () {
    Map<String, Object?>? extraOf(String input) =>
        _spans(input).firstWhere((s) => s.extra != null).extra;

    test('plain link exposes url', () {
      expect(extraOf('[t](https://x.io)')?['url'], 'https://x.io');
    });

    test('double-quoted title', () {
      expect(extraOf('[t](https://x.io "the title")')?['alt'], 'the title');
    });

    test('single-quoted title', () {
      expect(extraOf("[t](https://x.io 'the title')")?['alt'], 'the title');
    });

    test('parenthesised title', () {
      expect(extraOf('[t](https://x.io (the title))')?['alt'], 'the title');
    });

    test('angle-bracketed url with spaces', () {
      expect(extraOf('[t](<https://x.io/a b>)')?['url'], 'https://x.io/a b');
    });

    test('tab separates url and title', () {
      expect(extraOf('[t](https://x.io\ttitle)')?['alt'], 'title');
    });

    test('image carries the src key and image style', () {
      final span = _spans('![alt](https://x.io/i.png)')
          .firstWhere((s) => s.extra != null);
      expect(span.style.contains(MD$Style.image), isTrue);
      expect(span.extra?['src'], 'https://x.io/i.png');
    });
  });

  group('Escape rebuilding (range copy)', () {
    test('escaped emphasis markers stay literal', () {
      final spans = _spans(r'\*not italic\*');
      expect(_text(spans), '*not italic*');
      expect(spans.every((s) => s.style.isEmpty), isTrue);
    });

    test('double backslash yields a single backslash', () {
      expect(_text(_spans(r'a\\b')), r'a\b');
    });

    test('several escapes in one run', () {
      expect(_text(_spans(r'\# \! \[ \] \(')), '# ! [ ] (');
    });

    test('escape followed by real emphasis', () {
      final spans = _spans(r'\* *italic*');
      expect(_text(spans), '* italic');
      expect(
        spans,
        contains(isA<MD$Span>()
            .having((s) => s.text, 'text', 'italic')
            .having((s) => s.style, 'style', MD$Style.italic)),
      );
    });

    test('trailing backslash is literal', () {
      expect(_text(_spans('text\\')), 'text\\');
    });

    test('escape at the very start of a span', () {
      expect(_text(_spans(r'\*abc')), '*abc');
    });
  });

  group('Inline math fast bail', () {
    test('currency without a backslash is unchanged', () {
      expect(_text(_spans(r'It costs $5 and $10 today.')),
          r'It costs $5 and $10 today.');
    });

    test('a single greek command converts', () {
      expect(_text(_spans(r'angle $\alpha$ small')), contains('α'));
    });

    test('multiple commands in one expression', () {
      expect(_text(_spans(r'$\pi \approx 3.14$')), contains('π'));
      expect(_text(_spans(r'$\pi \approx 3.14$')), contains('≈'));
    });

    test('math inside a code span is left literal', () {
      final spans = _spans(r'`$\alpha$` stays');
      final code =
          spans.firstWhere((s) => s.style.contains(MD$Style.monospace));
      expect(code.text, r'$\alpha$');
    });

    test('unknown command is preserved verbatim', () {
      expect(_text(_spans(r'$\unknowncmd$ here')), r'$\unknowncmd$ here');
    });
  });

  group('Span offset invariants', () {
    // These guard the fast path and the selection-critical offset invariant:
    // spans must stay ordered, well-formed, and cover plain text exactly.
    const inputs = <String>[
      'just plain prose here',
      'a **b** c *d* e',
      'text with [link](https://x.io) and `code`',
      '**bold** _under_ ~~strike~~ ==mark== ||spoiler||',
      r'escapes \* and \_ here',
      'Привет **мир** 🌍',
      r'price $5 and math $\alpha$ mixed',
      '![img](https://x.io/i.png) then text',
    ];

    test('plain paragraph is a single unstyled span covering the text', () {
      const text = 'just plain prose here';
      final spans = _spans(text);
      expect(spans, hasLength(1));
      expect(spans.single.start, 0);
      expect(spans.single.end, text.length);
      expect(spans.single.style, MD$Style.none);
      expect(spans.single.text, text);
    });

    test('unicode-only plain paragraph is still a single span', () {
      expect(_spans('Привет мир 🌍 японский 日本語'), hasLength(1));
    });

    test('spans are ordered by ascending start offset', () {
      for (final input in inputs) {
        final spans = _spans(input);
        for (var i = 1; i < spans.length; i++) {
          expect(spans[i].start, greaterThanOrEqualTo(spans[i - 1].start),
              reason: input);
        }
      }
    });

    test('every span has start <= end', () {
      for (final input in inputs) {
        for (final span in _spans(input)) {
          expect(span.start, lessThanOrEqualTo(span.end), reason: input);
        }
      }
    });

    test('no span is empty (start strictly less than end)', () {
      for (final input in inputs) {
        for (final span in _spans(input)) {
          expect(span.start, lessThan(span.end), reason: '$input :: $span');
        }
      }
    });
  });
}
