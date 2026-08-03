// RENDER BENCHMARK — guards layout/paint cost and the content-Picture cache.
//
// Must run under the Flutter test engine (needs real dart:ui text layout +
// PictureRecorder); plain `dart run` has no text backend.
//
// Compare against the saved baseline:
//   flutter test benchmark/render_benchmark.dart
// Record a new baseline (benchmark/.render_baseline.txt):
//   flutter test benchmark/render_benchmark.dart --dart-define=RENDER_BASELINE=save
//
// Timings are RELATIVE (headless engine) — use the deltas for regressions, and
// confirm true frame-rate with `flutter run --profile` + DevTools timeline.
//
// Tiers:
//   layout_large   full layout of a large doc         (performLayout cost)
//   paint_miss     fresh painter: layout + first paint (records new Picture)
//   paint_hit      same painter+size: paint again      (cache hit → drawPicture)
//   stream_append  update(newModel) + relayout         (LLM streaming rebuild)
//   scroll_frame   wall time per pump during a drag     (widget-level)
//   selection_drag highlight repaint over cached Picture (must NOT rebuild it)
//
// The selection_drag tier encodes the spike-S7 invariant: a selection drag
// repaints only the highlight overlay, reusing the cached content Picture, so a
// drag frame must be far cheaper than a fresh (cache-miss) paint.
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_md/flutter_md.dart';
import 'package:flutter_md/src/render.dart' show MarkdownPainter;
import 'package:flutter_test/flutter_test.dart';

const bool _save = String.fromEnvironment('RENDER_BASELINE') == 'save';
const double _kWidth = 400;

final Map<String, double> _results = <String, double>{};

MarkdownThemeData _theme() => MarkdownThemeData(
      textStyle: const TextStyle(fontSize: 14, color: Color(0xFF000000)),
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.noScaling,
    );

String _largeSource({int blocks = 50}) {
  final b = StringBuffer();
  for (var i = 0; i < blocks; i++) {
    b.writeln('## Section $i');
    b.writeln();
    b.writeln('Paragraph $i with **bold**, _italic_, `code` and '
        '[a link](https://example.com/$i) plus some filler words here.');
    b.writeln();
    b.writeln('- item one for $i');
    b.writeln('- item two for $i');
    b.writeln();
    b.writeln('| A | B |');
    b.writeln('|---|---|');
    b.writeln('| $i | ${i * 2} |');
    b.writeln();
  }
  return b.toString();
}

/// Min-of-batches per-op microseconds (mirrors benchmark/compare.dart).
double _bench(void Function() body,
    {int warmupMs = 150, int batches = 20, int minBatchMs = 8}) {
  final warm = Stopwatch()..start();
  while (warm.elapsedMilliseconds < warmupMs) body();

  var iters = 1;
  while (true) {
    final sw = Stopwatch()..start();
    for (var i = 0; i < iters; i++) body();
    sw.stop();
    if (sw.elapsedMicroseconds >= minBatchMs * 1000) break;
    iters = iters < 2 ? 2 : iters * 2;
    if (iters > 1 << 22) break;
  }

  var best = double.infinity;
  for (var b = 0; b < batches; b++) {
    final sw = Stopwatch()..start();
    for (var i = 0; i < iters; i++) body();
    sw.stop();
    best = math.min(best, sw.elapsedMicroseconds / iters);
  }
  return best;
}

void _paintOnce(MarkdownPainter p, Size size) {
  final rec = ui.PictureRecorder();
  final canvas = Canvas(rec);
  p.paint(canvas, size);
  rec.endRecording().dispose();
}

