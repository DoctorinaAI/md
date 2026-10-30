// ON-DEVICE RENDER BENCHMARK (profile mode, real engine, real fonts).
//
// The `flutter test` benchmarks run in the headless engine with test fonts. This
// one runs on the device itself and reports three things:
//
//   * `stages`: flutter_md's pipeline taken apart, in microseconds: parse, build
//     the block painters, lay them out, record the picture, rasterize it.
//   * `frames`: flutter_md vs flutter_markdown vs gpt_markdown, as the engine's
//     own FrameTiming for a frame that shows a message for the first time.
//   * `scroll`: the same three libraries, FrameTiming over flings through a
//     chat feed. Unlike scroll_perf_test.dart this needs no VM service
//     connection from the app, which a physical iOS device can not make.
//   * `parse`: a very long document parsed at once and in slices while frames
//     keep running: the time it takes and the longest gap between two frames.
//
// Run through tool/device_bench.sh, which records the hardware and versions.
//
// Wall-clock numbers are medians of short batches. Unlike the minimum, the
// median also moves when a phone or tablet starts to throttle, and the spread
// (p10-p90) makes that visible.

import 'dart:io' show Platform, ProcessInfo;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_md/flutter_md.dart';
import 'package:flutter_md/highlight.dart';
import 'package:flutter_md/highlight/all.dart';
import 'package:flutter_md/highlight/themes.dart';
// ignore: invalid_use_of_internal_member, implementation_imports
import 'package:flutter_md/src/render.dart' show MarkdownPainter;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:md_benchmark_compare/corpus.dart';
import 'package:md_benchmark_compare/styles.dart';

const double _kWidth = 400;

/// What to run: `all`, `stages`, `frames`, `scroll`, `code` or `parse`.
const String _suite = String.fromEnvironment('SUITE', defaultValue: 'all');

/// Frames sampled per (library, document) after warm-up.
const int _kFrames = 40;

Map<String, num> _stats(List<double> samples) {
  final s = samples.toList()..sort();
  num at(double q) => s[((s.length - 1) * q).round()];
  return <String, num>{
    'p50': at(.5),
    'p10': at(.1),
    'p90': at(.9),
    'p99': at(.99),
    'max': s.last,
    'min': s.first,
    'n': s.length,
  };
}

/// Microseconds per call of [body]: warmed up, then batches of about 15 ms.
Map<String, num> _bench(void Function() body, {int batches = 25}) {
  final warm = Stopwatch()..start();
  while (warm.elapsedMilliseconds < 200) body();
  var iterations = 1;
  while (true) {
    final sw = Stopwatch()..start();
    for (var i = 0; i < iterations; i++) body();
    if (sw.elapsedMilliseconds >= 15) break;
    iterations *= 2;
  }
  final samples = <double>[];
  for (var b = 0; b < batches; b++) {
    final sw = Stopwatch()..start();
    for (var i = 0; i < iterations; i++) body();
    samples.add(sw.elapsedMicroseconds / iterations);
  }
  return _stats(samples);
}

/// Yields to the event loop so the OS and the raster thread can run.
Future<void> _breathe() => Future<void>.delayed(
      const Duration(milliseconds: 50),
    );

