// SPIKE S5 — Cross-widget topology.
//
// Question: what topology lets ONE selection span N MarkdownWidgets in a
// ListView.builder AND survive item disposal?
//
// Given S2's finding (a stock Scrollable interposes its own private
// SelectionContainer, so stock SelectableRegion coordinates only LIVE items and
// drops disposed ones), the answer is: DON'T route cross-widget selection
// through SelectableRegion/Scrollable at all. Instead a scope-owned controller
// holds logical anchors + an app-supplied model registry (survives disposal),
// while mounted render objects register as "surfaces" that map a global point
// to a logical position. The scope's gesture layer drives the controller.
//
// This spike wires that end to end (one paragraph per message, since cross-BLOCK
// was already proven in S3 and cross-doc extraction in S4) and proves:
//   * no SelectableRegion single-child assert is involved (we don't use it);
//   * selection spans multiple mounted MarkdownWidgets;
//   * it SURVIVES disposal — text still retrievable after scroll-off.
//
// Throwaway spike; outside lib/ and test/.
// Run: flutter test benchmark/experiments/s5_cross_widget_topology_test.dart
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

@immutable
class MdPos {
  const MdPos(this.doc, this.offset);
  final Object doc;
  final int offset;
}

abstract interface class MdSurface {
  Object get docId;
  Rect get globalBounds;
  int offsetForGlobal(Offset global);
}

class MdController extends ChangeNotifier {
  MdController(
      this.docs); // app-supplied, ordered, ALL messages (mounted or not)
  final List<(Object id, String text)> docs;

  final Map<Object, MdSurface> _surfaces = <Object, MdSurface>{};
  MdPos? base;
  MdPos? extent;

  void registerSurface(MdSurface s) => _surfaces[s.docId] = s;
  void unregisterSurface(MdSurface s) {
    if (_surfaces[s.docId] == s) _surfaces.remove(s.docId);
  }

  Iterable<Object> get mountedDocIds => _surfaces.keys;

  int _docIndex(Object id) => docs.indexWhere((d) => d.$1 == id);
  String _text(Object id) => docs[_docIndex(id)].$2;

  /// Map a global point to a logical position by asking mounted surfaces.
  MdPos? hitTest(Offset global) {
    for (final s in _surfaces.values) {
      if (s.globalBounds.contains(global)) {
        return MdPos(s.docId, s.offsetForGlobal(global));
      }
    }
    return null;
  }

  void startAt(Offset global) {
    final p = hitTest(global);
    if (p == null) return;
    base = extent = p;
    notifyListeners();
  }

  void extendTo(Offset global) {
    final p = hitTest(global);
    if (p == null) return;
    extent = p;
    notifyListeners();
  }

  int _cmp(MdPos a, MdPos b) {
    final ai = _docIndex(a.doc), bi = _docIndex(b.doc);
    return ai != bi ? ai.compareTo(bi) : a.offset.compareTo(b.offset);
  }

  String getPlainText({String docSep = '\n\n'}) {
    if (base == null || extent == null) return '';
    var a = base!, b = extent!;
    if (_cmp(a, b) > 0) {
      final t = a;
      a = b;
      b = t;
    }
    final start = _docIndex(a.doc), end = _docIndex(b.doc);
    final chunks = <String>[];
    for (var d = start; d <= end; d++) {
      final text = docs[d].$2;
      final from = d == start ? a.offset : 0;
      final to = d == end ? b.offset : text.length;
      chunks.add(
          text.substring(from.clamp(0, text.length), to.clamp(0, text.length)));
    }
    return chunks.join(docSep);
  }
}

class _Scope extends InheritedWidget {
  const _Scope({required this.controller, required super.child});
  final MdController controller;
  static MdController of(BuildContext c) =>
      c.dependOnInheritedWidgetOfExactType<_Scope>()!.controller;
  @override
  bool updateShouldNotify(_Scope old) => controller != old.controller;
}

