// ASYNC PARSE BENCHMARK — what parsing in slices costs and what it gives: the
// total time against the sync parse, and the longest pause it leaves the event
// loop with. The last row is the known limit: a block is never split.
//
//   dart compile exe benchmark/async_benchmark.dart -o /tmp/ab && /tmp/ab
//
// Pure Dart, so pauses are turns of the event loop; on-device numbers with real
// frames come from benchmark_compare (SUITE=parse).
import 'dart:async';

import 'package:flutter_md/src/markdown.dart' show Markdown;

const String _section = '''
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

const int _runs = 7;

/// The total microseconds of [body] and the longest gap between two turns of
/// the event loop while it ran.
Future<({int total, int gap})> _measure(Future<Object?> Function() body) async {
  var gap = 0;
  final sinceTurn = Stopwatch()..start();
  final timer = Timer.periodic(Duration.zero, (_) {
    if (sinceTurn.elapsedMicroseconds > gap) {
      gap = sinceTurn.elapsedMicroseconds;
    }
    sinceTurn.reset();
  });
  // Let the first turn come, so the gap measures the body alone.
  await Future<void>.delayed(Duration.zero);
  gap = 0;
  sinceTurn.reset();
  final total = Stopwatch()..start();
  await body();
  total.stop();
  await Future<void>.delayed(Duration.zero); // Ends a gap the body left open.
  timer.cancel();
  return (total: total.elapsedMicroseconds, gap: gap);
}

int _median(List<int> values) => (values..sort())[values.length ~/ 2];

String _ms(int micros) => (micros / 1000).toStringAsFixed(1).padLeft(9);

Future<void> main() async {
  final documents = <String, String>{
    for (final kb in const <int>[100, 1000, 5000])
      '$kb KB mixed': _section * (kb * 1024 ~/ _section.length),
    '1000 KB one paragraph': 'a **b** [c](d) ' * (1000 * 1024 ~/ 15),
  };
  // ignore: avoid_print
  print('${'document'.padRight(24)}${'sync ms'.padLeft(9)}'
      '${'gap ms'.padLeft(9)}${'async ms'.padLeft(9)}${'gap ms'.padLeft(9)}');
  for (final MapEntry(key: name, value: source) in documents.entries) {
    final sync = <({int total, int gap})>[];
    final sliced = <({int total, int gap})>[];
    for (var run = 0; run < _runs; run++) {
      sync.add(await _measure(() async => Markdown.fromString(source)));
      sliced.add(await _measure(() => Markdown.fromStringAsync(source)));
    }
    // ignore: avoid_print
    print('${name.padRight(24)}'
        '${_ms(_median([for (final s in sync) s.total]))}'
        '${_ms(_median([for (final s in sync) s.gap]))}'
        '${_ms(_median([for (final s in sliced) s.total]))}'
        '${_ms(_median([for (final s in sliced) s.gap]))}');
  }
}
