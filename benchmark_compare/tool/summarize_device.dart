// Turns the output of tool/device_bench.sh into the tables of
// docs/benchmarks.md. Runs are named <device>-<variant>-<round>; every number is
// the median over the rounds of that run's own median.
//
//   dart run tool/summarize_device.dart results/2026-10-30
//
// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

typedef Json = Map<String, dynamic>;

const _stages = <String>['parse', 'build', 'layout', 'record', 'relayout'];

double _median(Iterable<num> values) {
  final s = values.toList()..sort();
  final mid = s.length ~/ 2;
  return s.length.isOdd ? s[mid].toDouble() : (s[mid - 1] + s[mid]) / 2;
}

num _at(Json run, List<String> path) {
  Object? node = run;
  for (final key in path) {
    node = (node! as Json)[key];
  }
  return node! as num;
}

double _m(List<Json> runs, List<String> path) =>
    _median(runs.map((r) => _at(r, path)));

String _ms(num us) => (us / 1000).toStringAsFixed(2);

void main(List<String> args) {
  final dir = Directory(args.single);
  final runs = <String, Map<String, List<Json>>>{};
  final name = RegExp(r'^(.+)-(base|new)-\d+\.device\.json$');
  for (final file in dir.listSync().whereType<File>()) {
    final match = name.firstMatch(file.uri.pathSegments.last);
    if (match == null) continue;
    ((runs[match[1]!] ??= {})[match[2]!] ??= <Json>[])
        .add(jsonDecode(file.readAsStringSync()) as Json);
  }
  for (final MapEntry(key: device, value: variants) in runs.entries) {
    final base = variants['base']!, now = variants['new']!;
    final docs = (now.first['stages'] as Json).keys.where((k) => k != 'stream');
    print('\n#### $device: pipeline stages, before → after (µs)\n');
    print('| document | ${_stages.join(' | ')} |');
    print('| --- |${' ---: |' * _stages.length}');
    for (final doc in docs) {
      final cells = [
        for (final s in _stages)
          '${_m(base, ['stages', doc, s, 'p50']).round()} → '
              '${_m(now, ['stages', doc, s, 'p50']).round()}',
      ];
      print('| $doc | ${cells.join(' | ')} |');
    }
    print('\nStreamed chunk (µs): ${[
      for (final q in ['p50', 'p90', 'p99'])
        '$q ${_m(base, ['stages', 'stream', 'chunk', q]).round()} → '
            '${_m(now, ['stages', 'stream', 'chunk', q]).round()}',
    ].join(', ')}');

    final libs = (now.first['frames'] as Json).keys.toList();
    print('\n#### $device: first frame of a message, after (ms, build / raster)\n');
    print('| document | ${libs.join(' | ')} |');
    print('| --- |${' ---: |' * libs.length}');
    for (final doc in ((now.first['frames'] as Json)[libs.first] as Json).keys) {
      final cells = [
        for (final lib in libs)
          '${_ms(_m(now, ['frames', lib, doc, 'build', 'p50']))} / '
              '${_ms(_m(now, ['frames', lib, doc, 'raster', 'p50']))}',
      ];
      print('| $doc | ${cells.join(' | ')} |');
    }

    print('\n#### $device: scrolling a feed, after (ms)\n');
    print('| library | build p50 | build p99 | raster p50 | raster p99 | '
        'worst frame | over 16.7 ms |');
    print('| --- | ---: | ---: | ---: | ---: | ---: | ---: |');
    for (final lib in libs) {
      List<String> p(String a, String q) => ['scroll', lib, a, q];
      final worst = [
        _m(now, p('build', 'max')),
        _m(now, p('raster', 'max')),
      ].reduce((a, b) => a > b ? a : b);
      final missed = _m(now, ['scroll', lib, 'missed_build']) +
          _m(now, ['scroll', lib, 'missed_raster']);
      print('| $lib | ${_ms(_m(now, p('build', 'p50')))} | '
          '${_ms(_m(now, p('build', 'p99')))} | '
          '${_ms(_m(now, p('raster', 'p50')))} | '
          '${_ms(_m(now, p('raster', 'p99')))} | ${_ms(worst)} | $missed |');
    }
  }
}
