// SPIKE S2 — Custom MultiSelectable delegate: separators + snapshot-on-remove,
// and the STRUCTURAL LIMIT of the delegate approach for scrollables.
//
// Findings this file establishes:
//   S2.1 A StaticSelectionContainerDelegate subclass CAN insert block
//        separators between the selectables that register directly into it
//        (fixing the S1 glue defect) — in a NON-scrolling subtree.
//   S2.2 A stock Scrollable (ListView) interposes its OWN private
//        `_ScrollableSelectionContainerDelegate` (scrollable.dart:1157), so a
//        custom delegate placed ABOVE the ListView sees a single, already-glued
//        child and is powerless over per-item separators / ordering / disposal.
//        => the pure-delegate route is a dead end for the chat/lazy-list case.
//   S2.3 The snapshot-on-remove mechanism DOES retain a disposed child's text
//        (where the child registers directly into our delegate), but relies on
//        screen-Y keys that are not scroll-invariant — motivating the
//        controller's explicit registry order (S4).
//
// Throwaway spike; outside lib/ and test/.
// Run: flutter test benchmark/experiments/s2_custom_delegate_test.dart

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

class _Entry {
  _Entry(this.key, this.text);
  final double key;
  final String text;
}

class MdDelegate extends StaticSelectionContainerDelegate {
  MdDelegate({this.separator = '\n'});

  final String separator;
  final Map<Selectable, double> _lastTop = <Selectable, double>{};
  // Proactively cache each live child's content: at remove() time a dying
  // nested SelectionContainer already yields null, so we snapshot from here.
  final Map<Selectable, String> _lastContent = <Selectable, String>{};
  final List<_Entry> _snaps = <_Entry>[];

  int get liveChildCount => selectables.length;
  int get snapshotCount => _snaps.length;

  double _topOf(Selectable s) =>
      MatrixUtils.transformPoint(s.getTransformTo(null), Offset.zero).dy;

  @override
  void remove(Selectable selectable) {
    final cached = _lastContent[selectable];
    if (cached != null && cached.isNotEmpty) {
      _snaps.add(_Entry(_lastTop[selectable] ?? 0.0, cached));
    }
    _lastTop.remove(selectable);
    _lastContent.remove(selectable);
    super.remove(selectable);
  }

  @override
  SelectedContent? getSelectedContent() {
    final live = <_Entry>[];
    for (final s in selectables) {
      final content = s.getSelectedContent()?.plainText;
      if (content == null || content.isEmpty) continue;
      final top = _topOf(s);
      _lastTop[s] = top;
      _lastContent[s] = content;
      live.add(_Entry(top, content));
    }
    final entries = <_Entry>[...live];
    const eps = 1.0;
    for (final s in _snaps) {
      final coveredByLive = live.any((e) => (e.key - s.key).abs() < eps);
      if (!coveredByLive) entries.add(s);
    }
    if (entries.isEmpty) return null;
    entries.sort((a, b) => a.key.compareTo(b.key));
    return SelectedContent(
      plainText: entries.map((e) => e.text).join(separator),
    );
  }
}

