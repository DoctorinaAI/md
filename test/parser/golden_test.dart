// Golden characterization test for the Markdown parser.
//
// This test freezes the *exact* structural output of the parser for a diverse
// corpus of inputs. Its purpose is to guard performance refactors: any change
// that alters the produced AST (blocks, spans, styles, offsets, extras) will
// fail here immediately, even if the higher-level behavioural tests miss it.
//
// The expected snapshot lives in `parser_golden.txt` next to this file. When a
// change to parser output is *intentional*, regenerate it with:
//
// ```shell
// REGEN_GOLDEN=1 flutter test test/parser/golden_test.dart
// ```
//
// Then review the diff carefully before committing.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_md/flutter_md.dart';
import 'package:flutter_test/flutter_test.dart';

/// Path to the frozen snapshot, relative to the package root (the working
/// directory used by `flutter test`).
const String _goldenPath = 'test/parser/parser_golden.txt';

/// Section delimiter prefix inside the golden file.
const String _sectionPrefix = '@@@ ';

void main() {
  final actual = _buildSections();

  // Bootstrap or regenerate the golden file on request (or first run).
  final file = File(_goldenPath);
  final regen = Platform.environment['REGEN_GOLDEN'] == '1';
  if (regen || !file.existsSync()) {
    file.writeAsStringSync(_encode(actual));
    // ignore: avoid_print
    print('Wrote golden snapshot to $_goldenPath (${actual.length} entries).');
  }

  final expected = _decode(File(_goldenPath).readAsStringSync());

  group('Golden parser snapshot', () {
    test('corpus keys are unchanged', () {
      expect(actual.keys, expected.keys,
          reason: 'Corpus changed; regenerate with REGEN_GOLDEN=1.');
    });

    for (final name in actual.keys) {
      test(name, () {
        expect(
          actual[name],
          expected[name],
          reason: 'Parser output for "$name" changed vs the golden snapshot. '
              'If intentional, regenerate with REGEN_GOLDEN=1.',
        );
      });
    }
  });
}

/// Builds the serialized output for every corpus entry.
Map<String, String> _buildSections() {
  final out = <String, String>{};
  for (final entry in _corpus.entries) {
    out[entry.key] = _serialize(markdownDecoder.convert(entry.value));
  }
  return out;
}

/// Encodes the section map into a single golden-file string.
String _encode(Map<String, String> sections) {
  final buffer = StringBuffer();
  for (final entry in sections.entries) {
    buffer
      ..write(_sectionPrefix)
      ..writeln(entry.key)
      ..writeln(entry.value);
  }
  return buffer.toString();
}

/// Decodes a golden-file string back into a section map.
Map<String, String> _decode(String raw) {
  final sections = <String, String>{};
  String? current;
  final body = StringBuffer();
  void flush() {
    final key = current;
    if (key != null) {
      var text = body.toString();
      if (text.endsWith('\n')) text = text.substring(0, text.length - 1);
      sections[key] = text;
    }
    body.clear();
  }

  for (final line in const LineSplitter().convert(raw)) {
    if (line.startsWith(_sectionPrefix)) {
      flush();
      current = line.substring(_sectionPrefix.length);
    } else {
      body.writeln(line);
    }
  }
  flush();
  return sections;
}

// ---------------------------------------------------------------------------
// Serialization: a compact, deterministic textual form of the whole AST.
// ---------------------------------------------------------------------------

/// Serializes a [Markdown] document into a canonical multi-line string.
String _serialize(Markdown md) {
  final buffer = StringBuffer();
  for (final block in md.blocks) {
    _serializeBlock(block, buffer, 0);
  }
  return buffer.toString().trimRight();
}

