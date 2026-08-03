// ignore_for_file: avoid_print

import 'dart:io';

import 'package:flutter_md/src/markdown.dart' show Markdown;

import 'scenarios.dart';

/// A fast, low-noise timing tool used while iterating on parser optimizations.
///
/// For each scenario it runs a warmup, then times many batches and reports the
/// *minimum* per-op time (the minimum is the most stable estimator, least
/// affected by GC pauses and scheduler noise). It optionally reads a previous
/// baseline from `benchmark/.baseline.txt` and prints the delta.
///
/// Usage:
/// ```shell
/// # Record the current numbers as the baseline:
/// dart run benchmark/compare.dart --save
///
/// # Compare current numbers against the saved baseline:
/// dart run benchmark/compare.dart
/// ```
/// Accumulator that consumes parse output so the optimizer cannot eliminate
/// the parsing work as dead code.
int _sink = 0;

void main(List<String> args) {
  final save = args.contains('--save');
  final results = <String, double>{};

  for (final entry in scenarios.entries) {
    results[entry.key] = _bench(entry.value);
  }

  // Reference the sink so the whole benchmark cannot be optimized away.
  if (_sink == 0x7fffffff) print('(unreachable sink marker)');

  final baseline = save ? null : _loadBaseline();

  print('scenario                us/op       baseline    delta');
  print('----------------------  ----------  ----------  ----------');
  var total = 0.0;
  var baseTotal = 0.0;
  for (final entry in results.entries) {
    final us = entry.value;
    total += us;
    final base = baseline?[entry.key];
    final baseStr = base == null ? '-' : base.toStringAsFixed(2);
    final deltaStr = base == null ? '-' : _delta(base, us);
    if (base != null) baseTotal += base;
    print('${entry.key.padRight(22)}  '
        '${us.toStringAsFixed(2).padLeft(10)}  '
        '${baseStr.padLeft(10)}  '
        '${deltaStr.padLeft(10)}');
  }
  print('----------------------  ----------  ----------  ----------');
  final totalDelta = baseTotal > 0 ? _delta(baseTotal, total) : '-';
  print('${'TOTAL'.padRight(22)}  '
      '${total.toStringAsFixed(2).padLeft(10)}  '
      '${(baseTotal > 0 ? baseTotal.toStringAsFixed(2) : '-').padLeft(10)}  '
      '${totalDelta.padLeft(10)}');

  if (save) {
    _saveBaseline(results);
    print('\nSaved baseline to benchmark/.baseline.txt');
  }
}

/// Returns the minimum per-op time in microseconds for parsing [input].
double _bench(String input,
    {int warmupMs = 200, int batches = 25, int minBatchMs = 8}) {
  // Warmup to trigger JIT compilation / reach steady state.
  final warmupSw = Stopwatch()..start();
  while (warmupSw.elapsedMilliseconds < warmupMs) {
    _sink ^= Markdown.fromString(input).blocks.length;
  }

  // Calibrate iterations so a batch runs for at least [minBatchMs].
  var iters = 1;
  while (true) {
    final sw = Stopwatch()..start();
    for (var i = 0; i < iters; i++) {
      _sink ^= Markdown.fromString(input).blocks.length;
    }
    sw.stop();
    if (sw.elapsedMicroseconds >= minBatchMs * 1000) break;
    iters = iters < 2 ? 2 : (iters * 2);
    if (iters > 1 << 22) break;
  }

  var best = double.infinity;
  for (var b = 0; b < batches; b++) {
    final sw = Stopwatch()..start();
    for (var i = 0; i < iters; i++) {
      _sink ^= Markdown.fromString(input).blocks.length;
    }
    sw.stop();
    final us = sw.elapsedMicroseconds / iters;
    if (us < best) best = us;
  }
  return best;
}

String _delta(double base, double now) {
  final pct = (now - base) / base * 100;
  final sign = pct <= 0 ? '' : '+';
  return '$sign${pct.toStringAsFixed(1)}%';
}

Map<String, double>? _loadBaseline() {
  final file = File('benchmark/.baseline.txt');
  if (!file.existsSync()) return null;
  final map = <String, double>{};
  for (final line in file.readAsLinesSync()) {
    final parts = line.split('\t');
    if (parts.length == 2) {
      final value = double.tryParse(parts[1]);
      if (value != null) map[parts[0]] = value;
    }
  }
  return map;
}

void _saveBaseline(Map<String, double> results) {
  final buffer = StringBuffer();
  for (final entry in results.entries) {
    buffer.writeln('${entry.key}\t${entry.value.toStringAsFixed(3)}');
  }
  File('benchmark/.baseline.txt').writeAsStringSync(buffer.toString());
}
