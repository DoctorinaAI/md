// ignore_for_file: avoid_print

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:flutter_md/src/parser.dart' show MarkdownDecoder;

/// Scaling benchmark for inputs built to make a Markdown parser quadratic.
///
/// Every shape is measured at two sizes, [_small] and [_large]. A linear path
/// costs about [_large] / [_small] times more at the large size, so the `growth`
/// column should stay near that factor; a quadratic path shows its square.
///
/// Run:
/// ```shell
/// dart run benchmark/hostile_benchmark.dart
/// dart run benchmark/hostile_benchmark.dart heading quote  # by name
/// ```
void main(List<String> args) {
  print('Growth from ${_small >> 10} KB to ${_large >> 10} KB '
      '(linear = ${_large ~/ _small}x)');
  print('shape                         small us   large us     MB/s  growth');
  print('----------------------------  ---------  ---------  -------  ------');
  for (final MapEntry(:key, :value) in _shapes.entries) {
    if (args.isNotEmpty && !args.any(key.contains)) continue;
    final decoder = MarkdownDecoder(inlineMath: key.startsWith('math'));
    final small = _Benchmark(key, decoder, value(_small)).measure();
    final large = _Benchmark(key, decoder, value(_large)).measure();
    final bytes = value(_large).length;
    print('${key.padRight(28)}  '
        '${small.toStringAsFixed(1).padLeft(9)}  '
        '${large.toStringAsFixed(1).padLeft(9)}  '
        '${(bytes / large).toStringAsFixed(1).padLeft(7)}  '
        '${(large / small).toStringAsFixed(1).padLeft(5)}x');
  }
}

const int _small = 16 * 1024;
const int _large = 128 * 1024;

String _rows(String row, int size) => row * (size ~/ row.length);

/// The shapes, each a function of the wanted input size in code units.
final Map<String, String Function(int)> _shapes =
    <String, String Function(int)>{
  // Emphasis and code spans.
  'emphasis run, no closer': (n) => 'a${'*' * n}b',
  'underscore run, no closer': (n) => 'a${'_' * n}b',
  'bold openers, no closer': (n) => _rows('**a ', n),
  'mixed openers, no closer': (n) => _rows('**a __b ~~c ==d ||e ', n),
  'paired emphasis': (n) => _rows('*a* ', n),
  'backticks, escaped backslash': (n) => 'a${_rows(r'\\`', n)}b',
  'paired code spans': (n) => _rows('`a` ', n),
  // Links.
  'label openers, one closer': (n) => '${'[' * n}]',
  'labels without a target': (n) => _rows('[a]', n),
  'link target, never closed': (n) => _rows('[a](', n),
  'links': (n) => _rows('[a](b) ', n),
  'links past the 16-bit index': (n) => _rows('[a](b) ', n * 4),
  // Headings.
  'heading, spaces inside': (n) => '# a${' ' * n}b',
  'heading, closing-like runs': (n) => '# a${_rows(' #', n)}b',
  'heading lines': (n) => _rows('# a\n', n),
  // Quotes.
  'quote, deep': (n) => '>' * n,
  'quote, deep with a fence': (n) => '${'>' * n}```',
  'quote lines, deep': (n) => _rows('${'>' * 200}\n', n),
  // Tables.
  'table rows, no delimiter': (n) => _rows('| a | b |\n', n),
  'table, ragged last row': (n) =>
      '| h | i |\n|---|---|\n${_rows('| a | b |\n', n)}| a | b | c |\n',
  'table, stacked headers': (n) => '${_rows('|h|\n|-|\n', n)}|a|b|\n',
  // Math (enabled for the shapes named `math`).
  'math, braces never closed': (n) => '\$${_rows('x^{', n)}\$',
  'math, braces closed once': (n) => '\$${_rows('_{', n)}}\$',
  'math, commands': (n) => _rows(r'$\alpha$ ', n),
};

class _Benchmark extends BenchmarkBase {
  _Benchmark(super.name, this.decoder, this.input);

  final MarkdownDecoder decoder;
  final String input;
  int _blocks = 0;

  @override
  void run() => _blocks += decoder.convert(input).blocks.length;

  @override
  void teardown() {
    super.teardown();
    if (_blocks == 0) throw StateError('no blocks parsed');
  }
}
