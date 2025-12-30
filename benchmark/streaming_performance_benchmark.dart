// ignore_for_file: avoid_print

import 'package:flutter_md/src/parser.dart';

/// Benchmark comparing MarkdownDecoder vs StreamingMarkdownDecoder
/// for streaming scenarios.
void main() {
  print('='.padRight(80, '='));
  print('Streaming Markdown Decoder Performance Benchmark');
  print('='.padRight(80, '='));
  print('');

  // Test with different content sizes
  final smallContent = _generateMarkdownContent(lines: 50);
  final mediumContent = _generateMarkdownContent(lines: 200);
  final largeContent = _generateMarkdownContent(lines: 500);

  print('Test Content Sizes:');
  print('  Small:  ${smallContent.length} chars, ~50 lines');
  print('  Medium: ${mediumContent.length} chars, ~200 lines');
  print('  Large:  ${largeContent.length} chars, ~500 lines');
  print('');

  // Run benchmarks
  _runBenchmark('Small Content (50 lines)', smallContent, chunkSize: 5);
  print('');

  _runBenchmark('Medium Content (200 lines)', mediumContent, chunkSize: 10);
  print('');

  _runBenchmark('Large Content (500 lines)', largeContent, chunkSize: 15);
  print('');

  print('='.padRight(80, '='));
  print('Summary:');
  print('  StreamingMarkdownDecoder is optimized for incremental parsing');
  print('  and should show significant performance gains as content grows.');
  print('='.padRight(80, '='));
}

/// Runs a benchmark comparing both decoders.
void _runBenchmark(String name, String content, {int chunkSize = 10}) {
  print('$name (chunk size: $chunkSize chars)');
  print('-'.padRight(80, '-'));

  // Simulate streaming chunks
  final chunks = _splitIntoChunks(content, chunkSize);
  print('Total chunks: ${chunks.length}');
  print('');

  // Benchmark 1: MarkdownDecoder (full re-parse each time)
  final batch = _benchmarkBatchDecoder(chunks);

  // Benchmark 2: StreamingMarkdownDecoder (incremental)
  final streaming = _benchmarkStreamingDecoder(chunks);

  // Results
  print('Results:');
  print('  MarkdownDecoder:');
  print('    Total time:        ${batch.totalTime.inMilliseconds}ms');
  print('    Parse count:       ${batch.parseCount}');
  print(
      '    Avg per parse:     '
      '${batch.avgTimePerParse.inMicroseconds}µs');
  print('    Final blocks:      ${batch.finalBlockCount}');
  print('');
  print('  StreamingMarkdownDecoder:');
  print('    Total time:        ${streaming.totalTime.inMilliseconds}ms');
  print('    Parse count:       ${streaming.parseCount}');
  print(
      '    Avg per parse:     '
      '${streaming.avgTimePerParse.inMicroseconds}µs');
  print('    Final blocks:      ${streaming.finalBlockCount}');
  print('    Lines parsed:      ${streaming.totalLinesParsed}');
  print(
      '    Avg lines/parse:   '
      '${streaming.avgLinesPerParse.toStringAsFixed(1)}');
  print('');
  print('  Performance Gain:');
  final speedup = batch.totalTime.inMicroseconds /
      streaming.totalTime.inMicroseconds;
  print('    Speedup:           ${speedup.toStringAsFixed(2)}x faster');
  final timeSaved = batch.totalTime - streaming.totalTime;
  print('    Time saved:        ${timeSaved.inMilliseconds}ms');
  print('');
}

/// Benchmark result data.
class BenchmarkResult {
  const BenchmarkResult({
    required this.totalTime,
    required this.parseCount,
    required this.finalBlockCount,
    this.totalLinesParsed = 0,
  });

  final Duration totalTime;
  final int parseCount;
  final int finalBlockCount;
  final int totalLinesParsed;

  Duration get avgTimePerParse => Duration(
        microseconds: totalTime.inMicroseconds ~/ parseCount,
      );

