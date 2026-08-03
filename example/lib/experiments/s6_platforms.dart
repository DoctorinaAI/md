// SPIKE S6 — Platform interaction demo (RUN THIS ON EACH PLATFORM).
//
// This wires the recommended architecture end to end at a small scale:
//   * a scope-owned controller holds the selection as logical anchors over an
//     app-supplied model registry (so it survives disposal);
//   * each "message" is a custom Selectable RenderBox that paints its own
//     highlight under the glyphs (S3) and registers a surface (S5);
//   * a scope gesture layer drives selection from a mouse/touch drag;
//   * "Copy" reads controller.getPlainText() (full text WITH separators, even
//     for scrolled-off messages);
//   * one message is a link, to exercise the tap-vs-drag gesture arena.
//
// It is a manual, interactive spike (touch handles / magnifier / native menus
// can only be judged by a human on device). Headless mechanics are already
// proven by s1..s5,s7 under benchmark/experiments/.
//
// Run (from example/):
//   flutter run -t lib/experiments/s6_platforms.dart -d chrome
//   flutter run -t lib/experiments/s6_platforms.dart -d linux
//   flutter run -t lib/experiments/s6_platforms.dart -d <ios|android|macos|windows>

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

void main() => runApp(const _App());

class _App extends StatefulWidget {
  const _App();
  @override
  State<_App> createState() => _AppState();
}