void main() {
  final theme = _theme();
  final large = Markdown.fromString(_largeSource());
  final largeGrown = Markdown.fromString('${_largeSource()}\n\nAppended tail.');

  test('micro: layout / paint-miss / paint-hit / stream', () {
    // layout_large
    _results['layout_large'] = _bench(() {
      MarkdownPainter(markdown: large, theme: theme)
        ..layout(maxWidth: _kWidth)
        ..dispose();
    });

    // paint_miss (fresh painter each time -> records a new Picture)
    _results['paint_miss'] = _bench(() {
      final p = MarkdownPainter(markdown: large, theme: theme);
      final size = p.layout(maxWidth: _kWidth);
      _paintOnce(p, size);
      p.dispose();
    });

    // paint_hit (same painter + size -> reuses the cached Picture)
    final hitPainter = MarkdownPainter(markdown: large, theme: theme);
    final hitSize = hitPainter.layout(maxWidth: _kWidth);
    _paintOnce(hitPainter, hitSize); // prime the cache
    _results['paint_hit'] = _bench(() => _paintOnce(hitPainter, hitSize));
    hitPainter.dispose();

    // stream_append (toggle model so update() always sees a change)
    final p = MarkdownPainter(markdown: large, theme: theme)..layout(maxWidth: _kWidth);
    var flip = false;
    _results['stream_append'] = _bench(() {
      flip = !flip;
      p
        ..update(markdown: flip ? largeGrown : large, theme: theme)
        ..layout(maxWidth: _kWidth);
    });
    p.dispose();

    // selection_drag (grow a highlight over the cached content Picture each
    // frame; the content Picture must be reused, not re-recorded).
    final selPaint = Paint()..color = const Color(0x552196F3);
    final selPainter = MarkdownPainter(markdown: large, theme: theme);
    final selSize = selPainter.layout(maxWidth: _kWidth);
    _paintOnce(selPainter, selSize); // prime the content cache
    var off = 0;
    _results['selection_drag'] = _bench(() {
      off = (off + 1) % 8;
      final rec = ui.PictureRecorder();
      final canvas = Canvas(rec);
      selPainter.paintHighlight(
        canvas,
        (source) => source == 0 ? TextRange(start: 0, end: off) : null,
        selPaint,
      );
      selPainter.paint(canvas, selSize); // cache hit — no new Picture
      rec.endRecording().dispose();
    });
    selPainter.dispose();

    // Sanity: the cache must make a hit dramatically cheaper than a miss.
    expect(_results['paint_hit']!, lessThan(_results['paint_miss']!));
    // A selection-drag frame must not rebuild the content Picture, so it stays
    // far below a fresh paint (spike S7 invariant).
    expect(_results['selection_drag']!, lessThan(_results['paint_miss']! / 3));
  });

  testWidgets('widget: scroll_frame wall time', (tester) async {
    final docs = <Markdown>[
      for (var i = 0; i < 30; i++)
        Markdown.fromString('### Message $i\n\nBody of message $i with text.'),
    ];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ListView.builder(
          itemCount: docs.length,
          itemBuilder: (_, i) => Padding(
            padding: const EdgeInsets.all(8),
            child: MarkdownWidget(markdown: docs[i], theme: theme),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    const frames = 40;
    final sw = Stopwatch()..start();
    for (var i = 0; i < frames; i++) {
      await tester.drag(find.byType(ListView), const Offset(0, -12));
      await tester.pump(const Duration(milliseconds: 16));
    }
    sw.stop();
    _results['scroll_frame'] = sw.elapsedMicroseconds / frames;
  });

  tearDownAll(() {
    final baseline = _loadBaseline();
    // ignore: avoid_print
    print('\n${'tier'.padRight(16)}${'us/op'.padLeft(12)}'
        '${'base'.padLeft(12)}${'delta'.padLeft(10)}');
    for (final e in _results.entries) {
      final base = baseline?[e.key];
      final delta = base == null ? '-' : _delta(base, e.value);
      // ignore: avoid_print
      print('${e.key.padRight(16)}${e.value.toStringAsFixed(2).padLeft(12)}'
          '${(base?.toStringAsFixed(2) ?? '-').padLeft(12)}${delta.padLeft(10)}');
    }
    if (_save) {
      _saveBaseline(_results);
      // ignore: avoid_print
      print('\nSaved baseline to benchmark/.render_baseline.txt');
    }
  });
}

String _delta(double base, double now) {
  final pct = (now - base) / base * 100;
  return '${pct <= 0 ? '' : '+'}${pct.toStringAsFixed(1)}%';
}

Map<String, double>? _loadBaseline() {
  final file = File('benchmark/.render_baseline.txt');
  if (!file.existsSync()) return null;
  final map = <String, double>{};
  for (final line in file.readAsLinesSync()) {
    final parts = line.split('\t');
    if (parts.length == 2) {
      final v = double.tryParse(parts[1]);
      if (v != null) map[parts[0]] = v;
    }
  }
  return map;
}

void _saveBaseline(Map<String, double> results) {
  final buffer = StringBuffer();
  for (final e in results.entries) {
    buffer.writeln('${e.key}\t${e.value.toStringAsFixed(3)}');
  }
  File('benchmark/.render_baseline.txt').writeAsStringSync(buffer.toString());
}
