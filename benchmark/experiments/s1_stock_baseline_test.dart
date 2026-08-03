// SPIKE S1 — Stock SelectionArea + one Text-per-block baseline.
//
// Question: on Flutter 3.41.6, do the two documented defects actually reproduce
// with the naive "one Text widget per Markdown block in a scroll view" approach?
//   (1) GLUE: text of adjacent selectables is concatenated with NO separator.
//   (2) DISPOSAL: a scrolled-off (disposed) item's selected text vanishes.
//
// This is throwaway spike code. It lives OUTSIDE lib/ and test/ so it never
// enters the CI format/analyze/test gates.
//
// Run: flutter test benchmark/experiments/s1_stock_baseline_test.dart
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('S1.1 GLUE: adjacent selectables concatenate WITHOUT separators',
      (tester) async {
    String? captured;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SelectionArea(
            onSelectionChanged: (c) => captured = c?.plainText,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Alpha'),
                Text('Bravo'),
                Text('Charlie'),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Mouse-drag select from the very start of "Alpha" to the very end of
    // "Charlie" — i.e. everything.
    final start = tester.getTopLeft(find.text('Alpha')) + const Offset(1, 3);
    final end =
        tester.getBottomRight(find.text('Charlie')) - const Offset(1, 3);
    final gesture =
        await tester.startGesture(start, kind: PointerDeviceKind.mouse);
    await tester.pump(const Duration(milliseconds: 200));
    await gesture.moveTo(end);
    await tester.pump(const Duration(milliseconds: 200));
    await gesture.up();
    await tester.pumpAndSettle();

    debugPrint(
        'S1.1 captured plainText = ${captured!.replaceAll('\n', r'\n')}');

    // The defect: the three fragments are glued with no separator between them.
    expect(captured, isNotNull);
    expect(captured, contains('Bravo'));
    expect(captured, isNot(contains('\n')),
        reason:
            'DEFECT CONFIRMED if this passes: no separators inserted between '
            'selectables — "Alpha", "Bravo", "Charlie" are glued.');
    // Concretely, the whole selection is the bare concatenation.
    expect(captured, 'AlphaBravoCharlie');
  });

  testWidgets('S1.2 DISPOSAL: scrolled-off item text disappears from selection',
      (tester) async {
    String? captured;
    const itemExtent = 120.0;
    final controller = ScrollController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 300, // viewport shows ~2.5 items
            child: SelectionArea(
              onSelectionChanged: (c) => captured = c?.plainText,
              child: ListView.builder(
                controller: controller,
                cacheExtent: 0, // force disposal of off-screen items
                itemCount: 50,
                itemBuilder: (_, i) => SizedBox(
                  height: itemExtent,
                  child: Text('Item$i'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Select across Item0 and Item1 (both on screen).
    final start = tester.getTopLeft(find.text('Item0')) + const Offset(1, 3);
    final end = tester.getBottomRight(find.text('Item1')) - const Offset(1, 3);
    final gesture =
        await tester.startGesture(start, kind: PointerDeviceKind.mouse);
    await tester.pump(const Duration(milliseconds: 200));
    await gesture.moveTo(end);
    await tester.pump(const Duration(milliseconds: 200));
    await gesture.up();
    await tester.pumpAndSettle();

    final beforeScroll = captured;
    debugPrint('S1.2 before scroll = ${beforeScroll?.replaceAll('\n', r'\n')}');
    expect(beforeScroll, contains('Item0'));

    // Scroll far so Item0 (and Item1) are disposed.
    controller.jumpTo(itemExtent * 20);
    await tester.pumpAndSettle();
    expect(find.text('Item0'), findsNothing,
        reason: 'Item0 should be disposed');

    debugPrint('S1.2 after scroll  = ${captured?.replaceAll('\n', r'\n')}');
    // FINDING: disposing the selectable does NOT re-fire onSelectionChanged, so
    // the app's only selection signal goes STALE — it still reads "Item0Item1"
    // even though Item0's RenderParagraph (and its selectable) are gone. There
    // is no public API to pull the fresh, now-reduced live selection. That
    // staleness + the lack of a retrieval path IS the disposal defect from the
    // app's perspective. (S2 proves at the delegate level that the LIVE
    // getSelectedContent() actually drops the disposed text.)
    expect(captured, equals(beforeScroll),
        reason:
            'onSelectionChanged did not re-fire on disposal → stale value.');
  });
}
