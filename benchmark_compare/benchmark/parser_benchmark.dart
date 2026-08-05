// ignore_for_file: avoid_print
//
// PARSER BENCHMARK — flutter_md vs the `markdown` package (flutter_markdown's
// engine), using benchmark_harness.
//
// flutter_markdown does no parsing of its own; on every build it delegates to
// the `markdown` package (`md.Document(...).parse(source)`). So the fair
// parser-to-parser comparison is:
//
//   flutter_md   : Markdown.fromString(source)      -> block model
//   flutter_markdown engine : md.Document(gfm).parse(source) -> AST nodes
//
// gpt_markdown has **no separable parser** — it parses inline while building
// its widget tree — so it does not appear here; its parsing cost is folded into
// the render benchmark (test/render_benchmark_test.dart) instead.
//
// Run (JIT):      dart run benchmark/parser_benchmark.dart
// Run (AOT, best) dart compile exe benchmark/parser_benchmark.dart -o /tmp/pb && /tmp/pb
//
// Each benchmark overrides `exercise()` to call `run()` once, so the number
// reported by `measure()` is microseconds per single parse (per-op), not the
// benchmark_harness default of 10 runs per exercise.

import 'package:benchmark_harness/benchmark_harness.dart';
// Import the pure-Dart parser entry point directly (not the `flutter_md.dart`
// barrel, which pulls in Flutter widgets) so this runs under `dart`/AOT with no
// Flutter engine.
import 'package:flutter_md/src/markdown.dart' show Markdown;
import 'package:markdown/markdown.dart' as md;
import 'package:md_benchmark_compare/corpus.dart';

/// DCE guard — accumulates a byte of each result so the AOT compiler cannot
/// eliminate the parse as dead code.
int _sink = 0;

void main() {
  final rows = <_Row>[];
  for (final entry in corpus.entries) {
    final bytes = entry.value.length;
    final fmd = _FlutterMdBenchmark(entry.value).measure();
    final pkg = _MarkdownPkgBenchmark(entry.value).measure();
    rows.add(_Row(entry.key, bytes, fmd, pkg));
  }

  if (_sink == 0x7fffffff) print('(unreachable sink marker)');

  _printTable(rows);
}

void _printTable(List<_Row> rows) {
  print('');
  print('Parser: flutter_md vs `markdown` pkg (flutter_markdown engine)');
  print('Lower us/op is better; speedup = markdown-pkg / flutter_md.');
  print('');
  print('| scenario       |   bytes | flutter_md us/op | flutter_md MB/s '
      '| markdown-pkg us/op | speedup |');
  print('| -------------- | ------: | ---------------: | --------------: '
      '| -----------------: | ------: |');

  var fmdTotal = 0.0;
  var pkgTotal = 0.0;
  for (final r in rows) {
    fmdTotal += r.fmd;
    pkgTotal += r.pkg;
    final mbps = r.bytes / r.fmd; // bytes/us == MB/s
    final speedup = r.pkg / r.fmd;
    print('| ${r.name.padRight(14)} '
        '| ${r.bytes.toString().padLeft(7)} '
        '| ${r.fmd.toStringAsFixed(2).padLeft(16)} '
        '| ${mbps.toStringAsFixed(1).padLeft(15)} '
        '| ${r.pkg.toStringAsFixed(2).padLeft(18)} '
        '| ${'${speedup.toStringAsFixed(2)}x'.padLeft(7)} |');
  }
  final totalSpeedup = pkgTotal / fmdTotal;
  print('| ${'TOTAL'.padRight(14)} '
      '| ${''.padLeft(7)} '
      '| ${fmdTotal.toStringAsFixed(2).padLeft(16)} '
      '| ${''.padLeft(15)} '
      '| ${pkgTotal.toStringAsFixed(2).padLeft(18)} '
      '| ${'${totalSpeedup.toStringAsFixed(2)}x'.padLeft(7)} |');
  print('');
}

class _Row {
  _Row(this.name, this.bytes, this.fmd, this.pkg);
  final String name;
  final int bytes;
  final double fmd;
  final double pkg;
}

class _FlutterMdBenchmark extends BenchmarkBase {
  _FlutterMdBenchmark(this.input) : super('flutter_md');
  final String input;

  @override
  void exercise() => run(); // one parse per exercise -> measure() is per-op.

  @override
  void run() => _sink ^= Markdown.fromString(input).blocks.length;
}

class _MarkdownPkgBenchmark extends BenchmarkBase {
  _MarkdownPkgBenchmark(this.input) : super('markdown');
  final String input;

  @override
  void exercise() => run();

  @override
  void run() {
    // A fresh Document per parse — exactly how flutter_markdown uses the
    // package on every rebuild (Document is single-use / stateful).
    final nodes = md.Document(extensionSet: md.ExtensionSet.gitHubFlavored)
        .parse(input);
    _sink ^= nodes.length;
  }
}
