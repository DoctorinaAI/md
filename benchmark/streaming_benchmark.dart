// ignore_for_file: avoid_print

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:flutter_md/src/markdown.dart' show Markdown;
import 'package:flutter_md/src/parser.dart' show StreamingMarkdownParser;

import 'scenarios.dart';

/// Streaming benchmark: replays a document token-by-token and compares the two
/// ways of keeping a parsed [Markdown] up to date on every token.
///
/// - **full**   — what a naive chat UI does today: re-parse the *entire*
///   accumulated buffer on every token (`Markdown.fromString(buffer)`), which
///   is `O(N²)` over a stream.
/// - **stream** — feed each token to a [StreamingMarkdownParser], which freezes
///   completed blocks and only re-parses the live tail.
///
/// Each `measure()` replays the whole stream once, so the reported µs is the
/// cost of rendering one full message start-to-finish. The batch decoder is
/// byte-identical to `master` (this file adds no code to the hot path), so the
/// separate `parser_benchmark.dart` numbers are the regression guard; this file
/// shows the incremental win.
///
/// Run:
/// ```shell
/// dart run benchmark/streaming_benchmark.dart
/// # or, for stable numbers:
/// dart compile exe benchmark/streaming_benchmark.dart -o /tmp/sb && /tmp/sb
/// ```
void main() {
  final docs = <String, String>{
    'prose': scenarios['prose']!,
    'lists': scenarios['lists']!,
    'table': scenarios['table']!,
    'code': scenarios['code']!,
    'quotes': scenarios['quotes']!,
    'mixed': scenarios['mixed']!,
    'big-chat': _bigChat(80),
  };

  print('Replaying each document token-by-token (one full stream per op).');
  print('');
  print('scenario   tokens  chars   full ms   stream ms   speedup');
  print('---------  ------  ------  --------  ----------  --------');
  for (final entry in docs.entries) {
    final doc = entry.value;
    final tokens = _tokenize(doc);
    final full = _FullReparse(tokens).measure(); // us per full replay
    final stream = _Streaming(tokens).measure(); // us per full replay
    final speedup = full / stream;
    print('${entry.key.padRight(9)}  '
        '${tokens.length.toString().padLeft(6)}  '
        '${doc.length.toString().padLeft(6)}  '
        '${(full / 1000).toStringAsFixed(2).padLeft(8)}  '
        '${(stream / 1000).toStringAsFixed(2).padLeft(10)}  '
        '${'${speedup.toStringAsFixed(2)}x'.padLeft(8)}');
  }
  print('');
  print('Equivalence is proven in test/parser/streaming_test.dart — the stream '
      'result matches Markdown.fromString at every prefix.');
}

/// Splits [doc] into word-ish tokens that reconstruct it exactly, approximating
/// how an LLM streams sub-word/word tokens (whitespace rides along).
List<String> _tokenize(String doc) {
  final parts = doc.split(' ');
  return <String>[
    for (var i = 0; i < parts.length; i++) i == 0 ? parts[i] : ' ${parts[i]}',
  ];
}

/// Re-parses the whole accumulated buffer on every token (the `O(N²)` path).
class _FullReparse extends BenchmarkBase {
  _FullReparse(this.tokens) : super('full');

  final List<String> tokens;
  Markdown? _result;

  @override
  void run() {
    final buffer = StringBuffer();
    for (final token in tokens) {
      buffer.write(token);
      _result = Markdown.fromString(buffer.toString());
    }
  }

  @override
  void teardown() {
    super.teardown();
    if (_result == null) throw StateError('result is null');
  }
}

/// Feeds each token to a [StreamingMarkdownParser] (the incremental path).
class _Streaming extends BenchmarkBase {
  _Streaming(this.tokens) : super('stream');

  final List<String> tokens;
  Markdown? _result;

  @override
  void run() {
    final parser = StreamingMarkdownParser();
    for (final token in tokens) {
      _result = parser.add(token);
    }
  }

  @override
  void teardown() {
    super.teardown();
    if (_result == null) throw StateError('result is null');
  }
}

/// Builds a long, blank-separated chat message with [blocks] varied blocks, so
/// the incremental parser has plenty of completed blocks to freeze.
String _bigChat(int blocks) {
  final buffer = StringBuffer();
  for (var i = 0; i < blocks; i++) {
    switch (i % 5) {
      case 0:
        buffer.write('## Section $i\n\n');
      case 1:
        buffer.write('A paragraph with **bold**, _italic_ and `code` number '
            '$i to give the inline parser some real work to do.\n\n');
      case 2:
        buffer.write('- item ${i}a\n- item ${i}b\n- item ${i}c\n\n');
      case 3:
        buffer.write('| Col | Val |\n| --- | --: |\n'
            '| a | $i |\n| b | ${i + 1} |\n\n');
      case 4:
        buffer.write('```dart\nfinal x$i = $i;\nprint(x$i);\n```\n\n');
    }
  }
  return buffer.toString();
}
