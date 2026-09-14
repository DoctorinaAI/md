import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_md/flutter_md.dart';
import 'package:flutter_test/flutter_test.dart';

/// A scroll protocol that is **not** a [Scrollable]: an anchor offset the host
/// owns, exactly like the chat viewports that render their children from a
/// `RenderBox` instead of the sliver protocol.
///
/// `offset` grows as content moves up, so `scrollBy` here has the same sign as
/// a screen-space autoscroll delta; anchor-relative hosts (whose positive
/// delta reveals *older* content) negate it in their resolver.
class _AnchorScrollHost extends StatefulWidget {
  const _AnchorScrollHost({
    required this.viewportHeight,
    required this.child,
    required this.onState,
    this.maxOffset = double.infinity,
  });

  final double viewportHeight;
  final Widget child;
  final ValueChanged<_AnchorScrollHostState> onState;

  /// Hard stop, emulating "reached the oldest message".
  final double maxOffset;

  @override
  State<_AnchorScrollHost> createState() => _AnchorScrollHostState();
}

class _AnchorScrollHostState extends State<_AnchorScrollHost> {
  final GlobalKey _viewportKey = GlobalKey();

  /// Pixels of content scrolled past the top edge.
  double offset = 0;

  double get maxOffset => widget.maxOffset;

  int scrollCalls = 0;

  MarkdownAutoscrollViewport? viewportOf() {
    final box = _viewportKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    return MarkdownAutoscrollViewport(
      globalBounds: box.localToGlobal(Offset.zero) & box.size,
    );
  }

  bool canScroll({required bool forward}) =>
      forward ? offset < maxOffset : offset > 0;

  double applyScrollDelta(double delta) {
    final next = (offset + delta).clamp(0.0, maxOffset);
    final applied = next - offset;
    if (applied.abs() < 0.5) return 0;
    scrollCalls++;
    setState(() => offset = next);
    return applied;
  }

  MarkdownAutoscrollTarget get target => MarkdownCallbackAutoscrollTarget(
        viewportOf: viewportOf,
        onScrollDelta: applyScrollDelta,
        canScrollAt: canScroll,
      );

  @override
  void initState() {
    super.initState();
    widget.onState(this);
  }

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          key: _viewportKey,
          width: 400,
          height: widget.viewportHeight,
          child: ClipRect(
            child: OverflowBox(
              alignment: Alignment.topLeft,
              maxHeight: double.infinity,
              child: Transform.translate(
                offset: Offset(0, -offset),
                child: SizedBox(width: 400, child: widget.child),
              ),
            ),
          ),
        ),
      );
}

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

/// A long single-paragraph document that wraps into many lines.
Markdown _longDoc() => Markdown.fromString(
      List<String>.generate(60, (i) => 'line $i of the body').join(' '),
    );

const _config = MarkdownSelectionAutoscrollConfig(
  edgeZone: 40,
  maxVelocity: 2000,
  useMediaQueryPadding: false,
);

