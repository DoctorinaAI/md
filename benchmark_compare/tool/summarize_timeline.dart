// ignore_for_file: avoid_print
//
// Formats the profile-mode scroll benchmark output into a comparison table.
//
// Reads build/integration_response_data.json (written by the flutter drive run,
// one TimelineSummary per library) and prints Markdown tables of frame build &
// rasterizer times (average / 90th / 99th percentile) plus missed-frame counts.
//
//   dart run tool/summarize_timeline.dart

import 'dart:convert';
import 'dart:io';

const String _kInput = 'build/integration_response_data.json';

// Report keys are 'scroll_<lib>' in feed order.
const List<String> _libs = <String>[
  'flutter_md',
  'flutter_markdown',
  'gpt_markdown',
];

double? _num(Map<String, dynamic> m, String key) {
  final v = m[key];
  if (v is num) return v.toDouble();
  return null;
}

String _cell(double? v) => v == null ? '-' : v.toStringAsFixed(2);

void main() {
  final file = File(_kInput);
  if (!file.existsSync()) {
    stderr.writeln('Not found: $_kInput\n'
        'Run the profile-mode benchmark first:\n'
        '  flutter drive --driver=test_driver/perf_driver.dart '
        '--target=integration_test/scroll_perf_test.dart --profile -d linux');
    exitCode = 1;
    return;
  }

  final data = json.decode(file.readAsStringSync()) as Map<String, dynamic>;
  final summaries = <String, Map<String, dynamic>>{};
  for (final lib in _libs) {
    final raw = data['scroll_$lib'];
    if (raw is Map<String, dynamic>) {
      summaries[lib] = raw;
    } else if (raw is String) {
      // Some driver versions store the summary JSON as a string.
      summaries[lib] = json.decode(raw) as Map<String, dynamic>;
    }
  }

  // Metrics to show: (label, json key, lower-is-better).
  const metrics = <List<String>>[
    ['frame build avg (ms)', 'average_frame_build_time_millis'],
    ['frame build 90th (ms)', '90th_percentile_frame_build_time_millis'],
    ['frame build 99th (ms)', '99th_percentile_frame_build_time_millis'],
    ['frame build worst (ms)', 'worst_frame_build_time_millis'],
    ['raster avg (ms)', 'average_frame_rasterizer_time_millis'],
    ['raster 90th (ms)', '90th_percentile_frame_rasterizer_time_millis'],
    ['raster 99th (ms)', '99th_percentile_frame_rasterizer_time_millis'],
    ['raster worst (ms)', 'worst_frame_rasterizer_time_millis'],
    ['missed build frames', 'missed_frame_build_budget_count'],
    ['missed raster frames', 'missed_frame_rasterizer_budget_count'],
    ['frame count', 'frame_count'],
  ];

  print('');
  print('Profile-mode scroll benchmark — real frame timings (lower is better)');
  print('');
  final header = StringBuffer('| metric                  |');
  final sep = StringBuffer('| ----------------------- |');
  for (final lib in _libs) {
    header.write(' ${lib.padLeft(16)} |');
    sep.write(' ---------------: |');
  }
  print(header);
  print(sep);
  for (final metric in metrics) {
    final row = StringBuffer('| ${metric[0].padRight(23)} |');
    for (final lib in _libs) {
      final s = summaries[lib];
      final v = s == null ? null : _num(s, metric[1]);
      row.write(' ${_cell(v).padLeft(16)} |');
    }
    print(row);
  }
  print('');

  // Relative build-time (the frame work each library asks of the UI thread),
  // normalized to flutter_md.
  final base = summaries['flutter_md'];
  final baseBuild =
      base == null ? null : _num(base, 'average_frame_build_time_millis');
  if (baseBuild != null && baseBuild > 0) {
    print('Average frame build time relative to flutter_md '
        '(x = library / flutter_md):');
    print('');
    print('| ${'flutter_md'.padLeft(16)} | '
        '${'flutter_markdown'.padLeft(16)} | ${'gpt_markdown'.padLeft(16)} |');
    print('| ---------------: | ---------------: | ---------------: |');
    final row = StringBuffer('|');
    for (final lib in _libs) {
      final s = summaries[lib];
      final v =
          s == null ? null : _num(s, 'average_frame_build_time_millis');
      final cell = v == null ? '-' : '${(v / baseBuild).toStringAsFixed(2)}x';
      row.write(' ${cell.padLeft(16)} |');
    }
    print(row);
    print('');
  }
}