Future<Map<String, Object?>> _measureStages(MarkdownThemeData theme) async {
  final out = <String, Object?>{};
  for (final name in corpus.keys) {
    final source = corpus[name]!;
    final model = Markdown.fromString(source);
    final row = <String, Object?>{};

    row['parse'] = _bench(() => Markdown.fromString(source));
    await _breathe();

    row['build'] = _bench(
      () => MarkdownPainter(markdown: model, theme: theme).dispose(),
    );
    await _breathe();

    // Layout and paint are timed around the call itself, so the painter
    // construction above does not leak into them.
    final layoutSamples = <double>[];
    final paintSamples = <double>[];
    final stopwatch = Stopwatch();
    final until = Stopwatch()..start();
    while (until.elapsedMilliseconds < 600 || layoutSamples.length < 25) {
      final painter = MarkdownPainter(markdown: model, theme: theme);
      stopwatch
        ..reset()
        ..start();
      final size = painter.layout(maxWidth: _kWidth);
      stopwatch.stop();
      layoutSamples.add(stopwatch.elapsedMicroseconds.toDouble());
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      stopwatch
        ..reset()
        ..start();
      painter.paint(canvas, size);
      final picture = recorder.endRecording();
      stopwatch.stop();
      paintSamples.add(stopwatch.elapsedMicroseconds.toDouble());
      picture.dispose();
      painter.dispose();
    }
    row['layout'] = _stats(layoutSamples);
    row['record'] = _stats(paintSamples);
    await _breathe();

    // Rasterizing the whole document, which is what the raster thread does
    // the first time the cached picture reaches the screen.
    final painter = MarkdownPainter(markdown: model, theme: theme);
    final size = painter.layout(maxWidth: _kWidth);
    final recorder = ui.PictureRecorder();
    painter.paint(Canvas(recorder), size);
    final picture = recorder.endRecording();
    final rasterSamples = <double>[];
    for (var i = 0; i < 12; i++) {
      final sw = Stopwatch()..start();
      final image = await picture.toImage(
        size.width.ceil().clamp(1, 4096),
        size.height.ceil().clamp(1, 4096),
      );
      sw.stop();
      image.dispose();
      rasterSamples.add(sw.elapsedMicroseconds.toDouble());
    }
    picture.dispose();
    row['raster'] = _stats(rasterSamples);

    // Laying the same painter out again at another width: rotation or resize.
    var odd = false;
    row['relayout'] = _bench(() {
      painter.layout(maxWidth: (odd = !odd) ? _kWidth : _kWidth - 40);
    }, batches: 15);
    painter.dispose();

    row['height'] = size.height;
    row['blocks'] = model.blocks.length;
    row['bytes'] = source.length;
    out[name] = row;
    await _breathe();
  }
  out['stream'] = await _measureStream(theme);
  return out;
}

/// One LLM-style chunk arriving: parse the longer text, update, lay out, paint.
Future<Map<String, Object?>> _measureStream(MarkdownThemeData theme) async {
  final source = corpus['complex_large']!;
  const chunk = 48;
  final samples = <double>[];
  for (var round = 0; round < 3; round++) {
    final painter = MarkdownPainter(
      markdown: Markdown.fromString(''),
      theme: theme,
    );
    for (var end = chunk; end < source.length; end += chunk) {
      final prefix = source.substring(0, end);
      final sw = Stopwatch()..start();
      final size = (painter
            ..update(markdown: Markdown.fromString(prefix), theme: theme))
          .layout(maxWidth: _kWidth);
      final recorder = ui.PictureRecorder();
      painter.paint(Canvas(recorder), size);
      recorder.endRecording().dispose();
      sw.stop();
      if (round > 0) samples.add(sw.elapsedMicroseconds.toDouble());
    }
    painter.dispose();
    await _breathe();
  }
  return <String, Object?>{'chunk': _stats(samples), 'chunk_bytes': chunk};
}

/// A host whose subtree is rebuilt from scratch whenever [tick] changes.
class _Host extends StatelessWidget {
  const _Host(
      {required this.tick, required this.factory, required this.source});

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
                child: KeyedSubtree(
                  key: ValueKey<int>(value),
                  child: Builder(builder: (ctx) => factory(ctx, source)),
                ),
              ),
            ),
          ),
        ),
      );
}

/// One section of the long documents of [_measureParse].
const String _parseSection = '''
# Heading of a section

Paragraph with **bold**, *italic*, `code` and a [link](https://example.com) that
runs long enough to wrap over a couple of lines on a phone screen.

- first item with some text
- second item with **more** text

| a | b | c |
|---|---|---|
| 1 | 2 | 3 |

```dart
final value = compute(42); // A comment.
```

> A quote with a line of text.

''';

/// [parse] timed while a frame is requested after each frame: its duration and
/// the longest gap between two frames, in microseconds.
Future<({int total, int gap})> _parseWithFrames(
  Future<Object?> Function() parse,
) async {
  final binding = SchedulerBinding.instance;
  // Fails the run instead of hanging it if the engine stops producing frames.
  Future<void> nextFrame() =>
      binding.endOfFrame.timeout(const Duration(seconds: 10));
  var running = true, gap = 0;
  final sinceFrame = Stopwatch()..start();
  void onFrame(Duration _) {
    if (sinceFrame.elapsedMicroseconds > gap) {
      gap = sinceFrame.elapsedMicroseconds;
    }
    sinceFrame.reset();
    if (running) binding.scheduleFrameCallback(onFrame);
  }

  binding.scheduleFrameCallback(onFrame);
  await nextFrame();
  await nextFrame();
  gap = 0;
  sinceFrame.reset();
  final total = Stopwatch()..start();
  await parse();
  total.stop();
  await nextFrame(); // The gap ends at the frame after the parse.
  running = false;
  await nextFrame();
  return (total: total.elapsedMicroseconds, gap: gap);
}