class MarkdownScope extends StatelessWidget {
  const MarkdownScope(
      {required this.controller, required this.child, super.key});
  final MdController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) => _Scope(
        controller: controller,
        // A real scope resolves scroll-vs-select in the gesture arena (S6);
        // here the coordinator just forwards global drag points.
        child: RawGestureDetector(
          gestures: <Type, GestureRecognizerFactory>{
            PanGestureRecognizer:
                GestureRecognizerFactoryWithHandlers<PanGestureRecognizer>(
              () => PanGestureRecognizer(),
              (r) => r
                ..onStart = ((d) => controller.startAt(d.globalPosition))
                ..onUpdate = ((d) => controller.extendTo(d.globalPosition)),
            ),
          },
          child: child,
        ),
      );
}

class MdMessage extends LeafRenderObjectWidget {
  const MdMessage({required this.docId, required this.text, super.key});
  final Object docId;
  final String text;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _MdMessageBox(docId, text, _Scope.of(context));
  @override
  void updateRenderObject(BuildContext context, _MdMessageBox ro) =>
      ro.controller = _Scope.of(context);
}

class _MdMessageBox extends RenderBox implements MdSurface {
  _MdMessageBox(this.docId, String text, this.controller)
      : _painter = TextPainter(
          text: TextSpan(
            text: text,
            style: const TextStyle(fontSize: 16, color: Color(0xFF000000)),
          ),
          textDirection: TextDirection.ltr,
        );

  @override
  final Object docId;
  final TextPainter _painter;
  MdController controller;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    controller.registerSurface(this);
  }

  @override
  void detach() {
    controller.unregisterSurface(this);
    super.detach();
  }

  @override
  Rect get globalBounds => localToGlobal(Offset.zero) & size;

  @override
  int offsetForGlobal(Offset global) =>
      _painter.getPositionForOffset(globalToLocal(global)).offset;

  @override
  void performLayout() {
    _painter.layout(maxWidth: constraints.maxWidth);
    size = constraints.constrain(_painter.size);
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      _painter.paint(context.canvas, offset);
}

void main() {
  testWidgets('S5 cross-widget selection survives disposal', (tester) async {
    final controller = MdController(<(Object, String)>[
      for (var i = 0; i < 8; i++) ('m$i', 'Message number $i'),
    ]);
    final scroll = ScrollController();

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          height: 200,
          child: MarkdownScope(
            controller: controller,
            child: ListView.builder(
              controller: scroll,
              cacheExtent: 0,
              itemCount: 8,
              itemBuilder: (_, i) => SizedBox(
                height: 80,
                child: MdMessage(docId: 'm$i', text: 'Message number $i'),
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    // Only the first few messages are mounted (surfaces). Anchor the selection
    // across m0..m1 by hit-testing their mounted surfaces — exactly what the
    // scope gesture layer does on a real drag.
    final p0 =
        tester.getTopLeft(find.byType(MdMessage).first) + const Offset(1, 3);
    final m1 = find.byWidgetPredicate((w) => w is MdMessage && w.docId == 'm1');
    final p1 = tester.getBottomRight(m1) - const Offset(1, 3);
    controller.startAt(p0);
    controller.extendTo(p1);

    final before = controller.getPlainText();
    debugPrint('S5 before = ${before.replaceAll('\n', r'\n')}');
    expect(before, contains('Message number 0'));
    expect(before, contains('Message number 1'));

    // Scroll so m0 is disposed.
    scroll.jumpTo(80.0 * 6);
    await tester.pumpAndSettle();
    expect(find.byWidgetPredicate((w) => w is MdMessage && w.docId == 'm0'),
        findsNothing);
    expect(controller.mountedDocIds, isNot(contains('m0')),
        reason: 'm0 surface unregistered on disposal');

    // Selection text is derived from the app-supplied model registry, so it is
    // fully intact even though m0 is gone.
    final after = controller.getPlainText();
    debugPrint('S5 after  = ${after.replaceAll('\n', r'\n')}');
    expect(after, before, reason: 'cross-widget selection survived disposal');
    expect(after, contains('Message number 0'));
  });
}