Future<void> _dragSelect(WidgetTester tester, Finder from, Finder to) async {
  final start = tester.getTopLeft(from) + const Offset(1, 3);
  final end = tester.getBottomRight(to) - const Offset(1, 3);
  final g = await tester.startGesture(start, kind: PointerDeviceKind.mouse);
  await tester.pump(const Duration(milliseconds: 200));
  await g.moveTo(end);
  await tester.pump(const Duration(milliseconds: 200));
  await g.up();
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('S2.1 separators work in a NON-scrolling subtree',
      (tester) async {
    final delegate = MdDelegate();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SelectionArea(
          child: SelectionContainer(
            delegate: delegate,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[Text('Item0'), Text('Item1'), Text('Item2')],
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    await _dragSelect(tester, find.text('Item0'), find.text('Item2'));
    final text = delegate.getSelectedContent()?.plainText;
    debugPrint('S2.1 liveChildren=${delegate.liveChildCount} '
        'text=${text?.replaceAll('\n', r'\n')}');
    expect(delegate.liveChildCount, 3,
        reason: 'each Text registers directly into our delegate');
    expect(text, 'Item0\nItem1\nItem2'); // separators inserted
  });

  testWidgets(
      'S2.2 BLOCKER: a ListView hides its items behind its own container',
      (tester) async {
    final delegate = MdDelegate();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          height: 300,
          child: SelectionArea(
            child: SelectionContainer(
              delegate: delegate,
              child: ListView(
                children: const <Widget>[
                  SizedBox(height: 120, child: Text('Item0')),
                  SizedBox(height: 120, child: Text('Item1')),
                ],
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    await _dragSelect(tester, find.text('Item0'), find.text('Item1'));
    final text = delegate.getSelectedContent()?.plainText;
    debugPrint('S2.2 liveChildren=${delegate.liveChildCount} '
        'text=${text?.replaceAll('\n', r'\n')}');
    // The Scrollable interposes ONE aggregated child; our delegate can't split.
    expect(delegate.liveChildCount, 1,
        reason:
            'Scrollable._ScrollableSelectionContainerDelegate is the child');
    expect(text, 'Item0Item1',
        reason: 'gluing happened inside the private scrollable delegate, '
            'below us — the delegate route cannot fix the chat case');
  });

  testWidgets('S2.3 snapshot MECHANISM works when layout does not reflow',
      (tester) async {
    final delegate = MdDelegate();
    final result = await _removeWhileSelected(tester, delegate, removeIndex: 2);
    debugPrint('S2.3 snapshots=${delegate.snapshotCount} '
        'after=${result?.replaceAll('\n', r'\n')}');
    // Removing the LAST item: remaining items keep their Y, snapshot key
    // (>liveMax) splices cleanly. The mechanism retains the text.
    expect(delegate.snapshotCount, greaterThanOrEqualTo(1));
    expect(result, 'Item0\nItem1\nItem2');
  });

  testWidgets('S2.4 LIMIT: screen-Y snapshot key collides on reflow',
      (tester) async {
    final delegate = MdDelegate();
    final result = await _removeWhileSelected(tester, delegate, removeIndex: 1);
    debugPrint('S2.4 snapshots=${delegate.snapshotCount} '
        'after=${result?.replaceAll('\n', r'\n')}');
    // Removing the MIDDLE item: Item2 reflows UP into Item1's old Y, so the
    // snapshot's screen-Y key collides with a live child and is dropped —
    // Item1's retained text is LOST. Screen geometry is not a stable identity;
    // this is precisely why the controller (S4) anchors on an explicit
    // registry order over the immutable model instead.
    expect(result, 'Item0\nItem2', reason: 'DEFECT of the delegate approach');
    expect(result, isNot(contains('Item1')));
  });
}

/// Selects all three keyed Texts, then removes [removeIndex] while selected,
/// returning the delegate's assembled text afterwards.
Future<String?> _removeWhileSelected(
  WidgetTester tester,
  MdDelegate delegate, {
  required int removeIndex,
}) async {
  var items = <String>['Item0', 'Item1', 'Item2'];
  late StateSetter setOuter;
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: SelectionArea(
        child: SelectionContainer(
          delegate: delegate,
          child: StatefulBuilder(builder: (_, setState) {
            setOuter = setState;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                for (final s in items) Text(s, key: ValueKey<String>(s)),
              ],
            );
          }),
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();

  await _dragSelect(tester, find.text('Item0'), find.text('Item2'));
  expect(delegate.getSelectedContent()!.plainText, 'Item0\nItem1\nItem2');

  final removed = items[removeIndex];
  setOuter(() => items = List<String>.of(items)..removeAt(removeIndex));
  await tester.pumpAndSettle();
  expect(find.text(removed), findsNothing);

  return delegate.getSelectedContent()?.plainText;
}