void _serializeBlock(MD$Block block, StringBuffer out, int depth) {
  final pad = '  ' * depth;
  block.map<void>(
    paragraph: (p) {
      out.writeln('${pad}P');
      _serializeSpans(p.spans, out, depth + 1);
    },
    heading: (h) {
      out.writeln('${pad}H${h.level}');
      _serializeSpans(h.spans, out, depth + 1);
    },
    quote: (q) {
      out.writeln('${pad}Q indent=${q.indent}');
      if (q.blocks.isEmpty) {
        _serializeSpans(q.spans, out, depth + 1);
      } else {
        for (final child in q.blocks) {
          _serializeBlock(child, out, depth + 1);
        }
      }
    },
    alert: (a) {
      out.writeln('${pad}ALERT ${a.alert.name}');
      if (a.blocks.isEmpty) {
        _serializeSpans(a.spans, out, depth + 1);
      } else {
        for (final child in a.blocks) {
          _serializeBlock(child, out, depth + 1);
        }
      }
    },
    code: (c) {
      out.writeln('${pad}CODE lang=${_q(c.language ?? '')} '
          'text=${_q(c.text)}');
    },
    list: (l) {
      out.writeln('${pad}LIST');
      for (final item in l.items) {
        _serializeItem(item, out, depth + 1);
      }
    },
    table: (t) {
      final aligns = t.alignments.map((a) => a.name).join(',');
      out.writeln('${pad}TABLE aligns=[$aligns]');
      out.writeln('$pad  header');
      _serializeRow(t.header, out, depth + 2);
      for (final row in t.rows) {
        out.writeln('$pad  row');
        _serializeRow(row, out, depth + 2);
      }
    },
    divider: (d) => out.writeln('${pad}HR'),
    spacer: (s) => out.writeln('${pad}SPACER count=${s.count}'),
  );
}

void _serializeItem(MD$ListItem item, StringBuffer out, int depth) {
  final pad = '  ' * depth;
  out.writeln('${pad}ITEM marker=${_q(item.marker)} '
      'indent=${item.indent} checked=${item.checked}');
  _serializeSpans(item.spans, out, depth + 1);
  for (final child in item.children) {
    _serializeItem(child, out, depth + 1);
  }
}

void _serializeRow(MD$TableRow row, StringBuffer out, int depth) {
  final pad = '  ' * depth;
  for (var i = 0; i < row.cells.length; i++) {
    out.writeln('${pad}cell$i');
    _serializeSpans(row.cells[i], out, depth + 1);
  }
}

void _serializeSpans(List<MD$Span> spans, StringBuffer out, int depth) {
  final pad = '  ' * depth;
  for (final span in spans) {
    out.writeln('$pad${_span(span)}');
  }
}

String _span(MD$Span s) {
  final buffer = StringBuffer()
    ..write('[${s.start},${s.end}] style=${s.style.value} ${_q(s.text)}');
  final extra = s.extra;
  if (extra != null && extra.isNotEmpty) {
    final keys = extra.keys.toList(growable: false)..sort();
    buffer.write(' {');
    for (var i = 0; i < keys.length; i++) {
      if (i > 0) buffer.write(', ');
      buffer.write('${keys[i]}=${_q('${extra[keys[i]]}')}');
    }
    buffer.write('}');
  }
  return buffer.toString();
}

