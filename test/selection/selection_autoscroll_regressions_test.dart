import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_md/flutter_md.dart';
import 'package:flutter_md/src/selection_autoscroll.dart'
    show markdownAutoscrollVelocity;
import 'package:flutter_test/flutter_test.dart';

class _Doc extends StatelessWidget {
  const _Doc(this.id);

  final String id;

  @override
  Widget build(BuildContext context) {
    final controller = MarkdownSelectionScope.of(context);
    final model = controller.documents.firstWhere((d) => d.id == id).model;
    return MarkdownWidget(markdown: model, documentId: id);
  }
}

Markdown _longDoc() => Markdown.fromString(
      List<String>.generate(60, (i) => 'line $i of the body').join(' '),
    );

Future<(MarkdownSelectionController, ScrollController)> _pumpList(
  WidgetTester tester,
) async {
  final selection = MarkdownSelectionController()
    ..setDocuments(<MarkdownDocumentRef>[
      MarkdownDocumentRef(id: 'd', model: _longDoc()),
    ]);
  addTearDown(selection.dispose);
  final scroll = ScrollController();
  addTearDown(scroll.dispose);
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: MarkdownSelectionScope(
        controller: selection,
        autoscroll: const MarkdownSelectionAutoscrollConfig(
          edgeZone: 40,
          maxVelocity: 600,
          useMediaQueryPadding: false,
        ),
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 400,
            height: 200,
            child: ListView(
              controller: scroll,
              children: const <Widget>[_Doc('d'), SizedBox(height: 3000)],
            ),
          ),
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
  return (selection, scroll);
}

void main() {
  group('Autoscroll regressions', () {
    test('edge bands never overlap past half the viewport', () {
      const config = MarkdownSelectionAutoscrollConfig(edgeZone: 48);
      // 60px clip; pointer at y=45 is 15px from bottom, 45px from top.
      final v = markdownAutoscrollVelocity(
        localY: 45,
        clipTopLocalY: 0,
        clipHeight: 60,
        config: config,
      );
      expect(v, greaterThanOrEqualTo(0), reason: 'got $v');
    });

    testWidgets('pointer cancel mid-drag stops autoscroll', (tester) async {
      final (_, scroll) = await _pumpList(tester);
      final viewport = tester.getRect(find.byType(Scrollable));
      final gesture = await tester.startGesture(
        viewport.topLeft + const Offset(10, 10),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump(const Duration(milliseconds: 20));
      await gesture.moveTo(Offset(viewport.center.dx, viewport.bottom - 2));
      await tester.pump(const Duration(milliseconds: 16));
      await gesture.cancel();
      await tester.pump(const Duration(milliseconds: 16));
      final atCancel = scroll.offset;
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(scroll.offset, atCancel,
          reason: 'kept scrolling after cancel: $atCancel -> ${scroll.offset}');
    });

    testWidgets('pointer event rate does not multiply scroll speed',
        (tester) async {
      final (_, scroll) = await _pumpList(tester);
      final viewport = tester.getRect(find.byType(Scrollable));
      final gesture = await tester.startGesture(
        viewport.topLeft + const Offset(10, 10),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump(const Duration(milliseconds: 20));
      await gesture.moveTo(Offset(viewport.center.dx, viewport.bottom - 2));
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      final a = scroll.offset;
      await tester.pump(const Duration(milliseconds: 16));
      final perFrame = scroll.offset - a;
      final b = scroll.offset;
      // 10 mouse moves inside one frame (a 1000 Hz mouse delivers ~16).
      for (var i = 0; i < 10; i++) {
        await gesture.moveBy(Offset(i.isEven ? 1 : -1, 0));
      }
      await tester.pump(const Duration(milliseconds: 16));
      final withMoves = scroll.offset - b;
      await gesture.up();
      await tester.pumpAndSettle();
      expect(withMoves, lessThan(perFrame * 2.5),
          reason: 'per frame $perFrame, with 10 moves $withMoves');
    });

    testWidgets('a horizontal inner scrollable is not driven by vertical band',
        (tester) async {
      final selection = MarkdownSelectionController()
        ..setDocuments(<MarkdownDocumentRef>[
          MarkdownDocumentRef(id: 'd', model: _longDoc()),
          MarkdownDocumentRef(id: 'e', model: _longDoc()),
        ]);
      addTearDown(selection.dispose);
      final outer = ScrollController();
      final inner = ScrollController();
      addTearDown(outer.dispose);
      addTearDown(inner.dispose);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MarkdownSelectionScope(
            controller: selection,
            autoscroll: const MarkdownSelectionAutoscrollConfig(
              edgeZone: 40,
              maxVelocity: 2000,
              useMediaQueryPadding: false,
            ),
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 400,
                height: 300,
                child: ListView(
                  controller: outer,
                  children: <Widget>[
                    SizedBox(
                      height: 300,
                      child: ListView(
                        controller: inner,
                        scrollDirection: Axis.horizontal,
                        children: const <Widget>[
                          SizedBox(width: 400, child: _Doc('d')),
                          SizedBox(width: 2000),
                        ],
                      ),
                    ),
                    const _Doc('e'),
                    const SizedBox(height: 3000),
                  ],
                ),
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      final viewport = tester.getRect(find.byType(Scrollable).first);
      final gesture = await tester.startGesture(
        viewport.topLeft + const Offset(10, 10),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump(const Duration(milliseconds: 20));
      await gesture.moveTo(Offset(100, viewport.bottom - 2));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pumpAndSettle();
      expect(inner.offset, 0, reason: 'inner horizontal moved ${inner.offset}');
      expect(outer.offset, greaterThan(0));
    });

    test('an infinite edge zone yields a finite velocity', () {
      const config = MarkdownSelectionAutoscrollConfig(
        edgeZone: double.infinity,
      );
      for (final y in <double>[0, 10, 30, 50, 60]) {
        final v = markdownAutoscrollVelocity(
          localY: y,
          clipTopLocalY: 0,
          clipHeight: 60,
          config: config,
        );
        expect(v.isFinite, isTrue, reason: 'y=$y gave $v');
      }
    });

    test('config equality covers every field', () {
      const a = MarkdownSelectionAutoscrollConfig();
      for (final b in <MarkdownSelectionAutoscrollConfig>[
        a.copyWith(enabled: false),
        a.copyWith(edgeZone: 1),
        a.copyWith(maxVelocity: 1),
        a.copyWith(topPad: 1),
        a.copyWith(bottomPad: 1),
        a.copyWith(useMediaQueryPadding: false),
        a.copyWith(useHostUnionGate: false),
        a.copyWith(targetResolver: (_) => null),
      ]) {
        expect(a == b, isFalse, reason: '$b');
      }
      expect(a.copyWith(), a);
      expect(a.copyWith().hashCode, a.hashCode);
    });

    testWidgets('disposing the scope mid-drag stops autoscroll',
        (tester) async {
      await _pumpList(tester);
      final r = tester.getRect(find.byType(Scrollable));
      final g = await tester.startGesture(
        r.topLeft + const Offset(10, 10),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump(const Duration(milliseconds: 20));
      await g.moveTo(Offset(r.center.dx, r.bottom - 2));
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
      await g.up();
    });
  });
}
