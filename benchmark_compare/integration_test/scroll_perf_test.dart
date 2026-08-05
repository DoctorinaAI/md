// PROFILE-MODE SCROLL BENCHMARK
// flutter_md vs flutter_markdown vs gpt_markdown.
//
// The widget-test render benchmark (test/render_benchmark_test.dart) measures
// wall-clock around `tester.pump()` in the *headless* flutter_tester engine,
// which carries a fixed ~1 ms per-frame floor and does no real GPU raster.
// This test confirms those results on a **real device in profile mode**: it
// scrolls a feed of Markdown "messages" per library, capturing a
// TimelineSummary
// (the same data DevTools' Performance timeline shows) — real frame *build* and
// *rasterizer* times, with 90th/99th percentiles and missed-frame counts.
//
// Run:
//   flutter drive \
//     --driver=test_driver/perf_driver.dart \
//     --target=integration_test/scroll_perf_test.dart \
//     --profile -d linux
//
// The per-library summaries are written to build/integration_response_data.json
// by the driver; tool/summarize_timeline.dart formats them into a table.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:md_benchmark_compare/corpus.dart';
import 'package:md_benchmark_compare/styles.dart';

// All three libraries use the shared normalized styles from lib/styles.dart, so
// the feed renders at the same layout density for every library.
final Map<String, StyledFactory> _libraries = styledLibraries;

// Feed mode: 'mixed' (representative chat feed) or 'prose' (one prose doc
// repeated). The 'prose' feed is a control: with normalized styles the `inline`
// doc renders to near-identical height in all three libraries (294/294/296 px)
// and has no structural chrome, so any raster difference on it is due purely to
// the rendering model (single cached ui.Picture vs a widget tree), not layout
// density or code/table/list chrome.
const String _feedMode =
    String.fromEnvironment('FEED', defaultValue: 'mixed');

/// A realistic chat feed: representative documents, cycled. Excludes the huge
/// `complex_large` tier so many messages fit in a scrollable list.
final List<String> _feed = _feedMode == 'prose'
    ? <String>[corpus['inline']!]
    : <String>[
        corpus['simple']!,
        corpus['inline']!,
        corpus['quotes']!,
        corpus['lists']!,
        corpus['code']!,
        corpus['table']!,
        corpus['complex']!,
      ];

const int _feedLength = 60;

const Key _feedKey = ValueKey<String>('feed');

// Item sizing mode: 'natural' (each item its own height) or 'fixed' (every item
// clipped to a constant height, so a fling of the same distance crosses the
// same number of items for every library — this controls for the fact that a
// more compact renderer packs more items per screen and therefore rasterizes
// more of them per unit scroll).
const String _itemMode =
    String.fromEnvironment('ITEM_MODE', defaultValue: 'natural');
const double _kFixedItemHeight = 320;

Widget _sizeItem(Widget child) {
  if (_itemMode != 'fixed') return child;
  return SizedBox(
    height: _kFixedItemHeight,
    child: ClipRect(
      child: OverflowBox(
        alignment: Alignment.topLeft,
        minHeight: 0,
        maxHeight: double.infinity,
        child: child,
      ),
    ),
  );
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  for (final entry in _libraries.entries) {
    final lib = entry.key;
    final factory = entry.value;

    testWidgets('scroll perf: $lib', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: ListView.builder(
              key: _feedKey,
              itemCount: _feedLength,
              itemBuilder: (context, i) => Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: _sizeItem(factory(context, _feed[i % _feed.length])),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final listFinder = find.byKey(_feedKey);

      // Trace a series of flings (down then back up) — this builds, lays out
      // and rasterizes many items, exercising the real frame pipeline.
      await binding.watchPerformance(
        () async {
          for (var i = 0; i < 6; i++) {
            await tester.fling(listFinder, const Offset(0, -600), 2000);
            await tester.pumpAndSettle();
            await tester.fling(listFinder, const Offset(0, 600), 2000);
            await tester.pumpAndSettle();
          }
        },
        reportKey: 'scroll_$lib',
      );
    });
  }
}
