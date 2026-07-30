// ignore_for_file: avoid_print

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:flutter_md/src/markdown.dart' show Markdown;
import 'package:markdown/markdown.dart' as gmd;

import 'scenarios.dart';

/// Multi-scenario benchmark suite for the [Markdown] parser.
///
/// Unlike `parse_benchmark.dart` (which compares one mixed document against the
/// `markdown` package), this suite isolates individual workloads so that the
/// effect of a specific optimization can be observed per scenario.
///
/// Run:
/// ```shell
/// dart run benchmark/parser_benchmark.dart
/// ```
/// Or compile for stable numbers:
/// ```shell
/// dart compile exe benchmark/parser_benchmark.dart -o /tmp/pb && /tmp/pb
/// ```
void main() {
  print('scenario                bytes    us/op     MB/s');
  print('----------------------  -------  --------  -------');
  var total = 0.0;
  for (final entry in scenarios.entries) {
    final us = _ParseBenchmark(entry.key, entry.value).measure();
    total += us;
    final bytes = entry.value.length;
    final mbps = bytes / us; // bytes/us == MB/s
    print('${entry.key.padRight(22)}  '
        '${bytes.toString().padLeft(7)}  '
        '${us.toStringAsFixed(2).padLeft(8)}  '
        '${mbps.toStringAsFixed(1).padLeft(7)}');
  }
  print('----------------------  -------  --------  -------');
  print('${'TOTAL'.padRight(22)}  ${' '.padLeft(7)}  '
      '${total.toStringAsFixed(2).padLeft(8)}');

  // Keep a head-to-head comparison against the `markdown` package on the
  // representative mixed document, so regressions relative to it stay visible.
  print('');
  final current = _ParseBenchmark('current', mixed).measure();
  final google = _GoogleBenchmark(mixed).measure();
  final ratio = google / current;
  print('mixed vs. `markdown` pkg: '
      '${ratio.toStringAsFixed(2)}x faster '
      '(current ${current.toStringAsFixed(1)} us, '
      'google ${google.toStringAsFixed(1)} us)');
}

class _ParseBenchmark extends BenchmarkBase {
  _ParseBenchmark(super.name, this.input);

  final String input;
  Markdown? _result;

  @override
  void run() => _result = Markdown.fromString(input);

  @override
  void teardown() {
    super.teardown();
    if (_result == null) throw StateError('result is null');
  }
}

class _GoogleBenchmark extends BenchmarkBase {
  _GoogleBenchmark(this.input) : super('google');

  final String input;
  List<gmd.Node>? _result;

  @override
  void run() => _result =
      gmd.Document(extensionSet: gmd.ExtensionSet.gitHubFlavored).parse(input);

  @override
  void teardown() {
    super.teardown();
    if (_result == null) throw StateError('result is null');
  }
}
