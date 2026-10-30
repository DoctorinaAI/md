// CODE BENCHMARK — what a fenced code block costs, with and without syntax
// highlighting: tokenizing, layout, first paint and streaming a fence.
//
//   flutter test benchmark/code_benchmark.dart
//
// Timings are RELATIVE (headless engine); on-device numbers come from
// benchmark_compare/integration_test/device_bench_test.dart.
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_md/flutter_md.dart';
import 'package:flutter_md/highlight.dart';
import 'package:flutter_md/highlight/all.dart';
import 'package:flutter_md/highlight/themes.dart';
import 'package:flutter_md/src/render.dart' show MarkdownPainter;
import 'package:flutter_test/flutter_test.dart';

const double _width = 600;

final MarkdownHighlighter _highlighter = MarkdownHighlighter(
  languages: allHighlightLanguages,
  theme: HighlightThemes.githubDark,
);

MarkdownThemeData _theme({bool highlight = false}) => MarkdownThemeData(
      textStyle: const TextStyle(fontSize: 14, color: Color(0xFF000000)),
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.noScaling,
      highlighter: highlight ? _highlighter : null,
    );

const Map<String, String> _samples = <String, String>{
  'dart': r'''
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
''',
  'python': r'''
@dataclass
class Order:
    """An order with its line items."""
    id: int
    items: list[str] = field(default_factory=list)

    def total(self, rate: float = 0.2) -> float:
        # Tax is applied per item.
        return sum(price(i) * (1 + rate) for i in self.items if i != "free")

print(f"Order {order.id}: {order.total():.2f}")
''',
  'javascript': r'''
export async function load(url, { retries = 3, signal } = {}) {
  // Exponential backoff between the attempts.
  for (let i = 0; i < retries; i++) {
    const res = await fetch(`${url}?attempt=${i}`, { signal });
    if (res.ok) return res.json().then((d) => d.items.map(({ id }) => id));
    await new Promise((r) => setTimeout(r, 2 ** i * 100));
  }
  throw new Error("failed: " + url);
}
''',
  'json': r'''
{
  "name": "flutter_md", "version": "0.3.1", "private": false,
  "dependencies": { "meta": "^1.9.0", "flutter": null },
  "scores": [1, 2.5, -3e4, true], "nested": { "a": { "b": { "c": [] } } }
}
''',
  'bash': r'''
#!/usr/bin/env bash
set -euo pipefail
for f in "$@"; do
  if [[ -f "$f" ]]; then
    echo "size of $f: $(wc -c < "$f")" | tee -a "${LOG:-/tmp/log}" # Report it.
  fi
done
''',
};

String _lines(String language, int lines) {
  final sample = _samples[language]!;
  final count = sample.split('\n').length - 1;
  return (sample * (lines ~/ count + 1)).split('\n').take(lines).join('\n');
}

/// The median microseconds of [body], over [runs] runs.
int _median(void Function() body, {int runs = 15}) {
  final times = <int>[];
  final sw = Stopwatch();
  for (var i = 0; i < runs; i++) {
    sw
      ..reset()
      ..start();
    body();
    times.add(sw.elapsedMicroseconds);
  }
  times.sort();
  return times[times.length ~/ 2];
}

void _report(String name, int us) =>
    // ignore: avoid_print
    print(
        '${name.padRight(40)} ${(us / 1000).toStringAsFixed(2).padLeft(9)} ms');

MarkdownPainter _painter(MarkdownThemeData theme, Markdown markdown) =>
    MarkdownPainter(markdown: markdown, theme: theme);

void _paint(MarkdownPainter painter, Size size) {
  final recorder = ui.PictureRecorder();
  painter.paint(Canvas(recorder), size);
  recorder.endRecording().dispose();
}

void main() {
  test('tokenize', () {
    const base = TextStyle(fontSize: 14);
    for (final language in _samples.keys) {
      for (final lines in const <int>[50, 500, 5000]) {
        final code = _lines(language, lines);
        _report(
          'tokenize $language $lines lines',
          _median(
            () => _highlighter.highlight(code, language, base),
            runs: lines > 1000 ? 5 : 15,
          ),
        );
      }
    }
  });

  test('first layout and paint', () {
    for (final lines in const <int>[50, 500, 5000]) {
      final markdown =
          Markdown.fromString('```dart\n${_lines('dart', lines)}\n```\n');
      for (final highlight in const <bool>[false, true]) {
        final theme = _theme(highlight: highlight);
        final name = '${highlight ? 'highlighted' : 'plain'} $lines lines';
        final runs = lines > 1000 ? 5 : 15;
        _report(
          'build + layout $name',
          _median(() {
            _painter(theme, markdown)
              ..layout(maxWidth: _width)
              ..dispose();
          }, runs: runs),
        );
        final painter = _painter(theme, markdown);
        final size = Size(_width, painter.layout(maxWidth: _width).height);
        _report(
            'paint $name',
            _median(() {
              painter.invalidateLayout();
              painter.layout(maxWidth: _width);
              _paint(painter, size);
            }, runs: runs));
        painter.dispose();
      }
    }
  });

  test('stream a fence', () {
    for (final lines in const <int>[50, 500]) {
      final code = _lines('dart', lines);
      for (final highlight in const <bool>[false, true]) {
        final theme = _theme(highlight: highlight);
        const chunk = 16;
        final painter = _painter(theme, Markdown.fromString(''));
        final times = <int>[];
        final sw = Stopwatch();
        for (var end = chunk; end < code.length; end += chunk) {
          final markdown =
              Markdown.fromString('```dart\n${code.substring(0, end)}');
          sw
            ..reset()
            ..start();
          painter
            ..update(markdown: markdown, theme: theme)
            ..layout(maxWidth: _width);
          _paint(painter, Size(_width, painter.size.height));
          times.add(sw.elapsedMicroseconds);
        }
        painter.dispose();
        final last = times.sublist(times.length - 20)..sort();
        final name = '${highlight ? 'highlighted' : 'plain'} $lines lines';
        _report('stream chunk at the end, $name', last[last.length ~/ 2]);
        _report(
          'stream total, $name (${times.length} chunks)',
          times.reduce((a, b) => a + b),
        );
      }
    }
  });

  test('one long line', () {
    final json =
        '[${List<String>.generate(20000, (i) => '{"id":$i}').join(',')}]';
    final markdown = Markdown.fromString('```json\n$json\n```\n');
    for (final highlight in const <bool>[false, true]) {
      final theme = _theme(highlight: highlight);
      _report(
        'long line ${json.length} chars, '
        '${highlight ? 'highlighted' : 'plain'}',
        _median(() {
          _painter(theme, markdown)
            ..layout(maxWidth: _width)
            ..dispose();
        }, runs: 5),
      );
    }
  });
}
