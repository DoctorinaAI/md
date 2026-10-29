import 'package:flutter/widgets.dart';
import 'package:flutter_md/src/selection_autoscroll.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _scrollHost({
  required ScrollController controller,
  required GlobalKey hostKey,
  double height = 200,
}) =>
    MediaQuery(
      data: const MediaQueryData(size: Size(800, 600)),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 400,
            height: height,
            child: ListView(
              controller: controller,
              children: [
                SizedBox(
                  height: 800,
                  child: ColoredBox(
                    key: hostKey,
                    color: const Color(0xFF000000),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

void main() {
  const config = MarkdownSelectionAutoscrollConfig(
    edgeZone: 40,
    maxVelocity: 100,
    topPad: 10,
    bottomPad: 10,
    useMediaQueryPadding: false,
  );

  group('markdownAutoscrollVelocity', () {
    test('is zero in the middle of the clip', () {
      expect(
        markdownAutoscrollVelocityInViewport(
          localY: 200,
          viewportHeight: 400,
          config: config,
          resolvedTopPad: 10,
          resolvedBottomPad: 10,
        ),
        0,
      );
    });

    test('scrolls toward min at the top band with quadratic depth', () {
      expect(
        markdownAutoscrollVelocityInViewport(
          localY: 30,
          viewportHeight: 400,
          config: config,
          resolvedTopPad: 10,
          resolvedBottomPad: 10,
        ),
        closeTo(-25, 0.001),
      );
      expect(
        markdownAutoscrollVelocityInViewport(
          localY: 10,
          viewportHeight: 400,
          config: config,
          resolvedTopPad: 10,
          resolvedBottomPad: 10,
        ),
        closeTo(-100, 0.001),
      );
    });

    test('scrolls toward max at the bottom band with quadratic depth', () {
      expect(
        markdownAutoscrollVelocityInViewport(
          localY: 370,
          viewportHeight: 400,
          config: config,
          resolvedTopPad: 10,
          resolvedBottomPad: 10,
        ),
        closeTo(25, 0.001),
      );
      expect(
        markdownAutoscrollVelocityInViewport(
          localY: 390,
          viewportHeight: 400,
          config: config,
          resolvedTopPad: 10,
          resolvedBottomPad: 10,
        ),
        closeTo(100, 0.001),
      );
    });

    test('disabled config always returns zero', () {
      expect(
        markdownAutoscrollVelocity(
          localY: 0,
          clipTopLocalY: 0,
          clipHeight: 400,
          config: MarkdownSelectionAutoscrollConfig.disabled,
        ),
        0,
      );
    });

    test('mid-viewport host clip does not fire at scrollable bottom', () {
      // Host union sits mid-list: clip is [100, 200] in a 400 viewport.
      // Finger at the scrollable bottom must not activate.
      expect(
        markdownAutoscrollVelocity(
          localY: 398,
          clipTopLocalY: 100,
          clipHeight: 100,
          config: const MarkdownSelectionAutoscrollConfig(
            edgeZone: 40,
            maxVelocity: 100,
            useMediaQueryPadding: false,
          ),
        ),
        0,
      );
      // Finger in the host-clip bottom band does activate.
      expect(
        markdownAutoscrollVelocity(
          localY: 195,
          clipTopLocalY: 100,
          clipHeight: 100,
          config: const MarkdownSelectionAutoscrollConfig(
            edgeZone: 40,
            maxVelocity: 100,
            useMediaQueryPadding: false,
          ),
        ),
        greaterThan(0),
      );
    });
    test('allows edgeZone overshoot past the clip outer edge', () {
      // Finger just past clip bottom still activates; far chrome does not.
      expect(
        markdownAutoscrollVelocity(
          localY: 220,
          clipTopLocalY: 100,
          clipHeight: 100,
          config: const MarkdownSelectionAutoscrollConfig(
            edgeZone: 40,
            maxVelocity: 100,
            useMediaQueryPadding: false,
          ),
        ),
        greaterThan(0),
      );
      expect(
        markdownAutoscrollVelocity(
          localY: 398,
          clipTopLocalY: 100,
          clipHeight: 100,
          config: const MarkdownSelectionAutoscrollConfig(
            edgeZone: 40,
            maxVelocity: 100,
            useMediaQueryPadding: false,
          ),
        ),
        0,
      );
    });
  });

  testWidgets(
    'past padded viewport still scrolls when host union extends',
    (tester) async {
      final controller = ScrollController();
      final hostKey = GlobalKey();
      await tester.pumpWidget(
        _scrollHost(controller: controller, hostKey: hostKey),
      );
      await tester.pumpAndSettle();

      final hostContext = tester.element(find.byKey(hostKey));
      final listBox = tester.renderObject<RenderBox>(find.byType(Scrollable));
      final origin = listBox.localToGlobal(Offset.zero);

      Duration? last;
      final before = controller.offset;
      // Finger below the padded clip while content still continues past it.
      // Within edgeZone past the pad → velocity outer band still scrolls.
      final result = applyMarkdownSelectionAutoscroll(
        globalPosition: origin + Offset(10, listBox.size.height + 20),
        context: hostContext,
        config: const MarkdownSelectionAutoscrollConfig(
          edgeZone: 40,
          maxVelocity: 2000,
          useMediaQueryPadding: false,
        ),
        lastTimestamp: null,
        storeTimestamp: (value) => last = value,
        hostUnionTopGlobalY: origin.dy - 50,
        hostUnionBottomGlobalY: origin.dy + 2000,
      );

      expect(result, MarkdownAutoscrollResult.scrolled);
      expect(controller.offset, greaterThan(before));
      expect(last, isNotNull);
    },
  );

  testWidgets(
    'far past padded viewport still scrolls when host union extends',
    (tester) async {
      final controller = ScrollController();
      final hostKey = GlobalKey();
      await tester.pumpWidget(
        _scrollHost(controller: controller, hostKey: hostKey),
      );
      await tester.pumpAndSettle();

      final hostContext = tester.element(find.byKey(hostKey));
      final listBox = tester.renderObject<RenderBox>(find.byType(Scrollable));
      final origin = listBox.localToGlobal(Offset.zero);

      Duration? last;
      final before = controller.offset;
      // Beyond edgeZone past the pad → max velocity while host still extends.
      const edgeZone = 40.0;
      final result = applyMarkdownSelectionAutoscroll(
        globalPosition:
            origin + Offset(10, listBox.size.height + edgeZone + 10),
        context: hostContext,
        config: const MarkdownSelectionAutoscrollConfig(
          edgeZone: edgeZone,
          maxVelocity: 2000,
          useMediaQueryPadding: false,
        ),
        lastTimestamp: null,
        storeTimestamp: (value) => last = value,
        hostUnionTopGlobalY: origin.dy - 50,
        hostUnionBottomGlobalY: origin.dy + 2000,
      );

      expect(result, MarkdownAutoscrollResult.scrolled);
      expect(controller.offset, greaterThan(before));
      expect(last, isNotNull);
    },
  );

  testWidgets(
    'far past padded viewport idles when host union does not extend',
    (tester) async {
      final controller = ScrollController();
      final hostKey = GlobalKey();
      await tester.pumpWidget(
        _scrollHost(controller: controller, hostKey: hostKey),
      );
      await tester.pumpAndSettle();

      final hostContext = tester.element(find.byKey(hostKey));
      final listBox = tester.renderObject<RenderBox>(find.byType(Scrollable));
      final origin = listBox.localToGlobal(Offset.zero);

      final before = controller.offset;
      const edgeZone = 40.0;
      final result = applyMarkdownSelectionAutoscroll(
        globalPosition:
            origin + Offset(10, listBox.size.height + edgeZone + 10),
        context: hostContext,
        config: const MarkdownSelectionAutoscrollConfig(
          edgeZone: edgeZone,
          maxVelocity: 2000,
          useMediaQueryPadding: false,
        ),
        lastTimestamp: null,
        storeTimestamp: (_) {},
        // Mid-viewport host flush with / inside the pad — no endward scroll.
        hostUnionTopGlobalY: origin.dy + 80,
        hostUnionBottomGlobalY: origin.dy + 200,
      );

      expect(result, MarkdownAutoscrollResult.idle);
      expect(controller.offset, before);
    },
  );

  testWidgets(
    'past viewport does not scroll when host union ends mid-viewport',
    (tester) async {
      final controller = ScrollController();
      final hostKey = GlobalKey();
      await tester.pumpWidget(
        _scrollHost(controller: controller, hostKey: hostKey),
      );
      await tester.pumpAndSettle();

      final hostContext = tester.element(find.byKey(hostKey));
      final listBox = tester.renderObject<RenderBox>(find.byType(Scrollable));
      final origin = listBox.localToGlobal(Offset.zero);

      final result = applyMarkdownSelectionAutoscroll(
        globalPosition: origin + Offset(10, listBox.size.height - 2),
        context: hostContext,
        config: const MarkdownSelectionAutoscrollConfig(
          edgeZone: 40,
          maxVelocity: 2000,
          useMediaQueryPadding: false,
        ),
        lastTimestamp: null,
        storeTimestamp: (_) {},
        hostUnionTopGlobalY: origin.dy + 40,
        hostUnionBottomGlobalY: origin.dy + 100,
      );

      expect(result, isNot(MarkdownAutoscrollResult.scrolled));
      expect(controller.offset, 0);
    },
  );

  testWidgets(
    'applyMarkdownSelectionAutoscroll jumps when host union extends below',
    (tester) async {
      final controller = ScrollController();
      final hostKey = GlobalKey();
      await tester.pumpWidget(
        _scrollHost(controller: controller, hostKey: hostKey),
      );
      await tester.pumpAndSettle();

      final hostContext = tester.element(find.byKey(hostKey));
      final listBox = tester.renderObject<RenderBox>(find.byType(Scrollable));
      final origin = listBox.localToGlobal(Offset.zero);

      Duration? last;
      final before = controller.offset;
      final result = applyMarkdownSelectionAutoscroll(
        globalPosition: origin + Offset(10, listBox.size.height - 2),
        context: hostContext,
        config: const MarkdownSelectionAutoscrollConfig(
          edgeZone: 40,
          maxVelocity: 2000,
          useMediaQueryPadding: false,
        ),
        lastTimestamp: null,
        storeTimestamp: (value) => last = value,
        hostUnionTopGlobalY: origin.dy - 50,
        hostUnionBottomGlobalY: origin.dy + 2000,
      );

      expect(result, MarkdownAutoscrollResult.scrolled);
      expect(controller.offset, greaterThan(before));
      expect(last, isNotNull);
    },
  );

  testWidgets(
    'suppresses when host-union top is already visible (no list runaway)',
    (tester) async {
      final controller = ScrollController();
      final hostKey = GlobalKey();
      await tester.pumpWidget(
        _scrollHost(controller: controller, hostKey: hostKey),
      );
      await tester.pumpAndSettle();

      final hostContext = tester.element(find.byKey(hostKey));
      final listBox = tester.renderObject<RenderBox>(find.byType(Scrollable));
      final origin = listBox.localToGlobal(Offset.zero);
      final contentTop = origin.dy;
      final contentBottom = contentTop + 400;

      Duration? last;
      final result = applyMarkdownSelectionAutoscroll(
        globalPosition: origin + const Offset(10, 2),
        context: hostContext,
        config: const MarkdownSelectionAutoscrollConfig(
          edgeZone: 40,
          maxVelocity: 2000,
          useMediaQueryPadding: false,
        ),
        lastTimestamp: null,
        storeTimestamp: (value) => last = value,
        hostUnionTopGlobalY: contentTop,
        hostUnionBottomGlobalY: contentBottom,
      );

      expect(result, MarkdownAutoscrollResult.suppressed);
      expect(controller.offset, 0);
      expect(last, isNull);
    },
  );

  testWidgets(
    'hard-stops toward start when host-union top is already below pad',
    (tester) async {
      final controller = ScrollController();
      final hostKey = GlobalKey();
      await tester.pumpWidget(
        _scrollHost(controller: controller, hostKey: hostKey),
      );
      await tester.pumpAndSettle();
      controller.jumpTo(200);
      await tester.pumpAndSettle();

      final hostContext = tester.element(find.byKey(hostKey));
      final listBox = tester.renderObject<RenderBox>(find.byType(Scrollable));
      final origin = listBox.localToGlobal(Offset.zero);

      // Host starts mid-viewport (headers above). Top band must not scroll
      // into non-host chrome.
      final result = applyMarkdownSelectionAutoscroll(
        globalPosition: origin + const Offset(10, 2),
        context: hostContext,
        config: const MarkdownSelectionAutoscrollConfig(
          edgeZone: 40,
          maxVelocity: 2000,
          useMediaQueryPadding: false,
        ),
        lastTimestamp: null,
        storeTimestamp: (_) {},
        hostUnionTopGlobalY: origin.dy + 80,
        hostUnionBottomGlobalY: origin.dy + 2000,
      );

      expect(result, MarkdownAutoscrollResult.suppressed);
      expect(controller.offset, 200);
    },
  );

  testWidgets(
    'scrolls toward start when host-union top extends above the pad',
    (tester) async {
      final controller = ScrollController();
      final hostKey = GlobalKey();
      await tester.pumpWidget(
        _scrollHost(controller: controller, hostKey: hostKey),
      );
      await tester.pumpAndSettle();
      controller.jumpTo(200);
      await tester.pumpAndSettle();

      final hostContext = tester.element(find.byKey(hostKey));
      final listBox = tester.renderObject<RenderBox>(find.byType(Scrollable));
      final origin = listBox.localToGlobal(Offset.zero);

      Duration? last;
      final before = controller.offset;
      final result = applyMarkdownSelectionAutoscroll(
        globalPosition: origin + const Offset(10, 2),
        context: hostContext,
        config: const MarkdownSelectionAutoscrollConfig(
          edgeZone: 40,
          maxVelocity: 2000,
          useMediaQueryPadding: false,
        ),
        lastTimestamp: null,
        storeTimestamp: (value) => last = value,
        hostUnionTopGlobalY: origin.dy - 120,
        hostUnionBottomGlobalY: origin.dy + 2000,
      );

      expect(result, MarkdownAutoscrollResult.scrolled);
      expect(controller.offset, lessThan(before));
      expect(last, isNotNull);
    },
  );

  testWidgets(
    'pulls host back when entirely below the padded viewport',
    (tester) async {
      final controller = ScrollController();
      final hostKey = GlobalKey();
      await tester.pumpWidget(
        _scrollHost(controller: controller, hostKey: hostKey),
      );
      await tester.pumpAndSettle();

      final hostContext = tester.element(find.byKey(hostKey));
      final listBox = tester.renderObject<RenderBox>(find.byType(Scrollable));
      final origin = listBox.localToGlobal(Offset.zero);

      Duration? last;
      final before = controller.offset;
      // Host fully below the pad (former clipHeight<=0 death). Bottom band
      // must still pull it back into view.
      final result = applyMarkdownSelectionAutoscroll(
        globalPosition: origin + Offset(10, listBox.size.height - 2),
        context: hostContext,
        config: const MarkdownSelectionAutoscrollConfig(
          edgeZone: 40,
          maxVelocity: 2000,
          useMediaQueryPadding: false,
        ),
        lastTimestamp: null,
        storeTimestamp: (value) => last = value,
        hostUnionTopGlobalY: origin.dy + listBox.size.height + 20,
        hostUnionBottomGlobalY: origin.dy + listBox.size.height + 800,
      );

      expect(result, MarkdownAutoscrollResult.scrolled);
      expect(controller.offset, greaterThan(before));
      expect(last, isNotNull);
    },
  );

  testWidgets(
    'suppresses at host-union bottom even when scrollable still has extent',
    (tester) async {
      final controller = ScrollController();
      final hostKey = GlobalKey();
      await tester.pumpWidget(
        _scrollHost(controller: controller, hostKey: hostKey),
      );
      await tester.pumpAndSettle();

      final hostContext = tester.element(find.byKey(hostKey));
      final listBox = tester.renderObject<RenderBox>(find.byType(Scrollable));
      final origin = listBox.localToGlobal(Offset.zero);

      // Host ends mid-viewport; finger in the *padded viewport* bottom band.
      // ListView still has chrome below — must hard-stop at the union.
      final result = applyMarkdownSelectionAutoscroll(
        globalPosition: origin + Offset(10, listBox.size.height - 2),
        context: hostContext,
        config: const MarkdownSelectionAutoscrollConfig(
          edgeZone: 40,
          maxVelocity: 2000,
          useMediaQueryPadding: false,
        ),
        lastTimestamp: null,
        storeTimestamp: (_) {},
        hostUnionTopGlobalY: origin.dy,
        hostUnionBottomGlobalY: origin.dy + 100,
      );
      expect(result, MarkdownAutoscrollResult.suppressed);
      expect(controller.offset, 0);
    },
  );

  testWidgets(
    'arming gate blocks scroll after hard stop until leave and re-enter',
    (tester) async {
      final controller = ScrollController();
      final hostKey = GlobalKey();
      await tester.pumpWidget(
        _scrollHost(controller: controller, hostKey: hostKey),
      );
      await tester.pumpAndSettle();

      final hostContext = tester.element(find.byKey(hostKey));
      final listBox = tester.renderObject<RenderBox>(find.byType(Scrollable));
      final origin = listBox.localToGlobal(Offset.zero);
      final session = MarkdownAutoscrollSession();
      // Padded-viewport bottom band with a mid-viewport host (hard-stop).
      final edgePos = origin + Offset(10, listBox.size.height - 2);
      final midPos = origin + const Offset(10, 50);

      // Hard-stop at flush union bottom → disarms toward end.
      final stopped = applyMarkdownSelectionAutoscroll(
        globalPosition: edgePos,
        context: hostContext,
        config: const MarkdownSelectionAutoscrollConfig(
          edgeZone: 40,
          maxVelocity: 2000,
          useMediaQueryPadding: false,
        ),
        lastTimestamp: null,
        storeTimestamp: (_) {},
        hostUnionTopGlobalY: origin.dy,
        hostUnionBottomGlobalY: origin.dy + 100,
        session: session,
      );
      expect(stopped, MarkdownAutoscrollResult.suppressed);
      expect(session.isDisarmedTowardEnd, isTrue);

      // Still in band with content that *could* scroll — gate must suppress.
      final gated = applyMarkdownSelectionAutoscroll(
        globalPosition: origin + Offset(10, listBox.size.height - 2),
        context: hostContext,
        config: const MarkdownSelectionAutoscrollConfig(
          edgeZone: 40,
          maxVelocity: 2000,
          useMediaQueryPadding: false,
        ),
        lastTimestamp: null,
        storeTimestamp: (_) {},
        hostUnionTopGlobalY: origin.dy - 50,
        hostUnionBottomGlobalY: origin.dy + 2000,
        session: session,
      );
      expect(gated, MarkdownAutoscrollResult.suppressed);
      expect(controller.offset, 0);

      // Leave the band → re-arm.
      final left = applyMarkdownSelectionAutoscroll(
        globalPosition: midPos,
        context: hostContext,
        config: const MarkdownSelectionAutoscrollConfig(
          edgeZone: 40,
          maxVelocity: 2000,
          useMediaQueryPadding: false,
        ),
        lastTimestamp: null,
        storeTimestamp: (_) {},
        hostUnionTopGlobalY: origin.dy - 50,
        hostUnionBottomGlobalY: origin.dy + 2000,
        session: session,
      );
      expect(left, MarkdownAutoscrollResult.idle);
      expect(session.isDisarmedTowardEnd, isFalse);

      // Re-enter → may scroll again.
      final before = controller.offset;
      final resumed = applyMarkdownSelectionAutoscroll(
        globalPosition: origin + Offset(10, listBox.size.height - 2),
        context: hostContext,
        config: const MarkdownSelectionAutoscrollConfig(
          edgeZone: 40,
          maxVelocity: 2000,
          useMediaQueryPadding: false,
        ),
        lastTimestamp: null,
        storeTimestamp: (_) {},
        hostUnionTopGlobalY: origin.dy - 50,
        hostUnionBottomGlobalY: origin.dy + 2000,
        session: session,
      );
      expect(resumed, MarkdownAutoscrollResult.scrolled);
      expect(controller.offset, greaterThan(before));
    },
  );

  testWidgets(
    'keeps scrolling after full selection until host union clears bottomPad',
    (tester) async {
      final controller = ScrollController();
      final hostKey = GlobalKey();
      await tester.pumpWidget(
        _scrollHost(controller: controller, hostKey: hostKey),
      );
      await tester.pumpAndSettle();

      final hostContext = tester.element(find.byKey(hostKey));
      final listBox = tester.renderObject<RenderBox>(find.byType(Scrollable));
      final origin = listBox.localToGlobal(Offset.zero);

      Duration? last;
      final before = controller.offset;
      // With bottomPad 104, the padded clip ends at localY≈96; sit in that
      // clip's bottom band while the host union still extends below.
      final result = applyMarkdownSelectionAutoscroll(
        globalPosition: origin + const Offset(10, 90),
        context: hostContext,
        config: const MarkdownSelectionAutoscrollConfig(
          edgeZone: 40,
          maxVelocity: 2000,
          bottomPad: 104,
          useMediaQueryPadding: false,
        ),
        lastTimestamp: null,
        storeTimestamp: (value) => last = value,
        hostUnionTopGlobalY: origin.dy - 50,
        hostUnionBottomGlobalY: origin.dy + 500,
      );

      expect(result, MarkdownAutoscrollResult.scrolled);
      expect(controller.offset, greaterThan(before));
      expect(last, isNotNull);
    },
  );

  testWidgets('useMediaQueryPadding uses viewPadding', (tester) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(
          padding: EdgeInsets.only(top: 10, bottom: 20),
          viewPadding: EdgeInsets.only(top: 24, bottom: 48),
        ),
        child: SizedBox(),
      ),
    );
    final context = tester.element(find.byType(SizedBox));
    final (top, bottom) = resolveMarkdownAutoscrollPads(
      config: const MarkdownSelectionAutoscrollConfig(
        topPad: 8,
        bottomPad: 4,
      ),
      context: context,
    );
    expect(top, 32); // 8 + max(10, 24)
    expect(bottom, 52); // 4 + max(20, 48)
  });
}