class _AppState extends State<_App> {
  final MdSelectionController controller = MdSelectionController(<MdDoc>[
    MdDoc('m0', 'Heading of the conversation'),
    MdDoc('m1', 'This is the first message. Drag across me and the next ones.'),
    MdDoc('m2', 'Second message with a bit more text to select through.'),
    MdDoc('m3', 'LINK: tap me to test the tap-vs-drag arena.', isLink: true),
    MdDoc('m4', 'Fourth message. Selection should span all of these blocks.'),
    MdDoc('m5', 'Fifth and final message in this little transcript.'),
  ]);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'S6 selection spike',
      home: Scaffold(
        appBar: AppBar(title: const Text('flutter_md selection spike (S6)')),
        floatingActionButton: FloatingActionButton.extended(
          icon: const Icon(Icons.copy),
          label: const Text('Copy'),
          onPressed: () async {
            final text = controller.getPlainText();
            await Clipboard.setData(ClipboardData(text: text));
            if (!context.mounted) return;
            ScaffoldMessenger.of(context)
              ..clearSnackBars()
              ..showSnackBar(SnackBar(
                content: Text(text.isEmpty
                    ? '(no selection)'
                    : 'Copied ${text.length} chars:\n$text'),
              ));
          },
        ),
        body: MarkdownSelectionScope(
          controller: controller,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              for (final d in controller.docs)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: MdMessage(docId: d.id),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Controller + model registry (logical anchors over the immutable text).
// ---------------------------------------------------------------------------
class MdDoc {
  MdDoc(this.id, this.text, {this.isLink = false});
  final Object id;
  final String text;
  final bool isLink;
}

@immutable
class MdPos {
  const MdPos(this.doc, this.offset);
  final Object doc;
  final int offset;
}

class MdSelectionController extends ChangeNotifier {
  MdSelectionController(this.docs);
  final List<MdDoc> docs;
  final Map<Object, MdSurface> _surfaces = <Object, MdSurface>{};
  MdPos? base;
  MdPos? extent;

  void registerSurface(MdSurface s) => _surfaces[s.docId] = s;
  void unregisterSurface(MdSurface s) {
    if (_surfaces[s.docId] == s) _surfaces.remove(s.docId);
  }

  int docIndex(Object id) => docs.indexWhere((d) => d.id == id);
  String _text(Object id) => docs[docIndex(id)].text;

  MdPos? hitTest(Offset global) {
    for (final s in _surfaces.values) {
      if (s.globalBounds.inflate(6).contains(global)) {
        return MdPos(s.docId, s.offsetForGlobal(global));
      }
    }
    return null;
  }

  void startAt(Offset g) {
    final p = hitTest(g);
    if (p == null) return;
    base = extent = p;
    notifyListeners();
  }

  void extendTo(Offset g) {
    final p = hitTest(g);
    if (p == null) return;
    extent = p;
    notifyListeners();
  }

  void clear() {
    base = extent = null;
    notifyListeners();
  }

  int _cmp(MdPos a, MdPos b) {
    final ai = docIndex(a.doc), bi = docIndex(b.doc);
    return ai != bi ? ai.compareTo(bi) : a.offset.compareTo(b.offset);
  }

  /// The [start, end] selected range for [docId], or null if not selected.
  (int, int)? rangeFor(Object docId) {
    if (base == null || extent == null) return null;
    var a = base!, b = extent!;
    if (_cmp(a, b) > 0) {
      final t = a;
      a = b;
      b = t;
    }
    final di = docIndex(docId);
    if (di < docIndex(a.doc) || di > docIndex(b.doc)) return null;
    final len = _text(docId).length;
    final from = docId == a.doc ? a.offset : 0;
    final to = docId == b.doc ? b.offset : len;
    return (from.clamp(0, len), to.clamp(0, len));
  }

  String getPlainText({String docSep = '\n\n'}) {
    if (base == null || extent == null) return '';
    var a = base!, b = extent!;
    if (_cmp(a, b) > 0) {
      final t = a;
      a = b;
      b = t;
    }
    final start = docIndex(a.doc), end = docIndex(b.doc);
    final chunks = <String>[];
    for (var d = start; d <= end; d++) {
      final text = docs[d].text;
      final from = d == start ? a.offset : 0;
      final to = d == end ? b.offset : text.length;
      chunks.add(text.substring(from.clamp(0, text.length), to.clamp(0, text.length)));
    }
    return chunks.join(docSep);
  }
}

// ---------------------------------------------------------------------------
// Scope: provides the controller + a scope-level drag coordinator.
// ---------------------------------------------------------------------------
abstract interface class MdSurface {
  Object get docId;
  Rect get globalBounds;
  int offsetForGlobal(Offset global);
}

class _ScopeInherited extends InheritedWidget {
  const _ScopeInherited({required this.controller, required super.child});
  final MdSelectionController controller;
  static MdSelectionController of(BuildContext c) =>
      c.dependOnInheritedWidgetOfExactType<_ScopeInherited>()!.controller;
  @override
  bool updateShouldNotify(_ScopeInherited old) => controller != old.controller;
}

class MarkdownSelectionScope extends StatelessWidget {
  const MarkdownSelectionScope({
    required this.controller,
    required this.child,
    super.key,
  });
  final MdSelectionController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _ScopeInherited(
      controller: controller,
      // Mouse: drag selects. Touch: long-press-then-drag selects (so a plain
      // swipe still scrolls the ListView). This is the arena resolution S6 is
      // meant to eyeball on each platform.
      child: RawGestureDetector(
        gestures: <Type, GestureRecognizerFactory>{
          PanGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<PanGestureRecognizer>(
            () => PanGestureRecognizer(
                supportedDevices: <PointerDeviceKind>{PointerDeviceKind.mouse}),
            (r) => r
              ..onStart = ((d) => controller.startAt(d.globalPosition))
              ..onUpdate = ((d) => controller.extendTo(d.globalPosition)),
          ),
          LongPressGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
            () => LongPressGestureRecognizer(),
            (r) => r
              ..onLongPressStart = ((d) => controller.startAt(d.globalPosition))
              ..onLongPressMoveUpdate = ((d) => controller.extendTo(d.globalPosition)),
          ),
        },
        child: child,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// A message = a custom Selectable-ish RenderBox that paints its own highlight.
// ---------------------------------------------------------------------------
class MdMessage extends LeafRenderObjectWidget {
  const MdMessage({required this.docId, super.key});
  final Object docId;

  @override
  RenderObject createRenderObject(BuildContext context) {
    final controller = _ScopeInherited.of(context);
    final doc = controller.docs[controller.docIndex(docId)];
    return _MdMessageBox(doc, controller);
  }

  @override
  void updateRenderObject(BuildContext context, _MdMessageBox ro) {
    ro.controller = _ScopeInherited.of(context);
  }
}

class _MdMessageBox extends RenderBox implements MdSurface {
  _MdMessageBox(this.doc, this._controller)
      : _painter = TextPainter(
          text: TextSpan(
            text: doc.text,
            style: TextStyle(
              fontSize: 16,
              color: doc.isLink ? const Color(0xFF1565C0) : const Color(0xFF111111),
              decoration: doc.isLink ? TextDecoration.underline : null,
            ),
          ),
          textDirection: TextDirection.ltr,
        );

  final MdDoc doc;
  final TextPainter _painter;
  MdSelectionController _controller;
  bool _disposed = false;
  TapGestureRecognizer? _tap;

  @override
  Object get docId => doc.id;

  set controller(MdSelectionController c) {
    if (identical(c, _controller)) return;
    _controller.removeListener(_onSel);
    _controller = c;
    _controller.addListener(_onSel);
  }

  void _onSel() {
    if (!_disposed) markNeedsPaint();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _controller
      ..registerSurface(this)
      ..addListener(_onSel);
    if (doc.isLink) {
      _tap = TapGestureRecognizer()
        ..onTap = () => debugPrint('LINK TAP fired for ${doc.id}');
    }
  }

  @override
  void detach() {
    _controller
      ..unregisterSurface(this)
      ..removeListener(_onSel);
    _tap?.dispose();
    _tap = null;
    super.detach();
  }

  @override
  void dispose() {
    _disposed = true;
    _painter.dispose();
    super.dispose();
  }

  // Tap handling for the link (drag is handled at the scope level).
  @override
  bool hitTestSelf(Offset position) => doc.isLink;
  @override
  void handleEvent(PointerEvent event, covariant HitTestEntry entry) {
    if (doc.isLink && event is PointerDownEvent) _tap?.addPointer(event);
  }

  @override
  Rect get globalBounds => localToGlobal(Offset.zero) & size;

  @override
  int offsetForGlobal(Offset global) =>
      _painter.getPositionForOffset(globalToLocal(global)).offset;

  @override
  void performLayout() {
    _painter.layout(maxWidth: constraints.maxWidth);
    size = constraints.constrain(Size(constraints.maxWidth, _painter.height));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final range = _controller.rangeFor(doc.id);
    if (range != null && range.$1 != range.$2) {
      final boxes = _painter.getBoxesForSelection(
        TextSelection(baseOffset: range.$1, extentOffset: range.$2),
      );
      final paint = Paint()..color = const Color(0x552196F3);
      for (final b in boxes) {
        context.canvas.drawRect(b.toRect().shift(offset), paint);
      }
    }
    _painter.paint(context.canvas, offset);
  }
}