/// Quotes and escapes a string so newlines/tabs stay on a single line.
String _q(String s) {
  final escaped = s
      .replaceAll(r'\', r'\\')
      .replaceAll('\n', r'\n')
      .replaceAll('\t', r'\t')
      .replaceAll('"', r'\"');
  return '"$escaped"';
}

// ---------------------------------------------------------------------------
// Corpus: a broad set of inputs exercising every parser code path and the
// tricky corner cases that optimizations must not regress.
// ---------------------------------------------------------------------------

const Map<String, String> _corpus = <String, String>{
  // Plain prose (the fast-path target).
  'prose-simple': 'The quick brown fox jumps over the lazy dog.',
  'prose-multiline': 'First line of a paragraph\nsecond line here\nthird line.',
  'prose-two-paragraphs': 'Paragraph one.\n\nParagraph two.',
  'prose-operators': '5 * 6 = 30 and 3 < 4 and a_b_c and x > y stay literal.',
  'prose-unicode': 'Привет мир 👋 and 日本語 text 🌍 mixed together.',

  // Emphasis.
  'em-bold': 'This is **bold** text.',
  'em-italic-star': 'This is *italic* text.',
  'em-italic-underscore': 'This is _italic_ text.',
  'em-underline': 'This is __underline__ text.',
  'em-strike': 'This is ~~strike~~ text.',
  'em-highlight': 'This is ==highlight== text.',
  'em-spoiler': 'This is ||spoiler|| text.',
  'em-code': 'This is `code` text.',
  'em-nested': '**bold _and italic_ together**',
  'em-adjacent': '*a**b**c*',
  'em-unterminated-star': '**bold never closed',
  'em-unterminated-single': 'a * lonely asterisk',
  'em-intraword-underscore': 'snake_case and object_id remain literal',
  'em-cyrillic-underscore': 'переменная_значение_тут',
  'em-mixed-line': '**b** *i* __u__ ~~s~~ `c` ==h== ||sp||',
  'em-unterminated-code': 'a `code span never closed',
  'em-double-backtick': 'use ``double`` backticks',

  // Links & images.
  'link-simple': '[text](https://example.com)',
  'link-title': '[text](https://example.com "the title")',
  'link-single-quote-title': "[text](https://example.com 'the title')",
  'link-angle': '[text](<https://example.com/a b>)',
  'link-in-text': 'See [the docs](https://x.io) for more.',
  'link-emphasis': 'A **[bold link](https://x.io)** here.',
  'image-simple': '![alt](https://example.com/i.png)',
  'image-title': '![alt](https://example.com/i.png "cap")',
  'link-nested-parens': '[t](https://x.io/path(with)parens)',
  'link-two': '[a](b) and [c](d)',

  // Escapes.
  'escape-emphasis': r'\*not italic\* and \_not underline\_',
  'escape-backtick': r'\`not code\`',
  'escape-brackets': r'\[not a link\](nope)',
  'escape-backslash-eol': 'trailing backslash\\',
  'escape-lone': '\\',

  // Inline math.
  'math-alpha': r'The angle $\alpha$ is small.',
  'math-currency': r'It costs $5 and $10 today.',
  'math-in-code': r'`$\alpha$` stays literal in code.',
  'math-mixed': r'$\pi \approx 3.14$ but $plain$ is untouched.',

  // Headings.
  'heading-h1': '# Heading one',
  'heading-h6': '###### Heading six',
  'heading-closing': '## Heading ##',
  'heading-no-space': '#hashtag is not a heading',
  'heading-seven': '####### too many hashes',
  'heading-empty': '#',

  // Quotes & alerts.
  'quote-simple': '> quoted text',
  'quote-multiline': '> line one\n> line two',
  'alert-note': '> [!NOTE]\n> Take note of this.',
  'alert-tip': '> [!TIP]\n> A helpful tip.',
  'alert-important': '> [!IMPORTANT]\n> Important detail.',
  'alert-warning': '> [!WARNING]\n> A warning here.',
  'alert-caution': '> [!CAUTION]\n> Be cautious.',
  'alert-lowercase': '> [!note]\n> lowercase marker.',
  'alert-with-emphasis': '> [!NOTE]\n> Body with **bold** and `code`.',

  // Code blocks.
  'code-fenced': '```dart\nvoid main() {}\n```',
  'code-tilde': '~~~\nplain code\n~~~',
  'code-no-lang': '```\nno language\n```',
  'code-unterminated': '```dart\nvoid main() {}',

  // Lists.
  'list-unordered': '- one\n- two\n- three',
  'list-ordered': '1. one\n2. two\n3. three',
  'list-nested': '- a\n  - b\n    - c\n- d',
  'list-task': '- [ ] todo\n- [x] done\n- [X] also done',
  'list-mixed-marker': '* star\n+ plus\n- dash',
  'list-with-inline': '- item with **bold** and [link](https://x.io)',

  // Tables.
  'table-basic': '| a | b |\n| --- | --- |\n| 1 | 2 |',
  'table-aligned': '| L | C | R |\n| :-- | :-: | --: |\n| 1 | 2 | 3 |',
  'table-inline': '| a | b |\n| --- | --- |\n| **x** | `y` |',
  'table-malformed-ragged': '| a | b |\n| --- | --- |\n| 1 |',
  'table-no-delimiter': '| a | b |\n| 1 | 2 |',

  // Thematic breaks & spacers.
  'hr-dash': '---',
  'hr-star': '***',
  'hr-underscore': '___',
  'hr-spaced': '- - -',
  'hr-between': 'above\n\n---\n\nbelow',
  'spacer-multi': 'a\n\n\n\nb',

  // Whole documents / robustness.
  'doc-mixed': '# Title\n\nA **para** with `code`.\n\n> quote\n\n- x\n- y\n\n'
      '| a | b |\n| --- | --- |\n| 1 | 2 |\n\n---\n\nDone.',
  'empty': '',
  'whitespace-only': '   \t  ',
  'newlines-only': '\n\n\n',

  // Pathological shapes (kept small; pins output across linear rewrites).
  'patho-star-run-no-closer': r'a****************************************b',
  'patho-underscore-run-no-closer':
      r'a________________________________________b',
  'patho-tilde-run-no-closer': r'a~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~b',
  'patho-equals-run-no-closer': r'a========================================b',
  'patho-pipe-run-no-closer': r'a||||||||||||||||||||||||||||||||||||||||b',
  'patho-bold-openers-no-closer': r'**a **a **a **a **a **a **a **a **a **a ',
  'patho-italic-openers-closer-at-end': r'*x *x *x *x *x *x *x *x *x *x x*',
  'patho-mixed-openers-escapes':
      r'*a \*b **c \\**d _e __f ~~g ==h ||i \_j x** y*',
  'patho-marker-run-boundaries': r'***a**** b ****c*** __d___ e___',
  'patho-escaped-backslash-backtick': r'a\\`\\`\\`\\`\\`\\`\\`\\`\\`\\`\\`\\`b',
  'patho-escaped-backticks-then-real': r'\` x \\` y ` z \` w',
  'patho-label-openers-one-closer': r'[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[]',
  'patho-image-openers-one-closer': r'![![![![![![![![![![![![![![![]',
  'patho-label-openers-then-link': r'[[[a] [b](u) [[c]] ![d](e)',
  'patho-table-rows-no-separator':
      '| a | b |\n| a | b |\n| a | b |\n| a | b |\n| a | b |\n| a | b |\n',
  'patho-table-one-bad-last-row':
      '| h | i |\n|---|---|\n| a | b |\n| a | b |\n| a | b |\n| a | b |\n'
          '| a | b | c |\n',
  'patho-table-stacked-pairs-bad-row':
      '|h|\n|-|\n|h|\n|-|\n|h|\n|-|\n|h|\n|-|\n|h|\n|-|\n|a|b|\n',
  'patho-table-runs-of-counts':
      '| a | b |\n|---|---|\n| 1 | 2 |\n|x|\n| a |\n|:-:|\n| 1 |\n| 2 |\n\n'
          '|a|b|c|\n|-|-|-|\n|1|2|3|',
  'patho-table-cells-with-markers':
      '| *a | b* |\n|---|---|\n| `c | d` |\n| [e | f](g) |',

  // Shapes of the follow-up linear rewrites: heading scan, link cursor,
  // closer cursors, quote depth.
  'hostile-heading-closing-variants':
      '# a #\n## b ##  \n### c\t#\n# d#\n# e # f\n# # #\n#  \t \n# g \\#',
  'hostile-heading-inner-spaces': '# a          b          ',
  'hostile-link-in-code-then-link': '`[a](b)` [c](d) `![e](f)` ![g](h)',
  'hostile-escaped-bang-link': r'\![a](b) [c](d)',
  'hostile-adjacent-links': '![a](1)![b](2)[c](3)**[d](4)**',
  'hostile-closer-past-opener': '*a *b c* d* **e **f g** h** _i _j k_ l_',
  'hostile-closer-escaped': r'*a\* b* **c\** d** `e\` f` \`g`',
  'hostile-closer-run-alignment': '***a*** ~~~b~~~ ===c=== |||d||| ____e____',
  'hostile-fence-quote-depth-2': '> > ```\n> > code\n> > ```\n> after',
  'hostile-fence-quote-unspaced': '>>>```\n>>>code\n>>>```',
};
