// Coverage for controller paths that the scenario suites do not reach:
// endpoint geometry queries, coincident handle carets, collapse avoidance on
// a collapsed drag, registry validation, unregistered-document ordering and
// the lower-level autoscroll helpers.
import 'package:flutter/material.dart';
import 'package:flutter_md/flutter_md.dart';
import 'package:flutter_md/src/selection_autoscroll.dart'
    show
        MarkdownAutoscrollResult,
        MarkdownAutoscrollSession,
        applyMarkdownSelectionAutoscroll,
        markdownAutoscrollDepthFraction,
        resolveMarkdownScrollableAutoscrollTarget;
import 'package:flutter_test/flutter_test.dart';

/// A scriptable surface: geometry and hit results are plain fields.
class _Surface implements MarkdownSelectionSurface {
  _Surface(this.documentId, {this.bounds = Rect.zero});

  @override
  final Object documentId;

  /// Global bounds of the surface.
  Rect bounds;

  /// Result of [hitForGlobal] for any point.
  (MarkdownPosition, TextAffinity)? hit;

  /// Whether [isLinkAtGlobal] reports a link inside [bounds].
  bool link = false;

  /// Local caret rect per position; null when unset.
  Rect? Function(MarkdownPosition position)? caret;

  /// Local selection rects returned by [localSelectionRects].
  List<Rect> locals = const <Rect>[];

  @override
  TextDirection textDirection = TextDirection.ltr;

  int repaints = 0;

  @override
  Rect get globalBounds => bounds;

  @override
  MarkdownPosition? positionForGlobal(Offset globalPosition) => hit?.$1;

  @override
  (MarkdownPosition, TextAffinity)? hitForGlobal(Offset globalPosition) => hit;

  @override
  bool hitsSelectableGlyphs(Offset globalPosition) => false;

  @override
  bool isLinkAtGlobal(Offset globalPosition) =>
      link && bounds.contains(globalPosition);

  @override
  Rect? caretRectFor(MarkdownPosition position, TextAffinity affinity) =>
      caret?.call(position);

  @override
  (int, int, int)? wordBoundaryForGlobal(Offset globalPosition) => null;

  @override
  List<Rect> globalSelectionRects() =>
      [for (final r in locals) r.shift(bounds.topLeft)];

  @override
  List<Rect> localSelectionRects() => locals;

  @override
  List<Rect> localBoxesForRange(
    int blockIndex,
    int startOffset,
    int endOffset,
  ) =>
      const <Rect>[];

  @override
  void setSelectionHandleLayers({
    LayerLink? startLink,
    Offset? startLocal,
    LayerLink? endLink,
    Offset? endLocal,
  }) {}

  @override
  bool get hasSelectionHandleLeaders => false;

  @override
  void clearSelectionHandleLayersIfLinked({
    required LayerLink startLink,
    required LayerLink endLink,
  }) {}

  @override
  void repaintSelection() => repaints++;
}

MarkdownPosition _p(Object doc, int offset, [int block = 0]) =>
    MarkdownPosition(documentId: doc, blockIndex: block, offset: offset);

MarkdownSelectionController _controller(Map<Object, String> docs) {
  final c = MarkdownSelectionController()
    ..setDocuments(<MarkdownDocumentRef>[
      for (final e in docs.entries)
        MarkdownDocumentRef(id: e.key, model: Markdown.fromString(e.value)),
    ]);
  addTearDown(c.dispose);
  return c;
}

const _config = MarkdownSelectionAutoscrollConfig(
  edgeZone: 40,
  maxVelocity: 2000,
  useMediaQueryPadding: false,
);