Future<Map<String, Object?>> _measureParse() async {
  final out = <String, Object?>{};
  for (final kb in const <int>[100, 1000, 5000]) {
    final source = _parseSection * (kb * 1024 ~/ _parseSection.length);
    final modes = <String, Future<Object?> Function()>{
      'sync': () async => Markdown.fromString(source),
      'async': () => Markdown.fromStringAsync(source),
    };
    final result = <String, Object?>{};
    for (final MapEntry(key: mode, value: parse) in modes.entries) {
      final total = <double>[], gap = <double>[];
      for (var run = 0; run < 7; run++) {
        final sample = await _parseWithFrames(parse);
        total.add(sample.total.toDouble());
        gap.add(sample.gap.toDouble());
        await _breathe();
      }
      result[mode] = <String, Object?>{
        'total': _stats(total),
        'gap': _stats(gap),
      };
    }
    out['${kb}kb'] = result;
  }
  return out;
}

Future<Map<String, Object?>> _measureFrames(
  WidgetTester tester,
  String library,
  StyledFactory factory,
) async {
  final out = <String, Object?>{};
  for (final name in renderCorpus.keys) {
    final tick = ValueNotifier<int>(0);
    await tester.pumpWidget(
      _Host(tick: tick, factory: factory, source: renderCorpus[name]!),
    );
    for (var i = 0; i < 8; i++) {
      tick.value++;
      await tester.pump();
    }
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final timings = <ui.FrameTiming>[];
    void collect(List<ui.FrameTiming> batch) => timings.addAll(batch);
    SchedulerBinding.instance.addTimingsCallback(collect);
    for (var i = 0; i < _kFrames; i++) {
      tick.value++;
      await tester.pump();
    }
    // The engine reports timings in batches, at least once a second.
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    SchedulerBinding.instance.removeTimingsCallback(collect);
    expect(tester.takeException(), isNull, reason: '$library / $name');
    out[name] = <String, Object?>{
      'build': _stats(<double>[
        for (final t in timings) t.buildDuration.inMicroseconds.toDouble(),
      ]),
      'raster': _stats(<double>[
        for (final t in timings) t.rasterDuration.inMicroseconds.toDouble(),
      ]),
    };
    tick.dispose();
  }
  return out;
}