void main() {
  group('MarkdownAutoscrollViewport', () {
    test('padding deflates the padded bounds', () {
      const viewport = MarkdownAutoscrollViewport(
        globalBounds: Rect.fromLTWH(0, 100, 400, 200),
        padding: EdgeInsets.only(top: 10, bottom: 20),
      );
      expect(
        viewport.paddedGlobalBounds,
        const Rect.fromLTRB(0, 110, 400, 280),
      );
      expect(viewport.isUsable, isTrue);
    });

    test('padding taller than the viewport is not usable', () {
      const viewport = MarkdownAutoscrollViewport(
        globalBounds: Rect.fromLTWH(0, 0, 400, 30),
        padding: EdgeInsets.symmetric(vertical: 20),
      );
      expect(viewport.isUsable, isFalse);
    });

    test('a non-finite viewport is not usable', () {
      const viewport = MarkdownAutoscrollViewport(
        globalBounds: Rect.fromLTRB(0, 0, 400, double.infinity),
      );
      expect(viewport.isUsable, isFalse);
    });
  });

  group('custom scroll protocol', () {
    /// Everything below drives [applyMarkdownSelectionAutoscroll] directly with
    /// a hand-built target — no widget tree, no `Scrollable`.
    const bounds = Rect.fromLTWH(0, 100, 400, 200);

    ({
      MarkdownAutoscrollTarget target,
      List<double> deltas,
      double Function() offset,
    }) makeTarget({
      EdgeInsets padding = EdgeInsets.zero,
      double min = -1000,
      double max = 1000,
      MarkdownAutoscrollViewport? Function()? viewportOf,
    }) {
      var offset = 0.0;
      final deltas = <double>[];
      final target = MarkdownCallbackAutoscrollTarget(
        viewportOf: viewportOf ??
            () => MarkdownAutoscrollViewport(
                  globalBounds: bounds,
                  padding: padding,
                ),
        canScrollAt: ({required forward}) =>
            forward ? offset < max : offset > min,
        onScrollDelta: (delta) {
          final next = (offset + delta).clamp(min, max);
          final applied = next - offset;
          offset = next;
          if (applied != 0) deltas.add(applied);
          return applied;
        },
      );
      return (target: target, deltas: deltas, offset: () => offset);
    }

    MarkdownAutoscrollResult run(
      MarkdownAutoscrollTarget target,
      double globalY, {
      MarkdownAutoscrollSession? session,
      double hostTop = -1000,
      double hostBottom = 5000,
      Duration? last,
    }) =>
        applyMarkdownSelectionAutoscroll(
          globalPosition: Offset(10, globalY),
          target: target,
          config: _config,
          lastTimestamp: last,
          storeTimestamp: (_) {},
          hostUnionTopGlobalY: hostTop,
          hostUnionBottomGlobalY: hostBottom,
          session: session,
        );

    test('bottom band moves content up (positive delta)', () {
      final t = makeTarget();
      // 3 px above the bottom edge → inside the 40 px band.
      expect(
        run(t.target, bounds.bottom - 3),
        MarkdownAutoscrollResult.scrolled,
      );
      expect(t.deltas, isNotEmpty);
      expect(t.deltas.first, greaterThan(0));
      expect(t.offset(), greaterThan(0));
    });

    test('top band moves content down (negative delta)', () {
      final t = makeTarget();
      expect(run(t.target, bounds.top + 3), MarkdownAutoscrollResult.scrolled);
      expect(t.deltas, isNotEmpty);
      expect(t.deltas.first, lessThan(0));
      expect(t.offset(), lessThan(0));
    });

    test('mid-viewport pointer is idle', () {
      final t = makeTarget();
      expect(run(t.target, bounds.center.dy), MarkdownAutoscrollResult.idle);
      expect(t.deltas, isEmpty);
    });

    test('canScroll false suppresses and disarms that direction', () {
      final t = makeTarget(max: 0);
      final session = MarkdownAutoscrollSession();
      expect(
        run(t.target, bounds.bottom - 3, session: session),
        MarkdownAutoscrollResult.suppressed,
      );
      expect(t.deltas, isEmpty);
      expect(session.isDisarmedTowardEnd, isTrue);
      expect(session.isDisarmedTowardStart, isFalse);
    });

    test('a flush target (zero applied delta) suppresses and disarms', () {
      var asked = 0;
      final target = MarkdownCallbackAutoscrollTarget(
        viewportOf: () =>
            const MarkdownAutoscrollViewport(globalBounds: bounds),
        onScrollDelta: (_) {
          asked++;
          return 0;
        },
      );
      final session = MarkdownAutoscrollSession();
      expect(
        run(target, bounds.bottom - 3, session: session),
        MarkdownAutoscrollResult.suppressed,
      );
      expect(asked, 1);
      expect(session.isDisarmedTowardEnd, isTrue);
    });

    test('a disarmed direction stays suppressed until the band is left', () {
      final t = makeTarget();
      final session = MarkdownAutoscrollSession()..disarm(towardStart: false);
      expect(
        run(t.target, bounds.bottom - 3, session: session),
        MarkdownAutoscrollResult.suppressed,
      );
      expect(t.deltas, isEmpty);
      // Leaving the band re-arms.
      expect(
        run(t.target, bounds.center.dy, session: session),
        MarkdownAutoscrollResult.idle,
      );
      expect(session.isDisarmedTowardEnd, isFalse);
      expect(
        run(t.target, bounds.bottom - 3, session: session),
        MarkdownAutoscrollResult.scrolled,
      );
    });

    test('padding moves the activation band inward', () {
      final padded = makeTarget(padding: const EdgeInsets.only(bottom: 60));
      // 50 px above the raw bottom edge is *below* the padded bottom (140),
      // so it is still inside the band — but 10 px past the padded bottom.
      expect(
        run(padded.target, bounds.bottom - 50),
        MarkdownAutoscrollResult.scrolled,
      );

      final plain = makeTarget();
      // The same point is deep inside an unpadded viewport → idle.
      expect(
        run(plain.target, bounds.bottom - 50),
        MarkdownAutoscrollResult.idle,
      );
    });

    test('a null viewport idles without touching the target', () {
      var asked = 0;
      final target = MarkdownCallbackAutoscrollTarget(
        viewportOf: () => null,
        onScrollDelta: (delta) {
          asked++;
          return delta;
        },
      );
      expect(run(target, 0), MarkdownAutoscrollResult.idle);
      expect(asked, 0);
    });

    test('host union gate still applies to a custom target', () {
      final t = makeTarget();
      // Host union ends mid-viewport → nothing left to reveal downward.
      expect(
        run(
          t.target,
          bounds.bottom - 3,
          hostTop: bounds.top + 10,
          hostBottom: bounds.top + 100,
        ),
        MarkdownAutoscrollResult.suppressed,
      );
      expect(t.deltas, isEmpty);
    });

    test('useHostUnionGate false lets the target decide instead', () {
      final gated = makeTarget();
      // Host union ends mid-viewport: with the gate on, nothing to reveal.
      expect(
        run(
          gated.target,
          bounds.bottom - 3,
          hostTop: bounds.top + 10,
          hostBottom: bounds.top + 100,
        ),
        MarkdownAutoscrollResult.suppressed,
      );

      // A chat viewport that builds only what is visible opts out: its own
      // `canScroll` is the authority.
      var offset = 0.0;
      final ungated = MarkdownCallbackAutoscrollTarget(
        viewportOf: () =>
            const MarkdownAutoscrollViewport(globalBounds: bounds),
        onScrollDelta: (delta) {
          offset += delta;
          return delta;
        },
      );
      expect(
        applyMarkdownSelectionAutoscroll(
          globalPosition: Offset(10, bounds.bottom - 3),
          target: ungated,
          config: _config.copyWith(useHostUnionGate: false),
          lastTimestamp: null,
          storeTimestamp: (_) {},
          hostUnionTopGlobalY: bounds.top + 10,
          hostUnionBottomGlobalY: bounds.top + 100,
        ),
        MarkdownAutoscrollResult.scrolled,
      );
      expect(offset, greaterThan(0));
    });

    test('useHostUnionGate false still stops on a flush target', () {
      var offset = 0.0;
      final target = MarkdownCallbackAutoscrollTarget(
        viewportOf: () =>
            const MarkdownAutoscrollViewport(globalBounds: bounds),
        canScrollAt: ({required forward}) => false,
        onScrollDelta: (delta) {
          offset += delta;
          return delta;
        },
      );
      final session = MarkdownAutoscrollSession();
      expect(
        applyMarkdownSelectionAutoscroll(
          globalPosition: Offset(10, bounds.bottom - 3),
          target: target,
          config: _config.copyWith(useHostUnionGate: false),
          lastTimestamp: null,
          storeTimestamp: (_) {},
          hostUnionTopGlobalY: -1000,
          hostUnionBottomGlobalY: 5000,
          session: session,
        ),
        MarkdownAutoscrollResult.suppressed,
      );
      expect(offset, 0);
      expect(session.isDisarmedTowardEnd, isTrue);
    });

    test('a disabled config never resolves a target', () {
      var asked = 0;
      final target = MarkdownCallbackAutoscrollTarget(
        viewportOf: () {
          asked++;
          return const MarkdownAutoscrollViewport(globalBounds: bounds);
        },
        onScrollDelta: (delta) => delta,
      );
      expect(
        applyMarkdownSelectionAutoscroll(
          globalPosition: Offset(10, bounds.bottom - 3),
          target: target,
          config: MarkdownSelectionAutoscrollConfig.disabled,
          lastTimestamp: null,
          storeTimestamp: (_) {},
          hostUnionTopGlobalY: -1000,
          hostUnionBottomGlobalY: 5000,
        ),
        MarkdownAutoscrollResult.idle,
      );
      expect(asked, 0);
    });
  });

  group('MarkdownScrollableAutoscrollTarget', () {
    testWidgets('drives a forward list toward maxScrollExtent', (tester) async {
      final controller = ScrollController();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 400,
              height: 200,
              child: ListView(
                controller: controller,
                children: const <Widget>[SizedBox(height: 2000)],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final state = tester.state<ScrollableState>(find.byType(Scrollable));
      final target = MarkdownScrollableAutoscrollTarget(state);

      expect(target.viewport, isNotNull);
      expect(target.viewport!.globalBounds.height, 200);
      expect(target.canScroll(forward: true), isTrue);
      expect(target.canScroll(forward: false), isFalse);

      expect(target.applyScrollDelta(50), closeTo(50, 0.01));
      expect(controller.offset, closeTo(50, 0.01));
      expect(target.canScroll(forward: false), isTrue);

      expect(target.applyScrollDelta(-50), closeTo(-50, 0.01));
      expect(controller.offset, closeTo(0, 0.01));

      // Flush at the min extent — no movement, and the caller is told so.
      expect(target.applyScrollDelta(-50), 0);
      controller.dispose();
    });

    testWidgets('a reverse list keeps the screen-space delta sign',
        (tester) async {
      final controller = ScrollController();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 400,
              height: 200,
              child: ListView(
                controller: controller,
                reverse: true,
                children: const <Widget>[SizedBox(height: 2000)],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final state = tester.state<ScrollableState>(find.byType(Scrollable));
      expect(state.axisDirection, AxisDirection.up);
      final target = MarkdownScrollableAutoscrollTarget(state);

      // A reverse list starts pinned at the bottom: content can only move
      // *down* on screen (revealing what is above), i.e. a negative delta.
      expect(target.canScroll(forward: true), isFalse);
      expect(target.canScroll(forward: false), isTrue);

      // Screen-space "content down" must grow `pixels` on a reversed axis.
      final applied = target.applyScrollDelta(-50);
      expect(applied, closeTo(-50, 0.01));
      expect(controller.offset, closeTo(50, 0.01));
      controller.dispose();
    });

    testWidgets('an unmounted scrollable reports no viewport', (tester) async {
      final controller = ScrollController();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: 400,
            height: 200,
            child: ListView(
              controller: controller,
              children: const <Widget>[SizedBox(height: 2000)],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final state = tester.state<ScrollableState>(find.byType(Scrollable));
      final target = MarkdownScrollableAutoscrollTarget(state);
      expect(target.viewport, isNotNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();

      expect(target.viewport, isNull);
      expect(target.canScroll(forward: true), isFalse);
      expect(target.applyScrollDelta(50), 0);
      controller.dispose();
    });
  });

  group('MarkdownSelectionScope autoscroll target resolution', () {
    testWidgets('a custom scroll protocol is driven by a selection drag',
        (tester) async {
      final md = _longDoc();
      final selection = MarkdownSelectionController()
        ..setDocuments(<MarkdownDocumentRef>[
          MarkdownDocumentRef(id: 'd', model: md),
        ]);
      addTearDown(selection.dispose);

      late _AnchorScrollHostState host;
      var resolverCalls = 0;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => MarkdownSelectionScope(
              controller: selection,
              autoscroll: MarkdownSelectionAutoscrollConfig(
                edgeZone: 40,
                maxVelocity: 2000,
                useMediaQueryPadding: false,
                targetResolver: (request) {
                  resolverCalls++;
                  expect(request.config.edgeZone, 40);
                  expect(request.scopeContext.mounted, isTrue);
                  return host.target;
                },
              ),
              child: _AnchorScrollHost(
                viewportHeight: 200,
                onState: (state) => host = state,
                child: const _Doc('d'),
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final viewport = tester.getRect(find.byType(ClipRect).first);
      expect(host.offset, 0);

      final gesture = await tester.startGesture(
        viewport.topLeft + const Offset(10, 10),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump(const Duration(milliseconds: 20));
      // Drag into the bottom edge band and hold there.
      await gesture.moveTo(Offset(viewport.center.dx, viewport.bottom - 5));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pumpAndSettle();

      expect(resolverCalls, greaterThan(0));
      expect(host.scrollCalls, greaterThan(0));
      expect(host.offset, greaterThan(0));
      expect(selection.selection, isNotNull);
      expect(selection.getText(), isNotEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the resolver is not re-run on every frame of one drag',
        (tester) async {
      final md = _longDoc();
      final selection = MarkdownSelectionController()
        ..setDocuments(<MarkdownDocumentRef>[
          MarkdownDocumentRef(id: 'd', model: md),
        ]);
      addTearDown(selection.dispose);

      late _AnchorScrollHostState host;
      var resolverCalls = 0;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MarkdownSelectionScope(
            controller: selection,
            autoscroll: MarkdownSelectionAutoscrollConfig(
              edgeZone: 40,
              maxVelocity: 2000,
              useMediaQueryPadding: false,
              targetResolver: (_) {
                resolverCalls++;
                return host.target;
              },
            ),
            child: _AnchorScrollHost(
              viewportHeight: 200,
              onState: (state) => host = state,
              child: const _Doc('d'),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final viewport = tester.getRect(find.byType(ClipRect).first);
      final gesture = await tester.startGesture(
        viewport.topLeft + const Offset(10, 10),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump(const Duration(milliseconds: 20));
      await gesture.moveTo(Offset(viewport.center.dx, viewport.bottom - 5));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      final duringDrag = resolverCalls;
      await gesture.up();
      await tester.pumpAndSettle();

      expect(duringDrag, 1,
          reason: 'the target is cached for the lifetime of one drag');
      expect(host.scrollCalls, greaterThan(3));
    });

    testWidgets('a scope rebuild during a drag does not re-resolve the target',
        (tester) async {
      final md = _longDoc();
      final selection = MarkdownSelectionController()
        ..setDocuments(<MarkdownDocumentRef>[
          MarkdownDocumentRef(id: 'd', model: md),
        ]);
      addTearDown(selection.dispose);

      late _AnchorScrollHostState host;
      late StateSetter setStateFn;
      var tick = 0;
      var resolverCalls = 0;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(builder: (context, setState) {
            setStateFn = setState;
            return MarkdownSelectionScope(
              controller: selection,
              // A fresh config (and a fresh closure) on every rebuild — what a
              // real host writes. The cached surface must survive it.
              autoscroll: MarkdownSelectionAutoscrollConfig(
                edgeZone: 40,
                maxVelocity: 2000 + tick * 0.0,
                useMediaQueryPadding: false,
                targetResolver: (_) {
                  resolverCalls++;
                  return host.target;
                },
              ),
              child: _AnchorScrollHost(
                viewportHeight: 200,
                onState: (state) => host = state,
                child: const _Doc('d'),
              ),
            );
          }),
        ),
      ));
      await tester.pumpAndSettle();

      final viewport = tester.getRect(find.byType(ClipRect).first);
      final gesture = await tester.startGesture(
        viewport.topLeft + const Offset(10, 10),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump(const Duration(milliseconds: 20));
      await gesture.moveTo(Offset(viewport.center.dx, viewport.bottom - 5));
      for (var i = 0; i < 10; i++) {
        setStateFn(() => tick++);
        await tester.pump(const Duration(milliseconds: 16));
      }
      final duringDrag = resolverCalls;
      await gesture.up();
      await tester.pumpAndSettle();

      expect(duringDrag, 1);
      expect(host.scrollCalls, greaterThan(3));
    });

    testWidgets('a zero max velocity never drives the host', (tester) async {
      final md = _longDoc();
      final selection = MarkdownSelectionController()
        ..setDocuments(<MarkdownDocumentRef>[
          MarkdownDocumentRef(id: 'd', model: md),
        ]);
      addTearDown(selection.dispose);

      late _AnchorScrollHostState host;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MarkdownSelectionScope(
            controller: selection,
            autoscroll: MarkdownSelectionAutoscrollConfig(
              edgeZone: 40,
              maxVelocity: 0,
              useMediaQueryPadding: false,
              targetResolver: (_) => host.target,
            ),
            child: _AnchorScrollHost(
              viewportHeight: 200,
              onState: (state) => host = state,
              child: const _Doc('d'),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final viewport = tester.getRect(find.byType(ClipRect).first);
      final gesture = await tester.startGesture(
        viewport.topLeft + const Offset(10, 10),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump(const Duration(milliseconds: 20));
      // Hold far past the outer band — the branch that used to report
      // `scrolled` forever on a zero velocity.
      await gesture.moveTo(Offset(viewport.center.dx, viewport.bottom + 200));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pumpAndSettle();

      expect(host.scrollCalls, 0);
      expect(host.offset, 0);
    });

    testWidgets('a resolver returning null leaves the host unscrolled',
        (tester) async {
      final md = _longDoc();
      final selection = MarkdownSelectionController()
        ..setDocuments(<MarkdownDocumentRef>[
          MarkdownDocumentRef(id: 'd', model: md),
        ]);
      addTearDown(selection.dispose);

      late _AnchorScrollHostState host;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MarkdownSelectionScope(
            controller: selection,
            autoscroll: const MarkdownSelectionAutoscrollConfig(
              edgeZone: 40,
              maxVelocity: 2000,
              useMediaQueryPadding: false,
              targetResolver: _nullResolver,
            ),
            child: _AnchorScrollHost(
              viewportHeight: 200,
              onState: (state) => host = state,
              child: const _Doc('d'),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final viewport = tester.getRect(find.byType(ClipRect).first);
      final gesture = await tester.startGesture(
        viewport.topLeft + const Offset(10, 10),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump(const Duration(milliseconds: 20));
      await gesture.moveTo(Offset(viewport.center.dx, viewport.bottom - 5));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pumpAndSettle();

      expect(host.scrollCalls, 0);
      expect(host.offset, 0);
      // Selection still works — only the scroll is host-owned.
      expect(selection.selection, isNotNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a host that reports it cannot scroll is not driven',
        (tester) async {
      final md = _longDoc();
      final selection = MarkdownSelectionController()
        ..setDocuments(<MarkdownDocumentRef>[
          MarkdownDocumentRef(id: 'd', model: md),
        ]);
      addTearDown(selection.dispose);

      late _AnchorScrollHostState host;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MarkdownSelectionScope(
            controller: selection,
            autoscroll: MarkdownSelectionAutoscrollConfig(
              edgeZone: 40,
              maxVelocity: 2000,
              useMediaQueryPadding: false,
              targetResolver: (_) => host.target,
            ),
            child: _AnchorScrollHost(
              viewportHeight: 200,
              maxOffset: 0,
              onState: (state) => host = state,
              child: const _Doc('d'),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final viewport = tester.getRect(find.byType(ClipRect).first);
      final gesture = await tester.startGesture(
        viewport.topLeft + const Offset(10, 10),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump(const Duration(milliseconds: 20));
      await gesture.moveTo(Offset(viewport.center.dx, viewport.bottom - 5));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pumpAndSettle();

      expect(host.scrollCalls, 0);
      expect(host.offset, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('without a resolver the enclosing ListView is still driven',
        (tester) async {
      final md = _longDoc();
      final selection = MarkdownSelectionController()
        ..setDocuments(<MarkdownDocumentRef>[
          MarkdownDocumentRef(id: 'd', model: md),
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
              maxVelocity: 2000,
              useMediaQueryPadding: false,
            ),
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 400,
                height: 200,
                child: ListView(
                  controller: scroll,
                  children: const <Widget>[_Doc('d'), SizedBox(height: 1200)],
                ),
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final viewport = tester.getRect(find.byType(Scrollable));
      final gesture = await tester.startGesture(
        viewport.topLeft + const Offset(10, 10),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump(const Duration(milliseconds: 20));
      await gesture.moveTo(Offset(viewport.center.dx, viewport.bottom - 5));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pumpAndSettle();

      expect(scroll.offset, greaterThan(0));
      expect(tester.takeException(), isNull);
    });
  });
}

MarkdownAutoscrollTarget? _nullResolver(MarkdownAutoscrollRequest request) =>
    null;
