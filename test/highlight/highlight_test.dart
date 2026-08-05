import 'dart:math';

import 'package:flutter/painting.dart';
import 'package:flutter_md/flutter_md.dart';
import 'package:flutter_md/highlight.dart';
import 'package:flutter_md/highlight/all.dart';
import 'package:flutter_md/highlight/themes.dart';
import 'package:flutter_test/flutter_test.dart';

/// Flattens a span tree into (text, effectiveStyle) fragments, resolving the
/// inherited style down the tree exactly as the text engine would.
List<(String, TextStyle)> _fragments(InlineSpan span, [TextStyle? inherited]) {
  final out = <(String, TextStyle)>[];
  void walk(InlineSpan node, TextStyle acc) {
    if (node is! TextSpan) return;
    final merged = node.style == null ? acc : acc.merge(node.style);
    final text = node.text;
    if (text != null && text.isNotEmpty) out.add((text, merged));
    for (final child in node.children ?? const <InlineSpan>[]) {
      walk(child, merged);
    }
  }

  walk(span, inherited ?? const TextStyle());
  return out;
}

/// The effective color of the first fragment whose text equals [needle].
Color? _colorOf(List<(String, TextStyle)> frags, String needle) {
  for (final (text, style) in frags) {
    if (text == needle) return style.color;
  }
  return null;
}

