import 'dart:math';

import 'package:flutter_md/flutter_md.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pins what a linear rewrite of a parser path must keep, and checks inputs
/// that used to hang the parser. `edge_cases_test.dart` holds the first group
/// of quadratic shapes; these are the ones found after it.
void main() => group('Hostile input', () {
      group('Parses in linear time', () {
        const size = 256 * 1024;
        const budget = Duration(seconds: 1);
        String rows(String row) => row * (size ~/ row.length);
        const plain = MarkdownDecoder();
        const math = MarkdownDecoder(inlineMath: true);
        final inputs = <String, (MarkdownDecoder, String)>{
          'heading, spaces inside': (plain, '# a${' ' * size}b'),
          'heading, tabs inside': (plain, '# a${'\t' * size}b'),
          'heading, trailing spaces': (plain, '# a${' ' * size}'),
          'heading, closing-like runs': (plain, '# a${rows(' #')}b'),
          'quote, deep': (plain, '>' * size),
          'quote, deep with a fence': (plain, '${'>' * size}```'),
          'quote, deep with spaces': (plain, '${rows('> ')}```'),
          'quote, deep alert': (
            plain,
            '> [!NOTE]\n${'>' * size}```',
          ),
          'links, more than 65535': (plain, rows('[a](b) ') * 2),
          'math, braces never closed': (math, '\$${rows('x^{')}\$'),
          'math, braces closed once': (math, '\$${rows('_{')}}\$'),
        };
        for (final MapEntry(:key, :value) in inputs.entries) {
          test(key, () {
            final stopwatch = Stopwatch()..start();
            value.$1.convert(value.$2);
            expect(stopwatch.elapsed, lessThan(budget));
          });
        }
      });

      group('Headings', () {
        // The regular expressions the hand-rolled scan replaced, as an oracle.
        final pattern = RegExp(r'^(#{1,6})(?:[ \t]+(.*?))?[ \t]*$');
        final closing = RegExp(r'[ \t]+#+$');

        void expectSameAsOracle(String line) {
          final block = markdownDecoder.convert(line).blocks.single;
          final match = pattern.firstMatch(line);
          if (match == null) {
            expect(block, isA<MD$Paragraph>(), reason: line);
            return;
          }
          expect(block, isA<MD$Heading>(), reason: line);
          final heading = block as MD$Heading;
          expect(heading.level, match.group(1)!.length, reason: line);
          expect(
            heading.text,
            (match.group(2) ?? '').replaceFirst(closing, ''),
            reason: line,
          );
        }

        for (final line in <String>[
          '#',
          '######',
          '#######',
          '# ',
          '#\t',
          '#a',
          '# a',
          '#\ta',
          '#  \t a  \t ',
          '# #',
          '# ##',
          '# a #',
          '# a#',
          '# a #b',
          '# a # #',
          '# a \\#',
          '# a\t##\t',
          '## ## ##',
          '#  ',
          '# a b',
          '# ',
          '#  a ',
        ]) {
          test('agrees with the regular expressions on "$line"', () {
            expectSameAsOracle(line);
          });
        }

        test('agrees with the regular expressions on random lines', () {
          const alphabet = <String>['#', '#', ' ', ' ', '\t', 'a', r'\', ' '];
          final random = Random(38);
          for (var n = 0; n < 20000; n++) {
            final line = StringBuffer('#');
            for (var k = random.nextInt(12); k > 0; k--) {
              line.write(alphabet[random.nextInt(alphabet.length)]);
            }
            expectSameAsOracle(line.toString());
          }
        });
      });

      group('Links', () {
        test('keeps every link past the 16-bit boundary', () {
          const count = 70000;
          final spans = (markdownDecoder
                  .convert(List.generate(count, (i) => '[$i](u$i)').join(' '))
                  .blocks
                  .single as MD$Paragraph)
              .spans
              .where((s) => s.style.contains(MD$Style.link))
              .toList();
          expect(spans, hasLength(count));
          for (final i in <int>[0, 65534, 65535, 65536, 65537, count - 1]) {
            expect(spans[i].text, '$i');
            expect(spans[i].extra?['url'], 'u$i');
          }
        });

        List<MD$Span> spans(String text) =>
            (markdownDecoder.convert(text).blocks.single as MD$Paragraph).spans;

        test('a code span passes over the link inside it', () {
          final result = spans('`[a](b)` [c](d)');
          expect(result.first.text, '[a](b)');
          expect(result.first.style.contains(MD$Style.monospace), isTrue);
          expect(result.last.text, 'c');
          expect(result.last.extra?['url'], 'd');
        });

        test('an escaped bang leaves the label literal', () {
          final result = spans(r'\![a](b) [c](d)');
          expect(
              result.where((s) => s.style.contains(MD$Style.image)), isEmpty);
          expect(result.last.extra?['url'], 'd');
        });

        test('adjacent images and links keep their order', () {
          final urls = spans('![a](1)![b](2)[c](3)**[d](4)**')
              .map((s) => s.extra?['url'])
              .whereType<Object>()
              .toList();
          expect(urls, <Object>['1', '2', '3', '4']);
        });

        test('more labels than links resolve the right one', () {
          expect(
              spans('[[[a] [b](u) [[c]] ![d](e)')
                  .map((s) => s.extra?['url'])
                  .whereType<Object>()
                  .toList(),
              <Object>['u', 'e']);
        });
      });

      group('Quote depth', () {
        String nested(int depth) {
          final prefix = '> ' * depth;
          return '$prefix```\n${prefix}code\n$prefix```';
        }

        /// The block a chain of single-child quotes ends in.
        MD$Block innermost(Markdown markdown) {
          var block = markdown.blocks.single;
          while (block is MD$Quote && block.blocks.isNotEmpty) {
            block = block.blocks.single;
          }
          return block;
        }

        test('a fence stays code at the deepest parsed level', () {
          final code = innermost(markdownDecoder.convert(nested(32)));
          expect(code, isA<MD$Code>());
          expect((code as MD$Code).text, 'code');
        });

        test('a fence below that level is inline text', () {
          final quote = innermost(markdownDecoder.convert(nested(33)));
          expect(quote, isA<MD$Quote>());
          expect((quote as MD$Quote).spans, isNotEmpty);
        });

        test('an alert counts as a level', () {
          final prefix = '> ' * 40;
          final alert = markdownDecoder.convert(
            '> [!NOTE]\n> ${prefix}x\n> $prefix```',
          );
          expect(alert.blocks.single, isA<MD$Alert>());
        });

        test('input far deeper than the stack does not overflow', () {
          final markdown = markdownDecoder.convert('${'>' * 500000}```');
          expect(markdown.blocks.single, isA<MD$Quote>());
        });

        test('streaming agrees with the batch parse below the limit', () {
          final source = '${nested(40)}\n\nafter';
          final parser = StreamingMarkdownParser();
          late Markdown streamed;
          for (var i = 0; i < source.length; i += 7) {
            final end = min(i + 7, source.length);
            streamed = parser.add(source.substring(i, end));
          }
          expect(_shape(streamed), _shape(markdownDecoder.convert(source)));
        });
      });

      group('Math braces', () {
        const decoder = MarkdownDecoder(inlineMath: true);
        String text(String source) =>
            (decoder.convert(source).blocks.single as MD$Paragraph)
                .spans
                .map((s) => s.text)
                .join();

        for (final (source, expected) in <(String, String)>[
          (r'$x^{2$', r'$x^{2$'),
          (r'$x^{2}$', 'x²'),
          (r'$x^{2}^{3}$', 'x²³'),
          (r'$a^{b^{2}$', 'a^{b²'),
          (r'$a^{b}^{2}$', 'a^{b}²'),
          (r'$x^{$', r'$x^{$'),
          (r'$x^{}$', 'x'),
          (r'$H_{2}^{1}$', 'H₂¹'),
        ]) {
          test('"$source" reads "$expected"', () {
            expect(text(source), expected);
          });
        }
      });

      test('random documents keep the parser invariants', () {
        const tokens = <String>[
          '*', '**', '_', '__', '~~', '==', '||', '`', r'\', '[', ']', '(', ')',
          '![', '](', ' ', '  ', '\n', '\n\n', 'a', 'word', 'я', '😀', '# ',
          ' #', '> ', '>', '```', '~~~', '- ', '  - ', '1. ', '[x] ', '|',
          '|-|',
          '| a |', r'$', '^{', '}', r'\alpha', '[a](b)', '[!NOTE]', ' ',
          '\r\n', '\t', //
        ];
        final random = Random(20261030);
        const decoder = MarkdownDecoder(inlineMath: true);
        for (var n = 0; n < 4000; n++) {
          final pool = n.isEven
              ? tokens
              : (List.of(tokens)..shuffle(random)).take(6).toList();
          final source = StringBuffer();
          for (var k = 1 + random.nextInt(30); k > 0; k--) {
            source.write(pool[random.nextInt(pool.length)]);
          }
          final input = source.toString();
          final markdown = decoder.convert(input);
          expect(markdown.markdown, input);
          for (final block in markdown.blocks) {
            final spans = switch (block) {
              final MD$Paragraph p => p.spans,
              final MD$Heading h => h.spans,
              _ => const <MD$Span>[],
            };
            var previous = 0;
            for (final span in spans) {
              expect(span.start, greaterThanOrEqualTo(previous), reason: input);
              expect(span.end, greaterThanOrEqualTo(span.start), reason: input);
              previous = span.start;
            }
          }
          final parser = StreamingMarkdownParser(decoder: decoder);
          late Markdown streamed;
          for (var i = 0; i < input.length;) {
            final end = min(i + 1 + random.nextInt(9), input.length);
            streamed = parser.add(input.substring(i, end));
            i = end;
          }
          if (input.isEmpty) continue;
          expect(_shape(streamed), _shape(markdown), reason: input);
        }
      });
    });

/// Each block's type and rendered text.
List<String> _shape(Markdown markdown) => <String>[
      for (final block in markdown.blocks)
        '${block.runtimeType}: ${markdownBlockRenderedText(block)}',
    ];