Future<Map<String, Object?>> _measureScroll(
  WidgetTester tester,
  StyledFactory factory,
) async {
  final feed = <String>[
    for (final name in const <String>[
      'simple',
      'inline',
      'quotes',
      'lists',
      'code',
      'table',
      'complex',
    ])
      corpus[name]!,
  ];
  const key = ValueKey<String>('feed');
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: ListView.builder(
          key: key,
          itemCount: 60,
          itemBuilder: (context, i) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: factory(context, feed[i % feed.length]),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  final timings = <ui.FrameTiming>[];
  void collect(List<ui.FrameTiming> batch) => timings.addAll(batch);
  SchedulerBinding.instance.addTimingsCallback(collect);
  final list = find.byKey(key);
  for (var i = 0; i < 6; i++) {
    await tester.fling(list, const Offset(0, -600), 2000);
    await tester.pumpAndSettle();
    await tester.fling(list, const Offset(0, 600), 2000);
    await tester.pumpAndSettle();
  }
  await Future<void>.delayed(const Duration(milliseconds: 1200));
  SchedulerBinding.instance.removeTimingsCallback(collect);
  return <String, Object?>{
    'build': _stats(<double>[
      for (final t in timings) t.buildDuration.inMicroseconds.toDouble(),
    ]),
    'raster': _stats(<double>[
      for (final t in timings) t.rasterDuration.inMicroseconds.toDouble(),
    ]),
    'missed_build':
        timings.where((t) => t.buildDuration.inMicroseconds > 16667).length,
    'missed_raster':
        timings.where((t) => t.rasterDuration.inMicroseconds > 16667).length,
  };
}

const String _codeSample = r'''
/// A repository of users, cached in memory.
class UserRepository<T extends User> implements Repository<T> {
  UserRepository(this._client, {this.limit = 42});

  final HttpClient _client;
  final int limit;
  final Map<String, T> _cache = <String, T>{}; // By id.

  @override
  Future<T?> find(String id) async {
    if (_cache.containsKey(id)) return _cache[id];
    final response = await _client.get('/users/$id?limit=${limit * 2}');
    return response.isOk ? _cache[id] = decode(response.body) as T : null;
  }
}
''';

String _codeLines(int lines) {
  const count = 16;
  return (_codeSample * (lines ~/ count + 1))
      .split('\n')
      .take(lines)
      .join('\n');
}

/// Fenced code: tokenizing, layout, recording, rasterizing and streaming, with
/// and without highlighting. Rasterizing is clamped to 4096 px of height.
Future<Map<String, Object?>> _measureCode(MarkdownThemeData base) async {
  // A new highlighter each time: one that is kept returns repeated code from
  // its cache, and this measures the first time a block is seen.
  MarkdownHighlighter highlighter() => MarkdownHighlighter(
        languages: allHighlightLanguages,
        theme: HighlightThemes.githubDark,
      );
  final themes = <String, MarkdownThemeData Function()>{
    'plain': () => base,
    'highlighted': () => base.copyWith(highlighter: highlighter()),
  };
  final out = <String, Object?>{};
  for (final lines in const <int>[30, 100, 500]) {
    final code = _codeLines(lines);
    final model = Markdown.fromString('```dart\n$code\n```\n');
    final row = <String, Object?>{
      'tokenize': _bench(
        () => highlighter().highlight(code, 'dart', const TextStyle()),
      ),
    };
    await _breathe();
    for (final MapEntry(key: name, value: newTheme) in themes.entries) {
      final build = <double>[], layout = <double>[], record = <double>[];
      final sw = Stopwatch();
      final until = Stopwatch()..start();
      while (until.elapsedMilliseconds < 800 || layout.length < 15) {
        sw
          ..reset()
          ..start();
        final painter = MarkdownPainter(markdown: model, theme: newTheme());
        build.add(sw.elapsedMicroseconds.toDouble());
        sw
          ..reset()
          ..start();
        final size = painter.layout(maxWidth: _kWidth);
        layout.add(sw.elapsedMicroseconds.toDouble());
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        sw
          ..reset()
          ..start();
        painter.paint(canvas, size);
        final picture = recorder.endRecording();
        record.add(sw.elapsedMicroseconds.toDouble());
        picture.dispose();
        painter.dispose();
      }
      await _breathe();

      final theme = newTheme();
      final painter = MarkdownPainter(markdown: model, theme: theme);
      final size = painter.layout(maxWidth: _kWidth);
      final recorder = ui.PictureRecorder();
      painter.paint(Canvas(recorder), size);
      final picture = recorder.endRecording();
      final raster = <double>[];
      for (var i = 0; i < 12; i++) {
        final watch = Stopwatch()..start();
        final image = await picture.toImage(
          size.width.ceil().clamp(1, 4096),
          size.height.ceil().clamp(1, 4096),
        );
        watch.stop();
        image.dispose();
        raster.add(watch.elapsedMicroseconds.toDouble());
      }
      picture.dispose();
      var odd = false;
      final relayout = _bench(() {
        painter.layout(maxWidth: (odd = !odd) ? _kWidth : _kWidth - 40);
      }, batches: 10);
      painter.dispose();
      await _breathe();

      // A fence still being written: the chunks over the last tenth of it.
      const chunk = 32;
      final stream = <double>[];
      for (var round = 0; round < 2; round++) {
        final streaming = MarkdownPainter(
          markdown: Markdown.fromString(''),
          theme: theme,
        );
        final tail = code.length * 9 ~/ 10;
        for (var end = chunk; end < code.length; end += chunk) {
          if (end < tail) {
            if (end + chunk < tail) continue;
          }
          final next = Markdown.fromString(
            '```dart\n${code.substring(0, end)}',
          );
          final watch = Stopwatch()..start();
          final s = (streaming..update(markdown: next, theme: theme))
              .layout(maxWidth: _kWidth);
          final r = ui.PictureRecorder();
          streaming.paint(Canvas(r), s);
          r.endRecording().dispose();
          watch.stop();
          if (end >= tail) stream.add(watch.elapsedMicroseconds.toDouble());
        }
        streaming.dispose();
        await _breathe();
      }
      row[name] = <String, Object?>{
        'build': _stats(build),
        'layout': _stats(layout),
        'record': _stats(record),
        'raster': _stats(raster),
        'relayout': relayout,
        'stream_chunk': _stats(stream),
        'height': size.height,
      };
    }
    out['$lines'] = row;
  }
  return out;
}

/// FrameTiming over flings through a feed of [lines]-line fences.
Future<Map<String, Object?>> _measureCodeScroll(
  WidgetTester tester,
  MarkdownThemeData theme,
  int lines,
) async {
  final model = Markdown.fromString(
    '```dart\n${_codeLines(lines)}\n```\n',
  );
  const key = ValueKey<String>('code-feed');
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: ListView.builder(
          key: key,
          itemCount: 40,
          itemBuilder: (context, i) => Padding(
            padding: const EdgeInsets.all(8),
            child: MarkdownWidget(markdown: model, theme: theme),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  final timings = <ui.FrameTiming>[];
  void collect(List<ui.FrameTiming> batch) => timings.addAll(batch);
  SchedulerBinding.instance.addTimingsCallback(collect);
  final list = find.byKey(key);
  for (var i = 0; i < 5; i++) {
    await tester.fling(list, const Offset(0, -600), 2000);
    await tester.pumpAndSettle();
    await tester.fling(list, const Offset(0, 600), 2000);
    await tester.pumpAndSettle();
  }
  await Future<void>.delayed(const Duration(milliseconds: 1200));
  SchedulerBinding.instance.removeTimingsCallback(collect);
  return <String, Object?>{
    'build': _stats(<double>[
      for (final t in timings) t.buildDuration.inMicroseconds.toDouble(),
    ]),
    'raster': _stats(<double>[
      for (final t in timings) t.rasterDuration.inMicroseconds.toDouble(),
    ]),
  };
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final report = <String, Object?>{};

  tearDownAll(() {
    final view = ui.PlatformDispatcher.instance.implicitView;
    report['environment'] = <String, Object?>{
      'kind': kProfileMode ? 'profile' : (kReleaseMode ? 'release' : 'debug'),
      'os': Platform.operatingSystem,
      'os_version': Platform.operatingSystemVersion,
      'processors': Platform.numberOfProcessors,
      'dpr': view?.devicePixelRatio,
      'view': '${view?.physicalSize.width}x${view?.physicalSize.height}',
      'dart': Platform.version,
      'max_rss': ProcessInfo.maxRss,
    };
    binding.reportData = report;
  });

  if (_suite == 'all' || _suite == 'stages') {
    testWidgets('stages', (tester) async {
      report['stages'] = await _measureStages(flutterMdTheme());
    }, timeout: const Timeout(Duration(minutes: 20)));
  }

  if (_suite == 'all' || _suite == 'code') {
    testWidgets('code', (tester) async {
      final base = flutterMdTheme();
      final code = await _measureCode(base);
      final highlighted = base.copyWith(
        highlighter: MarkdownHighlighter(
          languages: allHighlightLanguages,
          theme: HighlightThemes.githubDark,
        ),
      );
      for (final lines in const <int>[30, 300]) {
        code['scroll_plain_$lines'] =
            await _measureCodeScroll(tester, base, lines);
        code['scroll_highlighted_$lines'] =
            await _measureCodeScroll(tester, highlighted, lines);
      }
      report['code'] = code;
    }, timeout: const Timeout(Duration(minutes: 20)));
  }

  if (_suite == 'all' || _suite == 'parse') {
    testWidgets('parse', (tester) async {
      // Frames as in an app, not only on pump.
      binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
      await tester.runAsync(() async {
        report['parse'] = await _measureParse();
      });
    }, timeout: const Timeout(Duration(minutes: 20)));
  }

  if (_suite == 'all' || _suite == 'frames') {
    final frames = <String, Object?>{};
    report['frames'] = frames;
    for (final entry in styledLibraries.entries) {
      testWidgets('frames: ${entry.key}', (tester) async {
        frames[entry.key] =
            await _measureFrames(tester, entry.key, entry.value);
      }, timeout: const Timeout(Duration(minutes: 20)));
    }
  }

  if (_suite == 'all' || _suite == 'scroll') {
    final scroll = <String, Object?>{};
    report['scroll'] = scroll;
    for (final entry in styledLibraries.entries) {
      testWidgets('scroll: ${entry.key}', (tester) async {
        scroll[entry.key] = await _measureScroll(tester, entry.value);
      }, timeout: const Timeout(Duration(minutes: 10)));
    }
  }
}
