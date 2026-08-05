import 'dart:math';

import 'package:flutter_md/flutter_md.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests for [StreamingMarkdownParser].
///
/// The governing invariant is simple and strong: for *any* split of a document
/// into chunks, after feeding a prefix of those chunks the parser's [current]
/// must be identical — block for block, span for span, offsets and all — to
/// `Markdown.fromString(thatPrefix)`. The incremental path is only ever an
/// optimization, so it must never diverge from the batch decoder at any step.
///
/// Most cases therefore run a document through many chunkings (whole, per-line,
/// per-word, fixed sizes, char-by-char, and seeded-random) and assert the
/// invariant after *every* chunk. That turns a handful of documents into
/// thousands of prefix comparisons and exercises every mid-construct boundary
/// (a fence opened but not closed, a table header before its delimiter row, a
/// blank run split across chunks, a surrogate pair split down the middle, …).
void main() => group('StreamingMarkdownParser', () {
      // ---------------------------------------------------------------------
      // The corpus: each entry is a document that exercises a specific corner.
      // ---------------------------------------------------------------------
      const corpus = <String, String>{
        'empty': '',
        'blank-only': '\n\n\n',
        'spaces-only': '   \n  \t \n',
        'single-paragraph': 'Just a single line of prose.',
        'paragraph-no-newline': 'No trailing newline here',
        'two-paragraphs': 'First paragraph.\n\nSecond paragraph.',
        'paragraphs-trailing-blank': 'P1\n\nP2\n\nP3\n\n',
        'wide-blank-run': 'A\n\n\n\n\nB',
        'leading-blanks': '\n\n\nAfter some blanks.',
        'soft-wrapped-paragraph': 'Line one\nline two\nline three.',
        'headings': '# H1\n\n## H2\n\n### H3 ###\n\ntext after',
        'heading-then-para': '# Title\nA paragraph right after.',
        'not-a-heading': '#hashtag is not a heading\n\n####### seven hashes',
        'thematic-breaks': 'a\n\n---\n\nb\n\n***\n\nc\n\n___\n\nd',
        'divider-dashes': 'text\n---\nmore',
        'quote': '> quote line one\n> quote line two\n\nafter',
        'quote-multi': '> a\n> b\n> c',
        'alert-note': '> [!NOTE]\n> Body of the note.\n\nafter',
        'alert-warning': '> [!WARNING]\n> Careful now.\n> Second line.',
        'code-closed': '```dart\nvoid main() {}\n```\n\nafter code',
        'code-tilde': '~~~\nplain\n~~~\n\nafter',
        'code-unclosed': '```dart\nline 1\nline 2\nstill going',
        'code-blank-inside': '```\n\n\ncode after blanks\n\n```\n\nafter',
        'code-then-code': '```\na\n```\n\n```\nb\n```\n\ntail',
        'code-fence-lookalike': '```\nnot ``` a real close\n```\n\nx',
        'list-unordered': '- one\n- two\n- three\n\nafter',
        'list-ordered': '1. one\n2. two\n3. three',
        'list-nested': '- a\n    - a1\n    - a2\n- b\n\nafter',
        'list-tasks': '- [x] done\n- [ ] todo\n- [X] also done',
        'list-then-para': '- item\n\nnot a list anymore',
        'table-full': '| A | B |\n| - | - |\n| 1 | 2 |\n| 3 | 4 |\n\nafter',
        'table-aligned': '| L | C | R |\n| :- | :-: | -: |\n| a | b | c |',
        'table-header-first': '| Col1 | Col2 |\n| ---- | ---- |\n| v1 | v2 |',
        'table-malformed': '| looks | like |\nbut no delimiter row',
        'pipes-not-table': 'a | b | c is just prose with pipes',
        'inline-styles':
            'Some **bold**, _italic_, `code`, ~~strike~~ and ==mark==.',
        'emoji-and-unicode': '# Welcome 👋\n\nUnicode: café, naïve, 日本語, 🚀.',
        'crlf-doc': 'para one\r\n\r\n## Heading\r\n\r\npara two\r\n',
        'crlf-code': '```\r\ncode\r\n```\r\n\r\nafter\r\n',
        'mixed': _mixed,
      };

      // Chunkings that all reconstruct the original exactly.
      List<String> whole(String s) => <String>[if (s.isNotEmpty) s];

      List<String> chars(String s) =>
          <String>[for (var i = 0; i < s.length; i++) s[i]];

      List<String> byWord(String s) {
        final parts = s.split(' ');
        return <String>[
          for (var i = 0; i < parts.length; i++)
            i == 0 ? parts[i] : ' ${parts[i]}',
        ];
      }

      List<String> byLine(String s) {
        final parts = s.split('\n');
        return <String>[
          for (var i = 0; i < parts.length; i++)
            i < parts.length - 1 ? '${parts[i]}\n' : parts[i],
        ];
      }

      List<String> bySize(String s, int n) => <String>[
            for (var i = 0; i < s.length; i += n)
              s.substring(i, min(i + n, s.length)),
          ];

      List<String> byRandom(String s, int seed) {
        final rng = Random(seed);
        final out = <String>[];
        var i = 0;
        while (i < s.length) {
          final take = 1 + rng.nextInt(7);
          out.add(s.substring(i, min(i + take, s.length)));
          i += take;
        }
        return out;
      }

      /// Feeds [chunks] into a fresh parser and asserts the invariant after
      /// every chunk against the batch decoder. Returns the final parser so
      /// callers can make extra assertions (e.g. on [stableBlockCount]).
      StreamingMarkdownParser feed(
        List<String> chunks, {
        bool inlineMath = false,
        String reason = '',
      }) {
        // The chunking must reconstruct the source, or the test is meaningless.
        final doc = chunks.join();
        final decoder = MarkdownDecoder(inlineMath: inlineMath);
        final parser = StreamingMarkdownParser(decoder: decoder);
        final acc = StringBuffer();
        for (var i = 0; i < chunks.length; i++) {
          parser.add(chunks[i]);
          acc.write(chunks[i]);
          final expected = decoder.convert(acc.toString());
          expect(
            _sig(parser.current),
            _sig(expected),
            reason: '$reason after chunk ${i + 1}/${chunks.length}',
          );
          expect(parser.source, acc.toString(), reason: '$reason source');
        }
        // Final result matches a single-shot parse of the whole document.
        expect(_sig(parser.current), _sig(decoder.convert(doc)),
            reason: '$reason final');
        return parser;
      }

      // ---------------------------------------------------------------------
      // Equivalence across the whole corpus and every chunking.
      // ---------------------------------------------------------------------
      corpus.forEach((name, doc) {
        group(name, () {
          test('whole', () => feed(whole(doc), reason: name));
          test('by-line', () => feed(byLine(doc), reason: name));
          test('by-word', () => feed(byWord(doc), reason: name));
          test('char-by-char', () => feed(chars(doc), reason: name));
          for (final n in const <int>[2, 3, 5, 7, 13]) {
            test('by-size-$n', () => feed(bySize(doc, n), reason: name));
          }
          for (final seed in const <int>[1, 42, 1337]) {
            test('random-$seed', () => feed(byRandom(doc, seed), reason: name));
          }
        });
      });

      // ---------------------------------------------------------------------
      // Inline math must flow through the injected decoder.
      // ---------------------------------------------------------------------
      group('inlineMath decoder', () {
        const doc = r'Euler: $e^{i\pi} + 1 = 0$.'
            '\n\n'
            r'Roots: $x = \frac{-b \pm \sqrt{b^2-4ac}}{2a}$ and $H_2O$.';
        test('char-by-char matches batch(inlineMath)', () {
          feed(chars(doc), inlineMath: true, reason: 'math');
        });
        test(r'literal $ preserved without inlineMath', () {
          feed(chars(r'Price is $5 and $HOME is a var.'), reason: 'no-math');
        });
      });

      // ---------------------------------------------------------------------
      // Targeted: freezing behaviour (the whole point of the optimization).
      // ---------------------------------------------------------------------
      group('freezing', () {
        test('completed blank-separated blocks are frozen', () {
          final p = StreamingMarkdownParser();
          for (final t in const <String>['P1\n\n', 'P2\n\n', 'P3\n\n']) {
            p.add(t);
          }
          // Nothing after the last blank run yet — the trailing spacer stays
          // live because more blanks could still arrive.
          final beforeTail = p.stableBlockCount;
          p.add('P4'); // real content proves the previous run is complete
          expect(p.stableBlockCount, greaterThan(beforeTail));
          expect(p.stableBlockCount, greaterThanOrEqualTo(6),
              reason: 'P1,Spacer,P2,Spacer,P3,Spacer should be frozen');
          expect(_sig(p.current),
              _sig(Markdown.fromString('P1\n\nP2\n\nP3\n\nP4')));
        });

        test('an open code fence never freezes', () {
          final p = StreamingMarkdownParser();
          p.add('```dart\n');
          p.add('line 1\n');
          p.add('line 2\n');
          p.add('\n'); // a blank line *inside* the fence must not freeze
          p.add('line 3\n');
          expect(p.stableBlockCount, 0,
              reason: 'blocks are unstable while the fence is open');
          // Closing the fence and starting a new block freezes the code.
          p.add('```\n\nAfter.');
          expect(p.stableBlockCount, greaterThan(0));
          expect(
            _sig(p.current),
            _sig(Markdown.fromString(
                '```dart\nline 1\nline 2\n\nline 3\n```\n\nAfter.')),
          );
        });

        test('a table header does not freeze before its delimiter row', () {
          // The PR-breaking case: the header line looks like a malformed table
          // (→ paragraph) until the delimiter row arrives. It must never freeze
          // as a paragraph, or the table could never form.
          final p = StreamingMarkdownParser();
          p.add('| A | B |\n');
          expect(p.stableBlockCount, 0);
          p.add('| - | - |\n');
          expect(p.stableBlockCount, 0);
          p.add('| 1 | 2 |\n');
          expect(p.stableBlockCount, 0);
          expect(_sig(p.current),
              _sig(Markdown.fromString('| A | B |\n| - | - |\n| 1 | 2 |\n')));
          final blocks = p.current.blocks;
          expect(blocks.length, 1);
          expect(blocks.single.type, 'table');
        });
      });

      // ---------------------------------------------------------------------
      // API surface: reset, empty adds, current/source, stream extension.
      // ---------------------------------------------------------------------
      group('api', () {
        test('starts empty', () {
          final p = StreamingMarkdownParser();
          expect(p.current.isEmpty, isTrue);
          expect(p.source, isEmpty);
          expect(p.stableBlockCount, 0);
        });

        test('empty chunks are no-ops', () {
          final p = StreamingMarkdownParser();
          expect(p.add('').isEmpty, isTrue);
          p.add('# Hi');
          final before = _sig(p.current);
          expect(_sig(p.add('')), before);
          expect(p.source, '# Hi');
        });

        test('reset reuses the instance', () {
          final p = StreamingMarkdownParser();
          p.add('# First doc\n\nbody\n\nmore');
          p.reset();
          expect(p.current.isEmpty, isTrue);
          expect(p.source, isEmpty);
          expect(p.stableBlockCount, 0);
          p.add('# Second doc');
          expect(_sig(p.current), _sig(Markdown.fromString('# Second doc')));
        });

        test('add returns the same as current', () {
          final p = StreamingMarkdownParser();
          final returned = p.add('# Hello\n\nworld');
          expect(_sig(returned), _sig(p.current));
        });

        test('Stream.toMarkdown emits growing, batch-equivalent results',
            () async {
          const doc = 'para one\n\n## Heading\n\n- a\n- b\n\ndone';
          final chunks = <String>[
            for (var i = 0; i < doc.length; i += 4)
              doc.substring(i, min(i + 4, doc.length)),
          ];
          final results =
              await Stream<String>.fromIterable(chunks).toMarkdown().toList();
          expect(results, isNotEmpty);
          expect(_sig(results.last), _sig(Markdown.fromString(doc)));
          // Every intermediate emission matches the batch parse of its prefix.
          final acc = StringBuffer();
          for (var i = 0; i < chunks.length; i++) {
            acc.write(chunks[i]);
            expect(_sig(results[i]), _sig(Markdown.fromString(acc.toString())));
          }
        });

        test('Stream.toMarkdown threads inlineMath through', () async {
          const doc = r'$\alpha$ and $x^2$';
          final results = await Stream<String>.value(doc)
              .toMarkdown(decoder: const MarkdownDecoder(inlineMath: true))
              .toList();
          expect(_sig(results.last),
              _sig(Markdown.fromString(doc, inlineMath: true)));
        });
      });
    });

