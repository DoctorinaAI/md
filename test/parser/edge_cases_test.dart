import 'package:flutter_md/flutter_md.dart';
import 'package:flutter_test/flutter_test.dart';

/// Asserts that parsing [input] does not throw and yields a [Markdown].
void _parsesCleanly(String input) {
  expect(() => markdownDecoder.convert(input), returnsNormally);
  expect(markdownDecoder.convert(input), isA<Markdown>());
}

void main() => group('Edge cases & robustness', () {
      group('Does not crash on pathological input', () {
        final inputs = <String, String>{
          'empty': '',
          'only whitespace': '   \t  ',
          'only newlines': '\n\n\n',
          'unterminated code fence': '```dart\nvoid main() {}',
          'unterminated tilde fence': '~~~\ncode',
          'unterminated link': '[label](http://x.com',
          'unterminated image': '![alt](',
          'unclosed label bracket': '[unclosed and [real](http://x.com)',
          'lonely markers': '* _ ~ = | ` #',
          'many hashes': '#############',
          'nested quotes': '> outer\n>> inner\n>>> deepest',
          'ragged table': '| a | b |\n|---|---|\n| 1 |\n| x | y |',
          'table missing trailing pipe': '| a | b\n| --- | --- |\n| 1 | 2',
          'pipes without table': 'a | b | c',
          'deeply nested list': '- a\n  - b\n    - c\n      - d\n'
              '        - e\n          - f',
          'non-monotonic list indent': '- a\n    - b\n  - c',
          'mixed tabs and spaces list': '- a\n\t- b\n  - c',
          'crlf line endings': 'line one\r\nline two\r\n\r\nsecond',
          'trailing whitespace': 'text with trailing   \nnext line',
          'huge emphasis run': '*' * 200,
          'all special chars': r'*_~=|`#>-+.![]()\{}',
          'backslash at end': 'text\\',
          'lone backslash': '\\',
        };
        for (final entry in inputs.entries) {
          test(entry.key, () => _parsesCleanly(entry.value));
        }
      });

      group('Unicode & emoji', () {
        test('cyrillic text parses and round-trips', () {
          final md = markdownDecoder.convert('Привет **мир**');
          expect(md.text, contains('Привет'));
          expect(md.text, contains('мир'));
        });

        test('emoji are preserved', () {
          final md = markdownDecoder.convert('Hello 👋 world 🌍');
          expect(md.text, contains('👋'));
          expect(md.text, contains('🌍'));
        });

        test('cyrillic underscores are not intraword emphasis', () {
          final md = markdownDecoder.convert('переменная_значение_тут');
          final spans = (md.blocks.single as MD$Paragraph).spans;
          expect(spans.every((s) => s.style.isEmpty), isTrue);
          expect(spans.map((s) => s.text).join(), 'переменная_значение_тут');
        });

        test('emphasis works around unicode content', () {
          final md = markdownDecoder.convert('**жирный**');
          expect((md.blocks.single as MD$Paragraph).spans.single.style, MD$Style.bold);
        });
      });

      group('Boundary conditions', () {
        test('single character', () => _parsesCleanly('a'));

        test('very long single-line paragraph', () {
          _parsesCleanly('word ' * 5000);
        });

        test('many blocks', () {
          final buffer = StringBuffer();
          for (var i = 0; i < 500; i++) {
            buffer.writeln('# Heading $i');
            buffer.writeln('Paragraph $i with **bold** and `code`.');
            buffer.writeln();
          }
          _parsesCleanly(buffer.toString());
        });

        test('markdown reference round-trips via the markdown field', () {
          const source = '# Title\n\nBody with **bold**.';
          expect(markdownDecoder.convert(source).markdown, source);
        });

        test('empty input yields no blocks', () {
          expect(markdownDecoder.convert('').blocks, isEmpty);
          expect(markdownDecoder.convert('').isEmpty, isTrue);
        });
      });

      group('Whitespace-only markers stay literal', () {
        test('a line of only pipes is not a table', () {
          expect(
            markdownDecoder.convert('|||').blocks.every((b) => b is! MD$Table),
            isTrue,
          );
        });

        test('a lone hash line with text after space is a heading', () {
          expect(markdownDecoder.convert('# ok').blocks.single, isA<MD$Heading>());
        });
      });
    });