void main() {
  group('selection coverage', () {
    group('selectionColor', () {
      test('repaints every mounted surface without notifying', () {
        final c = _controller({'a': 'Alpha', 'b': 'Bravo'});
        final a = _Surface('a');
        final b = _Surface('b');
        c
          ..attachSurface(a)
          ..attachSurface(b);
        var notified = 0;
        c.addListener(() => notified++);
        c.selectionColor = const Color(0xFF00FF00);
        expect(c.selectionColor, const Color(0xFF00FF00));
        expect(a.repaints, 1);
        expect(b.repaints, 1);
        // Same value is a no-op.
        c.selectionColor = const Color(0xFF00FF00);
        expect(a.repaints, 1);
        expect(notified, 0);
      });
    });

    group('selection endpoint geometry', () {
      test('global rect, overlap and unmounted edges', () {
        final c = _controller({'a': 'Hello world'});
        final s = _Surface('a', bounds: const Rect.fromLTWH(10, 20, 300, 40))
          ..caret =
              (p) => p.offset == 0 ? const Rect.fromLTWH(5, 0, 0, 10) : null;
        c
          ..attachSurface(s)
          ..selection = MarkdownSelection(base: _p('a', 0), extent: _p('a', 5));

        expect(
          c.selectionEndpointGlobalRect(base: true),
          const Rect.fromLTWH(15, 20, 0, 10),
        );
        // The extent surface reports no caret → null.
        expect(c.selectionEndpointGlobalRect(base: false), isNull);

        const near = Rect.fromLTWH(0, 0, 50, 50);
        const far = Rect.fromLTWH(200, 200, 10, 10);
        expect(c.selectionEndpointOverlaps(near, base: true), isTrue);
        expect(c.selectionEndpointOverlaps(far, base: true), isFalse);
        expect(c.selectionEndpointOverlaps(near, base: false), isFalse);
        expect(c.anySelectionEndpointOverlaps(near), isTrue);
        expect(c.anySelectionEndpointOverlaps(far), isFalse);

        // A zero-width caret exactly on the rect's left edge does not
        // overlap it geometrically; the 0.5 px inflate makes it count.
        const edge = Rect.fromLTWH(15, 20, 10, 10);
        expect(edge.overlaps(const Rect.fromLTWH(15, 20, 0, 10)), isFalse);
        expect(c.selectionEndpointOverlaps(edge, base: true), isTrue);
        // One pixel away is out of view.
        expect(
          c.selectionEndpointOverlaps(
            const Rect.fromLTWH(16, 20, 10, 10),
            base: true,
          ),
          isFalse,
        );

        // Unmounted: not "in view".
        c.detachSurface(s);
        expect(c.selectionEndpointGlobalRect(base: true), isNull);
        expect(c.anySelectionEndpointOverlaps(near), isFalse);
      });

      test('collapsed or empty selection has no endpoint rect', () {
        final c = _controller({'a': 'Hello'});
        c.attachSurface(
          _Surface('a')..caret = (_) => const Rect.fromLTWH(0, 0, 0, 10),
        );
        expect(c.selectionEndpointGlobalRect(base: true), isNull);
        c.selection = MarkdownSelection.collapsed(_p('a', 2));
        expect(c.selectionEndpointGlobalRect(base: true), isNull);
      });
    });

    group('coincident handle carets', () {
      MarkdownSelectionController setup(
        _Surface s, {
        bool reversed = false,
      }) {
        final c = _controller({'a': 'Hello world'})..attachSurface(s);
        final base = _p('a', reversed ? 5 : 0);
        final extent = _p('a', reversed ? 0 : 5);
        c.selection = MarkdownSelection(base: base, extent: extent);
        return c;
      }

      // Both directed carets land on the same point (soft-wrap affinity
      // churn), while the painted selection spans two lines.
      _Surface surface() =>
          _Surface('a', bounds: const Rect.fromLTWH(10, 20, 300, 100))
            ..locals = const <Rect>[
              Rect.fromLTWH(30, 12, 50, 10),
              Rect.fromLTWH(0, 0, 40, 10),
            ]
            ..caret = (_) => const Rect.fromLTWH(50, 0, 0, 10);

      test('fall back to the visible selection extremes', () {
        final c = setup(surface());
        final e = c.selectionHandleEndpoints()!;
        expect(e.startLocal, const Rect.fromLTWH(0, 0, 0, 10));
        expect(e.endLocal, const Rect.fromLTWH(80, 12, 0, 10));
        expect(e.startGlobal, const Rect.fromLTWH(10, 20, 0, 10));
        expect(e.endGlobal, const Rect.fromLTWH(90, 32, 0, 10));
      });

      test('a reversed selection swaps the extremes onto base/extent', () {
        final c = setup(surface(), reversed: true);
        expect(c.isSelectionReversed, isTrue);
        final e = c.selectionHandleEndpoints()!;
        // The base (start handle) of a reversed selection is the reading end.
        expect(e.startLocal, const Rect.fromLTWH(80, 12, 0, 10));
        expect(e.endLocal, const Rect.fromLTWH(0, 0, 0, 10));
      });

      test('keep the carets when the extremes coincide too', () {
        final s = surface()..locals = const <Rect>[Rect.fromLTWH(0, 0, 1, 10)];
        final c = setup(s);
        final e = c.selectionHandleEndpoints()!;
        expect(e.startLocal, const Rect.fromLTWH(50, 0, 0, 10));
        expect(e.endLocal, const Rect.fromLTWH(50, 0, 0, 10));
      });
    });

    group('moveSelectionEdgeToGlobal on a collapsed selection', () {
      test('bounces forward off the fixed edge', () {
        final c = _controller({'a': 'Hello'});
        final s = _Surface('a', bounds: const Rect.fromLTWH(0, 0, 100, 20))
          ..hit = (_p('a', 2), TextAffinity.downstream);
        c
          ..attachSurface(s)
          ..selection = MarkdownSelection.collapsed(_p('a', 2))
          ..moveSelectionEdgeToGlobal(const Offset(5, 5), isStart: false);
        expect(
          c.selection,
          MarkdownSelection(base: _p('a', 2), extent: _p('a', 3)),
        );
      });

      test('bounces backward at the very end of the last document', () {
        final c = _controller({'a': 'Hello'});
        final s = _Surface('a', bounds: const Rect.fromLTWH(0, 0, 100, 20))
          ..hit = (_p('a', 5), TextAffinity.downstream);
        c
          ..attachSurface(s)
          ..selection = MarkdownSelection.collapsed(_p('a', 5))
          ..moveSelectionEdgeToGlobal(const Offset(5, 5), isStart: false);
        expect(
          c.selection,
          MarkdownSelection(base: _p('a', 5), extent: _p('a', 4)),
        );
        expect(c.isSelectionReversed, isTrue);
      });
    });

    group('registry', () {
      test('setDocuments without the selected document drops it', () {
        final c = _controller({'a': 'Alpha', 'b': 'Bravo'})
          ..selection = MarkdownSelection(base: _p('a', 0), extent: _p('a', 3))
          ..toolbarWanted = true;
        c.setDocuments(<MarkdownDocumentRef>[
          MarkdownDocumentRef(id: 'b', model: Markdown.fromString('Bravo')),
        ]);
        expect(c.selection, isNull);
        expect(c.toolbarWanted, isFalse);
      });

      test('isLinkAtGlobal asks every mounted surface', () {
        final c = _controller({'a': 'Alpha', 'b': 'Bravo'});
        c
          ..attachSurface(
            _Surface('a', bounds: const Rect.fromLTWH(0, 0, 100, 20)),
          )
          ..attachSurface(
            _Surface('b', bounds: const Rect.fromLTWH(0, 40, 100, 20))
              ..link = true,
          );
        expect(c.isLinkAtGlobal(const Offset(5, 45)), isTrue);
        expect(c.isLinkAtGlobal(const Offset(5, 5)), isFalse);
        expect(c.isLinkAtGlobal(const Offset(500, 500)), isFalse);
      });

      test('two unregistered endpoints order by id, never as -1', () {
        final c = _controller({'a': 'Alpha'})
          ..selection =
              MarkdownSelection(base: _p('zz', 0), extent: _p('aa', 0));
        expect(c.isSelectionReversed, isTrue);
        expect(c.rangeFor('a', 0), isNull);
        c.selection = MarkdownSelection(base: _p('aa', 0), extent: _p('zz', 0));
        expect(c.isSelectionReversed, isFalse);
        expect(c.rangeFor('a', 0), isNull);
      });
    });

    group('autoscroll helpers', () {
      test('viewport toString names bounds and padding', () {
        const v = MarkdownAutoscrollViewport(
          globalBounds: Rect.fromLTWH(0, 0, 10, 20),
          padding: EdgeInsets.only(top: 3),
        );
        final s = v.toString();
        expect(s, startsWith('MarkdownAutoscrollViewport('));
        expect(s, contains('${v.globalBounds}'));
        expect(s, contains('padding: ${v.padding}'));
      });

      test('depth fraction is the square root of the velocity ratio', () {
        double depth(double y, [MarkdownSelectionAutoscrollConfig? c]) =>
            markdownAutoscrollDepthFraction(
              localY: y,
              clipTopLocalY: 0,
              clipHeight: 200,
              config: c ?? _config,
            );
        expect(depth(100), 0);
        // 10 px into the 40 px bottom band (threshold at 160).
        expect(depth(170), closeTo(0.25, 1e-9));
        expect(depth(30), closeTo(0.25, 1e-9));
        expect(depth(200), closeTo(1, 1e-9));
        expect(depth(170, MarkdownSelectionAutoscrollConfig.disabled), 0);
      });

      const bounds = Rect.fromLTWH(0, 100, 400, 200);

      test('an unusable viewport resets the session and idles', () {
        var asked = 0;
        final target = MarkdownCallbackAutoscrollTarget(
          viewportOf: () => const MarkdownAutoscrollViewport(
            globalBounds: bounds,
            padding: EdgeInsets.only(top: 150, bottom: 150),
          ),
          onScrollDelta: (d) {
            asked++;
            return d;
          },
        );
        final session = MarkdownAutoscrollSession()..disarm(towardStart: true);
        Duration? stored = Duration.zero;
        final result = applyMarkdownSelectionAutoscroll(
          globalPosition: Offset(10, bounds.bottom - 3),
          target: target,
          config: _config,
          lastTimestamp: const Duration(seconds: 1),
          storeTimestamp: (t) => stored = t,
          hostUnionTopGlobalY: -1000,
          hostUnionBottomGlobalY: 5000,
          session: session,
        );
        expect(result, MarkdownAutoscrollResult.idle);
        expect(asked, 0);
        expect(stored, isNull);
        expect(session.isDisarmedTowardStart, isFalse);
      });

      test('a finger far above the viewport keeps scrolling at max', () {
        final deltas = <double>[];
        final target = MarkdownCallbackAutoscrollTarget(
          viewportOf: () =>
              const MarkdownAutoscrollViewport(globalBounds: bounds),
          onScrollDelta: (d) {
            deltas.add(d);
            return d;
          },
        );
        final result = applyMarkdownSelectionAutoscroll(
          // 80 px above the top edge: past the 40 px outer band.
          globalPosition: Offset(10, bounds.top - 80),
          target: target,
          config: _config,
          lastTimestamp: null,
          storeTimestamp: (_) {},
          hostUnionTopGlobalY: -1000,
          hostUnionBottomGlobalY: 5000,
        );
        expect(result, MarkdownAutoscrollResult.scrolled);
        // Full max velocity for one 60 Hz frame, toward the start.
        expect(deltas.single, closeTo(-_config.maxVelocity / 60, 1e-6));
      });

      testWidgets('no target and no enclosing Scrollable is idle',
          (tester) async {
        await tester.pumpWidget(const SizedBox.expand());
        final context = tester.element(find.byType(SizedBox));
        Duration? stored = Duration.zero;
        final result = applyMarkdownSelectionAutoscroll(
          globalPosition: const Offset(10, 590),
          context: context,
          config: _config,
          lastTimestamp: const Duration(seconds: 1),
          storeTimestamp: (t) => stored = t,
          hostUnionTopGlobalY: -1000,
          hostUnionBottomGlobalY: 5000,
        );
        expect(result, MarkdownAutoscrollResult.idle);
        expect(stored, isNull);
      });

      testWidgets(
          'resolves from the Scrollable element itself and folds '
          'off-viewport chrome into the pads', (tester) async {
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(size: Size(800, 600)),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const SizedBox(height: 50),
                  SizedBox(
                    height: 300,
                    child: ListView(
                      children: <Widget>[
                        for (var i = 0; i < 40; i++)
                          SizedBox(height: 30, child: Text('row $i')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        final element = tester.element(find.byType(Scrollable));
        expect(element, isA<StatefulElement>());
        final state = tester.state<ScrollableState>(find.byType(Scrollable));
        final target = resolveMarkdownScrollableAutoscrollTarget(
          context: element,
          config: _config.copyWith(useMediaQueryPadding: true),
        );
        expect(target, isNotNull);
        expect(identical(target!.scrollable, state), isTrue);
        // 50 px of chrome above → at least the 8 px minimum top pad;
        // 250 px below → clamped to 120.
        expect(target.padding.top, 8);
        expect(target.padding.bottom, 120);
        expect(
          target.viewport!.globalBounds,
          const Rect.fromLTWH(0, 50, 800, 300),
        );
      });

      testWidgets('a reversed Scrollable element resolves to itself',
          (tester) async {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: ListView(
              reverse: true,
              children: <Widget>[
                for (var i = 0; i < 40; i++)
                  SizedBox(height: 30, child: Text('row $i')),
              ],
            ),
          ),
        );
        final state = tester.state<ScrollableState>(find.byType(Scrollable));
        expect(state.axisDirection, AxisDirection.up);
        final target = resolveMarkdownScrollableAutoscrollTarget(
          context: tester.element(find.byType(Scrollable)),
          config: _config,
        );
        expect(identical(target?.scrollable, state), isTrue);
        expect(target!.padding, EdgeInsets.zero);
      });
    });
  });
}