/// A structural signature of a [Markdown] value: source + a deep dump of every
/// block (type, level/marker/checked/alignment, inline spans with their exact
/// offsets and styles). Two [Markdown]s with equal signatures are equivalent
/// for every observable purpose, which node identity equality cannot express.
String _sig(Markdown md) {
  final b = StringBuffer()..writeln('SRC<<${md.markdown}>>');
  for (final block in md.blocks) {
    b.writeln(_blockSig(block));
  }
  return b.toString();
}

String _blockSig(MD$Block block) => block.map(
      paragraph: (p) => 'P|${_spans(p.spans)}',
      heading: (h) => 'H${h.level}|${_spans(h.spans)}',
      quote: (q) => 'Q${q.indent}|${_spans(q.spans)}',
      alert: (a) => 'A[${a.alert.marker}]|${_spans(a.spans)}',
      code: (c) => 'C[${c.language}]<<${c.text}>>',
      list: (l) => 'L|${l.items.map(_itemSig).join(';')}',
      divider: (_) => 'DIV',
      table: (t) => 'T|${_rowSig(t.header)}|'
          '${t.alignments.join(',')}|'
          '${t.rows.map(_rowSig).join(';')}',
      spacer: (s) => 'S${s.count}',
    );

String _itemSig(MD$ListItem it) =>
    '{${it.indent}/${it.marker}/${it.checked}/${_spans(it.spans)}'
    '[${it.children.map(_itemSig).join(',')}]}';

String _rowSig(MD$TableRow row) => row.cells.map(_spans).join('¦');

String _spans(List<MD$Span> spans) => spans
    .map((s) => '${s.start}:${s.end}:${s.style.value}:${s.text}')
    .join('§');

/// A varied document that hits most block types in one parse.
const String _mixed = '''
# Streaming demo

A short intro paragraph with **bold**, _italic_ and `code`.

> [!TIP]
> Blocks freeze once a blank line proves they are complete.

- one
- two
    - nested
- [x] a task

| Feature | Incremental |
| ------- | :---------: |
| Parse   |     yes     |
| Paint   |     n/a     |

```dart
final md = StreamingMarkdownParser();
md.add('# Hello');
```

---

The end.
''';
