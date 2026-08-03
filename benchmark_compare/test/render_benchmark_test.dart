// RENDER BENCHMARK — flutter_md vs flutter_markdown vs gpt_markdown.
//
// This measures the *end-to-end* cost of turning a Markdown **string** into
// painted pixels: parse + build + layout + paint, which is what every library
// actually does on the frame that first shows a message. It is measured as
// wall-clock time around `tester.pump()` after forcing a full subtree rebuild
// (a changing `ValueKey` unmounts the old tree and builds a fresh one).
//
//   flutter test test/render_benchmark_test.dart
//
// All three libraries are given the SAME normalized styles (see lib/styles.dart)
// — identical base text style + explicit line height, matched heading sizes and
// matched block spacing — so layout *density* is no longer a variable. The test
// also prints a rendered-height table so the density match can be verified.
//
// Notes on fairness & interpretation:
//   * Each iteration reconstructs from the source string. For flutter_md that
//     means `Markdown.fromString(src)` is called inside the builder too, so its
//     parse cost is included on equal footing with the other two (which parse
//     inside build()).
//   * All three render into the same fixed viewport (width 400) inside a
//     SingleChildScrollView, so layout covers the whole document while paint is
//     clipped to the same visible region for every library.
//   * Absolute microseconds include fixed flutter_test frame overhead and are
//     only meaningful *relative to each other* on the same machine — use the
//     ratios. Confirm real on-device frame time with the profile-mode scroll
//     benchmark (integration_test/scroll_perf_test.dart).
//
// The reported number per (library, document) is the min-of-batches per-op time
// (the minimum is the most stable estimator, least perturbed by GC / scheduler).

// ignore_for_file: avoid_print

import 'dart:math' as math;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:md_benchmark_compare/corpus.dart';
import 'package:md_benchmark_compare/styles.dart';

/// width the documents are laid out at.
const double _kWidth = 400;

/// results[library][document] = us/op.
final Map<String, Map<String, double>> _results = <String, Map<String, double>>{
  for (final name in styledLibraries.keys) name: <String, double>{},
};

/// heights[library][document] = rendered px height (density check).
final Map<String, Map<String, double>> _heights = <String, Map<String, double>>{
  for (final name in styledLibraries.keys) name: <String, double>{},
};

const Key _probeKey = ValueKey<String>('probe');

/// A host that rebuilds its subtree from scratch whenever [tick] changes, so a
/// pump measures the full parse+build+layout+paint of one library on one doc.
class _Host extends StatelessWidget {
  const _Host({
    required this.tick,
    required this.factory,
    required this.source,
  });

  final ValueListenable<int> tick;
  final StyledFactory factory;
  final String source;

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: ValueListenableBuilder<int>(
            valueListenable: tick,
            builder: (context, value, _) => SingleChildScrollView(
              child: SizedBox(
                width: _kWidth,
                // A fresh key each tick forces a full teardown + rebuild.
                child: KeyedSubtree(
                  key: ValueKey<int>(value),
                  child: Builder(
                    builder: (ctx) => KeyedSubtree(
                      key: _probeKey,
                      child: factory(ctx, source),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

Future<double> _benchBuild(
  WidgetTester tester,
  ValueNotifier<int> tick, {
  int warmup = 4,
  int batches = 10,
  int itersPerBatch = 4,
}) async {
  for (var i = 0; i < warmup; i++) {
    tick.value++;
    await tester.pump();
  }
  var best = double.infinity;
  for (var b = 0; b < batches; b++) {
    final sw = Stopwatch()..start();
    for (var i = 0; i < itersPerBatch; i++) {
      tick.value++;
      await tester.pump();
    }
    sw.stop();
    best = math.min(best, sw.elapsedMicroseconds / itersPerBatch);
  }
  return best;
}

void main() {
  for (final libEntry in styledLibraries.entries) {
    final lib = libEntry.key;
    final factory = libEntry.value;

    group('render: $lib', () {
      for (final docEntry in renderCorpus.entries) {
        final doc = docEntry.key;
        final source = docEntry.value;

        testWidgets('$lib / $doc', (tester) async {
          final tick = ValueNotifier<int>(0);
          await tester.pumpWidget(
            _Host(tick: tick, factory: factory, source: source),
          );
          // Surface any build-time error (e.g. an unsupported construct) loudly
          // rather than recording a bogus timing.
          expect(tester.takeException(), isNull,
              reason: '$lib failed to render "$doc"');

          _heights[lib]![doc] = tester.getSize(find.byKey(_probeKey)).height;
          _results[lib]![doc] = await _benchBuild(tester, tick);
          tick.dispose();
        });
      }
    });
  }

  tearDownAll(_printTables);
}

void _printTables() {
  final docs = renderCorpus.keys.toList();
  final libs = styledLibraries.keys.toList();

  _matrix('Render (end-to-end: parse + build + layout + paint), us/op — '
      'lower is better', docs, libs, _results, (v) => v.toStringAsFixed(1));

  // Relative-to-flutter_md view (how many times slower each library is).
  const base = 'flutter_md';
  print('');
  print('Render, relative to $base (x = library / $base; '
      'lower is better, 1.00x = same speed)');
  _relative(docs, libs, _results, base);

  // Density check: rendered height per library, and its spread vs flutter_md.
  _matrix('Rendered height (px) — density check (styles normalized)', docs,
      libs, _heights, (v) => v.toStringAsFixed(0));
  print('');
  print('Height relative to $base (x = library / $base; 1.00x = same height)');
  _relative(docs, libs, _heights, base);
}

void _matrix(
  String title,
  List<String> docs,
  List<String> libs,
  Map<String, Map<String, double>> data,
  String Function(double) fmt,
) {
  print('');
  print(title);
  print('');
  final header = StringBuffer('| document       |');
  final sep = StringBuffer('| -------------- |');
  for (final lib in libs) {
    header.write(' ${lib.padLeft(16)} |');
    sep.write(' ---------------: |');
  }
  print(header);
  print(sep);
  for (final doc in docs) {
    final row = StringBuffer('| ${doc.padRight(14)} |');
    for (final lib in libs) {
      final v = data[lib]![doc];
      row.write(' ${(v == null ? '-' : fmt(v)).padLeft(16)} |');
    }
    print(row);
  }
}

void _relative(
  List<String> docs,
  List<String> libs,
  Map<String, Map<String, double>> data,
  String base,
) {
  print('');
  final header = StringBuffer('| document       |');
  final sep = StringBuffer('| -------------- |');
  for (final lib in libs) {
    header.write(' ${lib.padLeft(16)} |');
    sep.write(' ---------------: |');
  }
  print(header);
  print(sep);
  for (final doc in docs) {
    final baseVal = data[base]![doc];
    final row = StringBuffer('| ${doc.padRight(14)} |');
    for (final lib in libs) {
      final v = data[lib]![doc];
      final cell = (baseVal == null || v == null || baseVal == 0)
          ? '-'
          : '${(v / baseVal).toStringAsFixed(2)}x';
      row.write(' ${cell.padLeft(16)} |');
    }
    print(row);
  }
  print('');
}