void main() {
  const base = TextStyle(fontFamily: 'monospace', fontSize: 14);

  MarkdownHighlighter highlighterWith(Map<String, Grammar> langs) =>
      MarkdownHighlighter(languages: langs, theme: HighlightThemes.githubDark);

  // Tokenizes [src] under the grammar registered for [tag] and returns the
  // concatenated span text (which must equal [src] for a lossless highlighter).
  String roundTrip(String tag, String src) {
    final grammar = allHighlightLanguages[tag]!;
    final highlighter = highlighterWith({tag: grammar});
    return TextSpan(children: highlighter.highlight(src, tag, base))
        .toPlainText();
  }

  group('Highlight › losslessness (selection stays aligned)', () {
    final cases = <String, (Grammar, String)>{
      'dart': (
        HighlightDart.grammar,
        '// a comment\n'
            'class Foo<T> extends Bar {\n'
            '  final String name = "hi \$world and \${a.b}";\n'
            '  int n = 0x1F + 42; // trailing\n'
            '  @override void f() => print(r\'raw\');\n'
            '}\n',
      ),
      'json': (
        HighlightJson.grammar,
        '{"a": 1, "b": "x", "c": [true, null], "d": 3.14e2}',
      ),
      'bash': (
        HighlightBash.grammar,
        '#!/usr/bin/env bash\n'
            '# comment\n'
            'name="world"\n'
            'echo "hello \$name \${name:-def} \$(date)"\n'
            'for i in 1 2 3; do echo "\$i"; done\n',
      ),
    };

    for (final MapEntry(key: lang, value: (grammar, source)) in cases.entries) {
      test('$lang round-trips to identical text', () {
        final highlighter = highlighterWith({lang: grammar});
        final spans = highlighter.highlight(source, lang, base);
        final joined = TextSpan(children: spans).toPlainText();
        expect(joined, source, reason: 'highlighting must not alter text');
      });
    }
  });

  group('Highlight › tokens are colored', () {
    test('dart keyword / comment / number use the theme palette', () {
      final highlighter = highlighterWith({'dart': HighlightDart.grammar});
      const code = '// hi\nclass Foo {}\nvar n = 42;';
      final frags = _fragments(TextSpan(
        style: base,
        children: highlighter.highlight(code, 'dart', base),
      ));

      expect(_colorOf(frags, 'class'), const Color(0xFFFF7B72)); // keyword
      expect(_colorOf(frags, '42'), const Color(0xFF79C0FF)); // number

      final comment = frags.firstWhere((f) => f.$1.startsWith('//'));
      expect(comment.$2.color, const Color(0xFF8B949E));
      expect(comment.$2.fontStyle, FontStyle.italic);
    });

    test('python keyword / string / comment use the theme palette', () {
      final highlighter = MarkdownHighlighter(
          languages: {'python': HighlightPython.grammar},
          theme: HighlightThemes.githubDark);
      const code = '# c\ndef greet(name):\n    return "hi"';
      final frags = _fragments(TextSpan(
        style: base,
        children: highlighter.highlight(code, 'python', base),
      ));
      expect(_colorOf(frags, 'def'), const Color(0xFFFF7B72)); // keyword
      expect(_colorOf(frags, '"hi"'), const Color(0xFFA5D6FF)); // string
      final comment = frags.firstWhere((f) => f.$1.startsWith('#'));
      expect(comment.$2.color, const Color(0xFF8B949E));
    });

    test('json string vs number are distinguished', () {
      final highlighter = highlighterWith({'json': HighlightJson.grammar});
      const code = '{"k": "v", "n": 7}';
      final frags = _fragments(TextSpan(
        style: base,
        children: highlighter.highlight(code, 'json', base),
      ));
      expect(_colorOf(frags, '"v"'), const Color(0xFFA5D6FF)); // string
      expect(_colorOf(frags, '7'), const Color(0xFF79C0FF)); // number
    });
  });

  group('Highlight › all bundled grammars', () {
    // A varied polyglot blob: tags, comments, interpolated strings, numbers,
    // template markers, keywords. Tokenizing it under every grammar exercises
    // regex compilation, nested/rest recursion, and lossless partitioning.
    const sample = r'''
<a href="test">link</a>
/* block comment */ // line comment
const greeting = "hi $name and ${a.b}";
let n = 0xFF + 42 - 3.14e2;
<?php echo $x; ?>
name: value  # yaml-ish comment
SELECT * FROM t WHERE id = 1;
def f(x): return x
''';

    test('every grammar builds, tokenizes and round-trips losslessly', () {
      final failures = <String>[];
      for (final MapEntry(key: tag, value: grammar)
          in allHighlightLanguages.entries) {
        final highlighter = MarkdownHighlighter(
          languages: {tag: grammar},
          theme: HighlightThemes.githubDark,
        );
        final joined =
            TextSpan(children: highlighter.highlight(sample, tag, base))
                .toPlainText();
        if (joined != sample) failures.add(tag);
      }
      expect(failures, isEmpty, reason: 'text altered for: $failures');
    });

    test('registry covers the popular languages and their aliases', () {
      // Spot-check that common fence tags resolve.
      for (final tag in const [
        'js',
        'javascript',
        'ts',
        'typescript',
        'py',
        'python',
        'rb',
        'ruby',
        'html',
        'css',
        'scss',
        'go',
        'rust',
        'java',
        'kotlin',
        'swift',
        'c',
        'cpp',
        'csharp',
        'php',
        'sql',
        'yaml',
        'json',
        'bash',
        'sh',
      ]) {
        expect(allHighlightLanguages.containsKey(tag), isTrue,
            reason: 'missing $tag');
      }
    });
  });

  group('Highlight › fallbacks', () {
    test('unknown language yields a single plain span equal to the source', () {
      final highlighter = highlighterWith({'dart': HighlightDart.grammar});
      const code = 'nothing to see here';
      final spans = highlighter.highlight(code, 'ruby', base);
      expect(spans, hasLength(1));
      expect(TextSpan(children: spans).toPlainText(), code);
    });

    test('null language yields plain text', () {
      final highlighter = highlighterWith({'dart': HighlightDart.grammar});
      final spans = highlighter.highlight('x = 1', null, base);
      expect(TextSpan(children: spans).toPlainText(), 'x = 1');
    });

    test('language tag is matched case-insensitively', () {
      final highlighter = highlighterWith({'dart': HighlightDart.grammar});
      final frags = _fragments(TextSpan(
        style: base,
        children: highlighter.highlight('class X {}', 'DART', base),
      ));
      expect(_colorOf(frags, 'class'), const Color(0xFFFF7B72));
    });
  });

  group('Highlight › BlockPainter\$Code integration', () {
    test('renderedText equals source (selection offset space preserved)', () {
      final theme = MarkdownThemeData(
        textStyle: base,
        highlighter: highlighterWith({'dart': HighlightDart.grammar}),
      );
      const code = 'void main() => print("hi"); // c';
      final painter = BlockPainter$Code(
        text: code,
        language: 'dart',
        theme: theme,
      );
      expect(painter.renderedText, code);
      painter.dispose();
    });

    test('no highlighter keeps plain-text behavior', () {
      final theme = MarkdownThemeData(textStyle: base);
      const code = 'class Foo {}';
      final painter = BlockPainter$Code(
        text: code,
        language: 'dart',
        theme: theme,
      );
      expect(painter.renderedText, code);
      painter.dispose();
    });

    test('delegates to the theme highlighter for the block language', () {
      final spy = _SpyHighlighter();
      final theme = MarkdownThemeData(textStyle: base, highlighter: spy);
      final painter =
          BlockPainter$Code(text: 'x = 1', language: 'dart', theme: theme);
      expect(spy.seenLanguages, contains('dart'));
      expect(painter.renderedText, 'x = 1');
      painter.dispose();
    });
  });

  group('Highlight › corner cases', () {
    test('empty and whitespace-only inputs round-trip and do not throw', () {
      for (final src in const ['', ' ', '\n', '\n\n', '\t  \n ', '   ']) {
        for (final tag in const ['dart', 'js', 'html', 'json', 'bash']) {
          expect(roundTrip(tag, src), src, reason: 'tag=$tag');
        }
      }
    });

    test('empty code yields an empty (or plain) span with no text', () {
      final highlighter = highlighterWith({'dart': HighlightDart.grammar});
      final joined = TextSpan(children: highlighter.highlight('', 'dart', base))
          .toPlainText();
      expect(joined, isEmpty);
    });

    test('unicode, emoji (surrogate pairs) and CJK are preserved', () {
      const src = '// π ≈ 3.14  你好, 世界  👍🏽 家族\n'
          'const s = "café — naïve — 🚀"; // ✅';
      for (final tag in const ['dart', 'python', 'js', 'json', 'yaml']) {
        expect(roundTrip(tag, src), src, reason: 'tag=$tag');
      }
    });

    test('CRLF and mixed line endings are preserved verbatim', () {
      const src = 'a = 1\r\n// c\r\nb = 2\rlast';
      for (final tag in const ['dart', 'js', 'bash', 'sql']) {
        expect(roundTrip(tag, src), src, reason: 'tag=$tag');
      }
    });

    test('deeply nested interpolation does not overflow and round-trips', () {
      final buffer = StringBuffer('"');
      for (var i = 0; i < 200; i++) {
        buffer.write(r'${x + ');
      }
      buffer.write('1');
      for (var i = 0; i < 200; i++) {
        buffer.write('}');
      }
      buffer.write('"');
      final src = buffer.toString();
      expect(roundTrip('dart', src), src);
    });

    test('templating language with a rest grammar (php+html) round-trips', () {
      const src = '<div class="x">\n'
          '  <?php echo "hi \$name"; // c\n'
          '  for (\$i = 0; \$i < 3; \$i++) { print(\$i); } ?>\n'
          '</div>';
      expect(roundTrip('php', src), src);
    });

    test('a very long input with many tokens round-trips', () {
      final src = ('final x = "s"; // comment ${'ab12 ' * 4}\n' * 500);
      expect(roundTrip('dart', src), src);
    });

    test('custom grammar exercises lookbehind, nested inside and rest', () {
      final inner =
          Grammar([GrammarToken('number', compileHighlightPattern(r'\d+'))]);
      final rest =
          Grammar([GrammarToken('keyword', compileHighlightPattern('foo'))]);
      final grammar = Grammar(
        [
          GrammarToken('comment', compileHighlightPattern('//.*')),
          // Lookbehind: group 1 ('@') is excluded from the emitted token.
          GrammarToken('function', compileHighlightPattern(r'(@)\w+'),
              lookbehind: true),
          GrammarToken('string', compileHighlightPattern(r'\{[^}]*\}'),
              inside: () => inner),
        ],
        rest: () => rest,
      );
      final highlighter = highlighterWith({'x': grammar});
      const src = '// c\n@name {42} foo';
      final spans = highlighter.highlight(src, 'x', base);
      final frags = _fragments(TextSpan(style: base, children: spans));

      expect(TextSpan(children: spans).toPlainText(), src);
      expect(_colorOf(frags, 'name'), const Color(0xFFD2A8FF)); // function
      // Lookbehind excluded '@', so the token is 'name', never '@name'.
      expect(_colorOf(frags, '@name'), isNull);
      expect(_colorOf(frags, '42'), const Color(0xFF79C0FF)); // inside → number
      expect(_colorOf(frags, 'foo'), const Color(0xFFFF7B72)); // rest → keyword
    });

    test('compileHighlightPattern: invalid source disables the rule', () {
      final bad = compileHighlightPattern('(unclosed');
      expect(bad.hasMatch('an (unclosed group'), isFalse);
      final good = compileHighlightPattern('abc', caseSensitive: false);
      expect(good.hasMatch('xxABCxx'), isTrue);
    });

    test('a rule whose regex Dart rejects is skipped, text still round-trips',
        () {
      final grammar = Grammar([
        GrammarToken(
            'bad', compileHighlightPattern(r'(?<= )\K')), // unsupported → never
        GrammarToken('number', compileHighlightPattern(r'\d+')),
      ]);
      final highlighter = highlighterWith({'x': grammar});
      const src = 'value 42 end';
      expect(
        TextSpan(children: highlighter.highlight(src, 'x', base)).toPlainText(),
        src,
      );
    });

    test('empty languages map falls back to plain text for any tag', () {
      final highlighter = MarkdownHighlighter(
          languages: const {}, theme: HighlightThemes.githubDark);
      const code = 'class Foo {}';
      final spans = highlighter.highlight(code, 'dart', base);
      expect(spans, hasLength(1));
      expect(TextSpan(children: spans).toPlainText(), code);
    });

    test('styleFor returns null for an unknown token type', () {
      expect(HighlightThemes.githubDark.styleFor('no-such-token'), isNull);
      expect(
          HighlightThemes.githubLight.styleFor('definitely-unknown'), isNull);
    });

    test('theme background/foreground surface through the highlighter', () {
      final highlighter = highlighterWith({'dart': HighlightDart.grammar});
      expect(highlighter.backgroundFor('dart'), const Color(0xFF0D1117));
      final derived = highlighter.baseStyleFor('dart', base);
      expect(derived.color, const Color(0xFFC9D1D9));
      expect(derived.fontFamily, 'monospace'); // fallback preserved
    });

    test('deterministic fuzz: random sources round-trip under many grammars',
        () {
      final rng = Random(20240805);
      // Chars that stress grammars: quotes, braces, comment/interp markers,
      // escapes, newlines, tabs.
      const alphabet = "abc 09{}()[]<>\"'/*#\$\\\n\t.:;=|&-_`~";
      const tags = [
        'dart',
        'js',
        'ts',
        'html',
        'php',
        'python',
        'ruby',
        'bash',
        'json',
        'yaml',
        'sql',
        'css',
        'go',
        'rust',
        'markdown',
      ];
      for (var i = 0; i < 300; i++) {
        final len = rng.nextInt(96);
        final sb = StringBuffer();
        for (var j = 0; j < len; j++) {
          sb.write(alphabet[rng.nextInt(alphabet.length)]);
        }
        final src = sb.toString();
        for (final tag in tags) {
          expect(roundTrip(tag, src), src, reason: 'tag=$tag len=$len iter=$i');
        }
      }
    });
  });
}

/// Records which languages it was asked to highlight; otherwise a pass-through
/// (lossless) highlighter, to verify [BlockPainter$Code] delegation.
class _SpyHighlighter implements SyntaxHighlighter {
  final List<String?> seenLanguages = <String?>[];

  @override
  List<InlineSpan> highlight(String code, String? language, TextStyle base) {
    seenLanguages.add(language);
    return <InlineSpan>[TextSpan(text: code)];
  }

  @override
  Color? backgroundFor(String? language) => null;

  @override
  TextStyle baseStyleFor(String? language, TextStyle fallback) => fallback;
}