  double get avgLinesPerParse =>
      totalLinesParsed > 0 ? totalLinesParsed / parseCount : 0;
}

/// Benchmark MarkdownDecoder (re-parses entire content each time).
BenchmarkResult _benchmarkBatchDecoder(List<String> chunks) {
  final stopwatch = Stopwatch()..start();
  var accumulated = '';
  var parseCount = 0;
  var finalBlockCount = 0;

  for (final chunk in chunks) {
    accumulated += chunk;
    final result = markdownDecoder.convert(accumulated);
    parseCount++;
    finalBlockCount = result.blocks.length;
  }

  stopwatch.stop();

  return BenchmarkResult(
    totalTime: stopwatch.elapsed,
    parseCount: parseCount,
    finalBlockCount: finalBlockCount,
  );
}

/// Benchmark StreamingMarkdownDecoder (incremental parsing).
BenchmarkResult _benchmarkStreamingDecoder(List<String> chunks) {
  final decoder = StreamingMarkdownDecoder();
  final stopwatch = Stopwatch()..start();
  var parseCount = 0;
  var finalBlockCount = 0;
  var totalLinesParsed = 0;

  for (final chunk in chunks) {
    final beforeOpenIndex = decoder.firstOpenIndex;

    decoder.append(chunk);

    final afterLines = decoder.lineCount;
    final linesInThisParse = afterLines - beforeOpenIndex;
    totalLinesParsed += linesInThisParse;

    parseCount++;
    finalBlockCount = decoder.blocks.length;
  }

  stopwatch.stop();

  return BenchmarkResult(
    totalTime: stopwatch.elapsed,
    parseCount: parseCount,
    finalBlockCount: finalBlockCount,
    totalLinesParsed: totalLinesParsed,
  );
}

/// Splits content into chunks of specified size.
List<String> _splitIntoChunks(String content, int chunkSize) {
  final chunks = <String>[];
  for (var i = 0; i < content.length; i += chunkSize) {
    final end = (i + chunkSize).clamp(0, content.length);
    chunks.add(content.substring(i, end));
  }
  return chunks;
}

/// Generates markdown content for testing.
String _generateMarkdownContent({required int lines}) {
  final buffer = StringBuffer();

  buffer.writeln('# Benchmark Test Document');
  buffer.writeln('');
  buffer.writeln('This document is generated for performance testing.');
  buffer.writeln('');

  var lineCount = 4; // Already written 4 lines above

  // Add headings
  for (var i = 1; lineCount < lines && i <= 6; i++) {
    buffer.writeln('${'#' * i} Heading Level $i');
    lineCount++;
  }

  buffer.writeln('');
  lineCount++;

  // Add paragraphs
  while (lineCount < lines - 100) {
    buffer.writeln(
      'This is a paragraph with **bold**, *italic*, and `code` formatting. '
      'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
    );
    buffer.writeln('');
    lineCount += 2;
  }

  // Add code block
  if (lineCount < lines - 50) {
    buffer.writeln('```dart');
    lineCount++;
    while (lineCount < lines - 40) {
      buffer.writeln('void function$lineCount() {');
      buffer.writeln('  print("Line $lineCount");');
      buffer.writeln('}');
      lineCount += 3;
    }
    buffer.writeln('```');
    buffer.writeln('');
    lineCount += 2;
  }

  // Add list
  if (lineCount < lines - 20) {
    buffer.writeln('## List Items');
    lineCount++;
    var itemNum = 1;
    while (lineCount < lines - 10) {
      buffer.writeln('- Item $itemNum');
      lineCount++;
      itemNum++;
    }
    buffer.writeln('');
    lineCount++;
  }

  // Add table
  if (lineCount < lines - 5) {
    buffer.writeln('| Column A | Column B | Column C |');
    buffer.writeln('|----------|----------|----------|');
    lineCount += 2;
    while (lineCount < lines) {
      buffer.writeln(
          '| Value A$lineCount | Value B$lineCount | Value C$lineCount |');
      lineCount++;
    }
  }

  return buffer.toString();
}
